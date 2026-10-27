IF OBJECT_ID(N'[campo].[PA_SalidaCampo_Upd_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [campo].[PA_SalidaCampo_Upd_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : campo.PA_SalidaCampo_Upd_Registro
' Descripción             : Actualiza la información de una salida de campo.
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
    EXEC [campo].[PA_SalidaCampo_Upd_Registro]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [campo].[PA_SalidaCampo_Upd_Registro]
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
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),@nSalida BIGINT,@nMotivo SMALLINT,@dProg DATETIME2(0),@cDesc NVARCHAR(400),@jPart NVARCHAR(MAX),@cAnt NVARCHAR(MAX),@cPost NVARCHAR(MAX),@cIdent NVARCHAR(200),@nAud BIGINT,@nTrans BIGINT;
    SET @bResultado=0;
 SET @cMensaje=N'No se pudo actualizar la salida.';
    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente] @cJson,'SALIDAS_EDITAR','SALIDA_EDITAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@nOp OUTPUT,@bRep OUTPUT,@cEstadoOp OUTPUT,@cIdRes OUTPUT,@cCodRes OUTPUT,@bIni OUTPUT,@cMsg OUTPUT;
    IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
 IF @bRep=1 BEGIN IF @cEstadoOp='COMPLETADA' BEGIN SET @bResultado=1;
 SET @cMensaje=N'La solicitud ya fue procesada correctamente.';
 END ELSE SET @cMensaje=N'La solicitud ya se encuentra en proceso.';
 GOTO __DESCO_Salida;
 END;
    SELECT @nSalida=salidaCampoId,@nMotivo=motivoSalidaId,@dProg=fechaHoraProgramada,@cDesc=NULLIF(LTRIM(RTRIM(descripcion)),N'') FROM OPENJSON(@cJson,'$.salida') WITH (salidaCampoId BIGINT '$.salidaCampoId',motivoSalidaId SMALLINT '$.motivoSalidaId',fechaHoraProgramada DATETIME2(0) '$.fechaHoraProgramada',descripcion NVARCHAR(400) '$.descripcion');
 SET @jPart=JSON_QUERY(@cJson,'$.participantes');
    IF @nSalida IS NULL OR @nMotivo IS NULL OR @dProg IS NULL BEGIN SET @cMensaje=N'Complete los datos obligatorios de la salida.';
 GOTO Fallar;
 END;
    IF NOT EXISTS(SELECT 1 FROM [campo].[SalidaCampo] WHERE salida_campo_id=@nSalida AND estado=1 AND estado_proceso IN('BORRADOR','PROGRAMADA')) BEGIN SET @cMensaje=N'La salida ya no está disponible para edición.';
 GOTO Fallar;
 END;
    IF NOT EXISTS(SELECT 1 FROM [campo].[MotivoSalida] WHERE motivo_salida_id=@nMotivo AND estado=1) BEGIN SET @cMensaje=N'El motivo seleccionado no está disponible.';
 GOTO Fallar;
 END;
    IF @jPart IS NOT NULL BEGIN IF NOT EXISTS(SELECT 1 FROM OPENJSON(@jPart)) OR (SELECT COUNT(*) FROM OPENJSON(@jPart) WITH (esResponsable BIT '$.esResponsable') WHERE esResponsable=1)<>1 BEGIN SET @cMensaje=N'Seleccione los participantes y un responsable.';
 GOTO Fallar;
 END;
 IF EXISTS(SELECT 1 FROM OPENJSON(@jPart) WITH (empleadoId BIGINT '$.empleadoId') T LEFT JOIN [org].[Empleado] E ON E.empleado_id=T.empleadoId WHERE T.empleadoId IS NULL OR E.empleado_id IS NULL OR E.estado=0) BEGIN SET @cMensaje=N'Uno de los participantes seleccionados no está disponible.';
 GOTO Fallar;
 END;
 END;
    BEGIN TRY BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
      SELECT @cAnt=(SELECT S.*,(SELECT SP.empleado_id,SP.funcion,SP.es_responsable,SP.estado FROM [campo].[SalidaParticipante] SP WHERE SP.salida_campo_id=S.salida_campo_id FOR JSON PATH) participantes FROM [campo].[SalidaCampo] S WHERE S.salida_campo_id=@nSalida FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
      UPDATE [campo].[SalidaCampo] SET motivo_salida_id=@nMotivo,fecha_hora_programada=@dProg,descripcion=@cDesc WHERE salida_campo_id=@nSalida AND estado=1 AND estado_proceso IN('BORRADOR','PROGRAMADA');
      IF @jPart IS NOT NULL
      BEGIN
        UPDATE SP SET estado=0 FROM [campo].[SalidaParticipante] SP WHERE SP.salida_campo_id=@nSalida AND SP.estado=1 AND NOT EXISTS(SELECT 1 FROM OPENJSON(@jPart) WITH (empleadoId BIGINT '$.empleadoId') J WHERE J.empleadoId=SP.empleado_id);
        UPDATE SP SET funcion=J.funcion,es_responsable=ISNULL(J.esResponsable,0),estado=1 FROM [campo].[SalidaParticipante] SP INNER JOIN OPENJSON(@jPart) WITH (empleadoId BIGINT '$.empleadoId',funcion NVARCHAR(120) '$.funcion',esResponsable BIT '$.esResponsable') J ON J.empleadoId=SP.empleado_id WHERE SP.salida_campo_id=@nSalida;
        INSERT [campo].[SalidaParticipante](salida_campo_id,empleado_id,funcion,es_responsable) SELECT @nSalida,J.empleadoId,J.funcion,ISNULL(J.esResponsable,0) FROM OPENJSON(@jPart) WITH (empleadoId BIGINT '$.empleadoId',funcion NVARCHAR(120) '$.funcion',esResponsable BIT '$.esResponsable') J WHERE NOT EXISTS(SELECT 1 FROM [campo].[SalidaParticipante] SP WHERE SP.salida_campo_id=@nSalida AND SP.empleado_id=J.empleadoId);
      END;
      SELECT @cPost=(SELECT S.*,(SELECT SP.empleado_id,SP.funcion,SP.es_responsable,SP.estado FROM [campo].[SalidaParticipante] SP WHERE SP.salida_campo_id=S.salida_campo_id FOR JSON PATH) participantes FROM [campo].[SalidaCampo] S WHERE S.salida_campo_id=@nSalida FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 SET @cIdent=CONVERT(NVARCHAR(200),@nSalida);
      EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio] @nUsuario,@nSesion,@nDisp,@nModulo,'EDITAR','campo','SalidaCampo',@cIdent,@cAnt,@cPost,NULL,NULL,NULL,NULL,@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
      /* Confirmar datos e idempotencia juntos. */ EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOp,'COMPLETADA','campo','SalidaCampo',@cIdent,'SALIDA_ACTUALIZADA',@bFin OUTPUT,@cMsgFin OUTPUT;
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
 SET @cMensaje=N'Salida actualizada correctamente.';
 GOTO __DESCO_Salida;
    END TRY BEGIN CATCH
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
 SET @cMensaje=N'No se pudo actualizar la salida. Intente nuevamente.';
 
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'campo.PA_SalidaCampo_Upd_Registro',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;
Fallar: IF @nOp IS NOT NULL AND @bResultado=0 EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOp,'FALLIDA',NULL,NULL,NULL,'NO_PROCESADO',@bFin OUTPUT,@cMsgFin OUTPUT;

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
    @cProcedimiento = N'campo.PA_SalidaCampo_Upd_Registro',
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
    @cProcedimiento = N'campo.PA_SalidaCampo_Upd_Registro',
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
    @cProcedimiento = N'campo.PA_SalidaCampo_Upd_Registro',
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
FROM config.FN_RespuestaUsuario(N'campo.PA_SalidaCampo_Upd_Registro',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
