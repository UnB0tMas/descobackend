IF OBJECT_ID(N'[campo].[PA_EvaluacionAgronomica_Upd_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [campo].[PA_EvaluacionAgronomica_Upd_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : campo.PA_EvaluacionAgronomica_Upd_Registro
' Descripción             : Actualiza una evaluación agronómica existente.
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
    EXEC [campo].[PA_EvaluacionAgronomica_Upd_Registro]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [campo].[PA_EvaluacionAgronomica_Upd_Registro]
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
            @bFin BIT,@cMsgFin NVARCHAR(300),@nEval BIGINT,@nCultivo BIGINT,@nTipo SMALLINT,@dFecha DATETIME2(0),
            @cResultadoEval NVARCHAR(600),@cObservacion NVARCHAR(400),@nPorcentaje DECIMAL(5,2),@nMuestras SMALLINT,
            @bMateriaPresente BIT=0,@nVisita BIGINT,@nPredioVisita BIGINT,@dInicioVisitaEdit DATETIME2(0),@cAnt NVARCHAR(MAX),@cPost NVARCHAR(MAX),
            @cIdent NVARCHAR(200),@nAud BIGINT,@nTrans BIGINT;
    SET @bResultado=0;
 SET @cMensaje=N'No se pudo actualizar la evaluación.';
    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente]
        @cJson,'EVALUACIONES_EDITAR','EVALUACION_EDITAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,
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

    SELECT @nEval=evaluacionAgronomicaId,@nCultivo=parcelaCultivoId,@nTipo=tipoEvaluacionId,@dFecha=fechaHora,
           @cResultadoEval=NULLIF(LTRIM(RTRIM(resultado)),N''),@cObservacion=NULLIF(LTRIM(RTRIM(observacion)),N'')
    FROM OPENJSON(@cJson,'$.evaluacion') WITH
    (evaluacionAgronomicaId BIGINT '$.evaluacionAgronomicaId',parcelaCultivoId BIGINT '$.parcelaCultivoId',
     tipoEvaluacionId SMALLINT '$.tipoEvaluacionId',fechaHora DATETIME2(0) '$.fechaHora',
     resultado NVARCHAR(600) '$.resultado',observacion NVARCHAR(400) '$.observacion');
    SET @bMateriaPresente=CASE WHEN JSON_QUERY(@cJson,'$.materiaSeca') IS NULL THEN 0 ELSE 1 END;
    IF @bMateriaPresente=1
      SELECT @nPorcentaje=porcentajeMateriaSeca,@nMuestras=numeroMuestras FROM OPENJSON(@cJson,'$.materiaSeca') WITH
      (porcentajeMateriaSeca DECIMAL(5,2) '$.porcentajeMateriaSeca',numeroMuestras SMALLINT '$.numeroMuestras');
    SELECT @nVisita=EA.visita_tecnica_id,@nPredioVisita=V.predio_id,@dInicioVisitaEdit=V.fecha_hora_inicio
    FROM [campo].[EvaluacionAgronomica] EA INNER JOIN [campo].[VisitaTecnica] V ON V.visita_tecnica_id=EA.visita_tecnica_id
    WHERE EA.evaluacion_agronomica_id=@nEval AND EA.estado=1 AND V.estado=1 AND V.estado_proceso='INICIADA';
    IF @nVisita IS NULL BEGIN SET @cMensaje=N'Solo las evaluaciones de una visita en curso pueden modificarse.';
 GOTO Fallar;
 END;
    IF @dFecha IS NOT NULL AND (@dFecha<@dInicioVisitaEdit OR @dFecha>SYSUTCDATETIME()) BEGIN SET @cMensaje=N'La fecha de la evaluación no corresponde al periodo de la visita.';
 GOTO Fallar;
 END;
    IF @nTipo IS NULL OR NOT EXISTS(SELECT 1 FROM [campo].[TipoEvaluacion] WHERE tipo_evaluacion_id=@nTipo AND estado=1)
    BEGIN SET @cMensaje=N'El tipo de evaluación seleccionado no está disponible.';
 GOTO Fallar;
 END;
    IF @nCultivo IS NOT NULL AND NOT EXISTS
       (SELECT 1 FROM [prod].[ParcelaCultivo] PC INNER JOIN [prod].[Parcela] PA ON PA.parcela_id=PC.parcela_id
        WHERE PC.parcela_cultivo_id=@nCultivo AND PC.estado=1 AND PA.estado=1 AND PA.predio_id=@nPredioVisita)
    BEGIN SET @cMensaje=N'El cultivo seleccionado no corresponde al predio de la visita.';
 GOTO Fallar;
 END;
    IF @bMateriaPresente=1 AND (@nPorcentaje IS NULL OR @nMuestras IS NULL OR @nPorcentaje<0 OR @nPorcentaje>100 OR @nMuestras<=0)
    BEGIN SET @cMensaje=N'Complete correctamente los datos de materia seca.';
 GOTO Fallar;
 END;

    BEGIN TRY
      BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
      SELECT @cAnt=(SELECT EA.*,(SELECT EMS.porcentaje_materia_seca,EMS.numero_muestras,EMS.estado FROM [campo].[EvaluacionMateriaSeca] EMS WHERE EMS.evaluacion_materia_seca_id=EA.evaluacion_agronomica_id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) materiaSeca FROM [campo].[EvaluacionAgronomica] EA WHERE EA.evaluacion_agronomica_id=@nEval FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
      UPDATE [campo].[EvaluacionAgronomica]
      SET parcela_cultivo_id=@nCultivo,tipo_evaluacion_id=@nTipo,fecha_hora=COALESCE(@dFecha,fecha_hora),resultado=@cResultadoEval,observacion=@cObservacion
      WHERE evaluacion_agronomica_id=@nEval AND estado=1;
      IF @bMateriaPresente=1
      BEGIN
        IF EXISTS(SELECT 1 FROM [campo].[EvaluacionMateriaSeca] WHERE evaluacion_materia_seca_id=@nEval)
          UPDATE [campo].[EvaluacionMateriaSeca] SET porcentaje_materia_seca=@nPorcentaje,numero_muestras=@nMuestras,estado=1 WHERE evaluacion_materia_seca_id=@nEval;
        ELSE
          INSERT [campo].[EvaluacionMateriaSeca](evaluacion_materia_seca_id,porcentaje_materia_seca,numero_muestras) VALUES(@nEval,@nPorcentaje,@nMuestras);
      END;
      SELECT @cPost=(SELECT EA.*,(SELECT EMS.porcentaje_materia_seca,EMS.numero_muestras,EMS.estado FROM [campo].[EvaluacionMateriaSeca] EMS WHERE EMS.evaluacion_materia_seca_id=EA.evaluacion_agronomica_id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) materiaSeca FROM [campo].[EvaluacionAgronomica] EA WHERE EA.evaluacion_agronomica_id=@nEval FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
      SET @cIdent=CONVERT(NVARCHAR(200),@nEval);
      EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio]
          @nUsuario,@nSesion,@nDisp,@nModulo,'EDITAR','campo','EvaluacionAgronomica',@cIdent,@cAnt,@cPost,NULL,NULL,NULL,NULL,
          @cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
      /* Confirmar datos e idempotencia juntos. */
      EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
          @nOp,'COMPLETADA','campo','EvaluacionAgronomica',@cIdent,'EVALUACION_ACTUALIZADA',@bFin OUTPUT,@cMsgFin OUTPUT;
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
 SET @cMensaje=N'Evaluación actualizada correctamente.';
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
 SET @cMensaje=N'No se pudo actualizar la evaluación. Intente nuevamente.';
 
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'campo.PA_EvaluacionAgronomica_Upd_Registro',
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
    @cProcedimiento = N'campo.PA_EvaluacionAgronomica_Upd_Registro',
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
    @cProcedimiento = N'campo.PA_EvaluacionAgronomica_Upd_Registro',
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
    @cProcedimiento = N'campo.PA_EvaluacionAgronomica_Upd_Registro',
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
FROM config.FN_RespuestaUsuario(N'campo.PA_EvaluacionAgronomica_Upd_Registro',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
