IF OBJECT_ID(N'[comercial].[PA_Jabas_Sel_SaldoInterno]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_Jabas_Sel_SaldoInterno];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_Jabas_Sel_SaldoInterno
' Descripción             : Obtiene el saldo interno de jabas para un operativo.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Comercial
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo de referencia: reemplazar valores e identificadores por datos válidos.
    DECLARE
        @nRecibidas INT,
        @nAsignadas INT,
        @nDevueltas INT,
        @nPendientes INT,
        @nDisponibles INT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [comercial].[PA_Jabas_Sel_SaldoInterno]
        @nOperativoVentaId = 0,
        @nOperativoSocioId = 0,
        @nRecibidas = @nRecibidas OUTPUT,
        @nAsignadas = @nAsignadas OUTPUT,
        @nDevueltas = @nDevueltas OUTPUT,
        @nPendientes = @nPendientes OUTPUT,
        @nDisponibles = @nDisponibles OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nRecibidas, @nAsignadas, @nDevueltas, @nPendientes, @nDisponibles, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [comercial].[PA_Jabas_Sel_SaldoInterno]
(
    @nOperativoVentaId BIGINT,
    @nOperativoSocioId BIGINT = NULL,
    @nRecibidas INT OUTPUT,
    @nAsignadas INT OUTPUT,
    @nDevueltas INT OUTPUT,
    @nPendientes INT OUTPUT,
    @nDisponibles INT OUTPUT
,@bResultado BIT=NULL OUTPUT,@cMensaje NVARCHAR(300)=NULL OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS
BEGIN
    SET @cMensaje=NULL; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;

 SET NOCOUNT ON;
 SELECT @bResultado=0,@cMensaje=N'No se pudo consultar la información.';
 BEGIN TRY

  SELECT @nRecibidas=NULL,@nAsignadas=0,@nDevueltas=0,@nPendientes=0,@nDisponibles=0;
  SELECT @nRecibidas=CONVERT(INT,recibidas),@nAsignadas=CONVERT(INT,asignadas),
   @nDevueltas=CONVERT(INT,devueltas_llenas+devueltas_vacias),@nPendientes=CONVERT(INT,pendientes),@nDisponibles=CONVERT(INT,disponibles)
  FROM comercial.JabaSaldoOperativo WHERE operativo_venta_id=@nOperativoVentaId;
  IF @nRecibidas IS NULL THROW 51100,N'DESCO_RECURSO_NO_DISPONIBLE',1;
  IF @nOperativoSocioId IS NOT NULL
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM comercial.OperativoSocio WHERE operativo_socio_id=@nOperativoSocioId AND operativo_venta_id=@nOperativoVentaId)
    THROW 51100,N'DESCO_JABA_RELACION',1;
   SELECT @nAsignadas=CONVERT(INT,COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)),0)),
    @nDevueltas=CONVERT(INT,COALESCE(SUM(A.cantidad_devuelta),0))
   FROM comercial.JabaAsignacion A WHERE A.operativo_socio_id=@nOperativoSocioId AND A.estado=1;
   SELECT @nPendientes=@nAsignadas-@nDevueltas,@nDisponibles=@nAsignadas-@nDevueltas;
  END;

  SELECT @bResultado=1,@cMensaje=N'Saldo de jabas consultado.';
 END TRY
 BEGIN CATCH
  SET @bResultado=0;
  EXEC config.PA_Respuesta_ResolverError @cProcedimiento=N'comercial.PA_Jabas_Sel_SaldoInterno',@cMensaje=@cMensaje OUTPUT,@cJson=NULL;
 END CATCH;
Salida:
 SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'comercial.PA_Jabas_Sel_SaldoInterno',@bResultado,@cMensaje) R;
IF @bResultado=0 AND @@NESTLEVEL>1 THROW 51000,@cMensaje,1;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
