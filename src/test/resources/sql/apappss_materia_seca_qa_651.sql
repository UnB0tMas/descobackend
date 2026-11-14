-- QA V651, materia seca para el fundo existente. Lecturas y registro con ROLLBACK.
-- Ejecutar contra la misma BD conectada al backend. No crear sesiones ni alterar permisos.
SET NOCOUNT ON;
DECLARE @uot BIGINT=2,@convenio BIGINT=2,@predio BIGINT=10032,@usuario BIGINT=1;
DECLARE @ahora DATETIME2(0)=SYSUTCDATETIME();

SELECT N'FLYWAY_V651' paso,version,success,installed_on
FROM dbo.flyway_schema_history WHERE version IN('647','648','649','650','651') ORDER BY installed_rank;

SELECT N'FUNDO' paso,P.predio_id,P.nombre,A.uot_id,A.convenio_uot_organizacion_id,
 (SELECT COUNT(*) FROM prod.PlantaPaltaE3 PL
  WHERE PL.predio_id=@predio AND PL.uot_id=@uot AND PL.convenio_id=@convenio
    AND PL.activo=1 AND PL.estado_actual NOT IN('MUERTA','ELIMINADA')) plantas_activas,
 (SELECT COUNT(*) FROM prod.PredioMateriaSecaGlobalE4 G
  WHERE G.predio_id=@predio AND G.uot_id=@uot AND G.convenio_id=@convenio) mediciones
FROM prod.Predio P JOIN prod.PredioAmbito A ON A.predio_id=P.predio_id
WHERE P.predio_id=@predio AND A.uot_id=@uot AND A.convenio_uot_organizacion_id=@convenio
 AND P.estado=1 AND A.estado=1;

SELECT N'PERMISO_UOT_2' paso,P.codigo,
 seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,P.codigo) permitido
FROM seg.Permiso P WHERE P.codigo IN
 ('APAPPSS_PREDIOS_VER','APAPPSS_PREDIOS_EDITAR',
 'APAPPSS_PREDIOS_SECA_LOTE','APAPPSS_PREDIOS_SECA_EDITAR','APAPPSS_PREDIOS_SECA_ELIMINAR')
ORDER BY P.codigo;

IF OBJECT_ID(N'prod.PA_E3_ExpedienteE4_Ejecutar',N'P') IS NULL
 THROW 51451,N'Falta el procedimiento de materia seca.',1;
IF seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'APAPPSS_PREDIOS_VER')<>1
 THROW 51452,N'El administrador no tiene el permiso efectivo para consultar en UOT 2.',1;
IF seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'APAPPSS_PREDIOS_SECA_LOTE')<>1
 THROW 51453,N'El administrador no tiene el permiso efectivo para registrar en UOT 2.',1;

-- Sesion real del usuario admin en la UOT2. Es necesario para replicar la llamada real.
DECLARE @sesion UNIQUEIDENTIFIER;
SELECT TOP(1) @sesion=S.sesion_publica_id
FROM seg.SesionUsuario S JOIN seg.Usuario U ON U.usuario_id=S.usuario_id
WHERE S.usuario_id=@usuario AND S.estado=1 AND S.fecha_revocacion IS NULL
 AND S.fecha_expiracion_renovacion>@ahora AND S.token_version=U.token_version
 AND U.estado=1 AND U.estado_cuenta='ACTIVA'
 AND (S.modo_uot='GENERAL' OR S.modo_uot='ESPECIFICA' AND S.uot_contexto_id=@uot)
ORDER BY S.fecha_ultima_actividad DESC,S.sesion_usuario_id DESC;
IF @sesion IS NULL
BEGIN
 SELECT N'SIN_SESION_ACTIVA' paso,N'Inicie sesion en la UOT 2 y repita el QA.' resultado;
 RETURN;
END;

