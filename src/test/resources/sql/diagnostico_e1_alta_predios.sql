-- Ejecutar solo en DEV, lectura. No modifica registros.
-- Caso reportado: uotId=2, convenioId=2, personaId=11, distrito=050801, centroPobladoId=6.
SELECT P.persona_id,P.estado persona_activa,S.socio_id,S.estado socio_activo
FROM org.Persona P LEFT JOIN org.Socio S ON S.socio_id=P.persona_id
WHERE P.persona_id=11;
SELECT SA.socio_id,SA.asociacion_id,SA.fecha_desde,SA.fecha_hasta,SA.estado,C.convenio_uot_organizacion_id,C.uot_id
FROM org.SocioAsociacion SA JOIN org.ConvenioUOTOrganizacion C ON C.empresa_id=SA.asociacion_id
WHERE SA.socio_id=11 AND C.convenio_uot_organizacion_id=2;
SELECT D.distrito_codigo,D.estado distrito_activo,CP.centro_poblado_id,CP.estado centro_activo,CP.distrito_codigo distrito_del_centro
FROM geo.Distrito D LEFT JOIN geo.CentroPoblado CP ON CP.centro_poblado_id=6
WHERE D.distrito_codigo='050801';
SELECT TOP(20) error_id,fecha_utc,correlacion_id,operacion,numero_sql,procedimiento,linea_sql,mensaje_sql
FROM auditoria.ExpedienteErrorTecnico WHERE operacion='PREDIO_CREAR' ORDER BY error_id DESC;
