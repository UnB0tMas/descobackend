IF OBJECT_ID(N'[comercial].[PA_HorarioAtencionPOS_Ejecutar]', N'P') IS NOT NULL
    DROP PROCEDURE comercial.PA_HorarioAtencionPOS_Ejecutar;
GO

-- Previsualiza cambios y actualiza atención/turnos de forma atómica por UOT.
CREATE PROCEDURE comercial.PA_HorarioAtencionPOS_Ejecutar
    @cAccion VARCHAR(15),
    @nUsuarioId BIGINT,
    @nUotId BIGINT,
    @cModo VARCHAR(15),
    @nDiaSemana TINYINT = NULL,
    @tHoraInicio TIME(0) = NULL,
    @tHoraFin TIME(0) = NULL,
    @bAjustar BIT = 0,
    @cVistaConfirmada NVARCHAR(MAX) = NULL,
    @bExitoso BIT OUTPUT,
    @cMensaje NVARCHAR(200) OUTPUT,
    @cCodigo VARCHAR(60) OUTPUT,
    @nHttp SMALLINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT @bExitoso = 0,
           @cMensaje = N'Revisa el horario seleccionado.',
           @cCodigo = 'ATENCION_DATOS',
           @nHttp = 400;

    IF @cAccion NOT IN ('PREVISUALIZAR', 'APLICAR')
       OR @cModo NOT IN ('GENERAL', 'PERSONALIZAR', 'HEREDAR')
       OR @nUotId IS NULL OR @nUotId <= 0
       OR (@cModo = 'GENERAL' AND @nDiaSemana IS NOT NULL)
       OR (@cModo <> 'GENERAL' AND (@nDiaSemana IS NULL OR @nDiaSemana NOT BETWEEN 1 AND 7))
       OR (@cModo <> 'HEREDAR' AND (@tHoraInicio IS NULL OR @tHoraFin IS NULL OR @tHoraInicio >= @tHoraFin))
        RETURN;

    IF ISNULL(seg.FN_Usuario_TienePermisoUOT(@nUsuarioId, @nUotId, 'HORARIO_COMERCIAL_CONFIGURAR'), 0) <> 1
    BEGIN
        SELECT @cMensaje = N'No tienes permiso para esta acción.',
               @cCodigo = 'ATENCION_PERMISO', @nHttp = 403;
        RETURN;
    END;

    BEGIN TRY
        IF @cAccion = 'APLICAR'
            BEGIN TRANSACTION;

        IF @cAccion = 'APLICAR'
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM org.UOT WITH (UPDLOCK, HOLDLOCK)
                           WHERE uot_id = @nUotId AND estado = 1)
            BEGIN
                SELECT @cMensaje = N'La unidad no está disponible.', @cCodigo = 'ATENCION_UOT', @nHttp = 404;
                ROLLBACK TRANSACTION;
                RETURN;
            END;
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM org.UOT WITH (NOLOCK) WHERE uot_id = @nUotId AND estado = 1)
        BEGIN
            SELECT @cMensaje = N'La unidad no está disponible.', @cCodigo = 'ATENCION_UOT', @nHttp = 404;
            RETURN;
        END;

        DECLARE @tGeneralInicio TIME(0) = '07:00';
        DECLARE @tGeneralFin TIME(0) = '20:00';
        SELECT @tGeneralInicio = A.hora_inicio, @tGeneralFin = A.hora_fin
        FROM comercial.HorarioAtencionUOT A
        WHERE A.uot_id = @nUotId;

        IF @cModo = 'HEREDAR'
        BEGIN
            SELECT @tHoraInicio = @tGeneralInicio, @tHoraFin = @tGeneralFin;
        END;

        DECLARE @Afectados TABLE
        (
            horarioId BIGINT NOT NULL PRIMARY KEY,
            empleadoId BIGINT NOT NULL,
            empleado NVARCHAR(250) NOT NULL,
            diaSemana INT NOT NULL,
            horaInicio VARCHAR(5) NOT NULL,
            horaFin VARCHAR(5) NOT NULL,
            nuevoInicio VARCHAR(5) NULL,
            nuevoFin VARCHAR(5) NULL,
            quitar BIT NOT NULL
        );

        INSERT INTO @Afectados
            (horarioId, empleadoId, empleado, diaSemana, horaInicio, horaFin, nuevoInicio, nuevoFin, quitar)
        SELECT H.horario_id,
               H.empleado_id,
               LTRIM(RTRIM(CONCAT(P.nombres, N' ', P.apellido_paterno, N' ', COALESCE(P.apellido_materno, N'')))),
               H.dia_semana,
               CONVERT(VARCHAR(5), H.hora_inicio, 108),
               CONVERT(VARCHAR(5), H.hora_fin, 108),
               CASE WHEN H.hora_inicio >= N.hasta OR H.hora_fin <= N.desde THEN NULL
                    ELSE CONVERT(VARCHAR(5), CASE WHEN H.hora_inicio < N.desde THEN N.desde ELSE H.hora_inicio END, 108) END,
               CASE WHEN H.hora_inicio >= N.hasta OR H.hora_fin <= N.desde THEN NULL
                    ELSE CONVERT(VARCHAR(5), CASE WHEN H.hora_fin > N.hasta THEN N.hasta ELSE H.hora_fin END, 108) END,
               CASE WHEN H.hora_inicio >= N.hasta OR H.hora_fin <= N.desde THEN 1 ELSE 0 END
        FROM comercial.HorarioEmpleadoPOS H
        JOIN org.Persona P ON P.persona_id = H.empleado_id
        LEFT JOIN comercial.HorarioAtencionDiaPOS D
            ON D.uot_id = H.uot_id AND D.dia_semana = H.dia_semana
        CROSS APPLY (SELECT
            CASE WHEN @cModo = 'GENERAL' THEN COALESCE(D.hora_inicio, @tHoraInicio)
                 ELSE @tHoraInicio END AS desde,
            CASE WHEN @cModo = 'GENERAL' THEN COALESCE(D.hora_fin, @tHoraFin)
                 ELSE @tHoraFin END AS hasta) N
        WHERE H.uot_id = @nUotId
          AND (@cModo = 'GENERAL' OR H.dia_semana = @nDiaSemana)
          AND (H.hora_inicio < N.desde OR H.hora_fin > N.hasta);

        IF @cAccion = 'PREVISUALIZAR'
        BEGIN
            SELECT @bExitoso = 1, @cCodigo = 'ATENCION_PREVIA',
                   @cMensaje = N'Consulta realizada.', @nHttp = 200;
            SELECT horarioId, empleadoId, empleado, diaSemana, horaInicio, horaFin,
                   nuevoInicio, nuevoFin, quitar
            FROM @Afectados
            ORDER BY diaSemana, empleado, horarioId;
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM @Afectados)
        BEGIN
            IF ISNULL(@bAjustar, 0) <> 1
            BEGIN
                SELECT @cCodigo = 'ATENCION_CONFLICTO', @nHttp = 409,
                       @cMensaje = N'Hay empleados con horarios fuera de la nueva atención.';
                ROLLBACK TRANSACTION;
                RETURN;
            END;
            IF ISNULL(seg.FN_Usuario_TienePermisoUOT(@nUsuarioId, @nUotId, 'PERSONAL_COMERCIAL_EDITAR'), 0) <> 1
            BEGIN
                SELECT @cCodigo = 'ATENCION_EDITAR_PERMISO', @nHttp = 403,
                       @cMensaje = N'No tienes permiso para ajustar los turnos afectados.';
                ROLLBACK TRANSACTION;
                RETURN;
            END;

            -- Impedir que una previsualización antigua ajuste asignaciones cambiadas por otro usuario.
            IF ISJSON(@cVistaConfirmada) <> 1
               OR EXISTS (
                   SELECT X.horarioId, X.horaInicio, X.horaFin FROM @Afectados X
                   EXCEPT
                   SELECT E.horarioId, E.horaInicio, E.horaFin
                   FROM OPENJSON(@cVistaConfirmada)
                   WITH (horarioId BIGINT '$.horarioId', horaInicio VARCHAR(5) '$.horaInicio',
                         horaFin VARCHAR(5) '$.horaFin') E
               )
               OR EXISTS (
                   SELECT E.horarioId, E.horaInicio, E.horaFin
                   FROM OPENJSON(@cVistaConfirmada)
                   WITH (horarioId BIGINT '$.horarioId', horaInicio VARCHAR(5) '$.horaInicio',
                         horaFin VARCHAR(5) '$.horaFin') E
                   EXCEPT
                   SELECT X.horarioId, X.horaInicio, X.horaFin FROM @Afectados X
               )
            BEGIN
                SELECT @cCodigo = 'ATENCION_CAMBIO_CONCURRENTE', @nHttp = 409,
                       @cMensaje = N'Los horarios han cambiado. Vuelve a revisar las asignaciones.';
                ROLLBACK TRANSACTION;
                RETURN;
            END;

            -- Los tramos sin intersección se retiran únicamente con confirmación explícita.
            DELETE H
            FROM comercial.HorarioEmpleadoPOS H
            JOIN @Afectados X ON X.horarioId = H.horario_id
            WHERE X.quitar = 1;

            UPDATE H
            SET H.hora_inicio = CONVERT(TIME(0), X.nuevoInicio),
                H.hora_fin = CONVERT(TIME(0), X.nuevoFin)
            FROM comercial.HorarioEmpleadoPOS H
            JOIN @Afectados X ON X.horarioId = H.horario_id
            WHERE X.quitar = 0;
        END;

        IF @cModo = 'GENERAL'
        BEGIN
            UPDATE A
            SET A.hora_inicio = @tHoraInicio, A.hora_fin = @tHoraFin,
                A.usuario_actualizacion_id = @nUsuarioId, A.fecha_actualizacion = SYSUTCDATETIME()
            FROM comercial.HorarioAtencionUOT A
            WHERE A.uot_id = @nUotId AND (A.hora_inicio <> @tHoraInicio OR A.hora_fin <> @tHoraFin);

            IF NOT EXISTS (SELECT 1 FROM comercial.HorarioAtencionUOT WHERE uot_id = @nUotId)
                INSERT INTO comercial.HorarioAtencionUOT (uot_id, hora_inicio, hora_fin, usuario_actualizacion_id)
                VALUES (@nUotId, @tHoraInicio, @tHoraFin, @nUsuarioId);
        END
        ELSE IF @cModo = 'HEREDAR'
        BEGIN
            DELETE FROM comercial.HorarioAtencionDiaPOS
            WHERE uot_id = @nUotId AND dia_semana = @nDiaSemana;
        END
        ELSE
        BEGIN
            UPDATE D
            SET D.hora_inicio = @tHoraInicio, D.hora_fin = @tHoraFin,
                D.usuario_actualizacion_id = @nUsuarioId, D.fecha_actualizacion = SYSUTCDATETIME()
            FROM comercial.HorarioAtencionDiaPOS D
            WHERE D.uot_id = @nUotId AND D.dia_semana = @nDiaSemana
              AND (D.hora_inicio <> @tHoraInicio OR D.hora_fin <> @tHoraFin);

            IF NOT EXISTS (SELECT 1 FROM comercial.HorarioAtencionDiaPOS
                           WHERE uot_id = @nUotId AND dia_semana = @nDiaSemana)
                INSERT INTO comercial.HorarioAtencionDiaPOS
                    (uot_id, dia_semana, hora_inicio, hora_fin, usuario_actualizacion_id)
                VALUES (@nUotId, @nDiaSemana, @tHoraInicio, @tHoraFin, @nUsuarioId);
        END;

        COMMIT TRANSACTION;
        SELECT @bExitoso = 1, @cMensaje = N'Horario de atención actualizado.',
               @cCodigo = 'ATENCION_GUARDADA', @nHttp = 200;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SELECT @bExitoso = 0, @cCodigo = 'ATENCION_SQL_ERROR', @nHttp = 503,
               @cMensaje = N'No se pudo guardar el horario.';
        THROW;
    END CATCH;
END;
GO
