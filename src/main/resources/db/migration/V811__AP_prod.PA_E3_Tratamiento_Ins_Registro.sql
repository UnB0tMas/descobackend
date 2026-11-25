IF OBJECT_ID(N'[prod].[PA_E3_Tratamiento_Ins_Registro]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_E3_Tratamiento_Ins_Registro];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_E3_Tratamiento_Ins_Registro
' Descripción            : Registra la información de e3 tratamiento.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_E3_Tratamiento_Ins_Registro
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
 SET @hash=HASHBYTES('SHA2_256',CONCAT('PA_E3_Tratamiento_Ins_Registro',N'|',JSON_QUERY(@cJson,'$.filtros'),N'|',JSON_QUERY(@cJson,'$.datos')));
 BEGIN TRANSACTION;
 SELECT @anterior=hash_peticion,@previo=respuesta FROM prod.PlantaSolicitudE3 WITH(UPDLOCK,HOLDLOCK)
 WHERE usuario_id=@usuario AND accion='E3_Tratamiento_Ins_Registro' AND clave=@clave;
 IF @anterior IS NOT NULL
 BEGIN
  IF @anterior<>@hash THROW 51217,N'La operación ya fue utilizada con otros datos.',1;
  SELECT @cDatos=@previo,@bResultado=1,@cMensaje=N'Operación previamente registrada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
  COMMIT TRANSACTION;RETURN;
 END;

 DECLARE @catalogo INT=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.catalogoTratamientoId')),
  @fecha DATETIME2(0)=COALESCE(TRY_CONVERT(DATETIME2(0),JSON_VALUE(@cJson,'$.datos.fechaAplicacion')),@now),
  @comentario NVARCHAR(1000)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.comentario'))),N''),
  @resultado NVARCHAR(600)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.resultado'))),N''),@id BIGINT,@inicio DATETIME2(0);
 IF EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 WITH(UPDLOCK,HOLDLOCK) WHERE planta_id=@planta AND estado_actual IN('MUERTA','ELIMINADA'))
  THROW 51240,N'No se puede tratar una planta inactiva.',1;
 SELECT @inicio=inicio FROM sanidad.EpisodioPlantaE3 WITH(UPDLOCK,HOLDLOCK)
   WHERE episodio_id=@episodio AND planta_id=@planta AND activo=1 AND fin IS NULL;
 IF @inicio IS NULL THROW 51241,N'El tratamiento requiere una enfermedad vigente.',1;
 IF @fecha<@inicio OR @fecha>@now THROW 51242,N'La fecha del tratamiento debe ser posterior al diagnóstico y no futura.',1;
 IF NOT EXISTS(SELECT 1 FROM sanidad.EpisodioPlantaE3 E
  JOIN prod.GPProblemaTratamiento PT ON PT.problema_id=E.gp_problema_id AND PT.tratamiento_id=@catalogo
  JOIN prod.GPTratamiento T ON T.tratamiento_id=PT.tratamiento_id AND T.estado=1 WHERE E.episodio_id=@episodio)
  THROW 51243,N'El tratamiento no corresponde a esta enfermedad.',1;
 INSERT INTO sanidad.TratamientoPlantaE3(episodio_id,gp_tratamiento_id,descripcion,resultado,comentario,
  fecha_aplicacion,usuario_id)
 SELECT @episodio,T.tratamiento_id,T.nombre,@resultado,@comentario,@fecha,@usuario
 FROM prod.GPTratamiento T WHERE T.tratamiento_id=@catalogo;
 SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
 INSERT INTO prod.PlantaEventoE3(planta_id,tipo,observacion,usuario_id,fecha_hecho)
 VALUES(@planta,'TRATAMIENTO',CONCAT(N'Tratamiento aplicado a enfermedad ',@episodio),@usuario,@now);
 SET @cDatos=(SELECT @id tratamientoId,@episodio episodioId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);

 SELECT @bResultado=1,@cMensaje=N'Operación realizada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 INSERT INTO prod.PlantaSolicitudE3(usuario_id,accion,clave,hash_peticion,respuesta)
 VALUES(@usuario,'E3_Tratamiento_Ins_Registro',@clave,@hash,COALESCE(@cDatos,N'{}'));
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
