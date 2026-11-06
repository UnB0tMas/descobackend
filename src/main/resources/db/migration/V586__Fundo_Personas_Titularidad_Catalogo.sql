-- V586 - Registro de fundos, personas y titularidad configurable.
-- Mantener migraciones anteriores intactas. SQL Server / Flyway.
SET XACT_ABORT ON;
GO
IF OBJECT_ID(N'prod.TipoTitularidadCatalogo', N'U') IS NULL
BEGIN
    CREATE TABLE prod.TipoTitularidadCatalogo (
        tipo_titularidad_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_GP_TipoTitularidadCatalogo PRIMARY KEY,
        codigo VARCHAR(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
        nombre NVARCHAR(120) NOT NULL,
        estado BIT NOT NULL CONSTRAINT DF_GP_TipoTitularidadEstado DEFAULT(1),
        CONSTRAINT UQ_GP_TipoTitularidadCodigo UNIQUE(codigo)
    );
END;
GO
MERGE prod.TipoTitularidadCatalogo WITH(HOLDLOCK) AS T
USING (VALUES
  ('PROPIETARIO', N'Propietario'), ('COPROPIETARIO',N'Copropietario'),
  ('POSESIONARIO',N'Posesionario'), ('ARRENDATARIO',N'Arrendatario'), ('OTRO',N'Otro')
) AS S(codigo,nombre) ON T.codigo=S.codigo
WHEN NOT MATCHED THEN INSERT(codigo,nombre,estado) VALUES(S.codigo,S.nombre,1);
GO
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'prod.PredioTitularidad')
    AND name='CK_PredioTitularidad_Tipo')
    ALTER TABLE prod.PredioTitularidad DROP CONSTRAINT CK_PredioTitularidad_Tipo;
GO
-- Rol principal y tipo jurídico/administrativo NO son la misma información.
IF COL_LENGTH('prod.PredioTitularidad','rol_titularidad') IS NULL
    ALTER TABLE prod.PredioTitularidad ADD rol_titularidad VARCHAR(12) NULL;
GO
;WITH C AS (
 SELECT predio_titularidad_id,
 ROW_NUMBER() OVER(PARTITION BY predio_id ORDER BY
   CASE WHEN tipo_titularidad='PROPIETARIO' THEN 0 ELSE 1 END, fecha_desde, predio_titularidad_id) AS orden
 FROM prod.PredioTitularidad WHERE estado=1 AND fecha_hasta IS NULL
)
UPDATE T SET rol_titularidad=CASE WHEN C.orden=1 THEN 'PRINCIPAL' ELSE 'ADICIONAL' END
FROM prod.PredioTitularidad T INNER JOIN C ON C.predio_titularidad_id=T.predio_titularidad_id
WHERE T.rol_titularidad IS NULL;
UPDATE prod.PredioTitularidad SET rol_titularidad='ADICIONAL' WHERE rol_titularidad IS NULL;
GO
IF NOT EXISTS(SELECT 1 FROM sys.default_constraints WHERE parent_object_id=OBJECT_ID(N'prod.PredioTitularidad') AND name='DF_GP_RolTitular')
  ALTER TABLE prod.PredioTitularidad ADD CONSTRAINT DF_GP_RolTitular DEFAULT ('ADICIONAL') FOR rol_titularidad;
IF NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'prod.PredioTitularidad') AND name='CK_GP_RolTitular')
  ALTER TABLE prod.PredioTitularidad WITH CHECK ADD CONSTRAINT CK_GP_RolTitular CHECK(rol_titularidad IN('PRINCIPAL','ADICIONAL'));
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'prod.PredioTitularidad') AND name='UX_GP_TitularPrincipalActual')
  CREATE UNIQUE INDEX UX_GP_TitularPrincipalActual ON prod.PredioTitularidad(predio_id)
  WHERE rol_titularidad='PRINCIPAL' AND estado=1 AND fecha_hasta IS NULL;
GO

