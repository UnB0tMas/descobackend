-- DESCO / QA SOLO LECTURA: diagnóstico POS DEMO tras corregir fechas.
SET NOCOUNT ON;
DECLARE @uot BIGINT=(SELECT uot_id FROM org.UOT WHERE codigo='UOT_LEGACY_4' AND estado=1 AND es_raiz=0);
IF @uot IS NULL THROW 51681,N'No existe UOT Sara Sara activa.',1;

SELECT U.nombre_usuario,U.usuario_id,@uot AS uot_id,
       UU.usuario_uot_id,UU.fecha_desde AS fecha_desde_uot,
       DATEDIFF(SECOND,SYSUTCDATETIME(),UU.fecha_desde) AS diferencia_segundos_uot,
       R.codigo AS rol,UR.fecha_desde AS fecha_desde_rol,
       DATEDIFF(SECOND,SYSUTCDATETIME(),UR.fecha_desde) AS diferencia_segundos_rol,
       P.codigo AS permiso,RP.estado AS permiso_rol_activo,
       seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@uot,'POS_OPERAR') AS pos_operar_efectivo
FROM seg.Usuario U
LEFT JOIN seg.UsuarioUOT UU ON UU.usuario_id=U.usuario_id AND UU.uot_id=@uot
LEFT JOIN seg.UsuarioUOTRol UR ON UR.usuario_uot_id=UU.usuario_uot_id
LEFT JOIN seg.Rol R ON R.rol_id=UR.rol_id AND R.codigo LIKE 'POS_DEMO_%'
LEFT JOIN seg.RolPermiso RP ON RP.rol_id=R.rol_id
   AND RP.permiso_id=(SELECT permiso_id FROM seg.Permiso WHERE codigo='POS_OPERAR')
LEFT JOIN seg.Permiso P ON P.permiso_id=RP.permiso_id
WHERE U.nombre_usuario IN('pos_sarasara_01','pos_sarasara_02','pos_sarasara_03')
ORDER BY U.nombre_usuario,UR.usuario_uot_rol_id;

-- Revisar denegaciones explícitas actuales o futuras; no alterar otros usuarios.
SELECT U.nombre_usuario,P.codigo AS permiso,UP.permitido,UP.estado,
       UP.fecha_desde,UP.fecha_hasta,UP.motivo
FROM seg.Usuario U
JOIN seg.UsuarioUOT UU ON UU.usuario_id=U.usuario_id AND UU.uot_id=@uot
JOIN seg.UsuarioUOTPermiso UP ON UP.usuario_uot_id=UU.usuario_uot_id
JOIN seg.Permiso P ON P.permiso_id=UP.permiso_id
WHERE U.nombre_usuario IN('pos_sarasara_01','pos_sarasara_02','pos_sarasara_03')
  AND P.codigo IN('POS_OPERAR','CAJAS_ABRIR','CAJAS_CERRAR','PERSONAL_COMERCIAL_LISTAR')
ORDER BY U.nombre_usuario,UP.usuario_uot_permiso_id DESC;

-- Resultado esperado: 3 empleados vinculados, permisos POS operativos.
SELECT U.nombre_usuario,E.empleado_id,EU.uot_id,
       EU.estado AS empleado_uot_activo,
       seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@uot,'POS_OPERAR') AS pos_operar,
       seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@uot,'CAJAS_ABRIR') AS cajas_abrir,
       seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@uot,'CAJAS_CERRAR') AS cajas_cerrar,
       seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@uot,'PERSONAL_COMERCIAL_LISTAR') AS gestionar_horarios
FROM seg.Usuario U
JOIN org.Empleado E ON E.empleado_id=U.persona_id AND E.estado=1
JOIN org.EmpleadoUOT EU ON EU.empleado_id=E.empleado_id AND EU.uot_id=@uot
  AND EU.estado=1 AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
  AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
WHERE U.nombre_usuario IN('pos_sarasara_01','pos_sarasara_02','pos_sarasara_03')
ORDER BY U.nombre_usuario;
