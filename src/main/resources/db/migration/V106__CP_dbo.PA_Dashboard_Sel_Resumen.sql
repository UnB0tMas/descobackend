IF OBJECT_ID(N'[dbo].[PA_Dashboard_Sel_Resumen]', N'P') IS NOT NULL
    DROP PROCEDURE [dbo].[PA_Dashboard_Sel_Resumen];
GO

/******************************************************************************************************
' Nombre del PA           : dbo.PA_Dashboard_Sel_Resumen
' Descripción             : Consulta el resumen del panel de control.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Panel de control
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
    EXEC [dbo].[PA_Dashboard_Sel_Resumen]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [dbo].[PA_Dashboard_Sel_Resumen]
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
        @nUsuario BIGINT,
        @nSesion BIGINT,
        @nDisp BIGINT,
        @nEmp BIGINT,
        @nModulo INT,
        @gCorr UNIQUEIDENTIFIER,
        @gSol UNIQUEIDENTIFIER,
        @cIp VARCHAR(64),
        @cEnd NVARCHAR(250),
        @bCtx BIT,
        @cMsg NVARCHAR(300),
        @dDesde DATE,
        @dHasta DATE,
        @dtDesde DATETIME2(0),
        @dtHastaExclusivo DATETIME2(0);

    SELECT
        @bResultado=0,
        @cMensaje=N'No se pudo cargar el inicio.';

    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
        @cJson=@cJson,
        @cCodigoPermiso='INICIO_LISTAR',
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

    SET @dHasta=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.hasta'));
    SET @dDesde=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.desde'));

    IF @dHasta IS NULL
        SET @dHasta=CONVERT(DATE,SYSUTCDATETIME());

    IF @dDesde IS NULL
        SET @dDesde=DATEADD(DAY,-89,@dHasta);

    IF @dDesde>@dHasta
    BEGIN
        SET @cMensaje=N'La fecha desde no puede ser posterior a la fecha hasta.';
        GOTO __DESCO_Salida;
    END;

    IF DATEDIFF(DAY,@dDesde,@dHasta)>365
    BEGIN
        SET @cMensaje=N'El dashboard admite como máximo 366 días por consulta.';
        GOTO __DESCO_Salida;
    END;

    IF @dHasta>CONVERT(DATE,SYSUTCDATETIME())
    BEGIN
        SET @cMensaje=N'La fecha hasta no puede ser posterior a la fecha actual.';
        GOTO __DESCO_Salida;
    END;

    SET @dtDesde=CONVERT(DATETIME2(0),@dDesde);
    SET @dtHastaExclusivo=DATEADD(DAY,1,CONVERT(DATETIME2(0),@dHasta));

    /* ------------------------------------------------------------------------
       5.1. Permisos efectivos de la sesión
       ------------------------------------------------------------------------ */
    CREATE TABLE #Permisos
    (
        permiso_id BIGINT NOT NULL PRIMARY KEY,
        codigo VARCHAR(80) NOT NULL,
        modulo_id INT NOT NULL
    );

    INSERT INTO #Permisos(permiso_id,codigo,modulo_id)
    SELECT DISTINCT
        P.permiso_id,
        P.codigo,
        P.modulo_id
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

    /* ------------------------------------------------------------------------
       5.2. Elementos visibles

       La excepción de usuario prevalece sobre las asignaciones de rol.
       El JOIN contra #Permisos evita usar el dashboard como bypass de RBAC.
       ------------------------------------------------------------------------ */
    CREATE TABLE #ElementosVisibles
    (
        dashboard_elemento_id BIGINT NOT NULL PRIMARY KEY,
        codigo VARCHAR(80) NOT NULL,
        tipo VARCHAR(12) NOT NULL,
        titulo NVARCHAR(180) NOT NULL,
        subtitulo NVARCHAR(300) NULL,
        permiso_id BIGINT NOT NULL,
        permiso_codigo VARCHAR(80) NOT NULL,
        modulo_id INT NOT NULL,
        unidad NVARCHAR(30) NULL,
        icono VARCHAR(80) NULL,
        tipo_grafico VARCHAR(20) NULL,
        permite_fechas BIT NOT NULL,
        ancho TINYINT NOT NULL,
        orden SMALLINT NOT NULL
    );

    INSERT INTO #ElementosVisibles
    (
        dashboard_elemento_id,codigo,tipo,titulo,subtitulo,permiso_id,
        permiso_codigo,modulo_id,unidad,icono,tipo_grafico,permite_fechas,
        ancho,orden
    )
    SELECT
        E.dashboard_elemento_id,
        E.codigo,
        E.tipo,
        E.titulo,
        E.subtitulo,
        E.permiso_id,
        P.codigo,
        P.modulo_id,
        E.unidad,
        E.icono,
        E.tipo_grafico,
        E.permite_fechas,
        E.ancho,
        CONVERT(SMALLINT,COALESCE(U.orden,RX.orden_rol,E.orden))
    FROM [config].[DashboardElemento] E
    INNER JOIN #Permisos P
        ON P.permiso_id=E.permiso_id
    OUTER APPLY
    (
        SELECT TOP(1)
            UE.usuario_id,
            UE.visible,
            UE.orden
        FROM [config].[DashboardUsuarioElemento] UE
        WHERE UE.usuario_id=@nUsuario
          AND UE.dashboard_elemento_id=E.dashboard_elemento_id
    ) U
    OUTER APPLY
    (
        SELECT
            CONVERT(BIT,1) tiene_rol_visible,
            MIN(RE.orden) orden_rol
        FROM [config].[DashboardRolElemento] RE
        INNER JOIN [seg].[UsuarioRol] UR
            ON UR.rol_id=RE.rol_id
           AND UR.usuario_id=@nUsuario
           AND UR.estado=1
           AND UR.fecha_desde<=SYSUTCDATETIME()
           AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta>=SYSUTCDATETIME())
        INNER JOIN [seg].[Rol] R
            ON R.rol_id=UR.rol_id
           AND R.estado=1
        WHERE RE.dashboard_elemento_id=E.dashboard_elemento_id
          AND RE.visible=1
        HAVING COUNT_BIG(*)>0
    ) RX
    WHERE E.estado=1
      AND
      (
          (U.usuario_id IS NOT NULL AND U.visible=1)
          OR
          (U.usuario_id IS NULL AND RX.tiene_rol_visible=1)
      );

    /* ------------------------------------------------------------------------
       5.3. KPI: solo se calcula lo que realmente será mostrado
       ------------------------------------------------------------------------ */
    CREATE TABLE #KpiValor
    (
        codigo VARCHAR(80) NOT NULL PRIMARY KEY,
        valor DECIMAL(19,2) NOT NULL
    );

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_PRODUCTORES_ACTIVOS')
        INSERT INTO #KpiValor SELECT 'KPI_PRODUCTORES_ACTIVOS',CONVERT(DECIMAL(19,2),COUNT_BIG(*)) FROM [org].[Socio] WHERE estado=1;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_PREDIOS_ACTIVOS')
        INSERT INTO #KpiValor SELECT 'KPI_PREDIOS_ACTIVOS',CONVERT(DECIMAL(19,2),COUNT_BIG(*)) FROM [prod].[Predio] WHERE estado=1;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_CULTIVOS_ACTIVOS')
        INSERT INTO #KpiValor SELECT 'KPI_CULTIVOS_ACTIVOS',CONVERT(DECIMAL(19,2),COUNT_BIG(*)) FROM [prod].[ParcelaCultivo] WHERE estado=1 AND situacion_cultivo='ACTIVO';

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_CENSOS_PERIODO')
        INSERT INTO #KpiValor
        SELECT 'KPI_CENSOS_PERIODO',CONVERT(DECIMAL(19,2),COUNT_BIG(*))
        FROM [prod].[CensoPlantas]
        WHERE estado=1
          AND fecha_censo>=@dDesde
          AND fecha_censo<=@dHasta;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_SALIDAS_PROGRAMADAS')
        INSERT INTO #KpiValor SELECT 'KPI_SALIDAS_PROGRAMADAS',CONVERT(DECIMAL(19,2),COUNT_BIG(*)) FROM [campo].[SalidaCampo] WHERE estado=1 AND estado_proceso='PROGRAMADA';

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_VISITAS_CURSO')
        INSERT INTO #KpiValor SELECT 'KPI_VISITAS_CURSO',CONVERT(DECIMAL(19,2),COUNT_BIG(*)) FROM [campo].[VisitaTecnica] WHERE estado=1 AND estado_proceso='INICIADA';

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_SANIDAD_ABIERTA')
        INSERT INTO #KpiValor SELECT 'KPI_SANIDAD_ABIERTA',CONVERT(DECIMAL(19,2),COUNT_BIG(*)) FROM [sanidad].[CasoFitosanitario] WHERE estado=1 AND estado_caso<>'CERRADO';

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_PRODUCCION_CONFIRMADA')
        INSERT INTO #KpiValor
        SELECT 'KPI_PRODUCCION_CONFIRMADA',CONVERT(DECIMAL(19,2),COALESCE(SUM(cantidad_estimada_kg),0))
        FROM [prod].[DisponibilidadProduccion]
        WHERE estado=1
          AND estado_estimacion='CONFIRMADA'
          AND fecha_estimacion>=@dtDesde
          AND fecha_estimacion<@dtHastaExclusivo;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_CAMPANIAS_ACTIVAS')
        INSERT INTO #KpiValor SELECT 'KPI_CAMPANIAS_ACTIVAS',CONVERT(DECIMAL(19,2),COUNT_BIG(*)) FROM [comercial].[CampaniaVenta] WHERE estado=1 AND estado_proceso='ACTIVA';

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_OPERATIVOS_RECEPCION')
        INSERT INTO #KpiValor SELECT 'KPI_OPERATIVOS_RECEPCION',CONVERT(DECIMAL(19,2),COUNT_BIG(*)) FROM [comercial].[OperativoVenta] WHERE estado=1 AND estado_proceso='EN_RECEPCION';

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_PRODUCTORES_PROGRAMADOS')
        INSERT INTO #KpiValor
        SELECT 'KPI_PRODUCTORES_PROGRAMADOS',CONVERT(DECIMAL(19,2),COUNT_BIG(*))
        FROM [comercial].[OperativoSocio] OS
        INNER JOIN [comercial].[OperativoVenta] O
            ON O.operativo_venta_id=OS.operativo_venta_id
           AND O.estado=1
           AND O.estado_proceso IN('PLANIFICADO','EN_RECEPCION')
        WHERE OS.estado=1
          AND OS.estado_participacion='PROGRAMADO';

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_JABAS_RECIBIDAS')
        INSERT INTO #KpiValor
        SELECT 'KPI_JABAS_RECIBIDAS',CONVERT(DECIMAL(19,2),COALESCE(SUM(CASE WHEN JM.tipo_movimiento IN('RECEPCION','AJUSTE_ENTRADA') THEN JM.cantidad WHEN JM.tipo_movimiento='AJUSTE_SALIDA' THEN -JM.cantidad ELSE 0 END),0))
        FROM [comercial].[JabaMovimiento] JM
        INNER JOIN [comercial].[OperativoVenta] O
            ON O.operativo_venta_id=JM.operativo_venta_id
           AND O.estado=1
           AND O.estado_proceso='EN_RECEPCION'
        WHERE JM.estado=1;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_JABAS_ASIGNADAS')
        INSERT INTO #KpiValor
        SELECT 'KPI_JABAS_ASIGNADAS',CONVERT(DECIMAL(19,2),COALESCE(SUM(CASE WHEN JM.tipo_movimiento='ASIGNACION' THEN JM.cantidad ELSE 0 END),0))
        FROM [comercial].[JabaMovimiento] JM
        INNER JOIN [comercial].[OperativoVenta] O
            ON O.operativo_venta_id=JM.operativo_venta_id
           AND O.estado=1
           AND O.estado_proceso='EN_RECEPCION'
        WHERE JM.estado=1;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_JABAS_PENDIENTES')
        INSERT INTO #KpiValor
        SELECT 'KPI_JABAS_PENDIENTES',CONVERT(DECIMAL(19,2),COALESCE(SUM(CASE WHEN JM.tipo_movimiento='ASIGNACION' THEN JM.cantidad WHEN JM.tipo_movimiento IN('DEVOLUCION_LLENA','DEVOLUCION_VACIA') THEN -JM.cantidad ELSE 0 END),0))
        FROM [comercial].[JabaMovimiento] JM
        INNER JOIN [comercial].[OperativoVenta] O
            ON O.operativo_venta_id=JM.operativo_venta_id
           AND O.estado=1
           AND O.estado_proceso='EN_RECEPCION'
        WHERE JM.estado=1;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_KILOS_RECIBIDOS')
        INSERT INTO #KpiValor
        SELECT 'KPI_KILOS_RECIBIDOS',CONVERT(DECIMAL(19,2),COALESCE(SUM(E.peso_aceptado_kg),0))
        FROM [comercial].[EntregaSocio] E
        WHERE E.estado=1
          AND E.estado_proceso='CONFIRMADA'
          AND E.fecha_hora>=@dtDesde
          AND E.fecha_hora<@dtHastaExclusivo;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_ENTREGAS_CONFIRMAR')
        INSERT INTO #KpiValor SELECT 'KPI_ENTREGAS_CONFIRMAR',CONVERT(DECIMAL(19,2),COUNT_BIG(*)) FROM [comercial].[EntregaSocio] WHERE estado=1 AND estado_proceso='REGISTRADA';

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_INCIDENCIAS_ABIERTAS')
        INSERT INTO #KpiValor SELECT 'KPI_INCIDENCIAS_ABIERTAS',CONVERT(DECIMAL(19,2),COUNT_BIG(*)) FROM [comercial].[IncidenciaOperativa] WHERE estado=1 AND estado_incidencia IN('ABIERTA','EN_REVISION');

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_BIENES_DISPONIBLES')
        INSERT INTO #KpiValor SELECT 'KPI_BIENES_DISPONIBLES',CONVERT(DECIMAL(19,2),COUNT_BIG(*)) FROM [logistica].[BienInventario] WHERE estado=1 AND estado_bien='DISPONIBLE';

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_BIENES_ASIGNADOS')
        INSERT INTO #KpiValor SELECT 'KPI_BIENES_ASIGNADOS',CONVERT(DECIMAL(19,2),COUNT_BIG(*)) FROM [logistica].[BienInventario] WHERE estado=1 AND estado_bien='ASIGNADO';

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_RECURSOS_PROGRAMADOS')
        INSERT INTO #KpiValor SELECT 'KPI_RECURSOS_PROGRAMADOS',CONVERT(DECIMAL(19,2),COUNT_BIG(*)) FROM [logistica].[RecursoProgramado] WHERE estado=1 AND estado_proceso='PROGRAMADO';

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_RECURSOS_PENDIENTES')
        INSERT INTO #KpiValor SELECT 'KPI_RECURSOS_PENDIENTES',CONVERT(DECIMAL(19,2),COUNT_BIG(*)) FROM [logistica].[RecursoProgramado] WHERE estado=1 AND estado_proceso='EN_EJECUCION';

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_GASTOS_APROBAR')
        INSERT INTO #KpiValor SELECT 'KPI_GASTOS_APROBAR',CONVERT(DECIMAL(19,2),COUNT_BIG(*)) FROM [finanzas].[GastoCampania] WHERE estado=1 AND estado_proceso='REGISTRADO';

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_LIQUIDACIONES_CALCULAR')
        INSERT INTO #KpiValor
        SELECT 'KPI_LIQUIDACIONES_CALCULAR',CONVERT(DECIMAL(19,2),COUNT_BIG(*))
        FROM [comercial].[ParticipacionCampaniaSocio] PCS
        WHERE PCS.estado=1
          AND PCS.estado_participacion='ACTIVO'
          AND EXISTS
          (
              SELECT 1
              FROM [comercial].[OperativoSocio] OS
              INNER JOIN [comercial].[EntregaSocio] E
                  ON E.operativo_socio_id=OS.operativo_socio_id
                 AND E.estado=1
                 AND E.estado_proceso='CONFIRMADA'
              WHERE OS.participacion_campania_socio_id=PCS.participacion_campania_socio_id
                AND OS.estado=1
          )
          AND NOT EXISTS
          (
              SELECT 1
              FROM [finanzas].[LiquidacionSocio] L
              WHERE L.participacion_campania_socio_id=PCS.participacion_campania_socio_id
                AND L.estado=1
                AND L.estado_proceso IN('CALCULADA','APROBADA','PAGADA_PARCIAL','PAGADA')
          );

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_LIQUIDACIONES_APROBAR')
        INSERT INTO #KpiValor SELECT 'KPI_LIQUIDACIONES_APROBAR',CONVERT(DECIMAL(19,2),COUNT_BIG(*)) FROM [finanzas].[LiquidacionSocio] WHERE estado=1 AND estado_proceso='CALCULADA';

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_PAGOS_CONFIRMAR')
        INSERT INTO #KpiValor SELECT 'KPI_PAGOS_CONFIRMAR',CONVERT(DECIMAL(19,2),COUNT_BIG(*)) FROM [finanzas].[PagoSocio] WHERE estado=1 AND estado_proceso='REGISTRADO';

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_COBROS_CONFIRMAR')
        INSERT INTO #KpiValor SELECT 'KPI_COBROS_CONFIRMAR',CONVERT(DECIMAL(19,2),COUNT_BIG(*)) FROM [finanzas].[CobroComprador] WHERE estado=1 AND estado_proceso='REGISTRADO';

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='KPI_SALDO_SOCIOS')
        INSERT INTO #KpiValor
        SELECT
            'KPI_SALDO_SOCIOS',
            CONVERT(DECIMAL(19,2),COALESCE(SUM(
                CASE
                    WHEN L.importe_neto-COALESCE(P.total_pagado,0)>0
                        THEN L.importe_neto-COALESCE(P.total_pagado,0)
                    ELSE 0
                END
            ),0))
        FROM [finanzas].[LiquidacionSocio] L
        OUTER APPLY
        (
            SELECT SUM(PG.importe) total_pagado
            FROM [finanzas].[PagoSocio] PG
            WHERE PG.liquidacion_socio_id=L.liquidacion_socio_id
              AND PG.estado=1
              AND PG.estado_proceso='CONFIRMADO'
        ) P
        WHERE L.estado=1
          AND L.moneda='PEN'
          AND L.estado_proceso IN('APROBADA','PAGADA_PARCIAL');

    /* RESULT SET 1 */
    SELECT
        E.codigo,
        E.titulo indicador,
        V.valor,
        E.unidad,
        E.icono,
        E.orden
    FROM #ElementosVisibles E
    INNER JOIN #KpiValor V
        ON V.codigo=E.codigo
    WHERE E.tipo='KPI'
    ORDER BY E.orden,E.titulo;

    /* ------------------------------------------------------------------------
       5.4. Alertas: solo de dominios representados en el dashboard visible
       ------------------------------------------------------------------------ */
    CREATE TABLE #Alertas
    (
        tipo VARCHAR(30) NOT NULL,
        mensaje NVARCHAR(300) NOT NULL,
        cantidad BIGINT NOT NULL,
        orden SMALLINT NOT NULL
    );

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE permiso_codigo='SALIDAS_LISTAR')
    BEGIN
        INSERT INTO #Alertas
        SELECT 'SALIDAS',N'Hay salidas programadas cuya hora prevista ya llegó.',COUNT_BIG(*),10
        FROM [campo].[SalidaCampo]
        WHERE estado=1
          AND estado_proceso='PROGRAMADA'
          AND fecha_hora_programada<=SYSUTCDATETIME()
        HAVING COUNT_BIG(*)>0;
    END;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE permiso_codigo='VISITAS_LISTAR')
    BEGIN
        INSERT INTO #Alertas
        SELECT 'VISITAS',N'Hay visitas técnicas en curso pendientes de finalización.',COUNT_BIG(*),20
        FROM [campo].[VisitaTecnica]
        WHERE estado=1
          AND estado_proceso='INICIADA'
        HAVING COUNT_BIG(*)>0;
    END;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE permiso_codigo='SANIDAD_LISTAR')
    BEGIN
        INSERT INTO #Alertas
        SELECT 'SANIDAD',N'Existen casos sanitarios que requieren seguimiento.',COUNT_BIG(*),30
        FROM [sanidad].[CasoFitosanitario]
        WHERE estado=1
          AND estado_caso IN('DETECTADO','EN_TRATAMIENTO','EN_SEGUIMIENTO')
        HAVING COUNT_BIG(*)>0;
    END;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE permiso_codigo='PRODUCCION_LISTAR')
    BEGIN
        INSERT INTO #Alertas
        SELECT 'PRODUCCION',N'Hay estimaciones de producción pendientes de confirmación.',COUNT_BIG(*),40
        FROM [prod].[DisponibilidadProduccion]
        WHERE estado=1
          AND estado_estimacion='ESTIMADA'
        HAVING COUNT_BIG(*)>0;
    END;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE permiso_codigo='JABAS_LISTAR')
    BEGIN
        INSERT INTO #Alertas
        SELECT
            'JABAS',
            N'Hay jabas pendientes de retorno en operativos en recepción.',
            CONVERT(BIGINT,SUM(CASE WHEN JM.tipo_movimiento='ASIGNACION' THEN JM.cantidad WHEN JM.tipo_movimiento IN('DEVOLUCION_LLENA','DEVOLUCION_VACIA') THEN -JM.cantidad ELSE 0 END)),
            45
        FROM [comercial].[JabaMovimiento] JM
        INNER JOIN [comercial].[OperativoVenta] O
            ON O.operativo_venta_id=JM.operativo_venta_id
           AND O.estado=1
           AND O.estado_proceso='EN_RECEPCION'
        WHERE JM.estado=1
        HAVING SUM(CASE WHEN JM.tipo_movimiento='ASIGNACION' THEN JM.cantidad WHEN JM.tipo_movimiento IN('DEVOLUCION_LLENA','DEVOLUCION_VACIA') THEN -JM.cantidad ELSE 0 END)>0;
    END;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE permiso_codigo='ENTREGAS_LISTAR')
    BEGIN
        INSERT INTO #Alertas
        SELECT 'ENTREGAS',N'Hay entregas pendientes de confirmación.',COUNT_BIG(*),50
        FROM [comercial].[EntregaSocio]
        WHERE estado=1
          AND estado_proceso='REGISTRADA'
        HAVING COUNT_BIG(*)>0;
    END;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE permiso_codigo='INCIDENCIAS_LISTAR')
    BEGIN
        INSERT INTO #Alertas
        SELECT 'INCIDENCIAS',N'Hay incidencias operativas pendientes de resolver.',COUNT_BIG(*),60
        FROM [comercial].[IncidenciaOperativa]
        WHERE estado=1
          AND estado_incidencia IN('ABIERTA','EN_REVISION')
        HAVING COUNT_BIG(*)>0;
    END;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE permiso_codigo='RECURSOS_LISTAR')
    BEGIN
        INSERT INTO #Alertas
        SELECT 'LOGISTICA',N'Hay recursos programados pendientes de asignación.',COUNT_BIG(*),65
        FROM [logistica].[RecursoProgramado]
        WHERE estado=1
          AND estado_proceso='PROGRAMADO'
        HAVING COUNT_BIG(*)>0;

        INSERT INTO #Alertas
        SELECT 'LOGISTICA',N'Hay recursos entregados pendientes de devolución o cierre.',COUNT_BIG(*),66
        FROM [logistica].[RecursoProgramado]
        WHERE estado=1
          AND estado_proceso='EN_EJECUCION'
        HAVING COUNT_BIG(*)>0;
    END;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE permiso_codigo='GASTOS_LISTAR')
    BEGIN
        INSERT INTO #Alertas
        SELECT 'FINANZAS',N'Hay gastos pendientes de aprobación.',COUNT_BIG(*),70
        FROM [finanzas].[GastoCampania]
        WHERE estado=1
          AND estado_proceso='REGISTRADO'
        HAVING COUNT_BIG(*)>0;
    END;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE permiso_codigo='LIQUIDACIONES_LISTAR')
    BEGIN
        INSERT INTO #Alertas
        SELECT 'FINANZAS',N'Hay liquidaciones pendientes de aprobación.',COUNT_BIG(*),71
        FROM [finanzas].[LiquidacionSocio]
        WHERE estado=1
          AND estado_proceso='CALCULADA'
        HAVING COUNT_BIG(*)>0;
    END;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE permiso_codigo='PAGOS_LISTAR')
    BEGIN
        INSERT INTO #Alertas
        SELECT 'FINANZAS',N'Hay pagos pendientes de confirmación.',COUNT_BIG(*),72
        FROM [finanzas].[PagoSocio]
        WHERE estado=1
          AND estado_proceso='REGISTRADO'
        HAVING COUNT_BIG(*)>0;
    END;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE permiso_codigo='COBROS_LISTAR')
    BEGIN
        INSERT INTO #Alertas
        SELECT 'FINANZAS',N'Hay cobros pendientes de confirmación.',COUNT_BIG(*),73
        FROM [finanzas].[CobroComprador]
        WHERE estado=1
          AND estado_proceso='REGISTRADO'
        HAVING COUNT_BIG(*)>0;
    END;

    /* RESULT SET 2 */
    SELECT tipo,mensaje,cantidad,orden
    FROM #Alertas
    ORDER BY orden,tipo;

    /* ------------------------------------------------------------------------
       5.5. Accesos rápidos: módulos relacionados con los elementos visibles.
       Máximo ocho para evitar saturar el Inicio del administrador.
       ------------------------------------------------------------------------ */
    ;
