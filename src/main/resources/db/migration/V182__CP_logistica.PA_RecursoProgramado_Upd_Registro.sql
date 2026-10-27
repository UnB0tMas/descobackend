IF OBJECT_ID(N'[logistica].[PA_RecursoProgramado_Upd_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_RecursoProgramado_Upd_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_RecursoProgramado_Upd_Registro
' Descripción             : Actualiza los datos de recurso programado.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
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
    EXEC [logistica].[PA_RecursoProgramado_Upd_Registro]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [logistica].[PA_RecursoProgramado_Upd_Registro]
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
        @nOperacion BIGINT,@bRepetida BIT,@cEstadoOperacion VARCHAR(20),@cIdResultado NVARCHAR(200),
        @cCodigoResultado VARCHAR(40),@bInicio BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),
        @nAud BIGINT,@nTrans BIGINT,
        @nId BIGINT,@nCantidad DECIMAL(14,3),@cObservacion NVARCHAR(300),
        @nCampania BIGINT,@nOperativo BIGINT,@nSalida BIGINT,@nBien BIGINT,@nSuministro BIGINT,
        @nStock DECIMAL(19,3),@bDestinoValido BIT,@cMensajeDestino NVARCHAR(300),@cIdentificador NVARCHAR(200);

    SELECT @bResultado=0,@cMensaje=N'No se pudo actualizar la programación.';

    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente]
        @cJson=@cJson,@cCodigoPermiso='RECURSOS_EDITAR',@cAmbito='RECURSO_EDITAR',
        @nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,
        @nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,
        @gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,
        @nOperacionIdempotenteId=@nOperacion OUTPUT,@bEsRepetida=@bRepetida OUTPUT,
        @cEstadoOperacion=@cEstadoOperacion OUTPUT,@cIdentificadorResultado=@cIdResultado OUTPUT,
        @cCodigoResultado=@cCodigoResultado OUTPUT,@bResultado=@bInicio OUTPUT,@cMensaje=@cMsg OUTPUT;

    IF @bInicio=0 AND @bRepetida=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    IF @bRepetida=1
    BEGIN
        SET @bResultado=CASE WHEN @cEstadoOperacion='COMPLETADA' THEN 1 ELSE 0 END;
        SET @cMensaje=CASE WHEN @cEstadoOperacion='COMPLETADA' THEN N'La solicitud ya fue procesada correctamente.' ELSE N'La solicitud ya se encuentra en proceso.' END;
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nId=recursoProgramadoId,
        @nCantidad=cantidadProgramada,
        @cObservacion=NULLIF(LTRIM(RTRIM(observacion)),N'')
    FROM OPENJSON(@cJson,'$.recurso')
    WITH
    (
        recursoProgramadoId BIGINT '$.recursoProgramadoId',
        cantidadProgramada DECIMAL(14,3) '$.cantidadProgramada',
        observacion NVARCHAR(300) '$.observacion'
    );

    SELECT
        @nCampania=campania_venta_id,@nOperativo=operativo_venta_id,@nSalida=salida_campo_id,
        @nBien=bien_inventario_id,@nSuministro=suministro_id
    FROM [logistica].[RecursoProgramado]
    WHERE recurso_programado_id=@nId AND estado=1 AND estado_proceso='PROGRAMADO';

    IF (@nBien IS NULL AND @nSuministro IS NULL)
       OR @nCantidad IS NULL OR @nCantidad<=0
       OR (@nBien IS NOT NULL AND @nCantidad<>1)
    BEGIN
        SET @cMensaje=N'La programación seleccionada no está disponible o la cantidad no es válida.';
        GOTO Fallar;
    END;

    EXEC [logistica].[PA_RecursoProgramado_Sel_ValidarDestinoInterno]
        @nCampaniaVentaId=@nCampania,
        @nOperativoVentaId=@nOperativo,
        @nSalidaCampoId=@nSalida,
        @cMomento='EDITAR',
        @bValido=@bDestinoValido OUTPUT,
        @cMensaje=@cMensajeDestino OUTPUT;

    IF @bDestinoValido=0
    BEGIN
        SET @cMensaje=N'La actividad asociada ya no permite modificar la programación.';
        GOTO Fallar;
    END;

    IF @nSuministro IS NOT NULL
    BEGIN
        EXEC [logistica].[PA_Suministro_Sel_StockInterno]
            @nSuministroId=@nSuministro,
            @nStock=NULL,@nDisponible=@nStock OUTPUT;
        SELECT @nStock=@nStock+CASE WHEN suministro_id=@nSuministro AND estado_proceso='PROGRAMADO' AND estado=1 THEN cantidad_programada ELSE 0 END FROM logistica.RecursoProgramado WHERE recurso_programado_id=@nId;
        IF @nCantidad>@nStock
        BEGIN
            SET @cMensaje=N'El suministro no tiene stock suficiente para la cantidad programada.';
            GOTO Fallar;
        END;
    END;

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        UPDATE [logistica].[RecursoProgramado]
        SET cantidad_programada=@nCantidad,
            observacion=@cObservacion
        WHERE recurso_programado_id=@nId AND estado=1 AND estado_proceso='PROGRAMADO';

        IF @@ROWCOUNT<>1
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
            SET @cMensaje=N'La programación cambió antes de completar la actualización.';
            GOTO Fallar;
        END;

        SET @cIdentificador=CONVERT(NVARCHAR(200),@nId);
        EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio]
            @nUsuarioId=@nUsuario,@nSesionUsuarioId=@nSesion,@nDispositivoUsuarioId=@nDisp,@nModuloId=@nModulo,
            @cAccion='EDITAR',@cEsquemaEntidad='logistica',@cNombreEntidad='RecursoProgramado',
            @cIdentificador=@cIdentificador,@cDatosAnteriores=NULL,@cDatosPosteriores=NULL,@cMotivo=NULL,
            @cCampoEstado=NULL,@cEstadoAnterior=NULL,@cEstadoNuevo=NULL,@cIp=@cIp,
            @gCorrelacionId=@gCorr,@gSolicitudId=@gSol,@cEndpoint=@cEnd,
            @nAuditoriaEventoId=@nAud OUTPUT,@nTransicionEstadoId=@nTrans OUTPUT;

        /* Confirmar datos e idempotencia juntos. */

        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
            @nOperacionIdempotenteId=@nOperacion,@cEstadoOperacion='COMPLETADA',
            @cEsquemaEntidad='logistica',@cNombreEntidad='RecursoProgramado',
            @cIdentificadorResultado=@cIdentificador,@cCodigoResultado='RECURSO_ACTUALIZADO',
            @bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
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
        SET @cMensaje=N'Programación actualizada correctamente.';
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
        SET @cMensaje=N'No se pudo actualizar la programación. Intente nuevamente.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'logistica.PA_RecursoProgramado_Upd_Registro',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;

Fallar:
    IF @nOperacion IS NOT NULL AND @bResultado=0
        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
            @nOperacionIdempotenteId=@nOperacion,@cEstadoOperacion='FALLIDA',
            @cEsquemaEntidad=NULL,@cNombreEntidad=NULL,@cIdentificadorResultado=NULL,
            @cCodigoResultado='NO_PROCESADO',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;

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
    @cProcedimiento = N'logistica.PA_RecursoProgramado_Upd_Registro',
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
    @cProcedimiento = N'logistica.PA_RecursoProgramado_Upd_Registro',
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
FROM config.FN_RespuestaUsuario(N'logistica.PA_RecursoProgramado_Upd_Registro',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
