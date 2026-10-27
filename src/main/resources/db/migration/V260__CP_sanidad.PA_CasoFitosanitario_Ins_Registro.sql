IF OBJECT_ID(N'[sanidad].[PA_CasoFitosanitario_Ins_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [sanidad].[PA_CasoFitosanitario_Ins_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : sanidad.PA_CasoFitosanitario_Ins_Registro
' Descripción             : Registra casos fitosanitarios.
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
        @nCasoFitosanitarioId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [sanidad].[PA_CasoFitosanitario_Ins_Registro]
        @cJson = N'{}',
        @nCasoFitosanitarioId = @nCasoFitosanitarioId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nCasoFitosanitarioId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [sanidad].[PA_CasoFitosanitario_Ins_Registro]
(
    @cJson NVARCHAR(MAX),
    @nCasoFitosanitarioId BIGINT OUTPUT,
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
        @nPC BIGINT,@nTipo SMALLINT,@nVisita BIGINT,@dFecha DATETIME2(0),@nPlantas INT,@bEst BIT,
        @cSev VARCHAR(10),@cObs NVARCHAR(500),@nPredio BIGINT,@nPredioVisita BIGINT,
        @dInicioVisita DATETIME2(0),@cPost NVARCHAR(MAX),@cIdent NVARCHAR(200),@nAud BIGINT,@nTrans BIGINT;

    SELECT
        @nCasoFitosanitarioId=NULL,
        @bResultado=0,
        @cMensaje=N'No se pudo registrar el caso sanitario.';

    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente]
        @cJson=@cJson,
        @cCodigoPermiso='SANIDAD_CREAR',
        @cAmbito='SANIDAD_CASO_CREAR',
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
        IF @cEstadoOp='COMPLETADA'
        BEGIN
            SET @nCasoFitosanitarioId=TRY_CONVERT(BIGINT,@cIdRes);
            SET @bResultado=1;
            SET @cMensaje=N'La solicitud ya fue procesada correctamente.';
        END
        ELSE
            SET @cMensaje=N'La solicitud ya se encuentra en proceso.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nPC=parcelaCultivoId,
        @nTipo=tipoProblemaId,
        @nVisita=visitaDeteccionId,
        @dFecha=fechaDeteccion,
        @nPlantas=plantasAfectadas,
        @bEst=cantidadEstimada,
        @cSev=UPPER(NULLIF(LTRIM(RTRIM(severidad)),'')),
        @cObs=NULLIF(LTRIM(RTRIM(observacion)),N'')
    FROM OPENJSON(@cJson,'$.caso')
    WITH
    (
        parcelaCultivoId BIGINT '$.parcelaCultivoId',
        tipoProblemaId SMALLINT '$.tipoProblemaId',
        visitaDeteccionId BIGINT '$.visitaDeteccionId',
        fechaDeteccion DATETIME2(0) '$.fechaDeteccion',
        plantasAfectadas INT '$.plantasAfectadas',
        cantidadEstimada BIT '$.cantidadEstimada',
        severidad VARCHAR(10) '$.severidad',
        observacion NVARCHAR(500) '$.observacion'
    );

    IF @dFecha IS NULL SET @dFecha=SYSUTCDATETIME();

    IF @nPC IS NULL OR @nTipo IS NULL OR @cSev NOT IN('BAJA','MEDIA','ALTA')
    BEGIN
        SET @cMensaje=N'Complete correctamente los datos del caso sanitario.';
        GOTO Fallar;
    END;

    IF @dFecha>SYSUTCDATETIME()
    BEGIN
        SET @cMensaje=N'La fecha de detección no puede estar en el futuro.';
        GOTO Fallar;
    END;

    IF @nPlantas IS NOT NULL AND @nPlantas<0
    BEGIN
        SET @cMensaje=N'La cantidad de plantas afectadas no es válida.';
        GOTO Fallar;
    END;

    IF @nPlantas IS NULL SET @bEst=NULL;

    SELECT @nPredio=P.predio_id
    FROM [prod].[ParcelaCultivo] PC
    INNER JOIN [prod].[Parcela] P
        ON P.parcela_id=PC.parcela_id
       AND P.estado=1
    WHERE PC.parcela_cultivo_id=@nPC
      AND PC.estado=1
      AND PC.situacion_cultivo='ACTIVO';

    IF @nPredio IS NULL
    BEGIN
        SET @cMensaje=N'El cultivo seleccionado no está disponible.';
        GOTO Fallar;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [sanidad].[TipoProblemaFitosanitario]
        WHERE tipo_problema_fitosanitario_id=@nTipo
          AND estado=1
    )
    BEGIN
        SET @cMensaje=N'El problema sanitario seleccionado no está disponible.';
        GOTO Fallar;
    END;

    IF @nVisita IS NOT NULL
    BEGIN
        SELECT
            @nPredioVisita=predio_id,
            @dInicioVisita=fecha_hora_inicio
        FROM [campo].[VisitaTecnica]
        WHERE visita_tecnica_id=@nVisita
          AND estado=1
          AND estado_proceso='INICIADA';

        IF @nPredioVisita IS NULL
        BEGIN
            SET @cMensaje=N'La visita seleccionada debe encontrarse en curso.';
            GOTO Fallar;
        END;

        IF @nPredioVisita<>@nPredio
        BEGIN
            SET @cMensaje=N'La visita seleccionada no corresponde al cultivo.';
            GOTO Fallar;
        END;

        IF @dFecha<@dInicioVisita
        BEGIN
            SET @cMensaje=N'La fecha de detección no corresponde al periodo de la visita.';
            GOTO Fallar;
        END;
    END;

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        INSERT [sanidad].[CasoFitosanitario]
        (
            parcela_cultivo_id,tipo_problema_fitosanitario_id,visita_deteccion_id,
            fecha_deteccion,plantas_afectadas,cantidad_estimada,severidad,
            estado_caso,observacion,estado
        )
        VALUES
        (
            @nPC,@nTipo,@nVisita,@dFecha,@nPlantas,@bEst,@cSev,'DETECTADO',@cObs,1
        );

        SET @nCasoFitosanitarioId=CONVERT(BIGINT,SCOPE_IDENTITY());
        SET @cIdent=CONVERT(NVARCHAR(200),@nCasoFitosanitarioId);

        SELECT @cPost=
        (
            SELECT
                @nCasoFitosanitarioId casoFitosanitarioId,
                @nPC parcelaCultivoId,
                @nTipo tipoProblemaId,
                @nVisita visitaDeteccionId,
                @dFecha fechaDeteccion,
                @nPlantas plantasAfectadas,
                @cSev severidad,
                'DETECTADO' estadoCaso
            FOR JSON PATH,WITHOUT_ARRAY_WRAPPER
        );

        EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio]
            @nUsuarioId=@nUsuario,
            @nSesionUsuarioId=@nSesion,
            @nDispositivoUsuarioId=@nDisp,
            @nModuloId=@nModulo,
            @cAccion='CREAR',
            @cEsquemaEntidad='sanidad',
            @cNombreEntidad='CasoFitosanitario',
            @cIdentificador=@cIdent,
            @cDatosAnteriores=NULL,
            @cDatosPosteriores=@cPost,
            @cMotivo=NULL,
            @cCampoEstado='estado_caso',
            @cEstadoAnterior=NULL,
            @cEstadoNuevo='DETECTADO',
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
            @cCodigoResultado='CASO_CREADO',
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
        SET @cMensaje=N'Caso sanitario registrado correctamente.';
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
        SET @cMensaje=N'No se pudo registrar el caso sanitario. Intente nuevamente.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'sanidad.PA_CasoFitosanitario_Ins_Registro',
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
    @cProcedimiento = N'sanidad.PA_CasoFitosanitario_Ins_Registro',
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
    @cProcedimiento = N'sanidad.PA_CasoFitosanitario_Ins_Registro',
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
    SELECT @nCasoFitosanitarioId = NULL;

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
    @cProcedimiento = N'sanidad.PA_CasoFitosanitario_Ins_Registro',
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
FROM config.FN_RespuestaUsuario(N'sanidad.PA_CasoFitosanitario_Ins_Registro',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
