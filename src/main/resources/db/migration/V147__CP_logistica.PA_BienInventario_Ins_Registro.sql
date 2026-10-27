IF OBJECT_ID(N'[logistica].[PA_BienInventario_Ins_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_BienInventario_Ins_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_BienInventario_Ins_Registro
' Descripción             : Registra bien de inventario.
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
        @nBienInventarioId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [logistica].[PA_BienInventario_Ins_Registro]
        @cJson = N'{}',
        @nBienInventarioId = @nBienInventarioId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nBienInventarioId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [logistica].[PA_BienInventario_Ins_Registro]
    @cJson NVARCHAR(MAX),
    @nBienInventarioId BIGINT OUTPUT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60) = NULL OUTPUT,
    @nHttpRespuesta SMALLINT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT
        @nBienInventarioId = NULL,
        @bResultado = 0,
        @cMensaje = N'No se pudo registrar el bien.',
        @cCodigoRespuesta = 'BIEN_NO_CREADO',
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
        @nUotId BIGINT,
        @nEmpresaId BIGINT,
        @nTipoBienId SMALLINT,
        @cCodigoPatrimonial VARCHAR(60),
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

    /* Conserva validación de sesión, permiso, correlación y contexto técnico. */
    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente]
        @cJson = @cJson,
        @cCodigoPermiso = 'INVENTARIO_CREAR',
        @cAmbito = 'BIEN_CREAR_SQL',
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
        SET @cCodigoRespuesta = 'BIEN_NO_CREADO';
        SET @nHttpRespuesta = 400;
        RETURN 1;
    END;

    IF ISNULL(@bRep, 0) = 1
    BEGIN
        IF @cEstadoOp = 'COMPLETADA'
        BEGIN
            SET @nBienInventarioId = TRY_CONVERT(BIGINT, @cIdRes);
            SET @bResultado = CASE WHEN @nBienInventarioId IS NULL THEN 0 ELSE 1 END;
            SET @cMensaje = CASE WHEN @bResultado = 1
                THEN N'La solicitud ya fue procesada correctamente.'
                ELSE N'No se pudo recuperar el resultado anterior.' END;
            SET @cCodigoRespuesta = CASE WHEN @bResultado = 1 THEN 'BIEN_CREADO' ELSE 'BIEN_NO_CREADO' END;
            SET @nHttpRespuesta = CASE WHEN @bResultado = 1 THEN 201 ELSE 503 END;
            RETURN CASE WHEN @bResultado = 1 THEN 0 ELSE 1 END;
        END;

        SELECT @cMensaje = COALESCE(
            NULLIF(mensaje_resultado, N''),
            CASE WHEN estado_operacion = 'FALLIDA'
                 THEN N'La solicitud anterior no se completó. Corrija los datos y envíe una nueva solicitud.'
                 ELSE N'La solicitud todavía se está procesando. Intente nuevamente.' END)
        FROM [auditoria].[OperacionIdempotente]
        WHERE operacion_idempotente_id = @nOp;

        SET @cCodigoRespuesta = CASE WHEN @cEstadoOp = 'EN_PROCESO'
                                     THEN 'OPERACION_EN_PROCESO'
                                     ELSE 'BIEN_NO_CREADO' END;
        SET @nHttpRespuesta = CASE WHEN @cEstadoOp = 'EN_PROCESO' THEN 409 ELSE 400 END;
        RETURN 1;
    END;

    /* Se admiten nombres del contrato HTTP actual y alias internos en inglés. */
    SELECT
        @nUotId = COALESCE(
            TRY_CONVERT(BIGINT, JSON_VALUE(@cJson, '$.bien.uotId')),
            TRY_CONVERT(BIGINT, JSON_VALUE(@cJson, '$.bien.uotContextoId')),
            TRY_CONVERT(BIGINT, JSON_VALUE(@cJson, '$.bien.contextUotId')),
            TRY_CONVERT(BIGINT, JSON_VALUE(@cJson, '$.contexto.uotId')),
            TRY_CONVERT(BIGINT, JSON_VALUE(@cJson, '$.uotId'))
        ),
        @nTipoBienId = COALESCE(
            TRY_CONVERT(SMALLINT, JSON_VALUE(@cJson, '$.bien.tipoBienId')),
            TRY_CONVERT(SMALLINT, JSON_VALUE(@cJson, '$.bien.assetTypeId'))
        ),
        @cCodigoPatrimonial = UPPER(NULLIF(LTRIM(RTRIM(COALESCE(
            JSON_VALUE(@cJson, '$.bien.codigoPatrimonial'),
            JSON_VALUE(@cJson, '$.bien.patrimonialCode')
        ))), '')),
        @cNombre = NULLIF(LTRIM(RTRIM(COALESCE(
            JSON_VALUE(@cJson, '$.bien.nombre'),
            JSON_VALUE(@cJson, '$.bien.name')
        ))), N''),
        @cMarca = NULLIF(LTRIM(RTRIM(COALESCE(
            JSON_VALUE(@cJson, '$.bien.marca'),
            JSON_VALUE(@cJson, '$.bien.brand')
        ))), N''),
        @cModelo = NULLIF(LTRIM(RTRIM(COALESCE(
            JSON_VALUE(@cJson, '$.bien.modelo'),
            JSON_VALUE(@cJson, '$.bien.model')
        ))), N''),
        @cSerie = NULLIF(LTRIM(RTRIM(COALESCE(
            JSON_VALUE(@cJson, '$.bien.serie'),
            JSON_VALUE(@cJson, '$.bien.serial')
        ))), N''),
        @dFechaAdquisicion = COALESCE(
            TRY_CONVERT(DATE, JSON_VALUE(@cJson, '$.bien.fechaAdquisicion')),
            TRY_CONVERT(DATE, JSON_VALUE(@cJson, '$.bien.acquisitionDate'))
        ),
        @nMontoAdquisicion = COALESCE(
            TRY_CONVERT(DECIMAL(19,4), JSON_VALUE(@cJson, '$.bien.montoAdquisicion')),
            TRY_CONVERT(DECIMAL(19,4), JSON_VALUE(@cJson, '$.bien.acquisitionAmount'))
        ),
        @cMoneda = UPPER(NULLIF(LTRIM(RTRIM(COALESCE(
            JSON_VALUE(@cJson, '$.bien.moneda'),
            JSON_VALUE(@cJson, '$.bien.currency')
        ))), '')),
        @nProveedorPersonaId = COALESCE(
            TRY_CONVERT(BIGINT, JSON_VALUE(@cJson, '$.bien.proveedorPersonaId')),
            TRY_CONVERT(BIGINT, JSON_VALUE(@cJson, '$.bien.providerPersonId'))
        ),
        @nProveedorEmpresaId = COALESCE(
            TRY_CONVERT(BIGINT, JSON_VALUE(@cJson, '$.bien.proveedorEmpresaId')),
            TRY_CONVERT(BIGINT, JSON_VALUE(@cJson, '$.bien.providerCompanyId'))
        ),
        @cObservacion = NULLIF(LTRIM(RTRIM(COALESCE(
            JSON_VALUE(@cJson, '$.bien.observacion'),
            JSON_VALUE(@cJson, '$.bien.observation')
        ))), N'');

    IF @nMontoAdquisicion IS NOT NULL AND @cMoneda IS NULL
        SET @cMoneda = 'PEN';

    IF @nUotId IS NULL OR @nTipoBienId IS NULL OR @cNombre IS NULL
    BEGIN
        SET @cMensaje = N'Complete correctamente los datos requeridos del bien.';
        GOTO Fallar;
    END;

    SELECT @nEmpresaId = U.empresa_legacy_id
    FROM [org].[UOT] U
    WHERE U.uot_id = @nUotId
      AND U.estado = 1;

    IF @nEmpresaId IS NULL
       OR NOT EXISTS (SELECT 1 FROM [org].[Empresa] WHERE empresa_id = @nEmpresaId AND estado = 1)
    BEGIN
        SET @cMensaje = N'La UOT seleccionada no tiene una organización operativa válida.';
        GOTO Fallar;
    END;

    IF [seg].[FN_Usuario_TienePermisoUOT](@nUsuario, @nUotId, 'INVENTARIO_CREAR') = 0
    BEGIN
        SET @cMensaje = N'No tiene permiso para registrar bienes en esta UOT.';
        SET @nHttpRespuesta = 403;
        GOTO Fallar;
    END;

    IF NOT EXISTS (SELECT 1 FROM [logistica].[TipoBien] WHERE tipo_bien_id = @nTipoBienId AND estado = 1)
    BEGIN
        SET @cMensaje = N'El tipo de bien seleccionado no está disponible.';
        GOTO Fallar;
    END;

    /* El código definitivo depende del ID, por eso el INSERT usa un valor temporal único. */
    SET @cCodigoPatrimonial =
        CONCAT(
            'TMP-B-',
            REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', '')
        );

    IF EXISTS (SELECT 1 FROM [logistica].[BienInventario] WHERE codigo_patrimonial = @cCodigoPatrimonial)
    BEGIN
        SET @cMensaje = N'El código patrimonial ya se encuentra registrado.';
        SET @cCodigoRespuesta = 'CODIGO_PATRIMONIAL_DUPLICADO';
        SET @nHttpRespuesta = 409;
        GOTO Fallar;
    END;

    IF @nMontoAdquisicion IS NOT NULL AND @nMontoAdquisicion < 0
    BEGIN
        SET @cMensaje = N'El monto de adquisición no es válido.';
        GOTO Fallar;
    END;

    IF @cMoneda IS NOT NULL AND (@cMoneda NOT LIKE '[A-Z][A-Z][A-Z]' OR LEN(@cMoneda) <> 3)
    BEGIN
        SET @cMensaje = N'La moneda seleccionada no es válida.';
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

    SET @nTranEntrada = @@TRANCOUNT;

    BEGIN TRY
        IF @nTranEntrada = 0
            BEGIN TRANSACTION;
        ELSE
            SAVE TRANSACTION BIEN_CREATE_SAVE;
        SET @bTranAbierta = 1;

        INSERT INTO [logistica].[BienInventario]
        (
            empresa_id,
            tipo_bien_id,
            codigo_patrimonial,
            nombre,
            marca,
            modelo,
            serie,
            estado_bien,
            estado,
            uot_id,
            fecha_adquisicion,
            monto_adquisicion,
            moneda_adquisicion,
            proveedor_persona_id,
            proveedor_empresa_id,
            observacion
        )
        VALUES
        (
            @nEmpresaId,
            @nTipoBienId,
            @cCodigoPatrimonial,
            @cNombre,
            @cMarca,
            @cModelo,
            @cSerie,
            'DISPONIBLE',
            1,
            @nUotId,
            @dFechaAdquisicion,
            @nMontoAdquisicion,
            @cMoneda,
            @nProveedorPersonaId,
            @nProveedorEmpresaId,
            @cObservacion
        );

        SET @nBienInventarioId = CONVERT(BIGINT, SCOPE_IDENTITY());

        SET @cCodigoPatrimonial =
            [logistica].[FN_CodigoRecursoUOT]
            (
                @nUotId,
                @cNombre,
                @nBienInventarioId
            );

        UPDATE [logistica].[BienInventario]
           SET codigo_patrimonial = @cCodigoPatrimonial
         WHERE bien_inventario_id = @nBienInventarioId;

        SET @cIdent = CONVERT(NVARCHAR(200), @nBienInventarioId);

        /* El historial nace junto con el bien, evitando un detalle sin estado inicial. */
        INSERT INTO [logistica].[BienEstadoHistorial]
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
            'DISPONIBLE',
            SYSUTCDATETIME(),
            N'Registro inicial del bien.',
            @nUsuario,
            1
        );

        EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio]
            @nUsuario, @nSesion, @nDisp, @nModulo,
            'CREAR', 'logistica', 'BienInventario', @cIdent,
            NULL, NULL, NULL, 'estado_bien', NULL, 'DISPONIBLE',
            @cIp, @gCorr, @gSol, @cEnd,
            @nAud OUTPUT, @nTrans OUTPUT;

        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
            @nOperacionIdempotenteId = @nOp,
            @cEstadoOperacion = 'COMPLETADA',
            @cEsquemaEntidad = 'logistica',
            @cNombreEntidad = 'BienInventario',
            @cIdentificadorResultado = @cIdent,
            @cCodigoResultado = 'BIEN_CREADO',
            @bResultado = @bFin OUTPUT,
            @cMensaje = @cMsgFin OUTPUT;

        IF ISNULL(@bFin, 0) = 0
            THROW 51003, 'DESCO_IDEMPOTENCIA_NO_CERRADA', 1;

        IF @nTranEntrada = 0
            COMMIT TRANSACTION;
        SET @bTranAbierta = 0;

        SELECT
            @bResultado = 1,
            @cMensaje = N'Bien registrado correctamente.',
            @cCodigoRespuesta = 'BIEN_CREADO',
            @nHttpRespuesta = 201;

        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @bTranAbierta = 1 AND XACT_STATE() <> 0
        BEGIN
            IF @nTranEntrada = 0
                ROLLBACK TRANSACTION;
            ELSE IF XACT_STATE() = 1
                ROLLBACK TRANSACTION BIEN_CREATE_SAVE;
        END;
        SET @bTranAbierta = 0;
        SET @nBienInventarioId = NULL;
        SET @bResultado = 0;
        SET @cCodigoRespuesta = 'BIEN_NO_CREADO';
        SET @nHttpRespuesta = 400;

        IF ERROR_NUMBER() IN (2601, 2627)
            SET @cMensaje = N'El código patrimonial ya se encuentra registrado.';
        ELSE
            SET @cMensaje = N'No se pudo registrar el bien. Intente nuevamente.';

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
            /* El fallo secundario de auditoría no reemplaza el motivo funcional. */
        END CATCH;
    END;

    IF @nHttpRespuesta IS NULL SET @nHttpRespuesta = 400;
    IF @cCodigoRespuesta IS NULL SET @cCodigoRespuesta = 'BIEN_NO_CREADO';
    SET @bResultado = 0;
    SET @nBienInventarioId = NULL;
    RETURN 1;
END;
GO
