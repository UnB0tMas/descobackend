-- QA de solo lectura: cuenta y horarios demo en UOT 2.
DECLARE @nUotId BIGINT = 2;
DECLARE @cUsuario VARCHAR(80) = 'pos_sarasara_01';

SELECT
    U.usuario_id AS usuarioId,
    U.nombre_usuario AS usuario,
    U.estado_cuenta AS estadoCuenta,
    E.empleado_id AS empleadoId,
    P.nombres AS nombres,
    P.apellido_paterno AS apellidoPaterno,
    P.apellido_materno AS apellidoMaterno,
    EU.uot_id AS uotEmpleado,
    UU.uot_id AS uotCuenta,
    CONVERT(INT, seg.FN_Usuario_TienePermisoUOT(U.usuario_id, @nUotId, 'PERSONAL_COMERCIAL_PROPIO')) AS permisoMiHorario
FROM seg.Usuario U WITH (NOLOCK)
JOIN org.Persona P WITH (NOLOCK) ON P.persona_id = U.persona_id
LEFT JOIN org.Empleado E WITH (NOLOCK) ON E.empleado_id = P.persona_id AND E.estado = 1
LEFT JOIN org.EmpleadoUOT EU WITH (NOLOCK) ON EU.empleado_id = E.empleado_id
    AND EU.uot_id = @nUotId AND EU.estado = 1
    AND EU.fecha_desde <= CONVERT(DATE, SYSUTCDATETIME())
    AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta >= CONVERT(DATE, SYSUTCDATETIME()))
LEFT JOIN seg.UsuarioUOT UU WITH (NOLOCK) ON UU.usuario_id = U.usuario_id
    AND UU.uot_id = @nUotId AND UU.estado = 1
    AND UU.fecha_desde <= SYSUTCDATETIME()
    AND (UU.fecha_hasta IS NULL OR UU.fecha_hasta > SYSUTCDATETIME())
WHERE U.nombre_usuario = @cUsuario;

SELECT
    P.nombres AS empleado,
    H.dia_semana AS dia,
    CONVERT(VARCHAR(5), H.hora_inicio, 108) AS desde,
    CONVERT(VARCHAR(5), H.hora_fin, 108) AS hasta
FROM comercial.HorarioEmpleadoPOS H WITH (NOLOCK)
JOIN org.Persona P WITH (NOLOCK) ON P.persona_id = H.empleado_id
JOIN seg.Usuario U WITH (NOLOCK) ON U.persona_id = P.persona_id
WHERE U.nombre_usuario = @cUsuario AND H.uot_id = @nUotId
ORDER BY H.dia_semana, H.hora_inicio;
