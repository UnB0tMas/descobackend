IF OBJECT_ID(N'[reporte].[PA_InformesEspeciales_Operacion]') IS NOT NULL
    DROP PROCEDURE [reporte].[PA_InformesEspeciales_Operacion];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : reporte.PA_InformesEspeciales_Operacion
' Descripción            : Ejecuta el proceso de informes especiales operacion.
' Aplicativo / Módulo    : DESCO / reporte
*******************************************************************************************************/
CREATE   PROCEDURE reporte.PA_InformesEspeciales_Operacion
 @cAccion VARCHAR(15),@cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@nHttp SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo completar la consulta.',@nHttp=400;
 IF ISJSON(@cJson)<>1 OR @cAccion NOT IN('CATALOGO','FILTROS','CREAR','LISTAR','DESCARGAR','VISTO') RETURN;
 DECLARE @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
 @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
 @autorizado BIT,@mensaje NVARCHAR(300),@uot BIGINT,@modo VARCHAR(12),@tipo VARCHAR(30),
 @formato VARCHAR(5),@desde DATE,@hasta DATE,@hoy DATE,@clave UNIQUEIDENTIFIER,
 @convenio BIGINT,@socio BIGINT,@predio BIGINT,@campania BIGINT,@id BIGINT,@perm VARCHAR(40),@especial BIT;
 BEGIN TRY
 EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='REPORTES_LISTAR',
 @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
 @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
 @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
 @bResultado=@autorizado OUTPUT,@cMensaje=@mensaje OUTPUT;
 IF ISNULL(@autorizado,0)<>1 BEGIN SELECT @cMensaje=N'Acceso no autorizado.',@nHttp=403;RETURN;END;
 SELECT @uot=uot_contexto_id,@modo=modo_uot FROM seg.SesionUsuario
 WHERE sesion_usuario_id=@sesion AND usuario_id=@usuario AND estado=1 AND fecha_revocacion IS NULL;
 IF @uot IS NULL OR @modo<>'ESPECIFICA'
 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'REPORTES_CONTROL_VER')<>1
 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'REPORTES_LISTAR')<>1
 OR NOT EXISTS(SELECT 1 FROM seg.UsuarioUOT WHERE usuario_id=@usuario AND uot_id=@uot AND estado=1
 AND fecha_desde<=SYSUTCDATETIME() AND (fecha_hasta IS NULL OR fecha_hasta>=SYSUTCDATETIME()))
 BEGIN SELECT @cMensaje=N'No tiene acceso a esta sección.',@nHttp=403;RETURN;END;
 IF @cAccion='CATALOGO'
 BEGIN
  SET @cDatos=(SELECT codigo,nombre,grupo FROM (VALUES
   ('AP_SOCIOS',N'Socios',N'APAPPSS','APAPPSS_SOCIOS_LISTAR'),('AP_PREDIOS',N'Predios',N'APAPPSS','APAPPSS_PREDIOS_LISTAR'),
   ('AP_CAMPANIAS',N'Campañas',N'APAPPSS','CAMPANIAS_LISTAR'),('AP_VENTAS',N'Ventas y entregas',N'APAPPSS','ENTREGAS_LISTAR'),
   ('AP_COMPRADORES',N'Compradores',N'APAPPSS','COMPRADORES_LISTAR'),('AP_LIQUIDACIONES',N'Liquidaciones',N'APAPPSS','LIQUIDACIONES_LISTAR'),
   ('AP_PAGOS',N'Pagos a socios',N'APAPPSS','PAGOS_LISTAR'),
   ('AP_SANIDAD',N'Informe sanitario',N'APAPPSS','APAPPSS_PREDIOS_VER'),
   ('TEC_SANIDAD_DOC',N'Informe sanitario',N'TECNICA','SANIDAD_LISTAR')
  ) X(codigo,nombre,grupo,permiso)
  WHERE seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,X.permiso)=1
   AND (X.codigo NOT IN('AP_SANIDAD','TEC_SANIDAD_DOC') OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'REPORTES_SANIDAD_DOC_VER')=1)
   AND (X.grupo<>'APAPPSS' OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'REPORTES_APAPPSS_VER')=1)
  FOR JSON PATH);
  SELECT @bResultado=1,@nHttp=200,@cMensaje=N'Informes disponibles.';RETURN;
 END;
 IF @cAccion='FILTROS'
 BEGIN
  SET @cDatos=(SELECT
   JSON_QUERY((SELECT C.convenio_uot_organizacion_id id,COALESCE(C.numero_convenio,N'Convenio') nombre FROM org.ConvenioUOTOrganizacion C
    WHERE C.uot_id=@uot AND C.estado=1 AND EXISTS(SELECT 1 FROM org.ConvenioModuloEspecial M
      JOIN seg.ModuloEspecial E ON E.modulo_especial_id=M.modulo_especial_id AND E.codigo='COMERCIALIZACION_ASOCIATIVA'
      WHERE M.convenio_uot_organizacion_id=C.convenio_uot_organizacion_id AND M.estado=1)
    ORDER BY nombre FOR JSON PATH)) convenios,
   JSON_QUERY((SELECT DISTINCT S.socio_id id,CONCAT(P.nombres,N' ',P.apellido_paterno) nombre
     FROM org.SocioAsociacion S JOIN org.Asociacion A ON A.asociacion_id=S.asociacion_id AND A.uot_id=@uot
     JOIN org.Persona P ON P.persona_id=S.socio_id WHERE S.estado=1 ORDER BY nombre FOR JSON PATH)) socios,
   JSON_QUERY((SELECT P.predio_id id,P.nombre FROM prod.Predio P
    JOIN prod.PredioAmbito A ON A.predio_id=P.predio_id AND A.uot_id=@uot AND A.estado=1
    WHERE P.estado=1 ORDER BY P.nombre FOR JSON PATH)) predios,
   JSON_QUERY((SELECT C.campania_venta_id id,C.nombre FROM comercial.CampaniaVenta C WHERE C.uot_id=@uot AND C.estado=1
     ORDER BY C.nombre FOR JSON PATH)) campanias
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@nHttp=200,@cMensaje=N'Filtros disponibles.';RETURN;
 END;
 SELECT @tipo=UPPER(JSON_VALUE(@cJson,'$.datos.tipo')),@formato=UPPER(JSON_VALUE(@cJson,'$.datos.formato')),
 @desde=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.desde')),@hasta=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.hasta')),
 @convenio=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.convenioId')),
 @socio=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.socioId')),
 @predio=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.predioId')),
 @campania=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.campaniaId')),
 @clave=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.datos.clave')),
 @id=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.id'));
 IF @cAccion IN('DESCARGAR','VISTO')
 BEGIN
  SELECT @tipo=tipo,@formato=formato,@convenio=convenio_id FROM reporte.TrabajoEspecial
  WHERE trabajo_id=@id AND usuario_id=@usuario AND uot_id=@uot;
  IF @tipo IS NULL BEGIN SELECT @cMensaje=N'Archivo no disponible.',@nHttp=404;RETURN;END;
 END;
 IF @cAccion='LISTAR'
 BEGIN
  SET @cDatos=(SELECT TOP(30) trabajo_id id,tipo,formato,estado,fecha_desde desde,fecha_hasta hasta,
   creado_utc creadoUtc,mensaje,visto FROM reporte.TrabajoEspecial WHERE usuario_id=@usuario AND uot_id=@uot
   ORDER BY creado_utc DESC,trabajo_id DESC FOR JSON PATH);
  SELECT @bResultado=1,@nHttp=200,@cMensaje=N'Mis informes.';RETURN;
 END;
 IF @tipo NOT IN('AP_SOCIOS','AP_PREDIOS','AP_CAMPANIAS','AP_VENTAS','AP_COMPRADORES','AP_LIQUIDACIONES','AP_PAGOS','AP_SANIDAD','TEC_SANIDAD_DOC')
 BEGIN SELECT @cMensaje=N'Informe no disponible.';RETURN;END;
 SET @especial=CASE WHEN @tipo LIKE 'AP[_]%' THEN 1 ELSE 0 END;
 SET @perm=CASE WHEN @tipo='AP_SOCIOS' THEN 'APAPPSS_SOCIOS_LISTAR' WHEN @tipo='AP_PREDIOS' THEN 'APAPPSS_PREDIOS_LISTAR'
 WHEN @tipo='AP_CAMPANIAS' THEN 'CAMPANIAS_LISTAR' WHEN @tipo='AP_VENTAS' THEN 'ENTREGAS_LISTAR'
 WHEN @tipo='AP_COMPRADORES' THEN 'COMPRADORES_LISTAR' WHEN @tipo='AP_LIQUIDACIONES' THEN 'LIQUIDACIONES_LISTAR'
 WHEN @tipo='AP_PAGOS' THEN 'PAGOS_LISTAR' WHEN @tipo='AP_SANIDAD' THEN 'APAPPSS_PREDIOS_VER'
 ELSE 'SANIDAD_LISTAR' END;
 IF seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,@perm)<>1
 OR (@especial=1 AND seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'REPORTES_APAPPSS_VER')<>1)
 OR (@tipo IN('AP_SANIDAD','TEC_SANIDAD_DOC') AND seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'REPORTES_SANIDAD_DOC_VER')<>1)
 BEGIN SELECT @cMensaje=N'No tiene permiso para consultar este informe.',@nHttp=403;RETURN;END;
 IF @cAccion='VISTO'
 BEGIN
  UPDATE reporte.TrabajoEspecial SET visto=1 WHERE trabajo_id=@id AND usuario_id=@usuario AND uot_id=@uot;
  SELECT @bResultado=1,@cMensaje=N'Actualizado.',@nHttp=200;RETURN;
 END;
 IF @cAccion='DESCARGAR'
 BEGIN
  SET @cDatos=(SELECT archivo_clave clave,tipo,formato FROM reporte.TrabajoEspecial
   WHERE trabajo_id=@id AND usuario_id=@usuario AND uot_id=@uot AND estado='LISTO' FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  IF @cDatos IS NULL BEGIN SELECT @cMensaje=N'El archivo aún no está disponible.',@nHttp=404;RETURN;END;
  SELECT @bResultado=1,@cMensaje=N'Archivo disponible.',@nHttp=200;RETURN;
 END;
 IF @cAccion='CREAR'
 BEGIN
  IF seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'REPORTES_EXPORTAR')<>1
  BEGIN SELECT @cMensaje=N'No puede generar informes.',@nHttp=403;RETURN;END;
  IF @clave IS NULL OR @formato NOT IN('XLSX','PDF','DOCX')
   OR (@tipo IN('AP_SANIDAD','TEC_SANIDAD_DOC') AND @formato='XLSX')
   OR (@tipo NOT IN('AP_SANIDAD','TEC_SANIDAD_DOC') AND @formato<>'XLSX')
  BEGIN SET @cMensaje=N'Seleccione un formato válido.';RETURN;END;
  SET @hoy=CONVERT(DATE,(SYSUTCDATETIME() AT TIME ZONE 'UTC') AT TIME ZONE 'SA Pacific Standard Time');
  SELECT @hasta=COALESCE(@hasta,@hoy),@desde=COALESCE(@desde,@hasta);
  IF @desde>@hasta OR @hasta>@hoy OR DATEDIFF(DAY,@desde,@hasta)>365
  BEGIN SET @cMensaje=N'Seleccione fechas válidas.';RETURN;END;
  IF @especial=1 AND (@convenio IS NULL OR NOT EXISTS(SELECT 1 FROM org.ConvenioUOTOrganizacion C
    JOIN org.ConvenioModuloEspecial M ON M.convenio_uot_organizacion_id=C.convenio_uot_organizacion_id AND M.estado=1
    JOIN seg.ModuloEspecial E ON E.modulo_especial_id=M.modulo_especial_id AND E.codigo='COMERCIALIZACION_ASOCIATIVA'
    WHERE C.convenio_uot_organizacion_id=@convenio AND C.uot_id=@uot AND C.estado=1))
  BEGIN SET @cMensaje=N'Seleccione un convenio válido.';RETURN;END;
  IF @tipo='TEC_SANIDAD_DOC' AND @convenio IS NOT NULL
  BEGIN SET @cMensaje=N'Seleccione un predio de gestión técnica.';RETURN;END;
  IF @tipo IN('AP_SANIDAD','TEC_SANIDAD_DOC') AND @predio IS NULL
  BEGIN SET @cMensaje=N'Seleccione un predio para el informe sanitario.';RETURN;END;
  IF @predio IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.PredioAmbito
    WHERE predio_id=@predio AND uot_id=@uot AND estado=1
    AND ((@especial=1 AND convenio_uot_organizacion_id=@convenio)
      OR (@especial=0 AND convenio_uot_organizacion_id IS NULL)))
  BEGIN SET @cMensaje=N'Predio no disponible en este ámbito.';RETURN;END;
  IF @socio IS NOT NULL AND NOT EXISTS(SELECT 1 FROM org.SocioAsociacion S JOIN org.Asociacion A
    ON A.asociacion_id=S.asociacion_id WHERE S.socio_id=@socio AND S.estado=1 AND A.uot_id=@uot)
  BEGIN SET @cMensaje=N'Socio no disponible en este ámbito.';RETURN;END;
  IF @especial=1 AND @predio IS NOT NULL AND @socio IS NOT NULL AND NOT EXISTS(
   SELECT 1 FROM prod.PredioTitularidad T WHERE T.predio_id=@predio AND T.socio_id=@socio AND T.estado=1)
   AND NOT EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 T WHERE T.predio_id=@predio AND T.socio_id=@socio AND T.convenio_id=@convenio AND T.activo=1)
  BEGIN SET @cMensaje=N'El predio no corresponde al socio seleccionado.';RETURN;END;
  IF @campania IS NOT NULL AND NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta WHERE campania_venta_id=@campania AND uot_id=@uot AND estado=1)
  BEGIN SET @cMensaje=N'Campaña no disponible.';RETURN;END;
  SELECT @id=trabajo_id FROM reporte.TrabajoEspecial WHERE usuario_id=@usuario AND clave=@clave;
  IF @id IS NULL
  BEGIN
   IF (SELECT COUNT(*) FROM reporte.TrabajoEspecial WHERE usuario_id=@usuario AND estado IN('PENDIENTE','PROCESANDO'))>=3
   BEGIN SELECT @cMensaje=N'Tiene tres informes pendientes.',@nHttp=429;RETURN;END;
   INSERT reporte.TrabajoEspecial(usuario_id,uot_id,convenio_id,socio_id,predio_id,campania_id,tipo,formato,fecha_desde,fecha_hasta,clave)
    VALUES(@usuario,@uot,@convenio,@socio,@predio,@campania,@tipo,@formato,@desde,@hasta,@clave);
   SET @id=SCOPE_IDENTITY();
  END
  ELSE IF EXISTS(SELECT 1 FROM reporte.TrabajoEspecial WHERE trabajo_id=@id
   AND (tipo<>@tipo OR formato<>@formato OR fecha_desde<>@desde OR fecha_hasta<>@hasta
   OR ISNULL(convenio_id,-1)<>ISNULL(@convenio,-1) OR ISNULL(predio_id,-1)<>ISNULL(@predio,-1)
   OR ISNULL(socio_id,-1)<>ISNULL(@socio,-1) OR ISNULL(campania_id,-1)<>ISNULL(@campania,-1)))
  BEGIN SELECT @cMensaje=N'Esta solicitud ya se utilizó.',@nHttp=409;RETURN;END;
  SET @cDatos=(SELECT trabajo_id id,estado FROM reporte.TrabajoEspecial WHERE trabajo_id=@id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Informe en preparación.',@nHttp=202;RETURN;
 END;
 END TRY BEGIN CATCH
  SELECT @bResultado=0,@cMensaje=N'No se pudo procesar la solicitud.',@nHttp=500;
 END CATCH
END;
GO
