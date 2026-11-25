-- Diagnóstico de solo lectura del bootstrap comercial de pruebas.
SET NOCOUNT ON;
DECLARE @sara BIGINT=(SELECT uot_id FROM org.UOT WHERE codigo='UOT_LEGACY_4' AND estado=1);
IF @sara IS NULL THROW 51601,N'UOT Sara Sara no disponible.',1;
IF OBJECT_ID(N'comercial.FN_Pos_HorarioVigente',N'FN') IS NULL
 OR OBJECT_ID(N'comercial.TR_Venta_CajaSesion',N'TR') IS NULL
 OR OBJECT_ID(N'comercial.TR_PagoVenta_CajaActiva',N'TR') IS NULL
 THROW 51606,N'Faltan controles comerciales de horario y caja.',1;
SELECT O.codigo,U.nombre_usuario,E.empleado_id,P.nombres,P.apellido_paterno,
       EU.es_principal,UU.es_predeterminada,ISNULL(A.habilitado,CONVERT(BIT,1)) habilitado_pos,
       seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@sara,'POS_OPERAR') puede_vender,
       seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@sara,'CAJAS_LISTAR') ver_caja,
       seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@sara,'CAJAS_ABRIR') abrir_caja,
       seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@sara,'CAJAS_CERRAR') cerrar_caja,
       seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@sara,'VENTAS_REPORTES') reporte_cierre,
       seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@sara,'PERSONAL_COMERCIAL_PROPIO') mi_horario,
       seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@sara,'PERSONAL_COMERCIAL_LISTAR') gestionar_horarios,
       seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@sara,'POS_SIN_HORARIO') sin_horario,
       seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@sara,'POS_SIN_CAJA') sin_caja
FROM seg.Usuario U
JOIN org.Empleado E ON E.empleado_id=U.persona_id AND E.estado=1
JOIN org.Persona P ON P.persona_id=E.empleado_id AND P.estado=1
JOIN org.EmpleadoUOT EU ON EU.empleado_id=E.empleado_id AND EU.uot_id=@sara AND EU.estado=1
 AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME()) AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
JOIN seg.UsuarioUOT UU ON UU.usuario_id=U.usuario_id AND UU.uot_id=@sara AND UU.estado=1
 AND UU.fecha_desde<=SYSUTCDATETIME() AND (UU.fecha_hasta IS NULL OR UU.fecha_hasta>SYSUTCDATETIME())
JOIN org.UOT O ON O.uot_id=EU.uot_id
LEFT JOIN comercial.AccesoEmpleadoPOS A ON A.empleado_id=E.empleado_id AND A.uot_id=@sara
WHERE U.nombre_usuario IN('pos_sarasara_01','pos_sarasara_02','pos_sarasara_03')
ORDER BY U.nombre_usuario;
IF (SELECT COUNT(DISTINCT U.usuario_id)
    FROM seg.Usuario U JOIN org.Empleado E ON E.empleado_id=U.persona_id AND E.estado=1
    JOIN org.EmpleadoUOT EU ON EU.empleado_id=E.empleado_id AND EU.uot_id=@sara AND EU.estado=1
      AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME()) AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
    JOIN seg.UsuarioUOT UU ON UU.usuario_id=U.usuario_id AND UU.uot_id=@sara AND UU.estado=1
      AND UU.fecha_desde<=SYSUTCDATETIME() AND (UU.fecha_hasta IS NULL OR UU.fecha_hasta>SYSUTCDATETIME())
    WHERE U.nombre_usuario IN('pos_sarasara_01','pos_sarasara_02','pos_sarasara_03')
      AND U.estado=1 AND U.estado_cuenta='ACTIVA'
      AND seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@sara,'POS_OPERAR')=1
      AND seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@sara,'CAJAS_ABRIR')=1
      AND seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@sara,'CAJAS_CERRAR')=1)<>3
    THROW 51602,N'No están habilitados los tres operadores de Sara Sara.',1;
-- Los tres operadores consultan sus propios horarios, sin administrar turnos ajenos.
IF EXISTS (SELECT 1 FROM seg.Usuario U
 CROSS JOIN (VALUES ('PERSONAL_COMERCIAL_LISTAR'),('PERSONAL_COMERCIAL_EDITAR'),
                   ('PERSONAL_COMERCIAL_HABILITAR'),('HORARIO_COMERCIAL_CONFIGURAR')) P(codigo)
 WHERE U.nombre_usuario='pos_sarasara_01'
   AND seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@sara,P.codigo)=1)
 THROW 51603,N'El perfil operativo demo conserva funciones de administración.',1;
IF EXISTS (SELECT 1 FROM seg.Usuario U
 WHERE U.nombre_usuario IN('pos_sarasara_02','pos_sarasara_03')
 AND seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@sara,'PERSONAL_COMERCIAL_EDITAR')=1)
 THROW 51607,N'Un operador de prueba recibió permisos administrativos.',1;
IF (SELECT COUNT(*) FROM seg.Usuario U WHERE U.nombre_usuario IN('pos_sarasara_02','pos_sarasara_03')
 AND seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@sara,'POS_SIN_HORARIO')=1)<>2
 THROW 51604,N'Permisos de excepción de horario incompletos.',1;
IF (SELECT COUNT(*) FROM seg.Usuario U WHERE U.nombre_usuario='pos_sarasara_03'
 AND seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@sara,'POS_SIN_CAJA')=1)<>1
 THROW 51605,N'Excepción de caja incompleta.',1;
SELECT N'QA POS SARA SARA: tres operadores habilitados, sin administración de horarios.' resultado;
