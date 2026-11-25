IF OBJECT_ID(N'[config].[PA_CatalogoRecurso_Sel_Listado]') IS NOT NULL
    DROP PROCEDURE [config].[PA_CatalogoRecurso_Sel_Listado];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : config.PA_CatalogoRecurso_Sel_Listado
' Descripción            : Consulta información de Catalogo Recurso (listado).
' Aplicativo / Módulo    : DESCO / config
*******************************************************************************************************/
CREATE   PROCEDURE [config].[PA_CatalogoRecurso_Sel_Listado]
    @nUsuarioId BIGINT,
    @cCatalogo VARCHAR(40),
    @nPagina INT=1,
    @nTamano INT=20,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @bResultado=0,@cMensaje=N'No se pudo consultar el catálogo.',@cCodigoRespuesta='CATALOGO_NO_LISTADO',@nHttpRespuesta=400;
    SET @cCatalogo=UPPER(NULLIF(LTRIM(RTRIM(@cCatalogo)),''));
    SET @nPagina=CASE WHEN ISNULL(@nPagina,0)<1 THEN 1 ELSE @nPagina END;
    SET @nTamano=CASE WHEN ISNULL(@nTamano,0)<1 THEN 20 WHEN @nTamano>100 THEN 100 ELSE @nTamano END;
    IF @cCatalogo NOT IN('TIPO_VEHICULO','UNIDAD_MEDIDA','CATEGORIA_PRODUCTO','MONEDA','CARGO_EMPLEADO','TIPO_TITULARIDAD_PREDIO') BEGIN SET @cMensaje=N'El catálogo seleccionado no está disponible.'; RETURN 1; END;
    IF NOT EXISTS(
        SELECT 1 FROM seg.UsuarioRol UR JOIN seg.Rol R ON R.rol_id=UR.rol_id AND R.estado=1
        JOIN seg.RolPermiso RP ON RP.rol_id=R.rol_id AND RP.estado=1
        JOIN seg.Permiso P ON P.permiso_id=RP.permiso_id AND P.estado=1 AND P.codigo='REFERENCIAS_LISTAR'
        WHERE UR.usuario_id=@nUsuarioId AND UR.estado=1 AND UR.fecha_desde<=SYSUTCDATETIME()
          AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta>SYSUTCDATETIME())
    ) BEGIN SET @cMensaje=N'No tiene permiso para consultar catálogos.'; SET @cCodigoRespuesta='NO_AUTORIZADO'; SET @nHttpRespuesta=403; RETURN 1; END;

    ;WITH C AS(
        SELECT V.*,
          CONVERT(BIGINT,
             CASE V.catalogo
              WHEN 'TIPO_VEHICULO' THEN (SELECT COUNT_BIG(*) FROM logistica.Vehiculo X WHERE UPPER(X.tipo_vehiculo)=V.codigo)
              WHEN 'UNIDAD_MEDIDA' THEN (SELECT COUNT_BIG(*) FROM logistica.Producto X WHERE UPPER(X.unidad_medida)=V.codigo)+(SELECT COUNT_BIG(*) FROM logistica.Suministro X WHERE UPPER(X.unidad_medida)=V.codigo)
              WHEN 'CATEGORIA_PRODUCTO' THEN (SELECT COUNT_BIG(*) FROM logistica.Producto X WHERE UPPER(CONVERT(VARCHAR(100),X.categoria))=V.codigo)
              WHEN 'MONEDA' THEN (SELECT COUNT_BIG(*) FROM logistica.ProductoPrecio X WHERE UPPER(X.moneda)=V.codigo)+(SELECT COUNT_BIG(*) FROM logistica.DetalleMovimientoInventario X WHERE UPPER(X.moneda)=V.codigo)+(SELECT COUNT_BIG(*) FROM logistica.BienInventario X WHERE UPPER(X.moneda_adquisicion)=V.codigo)
              WHEN 'TIPO_TITULARIDAD_PREDIO' THEN (SELECT COUNT_BIG(*) FROM prod.PredioTitularidad T WHERE T.tipo_titularidad COLLATE DATABASE_DEFAULT = V.codigo COLLATE DATABASE_DEFAULT)
              WHEN 'CARGO_EMPLEADO' THEN (SELECT COUNT_BIG(*) FROM org.EmpleadoArea X WHERE X.cargo COLLATE DATABASE_DEFAULT
                    = V.nombre COLLATE DATABASE_DEFAULT)
              ELSE 0 END) cantidadUso
        FROM config.CatalogoRecursoValor V WHERE V.catalogo=@cCatalogo
    )
    SELECT catalogo_recurso_valor_id id,codigo,nombre,descripcion,estado,cantidadUso,
           CONVERT(BIT,CASE WHEN cantidadUso>0 THEN 1 ELSE 0 END) enUso,COUNT_BIG(*) OVER() totalRegistros
    FROM C
    ORDER BY nombre,catalogo_recurso_valor_id
    OFFSET (@nPagina-1)*@nTamano ROWS FETCH NEXT @nTamano ROWS ONLY;

    SELECT @bResultado=1,@cMensaje=N'Catálogo consultado.',@cCodigoRespuesta='CATALOGO_LISTADO',@nHttpRespuesta=200;
    RETURN 0;
END;
GO
