IF OBJECT_ID(N'[prod].[PA_FundoHabilitacion_Upd_Estado]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_FundoHabilitacion_Upd_Estado];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_FundoHabilitacion_Upd_Estado
' Descripción            : Actualiza información de Fundo Habilitacion (estado).
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_FundoHabilitacion_Upd_Estado
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigo VARCHAR(60) OUTPUT,@nHttp SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo cambiar el estado.',@cCodigo='FUNDO_APTITUD_ERROR',@nHttp=400;
 DECLARE @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
  @conv BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.convenioId')),
  @predio BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.predioId')),
  @valor NVARCHAR(10)=JSON_VALUE(@cJson,'$.datos.habilitado'),@habilitar BIT,
  @esperada BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.version')),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
  @auth BIT,@authMsg NVARCHAR(300),@plantas BIGINT=0,@actual BIGINT=0,
  @hash VARBINARY(32),@hashPrev VARBINARY(32),@prev NVARCHAR(MAX);
 BEGIN TRY
  IF ISJSON(@cJson)<>1 OR @uot IS NULL OR @conv IS NULL OR @predio IS NULL OR @clave IS NULL
    OR @esperada IS NULL OR @esperada<0 OR @valor IS NULL OR @valor NOT IN(N'true',N'false')
   THROW 51911,N'La solicitud no es válida.',1;
  SET @habilitar=CASE WHEN @valor=N'true' THEN 1 ELSE 0 END;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,'APAPPSS_PREDIOS_EDITAR',
   @usuario OUTPUT,@sesion OUTPUT,@dispositivo OUTPUT,@empleado OUTPUT,@modulo OUTPUT,
   @corr OUTPUT,@sol OUTPUT,@ip OUTPUT,@endpoint OUTPUT,@auth OUTPUT,@authMsg OUTPUT;
  IF ISNULL(@auth,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'APAPPSS_PREDIOS_EDITAR')<>1
   THROW 51912,N'No tiene permiso para cambiar la aptitud.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(@predio,N'|',@conv,N'|',JSON_QUERY(@cJson,'$.datos')));
  BEGIN TRANSACTION;
  SELECT @hashPrev=hash_peticion,@prev=respuesta FROM prod.FundoAccionSolicitud WITH(UPDLOCK,HOLDLOCK)
   WHERE usuario_id=@usuario AND clave=@clave;
  IF @hashPrev IS NOT NULL
  BEGIN
   IF @hashPrev<>@hash THROW 51913,N'La solicitud ya fue utilizada.',1;
   COMMIT TRANSACTION;
   SELECT @cDatos=@prev,@bResultado=1,@cMensaje=N'Operación ya registrada.',@cCodigo='FUNDO_APTITUD_OK',@nHttp=200;
   RETURN;
  END;
  IF NOT EXISTS(SELECT 1 FROM prod.Predio P WITH(UPDLOCK,HOLDLOCK)
   JOIN prod.PredioAmbito A ON A.predio_id=P.predio_id AND A.estado=1
   JOIN org.ConvenioUOTOrganizacion C ON C.convenio_uot_organizacion_id=A.convenio_uot_organizacion_id AND C.estado=1
   WHERE P.predio_id=@predio AND P.estado=1 AND A.uot_id=@uot AND A.convenio_uot_organizacion_id=@conv
    AND C.uot_id=@uot AND EXISTS(SELECT 1 FROM prod.PredioTitularidad T
     JOIN org.SocioAsociacion S ON S.socio_id=T.socio_id AND S.asociacion_id=C.empresa_id AND S.estado=1
     WHERE T.predio_id=P.predio_id AND T.estado=1 AND T.fecha_hasta IS NULL))
   THROW 51914,N'Fundo no disponible para el convenio.',1;
  SELECT @plantas=COUNT_BIG(*) FROM prod.PlantaPaltaE3
   WHERE predio_id=@predio AND uot_id=@uot AND convenio_id=@conv AND activo=1 AND estado_actual IN('SIN_EVALUAR','SANA','ENFERMA');
  IF @habilitar=1 AND @plantas=0 THROW 51915,N'Registre al menos una planta activa.',1;
  SELECT @actual=version FROM prod.FundoHabilitacion WITH(UPDLOCK,HOLDLOCK)
   WHERE predio_id=@predio AND convenio_id=@conv;
  IF @actual<>@esperada THROW 51916,N'El estado cambió. Actualice el fundo.',1;
  IF @actual=0
   INSERT prod.FundoHabilitacion(predio_id,convenio_id,uot_id,habilitado,usuario_id)
    VALUES(@predio,@conv,@uot,@habilitar,@usuario);
  ELSE
   UPDATE prod.FundoHabilitacion SET habilitado=@habilitar,version=version+1,usuario_id=@usuario,
    actualizado_en=SYSUTCDATETIME() WHERE predio_id=@predio AND convenio_id=@conv;
  INSERT prod.FundoAccionHistorial(predio_id,convenio_id,accion,usuario_id)
   VALUES(@predio,@conv,CASE WHEN @habilitar=1 THEN 'HABILITAR' ELSE 'DESHABILITAR' END,@usuario);
  SELECT @actual=version FROM prod.FundoHabilitacion WHERE predio_id=@predio AND convenio_id=@conv;
  SET @cDatos=(SELECT @predio predioId,@habilitar habilitado,@plantas plantasActivas,@actual version FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT prod.FundoAccionSolicitud(usuario_id,clave,tipo,hash_peticion,respuesta)
   VALUES(@usuario,@clave,'APTITUD',@hash,@cDatos);
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cMensaje=N'Aptitud actualizada.',@cCodigo='FUNDO_APTITUD_OK',@nHttp=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,@cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51911 AND 51999
   THEN ERROR_MESSAGE() ELSE N'No se pudo cambiar el estado.' END,
   @cCodigo='FUNDO_APTITUD_ERROR',@nHttp=CASE WHEN ERROR_NUMBER() BETWEEN 51911 AND 51999 THEN 400 ELSE 503 END;
 END CATCH;
END;
GO
