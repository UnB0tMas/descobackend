IF OBJECT_ID(N'[config].[PA_Respuesta_Sel_Catalogo]') IS NOT NULL
    DROP PROCEDURE [config].[PA_Respuesta_Sel_Catalogo];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : config.PA_Respuesta_Sel_Catalogo
' Descripción            : Consulta el catálogo de respuestas de la base de datos.
' Aplicativo / Módulo    : DESCO / Configuración
*******************************************************************************************************/
CREATE PROCEDURE [config].[PA_Respuesta_Sel_Catalogo]
    @cCodigo VARCHAR(60) = NULL,@bResultado BIT=NULL OUTPUT,@cMensaje NVARCHAR(300)=NULL OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET @cMensaje=NULL; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;

 SET NOCOUNT ON;
 SELECT @bResultado=0,@cMensaje=N'No se pudo consultar la información.';
 BEGIN TRY
  
  SELECT clave,codigo,numero_sql,mensaje,http_sugerido,reintentable
 FROM config.RespuestaBaseDatos WHERE estado=1 AND (@cCodigo IS NULL OR codigo=@cCodigo) ORDER BY codigo,clave;
  SELECT @bResultado=1,@cMensaje=N'Consulta realizada.';
 END TRY
 BEGIN CATCH
  SET @bResultado=0;
  EXEC config.PA_Respuesta_ResolverError @cProcedimiento=N'config.PA_Respuesta_Sel_Catalogo',@cMensaje=@cMensaje OUTPUT,@cJson=NULL;
 END CATCH;
Salida:
 SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'config.PA_Respuesta_Sel_Catalogo',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
