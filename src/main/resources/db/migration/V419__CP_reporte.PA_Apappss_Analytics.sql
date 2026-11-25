IF OBJECT_ID(N'[reporte].[PA_Apappss_Analytics]') IS NOT NULL
    DROP PROCEDURE [reporte].[PA_Apappss_Analytics];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : reporte.PA_Apappss_Analytics
' Descripción            : Ejecuta el proceso de apappss analytics.
' Aplicativo / Módulo    : DESCO / reporte
*******************************************************************************************************/
CREATE   PROCEDURE reporte.PA_Apappss_Analytics
 @cAccion VARCHAR(15),@cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@nHttp SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo consultar la información.',@nHttp=400;
 IF ISJSON(@cJson)<>1 OR @cAccion NOT IN('RESUMEN','FILTROS') RETURN;
 DECLARE @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
 @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
 @autorizado BIT,@mensaje NVARCHAR(300),@uot BIGINT,@modo VARCHAR(12),
 @convenio BIGINT,@socio BIGINT,@predio BIGINT,@campania BIGINT,
 @tab VARCHAR(20),@desde DATE,@hasta DATE,@hoy DATE,@inicio DATETIME2(0),@fin DATETIME2(0),@permiso VARCHAR(40),
 @fase NVARCHAR(100)=N'VALIDACION_INICIAL';
 BEGIN TRY
 SET @corr=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.correlacionId'));
 SET @fase=N'CONTEXTO_AUTORIZADO';
 EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='DASHBOARD_APAPPSS_VER',
 @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
 @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
 @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
 @bResultado=@autorizado OUTPUT,@cMensaje=@mensaje OUTPUT;
 IF ISNULL(@autorizado,0)<>1 BEGIN SELECT @cMensaje=N'Acceso no autorizado.',@nHttp=403;RETURN;END;
 SELECT @uot=uot_contexto_id,@modo=modo_uot FROM seg.SesionUsuario
 WHERE sesion_usuario_id=@sesion AND usuario_id=@usuario AND estado=1 AND fecha_revocacion IS NULL;
 IF @uot IS NULL OR @modo<>'ESPECIFICA'
  OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'REPORTES_CONTROL_VER')<>1
  OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'DASHBOARD_APAPPSS_VER')<>1
  OR NOT EXISTS(SELECT 1 FROM seg.UsuarioUOT WHERE usuario_id=@usuario AND uot_id=@uot AND estado=1
    AND fecha_desde<=SYSUTCDATETIME() AND (fecha_hasta IS NULL OR fecha_hasta>=SYSUTCDATETIME()))
 BEGIN SELECT @cMensaje=N'No tiene acceso a esta unidad.',@nHttp=403;RETURN;END;
 SELECT @tab=UPPER(JSON_VALUE(@cJson,'$.filtros.tab')),
 @desde=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.filtros.desde')),
 @hasta=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.filtros.hasta')),
 @convenio=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.convenioId')),
 @socio=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.socioId')),
 @predio=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.predioId')),
 @campania=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId'));
 DECLARE @convenios TABLE(id BIGINT PRIMARY KEY,nombre NVARCHAR(180));
 INSERT @convenios SELECT C.convenio_uot_organizacion_id,COALESCE(C.numero_convenio,N'Convenio '+CONVERT(NVARCHAR(20),C.convenio_uot_organizacion_id))
 FROM org.ConvenioUOTOrganizacion C JOIN org.ConvenioModuloEspecial CM
 ON CM.convenio_uot_organizacion_id=C.convenio_uot_organizacion_id AND CM.estado=1
 JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id
 AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
 WHERE C.uot_id=@uot AND C.estado=1;
 IF NOT EXISTS(SELECT 1 FROM @convenios) BEGIN SELECT @cMensaje=N'No hay un convenio disponible.',@nHttp=403;RETURN;END;
 IF @cAccion='FILTROS'
 BEGIN
  IF @convenio IS NOT NULL AND NOT EXISTS(SELECT 1 FROM @convenios WHERE id=@convenio)
  BEGIN SELECT @cMensaje=N'Convenio no disponible.',@nHttp=400;RETURN;END;
  SET @cDatos=(SELECT JSON_QUERY((SELECT id,nombre FROM @convenios ORDER BY nombre FOR JSON PATH)) convenios,
   JSON_QUERY((SELECT DISTINCT S.socio_id id,CONCAT(H.nombres,N' ',H.apellido_paterno,N' ',COALESCE(H.apellido_materno,N'')) nombre
    FROM org.SocioAsociacion S
    JOIN org.Asociacion A ON A.asociacion_id=S.asociacion_id AND A.uot_id=@uot
    JOIN org.Persona H ON H.persona_id=S.socio_id AND H.estado=1
    WHERE S.estado=1
      AND A.asociacion_id IN (SELECT C.empresa_id FROM org.ConvenioUOTOrganizacion C WHERE C.convenio_uot_organizacion_id IN(SELECT id FROM @convenios))
      AND (@convenio IS NULL OR A.asociacion_id=(SELECT C.empresa_id FROM org.ConvenioUOTOrganizacion C WHERE C.convenio_uot_organizacion_id=@convenio))
    ORDER BY nombre FOR JSON PATH)) socios,
   JSON_QUERY((SELECT DISTINCT P.predio_id id,P.nombre FROM prod.Predio P
    JOIN prod.PredioAmbito A ON A.predio_id=P.predio_id AND A.estado=1
    WHERE A.uot_id=@uot AND A.convenio_uot_organizacion_id IN(SELECT id FROM @convenios)
      AND (@convenio IS NULL OR A.convenio_uot_organizacion_id=@convenio)
    ORDER BY P.nombre FOR JSON PATH)) predios,
   JSON_QUERY((SELECT C.campania_venta_id id,C.nombre FROM comercial.CampaniaVenta C
    WHERE C.uot_id=@uot AND C.asociacion_id IN(SELECT O.empresa_id FROM org.ConvenioUOTOrganizacion O WHERE O.convenio_uot_organizacion_id IN(SELECT id FROM @convenios))
      AND (@convenio IS NULL OR C.asociacion_id=(SELECT O.empresa_id FROM org.ConvenioUOTOrganizacion O WHERE O.convenio_uot_organizacion_id=@convenio))
      AND C.estado=1 ORDER BY C.nombre FOR JSON PATH)) campanias
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Filtros disponibles.',@nHttp=200;RETURN;
 END;
 IF @tab NOT IN('SOCIOS','PREDIOS','CAMPANIAS','VENTAS','COMPRADORES','LIQUIDACIONES','PAGOS') OR @convenio IS NULL
 OR NOT EXISTS(SELECT 1 FROM @convenios WHERE id=@convenio)
 BEGIN SELECT @cMensaje=N'Seleccione una sección y un convenio.',@nHttp=400;RETURN;END;
 SET @permiso=CASE WHEN @tab='SOCIOS' THEN 'APAPPSS_SOCIOS_LISTAR'
 WHEN @tab='PREDIOS' THEN 'APAPPSS_PREDIOS_LISTAR'
 WHEN @tab='CAMPANIAS' THEN 'CAMPANIAS_LISTAR' WHEN @tab='VENTAS' THEN 'ENTREGAS_LISTAR'
 WHEN @tab='COMPRADORES' THEN 'COMPRADORES_LISTAR' WHEN @tab='LIQUIDACIONES' THEN 'LIQUIDACIONES_LISTAR'
 ELSE 'PAGOS_LISTAR' END;
 IF ISNULL(seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,@permiso),0)<>1
 BEGIN SELECT @cMensaje=N'No tiene acceso a esta sección.',@nHttp=403;RETURN;END;
 SET @hoy=CONVERT(DATE,(SYSUTCDATETIME() AT TIME ZONE 'UTC') AT TIME ZONE 'SA Pacific Standard Time');
 SELECT @hasta=COALESCE(@hasta,@hoy),@desde=COALESCE(@desde,@hasta);
 IF @desde>@hasta OR @hasta>@hoy OR DATEDIFF(DAY,@desde,@hasta)>365
 BEGIN SELECT @cMensaje=N'Seleccione fechas válidas.',@nHttp=400;RETURN;END;
 SET @inicio=CONVERT(DATETIME2(0),CAST(@desde AS DATETIME2(0)) AT TIME ZONE 'SA Pacific Standard Time' AT TIME ZONE 'UTC');
 SET @fin=CONVERT(DATETIME2(0),DATEADD(DAY,1,CAST(@hasta AS DATETIME2(0))) AT TIME ZONE 'SA Pacific Standard Time' AT TIME ZONE 'UTC');
 IF @socio IS NOT NULL AND NOT EXISTS(SELECT 1 FROM org.SocioAsociacion S
 JOIN org.Asociacion A ON A.asociacion_id=S.asociacion_id WHERE S.socio_id=@socio AND A.uot_id=@uot AND S.estado=1
 AND A.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio))
 BEGIN SELECT @cMensaje=N'Socio no disponible.',@nHttp=400;RETURN;END;
 IF @predio IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.PredioAmbito
 WHERE predio_id=@predio AND uot_id=@uot AND convenio_uot_organizacion_id=@convenio AND estado=1)
 BEGIN SELECT @cMensaje=N'Predio no disponible.',@nHttp=400;RETURN;END;
 IF @campania IS NOT NULL AND NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta WHERE campania_venta_id=@campania AND uot_id=@uot AND estado=1
  AND asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio))
 BEGIN SELECT @cMensaje=N'Campaña no disponible.',@nHttp=400;RETURN;END;
 DECLARE @K TABLE(codigo VARCHAR(45),titulo NVARCHAR(90),valor DECIMAL(38,4),unidad VARCHAR(8),orden INT);
 DECLARE @G TABLE(grafico VARCHAR(40),categoria NVARCHAR(250),serie NVARCHAR(80),valor DECIMAL(38,4),orden INT);
 /* Datos del convenio según unidad; filtros temporales aplicados a eventos fechados. */
 IF @tab='SOCIOS'
 BEGIN
  INSERT @K SELECT 'SOCIOS',N'Socios registrados',COUNT_BIG(DISTINCT S.socio_id),'UND',1
    FROM org.SocioAsociacion S JOIN org.Asociacion A ON A.asociacion_id=S.asociacion_id AND A.uot_id=@uot
    AND A.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio)
    WHERE S.estado=1;
  INSERT @K SELECT 'ACTIVOS',N'Membresías vigentes',COUNT_BIG(DISTINCT S.socio_id),'UND',2
    FROM org.SocioAsociacion S JOIN org.Asociacion A ON A.asociacion_id=S.asociacion_id AND A.uot_id=@uot
    AND A.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio)
    WHERE S.estado=1 AND S.fecha_desde<=@hasta AND (S.fecha_hasta IS NULL OR S.fecha_hasta>=@hasta);
  INSERT @K SELECT 'ALTAS',N'Altas en el período',COUNT_BIG(DISTINCT S.socio_id),'UND',3
    FROM org.SocioAsociacion S JOIN org.Asociacion A ON A.asociacion_id=S.asociacion_id AND A.uot_id=@uot
    AND A.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio)
    WHERE S.estado=1 AND S.fecha_desde BETWEEN @desde AND @hasta;
  INSERT @K SELECT 'PARTICIPACION',N'Socios participantes',COUNT_BIG(DISTINCT S.socio_id),'UND',4
    FROM comercial.ParticipacionCampaniaSocio P JOIN org.SocioAsociacion S ON S.socio_asociacion_id=P.socio_asociacion_id
    JOIN comercial.CampaniaVenta C ON C.campania_venta_id=P.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio)
    WHERE P.estado=1 AND ( @campania IS NULL OR C.campania_venta_id=@campania)
    AND P.fecha_registro>=@inicio AND P.fecha_registro<@fin;
  INSERT @G SELECT 'ALTAS',CONVERT(NVARCHAR(10),S.fecha_desde,23),N'Socios',COUNT_BIG(*),1
    FROM org.SocioAsociacion S JOIN org.Asociacion A ON A.asociacion_id=S.asociacion_id AND A.uot_id=@uot
    AND A.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio)
    WHERE S.fecha_desde BETWEEN @desde AND @hasta AND S.estado=1 GROUP BY S.fecha_desde;
  INSERT @G SELECT 'MEMBRESIA',S.situacion_membresia,N'Socios',COUNT_BIG(*),1
    FROM org.SocioAsociacion S JOIN org.Asociacion A ON A.asociacion_id=S.asociacion_id AND A.uot_id=@uot
    AND A.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio)
    WHERE S.estado=1 GROUP BY S.situacion_membresia;
  INSERT @G SELECT 'ASOCIACION',CONVERT(NVARCHAR(20),A.asociacion_id),N'Socios',COUNT_BIG(*),1
    FROM org.SocioAsociacion S JOIN org.Asociacion A ON A.asociacion_id=S.asociacion_id AND A.uot_id=@uot
    AND A.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio)
    WHERE S.estado=1 GROUP BY A.asociacion_id;
  INSERT @G SELECT 'PARTICIPANTES',C.nombre,N'Socios',COUNT_BIG(DISTINCT S.socio_id),1
    FROM comercial.ParticipacionCampaniaSocio P JOIN comercial.CampaniaVenta C ON C.campania_venta_id=P.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio)
    JOIN org.SocioAsociacion S ON S.socio_asociacion_id=P.socio_asociacion_id
    WHERE P.estado=1 AND P.fecha_registro>=@inicio AND P.fecha_registro<@fin
    GROUP BY C.nombre;
 END;
 IF @tab='PREDIOS'
 BEGIN
  INSERT @K SELECT 'PREDIOS',N'Predios registrados',COUNT_BIG(DISTINCT A.predio_id),'UND',1
    FROM prod.PredioAmbito A WHERE A.uot_id=@uot AND A.convenio_uot_organizacion_id=@convenio AND A.estado=1 AND (@predio IS NULL OR A.predio_id=@predio);
  INSERT @K SELECT 'PARCELAS',N'Parcelas registradas',COUNT_BIG(*),'UND',2
    FROM prod.Parcela P JOIN prod.PredioAmbito A ON A.predio_id=P.predio_id AND A.uot_id=@uot AND A.convenio_uot_organizacion_id=@convenio AND A.estado=1
    WHERE P.estado=1 AND (@predio IS NULL OR P.predio_id=@predio);
  INSERT @K SELECT 'PLANTAS',N'Plantas registradas',COUNT_BIG(*),'UND',3
    FROM prod.PlantaPaltaE3 P WHERE P.uot_id=@uot AND P.convenio_id=@convenio AND P.activo=1
    AND (@predio IS NULL OR P.predio_id=@predio) AND (@socio IS NULL OR P.socio_id=@socio);
  INSERT @K SELECT 'AFECTADAS',N'Plantas con afectación',COUNT_BIG(*),'UND',4
    FROM prod.PlantaPaltaE3 P WHERE P.uot_id=@uot AND P.convenio_id=@convenio AND P.activo=1 AND P.estado_actual NOT IN('SANA','MUERTA')
    AND (@predio IS NULL OR P.predio_id=@predio) AND (@socio IS NULL OR P.socio_id=@socio);
  INSERT @G SELECT 'VARIEDAD',V.nombre,N'Plantas',COUNT_BIG(*),1 FROM prod.PlantaPaltaE3 P JOIN prod.VariedadPalta V ON V.variedad_palta_id=P.variedad_palta_id
    WHERE P.uot_id=@uot AND P.convenio_id=@convenio AND P.activo=1 AND (@predio IS NULL OR P.predio_id=@predio) AND (@socio IS NULL OR P.socio_id=@socio) GROUP BY V.nombre;
  INSERT @G SELECT 'ESTADO_PLANTA',P.estado_actual,N'Plantas',COUNT_BIG(*),1 FROM prod.PlantaPaltaE3 P
    WHERE P.uot_id=@uot AND P.convenio_id=@convenio AND P.activo=1 AND (@predio IS NULL OR P.predio_id=@predio) AND (@socio IS NULL OR P.socio_id=@socio) GROUP BY P.estado_actual;
  INSERT @G SELECT 'DISTRITO',D.nombre,N'Predios',COUNT_BIG(DISTINCT P.predio_id),1
    FROM prod.Predio P JOIN prod.PredioAmbito A ON A.predio_id=P.predio_id AND A.estado=1 AND A.uot_id=@uot AND A.convenio_uot_organizacion_id=@convenio
    JOIN geo.Ubicacion U ON U.ubicacion_id=P.ubicacion_id JOIN geo.Distrito D ON D.distrito_codigo=U.distrito_codigo
    WHERE (@predio IS NULL OR P.predio_id=@predio) GROUP BY D.nombre;
  INSERT @G SELECT 'REGISTRO_PLANTA',CONVERT(NVARCHAR(10),DATEADD(HOUR,-5,P.creado_en),23),N'Plantas',COUNT_BIG(*),1
    FROM prod.PlantaPaltaE3 P WHERE P.uot_id=@uot AND P.convenio_id=@convenio AND P.activo=1
    AND P.creado_en>=@inicio AND P.creado_en<@fin AND (@predio IS NULL OR P.predio_id=@predio) AND (@socio IS NULL OR P.socio_id=@socio)
    GROUP BY CONVERT(NVARCHAR(10),DATEADD(HOUR,-5,P.creado_en),23);
 END;
 IF @tab='CAMPANIAS'
 BEGIN
  INSERT @K SELECT 'CAMPANIAS',N'Campañas registradas',COUNT_BIG(*),'UND',1 FROM comercial.CampaniaVenta C WHERE C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) AND C.estado=1 AND (@campania IS NULL OR C.campania_venta_id=@campania);
  INSERT @K SELECT 'VIGENTES',N'Campañas vigentes',COUNT_BIG(*),'UND',2 FROM comercial.CampaniaVenta C WHERE C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) AND C.estado=1 AND C.fecha_inicio<=@hasta AND (C.fecha_fin IS NULL OR C.fecha_fin>=@desde) AND (@campania IS NULL OR C.campania_venta_id=@campania);
  INSERT @K SELECT 'PARTICIPANTES',N'Participaciones',COUNT_BIG(*),'UND',3 FROM comercial.ParticipacionCampaniaSocio P JOIN comercial.CampaniaVenta C ON C.campania_venta_id=P.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio)
    WHERE P.estado=1 AND P.fecha_registro>=@inicio AND P.fecha_registro<@fin AND (@campania IS NULL OR C.campania_venta_id=@campania);
  INSERT @K SELECT 'OPERATIVOS',N'Operativos registrados',COUNT_BIG(*),'UND',4 FROM comercial.OperativoVenta O JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE O.estado=1 AND (@campania IS NULL OR C.campania_venta_id=@campania);
  INSERT @G SELECT 'FECHAS',CONVERT(NVARCHAR(7),C.fecha_inicio,126),N'Campañas',COUNT_BIG(*),1 FROM comercial.CampaniaVenta C WHERE C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) AND C.estado=1 AND (@campania IS NULL OR C.campania_venta_id=@campania) AND C.fecha_inicio BETWEEN @desde AND @hasta GROUP BY CONVERT(NVARCHAR(7),C.fecha_inicio,126);
  INSERT @G SELECT 'ESTADOS',C.estado_proceso,N'Campañas',COUNT_BIG(*),1 FROM comercial.CampaniaVenta C WHERE C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) AND C.estado=1 AND (@campania IS NULL OR C.campania_venta_id=@campania) GROUP BY C.estado_proceso;
  INSERT @G SELECT 'PARTICIPACION',C.nombre,N'Socios',COUNT_BIG(DISTINCT P.socio_asociacion_id),1 FROM comercial.CampaniaVenta C JOIN comercial.ParticipacionCampaniaSocio P ON P.campania_venta_id=C.campania_venta_id AND P.estado=1 WHERE C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) AND C.estado=1 AND (@campania IS NULL OR C.campania_venta_id=@campania) GROUP BY C.nombre;
  INSERT @G SELECT 'OPERATIVOS',C.nombre,N'Operativos',COUNT_BIG(*),1 FROM comercial.CampaniaVenta C JOIN comercial.OperativoVenta O ON O.campania_venta_id=C.campania_venta_id AND O.estado=1 WHERE C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) AND C.estado=1 AND (@campania IS NULL OR C.campania_venta_id=@campania) GROUP BY C.nombre;
 END;
 IF @tab='VENTAS'
 BEGIN
  SET @fase=N'VENTAS_INICIO';
  SET @fase=N'VENTAS_KPI_ENTREGAS';
  INSERT @K SELECT 'ENTREGAS',N'Entregas registradas',COUNT_BIG(*),'UND',1 FROM comercial.EntregaSocio E JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE E.estado=1 AND E.fecha_hora>=@inicio AND E.fecha_hora<@fin AND (@campania IS NULL OR C.campania_venta_id=@campania);
  SET @fase=N'VENTAS_KPI_KILOS';
  INSERT @K SELECT 'KILOS',N'Kilos aceptados',COALESCE(SUM(E.peso_aceptado_kg),0),'KG',2 FROM comercial.EntregaSocio E JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE E.estado=1 AND E.fecha_hora>=@inicio AND E.fecha_hora<@fin AND (@campania IS NULL OR C.campania_venta_id=@campania);
  SET @fase=N'VENTAS_KPI_JABAS';
  INSERT @K SELECT 'JABAS',N'Jabas recibidas',COALESCE(SUM(CONVERT(BIGINT,O.cantidad_jabas_recibidas)),0),'UND',3 FROM comercial.OperativoVenta O JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE O.estado=1 AND (@campania IS NULL OR C.campania_venta_id=@campania);
  SET @fase=N'VENTAS_KPI_RECHAZADO';
  INSERT @K SELECT 'RECHAZADO',N'Kilos rechazados',COALESCE(SUM(E.peso_rechazado_kg),0),'KG',4 FROM comercial.EntregaSocio E JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE E.estado=1 AND E.fecha_hora>=@inicio AND E.fecha_hora<@fin AND (@campania IS NULL OR C.campania_venta_id=@campania);
  SET @fase=N'VENTAS_GRAFICO_KILOS_DIA';
  INSERT @G SELECT 'KILOS_DIA',CONVERT(NVARCHAR(10),DATEADD(HOUR,-5,E.fecha_hora),23),N'Kilos',SUM(E.peso_aceptado_kg),1 FROM comercial.EntregaSocio E JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE E.estado=1 AND (@campania IS NULL OR C.campania_venta_id=@campania) AND E.fecha_hora>=@inicio AND E.fecha_hora<@fin GROUP BY CONVERT(NVARCHAR(10),DATEADD(HOUR,-5,E.fecha_hora),23);
  SET @fase=N'VENTAS_GRAFICO_ESTADO_ENTREGA';
  INSERT @G SELECT 'ESTADO_ENTREGA',E.estado_proceso,N'Entregas',COUNT_BIG(*),1 FROM comercial.EntregaSocio E JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE E.estado=1 AND (@campania IS NULL OR C.campania_venta_id=@campania) AND E.fecha_hora>=@inicio AND E.fecha_hora<@fin GROUP BY E.estado_proceso;
  SET @fase=N'VENTAS_GRAFICO_KILOS_CAMPANIA';
  INSERT @G SELECT 'KILOS_CAMPANIA',C.nombre,N'Kilos',SUM(E.peso_aceptado_kg),1 FROM comercial.EntregaSocio E JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE E.estado=1 AND (@campania IS NULL OR C.campania_venta_id=@campania) AND E.fecha_hora>=@inicio AND E.fecha_hora<@fin GROUP BY C.nombre;
  SET @fase=N'VENTAS_GRAFICO_CALIDAD';
  INSERT @G SELECT 'CALIDAD',E.estado_control_calidad,N'Entregas',COUNT_BIG(*),1 FROM comercial.EntregaSocio E JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE E.estado=1 AND (@campania IS NULL OR C.campania_venta_id=@campania) AND E.fecha_hora>=@inicio AND E.fecha_hora<@fin GROUP BY E.estado_control_calidad;
 END;
 IF @tab='COMPRADORES'
 BEGIN
  INSERT @K SELECT 'TOTAL',N'Compradores registrados',COUNT_BIG(*),'UND',1 FROM comercial.CompradorAPAPPSS B WHERE B.uot_id=@uot AND B.estado=1 AND EXISTS(SELECT 1 FROM comercial.CampaniaVenta X WHERE X.comprador_apappss_id=B.comprador_apappss_id AND X.uot_id=@uot AND X.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) AND X.estado=1);
  INSERT @K SELECT 'PERSONAS',N'Personas naturales',COUNT_BIG(*),'UND',2 FROM comercial.CompradorAPAPPSS B WHERE B.uot_id=@uot AND B.estado=1 AND EXISTS(SELECT 1 FROM comercial.CampaniaVenta X WHERE X.comprador_apappss_id=B.comprador_apappss_id AND X.uot_id=@uot AND X.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) AND X.estado=1) AND B.persona_id IS NOT NULL;
  INSERT @K SELECT 'EMPRESAS',N'Empresas',COUNT_BIG(*),'UND',3 FROM comercial.CompradorAPAPPSS B WHERE B.uot_id=@uot AND B.estado=1 AND EXISTS(SELECT 1 FROM comercial.CampaniaVenta X WHERE X.comprador_apappss_id=B.comprador_apappss_id AND X.uot_id=@uot AND X.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) AND X.estado=1) AND B.empresa_id IS NOT NULL;
  INSERT @K SELECT 'NUEVOS',N'Nuevos compradores',COUNT_BIG(*),'UND',4 FROM comercial.CompradorAPAPPSS B WHERE B.uot_id=@uot AND B.estado=1 AND EXISTS(SELECT 1 FROM comercial.CampaniaVenta X WHERE X.comprador_apappss_id=B.comprador_apappss_id AND X.uot_id=@uot AND X.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) AND X.estado=1) AND B.fecha_registro>=@inicio AND B.fecha_registro<@fin;
  INSERT @G SELECT 'TIPOS',B.tipo,N'Compradores',COUNT_BIG(*),1 FROM comercial.CompradorAPAPPSS B WHERE B.uot_id=@uot AND B.estado=1 AND EXISTS(SELECT 1 FROM comercial.CampaniaVenta X WHERE X.comprador_apappss_id=B.comprador_apappss_id AND X.uot_id=@uot AND X.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) AND X.estado=1) GROUP BY B.tipo;
  INSERT @G SELECT 'NUEVOS_DIA',CONVERT(NVARCHAR(10),B.fecha_registro,23),N'Compradores',COUNT_BIG(*),1 FROM comercial.CompradorAPAPPSS B WHERE B.uot_id=@uot AND B.estado=1 AND EXISTS(SELECT 1 FROM comercial.CampaniaVenta X WHERE X.comprador_apappss_id=B.comprador_apappss_id AND X.uot_id=@uot AND X.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) AND X.estado=1) AND B.fecha_registro>=@inicio AND B.fecha_registro<@fin GROUP BY CONVERT(NVARCHAR(10),B.fecha_registro,23);
  INSERT @G SELECT 'CAMPANIAS',CONVERT(NVARCHAR(20),C.comprador_apappss_id),N'Campañas',COUNT_BIG(*),1 FROM comercial.CampaniaVenta C WHERE C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) AND C.estado=1 AND C.comprador_apappss_id IS NOT NULL GROUP BY C.comprador_apappss_id;
  INSERT @G SELECT 'COBROS',CONVERT(NVARCHAR(20),C.comprador_apappss_id),N'Soles',SUM(B.importe),1 FROM finanzas.CobroComprador B JOIN comercial.CampaniaVenta C ON C.campania_venta_id=B.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE B.estado=1 AND C.comprador_apappss_id IS NOT NULL AND B.fecha_hora>=@inicio AND B.fecha_hora<@fin GROUP BY C.comprador_apappss_id;
 END;
 IF @tab='LIQUIDACIONES'
 BEGIN
  INSERT @K SELECT 'CANTIDAD',N'Liquidaciones',COUNT_BIG(*),'UND',1 FROM finanzas.LiquidacionSocio L JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id JOIN comercial.CampaniaVenta C ON C.campania_venta_id=P.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE L.estado=1 AND L.fecha_calculo>=@inicio AND L.fecha_calculo<@fin AND (@campania IS NULL OR C.campania_venta_id=@campania);
  INSERT @K SELECT 'BRUTO',N'Importe bruto',COALESCE(SUM(L.importe_bruto),0),'PEN',2 FROM finanzas.LiquidacionSocio L JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id JOIN comercial.CampaniaVenta C ON C.campania_venta_id=P.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE L.estado=1 AND L.fecha_calculo>=@inicio AND L.fecha_calculo<@fin AND (@campania IS NULL OR C.campania_venta_id=@campania);
  INSERT @K SELECT 'NETO',N'Importe neto',COALESCE(SUM(L.importe_neto),0),'PEN',3 FROM finanzas.LiquidacionSocio L JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id JOIN comercial.CampaniaVenta C ON C.campania_venta_id=P.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE L.estado=1 AND L.fecha_calculo>=@inicio AND L.fecha_calculo<@fin AND (@campania IS NULL OR C.campania_venta_id=@campania);
  INSERT @K SELECT 'PENDIENTES',N'Liquidaciones en trámite',COUNT_BIG(*),'UND',4 FROM finanzas.LiquidacionSocio L JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id JOIN comercial.CampaniaVenta C ON C.campania_venta_id=P.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE L.estado=1 AND L.estado_proceso NOT IN('PAGADA','CERRADA','ANULADA') AND (@campania IS NULL OR C.campania_venta_id=@campania);
  INSERT @G SELECT 'NETO_DIA',CONVERT(NVARCHAR(10),DATEADD(HOUR,-5,L.fecha_calculo),23),N'Soles',SUM(L.importe_neto),1 FROM finanzas.LiquidacionSocio L JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id JOIN comercial.CampaniaVenta C ON C.campania_venta_id=P.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE L.estado=1 AND (@campania IS NULL OR C.campania_venta_id=@campania) AND L.fecha_calculo>=@inicio AND L.fecha_calculo<@fin GROUP BY CONVERT(NVARCHAR(10),DATEADD(HOUR,-5,L.fecha_calculo),23);
  INSERT @G SELECT 'ESTADOS',L.estado_proceso,N'Liquidaciones',COUNT_BIG(*),1 FROM finanzas.LiquidacionSocio L JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id JOIN comercial.CampaniaVenta C ON C.campania_venta_id=P.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE L.estado=1 AND (@campania IS NULL OR C.campania_venta_id=@campania) GROUP BY L.estado_proceso;
  INSERT @G SELECT 'POR_CAMPANIA',C.nombre,N'Soles',SUM(L.importe_neto),1 FROM finanzas.LiquidacionSocio L JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id JOIN comercial.CampaniaVenta C ON C.campania_venta_id=P.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE L.estado=1 AND (@campania IS NULL OR C.campania_venta_id=@campania) AND L.fecha_calculo>=@inicio AND L.fecha_calculo<@fin GROUP BY C.nombre;
  INSERT @G SELECT 'AJUSTES',CONVERT(NVARCHAR(7),L.fecha_calculo,126),N'Soles',SUM(L.total_ajustes),1 FROM finanzas.LiquidacionSocio L JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id JOIN comercial.CampaniaVenta C ON C.campania_venta_id=P.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE L.estado=1 AND (@campania IS NULL OR C.campania_venta_id=@campania) AND L.fecha_calculo>=@inicio AND L.fecha_calculo<@fin GROUP BY CONVERT(NVARCHAR(7),L.fecha_calculo,126);
 END;
 IF @tab='PAGOS'
 BEGIN
  SET @fase=N'PAGOS_INICIO';
  SET @fase=N'PAGOS_KPI_OPERACIONES';
  INSERT @K SELECT 'OPERACIONES',N'Pagos registrados',COUNT_BIG(*),'UND',1 FROM finanzas.PagoSocio P JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=P.liquidacion_socio_id JOIN comercial.ParticipacionCampaniaSocio S ON S.participacion_campania_socio_id=L.participacion_campania_socio_id JOIN comercial.CampaniaVenta C ON C.campania_venta_id=S.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE P.estado=1 AND P.fecha_hora>=@inicio AND P.fecha_hora<@fin;
  SET @fase=N'PAGOS_KPI_ABONADO';
  INSERT @K SELECT 'ABONADO',N'Total pagado',COALESCE(SUM(P.importe),0),'PEN',2 FROM finanzas.PagoSocio P JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=P.liquidacion_socio_id JOIN comercial.ParticipacionCampaniaSocio S ON S.participacion_campania_socio_id=L.participacion_campania_socio_id JOIN comercial.CampaniaVenta C ON C.campania_venta_id=S.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE P.estado=1 AND P.fecha_hora>=@inicio AND P.fecha_hora<@fin AND P.estado_proceso<>'ANULADO';
  SET @fase=N'PAGOS_KPI_CONFIRMADOS';
  INSERT @K SELECT 'CONFIRMADOS',N'Pagos confirmados',COUNT_BIG(*),'UND',3 FROM finanzas.PagoSocio P JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=P.liquidacion_socio_id JOIN comercial.ParticipacionCampaniaSocio S ON S.participacion_campania_socio_id=L.participacion_campania_socio_id JOIN comercial.CampaniaVenta C ON C.campania_venta_id=S.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE P.estado=1 AND P.fecha_hora>=@inicio AND P.fecha_hora<@fin AND P.fecha_confirmacion IS NOT NULL;
  SET @fase=N'PAGOS_KPI_EN_TRAMITE';
  INSERT @K SELECT 'EN_TRAMITE',N'Pagos en trámite',COUNT_BIG(*),'UND',4 FROM finanzas.PagoSocio P JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=P.liquidacion_socio_id JOIN comercial.ParticipacionCampaniaSocio S ON S.participacion_campania_socio_id=L.participacion_campania_socio_id JOIN comercial.CampaniaVenta C ON C.campania_venta_id=S.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE P.estado=1 AND P.fecha_confirmacion IS NULL AND P.fecha_anulacion IS NULL;
  SET @fase=N'PAGOS_GRAFICO_PAGOS_DIA';
  INSERT @G SELECT 'PAGOS_DIA',CONVERT(NVARCHAR(10),DATEADD(HOUR,-5,P.fecha_hora),23),N'Soles',SUM(P.importe),1 FROM finanzas.PagoSocio P JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=P.liquidacion_socio_id JOIN comercial.ParticipacionCampaniaSocio S ON S.participacion_campania_socio_id=L.participacion_campania_socio_id JOIN comercial.CampaniaVenta C ON C.campania_venta_id=S.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE P.estado=1 AND P.fecha_hora>=@inicio AND P.fecha_hora<@fin AND P.fecha_anulacion IS NULL GROUP BY CONVERT(NVARCHAR(10),DATEADD(HOUR,-5,P.fecha_hora),23);
  SET @fase=N'PAGOS_GRAFICO_ESTADOS';
  INSERT @G SELECT 'ESTADOS',P.estado_proceso,N'Pagos',COUNT_BIG(*),1 FROM finanzas.PagoSocio P JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=P.liquidacion_socio_id JOIN comercial.ParticipacionCampaniaSocio S ON S.participacion_campania_socio_id=L.participacion_campania_socio_id JOIN comercial.CampaniaVenta C ON C.campania_venta_id=S.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE P.estado=1 GROUP BY P.estado_proceso;
  SET @fase=N'PAGOS_GRAFICO_MEDIOS';
  INSERT @G SELECT 'MEDIOS',P.medio_pago,N'Pagos',COUNT_BIG(*),1 FROM finanzas.PagoSocio P JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=P.liquidacion_socio_id JOIN comercial.ParticipacionCampaniaSocio S ON S.participacion_campania_socio_id=L.participacion_campania_socio_id JOIN comercial.CampaniaVenta C ON C.campania_venta_id=S.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE P.estado=1 AND P.fecha_hora>=@inicio AND P.fecha_hora<@fin GROUP BY P.medio_pago;
  SET @fase=N'PAGOS_GRAFICO_POR_CAMPANIA';
  INSERT @G SELECT 'POR_CAMPANIA',C.nombre,N'Soles',SUM(P.importe),1 FROM finanzas.PagoSocio P JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=P.liquidacion_socio_id JOIN comercial.ParticipacionCampaniaSocio S ON S.participacion_campania_socio_id=L.participacion_campania_socio_id JOIN comercial.CampaniaVenta C ON C.campania_venta_id=S.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) WHERE P.estado=1 AND P.fecha_hora>=@inicio AND P.fecha_hora<@fin AND P.fecha_anulacion IS NULL GROUP BY C.nombre;
 END;
 SET @fase=N'ARMADO_JSON';
 SET @cDatos=(SELECT @tab tab,@desde desde,@hasta hasta,@uot uotId,@convenio convenioId,
 JSON_QUERY((SELECT codigo,titulo,valor,unidad,orden FROM @K ORDER BY orden FOR JSON PATH)) indicadores,
 JSON_QUERY((SELECT grafico,categoria,serie,valor,orden FROM @G ORDER BY grafico,orden,categoria FOR JSON PATH)) puntos
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 /* Cuatro KPI por panel y un arreglo de puntos, incluso cuando no existen eventos. */
 IF (SELECT COUNT_BIG(*) FROM @K)<>4 OR ISJSON(@cDatos)<>1
    OR (SELECT COUNT_BIG(*) FROM OPENJSON(@cDatos,'$.indicadores'))<>4
    OR JSON_QUERY(@cDatos,'$.puntos') IS NULL
    THROW 51021,N'Contrato incompleto del dashboard APAPPSS.',1;
 SELECT @bResultado=1,@cMensaje=N'Información disponible.',@nHttp=200;
 END TRY BEGIN CATCH
  /* Capturar datos del CATCH original antes de intentar registrar el diagnóstico. */
  DECLARE @errNumero INT=ERROR_NUMBER(), @errProcedimiento NVARCHAR(257)=ERROR_PROCEDURE(),
          @errLinea INT=ERROR_LINE(), @errMensaje NVARCHAR(4000)=ERROR_MESSAGE();
  BEGIN TRY
   INSERT INTO auditoria.ErrorBaseDatos(fecha_utc,numero_error,procedimiento,linea,codigo,correlacion_id,mensaje_sql,tab,diagnostico_etapa)
   VALUES(SYSUTCDATETIME(),@errNumero,@errProcedimiento,@errLinea,'APAPPSS_DASHBOARD',@corr,@errMensaje,@tab,@fase);
  END TRY BEGIN CATCH
   /* Si falla la auditoría, mantener la respuesta controlada al cliente. */
  END CATCH;
  SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo cargar la información.',@nHttp=500;
 END CATCH
END;
GO
