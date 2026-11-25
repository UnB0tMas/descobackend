-- DESCO / QA SOLO LECTURA: diagnóstico POS DEMO (DEV).
-- No cambia permisos, no crea usuarios y no toca Flyway.
SET NOCOUNT ON;
DECLARE @ahora DATETIME2(3)=SYSUTCDATETIME();
DECLARE @uot BIGINT=(SELECT O.uot_id FROM org.UOT O WHERE O.codigo='UOT_LEGACY_4' AND O.estado=1 AND O.es_raiz=0);
IF @uot IS NULL THROW 51680,N'No existe una UOT Sara Sara activa y no raíz.',1;

-- Confirmar estado de las migraciones, sin ejecutar repair ni alterar checksums.
SELECT installed_rank,version,description,script,success
FROM dbo.flyway_schema_history
WHERE version IN('687','688','689','690')
ORDER BY installed_rank;

-- El resultado efectivo puede ser 0 incluso si RolPermiso está activo:
-- UsuarioUOTPermiso (denegación explícita) tiene prioridad en la función SQL.
SELECT U.nombre_usuario, U.usuario_id,
       CONVERT(INT,U.estado) AS usuario_activo,U.estado_cuenta,
       O.codigo AS uot_codigo,UU.usuario_uot_id,UU.fecha_desde AS uot_desde,
       UU.fecha_hasta AS uot_hasta,
       COALESCE(P.codigo,'POS_OPERAR') AS permiso_codigo,
       CONVERT(INT,P.estado) AS permiso_activo,
       ISNULL(AV.asignaciones_uot_vigentes,0) AS asignaciones_uot_vigentes,
       ISNULL(RO.roles_que_conceden,0) AS roles_vigentes_que_conceden,
       CAST(OV.permitido AS INT) AS override_explicito,
       OV.motivo AS override_motivo,
       CONVERT(INT,seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@uot,'POS_OPERAR')) AS permiso_efectivo,
       CASE
         WHEN U.estado<>1 OR U.estado_cuenta<>'ACTIVA' THEN 'CUENTA_INACTIVA'
         WHEN ISNULL(AV.asignaciones_uot_vigentes,0)=0 THEN 'SIN_ASIGNACION_UOT_VIGENTE'
         WHEN ISNULL(AV.asignaciones_uot_vigentes,0)>1 THEN 'ASIGNACION_UOT_DUPLICADA'
         WHEN P.permiso_id IS NULL OR P.estado<>1 THEN 'PERMISO_INACTIVO_O_AUSENTE'
         WHEN OV.permitido=0 THEN 'DENEGACION_INDIVIDUAL_VIGENTE'
         WHEN OV.permitido=1 THEN 'AUTORIZACION_INDIVIDUAL_VIGENTE'
         WHEN ISNULL(RO.roles_que_conceden,0)=0 THEN 'SIN_ROL_VIGENTE_QUE_CONCEDA'
         ELSE 'REVISAR_FUNCION_O_TERRITORIO'
       END AS diagnostico
FROM seg.Usuario U
CROSS JOIN (SELECT codigo FROM org.UOT WHERE uot_id=@uot) O
LEFT JOIN seg.Permiso P ON P.codigo='POS_OPERAR'
OUTER APPLY (
    SELECT COUNT_BIG(*) AS asignaciones_uot_vigentes FROM seg.UsuarioUOT X
    WHERE X.usuario_id=U.usuario_id AND X.uot_id=@uot AND X.estado=1
      AND X.fecha_desde<=@ahora AND X.fecha_hasta IS NULL
) AV
OUTER APPLY (
    SELECT TOP (1) X.usuario_uot_id,X.fecha_desde,X.fecha_hasta
    FROM seg.UsuarioUOT X
    WHERE X.usuario_id=U.usuario_id AND X.uot_id=@uot AND X.estado=1
      AND X.fecha_desde<=@ahora AND X.fecha_hasta IS NULL
    ORDER BY X.usuario_uot_id
) UU
OUTER APPLY (
    SELECT TOP (1) X.permitido,X.motivo
    FROM seg.UsuarioUOTPermiso X
    WHERE X.usuario_uot_id=UU.usuario_uot_id AND X.permiso_id=P.permiso_id
      AND X.estado=1 AND X.fecha_desde<=@ahora
      AND (X.fecha_hasta IS NULL OR X.fecha_hasta>@ahora)
    ORDER BY X.usuario_uot_permiso_id DESC
) OV
OUTER APPLY (
    SELECT COUNT_BIG(DISTINCT R.rol_id) AS roles_que_conceden
    FROM seg.UsuarioUOTRol UR
    JOIN seg.Rol R ON R.rol_id=UR.rol_id AND R.estado=1
    JOIN seg.RolPermiso RP ON RP.rol_id=R.rol_id AND RP.permiso_id=P.permiso_id AND RP.estado=1
    WHERE UR.usuario_uot_id=UU.usuario_uot_id AND UR.estado=1
      AND UR.fecha_desde<=@ahora AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta>@ahora)
) RO
WHERE U.nombre_usuario IN ('pos_sarasara_01','pos_sarasara_02','pos_sarasara_03')
ORDER BY U.nombre_usuario;

-- Si el diagnóstico arroja DENEGACION_INDIVIDUAL_VIGENTE, NO retirar esa restricción
-- automáticamente: debe revisarse la decisión de seguridad que la originó.
-- Validar la autorización del administrador al Dashboard, independientemente de POS DEMO.
SELECT TOP (50) U.nombre_usuario,O.codigo AS uot_codigo,
       CONVERT(INT,seg.FN_Usuario_TienePermisoUOT(U.usuario_id,O.uot_id,'REPORTES_CONTROL_VER')) AS reportes_control,
       CONVERT(INT,seg.FN_Usuario_TienePermisoUOT(U.usuario_id,O.uot_id,'DASHBOARD_APAPPSS_VER')) AS dashboard_apappss
FROM seg.Usuario U
JOIN seg.UsuarioRol UR ON UR.usuario_id=U.usuario_id AND UR.estado=1
  AND UR.fecha_desde<=@ahora AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta>@ahora)
JOIN seg.Rol R ON R.rol_id=UR.rol_id AND R.codigo='ADMINISTRADOR' AND R.estado=1
JOIN seg.UsuarioUOT UU ON UU.usuario_id=U.usuario_id AND UU.estado=1
  AND UU.fecha_desde<=@ahora AND UU.fecha_hasta IS NULL
JOIN org.UOT O ON O.uot_id=UU.uot_id AND O.estado=1
ORDER BY U.nombre_usuario,O.codigo;
