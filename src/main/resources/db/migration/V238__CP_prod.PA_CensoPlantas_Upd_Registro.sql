IF OBJECT_ID(N'[prod].[PA_CensoPlantas_Upd_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [prod].[PA_CensoPlantas_Upd_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : prod.PA_CensoPlantas_Upd_Registro
' Descripción             : Actualiza los datos de censos de plantas.
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
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [prod].[PA_CensoPlantas_Upd_Registro]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [prod].[PA_CensoPlantas_Upd_Registro]
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
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),
            @nCenso BIGINT,@nCultivo BIGINT,@dFecha DATE,@nTot INT,@nProd INT,@nNoProd INT,@nNuevas INT,@nMuertas INT,@nAfect INT,@cObs NVARCHAR(300),@cAnt NVARCHAR(MAX),@cPost NVARCHAR(MAX),@cIdent NVARCHAR(200),@nAud BIGINT,@nTrans BIGINT;
    SET @bResultado=0;
 SET @cMensaje=N'No se pudo actualizar el censo.';
    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente] @cJson,'CENSOS_EDITAR','CENSO_EDITAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@nOp OUTPUT,@bRep OUTPUT,@cEstadoOp OUTPUT,@cIdRes OUTPUT,@cCodRes OUTPUT,@bIni OUTPUT,@cMsg OUTPUT;
    IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
 IF @bRep=1 BEGIN IF @cEstadoOp='COMPLETADA' BEGIN SET @bResultado=1;
 SET @cMensaje=N'La solicitud ya fue procesada correctamente.';
 END ELSE SET @cMensaje=N'La solicitud ya se encuentra en proceso.';
 GOTO __DESCO_Salida;
 END;
    SELECT @nCenso=censoPlantasId,@dFecha=fechaCenso,@nTot=plantasTotales,@nProd=plantasProductivas,@nNoProd=plantasNoProductivas,@nNuevas=ISNULL(plantasNuevas,0),@nMuertas=ISNULL(plantasMuertas,0),@nAfect=ISNULL(plantasAfectadas,0),@cObs=NULLIF(LTRIM(RTRIM(observacion)),N'') FROM OPENJSON(@cJson,'$.censo') WITH (censoPlantasId BIGINT '$.censoPlantasId',fechaCenso DATE '$.fechaCenso',plantasTotales INT '$.plantasTotales',plantasProductivas INT '$.plantasProductivas',plantasNoProductivas INT '$.plantasNoProductivas',plantasNuevas INT '$.plantasNuevas',plantasMuertas INT '$.plantasMuertas',plantasAfectadas INT '$.plantasAfectadas',observacion NVARCHAR(300) '$.observacion');
    SELECT @nCultivo=parcela_cultivo_id FROM [prod].[CensoPlantas] WHERE censo_plantas_id=@nCenso AND estado=1;
    IF @nCultivo IS NULL OR NOT EXISTS(SELECT 1 FROM [prod].[ParcelaCultivo] WHERE parcela_cultivo_id=@nCultivo AND estado=1 AND situacion_cultivo='ACTIVO') BEGIN SET @cMensaje=N'El censo seleccionado ya no está disponible para edición.';
 GOTO Fallar;
 END;
    IF EXISTS(SELECT 1 FROM [prod].[ParcelaCultivo] WHERE parcela_cultivo_id=@nCultivo AND @dFecha<fecha_inicio) OR @dFecha>CONVERT(DATE,SYSUTCDATETIME()) BEGIN SET @cMensaje=N'La fecha del censo no es válida para el cultivo seleccionado.';
 GOTO Fallar;
 END;
    IF @dFecha IS NULL OR @nTot IS NULL OR @nProd IS NULL OR @nNoProd IS NULL OR @nTot<0 OR @nProd<0 OR @nNoProd<0 OR @nNuevas<0 OR @nMuertas<0 OR @nAfect<0 OR @nProd+@nNoProd>@nTot OR @nAfect>@nTot BEGIN SET @cMensaje=N'Revise las cantidades del censo.';
 GOTO Fallar;
 END;
    IF @dFecha>CONVERT(DATE,SYSUTCDATETIME()) BEGIN SET @cMensaje=N'La fecha del censo no puede ser posterior a hoy.';
 GOTO Fallar;
 END;
    IF EXISTS(SELECT 1 FROM [prod].[CensoPlantas] WHERE parcela_cultivo_id=@nCultivo AND fecha_censo=@dFecha AND censo_plantas_id<>@nCenso) BEGIN SET @cMensaje=N'Ya existe un censo registrado para esa fecha.';
 GOTO Fallar;
 END;
    BEGIN TRY BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
      SELECT @cAnt=(SELECT * FROM [prod].[CensoPlantas] WHERE censo_plantas_id=@nCenso FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
      UPDATE [prod].[CensoPlantas] SET fecha_censo=@dFecha,plantas_totales=@nTot,plantas_productivas=@nProd,plantas_no_productivas=@nNoProd,plantas_nuevas=@nNuevas,plantas_muertas=@nMuertas,plantas_afectadas=@nAfect,observacion=@cObs WHERE censo_plantas_id=@nCenso AND estado=1;
      SELECT @cPost=(SELECT * FROM [prod].[CensoPlantas] WHERE censo_plantas_id=@nCenso FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 SET @cIdent=CONVERT(NVARCHAR(200),@nCenso);
      EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio] @nUsuario,@nSesion,@nDisp,@nModulo,'EDITAR','prod','CensoPlantas',@cIdent,@cAnt,@cPost,NULL,NULL,NULL,NULL,@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
      /* Confirmar datos e idempotencia juntos. */ EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOp,'COMPLETADA','prod','CensoPlantas',@cIdent,'CENSO_ACTUALIZADO',@bFin OUTPUT,@cMsgFin OUTPUT;
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
 SET @cMensaje=N'Censo actualizado correctamente.';
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
 SET @cMensaje=N'No se pudo actualizar el censo. Intente nuevamente.';
 
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'prod.PA_CensoPlantas_Upd_Registro',
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
    @cProcedimiento = N'prod.PA_CensoPlantas_Upd_Registro',
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
    @cProcedimiento = N'prod.PA_CensoPlantas_Upd_Registro',
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
    @cProcedimiento = N'prod.PA_CensoPlantas_Upd_Registro',
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
FROM config.FN_RespuestaUsuario(N'prod.PA_CensoPlantas_Upd_Registro',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
