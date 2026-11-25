IF OBJECT_ID(N'[comercial].[PA_APAPPSS_TipoDocumento_Sel_Listado]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_APAPPSS_TipoDocumento_Sel_Listado];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_APAPPSS_TipoDocumento_Sel_Listado
' Descripción            : Consulta información de APAPPSS Tipo Documento (listado).
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_APAPPSS_TipoDocumento_Sel_Listado
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT, @cCodigoRespuesta VARCHAR(60) OUTPUT, @nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudieron consultar documentos.',
   @cCodigoRespuesta='APAPPSS_DOCUMENTOS_ERROR',@nHttpRespuesta=403;
 DECLARE @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
   @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
   @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
   @acceso BIT,@mensajeAcceso NVARCHAR(300);
 BEGIN TRY
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='APAPPSS_COMPRADORES_CREAR',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR @uot IS NULL
      OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'APAPPSS_COMPRADORES_CREAR')<>1
    THROW 51831,N'No tiene autorización para consultar documentos.',1;
  SET @cDatos=(SELECT JSON_QUERY((SELECT codigo,nombre FROM config.TipoDocumentoComprador
    WHERE estado=1 ORDER BY CASE codigo WHEN 'DNI' THEN 0 WHEN 'RUC' THEN 1
        WHEN 'CE' THEN 2 WHEN 'PASAPORTE' THEN 3 ELSE 4 END,nombre FOR JSON PATH)) AS items
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Documentos consultados.',
    @cCodigoRespuesta='APAPPSS_DOCUMENTOS_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  SELECT @cDatos=NULL,@bResultado=0,@cMensaje=LEFT(ERROR_MESSAGE(),300),
    @cCodigoRespuesta='APAPPSS_DOCUMENTOS_ERROR',@nHttpRespuesta=403;
 END CATCH;
END;
GO
