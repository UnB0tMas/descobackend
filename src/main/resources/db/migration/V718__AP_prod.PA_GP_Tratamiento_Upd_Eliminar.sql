IF OBJECT_ID(N'[prod].[PA_GP_Tratamiento_Upd_Eliminar]', N'P') IS NOT NULL
    DROP PROCEDURE [prod].[PA_GP_Tratamiento_Upd_Eliminar];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- Corrección de tratamiento erróneo: retiro lógico y devolución transaccional.
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
                FROM prod.GPEvento E WITH (NOLOCK)
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
          AND T.fecha_fin_real IS NULL
          AND I.estado = 1 AND I.estado_seguimiento = 'ABIERTA'
          AND A.uot_id = @Uot;

        IF @Actividad IS NULL
            THROW 51102, N'El tratamiento no está disponible para retirar.', 1;

        -- Si se consumió un producto por equivocación, revierte el consumo
        -- y registra la devolución física mediante el PA existente de Logística.
        -- Ambas operaciones y la marca de eliminación quedan en la misma transacción.
        DECLARE @Programa BIGINT, @Cantidad DECIMAL(19,3),
                @EventoDevolucion BIGINT, @DevolucionCorrecta BIT,
                @MensajeDevolucion NVARCHAR(300);

        SELECT @Programa = U.programacion_producto_id,
               @Cantidad = U.cantidad
        FROM logistica.UsoProductoTecnico U WITH (UPDLOCK, HOLDLOCK)
        WHERE U.tipo_origen = 'GP'
          AND U.registro_id = @Evento;

        IF @Programa IS NOT NULL
        BEGIN
            UPDATE P
            SET P.cantidad_consumida = P.cantidad_consumida - @Cantidad,
                P.estado_proceso = 'ENTREGADA'
            FROM logistica.ProgramacionProducto P WITH (UPDLOCK, HOLDLOCK)
            WHERE P.programacion_producto_id = @Programa
              AND P.uot_id = @Uot
              AND P.estado_proceso IN ('ENTREGADA', 'FINALIZADA')
              AND P.cantidad_consumida >= @Cantidad
              AND P.cantidad_entregada >= P.cantidad_devuelta + P.cantidad_consumida;

            IF @@ROWCOUNT <> 1
                THROW 51103, N'No se pudo revertir el consumo del producto.', 1;

            -- Compensa también la cantidad consumida en el historial del recurso.
            INSERT logistica.ProgramacionProductoEvento (
                programacion_producto_id, tipo_evento, cantidad,
                usuario_id, clave_idempotencia, observacion
            )
            VALUES (
                @Programa, 'REVERTIR_CONSUMO', @Cantidad, @Usuario, NEWID(),
                CONCAT(N'Consumo erróneo de tratamiento #', @Evento)
            );

            -- El movimiento de devolución compensa la salida real del almacén.
            -- Se reutiliza el control de stock, permisos y kardex existente.
            EXEC logistica.PA_ProgramacionProducto_Ins_Operacion
                @nUsuarioId = @Usuario,
                @nProgramacionId = @Programa,
                @cOperacion = 'DEVOLVER',
                @nCantidad = @Cantidad,
                @cObservacion = N'Corrección de tratamiento registrado por error.',
                @gClaveIdempotencia = @Solicitud,
                @nEventoId = @EventoDevolucion OUTPUT,
                @bResultado = @DevolucionCorrecta OUTPUT,
                @cMensaje = @MensajeDevolucion OUTPUT;

            IF ISNULL(@DevolucionCorrecta, 0) <> 1 OR @EventoDevolucion IS NULL
                THROW 51103, N'No se pudo devolver el producto al almacén.', 1;
        END;

        UPDATE prod.GPIncidenciaTratamiento
        SET estado = 0
        WHERE evento_id = @Evento AND estado = 1;
        IF @@ROWCOUNT <> 1
            THROW 51103, N'El tratamiento ya fue retirado.', 1;

        UPDATE prod.GPEvento
        SET estado = 0
        WHERE evento_id = @Evento AND estado = 1;

        -- Mantiene los movimientos originales para auditoría y agrega su devolución.
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
