-- V610 - Compradores APAPPSS: catalogo administrable, busqueda local y alta/completado de campos vacios.
-- No reescribir migraciones anteriores; la consulta externa sigue en el servicio Identity/Factiliza existente.
IF OBJECT_ID(N'config.TipoDocumentoComprador', N'U') IS NULL
BEGIN
    CREATE TABLE config.TipoDocumentoComprador (
        tipo_documento_comprador_id BIGINT IDENTITY(1,1) NOT NULL
          CONSTRAINT PK_TipoDocumentoComprador PRIMARY KEY,
        codigo VARCHAR(15) NOT NULL,
        nombre NVARCHAR(120) NOT NULL,
        descripcion NVARCHAR(300) NULL,
        estado BIT NOT NULL CONSTRAINT DF_TipoDocumentoComprador_Estado DEFAULT (1),
        CONSTRAINT UQ_TipoDocumentoComprador_Codigo UNIQUE(codigo),
        CONSTRAINT CK_TipoDocumentoComprador_Codigo CHECK (
          LEN(codigo) BETWEEN 2 AND 15 AND codigo NOT LIKE '%[^A-Z0-9_]%')
    );
END;
GO

INSERT config.TipoDocumentoComprador(codigo,nombre,descripcion,estado)
SELECT V.codigo,V.nombre,V.descripcion,1
FROM (VALUES
 ('DNI',N'DNI',N'Documento nacional de identidad'),
 ('RUC',N'RUC',N'Registro unico de contribuyentes, empresa'),
 ('CE',N'Carne de extranjeria',N'Documento de persona natural'),
 ('PASAPORTE',N'Pasaporte',N'Documento de persona natural'),
 ('OTRO',N'Otro documento',N'Documento de persona natural no estandar')
) V(codigo,nombre,descripcion)
WHERE NOT EXISTS(SELECT 1 FROM config.TipoDocumentoComprador T WHERE T.codigo=V.codigo);
GO

-- La clasificacion se controla por el catalogo y los PA, no por una lista fija del esquema.
-- El cambio es necesario para permitir documentos nuevos creados por administracion.
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'org.Persona')
    AND name=N'CK_Persona_TipoDocumento')
    ALTER TABLE org.Persona DROP CONSTRAINT CK_Persona_TipoDocumento;
GO
ALTER TABLE org.Persona WITH CHECK ADD CONSTRAINT CK_Persona_TipoDocumento
  CHECK (LEN(tipo_documento) BETWEEN 2 AND 15 AND tipo_documento NOT LIKE '%[^A-Z0-9_]%');
GO

-- El formato basico existente limita explicitamente los tipos; extender sin romper los registros historicos.
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'org.Persona')
    AND name=N'CK_Persona_DocumentoFormatoBasico')
    ALTER TABLE org.Persona DROP CONSTRAINT CK_Persona_DocumentoFormatoBasico;
GO
ALTER TABLE org.Persona WITH CHECK ADD CONSTRAINT CK_Persona_DocumentoFormatoBasico
  CHECK (
    (tipo_documento='DNI' AND LEN(numero_documento)=8 AND numero_documento NOT LIKE '%[^0-9]%')
    OR (tipo_documento='RUC' AND LEN(numero_documento)=11 AND numero_documento NOT LIKE '%[^0-9]%')
    OR (tipo_documento IN('OTRO','PASAPORTE','CE') AND LEN(LTRIM(RTRIM(numero_documento)))>0)
    OR (tipo_documento NOT IN('DNI','RUC','CE','PASAPORTE','OTRO')
       AND LEN(LTRIM(RTRIM(numero_documento))) BETWEEN 5 AND 30
       AND numero_documento NOT LIKE '%[^A-Z0-9]%')
  );
GO


