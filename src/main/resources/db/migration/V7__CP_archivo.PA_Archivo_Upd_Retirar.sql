IF OBJECT_ID(N'[archivo].[PA_Archivo_Upd_Retirar]', N'P') IS NOT NULL
    DROP PROCEDURE [archivo].[PA_Archivo_Upd_Retirar];
GO

/******************************************************************************************************
' Nombre del PA           : archivo.PA_Archivo_Upd_Retirar
' Descripción             : Retira un archivo aplicando las validaciones de autorización.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Archivo
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
    EXEC [archivo].[PA_Archivo_Upd_Retirar]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [archivo].[PA_Archivo_Upd_Retirar]
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
        @nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),
        @bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),
        @nAud BIGINT,@nTrans BIGINT,@nId BIGINT,@cMotivo NVARCHAR(300),@cIdent NVARCHAR(200);

    SELECT @bResultado=0,@cMensaje=N'No se pudo retirar el documento.';

    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente]
        @cJson=@cJson,@cCodigoPermiso='ARCHIVOS_RETIRAR',@cAmbito='ARCHIVO_RETIRAR',
        @nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,
        @nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,
        @nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,
        @cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@nOperacionIdempotenteId=@nOp OUTPUT,
        @bEsRepetida=@bRep OUTPUT,@cEstadoOperacion=@cEstadoOp OUTPUT,
        @cIdentificadorResultado=@cIdRes OUTPUT,@cCodigoResultado=@cCodRes OUTPUT,
        @bResultado=@bIni OUTPUT,@cMensaje=@cMsg OUTPUT;

    IF @bIni=0 AND @bRep=0
    BEGIN
        SET @cMensaje=@cMsg;
        GOTO __DESCO_Salida;
    END;

    IF @bRep=1
    BEGIN
        SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END;
        SET @cMensaje=CASE
            WHEN @cEstadoOp='COMPLETADA' THEN N'La solicitud ya fue procesada correctamente.'
            ELSE N'La solicitud ya se encuentra en proceso.'
        END;
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nId=archivoId,
        @cMotivo=NULLIF(LTRIM(RTRIM(motivo)),N'')
    FROM OPENJSON(@cJson,'$.archivo')
    WITH
    (
        archivoId BIGINT '$.archivoId',
        motivo NVARCHAR(300) '$.motivo'
    );

    IF @nId IS NULL OR @cMotivo IS NULL
    BEGIN
        SET @cMensaje=N'Seleccione el documento e indique el motivo.';
        GOTO Fallar;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [archivo].[Archivo]
        WHERE archivo_id=@nId
          AND estado=1
    )
    BEGIN
        SET @cMensaje=N'El documento seleccionado no está disponible.';
        GOTO Fallar;
    END;

    DECLARE @PermisosContexto TABLE(codigo VARCHAR(40) NOT NULL PRIMARY KEY);
    INSERT INTO @PermisosContexto(codigo)
    SELECT DISTINCT P.codigo
    FROM [seg].[UsuarioRol] UR
    INNER JOIN [seg].[Rol] R ON R.rol_id=UR.rol_id AND R.estado=1
    INNER JOIN [seg].[RolPermiso] RP ON RP.rol_id=R.rol_id AND RP.estado=1
    INNER JOIN [seg].[Permiso] P ON P.permiso_id=RP.permiso_id AND P.estado=1
    WHERE UR.usuario_id=@nUsuario
      AND UR.estado=1
      AND UR.fecha_desde<=SYSUTCDATETIME()
      AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta>=SYSUTCDATETIME());

    IF NOT EXISTS
    (
        SELECT 1
        FROM [archivo].[ArchivoVinculo] V
        WHERE V.archivo_id=@nId
          AND V.estado=1
          AND (
            (V.socio_id IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('PRODUCTORES_LISTAR','PRODUCTORES_VER')))
         OR (V.empleado_id IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('EMPLEADOS_LISTAR','EMPLEADOS_VER')))
         OR (V.predio_id IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('PREDIOS_LISTAR','PREDIOS_VER')))
         OR ((V.parcela_id IS NOT NULL OR V.parcela_cultivo_id IS NOT NULL) AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('CULTIVOS_LISTAR','CULTIVOS_VER')))
         OR (V.censo_plantas_id IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('CENSOS_LISTAR','CENSOS_VER')))
         OR (V.salida_campo_id IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('SALIDAS_LISTAR','SALIDAS_VER')))
         OR (V.visita_tecnica_id IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('VISITAS_LISTAR','VISITAS_VER')))
         OR (V.evaluacion_agronomica_id IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('EVALUACIONES_LISTAR','EVALUACIONES_VER')))
         OR ((V.caso_fitosanitario_id IS NOT NULL OR V.tratamiento_id IS NOT NULL OR V.seguimiento_fitosanitario_id IS NOT NULL) AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('SANIDAD_LISTAR','SANIDAD_VER')))
         OR (V.disponibilidad_produccion_id IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('PRODUCCION_LISTAR','PRODUCCION_VER')))
         OR (V.campania_venta_id IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('CAMPANIAS_LISTAR','CAMPANIAS_VER')))
         OR (V.precio_comercial_id IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('PRECIOS_LISTAR','PRECIOS_VER')))
         OR (V.participacion_campania_socio_id IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('PARTICIPANTES_LISTAR','PARTICIPANTES_VER')))
         OR (V.operativo_venta_id IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('OPERATIVOS_LISTAR','OPERATIVOS_VER')))
         OR ((V.jaba_asignacion_id IS NOT NULL OR V.jaba_devolucion_id IS NOT NULL) AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('JABAS_LISTAR','JABAS_VER')))
         OR (V.entrega_socio_id IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('ENTREGAS_LISTAR','ENTREGAS_VER')))
         OR (V.incidencia_operativa_id IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('INCIDENCIAS_LISTAR','INCIDENCIAS_VER')))
         OR (V.ajuste_precio_socio_id IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('AJUSTES_LISTAR','AJUSTES_VER')))
         OR (V.bien_inventario_id IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('INVENTARIO_LISTAR','INVENTARIO_VER')))
         OR (V.recurso_programado_id IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('RECURSOS_LISTAR','RECURSOS_VER')))
         OR (V.gasto_campania_id IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('GASTOS_LISTAR','GASTOS_VER')))
         OR (V.liquidacion_socio_id IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('LIQUIDACIONES_LISTAR','LIQUIDACIONES_VER')))
         OR (V.pago_socio_id IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('PAGOS_LISTAR','PAGOS_VER')))
         OR (V.cobro_comprador_id IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('COBROS_LISTAR','COBROS_VER')))
        )
    )
    BEGIN
        SET @cMensaje=N'El documento seleccionado no está disponible dentro de su contexto autorizado.';
        GOTO Fallar;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM [archivo].[ArchivoVinculo] V
        LEFT JOIN [campo].[SalidaCampo] SC
            ON SC.salida_campo_id=V.salida_campo_id
        LEFT JOIN [campo].[VisitaTecnica] VT
            ON VT.visita_tecnica_id=V.visita_tecnica_id
        LEFT JOIN [campo].[EvaluacionAgronomica] EA
            ON EA.evaluacion_agronomica_id=V.evaluacion_agronomica_id
        LEFT JOIN [campo].[VisitaTecnica] VEA
            ON VEA.visita_tecnica_id=EA.visita_tecnica_id
        LEFT JOIN [sanidad].[CasoFitosanitario] CF
            ON CF.caso_fitosanitario_id=V.caso_fitosanitario_id
        LEFT JOIN [sanidad].[TratamientoFitosanitario] TF
            ON TF.tratamiento_fitosanitario_id=V.tratamiento_id
        LEFT JOIN [sanidad].[CasoFitosanitario] CFT
            ON CFT.caso_fitosanitario_id=TF.caso_fitosanitario_id
        LEFT JOIN [sanidad].[SeguimientoFitosanitario] SF
            ON SF.seguimiento_fitosanitario_id=V.seguimiento_fitosanitario_id
        LEFT JOIN [sanidad].[CasoFitosanitario] CFS
            ON CFS.caso_fitosanitario_id=SF.caso_fitosanitario_id
        LEFT JOIN [prod].[DisponibilidadProduccion] DP
            ON DP.disponibilidad_produccion_id=V.disponibilidad_produccion_id
        LEFT JOIN [prod].[ParcelaCultivo] PCV
            ON PCV.parcela_cultivo_id=V.parcela_cultivo_id
        LEFT JOIN [prod].[CensoPlantas] CEN
            ON CEN.censo_plantas_id=V.censo_plantas_id
        LEFT JOIN [prod].[ParcelaCultivo] PCEN
            ON PCEN.parcela_cultivo_id=CEN.parcela_cultivo_id
        LEFT JOIN [comercial].[EntregaSocio] E
            ON E.entrega_socio_id=V.entrega_socio_id
        LEFT JOIN [finanzas].[GastoCampania] G
            ON G.gasto_campania_id=V.gasto_campania_id
        LEFT JOIN [finanzas].[LiquidacionSocio] L
            ON L.liquidacion_socio_id=V.liquidacion_socio_id
        LEFT JOIN [finanzas].[PagoSocio] P
            ON P.pago_socio_id=V.pago_socio_id
        LEFT JOIN [finanzas].[CobroComprador] C
            ON C.cobro_comprador_id=V.cobro_comprador_id
        WHERE V.archivo_id=@nId
          AND V.estado=1
          AND
          (
              SC.estado_proceso IN('FINALIZADA','CANCELADA')
              OR VT.estado_proceso IN('FINALIZADA','ANULADA')
              OR VEA.estado_proceso IN('FINALIZADA','ANULADA')
              OR CF.estado_caso='CERRADO'
              OR CFT.estado_caso='CERRADO'
              OR CFS.estado_caso='CERRADO'
              OR DP.estado_estimacion IN('CONFIRMADA','DESCARTADA')
              OR PCV.situacion_cultivo IN('FINALIZADO','ABANDONADO')
              OR PCEN.situacion_cultivo IN('FINALIZADO','ABANDONADO')
              OR E.estado_proceso='CONFIRMADA'
              OR G.estado_proceso='APROBADO'
              OR L.estado_proceso IN('APROBADA','PAGADA_PARCIAL','PAGADA')
              OR P.estado_proceso='CONFIRMADO'
              OR C.estado_proceso='CONFIRMADO'
          )
    )
    BEGIN
        SET @cMensaje=N'El documento forma parte de un registro ya cerrado o confirmado y debe conservarse como evidencia.';
        GOTO Fallar;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM [archivo].[ArchivoVinculo] V
        LEFT JOIN [comercial].[CampaniaVenta] CA ON CA.campania_venta_id=V.campania_venta_id
        LEFT JOIN [comercial].[PrecioComercial] PR ON PR.precio_comercial_id=V.precio_comercial_id
        LEFT JOIN [comercial].[CampaniaVenta] CAPR ON CAPR.campania_venta_id=PR.campania_venta_id
        LEFT JOIN [comercial].[ParticipacionCampaniaSocio] PCS ON PCS.participacion_campania_socio_id=V.participacion_campania_socio_id
        LEFT JOIN [comercial].[CampaniaVenta] CAPS ON CAPS.campania_venta_id=PCS.campania_venta_id
        LEFT JOIN [comercial].[OperativoVenta] OV ON OV.operativo_venta_id=V.operativo_venta_id
        LEFT JOIN [comercial].[JabaAsignacion] JA ON JA.jaba_asignacion_id=V.jaba_asignacion_id
        LEFT JOIN [comercial].[OperativoSocio] OSA ON OSA.operativo_socio_id=JA.operativo_socio_id
        LEFT JOIN [comercial].[OperativoVenta] OVA ON OVA.operativo_venta_id=OSA.operativo_venta_id
        LEFT JOIN [comercial].[JabaDevolucion] JD ON JD.jaba_devolucion_id=V.jaba_devolucion_id
        LEFT JOIN [comercial].[JabaAsignacion] JDA ON JDA.jaba_asignacion_id=JD.jaba_asignacion_id
        LEFT JOIN [comercial].[OperativoSocio] OSJ ON OSJ.operativo_socio_id=JDA.operativo_socio_id
        LEFT JOIN [comercial].[OperativoVenta] OVJ ON OVJ.operativo_venta_id=OSJ.operativo_venta_id
        LEFT JOIN [comercial].[EntregaSocio] EN ON EN.entrega_socio_id=V.entrega_socio_id
        LEFT JOIN [comercial].[IncidenciaOperativa] IO ON IO.incidencia_operativa_id=V.incidencia_operativa_id
        LEFT JOIN [comercial].[AjustePrecioSocio] AP ON AP.ajuste_precio_socio_id=V.ajuste_precio_socio_id
        LEFT JOIN [finanzas].[GastoCampania] GC ON GC.gasto_campania_id=V.gasto_campania_id
        LEFT JOIN [finanzas].[LiquidacionSocio] LS ON LS.liquidacion_socio_id=V.liquidacion_socio_id
        LEFT JOIN [finanzas].[PagoSocio] PS ON PS.pago_socio_id=V.pago_socio_id
        LEFT JOIN [finanzas].[CobroComprador] CB ON CB.cobro_comprador_id=V.cobro_comprador_id
        WHERE V.archivo_id=@nId
          AND V.estado=1
          AND
          (
              CA.estado_proceso IN('CERRADA','CANCELADA')
              OR PR.estado=0 OR CAPR.estado_proceso IN('CERRADA','CANCELADA')
              OR PCS.estado_participacion IN('RETIRADO','EXCLUIDO') OR CAPS.estado_proceso IN('CERRADA','CANCELADA')
              OR OV.estado_proceso IN('CERRADO','CANCELADO')
              OR JA.estado=0 OR OVA.estado_proceso IN('CERRADO','CANCELADO')
              OR JD.estado=0 OR OVJ.estado_proceso IN('CERRADO','CANCELADO')
              OR EN.estado_proceso='ANULADA'
              OR IO.estado_incidencia IN('RESUELTA','ANULADA')
              OR AP.estado_ajuste='ANULADO'
              OR GC.estado_proceso='ANULADO'
              OR LS.estado_proceso='ANULADA'
              OR PS.estado_proceso='ANULADO'
              OR CB.estado_proceso='ANULADO'
          )
    )
    BEGIN
        SET @cMensaje=N'El documento forma parte de un registro cerrado, resuelto o anulado y debe conservarse como evidencia.';
        GOTO Fallar;
    END;

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        UPDATE [archivo].[Archivo]
        SET estado=0,
            fecha_retiro=SYSUTCDATETIME(),
            usuario_retiro_id=@nUsuario,
            retirado_por_usuario_id=@nUsuario,
            motivo_retiro=@cMotivo
        WHERE archivo_id=@nId
          AND estado=1;

        UPDATE [archivo].[ArchivoVinculo]
        SET estado=0
        WHERE archivo_id=@nId
          AND estado=1;

        SET @cIdent=CONVERT(NVARCHAR(200),@nId);

        EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio]
            @nUsuario,@nSesion,@nDisp,@nModulo,'RETIRAR','archivo','Archivo',
            @cIdent,NULL,NULL,@cMotivo,'estado','1','0',
            @cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;

        /* Confirmar datos e idempotencia juntos. */

        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
            @nOperacionIdempotenteId=@nOp,
            @cEstadoOperacion='COMPLETADA',
            @cEsquemaEntidad='archivo',
            @cNombreEntidad='Archivo',
            @cIdentificadorResultado=@cIdent,
            @cCodigoResultado='ARCHIVO_RETIRADO',
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
        SET @cMensaje=N'Documento retirado correctamente.';
        GOTO __DESCO_Salida;
    END TRY
    BEGIN CATCH
SET @bResultado = 0;

        IF XACT_STATE()<>0
            BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;

        SET @cMensaje=N'No se pudo retirar el documento. Intente nuevamente.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'archivo.PA_Archivo_Upd_Retirar',
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
    @cProcedimiento = N'archivo.PA_Archivo_Upd_Retirar',
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
    @cProcedimiento = N'archivo.PA_Archivo_Upd_Retirar',
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
    @cProcedimiento = N'archivo.PA_Archivo_Upd_Retirar',
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
FROM config.FN_RespuestaUsuario(N'archivo.PA_Archivo_Upd_Retirar',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
