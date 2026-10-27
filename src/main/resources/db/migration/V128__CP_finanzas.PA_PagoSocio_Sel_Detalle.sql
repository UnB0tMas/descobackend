IF OBJECT_ID(N'[finanzas].[PA_PagoSocio_Sel_Detalle]', N'P') IS NOT NULL
    DROP PROCEDURE [finanzas].[PA_PagoSocio_Sel_Detalle];
GO

/******************************************************************************************************
' Nombre del PA           : finanzas.PA_PagoSocio_Sel_Detalle
' Descripción             : Consulta el detalle de pago al socio.
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
    -- El JSON mostrado es ilustrativo y debe ajustarse al contrato del PA.
    DECLARE
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [finanzas].[PA_PagoSocio_Sel_Detalle]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [finanzas].[PA_PagoSocio_Sel_Detalle]
(
    @cJson NVARCHAR(MAX),
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
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
    SET @bResultado = 0;

    BEGIN TRY

    SET NOCOUNT ON;

    DECLARE
        @nUsuario BIGINT,
        @nSesion BIGINT,
        @nDisp BIGINT,
        @nEmp BIGINT,
        @nModulo INT,
        @gCorr UNIQUEIDENTIFIER,
        @gSol UNIQUEIDENTIFIER,
        @cIp VARCHAR(64),
        @cEnd NVARCHAR(250),
        @bCtx BIT,
        @cMsg NVARCHAR(300),
        @nId BIGINT,
        @nLiq BIGINT,
        @dFechaPago DATETIME2(0),
        @nNeto DECIMAL(19,4),
        @nPagadoActual DECIMAL(19,4),
        @nSaldoActual DECIMAL(19,4),
        @nConfirmadoHastaPago DECIMAL(19,4),
        @nSaldoPosteriorPago DECIMAL(19,4);

    SELECT
        @bResultado = 0,
        @cMensaje = N'No se pudo consultar el pago.';

    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
        @cJson = @cJson,
        @cCodigoPermiso = 'PAGOS_VER',
        @nUsuarioId = @nUsuario OUTPUT,
        @nSesionUsuarioId = @nSesion OUTPUT,
        @nDispositivoUsuarioId = @nDisp OUTPUT,
        @nEmpleadoId = @nEmp OUTPUT,
        @nModuloId = @nModulo OUTPUT,
        @gCorrelacionId = @gCorr OUTPUT,
        @gSolicitudId = @gSol OUTPUT,
        @cIp = @cIp OUTPUT,
        @cEndpoint = @cEnd OUTPUT,
        @bResultado = @bCtx OUTPUT,
        @cMensaje = @cMsg OUTPUT;

    IF @bCtx = 0
    BEGIN
        SET @cMensaje = @cMsg;
        GOTO __DESCO_Salida;
    END;

    SELECT @nId = pagoSocioId
    FROM OPENJSON(@cJson, '$.pago')
    WITH
    (
        pagoSocioId BIGINT '$.pagoSocioId'
    );

    SELECT
        @nLiq = P.liquidacion_socio_id,
        @dFechaPago = P.fecha_hora
    FROM [finanzas].[PagoSocio] P
    WHERE P.pago_socio_id = @nId
      AND P.estado = 1;

    IF @nLiq IS NULL
    BEGIN
        SET @cMensaje = N'El pago seleccionado no está disponible.';
        GOTO __DESCO_Salida;
    END;

    EXEC [finanzas].[PA_Liquidacion_Sel_SaldoPendienteInterno]
        @nLiquidacionSocioId = @nLiq,
        @nImporteNeto = @nNeto OUTPUT,
        @nTotalPagado = @nPagadoActual OUTPUT,
        @nSaldoPendiente = @nSaldoActual OUTPUT;

    SELECT
        @nConfirmadoHastaPago = COALESCE(SUM(P2.importe), 0)
    FROM [finanzas].[PagoSocio] P2
    WHERE P2.liquidacion_socio_id = @nLiq
      AND P2.estado = 1
      AND P2.estado_proceso = 'CONFIRMADO'
      AND
      (
          P2.fecha_hora < @dFechaPago
          OR
          (
              P2.fecha_hora = @dFechaPago
              AND P2.pago_socio_id <= @nId
          )
      );

    SET @nSaldoPosteriorPago =
        CASE
            WHEN @nNeto - @nConfirmadoHastaPago < 0 THEN 0
            ELSE @nNeto - @nConfirmadoHastaPago
        END;

    SELECT
        P.pago_socio_id AS pagoSocioId,
        P.liquidacion_socio_id AS liquidacionSocioId,
        P.fecha_hora AS fechaHora,
        P.importe,
        P.medio_pago AS medioPago,
        P.numero_operacion AS numeroOperacion,
        P.estado_proceso AS estadoProceso,
        P.estado,
        @nNeto AS importeNeto,
        @nConfirmadoHastaPago AS totalConfirmadoHastaPago,
        @nSaldoPosteriorPago AS saldoPosteriorPago,
        @nPagadoActual AS totalPagadoActual,
        @nSaldoActual AS saldoPendienteActual,
        @nSaldoActual AS saldoPendiente
    FROM [finanzas].[PagoSocio] P
    WHERE P.pago_socio_id = @nId;

    SET @bResultado = 1;
    SET @cMensaje = N'Pago consultado correctamente.';

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
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'finanzas.PA_PagoSocio_Sel_Detalle',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
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
IF ISNULL(@bResultado,0) = 1 OR NULLIF(@cMensaje,N'') IS NULL SET @cMensaje = N'La operación no se completó y sus cambios fueron revertidos.';
SET @bResultado = 0;
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
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'finanzas.PA_PagoSocio_Sel_Detalle',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bResultado,0) = 1
BEGIN
SET @bResultado = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'finanzas.PA_PagoSocio_Sel_Detalle',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
