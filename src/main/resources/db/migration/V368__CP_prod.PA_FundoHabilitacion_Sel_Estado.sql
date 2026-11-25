IF OBJECT_ID(N'[prod].[PA_FundoHabilitacion_Sel_Estado]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_FundoHabilitacion_Sel_Estado];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_FundoHabilitacion_Sel_Estado
' Descripción            : Consulta información de Fundo Habilitacion (estado).
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_FundoHabilitacion_Sel_Estado
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigo VARCHAR(60) OUTPUT,@nHttp SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'Fundo no disponible.',@cCodigo='FUNDO_APTITUD_ERROR',@nHttp=400;
 DECLARE @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
  @conv BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.convenioId')),
  @predio BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.predioId')),
  @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
  @auth BIT,@authMsg NVARCHAR(300),@plantas BIGINT=0,@habilitado BIT=0,@version BIGINT=0;
 BEGIN TRY
  IF ISJSON(@cJson)<>1 OR @uot IS NULL OR @conv IS NULL OR @predio IS NULL THROW 51901,N'Indique fundo y convenio.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,'APAPPSS_PREDIOS_VER',
   @usuario OUTPUT,@sesion OUTPUT,@dispositivo OUTPUT,@empleado OUTPUT,@modulo OUTPUT,
   @corr OUTPUT,@sol OUTPUT,@ip OUTPUT,@endpoint OUTPUT,@auth OUTPUT,@authMsg OUTPUT;
  IF ISNULL(@auth,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'APAPPSS_PREDIOS_VER')<>1
   THROW 51902,N'No tiene permiso para consultar el fundo.',1;
  IF NOT EXISTS(SELECT 1 FROM prod.Predio P JOIN prod.PredioAmbito A ON A.predio_id=P.predio_id AND A.estado=1
   JOIN org.ConvenioUOTOrganizacion C ON C.convenio_uot_organizacion_id=A.convenio_uot_organizacion_id AND C.estado=1
   WHERE P.predio_id=@predio AND P.estado=1 AND A.uot_id=@uot AND A.convenio_uot_organizacion_id=@conv
    AND C.uot_id=@uot AND EXISTS(SELECT 1 FROM prod.PredioTitularidad T
     JOIN org.SocioAsociacion S ON S.socio_id=T.socio_id AND S.asociacion_id=C.empresa_id AND S.estado=1
     WHERE T.predio_id=P.predio_id AND T.estado=1 AND T.fecha_hasta IS NULL))
   THROW 51903,N'Fundo no vinculado a este convenio.',1;
  SELECT @plantas=COUNT_BIG(*) FROM prod.PlantaPaltaE3
   WHERE predio_id=@predio AND uot_id=@uot AND convenio_id=@conv AND activo=1 AND estado_actual IN('SIN_EVALUAR','SANA','ENFERMA');
  SELECT @habilitado=habilitado,@version=version FROM prod.FundoHabilitacion
   WHERE predio_id=@predio AND uot_id=@uot AND convenio_id=@conv;
  SET @cDatos=(SELECT @predio predioId,@habilitado habilitado,@plantas plantasActivas,@version version FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Aptitud consultada.',@cCodigo='FUNDO_APTITUD_OK',@nHttp=200;
 END TRY BEGIN CATCH
  SELECT @cDatos=NULL,@bResultado=0,@cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51901 AND 51999
   THEN ERROR_MESSAGE() ELSE N'No se pudo consultar la aptitud.' END,
   @cCodigo='FUNDO_APTITUD_ERROR',@nHttp=CASE WHEN ERROR_NUMBER() BETWEEN 51901 AND 51999 THEN 400 ELSE 503 END;
 END CATCH;
END;
GO
