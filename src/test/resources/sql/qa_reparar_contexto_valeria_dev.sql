-- Reparación de sesiones existentes de Valeria, SOLO en DESCO_DB_dev / DESCO_DB_dev2.
-- No cambia roles, permisos, contraseñas ni otras cuentas.
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF LOWER(DB_NAME()) NOT IN (N'desco_db_dev', N'desco_db_dev2')
    THROW 51850, N'Este script solo puede ejecutarse en la base de desarrollo DESCO.', 1;

DECLARE @UsuarioId BIGINT, @UotId BIGINT, @Ahora DATETIME2(0) = SYSUTCDATETIME();

SELECT @UsuarioId = U.usuario_id
FROM seg.Usuario U
JOIN org.Persona P ON P.persona_id = U.persona_id
WHERE U.nombre_usuario = 'pos_sarasara_01'
  AND P.numero_documento = 'DESCO-POS-DEMO-01'
  AND U.estado = 1 AND U.estado_cuenta = 'ACTIVA';

SELECT @UotId = O.uot_id
FROM org.UOT O
WHERE O.codigo = 'UOT_LEGACY_4' AND O.estado = 1;

IF @UsuarioId IS NULL OR @UotId IS NULL
    THROW 51851, N'La cuenta o la sede de prueba no están disponibles.', 1;

IF ISNULL(seg.FN_Usuario_TieneAccesoUOT(@UsuarioId, @UotId), 0) <> 1
    THROW 51852, N'La cuenta no tiene un vínculo de UOT vigente; revise sus asignaciones.', 1;

SELECT 'ANTES' AS etapa, S.sesion_usuario_id, S.modo_uot, S.uot_contexto_id
FROM seg.SesionUsuario S
WHERE S.usuario_id = @UsuarioId
  AND S.estado = 1 AND S.fecha_revocacion IS NULL
  AND S.fecha_expiracion_renovacion > @Ahora;

BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE S
    SET modo_uot = 'ESPECIFICA',
        uot_contexto_id = @UotId,
        fecha_ultima_actividad = SYSUTCDATETIME()
    FROM seg.SesionUsuario S
    JOIN seg.Usuario U ON U.usuario_id = S.usuario_id
    WHERE S.usuario_id = @UsuarioId
      AND S.estado = 1
      AND S.fecha_revocacion IS NULL
      AND S.fecha_expiracion_renovacion > @Ahora
      AND S.token_version = U.token_version
      AND S.modo_uot = 'ESPECIFICA'
      AND S.uot_contexto_id IS NULL;

    SELECT @@ROWCOUNT AS sesiones_reparadas;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

SELECT 'DESPUES' AS etapa, S.sesion_usuario_id, S.modo_uot, S.uot_contexto_id
FROM seg.SesionUsuario S
WHERE S.usuario_id = @UsuarioId
  AND S.estado = 1 AND S.fecha_revocacion IS NULL
  AND S.fecha_expiracion_renovacion > @Ahora;

SELECT P.codigo AS permiso,
       CONVERT(INT, seg.FN_Usuario_TienePermisoUOT(@UsuarioId, @UotId, P.codigo)) AS permitido
FROM seg.Permiso P
WHERE P.codigo IN ('POS_OPERAR', 'PERSONAL_COMERCIAL_PROPIO')
ORDER BY P.codigo;

-- Si permitido=0, investigar rol/permisos vigentes; no conceder acceso automáticamente.
