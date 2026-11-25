IF OBJECT_ID(N'[sanidad].[PA_E3_TratamientoArchivo_Ins_Vinculo]') IS NOT NULL
    DROP PROCEDURE [sanidad].[PA_E3_TratamientoArchivo_Ins_Vinculo];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : sanidad.PA_E3_TratamientoArchivo_Ins_Vinculo
' Descripción            : Registra e3 tratamiento archivo para vinculo.
' Aplicativo / Módulo    : DESCO / sanidad
*******************************************************************************************************/
CREATE   PROCEDURE sanidad.PA_E3_TratamientoArchivo_Ins_Vinculo
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo vincular el archivo.',
   @cCodigoRespuesta='E3_ERROR',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@planta BIGINT,@episodio BIGINT;
 BEGIN TRY
  EXEC prod.PA_E3_Sel_ValidarContexto @cJson,'APAPPSS_PREDIOS_EDITAR',
   @usuario OUTPUT,@planta OUTPUT,@episodio OUTPUT;
  DECLARE @archivo BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.archivoId')),
   @aplicacion BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.aplicacionId')),
   @predio BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.predioId')),
   @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
   @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
   @hash VARBINARY(32),@antes VARBINARY(32),@previo NVARCHAR(MAX),@id BIGINT;
  IF @episodio IS NULL OR @archivo IS NULL OR @aplicacion IS NULL OR @clave IS NULL
   THROW 51241,N'Datos de tratamiento o archivo no válidos.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'PA_E3_TratamientoArchivo_Ins_Vinculo|',
   JSON_QUERY(@cJson,'$.filtros'),N'|',JSON_QUERY(@cJson,'$.datos')));
  BEGIN TRANSACTION;
  SELECT @antes=hash_peticion,@previo=respuesta FROM prod.PlantaSolicitudE3 WITH(UPDLOCK,HOLDLOCK)
   WHERE usuario_id=@usuario AND accion='E3_TratArchivo_Ins_Vinculo' AND clave=@clave;
  IF @antes IS NOT NULL
  BEGIN
   IF @antes<>@hash THROW 51242,N'La clave ya fue utilizada con otros datos.',1;
   SELECT @cDatos=@previo,@bResultado=1,@cMensaje=N'Archivo previamente vinculado.',
    @cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
   COMMIT TRANSACTION;RETURN;
  END;
  IF NOT EXISTS(SELECT 1 FROM sanidad.TratamientoAplicacionE4 T
    JOIN sanidad.EpisodioPlantaE3 E ON E.episodio_id=T.episodio_id
    WHERE T.aplicacion_id=@aplicacion AND E.episodio_id=@episodio AND E.planta_id=@planta)
   THROW 51243,N'La aplicación no pertenece a esta enfermedad.',1;
  IF NOT EXISTS(SELECT 1 FROM archivo.Archivo A
    JOIN archivo.ArchivoVinculo V ON V.archivo_id=A.archivo_id AND V.predio_id=@predio AND V.estado=1
    WHERE A.archivo_id=@archivo AND A.estado=1 AND A.uot_id=@uot
      AND A.proveedor_almacenamiento='LOCAL' AND A.usuario_id=@usuario)
   THROW 51244,N'El archivo debe estar cargado en el servidor y vinculado al predio.',1;
  IF EXISTS(SELECT 1 FROM sanidad.TratamientoArchivoE4
   WHERE aplicacion_id=@aplicacion AND archivo_id=@archivo)
   THROW 51245,N'El archivo ya está vinculado a esta aplicación.',1;
  INSERT INTO sanidad.TratamientoArchivoE4(aplicacion_id,archivo_id,usuario_id)
   VALUES(@aplicacion,@archivo,@usuario);
  SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
  SET @cDatos=(SELECT @id tratamientoArchivoId,@archivo archivoId,@aplicacion aplicacionId
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT INTO prod.PlantaSolicitudE3(usuario_id,accion,clave,hash_peticion,respuesta)
   VALUES(@usuario,'E3_TratArchivo_Ins_Vinculo',@clave,@hash,@cDatos);
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cMensaje=N'Archivo vinculado al tratamiento.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN 400 ELSE 503 END,
   @cCodigoRespuesta='E3_ERROR',
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN ERROR_MESSAGE()
     ELSE N'No se pudo vincular el archivo.' END;
 END CATCH;
END;
GO
