-- Consultas de verificación, sin escrituras.
DECLARE @uot BIGINT=(SELECT uot_id FROM org.UOT WHERE codigo='UOT_LEGACY_4' AND estado=1);
SELECT O.codigo,U.nombre_usuario,E.empleado_id,
 seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@uot,'POS_OPERAR') pos,
 seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@uot,'CAJAS_ABRIR') abrir,
 seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@uot,'CAJAS_CERRAR') cerrar,
 seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@uot,'VENTAS_REPORTES') reporte,
 seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@uot,'PERSONAL_COMERCIAL_PROPIO') mi_horario,
 seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@uot,'POS_SIN_HORARIO') sin_horario,
 seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@uot,'POS_SIN_CAJA') sin_caja,
 comercial.FN_Pos_HorarioVigente(U.usuario_id,@uot) puede_operar_ahora
FROM seg.Usuario U JOIN org.Empleado E ON E.empleado_id=U.persona_id
JOIN org.UOT O ON O.uot_id=@uot
WHERE U.nombre_usuario IN('pos_sarasara_01','pos_sarasara_02','pos_sarasara_03')
ORDER BY U.nombre_usuario;
SELECT S.caja_sesion_id,C.nombre AS caja,U.nombre_usuario AS empleado,
 A.fecha_asignacion,A.activo
FROM comercial.CajaSesionOperador A JOIN comercial.CajaSesion S ON S.caja_sesion_id=A.caja_sesion_id
JOIN comercial.CajaPOS C ON C.caja_id=S.caja_id JOIN seg.Usuario U ON U.usuario_id=A.usuario_id
WHERE C.uot_id=@uot AND S.estado='ABIERTA' ORDER BY S.caja_sesion_id,A.fecha_asignacion;
SELECT V.venta_id,V.caja_sesion_id,U.nombre_usuario AS vendedor,V.fecha_hora,V.total
FROM comercial.Venta V JOIN seg.Usuario U ON U.usuario_id=V.vendedor_usuario_id
WHERE V.uot_id=@uot ORDER BY V.venta_id DESC;
