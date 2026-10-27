IF OBJECT_ID(N'[prod].[PA_DisponibilidadProduccion_Ins_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [prod].[PA_DisponibilidadProduccion_Ins_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : prod.PA_DisponibilidadProduccion_Ins_Registro
' Descripción             : Registra disponibilidades de producción.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Producción
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
        @nDisponibilidadProduccionId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [prod].[PA_DisponibilidadProduccion_Ins_Registro]
        @cJson = N'{}',
        @nDisponibilidadProduccionId = @nDisponibilidadProduccionId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nDisponibilidadProduccionId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [prod].[PA_DisponibilidadProduccion_Ins_Registro]
(
    @cJson NVARCHAR(MAX),
    @nDisponibilidadProduccionId BIGINT OUTPUT,
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
    SET ANSI_NULLS ON;
    SET ANSI_PADDING ON;
    SET ANSI_WARNINGS ON;
    SET ARITHABORT ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET NUMERIC_ROUNDABORT OFF;

    BEGIN TRY

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,
        @gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
        @nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),
        @bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),
        @nPC BIGINT,@nVisita BIGINT,@nPredioCultivo BIGINT,@nPredioVisita BIGINT,
        @dFecha DATETIME2(0),@dDesde DATE,@dHasta DATE,@nKg DECIMAL(14,3),@cObs NVARCHAR(400),
        @cIdent NVARCHAR(200),@cPost NVARCHAR(MAX),@nAud BIGINT,@nTrans BIGINT;

    SELECT
        @nDisponibilidadProduccionId=NULL,
        @bResultado=0,
        @cMensaje=N'No se pudo registrar la estimación de producción.';

    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente]
        @cJson,'PRODUCCION_CREAR','PRODUCCION_ESTIMAR',
        @nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,
        @gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@nOp OUTPUT,@bRep OUTPUT,
        @cEstadoOp OUTPUT,@cIdRes OUTPUT,@cCodRes OUTPUT,@bIni OUTPUT,@cMsg OUTPUT;

    IF @bIni=0 AND @bRep=0
    BEGIN
        SET @cMensaje=@cMsg;
        GOTO __DESCO_Salida;
    END;

    IF @bRep=1
    BEGIN
        IF @cEstadoOp='COMPLETADA'
        BEGIN
            SET @nDisponibilidadProduccionId=TRY_CONVERT(BIGINT,@cIdRes);
            SET @bResultado=1;
            SET @cMensaje=N'La solicitud ya fue procesada correctamente.';
        END
        ELSE
            SET @cMensaje=N'La solicitud ya se encuentra en proceso.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nPC=parcelaCultivoId,
        @nVisita=visitaTecnicaId,
        @dFecha=fechaEstimacion,
        @dDesde=disponibleDesde,
        @dHasta=disponibleHasta,
        @nKg=cantidadEstimadaKg,
        @cObs=NULLIF(LTRIM(RTRIM(observacion)),N'')
    FROM OPENJSON(@cJson,'$.produccion')
    WITH
    (
        parcelaCultivoId BIGINT '$.parcelaCultivoId',
        visitaTecnicaId BIGINT '$.visitaTecnicaId',
        fechaEstimacion DATETIME2(0) '$.fechaEstimacion',
        disponibleDesde DATE '$.disponibleDesde',
        disponibleHasta DATE '$.disponibleHasta',
        cantidadEstimadaKg DECIMAL(14,3) '$.cantidadEstimadaKg',
        observacion NVARCHAR(400) '$.observacion'
    );

    IF @dFecha IS NULL
        SET @dFecha=SYSUTCDATETIME();

    IF @nPC IS NULL
       OR @dDesde IS NULL
       OR @nKg IS NULL
       OR @nKg<0
       OR (@dHasta IS NOT NULL AND @dHasta<@dDesde)
    BEGIN
        SET @cMensaje=N'Complete correctamente los datos de la estimación.';
        GOTO Fallar;
    END;

    IF @dFecha>SYSUTCDATETIME()
    BEGIN
        SET @cMensaje=N'La fecha de la estimación no puede estar en el futuro.';
        GOTO Fallar;
    END;

    SELECT @nPredioCultivo=P.predio_id
    FROM [prod].[ParcelaCultivo] PC
    INNER JOIN [prod].[Parcela] P
        ON P.parcela_id=PC.parcela_id
       AND P.estado=1
    WHERE PC.parcela_cultivo_id=@nPC
      AND PC.estado=1
      AND PC.situacion_cultivo='ACTIVO';

    IF @nPredioCultivo IS NULL
    BEGIN
        SET @cMensaje=N'El cultivo seleccionado no está disponible.';
        GOTO Fallar;
    END;

    IF @nVisita IS NOT NULL
    BEGIN
        SELECT @nPredioVisita=V.predio_id
        FROM [campo].[VisitaTecnica] V
        WHERE V.visita_tecnica_id=@nVisita
          AND V.estado=1;

        IF @nPredioVisita IS NULL
        BEGIN
            SET @cMensaje=N'La visita indicada como origen no está disponible.';
            GOTO Fallar;
        END;

        IF @nPredioVisita<>@nPredioCultivo
        BEGIN
            SET @cMensaje=N'La visita indicada no corresponde al predio de esta producción.';
            GOTO Fallar;
        END;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM [prod].[DisponibilidadProduccion]
        WHERE parcela_cultivo_id=@nPC
          AND fecha_estimacion=@dFecha
    )
    BEGIN
        SET @cMensaje=N'Ya existe una estimación registrada para esa fecha.';
        GOTO Fallar;
    END;

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        INSERT [prod].[DisponibilidadProduccion]
        (
            parcela_cultivo_id,
            visita_tecnica_id,
            fecha_estimacion,
            disponible_desde,
            disponible_hasta,
            cantidad_estimada_kg,
            estado_estimacion,
            observacion,
            estado
        )
        VALUES
        (
            @nPC,@nVisita,@dFecha,@dDesde,@dHasta,@nKg,'ESTIMADA',@cObs,1
        );

        SET @nDisponibilidadProduccionId=CONVERT(BIGINT,SCOPE_IDENTITY());
        SET @cIdent=CONVERT(NVARCHAR(200),@nDisponibilidadProduccionId);

        SELECT @cPost=
        (
            SELECT
                @nDisponibilidadProduccionId disponibilidadProduccionId,
                @nPC parcelaCultivoId,
                @nVisita visitaTecnicaId,
                CASE WHEN @nVisita IS NULL THEN N'Estimación directa' ELSE N'Visita técnica' END origenEstimacion,
                @dDesde disponibleDesde,
                @dHasta disponibleHasta,
                @nKg cantidadEstimadaKg,
                'ESTIMADA' estadoEstimacion
            FOR JSON PATH,WITHOUT_ARRAY_WRAPPER
        );

        EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio]
            @nUsuario,@nSesion,@nDisp,@nModulo,'CREAR','prod','DisponibilidadProduccion',
            @cIdent,NULL,@cPost,NULL,'estado_estimacion',NULL,'ESTIMADA',
            @cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;

        /* Confirmar datos e idempotencia juntos. */

        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
            @nOp,'COMPLETADA','prod','DisponibilidadProduccion',@cIdent,
            'PRODUCCION_ESTIMADA',@bFin OUTPUT,@cMsgFin OUTPUT;
