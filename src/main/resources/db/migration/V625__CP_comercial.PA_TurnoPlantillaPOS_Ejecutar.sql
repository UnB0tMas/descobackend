IF OBJECT_ID(N'[comercial].[PA_TurnoPlantillaPOS_Ejecutar]', N'P') IS NOT NULL
    DROP PROCEDURE comercial.PA_TurnoPlantillaPOS_Ejecutar;
GO

-- Consulta y mantiene turnos reutilizables sin modificar asignaciones del personal.
CREATE PROCEDURE comercial.PA_TurnoPlantillaPOS_Ejecutar
    @cAccion VARCHAR(12),
    @nUsuarioId BIGINT,
    @nUotId BIGINT,
    @nPlantillaId BIGINT = NULL,
    @cNombre NVARCHAR(80) = NULL,
    @tHoraInicio TIME(0) = NULL,
    @tHoraFin TIME(0) = NULL,
    @bExitoso BIT OUTPUT,
    @cMensaje NVARCHAR(200) OUTPUT,
    @cCodigo VARCHAR(60) OUTPUT,
    @nHttp SMALLINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT @bExitoso = 0,
           @cMensaje = N'No se pudo completar la solicitud.',
           @cCodigo = 'TURNO_INVALIDO',
           @nHttp = 400;

    IF @cAccion NOT IN ('LISTAR', 'GUARDAR', 'DESACTIVAR') OR @nUotId IS NULL OR @nUotId <= 0
        RETURN;

    DECLARE @cPermiso VARCHAR(60) = CASE WHEN @cAccion = 'LISTAR'
        THEN 'PERSONAL_COMERCIAL_LISTAR' ELSE 'HORARIO_COMERCIAL_CONFIGURAR' END;

    IF ISNULL(seg.FN_Usuario_TienePermisoUOT(@nUsuarioId, @nUotId, @cPermiso), 0) <> 1
    BEGIN
        SELECT @cMensaje = N'No tienes permisos para esta acción.', @cCodigo = 'TURNO_SIN_PERMISO', @nHttp = 403;
        RETURN;
    END;

    IF @cAccion = 'LISTAR'
    BEGIN
        SELECT @bExitoso = 1, @cMensaje = N'Consulta realizada.', @cCodigo = 'TURNO_LISTADO', @nHttp = 200;
        SELECT T.turno_plantilla_id AS plantillaId,
               T.nombre AS nombre,
               CONVERT(VARCHAR(5), T.hora_inicio, 108) AS horaInicio,
               CONVERT(VARCHAR(5), T.hora_fin, 108) AS horaFin
        FROM comercial.TurnoPlantillaPOS T WITH (NOLOCK)
        WHERE T.uot_id = @nUotId AND T.estado = 1
        ORDER BY T.hora_inicio, T.nombre, T.turno_plantilla_id;
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM org.UOT U WITH (UPDLOCK, HOLDLOCK)
                       WHERE U.uot_id = @nUotId AND U.estado = 1)
        BEGIN
            SELECT @cMensaje = N'La unidad no está disponible.', @cCodigo = 'TURNO_UOT', @nHttp = 404;
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        IF @cAccion = 'DESACTIVAR'
        BEGIN
            UPDATE T
            SET T.estado = 0,
                T.usuario_actualizacion_id = @nUsuarioId,
                T.fecha_actualizacion = SYSUTCDATETIME()
            FROM comercial.TurnoPlantillaPOS T
            WHERE T.turno_plantilla_id = @nPlantillaId AND T.uot_id = @nUotId AND T.estado = 1;

            IF @@ROWCOUNT <> 1
            BEGIN
                SELECT @cMensaje = N'El turno ya no está disponible.', @cCodigo = 'TURNO_NO_EXISTE', @nHttp = 404;
                ROLLBACK TRANSACTION;
                RETURN;
            END;
        END
        ELSE
        BEGIN
            SET @cNombre = NULLIF(LTRIM(RTRIM(@cNombre)), N'');
            IF @cNombre IS NULL OR LEN(@cNombre) < 2 OR LEN(@cNombre) > 80
               OR @tHoraInicio IS NULL OR @tHoraFin IS NULL OR @tHoraInicio >= @tHoraFin
            BEGIN
                SELECT @cMensaje = N'Revisa el nombre y las horas.', @cCodigo = 'TURNO_DATOS', @nHttp = 400;
                ROLLBACK TRANSACTION;
                RETURN;
            END;

            DECLARE @tApertura TIME(0) = '07:00', @tCierre TIME(0) = '20:00';
            SELECT @tApertura = A.hora_inicio, @tCierre = A.hora_fin
            FROM comercial.HorarioAtencionUOT A WITH (UPDLOCK, HOLDLOCK)
            WHERE A.uot_id = @nUotId;

            IF @tHoraInicio < @tApertura OR @tHoraFin > @tCierre
            BEGIN
                SELECT @cMensaje = N'El turno debe estar dentro del horario de atención.',
                       @cCodigo = 'TURNO_FUERA_RANGO', @nHttp = 400;
                ROLLBACK TRANSACTION;
                RETURN;
            END;

            IF EXISTS (SELECT 1 FROM comercial.TurnoPlantillaPOS T WITH (UPDLOCK, HOLDLOCK)
                       WHERE T.uot_id = @nUotId AND T.estado = 1 AND T.nombre = @cNombre
                         AND (@nPlantillaId IS NULL OR T.turno_plantilla_id <> @nPlantillaId))
            BEGIN
                SELECT @cMensaje = N'Ya existe un turno con ese nombre.', @cCodigo = 'TURNO_REPETIDO', @nHttp = 409;
                ROLLBACK TRANSACTION;
                RETURN;
            END;

            IF @nPlantillaId IS NULL
            BEGIN
                INSERT INTO comercial.TurnoPlantillaPOS
                    (uot_id, nombre, hora_inicio, hora_fin, usuario_registro_id)
                VALUES (@nUotId, @cNombre, @tHoraInicio, @tHoraFin, @nUsuarioId);
            END
            ELSE
            BEGIN
                UPDATE T
                SET T.nombre = @cNombre,
                    T.hora_inicio = @tHoraInicio,
                    T.hora_fin = @tHoraFin,
                    T.usuario_actualizacion_id = @nUsuarioId,
                    T.fecha_actualizacion = SYSUTCDATETIME()
                FROM comercial.TurnoPlantillaPOS T
                WHERE T.turno_plantilla_id = @nPlantillaId AND T.uot_id = @nUotId AND T.estado = 1;

                IF @@ROWCOUNT <> 1
                BEGIN
                    SELECT @cMensaje = N'El turno ya no está disponible.', @cCodigo = 'TURNO_NO_EXISTE', @nHttp = 404;
                    ROLLBACK TRANSACTION;
                    RETURN;
                END;
            END;
        END;

        COMMIT TRANSACTION;
        SELECT @bExitoso = 1,
               @cMensaje = N'Turno actualizado.',
               @cCodigo = 'TURNO_OK',
               @nHttp = 200;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
