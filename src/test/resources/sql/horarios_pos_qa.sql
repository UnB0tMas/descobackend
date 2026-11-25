-- DESCO / QA: solo lectura. Ejecutar después de V683 y del bootstrap dev habilitado.
SELECT O.codigo AS uot,U.nombre_usuario AS login,
 CONCAT(P.nombres,N' ',P.apellido_paterno,N' ',COALESCE(P.apellido_materno,N'')) AS empleado,
 E.empleado_id,
 seg.FN_Usuario_TienePermisoUOT(U.usuario_id,O.uot_id,'POS_OPERAR') AS punto_venta,
 seg.FN_Usuario_TienePermisoUOT(U.usuario_id,O.uot_id,'CAJAS_ABRIR') AS abrir_caja,
 seg.FN_Usuario_TienePermisoUOT(U.usuario_id,O.uot_id,'CAJAS_CERRAR') AS cerrar_caja,
 seg.FN_Usuario_TienePermisoUOT(U.usuario_id,O.uot_id,'PERSONAL_COMERCIAL_PROPIO') AS mi_horario,
 ISNULL(AX.habilitado,CONVERT(BIT,1)) AS acceso_comercial
FROM seg.Usuario U JOIN org.Empleado E ON E.empleado_id=U.persona_id
JOIN org.Persona P ON P.persona_id=E.empleado_id
JOIN org.EmpleadoUOT EU ON EU.empleado_id=E.empleado_id AND EU.estado=1
JOIN org.UOT O ON O.uot_id=EU.uot_id AND O.estado=1
LEFT JOIN comercial.AccesoEmpleadoPOS AX ON AX.empleado_id=E.empleado_id AND AX.uot_id=O.uot_id
WHERE U.nombre_usuario IN('pos_sarasara_01','pos_sarasara_02','pos_sarasara_03')
AND O.codigo IN('UOT_GENERAL','UOT_LEGACY_4')
ORDER BY O.codigo,U.nombre_usuario;
SELECT O.codigo AS uot,U.nombre_usuario,H.dia_semana,
 CONVERT(VARCHAR(5),H.hora_inicio,108) AS desde,
 CONVERT(VARCHAR(5),H.hora_fin,108) AS hasta
FROM comercial.HorarioEmpleadoPOS H JOIN org.UOT O ON O.uot_id=H.uot_id
JOIN seg.Usuario U ON U.persona_id=H.empleado_id
WHERE U.nombre_usuario IN('pos_sarasara_01','pos_sarasara_02','pos_sarasara_03')
ORDER BY O.codigo,H.dia_semana,H.hora_inicio;
