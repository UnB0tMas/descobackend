IF OBJECT_ID(N'[logistica].[PA_RecursoProgramado_Ins_Programar]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_RecursoProgramado_Ins_Programar];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_RecursoProgramado_Ins_Programar
' Descripción             : Programa recurso programado.
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
        @nRecursoProgramadoId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [logistica].[PA_RecursoProgramado_Ins_Programar]
        @cJson = N'{}',
        @nRecursoProgramadoId = @nRecursoProgramadoId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nRecursoProgramadoId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [logistica].[PA_RecursoProgramado_Ins_Programar]
(
    @cJson NVARCHAR(MAX),
    @nRecursoProgramadoId BIGINT OUTPUT,
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
        @nCampania BIGINT,@nOperativo BIGINT,@nSalida BIGINT,@nBien BIGINT,@nSuministro BIGINT,
        @nCantidad DECIMAL(14,3),@cObservacion NVARCHAR(300),@nStock DECIMAL(19,3),
        @bDestinoValido BIT,@cMensajeDestino NVARCHAR(300),@cIdentificador NVARCHAR(200);

    SELECT @nRecursoProgramadoId=NULL,@bResultado=0,@cMensaje=N'No se pudo programar el recurso.';

    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente]
        @cJson=@cJson,
        @cCodigoPermiso='RECURSOS_CREAR',
        @cAmbito='RECURSO_PROGRAMAR',
        @nUsuarioId=@nUsuario OUTPUT,
        @nSesionUsuarioId=@nSesion OUTPUT,
        @nDispositivoUsuarioId=@nDisp OUTPUT,
        @nEmpleadoId=@nEmp OUTPUT,
        @nModuloId=@nModulo OUTPUT,
        @gCorrelacionId=@gCorr OUTPUT,
        @gSolicitudId=@gSol OUTPUT,
        @cIp=@cIp OUTPUT,
        @cEndpoint=@cEnd OUTPUT,
        @nOperacionIdempotenteId=@nOperacion OUTPUT,
        @bEsRepetida=@bRepetida OUTPUT,
        @cEstadoOperacion=@cEstadoOperacion OUTPUT,
        @cIdentificadorResultado=@cIdResultado OUTPUT,
        @cCodigoResultado=@cCodigoResultado OUTPUT,
        @bResultado=@bInicio OUTPUT,
        @cMensaje=@cMsg OUTPUT;

    IF @bInicio=0 AND @bRepetida=0
    BEGIN
        SET @cMensaje=@cMsg;
        GOTO __DESCO_Salida;
    END;

    IF @bRepetida=1
    BEGIN
        IF @cEstadoOperacion='COMPLETADA'
        BEGIN
            SET @nRecursoProgramadoId=TRY_CONVERT(BIGINT,@cIdResultado);
            SET @bResultado=1;
            SET @cMensaje=N'La solicitud ya fue procesada correctamente.';
        END
        ELSE
            SET @cMensaje=N'La solicitud ya se encuentra en proceso.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nCampania=campaniaVentaId,
        @nOperativo=operativoVentaId,
        @nSalida=salidaCampoId,
        @nBien=bienInventarioId,
        @nSuministro=suministroId,
        @nCantidad=cantidadProgramada,
        @cObservacion=NULLIF(LTRIM(RTRIM(observacion)),N'')
    FROM OPENJSON(@cJson,'$.recurso')
    WITH
    (
        campaniaVentaId BIGINT '$.campaniaVentaId',
        operativoVentaId BIGINT '$.operativoVentaId',
        salidaCampoId BIGINT '$.salidaCampoId',
        bienInventarioId BIGINT '$.bienInventarioId',
        suministroId BIGINT '$.suministroId',
        cantidadProgramada DECIMAL(14,3) '$.cantidadProgramada',
        observacion NVARCHAR(300) '$.observacion'
    );

    IF (CASE WHEN @nBien IS NULL THEN 0 ELSE 1 END)+(CASE WHEN @nSuministro IS NULL THEN 0 ELSE 1 END)<>1
       OR @nCantidad IS NULL OR @nCantidad<=0
    BEGIN
        SET @cMensaje=N'Seleccione un recurso y una cantidad válida.';
        GOTO Fallar;
    END;

    EXEC [logistica].[PA_RecursoProgramado_Sel_ValidarDestinoInterno]
        @nCampaniaVentaId=@nCampania,
        @nOperativoVentaId=@nOperativo,
        @nSalidaCampoId=@nSalida,
        @cMomento='PROGRAMAR',
        @bValido=@bDestinoValido OUTPUT,
        @cMensaje=@cMensajeDestino OUTPUT;

    IF @bDestinoValido=0
    BEGIN
        SET @cMensaje=@cMensajeDestino;
        GOTO Fallar;
    END;

    IF @nBien IS NOT NULL
    BEGIN
        IF @nCantidad<>1
           OR NOT EXISTS
              (
                  SELECT 1 FROM [logistica].[BienInventario]
                  WHERE bien_inventario_id=@nBien AND estado=1 AND estado_bien='DISPONIBLE'
              )
           OR EXISTS
              (
                  SELECT 1 FROM [logistica].[RecursoProgramado]
                  WHERE bien_inventario_id=@nBien AND estado=1 AND estado_proceso IN('PROGRAMADO','EN_EJECUCION')
              )
        BEGIN
            SET @cMensaje=N'El bien seleccionado no está disponible para programación.';
            GOTO Fallar;
        END;
    END
    ELSE
    BEGIN
        EXEC [logistica].[PA_Suministro_Sel_StockInterno]
            @nSuministroId=@nSuministro,
            @nStock=NULL,@nDisponible=@nStock OUTPUT;

        IF NOT EXISTS(SELECT 1 FROM [logistica].[Suministro] WHERE suministro_id=@nSuministro AND estado=1)
           OR @nCantidad>@nStock
        BEGIN
            SET @cMensaje=N'El suministro no tiene stock suficiente para esta programación.';
            GOTO Fallar;
        END;
    END;

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        INSERT INTO [logistica].[RecursoProgramado]
        (
            campania_venta_id,operativo_venta_id,salida_campo_id,bien_inventario_id,suministro_id,
            cantidad_programada,observacion,estado,estado_proceso,usuario_programacion_id,fecha_programacion
        )
        VALUES
        (
            @nCampania,@nOperativo,@nSalida,@nBien,@nSuministro,
            @nCantidad,@cObservacion,1,'PROGRAMADO',@nUsuario,SYSUTCDATETIME()
        );

        SET @nRecursoProgramadoId=CONVERT(BIGINT,SCOPE_IDENTITY());
        SET @cIdentificador=CONVERT(NVARCHAR(200),@nRecursoProgramadoId);

        EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio]
            @nUsuarioId=@nUsuario,
            @nSesionUsuarioId=@nSesion,
            @nDispositivoUsuarioId=@nDisp,
            @nModuloId=@nModulo,
            @cAccion='PROGRAMAR',
            @cEsquemaEntidad='logistica',
            @cNombreEntidad='RecursoProgramado',
            @cIdentificador=@cIdentificador,
            @cDatosAnteriores=NULL,
            @cDatosPosteriores=NULL,
            @cMotivo=NULL,
            @cCampoEstado='estado_proceso',
            @cEstadoAnterior=NULL,
            @cEstadoNuevo='PROGRAMADO',
            @cIp=@cIp,
            @gCorrelacionId=@gCorr,
            @gSolicitudId=@gSol,
            @cEndpoint=@cEnd,
            @nAuditoriaEventoId=@nAud OUTPUT,
            @nTransicionEstadoId=@nTrans OUTPUT;

        /* Confirmar datos e idempotencia juntos. */

        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
            @nOperacionIdempotenteId=@nOperacion,
            @cEstadoOperacion='COMPLETADA',
            @cEsquemaEntidad='logistica',
            @cNombreEntidad='RecursoProgramado',
            @cIdentificadorResultado=@cIdentificador,
            @cCodigoResultado='RECURSO_PROGRAMADO',
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
        SET @cMensaje=N'Recurso programado correctamente.';
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
        SET @cMensaje=N'No se pudo programar el recurso. Intente nuevamente.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'logistica.PA_RecursoProgramado_Ins_Programar',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;

Fallar:
    IF @nOperacion IS NOT NULL AND @bResultado=0
        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
            @nOperacionIdempotenteId=@nOperacion,
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
    @cProcedimiento = N'logistica.PA_RecursoProgramado_Ins_Programar',
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
    @cProcedimiento = N'logistica.PA_RecursoProgramado_Ins_Programar',
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
FROM config.FN_RespuestaUsuario(N'logistica.PA_RecursoProgramado_Ins_Programar',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
