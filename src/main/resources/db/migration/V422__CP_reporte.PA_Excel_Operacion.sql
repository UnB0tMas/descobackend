IF OBJECT_ID(N'[reporte].[PA_Excel_Operacion]') IS NOT NULL
    DROP PROCEDURE [reporte].[PA_Excel_Operacion];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : reporte.PA_Excel_Operacion
' Descripción            : Ejecuta el proceso de excel operacion.
' Aplicativo / Módulo    : DESCO / reporte
*******************************************************************************************************/
CREATE   PROCEDURE reporte.PA_Excel_Operacion
 @cAccion VARCHAR(16),@cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@nHttp SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @bResultado=0,@cDatos=NULL,@cMensaje=N'No se pudo completar la consulta.',@nHttp=400;
 IF ISJSON(@cJson)<>1 OR @cAccion NOT IN('CATALOGO','SEGMENTADORES','CREAR','LISTAR','DESCARGAR','VISTO') RETURN;
 DECLARE @u BIGINT,@s BIGINT,@disp BIGINT,@emp BIGINT,@mod INT,@uot BIGINT,@modo VARCHAR(12),
 @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
 @ok BIT,@msg NVARCHAR(300),@codigo VARCHAR(35),@perm VARCHAR(40),@fechaDesde DATE,@fechaHasta DATE,
 @almacen BIGINT,@predio BIGINT,@trabajo BIGINT,@key UNIQUEIDENTIFIER,@hoy DATE;
 BEGIN TRY
 EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,
  @cCodigoPermiso='REPORTES_LISTAR',@nUsuarioId=@u OUTPUT,@nSesionUsuarioId=@s OUTPUT,
  @nDispositivoUsuarioId=@disp OUTPUT,@nEmpleadoId=@emp OUTPUT,@nModuloId=@mod OUTPUT,
  @gCorrelacionId=@corr OUTPUT,@gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,
  @cEndpoint=@endpoint OUTPUT,@bResultado=@ok OUTPUT,@cMensaje=@msg OUTPUT;
 IF ISNULL(@ok,0)<>1
 BEGIN SELECT @cMensaje=COALESCE(@msg,N'Acceso no autorizado.'),@nHttp=403;RETURN; END;
 SELECT @uot=uot_contexto_id,@modo=modo_uot FROM seg.SesionUsuario
  WHERE sesion_usuario_id=@s AND usuario_id=@u AND estado=1 AND fecha_revocacion IS NULL;
 IF @uot IS NULL OR @modo<>'ESPECIFICA'
 OR ISNULL(seg.FN_Usuario_TienePermisoUOT(@u,@uot,'REPORTES_CONTROL_VER'),0)<>1
 OR ISNULL(seg.FN_Usuario_TienePermisoUOT(@u,@uot,'REPORTES_LISTAR'),0)<>1
 OR NOT EXISTS(SELECT 1 FROM seg.UsuarioUOT WHERE usuario_id=@u AND uot_id=@uot AND estado=1
     AND fecha_desde<=SYSUTCDATETIME() AND (fecha_hasta IS NULL OR fecha_hasta>=SYSUTCDATETIME()))
 BEGIN SELECT @cMensaje=N'No tiene acceso a esta sección.',@nHttp=403;RETURN;END;
 IF @cAccion='CATALOGO'
 BEGIN
  SET @cDatos=(SELECT C.codigo,C.nombre,C.grupo,C.descripcion FROM (VALUES
    ('POS_VENTAS',N'Ventas realizadas',N'POS',N'Registro de ventas y sus importes.', 'VENTAS_REPORTES',NULL),
    ('POS_DETALLE',N'Detalle de productos vendidos',N'POS',N'Productos, cantidades e importes por venta.','VENTAS_REPORTES',NULL),
    ('TEC_VISITAS',N'Visitas técnicas',N'TECNICA',N'Registro de visitas realizadas.','VISITAS_LISTAR',NULL),
    ('TEC_SALIDAS',N'Salidas de campo',N'TECNICA',N'Salidas y su estado.','SALIDAS_LISTAR',NULL),
    ('TEC_SANIDAD',N'Casos fitosanitarios',N'TECNICA',N'Casos y nivel de afectación.','SANIDAD_LISTAR',NULL),
    ('REC_MOVIMIENTOS',N'Movimientos de inventario',N'RECURSOS',N'Entradas y salidas registradas.','INVENTARIO_LISTAR',NULL),
    ('REC_PRODUCTOS',N'Movimientos por producto',N'RECURSOS',N'Cantidades y productos movilizados.','INVENTARIO_LISTAR',NULL),
    ('DOC_EVIDENCIAS',N'Evidencias registradas',N'DOCUMENTOS',N'Archivos vinculados a la gestión.','ARCHIVOS_LISTAR',NULL),
    ('DOC_CORRESPONDENCIA',N'Correspondencia interna',N'DOCUMENTOS',N'Documentos enviados y recibidos.','DOCS_LISTAR','DOCS_VER')
  ) C(codigo,nombre,grupo,descripcion,permiso,segundo)
  WHERE seg.FN_Usuario_TienePermisoUOT(@u,@uot,C.permiso)=1
    AND (C.segundo IS NULL OR seg.FN_Usuario_TienePermisoUOT(@u,@uot,C.segundo)=1)
  ORDER BY C.grupo,C.codigo FOR JSON PATH);
  SELECT @bResultado=1,@nHttp=200,@cMensaje=N'Reportes disponibles.';RETURN;
 END;
 IF @cAccion='SEGMENTADORES'
 BEGIN
  SET @cDatos=(SELECT
    JSON_QUERY((SELECT almacen_id id,nombre FROM logistica.Almacen
       WHERE uot_propietaria_id=@uot AND estado=1 AND (
          seg.FN_Usuario_TienePermisoUOT(@u,@uot,'VENTAS_REPORTES')=1 OR
          seg.FN_Usuario_TienePermisoUOT(@u,@uot,'INVENTARIO_LISTAR')=1) ORDER BY nombre FOR JSON PATH)) almacenes,
    JSON_QUERY((SELECT P.predio_id id,P.nombre FROM prod.Predio P
       WHERE P.uot_id=@uot AND P.estado=1 AND (
          seg.FN_Usuario_TienePermisoUOT(@u,@uot,'SALIDAS_LISTAR')=1 OR
          seg.FN_Usuario_TienePermisoUOT(@u,@uot,'VISITAS_LISTAR')=1 OR
          seg.FN_Usuario_TienePermisoUOT(@u,@uot,'SANIDAD_LISTAR')=1) AND EXISTS(
        SELECT 1 FROM prod.PredioAmbito A WHERE A.predio_id=P.predio_id AND A.uot_id=@uot
          AND A.estado=1 AND A.convenio_uot_organizacion_id IS NULL)
       ORDER BY P.nombre FOR JSON PATH)) predios
     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@nHttp=200,@cMensaje=N'Filtros disponibles.';RETURN;
 END;
 IF @cAccion IN('CREAR','DESCARGAR') AND ISNULL(seg.FN_Usuario_TienePermisoUOT(@u,@uot,'REPORTES_EXPORTAR'),0)<>1
 BEGIN SELECT @cMensaje=N'No tiene permiso para generar o descargar reportes.',@nHttp=403;RETURN;END;
 IF @cAccion='CREAR'
 BEGIN
  SELECT @codigo=UPPER(JSON_VALUE(@cJson,'$.datos.codigo')),
    @fechaDesde=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.desde')),
    @fechaHasta=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.hasta')),
    @almacen=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.almacenId')),
    @predio=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.predioId')),
    @key=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.datos.clave'));
  SET @hoy=CONVERT(DATE,(SYSUTCDATETIME() AT TIME ZONE 'UTC') AT TIME ZONE 'SA Pacific Standard Time');
  SET @fechaHasta=COALESCE(@fechaHasta,@hoy);SET @fechaDesde=COALESCE(@fechaDesde,@fechaHasta);
  IF @key IS NULL OR @codigo IS NULL OR @codigo NOT IN('POS_VENTAS','POS_DETALLE','TEC_VISITAS','TEC_SALIDAS','TEC_SANIDAD',
                 'REC_MOVIMIENTOS','REC_PRODUCTOS','DOC_EVIDENCIAS','DOC_CORRESPONDENCIA')
    OR @fechaDesde>@fechaHasta OR @fechaHasta>@hoy OR DATEDIFF(DAY,@fechaDesde,@fechaHasta)>366
  BEGIN SET @cMensaje=N'Elija un reporte y un período válido (máximo 367 días).';RETURN;END;
  SET @perm=CASE WHEN @codigo LIKE 'POS[_]%' THEN 'VENTAS_REPORTES'
                 WHEN @codigo='TEC_VISITAS' THEN 'VISITAS_LISTAR'
                 WHEN @codigo='TEC_SALIDAS' THEN 'SALIDAS_LISTAR'
                 WHEN @codigo='TEC_SANIDAD' THEN 'SANIDAD_LISTAR'
                 WHEN @codigo LIKE 'REC[_]%' THEN 'INVENTARIO_LISTAR'
                 WHEN @codigo='DOC_EVIDENCIAS' THEN 'ARCHIVOS_LISTAR'
                 ELSE 'DOCS_LISTAR' END;
  IF ISNULL(seg.FN_Usuario_TienePermisoUOT(@u,@uot,@perm),0)<>1
     OR (@codigo='DOC_CORRESPONDENCIA' AND ISNULL(seg.FN_Usuario_TienePermisoUOT(@u,@uot,'DOCS_VER'),0)<>1)
  BEGIN SELECT @cMensaje=N'No tiene acceso a este reporte.',@nHttp=403;RETURN;END;
  IF (@almacen IS NOT NULL AND LEFT(@codigo,3) NOT IN ('POS','REC'))
     OR (@predio IS NOT NULL AND LEFT(@codigo,3)<>'TEC')
     OR (@almacen IS NOT NULL AND NOT EXISTS(SELECT 1 FROM logistica.Almacen WHERE almacen_id=@almacen AND uot_propietaria_id=@uot AND estado=1))
     OR (@predio IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.PredioAmbito WHERE predio_id=@predio AND uot_id=@uot AND estado=1 AND convenio_uot_organizacion_id IS NULL))
  BEGIN SET @cMensaje=N'El filtro seleccionado no está disponible.';RETURN;END;
  SELECT @trabajo=trabajo_id FROM reporte.TrabajoExcel WHERE usuario_id=@u AND idempotencia=@key;
  IF @trabajo IS NULL
  BEGIN
   IF (SELECT COUNT(*) FROM reporte.TrabajoExcel WHERE usuario_id=@u AND uot_id=@uot AND estado IN('PENDIENTE','PROCESANDO'))>=3
   BEGIN SELECT @cMensaje=N'Tiene tres reportes pendientes. Revise sus descargas.',@nHttp=429;RETURN; END;
   INSERT reporte.TrabajoExcel(usuario_id,uot_id,idempotencia,codigo,fecha_desde,fecha_hasta,almacen_id,predio_id)
    VALUES(@u,@uot,@key,@codigo,@fechaDesde,@fechaHasta,@almacen,@predio);
   SET @trabajo=SCOPE_IDENTITY();
  END
  ELSE IF EXISTS(SELECT 1 FROM reporte.TrabajoExcel WHERE trabajo_id=@trabajo
      AND (codigo<>@codigo OR fecha_desde<>@fechaDesde OR fecha_hasta<>@fechaHasta
        OR ISNULL(almacen_id,-1)<>ISNULL(@almacen,-1) OR ISNULL(predio_id,-1)<>ISNULL(@predio,-1)))
  BEGIN SELECT @cMensaje=N'La solicitud ya se utilizó con otros filtros.',@nHttp=409;RETURN;END;
  SET @cDatos=(SELECT trabajo_id id,estado FROM reporte.TrabajoExcel WHERE trabajo_id=@trabajo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@nHttp=202,@cMensaje=N'El reporte está en preparación.';RETURN;
 END;
 SET @trabajo=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.id'));
 IF @cAccion IN('DESCARGAR','VISTO') AND NOT EXISTS(
     SELECT 1 FROM reporte.TrabajoExcel WHERE trabajo_id=@trabajo AND usuario_id=@u AND uot_id=@uot)
 BEGIN SELECT @cMensaje=N'El reporte no está disponible.',@nHttp=404;RETURN;END;
 IF @cAccion='VISTO'
 BEGIN
  UPDATE reporte.TrabajoExcel SET visto=1 WHERE trabajo_id=@trabajo AND usuario_id=@u AND uot_id=@uot AND estado='LISTO';
  SELECT @bResultado=1,@nHttp=200,@cDatos=N'{}',@cMensaje=N'Notificación leída.';RETURN;
 END;
 IF @cAccion='DESCARGAR'
 BEGIN
  SELECT @codigo=codigo FROM reporte.TrabajoExcel WHERE trabajo_id=@trabajo AND usuario_id=@u AND uot_id=@uot AND estado='LISTO';
  IF @codigo IS NULL BEGIN SELECT @cMensaje=N'El reporte aún no está listo.',@nHttp=409;RETURN;END;
  SET @perm=CASE WHEN @codigo LIKE 'POS[_]%' THEN 'VENTAS_REPORTES'
                 WHEN @codigo='TEC_VISITAS' THEN 'VISITAS_LISTAR' WHEN @codigo='TEC_SALIDAS' THEN 'SALIDAS_LISTAR'
                 WHEN @codigo='TEC_SANIDAD' THEN 'SANIDAD_LISTAR' WHEN @codigo LIKE 'REC[_]%' THEN 'INVENTARIO_LISTAR'
                 WHEN @codigo='DOC_EVIDENCIAS' THEN 'ARCHIVOS_LISTAR' ELSE 'DOCS_VER' END;
  IF ISNULL(seg.FN_Usuario_TienePermisoUOT(@u,@uot,@perm),0)<>1
  BEGIN SELECT @cMensaje=N'El acceso a este reporte cambió.',@nHttp=403;RETURN;END;
  SET @cDatos=(SELECT archivo_clave AS clave,codigo FROM reporte.TrabajoExcel WHERE trabajo_id=@trabajo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@nHttp=200,@cMensaje=N'Descarga disponible.';RETURN;
 END;
 SET @cDatos=(SELECT TOP(25) T.trabajo_id id,T.codigo,T.estado,T.fecha_desde desde,T.fecha_hasta hasta,
   T.creado_utc creadoUtc,T.total_filas filas,T.mensaje,T.visto
   FROM reporte.TrabajoExcel T WHERE T.usuario_id=@u AND T.uot_id=@uot
      AND (T.estado IN('PENDIENTE','PROCESANDO') OR T.creado_utc>=DATEADD(DAY,-30,SYSUTCDATETIME()))
      AND (T.codigo NOT LIKE 'POS[_]%' OR seg.FN_Usuario_TienePermisoUOT(@u,@uot,'VENTAS_REPORTES')=1)
      AND (T.codigo NOT LIKE 'TEC[_]%' OR seg.FN_Usuario_TienePermisoUOT(@u,@uot,CASE T.codigo WHEN 'TEC_VISITAS' THEN 'VISITAS_LISTAR' WHEN 'TEC_SALIDAS' THEN 'SALIDAS_LISTAR' ELSE 'SANIDAD_LISTAR' END)=1)
      AND (T.codigo NOT LIKE 'REC[_]%' OR seg.FN_Usuario_TienePermisoUOT(@u,@uot,'INVENTARIO_LISTAR')=1)
      AND (T.codigo<>'DOC_EVIDENCIAS' OR seg.FN_Usuario_TienePermisoUOT(@u,@uot,'ARCHIVOS_LISTAR')=1)
      AND (T.codigo<>'DOC_CORRESPONDENCIA' OR seg.FN_Usuario_TienePermisoUOT(@u,@uot,'DOCS_VER')=1)
   ORDER BY T.trabajo_id DESC FOR JSON PATH);
 SELECT @bResultado=1,@nHttp=200,@cMensaje=N'Reportes consultados.';
 END TRY
 BEGIN CATCH
  SELECT @bResultado=0,@nHttp=500,@cMensaje=N'No se pudo completar la operación.';
 END CATCH;
END;
GO
