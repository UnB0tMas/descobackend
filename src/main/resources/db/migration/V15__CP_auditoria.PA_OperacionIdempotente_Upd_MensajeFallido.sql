IF OBJECT_ID(N'[auditoria].[PA_OperacionIdempotente_Upd_MensajeFallido]', N'P') IS NOT NULL
    DROP PROCEDURE [auditoria].[PA_OperacionIdempotente_Upd_MensajeFallido];
GO

/******************************************************************************************************
' Nombre del PA           : auditoria.PA_OperacionIdempotente_Upd_MensajeFallido
' Descripción             : Actualiza el mensaje de resultado fallido de una operación idempotente.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Auditoría
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo. Sustituir JSON, IDs y valores por datos válidos del entorno.
    DECLARE
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [auditoria].[PA_OperacionIdempotente_Upd_MensajeFallido]
        @nOperacionIdempotenteId = 1,
        @cMensajeResultado = N'No se completó la operación.',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE auditoria.PA_OperacionIdempotente_Upd_MensajeFallido
 @nOperacionIdempotenteId BIGINT,@cMensajeResultado NVARCHAR(300),
 @bResultado BIT=NULL OUTPUT,@cMensaje NVARCHAR(300)=NULL OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET @cMensaje=NULL; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;

 SET NOCOUNT ON;
 SELECT @bResultado=0,@cMensaje=N'No se pudo guardar el resultado.';
 BEGIN TRY
  IF XACT_STATE()=-1 GOTO Salida;
  UPDATE auditoria.OperacionIdempotente SET estado_operacion='FALLIDA',fecha_fin=COALESCE(fecha_fin,SYSUTCDATETIME()),
   codigo_resultado=COALESCE(codigo_resultado,'NO_PROCESADO'),mensaje_resultado=LEFT(COALESCE(NULLIF(@cMensajeResultado,N''),N'La acción no se completó.'),300)
  WHERE operacion_idempotente_id=@nOperacionIdempotenteId AND estado_operacion IN('EN_PROCESO','FALLIDA');
  IF @@ROWCOUNT>0 SELECT @bResultado=1,@cMensaje=N'Resultado guardado.';
  ELSE IF EXISTS(SELECT 1 FROM auditoria.OperacionIdempotente WHERE operacion_idempotente_id=@nOperacionIdempotenteId AND estado_operacion='COMPLETADA')
   SELECT @bResultado=1,@cMensaje=N'Resultado conservado.';
 END TRY
 BEGIN CATCH
  SET @bResultado=0;
 END CATCH;
Salida:
 SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'auditoria.PA_OperacionIdempotente_Upd_MensajeFallido',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