WITH ModulosRelacionados AS
    (
        SELECT
            M.modulo_id,
            M.codigo,
            M.nombre,
            M.ruta,
            M.icono,
            MIN(CONVERT(INT,E.orden)) orden_dashboard,
            MIN(CONVERT(INT,M.orden)) orden_modulo
        FROM #ElementosVisibles E
        INNER JOIN [seg].[Modulo] M
            ON M.modulo_id=E.modulo_id
           AND M.estado=1
           AND M.visible_menu=1
           AND M.es_grupo=0
           AND M.ruta IS NOT NULL
        GROUP BY M.modulo_id,M.codigo,M.nombre,M.ruta,M.icono
    )
    SELECT TOP(8)
        modulo_id moduloId,
        codigo codigoModulo,
        nombre nombreModulo,
        ruta,
        icono,
        CONVERT(INT,ROW_NUMBER() OVER(ORDER BY orden_dashboard,orden_modulo,nombre)) orden
    FROM ModulosRelacionados
    ORDER BY orden_dashboard,orden_modulo,nombre;

    /* ------------------------------------------------------------------------
       5.6. Definición de gráficos
       ------------------------------------------------------------------------ */
    /* RESULT SET 4 */
    SELECT
        codigo,
        titulo,
        subtitulo,
        tipo_grafico tipoGrafico,
        unidad,
        CONVERT(INT,ancho) ancho,
        CONVERT(INT,orden) orden
    FROM #ElementosVisibles
    WHERE tipo='GRAFICO'
    ORDER BY orden,titulo;

    /* ------------------------------------------------------------------------
       5.7. Datos de gráficos
       ------------------------------------------------------------------------ */
    CREATE TABLE #GraficoPunto
    (
        codigo_grafico VARCHAR(80) NOT NULL,
        serie NVARCHAR(100) NOT NULL,
        categoria NVARCHAR(100) NOT NULL,
        valor DECIMAL(19,4) NOT NULL,
        orden INT NOT NULL
    );

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='GRAF_PRODUCCION_MENSUAL')
    BEGIN
        INSERT INTO #GraficoPunto
        SELECT
            'GRAF_PRODUCCION_MENSUAL',
            N'Producción confirmada',
            CONCAT(YEAR(fecha_estimacion),'-',RIGHT('0'+CONVERT(VARCHAR(2),MONTH(fecha_estimacion)),2)),
            CONVERT(DECIMAL(19,4),SUM(cantidad_estimada_kg)),
            YEAR(fecha_estimacion)*100+MONTH(fecha_estimacion)
        FROM [prod].[DisponibilidadProduccion]
        WHERE estado=1
          AND estado_estimacion='CONFIRMADA'
          AND fecha_estimacion>=@dtDesde
          AND fecha_estimacion<@dtHastaExclusivo
        GROUP BY YEAR(fecha_estimacion),MONTH(fecha_estimacion);
    END;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='GRAF_VISITAS_ESTADO')
    BEGIN
        INSERT INTO #GraficoPunto
        SELECT
            'GRAF_VISITAS_ESTADO',
            N'Visitas',
            CASE estado_proceso
                WHEN 'INICIADA' THEN N'Iniciadas'
                WHEN 'FINALIZADA' THEN N'Finalizadas'
                WHEN 'ANULADA' THEN N'Anuladas'
                ELSE estado_proceso
            END,
            CONVERT(DECIMAL(19,4),COUNT_BIG(*)),
            CASE estado_proceso WHEN 'INICIADA' THEN 10 WHEN 'FINALIZADA' THEN 20 WHEN 'ANULADA' THEN 30 ELSE 90 END
        FROM [campo].[VisitaTecnica]
        WHERE estado=1
          AND fecha_hora_inicio>=@dtDesde
          AND fecha_hora_inicio<@dtHastaExclusivo
        GROUP BY estado_proceso;
    END;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='GRAF_CAMPANIAS_ESTADO')
    BEGIN
        INSERT INTO #GraficoPunto
        SELECT
            'GRAF_CAMPANIAS_ESTADO',
            N'Campañas',
            CASE estado_proceso
                WHEN 'PLANIFICACION' THEN N'Planificación'
                WHEN 'ACTIVA' THEN N'Activas'
                WHEN 'CERRADA' THEN N'Cerradas'
                WHEN 'CANCELADA' THEN N'Canceladas'
                ELSE estado_proceso
            END,
            CONVERT(DECIMAL(19,4),COUNT_BIG(*)),
            CASE estado_proceso WHEN 'PLANIFICACION' THEN 10 WHEN 'ACTIVA' THEN 20 WHEN 'CERRADA' THEN 30 WHEN 'CANCELADA' THEN 40 ELSE 90 END
        FROM [comercial].[CampaniaVenta]
        WHERE estado=1
          AND fecha_inicio<=@dHasta
          AND (fecha_fin IS NULL OR fecha_fin>=@dDesde)
        GROUP BY estado_proceso;
    END;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='GRAF_ACOPIO_MENSUAL')
    BEGIN
        INSERT INTO #GraficoPunto
        SELECT
            'GRAF_ACOPIO_MENSUAL',
            N'Peso aceptado',
            CONCAT(YEAR(fecha_hora),'-',RIGHT('0'+CONVERT(VARCHAR(2),MONTH(fecha_hora)),2)),
            CONVERT(DECIMAL(19,4),SUM(peso_aceptado_kg)),
            YEAR(fecha_hora)*100+MONTH(fecha_hora)
        FROM [comercial].[EntregaSocio]
        WHERE estado=1
          AND estado_proceso='CONFIRMADA'
          AND fecha_hora>=@dtDesde
          AND fecha_hora<@dtHastaExclusivo
        GROUP BY YEAR(fecha_hora),MONTH(fecha_hora);
    END;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='GRAF_INCIDENCIAS_ESTADO')
    BEGIN
        INSERT INTO #GraficoPunto
        SELECT
            'GRAF_INCIDENCIAS_ESTADO',
            N'Incidencias',
            CASE estado_incidencia
                WHEN 'ABIERTA' THEN N'Abiertas'
                WHEN 'EN_REVISION' THEN N'En revisión'
                WHEN 'RESUELTA' THEN N'Resueltas'
                WHEN 'ANULADA' THEN N'Anuladas'
                ELSE estado_incidencia
            END,
            CONVERT(DECIMAL(19,4),COUNT_BIG(*)),
            CASE estado_incidencia WHEN 'ABIERTA' THEN 10 WHEN 'EN_REVISION' THEN 20 WHEN 'RESUELTA' THEN 30 WHEN 'ANULADA' THEN 40 ELSE 90 END
        FROM [comercial].[IncidenciaOperativa]
        WHERE estado=1
          AND fecha_hora>=@dtDesde
          AND fecha_hora<@dtHastaExclusivo
        GROUP BY estado_incidencia;
    END;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='GRAF_RECURSOS_ESTADO')
    BEGIN
        INSERT INTO #GraficoPunto
        SELECT
            'GRAF_RECURSOS_ESTADO',
            N'Recursos',
            CASE estado_proceso
                WHEN 'PROGRAMADO' THEN N'Programados'
                WHEN 'EN_EJECUCION' THEN N'En ejecución'
                WHEN 'DEVUELTO' THEN N'Devueltos'
                WHEN 'CERRADO' THEN N'Cerrados'
                WHEN 'CANCELADO' THEN N'Cancelados'
                ELSE REPLACE(estado_proceso,'_',N' ')
            END,
            CONVERT(DECIMAL(19,4),COUNT_BIG(*)),
            CASE estado_proceso WHEN 'PROGRAMADO' THEN 10 WHEN 'EN_EJECUCION' THEN 20 WHEN 'DEVUELTO' THEN 30 WHEN 'CERRADO' THEN 40 WHEN 'CANCELADO' THEN 50 ELSE 90 END
        FROM [logistica].[RecursoProgramado]
        WHERE estado=1
          AND fecha_programacion>=@dtDesde
          AND fecha_programacion<@dtHastaExclusivo
        GROUP BY estado_proceso;
    END;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='GRAF_PAGOS_MENSUAL')
    BEGIN
        INSERT INTO #GraficoPunto
        SELECT
            'GRAF_PAGOS_MENSUAL',
            N'Pagos confirmados',
            CONCAT(YEAR(fecha_hora),'-',RIGHT('0'+CONVERT(VARCHAR(2),MONTH(fecha_hora)),2)),
            CONVERT(DECIMAL(19,4),SUM(importe)),
            YEAR(fecha_hora)*100+MONTH(fecha_hora)
        FROM [finanzas].[PagoSocio]
        WHERE estado=1
          AND estado_proceso='CONFIRMADO'
          AND fecha_hora>=@dtDesde
          AND fecha_hora<@dtHastaExclusivo
        GROUP BY YEAR(fecha_hora),MONTH(fecha_hora);
    END;

    IF EXISTS(SELECT 1 FROM #ElementosVisibles WHERE codigo='GRAF_COBROS_MENSUAL')
    BEGIN
        INSERT INTO #GraficoPunto
        SELECT
            'GRAF_COBROS_MENSUAL',
            N'Cobros confirmados',
            CONCAT(YEAR(fecha_hora),'-',RIGHT('0'+CONVERT(VARCHAR(2),MONTH(fecha_hora)),2)),
            CONVERT(DECIMAL(19,4),SUM(importe)),
            YEAR(fecha_hora)*100+MONTH(fecha_hora)
        FROM [finanzas].[CobroComprador]
        WHERE estado=1
          AND estado_proceso='CONFIRMADO'
          AND moneda='PEN'
          AND fecha_hora>=@dtDesde
          AND fecha_hora<@dtHastaExclusivo
        GROUP BY YEAR(fecha_hora),MONTH(fecha_hora);
    END;

    /* RESULT SET 5 */
    SELECT
        codigo_grafico codigoGrafico,
        serie,
        categoria,
        valor,
        orden
    FROM #GraficoPunto
    ORDER BY codigo_grafico,serie,orden,categoria;

    SET @bResultado=1;
    SET @cMensaje=N'Inicio cargado correctamente.';

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
    @cProcedimiento = N'dbo.PA_Dashboard_Sel_Resumen',
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
    @cProcedimiento = N'dbo.PA_Dashboard_Sel_Resumen',
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
FROM config.FN_RespuestaUsuario(N'dbo.PA_Dashboard_Sel_Resumen',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