IF ISNULL(@bFin,0) = 0
    THROW 51003, N'DESCO_IDEMPOTENCIA_NO_CERRADA', 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;

        SET @bResultado=1;
        SET @cMensaje=N'Estimación de producción registrada correctamente.';
        GOTO __DESCO_Salida;
    END TRY
    BEGIN CATCH
SET @bResultado = 0;

        IF XACT_STATE()<>0
            BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;

        SET @cMensaje=N'No se pudo registrar la estimación. Intente nuevamente.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'prod.PA_DisponibilidadProduccion_Ins_Registro',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;

Fallar:
    IF @nOp IS NOT NULL AND @bResultado=0
        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
            @nOp,'FALLIDA',NULL,NULL,NULL,'NO_PROCESADO',@bFin OUTPUT,@cMsgFin OUTPUT;

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
    @cProcedimiento = N'prod.PA_DisponibilidadProduccion_Ins_Registro',
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

    IF @bResultado = 0 AND @nOp IS NOT NULL AND XACT_STATE() <> -1
    BEGIN
        IF ISNULL(@bRep,0) = 0
        BEGIN
        BEGIN TRY
            EXEC [auditoria].[PA_OperacionIdempotente_Upd_MensajeFallido]
                 @nOperacionIdempotenteId = @nOp, @cMensajeResultado = @cMensaje;
        END TRY
        BEGIN CATCH
            -- No sustituir el motivo funcional por un fallo de registro secundario.
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'prod.PA_DisponibilidadProduccion_Ins_Registro',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
        END CATCH;
        END
        ELSE
        BEGIN
            SELECT @cMensaje = COALESCE(mensaje_resultado,
                CASE WHEN estado_operacion = 'FALLIDA'
                     THEN N'La solicitud anterior no se completó. Corrija los datos y envíe una nueva solicitud.'
                     ELSE N'La solicitud todavía se está procesando. Consulte el resultado antes de repetirla.' END)
            FROM [auditoria].[OperacionIdempotente]
            WHERE operacion_idempotente_id = @nOp;
        END;
    END;
IF @bResultado = 0
    SELECT @nDisponibilidadProduccionId = NULL;

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
    @cProcedimiento = N'prod.PA_DisponibilidadProduccion_Ins_Registro',
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
FROM config.FN_RespuestaUsuario(N'prod.PA_DisponibilidadProduccion_Ins_Registro',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
