IF OBJECT_ID(N'[campo].[PA_EvaluacionAgronomica_Ins_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [campo].[PA_EvaluacionAgronomica_Ins_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : campo.PA_EvaluacionAgronomica_Ins_Registro
' Descripción             : Registra una evaluación agronómica asociada a la actividad de campo.
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
        @nEvaluacionAgronomicaId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [campo].[PA_EvaluacionAgronomica_Ins_Registro]
        @cJson = N'{}',
        @nEvaluacionAgronomicaId = @nEvaluacionAgronomicaId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nEvaluacionAgronomicaId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [campo].[PA_EvaluacionAgronomica_Ins_Registro]
(
    @cJson NVARCHAR(MAX), @nEvaluacionAgronomicaId BIGINT OUTPUT,
    @bResultado BIT OUTPUT, @cMensaje NVARCHAR(300) OUTPUT,
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
            @bFin BIT,@cMsgFin NVARCHAR(300),@nVisita BIGINT,@nCultivo BIGINT,@nTipo SMALLINT,@dFecha DATETIME2(0),
            @cResultadoEval NVARCHAR(600),@cObservacion NVARCHAR(400),@nPorcentaje DECIMAL(5,2),@nMuestras SMALLINT,
            @nPredioVisita BIGINT,@dInicioVisita DATETIME2(0),@cPost NVARCHAR(MAX),@cIdent NVARCHAR(200),@nAud BIGINT,@nTrans BIGINT;
    SELECT @nEvaluacionAgronomicaId=NULL,@bResultado=0,@cMensaje=N'No se pudo registrar la evaluación.';
    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente]
        @cJson,'EVALUACIONES_CREAR','EVALUACION_REGISTRAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,
        @nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@nOp OUTPUT,@bRep OUTPUT,
        @cEstadoOp OUTPUT,@cIdRes OUTPUT,@cCodRes OUTPUT,@bIni OUTPUT,@cMsg OUTPUT;
    IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    IF @bRep=1 BEGIN IF @cEstadoOp='COMPLETADA' BEGIN SET @nEvaluacionAgronomicaId=TRY_CONVERT(BIGINT,@cIdRes);
 SET @bResultado=1;
 SET @cMensaje=N'La solicitud ya fue procesada correctamente.';
 END ELSE SET @cMensaje=N'La solicitud ya se encuentra en proceso.';
 GOTO __DESCO_Salida;
 END;

    SELECT @nVisita=visitaTecnicaId,@nCultivo=parcelaCultivoId,@nTipo=tipoEvaluacionId,@dFecha=fechaHora,
           @cResultadoEval=NULLIF(LTRIM(RTRIM(resultado)),N''),@cObservacion=NULLIF(LTRIM(RTRIM(observacion)),N'')
    FROM OPENJSON(@cJson,'$.evaluacion') WITH
    (visitaTecnicaId BIGINT '$.visitaTecnicaId',parcelaCultivoId BIGINT '$.parcelaCultivoId',
     tipoEvaluacionId SMALLINT '$.tipoEvaluacionId',fechaHora DATETIME2(0) '$.fechaHora',
     resultado NVARCHAR(600) '$.resultado',observacion NVARCHAR(400) '$.observacion');
    SELECT @nPorcentaje=porcentajeMateriaSeca,@nMuestras=numeroMuestras
    FROM OPENJSON(@cJson,'$.materiaSeca') WITH
    (porcentajeMateriaSeca DECIMAL(5,2) '$.porcentajeMateriaSeca',numeroMuestras SMALLINT '$.numeroMuestras');
    IF @dFecha IS NULL SET @dFecha=SYSUTCDATETIME();
    IF @nVisita IS NULL OR @nTipo IS NULL BEGIN SET @cMensaje=N'Seleccione la visita y el tipo de evaluación.';
 GOTO Fallar;
 END;
    SELECT @nPredioVisita=predio_id,@dInicioVisita=fecha_hora_inicio FROM [campo].[VisitaTecnica]
    WHERE visita_tecnica_id=@nVisita AND estado=1 AND estado_proceso='INICIADA';
    IF @nPredioVisita IS NULL BEGIN SET @cMensaje=N'La visita debe estar en curso para registrar evaluaciones.';
 GOTO Fallar;
 END;
    IF @dFecha<@dInicioVisita OR @dFecha>SYSUTCDATETIME() BEGIN SET @cMensaje=N'La fecha de la evaluación no corresponde al periodo de la visita.';
 GOTO Fallar;
 END;
    IF NOT EXISTS(SELECT 1 FROM [campo].[TipoEvaluacion] WHERE tipo_evaluacion_id=@nTipo AND estado=1)
    BEGIN SET @cMensaje=N'El tipo de evaluación seleccionado no está disponible.';
 GOTO Fallar;
 END;
    IF @nCultivo IS NOT NULL AND NOT EXISTS
       (SELECT 1 FROM [prod].[ParcelaCultivo] PC INNER JOIN [prod].[Parcela] PA ON PA.parcela_id=PC.parcela_id
        WHERE PC.parcela_cultivo_id=@nCultivo AND PC.estado=1 AND PA.estado=1 AND PA.predio_id=@nPredioVisita)
    BEGIN SET @cMensaje=N'El cultivo seleccionado no corresponde al predio de la visita.';
 GOTO Fallar;
 END;
    IF (@nPorcentaje IS NULL AND @nMuestras IS NOT NULL) OR (@nPorcentaje IS NOT NULL AND @nMuestras IS NULL)
       OR @nPorcentaje<0 OR @nPorcentaje>100 OR @nMuestras<=0
    BEGIN SET @cMensaje=N'Los datos de materia seca no son válidos.';
 GOTO Fallar;
 END;

    BEGIN TRY
      BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
      INSERT [campo].[EvaluacionAgronomica](visita_tecnica_id,parcela_cultivo_id,tipo_evaluacion_id,fecha_hora,resultado,observacion)
      VALUES(@nVisita,@nCultivo,@nTipo,@dFecha,@cResultadoEval,@cObservacion);
      SET @nEvaluacionAgronomicaId=CONVERT(BIGINT,SCOPE_IDENTITY());
      IF @nPorcentaje IS NOT NULL
        INSERT [campo].[EvaluacionMateriaSeca](evaluacion_materia_seca_id,porcentaje_materia_seca,numero_muestras)
        VALUES(@nEvaluacionAgronomicaId,@nPorcentaje,@nMuestras);
      SET @cIdent=CONVERT(NVARCHAR(200),@nEvaluacionAgronomicaId);
      SELECT @cPost=(SELECT EA.*,(SELECT EMS.porcentaje_materia_seca,EMS.numero_muestras FROM [campo].[EvaluacionMateriaSeca] EMS WHERE EMS.evaluacion_materia_seca_id=EA.evaluacion_agronomica_id AND EMS.estado=1 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) materiaSeca
                     FROM [campo].[EvaluacionAgronomica] EA WHERE EA.evaluacion_agronomica_id=@nEvaluacionAgronomicaId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
      EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio]
          @nUsuario,@nSesion,@nDisp,@nModulo,'REGISTRAR','campo','EvaluacionAgronomica',@cIdent,NULL,@cPost,NULL,NULL,NULL,NULL,
          @cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
      /* Confirmar datos e idempotencia juntos. */
      EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
          @nOp,'COMPLETADA','campo','EvaluacionAgronomica',@cIdent,'EVALUACION_REGISTRADA',@bFin OUTPUT,@cMsgFin OUTPUT;
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
 SET @cMensaje=N'Evaluación registrada correctamente.';
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
 SET @cMensaje=N'No se pudo registrar la evaluación. Intente nuevamente.';
 
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'campo.PA_EvaluacionAgronomica_Ins_Registro',
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
    @cProcedimiento = N'campo.PA_EvaluacionAgronomica_Ins_Registro',
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
    @cProcedimiento = N'campo.PA_EvaluacionAgronomica_Ins_Registro',
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
    SELECT @nEvaluacionAgronomicaId = NULL;

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
    @cProcedimiento = N'campo.PA_EvaluacionAgronomica_Ins_Registro',
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
FROM config.FN_RespuestaUsuario(N'campo.PA_EvaluacionAgronomica_Ins_Registro',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