-- Administracion / listar tipos con uso y permisos vigentes
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
    ELSE IF @cCat = 'TIPO_DOCUMENTO_COMPRADOR'
    BEGIN
        SELECT T.tipo_documento_comprador_id AS id,T.codigo,T.nombre,T.descripcion,T.estado,
          U.cantidadUso,
          CONVERT(BIT,CASE WHEN U.cantidadUso>0 THEN 1 ELSE 0 END) AS enUso,
          COUNT_BIG(*) OVER() AS totalRegistros
        FROM config.TipoDocumentoComprador T
        CROSS APPLY (SELECT
          (SELECT COUNT_BIG(*) FROM org.Persona P WHERE P.tipo_documento=T.codigo)
          +(CASE WHEN T.codigo='RUC' THEN (SELECT COUNT_BIG(*) FROM org.Empresa E) ELSE CONVERT(BIGINT,0) END)
          AS cantidadUso) U
        ORDER BY T.nombre,T.tipo_documento_comprador_id
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


-- Administracion / crear documento con codigo estable
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
ELSE IF @cCat='TIPO_DOCUMENTO_COMPRADOR' BEGIN
 SET @cCodigo=UPPER(NULLIF(TRIM(JSON_VALUE(@cJson,'$.catalogo.codigo')),''));
 IF @cCodigo IS NULL OR LEN(@cCodigo) NOT BETWEEN 2 AND 15 OR @cCodigo LIKE '%[^A-Z0-9_]%' 
    THROW 53401,N'CODIGO_DOCUMENTO_INVALIDO',1;
 IF EXISTS(SELECT 1 FROM config.TipoDocumentoComprador WHERE codigo=@cCodigo)
    THROW 53401,N'VALOR_DUPLICADO',1;
 INSERT config.TipoDocumentoComprador(codigo,nombre,descripcion,estado)
 VALUES(@cCodigo,@cNombre,@cDesc,1);
 SET @nCatalogoId=CONVERT(BIGINT,SCOPE_IDENTITY());
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
IF @cCat<>'TIPO_DOCUMENTO_COMPRADOR'
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


-- Administracion / editar etiquetas (codigo inmutable)
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
ELSE IF @cCat='TIPO_DOCUMENTO_COMPRADOR' UPDATE config.TipoDocumentoComprador
 SET nombre=@cNombre,descripcion=@cDesc WHERE tipo_documento_comprador_id=@nId AND estado=1;
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


-- Administracion / deshabilitar tipos no usados
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
ELSE IF @cCat='TIPO_DOCUMENTO_COMPRADOR' UPDATE T SET estado=0
 FROM config.TipoDocumentoComprador T
 WHERE T.tipo_documento_comprador_id=@nId AND T.estado=1
 AND T.codigo NOT IN('DNI','RUC')
 AND NOT EXISTS(SELECT 1 FROM org.Persona P WHERE P.tipo_documento=T.codigo);
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

