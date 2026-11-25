IF OBJECT_ID(N'[prod].[PA_E3_Planta_Ins_Individual]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_E3_Planta_Ins_Individual];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_E3_Planta_Ins_Individual
' Descripción            : Registra e3 planta para individual.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_E3_Planta_Ins_Individual
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @bResultado=0,@cDatos=NULL,@cCodigoRespuesta='E3_ERROR',@cMensaje=N'No se pudo registrar la planta.',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@uot BIGINT,@conv BIGINT,@predio BIGINT,
  @variedad SMALLINT=TRY_CONVERT(SMALLINT,JSON_VALUE(@cJson,'$.datos.variedadId')),
  @socioSolicitado BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.socioId')),
  @socio BIGINT,@socios INT,
  @observacion NVARCHAR(1000)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.observacion')),N''),
  @plantacion DATE=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaPlantacion')),
  @edad SMALLINT=TRY_CONVERT(SMALLINT,JSON_VALUE(@cJson,'$.datos.edadReferenciaAnios')),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @hash VARBINARY(32),@hashAnterior VARBINARY(32),@replay NVARCHAR(MAX),
  @correlativo INT,@planta BIGINT,@codigo VARCHAR(80),@bloqueo INT,
  @fecha DATETIME2(0)=SYSUTCDATETIME();
 BEGIN TRY
  EXEC prod.PA_E3_Sel_ValidarPredio @cJson,'APAPPSS_PREDIOS_CREAR',@usuario OUTPUT,@uot OUTPUT,@conv OUTPUT,@predio OUTPUT;
  IF @variedad IS NULL OR NOT EXISTS(SELECT 1 FROM prod.VariedadPalta WHERE variedad_palta_id=@variedad AND estado=1)
   THROW 51320,N'Seleccione una variedad vigente.',1;
  IF @edad IS NOT NULL AND @edad NOT BETWEEN 0 AND 200 THROW 51320,N'La edad debe estar entre 0 y 200 años.',1;
  IF @plantacion IS NOT NULL AND (@plantacion>CONVERT(DATE,@fecha) OR @edad IS NOT NULL)
   THROW 51320,N'Indique una fecha de plantación válida o una edad, no ambas.',1;
  IF LEN(@observacion)>1000 THROW 51320,N'La observación excede el límite permitido.',1;
  IF @clave IS NULL THROW 51320,N'La solicitud no tiene identificador para evitar duplicaciones.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT('E3_INDIVIDUAL|',JSON_QUERY(@cJson,'$.filtros'),N'|',JSON_QUERY(@cJson,'$.datos')));
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM prod.Predio WITH(UPDLOCK,HOLDLOCK) WHERE predio_id=@predio)
   THROW 51312,N'El predio no está disponible.',1;
  SELECT @hashAnterior=hash_peticion,@replay=respuesta FROM prod.PlantaSolicitudE3 WITH(UPDLOCK,HOLDLOCK)
   WHERE usuario_id=@usuario AND accion='ALTA_INDIVIDUAL' AND clave=@clave;
  IF @hashAnterior IS NOT NULL BEGIN
   IF @hashAnterior<>@hash THROW 51321,N'La solicitud ya fue utilizada con otros datos.',1;
   SELECT @cDatos=@replay,@bResultado=1,@cCodigoRespuesta='E3_OK',@cMensaje=N'Planta previamente registrada.',@nHttpRespuesta=200;
   COMMIT TRANSACTION;RETURN;
  END;
  IF NOT EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 WHERE predio_id=@predio)
   THROW 51322,N'Primero debe registrar la cantidad inicial de plantas del predio.',1;
  SELECT @socios=COUNT(DISTINCT T.socio_id),@socio=MIN(T.socio_id)
   FROM prod.PredioTitularidad T
   JOIN org.SocioAsociacion SA ON SA.socio_id=T.socio_id AND SA.estado=1
   JOIN org.ConvenioUOTOrganizacion C ON C.convenio_uot_organizacion_id=@conv AND SA.asociacion_id=C.empresa_id
   WHERE T.predio_id=@predio AND T.estado=1 AND T.fecha_hasta IS NULL
    AND SA.fecha_desde<=CONVERT(DATE,@fecha) AND (SA.fecha_hasta IS NULL OR SA.fecha_hasta>=CONVERT(DATE,@fecha))
    AND (@socioSolicitado IS NULL OR T.socio_id=@socioSolicitado);
  IF ISNULL(@socios,0)<>1 THROW 51323,N'Seleccione el socio titular del predio.',1;
  DECLARE @recurso NVARCHAR(255)=CONCAT(N'DESCO:E3:CORR:',@predio,N':',@variedad);
  EXEC @bloqueo=sys.sp_getapplock @Resource=@recurso,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=5000;
  IF @bloqueo<0 THROW 51324,N'Hay un registro de plantas en curso. Vuelva a intentarlo.',1;
  SELECT @correlativo=ultimo FROM prod.PlantaCorrelativoE3 WITH(UPDLOCK,HOLDLOCK)
    WHERE predio_id=@predio AND variedad_palta_id=@variedad;
  IF @correlativo IS NULL BEGIN
   SELECT @correlativo=ISNULL(MAX(secuencia),0) FROM prod.PlantaPaltaE3 WITH(UPDLOCK,HOLDLOCK)
    WHERE predio_id=@predio AND variedad_palta_id=@variedad;
   INSERT INTO prod.PlantaCorrelativoE3(predio_id,variedad_palta_id,ultimo) VALUES(@predio,@variedad,@correlativo+1);
  END ELSE UPDATE prod.PlantaCorrelativoE3 SET ultimo=@correlativo+1 WHERE predio_id=@predio AND variedad_palta_id=@variedad;
  SET @codigo=CONCAT('PAL-',@predio,'-',@variedad,'-',RIGHT(CONCAT('000000000',@correlativo+1),9));
  INSERT INTO prod.PlantaPaltaE3(predio_id,uot_id,convenio_id,socio_id,variedad_palta_id,secuencia,codigo,estado_actual,
    fecha_plantacion,edad_referencia_anios,fecha_referencia,creado_por_usuario_id)
  VALUES(@predio,@uot,@conv,@socio,@variedad,@correlativo+1,@codigo,'SIN_EVALUAR',@plantacion,@edad,
    CASE WHEN @edad IS NOT NULL THEN CONVERT(DATE,@fecha) ELSE NULL END,@usuario);
  SET @planta=CONVERT(BIGINT,SCOPE_IDENTITY());
  INSERT INTO prod.PlantaEventoE3(planta_id,tipo,estado_nuevo,observacion,usuario_id,fecha_hecho)
   VALUES(@planta,'ALTA','SIN_EVALUAR',@observacion,@usuario,@fecha);
  SET @cDatos=(SELECT @planta plantaId,@codigo codigo,'SIN_EVALUAR' estado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT INTO prod.PlantaSolicitudE3(usuario_id,accion,clave,hash_peticion,respuesta)
   VALUES(@usuario,'ALTA_INDIVIDUAL',@clave,@hash,@cDatos);
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cCodigoRespuesta='E3_OK',@cMensaje=N'Planta registrada.',@nHttpRespuesta=201;
 END TRY BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
  SELECT @bResultado=0,@cDatos=NULL,@cCodigoRespuesta='E3_ERROR',
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51300 AND 51399 THEN ERROR_MESSAGE() ELSE N'No se pudo registrar la planta.' END,
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51300 AND 51399 THEN 400 ELSE 503 END;
 END CATCH;
END;
GO
