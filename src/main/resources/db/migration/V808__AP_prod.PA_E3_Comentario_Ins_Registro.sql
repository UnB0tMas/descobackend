IF OBJECT_ID(N'[prod].[PA_E3_Comentario_Ins_Registro]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_E3_Comentario_Ins_Registro];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_E3_Comentario_Ins_Registro
' Descripción            : Registra la información de e3 comentario.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_E3_Comentario_Ins_Registro
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
 SET @hash=HASHBYTES('SHA2_256',CONCAT('PA_E3_Comentario_Ins_Registro',N'|',JSON_QUERY(@cJson,'$.filtros'),N'|',JSON_QUERY(@cJson,'$.datos')));
 BEGIN TRANSACTION;
 SELECT @anterior=hash_peticion,@previo=respuesta FROM prod.PlantaSolicitudE3 WITH(UPDLOCK,HOLDLOCK)
 WHERE usuario_id=@usuario AND accion='E3_Comentario_Ins_Registro' AND clave=@clave;
 IF @anterior IS NOT NULL
 BEGIN
  IF @anterior<>@hash THROW 51217,N'La operación ya fue utilizada con otros datos.',1;
  SELECT @cDatos=@previo,@bResultado=1,@cMensaje=N'Operación previamente registrada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
  COMMIT TRANSACTION;RETURN;
 END;

 DECLARE @comentario NVARCHAR(1500)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.comentario'))),N''),@id BIGINT;
 IF @comentario IS NULL THROW 51223,N'Escriba un comentario.',1;
 IF EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 WITH(UPDLOCK,HOLDLOCK) WHERE planta_id=@planta AND estado_actual IN('MUERTA','ELIMINADA'))
  THROW 51224,N'La planta eliminada solo admite consultas.',1;
 INSERT INTO prod.PlantaComentarioE3(planta_id,comentario,usuario_id) VALUES(@planta,@comentario,@usuario);
 SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
 INSERT INTO prod.PlantaEventoE3(planta_id,tipo,observacion,usuario_id,fecha_hecho)
 VALUES(@planta,'COMENTARIO',LEFT(@comentario,1000),@usuario,@now);
 SET @cDatos=(SELECT @id comentarioId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);

 SELECT @bResultado=1,@cMensaje=N'Operación realizada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 INSERT INTO prod.PlantaSolicitudE3(usuario_id,accion,clave,hash_peticion,respuesta)
 VALUES(@usuario,'E3_Comentario_Ins_Registro',@clave,@hash,COALESCE(@cDatos,N'{}'));
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
