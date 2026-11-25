-- Diagnóstico del usuario administrador por UOT y sesión.
DECLARE @UsuarioId BIGINT;
SELECT @UsuarioId = U.usuario_id
FROM seg.Usuario U WITH (NOLOCK)
WHERE U.nombre_usuario = 'admin' AND U.estado = 1;

SELECT U.nombre_usuario,
       UU.uot_id,
       O.nombre AS uot_nombre,
       P.codigo AS permiso,
       seg.FN_Usuario_TienePermisoUOT(U.usuario_id, UU.uot_id, P.codigo) AS autorizado
FROM seg.Usuario U WITH (NOLOCK)
INNER JOIN seg.UsuarioUOT UU WITH (NOLOCK)
    ON UU.usuario_id = U.usuario_id AND UU.estado = 1
    AND UU.fecha_desde <= SYSUTCDATETIME()
    AND (UU.fecha_hasta IS NULL OR UU.fecha_hasta > SYSUTCDATETIME())
INNER JOIN org.UOT O WITH (NOLOCK)
    ON O.uot_id = UU.uot_id AND O.estado = 1
INNER JOIN seg.Permiso P WITH (NOLOCK)
    ON P.codigo IN ('CULTIVOS_CREAR', 'CULTIVOS_EDITAR', 'CULTIVOS_VER') AND P.estado = 1
WHERE U.usuario_id = @UsuarioId
ORDER BY UU.uot_id, P.codigo;

SELECT S.sesion_publica_id, S.modo_uot, S.uot_contexto_id, S.estado,
       S.fecha_revocacion
FROM seg.SesionUsuario S WITH (NOLOCK)
WHERE S.usuario_id = @UsuarioId AND S.estado = 1
  AND S.fecha_revocacion IS NULL;
