-- QA SOLO LECTURA: Dashboard APAPPSS (no modifica registros ni crea datos).
-- Indicar IDs válidos de la sesión/UOT/convenio que presentan el problema.
DECLARE @UsuarioId BIGINT = NULL; -- usuario ADMINISTRADOR
DECLARE @UotId BIGINT = NULL; -- UOT seleccionada en el frontend
DECLARE @ConvenioId BIGINT = NULL; -- convenio activo APAPPSS
DECLARE @Desde DATE = DATEADD(DAY,-365,CONVERT(DATE,(SYSUTCDATETIME() AT TIME ZONE 'UTC') AT TIME ZONE 'SA Pacific Standard Time'));
DECLARE @Hasta DATE = CONVERT(DATE,(SYSUTCDATETIME() AT TIME ZONE 'UTC') AT TIME ZONE 'SA Pacific Standard Time');

IF @UsuarioId IS NULL OR @UotId IS NULL OR @ConvenioId IS NULL
    THROW 51000,N'Debe completar UsuarioId, UotId y ConvenioId antes del diagnóstico.',1;
IF NOT EXISTS (SELECT 1 FROM org.ConvenioUOTOrganizacion
               WHERE convenio_uot_organizacion_id=@ConvenioId AND uot_id=@UotId AND estado=1)
    THROW 51001,N'El convenio no corresponde a la UOT activa.',1;

DECLARE @EmpresaId BIGINT = (SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@ConvenioId);
DECLARE @Inicio DATETIME2(0)=CONVERT(DATETIME2(0),CAST(@Desde AS DATETIME2(0)) AT TIME ZONE 'SA Pacific Standard Time' AT TIME ZONE 'UTC');
DECLARE @Fin DATETIME2(0)=CONVERT(DATETIME2(0),DATEADD(DAY,1,CAST(@Hasta AS DATETIME2(0))) AT TIME ZONE 'SA Pacific Standard Time' AT TIME ZONE 'UTC');

-- 1) Confirmar acceso efectivo al mismo contexto que usa el PA.
SELECT P.codigo,
       seg.FN_Usuario_TienePermisoUOT(@UsuarioId,@UotId,P.codigo) AS permitido
FROM seg.Permiso P
WHERE P.codigo IN ('REPORTES_CONTROL_VER','DASHBOARD_APAPPSS_VER','APAPPSS_SOCIOS_LISTAR',
                   'APAPPSS_PREDIOS_LISTAR','CAMPANIAS_LISTAR','ENTREGAS_LISTAR','COMPRADORES_LISTAR',
                   'LIQUIDACIONES_LISTAR','PAGOS_LISTAR','APAPPSS_PAGOS_LISTAR')
ORDER BY P.codigo;

-- 2) Socios: comparar total de membresías con socios que tengan plantas.
SELECT
 (SELECT COUNT(DISTINCT S.socio_id) FROM org.SocioAsociacion S
  JOIN org.Asociacion A ON A.asociacion_id=S.asociacion_id
  WHERE S.estado=1 AND A.uot_id=@UotId AND A.asociacion_id=@EmpresaId) AS socios_registrados,
 (SELECT COUNT(DISTINCT P.socio_id) FROM prod.PlantaPaltaE3 P
  WHERE P.uot_id=@UotId AND P.convenio_id=@ConvenioId AND P.activo=1) AS socios_con_plantas;

-- 3) Campañas/operativos: verificar si existen, cuándo comenzaron y su estado lógico.
SELECT C.campania_venta_id,C.nombre,C.fecha_inicio,C.fecha_fin,C.estado_proceso,C.estado,
       (SELECT COUNT(*) FROM comercial.OperativoVenta O WHERE O.campania_venta_id=C.campania_venta_id AND O.estado=1) AS operativos_activos
FROM comercial.CampaniaVenta C
WHERE C.uot_id=@UotId AND C.asociacion_id=@EmpresaId
ORDER BY C.fecha_inicio DESC;

-- 4) Plantas: diferenciar registros en el rango de los históricos.
SELECT COUNT_BIG(*) AS plantas_activas,
       SUM(CASE WHEN P.creado_en>=@Inicio AND P.creado_en<@Fin THEN 1 ELSE 0 END) AS plantas_registradas_en_periodo,
       MIN(P.creado_en) AS primera_alta_utc,MAX(P.creado_en) AS ultima_alta_utc
FROM prod.PlantaPaltaE3 P
WHERE P.uot_id=@UotId AND P.convenio_id=@ConvenioId AND P.activo=1;

-- 5) Ventas: entregas registradas y fechas; un rango vacío no equivale a error.
SELECT COUNT_BIG(*) AS entregas_activas,
       SUM(CASE WHEN E.fecha_hora>=@Inicio AND E.fecha_hora<@Fin THEN 1 ELSE 0 END) AS entregas_en_periodo,
       MIN(E.fecha_hora) AS primera_entrega_utc,MAX(E.fecha_hora) AS ultima_entrega_utc
FROM comercial.EntregaSocio E
JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id
WHERE E.estado=1 AND C.uot_id=@UotId AND C.asociacion_id=@EmpresaId;

-- 6) Pagos: montos y registros del mismo convenio.
SELECT COUNT_BIG(*) AS pagos_activos,
       SUM(CASE WHEN P.fecha_hora>=@Inicio AND P.fecha_hora<@Fin THEN 1 ELSE 0 END) AS pagos_en_periodo,
       MIN(P.fecha_hora) AS primer_pago_utc,MAX(P.fecha_hora) AS ultimo_pago_utc
FROM finanzas.PagoSocio P
JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=P.liquidacion_socio_id
JOIN comercial.ParticipacionCampaniaSocio S ON S.participacion_campania_socio_id=L.participacion_campania_socio_id
JOIN comercial.CampaniaVenta C ON C.campania_venta_id=S.campania_venta_id
WHERE P.estado=1 AND C.uot_id=@UotId AND C.asociacion_id=@EmpresaId;

-- 7) Tras reproducir un panel fallido, revisar errores técnicos registrados por V687.
SELECT TOP (30) fecha_utc,numero_error,procedimiento,linea,codigo,correlacion_id
FROM auditoria.ErrorBaseDatos
WHERE codigo='APAPPSS_DASHBOARD'
ORDER BY fecha_utc DESC;
