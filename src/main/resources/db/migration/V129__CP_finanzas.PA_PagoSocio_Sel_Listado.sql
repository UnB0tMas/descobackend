IF OBJECT_ID(N'[finanzas].[PA_PagoSocio_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [finanzas].[PA_PagoSocio_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : finanzas.PA_PagoSocio_Sel_Listado
' Descripción             : Lista pago al socio.
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
    EXEC [finanzas].[PA_PagoSocio_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [finanzas].[PA_PagoSocio_Sel_Listado]
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
        @nLiq BIGINT,
        @cEstado VARCHAR(20),
        @nPagina INT = 1,
        @nTamano INT = 50,
        @nOffset INT;

    SELECT
        @bResultado = 0,
        @cMensaje = N'No se pudieron consultar los pagos.';

    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
        @cJson = @cJson,
        @cCodigoPermiso = 'PAGOS_LISTAR',
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

    SELECT
        @nLiq = liquidacionSocioId,
        @cEstado = UPPER(NULLIF(LTRIM(RTRIM(estadoProceso)), ''))
    FROM OPENJSON(@cJson, '$.filtros')
    WITH
    (
        liquidacionSocioId BIGINT '$.liquidacionSocioId',
        estadoProceso VARCHAR(20) '$.estadoProceso'
    );

    SELECT
        @nPagina = COALESCE(pagina, 1),
        @nTamano = COALESCE(tamano, 50)
    FROM OPENJSON(@cJson, '$.paginacion')
    WITH
    (
        pagina INT '$.pagina',
        tamano INT '$.tamano'
    );

    IF @nPagina < 1 SET @nPagina = 1;
    IF @nTamano < 1 SET @nTamano = 50;
    IF @nTamano > 200 SET @nTamano = 200;

    SET @nOffset = (@nPagina - 1) * @nTamano;

    ;
WITH PagoBase AS
    (
        SELECT
            P.pago_socio_id,
            P.liquidacion_socio_id,
            P.fecha_hora,
            P.importe,
            P.medio_pago,
            P.numero_operacion,
            P.estado_proceso,
            L.importe_neto,
            PE.numero_documento,
            LTRIM
            (
                RTRIM
                (
                    CONCAT
                    (
                        COALESCE(PE.nombres, N''),
                        N' ',
                        COALESCE(PE.apellido_paterno, N''),
                        N' ',
                        COALESCE(PE.apellido_materno, N'')
                    )
                )
            ) AS socio_nombre,
            SUM
            (
                CASE
                    WHEN P.estado_proceso = 'CONFIRMADO' THEN P.importe
                    ELSE CONVERT(DECIMAL(19,4), 0)
                END
            )
            OVER
            (
                PARTITION BY P.liquidacion_socio_id
                ORDER BY P.fecha_hora, P.pago_socio_id
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS total_confirmado_hasta_pago
        FROM [finanzas].[PagoSocio] P
        INNER JOIN [finanzas].[LiquidacionSocio] L
            ON L.liquidacion_socio_id = P.liquidacion_socio_id
        INNER JOIN [comercial].[ParticipacionCampaniaSocio] PC
            ON PC.participacion_campania_socio_id = L.participacion_campania_socio_id
        INNER JOIN [org].[SocioAsociacion] SA
            ON SA.socio_asociacion_id = PC.socio_asociacion_id
        INNER JOIN [org].[Persona] PE
            ON PE.persona_id = SA.socio_id
        WHERE P.estado = 1
    )
    SELECT
        PB.pago_socio_id AS pagoSocioId,
        PB.liquidacion_socio_id AS liquidacionSocioId,
        PB.fecha_hora AS fechaHora,
        PB.importe,
        PB.medio_pago AS medioPago,
        PB.numero_operacion AS numeroOperacion,
        PB.estado_proceso AS estadoProceso,
        PB.importe_neto AS importeNeto,
        PB.numero_documento AS numeroDocumento,
        PB.socio_nombre AS socioNombre,
        CONVERT
        (
            DECIMAL(19,4),
            CASE
                WHEN PB.importe_neto - PB.total_confirmado_hasta_pago < 0 THEN 0
                ELSE PB.importe_neto - PB.total_confirmado_hasta_pago
            END
        ) AS saldoPosteriorPago,
        COUNT_BIG(*) OVER() AS totalRegistros
    FROM PagoBase PB
    WHERE (@nLiq IS NULL OR PB.liquidacion_socio_id = @nLiq)
      AND (@cEstado IS NULL OR PB.estado_proceso = @cEstado)
    ORDER BY PB.fecha_hora DESC, PB.pago_socio_id DESC
    OFFSET @nOffset ROWS
    FETCH NEXT @nTamano ROWS ONLY;

    SET @bResultado = 1;
    SET @cMensaje = N'Pagos consultados correctamente.';

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
    @cProcedimiento = N'finanzas.PA_PagoSocio_Sel_Listado',
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
    @cProcedimiento = N'finanzas.PA_PagoSocio_Sel_Listado',
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
FROM config.FN_RespuestaUsuario(N'finanzas.PA_PagoSocio_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