DECLARE @filtros NVARCHAR(MAX)=(SELECT @uot uotId,@convenio convenioId,@predio predioId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @contexto NVARCHAR(MAX)=(SELECT @sesion sesionPublicaId,NEWID() correlacionId,NEWID() solicitudId,
  N'/api/v1/apappss/predios/10032/materia-seca' endpoint FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @peticion NVARCHAR(MAX)=(SELECT JSON_QUERY(@contexto) contexto,JSON_QUERY(@filtros) filtros,
 JSON_QUERY(N'{}') datos FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @datos NVARCHAR(MAX),@ok BIT,@mensaje NVARCHAR(300),@codigo VARCHAR(60),@http SMALLINT;
EXEC prod.PA_E3_ExpedienteE4_Ejecutar @cAccion='SECA_PREDIO_LISTAR',@cJson=@peticion,
 @cDatos=@datos OUTPUT,@bResultado=@ok OUTPUT,@cMensaje=@mensaje OUTPUT,
 @cCodigoRespuesta=@codigo OUTPUT,@nHttpRespuesta=@http OUTPUT;
SELECT N'LISTAR' paso,@ok exitoso,@codigo codigo,@http http,@mensaje mensaje,
 ISJSON(@datos) json_valido,@datos respuesta;
IF ISNULL(@ok,0)<>1 OR ISJSON(@datos)<>1
 THROW 51454,N'El procedimiento devolvio error. Revise el codigo y auditoria.ErrorBaseDatos.',1;
IF TRY_CONVERT(INT,JSON_VALUE(@datos,'$.totalPlantasActivas')) IS NULL
 THROW 51455,N'Falta totalPlantasActivas en el JSON.',1;
IF JSON_QUERY(@datos,'$.items') IS NULL
 THROW 51456,N'Falta el arreglo de items; incluso el historial vacio debe devolver [].',1;

IF NOT EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 WHERE predio_id=@predio
 AND uot_id=@uot AND convenio_id=@convenio AND activo=1 AND estado_actual NOT IN('MUERTA','ELIMINADA'))
BEGIN
 SELECT N'ALTA_OMITIDA' paso,N'No hay plantas activas.' resultado;
 RETURN;
END;
IF EXISTS(SELECT 1 FROM prod.PredioMateriaSecaGlobalE4
 WHERE predio_id=@predio AND uot_id=@uot AND convenio_id=@convenio AND estado=1
 AND ABS(DATEDIFF(DAY,fecha_muestreo,CONVERT(DATE,@ahora)))<7)
BEGIN
 SELECT N'ALTA_OMITIDA' paso,N'Existe un muestreo activo dentro de los siete dias.' resultado;
 RETURN;
END;

DECLARE @altaContexto NVARCHAR(MAX)=(SELECT @sesion sesionPublicaId,NEWID() correlacionId,
 NEWID() solicitudId,NEWID() claveIdempotencia,
 N'/api/v1/apappss/predios/10032/materia-seca' endpoint FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @muestra NVARCHAR(MAX)=(SELECT CONVERT(DECIMAL(6,3),21.500) porcentaje,
  1 cantidadPlantas,3 cantidadFrutos,'LABORATORIO' metodo,
  CONVERT(DATE,@ahora) fechaMuestreo,N'Prueba QA temporal de materia seca.' informe
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
SET @peticion=(SELECT JSON_QUERY(@altaContexto) contexto,JSON_QUERY(@filtros) filtros,
 JSON_QUERY(@muestra) datos FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
BEGIN TRY
 BEGIN TRANSACTION;
 EXEC prod.PA_E3_ExpedienteE4_Ejecutar @cAccion='SECA_GLOBAL',@cJson=@peticion,
 @cDatos=@datos OUTPUT,@bResultado=@ok OUTPUT,@cMensaje=@mensaje OUTPUT,
 @cCodigoRespuesta=@codigo OUTPUT,@nHttpRespuesta=@http OUTPUT;
 SELECT N'ALTA_QA' paso,@ok exitoso,@codigo codigo,@http http,@mensaje mensaje,@datos datos;
 IF ISNULL(@ok,0)<>1 OR TRY_CONVERT(BIGINT,JSON_VALUE(@datos,'$.informeId')) IS NULL
  THROW 51457,N'El alta no devolvio informeId. Revisar respuesta del servicio.',1;
 IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
 SELECT N'ROLLBACK_OK' paso,N'Sin registros persistentes de prueba.' resultado;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
 SELECT N'QA_FALLO' paso,ERROR_NUMBER() numero_error,ERROR_MESSAGE() error;
 THROW;
END CATCH;
