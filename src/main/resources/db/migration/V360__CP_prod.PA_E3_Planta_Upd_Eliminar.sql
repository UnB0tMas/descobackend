IF OBJECT_ID(N'[prod].[PA_E3_Planta_Upd_Eliminar]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_E3_Planta_Upd_Eliminar];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_E3_Planta_Upd_Eliminar
' Descripción            : Actualiza e3 planta para eliminar.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_E3_Planta_Upd_Eliminar
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
 SET @hash=HASHBYTES('SHA2_256',CONCAT('PA_E3_Planta_Upd_Eliminar',N'|',JSON_QUERY(@cJson,'$.filtros'),N'|',JSON_QUERY(@cJson,'$.datos')));
 BEGIN TRANSACTION;
 SELECT @anterior=hash_peticion,@previo=respuesta FROM prod.PlantaSolicitudE3 WITH(UPDLOCK,HOLDLOCK)
 WHERE usuario_id=@usuario AND accion='E3_Planta_Upd_Eliminar' AND clave=@clave;
 IF @anterior IS NOT NULL
 BEGIN
  IF @anterior<>@hash THROW 51217,N'La operación ya fue utilizada con otros datos.',1;
  SELECT @cDatos=@previo,@bResultado=1,@cMensaje=N'Operación previamente registrada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
  COMMIT TRANSACTION;RETURN;
 END;

 DECLARE @motivo NVARCHAR(1000)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.motivo'))),N''),@prev VARCHAR(16),@version BIGINT;
 IF @motivo IS NULL OR LEN(@motivo)<5 THROW 51220,N'Indique el motivo de eliminación (mínimo 5 caracteres).',1;
 SELECT @prev=estado_actual,@version=version FROM prod.PlantaPaltaE3 WITH(UPDLOCK,HOLDLOCK) WHERE planta_id=@planta;
 IF @prev='ELIMINADA' THROW 51221,N'La planta ya está eliminada.',1;
 IF @version<>TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.version')) THROW 51222,N'La planta cambió. Actualice antes de eliminar.',1;
 UPDATE prod.PlantaPaltaE3 SET estado_actual='ELIMINADA',activo=0,version=version+1 WHERE planta_id=@planta;
 INSERT INTO prod.PlantaEventoE3(planta_id,tipo,estado_anterior,estado_nuevo,observacion,usuario_id,fecha_hecho)
 VALUES(@planta,'ELIMINACION',@prev,'ELIMINADA',@motivo,@usuario,@now);
 SET @cDatos=(SELECT @planta plantaId,SCOPE_IDENTITY() eventoId,'ELIMINADA' estado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);

 SELECT @bResultado=1,@cMensaje=N'Operación realizada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 INSERT INTO prod.PlantaSolicitudE3(usuario_id,accion,clave,hash_peticion,respuesta)
 VALUES(@usuario,'E3_Planta_Upd_Eliminar',@clave,@hash,COALESCE(@cDatos,N'{}'));
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
