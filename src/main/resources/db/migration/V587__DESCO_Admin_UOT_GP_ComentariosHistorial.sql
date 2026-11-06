SET XACT_ABORT ON;
GO
BEGIN TRANSACTION;

DECLARE @RolAdmin BIGINT;
SELECT @RolAdmin = rol_id FROM seg.Rol WHERE codigo='ADMINISTRADOR' AND estado=1;
IF @RolAdmin IS NULL THROW 51000, N'No existe el rol ADMINISTRADOR activo.', 1;

UPDATE RP
   SET estado=1, fecha_retiro=NULL, retirado_por_usuario_id=NULL, motivo_retiro=NULL
FROM seg.RolPermiso RP
JOIN seg.Permiso P ON P.permiso_id=RP.permiso_id AND P.estado=1
WHERE RP.rol_id=@RolAdmin AND RP.estado=0;

INSERT INTO seg.RolPermiso(rol_id,permiso_id,estado,fecha_asignacion)
SELECT @RolAdmin,P.permiso_id,1,SYSUTCDATETIME()
FROM seg.Permiso P
WHERE P.estado=1
  AND NOT EXISTS(SELECT 1 FROM seg.RolPermiso RP WITH(UPDLOCK,HOLDLOCK)
                 WHERE RP.rol_id=@RolAdmin AND RP.permiso_id=P.permiso_id);

INSERT INTO seg.UsuarioUOT(usuario_id,uot_id,es_predeterminada,fecha_desde,estado)
SELECT A.usuario_id,A.uot_id,0,SYSUTCDATETIME(),1
FROM (
    SELECT DISTINCT UR.usuario_id,O.uot_id
    FROM seg.UsuarioRol UR
    JOIN seg.Usuario U ON U.usuario_id=UR.usuario_id AND U.estado=1
    CROSS JOIN org.UOT O
    WHERE UR.rol_id=@RolAdmin AND UR.estado=1 AND O.estado=1
      AND UR.fecha_desde<=SYSUTCDATETIME()
      AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta>SYSUTCDATETIME())
) A
WHERE NOT EXISTS(SELECT 1 FROM seg.UsuarioUOT UU WITH(UPDLOCK,HOLDLOCK)
                 WHERE UU.usuario_id=A.usuario_id AND UU.uot_id=A.uot_id
                   AND UU.estado=1 AND UU.fecha_hasta IS NULL);

INSERT INTO seg.UsuarioUOTRol(usuario_uot_id,rol_id,fecha_desde,estado)
SELECT UU.usuario_uot_id,@RolAdmin,SYSUTCDATETIME(),1
FROM seg.UsuarioUOT UU
JOIN seg.Usuario U ON U.usuario_id=UU.usuario_id AND U.estado=1
JOIN org.UOT O ON O.uot_id=UU.uot_id AND O.estado=1
WHERE UU.estado=1 AND UU.fecha_desde<=SYSUTCDATETIME()
  AND (UU.fecha_hasta IS NULL OR UU.fecha_hasta>SYSUTCDATETIME())
  AND EXISTS(SELECT 1 FROM seg.UsuarioRol UR
             WHERE UR.usuario_id=UU.usuario_id AND UR.rol_id=@RolAdmin
               AND UR.estado=1 AND UR.fecha_desde<=SYSUTCDATETIME()
               AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta>SYSUTCDATETIME()))
  AND NOT EXISTS(SELECT 1 FROM seg.UsuarioUOTRol UUR WITH(UPDLOCK,HOLDLOCK)
                 WHERE UUR.usuario_uot_id=UU.usuario_uot_id AND UUR.rol_id=@RolAdmin
                   AND UUR.estado=1 AND UUR.fecha_hasta IS NULL);
COMMIT TRANSACTION;
GO

CREATE OR ALTER PROCEDURE prod.PA_GP_Evento_Sel_Historial
    @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'PREDIOS_VER',0)<>1
        THROW 51101,N'Acceso no autorizado.',1;
    IF NOT EXISTS(
        SELECT 1 FROM prod.GPActividad A
        JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.predio_id=A.predio_id
        JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot
            AND B.convenio_uot_organizacion_id IS NULL AND B.estado=1
        WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot
    ) THROW 51102,N'Actividad fuera del ámbito general.',1;

    SELECT E.evento_id AS eventoId,E.actividad_id AS actividadId,E.tipo,E.observacion,
           E.fecha_hecho AS fechaHecho,E.fecha_registro AS fechaRegistro,
           E.usuario_creacion_id AS usuarioId,U.nombre_usuario AS usuarioNombre,
           E.respuesta_a_id AS respuestaAId,E.problema_id AS problemaId,P.nombre AS problema,
           E.tratamiento_id AS tratamientoId,T.nombre AS tratamiento,
           E.cantidad_afectada AS cantidadAfectada,E.afectados_aproximado AS afectadosAproximado,
           F.foto_id AS fotoId
    FROM prod.GPEvento E
    JOIN seg.Usuario U ON U.usuario_id=E.usuario_creacion_id
    LEFT JOIN prod.GPProblema P ON P.problema_id=E.problema_id
    LEFT JOIN prod.GPTratamiento T ON T.tratamiento_id=E.tratamiento_id
    OUTER APPLY (SELECT TOP(1) EF.foto_id FROM prod.GPEventoFoto EF
                 WHERE EF.evento_id=E.evento_id ORDER BY EF.foto_id) F
    WHERE E.actividad_id=@Actividad AND E.estado=1
    ORDER BY E.fecha_hecho DESC,E.evento_id DESC;
END;
GO
