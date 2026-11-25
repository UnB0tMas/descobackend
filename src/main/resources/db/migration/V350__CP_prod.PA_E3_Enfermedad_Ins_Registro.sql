IF OBJECT_ID(N'[prod].[PA_E3_Enfermedad_Ins_Registro]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_E3_Enfermedad_Ins_Registro];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_E3_Enfermedad_Ins_Registro
' Descripción            : Registra la información de e3 enfermedad.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_E3_Enfermedad_Ins_Registro
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No fue posible completar la operación.',@cCodigoRespuesta='E3_ERROR',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@planta BIGINT,@episodio BIGINT,@now DATETIME2(0)=SYSUTCDATETIME();
 BEGIN TRY
 EXEC prod.PA_E3_Sel_ValidarContexto @cJson,'APAPPSS_PREDIOS_EDITAR',@usuario OUTPUT,@planta OUTPUT,@episodio OUTPUT;
 DECLARE @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
   @hash VARBINARY(32),@anterior VARBINARY(32),@previo NVARCHAR(MAX);
 IF @clave IS NULL THROW 51216,N'Falta la clave de la operación.',1;
 SET @hash=HASHBYTES('SHA2_256',CONCAT('PA_E3_Enfermedad_Ins_Registro',N'|',JSON_QUERY(@cJson,'$.filtros'),N'|',JSON_QUERY(@cJson,'$.datos')));
 BEGIN TRANSACTION;
 SELECT @anterior=hash_peticion,@previo=respuesta FROM prod.PlantaSolicitudE3 WITH(UPDLOCK,HOLDLOCK)
 WHERE usuario_id=@usuario AND accion='E3_Enfermedad_Ins_Registro' AND clave=@clave;
 IF @anterior IS NOT NULL
 BEGIN
  IF @anterior<>@hash THROW 51217,N'La operación ya fue utilizada con otros datos.',1;
  SELECT @cDatos=@previo,@bResultado=1,@cMensaje=N'Operación previamente registrada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
  COMMIT TRANSACTION;RETURN;
 END;

 DECLARE @diagnostico INT=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.diagnosticoId')),
  @comentario NVARCHAR(1000)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.observacion'))),N''),
  @inicio DATETIME2(0)=COALESCE(TRY_CONVERT(DATETIME2(0),JSON_VALUE(@cJson,'$.datos.inicio')),@now),
  @estadoPrev VARCHAR(16),@id BIGINT;
 SELECT @estadoPrev=estado_actual FROM prod.PlantaPaltaE3 WITH(UPDLOCK,HOLDLOCK) WHERE planta_id=@planta;
 IF @estadoPrev IN('MUERTA','ELIMINADA') THROW 51225,N'No se puede registrar una enfermedad en una planta inactiva.',1;
 IF @inicio>@now OR @inicio<DATEADD(YEAR,-100,@now) THROW 51226,N'La fecha de diagnóstico no es válida.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPProblema GP JOIN prod.Cultivo C ON C.cultivo_id=GP.cultivo_id AND C.estado=1
   WHERE GP.problema_id=@diagnostico AND GP.estado=1 AND (UPPER(C.codigo)='PALTA' OR UPPER(C.nombre)=N'PALTA'))
  THROW 51227,N'Seleccione una enfermedad válida del catálogo.',1;
 IF EXISTS(SELECT 1 FROM sanidad.EpisodioPlantaE3 WITH(UPDLOCK,HOLDLOCK)
  WHERE planta_id=@planta AND gp_problema_id=@diagnostico AND fin IS NULL AND activo=1)
  THROW 51228,N'La enfermedad ya está vigente en esta planta.',1;
 INSERT INTO sanidad.EpisodioPlantaE3(planta_id,gp_problema_id,inicio,observacion,usuario_apertura_id)
 VALUES(@planta,@diagnostico,@inicio,@comentario,@usuario);
 SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
 UPDATE prod.PlantaPaltaE3 SET estado_actual='ENFERMA',version=version+1 WHERE planta_id=@planta;
 INSERT INTO prod.PlantaEventoE3(planta_id,tipo,estado_anterior,estado_nuevo,observacion,usuario_id,fecha_hecho)
 VALUES(@planta,'ENFERMEDAD',@estadoPrev,'ENFERMA',@comentario,@usuario,@now);
 SET @cDatos=(SELECT @id episodioId,@planta plantaId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);

 SELECT @bResultado=1,@cMensaje=N'Operación realizada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 INSERT INTO prod.PlantaSolicitudE3(usuario_id,accion,clave,hash_peticion,respuesta)
 VALUES(@usuario,'E3_Enfermedad_Ins_Registro',@clave,@hash,COALESCE(@cDatos,N'{}'));
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
