IF OBJECT_ID(N'[logistica].[PA_Suministro_Sel_StockInterno]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_Suministro_Sel_StockInterno];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_Suministro_Sel_StockInterno
' Descripción             : Consulta el stock interno de suministros.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo: sustituir identificadores y valores por datos válidos.
    DECLARE
        @nStock DECIMAL(19,3),
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @nReservado DECIMAL(19,3),
        @nDisponible DECIMAL(19,3),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [logistica].[PA_Suministro_Sel_StockInterno]
        @nSuministroId = 0,
        @nStock = @nStock OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @nReservado = @nReservado OUTPUT,
        @nDisponible = @nDisponible OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nStock, @bResultado, @cMensaje, @nReservado, @nDisponible, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [logistica].[PA_Suministro_Sel_StockInterno](@nSuministroId BIGINT,@nStock DECIMAL(19,3) OUTPUT,@bResultado BIT=NULL OUTPUT,@cMensaje NVARCHAR(300)=NULL OUTPUT,@nReservado DECIMAL(19,3)=NULL OUTPUT,@nDisponible DECIMAL(19,3)=NULL OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS
BEGIN
    SET @cMensaje=NULL; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;

 SET NOCOUNT ON;
 SELECT @bResultado=0,@cMensaje=N'No se pudo consultar la información.';
 BEGIN TRY

  SELECT @nStock=NULL,@nReservado=NULL,@nDisponible=NULL;
  SELECT @nStock=stock_actual,@nReservado=stock_reservado,@nDisponible=stock_disponible
  FROM logistica.SuministroSaldo WHERE suministro_id=@nSuministroId;
  IF @nStock IS NULL THROW 51100,N'DESCO_RECURSO_NO_DISPONIBLE',1;

  SELECT @bResultado=1,@cMensaje=N'Saldo consultado.';
 END TRY
 BEGIN CATCH
  SET @bResultado=0;
  EXEC config.PA_Respuesta_ResolverError @cProcedimiento=N'logistica.PA_Suministro_Sel_StockInterno',@cMensaje=@cMensaje OUTPUT,@cJson=NULL;
 END CATCH;
Salida:
 SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'logistica.PA_Suministro_Sel_StockInterno',@bResultado,@cMensaje) R;
IF @bResultado=0 AND @@NESTLEVEL>1 THROW 51000,@cMensaje,1;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
