IF OBJECT_ID(N'[prod].[PA_E3_Enfermedad_Upd_Recuperar]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_E3_Enfermedad_Upd_Recuperar];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_E3_Enfermedad_Upd_Recuperar
' Descripción            : Actualiza e3 enfermedad para recuperar.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_E3_Enfermedad_Upd_Recuperar
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No fue posible completar la operación.',@cCodigoRespuesta='E3_ERROR',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@planta BIGINT,@episodio BIGINT,@now DATETIME2(0)=SYSUTCDATETIME();
 BEGIN TRY
 EXEC prod.PA_E3_Sel_ValidarContexto @cJson,'APAPPSS_PREDIOS_EDITAR',@usuario OUTPUT,@planta OUTPUT,@episodio OUTPUT;
 IF @episodio IS NULL THROW 51215,N'Seleccione una enfermedad válida.',1;
 DECLARE @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
   @hash VARBINARY(32),@anterior VARBINARY(32),@previo NVARCHAR(MAX);
 IF @clave IS NULL THROW 51216,N'Falta la clave de la operación.',1;
 SET @hash=HASHBYTES('SHA2_256',CONCAT('PA_E3_Enfermedad_Upd_Recuperar',N'|',JSON_QUERY(@cJson,'$.filtros'),N'|',JSON_QUERY(@cJson,'$.datos')));
 BEGIN TRANSACTION;
 SELECT @anterior=hash_peticion,@previo=respuesta FROM prod.PlantaSolicitudE3 WITH(UPDLOCK,HOLDLOCK)
 WHERE usuario_id=@usuario AND accion='E3_Enfermedad_Upd_Recuperar' AND clave=@clave;
 IF @anterior IS NOT NULL
 BEGIN
  IF @anterior<>@hash THROW 51217,N'La operación ya fue utilizada con otros datos.',1;
  SELECT @cDatos=@previo,@bResultado=1,@cMensaje=N'Operación previamente registrada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
  COMMIT TRANSACTION;RETURN;
 END;

 DECLARE @fin DATETIME2(0)=COALESCE(TRY_CONVERT(DATETIME2(0),JSON_VALUE(@cJson,'$.datos.fechaCuracion')),@now),
  @motivo NVARCHAR(600)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.comentario'))),N''),
  @inicio DATETIME2(0),@prev VARCHAR(16),@nuevo VARCHAR(16),
  @resultado VARCHAR(20)=COALESCE(JSON_VALUE(@cJson,'$.datos.resultado'),'CONTROLADA');
 IF @resultado NOT IN('CONTROLADA','NO_CONTROLADA') THROW 51233,N'Resultado de cierre no válido.',1;
 SELECT @prev=estado_actual FROM prod.PlantaPaltaE3 WITH(UPDLOCK,HOLDLOCK) WHERE planta_id=@planta;
 IF @prev IN('MUERTA','ELIMINADA') THROW 51231,N'La planta inactiva no admite cambios sanitarios.',1;
 SELECT @inicio=inicio FROM sanidad.EpisodioPlantaE3 WITH(UPDLOCK,HOLDLOCK)
  WHERE episodio_id=@episodio AND activo=1 AND fin IS NULL;
 IF @inicio IS NULL THROW 51232,N'La enfermedad ya no está vigente.',1;
 IF @resultado='NO_CONTROLADA'
 BEGIN
  IF @prev<>'ENFERMA' OR @motivo IS NULL OR LEN(@motivo)<5
   THROW 51233,N'Indique el motivo de la muerte (mínimo 5 caracteres) de una planta enferma.',1;
  -- Fecha efectiva del servidor después de adquirir el bloqueo de la planta.
  SET @now=SYSUTCDATETIME();
  IF EXISTS(SELECT 1 FROM sanidad.EpisodioPlantaE3 E WITH(UPDLOCK,HOLDLOCK)
    WHERE E.planta_id=@planta AND E.activo=1 AND E.fin IS NULL AND
    (E.inicio>@now OR EXISTS(SELECT 1 FROM sanidad.TratamientoPlantaE3 T
      WHERE T.episodio_id=E.episodio_id AND T.fecha_aplicacion>@now)))
   THROW 51233,N'La fecha de muerte no puede anteceder al diagnóstico o tratamiento.',1;
  UPDATE sanidad.EpisodioPlantaE3 SET fin=@now,usuario_cierre_id=@usuario,cierre_por_muerte=1,
   motivo_cierre=CASE WHEN episodio_id=@episodio THEN @motivo ELSE LEFT(CONCAT(N'Cierre por muerte de la planta. Episodio de referencia #',@episodio,N'. ',@motivo),600) END
   WHERE planta_id=@planta AND activo=1 AND fin IS NULL;
  SET @nuevo='MUERTA';
  UPDATE prod.PlantaPaltaE3 SET estado_actual=@nuevo,activo=0,version=version+1 WHERE planta_id=@planta;
  INSERT INTO prod.PlantaEventoE3(planta_id,tipo,estado_anterior,estado_nuevo,observacion,usuario_id,fecha_hecho)
   VALUES(@planta,'ENFERMEDAD',@prev,@nuevo,LEFT(CONCAT(N'Enfermedad no controlada #',@episodio,N'. ',@motivo),1000),@usuario,@now);
 END
 ELSE
 BEGIN
 IF NOT EXISTS(SELECT 1 FROM sanidad.TratamientoPlantaE3 T WHERE T.episodio_id=@episodio)
  THROW 51234,N'Registre al menos un tratamiento antes de controlar la enfermedad.',1;
 IF @fin<@inicio OR @fin>@now THROW 51233,N'La fecha de recuperación no es válida.',1;
 IF EXISTS(SELECT 1 FROM sanidad.TratamientoPlantaE3 WHERE episodio_id=@episodio AND fecha_aplicacion>@fin)
  THROW 51233,N'La fecha de control no puede ser anterior al último tratamiento.',1;
 UPDATE sanidad.EpisodioPlantaE3 SET fin=@fin,usuario_cierre_id=@usuario,motivo_cierre=@motivo WHERE episodio_id=@episodio;
 SET @nuevo=CASE WHEN EXISTS(SELECT 1 FROM sanidad.EpisodioPlantaE3
  WHERE planta_id=@planta AND fin IS NULL AND activo=1) THEN 'ENFERMA' ELSE 'SANA' END;
 UPDATE prod.PlantaPaltaE3 SET estado_actual=@nuevo,version=version+1 WHERE planta_id=@planta;
 INSERT INTO prod.PlantaEventoE3(planta_id,tipo,estado_anterior,estado_nuevo,observacion,usuario_id,fecha_hecho)
 VALUES(@planta,'ENFERMEDAD',@prev,@nuevo,COALESCE(@motivo,N'Recuperación registrada.'),@usuario,@now);
 END;
 SET @cDatos=(SELECT @episodio episodioId,@nuevo estado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);

 SELECT @bResultado=1,@cMensaje=N'Operación realizada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 INSERT INTO prod.PlantaSolicitudE3(usuario_id,accion,clave,hash_peticion,respuesta)
 VALUES(@usuario,'E3_Enfermedad_Upd_Recuperar',@clave,@hash,COALESCE(@cDatos,N'{}'));
 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
  SELECT @bResultado=0,@cDatos=NULL,@nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN 400 ELSE 503 END,
    @cCodigoRespuesta='E3_ERROR',
    @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN ERROR_MESSAGE() ELSE N'No se pudo completar la operación.' END;
 END CATCH;
END;
GO
