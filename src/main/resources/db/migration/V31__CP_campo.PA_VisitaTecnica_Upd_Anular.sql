IF OBJECT_ID(N'[campo].[PA_VisitaTecnica_Upd_Anular]', N'P') IS NOT NULL
    DROP PROCEDURE [campo].[PA_VisitaTecnica_Upd_Anular];
GO

/******************************************************************************************************
' Nombre del PA           : campo.PA_VisitaTecnica_Upd_Anular
' Descripción             : Anula una visita técnica conforme a sus reglas de negocio.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Campo
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
    EXEC [campo].[PA_VisitaTecnica_Upd_Anular]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [campo].[PA_VisitaTecnica_Upd_Anular]
(
    @cJson NVARCHAR(MAX), @bResultado BIT OUTPUT, @cMensaje NVARCHAR(300) OUTPUT,
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
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,
            @gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
            @nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),
            @bFin BIT,@cMsgFin NVARCHAR(300),@nVisita BIGINT,@cMotivo NVARCHAR(500),@dFin DATETIME2(0),
            @cAnt NVARCHAR(MAX),@cPost NVARCHAR(MAX),@cIdent NVARCHAR(200),@nAud BIGINT,@nTrans BIGINT;
    SET @bResultado=0;
 SET @cMensaje=N'No se pudo anular la visita.';
    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente]
        @cJson,'VISITAS_RETIRAR','VISITA_ANULAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,
        @nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@nOp OUTPUT,@bRep OUTPUT,
        @cEstadoOp OUTPUT,@cIdRes OUTPUT,@cCodRes OUTPUT,@bIni OUTPUT,@cMsg OUTPUT;
    IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    IF @bRep=1 BEGIN IF @cEstadoOp='COMPLETADA' BEGIN SET @bResultado=1;
 SET @cMensaje=N'La solicitud ya fue procesada correctamente.';
 END ELSE SET @cMensaje=N'La solicitud ya se encuentra en proceso.';
 GOTO __DESCO_Salida;
 END;

    SELECT @nVisita=visitaTecnicaId,@cMotivo=NULLIF(LTRIM(RTRIM(motivo)),N''),@dFin=fechaHoraFin
    FROM OPENJSON(@cJson,'$.visita') WITH
    (visitaTecnicaId BIGINT '$.visitaTecnicaId',motivo NVARCHAR(500) '$.motivo',fechaHoraFin DATETIME2(0) '$.fechaHoraFin');
    IF @dFin IS NULL SET @dFin=SYSUTCDATETIME();
    IF @cMotivo IS NULL BEGIN SET @cMensaje=N'Indique el motivo de la anulación.';
 GOTO Fallar;
 END;
    IF NOT EXISTS(SELECT 1 FROM [campo].[VisitaTecnica] WHERE visita_tecnica_id=@nVisita AND estado=1 AND estado_proceso='INICIADA' AND @dFin>=fecha_hora_inicio)
    BEGIN SET @cMensaje=N'La visita ya no puede anularse.';
 GOTO Fallar;
 END;
    IF EXISTS(SELECT 1 FROM [campo].[EvaluacionAgronomica] WHERE visita_tecnica_id=@nVisita AND estado=1)
    BEGIN SET @cMensaje=N'La visita tiene información técnica registrada y no puede anularse directamente.';
 GOTO Fallar;
 END;

    BEGIN TRY
      BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
      SELECT @cAnt=(
          SELECT
              [visita_tecnica_id],
              [salida_participante_id],
              [predio_id],
              [fecha_hora_inicio],
              [fecha_hora_fin],
              CASE WHEN [posicion_inicio] IS NULL THEN NULL ELSE [posicion_inicio].STAsText() END AS [posicion_inicio_wkt],
              CASE WHEN [posicion_inicio] IS NULL THEN NULL ELSE [posicion_inicio].STSrid END AS [posicion_inicio_srid],
              [objetivo],
              [resumen],
              [recomendaciones],
              [estado_proceso],
              [estado]
          FROM [campo].[VisitaTecnica]
          WHERE [visita_tecnica_id]=@nVisita
          FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
      );
      UPDATE [campo].[VisitaTecnica] SET fecha_hora_fin=@dFin,estado_proceso='ANULADA'
      WHERE visita_tecnica_id=@nVisita AND estado=1 AND estado_proceso='INICIADA';
      SELECT @cPost=(
          SELECT
              [visita_tecnica_id],
              [salida_participante_id],
              [predio_id],
              [fecha_hora_inicio],
              [fecha_hora_fin],
              CASE WHEN [posicion_inicio] IS NULL THEN NULL ELSE [posicion_inicio].STAsText() END AS [posicion_inicio_wkt],
              CASE WHEN [posicion_inicio] IS NULL THEN NULL ELSE [posicion_inicio].STSrid END AS [posicion_inicio_srid],
              [objetivo],
              [resumen],
              [recomendaciones],
              [estado_proceso],
              [estado]
          FROM [campo].[VisitaTecnica]
          WHERE [visita_tecnica_id]=@nVisita
          FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
      );
      SET @cIdent=CONVERT(NVARCHAR(200),@nVisita);
      EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio]
          @nUsuario,@nSesion,@nDisp,@nModulo,'ANULAR','campo','VisitaTecnica',@cIdent,@cAnt,@cPost,@cMotivo,
          'estado_proceso','INICIADA','ANULADA',@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
      /* Confirmar datos e idempotencia juntos. */
      EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
          @nOp,'COMPLETADA','campo','VisitaTecnica',@cIdent,'VISITA_ANULADA',@bFin OUTPUT,@cMsgFin OUTPUT;
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
 SET @cMensaje=N'Visita anulada correctamente.';
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
 SET @cMensaje=N'No se pudo anular la visita. Intente nuevamente.';
 
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'campo.PA_VisitaTecnica_Upd_Anular',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;
Fallar:
    IF @nOp IS NOT NULL AND @bResultado=0
        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOp,'FALLIDA',NULL,NULL,NULL,'NO_PROCESADO',@bFin OUTPUT,@cMsgFin OUTPUT;

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
    @cProcedimiento = N'campo.PA_VisitaTecnica_Upd_Anular',
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
    @cProcedimiento = N'campo.PA_VisitaTecnica_Upd_Anular',
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
    @cProcedimiento = N'campo.PA_VisitaTecnica_Upd_Anular',
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
FROM config.FN_RespuestaUsuario(N'campo.PA_VisitaTecnica_Upd_Anular',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
