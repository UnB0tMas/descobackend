-- Inicio: habilitar consulta de datos propios al personal de caja.
SET NOCOUNT ON;
UPDATE RP
SET estado=1,fecha_asignacion=SYSUTCDATETIME(),fecha_retiro=NULL,
    retirado_por_usuario_id=NULL,motivo_retiro=NULL
FROM seg.RolPermiso RP
INNER JOIN seg.Rol R WITH (NOLOCK) ON R.rol_id=RP.rol_id
INNER JOIN seg.Permiso P WITH (NOLOCK) ON P.permiso_id=RP.permiso_id
WHERE R.codigo IN ('OPERADOR_POS','POS_DEMO_BASE','POS_DEMO_FLEX','POS_DEMO_LIBRE')
  AND P.codigo='INICIO_LISTAR' AND R.estado=1 AND P.estado=1 AND RP.estado=0;

INSERT INTO seg.RolPermiso (rol_id,permiso_id,estado,fecha_asignacion,asignado_por_usuario_id)
SELECT R.rol_id,P.permiso_id,1,SYSUTCDATETIME(),NULL
FROM seg.Rol R WITH (NOLOCK)
INNER JOIN seg.Permiso P WITH (NOLOCK) ON P.codigo='INICIO_LISTAR' AND P.estado=1
WHERE R.codigo IN ('OPERADOR_POS','POS_DEMO_BASE','POS_DEMO_FLEX','POS_DEMO_LIBRE')
  AND R.estado=1
  AND NOT EXISTS (
      SELECT 1 FROM seg.RolPermiso RP WITH (NOLOCK)
      WHERE RP.rol_id=R.rol_id AND RP.permiso_id=P.permiso_id
  );
