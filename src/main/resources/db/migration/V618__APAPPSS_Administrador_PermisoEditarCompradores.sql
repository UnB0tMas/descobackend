-- Compradores APAPPSS: el rol ADMINISTRADOR puede editar con el permiso de V617.
-- No concede edición a otros roles ni modifica las asignaciones existentes.
SET XACT_ABORT ON;
GO
BEGIN TRANSACTION;

DECLARE @nRolId BIGINT,
        @nPermisoId BIGINT;

SELECT @nRolId = R.rol_id
FROM seg.Rol R
WHERE R.codigo = 'ADMINISTRADOR' AND R.estado = 1;

SELECT @nPermisoId = P.permiso_id
FROM seg.Permiso P
WHERE P.codigo = 'APAPPSS_COMPRADORES_EDITAR' AND P.estado = 1;

IF @nRolId IS NULL OR @nPermisoId IS NULL
    THROW 51000, N'Falta el rol ADMINISTRADOR o el permiso de edición. Aplicar primero V617.', 1;

UPDATE RP
SET RP.estado = 1,
    RP.fecha_retiro = NULL,
    RP.retirado_por_usuario_id = NULL,
    RP.motivo_retiro = NULL
FROM seg.RolPermiso RP
WHERE RP.rol_id = @nRolId
  AND RP.permiso_id = @nPermisoId
  AND RP.estado = 0;

INSERT INTO seg.RolPermiso(rol_id,permiso_id,estado,fecha_asignacion)
SELECT @nRolId,@nPermisoId,1,SYSUTCDATETIME()
WHERE NOT EXISTS (
    SELECT 1
    FROM seg.RolPermiso RP WITH (UPDLOCK,HOLDLOCK)
    WHERE RP.rol_id = @nRolId AND RP.permiso_id = @nPermisoId
);

COMMIT TRANSACTION;
GO
