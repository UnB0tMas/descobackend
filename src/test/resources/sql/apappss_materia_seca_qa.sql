-- QA de solo lectura: DESCO APAPPSS / materia seca por fundo.
-- Ejecutar en la BD del ambiente con los valores reales; NO modifica datos.
SET NOCOUNT ON;
DECLARE @uotId BIGINT = NULL;
DECLARE @convenioId BIGINT = NULL;
DECLARE @predioId BIGINT = NULL;
-- Opcional: completar los tres IDs de la URL de la consulta que falla.

SELECT N'Objetos' AS control,
 OBJECT_ID(N'prod.PredioMateriaSecaGlobalE4',N'U') AS tabla_materia_seca,
 OBJECT_ID(N'prod.PredioMateriaSecaCambioE4',N'U') AS tabla_auditoria,
 OBJECT_ID(N'prod.PA_E3_ExpedienteE4_Ejecutar',N'P') AS procedimiento,
 OBJECT_ID(N'seg.FN_Usuario_TienePermisoUOT',N'FN') AS funcion_permiso;

SELECT C.name AS columna, T.name AS tipo
FROM sys.columns C
JOIN sys.types T ON T.user_type_id=C.user_type_id
WHERE C.object_id=OBJECT_ID(N'prod.PredioMateriaSecaGlobalE4',N'U')
AND C.name IN(N'estado',N'version',N'cantidad_frutos',N'metodo',N'usuario_id',N'fecha_registro')
ORDER BY C.name;

IF OBJECT_ID(N'dbo.flyway_schema_history',N'U') IS NOT NULL
 EXEC sys.sp_executesql N'SELECT version,description,success,installed_on
 FROM dbo.flyway_schema_history WHERE version IN (''645'',''647'',''648'') ORDER BY version';
ELSE PRINT N'Comprobar historial Flyway en el esquema utilizado por el backend.';

SELECT P.codigo,P.estado AS permiso_activo,
 CASE WHEN EXISTS(SELECT 1 FROM seg.ModuloEspecialPermiso M
   JOIN seg.ModuloEspecial E ON E.modulo_especial_id=M.modulo_especial_id
   WHERE M.permiso_id=P.permiso_id AND E.codigo='COMERCIALIZACION_ASOCIATIVA' AND E.estado=1)
 THEN 1 ELSE 0 END AS modulo_especial,
 CASE WHEN EXISTS(SELECT 1 FROM seg.RolPermiso RP
   JOIN seg.Rol R ON R.rol_id=RP.rol_id
   WHERE RP.permiso_id=P.permiso_id AND RP.estado=1 AND R.codigo='ADMINISTRADOR' AND R.estado=1)
 THEN 1 ELSE 0 END AS rol_administrador
FROM seg.Permiso P
WHERE P.codigo IN ('APAPPSS_SOCIOS_LISTAR','APAPPSS_SOCIOS_VER',
'APAPPSS_PREDIOS_LISTAR','APAPPSS_PREDIOS_VER','APAPPSS_PREDIOS_EDITAR',
'APAPPSS_PREDIOS_SECA_LOTE','APAPPSS_PREDIOS_SECA_EDITAR','APAPPSS_PREDIOS_SECA_ELIMINAR')
ORDER BY P.codigo;

-- Permiso EFECTIVO para cada administrador, en su UOT real.
SELECT U.usuario_id,U.nombre_usuario,UU.uot_id,P.codigo,
 seg.FN_Usuario_TienePermisoUOT(U.usuario_id,UU.uot_id,P.codigo) AS permiso_efectivo
FROM seg.Usuario U
JOIN seg.UsuarioRol UR ON UR.usuario_id=U.usuario_id AND UR.estado=1
JOIN seg.Rol R ON R.rol_id=UR.rol_id AND R.estado=1 AND R.codigo='ADMINISTRADOR'
JOIN seg.UsuarioUOT UU ON UU.usuario_id=U.usuario_id AND UU.estado=1
JOIN org.UOT O ON O.uot_id=UU.uot_id AND O.estado=1
CROSS JOIN seg.Permiso P
WHERE U.estado=1 AND P.estado=1
AND UR.fecha_desde<=SYSUTCDATETIME()
AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta>SYSUTCDATETIME())
AND UU.fecha_desde<=SYSUTCDATETIME()
AND (UU.fecha_hasta IS NULL OR UU.fecha_hasta>SYSUTCDATETIME())
AND (@uotId IS NULL OR UU.uot_id=@uotId)
AND P.codigo IN ('APAPPSS_PREDIOS_VER','APAPPSS_PREDIOS_EDITAR',
'APAPPSS_PREDIOS_SECA_LOTE','APAPPSS_PREDIOS_SECA_EDITAR','APAPPSS_PREDIOS_SECA_ELIMINAR')
ORDER BY U.usuario_id,UU.uot_id,P.codigo;

IF @uotId IS NOT NULL AND @convenioId IS NOT NULL AND @predioId IS NOT NULL
BEGIN
 SELECT A.predio_id,A.uot_id,A.convenio_uot_organizacion_id,A.estado,
        C.estado AS convenio_activo,C.fecha_inicio,C.fecha_fin
 FROM prod.PredioAmbito A
 JOIN org.ConvenioUOTOrganizacion C
   ON C.convenio_uot_organizacion_id=A.convenio_uot_organizacion_id
 WHERE A.predio_id=@predioId AND A.uot_id=@uotId
   AND A.convenio_uot_organizacion_id=@convenioId;

 SELECT G.informe_id,G.fecha_muestreo,G.porcentaje,G.usuario_id,G.estado,G.version
 FROM prod.PredioMateriaSecaGlobalE4 G
 WHERE G.predio_id=@predioId AND G.uot_id=@uotId AND G.convenio_id=@convenioId
 ORDER BY G.fecha_muestreo DESC,G.informe_id DESC;
END;

-- Si existen los objetos y la autorización es 1, probar el GET real y buscar
-- el correlacionId en los logs del backend. El QA no suplanta sesiones reales.
