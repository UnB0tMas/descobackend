-- DESCO APAPPSS / Materia seca de fundo: QA DE SOLO LECTURA.
-- Ejecutar en SQL Server luego de aplicar V645, V647 y V648.
-- No contiene INSERT, UPDATE, DELETE ni cambia datos.
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.flyway_schema_history',N'U') IS NOT NULL
 EXEC(N'SELECT [version],[description],[success],[installed_on]
       FROM dbo.flyway_schema_history
       WHERE [version] IN (''413'',''414'',''645'',''647'',''648'')
       ORDER BY TRY_CONVERT(INT,[version]);');
ELSE PRINT N'Consultar el esquema configurado para flyway_schema_history.';

SELECT
    OBJECT_ID(N'prod.PredioMateriaSecaGlobalE4',N'U') AS tabla_informes,
    OBJECT_ID(N'prod.PredioMateriaSecaCambioE4',N'U') AS tabla_auditoria,
    OBJECT_ID(N'prod.PA_E3_ExpedienteE4_Ejecutar',N'P') AS procedimiento,
    OBJECT_ID(N'seg.FN_Usuario_TienePermisoUOT',N'FN') AS funcion_autorizacion,
    COL_LENGTH(N'prod.PredioMateriaSecaGlobalE4',N'version') AS bytes_version,
    COL_LENGTH(N'prod.PredioMateriaSecaGlobalE4',N'estado') AS bytes_estado;

SELECT P.codigo, P.estado permiso_activo,
       SUM(CASE WHEN RP.estado=1 THEN 1 ELSE 0 END) asignaciones_admin_activas
FROM seg.Permiso P
LEFT JOIN seg.RolPermiso RP ON RP.permiso_id=P.permiso_id
 AND RP.rol_id=(SELECT TOP(1) rol_id FROM seg.Rol WHERE codigo='ADMINISTRADOR' AND estado=1)
WHERE P.codigo IN ('APAPPSS_SOCIOS_LISTAR','APAPPSS_SOCIOS_VER',
    'APAPPSS_PREDIOS_LISTAR','APAPPSS_PREDIOS_VER',
    'APAPPSS_PREDIOS_CREAR','APAPPSS_PREDIOS_EDITAR','APAPPSS_PREDIOS_RETIRAR',
    'APAPPSS_PREDIOS_SECA_LOTE','APAPPSS_PREDIOS_SECA_EDITAR',
    'APAPPSS_PREDIOS_SECA_ELIMINAR')
GROUP BY P.codigo,P.estado ORDER BY P.codigo;

-- Muestra autorizaciones explicitas por UOT para administradores activos.
SELECT U.nombre_usuario, OU.uot_id AS uot_id, P.codigo,
       UP.permitido, UP.estado, UP.fecha_desde, UP.fecha_hasta
FROM seg.Usuario U
JOIN seg.UsuarioRol UR ON UR.usuario_id=U.usuario_id AND UR.estado=1
JOIN seg.Rol R ON R.rol_id=UR.rol_id AND R.codigo='ADMINISTRADOR' AND R.estado=1
JOIN seg.UsuarioUOT UU ON UU.usuario_id=U.usuario_id AND UU.estado=1
JOIN org.UOT OU ON OU.uot_id=UU.uot_id
JOIN seg.UsuarioUOTPermiso UP ON UP.usuario_uot_id=UU.usuario_uot_id AND UP.estado=1
JOIN seg.Permiso P ON P.permiso_id=UP.permiso_id
WHERE U.estado=1 AND P.codigo IN (
 'APAPPSS_PREDIOS_VER','APAPPSS_PREDIOS_EDITAR',
 'APAPPSS_PREDIOS_SECA_LOTE','APAPPSS_PREDIOS_SECA_EDITAR',
 'APAPPSS_PREDIOS_SECA_ELIMINAR')
ORDER BY U.nombre_usuario,OU.uot_id,P.codigo;

-- Revisar para un predio real el GET /api/v1/apappss/predios/{predioId}/materia-seca
-- usando uotId y convenioId del expediente. Si hay 403 revisar override/ambito,
-- si hay 503 comprobar la migracion SQL y el log servidor con correlacionId.
