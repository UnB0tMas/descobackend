-- QA de solo lectura. No modifica datos ni sesiones.
SET NOCOUNT ON;

SELECT DB_NAME() AS base_datos,
       CASE WHEN OBJECT_ID(N'[seg].[SesionUsuario]', N'U') IS NULL THEN 'NO_EXISTE' ELSE 'EXISTE' END AS tabla_sesion,
       CASE WHEN COL_LENGTH(N'seg.SesionUsuario',N'modo_uot') IS NULL THEN 'FALTA' ELSE 'OK' END AS modo_uot,
       CASE WHEN COL_LENGTH(N'seg.SesionUsuario',N'uot_contexto_id') IS NULL THEN 'FALTA' ELSE 'OK' END AS uot_contexto_id;

DECLARE @RolAdmin BIGINT;
DECLARE @UsuarioAdmin BIGINT;
SELECT @RolAdmin=R.rol_id FROM seg.Rol R WHERE R.codigo='ADMINISTRADOR' AND R.estado=1;
SELECT @UsuarioAdmin=U.usuario_id FROM seg.Usuario U WHERE U.nombre_usuario='admin' AND U.estado=1;

SELECT U.usuario_id,U.nombre_usuario,R.codigo AS rol,
       UR.estado AS asignacion_activa,UR.fecha_desde,UR.fecha_hasta
FROM seg.Usuario U
LEFT JOIN seg.UsuarioRol UR ON UR.usuario_id=U.usuario_id AND UR.rol_id=@RolAdmin
LEFT JOIN seg.Rol R ON R.rol_id=UR.rol_id
WHERE U.nombre_usuario='admin';

SELECT COUNT(P.permiso_id) AS permisos_activos,
       SUM(CASE WHEN RP.permiso_id IS NOT NULL AND RP.estado=1 THEN 1 ELSE 0 END) AS permisos_admin_activos,
       SUM(CASE WHEN RP.permiso_id IS NULL OR RP.estado<>1 THEN 1 ELSE 0 END) AS permisos_pendientes
FROM seg.Permiso P
LEFT JOIN seg.RolPermiso RP ON RP.permiso_id=P.permiso_id AND RP.rol_id=@RolAdmin
WHERE P.estado=1;

SELECT O.uot_id,O.nombre AS uot,
       CASE WHEN UU.usuario_uot_id IS NULL THEN 'PENDIENTE' ELSE 'OK' END AS asignacion_uot,
       CASE WHEN UUR.usuario_uot_rol_id IS NULL THEN 'PENDIENTE' ELSE 'OK' END AS rol_admin_uot,
       seg.FN_Usuario_TieneAccesoUOT(@UsuarioAdmin,O.uot_id) AS acceso_uot
FROM org.UOT O
OUTER APPLY (
    SELECT TOP (1) A.usuario_uot_id FROM seg.UsuarioUOT A
    WHERE A.usuario_id=@UsuarioAdmin AND A.uot_id=O.uot_id
      AND A.estado=1 AND A.fecha_desde<=SYSUTCDATETIME()
      AND (A.fecha_hasta IS NULL OR A.fecha_hasta>SYSUTCDATETIME())
    ORDER BY A.usuario_uot_id DESC
) UU
OUTER APPLY (
    SELECT TOP (1) A.usuario_uot_rol_id FROM seg.UsuarioUOTRol A
    WHERE A.usuario_uot_id=UU.usuario_uot_id AND A.rol_id=@RolAdmin
      AND A.estado=1 AND A.fecha_desde<=SYSUTCDATETIME()
      AND (A.fecha_hasta IS NULL OR A.fecha_hasta>SYSUTCDATETIME())
    ORDER BY A.usuario_uot_rol_id DESC
) UUR
WHERE O.estado=1 ORDER BY O.uot_id;

SELECT O.uot_id,P.codigo AS permiso,
       seg.FN_Usuario_TienePermisoUOT(@UsuarioAdmin,O.uot_id,P.codigo) AS autorizado,
       CASE WHEN EXISTS (
           SELECT 1 FROM seg.ModuloEspecialPermiso MP WHERE MP.permiso_id=P.permiso_id
       ) THEN 'MODULO_ESPECIAL: requiere convenio vigente' ELSE 'GENERAL' END AS clase
FROM org.UOT O CROSS JOIN seg.Permiso P
WHERE O.estado=1 AND P.estado=1
  AND P.codigo IN ('PREDIOS_VER','PREDIOS_EDITAR','CULTIVOS_VER','CULTIVOS_EDITAR','SANIDAD_CREAR','EVALUACIONES_CREAR')
ORDER BY O.uot_id,P.codigo;

-- Consulta dinamica para que no falle la compilacion SQL cuando falten columnas.
IF COL_LENGTH(N'seg.SesionUsuario',N'modo_uot') IS NOT NULL
   AND COL_LENGTH(N'seg.SesionUsuario',N'uot_contexto_id') IS NOT NULL
BEGIN
    EXEC sys.sp_executesql N'
      SELECT TOP (10) U.nombre_usuario,S.modo_uot,S.uot_contexto_id,
             S.fecha_ultima_actividad
      FROM seg.SesionUsuario S
      JOIN seg.Usuario U ON U.usuario_id=S.usuario_id
      WHERE U.nombre_usuario = N''admin'' AND S.estado=1 AND S.fecha_revocacion IS NULL
      ORDER BY S.fecha_ultima_actividad DESC;';
END
ELSE
    SELECT N'Faltan columnas de contexto UOT en esta base. Comparar el esquema con la migracion V588 y volver a iniciar sesion.' AS diagnostico_sesion;

SELECT TOP (30) E.actividad_id,E.evento_id,E.observacion,
       E.fecha_registro AS fecha_registro_utc,
       E.usuario_creacion_id,U.nombre_usuario
FROM prod.GPEvento E
JOIN seg.Usuario U ON U.usuario_id=E.usuario_creacion_id
WHERE E.tipo='OBSERVACION' AND E.estado=1
ORDER BY E.fecha_registro DESC,E.evento_id DESC;
