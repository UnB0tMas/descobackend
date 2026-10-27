IF OBJECT_ID(N'[sanidad].[PA_CasoFitosanitario_Upd_Cerrar]', N'P') IS NOT NULL
    DROP PROCEDURE [sanidad].[PA_CasoFitosanitario_Upd_Cerrar];
GO

/******************************************************************************************************
' Nombre del PA           : sanidad.PA_CasoFitosanitario_Upd_Cerrar
' Descripción             : Cierra un caso fitosanitario.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Sanidad
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
    EXEC [sanidad].[PA_CasoFitosanitario_Upd_Cerrar]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [sanidad].[PA_CasoFitosanitario_Upd_Cerrar]
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
        @nCaso BIGINT,@cAnt VARCHAR(20),@cMotivo NVARCHAR(500),@cIdent NVARCHAR(200),
        @nAud BIGINT,@nTrans BIGINT;

    SELECT @bResultado=0,@cMensaje=N'No se pudo cerrar el caso sanitario.';

    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente]
        @cJson=@cJson,
        @cCodigoPermiso='SANIDAD_CONFIRMAR',
        @cAmbito='SANIDAD_CASO_CERRAR',
        @nUsuarioId=@nUsuario OUTPUT,
        @nSesionUsuarioId=@nSesion OUTPUT,
        @nDispositivoUsuarioId=@nDisp OUTPUT,
        @nEmpleadoId=@nEmp OUTPUT,
        @nModuloId=@nModulo OUTPUT,
        @gCorrelacionId=@gCorr OUTPUT,
        @gSolicitudId=@gSol OUTPUT,
        @cIp=@cIp OUTPUT,
        @cEndpoint=@cEnd OUTPUT,
        @nOperacionIdempotenteId=@nOp OUTPUT,
        @bEsRepetida=@bRep OUTPUT,
        @cEstadoOperacion=@cEstadoOp OUTPUT,
        @cIdentificadorResultado=@cIdRes OUTPUT,
        @cCodigoResultado=@cCodRes OUTPUT,
        @bResultado=@bIni OUTPUT,
        @cMensaje=@cMsg OUTPUT;

    IF @bIni=0 AND @bRep=0
    BEGIN
        SET @cMensaje=@cMsg;
        GOTO __DESCO_Salida;
    END;

    IF @bRep=1
    BEGIN
        SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END;
        SET @cMensaje=CASE WHEN @cEstadoOp='COMPLETADA'
                           THEN N'La solicitud ya fue procesada correctamente.'
                           ELSE N'La solicitud ya se encuentra en proceso.' END;
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nCaso=casoFitosanitarioId,
        @cMotivo=NULLIF(LTRIM(RTRIM(motivo)),N'')
    FROM OPENJSON(@cJson,'$.caso')
    WITH
    (
        casoFitosanitarioId BIGINT '$.casoFitosanitarioId',
        motivo NVARCHAR(500) '$.motivo'
    );

    SELECT @cAnt=estado_caso
    FROM [sanidad].[CasoFitosanitario]
    WHERE caso_fitosanitario_id=@nCaso
      AND estado=1;

    IF @cAnt IS NULL
    BEGIN
        SET @cMensaje=N'El caso sanitario seleccionado no está disponible.';
        GOTO Fallar;
    END;

    IF @cAnt NOT IN('RECUPERADO','NO_RECUPERADO')
    BEGIN
        SET @cMensaje=N'Antes de cerrar el caso debe completar el seguimiento y registrar un resultado final.';
        GOTO Fallar;
    END;

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        UPDATE [sanidad].[CasoFitosanitario]
        SET estado_caso='CERRADO'
        WHERE caso_fitosanitario_id=@nCaso
          AND estado=1
          AND estado_caso=@cAnt;

        IF @@ROWCOUNT<>1
            THROW 54702,N'ESTADO_CIERRE_CONCURRENTE',1;

        SET @cIdent=CONVERT(NVARCHAR(200),@nCaso);

        EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio]
            @nUsuarioId=@nUsuario,
            @nSesionUsuarioId=@nSesion,
            @nDispositivoUsuarioId=@nDisp,
            @nModuloId=@nModulo,
            @cAccion='CERRAR',
            @cEsquemaEntidad='sanidad',
            @cNombreEntidad='CasoFitosanitario',
            @cIdentificador=@cIdent,
            @cDatosAnteriores=NULL,
            @cDatosPosteriores=NULL,
            @cMotivo=@cMotivo,
            @cCampoEstado='estado_caso',
            @cEstadoAnterior=@cAnt,
            @cEstadoNuevo='CERRADO',
            @cIp=@cIp,
            @gCorrelacionId=@gCorr,
            @gSolicitudId=@gSol,
            @cEndpoint=@cEnd,
            @nAuditoriaEventoId=@nAud OUTPUT,
            @nTransicionEstadoId=@nTrans OUTPUT;

        /* Confirmar datos e idempotencia juntos. */

        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
            @nOperacionIdempotenteId=@nOp,
            @cEstadoOperacion='COMPLETADA',
            @cEsquemaEntidad='sanidad',
            @cNombreEntidad='CasoFitosanitario',
            @cIdentificadorResultado=@cIdent,
            @cCodigoResultado='CASO_CERRADO',
            @bResultado=@bFin OUTPUT,
            @cMensaje=@cMsgFin OUTPUT;
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
        SET @cMensaje=N'Caso sanitario cerrado correctamente.';
        GOTO __DESCO_Salida;
    END TRY
    BEGIN CATCH
SET @bResultado = 0;

        IF XACT_STATE()<>0 BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
        IF ERROR_MESSAGE()=N'ESTADO_CIERRE_CONCURRENTE'
            SET @cMensaje=N'El caso cambió mientras se procesaba la solicitud. Actualice la información e intente nuevamente.';
        ELSE
            SET @cMensaje=N'No se pudo cerrar el caso sanitario. Intente nuevamente.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'sanidad.PA_CasoFitosanitario_Upd_Cerrar',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;

Fallar:
    IF @nOp IS NOT NULL AND @bResultado=0
        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
            @nOperacionIdempotenteId=@nOp,
            @cEstadoOperacion='FALLIDA',
            @cEsquemaEntidad=NULL,
            @cNombreEntidad=NULL,
            @cIdentificadorResultado=NULL,
            @cCodigoResultado='NO_PROCESADO',
            @bResultado=@bFin OUTPUT,
            @cMensaje=@cMsgFin OUTPUT;

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
    @cProcedimiento = N'sanidad.PA_CasoFitosanitario_Upd_Cerrar',
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
    @cProcedimiento = N'sanidad.PA_CasoFitosanitario_Upd_Cerrar',
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
    @cProcedimiento = N'sanidad.PA_CasoFitosanitario_Upd_Cerrar',
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
FROM config.FN_RespuestaUsuario(N'sanidad.PA_CasoFitosanitario_Upd_Cerrar',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
