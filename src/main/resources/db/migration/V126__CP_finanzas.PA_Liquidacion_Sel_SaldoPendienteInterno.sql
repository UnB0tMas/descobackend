IF OBJECT_ID(N'[finanzas].[PA_Liquidacion_Sel_SaldoPendienteInterno]', N'P') IS NOT NULL
    DROP PROCEDURE [finanzas].[PA_Liquidacion_Sel_SaldoPendienteInterno];
GO

/******************************************************************************************************
' Nombre del PA           : finanzas.PA_Liquidacion_Sel_SaldoPendienteInterno
' Descripción             : Consulta el saldo pendiente interno de una liquidación.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Finanzas
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo: sustituir identificadores y valores por datos válidos.
    DECLARE
        @nImporteNeto DECIMAL(19,4),
        @nTotalPagado DECIMAL(19,4),
        @nSaldoPendiente DECIMAL(19,4),
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [finanzas].[PA_Liquidacion_Sel_SaldoPendienteInterno]
        @nLiquidacionSocioId = 0,
        @nImporteNeto = @nImporteNeto OUTPUT,
        @nTotalPagado = @nTotalPagado OUTPUT,
        @nSaldoPendiente = @nSaldoPendiente OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nImporteNeto, @nTotalPagado, @nSaldoPendiente, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [finanzas].[PA_Liquidacion_Sel_SaldoPendienteInterno]
(
    @nLiquidacionSocioId BIGINT,
    @nImporteNeto DECIMAL(19,4) OUTPUT,
    @nTotalPagado DECIMAL(19,4) OUTPUT,
    @nSaldoPendiente DECIMAL(19,4) OUTPUT,
    @bResultado BIT=NULL OUTPUT,
    @cMensaje NVARCHAR(300)=NULL OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS
BEGIN
    SET @cMensaje=NULL; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;

    /* Respuesta explícita; mensajes públicos aprobados. */
    SET NOCOUNT ON;
    DECLARE @__DbTranEntrada INT = @@TRANCOUNT,
            @__DbTranAbierta BIT = 0,
            @__DbSavepoint VARCHAR(32) = REPLACE(CONVERT(VARCHAR(36),NEWID()),'-',''),
            @__DbMensaje NVARCHAR(300),
            @__DbError BIT = 0;

    SET @bResultado=0;
BEGIN TRY

    SET NOCOUNT ON;
    SELECT @nImporteNeto=0,@nTotalPagado=0,@nSaldoPendiente=0;
    SELECT @nImporteNeto=importe_neto FROM [finanzas].[LiquidacionSocio]
    WHERE liquidacion_socio_id=@nLiquidacionSocioId AND estado=1;
    SELECT @nTotalPagado=COALESCE(SUM(importe),0) FROM [finanzas].[PagoSocio]
    WHERE liquidacion_socio_id=@nLiquidacionSocioId AND estado=1 AND estado_proceso='CONFIRMADO';
    SET @nSaldoPendiente=CASE WHEN @nImporteNeto-@nTotalPagado<0 THEN 0 ELSE @nImporteNeto-@nTotalPagado END;

    END TRY
    BEGIN CATCH

        SET @__DbError = 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'finanzas.PA_Liquidacion_Sel_SaldoPendienteInterno',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
SET @bResultado=0; SET @cMensaje=@__DbMensaje;
    END CATCH;

__DESCO_Salida:
BEGIN TRY

IF @__DbTranAbierta = 1
BEGIN
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
END;

END TRY
BEGIN CATCH

        SET @__DbError = 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'finanzas.PA_Liquidacion_Sel_SaldoPendienteInterno',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
SET @bResultado=0; SET @cMensaje=@__DbMensaje;
END CATCH;
SET @bResultado=CASE WHEN @__DbError=0 THEN 1 ELSE 0 END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'finanzas.PA_Liquidacion_Sel_SaldoPendienteInterno',@bResultado,@cMensaje) R;
IF @bResultado=0 AND @@NESTLEVEL>1 THROW 51000,@cMensaje,1;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
