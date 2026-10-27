IF OBJECT_ID(N'[reporte].[PA_Reporte_Sel_Datos]', N'P') IS NOT NULL
    DROP PROCEDURE [reporte].[PA_Reporte_Sel_Datos];
GO

/******************************************************************************************************
' Nombre del PA           : reporte.PA_Reporte_Sel_Datos
' Descripción             : Consulta los datos de un reporte.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Reportes
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
    EXEC [reporte].[PA_Reporte_Sel_Datos]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [reporte].[PA_Reporte_Sel_Datos]
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

    DECLARE
        @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,
        @gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
        @bCtx BIT,@cMsg NVARCHAR(300),@cReporte VARCHAR(30),@dDesde DATE,@dHasta DATE,
        @nCamp BIGINT,@nOper BIGINT,@nZona BIGINT,@bPermitido BIT=0,@bSupervisionTransversal BIT=0;

    SELECT
        @bResultado=0,
        @cMensaje=N'No se pudo generar el reporte.';

    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
        @cJson=@cJson,
        @cCodigoPermiso='REPORTES_VER',
        @nUsuarioId=@nUsuario OUTPUT,
        @nSesionUsuarioId=@nSesion OUTPUT,
        @nDispositivoUsuarioId=@nDisp OUTPUT,
        @nEmpleadoId=@nEmp OUTPUT,
        @nModuloId=@nModulo OUTPUT,
        @gCorrelacionId=@gCorr OUTPUT,
        @gSolicitudId=@gSol OUTPUT,
        @cIp=@cIp OUTPUT,
        @cEndpoint=@cEnd OUTPUT,
        @bResultado=@bCtx OUTPUT,
        @cMensaje=@cMsg OUTPUT;

    IF @bCtx=0
    BEGIN
        SET @cMensaje=@cMsg;
        GOTO __DESCO_Salida;
    END;

    SELECT
        @cReporte=UPPER(NULLIF(LTRIM(RTRIM(reporte)),'')),
        @dDesde=fechaDesde,
        @dHasta=fechaHasta,
        @nCamp=campaniaVentaId,
        @nOper=operativoVentaId,
        @nZona=zonaProductivaId
    FROM OPENJSON(@cJson,'$.filtros')
    WITH
    (
        reporte VARCHAR(30) '$.reporte',
        fechaDesde DATE '$.fechaDesde',
        fechaHasta DATE '$.fechaHasta',
        campaniaVentaId BIGINT '$.campaniaVentaId',
        operativoVentaId BIGINT '$.operativoVentaId',
        zonaProductivaId BIGINT '$.zonaProductivaId'
    );

    IF @cReporte IS NULL
    BEGIN
        SET @cMensaje=N'Seleccione el reporte que desea consultar.';
        GOTO __DESCO_Salida;
    END;

    IF @dDesde IS NOT NULL AND @dHasta IS NOT NULL AND @dHasta<@dDesde
    BEGIN
        SET @cMensaje=N'El rango de fechas seleccionado no es válido.';
        GOTO __DESCO_Salida;
    END;

    DECLARE @Permisos TABLE
    (
        codigo VARCHAR(40) NOT NULL PRIMARY KEY
    );

    INSERT INTO @Permisos(codigo)
    SELECT DISTINCT P.codigo
    FROM [seg].[UsuarioRol] UR
    INNER JOIN [seg].[Rol] R
        ON R.rol_id=UR.rol_id
       AND R.estado=1
    INNER JOIN [seg].[RolPermiso] RP
        ON RP.rol_id=R.rol_id
       AND RP.estado=1
    INNER JOIN [seg].[Permiso] P
        ON P.permiso_id=RP.permiso_id
       AND P.estado=1
    WHERE UR.usuario_id=@nUsuario
      AND UR.estado=1
      AND UR.fecha_desde<=SYSUTCDATETIME()
      AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta>=SYSUTCDATETIME());

    SET @bSupervisionTransversal=
        CASE WHEN EXISTS(SELECT 1 FROM @Permisos WHERE codigo='AUDITORIA_VER') THEN 1 ELSE 0 END;

    IF @cReporte='TECNICO'
       AND
       (
           @bSupervisionTransversal=1
           OR
           (
               EXISTS(SELECT 1 FROM @Permisos WHERE codigo='PRODUCTORES_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='PREDIOS_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='EVALUACIONES_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='SANIDAD_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='PRODUCCION_LISTAR')
           )
       )
        SET @bPermitido=1;
    ELSE IF @cReporte='PLANIFICACION'
       AND
       (
           @bSupervisionTransversal=1
           OR
           (
               EXISTS(SELECT 1 FROM @Permisos WHERE codigo='SALIDAS_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='RECURSOS_LISTAR')
           )
       )
        SET @bPermitido=1;
    ELSE IF @cReporte='COMERCIAL'
       AND
       (
           @bSupervisionTransversal=1
           OR
           (
               EXISTS(SELECT 1 FROM @Permisos WHERE codigo='CAMPANIAS_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='OPERATIVOS_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='JABAS_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='ENTREGAS_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='INCIDENCIAS_LISTAR')
           )
       )
        SET @bPermitido=1;
    ELSE IF @cReporte='FINANCIERO'
       AND
       (
           @bSupervisionTransversal=1
           OR
           (
               EXISTS(SELECT 1 FROM @Permisos WHERE codigo='GASTOS_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='LIQUIDACIONES_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='PAGOS_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='COBROS_LISTAR')
           )
       )
        SET @bPermitido=1;

    IF @bPermitido=0
    BEGIN
        SET @cMensaje=N'El reporte seleccionado no está habilitado para su perfil.';
        GOTO __DESCO_Salida;
    END;

    IF @cReporte='TECNICO'
    BEGIN
        SELECT
            (SELECT COUNT_BIG(*) FROM [org].[Socio] WHERE estado=1) productoresActivos,
            (SELECT COUNT_BIG(*) FROM [prod].[Predio] WHERE estado=1) prediosActivos,
            (SELECT COUNT_BIG(*) FROM [prod].[ParcelaCultivo] WHERE estado=1 AND situacion_cultivo='ACTIVO') cultivosActivos,
            (SELECT COUNT_BIG(*) FROM [campo].[EvaluacionAgronomica] WHERE estado=1 AND (@dDesde IS NULL OR CONVERT(DATE,fecha_hora)>=@dDesde) AND (@dHasta IS NULL OR CONVERT(DATE,fecha_hora)<=@dHasta)) evaluacionesPeriodo,
            (SELECT COUNT_BIG(*) FROM [campo].[VisitaTecnica] WHERE estado=1 AND (@dDesde IS NULL OR CONVERT(DATE,fecha_hora_inicio)>=@dDesde) AND (@dHasta IS NULL OR CONVERT(DATE,fecha_hora_inicio)<=@dHasta)) visitasPeriodo,
            (SELECT COUNT_BIG(*) FROM [sanidad].[CasoFitosanitario] WHERE estado=1 AND estado_caso<>'CERRADO') casosAbiertos,
            (SELECT COALESCE(SUM(cantidad_estimada_kg),0) FROM [prod].[DisponibilidadProduccion] WHERE estado=1 AND estado_estimacion='ESTIMADA') produccionEstimadaKg,
            (SELECT COALESCE(SUM(cantidad_estimada_kg),0) FROM [prod].[DisponibilidadProduccion] WHERE estado=1 AND estado_estimacion='CONFIRMADA') produccionConfirmadaKg;

        SELECT
            C.caso_fitosanitario_id casoId,
            C.fecha_deteccion fechaDeteccion,
            C.severidad,
            C.estado_caso estadoCaso,
            T.nombre problema,
            PC.parcela_cultivo_id parcelaCultivoId
        FROM [sanidad].[CasoFitosanitario] C
        INNER JOIN [sanidad].[TipoProblemaFitosanitario] T
            ON T.tipo_problema_fitosanitario_id=C.tipo_problema_fitosanitario_id
        INNER JOIN [prod].[ParcelaCultivo] PC
            ON PC.parcela_cultivo_id=C.parcela_cultivo_id
        WHERE C.estado=1
          AND C.estado_caso<>'CERRADO'
          AND (@dDesde IS NULL OR CONVERT(DATE,C.fecha_deteccion)>=@dDesde)
          AND (@dHasta IS NULL OR CONVERT(DATE,C.fecha_deteccion)<=@dHasta)
        ORDER BY C.fecha_deteccion DESC;

        SELECT
            EA.evaluacion_agronomica_id evaluacionAgronomicaId,
            EA.fecha_hora fechaHora,
            TE.nombre tipoEvaluacion,
            EA.resultado,
            EMS.porcentaje_materia_seca porcentajeMateriaSeca,
            EMS.numero_muestras numeroMuestras
        FROM [campo].[EvaluacionAgronomica] EA
        INNER JOIN [campo].[TipoEvaluacion] TE
            ON TE.tipo_evaluacion_id=EA.tipo_evaluacion_id
        LEFT JOIN [campo].[EvaluacionMateriaSeca] EMS
            ON EMS.evaluacion_materia_seca_id=EA.evaluacion_agronomica_id
           AND EMS.estado=1
        WHERE EA.estado=1
          AND (@dDesde IS NULL OR CONVERT(DATE,EA.fecha_hora)>=@dDesde)
          AND (@dHasta IS NULL OR CONVERT(DATE,EA.fecha_hora)<=@dHasta)
        ORDER BY EA.fecha_hora DESC;
    END
    ELSE IF @cReporte='PLANIFICACION'
    BEGIN
        SELECT
            S.salida_campo_id salidaCampoId,
            S.fecha_hora_programada fechaProgramada,
            S.estado_proceso estadoProceso,
            M.nombre motivo,
            COUNT(V.visita_tecnica_id) visitasRegistradas
        FROM [campo].[SalidaCampo] S
        INNER JOIN [campo].[MotivoSalida] M
            ON M.motivo_salida_id=S.motivo_salida_id
        LEFT JOIN [campo].[SalidaParticipante] SP
            ON SP.salida_campo_id=S.salida_campo_id
           AND SP.estado=1
        LEFT JOIN [campo].[VisitaTecnica] V
            ON V.salida_participante_id=SP.salida_participante_id
           AND V.estado=1
        WHERE S.estado=1
          AND (@dDesde IS NULL OR CONVERT(DATE,S.fecha_hora_programada)>=@dDesde)
          AND (@dHasta IS NULL OR CONVERT(DATE,S.fecha_hora_programada)<=@dHasta)
        GROUP BY S.salida_campo_id,S.fecha_hora_programada,S.estado_proceso,M.nombre
        ORDER BY S.fecha_hora_programada;

        SELECT
            R.recurso_programado_id recursoProgramadoId,
            R.estado_proceso estadoProceso,
            R.cantidad_programada cantidadProgramada,
            COALESCE
            (
                (
                    SELECT SUM(M.cantidad)
                    FROM [logistica].[RecursoMovimiento] M
                    WHERE M.recurso_programado_id=R.recurso_programado_id
                      AND M.estado=1
                      AND M.tipo_movimiento IN('ASIGNACION','ENTREGA','CONSUMO')
                ),0
            ) cantidadEjecutada
        FROM [logistica].[RecursoProgramado] R
        WHERE R.estado=1
          AND (@nCamp IS NULL OR R.campania_venta_id=@nCamp)
          AND (@nOper IS NULL OR R.operativo_venta_id=@nOper)
        ORDER BY R.recurso_programado_id DESC;
    END
    ELSE IF @cReporte='COMERCIAL'
    BEGIN
        SELECT
            O.operativo_venta_id operativoVentaId,
            O.codigo,
            O.estado_proceso estadoProceso,
            O.fecha_inicio_programada fechaInicioProgramada,
            COALESCE(SUM(CASE WHEN E.estado=1 AND E.estado_proceso='CONFIRMADA' THEN E.peso_bruto_kg ELSE 0 END),0) kilosBrutos,
            COALESCE(SUM(CASE WHEN E.estado=1 AND E.estado_proceso='CONFIRMADA' THEN E.peso_aceptado_kg ELSE 0 END),0) kilosAceptados,
            COALESCE(SUM(CASE WHEN E.estado=1 AND E.estado_proceso='CONFIRMADA' THEN E.peso_rechazado_kg ELSE 0 END),0) kilosRechazados,
            (
                SELECT COUNT_BIG(*)
                FROM [comercial].[IncidenciaOperativa] I
                WHERE I.operativo_venta_id=O.operativo_venta_id
                  AND I.estado=1
                  AND I.estado_incidencia<>'ANULADA'
            ) incidencias
        FROM [comercial].[OperativoVenta] O
        LEFT JOIN [comercial].[OperativoSocio] OS
            ON OS.operativo_venta_id=O.operativo_venta_id
           AND OS.estado=1
        LEFT JOIN [comercial].[EntregaSocio] E
            ON E.operativo_socio_id=OS.operativo_socio_id
        WHERE O.estado=1
          AND (@nCamp IS NULL OR O.campania_venta_id=@nCamp)
          AND (@nOper IS NULL OR O.operativo_venta_id=@nOper)
          AND (@dDesde IS NULL OR CONVERT(DATE,O.fecha_inicio_programada)>=@dDesde)
          AND (@dHasta IS NULL OR CONVERT(DATE,O.fecha_inicio_programada)<=@dHasta)
          AND
          (
              @nZona IS NULL
              OR EXISTS
              (
                  SELECT 1
                  FROM [comercial].[OperativoZona] OZ
                  WHERE OZ.operativo_venta_id=O.operativo_venta_id
                    AND OZ.zona_productiva_id=@nZona
                    AND OZ.estado=1
              )
          )
        GROUP BY O.operativo_venta_id,O.codigo,O.estado_proceso,O.fecha_inicio_programada
        ORDER BY O.fecha_inicio_programada DESC;

        SELECT
            JM.operativo_venta_id operativoVentaId,
            SUM(CASE WHEN JM.tipo_movimiento IN('RECEPCION','AJUSTE_ENTRADA') THEN JM.cantidad WHEN JM.tipo_movimiento='AJUSTE_SALIDA' THEN -JM.cantidad ELSE 0 END) jabasRecibidas,
            SUM(CASE WHEN JM.tipo_movimiento='ASIGNACION' THEN JM.cantidad ELSE 0 END) jabasAsignadas,
            SUM(CASE WHEN JM.tipo_movimiento IN('DEVOLUCION_LLENA','DEVOLUCION_VACIA') THEN JM.cantidad ELSE 0 END) jabasDevueltas
        FROM [comercial].[JabaMovimiento] JM
        WHERE JM.estado=1
          AND (@nOper IS NULL OR JM.operativo_venta_id=@nOper)
        GROUP BY JM.operativo_venta_id;
    END
    ELSE IF @cReporte='FINANCIERO'
    BEGIN
        SELECT
            C.campania_venta_id campaniaVentaId,
            C.nombre campania,
            COALESCE
            (
                (
                    SELECT SUM(G.importe)
                    FROM [finanzas].[GastoCampania] G
                    WHERE G.campania_venta_id=C.campania_venta_id
                      AND G.estado=1
                      AND G.estado_proceso='APROBADO'
                ),0
            ) gastosAprobados,
            COALESCE
            (
                (
                    SELECT SUM(L.importe_neto)
                    FROM [finanzas].[LiquidacionSocio] L
                    INNER JOIN [comercial].[ParticipacionCampaniaSocio] P
                        ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
                    WHERE P.campania_venta_id=C.campania_venta_id
                      AND L.estado=1
                      AND L.estado_proceso IN('APROBADA','PAGADA_PARCIAL','PAGADA')
                ),0
            ) liquidado,
            COALESCE
            (
                (
                    SELECT SUM(PG.importe)
                    FROM [finanzas].[PagoSocio] PG
                    INNER JOIN [finanzas].[LiquidacionSocio] L
                        ON L.liquidacion_socio_id=PG.liquidacion_socio_id
                    INNER JOIN [comercial].[ParticipacionCampaniaSocio] P
                        ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
                    WHERE P.campania_venta_id=C.campania_venta_id
                      AND PG.estado=1
                      AND PG.estado_proceso='CONFIRMADO'
                ),0
            ) pagado,
            COALESCE
            (
                (
                    SELECT SUM(CB.importe)
                    FROM [finanzas].[CobroComprador] CB
                    WHERE CB.campania_venta_id=C.campania_venta_id
                      AND CB.estado=1
                      AND CB.estado_proceso='CONFIRMADO'
                ),0
            ) cobrado
        FROM [comercial].[CampaniaVenta] C
        WHERE C.estado=1
          AND (@nCamp IS NULL OR C.campania_venta_id=@nCamp)
        ORDER BY C.fecha_inicio DESC;
    END;

    SET @bResultado=1;
    SET @cMensaje=N'Reporte generado correctamente.';

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
    @cProcedimiento = N'reporte.PA_Reporte_Sel_Datos',
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
    @cProcedimiento = N'reporte.PA_Reporte_Sel_Datos',
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
FROM config.FN_RespuestaUsuario(N'reporte.PA_Reporte_Sel_Datos',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
