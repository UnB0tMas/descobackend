IF OBJECT_ID(N'[config].[PA_Catalogo_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [config].[PA_Catalogo_Sel_Listado];
GO

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
CREATE PROCEDURE [config].[PA_Catalogo_Sel_Listado]
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

    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
         @cJson = @cJson,
         @cCodigoPermiso = 'CATALOGOS_LISTAR',
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
