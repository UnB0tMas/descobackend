IF OBJECT_ID(N'[finanzas].[PA_GastoCampania_Ins_EjecutarProrrateo]', N'P') IS NOT NULL
    DROP PROCEDURE [finanzas].[PA_GastoCampania_Ins_EjecutarProrrateo];
GO

/******************************************************************************************************
' Nombre del PA           : finanzas.PA_GastoCampania_Ins_EjecutarProrrateo
' Descripción             : Ejecuta el prorrateo de gastos de campaña.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Finanzas
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
    EXEC [finanzas].[PA_GastoCampania_Ins_EjecutarProrrateo]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [finanzas].[PA_GastoCampania_Ins_EjecutarProrrateo](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS BEGIN
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
DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),@nAud BIGINT,@nTrans BIGINT,@nId BIGINT,@nCamp BIGINT,@nOpVenta BIGINT,@nImporte DECIMAL(19,4),@cRegla VARCHAR(40),@nBase DECIMAL(38,10),@cIdent NVARCHAR(200);
SELECT @bResultado=0,@cMensaje=N'No se pudo calcular el prorrateo.';
EXEC seg.PA_Operacion_Ins_IniciarIdempotente @cJson=@cJson,@cCodigoPermiso='GASTOS_CREAR',@cAmbito='GASTO_PRORRATEAR',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@nOperacionIdempotenteId=@nOp OUTPUT,@bEsRepetida=@bRep OUTPUT,@cEstadoOperacion=@cEstadoOp OUTPUT,@cIdentificadorResultado=@cIdRes OUTPUT,@cCodigoResultado=@cCodRes OUTPUT,@bResultado=@bIni OUTPUT,@cMensaje=@cMsg OUTPUT;
IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;
IF @bRep=1 BEGIN SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END;
SET @cMensaje=CASE WHEN @cEstadoOp='COMPLETADA' THEN N'La solicitud ya fue procesada correctamente.' ELSE N'La solicitud ya se encuentra en proceso.' END;
GOTO __DESCO_Salida;
END;
 SELECT @nId=gastoCampaniaId FROM OPENJSON(@cJson,'$.gasto') WITH(gastoCampaniaId BIGINT '$.gastoCampaniaId');
SELECT @nCamp=G.campania_venta_id,@nOpVenta=G.operativo_venta_id,@nImporte=G.importe,@cRegla=UPPER(R.codigo) FROM finanzas.GastoCampania G INNER JOIN finanzas.ReglaProrrateo R ON R.regla_prorrateo_id=G.regla_prorrateo_id WHERE G.gasto_campania_id=@nId AND G.estado=1 AND G.estado_proceso='REGISTRADO';
IF @nCamp IS NULL BEGIN SET @cMensaje=N'El gasto seleccionado no está disponible para prorrateo.';
GOTO Fallar;
END;
IF @cRegla NOT IN('IGUAL','PESO_ACEPTADO','VENTA_BRUTA','MANUAL') BEGIN SET @cMensaje=N'La regla de prorrateo seleccionada todavía no está disponible.';
GOTO Fallar;
END;
BEGIN TRY BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
-- Releer y bloquear el gasto dentro de la misma transacción que lo distribuye.
SELECT @nCamp=NULL, @nImporte=NULL, @cRegla=NULL;
SELECT @nCamp=G.campania_venta_id, @nOpVenta=G.operativo_venta_id,
       @nImporte=G.importe, @cRegla=UPPER(R.codigo)
FROM finanzas.GastoCampania G WITH(UPDLOCK,HOLDLOCK)
JOIN finanzas.ReglaProrrateo R ON R.regla_prorrateo_id=G.regla_prorrateo_id
WHERE G.gasto_campania_id=@nId AND G.estado=1 AND G.estado_proceso='REGISTRADO';
IF @nCamp IS NULL
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
 SET @cMensaje=N'El gasto cambió de estado y ya no admite prorrateo.';
 GOTO Fallar;
END;
IF EXISTS
(
    SELECT 1 FROM finanzas.GastoProrrateoSocio GP
    JOIN finanzas.LiquidacionDetalle LD ON LD.gasto_prorrateo_socio_id=GP.gasto_prorrateo_socio_id
    WHERE GP.gasto_campania_id=@nId AND LD.estado=1
)
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
 SET @cMensaje=N'El gasto ya está incluido en una liquidación. No se puede recalcular su distribución.';
 GOTO Fallar;
END;
DECLARE @Distribucion TABLE
(
    participacion_id BIGINT PRIMARY KEY,
    base_calculo DECIMAL(28,8) NOT NULL,
    importe DECIMAL(19,4) NOT NULL
);
IF @cRegla='MANUAL'
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM OPENJSON(@cJson,'$.prorrateo') WITH
            (participacionId BIGINT '$.participacionId', importeAsignado DECIMAL(19,4) '$.importeAsignado') J
        LEFT JOIN comercial.ParticipacionCampaniaSocio P WITH(UPDLOCK,HOLDLOCK)
          ON P.participacion_campania_socio_id=J.participacionId
         AND P.campania_venta_id=@nCamp AND P.estado=1 AND P.estado_participacion='ACTIVO'
        WHERE P.participacion_campania_socio_id IS NULL
           OR J.importeAsignado IS NULL OR J.importeAsignado<0
    ) THROW 51004, N'DESCO_PRORRATEO_INVALIDO', 1;
    INSERT @Distribucion(participacion_id,base_calculo,importe)
    SELECT participacionId,0,importeAsignado
    FROM OPENJSON(@cJson,'$.prorrateo') WITH
        (participacionId BIGINT '$.participacionId',importeAsignado DECIMAL(19,4) '$.importeAsignado');
    IF NOT EXISTS(SELECT 1 FROM @Distribucion)
       OR ABS((SELECT COALESCE(SUM(importe),0) FROM @Distribucion)-@nImporte)>0.01
        THROW 51004, N'DESCO_PRORRATEO_INVALIDO', 1;
END
ELSE
BEGIN
    IF @cRegla='IGUAL'
        INSERT @Distribucion(participacion_id,base_calculo,importe)
        SELECT P.participacion_campania_socio_id,1,0
        FROM comercial.ParticipacionCampaniaSocio P WITH(UPDLOCK,HOLDLOCK)
        WHERE P.campania_venta_id=@nCamp AND P.estado=1 AND P.estado_participacion='ACTIVO';
    ELSE IF @cRegla IN ('PESO_ACEPTADO','VENTA_BRUTA')
    BEGIN
        -- El detalle se agrega por entrega ANTES del JOIN: el peso no se multiplica por cada clasificación.
        INSERT @Distribucion(participacion_id,base_calculo,importe)
        SELECT P.participacion_campania_socio_id,
               CONVERT(DECIMAL(28,8),SUM(CASE WHEN @cRegla='PESO_ACEPTADO'
                    THEN CONVERT(DECIMAL(28,8),COALESCE(E.peso_aceptado_kg,0))
                    ELSE CONVERT(DECIMAL(28,8),COALESCE(D.importe,0)) END)),0
        FROM comercial.ParticipacionCampaniaSocio P WITH(UPDLOCK,HOLDLOCK)
        LEFT JOIN comercial.OperativoSocio OS ON OS.participacion_campania_socio_id=P.participacion_campania_socio_id AND OS.estado=1
        LEFT JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
        OUTER APPLY
        (
            SELECT SUM(CONVERT(DECIMAL(28,8),ED.importe)) AS importe
            FROM comercial.EntregaDetalle ED WHERE ED.entrega_socio_id=E.entrega_socio_id AND ED.estado=1
        ) D
        WHERE P.campania_venta_id=@nCamp AND P.estado=1 AND P.estado_participacion='ACTIVO'
          AND (@nOpVenta IS NULL OR OS.operativo_venta_id=@nOpVenta)
        GROUP BY P.participacion_campania_socio_id;
        DELETE @Distribucion WHERE base_calculo<=0;
    END
    ELSE THROW 51004, N'DESCO_PRORRATEO_INVALIDO', 1;
    SELECT @nBase=SUM(base_calculo) FROM @Distribucion;
    IF COALESCE(@nBase,0)<=0
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
 SET @cMensaje=N'No hay participantes o información suficiente para distribuir el gasto con esta regla.';
 GOTO Fallar;
    END;
    -- Convertir la proporción primero evita una multiplicación desbordada de importes.
    UPDATE @Distribucion SET importe=CONVERT(DECIMAL(19,4),ROUND(
        @nImporte * CONVERT(DECIMAL(18,12),base_calculo / @nBase),4));
END;
DECLARE @nDif DECIMAL(19,4), @nAjustar BIGINT;
SELECT @nDif=@nImporte-COALESCE(SUM(importe),0) FROM @Distribucion;
-- Ajustar el importe mayor evita convertir una asignación cero en negativa.
SELECT TOP(1) @nAjustar=participacion_id FROM @Distribucion ORDER BY importe DESC,participacion_id;
UPDATE @Distribucion SET importe=importe+@nDif WHERE participacion_id=@nAjustar;
IF NOT EXISTS(SELECT 1 FROM @Distribucion) OR EXISTS(SELECT 1 FROM @Distribucion WHERE importe<0)
   OR (SELECT SUM(importe) FROM @Distribucion)<>@nImporte
    THROW 51004, N'DESCO_PRORRATEO_INVALIDO', 1;
-- Reutilizar la misma fila evita violar UQ_GastoProrrateoSocio al recalcular.
UPDATE GP SET estado=0
FROM finanzas.GastoProrrateoSocio GP
WHERE GP.gasto_campania_id=@nId
  AND NOT EXISTS(SELECT 1 FROM @Distribucion D WHERE D.participacion_id=GP.participacion_campania_socio_id);
UPDATE GP SET importe_asignado=D.importe,estado=1
FROM finanzas.GastoProrrateoSocio GP
JOIN @Distribucion D ON D.participacion_id=GP.participacion_campania_socio_id
WHERE GP.gasto_campania_id=@nId;
INSERT finanzas.GastoProrrateoSocio(gasto_campania_id,participacion_campania_socio_id,importe_asignado,estado)
SELECT @nId,D.participacion_id,D.importe,1 FROM @Distribucion D
WHERE NOT EXISTS
(
    SELECT 1 FROM finanzas.GastoProrrateoSocio GP WITH(UPDLOCK,HOLDLOCK)
    WHERE GP.gasto_campania_id=@nId AND GP.participacion_campania_socio_id=D.participacion_id
);
SET @cIdent=CONVERT(NVARCHAR(200),@nId);
EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @nUsuario,@nSesion,@nDisp,@nModulo,'PRORRATEAR','finanzas','GastoCampania',@cIdent,NULL,NULL,NULL,NULL,NULL,NULL,@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
/* Confirmar datos e idempotencia juntos. */EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='COMPLETADA',@cEsquemaEntidad='finanzas',@cNombreEntidad='GastoCampania',@cIdentificadorResultado=@cIdent,@cCodigoResultado='GASTO_PRORRATEADO',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
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
SET @cMensaje=N'Prorrateo calculado correctamente.';
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
SET @cMensaje=N'No se pudo calcular el prorrateo. Intente nuevamente.';
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'finanzas.PA_GastoCampania_Ins_EjecutarProrrateo',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;
Fallar: IF @nOp IS NOT NULL AND @bResultado=0 EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='FALLIDA',@cEsquemaEntidad=NULL,@cNombreEntidad=NULL,@cIdentificadorResultado=NULL,@cCodigoResultado='NO_PROCESADO',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
 
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
    @cProcedimiento = N'finanzas.PA_GastoCampania_Ins_EjecutarProrrateo',
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
    @cProcedimiento = N'finanzas.PA_GastoCampania_Ins_EjecutarProrrateo',
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
    @cProcedimiento = N'finanzas.PA_GastoCampania_Ins_EjecutarProrrateo',
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
FROM config.FN_RespuestaUsuario(N'finanzas.PA_GastoCampania_Ins_EjecutarProrrateo',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
