IF OBJECT_ID(N'[logistica].[PA_BienInventario_Ins_Incidente]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_BienInventario_Ins_Incidente];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_BienInventario_Ins_Incidente
' Descripción             : Registra un incidente asociado a un bien de inventario.
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
        @nBienIncidenteId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300);
    EXEC [logistica].[PA_BienInventario_Ins_Incidente]
        @nUsuarioId = 0,
        @nBienInventarioId = 0,
        @cTipo = '',
        @dFechaHora = '2026-10-11',
        @cDescripcion = N'',
        @nCostoEstimado = 0,
        @nBienIncidenteId = @nBienIncidenteId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @nBienIncidenteId, @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE [logistica].[PA_BienInventario_Ins_Incidente]
    @nUsuarioId BIGINT,
    @nBienInventarioId BIGINT,
    @cTipo VARCHAR(30),
    @dFechaHora DATETIME2(0),
    @cDescripcion NVARCHAR(700),
    @nCostoEstimado DECIMAL(19,4) = NULL,
    @nBienIncidenteId BIGINT OUTPUT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT
        @nBienIncidenteId = NULL,
        @bResultado = 0,
        @cMensaje = N'No se pudo registrar el incidente.';

    SELECT
        @cTipo = UPPER(NULLIF(LTRIM(RTRIM(@cTipo)), '')),
        @cDescripcion = NULLIF(LTRIM(RTRIM(@cDescripcion)), N'');

    DECLARE
        @nUotId BIGINT,
        @cEstadoObjetivo VARCHAR(20),
        @bCambioEstado BIT,
        @cMensajeEstado NVARCHAR(300),
        @nTranEntrada INT = @@TRANCOUNT;

    SELECT @nUotId = uot_id
    FROM [logistica].[BienInventario]
    WHERE bien_inventario_id = @nBienInventarioId
      AND estado = 1
      AND estado_bien <> 'BAJA';

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
        SET @cMensaje =
            N'No tiene permiso para registrar incidentes en este recurso.';
        RETURN 1;
    END;

    IF @dFechaHora IS NULL
       OR @dFechaHora > SYSUTCDATETIME()
    BEGIN
        SET @cMensaje = N'La fecha del incidente no es válida.';
        RETURN 1;
    END;

    IF @cTipo NOT IN
       ('AVERIA', 'ACCIDENTE', 'PERDIDA', 'ROBO', 'MANTENIMIENTO', 'OTRO')
       OR @cDescripcion IS NULL
       OR (@nCostoEstimado IS NOT NULL AND @nCostoEstimado < 0)
    BEGIN
        SET @cMensaje = N'Complete correctamente los datos del incidente.';
        RETURN 1;
    END;

    SET @cEstadoObjetivo =
        CASE
            WHEN @cTipo IN ('AVERIA', 'ACCIDENTE') THEN 'AVERIADO'
            WHEN @cTipo IN ('PERDIDA', 'ROBO') THEN 'NO_DISPONIBLE'
            WHEN @cTipo = 'MANTENIMIENTO' THEN 'MANTENIMIENTO'
            ELSE NULL
        END;

    BEGIN TRY
        IF @nTranEntrada = 0
            BEGIN TRANSACTION;
        ELSE
            SAVE TRANSACTION BIEN_INCIDENT_SAVE;

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
            @cTipo,
            @dFechaHora,
            @cDescripcion,
            @nCostoEstimado,
            CASE
                WHEN @cTipo = 'MANTENIMIENTO' THEN 'EN_ATENCION'
                ELSE 'ABIERTO'
            END,
            @nUsuarioId,
            1
        );

        SET @nBienIncidenteId =
            CONVERT(BIGINT, SCOPE_IDENTITY());

        /*
         * El tipo de incidencia gobierna el estado operativo del bien.
         */
        IF @cEstadoObjetivo IS NOT NULL
        BEGIN
            EXEC [logistica].[PA_BienInventario_Ins_CambioEstado]
                @nUsuarioId = @nUsuarioId,
                @nBienInventarioId = @nBienInventarioId,
                @cEstadoBien = @cEstadoObjetivo,
                @cMotivo = @cDescripcion,
                @bResultado = @bCambioEstado OUTPUT,
                @cMensaje = @cMensajeEstado OUTPUT;

            IF ISNULL(@bCambioEstado, 0) = 0
                THROW 51070,
                      N'No se pudo sincronizar el estado del bien.',
                      1;
        END;

        IF @nTranEntrada = 0
            COMMIT TRANSACTION;

        SELECT
            @bResultado = 1,
            @cMensaje = N'Incidente registrado correctamente.';

        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            IF @nTranEntrada = 0
                ROLLBACK TRANSACTION;
            ELSE IF XACT_STATE() = 1
                ROLLBACK TRANSACTION BIEN_INCIDENT_SAVE;
        END;

        SET @nBienIncidenteId = NULL;
        SET @bResultado = 0;
        SET @cMensaje =
            COALESCE(
                NULLIF(@cMensajeEstado, N''),
                N'No se pudo registrar el incidente. Intente nuevamente.'
            );

        RETURN 1;
    END CATCH;
END;
GO
