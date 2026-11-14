-- DESCO V651. Materia seca APAPPSS: historial vacio y errores verificables.
-- Basado exactamente en PA de V647, sin cambios en permisos, filtros territoriales ni CRUD.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE prod.PA_E3_ExpedienteE4_Ejecutar
 @cAccion VARCHAR(30), @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT,
 @bResultado BIT OUTPUT, @cMensaje NVARCHAR(300) OUTPUT,
 @cCodigoRespuesta VARCHAR(60) OUTPUT, @nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo completar el expediente.',
        @cCodigoRespuesta='E4_ERROR',@nHttpRespuesta=400;
 DECLARE @uot BIGINT, @conv BIGINT, @predio BIGINT, @planta BIGINT, @episodio BIGINT,
         @usuario BIGINT, @sesion BIGINT, @disp BIGINT, @emp BIGINT, @modulo INT,
         @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
         @auth BIT,@authMensaje NVARCHAR(300),@perm VARCHAR(60),@extra VARCHAR(60),
         @clave UNIQUEIDENTIFIER,@hash VARBINARY(32),@anterior VARBINARY(32),@previo NVARCHAR(MAX),
         @fecha DATE,@porcentaje DECIMAL(6,3),@texto NVARCHAR(2000),@comentario NVARCHAR(1000),
         @resultado NVARCHAR(600),@cantidad INT,@total INT,@id BIGINT,@estado VARCHAR(16),
         @inicio DATETIME2(0),@gp INT,@ahora DATETIME2(0)=SYSUTCDATETIME(),
         @version BIGINT,@versionActual BIGINT,@fechaAnterior DATE,
         @frutos INT,@metodo VARCHAR(15),@motivo NVARCHAR(500),
         @antes NVARCHAR(MAX),@despues NVARCHAR(MAX);
 BEGIN TRY
  IF ISJSON(@cJson)<>1 THROW 51310,N'Petición inválida.',1;
  SELECT @uot=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
   @conv=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.convenioId')),
   @predio=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.predioId')),
   @planta=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.plantaId')),
   @episodio=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.episodioId')),
   @clave=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia'));
  IF @uot IS NULL OR @conv IS NULL OR @predio IS NULL OR @uot<=0 OR @conv<=0 OR @predio<=0
    THROW 51311,N'Indique la UOT, convenio y predio válidos.',1;
  IF @cAccion NOT IN ('NOTAS_LISTAR','NOTA_REGISTRAR','TRATAMIENTOS_LOTE',
       'SECA_PLANTA_LISTAR','SECA_INDIVIDUAL','SECA_PREDIO_LISTAR','SECA_GLOBAL',
       'SECA_GLOBAL_EDITAR','SECA_GLOBAL_ELIMINAR')
    THROW 51312,N'Operación no permitida.',1;
  SET @perm=CASE WHEN @cAccion IN ('NOTAS_LISTAR','SECA_PLANTA_LISTAR','SECA_PREDIO_LISTAR')
    THEN 'APAPPSS_PREDIOS_VER' ELSE 'APAPPSS_PREDIOS_EDITAR' END;
  SET @extra=CASE @cAccion
    WHEN 'NOTA_REGISTRAR' THEN 'APAPPSS_PLANTAS_SALUD_COMENTAR'
    WHEN 'TRATAMIENTOS_LOTE' THEN 'APAPPSS_PLANTAS_TRATAMIENTO_LOTE'
    WHEN 'SECA_INDIVIDUAL' THEN 'APAPPSS_PLANTAS_SECA_REGISTRAR'
    WHEN 'SECA_GLOBAL' THEN 'APAPPSS_PREDIOS_SECA_LOTE'
    WHEN 'SECA_GLOBAL_EDITAR' THEN 'APAPPSS_PREDIOS_SECA_EDITAR'
    WHEN 'SECA_GLOBAL_ELIMINAR' THEN 'APAPPSS_PREDIOS_SECA_ELIMINAR' ELSE NULL END;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,@perm,
    @usuario OUTPUT,@sesion OUTPUT,@disp OUTPUT,@emp OUTPUT,@modulo OUTPUT,
    @corr OUTPUT,@sol OUTPUT,@ip OUTPUT,@endpoint OUTPUT,@auth OUTPUT,@authMensaje OUTPUT;
  IF ISNULL(@auth,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,@perm)<>1
    THROW 51313,N'No tiene acceso al expediente de este predio.',1;
  IF @extra IS NOT NULL AND seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,@extra)<>1
    THROW 51314,N'No tiene permiso para registrar esta actuación.',1;
  SET @fecha=CONVERT(DATE,@ahora);
  IF NOT EXISTS (SELECT 1 FROM prod.PredioAmbito A
    JOIN org.ConvenioUOTOrganizacion C ON C.convenio_uot_organizacion_id=A.convenio_uot_organizacion_id
    JOIN org.ConvenioModuloEspecial M ON M.convenio_uot_organizacion_id=C.convenio_uot_organizacion_id AND M.estado=1
    JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=M.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
    JOIN prod.Predio P ON P.predio_id=A.predio_id AND P.estado=1
    WHERE A.predio_id=@predio AND A.uot_id=@uot AND A.convenio_uot_organizacion_id=@conv AND A.estado=1
      AND C.uot_id=@uot AND C.estado=1 AND (C.fecha_inicio IS NULL OR C.fecha_inicio<=@fecha)
      AND (C.fecha_fin IS NULL OR C.fecha_fin>=@fecha)
      AND EXISTS(SELECT 1 FROM prod.PredioTitularidad T
        JOIN org.Socio S ON S.socio_id=T.socio_id AND S.estado=1
        JOIN org.SocioAsociacion SA ON SA.socio_id=T.socio_id AND SA.asociacion_id=C.empresa_id
           AND SA.estado=1 AND SA.fecha_desde<=@fecha AND (SA.fecha_hasta IS NULL OR SA.fecha_hasta>=@fecha)
        WHERE T.predio_id=@predio AND T.estado=1 AND T.fecha_hasta IS NULL))
    THROW 51315,N'El predio no pertenece al convenio autorizado.',1;
  IF @cAccion NOT IN('SECA_GLOBAL','SECA_PREDIO_LISTAR','SECA_GLOBAL_EDITAR','SECA_GLOBAL_ELIMINAR')
  BEGIN
   IF @planta IS NULL OR NOT EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 P
      WHERE P.planta_id=@planta AND P.predio_id=@predio AND P.uot_id=@uot AND P.convenio_id=@conv)
    THROW 51316,N'La planta no pertenece a este predio.',1;
  END;
  IF @cAccion IN('NOTAS_LISTAR','NOTA_REGISTRAR','TRATAMIENTOS_LOTE')
  BEGIN
   IF @episodio IS NULL OR NOT EXISTS(SELECT 1 FROM sanidad.EpisodioPlantaE3 E
       WHERE E.episodio_id=@episodio AND E.planta_id=@planta)
    THROW 51317,N'La enfermedad no pertenece a esta planta.',1;
  END;

  IF @cAccion='NOTAS_LISTAR'
  BEGIN
   SET @cDatos=(SELECT JSON_QUERY((SELECT N.nota_id notaId,N.comentario,N.usuario_id usuarioId,
     U.nombre_usuario usuarioNombre,
     CONVERT(VARCHAR(19),N.fecha_registro,126)+'Z' fechaHora
     FROM sanidad.EpisodioNotaE4 N LEFT JOIN seg.Usuario U ON U.usuario_id=N.usuario_id
     WHERE N.episodio_id=@episodio ORDER BY N.fecha_registro DESC,N.nota_id DESC FOR JSON PATH)) items
     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='SECA_PREDIO_LISTAR'
  BEGIN
   SELECT @total=COUNT(*) FROM prod.PlantaPaltaE3 P WHERE P.predio_id=@predio AND P.uot_id=@uot
    AND P.convenio_id=@conv AND P.activo=1 AND P.estado_actual NOT IN('MUERTA','ELIMINADA');
   SET @cDatos=(SELECT @total totalPlantasActivas,
    COALESCE(JSON_QUERY((SELECT G.informe_id informeId,G.porcentaje,G.cantidad_plantas cantidadPlantas,
       G.total_plantas_activas totalPlantasAlRegistro,G.cobertura,G.informe,
       G.cantidad_frutos cantidadFrutos,G.metodo,
       CONVERT(BIT,G.estado) activo,G.version,
       G.modificado_por_usuario_id modificadoPorUsuarioId,
       UM.nombre_usuario modificadoPorNombre,
       CONVERT(VARCHAR(19),G.fecha_modificacion,126)+'Z' fechaModificacion,
       G.eliminado_por_usuario_id eliminadoPorUsuarioId,
       UB.nombre_usuario eliminadoPorNombre,
       CONVERT(VARCHAR(19),G.fecha_baja,126)+'Z' fechaBaja,G.motivo_baja motivoBaja,
       CONVERT(VARCHAR(10),G.fecha_muestreo,23) fechaMuestreo,
       CONVERT(VARCHAR(19),G.fecha_registro,126)+'Z' fechaRegistro,G.usuario_id usuarioId,
       U.nombre_usuario usuarioNombre
     FROM prod.PredioMateriaSecaGlobalE4 G LEFT JOIN seg.Usuario U ON U.usuario_id=G.usuario_id
     LEFT JOIN seg.Usuario UM ON UM.usuario_id=G.modificado_por_usuario_id
     LEFT JOIN seg.Usuario UB ON UB.usuario_id=G.eliminado_por_usuario_id
     WHERE G.predio_id=@predio AND G.uot_id=@uot AND G.convenio_id=@conv
     ORDER BY G.fecha_muestreo DESC,G.informe_id DESC FOR JSON PATH)),JSON_QUERY(N'[]')) items
     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='SECA_PLANTA_LISTAR'
  BEGIN
   SELECT @total=COUNT(*) FROM prod.PlantaPaltaE3 P WHERE P.predio_id=@predio AND P.uot_id=@uot
    AND P.convenio_id=@conv AND P.activo=1 AND P.estado_actual NOT IN('MUERTA','ELIMINADA');
   SET @cDatos=(SELECT
    JSON_QUERY((SELECT X.clave,X.origen,X.porcentaje,X.informe,X.fechaMuestreo,X.fechaRegistro,X.usuarioId,X.usuarioNombre
      FROM (SELECT CONCAT('IND-',I.medicion_id) clave,'INDIVIDUAL' origen,I.porcentaje,I.informe,
          CONVERT(VARCHAR(10),I.fecha_muestreo,23) fechaMuestreo,
          CONVERT(VARCHAR(19),I.fecha_registro,126)+'Z' fechaRegistro,I.usuario_id usuarioId,
          U.nombre_usuario usuarioNombre
          FROM prod.PlantaMateriaSecaIndividualE4 I LEFT JOIN seg.Usuario U ON U.usuario_id=I.usuario_id
          WHERE I.planta_id=@planta
        UNION ALL
        SELECT CONCAT('VIS-',V.medicion_id),'VISITA',V.porcentaje,V.observacion,
          CONVERT(VARCHAR(10),V.fecha_hecho,23),
          CONVERT(VARCHAR(19),V.fecha_registro,126)+'Z',V.usuario_id,U.nombre_usuario
          FROM prod.PlantaMedicionE3 V LEFT JOIN seg.Usuario U ON U.usuario_id=V.usuario_id
          WHERE V.planta_id=@planta) X
      ORDER BY X.fechaMuestreo DESC,X.fechaRegistro DESC FOR JSON PATH)) items,
    JSON_QUERY((SELECT TOP(1) G.informe_id informeId,G.porcentaje,G.cobertura,
      G.cantidad_plantas cantidadPlantas,G.total_plantas_activas totalPlantasAlRegistro,
      CONVERT(VARCHAR(10),G.fecha_muestreo,23) fechaMuestreo,
      G.informe,U.nombre_usuario usuarioNombre
      FROM prod.PredioMateriaSecaGlobalE4 G LEFT JOIN seg.Usuario U ON U.usuario_id=G.usuario_id
      WHERE G.predio_id=@predio AND G.uot_id=@uot AND G.convenio_id=@conv
        AND G.estado=1 AND G.cobertura='TOTAL' AND G.total_plantas_activas=@total AND @total>0
      ORDER BY G.fecha_muestreo DESC,G.informe_id DESC FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) globalVigente
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE
  BEGIN
   IF @clave IS NULL THROW 51318,N'No se recibió la clave de idempotencia.',1;
   SET @hash=HASHBYTES('SHA2_256',CONCAT(@cAccion,N'|',JSON_QUERY(@cJson,'$.filtros'),
                                             N'|',JSON_QUERY(@cJson,'$.datos')));
   BEGIN TRANSACTION;
   SELECT @anterior=hash_peticion,@previo=respuesta
   FROM prod.PlantaSolicitudE3 WITH(UPDLOCK,HOLDLOCK)
   WHERE usuario_id=@usuario AND accion=@cAccion AND clave=@clave;
   IF @anterior IS NOT NULL
   BEGIN
    IF @anterior<>@hash THROW 51319,N'La clave ya fue utilizada con información diferente.',1;
    SELECT @cDatos=@previo,@bResultado=1,@cMensaje=N'Operación ya registrada.',
       @cCodigoRespuesta='E4_OK',@nHttpRespuesta=200;
    COMMIT TRANSACTION;
    RETURN;
   END;
   IF @cAccion='NOTA_REGISTRAR'
   BEGIN
    SELECT @estado=CASE WHEN E.activo=1 AND E.fin IS NULL AND P.estado_actual NOT IN('MUERTA','ELIMINADA')
       THEN 'VIGENTE' ELSE 'CERRADA' END
    FROM sanidad.EpisodioPlantaE3 E WITH(UPDLOCK,HOLDLOCK)
    JOIN prod.PlantaPaltaE3 P ON P.planta_id=E.planta_id WHERE E.episodio_id=@episodio;
    IF @estado<>'VIGENTE' THROW 51320,N'Solo se pueden comentar enfermedades vigentes.',1;
    SET @texto=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.comentario'))),N'');
    IF @texto IS NULL OR LEN(@texto)>1500 THROW 51321,N'Ingrese un comentario de hasta 1500 caracteres.',1;
    INSERT INTO sanidad.EpisodioNotaE4(episodio_id,comentario,usuario_id)
      VALUES(@episodio,@texto,@usuario);
    SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
    SET @cDatos=(SELECT @id notaId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   END
   ELSE IF @cAccion='TRATAMIENTOS_LOTE'
   BEGIN
    SELECT @inicio=E.inicio,@gp=E.gp_problema_id,
      @estado=CASE WHEN E.activo=1 AND E.fin IS NULL AND P.estado_actual NOT IN('MUERTA','ELIMINADA')
       THEN 'VIGENTE' ELSE 'CERRADA' END
    FROM sanidad.EpisodioPlantaE3 E WITH(UPDLOCK,HOLDLOCK)
    JOIN prod.PlantaPaltaE3 P ON P.planta_id=E.planta_id WHERE E.episodio_id=@episodio;
    IF @estado<>'VIGENTE' THROW 51322,N'La enfermedad ya no admite tratamientos.',1;
    DECLARE @aplica DATE=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaAplicacion'));
    IF @aplica IS NULL OR @aplica>CONVERT(DATE,@ahora) OR @aplica<CONVERT(DATE,@inicio)
      THROW 51323,N'La fecha de aplicación no es válida para esta enfermedad.',1;
    SET @comentario=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.comentario'))),N'');
    SET @resultado=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.resultado'))),N'');
    IF LEN(ISNULL(JSON_VALUE(@cJson,'$.datos.comentario'),N''))>1000
      OR LEN(ISNULL(JSON_VALUE(@cJson,'$.datos.resultado'),N''))>600
      THROW 51324,N'La descripción supera el tamaño permitido.',1;
    IF ISJSON(JSON_QUERY(@cJson,'$.datos.tratamientoIds'))<>1
      THROW 51325,N'Seleccione tratamientos del catálogo.',1;
    DECLARE @ids TABLE(tratamientoId INT NOT NULL PRIMARY KEY);
    INSERT INTO @ids(tratamientoId)
      SELECT DISTINCT TRY_CONVERT(INT,J.value) FROM OPENJSON(@cJson,'$.datos.tratamientoIds') J
      WHERE TRY_CONVERT(INT,J.value)>0;
    DECLARE @nTotal INT=(SELECT COUNT(*) FROM OPENJSON(@cJson,'$.datos.tratamientoIds'));
    IF @nTotal NOT BETWEEN 1 AND 20 OR @nTotal<>(SELECT COUNT(*) FROM @ids)
      THROW 51326,N'Seleccione entre uno y veinte tratamientos sin duplicados.',1;
    IF EXISTS(SELECT 1 FROM @ids I WHERE NOT EXISTS(
       SELECT 1 FROM prod.GPProblemaTratamiento R
       JOIN prod.GPTratamiento T ON T.tratamiento_id=R.tratamiento_id AND T.estado=1
       JOIN prod.GPProblema GP ON GP.problema_id=R.problema_id AND GP.estado=1
       WHERE R.problema_id=@gp AND R.tratamiento_id=I.tratamientoId))
      THROW 51327,N'Un tratamiento no corresponde a la enfermedad seleccionada.',1;
    INSERT INTO sanidad.TratamientoAplicacionE4(episodio_id,fecha_aplicacion,comentario,resultado,usuario_id)
      VALUES(@episodio,@aplica,@comentario,@resultado,@usuario);
    SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
    INSERT INTO sanidad.TratamientoPlantaE3(episodio_id,gp_tratamiento_id,descripcion,resultado,
         comentario,fecha_aplicacion,usuario_id,aplicacion_id)
      SELECT @episodio,T.tratamiento_id,T.nombre,@resultado,@comentario,
      CASE WHEN @aplica=CONVERT(DATE,@inicio) THEN @inicio ELSE CONVERT(DATETIME2(0),@aplica) END,
      @usuario,@id
      FROM @ids I JOIN prod.GPTratamiento T ON T.tratamiento_id=I.tratamientoId;
    INSERT INTO prod.PlantaEventoE3(planta_id,tipo,observacion,usuario_id,fecha_hecho,correlacion_id)
      VALUES(@planta,'TRATAMIENTO',LEFT(CONCAT(N'Aplicación de ',@nTotal,N' tratamiento(s): ',COALESCE(@comentario,N'Sin observación')),1000),
       @usuario,CASE WHEN @aplica=CONVERT(DATE,@inicio) THEN @inicio ELSE CONVERT(DATETIME2(0),@aplica) END,@corr);
    SET @cDatos=(SELECT @id aplicacionId,@nTotal tratamientosRegistrados
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   END
   ELSE IF @cAccion='SECA_INDIVIDUAL'
   BEGIN
    THROW 51331,N'La materia seca ahora se registra exclusivamente por fundo.',1;
    SELECT @estado=P.estado_actual FROM prod.PlantaPaltaE3 P WITH(UPDLOCK,HOLDLOCK)
      WHERE P.planta_id=@planta;
    IF @estado IN('MUERTA','ELIMINADA') THROW 51328,N'La planta no admite nuevas mediciones.',1;
    SET @fecha=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaMuestreo'));
    SET @porcentaje=TRY_CONVERT(DECIMAL(6,3),JSON_VALUE(@cJson,'$.datos.porcentaje'));
    SET @texto=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.informe'))),N'');
    IF @fecha IS NULL OR @fecha>CONVERT(DATE,@ahora) OR @porcentaje IS NULL OR @porcentaje<=0 OR @porcentaje>100
      OR LEN(ISNULL(JSON_VALUE(@cJson,'$.datos.informe'),N''))>2000
      THROW 51329,N'La fecha, el porcentaje o el informe no son válidos.',1;
    INSERT INTO prod.PlantaMateriaSecaIndividualE4(planta_id,fecha_muestreo,porcentaje,informe,usuario_id)
     VALUES(@planta,@fecha,@porcentaje,@texto,@usuario);
    SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
    SET @cDatos=(SELECT @id medicionId,@planta plantaId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   END
   ELSE IF @cAccion='SECA_GLOBAL'
   BEGIN
    SET @fecha=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaMuestreo'));
    SET @porcentaje=TRY_CONVERT(DECIMAL(6,3),JSON_VALUE(@cJson,'$.datos.porcentaje'));
    SET @cantidad=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.cantidadPlantas'));
    SET @frutos=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.cantidadFrutos'));
    SET @metodo=JSON_VALUE(@cJson,'$.datos.metodo');
    SET @texto=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.informe'))),N'');
    SELECT @total=COUNT(*) FROM prod.PlantaPaltaE3 P WITH(UPDLOCK,HOLDLOCK)
      WHERE P.predio_id=@predio AND P.uot_id=@uot AND P.convenio_id=@conv AND P.activo=1
        AND P.estado_actual NOT IN('MUERTA','ELIMINADA');
    IF @fecha IS NULL OR @fecha>CONVERT(DATE,@ahora) OR @porcentaje IS NULL OR @porcentaje<=0
      OR @porcentaje>100 OR @cantidad IS NULL OR @cantidad<1 OR @cantidad>@total
      OR @texto IS NULL OR LEN(ISNULL(JSON_VALUE(@cJson,'$.datos.informe'),N''))>2000
      OR @frutos IS NULL OR @frutos<@cantidad OR @frutos>10000
      OR @metodo NOT IN ('LABORATORIO','HORNO','MICROONDAS','NIR','OTRO') OR @metodo IS NULL
      THROW 51330,N'Ingrese muestra, cantidad de frutos, método e informe válidos.',1;
    IF EXISTS(SELECT 1 FROM prod.PredioMateriaSecaGlobalE4 G WITH(UPDLOCK,HOLDLOCK)
       WHERE G.predio_id=@predio AND G.uot_id=@uot AND G.convenio_id=@conv AND G.estado=1
         AND ABS(DATEDIFF(DAY,G.fecha_muestreo,@fecha))<7)
      THROW 51332,N'Ya existe un muestreo activo a menos de 7 días de esta fecha.',1;
    INSERT INTO prod.PredioMateriaSecaGlobalE4(predio_id,uot_id,convenio_id,fecha_muestreo,
         porcentaje,cantidad_plantas,total_plantas_activas,cobertura,informe,usuario_id,cantidad_frutos,metodo)
      VALUES(@predio,@uot,@conv,@fecha,@porcentaje,@cantidad,@total,
         CASE WHEN @cantidad=@total THEN 'TOTAL' ELSE 'PARCIAL' END,@texto,@usuario,@frutos,@metodo);
    SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
    SET @despues=(SELECT G.informe_id informeId,G.porcentaje,G.fecha_muestreo fechaMuestreo,
       G.cantidad_plantas cantidadPlantas,G.total_plantas_activas totalPlantasAlRegistro,
       G.cantidad_frutos cantidadFrutos,G.metodo,G.cobertura,G.informe,G.estado,G.version
       FROM prod.PredioMateriaSecaGlobalE4 G WHERE G.informe_id=@id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    INSERT INTO prod.PredioMateriaSecaCambioE4(informe_id,accion,usuario_id,correlacion_id,valor_nuevo)
      VALUES(@id,'CREAR',@usuario,@corr,@despues);
    SET @cDatos=(SELECT @id informeId,CONVERT(BIGINT,0) version FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   END
   ELSE IF @cAccion='SECA_GLOBAL_EDITAR'
   BEGIN
    SET @id=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.informeId'));
    SET @version=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.version'));
    IF @id IS NULL OR @id<1 OR @version IS NULL OR @version<0
      THROW 51333,N'Indique el informe y su versión vigente.',1;
    SELECT @versionActual=G.version,@fechaAnterior=G.fecha_muestreo,
       @antes=(SELECT X.informe_id informeId,X.porcentaje,X.fecha_muestreo fechaMuestreo,
        X.cantidad_plantas cantidadPlantas,X.total_plantas_activas totalPlantasAlRegistro,
        X.cantidad_frutos cantidadFrutos,X.metodo,X.cobertura,X.informe,X.estado,X.version
        FROM prod.PredioMateriaSecaGlobalE4 X WHERE X.informe_id=G.informe_id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)
    FROM prod.PredioMateriaSecaGlobalE4 G WITH(UPDLOCK,HOLDLOCK)
    WHERE G.informe_id=@id AND G.predio_id=@predio AND G.uot_id=@uot
       AND G.convenio_id=@conv AND G.estado=1;
    IF @versionActual IS NULL THROW 51334,N'El informe no existe o fue inactivado.',1;
    IF @versionActual<>@version THROW 51335,N'El informe fue actualizado por otra persona. Actualice el historial.',1;
    SET @fecha=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaMuestreo'));
    SET @porcentaje=TRY_CONVERT(DECIMAL(6,3),JSON_VALUE(@cJson,'$.datos.porcentaje'));
    SET @cantidad=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.cantidadPlantas'));
    SET @frutos=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.cantidadFrutos'));
    SET @metodo=JSON_VALUE(@cJson,'$.datos.metodo');
    SET @texto=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.informe'))),N'');
    SET @motivo=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.motivoEdicion'))),N'');
    SELECT @total=COUNT(*) FROM prod.PlantaPaltaE3 P WITH(UPDLOCK,HOLDLOCK)
      WHERE P.predio_id=@predio AND P.uot_id=@uot AND P.convenio_id=@conv AND P.activo=1
        AND P.estado_actual NOT IN('MUERTA','ELIMINADA');
    IF @fecha IS NULL OR @fecha>CONVERT(DATE,@ahora) OR @porcentaje IS NULL OR @porcentaje<=0
      OR @porcentaje>100 OR @cantidad IS NULL OR @cantidad<1 OR @cantidad>@total
      OR @frutos IS NULL OR @frutos<@cantidad OR @frutos>10000
      OR @metodo NOT IN('LABORATORIO','HORNO','MICROONDAS','NIR','OTRO') OR @metodo IS NULL
      OR @texto IS NULL OR LEN(ISNULL(JSON_VALUE(@cJson,'$.datos.informe'),N''))>2000
      OR @motivo IS NULL OR LEN(@motivo)<10 OR LEN(@motivo)>500
      THROW 51336,N'Los datos o el motivo de edición no son válidos.',1;
    IF @fecha<>@fechaAnterior AND EXISTS(SELECT 1 FROM prod.PredioMateriaSecaGlobalE4 G WITH(UPDLOCK,HOLDLOCK)
       WHERE G.predio_id=@predio AND G.uot_id=@uot AND G.convenio_id=@conv
         AND G.informe_id<>@id AND G.estado=1 AND ABS(DATEDIFF(DAY,G.fecha_muestreo,@fecha))<7)
      THROW 51337,N'Existe otro muestreo activo a menos de 7 días de la nueva fecha.',1;
    UPDATE prod.PredioMateriaSecaGlobalE4
    SET porcentaje=@porcentaje,fecha_muestreo=@fecha,cantidad_plantas=@cantidad,
      total_plantas_activas=@total,cobertura=CASE WHEN @cantidad=@total THEN 'TOTAL' ELSE 'PARCIAL' END,
      cantidad_frutos=@frutos,metodo=@metodo,informe=@texto,
      version=version+1,modificado_por_usuario_id=@usuario,fecha_modificacion=@ahora
    WHERE informe_id=@id AND estado=1 AND version=@version;
    SET @despues=(SELECT G.informe_id informeId,G.porcentaje,G.fecha_muestreo fechaMuestreo,
       G.cantidad_plantas cantidadPlantas,G.total_plantas_activas totalPlantasAlRegistro,
       G.cantidad_frutos cantidadFrutos,G.metodo,G.cobertura,G.informe,G.estado,G.version
       FROM prod.PredioMateriaSecaGlobalE4 G WHERE G.informe_id=@id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    INSERT INTO prod.PredioMateriaSecaCambioE4(informe_id,accion,usuario_id,correlacion_id,valor_anterior,valor_nuevo,motivo)
      VALUES(@id,'EDITAR',@usuario,@corr,@antes,@despues,@motivo);
    SET @cDatos=(SELECT @id informeId,(@version+1) version FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   END
   ELSE IF @cAccion='SECA_GLOBAL_ELIMINAR'
   BEGIN
    SET @id=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.informeId'));
    SET @version=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.version'));
    SET @motivo=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.motivo'))),N'');
    IF @id IS NULL OR @id<1 OR @version IS NULL OR @version<0
       OR @motivo IS NULL OR LEN(@motivo)<10 OR LEN(@motivo)>500
      THROW 51338,N'Indique informe, versión y motivo de baja (mínimo 10 caracteres).',1;
    SELECT @versionActual=G.version,
       @antes=(SELECT X.informe_id informeId,X.estado,X.version,X.informe
        FROM prod.PredioMateriaSecaGlobalE4 X WHERE X.informe_id=G.informe_id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)
    FROM prod.PredioMateriaSecaGlobalE4 G WITH(UPDLOCK,HOLDLOCK)
    WHERE G.informe_id=@id AND G.predio_id=@predio AND G.uot_id=@uot AND G.convenio_id=@conv AND G.estado=1;
    IF @versionActual IS NULL THROW 51339,N'El informe no existe o ya está inactivo.',1;
    IF @versionActual<>@version THROW 51340,N'El informe fue actualizado por otra persona. Actualice el historial.',1;
    UPDATE prod.PredioMateriaSecaGlobalE4
       SET estado=0,version=version+1,fecha_baja=@ahora,
         eliminado_por_usuario_id=@usuario,motivo_baja=@motivo
       WHERE informe_id=@id AND estado=1 AND version=@version;
    SET @despues=(SELECT G.informe_id informeId,G.estado,G.version,G.motivo_baja motivoBaja
      FROM prod.PredioMateriaSecaGlobalE4 G WHERE G.informe_id=@id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    INSERT INTO prod.PredioMateriaSecaCambioE4(informe_id,accion,usuario_id,correlacion_id,valor_anterior,valor_nuevo,motivo)
      VALUES(@id,'INACTIVAR',@usuario,@corr,@antes,@despues,@motivo);
    SET @cDatos=(SELECT @id informeId,(@version+1) version FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   END;
   INSERT INTO prod.PlantaSolicitudE3(usuario_id,accion,clave,hash_peticion,respuesta)
     VALUES(@usuario,@cAccion,@clave,@hash,COALESCE(@cDatos,N'{}'));
   COMMIT TRANSACTION;
  END;
  SELECT @bResultado=1,@cCodigoRespuesta='E4_OK',@cMensaje=N'Operación completada.',@nHttpRespuesta=200;
 END TRY
 BEGIN CATCH
  DECLARE @e4ErrorNumero INT=ERROR_NUMBER(), @e4ErrorLinea INT=ERROR_LINE();
  DECLARE @e4ErrorProcedimiento NVARCHAR(257)=COALESCE(ERROR_PROCEDURE(),N'prod.PA_E3_ExpedienteE4_Ejecutar');
  IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
  IF @e4ErrorNumero NOT BETWEEN 51310 AND 51399
  BEGIN
   BEGIN TRY
    INSERT INTO auditoria.ErrorBaseDatos(fecha_utc,numero_error,procedimiento,linea,codigo,correlacion_id)
    VALUES(SYSUTCDATETIME(),@e4ErrorNumero,@e4ErrorProcedimiento,@e4ErrorLinea,'E4_SQL',@corr);
   END TRY
   BEGIN CATCH
    -- No ocultar el error original si la bitacora no esta disponible.
    DECLARE @e4RegistroErrorIgnorado INT=ERROR_NUMBER();
   END CATCH;
  END;
  SELECT @bResultado=0,@cDatos=NULL,
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() IN(51313,51314,51315) THEN 403
                       WHEN ERROR_NUMBER() BETWEEN 51310 AND 51399 THEN 400 ELSE 503 END,
   @cCodigoRespuesta='E4_ERROR',
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51310 AND 51399
            THEN ERROR_MESSAGE() ELSE N'No fue posible completar la operación.' END;
 END CATCH;
END;
GO