-- Consulta el mismo catalogo administrable desde la pantalla de Compradores.
CREATE OR ALTER PROCEDURE comercial.PA_APAPPSS_TipoDocumento_Sel_Listado
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT, @cCodigoRespuesta VARCHAR(60) OUTPUT, @nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudieron consultar documentos.',
   @cCodigoRespuesta='APAPPSS_DOCUMENTOS_ERROR',@nHttpRespuesta=403;
 DECLARE @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
   @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
   @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
   @acceso BIT,@mensajeAcceso NVARCHAR(300);
 BEGIN TRY
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='APAPPSS_COMPRADORES_CREAR',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR @uot IS NULL
      OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'APAPPSS_COMPRADORES_CREAR')<>1
    THROW 51831,N'No tiene autorización para consultar documentos.',1;
  SET @cDatos=(SELECT JSON_QUERY((SELECT codigo,nombre FROM config.TipoDocumentoComprador
    WHERE estado=1 ORDER BY CASE codigo WHEN 'DNI' THEN 0 WHEN 'RUC' THEN 1
        WHEN 'CE' THEN 2 WHEN 'PASAPORTE' THEN 3 ELSE 4 END,nombre FOR JSON PATH)) AS items
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Documentos consultados.',
    @cCodigoRespuesta='APAPPSS_DOCUMENTOS_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  SELECT @cDatos=NULL,@bResultado=0,@cMensaje=LEFT(ERROR_MESSAGE(),300),
    @cCodigoRespuesta='APAPPSS_DOCUMENTOS_ERROR',@nHttpRespuesta=403;
 END CATCH;
END;
GO

-- Consulta EXACTA en DESCO; no llama proveedor ni crea personas.
CREATE OR ALTER PROCEDURE comercial.PA_APAPPSS_Comprador_Sel_IdentidadLocal
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT, @cCodigoRespuesta VARCHAR(60) OUTPUT, @nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo consultar la identidad.',
   @cCodigoRespuesta='APAPPSS_IDENTIDAD_ERROR',@nHttpRespuesta=400;
 DECLARE @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
   @tipoDoc VARCHAR(15)=UPPER(NULLIF(TRIM(JSON_VALUE(@cJson,'$.filtros.tipoDocumento')),'')),
   @doc VARCHAR(30)=UPPER(NULLIF(TRIM(JSON_VALUE(@cJson,'$.filtros.documento')),'')),
   @tipo VARCHAR(10),@entidad BIGINT=NULL,@comprador BIGINT=NULL,
   @nombres NVARCHAR(100)=NULL,@paterno NVARCHAR(80)=NULL,@materno NVARCHAR(80)=NULL,
   @razon NVARCHAR(200)=NULL,@comercial NVARCHAR(160)=NULL,
   @telefono VARCHAR(30)=NULL,@correo VARCHAR(180)=NULL,
   @fecha DATE=NULL,@sexo VARCHAR(20)=NULL,
   @distrito CHAR(6)=NULL,@centro BIGINT=NULL,@referencia NVARCHAR(300)=NULL,
   @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
   @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
   @acceso BIT,@mensajeAcceso NVARCHAR(300);
 BEGIN TRY
  IF @uot IS NULL OR @tipoDoc IS NULL OR @doc IS NULL OR LEN(@doc) NOT BETWEEN 5 AND 30
    THROW 51832,N'Ingrese un documento válido.',1;
  IF NOT EXISTS(SELECT 1 FROM config.TipoDocumentoComprador
      WHERE codigo=@tipoDoc AND estado=1)
    THROW 51832,N'Tipo de documento no habilitado.',1;
  SET @tipo=CASE WHEN @tipoDoc='RUC' THEN 'EMPRESA' ELSE 'PERSONA' END;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='APAPPSS_COMPRADORES_CREAR',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'APAPPSS_COMPRADORES_CREAR')<>1
    THROW 51833,N'No tiene autorización para consultar identidades.',1;
  IF NOT EXISTS (SELECT 1 FROM org.ConvenioUOTOrganizacion CU
      JOIN org.Empresa E ON E.empresa_id=CU.empresa_id AND E.ruc='20602771394' AND E.estado=1
      JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND CM.estado=1
      JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
      JOIN org.UOT U ON U.uot_id=CU.uot_id AND U.estado=1 AND U.es_raiz=0
      WHERE CU.uot_id=@uot AND CU.estado=1 AND CU.tipo_vinculo='ASOCIACION'
      AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())))
      AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()))))
    THROW 51834,N'La UOT no tiene convenio vigente con APAPPSS.',1;
  IF @tipo='PERSONA'
  BEGIN
    SELECT TOP(1) @entidad=P.persona_id,@nombres=P.nombres,@paterno=P.apellido_paterno,
      @materno=P.apellido_materno,@telefono=P.telefono,@correo=P.correo,
      @fecha=P.fecha_nacimiento,@sexo=P.sexo,@distrito=G.distrito_codigo,
      @centro=G.centro_poblado_id,@referencia=G.referencia
    FROM org.Persona P
    LEFT JOIN geo.Ubicacion G ON G.ubicacion_id=P.ubicacion_id
    WHERE P.tipo_documento=@tipoDoc AND P.numero_documento=@doc AND P.estado=1
    ORDER BY P.persona_id;
  END
  ELSE
  BEGIN
    SELECT TOP(1) @entidad=E.empresa_id,@razon=E.razon_social,@comercial=E.nombre_comercial,
      @telefono=E.telefono,@correo=E.correo,@distrito=G.distrito_codigo,
      @centro=G.centro_poblado_id,@referencia=G.referencia
    FROM org.Empresa E
    LEFT JOIN geo.Ubicacion G ON G.ubicacion_id=E.ubicacion_id
    WHERE E.ruc=@doc AND E.estado=1
    ORDER BY E.empresa_id;
  END;
  IF @entidad IS NOT NULL
    SELECT @comprador=B.comprador_apappss_id
    FROM comercial.CompradorAPAPPSS B
    WHERE B.uot_id=@uot AND B.estado=1 AND
      ((@tipo='PERSONA' AND B.persona_id=@entidad) OR (@tipo='EMPRESA' AND B.empresa_id=@entidad));
  SET @cDatos=(SELECT CONVERT(BIT,CASE WHEN @entidad IS NULL THEN 0 ELSE 1 END) encontrado,
    @comprador compradorId,@tipo tipo,@entidad entidadId,@nombres nombres,@paterno apellidoPaterno,
    @materno apellidoMaterno,@razon razonSocial,@comercial nombreComercial,
    @telefono telefono,@correo correo,@fecha fechaNacimiento,@sexo sexo,
    @distrito distritoCodigo,@centro centroPobladoId,@referencia referencia
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
  SELECT @bResultado=1,@cMensaje=N'Consulta local completada.',
    @cCodigoRespuesta='APAPPSS_IDENTIDAD_LOCAL_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  SELECT @cDatos=NULL,@bResultado=0,@cMensaje=LEFT(ERROR_MESSAGE(),300),
    @cCodigoRespuesta='APAPPSS_IDENTIDAD_ERROR',@nHttpRespuesta=403;
 END CATCH;
END;
GO

-- Registrar comprador sin duplicar identidad y completando EXCLUSIVAMENTE campos faltantes.
CREATE OR ALTER PROCEDURE comercial.PA_APAPPSS_Comprador_Ins_Registro
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT, @cCodigoRespuesta VARCHAR(60) OUTPUT, @nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo registrar al comprador.',
   @cCodigoRespuesta='APAPPSS_COMPRADOR_ERROR',@nHttpRespuesta=400;
 DECLARE @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
   @tipo VARCHAR(10)=UPPER(NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.tipo')),'')),
   @tipoDocumento VARCHAR(15)=UPPER(NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.tipoDocumento')),'')),
   @doc VARCHAR(30)=UPPER(NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.documento')),'')),
   @nombres NVARCHAR(100)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.nombres')),N''),
   @paterno NVARCHAR(80)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.apellidoPaterno')),N''),
   @materno NVARCHAR(80)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.apellidoMaterno')),N''),
   @razon NVARCHAR(200)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.razonSocial')),N''),
   @comercial NVARCHAR(160)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.nombreComercial')),N''),
   @telefono VARCHAR(30)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.telefono')),''),
   @correo VARCHAR(180)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.correo')),''),
   @fecha DATE=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaNacimiento'),23),
   @sexo VARCHAR(20)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.sexo')),''),
   @distrito CHAR(6)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.distritoCodigo')),''),
   @centro BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.centroPobladoId')),
   @referencia NVARCHAR(300)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.referencia')),N''),
   @persona BIGINT=NULL,@empresa BIGINT=NULL,@id BIGINT=NULL,@ubicacion BIGINT=NULL,@locked INT,
   @okUbicacion BIT,@msgUbicacion NVARCHAR(300),
   @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
   @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
   @acceso BIT,@mensajeAcceso NVARCHAR(300);
 BEGIN TRY
   IF @uot IS NULL OR @tipo NOT IN('PERSONA','EMPRESA') OR @doc IS NULL OR @tipoDocumento IS NULL
      THROW 51821,N'Identifique el comprador y la UOT.',1;
   IF (@tipoDocumento='RUC' AND @tipo<>'EMPRESA') OR (@tipoDocumento<>'RUC' AND @tipo<>'PERSONA')
      OR LEN(@tipoDocumento) NOT BETWEEN 2 AND 15
      OR @tipoDocumento LIKE '%[^A-Z0-9_]%' OR @doc LIKE '%[^A-Z0-9]%'
      OR (@tipoDocumento='DNI' AND (LEN(@doc)<>8 OR @doc LIKE '%[^0-9]%'))
      OR (@tipoDocumento='RUC' AND (LEN(@doc)<>11 OR @doc LIKE '%[^0-9]%'))
      OR (@tipoDocumento='CE' AND LEN(@doc) NOT BETWEEN 6 AND 20)
      OR (@tipoDocumento NOT IN('DNI','RUC','CE') AND LEN(@doc) NOT BETWEEN 5 AND 30)
      THROW 51822,N'El documento o tipo de persona no es válido.',1;
   IF NOT EXISTS(SELECT 1 FROM config.TipoDocumentoComprador WHERE codigo=@tipoDocumento AND estado=1)
      THROW 51822,N'El tipo de documento no está habilitado en Administración.',1;
   IF @correo IS NOT NULL AND @correo NOT LIKE '%_@_%._%'
      THROW 51822,N'Ingrese un correo válido.',1;
   IF @fecha>CONVERT(DATE,SYSUTCDATETIME()) OR
      (JSON_VALUE(@cJson,'$.datos.fechaNacimiento') IS NOT NULL AND @fecha IS NULL)
      THROW 51822,N'La fecha de nacimiento no es válida.',1;
   IF @distrito IS NOT NULL AND NOT EXISTS(SELECT 1 FROM geo.Distrito WHERE distrito_codigo=@distrito AND estado=1)
      THROW 51822,N'El distrito seleccionado no existe.',1;
   IF @centro IS NOT NULL AND (@distrito IS NULL OR NOT EXISTS(
      SELECT 1 FROM geo.CentroPoblado WHERE centro_poblado_id=@centro AND distrito_codigo=@distrito AND estado=1))
      THROW 51822,N'El centro poblado no corresponde al distrito.',1;
   EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='APAPPSS_COMPRADORES_CREAR',
     @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
     @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
     @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
     @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
   IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'APAPPSS_COMPRADORES_CREAR')<>1
      THROW 51823,N'No tiene permiso para registrar compradores.',1;
   IF NOT EXISTS (SELECT 1 FROM org.ConvenioUOTOrganizacion CU
      JOIN org.Empresa E ON E.empresa_id=CU.empresa_id AND E.ruc='20602771394' AND E.estado=1
      JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND CM.estado=1
      JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
      JOIN org.UOT U ON U.uot_id=CU.uot_id AND U.estado=1 AND U.es_raiz=0
      WHERE CU.uot_id=@uot AND CU.estado=1 AND CU.tipo_vinculo='ASOCIACION'
      AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())))
      AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()))))
      THROW 51824,N'La UOT no tiene convenio vigente con APAPPSS.',1;
   BEGIN TRANSACTION;
   DECLARE @lockName NVARCHAR(255)=CONCAT(N'APAPPSS:COMPRADOR:',@tipo,N':',@tipoDocumento,N':',@doc);
   EXEC @locked=sys.sp_getapplock @Resource=@lockName,@LockMode='Exclusive',
     @LockOwner='Transaction',@LockTimeout=5000;
   IF @locked<0 THROW 51825,N'El comprador está siendo registrado por otro usuario.',1;

   IF @tipo='PERSONA'
   BEGIN
     SELECT TOP(1) @persona=P.persona_id,@ubicacion=P.ubicacion_id
       FROM org.Persona P WITH(UPDLOCK,HOLDLOCK)
       WHERE P.tipo_documento=@tipoDocumento AND P.numero_documento=@doc
       ORDER BY P.persona_id;
     IF @persona IS NULL AND (@nombres IS NULL OR @paterno IS NULL)
       THROW 51822,N'Complete los nombres y apellido paterno de la persona.',1;
     IF @persona IS NOT NULL AND NOT EXISTS(SELECT 1 FROM org.Persona WHERE persona_id=@persona AND estado=1)
       THROW 51826,N'La persona existe pero está inactiva.',1;
   END
   ELSE
   BEGIN
     IF @doc='20602771394' THROW 51827,N'La asociación APAPPSS no puede ser su propio comprador.',1;
     SELECT TOP(1) @empresa=E.empresa_id,@ubicacion=E.ubicacion_id
       FROM org.Empresa E WITH(UPDLOCK,HOLDLOCK) WHERE E.ruc=@doc ORDER BY E.empresa_id;
     IF @empresa IS NULL AND @razon IS NULL
       THROW 51822,N'Ingrese la razón social de la empresa.',1;
     IF @empresa IS NOT NULL AND NOT EXISTS(SELECT 1 FROM org.Empresa WHERE empresa_id=@empresa AND estado=1)
       THROW 51828,N'La empresa existe pero está inactiva.',1;
   END;

   -- Sólo completar la ubicación si aún no existe o si se facilitan campos vacíos compatibles.
   IF @ubicacion IS NULL AND @distrito IS NOT NULL
   BEGIN
     EXEC geo.PA_Ubicacion_Ins_Interna @cDistritoCodigo=@distrito,
       @nCentroPobladoId=@centro,@cReferencia=@referencia,
       @nLatitud=NULL,@nLongitud=NULL,@nAltitudM=NULL,
       @nUbicacionId=@ubicacion OUTPUT,@bResultado=@okUbicacion OUTPUT,@cMensaje=@msgUbicacion OUTPUT;
     IF ISNULL(@okUbicacion,0)<>1 OR @ubicacion IS NULL
       THROW 51829,N'No se pudo registrar la ubicación del comprador.',1;
   END
   ELSE IF @ubicacion IS NOT NULL AND @distrito IS NOT NULL
   BEGIN
     IF EXISTS(SELECT 1 FROM geo.Ubicacion U WHERE U.ubicacion_id=@ubicacion AND U.distrito_codigo<>@distrito)
       THROW 51829,N'La ubicación existente no coincide con el distrito ingresado.',1;
     UPDATE geo.Ubicacion
       SET centro_poblado_id=COALESCE(centro_poblado_id,@centro),
           referencia=CASE WHEN NULLIF(TRIM(referencia),N'') IS NULL THEN @referencia ELSE referencia END
     WHERE ubicacion_id=@ubicacion AND estado=1
       AND ((centro_poblado_id IS NULL AND @centro IS NOT NULL)
         OR (NULLIF(TRIM(referencia),N'') IS NULL AND @referencia IS NOT NULL));
   END;

   IF @tipo='PERSONA'
   BEGIN
     IF @persona IS NULL
     BEGIN
       INSERT org.Persona(tipo_persona,tipo_documento,numero_documento,nombres,apellido_paterno,
         apellido_materno,telefono,correo,fecha_nacimiento,sexo,ubicacion_id,estado)
       VALUES('NATURAL',@tipoDocumento,@doc,@nombres,@paterno,@materno,@telefono,@correo,
         @fecha,@sexo,@ubicacion,1);
       SET @persona=CONVERT(BIGINT,SCOPE_IDENTITY());
     END
     ELSE
       UPDATE org.Persona SET
         nombres=CASE WHEN NULLIF(TRIM(nombres),N'') IS NULL THEN COALESCE(@nombres,nombres) ELSE nombres END,
         apellido_paterno=CASE WHEN NULLIF(TRIM(apellido_paterno),N'') IS NULL THEN COALESCE(@paterno,apellido_paterno) ELSE apellido_paterno END,
         apellido_materno=CASE WHEN NULLIF(TRIM(apellido_materno),N'') IS NULL THEN COALESCE(@materno,apellido_materno) ELSE apellido_materno END,
         telefono=CASE WHEN NULLIF(TRIM(telefono),'') IS NULL THEN COALESCE(@telefono,telefono) ELSE telefono END,
         correo=CASE WHEN NULLIF(TRIM(correo),'') IS NULL THEN COALESCE(@correo,correo) ELSE correo END,
         fecha_nacimiento=COALESCE(fecha_nacimiento,@fecha),sexo=COALESCE(NULLIF(TRIM(sexo),''),@sexo),
         ubicacion_id=COALESCE(ubicacion_id,@ubicacion)
       WHERE persona_id=@persona AND estado=1;
   END
   ELSE
   BEGIN
     IF @empresa IS NULL
     BEGIN
       INSERT org.Empresa(ruc,razon_social,nombre_comercial,telefono,correo,ubicacion_id,estado)
       VALUES(@doc,@razon,@comercial,@telefono,@correo,@ubicacion,1);
       SET @empresa=CONVERT(BIGINT,SCOPE_IDENTITY());
     END
     ELSE
       UPDATE org.Empresa SET
         razon_social=CASE WHEN NULLIF(TRIM(razon_social),N'') IS NULL THEN COALESCE(@razon,razon_social) ELSE razon_social END,
         nombre_comercial=CASE WHEN NULLIF(TRIM(nombre_comercial),N'') IS NULL THEN COALESCE(@comercial,nombre_comercial) ELSE nombre_comercial END,
         telefono=CASE WHEN NULLIF(TRIM(telefono),'') IS NULL THEN COALESCE(@telefono,telefono) ELSE telefono END,
         correo=CASE WHEN NULLIF(TRIM(correo),'') IS NULL THEN COALESCE(@correo,correo) ELSE correo END,
         ubicacion_id=COALESCE(ubicacion_id,@ubicacion)
       WHERE empresa_id=@empresa AND estado=1;
   END;

   SELECT @id=B.comprador_apappss_id FROM comercial.CompradorAPAPPSS B WITH(UPDLOCK,HOLDLOCK)
     WHERE B.uot_id=@uot AND ((@tipo='PERSONA' AND B.persona_id=@persona)
       OR (@tipo='EMPRESA' AND B.empresa_id=@empresa));
   IF @id IS NULL
   BEGIN
     INSERT comercial.CompradorAPAPPSS(uot_id,tipo,persona_id,empresa_id,estado)
       VALUES(@uot,@tipo,@persona,@empresa,1);
     SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
   END
   ELSE UPDATE comercial.CompradorAPAPPSS SET estado=1 WHERE comprador_apappss_id=@id;
   SET @cDatos=(SELECT @id compradorId,@tipo tipo,@persona personaId,@empresa empresaId
     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
   COMMIT TRANSACTION;
   SELECT @bResultado=1,@cMensaje=N'Comprador registrado.',
     @cCodigoRespuesta='APAPPSS_COMPRADOR_OK',@nHttpRespuesta=201;
 END TRY BEGIN CATCH
   IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
   SELECT @cDatos=NULL,@bResultado=0,
     @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51820 AND 51849 THEN LEFT(ERROR_MESSAGE(),300)
       ELSE N'No se pudo registrar al comprador.' END,
     @cCodigoRespuesta='APAPPSS_COMPRADOR_ERROR',
     @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51820 AND 51849 OR ERROR_NUMBER() IN(2601,2627) THEN 409 ELSE 500 END;
 END CATCH;
END;
GO
