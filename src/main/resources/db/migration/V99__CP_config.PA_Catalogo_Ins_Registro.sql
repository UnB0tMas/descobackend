IF OBJECT_ID(N'[config].[PA_Catalogo_Ins_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [config].[PA_Catalogo_Ins_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : config.PA_Catalogo_Ins_Registro
' Descripción             : Registra un valor de catálogo de configuración.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Configuración
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
        @nCatalogoId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [config].[PA_Catalogo_Ins_Registro]
        @cJson = N'{}',
        @nCatalogoId = @nCatalogoId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nCatalogoId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [config].[PA_Catalogo_Ins_Registro](@cJson NVARCHAR(MAX),@nCatalogoId BIGINT OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS BEGIN
    SET @cMensaje=NULL; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;

    /* Respuesta explícita; mensajes públicos aprobados. */
    SET NOCOUNT ON;
    DECLARE @__DbTranEntrada INT = @@TRANCOUNT,
            @__DbTranAbierta BIT = 0,
            @__DbSavepoint VARCHAR(32) = REPLACE(CONVERT(VARCHAR(36),NEWID()),'-',''),
            @__DbMensaje NVARCHAR(300),
            @__DbError BIT = 0;
    SET @bResultado = 0;
    SET ANSI_NULLS ON;
    SET ANSI_PADDING ON;
    SET ANSI_WARNINGS ON;
    SET ARITHABORT ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET NUMERIC_ROUNDABORT OFF;

    BEGIN TRY
  SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),@nAud BIGINT,@nTrans BIGINT,@cCat VARCHAR(40),@cCodigo VARCHAR(40),@cNombre NVARCHAR(150),@cDesc NVARCHAR(300),@cCategoria VARCHAR(20),@cIdent NVARCHAR(200);
    SELECT @bResultado=0,@cMensaje=N'No se pudo registrar el valor del catálogo.';
    EXEC seg.PA_Operacion_Ins_IniciarIdempotente @cJson=@cJson,@cCodigoPermiso='CATALOGOS_CREAR',@cAmbito='CATALOGO_CREAR',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@nOperacionIdempotenteId=@nOp OUTPUT,@bEsRepetida=@bRep OUTPUT,@cEstadoOperacion=@cEstadoOp OUTPUT,@cIdentificadorResultado=@cIdRes OUTPUT,@cCodigoResultado=@cCodRes OUTPUT,@bResultado=@bIni OUTPUT,@cMensaje=@cMsg OUTPUT;
    IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;
    IF @bRep=1 BEGIN SET @nCatalogoId=CASE WHEN @cEstadoOp='COMPLETADA' THEN TRY_CONVERT(BIGINT,@cIdRes) ELSE NULL END;
 SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END;
SET @cMensaje=CASE WHEN @cEstadoOp='COMPLETADA' THEN N'La solicitud ya fue procesada correctamente.' ELSE N'La solicitud ya se encuentra en proceso.' END;
GOTO __DESCO_Salida;
END;
SET @nCatalogoId=NULL;
SELECT
    @cCat = UPPER(NULLIF(LTRIM(RTRIM(COALESCE(
        JSON_VALUE(@cJson,'$.catalogo.catalogo'),
        JSON_VALUE(@cJson,'$.catalogo'),
        JSON_VALUE(@cJson,'$.datos.catalogo'),
        JSON_VALUE(@cJson,'$.command.catalogo')
    ))),'')),
    @cNombre = NULLIF(LTRIM(RTRIM(COALESCE(
        JSON_VALUE(@cJson,'$.catalogo.nombre'),
        JSON_VALUE(@cJson,'$.nombre'),
        JSON_VALUE(@cJson,'$.datos.nombre'),
        JSON_VALUE(@cJson,'$.command.nombre')
    ))),N''),
    @cDesc = NULLIF(LTRIM(RTRIM(COALESCE(
        JSON_VALUE(@cJson,'$.catalogo.descripcion'),
        JSON_VALUE(@cJson,'$.descripcion'),
        JSON_VALUE(@cJson,'$.datos.descripcion'),
        JSON_VALUE(@cJson,'$.command.descripcion')
    ))),N''),
    @cCategoria = UPPER(NULLIF(LTRIM(RTRIM(COALESCE(
        JSON_VALUE(@cJson,'$.catalogo.categoria'),
        JSON_VALUE(@cJson,'$.categoria'),
        JSON_VALUE(@cJson,'$.datos.categoria'),
        JSON_VALUE(@cJson,'$.command.categoria')
    ))),''));

IF @cCat IS NULL OR @cNombre IS NULL
BEGIN
    SET @cMensaje=N'Complete correctamente los datos del catálogo.';
    GOTO Fallar;
END;

SET @cCodigo = CONCAT(
    'TMP-',
    LEFT(REPLACE(CONVERT(VARCHAR(36),NEWID()),'-',''),20)
);
BEGIN TRY BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
IF @cCat='MOTIVO_SALIDA' BEGIN IF EXISTS(SELECT 1 FROM campo.MotivoSalida WHERE codigo=@cCodigo) THROW 53401,N'VALOR_DUPLICADO',1;
 INSERT campo.MotivoSalida(codigo,nombre,estado) VALUES(@cCodigo,@cNombre,1);
SET @nCatalogoId=SCOPE_IDENTITY();
END
ELSE IF @cCat='TIPO_EVALUACION' BEGIN IF EXISTS(SELECT 1 FROM campo.TipoEvaluacion WHERE codigo=@cCodigo) THROW 53401,N'VALOR_DUPLICADO',1;
 INSERT campo.TipoEvaluacion(codigo,nombre,estado) VALUES(@cCodigo,@cNombre,1);
SET @nCatalogoId=SCOPE_IDENTITY();
END
ELSE IF @cCat='VARIEDAD_PALTA' BEGIN IF EXISTS(SELECT 1 FROM prod.VariedadPalta WHERE codigo=@cCodigo) THROW 53401,N'VALOR_DUPLICADO',1;
 INSERT prod.VariedadPalta(codigo,nombre,estado) VALUES(@cCodigo,@cNombre,1);
SET @nCatalogoId=SCOPE_IDENTITY();
END
ELSE IF @cCat='PROBLEMA_FITOSANITARIO' BEGIN IF @cCategoria NOT IN('PLAGA','ENFERMEDAD','OTRO') BEGIN BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @cMensaje=N'Seleccione una categoría válida.';
GOTO Fallar;
END;
 IF EXISTS(SELECT 1 FROM sanidad.TipoProblemaFitosanitario WHERE codigo=@cCodigo) THROW 53401,N'VALOR_DUPLICADO',1;
 INSERT sanidad.TipoProblemaFitosanitario(categoria,codigo,nombre,estado) VALUES(@cCategoria,@cCodigo,@cNombre,1);
SET @nCatalogoId=SCOPE_IDENTITY();
END
ELSE IF @cCat='MODALIDAD_VENTA' BEGIN IF EXISTS(SELECT 1 FROM comercial.ModalidadVenta WHERE codigo=@cCodigo) THROW 53401,N'VALOR_DUPLICADO',1;
 INSERT comercial.ModalidadVenta(codigo,nombre,estado) VALUES(@cCodigo,@cNombre,1);
SET @nCatalogoId=SCOPE_IDENTITY();
END
ELSE IF @cCat='TIPO_GASTO' BEGIN IF EXISTS(SELECT 1 FROM finanzas.TipoGasto WHERE codigo=@cCodigo) THROW 53401,N'VALOR_DUPLICADO',1;
 INSERT finanzas.TipoGasto(codigo,nombre,estado) VALUES(@cCodigo,@cNombre,1);
SET @nCatalogoId=SCOPE_IDENTITY();
END
ELSE IF @cCat='REGLA_PRORRATEO' BEGIN IF EXISTS(SELECT 1 FROM finanzas.ReglaProrrateo WHERE codigo=@cCodigo) THROW 53401,N'VALOR_DUPLICADO',1;
 INSERT finanzas.ReglaProrrateo(codigo,nombre,estado) VALUES(@cCodigo,@cNombre,1);
SET @nCatalogoId=SCOPE_IDENTITY();
END
ELSE IF @cCat='TIPO_BIEN' BEGIN IF EXISTS(SELECT 1 FROM logistica.TipoBien WHERE codigo=@cCodigo) THROW 53401,N'VALOR_DUPLICADO',1;
 INSERT logistica.TipoBien(codigo,nombre,estado) VALUES(@cCodigo,@cNombre,1);
SET @nCatalogoId=SCOPE_IDENTITY();
END
ELSE IF @cCat='ZONA_PRODUCTIVA' BEGIN IF EXISTS(SELECT 1 FROM geo.ZonaProductiva WHERE codigo=@cCodigo) THROW 53401,N'VALOR_DUPLICADO',1;
 INSERT geo.ZonaProductiva(codigo,nombre,descripcion,estado) VALUES(@cCodigo,@cNombre,@cDesc,1);
SET @nCatalogoId=SCOPE_IDENTITY();
END
ELSE BEGIN BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @cMensaje=N'El catálogo seleccionado no está disponible para registro.';
GOTO Fallar;
END;
SET @cCodigo = [config].[FN_CodigoCatalogo](@cNombre,@nCatalogoId);

IF @cCat='MOTIVO_SALIDA'
    UPDATE campo.MotivoSalida SET codigo=@cCodigo WHERE motivo_salida_id=@nCatalogoId;
ELSE IF @cCat='TIPO_EVALUACION'
    UPDATE campo.TipoEvaluacion SET codigo=@cCodigo WHERE tipo_evaluacion_id=@nCatalogoId;
ELSE IF @cCat='VARIEDAD_PALTA'
    UPDATE prod.VariedadPalta SET codigo=@cCodigo WHERE variedad_palta_id=@nCatalogoId;
ELSE IF @cCat='PROBLEMA_FITOSANITARIO'
    UPDATE sanidad.TipoProblemaFitosanitario SET codigo=@cCodigo WHERE tipo_problema_fitosanitario_id=@nCatalogoId;
ELSE IF @cCat='MODALIDAD_VENTA'
    UPDATE comercial.ModalidadVenta SET codigo=@cCodigo WHERE modalidad_venta_id=@nCatalogoId;
ELSE IF @cCat='TIPO_GASTO'
    UPDATE finanzas.TipoGasto SET codigo=@cCodigo WHERE tipo_gasto_id=@nCatalogoId;
ELSE IF @cCat='REGLA_PRORRATEO'
    UPDATE finanzas.ReglaProrrateo SET codigo=@cCodigo WHERE regla_prorrateo_id=@nCatalogoId;
ELSE IF @cCat='TIPO_BIEN'
    UPDATE logistica.TipoBien SET codigo=@cCodigo WHERE tipo_bien_id=@nCatalogoId;
ELSE IF @cCat='ZONA_PRODUCTIVA'
    UPDATE geo.ZonaProductiva SET codigo=@cCodigo WHERE zona_productiva_id=@nCatalogoId;

SET @cIdent=CONVERT(NVARCHAR(200),@nCatalogoId);
EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @nUsuario,@nSesion,@nDisp,@nModulo,'CREAR','config',@cCat,@cIdent,NULL,NULL,NULL,NULL,NULL,NULL,@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
/* Confirmar datos e idempotencia juntos. */
EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='COMPLETADA',@cEsquemaEntidad='config',@cNombreEntidad='Catalogo',@cIdentificadorResultado=@cIdent,@cCodigoResultado='CATALOGO_REGISTRADO',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
IF ISNULL(@bFin,0) = 0
    THROW 51003, N'DESCO_IDEMPOTENCIA_NO_CERRADA', 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;
 SET @bResultado=1;
SET @cMensaje=N'Valor registrado correctamente.';
GOTO __DESCO_Salida;
END TRY BEGIN CATCH
SET @bResultado = 0;
 IF XACT_STATE()<>0 BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
IF ERROR_MESSAGE()=N'VALOR_DUPLICADO' SET @cMensaje=N'Ya existe un valor con ese código.';
ELSE SET @cMensaje=N'No se pudo registrar el valor. Intente nuevamente.';
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'config.PA_Catalogo_Ins_Registro',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;
Fallar: IF @nOp IS NOT NULL AND @bResultado=0 EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='FALLIDA',@cEsquemaEntidad=NULL,@cNombreEntidad=NULL,@cIdentificadorResultado=NULL,@cCodigoResultado='NO_PROCESADO',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
 
    END TRY
    BEGIN CATCH

        SET @__DbError = 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'config.PA_Catalogo_Ins_Registro',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
    END CATCH;

__DESCO_Salida:
BEGIN TRY

IF @__DbTranAbierta = 1
BEGIN
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
IF ISNULL(@bResultado,0) = 1 OR NULLIF(@cMensaje,N'') IS NULL SET @cMensaje = N'La operación no se completó y sus cambios fueron revertidos.';
SET @bResultado = 0;
END;

    IF @bResultado = 0 AND @nOp IS NOT NULL AND XACT_STATE() <> -1
    BEGIN
        IF ISNULL(@bRep,0) = 0
        BEGIN
        BEGIN TRY
            EXEC [auditoria].[PA_OperacionIdempotente_Upd_MensajeFallido]
                 @nOperacionIdempotenteId = @nOp, @cMensajeResultado = @cMensaje;
        END TRY
        BEGIN CATCH
            -- No sustituir el motivo funcional por un fallo de registro secundario.
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'config.PA_Catalogo_Ins_Registro',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
        END CATCH;
        END
        ELSE
        BEGIN
            SELECT @cMensaje = COALESCE(mensaje_resultado,
                CASE WHEN estado_operacion = 'FALLIDA'
                     THEN N'La solicitud anterior no se completó. Corrija los datos y envíe una nueva solicitud.'
                     ELSE N'La solicitud todavía se está procesando. Consulte el resultado antes de repetirla.' END)
            FROM [auditoria].[OperacionIdempotente]
            WHERE operacion_idempotente_id = @nOp;
        END;
    END;
IF @bResultado = 0
    SELECT @nCatalogoId = NULL;

END TRY
BEGIN CATCH

        SET @__DbError = 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'config.PA_Catalogo_Ins_Registro',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bResultado,0) = 1
BEGIN
SET @bResultado = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'config.PA_Catalogo_Ins_Registro',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
