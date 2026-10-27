IF OBJECT_ID(N'[logistica].[PA_BienInventario_Ins_CambioEstado]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_BienInventario_Ins_CambioEstado];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_BienInventario_Ins_CambioEstado
' Descripción             : Registra un cambio de estado de un bien de inventario.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo: sustituir identificadores y valores por datos válidos.
    DECLARE
        @bResultado BIT,
        @cMensaje NVARCHAR(300);
    EXEC [logistica].[PA_BienInventario_Ins_CambioEstado]
        @nUsuarioId = 0,
        @nBienInventarioId = 0,
        @cEstadoBien = '',
        @cMotivo = N'',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE [logistica].[PA_BienInventario_Ins_CambioEstado]
    @nUsuarioId BIGINT,
    @nBienInventarioId BIGINT,
    @cEstadoBien VARCHAR(20),
    @cMotivo NVARCHAR(500) = NULL,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT
        @bResultado = 0,
        @cMensaje = N'No se pudo cambiar el estado del recurso.';

    SELECT
        @cEstadoBien = UPPER(NULLIF(LTRIM(RTRIM(@cEstadoBien)), '')),
        @cMotivo = NULLIF(LTRIM(RTRIM(@cMotivo)), N'');

    IF @cEstadoBien NOT IN
       (
           'DISPONIBLE',
           'ASIGNADO',
           'MANTENIMIENTO',
           'AVERIADO',
           'INACTIVO',
           'BAJA',
           'NO_DISPONIBLE'
       )
    BEGIN
        SET @cMensaje = N'El estado del recurso no es válido.';
        RETURN 1;
    END;

    IF @cMotivo IS NULL
    BEGIN
        SET @cMensaje = N'Indique el motivo del cambio de estado.';
        RETURN 1;
    END;

    DECLARE
        @nUotId BIGINT,
        @cEstadoActual VARCHAR(20),
        @bActivo BIT,
        @nTranEntrada INT = @@TRANCOUNT,
        @dAhora DATETIME2(0) = SYSUTCDATETIME();

    SELECT
        @nUotId = uot_id,
        @cEstadoActual = estado_bien,
        @bActivo = estado
    FROM [logistica].[BienInventario]
    WHERE bien_inventario_id = @nBienInventarioId;

    IF @nUotId IS NULL
    BEGIN
        SET @cMensaje = N'El recurso no está disponible.';
        RETURN 1;
    END;

    IF [seg].[FN_Usuario_TienePermisoUOT]
       (
           @nUsuarioId,
           @nUotId,
           'INVENTARIO_EDITAR'
       ) = 0
    BEGIN
        SET @cMensaje = N'No tiene permiso para modificar este recurso.';
        RETURN 1;
    END;

    IF @cEstadoBien = 'ASIGNADO'
       AND EXISTS
       (
           SELECT 1
           FROM [logistica].[BienIncidente]
           WHERE bien_inventario_id = @nBienInventarioId
             AND estado = 1
             AND estado_incidente IN ('ABIERTO', 'EN_ATENCION')
       )
    BEGIN
        SET @cMensaje = N'No puede asignar un bien con incidencias abiertas.';
        RETURN 1;
    END;

    IF ISNULL(@bActivo, 0) = 0
       AND @cEstadoActual <> 'BAJA'
    BEGIN
        SET @cMensaje = N'El recurso no está disponible para cambiar de estado.';
        RETURN 1;
    END;

    BEGIN TRY
        IF @nTranEntrada = 0
            BEGIN TRANSACTION;
        ELSE
            SAVE TRANSACTION BIEN_STATE_SAVE;

        IF @cEstadoActual <> @cEstadoBien
        BEGIN
            UPDATE [logistica].[BienEstadoHistorial]
               SET fecha_hasta = COALESCE(fecha_hasta, @dAhora),
                   estado = 0
             WHERE bien_inventario_id = @nBienInventarioId
               AND estado = 1
               AND fecha_hasta IS NULL;

            INSERT [logistica].[BienEstadoHistorial]
            (
                bien_inventario_id,
                estado_bien,
                fecha_desde,
                motivo,
                usuario_id,
                estado
            )
            VALUES
            (
                @nBienInventarioId,
                @cEstadoBien,
                @dAhora,
                @cMotivo,
                @nUsuarioId,
                1
            );

            UPDATE [logistica].[BienInventario]
               SET estado_bien = @cEstadoBien,
                   estado =
                       CASE
                           WHEN @cEstadoBien = 'BAJA' THEN 0
                           ELSE 1
                       END
             WHERE bien_inventario_id = @nBienInventarioId;
        END;

        /*
         * MANTENIMIENTO es una situación operativa, no solo una etiqueta:
         * abre o pone en atención una incidencia de mantenimiento.
         */
        IF @cEstadoBien = 'MANTENIMIENTO'
        BEGIN
            UPDATE [logistica].[BienIncidente]
               SET estado_incidente = 'EN_ATENCION'
             WHERE bien_inventario_id = @nBienInventarioId
               AND estado = 1
               AND estado_incidente = 'ABIERTO'
               AND tipo_incidente IN
                   ('AVERIA', 'ACCIDENTE', 'MANTENIMIENTO');

            IF NOT EXISTS
            (
                SELECT 1
                FROM [logistica].[BienIncidente]
                WHERE bien_inventario_id = @nBienInventarioId
                  AND tipo_incidente = 'MANTENIMIENTO'
                  AND estado = 1
                  AND estado_incidente IN ('ABIERTO', 'EN_ATENCION')
            )
            BEGIN
                INSERT [logistica].[BienIncidente]
                (
                    bien_inventario_id,
                    tipo_incidente,
                    fecha_hora,
                    descripcion,
                    costo_estimado,
                    estado_incidente,
                    usuario_reporte_id,
                    estado
                )
                VALUES
                (
                    @nBienInventarioId,
                    'MANTENIMIENTO',
                    @dAhora,
                    @cMotivo,
                    NULL,
                    'EN_ATENCION',
                    @nUsuarioId,
                    1
                );
            END;
        END;

        /*
         * Si se marca AVERIADO manualmente y no existe una incidencia
         * operativa, se crea una para conservar trazabilidad.
         */
        IF @cEstadoBien = 'AVERIADO'
           AND NOT EXISTS
           (
               SELECT 1
               FROM [logistica].[BienIncidente]
               WHERE bien_inventario_id = @nBienInventarioId
                 AND tipo_incidente IN ('AVERIA', 'ACCIDENTE')
                 AND estado = 1
                 AND estado_incidente IN ('ABIERTO', 'EN_ATENCION')
           )
        BEGIN
            INSERT [logistica].[BienIncidente]
            (
                bien_inventario_id,
                tipo_incidente,
                fecha_hora,
                descripcion,
                costo_estimado,
                estado_incidente,
                usuario_reporte_id,
                estado
            )
            VALUES
            (
                @nBienInventarioId,
                'AVERIA',
                @dAhora,
                @cMotivo,
                NULL,
                'ABIERTO',
                @nUsuarioId,
                1
            );
        END;

        /*
         * Volver a DISPONIBLE significa que el evento operativo terminó.
         */
        IF @cEstadoBien = 'DISPONIBLE'
        BEGIN
            UPDATE [logistica].[BienIncidente]
               SET estado_incidente = 'RESUELTO',
                   fecha_cierre = COALESCE(fecha_cierre, @dAhora),
                   usuario_cierre_id =
                       COALESCE(usuario_cierre_id, @nUsuarioId),
                   solucion =
                       COALESCE(NULLIF(solucion, N''), @cMotivo)
             WHERE bien_inventario_id = @nBienInventarioId
               AND estado = 1
               AND estado_incidente IN ('ABIERTO', 'EN_ATENCION');
        END;

        /*
         * La BAJA cierra definitivamente cualquier incidencia pendiente.
         */
        IF @cEstadoBien = 'BAJA'
        BEGIN
            UPDATE [logistica].[BienIncidente]
               SET estado_incidente = 'CERRADO',
                   fecha_cierre = COALESCE(fecha_cierre, @dAhora),
                   usuario_cierre_id =
                       COALESCE(usuario_cierre_id, @nUsuarioId),
                   solucion =
                       COALESCE(
                           NULLIF(solucion, N''),
                           N'Incidencia cerrada por baja del bien. '
                           + @cMotivo
                       )
             WHERE bien_inventario_id = @nBienInventarioId
               AND estado = 1
               AND estado_incidente IN ('ABIERTO', 'EN_ATENCION');
        END;

        IF @nTranEntrada = 0
            COMMIT TRANSACTION;

        SELECT
            @bResultado = 1,
            @cMensaje =
                CASE
                    WHEN @cEstadoActual = @cEstadoBien
                        THEN N'El recurso ya se encuentra en el estado indicado.'
                    ELSE N'Estado del recurso actualizado correctamente.'
                END;

        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            IF @nTranEntrada = 0
                ROLLBACK TRANSACTION;
            ELSE IF XACT_STATE() = 1
                ROLLBACK TRANSACTION BIEN_STATE_SAVE;
        END;

        SET @bResultado = 0;
        SET @cMensaje =
            N'No se pudo cambiar el estado del recurso. Intente nuevamente.';

        RETURN 1;
    END CATCH;
END;
GO
