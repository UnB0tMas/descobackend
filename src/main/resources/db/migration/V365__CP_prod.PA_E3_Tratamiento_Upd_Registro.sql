IF OBJECT_ID(N'[prod].[PA_E3_Tratamiento_Upd_Registro]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_E3_Tratamiento_Upd_Registro];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_E3_Tratamiento_Upd_Registro
' Descripción            : Actualiza la información de e3 tratamiento.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_E3_Tratamiento_Upd_Registro
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo actualizar el tratamiento.',
   @cCodigoRespuesta='E3_ERROR',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@planta BIGINT,@episodio BIGINT,@now DATETIME2(0)=SYSUTCDATETIME();
 BEGIN TRY
  EXEC prod.PA_E3_Sel_ValidarContexto @cJson,'APAPPSS_PREDIOS_EDITAR',
   @usuario OUTPUT,@planta OUTPUT,@episodio OUTPUT;
  IF seg.FN_Usuario_TienePermisoUOT(@usuario,TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
     'APAPPSS_PLANTAS_TRATAMIENTO_LOTE')<>1
    THROW 51211,N'No tiene permiso para editar tratamientos.',1;
  DECLARE @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
   @hash VARBINARY(32),@hashPrev VARBINARY(32),@respuestaPrev NVARCHAR(MAX),
   @id BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.tratamientoId')),
   @catalogo INT=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.catalogoTratamientoId')),
   @fecha DATE=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaAplicacion')),
   @comentario NVARCHAR(1000)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.comentario')),N''),
   @resultado NVARCHAR(600)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.resultado')),N''),
   @inicio DATETIME2(0),@gp INT,@anterior NVARCHAR(MAX),@nuevo NVARCHAR(MAX),@nombre NVARCHAR(250);
  IF @episodio IS NULL OR @id IS NULL OR @id<=0 OR @catalogo IS NULL OR @catalogo<=0
    OR @fecha IS NULL OR @clave IS NULL
    THROW 51244,N'Complete los datos obligatorios del tratamiento.',1;
  IF LEN(ISNULL(JSON_VALUE(@cJson,'$.datos.comentario'),N''))>1000
    OR LEN(ISNULL(JSON_VALUE(@cJson,'$.datos.resultado'),N''))>600
    THROW 51245,N'La observación o el resultado es demasiado extenso.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'PA_E3_Tratamiento_Upd_Registro|',
   JSON_QUERY(@cJson,'$.filtros'),N'|',JSON_QUERY(@cJson,'$.datos')));
  BEGIN TRANSACTION;
  SELECT @hashPrev=hash_peticion,@respuestaPrev=respuesta
  FROM prod.PlantaSolicitudE3 WITH(UPDLOCK,HOLDLOCK)
  WHERE usuario_id=@usuario AND accion='E3_Tratamiento_Upd_Registro' AND clave=@clave;
  IF @hashPrev IS NOT NULL
  BEGIN
   IF @hashPrev<>@hash THROW 51217,N'Esta solicitud ya se utilizó con otros datos.',1;
   SELECT @cDatos=@respuestaPrev,@bResultado=1,@cMensaje=N'Tratamiento actualizado.',
    @cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
   COMMIT TRANSACTION;RETURN;
  END;
  IF NOT EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 WITH(UPDLOCK,HOLDLOCK)
    WHERE planta_id=@planta AND estado_actual='ENFERMA')
    THROW 51246,N'La planta ya no admite cambios de tratamiento.',1;
  SELECT @inicio=E.inicio,@gp=E.gp_problema_id
  FROM sanidad.EpisodioPlantaE3 E WITH(UPDLOCK,HOLDLOCK)
  WHERE E.episodio_id=@episodio AND E.planta_id=@planta AND E.activo=1 AND E.fin IS NULL;
  IF @inicio IS NULL THROW 51247,N'La enfermedad ya no admite cambios.',1;
  IF @fecha<CONVERT(DATE,DATEADD(HOUR,-5,@inicio)) OR @fecha>CONVERT(DATE,DATEADD(HOUR,-5,@now))
    THROW 51248,N'La fecha debe estar entre el diagnóstico y hoy.',1;
  IF NOT EXISTS(SELECT 1 FROM sanidad.TratamientoPlantaE3 WITH(UPDLOCK,HOLDLOCK)
    WHERE tratamiento_id=@id AND episodio_id=@episodio)
    THROW 51249,N'El tratamiento no corresponde a esta enfermedad.',1;
  SELECT @nombre=T.nombre FROM prod.GPTratamiento T
  JOIN prod.GPProblemaTratamiento P ON P.tratamiento_id=T.tratamiento_id
  WHERE T.tratamiento_id=@catalogo AND T.estado=1 AND P.problema_id=@gp;
  IF @nombre IS NULL THROW 51243,N'El tratamiento no corresponde al diagnóstico.',1;
  SELECT @anterior=(SELECT T.gp_tratamiento_id catalogoTratamientoId,T.fecha_aplicacion fechaAplicacion,
    T.comentario,T.resultado FROM sanidad.TratamientoPlantaE3 T
    WHERE T.tratamiento_id=@id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  UPDATE sanidad.TratamientoPlantaE3 SET gp_tratamiento_id=@catalogo,descripcion=@nombre,
   fecha_aplicacion=CASE WHEN @fecha=CONVERT(DATE,DATEADD(HOUR,-5,@inicio)) THEN @inicio ELSE DATEADD(HOUR,5,CONVERT(DATETIME2(0),@fecha)) END,
   resultado=@resultado,comentario=@comentario,modificado_por_usuario_id=@usuario,modificado_en=@now
  WHERE tratamiento_id=@id AND episodio_id=@episodio;
  IF @@ROWCOUNT<>1 THROW 51249,N'El tratamiento no está disponible.',1;
  SET @nuevo=(SELECT @catalogo catalogoTratamientoId,@fecha fechaAplicacion,
   @comentario comentario,@resultado resultado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
  INSERT INTO sanidad.TratamientoEdicionE3(tratamiento_id,anterior,nuevo,usuario_id,fecha_hora)
   VALUES(@id,@anterior,@nuevo,@usuario,@now);
  INSERT INTO prod.PlantaEventoE3(planta_id,tipo,observacion,usuario_id,fecha_hecho)
   VALUES(@planta,'TRATAMIENTO',N'Tratamiento actualizado.',@usuario,@now);
  SET @cDatos=(SELECT @id tratamientoId,@episodio episodioId,@usuario modificadoPorUsuarioId,
   CONVERT(VARCHAR(19),@now,126)+'Z' modificadoEn FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT INTO prod.PlantaSolicitudE3(usuario_id,accion,clave,hash_peticion,respuesta)
   VALUES(@usuario,'E3_Tratamiento_Upd_Registro',@clave,@hash,COALESCE(@cDatos,N'{}'));
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cMensaje=N'Tratamiento actualizado.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN ERROR_MESSAGE()
    ELSE N'No se pudo actualizar el tratamiento.' END,
   @cCodigoRespuesta='E3_ERROR',
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN 400 ELSE 503 END;
 END CATCH;
END;
GO
