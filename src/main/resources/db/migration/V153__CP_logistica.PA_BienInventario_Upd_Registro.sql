IF OBJECT_ID(N'[logistica].[PA_BienInventario_Upd_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_BienInventario_Upd_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_BienInventario_Upd_Registro
' Descripción             : Actualiza los datos de bien de inventario.
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
    -- El JSON mostrado es ilustrativo y debe ajustarse al contrato del PA.
    DECLARE
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [logistica].[PA_BienInventario_Upd_Registro]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [logistica].[PA_BienInventario_Upd_Registro]
    @cJson NVARCHAR(MAX),
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60) = NULL OUTPUT,
    @nHttpRespuesta SMALLINT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT
        @bResultado = 0,
        @cMensaje = N'No se pudo actualizar el bien.',
        @cCodigoRespuesta = 'BIEN_NO_ACTUALIZADO',
        @nHttpRespuesta = 400;

    DECLARE
        @nUsuario BIGINT,
        @nSesion BIGINT,
        @nDisp BIGINT,
        @nEmp BIGINT,
        @nModulo INT,
        @gCorr UNIQUEIDENTIFIER,
        @gSol UNIQUEIDENTIFIER,
        @cIp VARCHAR(64),
        @cEnd NVARCHAR(250),
        @nOp BIGINT,
        @bRep BIT,
        @cEstadoOp VARCHAR(20),
        @cIdRes NVARCHAR(200),
        @cCodRes VARCHAR(40),
        @bIni BIT,
        @cMsg NVARCHAR(300),
        @bFin BIT,
        @cMsgFin NVARCHAR(300),
        @nAud BIGINT,
        @nTrans BIGINT,
        @nId BIGINT,
        @nUotId BIGINT,
        @nTipoBienId SMALLINT,
        @cNombre NVARCHAR(150),
        @cMarca NVARCHAR(80),
        @cModelo NVARCHAR(80),
        @cSerie NVARCHAR(100),
        @dFechaAdquisicion DATE,
        @nMontoAdquisicion DECIMAL(19,4),
        @cMoneda CHAR(3),
        @nProveedorPersonaId BIGINT,
        @nProveedorEmpresaId BIGINT,
        @cObservacion NVARCHAR(500),
        @nTranEntrada INT,
        @bTranAbierta BIT = 0,
        @cIdent NVARCHAR(200);

    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente]
        @cJson = @cJson,
        @cCodigoPermiso = 'INVENTARIO_EDITAR',
        @cAmbito = 'BIEN_EDITAR_SQL',
        @nUsuarioId = @nUsuario OUTPUT,
        @nSesionUsuarioId = @nSesion OUTPUT,
        @nDispositivoUsuarioId = @nDisp OUTPUT,
        @nEmpleadoId = @nEmp OUTPUT,
        @nModuloId = @nModulo OUTPUT,
        @gCorrelacionId = @gCorr OUTPUT,
        @gSolicitudId = @gSol OUTPUT,
        @cIp = @cIp OUTPUT,
        @cEndpoint = @cEnd OUTPUT,
        @nOperacionIdempotenteId = @nOp OUTPUT,
        @bEsRepetida = @bRep OUTPUT,
        @cEstadoOperacion = @cEstadoOp OUTPUT,
        @cIdentificadorResultado = @cIdRes OUTPUT,
        @cCodigoResultado = @cCodRes OUTPUT,
        @bResultado = @bIni OUTPUT,
        @cMensaje = @cMsg OUTPUT;

    IF ISNULL(@bIni, 0) = 0 AND ISNULL(@bRep, 0) = 0
    BEGIN
        SET @cMensaje = COALESCE(NULLIF(@cMsg, N''), @cMensaje);
        RETURN 1;
    END;

    IF ISNULL(@bRep, 0) = 1
    BEGIN
        IF @cEstadoOp = 'COMPLETADA'
        BEGIN
            SELECT
                @bResultado = 1,
                @cMensaje = N'La solicitud ya fue procesada correctamente.',
                @cCodigoRespuesta = 'BIEN_ACTUALIZADO',
                @nHttpRespuesta = 200;
            RETURN 0;
        END;

        SELECT @cMensaje = COALESCE(
            NULLIF(mensaje_resultado, N''),
            N'La solicitud anterior no se completó o todavía se está procesando.')
        FROM [auditoria].[OperacionIdempotente]
        WHERE operacion_idempotente_id = @nOp;
        SET @nHttpRespuesta = CASE WHEN @cEstadoOp = 'EN_PROCESO' THEN 409 ELSE 400 END;
        RETURN 1;
    END;

    SELECT
        @nId = COALESCE(
            TRY_CONVERT(BIGINT, JSON_VALUE(@cJson, '$.bien.bienInventarioId')),
            TRY_CONVERT(BIGINT, JSON_VALUE(@cJson, '$.bien.assetId'))
        ),
        @nTipoBienId = COALESCE(
            TRY_CONVERT(SMALLINT, JSON_VALUE(@cJson, '$.bien.tipoBienId')),
            TRY_CONVERT(SMALLINT, JSON_VALUE(@cJson, '$.bien.assetTypeId'))
        ),
        @cNombre = NULLIF(LTRIM(RTRIM(COALESCE(
            JSON_VALUE(@cJson, '$.bien.nombre'),
            JSON_VALUE(@cJson, '$.bien.name')
        ))), N''),
        @cMarca = NULLIF(LTRIM(RTRIM(COALESCE(JSON_VALUE(@cJson, '$.bien.marca'), JSON_VALUE(@cJson, '$.bien.brand')))), N''),
        @cModelo = NULLIF(LTRIM(RTRIM(COALESCE(JSON_VALUE(@cJson, '$.bien.modelo'), JSON_VALUE(@cJson, '$.bien.model')))), N''),
        @cSerie = NULLIF(LTRIM(RTRIM(COALESCE(JSON_VALUE(@cJson, '$.bien.serie'), JSON_VALUE(@cJson, '$.bien.serial')))), N''),
        @dFechaAdquisicion = COALESCE(
            TRY_CONVERT(DATE, JSON_VALUE(@cJson, '$.bien.fechaAdquisicion')),
            TRY_CONVERT(DATE, JSON_VALUE(@cJson, '$.bien.acquisitionDate'))
        ),
        @nMontoAdquisicion = COALESCE(
            TRY_CONVERT(DECIMAL(19,4), JSON_VALUE(@cJson, '$.bien.montoAdquisicion')),
            TRY_CONVERT(DECIMAL(19,4), JSON_VALUE(@cJson, '$.bien.acquisitionAmount'))
        ),
        @cMoneda = UPPER(NULLIF(LTRIM(RTRIM(COALESCE(JSON_VALUE(@cJson, '$.bien.moneda'), JSON_VALUE(@cJson, '$.bien.currency')))), '')),
        @nProveedorPersonaId = COALESCE(
            TRY_CONVERT(BIGINT, JSON_VALUE(@cJson, '$.bien.proveedorPersonaId')),
            TRY_CONVERT(BIGINT, JSON_VALUE(@cJson, '$.bien.providerPersonId'))
        ),
        @nProveedorEmpresaId = COALESCE(
            TRY_CONVERT(BIGINT, JSON_VALUE(@cJson, '$.bien.proveedorEmpresaId')),
            TRY_CONVERT(BIGINT, JSON_VALUE(@cJson, '$.bien.providerCompanyId'))
        ),
        @cObservacion = NULLIF(LTRIM(RTRIM(COALESCE(JSON_VALUE(@cJson, '$.bien.observacion'), JSON_VALUE(@cJson, '$.bien.observation')))), N'');

    IF @nMontoAdquisicion IS NOT NULL AND @cMoneda IS NULL
        SET @cMoneda = 'PEN';

    IF @nId IS NULL OR @nTipoBienId IS NULL OR @cNombre IS NULL
    BEGIN
        SET @cMensaje = N'Complete correctamente los datos del bien.';
        GOTO Fallar;
    END;

    SELECT @nUotId = uot_id
    FROM [logistica].[BienInventario]
    WHERE bien_inventario_id = @nId
      AND estado = 1
      AND estado_bien <> 'BAJA';

    IF @nUotId IS NULL
    BEGIN
        SET @cMensaje = N'El bien seleccionado no está disponible.';
        SET @nHttpRespuesta = 404;
        GOTO Fallar;
    END;

    IF [seg].[FN_Usuario_TienePermisoUOT](@nUsuario, @nUotId, 'INVENTARIO_EDITAR') = 0
    BEGIN
        SET @cMensaje = N'No tiene permiso para modificar este bien.';
        SET @nHttpRespuesta = 403;
        GOTO Fallar;
    END;

    IF NOT EXISTS (SELECT 1 FROM [logistica].[TipoBien] WHERE tipo_bien_id = @nTipoBienId AND estado = 1)
    BEGIN
        SET @cMensaje = N'El tipo de bien seleccionado no está disponible.';
        GOTO Fallar;
    END;

    IF @nProveedorPersonaId IS NOT NULL AND @nProveedorEmpresaId IS NOT NULL
    BEGIN
        SET @cMensaje = N'Seleccione solo una persona o una empresa como proveedor.';
        GOTO Fallar;
    END;

    IF @nProveedorPersonaId IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM [org].[Persona] WHERE persona_id = @nProveedorPersonaId AND estado = 1)
    BEGIN
        SET @cMensaje = N'El proveedor seleccionado no está disponible.';
        GOTO Fallar;
    END;

    IF @nProveedorEmpresaId IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM [org].[Empresa] WHERE empresa_id = @nProveedorEmpresaId AND estado = 1)
    BEGIN
        SET @cMensaje = N'El proveedor seleccionado no está disponible.';
        GOTO Fallar;
    END;

    IF @cMoneda IS NOT NULL AND (@cMoneda NOT LIKE '[A-Z][A-Z][A-Z]' OR LEN(@cMoneda) <> 3)
    BEGIN
        SET @cMensaje = N'La moneda seleccionada no es válida.';
        GOTO Fallar;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM [logistica].[RecursoProgramado]
        WHERE bien_inventario_id = @nId
          AND estado = 1
          AND estado_proceso = 'EN_EJECUCION'
    )
    BEGIN
        SET @cMensaje = N'El bien está asignado actualmente y no puede editarse desde esta opción.';
        SET @nHttpRespuesta = 409;
        GOTO Fallar;
    END;

    SET @nTranEntrada = @@TRANCOUNT;

    BEGIN TRY
        IF @nTranEntrada = 0
            BEGIN TRANSACTION;
        ELSE
            SAVE TRANSACTION BIEN_UPDATE_SAVE;
        SET @bTranAbierta = 1;

        UPDATE [logistica].[BienInventario]
        SET
            tipo_bien_id = @nTipoBienId,
            nombre = @cNombre,
            marca = @cMarca,
            modelo = @cModelo,
            serie = @cSerie,
            fecha_adquisicion = @dFechaAdquisicion,
            monto_adquisicion = @nMontoAdquisicion,
            moneda_adquisicion = @cMoneda,
            proveedor_persona_id = @nProveedorPersonaId,
            proveedor_empresa_id = @nProveedorEmpresaId,
            observacion = @cObservacion
        WHERE bien_inventario_id = @nId
          AND estado = 1
          AND estado_bien <> 'BAJA';

        IF @@ROWCOUNT = 0
            THROW 51004, 'DESCO_BIEN_NO_DISPONIBLE', 1;

        SET @cIdent = CONVERT(NVARCHAR(200), @nId);

        EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio]
            @nUsuario, @nSesion, @nDisp, @nModulo,
            'EDITAR', 'logistica', 'BienInventario', @cIdent,
            NULL, NULL, NULL, NULL, NULL, NULL,
            @cIp, @gCorr, @gSol, @cEnd,
            @nAud OUTPUT, @nTrans OUTPUT;

        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
            @nOperacionIdempotenteId = @nOp,
            @cEstadoOperacion = 'COMPLETADA',
            @cEsquemaEntidad = 'logistica',
            @cNombreEntidad = 'BienInventario',
            @cIdentificadorResultado = @cIdent,
            @cCodigoResultado = 'BIEN_ACTUALIZADO',
            @bResultado = @bFin OUTPUT,
            @cMensaje = @cMsgFin OUTPUT;

        IF ISNULL(@bFin, 0) = 0
            THROW 51003, 'DESCO_IDEMPOTENCIA_NO_CERRADA', 1;

        IF @nTranEntrada = 0
            COMMIT TRANSACTION;
        SET @bTranAbierta = 0;

        SELECT
            @bResultado = 1,
            @cMensaje = N'Bien actualizado correctamente.',
            @cCodigoRespuesta = 'BIEN_ACTUALIZADO',
            @nHttpRespuesta = 200;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @bTranAbierta = 1 AND XACT_STATE() <> 0
        BEGIN
            IF @nTranEntrada = 0
                ROLLBACK TRANSACTION;
            ELSE IF XACT_STATE() = 1
                ROLLBACK TRANSACTION BIEN_UPDATE_SAVE;
        END;
        SET @bTranAbierta = 0;
        SET @bResultado = 0;
        SET @cMensaje = N'No se pudo actualizar el bien. Intente nuevamente.';
        GOTO Fallar;
    END CATCH;

Fallar:
    IF @nOp IS NOT NULL AND ISNULL(@bRep, 0) = 0 AND XACT_STATE() <> -1
    BEGIN
        BEGIN TRY
            EXEC [auditoria].[PA_OperacionIdempotente_Upd_MensajeFallido]
                @nOperacionIdempotenteId = @nOp,
                @cMensajeResultado = @cMensaje;
        END TRY
        BEGIN CATCH
        END CATCH;
    END;

    IF @cCodigoRespuesta IS NULL SET @cCodigoRespuesta = 'BIEN_NO_ACTUALIZADO';
    IF @nHttpRespuesta IS NULL SET @nHttpRespuesta = 400;
    SET @bResultado = 0;
    RETURN 1;
END;
GO
