IF OBJECT_ID(N'[campo].[PA_VisitaTecnica_Ins_Iniciar]', N'P') IS NOT NULL
    DROP PROCEDURE [campo].[PA_VisitaTecnica_Ins_Iniciar];
GO

/******************************************************************************************************
' Nombre del PA           : campo.PA_VisitaTecnica_Ins_Iniciar
' Descripción             : Inicia el registro de una visita técnica.
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
        @nVisitaTecnicaId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [campo].[PA_VisitaTecnica_Ins_Iniciar]
        @cJson = N'{}',
        @nVisitaTecnicaId = @nVisitaTecnicaId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nVisitaTecnicaId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [campo].[PA_VisitaTecnica_Ins_Iniciar]
(
    @cJson NVARCHAR(MAX), @nVisitaTecnicaId BIGINT OUTPUT,
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
            @bFin BIT,@cMsgFin NVARCHAR(300),@nPart BIGINT,@nPredio BIGINT,@dInicio DATETIME2(0),
            @nLat DECIMAL(9,6),@nLon DECIMAL(9,6),@cObjetivo NVARCHAR(250),@nSalida BIGINT,@nEmpleadoPart BIGINT,
            @cEstadoSalida VARCHAR(20),@gSesionPublica UNIQUEIDENTIFIER,@bAdmin BIT=0,@cPost NVARCHAR(MAX),@cIdent NVARCHAR(200),
            @nAud BIGINT,@nTrans BIGINT,@nAudSalida BIGINT,@nTransSalida BIGINT;

    SELECT @nVisitaTecnicaId=NULL,@bResultado=0,@cMensaje=N'No se pudo iniciar la visita.';
    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente]
        @cJson,'VISITAS_EDITAR','VISITA_INICIAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,
        @nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@nOp OUTPUT,@bRep OUTPUT,
        @cEstadoOp OUTPUT,@cIdRes OUTPUT,@cCodRes OUTPUT,@bIni OUTPUT,@cMsg OUTPUT;
    IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    IF @bRep=1 BEGIN IF @cEstadoOp='COMPLETADA' BEGIN SET @nVisitaTecnicaId=TRY_CONVERT(BIGINT,@cIdRes);
 SET @bResultado=1;
 SET @cMensaje=N'La solicitud ya fue procesada correctamente.';
 END ELSE SET @cMensaje=N'La solicitud ya se encuentra en proceso.';
 GOTO __DESCO_Salida;
 END;

    SELECT @nPart=salidaParticipanteId,@nPredio=predioId,@dInicio=fechaHoraInicio,
           @nLat=latitud,@nLon=longitud,@cObjetivo=NULLIF(LTRIM(RTRIM(objetivo)),N'')
    FROM OPENJSON(@cJson,'$.visita') WITH
    (salidaParticipanteId BIGINT '$.salidaParticipanteId',predioId BIGINT '$.predioId',
     fechaHoraInicio DATETIME2(0) '$.fechaHoraInicio',latitud DECIMAL(9,6) '$.latitud',
     longitud DECIMAL(9,6) '$.longitud',objetivo NVARCHAR(250) '$.objetivo');
    IF @dInicio IS NULL SET @dInicio=SYSUTCDATETIME();
    SELECT @gSesionPublica=sesionPublicaId FROM OPENJSON(@cJson,'$.contexto') WITH (sesionPublicaId UNIQUEIDENTIFIER '$.sesionPublicaId');

    IF @nPart IS NULL OR @nPredio IS NULL BEGIN SET @cMensaje=N'Seleccione la salida y el predio de la visita.';
 GOTO Fallar;
 END;
    IF (@nLat IS NULL AND @nLon IS NOT NULL) OR (@nLat IS NOT NULL AND @nLon IS NULL) OR @nLat NOT BETWEEN -90 AND 90 OR @nLon NOT BETWEEN -180 AND 180
    BEGIN SET @cMensaje=N'La ubicación indicada no es válida.';
 GOTO Fallar;
 END;

    SELECT @nSalida=SP.salida_campo_id,@nEmpleadoPart=SP.empleado_id,@cEstadoSalida=SC.estado_proceso
    FROM [campo].[SalidaParticipante] SP
    INNER JOIN [campo].[SalidaCampo] SC ON SC.salida_campo_id=SP.salida_campo_id
    WHERE SP.salida_participante_id=@nPart AND SP.estado=1 AND SC.estado=1;
    IF @nSalida IS NULL OR @cEstadoSalida IS NULL OR @cEstadoSalida NOT IN('PROGRAMADA','EN_CURSO') BEGIN SET @cMensaje=N'La salida seleccionada no está disponible para iniciar visitas.';
 GOTO Fallar;
 END;
    IF NOT EXISTS(SELECT 1 FROM [prod].[Predio] WHERE predio_id=@nPredio AND estado=1) BEGIN SET @cMensaje=N'El predio seleccionado no está disponible.';
 GOTO Fallar;
 END;

    IF @nEmpleadoPart<>@nEmp
    BEGIN
        EXEC [seg].[PA_Autorizacion_Sel_ValidarPermiso] @nUsuario,@gSesionPublica,'VISITAS_ADMINISTRAR',@bAdmin OUTPUT;
        IF @bAdmin=0 BEGIN SET @cMensaje=N'La visita debe ser iniciada por el participante asignado.';
 GOTO Fallar;
 END;
    END;

    IF EXISTS(SELECT 1 FROM [campo].[VisitaTecnica] WHERE salida_participante_id=@nPart AND predio_id=@nPredio AND estado=1 AND estado_proceso='INICIADA')
    BEGIN SET @cMensaje=N'Ya existe una visita en curso para este participante y predio.';
 GOTO Fallar;
 END;

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        IF @cEstadoSalida='PROGRAMADA'
        BEGIN
            UPDATE [campo].[SalidaCampo]
            SET fecha_hora_salida_real=COALESCE(fecha_hora_salida_real,@dInicio),estado_proceso='EN_CURSO'
            WHERE salida_campo_id=@nSalida AND estado=1 AND estado_proceso='PROGRAMADA';
            DECLARE @cSalidaIdent NVARCHAR(200)=CONVERT(NVARCHAR(200),@nSalida);
            EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio]
                @nUsuario,@nSesion,@nDisp,@nModulo,'INICIAR','campo','SalidaCampo',@cSalidaIdent,NULL,NULL,
                N'Inicio automático al comenzar la primera visita.','estado_proceso','PROGRAMADA','EN_CURSO',
                @cIp,@gCorr,@gSol,@cEnd,@nAudSalida OUTPUT,@nTransSalida OUTPUT;
        END;

        INSERT INTO [campo].[VisitaTecnica]
        (salida_participante_id,predio_id,fecha_hora_inicio,fecha_hora_fin,posicion_inicio,objetivo,resumen,recomendaciones,estado_proceso)
        VALUES(@nPart,@nPredio,@dInicio,NULL,
               CASE WHEN @nLat IS NULL THEN NULL ELSE geography::Point(CONVERT(FLOAT,@nLat),CONVERT(FLOAT,@nLon),4326) END,
               @cObjetivo,NULL,NULL,'INICIADA');
        SET @nVisitaTecnicaId=CONVERT(BIGINT,SCOPE_IDENTITY());
        SET @cIdent=CONVERT(NVARCHAR(200),@nVisitaTecnicaId);
        SELECT @cPost=(SELECT visita_tecnica_id,salida_participante_id,predio_id,fecha_hora_inicio,objetivo,estado_proceso
                       FROM [campo].[VisitaTecnica] WHERE visita_tecnica_id=@nVisitaTecnicaId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
        EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio]
            @nUsuario,@nSesion,@nDisp,@nModulo,'INICIAR','campo','VisitaTecnica',@cIdent,NULL,@cPost,NULL,
            'estado_proceso',NULL,'INICIADA',@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
        /* Confirmar datos e idempotencia juntos. */

        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
            @nOp,'COMPLETADA','campo','VisitaTecnica',@cIdent,'VISITA_INICIADA',@bFin OUTPUT,@cMsgFin OUTPUT;
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
 SET @cMensaje=N'Visita iniciada correctamente.';
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
        SET @cMensaje=N'No se pudo iniciar la visita. Intente nuevamente.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'campo.PA_VisitaTecnica_Ins_Iniciar',
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
    @cProcedimiento = N'campo.PA_VisitaTecnica_Ins_Iniciar',
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
    @cProcedimiento = N'campo.PA_VisitaTecnica_Ins_Iniciar',
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
    SELECT @nVisitaTecnicaId = NULL;

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
    @cProcedimiento = N'campo.PA_VisitaTecnica_Ins_Iniciar',
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
FROM config.FN_RespuestaUsuario(N'campo.PA_VisitaTecnica_Ins_Iniciar',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
