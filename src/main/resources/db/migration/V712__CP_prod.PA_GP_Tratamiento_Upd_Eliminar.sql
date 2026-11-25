IF OBJECT_ID(N'[prod].[PA_GP_Tratamiento_Upd_Eliminar]', N'P') IS NOT NULL
    DROP PROCEDURE [prod].[PA_GP_Tratamiento_Upd_Eliminar];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- Retiro lógico de tratamiento con motivo, permiso, ámbito e idempotencia.
CREATE PROCEDURE prod.PA_GP_Tratamiento_Upd_Eliminar
    @Sesion UNIQUEIDENTIFIER,
    @Usuario BIGINT,
    @Uot BIGINT,
    @Evento BIGINT,
    @Motivo NVARCHAR(1000),
    @Solicitud UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF prod.FN_GP_Permiso(@Sesion, @Usuario, @Uot, 'SANIDAD_RETIRAR', 1) <> 1
        THROW 51101, N'Acceso no autorizado.', 1;
    IF @Solicitud IS NULL OR LEN(TRIM(COALESCE(@Motivo, N''))) < 3
        THROW 51103, N'Indique el motivo del retiro.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Auditoria BIGINT, @Actividad BIGINT, @Incidencia BIGINT;
        SELECT @Auditoria = E.evento_id
        FROM prod.GPEvento E WITH (UPDLOCK, HOLDLOCK)
        WHERE E.solicitud_id = @Solicitud;

        IF @Auditoria IS NOT NULL
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM prod.GPEvento E
                WHERE E.evento_id = @Auditoria
                  AND E.tipo = 'OBSERVACION'
                  AND E.respuesta_a_id = @Evento
                  AND E.observacion = CONCAT(N'Retiro lógico de tratamiento #', @Evento, N'. Motivo: ', TRIM(@Motivo))
            )
                THROW 51103, N'La solicitud ya fue utilizada.', 1;
            COMMIT TRANSACTION;
            SELECT @Evento AS id;
            RETURN;
        END;

        SELECT @Incidencia = I.incidencia_id, @Actividad = I.actividad_id
        FROM prod.GPIncidenciaTratamiento T WITH (UPDLOCK, HOLDLOCK)
        JOIN prod.GPIncidencia I WITH (UPDLOCK, HOLDLOCK)
            ON I.incidencia_id = T.incidencia_id
        JOIN prod.GPEvento E WITH (UPDLOCK, HOLDLOCK)
            ON E.evento_id = T.evento_id
        JOIN prod.GPActividad A
            ON A.actividad_id = I.actividad_id AND A.estado = 1 AND A.estado_proceso = 'ACTIVA'
        JOIN prod.Parcela P
            ON P.parcela_id = A.parcela_id AND P.estado = 1
        JOIN prod.PredioAmbito B
            ON B.predio_id = A.predio_id AND B.uot_id = @Uot
            AND B.estado = 1 AND B.convenio_uot_organizacion_id IS NULL
        WHERE T.evento_id = @Evento AND T.estado = 1 AND E.estado = 1
          AND I.estado = 1 AND I.estado_seguimiento = 'ABIERTA'
          AND A.uot_id = @Uot;

        IF @Actividad IS NULL
            THROW 51102, N'El tratamiento no está disponible para retirar.', 1;

        UPDATE prod.GPIncidenciaTratamiento
        SET estado = 0
        WHERE evento_id = @Evento AND estado = 1;
        IF @@ROWCOUNT <> 1
            THROW 51103, N'El tratamiento ya fue retirado.', 1;

        UPDATE prod.GPEvento
        SET estado = 0
        WHERE evento_id = @Evento AND estado = 1;

        -- Conserva el consumo histórico y documenta la operación sin devolver inventario.
        INSERT prod.GPEvento (
            actividad_id, tipo, respuesta_a_id, observacion,
            fecha_hecho, usuario_creacion_id, solicitud_id
        )
        VALUES (
            @Actividad, 'OBSERVACION', @Evento,
            CONCAT(N'Retiro lógico de tratamiento #', @Evento, N'. Motivo: ', TRIM(@Motivo)),
            SYSUTCDATETIME(), @Usuario, @Solicitud
        );

        COMMIT TRANSACTION;
        SELECT @Evento AS id;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