-- Catalogo extendido: V99__CP_config.PA_Catalogo_Ins_Registro.sql

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
CREATE OR ALTER PROCEDURE [config].[PA_Catalogo_Ins_Registro](@cJson NVARCHAR(MAX),@nCatalogoId BIGINT OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
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
ELSE IF @cCat='TIPO_TITULARIDAD' BEGIN
    INSERT prod.TipoTitularidadCatalogo(codigo,nombre,estado)
    VALUES(LEFT(@cCodigo,20),@cNombre,1);
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
ELSE IF @cCat='TIPO_TITULARIDAD'
    UPDATE prod.TipoTitularidadCatalogo SET codigo=LEFT(@cCodigo,20) WHERE tipo_titularidad_id=@nCatalogoId;
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

GO

-- Catalogo extendido: V100__CP_config.PA_Catalogo_Sel_Listado.sql

/******************************************************************************************************
' Nombre del PA           : config.PA_Catalogo_Sel_Listado
' Descripción             : Lista catálogo.
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
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [config].[PA_Catalogo_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE OR ALTER PROCEDURE [config].[PA_Catalogo_Sel_Listado]
(
    @cJson NVARCHAR(MAX),
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS
BEGIN
    SET @cMensaje=NULL; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;

    /* Respuesta explícita; mensajes públicos aprobados. */
    SET NOCOUNT ON;
    DECLARE @__DbTranEntrada INT = @@TRANCOUNT,
            @__DbTranAbierta BIT = 0,
            @__DbSavepoint VARCHAR(32) = REPLACE(CONVERT(VARCHAR(36),NEWID()),'-',''),
            @__DbMensaje NVARCHAR(300),
            @__DbError BIT = 0;
    SET @bResultado = 0;

    BEGIN TRY

    /* DESCO_CIERRE_FINAL_CATALOGO_USO_V1_20260829 */
    SET NOCOUNT ON;

    DECLARE
        @nPaginaListado INT,
        @nTamanoListado INT,
        @nOffsetListado BIGINT;

    EXEC [seg].[PA_Consulta_Sel_ResolverPaginacion]
         @cJson = @cJson,
         @nPagina = @nPaginaListado OUTPUT,
         @nTamanoPagina = @nTamanoListado OUTPUT,
         @nOffset = @nOffsetListado OUTPUT;

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
        @bCtx BIT,
        @cMsg NVARCHAR(300);

    SELECT
        @bResultado = 0,
        @cMensaje = N'No se pudo consultar el catálogo.';

    DECLARE @cCatalogoPermiso VARCHAR(40) = CASE
        WHEN UPPER(JSON_VALUE(@cJson,'$.filtros.catalogo'))='TIPO_TITULARIDAD' THEN 'PREDIOS_LISTAR'
        ELSE 'CATALOGOS_LISTAR' END;
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
         @cJson = @cJson,
         @cCodigoPermiso = @cCatalogoPermiso,
         @nUsuarioId = @nUsuario OUTPUT,
         @nSesionUsuarioId = @nSesion OUTPUT,
         @nDispositivoUsuarioId = @nDisp OUTPUT,
         @nEmpleadoId = @nEmp OUTPUT,
         @nModuloId = @nModulo OUTPUT,
         @gCorrelacionId = @gCorr OUTPUT,
         @gSolicitudId = @gSol OUTPUT,
         @cIp = @cIp OUTPUT,
         @cEndpoint = @cEnd OUTPUT,
         @bResultado = @bCtx OUTPUT,
         @cMensaje = @cMsg OUTPUT;

    IF @bCtx = 0
    BEGIN
        SET @cMensaje = @cMsg;
        GOTO __DESCO_Salida;
    END;

    DECLARE @cCat VARCHAR(40);

    SELECT
        @cCat = UPPER(NULLIF(LTRIM(RTRIM(catalogo)), ''))
    FROM OPENJSON(@cJson, '$.filtros')
    WITH
    (
        catalogo VARCHAR(40) '$.catalogo'
    );

    IF @cCat IS NULL
    BEGIN
        SET @cMensaje = N'Seleccione un catálogo.';
        GOTO __DESCO_Salida;
    END;

    IF @cCat = 'MOTIVO_SALIDA'
    BEGIN
        SELECT
            M.motivo_salida_id AS id,
            M.codigo,
            M.nombre,
            CAST(NULL AS NVARCHAR(300)) AS descripcion,
            M.estado,
            U.cantidadUso,
            CONVERT(BIT, CASE WHEN U.cantidadUso > 0 THEN 1 ELSE 0 END) AS enUso,
            COUNT_BIG(*) OVER() AS totalRegistros
        FROM [campo].[MotivoSalida] M
        CROSS APPLY
        (
            SELECT COUNT_BIG(*) AS cantidadUso
            FROM [campo].[SalidaCampo] S
            WHERE S.motivo_salida_id = M.motivo_salida_id
        ) U
        ORDER BY M.nombre, M.motivo_salida_id
        OFFSET @nOffsetListado ROWS
        FETCH NEXT @nTamanoListado ROWS ONLY;
    END
    ELSE IF @cCat = 'TIPO_EVALUACION'
    BEGIN
        SELECT
            T.tipo_evaluacion_id AS id,
            T.codigo,
            T.nombre,
            CAST(NULL AS NVARCHAR(300)) AS descripcion,
            T.estado,
            U.cantidadUso,
            CONVERT(BIT, CASE WHEN U.cantidadUso > 0 THEN 1 ELSE 0 END) AS enUso,
            COUNT_BIG(*) OVER() AS totalRegistros
        FROM [campo].[TipoEvaluacion] T
        CROSS APPLY
        (
            SELECT COUNT_BIG(*) AS cantidadUso
            FROM [campo].[EvaluacionAgronomica] E
            WHERE E.tipo_evaluacion_id = T.tipo_evaluacion_id
        ) U
        ORDER BY T.nombre, T.tipo_evaluacion_id
        OFFSET @nOffsetListado ROWS
        FETCH NEXT @nTamanoListado ROWS ONLY;
    END
    ELSE IF @cCat = 'VARIEDAD_PALTA'
    BEGIN
        SELECT
            V.variedad_palta_id AS id,
            V.codigo,
            V.nombre,
            CAST(NULL AS NVARCHAR(300)) AS descripcion,
            V.estado,
            U.cantidadUso,
            CONVERT(BIT, CASE WHEN U.cantidadUso > 0 THEN 1 ELSE 0 END) AS enUso,
            COUNT_BIG(*) OVER() AS totalRegistros
        FROM [prod].[VariedadPalta] V
        CROSS APPLY
        (
            SELECT
                (SELECT COUNT_BIG(*) FROM [prod].[ParcelaCultivo] PC WHERE PC.variedad_palta_id = V.variedad_palta_id)
                +
                (SELECT COUNT_BIG(*) FROM [comercial].[PrecioComercial] P WHERE P.variedad_palta_id = V.variedad_palta_id)
                AS cantidadUso
        ) U
        ORDER BY V.nombre, V.variedad_palta_id
        OFFSET @nOffsetListado ROWS
        FETCH NEXT @nTamanoListado ROWS ONLY;
    END
    ELSE IF @cCat = 'PROBLEMA_FITOSANITARIO'
    BEGIN
        SELECT
            T.tipo_problema_fitosanitario_id AS id,
            T.codigo,
            T.nombre,
            CONCAT(N'Categoría: ', T.categoria) AS descripcion,
            T.estado,
            U.cantidadUso,
            CONVERT(BIT, CASE WHEN U.cantidadUso > 0 THEN 1 ELSE 0 END) AS enUso,
            COUNT_BIG(*) OVER() AS totalRegistros
        FROM [sanidad].[TipoProblemaFitosanitario] T
        CROSS APPLY
        (
            SELECT COUNT_BIG(*) AS cantidadUso
            FROM [sanidad].[CasoFitosanitario] C
            WHERE C.tipo_problema_fitosanitario_id = T.tipo_problema_fitosanitario_id
        ) U
        ORDER BY T.categoria, T.nombre, T.tipo_problema_fitosanitario_id
        OFFSET @nOffsetListado ROWS
        FETCH NEXT @nTamanoListado ROWS ONLY;
    END
    ELSE IF @cCat = 'MODALIDAD_VENTA'
    BEGIN
        SELECT
            M.modalidad_venta_id AS id,
            M.codigo,
            M.nombre,
            CAST(NULL AS NVARCHAR(300)) AS descripcion,
            M.estado,
            U.cantidadUso,
            CONVERT(BIT, CASE WHEN U.cantidadUso > 0 THEN 1 ELSE 0 END) AS enUso,
            COUNT_BIG(*) OVER() AS totalRegistros
        FROM [comercial].[ModalidadVenta] M
        CROSS APPLY
        (
            SELECT COUNT_BIG(*) AS cantidadUso
            FROM [comercial].[CondicionComercial] C
            WHERE C.modalidad_venta_id = M.modalidad_venta_id
        ) U
        ORDER BY M.nombre, M.modalidad_venta_id
        OFFSET @nOffsetListado ROWS
        FETCH NEXT @nTamanoListado ROWS ONLY;
    END
    ELSE IF @cCat = 'TIPO_GASTO'
    BEGIN
        SELECT
            T.tipo_gasto_id AS id,
            T.codigo,
            T.nombre,
            CAST(NULL AS NVARCHAR(300)) AS descripcion,
            T.estado,
            U.cantidadUso,
            CONVERT(BIT, CASE WHEN U.cantidadUso > 0 THEN 1 ELSE 0 END) AS enUso,
            COUNT_BIG(*) OVER() AS totalRegistros
        FROM [finanzas].[TipoGasto] T
        CROSS APPLY
        (
            SELECT COUNT_BIG(*) AS cantidadUso
            FROM [finanzas].[GastoCampania] G
            WHERE G.tipo_gasto_id = T.tipo_gasto_id
        ) U
        ORDER BY T.nombre, T.tipo_gasto_id
        OFFSET @nOffsetListado ROWS
        FETCH NEXT @nTamanoListado ROWS ONLY;
    END
    ELSE IF @cCat = 'REGLA_PRORRATEO'
    BEGIN
        SELECT
            R.regla_prorrateo_id AS id,
            R.codigo,
            R.nombre,
            CAST(NULL AS NVARCHAR(300)) AS descripcion,
            R.estado,
            U.cantidadUso,
            CONVERT(BIT, CASE WHEN U.cantidadUso > 0 THEN 1 ELSE 0 END) AS enUso,
            COUNT_BIG(*) OVER() AS totalRegistros
        FROM [finanzas].[ReglaProrrateo] R
        CROSS APPLY
        (
            SELECT COUNT_BIG(*) AS cantidadUso
            FROM [finanzas].[GastoCampania] G
            WHERE G.regla_prorrateo_id = R.regla_prorrateo_id
        ) U
        ORDER BY R.nombre, R.regla_prorrateo_id
        OFFSET @nOffsetListado ROWS
        FETCH NEXT @nTamanoListado ROWS ONLY;
    END
    ELSE IF @cCat = 'TIPO_BIEN'
    BEGIN
        SELECT
            T.tipo_bien_id AS id,
            T.codigo,
            T.nombre,
            CAST(NULL AS NVARCHAR(300)) AS descripcion,
            T.estado,
            U.cantidadUso,
            CONVERT(BIT, CASE WHEN U.cantidadUso > 0 THEN 1 ELSE 0 END) AS enUso,
            COUNT_BIG(*) OVER() AS totalRegistros
        FROM [logistica].[TipoBien] T
        CROSS APPLY
        (
            SELECT COUNT_BIG(*) AS cantidadUso
            FROM [logistica].[BienInventario] B
            WHERE B.tipo_bien_id = T.tipo_bien_id
        ) U
        ORDER BY T.nombre, T.tipo_bien_id
        OFFSET @nOffsetListado ROWS
        FETCH NEXT @nTamanoListado ROWS ONLY;
    END
    ELSE IF @cCat = 'TIPO_TITULARIDAD'
    BEGIN
        SELECT T.tipo_titularidad_id AS id,T.codigo,T.nombre,
            CAST(NULL AS NVARCHAR(300)) AS descripcion,T.estado,
            U.cantidadUso,CONVERT(BIT,CASE WHEN U.cantidadUso>0 THEN 1 ELSE 0 END) AS enUso,
            COUNT_BIG(*) OVER() AS totalRegistros
        FROM prod.TipoTitularidadCatalogo T
        CROSS APPLY (SELECT COUNT_BIG(*) cantidadUso FROM prod.PredioTitularidad P
                     WHERE P.tipo_titularidad=T.codigo) U
        ORDER BY T.nombre,T.tipo_titularidad_id
        OFFSET @nOffsetListado ROWS FETCH NEXT @nTamanoListado ROWS ONLY;
    END
    ELSE IF @cCat = 'ZONA_PRODUCTIVA'
    BEGIN
        SELECT
            Z.zona_productiva_id AS id,
            Z.codigo,
            Z.nombre,
            Z.descripcion,
            Z.estado,
            U.cantidadUso,
            CONVERT(BIT, CASE WHEN U.cantidadUso > 0 THEN 1 ELSE 0 END) AS enUso,
            COUNT_BIG(*) OVER() AS totalRegistros
        FROM [geo].[ZonaProductiva] Z
        CROSS APPLY
        (
            SELECT
                (SELECT COUNT_BIG(*) FROM [geo].[ZonaProductivaPredio] ZP WHERE ZP.zona_productiva_id = Z.zona_productiva_id AND ZP.estado = 1)
                +
                (SELECT COUNT_BIG(*) FROM [comercial].[OperativoZona] OZ WHERE OZ.zona_productiva_id = Z.zona_productiva_id)
                AS cantidadUso
        ) U
        ORDER BY Z.nombre, Z.zona_productiva_id
        OFFSET @nOffsetListado ROWS
        FETCH NEXT @nTamanoListado ROWS ONLY;
    END
    ELSE
    BEGIN
        SET @cMensaje = N'El catálogo seleccionado no está disponible.';
        GOTO __DESCO_Salida;
    END;

    SET @bResultado = 1;
    SET @cMensaje = N'Catálogo consultado correctamente.';

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
    @cProcedimiento = N'config.PA_Catalogo_Sel_Listado',
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
    @cProcedimiento = N'config.PA_Catalogo_Sel_Listado',
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
FROM config.FN_RespuestaUsuario(N'config.PA_Catalogo_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO

GO

-- Catalogo extendido: V101__CP_config.PA_Catalogo_Upd_Deshabilitar.sql

/******************************************************************************************************
' Nombre del PA           : config.PA_Catalogo_Upd_Deshabilitar
' Descripción             : Deshabilita catálogo.
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
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [config].[PA_Catalogo_Upd_Deshabilitar]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE OR ALTER PROCEDURE [config].[PA_Catalogo_Upd_Deshabilitar](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
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
DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),@nAud BIGINT,@nTrans BIGINT,@cCat VARCHAR(40),@nId BIGINT,@cMotivo NVARCHAR(300),@bUsado BIT=0,@cIdent NVARCHAR(200);
    SELECT @bResultado=0,@cMensaje=N'No se pudo deshabilitar el valor.';
    EXEC seg.PA_Operacion_Ins_IniciarIdempotente @cJson=@cJson,@cCodigoPermiso='CATALOGOS_RETIRAR',@cAmbito='CATALOGO_DESHABILITAR',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@nOperacionIdempotenteId=@nOp OUTPUT,@bEsRepetida=@bRep OUTPUT,@cEstadoOperacion=@cEstadoOp OUTPUT,@cIdentificadorResultado=@cIdRes OUTPUT,@cCodigoResultado=@cCodRes OUTPUT,@bResultado=@bIni OUTPUT,@cMensaje=@cMsg OUTPUT;
    IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;
    IF @bRep=1 BEGIN SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END;
SET @cMensaje=CASE WHEN @cEstadoOp='COMPLETADA' THEN N'La solicitud ya fue procesada correctamente.' ELSE N'La solicitud ya se encuentra en proceso.' END;
GOTO __DESCO_Salida;
END;
SELECT
    @cCat = UPPER(NULLIF(LTRIM(RTRIM(COALESCE(
        JSON_VALUE(@cJson,'$.catalogo.catalogo'),
        JSON_VALUE(@cJson,'$.catalogo'),
        JSON_VALUE(@cJson,'$.datos.catalogo'),
        JSON_VALUE(@cJson,'$.command.catalogo')
    ))),'')),
    @nId = TRY_CONVERT(BIGINT,COALESCE(
        JSON_VALUE(@cJson,'$.catalogo.id'),
        JSON_VALUE(@cJson,'$.id'),
        JSON_VALUE(@cJson,'$.datos.id'),
        JSON_VALUE(@cJson,'$.command.id')
    )),
    @cMotivo = NULLIF(LTRIM(RTRIM(COALESCE(
        JSON_VALUE(@cJson,'$.catalogo.motivo'),
        JSON_VALUE(@cJson,'$.motivo'),
        JSON_VALUE(@cJson,'$.datos.motivo'),
        JSON_VALUE(@cJson,'$.command.motivo')
    ))),N'');

IF @cCat IS NULL OR @nId IS NULL OR @cMotivo IS NULL
BEGIN
    SET @cMensaje=N'Seleccione el valor e indique el motivo.';
    GOTO Fallar;
END;
BEGIN TRY BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
IF @cCat='MOTIVO_SALIDA' UPDATE campo.MotivoSalida SET estado=0 WHERE motivo_salida_id=@nId AND estado=1;
ELSE IF @cCat='TIPO_EVALUACION' UPDATE campo.TipoEvaluacion SET estado=0 WHERE tipo_evaluacion_id=@nId AND estado=1;
ELSE IF @cCat='VARIEDAD_PALTA' UPDATE prod.VariedadPalta SET estado=0 WHERE variedad_palta_id=@nId AND estado=1;
ELSE IF @cCat='PROBLEMA_FITOSANITARIO' UPDATE sanidad.TipoProblemaFitosanitario SET estado=0 WHERE tipo_problema_fitosanitario_id=@nId AND estado=1;
ELSE IF @cCat='MODALIDAD_VENTA' UPDATE comercial.ModalidadVenta SET estado=0 WHERE modalidad_venta_id=@nId AND estado=1;
ELSE IF @cCat='TIPO_GASTO' UPDATE finanzas.TipoGasto SET estado=0 WHERE tipo_gasto_id=@nId AND estado=1;
ELSE IF @cCat='REGLA_PRORRATEO' UPDATE finanzas.ReglaProrrateo SET estado=0 WHERE regla_prorrateo_id=@nId AND estado=1;
ELSE IF @cCat='TIPO_BIEN' UPDATE logistica.TipoBien SET estado=0 WHERE tipo_bien_id=@nId AND estado=1;
ELSE IF @cCat='TIPO_TITULARIDAD' UPDATE prod.TipoTitularidadCatalogo SET estado=0
 WHERE tipo_titularidad_id=@nId AND estado=1 AND NOT EXISTS(
   SELECT 1 FROM prod.PredioTitularidad P WHERE P.tipo_titularidad=
   (SELECT codigo FROM prod.TipoTitularidadCatalogo WHERE tipo_titularidad_id=@nId)
   AND P.estado=1 AND P.fecha_hasta IS NULL);
ELSE IF @cCat='ZONA_PRODUCTIVA' UPDATE geo.ZonaProductiva SET estado=0 WHERE zona_productiva_id=@nId AND estado=1;
ELSE BEGIN BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @cMensaje=N'El catálogo seleccionado no está disponible.';
GOTO Fallar;
END;
IF @@ROWCOUNT=0 BEGIN BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @cMensaje=N'El valor seleccionado no está disponible.';
GOTO Fallar;
END;
SET @cIdent=CONVERT(NVARCHAR(200),@nId);
EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @nUsuario,@nSesion,@nDisp,@nModulo,'DESHABILITAR','config',@cCat,@cIdent,NULL,NULL,@cMotivo,'estado','1','0',@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
/* Confirmar datos e idempotencia juntos. */
EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='COMPLETADA',@cEsquemaEntidad='config',@cNombreEntidad='Catalogo',@cIdentificadorResultado=@cIdent,@cCodigoResultado='CATALOGO_DESHABILITADO',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
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
SET @cMensaje=N'Valor deshabilitado correctamente.';
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
SET @cMensaje=N'No se pudo deshabilitar el valor. Intente nuevamente.';
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'config.PA_Catalogo_Upd_Deshabilitar',
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
    @cProcedimiento = N'config.PA_Catalogo_Upd_Deshabilitar',
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
    @cProcedimiento = N'config.PA_Catalogo_Upd_Deshabilitar',
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
    @cProcedimiento = N'config.PA_Catalogo_Upd_Deshabilitar',
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
FROM config.FN_RespuestaUsuario(N'config.PA_Catalogo_Upd_Deshabilitar',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO

GO

-- Catalogo extendido: V102__CP_config.PA_Catalogo_Upd_Registro.sql

/******************************************************************************************************
' Nombre del PA           : config.PA_Catalogo_Upd_Registro
' Descripción             : Actualiza los datos de catálogo.
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
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [config].[PA_Catalogo_Upd_Registro]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE OR ALTER PROCEDURE [config].[PA_Catalogo_Upd_Registro](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
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
DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),@nAud BIGINT,@nTrans BIGINT,@cCat VARCHAR(40),@nId BIGINT,@cNombre NVARCHAR(150),@cDesc NVARCHAR(300),@cCategoria VARCHAR(20),@cIdent NVARCHAR(200);
    SELECT @bResultado=0,@cMensaje=N'No se pudo actualizar el valor del catálogo.';
    EXEC seg.PA_Operacion_Ins_IniciarIdempotente @cJson=@cJson,@cCodigoPermiso='CATALOGOS_EDITAR',@cAmbito='CATALOGO_EDITAR',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@nOperacionIdempotenteId=@nOp OUTPUT,@bEsRepetida=@bRep OUTPUT,@cEstadoOperacion=@cEstadoOp OUTPUT,@cIdentificadorResultado=@cIdRes OUTPUT,@cCodigoResultado=@cCodRes OUTPUT,@bResultado=@bIni OUTPUT,@cMensaje=@cMsg OUTPUT;
    IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;
    IF @bRep=1 BEGIN SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END;
SET @cMensaje=CASE WHEN @cEstadoOp='COMPLETADA' THEN N'La solicitud ya fue procesada correctamente.' ELSE N'La solicitud ya se encuentra en proceso.' END;
GOTO __DESCO_Salida;
END;
SELECT
    @cCat = UPPER(NULLIF(LTRIM(RTRIM(COALESCE(
        JSON_VALUE(@cJson,'$.catalogo.catalogo'),
        JSON_VALUE(@cJson,'$.catalogo'),
        JSON_VALUE(@cJson,'$.datos.catalogo'),
        JSON_VALUE(@cJson,'$.command.catalogo')
    ))),'')),
    @nId = TRY_CONVERT(BIGINT,COALESCE(
        JSON_VALUE(@cJson,'$.catalogo.id'),
        JSON_VALUE(@cJson,'$.id'),
        JSON_VALUE(@cJson,'$.datos.id'),
        JSON_VALUE(@cJson,'$.command.id')
    )),
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

IF @cCat IS NULL OR @nId IS NULL OR @cNombre IS NULL
BEGIN
    SET @cMensaje=N'Complete correctamente los datos del catálogo.';
    GOTO Fallar;
END;
BEGIN TRY BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
IF @cCat='MOTIVO_SALIDA' UPDATE campo.MotivoSalida SET codigo=[config].[FN_CodigoCatalogo](@cNombre,@nId),nombre=@cNombre WHERE motivo_salida_id=@nId AND estado=1;
ELSE IF @cCat='TIPO_EVALUACION' UPDATE campo.TipoEvaluacion SET codigo=[config].[FN_CodigoCatalogo](@cNombre,@nId),nombre=@cNombre WHERE tipo_evaluacion_id=@nId AND estado=1;
ELSE IF @cCat='VARIEDAD_PALTA' UPDATE prod.VariedadPalta SET codigo=[config].[FN_CodigoCatalogo](@cNombre,@nId),nombre=@cNombre WHERE variedad_palta_id=@nId AND estado=1;
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
 UPDATE sanidad.TipoProblemaFitosanitario SET codigo=[config].[FN_CodigoCatalogo](@cNombre,@nId),nombre=@cNombre,categoria=@cCategoria WHERE tipo_problema_fitosanitario_id=@nId AND estado=1;
END
ELSE IF @cCat='MODALIDAD_VENTA' UPDATE comercial.ModalidadVenta SET codigo=[config].[FN_CodigoCatalogo](@cNombre,@nId),nombre=@cNombre WHERE modalidad_venta_id=@nId AND estado=1;
ELSE IF @cCat='TIPO_GASTO' UPDATE finanzas.TipoGasto SET codigo=[config].[FN_CodigoCatalogo](@cNombre,@nId),nombre=@cNombre WHERE tipo_gasto_id=@nId AND estado=1;
ELSE IF @cCat='REGLA_PRORRATEO' UPDATE finanzas.ReglaProrrateo SET codigo=[config].[FN_CodigoCatalogo](@cNombre,@nId),nombre=@cNombre WHERE regla_prorrateo_id=@nId AND estado=1;
ELSE IF @cCat='TIPO_BIEN' UPDATE logistica.TipoBien SET codigo=[config].[FN_CodigoCatalogo](@cNombre,@nId),nombre=@cNombre WHERE tipo_bien_id=@nId AND estado=1;
ELSE IF @cCat='TIPO_TITULARIDAD' UPDATE prod.TipoTitularidadCatalogo
 SET nombre=@cNombre WHERE tipo_titularidad_id=@nId AND estado=1;
ELSE IF @cCat='ZONA_PRODUCTIVA' UPDATE geo.ZonaProductiva SET codigo=[config].[FN_CodigoCatalogo](@cNombre,@nId),nombre=@cNombre,descripcion=@cDesc WHERE zona_productiva_id=@nId AND estado=1;
ELSE BEGIN BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @cMensaje=N'El catálogo seleccionado no está disponible para edición.';
GOTO Fallar;
END;
IF @@ROWCOUNT=0 BEGIN BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @cMensaje=N'El valor seleccionado no está disponible.';
GOTO Fallar;
END;
SET @cIdent=CONVERT(NVARCHAR(200),@nId);
EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @nUsuario,@nSesion,@nDisp,@nModulo,'EDITAR','config',@cCat,@cIdent,NULL,NULL,NULL,NULL,NULL,NULL,@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
/* Confirmar datos e idempotencia juntos. */
EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='COMPLETADA',@cEsquemaEntidad='config',@cNombreEntidad='Catalogo',@cIdentificadorResultado=@cIdent,@cCodigoResultado='CATALOGO_ACTUALIZADO',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
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
SET @cMensaje=N'Valor actualizado correctamente.';
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
SET @cMensaje=N'No se pudo actualizar el valor. Intente nuevamente.';
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'config.PA_Catalogo_Upd_Registro',
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
    @cProcedimiento = N'config.PA_Catalogo_Upd_Registro',
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
    @cProcedimiento = N'config.PA_Catalogo_Upd_Registro',
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
    @cProcedimiento = N'config.PA_Catalogo_Upd_Registro',
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
FROM config.FN_RespuestaUsuario(N'config.PA_Catalogo_Upd_Registro',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO

GO

-- Mutaciones legado compatibles con personas no socias
-- Compatibilidad de PAs existentes con persona_id manteniendo contrato de socios.
GO

/******************************************************************************************************
' Nombre del PA           : prod.PA_Predio_Ins_Registro
' Descripción             : Registra predios.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Producción
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
        @nPredioId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [prod].[PA_Predio_Ins_Registro]
        @cJson = N'{}',
        @nPredioId = @nPredioId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nPredioId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE OR ALTER PROCEDURE [prod].[PA_Predio_Ins_Registro]
(
    @cJson NVARCHAR(MAX), @nPredioId BIGINT OUTPUT, @bResultado BIT OUTPUT, @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS
BEGIN
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
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
            @nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),
            @cCodigo VARCHAR(40),@nCodigoConsecutivo BIGINT,@cNombre NVARCHAR(150),@dRegistro DATE,@cDistrito CHAR(6),@nCP BIGINT,@cRef NVARCHAR(300),@nLat DECIMAL(9,6),@nLon DECIMAL(9,6),@nAlt DECIMAL(8,2),@nUbicacion BIGINT,@bUbi BIT,@cMsgUbi NVARCHAR(300),
            @nArea DECIMAL(10,4),@nAreaCult DECIMAL(10,4),@cRiego VARCHAR(30),@cFuente NVARCHAR(150),@cInfra NVARCHAR(300),@cObs NVARCHAR(500),@dVig DATE,@jTit NVARCHAR(MAX),
            @cPosterior NVARCHAR(MAX),@cIdent NVARCHAR(200),@nAud BIGINT,@nTrans BIGINT;
    SELECT @nPredioId=NULL,@bResultado=0,@cMensaje=N'No se pudo registrar el predio.';
    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente] @cJson,'PREDIOS_CREAR','PREDIO_CREAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@nOp OUTPUT,@bRep OUTPUT,@cEstadoOp OUTPUT,@cIdRes OUTPUT,@cCodRes OUTPUT,@bIni OUTPUT,@cMsg OUTPUT;
    IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    IF @bRep=1 BEGIN IF @cEstadoOp='COMPLETADA' BEGIN SET @nPredioId=TRY_CONVERT(BIGINT,@cIdRes);
 SET @bResultado=1;
 SET @cMensaje=N'La solicitud ya fue procesada correctamente.';
 END ELSE SET @cMensaje=N'La solicitud ya se encuentra en proceso.';
 GOTO __DESCO_Salida;
 END;

    SELECT @cNombre=NULLIF(LTRIM(RTRIM(nombre)),N''),@dRegistro=fechaRegistro FROM OPENJSON(@cJson,'$.predio') WITH (nombre NVARCHAR(150) '$.nombre',fechaRegistro DATE '$.fechaRegistro');
    SELECT @cDistrito=NULLIF(LTRIM(RTRIM(distritoCodigo)),''),@nCP=centroPobladoId,@cRef=NULLIF(LTRIM(RTRIM(referencia)),N''),@nLat=latitud,@nLon=longitud,@nAlt=altitudM FROM OPENJSON(@cJson,'$.ubicacion') WITH (distritoCodigo CHAR(6) '$.distritoCodigo',centroPobladoId BIGINT '$.centroPobladoId',referencia NVARCHAR(300) '$.referencia',latitud DECIMAL(9,6) '$.latitud',longitud DECIMAL(9,6) '$.longitud',altitudM DECIMAL(8,2) '$.altitudM');
    SELECT @nArea=areaTotalHa,@nAreaCult=areaCultivableHa,@cRiego=NULLIF(LTRIM(RTRIM(tipoRiego)),''),@cFuente=NULLIF(LTRIM(RTRIM(fuenteAgua)),N''),@cInfra=NULLIF(LTRIM(RTRIM(infraestructura)),N''),@cObs=NULLIF(LTRIM(RTRIM(observacion)),N''),@dVig=fechaDesde FROM OPENJSON(@cJson,'$.caracteristicas') WITH (areaTotalHa DECIMAL(10,4) '$.areaTotalHa',areaCultivableHa DECIMAL(10,4) '$.areaCultivableHa',tipoRiego VARCHAR(30) '$.tipoRiego',fuenteAgua NVARCHAR(150) '$.fuenteAgua',infraestructura NVARCHAR(300) '$.infraestructura',observacion NVARCHAR(500) '$.observacion',fechaDesde DATE '$.fechaDesde');
    SET @jTit=JSON_QUERY(@cJson,'$.titulares');
 IF @dRegistro IS NULL SET @dRegistro=CONVERT(DATE,SYSUTCDATETIME());
 IF @dVig IS NULL SET @dVig=@dRegistro;
    IF @cNombre IS NULL OR @cDistrito IS NULL OR @nArea IS NULL OR @nArea<=0 BEGIN SET @cMensaje=N'Complete los datos obligatorios del predio.';
 GOTO Fallar;
 END;
    IF @nAreaCult IS NOT NULL AND (@nAreaCult<0 OR @nAreaCult>@nArea) BEGIN SET @cMensaje=N'El área cultivable no puede superar el área total.';
 GOTO Fallar;
 END;
    IF @jTit IS NULL OR NOT EXISTS(SELECT 1 FROM OPENJSON(@jTit)) BEGIN SET @cMensaje=N'Agregue al menos un titular del predio.';
 GOTO Fallar;
 END;
    IF EXISTS(SELECT 1 FROM OPENJSON(@jTit) WITH (personaId BIGINT '$.personaId',socioId BIGINT '$.socioId',tipoTitularidad VARCHAR(20) '$.tipoTitularidad',porcentaje DECIMAL(5,2) '$.porcentaje') T
 LEFT JOIN org.Persona P ON P.persona_id=COALESCE(T.personaId,T.socioId)
 LEFT JOIN prod.TipoTitularidadCatalogo C ON C.codigo=UPPER(T.tipoTitularidad) AND C.estado=1
 WHERE P.persona_id IS NULL OR P.estado=0 OR C.codigo IS NULL OR T.porcentaje IS NULL OR T.porcentaje<=0 OR T.porcentaje>100) BEGIN SET @cMensaje=N'Revise la información de titularidad.';
 GOTO Fallar;
 END;
    IF (SELECT SUM(ISNULL(porcentaje,0)) FROM OPENJSON(@jTit) WITH (porcentaje DECIMAL(5,2) '$.porcentaje'))>100 BEGIN SET @cMensaje=N'La suma de porcentajes de titularidad no puede superar el 100%.';
 GOTO Fallar;
 END;
    IF EXISTS(SELECT COALESCE(personaId,socioId) FROM OPENJSON(@jTit) WITH (personaId BIGINT '$.personaId',socioId BIGINT '$.socioId') GROUP BY COALESCE(personaId,socioId) HAVING COUNT(*)>1) BEGIN SET @cMensaje=N'No repita un mismo titular en el predio.';
 GOTO Fallar;
 END;

    DECLARE @nUotCreacion BIGINT = TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId'));
    IF @nUotCreacion IS NULL
      SELECT TOP(1) @nUotCreacion=EU.uot_id
      FROM org.EmpleadoUOT EU WHERE EU.empleado_id=@nEmp AND EU.estado=1
        AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
        AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
        AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,EU.uot_id,'PREDIOS_CREAR')=1
      ORDER BY EU.es_principal DESC,EU.uot_id;
    IF @nUotCreacion IS NULL OR seg.FN_Usuario_TienePermisoUOT(@nUsuario,@nUotCreacion,'PREDIOS_CREAR')<>1
    BEGIN SET @cMensaje=N'Seleccione una unidad territorial autorizada.'; GOTO Fallar; END;

    BEGIN TRY
      BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
      EXEC [geo].[PA_Ubicacion_Ins_Interna] @cDistrito,@nCP,@cRef,@nLat,@nLon,@nAlt,@nUbicacion OUTPUT,@bUbi OUTPUT,@cMsgUbi OUTPUT;
      IF @bUbi=0 BEGIN BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
 SET @cMensaje=@cMsgUbi;
 GOTO Fallar;
 END;
      /* Código de predio generado por el sistema. */
      WHILE 1=1
      BEGIN
          SET @nCodigoConsecutivo = NEXT VALUE FOR [prod].[SQ_CodigoPredio];
          SET @cCodigo = 'PRE-' + RIGHT(REPLICATE('0',12) + CONVERT(VARCHAR(20),@nCodigoConsecutivo),12);
          IF NOT EXISTS(SELECT 1 FROM [prod].[Predio] WHERE codigo=@cCodigo) BREAK;
      END;

      INSERT [prod].[Predio](codigo,nombre,ubicacion_id,fecha_registro,uot_id) VALUES(@cCodigo,@cNombre,@nUbicacion,@dRegistro,@nUotCreacion);
 SET @nPredioId=CONVERT(BIGINT,SCOPE_IDENTITY());
      INSERT prod.PredioAmbito(predio_id,uot_id,usuario_creacion_id) VALUES(@nPredioId,@nUotCreacion,@nUsuario);
      INSERT [prod].[PredioVersion](predio_id,area_total_ha,area_cultivable_ha,tipo_riego,fuente_agua,infraestructura,observacion,fecha_desde,fecha_hasta)
      VALUES(@nPredioId,@nArea,@nAreaCult,@cRiego,@cFuente,@cInfra,@cObs,@dVig,NULL);
      INSERT [prod].[PredioTitularidad](predio_id,persona_id,socio_id,tipo_titularidad,porcentaje,fecha_desde,fecha_hasta,rol_titularidad)
      SELECT @nPredioId,COALESCE(X.personaId,X.socioId),S.socio_id,
        UPPER(X.tipoTitularidad),X.porcentaje,@dRegistro,NULL,
        CASE WHEN J.[key]='0' THEN 'PRINCIPAL' ELSE 'ADICIONAL' END
      FROM OPENJSON(@jTit) J
      CROSS APPLY OPENJSON(J.value) WITH (personaId BIGINT '$.personaId',socioId BIGINT '$.socioId',tipoTitularidad VARCHAR(20) '$.tipoTitularidad',porcentaje DECIMAL(5,2) '$.porcentaje') X
      LEFT JOIN org.Socio S ON S.socio_id=COALESCE(X.personaId,X.socioId) AND S.estado=1;
      INSERT prod.PredioIdentidad(persona_id,distrito_codigo,nombre_normalizado,predio_id)
      SELECT COALESCE(T.personaId,T.socioId),@cDistrito,UPPER(LTRIM(RTRIM(@cNombre))),@nPredioId
      FROM OPENJSON(@jTit) WITH(personaId BIGINT '$.personaId',socioId BIGINT '$.socioId') T
      WHERE NOT EXISTS(SELECT 1 FROM prod.PredioIdentidad I WITH(UPDLOCK,HOLDLOCK)
           WHERE I.persona_id=COALESCE(T.personaId,T.socioId) AND I.distrito_codigo=@cDistrito
             AND I.nombre_normalizado=UPPER(LTRIM(RTRIM(@cNombre))));
      SELECT @cPosterior=(SELECT PR.predio_id,PR.codigo,PR.nombre,PR.ubicacion_id,PR.fecha_registro,@nArea areaTotalHa,@nAreaCult areaCultivableHa,JSON_QUERY(@jTit) titulares FROM [prod].[Predio] PR WHERE PR.predio_id=@nPredioId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
      SET @cIdent=CONVERT(NVARCHAR(200),@nPredioId);
      EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio] @nUsuario,@nSesion,@nDisp,@nModulo,'CREAR','prod','Predio',@cIdent,NULL,@cPosterior,NULL,'estado',NULL,'1',@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
      /* Confirmar datos e idempotencia juntos. */
      EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOp,'COMPLETADA','prod','Predio',@cIdent,'PREDIO_CREADO',@bFin OUTPUT,@cMsgFin OUTPUT;
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
 SET @cMensaje=N'Predio registrado correctamente.';
 GOTO __DESCO_Salida;
    END TRY
    BEGIN CATCH
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
 SET @cMensaje=N'No se pudo registrar el predio. Intente nuevamente.';
 
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'prod.PA_Predio_Ins_Registro',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;
Fallar:
    IF @nOp IS NOT NULL AND @bResultado=0 EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOp,'FALLIDA',NULL,NULL,NULL,'NO_PROCESADO',@bFin OUTPUT,@cMsgFin OUTPUT;

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
    @cProcedimiento = N'prod.PA_Predio_Ins_Registro',
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
    @cProcedimiento = N'prod.PA_Predio_Ins_Registro',
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
    SELECT @nPredioId = NULL;

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
    @cProcedimiento = N'prod.PA_Predio_Ins_Registro',
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
FROM config.FN_RespuestaUsuario(N'prod.PA_Predio_Ins_Registro',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO


/******************************************************************************************************
' Nombre del PA           : prod.PA_Predio_Upd_Registro
' Descripción             : Actualiza los datos de predios.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Producción
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
    EXEC [prod].[PA_Predio_Upd_Registro]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE OR ALTER PROCEDURE [prod].[PA_Predio_Upd_Registro]
(
    @cJson NVARCHAR(MAX), @bResultado BIT OUTPUT, @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS
BEGIN
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
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
            @nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),
            @nPredio BIGINT,@cCodigo VARCHAR(40),@cNombre NVARCHAR(150),@jUbi NVARCHAR(MAX),@jCar NVARCHAR(MAX),@jTit NVARCHAR(MAX),@dTit DATE,
            @cDistrito CHAR(6),@nCP BIGINT,@cRef NVARCHAR(300),@nLat DECIMAL(9,6),@nLon DECIMAL(9,6),@nAlt DECIMAL(8,2),@nUbicacionActual BIGINT,@bUbi BIT,@cMsgUbi NVARCHAR(300),
            @nArea DECIMAL(10,4),@nAreaCult DECIMAL(10,4),@cRiego VARCHAR(30),@cFuente NVARCHAR(150),@cInfra NVARCHAR(300),@cObs NVARCHAR(500),@dVig DATE,@nVersionActual BIGINT,@dVersionActual DATE,
            @dTitActual DATE,@cAnterior NVARCHAR(MAX),@cPosterior NVARCHAR(MAX),@cIdent NVARCHAR(200),@nAud BIGINT,@nTrans BIGINT;
    SET @bResultado=0;
 SET @cMensaje=N'No se pudo actualizar el predio.';
    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente] @cJson,'PREDIOS_EDITAR','PREDIO_EDITAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@nOp OUTPUT,@bRep OUTPUT,@cEstadoOp OUTPUT,@cIdRes OUTPUT,@cCodRes OUTPUT,@bIni OUTPUT,@cMsg OUTPUT;
    IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    IF @bRep=1 BEGIN IF @cEstadoOp='COMPLETADA' BEGIN SET @bResultado=1;
 SET @cMensaje=N'La solicitud ya fue procesada correctamente.';
 END ELSE SET @cMensaje=N'La solicitud ya se encuentra en proceso.';
 GOTO __DESCO_Salida;
 END;

    SELECT @nPredio=predioId,@cNombre=NULLIF(LTRIM(RTRIM(nombre)),N''),@dTit=fechaTitularidad FROM OPENJSON(@cJson,'$.predio') WITH (predioId BIGINT '$.predioId',nombre NVARCHAR(150) '$.nombre',fechaTitularidad DATE '$.fechaTitularidad');
    SET @jUbi=JSON_QUERY(@cJson,'$.ubicacion');
 SET @jCar=JSON_QUERY(@cJson,'$.caracteristicas');
 SET @jTit=JSON_QUERY(@cJson,'$.titulares');
    IF @dTit IS NULL SET @dTit=CONVERT(DATE,SYSUTCDATETIME());
    IF @nPredio IS NULL OR @cNombre IS NULL BEGIN SET @cMensaje=N'Complete los datos obligatorios del predio.';
 GOTO Fallar;
 END;
    IF NOT EXISTS(SELECT 1 FROM [prod].[Predio] WHERE predio_id=@nPredio AND estado=1) BEGIN SET @cMensaje=N'El predio seleccionado no está disponible.';
 GOTO Fallar;
 END;
    IF NOT EXISTS(SELECT 1 FROM prod.PredioAmbito AM WHERE AM.predio_id=@nPredio AND AM.estado=1
        AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,AM.uot_id,'PREDIOS_EDITAR')=1
        AND (AM.convenio_uot_organizacion_id IS NULL OR
             seg.FN_Usuario_TienePermisoUOT(@nUsuario,AM.uot_id,'APAPPSS_PREDIOS_EDITAR')=1))
    BEGIN SET @cMensaje=N'No tiene acceso al ámbito del predio.'; GOTO Fallar; END;
    SELECT @nUbicacionActual=ubicacion_id FROM [prod].[Predio] WHERE predio_id=@nPredio AND estado=1;

    IF @jUbi IS NOT NULL
    BEGIN
      SELECT @cDistrito=NULLIF(LTRIM(RTRIM(distritoCodigo)),''),@nCP=centroPobladoId,@cRef=NULLIF(LTRIM(RTRIM(referencia)),N''),@nLat=latitud,@nLon=longitud,@nAlt=altitudM FROM OPENJSON(@jUbi) WITH (distritoCodigo CHAR(6) '$.distritoCodigo',centroPobladoId BIGINT '$.centroPobladoId',referencia NVARCHAR(300) '$.referencia',latitud DECIMAL(9,6) '$.latitud',longitud DECIMAL(9,6) '$.longitud',altitudM DECIMAL(8,2) '$.altitudM');
      IF @cDistrito IS NULL BEGIN SET @cMensaje=N'Seleccione una ubicación válida.';
 GOTO Fallar;
 END;
    END;

    IF @jCar IS NOT NULL
    BEGIN
      SELECT @nArea=areaTotalHa,@nAreaCult=areaCultivableHa,@cRiego=NULLIF(LTRIM(RTRIM(tipoRiego)),''),@cFuente=NULLIF(LTRIM(RTRIM(fuenteAgua)),N''),@cInfra=NULLIF(LTRIM(RTRIM(infraestructura)),N''),@cObs=NULLIF(LTRIM(RTRIM(observacion)),N''),@dVig=fechaDesde FROM OPENJSON(@jCar) WITH (areaTotalHa DECIMAL(10,4) '$.areaTotalHa',areaCultivableHa DECIMAL(10,4) '$.areaCultivableHa',tipoRiego VARCHAR(30) '$.tipoRiego',fuenteAgua NVARCHAR(150) '$.fuenteAgua',infraestructura NVARCHAR(300) '$.infraestructura',observacion NVARCHAR(500) '$.observacion',fechaDesde DATE '$.fechaDesde');
      IF @nArea IS NULL OR @nArea<=0 OR (@nAreaCult IS NOT NULL AND (@nAreaCult<0 OR @nAreaCult>@nArea)) OR @dVig IS NULL BEGIN SET @cMensaje=N'Revise las características y su fecha de vigencia.';
 GOTO Fallar;
 END;
      SELECT TOP(1) @nVersionActual=predio_version_id,@dVersionActual=fecha_desde FROM [prod].[PredioVersion] WHERE predio_id=@nPredio AND estado=1 AND fecha_hasta IS NULL ORDER BY fecha_desde DESC;
      IF @nVersionActual IS NOT NULL AND @dVig<@dVersionActual BEGIN SET @cMensaje=N'La fecha de vigencia no puede ser anterior a la versión vigente.';
 GOTO Fallar;
 END;
      IF EXISTS(SELECT 1 FROM [prod].[Parcela] WHERE predio_id=@nPredio AND estado=1 GROUP BY predio_id HAVING SUM(area_ha)>ISNULL(@nAreaCult,@nArea)) BEGIN SET @cMensaje=N'El área indicada es menor al área ya distribuida en parcelas.';
 GOTO Fallar;
 END;
    END;

    IF @jTit IS NOT NULL
    BEGIN
      IF NOT EXISTS(SELECT 1 FROM OPENJSON(@jTit)) BEGIN SET @cMensaje=N'Agregue al menos un titular del predio.';
 GOTO Fallar;
 END;
      IF EXISTS(SELECT 1 FROM OPENJSON(@jTit) WITH (personaId BIGINT '$.personaId',socioId BIGINT '$.socioId',tipoTitularidad VARCHAR(20) '$.tipoTitularidad',porcentaje DECIMAL(5,2) '$.porcentaje') T
 LEFT JOIN org.Persona P ON P.persona_id=COALESCE(T.personaId,T.socioId)
 LEFT JOIN prod.TipoTitularidadCatalogo C ON C.codigo=UPPER(T.tipoTitularidad) AND C.estado=1
 WHERE P.persona_id IS NULL OR P.estado=0 OR C.codigo IS NULL OR T.porcentaje IS NULL OR T.porcentaje<=0 OR T.porcentaje>100) BEGIN SET @cMensaje=N'Revise la información de titularidad.';
 GOTO Fallar;
 END;
      IF (SELECT SUM(ISNULL(porcentaje,0)) FROM OPENJSON(@jTit) WITH (porcentaje DECIMAL(5,2) '$.porcentaje'))>100 BEGIN SET @cMensaje=N'La suma de porcentajes de titularidad no puede superar el 100%.';
 GOTO Fallar;
 END;
    IF EXISTS(SELECT COALESCE(personaId,socioId) FROM OPENJSON(@jTit) WITH (personaId BIGINT '$.personaId',socioId BIGINT '$.socioId') GROUP BY COALESCE(personaId,socioId) HAVING COUNT(*)>1) BEGIN SET @cMensaje=N'No repita un mismo titular en el predio.';
 GOTO Fallar;
 END;
      SELECT @dTitActual=MAX(fecha_desde) FROM [prod].[PredioTitularidad] WHERE predio_id=@nPredio AND estado=1 AND fecha_hasta IS NULL;
      IF @dTitActual IS NOT NULL AND @dTit<@dTitActual BEGIN SET @cMensaje=N'La fecha de titularidad no puede ser anterior a la titularidad vigente.';
 GOTO Fallar;
 END;
    END;

    BEGIN TRY
      BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
      SELECT @cAnterior=
      (
        SELECT
            PR.predio_id,PR.codigo,PR.nombre,PR.ubicacion_id,PR.fecha_registro,PR.estado,
            JSON_QUERY
            (
                (
                    SELECT
                        U.distrito_codigo AS distritoCodigo,
                        U.centro_poblado_id AS centroPobladoId,
                        U.referencia,
                        CASE WHEN U.posicion IS NULL THEN NULL ELSE U.posicion.Lat END AS latitud,
                        CASE WHEN U.posicion IS NULL THEN NULL ELSE U.posicion.Long END AS longitud,
                        U.altitud_m AS altitudM
                    FROM [geo].[Ubicacion] U
                    WHERE U.ubicacion_id=PR.ubicacion_id
                    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER
                )
            ) AS ubicacion,
            JSON_QUERY
            (
                (
                    SELECT TOP(1) V.*
                    FROM [prod].[PredioVersion] V
                    WHERE V.predio_id=PR.predio_id
                      AND V.estado=1
                      AND V.fecha_hasta IS NULL
                    ORDER BY V.fecha_desde DESC
                    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER
                )
            ) AS caracteristicas,
            JSON_QUERY
            (
                (
                    SELECT T.socio_id,T.tipo_titularidad,T.porcentaje,T.fecha_desde
                    FROM [prod].[PredioTitularidad] T
                    WHERE T.predio_id=PR.predio_id
                      AND T.estado=1
                      AND T.fecha_hasta IS NULL
                    FOR JSON PATH
                )
            ) AS titulares
        FROM [prod].[Predio] PR
        WHERE PR.predio_id=@nPredio
        FOR JSON PATH,WITHOUT_ARRAY_WRAPPER
      );
      UPDATE [prod].[Predio] SET nombre=@cNombre WHERE predio_id=@nPredio AND estado=1;
      IF @jUbi IS NOT NULL
      BEGIN
        EXEC [geo].[PA_Ubicacion_Upd_Interna]
             @nUbicacionId=@nUbicacionActual,
             @cDistritoCodigo=@cDistrito,
             @nCentroPobladoId=@nCP,
             @cReferencia=@cRef,
             @bResultado=@bUbi OUTPUT,
             @cMensaje=@cMsgUbi OUTPUT,
             @nLatitud=@nLat,
             @nLongitud=@nLon,
             @nAltitudM=@nAlt,
             @bActualizarGeoposicion=1;
        IF @bUbi=0
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
            SET @cMensaje=@cMsgUbi;
            GOTO Fallar;
        END;
      END;
      IF @jCar IS NOT NULL
      BEGIN
        IF @nVersionActual IS NOT NULL AND @dVig=@dVersionActual
        BEGIN
          UPDATE [prod].[PredioVersion]
          SET area_total_ha=@nArea,
              area_cultivable_ha=@nAreaCult,
              tipo_riego=@cRiego,
              fuente_agua=@cFuente,
              infraestructura=@cInfra,
              observacion=@cObs
          WHERE predio_version_id=@nVersionActual;
        END
        ELSE
        BEGIN
          IF @nVersionActual IS NOT NULL
            UPDATE [prod].[PredioVersion]
            SET fecha_hasta=DATEADD(DAY,-1,@dVig),estado=0
            WHERE predio_version_id=@nVersionActual;

          INSERT [prod].[PredioVersion](predio_id,area_total_ha,area_cultivable_ha,tipo_riego,fuente_agua,infraestructura,observacion,fecha_desde,fecha_hasta)
          VALUES(@nPredio,@nArea,@nAreaCult,@cRiego,@cFuente,@cInfra,@cObs,@dVig,NULL);
        END;
      END;
      IF @jTit IS NOT NULL
      BEGIN
        IF @dTitActual IS NOT NULL AND @dTit=@dTitActual
        BEGIN
          DELETE FROM [prod].[PredioTitularidad]
          WHERE predio_id=@nPredio
            AND estado=1
            AND fecha_hasta IS NULL
            AND fecha_desde=@dTit;
        END
        ELSE
        BEGIN
          UPDATE [prod].[PredioTitularidad]
          SET fecha_hasta=DATEADD(DAY,-1,@dTit),estado=0
          WHERE predio_id=@nPredio
            AND estado=1
            AND fecha_hasta IS NULL;
        END;

        INSERT [prod].[PredioTitularidad](predio_id,persona_id,socio_id,tipo_titularidad,porcentaje,fecha_desde,fecha_hasta,rol_titularidad)
        SELECT @nPredio,COALESCE(X.personaId,X.socioId),S.socio_id,UPPER(X.tipoTitularidad),X.porcentaje,@dTit,NULL,
          CASE WHEN J.[key]='0' THEN 'PRINCIPAL' ELSE 'ADICIONAL' END
        FROM OPENJSON(@jTit) J
        CROSS APPLY OPENJSON(J.value) WITH (personaId BIGINT '$.personaId',socioId BIGINT '$.socioId',tipoTitularidad VARCHAR(20) '$.tipoTitularidad',porcentaje DECIMAL(5,2) '$.porcentaje') X
        LEFT JOIN org.Socio S ON S.socio_id=COALESCE(X.personaId,X.socioId) AND S.estado=1;
      END;
      SELECT @cPosterior=
      (
        SELECT
            PR.predio_id,PR.codigo,PR.nombre,PR.ubicacion_id,PR.fecha_registro,PR.estado,
            JSON_QUERY
            (
                (
                    SELECT
                        U.distrito_codigo AS distritoCodigo,
                        U.centro_poblado_id AS centroPobladoId,
                        U.referencia,
                        CASE WHEN U.posicion IS NULL THEN NULL ELSE U.posicion.Lat END AS latitud,
                        CASE WHEN U.posicion IS NULL THEN NULL ELSE U.posicion.Long END AS longitud,
                        U.altitud_m AS altitudM
                    FROM [geo].[Ubicacion] U
                    WHERE U.ubicacion_id=PR.ubicacion_id
                    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER
                )
            ) AS ubicacion,
            JSON_QUERY
            (
                (
                    SELECT TOP(1) V.*
                    FROM [prod].[PredioVersion] V
                    WHERE V.predio_id=PR.predio_id
                      AND V.estado=1
                      AND V.fecha_hasta IS NULL
                    ORDER BY V.fecha_desde DESC
                    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER
                )
            ) AS caracteristicas,
            JSON_QUERY
            (
                (
                    SELECT T.socio_id,T.tipo_titularidad,T.porcentaje,T.fecha_desde
                    FROM [prod].[PredioTitularidad] T
                    WHERE T.predio_id=PR.predio_id
                      AND T.estado=1
                      AND T.fecha_hasta IS NULL
                    FOR JSON PATH
                )
            ) AS titulares
        FROM [prod].[Predio] PR
        WHERE PR.predio_id=@nPredio
        FOR JSON PATH,WITHOUT_ARRAY_WRAPPER
      );
      SET @cIdent=CONVERT(NVARCHAR(200),@nPredio);
      EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio] @nUsuario,@nSesion,@nDisp,@nModulo,'EDITAR','prod','Predio',@cIdent,@cAnterior,@cPosterior,NULL,NULL,NULL,NULL,@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
      /* Confirmar datos e idempotencia juntos. */
      EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOp,'COMPLETADA','prod','Predio',@cIdent,'PREDIO_ACTUALIZADO',@bFin OUTPUT,@cMsgFin OUTPUT;
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
 SET @cMensaje=N'Predio actualizado correctamente.';
 GOTO __DESCO_Salida;
    END TRY
    BEGIN CATCH
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
 SET @cMensaje=N'No se pudo actualizar el predio. Intente nuevamente.';
 
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'prod.PA_Predio_Upd_Registro',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;
Fallar:
    IF @nOp IS NOT NULL AND @bResultado=0 EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOp,'FALLIDA',NULL,NULL,NULL,'NO_PROCESADO',@bFin OUTPUT,@cMsgFin OUTPUT;

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
    @cProcedimiento = N'prod.PA_Predio_Upd_Registro',
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
    @cProcedimiento = N'prod.PA_Predio_Upd_Registro',
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
    @cProcedimiento = N'prod.PA_Predio_Upd_Registro',
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
FROM config.FN_RespuestaUsuario(N'prod.PA_Predio_Upd_Registro',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO

GO

-- Consultas de predios por persona y rol
-- E1: read models, autorización por ámbito UOT/convenio y compatibilidad de cultivos.

/******************************************************************************************************
' Nombre del PA           : prod.PA_Predio_Sel_Listado
' Descripción             : Lista predios.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Producción
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
    EXEC [prod].[PA_Predio_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE OR ALTER PROCEDURE [prod].[PA_Predio_Sel_Listado]
(
    @cJson NVARCHAR(MAX), @bResultado BIT OUTPUT, @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS
BEGIN
    SET @cMensaje=NULL; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;

    /* Respuesta explícita; mensajes públicos aprobados. */
    SET NOCOUNT ON;
    DECLARE @__DbTranEntrada INT = @@TRANCOUNT,
            @__DbTranAbierta BIT = 0,
            @__DbSavepoint VARCHAR(32) = REPLACE(CONVERT(VARCHAR(36),NEWID()),'-',''),
            @__DbMensaje NVARCHAR(300),
            @__DbError BIT = 0;
    SET @bResultado = 0;

    BEGIN TRY

    SET NOCOUNT ON;
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bOk BIT,@cMsg NVARCHAR(300);
    DECLARE @cBuscar NVARCHAR(160),@nSocio BIGINT,@cDistrito CHAR(6),@nPagina INT=1,@nTam INT=20,@bSoloActivos BIT=NULL;
    SET @bResultado=0;
 SET @cMensaje=N'No se pudo cargar la información.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado] @cJson,'PREDIOS_LISTAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bOk OUTPUT,@cMsg OUTPUT;
    IF @bOk=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    SELECT @cBuscar=NULLIF(LTRIM(RTRIM(buscar)),N''),@nSocio=socioId,@cDistrito=NULLIF(LTRIM(RTRIM(distritoCodigo)),''),@nPagina=ISNULL(pagina,1),@nTam=ISNULL(tamanoPagina,20),@bSoloActivos=soloActivos
    FROM OPENJSON(@cJson,'$.filtros') WITH (buscar NVARCHAR(160) '$.buscar',socioId BIGINT '$.socioId',distritoCodigo CHAR(6) '$.distritoCodigo',pagina INT '$.pagina',tamanoPagina INT '$.tamanoPagina',soloActivos BIT '$.soloActivos');
    IF @nPagina<1 SET @nPagina=1;
 IF @nTam<1 SET @nTam=20;
 IF @nTam>200 SET @nTam=200;
    ;
WITH Q AS
    (
      SELECT PR.predio_id,PR.codigo,PR.nombre,PR.fecha_registro,PR.estado,U.distrito_codigo,U.centro_poblado_id,U.referencia,
             PV.area_total_ha,PV.area_cultivable_ha,PV.tipo_riego,
             T.titulares,COUNT_BIG(*) OVER() totalRegistros
      FROM [prod].[Predio] PR
      INNER JOIN [geo].[Ubicacion] U ON U.ubicacion_id=PR.ubicacion_id
      OUTER APPLY(SELECT TOP(1) V.* FROM [prod].[PredioVersion] V WHERE V.predio_id=PR.predio_id AND V.estado=1 AND V.fecha_hasta IS NULL ORDER BY V.fecha_desde DESC) PV
      OUTER APPLY
      (
        SELECT STRING_AGG(CONCAT(P.nombres,N' ',P.apellido_paterno,N' ',ISNULL(P.apellido_materno,N'')),N', ') titulares
        FROM [prod].[PredioTitularidad] PT INNER JOIN [org].[Persona] P ON P.persona_id=PT.persona_id
        WHERE PT.predio_id=PR.predio_id AND PT.estado=1 AND PT.fecha_hasta IS NULL
      ) T
      WHERE EXISTS (
            SELECT 1 FROM prod.PredioAmbito AM
            WHERE AM.predio_id=PR.predio_id AND AM.estado=1
              AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,AM.uot_id,'PREDIOS_LISTAR')=1
              AND (AM.convenio_uot_organizacion_id IS NULL OR
                   seg.FN_Usuario_TienePermisoUOT(@nUsuario,AM.uot_id,'APAPPSS_PREDIOS_LISTAR')=1)
          ) AND (@bSoloActivos IS NULL OR PR.estado=@bSoloActivos)
        AND (@cDistrito IS NULL OR U.distrito_codigo=@cDistrito)
        AND (@nSocio IS NULL OR EXISTS(SELECT 1 FROM [prod].[PredioTitularidad] X WHERE X.predio_id=PR.predio_id AND X.socio_id=@nSocio AND X.estado=1 AND X.fecha_hasta IS NULL))
        AND (@cBuscar IS NULL OR PR.codigo LIKE '%'+@cBuscar+'%' OR PR.nombre LIKE N'%'+@cBuscar+N'%' OR T.titulares LIKE N'%'+@cBuscar+N'%')
    )
    SELECT * FROM Q ORDER BY nombre,predio_id OFFSET (@nPagina-1)*@nTam ROWS FETCH NEXT @nTam ROWS ONLY;
    SET @bResultado=1;
 SET @cMensaje=N'Información cargada correctamente.';

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
    @cProcedimiento = N'prod.PA_Predio_Sel_Listado',
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
    @cProcedimiento = N'prod.PA_Predio_Sel_Listado',
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
FROM config.FN_RespuestaUsuario(N'prod.PA_Predio_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO


/******************************************************************************************************
' Nombre del PA           : prod.PA_Predio_Sel_DetalleCompleto
' Descripción             : Consulta el detalle completo de predios.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Producción
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
    EXEC [prod].[PA_Predio_Sel_DetalleCompleto]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE OR ALTER PROCEDURE [prod].[PA_Predio_Sel_DetalleCompleto]
(
    @cJson NVARCHAR(MAX), @bResultado BIT OUTPUT, @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS
BEGIN
    SET @cMensaje=NULL; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;

    /* Respuesta explícita; mensajes públicos aprobados. */
    SET NOCOUNT ON;
    DECLARE @__DbTranEntrada INT = @@TRANCOUNT,
            @__DbTranAbierta BIT = 0,
            @__DbSavepoint VARCHAR(32) = REPLACE(CONVERT(VARCHAR(36),NEWID()),'-',''),
            @__DbMensaje NVARCHAR(300),
            @__DbError BIT = 0;
    SET @bResultado = 0;

    BEGIN TRY

    SET NOCOUNT ON;
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bOk BIT,@cMsg NVARCHAR(300),@nPredio BIGINT;
    SET @bResultado=0;
 SET @cMensaje=N'No se pudo cargar el detalle.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado] @cJson,'PREDIOS_VER',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bOk OUTPUT,@cMsg OUTPUT;
    IF @bOk=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    SELECT @nPredio=predioId FROM OPENJSON(@cJson,'$.filtros') WITH (predioId BIGINT '$.predioId');
    IF @nPredio IS NULL OR NOT EXISTS(SELECT 1 FROM [prod].[Predio] WHERE predio_id=@nPredio
      AND EXISTS (SELECT 1 FROM prod.PredioAmbito AM WHERE AM.predio_id=@nPredio AND AM.estado=1
         AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,AM.uot_id,'PREDIOS_VER')=1
         AND (AM.convenio_uot_organizacion_id IS NULL OR
              seg.FN_Usuario_TienePermisoUOT(@nUsuario,AM.uot_id,'APAPPSS_PREDIOS_VER')=1))) BEGIN SET @cMensaje=N'El predio seleccionado no está disponible.';
 GOTO __DESCO_Salida;
 END;

    /* 1. Ficha + mapa + versión vigente */
    SELECT PR.predio_id,PR.codigo,PR.nombre,PR.fecha_registro,PR.estado,U.ubicacion_id,U.distrito_codigo,U.centro_poblado_id,U.referencia,
           CASE WHEN U.posicion IS NULL THEN NULL ELSE U.posicion.Lat END latitud,
           CASE WHEN U.posicion IS NULL THEN NULL ELSE U.posicion.Long END longitud,U.altitud_m,
           PV.predio_version_id,PV.area_total_ha,PV.area_cultivable_ha,PV.tipo_riego,PV.fuente_agua,PV.infraestructura,PV.observacion,PV.fecha_desde
    FROM [prod].[Predio] PR INNER JOIN [geo].[Ubicacion] U ON U.ubicacion_id=PR.ubicacion_id
    OUTER APPLY(SELECT TOP(1) V.* FROM [prod].[PredioVersion] V WHERE V.predio_id=PR.predio_id AND V.estado=1 AND V.fecha_hasta IS NULL ORDER BY V.fecha_desde DESC) PV
    WHERE PR.predio_id=@nPredio;

    /* 2. Titularidad completa */
    SELECT PT.predio_titularidad_id,PT.persona_id,PT.socio_id,P.tipo_documento,P.numero_documento,P.nombres,P.apellido_paterno,P.apellido_materno,
           PT.tipo_titularidad,PT.porcentaje,PT.rol_titularidad,PT.fecha_desde,PT.fecha_hasta,PT.estado
    FROM [prod].[PredioTitularidad] PT INNER JOIN [org].[Persona] P ON P.persona_id=PT.persona_id WHERE PT.predio_id=@nPredio ORDER BY PT.estado DESC, CASE WHEN PT.rol_titularidad='PRINCIPAL' THEN 0 ELSE 1 END,PT.fecha_desde DESC,PT.predio_titularidad_id;

    /* 3. Historial de características */
    SELECT predio_version_id,area_total_ha,area_cultivable_ha,tipo_riego,fuente_agua,infraestructura,observacion,fecha_desde,fecha_hasta,estado
    FROM [prod].[PredioVersion] WHERE predio_id=@nPredio ORDER BY fecha_desde DESC,predio_version_id DESC;

    /* 4. Parcelas y cultivos */
    SELECT PA.parcela_id,PA.codigo parcelaCodigo,PA.nombre parcelaNombre,PA.area_ha,PA.estado parcelaEstado,PA.ubicacion_id,
           PC.parcela_cultivo_id,VP.variedad_palta_id,COALESCE(VC.nombre,VP.nombre,C.nombre) variedad,PC.fecha_inicio,PC.fecha_fin,PC.situacion_cultivo,PC.estado cultivoEstado
    FROM [prod].[Parcela] PA LEFT JOIN [prod].[ParcelaCultivo] PC ON PC.parcela_id=PA.parcela_id
    LEFT JOIN [prod].[VariedadPalta] VP ON VP.variedad_palta_id=PC.variedad_palta_id
    LEFT JOIN [prod].[VariedadCultivo] VC ON VC.variedad_cultivo_id=PC.variedad_cultivo_id
    LEFT JOIN [prod].[Cultivo] C ON C.cultivo_id=COALESCE(PC.cultivo_id,VC.cultivo_id)
    WHERE PA.predio_id=@nPredio ORDER BY PA.nombre,PC.fecha_inicio DESC;

    /* 5. Evidencias vinculadas al predio */
    SELECT A.archivo_id,A.nombre_original,A.mime_type,A.secure_url,A.fecha_carga,A.categoria,A.origen_captura
    FROM [archivo].[ArchivoVinculo] AV INNER JOIN [archivo].[Archivo] A ON A.archivo_id=AV.archivo_id WHERE AV.predio_id=@nPredio AND AV.estado=1 AND A.estado=1 ORDER BY A.fecha_carga DESC;

    SET @bResultado=1;
 SET @cMensaje=N'Detalle cargado correctamente.';

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
    @cProcedimiento = N'prod.PA_Predio_Sel_DetalleCompleto',
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
    @cProcedimiento = N'prod.PA_Predio_Sel_DetalleCompleto',
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
FROM config.FN_RespuestaUsuario(N'prod.PA_Predio_Sel_DetalleCompleto',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO

GO

-- E1: alta atomica de fundo y titulares
-- V584: El alta tradicional registra predio, titularidad, ámbito y ficha productiva
-- en una única transacción gestionada por prod.PA_ExpedienteProductivo_Ejecutar.
-- Se mantienen las condiciones propias de APAPPSS y la reutilización de predios existentes.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE prod.PA_E1_Predio_Ins_Registrar
 @cJson NVARCHAR(MAX),@nUot BIGINT,@nConvenio BIGINT,@nUsuario BIGINT,
 @nPredio BIGINT OUTPUT,@nEntidad BIGINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 IF @@TRANCOUNT=0 THROW 51110,N'La alta debe ejecutarse dentro de la transaccion E1.',1;
 DECLARE @nPersona BIGINT,@cNombre NVARCHAR(150),@cDistrito CHAR(6),@nCentroPoblado BIGINT,
 @cRef NVARCHAR(300),@nLat DECIMAL(9,6),@nLon DECIMAL(9,6),@nArea DECIMAL(10,4),@nAreaCult DECIMAL(10,4),@cRiego VARCHAR(30),
 @nUbicacion BIGINT,@bUbi BIT,@cMsgUbi NVARCHAR(300),@nConsecutivo BIGINT,@cCodigo VARCHAR(40),
 @nAlt DECIMAL(8,2),@cFuente NVARCHAR(150),@cInfra NVARCHAR(300),@cObs NVARCHAR(500),
 @dRegistro DATE,@dVig DATE,@cTipoPrincipal VARCHAR(20),@jAdicionales NVARCHAR(MAX),@nSuma DECIMAL(9,2);
          SELECT @nPersona=personaId,@cNombre=nombre,@cDistrito=distritoCodigo,@nCentroPoblado=centroPobladoId,@cRef=referencia,@nLat=latitud,@nLon=longitud,@nArea=areaTotalHa,@nAreaCult=areaCultivableHa,@cRiego=tipoRiego,@nAlt=altitudM,
            @cFuente=fuenteAgua,@cInfra=infraestructura,@cObs=observacion,
            @dRegistro=fechaRegistro,@dVig=fechaDesde,@cTipoPrincipal=tipoTitularidadPrincipal
          FROM OPENJSON(@cJson,'$.datos') WITH(personaId BIGINT,nombre NVARCHAR(150),distritoCodigo CHAR(6),centroPobladoId BIGINT,referencia NVARCHAR(300),latitud DECIMAL(9,6),longitud DECIMAL(9,6),areaTotalHa DECIMAL(10,4),areaCultivableHa DECIMAL(10,4),tipoRiego VARCHAR(30),
          altitudM DECIMAL(8,2),fuenteAgua NVARCHAR(150),infraestructura NVARCHAR(300),observacion NVARCHAR(500),fechaRegistro DATE,fechaDesde DATE,tipoTitularidadPrincipal VARCHAR(20));
          SET @dRegistro=COALESCE(@dRegistro,CONVERT(DATE,SYSUTCDATETIME()));
          SET @dVig=COALESCE(@dVig,@dRegistro);
          SET @cTipoPrincipal=UPPER(COALESCE(NULLIF(LTRIM(RTRIM(@cTipoPrincipal)),''),'PROPIETARIO'));
          SET @jAdicionales=JSON_QUERY(@cJson,'$.datos.titularesAdicionales');
          SELECT @nSuma=COALESCE(SUM(porcentaje),0) FROM OPENJSON(@jAdicionales)
             WITH (porcentaje DECIMAL(5,2) '$.porcentaje');
          IF @nSuma>=100 OR @nSuma<0 OR @dRegistro>CONVERT(DATE,SYSUTCDATETIME()) OR @dVig<@dRegistro
             OR @dVig>CONVERT(DATE,SYSUTCDATETIME()) THROW 51053,N'Vigencia o porcentaje de titularidad inválido.',1;
          IF NOT EXISTS(SELECT 1 FROM prod.TipoTitularidadCatalogo WHERE codigo=@cTipoPrincipal AND estado=1)
             THROW 51053,N'Tipo del titular principal no disponible.',1;
          IF EXISTS (SELECT 1 FROM OPENJSON(@jAdicionales)
            WITH(personaId BIGINT '$.personaId',tipoTitularidad VARCHAR(20) '$.tipoTitularidad',porcentaje DECIMAL(5,2) '$.porcentaje') X
            LEFT JOIN org.Persona P ON P.persona_id=X.personaId AND P.estado=1
            LEFT JOIN prod.TipoTitularidadCatalogo T ON T.codigo=UPPER(X.tipoTitularidad) AND T.estado=1
            WHERE P.persona_id IS NULL OR T.codigo IS NULL OR X.personaId=@nPersona OR X.porcentaje<=0 OR X.porcentaje IS NULL)
             THROW 51053,N'Revise las personas adicionales y su titularidad.',1;
          IF EXISTS(SELECT personaId FROM OPENJSON(@jAdicionales) WITH(personaId BIGINT '$.personaId') GROUP BY personaId HAVING COUNT_BIG(*)>1)
             THROW 51053,N'No se puede repetir una persona como titular.',1;
          IF @nAlt IS NOT NULL AND NOT (@nAlt BETWEEN -500 AND 7000) THROW 51053,N'Altitud inválida.',1;
          SET @cNombre=NULLIF(LTRIM(RTRIM(@cNombre)),N'');
          IF @nPersona IS NULL OR @cNombre IS NULL OR LEN(@cNombre)<2 OR
             NOT EXISTS(SELECT 1 FROM org.Persona WHERE persona_id=@nPersona AND estado=1) OR
             NOT EXISTS(SELECT 1 FROM geo.Distrito WHERE distrito_codigo=@cDistrito AND estado=1) OR
             ((@nLat IS NULL AND @nLon IS NOT NULL) OR (@nLat IS NOT NULL AND @nLon IS NULL)) OR
             (@nLat IS NOT NULL AND (@nLat NOT BETWEEN -90 AND 90 OR @nLon NOT BETWEEN -180 AND 180)) OR
             (@nArea IS NOT NULL AND @nArea<=0)
             THROW 51053,N'Revise titular, nombre, distrito y coordenadas.',1;
          IF @nAreaCult IS NOT NULL AND (@nAreaCult<0 OR (@nArea IS NOT NULL AND @nAreaCult>@nArea))
             THROW 51053,N'La superficie cultivable debe estar entre cero y la superficie total.',1;
          IF @nConvenio IS NULL AND (@nArea IS NULL OR @nAreaCult IS NULL OR
             NULLIF(LTRIM(RTRIM(@cRiego)), '') IS NULL OR @nLat IS NULL OR @nLon IS NULL)
             THROW 51053,N'Complete las superficies, el tipo de riego y la ubicación del fundo.',1;
          IF @nCentroPoblado IS NOT NULL AND NOT EXISTS(
             SELECT 1 FROM geo.CentroPoblado CP
             WHERE CP.centro_poblado_id=@nCentroPoblado AND CP.distrito_codigo=@cDistrito AND CP.estado=1)
             THROW 51055,N'El centro poblado no corresponde al distrito seleccionado.',1;
          IF @nConvenio IS NOT NULL AND NOT EXISTS(
             SELECT 1 FROM org.Socio S WHERE S.socio_id=@nPersona AND S.estado=1)
             THROW 51054,N'La persona no tiene un registro de socio vigente.',1;
          IF @nConvenio IS NOT NULL AND NOT EXISTS(
             SELECT 1 FROM org.SocioAsociacion SA
             JOIN org.ConvenioUOTOrganizacion C ON C.empresa_id=SA.asociacion_id AND C.convenio_uot_organizacion_id=@nConvenio
             WHERE SA.socio_id=@nPersona AND SA.estado=1 AND SA.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
               AND (SA.fecha_hasta IS NULL OR SA.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME())))
             THROW 51054,N'El titular no tiene membresía vigente para este convenio.',1;
          SELECT @nEntidad=predio_id FROM prod.PredioIdentidad WITH(UPDLOCK,HOLDLOCK)
          WHERE persona_id=@nPersona AND distrito_codigo=@cDistrito AND nombre_normalizado=UPPER(LTRIM(RTRIM(@cNombre)));
          IF @nEntidad IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.Predio WHERE predio_id=@nEntidad AND estado=1)
             THROW 51065,N'El predio está retirado; regularice su estado antes de volver a vincularlo.',1;
          IF @nEntidad IS NOT NULL AND NOT EXISTS(
              SELECT 1 FROM prod.Predio P
              WHERE P.predio_id=@nEntidad AND
                (P.uot_id=@nUot OR EXISTS(SELECT 1 FROM prod.PredioAmbito A WHERE A.predio_id=P.predio_id AND
                   seg.FN_Usuario_TienePermisoUOT(@nUsuario,A.uot_id,'PREDIOS_VER')=1)))
              THROW 51065,N'El predio identificado existe fuera del ámbito autorizado.',1;
          IF @nEntidad IS NOT NULL AND EXISTS (SELECT 1 FROM OPENJSON(@jAdicionales))
              THROW 51053,N'No se pueden añadir titulares al reutilizar un predio; edite primero su titularidad.',1;
          IF @nEntidad IS NULL
          BEGIN
            EXEC geo.PA_Ubicacion_Ins_Interna @cDistrito,@nCentroPoblado,@cRef,@nLat,@nLon,@nAlt,@nUbicacion OUTPUT,@bUbi OUTPUT,@cMsgUbi OUTPUT;
            IF ISNULL(@bUbi,0)=0
            BEGIN
              SET @cMsgUbi=COALESCE(NULLIF(@cMsgUbi,N''),N'No se pudo registrar la ubicación.');
              THROW 51055,@cMsgUbi,1;
            END;
            SET @nConsecutivo=NEXT VALUE FOR prod.SQ_CodigoPredio;
            SET @cCodigo='PRE-'+RIGHT(REPLICATE('0',12)+CONVERT(VARCHAR(20),@nConsecutivo),12);
            INSERT prod.Predio(codigo,nombre,ubicacion_id,fecha_registro,uot_id)
            VALUES(@cCodigo,@cNombre,@nUbicacion,@dRegistro,@nUot);
            SET @nEntidad=SCOPE_IDENTITY();
            INSERT prod.PredioIdentidad(persona_id,distrito_codigo,nombre_normalizado,predio_id)
            VALUES(@nPersona,@cDistrito,UPPER(LTRIM(RTRIM(@cNombre))),@nEntidad);
            INSERT prod.PredioTitularidad(predio_id,persona_id,socio_id,tipo_titularidad,porcentaje,fecha_desde,rol_titularidad)
            SELECT @nEntidad,A.personaId,S.socio_id,A.tipoTitularidad,A.porcentaje,@dRegistro,A.rol
            FROM (
                SELECT @nPersona personaId,@cTipoPrincipal tipoTitularidad,
                  CAST(100.00-@nSuma AS DECIMAL(5,2)) porcentaje,'PRINCIPAL' rol
                UNION ALL
                SELECT X.personaId,UPPER(X.tipoTitularidad),X.porcentaje,'ADICIONAL'
                FROM OPENJSON(@jAdicionales) WITH(personaId BIGINT '$.personaId',tipoTitularidad VARCHAR(20) '$.tipoTitularidad',porcentaje DECIMAL(5,2) '$.porcentaje') X
            ) A
            LEFT JOIN org.Socio S ON S.socio_id=A.personaId AND S.estado=1;
          END;
          SET @nPredio=@nEntidad;
          UPDATE prod.PredioAmbito SET estado=1 WHERE predio_id=@nEntidad AND uot_id=@nUot AND estado=0
             AND ((@nConvenio IS NULL AND convenio_uot_organizacion_id IS NULL) OR convenio_uot_organizacion_id=@nConvenio);
          IF NOT EXISTS(SELECT 1 FROM prod.PredioAmbito WITH(UPDLOCK,HOLDLOCK) WHERE predio_id=@nEntidad AND uot_id=@nUot
             AND ((@nConvenio IS NULL AND convenio_uot_organizacion_id IS NULL) OR convenio_uot_organizacion_id=@nConvenio))
             INSERT prod.PredioAmbito(predio_id,uot_id,convenio_uot_organizacion_id,usuario_creacion_id)
             VALUES(@nEntidad,@nUot,@nConvenio,@nUsuario);
          -- El alta con superficie es UNA sola transaccion: crear, vincular y registrar ficha.
          -- Nunca sobrescribir una ficha existente cuando se reutiliza un predio por identidad.
          IF @nArea IS NOT NULL AND NOT EXISTS(
             SELECT 1 FROM prod.PredioVersion WITH(UPDLOCK,HOLDLOCK)
             WHERE predio_id=@nPredio AND estado=1 AND fecha_hasta IS NULL)
          BEGIN
            DECLARE @nRevisionAlta INT;
            SELECT @nRevisionAlta=ISNULL(MAX(revision),0)+1 FROM prod.PredioVersion WITH(UPDLOCK,HOLDLOCK)
             WHERE predio_id=@nPredio AND fecha_desde=@dVig;
            INSERT prod.PredioVersion(predio_id,area_total_ha,area_cultivable_ha,tipo_riego,fuente_agua,infraestructura,observacion,fecha_desde,revision)
            VALUES(@nPredio,@nArea,@nAreaCult,NULLIF(LTRIM(RTRIM(@cRiego)),''),
              NULLIF(LTRIM(RTRIM(@cFuente)),N''),NULLIF(LTRIM(RTRIM(@cInfra)),N''),
              NULLIF(LTRIM(RTRIM(@cObs)),N''),@dVig,@nRevisionAlta);
          END;
END;
GO

GO
