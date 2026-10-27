IF OBJECT_ID(N'[logistica].[PA_BienInventario_Sel_ListadoPaginado]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_BienInventario_Sel_ListadoPaginado];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_BienInventario_Sel_ListadoPaginado
' Descripción             : Consulta el listado paginado de bien de inventario.
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
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [logistica].[PA_BienInventario_Sel_ListadoPaginado]
        @nUsuarioId = 0,
        @nSesionUsuarioId = 0,
        @nUotId = 0,
        @cBuscar = N'',
        @nTipoBienId = 0,
        @cEstado = '',
        @nPagina = 0,
        @nTamano = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [logistica].[PA_BienInventario_Sel_ListadoPaginado]
 @nUsuarioId BIGINT,@nSesionUsuarioId BIGINT,@nUotId BIGINT=NULL,@cBuscar NVARCHAR(150)=NULL,@nTipoBienId INT=NULL,@cEstado VARCHAR(20)=NULL,@nPagina INT=1,@nTamano INT=20,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SELECT @bResultado=0,@cMensaje=N'No se pudo consultar el inventario.',@cCodigoRespuesta='BIENES_NO_LISTADOS',@nHttpRespuesta=400;
 SET @cBuscar=NULLIF(LTRIM(RTRIM(@cBuscar)),N''); SET @cEstado=UPPER(NULLIF(LTRIM(RTRIM(@cEstado)),''));
 SET @nPagina=CASE WHEN ISNULL(@nPagina,0)<1 THEN 1 ELSE @nPagina END; SET @nTamano=CASE WHEN ISNULL(@nTamano,0)<1 THEN 20 WHEN @nTamano>100 THEN 100 ELSE @nTamano END;
 DECLARE @Uot BIGINT=@nUotId,@General BIT,@Ok BIT,@Msg NVARCHAR(300);
 EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuarioId,@nSesionUsuarioId,@Uot,'INVENTARIO_LISTAR',0,@Uot OUTPUT,@General OUTPUT,@Ok OUTPUT,@Msg OUTPUT;
 IF @Ok=0 BEGIN SET @cMensaje=@Msg; RETURN 1; END;
 ;WITH B AS(
   SELECT BI.bien_inventario_id bienInventarioId,BI.uot_id uotId,U.codigo uotCodigo,U.nombre uotNombre,BI.tipo_bien_id tipoBienId,T.codigo tipoBienCodigo,T.nombre tipoBien,
          BI.codigo_patrimonial codigoPatrimonial,BI.nombre,BI.marca,BI.modelo,BI.serie,BI.estado_bien estadoBien,BI.fecha_adquisicion fechaAdquisicion,BI.monto_adquisicion montoAdquisicion,BI.moneda_adquisicion monedaAdquisicion,
          BI.proveedor_persona_id proveedorPersonaId,BI.proveedor_empresa_id proveedorEmpresaId,
          COALESCE(Emp.nombre_comercial,Emp.razon_social,CONCAT(Per.nombres,N' ',Per.apellido_paterno,CASE WHEN Per.apellido_materno IS NULL THEN N'' ELSE N' '+Per.apellido_materno END)) proveedorNombre,
          BI.observacion,V.placa,V.tipo_vehiculo tipoVehiculo,V.kilometraje_km kilometrajeKm,
          Img.archivo_id archivoPrincipalId,ISNULL(Inc.total,0) incidentesAbiertos,BI.estado
   FROM logistica.BienInventario BI JOIN org.UOT U ON U.uot_id=BI.uot_id AND U.estado=1 JOIN logistica.TipoBien T ON T.tipo_bien_id=BI.tipo_bien_id
   LEFT JOIN logistica.Vehiculo V ON V.vehiculo_id=BI.bien_inventario_id AND V.estado=1
   LEFT JOIN org.Empresa Emp ON Emp.empresa_id=BI.proveedor_empresa_id LEFT JOIN org.Persona Per ON Per.persona_id=BI.proveedor_persona_id
   OUTER APPLY(SELECT TOP(1) X.archivo_id FROM logistica.BienImagen X WHERE X.bien_inventario_id=BI.bien_inventario_id AND X.estado=1 ORDER BY X.es_principal DESC,X.orden,X.bien_imagen_id) Img
   OUTER APPLY(SELECT COUNT(*) total FROM logistica.BienIncidente X WHERE X.bien_inventario_id=BI.bien_inventario_id AND X.estado=1 AND X.estado_incidente IN('ABIERTO','EN_ATENCION')) Inc
   WHERE ((@General=0 AND BI.uot_id=@Uot) OR (@General=1 AND (@Uot IS NULL OR BI.uot_id=@Uot) AND seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,BI.uot_id,'INVENTARIO_LISTAR')=1))
     AND (@nTipoBienId IS NULL OR BI.tipo_bien_id=@nTipoBienId) AND (@cEstado IS NULL OR BI.estado_bien=@cEstado)
     AND (@cBuscar IS NULL OR BI.codigo_patrimonial LIKE N'%'+@cBuscar+N'%' OR BI.nombre LIKE N'%'+@cBuscar+N'%' OR BI.marca LIKE N'%'+@cBuscar+N'%' OR BI.modelo LIKE N'%'+@cBuscar+N'%' OR BI.serie LIKE N'%'+@cBuscar+N'%')
 )
 SELECT *,COUNT_BIG(*) OVER() totalRegistros FROM B ORDER BY uotNombre,nombre,bienInventarioId OFFSET(@nPagina-1)*@nTamano ROWS FETCH NEXT @nTamano ROWS ONLY;
 SELECT @bResultado=1,@cMensaje=N'Inventario consultado.',@cCodigoRespuesta='BIENES_LISTADOS',@nHttpRespuesta=200; RETURN 0;
END;
GO
