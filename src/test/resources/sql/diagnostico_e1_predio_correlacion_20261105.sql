-- DEV / QA: SOLO LECTURA. No modifica datos ni requiere ROLLBACK.
-- Correlación del error reportado: 7ec5387d-f656-425f-93f4-90d7dde46d34.
-- Los datos siguientes pertenecen al ejemplo anterior; actualícelos si esta solicitud fue distinta.
DECLARE @correlacion UNIQUEIDENTIFIER='7ec5387d-f656-425f-93f4-90d7dde46d34';
DECLARE @uot BIGINT=2, @convenio BIGINT=2, @persona BIGINT=11;
DECLARE @distrito CHAR(6)='050801', @centro BIGINT=6;
DECLARE @nombre NVARCHAR(150)=N'Prueba23';

SELECT DB_NAME() AS base_actual, @@SERVERNAME AS servidor;

-- Diagnóstico principal: la columna mensaje_sql indica la causa real, no el HTTP 400.
IF OBJECT_ID(N'auditoria.ExpedienteErrorTecnico',N'U') IS NOT NULL
BEGIN
  SELECT TOP (20) error_id,fecha_utc,correlacion_id,operacion,uot_id,convenio_id,
         persona_id,numero_sql,procedimiento,linea_sql,mensaje_sql
  FROM auditoria.ExpedienteErrorTecnico
  WHERE correlacion_id=@correlacion
  ORDER BY error_id DESC;
  -- Si no aparece, buscar por fecha y operación para detectar diferencias de correlación.
  SELECT TOP (20) error_id,fecha_utc,correlacion_id,operacion,
         numero_sql,procedimiento,linea_sql,mensaje_sql
  FROM auditoria.ExpedienteErrorTecnico
  WHERE operacion='PREDIO_CREAR' AND fecha_utc>DATEADD(DAY,-3,SYSUTCDATETIME())
  ORDER BY error_id DESC;
END
ELSE PRINT N'Falta la tabla de diagnóstico: compruebe que V578 se haya ejecutado.';

SELECT P.persona_id,P.estado AS persona_activa,S.socio_id,S.estado AS socio_activo
FROM org.Persona P LEFT JOIN org.Socio S ON S.socio_id=P.persona_id
WHERE P.persona_id=@persona;

SELECT C.convenio_uot_organizacion_id,C.uot_id,C.empresa_id,C.estado,
       C.fecha_inicio,C.fecha_fin,SA.socio_id,SA.estado AS membresia_activa,
       SA.fecha_desde,SA.fecha_hasta,SA.situacion_membresia
FROM org.ConvenioUOTOrganizacion C
LEFT JOIN org.SocioAsociacion SA ON SA.asociacion_id=C.empresa_id AND SA.socio_id=@persona
WHERE C.convenio_uot_organizacion_id=@convenio AND C.uot_id=@uot;

SELECT D.distrito_codigo,D.estado AS distrito_activo,
       CP.centro_poblado_id,CP.distrito_codigo AS distrito_del_centro,CP.estado AS centro_activo
FROM geo.Distrito D LEFT JOIN geo.CentroPoblado CP ON CP.centro_poblado_id=@centro
WHERE D.distrito_codigo=@distrito;

SELECT I.predio_id,I.persona_id,I.distrito_codigo,I.nombre_normalizado,
       P.nombre,P.estado, A.uot_id,A.convenio_uot_organizacion_id,A.estado AS ambito_activo
FROM prod.PredioIdentidad I JOIN prod.Predio P ON P.predio_id=I.predio_id
LEFT JOIN prod.PredioAmbito A ON A.predio_id=P.predio_id
WHERE I.persona_id=@persona AND I.distrito_codigo=@distrito
  AND I.nombre_normalizado=UPPER(LTRIM(RTRIM(@nombre)));

SELECT OBJECT_SCHEMA_NAME(object_id) AS esquema,OBJECT_NAME(object_id) AS procedimiento,
       modify_date
FROM sys.procedures
WHERE object_id IN(OBJECT_ID(N'prod.PA_ExpedienteProductivo_Ejecutar'),
                   OBJECT_ID(N'prod.PA_E1_Predio_Ins_Registrar'));
