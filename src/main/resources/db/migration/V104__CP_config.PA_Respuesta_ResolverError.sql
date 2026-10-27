IF OBJECT_ID(N'[config].[PA_Respuesta_ResolverError]', N'P') IS NOT NULL
    DROP PROCEDURE [config].[PA_Respuesta_ResolverError];
GO

/******************************************************************************************************
' Nombre del PA           : config.PA_Respuesta_ResolverError
' Descripción             : Resuelve el mensaje de error aplicable a un procedimiento almacenado.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Configuración
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo: sustituir identificadores y valores por datos válidos.
    -- El JSON mostrado es ilustrativo y debe ajustarse al contrato del PA.
    DECLARE
        @cMensaje NVARCHAR(300),
        @cCodigo VARCHAR(60),
        @nHttpSugerido SMALLINT,
        @bReintentable BIT,
        @bResultado BIT,
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [config].[PA_Respuesta_ResolverError]
        @cProcedimiento = N'',
        @cMensaje = @cMensaje OUTPUT,
        @cJson = N'{}',
        @bMensajePublicoGenerico = 0,
        @nNumeroError = 0,
        @cDetalleError = N'',
        @bRegistrar = 0,
        @cCodigo = @cCodigo OUTPUT,
        @nHttpSugerido = @nHttpSugerido OUTPUT,
        @bReintentable = @bReintentable OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @cMensaje, @cCodigo, @nHttpSugerido, @bReintentable, @bResultado, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE config.PA_Respuesta_ResolverError
 @cProcedimiento NVARCHAR(257),@cMensaje NVARCHAR(300) OUTPUT,@cJson NVARCHAR(MAX)=NULL,
 @bMensajePublicoGenerico BIT=0,@nNumeroError INT=NULL,@cDetalleError NVARCHAR(4000)=NULL,
 @bRegistrar BIT=1,@cCodigo VARCHAR(60)=NULL OUTPUT,@nHttpSugerido SMALLINT=NULL OUTPUT,
 @bReintentable BIT=NULL OUTPUT,@bResultado BIT=NULL OUTPUT,
 @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @numero INT=COALESCE(@nNumeroError,ERROR_NUMBER(),0),
 @detalle NVARCHAR(4000)=COALESCE(@cDetalleError,ERROR_MESSAGE(),N''),
 @linea INT=ERROR_LINE(),@origen NVARCHAR(257)=COALESCE(ERROR_PROCEDURE(),@cProcedimiento),
 @clave VARCHAR(150),@correlacion UNIQUEIDENTIFIER;
 SELECT @bResultado=0,@cMensaje=N'No se pudo completar la acción. Intente nuevamente.',
 @cCodigo='ERROR_INTERNO',@nHttpSugerido=500,@bReintentable=0;
 BEGIN TRY
  SELECT TOP(1) @clave=R.clave,@cMensaje=R.mensaje,@cCodigo=R.codigo,
   @nHttpSugerido=R.http_sugerido,@bReintentable=R.reintentable
  FROM config.RespuestaBaseDatos R WHERE R.estado=1 AND
   ((@numero IN(2601,2627,547) AND
     (CHARINDEX(NCHAR(39)+CONVERT(NVARCHAR(150),R.clave)+NCHAR(39),@detalle)>0
       OR CHARINDEX(N'"'+CONVERT(NVARCHAR(150),R.clave)+N'"',@detalle)>0
       OR CHARINDEX(N'['+CONVERT(NVARCHAR(150),R.clave)+N']',@detalle)>0))
    OR (@numero>=50000 AND @detalle=CONVERT(NVARCHAR(150),R.clave)))
  ORDER BY LEN(R.clave) DESC,R.clave;
  IF @clave IS NULL AND @numero>=50000
  BEGIN
   SELECT TOP(1) @clave='MENSAJE_APROBADO',@cMensaje=M.mensaje,@cCodigo=M.codigo_error,@nHttpSugerido=M.http_error
   FROM config.MensajeUsuario M WHERE M.texto_origen=@detalle OR M.mensaje=@detalle
   ORDER BY CASE WHEN M.texto_origen=@detalle THEN 0 ELSE 1 END,M.texto_origen;
  END;
  IF @clave IS NULL
   SELECT @cMensaje=R.mensaje,@cCodigo=R.codigo,@nHttpSugerido=R.http_sugerido,@bReintentable=R.reintentable
   FROM config.RespuestaBaseDatos R WHERE R.estado=1 AND R.clave='SQL_'+CONVERT(VARCHAR(11),@numero);
  IF ISJSON(@cJson)=1
   SET @correlacion=TRY_CONVERT(UNIQUEIDENTIFIER,COALESCE(JSON_VALUE(@cJson,'$.contexto.correlacionId'),JSON_VALUE(@cJson,'$.correlacionId')));
  IF @bRegistrar=1 AND XACT_STATE()<>-1
  BEGIN TRY
   -- No se almacenan documentos, correos, contraseñas, tokens ni el contenido de la solicitud.
   INSERT auditoria.ErrorBaseDatos(fecha_utc,numero_error,procedimiento,linea,codigo,correlacion_id)
   VALUES(SYSUTCDATETIME(),@numero,@origen,@linea,@cCodigo,@correlacion);
  END TRY
  BEGIN CATCH
   SET @bResultado=0;
  END CATCH;
 END TRY
 BEGIN CATCH
  SELECT @cMensaje=N'No se pudo completar la acción. Intente nuevamente.',@cCodigo='ERROR_INTERNO',@nHttpSugerido=500;
 END CATCH;
 IF @bMensajePublicoGenerico=1
  SELECT @cMensaje=N'No se pudo completar la solicitud. Verifique los datos.',@cCodigo='SOLICITUD_NO_COMPLETADA';
 SELECT @cCodigoRespuesta=@cCodigo,@nHttpRespuesta=@nHttpSugerido;
 RETURN 1;
END;
GO
