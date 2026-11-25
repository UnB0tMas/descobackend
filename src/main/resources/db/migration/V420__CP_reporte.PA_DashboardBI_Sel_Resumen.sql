IF OBJECT_ID(N'[reporte].[PA_DashboardBI_Sel_Resumen]') IS NOT NULL
    DROP PROCEDURE [reporte].[PA_DashboardBI_Sel_Resumen];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : reporte.PA_DashboardBI_Sel_Resumen
' Descripción            : Consulta información de Dashboard BI (resumen).
' Aplicativo / Módulo    : DESCO / reporte
*******************************************************************************************************/
CREATE   PROCEDURE reporte.PA_DashboardBI_Sel_Resumen
    @cJson NVARCHAR(MAX),
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60) = NULL OUTPUT,
    @nHttpRespuesta SMALLINT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @bResultado = 0;
    SET @cMensaje = N'No se pudo cargar la información.';
    SET @cCodigoRespuesta = 'BI_NO_DISPONIBLE';
    SET @nHttpRespuesta = 400;

    BEGIN TRY
        DECLARE @nUsuario BIGINT, @nSesion BIGINT, @nDisp BIGINT, @nEmpleado BIGINT, @nModulo INT,
                @gCorr UNIQUEIDENTIFIER, @gSol UNIQUEIDENTIFIER, @cIp VARCHAR(64), @cEndpoint NVARCHAR(250),
                @bCtx BIT, @cMsg NVARCHAR(300), @nUot BIGINT, @cModo VARCHAR(12),
                @cTab VARCHAR(20), @dDesde DATE, @dHasta DATE, @nAlmacen BIGINT, @nPredio BIGINT,
                @tInicio DATETIME2(0), @tFin DATETIME2(0), @dHoy DATE;

        EXEC seg.PA_Operacion_Sel_ContextoAutorizado
            @cJson = @cJson, @cCodigoPermiso = 'DASHBOARD_BI_VER',
            @nUsuarioId = @nUsuario OUTPUT,
            @nSesionUsuarioId = @nSesion OUTPUT,
            @nDispositivoUsuarioId = @nDisp OUTPUT,
            @nEmpleadoId = @nEmpleado OUTPUT,
            @nModuloId = @nModulo OUTPUT,
            @gCorrelacionId = @gCorr OUTPUT,
            @gSolicitudId = @gSol OUTPUT,
            @cIp = @cIp OUTPUT,
            @cEndpoint = @cEndpoint OUTPUT,
            @bResultado = @bCtx OUTPUT, @cMensaje = @cMsg OUTPUT;

        IF ISNULL(@bCtx, 0) <> 1
        BEGIN
            SET @cMensaje = COALESCE(@cMsg, N'No está autorizado a ver el dashboard.');
            SET @cCodigoRespuesta = 'BI_NO_AUTORIZADO';
            SET @nHttpRespuesta = 403;
            RETURN;
        END;

        SELECT @nUot = S.uot_contexto_id, @cModo = S.modo_uot
        FROM seg.SesionUsuario S
        WHERE S.sesion_usuario_id = @nSesion AND S.usuario_id = @nUsuario AND S.estado = 1;

        IF @cModo <> 'ESPECIFICA' OR @nUot IS NULL OR
           ISNULL(seg.FN_Usuario_TienePermisoUOT(@nUsuario, @nUot, 'DASHBOARD_BI_VER'), 0) <> 1 OR NOT EXISTS (
            SELECT 1 FROM seg.UsuarioUOT UU
            WHERE UU.usuario_id = @nUsuario AND UU.uot_id = @nUot AND UU.estado = 1
              AND UU.fecha_desde <= SYSUTCDATETIME()
              AND (UU.fecha_hasta IS NULL OR UU.fecha_hasta >= SYSUTCDATETIME()))
        BEGIN
            SET @cMensaje = N'Seleccione una unidad autorizada.';
            SET @cCodigoRespuesta = 'BI_UOT_REQUERIDA';
            SET @nHttpRespuesta = 403;
            RETURN;
        END;

        SELECT @cTab = UPPER(NULLIF(LTRIM(RTRIM(tab)), '')),
               @dDesde = desde, @dHasta = hasta,
               @nAlmacen = almacenId, @nPredio = predioId
        FROM OPENJSON(@cJson, '$.filtros') WITH (
            tab VARCHAR(20) '$.tab', desde DATE '$.desde', hasta DATE '$.hasta',
            almacenId BIGINT '$.almacenId', predioId BIGINT '$.predioId');

        IF @cTab NOT IN ('POS', 'TECNICA', 'RECURSOS', 'DOCUMENTOS') OR @cTab IS NULL
        BEGIN
            SET @cMensaje = N'La sección solicitada no existe.';
            SET @cCodigoRespuesta = 'BI_TAB_INVALIDO';
            RETURN;
        END;

        /* Los permisos se verifican para la UOT activa, respetando overrides y roles UOT. */
        IF (@cTab = 'POS' AND ISNULL(seg.FN_Usuario_TienePermisoUOT(@nUsuario, @nUot, 'VENTAS_REPORTES'), 0) <> 1)
           OR (@cTab = 'TECNICA' AND (
                    ISNULL(seg.FN_Usuario_TienePermisoUOT(@nUsuario, @nUot, 'SALIDAS_LISTAR'), 0) <> 1
                    OR ISNULL(seg.FN_Usuario_TienePermisoUOT(@nUsuario, @nUot, 'VISITAS_LISTAR'), 0) <> 1
                    OR ISNULL(seg.FN_Usuario_TienePermisoUOT(@nUsuario, @nUot, 'SANIDAD_LISTAR'), 0) <> 1))
           OR (@cTab = 'RECURSOS' AND ISNULL(seg.FN_Usuario_TienePermisoUOT(@nUsuario, @nUot, 'INVENTARIO_LISTAR'), 0) <> 1)
           OR (@cTab = 'DOCUMENTOS' AND (ISNULL(seg.FN_Usuario_TienePermisoUOT(@nUsuario, @nUot, 'ARCHIVOS_LISTAR'), 0) <> 1
                    OR ISNULL(seg.FN_Usuario_TienePermisoUOT(@nUsuario, @nUot, 'DOCS_LISTAR'), 0) <> 1))
        BEGIN
            SET @cMensaje = N'No dispone de permisos para consultar esta sección.';
            SET @cCodigoRespuesta = 'BI_TAB_SIN_PERMISO';
            SET @nHttpRespuesta = 403;
            RETURN;
        END;

        /* El rango se expresa en día civil de Lima; las columnas datetime2 se almacenan en UTC. */
        SET @dHoy = CONVERT(DATE, (SYSUTCDATETIME() AT TIME ZONE 'UTC') AT TIME ZONE 'SA Pacific Standard Time');
        SET @dHasta = COALESCE(@dHasta, @dHoy);
        SET @dDesde = COALESCE(@dDesde, @dHasta);
        IF @dDesde > @dHasta OR @dHasta > @dHoy OR DATEDIFF(DAY, @dDesde, @dHasta) > 365
        BEGIN
            SET @cMensaje = N'El rango debe ser válido, no futuro y de máximo 366 días.';
            SET @cCodigoRespuesta = 'BI_PERIODO_INVALIDO';
            RETURN;
        END;
        SET @tInicio = CONVERT(DATETIME2(0), (CAST(@dDesde AS DATETIME2(0)) AT TIME ZONE 'SA Pacific Standard Time') AT TIME ZONE 'UTC');
        SET @tFin = CONVERT(DATETIME2(0), (CAST(DATEADD(DAY, 1, @dHasta) AS DATETIME2(0)) AT TIME ZONE 'SA Pacific Standard Time') AT TIME ZONE 'UTC');

        IF (@nAlmacen IS NOT NULL AND @cTab NOT IN ('POS','RECURSOS'))
           OR (@nPredio IS NOT NULL AND @cTab <> 'TECNICA')
        BEGIN
            SET @cMensaje = N'Filtro no disponible para esta sección.';
            SET @cCodigoRespuesta = 'BI_FILTRO_INVALIDO';
            RETURN;
        END;

        IF @nAlmacen IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM logistica.Almacen A WHERE A.almacen_id = @nAlmacen AND A.uot_propietaria_id = @nUot AND A.estado = 1)
        BEGIN
            SET @cMensaje = N'El almacén no está disponible.';
            SET @cCodigoRespuesta = 'BI_ALMACEN_INVALIDO';
            RETURN;
        END;
        IF @nPredio IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM prod.Predio PR WHERE PR.predio_id = @nPredio AND PR.uot_id = @nUot AND PR.estado = 1
              AND EXISTS (SELECT 1 FROM prod.PredioAmbito PA
                          WHERE PA.predio_id = PR.predio_id AND PA.uot_id = @nUot
                            AND PA.convenio_uot_organizacion_id IS NULL AND PA.estado = 1))
        BEGIN
            SET @cMensaje = N'El predio no está disponible.';
            SET @cCodigoRespuesta = 'BI_PREDIO_INVALIDO';
            RETURN;
        END;

        CREATE TABLE #Kpi (codigo VARCHAR(40) NOT NULL, titulo NVARCHAR(100) NOT NULL,
                           valor DECIMAL(19,4) NOT NULL, unidad VARCHAR(16) NOT NULL, orden TINYINT NOT NULL);
        CREATE TABLE #Grafico (grafico VARCHAR(40) NOT NULL, categoria NVARCHAR(120) NOT NULL,
                               serie NVARCHAR(60) NOT NULL, valor DECIMAL(19,4) NOT NULL, orden INT NOT NULL);

        IF @cTab = 'POS'
        BEGIN
            /* Ventas completadas en PEN: nunca mezclar órdenes reservadas ni anulaciones. */
            SELECT V.venta_id, V.caja_sesion_id, CAST(DATEADD(HOUR, -5, V.fecha_hora) AS DATE) fecha,
                   DATEPART(HOUR, DATEADD(HOUR, -5, V.fecha_hora)) hora,
                   V.total
            INTO #Ventas
            FROM comercial.Venta V
            WHERE V.estado = 1 AND V.uot_id = @nUot AND V.moneda = 'PEN'
              AND V.estado_venta IN ('PAGADA', 'ENTREGADA')
              AND V.fecha_hora >= @tInicio AND V.fecha_hora < @tFin
              AND (@nAlmacen IS NULL OR V.almacen_id = @nAlmacen);

            SELECT DV.venta_id, DV.producto_id, P.nombre, DV.cantidad,
                   CONVERT(DECIMAL(19,4), DV.subtotal) importe
            INTO #Lineas
            FROM comercial.DetalleVenta DV
            INNER JOIN #Ventas V ON V.venta_id = DV.venta_id
            INNER JOIN logistica.Producto P ON P.producto_id = DV.producto_id
            WHERE DV.estado = 1;

            INSERT INTO #Kpi(codigo, titulo, valor, unidad, orden)
            SELECT 'VENTAS_NETAS', N'Ventas completadas', COALESCE(SUM(total), 0), 'PEN', 1 FROM #Ventas
            UNION ALL SELECT 'OPERACIONES', N'Operaciones', COUNT_BIG(*), 'UND', 2 FROM #Ventas
            UNION ALL SELECT 'TICKET', N'Ticket promedio', COALESCE(AVG(total), 0), 'PEN', 3 FROM #Ventas
            UNION ALL SELECT 'UNIDADES', N'Unidades vendidas', COALESCE(SUM(cantidad), 0), 'UND', 4 FROM #Lineas;

            INSERT INTO #Grafico(grafico, categoria, serie, valor, orden)
            SELECT 'VENTAS_DIA', CONVERT(VARCHAR(10), fecha, 23), N'Ventas S/', SUM(total), DATEDIFF(DAY, @dDesde, fecha)
            FROM #Ventas GROUP BY fecha;
            INSERT INTO #Grafico(grafico, categoria, serie, valor, orden)
            SELECT 'TOP_PRODUCTOS', nombre, N'Importe S/', SUM(importe), ROW_NUMBER() OVER (ORDER BY SUM(importe) DESC)
            FROM #Lineas GROUP BY producto_id, nombre
            ORDER BY SUM(importe) DESC OFFSET 0 ROWS FETCH NEXT 7 ROWS ONLY;
            INSERT INTO #Grafico(grafico, categoria, serie, valor, orden)
            SELECT 'METODOS_PAGO', MP.nombre, N'Cobrado S/', SUM(PV.importe), ROW_NUMBER() OVER (ORDER BY SUM(PV.importe) DESC)
            FROM comercial.PagoVenta PV
            INNER JOIN #Ventas V ON V.venta_id = PV.venta_id
            INNER JOIN comercial.MetodoPago MP ON MP.metodo_pago_id = PV.metodo_pago_id
            WHERE PV.estado = 1 AND PV.estado_pago = 'CONFIRMADO' AND PV.moneda = 'PEN'
            GROUP BY MP.metodo_pago_id, MP.nombre;
            INSERT INTO #Grafico(grafico, categoria, serie, valor, orden)
            SELECT 'VENTAS_CAJA', COALESCE(CP.nombre, N'Sin caja'), N'Ventas S/', SUM(V.total),
                   ROW_NUMBER() OVER (ORDER BY SUM(V.total) DESC)
            FROM #Ventas V
            LEFT JOIN comercial.CajaSesion CS ON CS.caja_sesion_id = V.caja_sesion_id
            LEFT JOIN comercial.CajaPOS CP ON CP.caja_id = CS.caja_id AND CP.uot_id = @nUot
            GROUP BY CP.caja_id, CP.nombre
            ORDER BY SUM(V.total) DESC OFFSET 0 ROWS FETCH NEXT 7 ROWS ONLY;
        END
        ELSE IF @cTab = 'TECNICA'
        BEGIN
            /* Solo proceso técnico ordinario; omitir salidas adscritas a convenios. */
            SELECT V.visita_tecnica_id, CAST(DATEADD(HOUR, -5, V.fecha_hora_inicio) AS DATE) fecha,
                   V.estado_proceso, PR.nombre predio
            INTO #Visitas
            FROM campo.VisitaTecnica V
            INNER JOIN campo.SalidaParticipante SP ON SP.salida_participante_id = V.salida_participante_id AND SP.estado = 1
            INNER JOIN campo.SalidaCampo SC ON SC.salida_campo_id = SP.salida_campo_id AND SC.estado = 1 AND SC.uot_id = @nUot
            INNER JOIN prod.Predio PR ON PR.predio_id = V.predio_id AND PR.estado = 1 AND PR.uot_id = @nUot
            WHERE V.estado = 1 AND V.fecha_hora_inicio >= @tInicio AND V.fecha_hora_inicio < @tFin
              AND (@nPredio IS NULL OR V.predio_id = @nPredio)
              AND EXISTS (SELECT 1 FROM prod.PredioAmbito PA
                          WHERE PA.predio_id = V.predio_id AND PA.uot_id = @nUot
                            AND PA.convenio_uot_organizacion_id IS NULL AND PA.estado = 1)
              AND NOT EXISTS (SELECT 1 FROM campo.SalidaE2 E2
                              WHERE E2.salida_campo_id = SC.salida_campo_id AND E2.convenio_id IS NOT NULL);

            SELECT SC.salida_campo_id, SC.estado_proceso
            INTO #Salidas
            FROM campo.SalidaCampo SC
            WHERE SC.estado = 1 AND SC.uot_id = @nUot
              AND SC.fecha_hora_programada >= @tInicio AND SC.fecha_hora_programada < @tFin
              AND NOT EXISTS (SELECT 1 FROM campo.SalidaE2 E2
                              WHERE E2.salida_campo_id = SC.salida_campo_id AND E2.convenio_id IS NOT NULL)
              AND (@nPredio IS NULL OR EXISTS (
                  SELECT 1 FROM campo.SalidaParticipante SP
                  INNER JOIN campo.VisitaTecnica VT ON VT.salida_participante_id = SP.salida_participante_id
                  WHERE SP.salida_campo_id = SC.salida_campo_id AND VT.predio_id = @nPredio
                    AND EXISTS (SELECT 1 FROM prod.PredioAmbito PA
                                WHERE PA.predio_id = VT.predio_id AND PA.uot_id = @nUot
                                  AND PA.convenio_uot_organizacion_id IS NULL AND PA.estado = 1)));

            SELECT C.caso_fitosanitario_id, C.severidad, C.tipo_problema_fitosanitario_id
            INTO #Casos
            FROM sanidad.CasoFitosanitario C
            INNER JOIN prod.ParcelaCultivo PC ON PC.parcela_cultivo_id = C.parcela_cultivo_id
            INNER JOIN prod.Parcela PA ON PA.parcela_id = PC.parcela_id
            INNER JOIN prod.Predio PR ON PR.predio_id = PA.predio_id AND PR.uot_id = @nUot
            WHERE C.estado = 1 AND C.fecha_deteccion >= @tInicio AND C.fecha_deteccion < @tFin
              AND (@nPredio IS NULL OR PR.predio_id = @nPredio)
              AND EXISTS (SELECT 1 FROM prod.PredioAmbito AM
                          WHERE AM.predio_id = PR.predio_id AND AM.uot_id = @nUot
                            AND AM.convenio_uot_organizacion_id IS NULL AND AM.estado = 1);

            SELECT T.tratamiento_fitosanitario_id, C.tipo_problema_fitosanitario_id
            INTO #Tratamientos
            FROM sanidad.TratamientoFitosanitario T
            INNER JOIN sanidad.CasoFitosanitario C ON C.caso_fitosanitario_id = T.caso_fitosanitario_id
            INNER JOIN prod.ParcelaCultivo PC ON PC.parcela_cultivo_id = C.parcela_cultivo_id
            INNER JOIN prod.Parcela PA ON PA.parcela_id = PC.parcela_id
            INNER JOIN prod.Predio PR ON PR.predio_id = PA.predio_id AND PR.uot_id = @nUot
            WHERE T.estado = 1 AND T.fecha_hora >= @tInicio AND T.fecha_hora < @tFin
              AND (@nPredio IS NULL OR PR.predio_id = @nPredio)
              AND EXISTS (SELECT 1 FROM prod.PredioAmbito AM
                          WHERE AM.predio_id = PR.predio_id AND AM.uot_id = @nUot
                            AND AM.convenio_uot_organizacion_id IS NULL AND AM.estado = 1);

            INSERT INTO #Kpi(codigo,titulo,valor,unidad,orden)
            SELECT 'VISITAS', N'Visitas registradas', COUNT_BIG(*), 'UND', 1 FROM #Visitas
            UNION ALL SELECT 'SALIDAS', N'Salidas programadas', COUNT_BIG(*), 'UND', 2 FROM #Salidas
            UNION ALL SELECT 'CASOS', N'Casos detectados', COUNT_BIG(*), 'UND', 3 FROM #Casos
            UNION ALL SELECT 'TRATAMIENTOS', N'Tratamientos aplicados', COUNT_BIG(*), 'UND', 4 FROM #Tratamientos;

            INSERT INTO #Grafico(grafico,categoria,serie,valor,orden)
            SELECT 'VISITAS_DIA', CONVERT(VARCHAR(10),fecha,23), N'Visitas', COUNT_BIG(*), DATEDIFF(DAY,@dDesde,fecha)
            FROM #Visitas GROUP BY fecha;
            INSERT INTO #Grafico(grafico,categoria,serie,valor,orden)
            SELECT 'SALIDAS_ESTADO', estado_proceso, N'Salidas', COUNT_BIG(*), ROW_NUMBER() OVER (ORDER BY COUNT_BIG(*) DESC)
            FROM #Salidas GROUP BY estado_proceso;
            INSERT INTO #Grafico(grafico,categoria,serie,valor,orden)
            SELECT 'CASOS_SEVERIDAD', severidad, N'Casos', COUNT_BIG(*), ROW_NUMBER() OVER (ORDER BY COUNT_BIG(*) DESC)
            FROM #Casos GROUP BY severidad;
            INSERT INTO #Grafico(grafico,categoria,serie,valor,orden)
            SELECT 'TRATAMIENTOS_PROBLEMA', COALESCE(TP.nombre,N'No clasificado'), N'Tratamientos', COUNT_BIG(*),
                   ROW_NUMBER() OVER (ORDER BY COUNT_BIG(*) DESC)
            FROM #Tratamientos T
            LEFT JOIN sanidad.TipoProblemaFitosanitario TP ON TP.tipo_problema_fitosanitario_id = T.tipo_problema_fitosanitario_id
            GROUP BY TP.tipo_problema_fitosanitario_id, TP.nombre
            ORDER BY COUNT_BIG(*) DESC OFFSET 0 ROWS FETCH NEXT 7 ROWS ONLY;
        END
        ELSE IF @cTab = 'RECURSOS'
        BEGIN
            SELECT M.movimiento_inventario_id, CAST(DATEADD(HOUR,-5,M.fecha_hora) AS DATE) fecha,
                   M.naturaleza, M.tipo_movimiento, A.nombre almacen
            INTO #Movimientos
            FROM logistica.MovimientoInventario M
            INNER JOIN logistica.Almacen A ON A.almacen_id = M.almacen_id AND A.uot_propietaria_id = @nUot
            WHERE M.estado = 1 AND M.uot_id = @nUot
              AND M.fecha_hora >= @tInicio AND M.fecha_hora < @tFin
              AND (@nAlmacen IS NULL OR M.almacen_id = @nAlmacen);

            SELECT DISTINCT D.movimiento_inventario_id, D.producto_id, P.nombre
            INTO #ProductosMovidos
            FROM logistica.DetalleMovimientoInventario D
            INNER JOIN #Movimientos M ON M.movimiento_inventario_id = D.movimiento_inventario_id
            INNER JOIN logistica.Producto P ON P.producto_id = D.producto_id;

            /* No mezclar cantidades de unidades diferentes: se cuentan movimientos y productos. */
            INSERT INTO #Kpi(codigo,titulo,valor,unidad,orden)
            SELECT 'MOVIMIENTOS', N'Movimientos', COUNT_BIG(*), 'UND', 1 FROM #Movimientos
            UNION ALL SELECT 'ENTRADAS', N'Entradas', COUNT_BIG(*), 'UND', 2 FROM #Movimientos WHERE naturaleza = 'E'
            UNION ALL SELECT 'SALIDAS', N'Salidas', COUNT_BIG(*), 'UND', 3 FROM #Movimientos WHERE naturaleza = 'S'
            UNION ALL SELECT 'PRODUCTOS', N'Productos movilizados', COUNT_BIG(DISTINCT producto_id), 'UND', 4 FROM #ProductosMovidos;

            INSERT INTO #Grafico(grafico,categoria,serie,valor,orden)
            SELECT 'FLUJO_DIA', CONVERT(VARCHAR(10),fecha,23),
                   CASE WHEN naturaleza = 'E' THEN N'Entradas' ELSE N'Salidas' END,
                   COUNT_BIG(*), DATEDIFF(DAY,@dDesde,fecha)
            FROM #Movimientos WHERE naturaleza IN ('E','S') GROUP BY fecha,naturaleza;
            INSERT INTO #Grafico(grafico,categoria,serie,valor,orden)
            SELECT 'TIPOS_MOVIMIENTO', tipo_movimiento, N'Movimientos', COUNT_BIG(*), ROW_NUMBER() OVER (ORDER BY COUNT_BIG(*) DESC)
            FROM #Movimientos GROUP BY tipo_movimiento;
            INSERT INTO #Grafico(grafico,categoria,serie,valor,orden)
            SELECT 'ALMACENES', almacen, N'Movimientos', COUNT_BIG(*), ROW_NUMBER() OVER (ORDER BY COUNT_BIG(*) DESC)
            FROM #Movimientos GROUP BY almacen
            ORDER BY COUNT_BIG(*) DESC OFFSET 0 ROWS FETCH NEXT 7 ROWS ONLY;
            INSERT INTO #Grafico(grafico,categoria,serie,valor,orden)
            SELECT 'PRODUCTOS_TOP', nombre, N'Movimientos', COUNT_BIG(*), ROW_NUMBER() OVER (ORDER BY COUNT_BIG(*) DESC)
            FROM #ProductosMovidos GROUP BY producto_id,nombre
            ORDER BY COUNT_BIG(*) DESC OFFSET 0 ROWS FETCH NEXT 7 ROWS ONLY;
        END
        ELSE IF @cTab = 'DOCUMENTOS'
        BEGIN
            /* Correspondencia: solo envíos y recepciones en que participa el usuario. */
            SELECT D.documento_id, TD.nombre AS tipo,
                   CAST(DATEADD(HOUR,-5,D.fecha_envio) AS DATE) AS fecha
            INTO #Correspondencia
            FROM doc.Documento D
            INNER JOIN doc.Hilo H ON H.hilo_id = D.hilo_id AND H.uot_id = @nUot
            INNER JOIN doc.TipoDocumento TD ON TD.tipo_documento_id = D.tipo_documento_id
            WHERE D.fecha_envio >= @tInicio AND D.fecha_envio < @tFin
              AND (D.emisor_usuario_id = @nUsuario OR EXISTS (
                   SELECT 1 FROM doc.Destinatario DST
                   WHERE DST.documento_id = D.documento_id AND DST.usuario_id = @nUsuario));

            SELECT D.documento_id, DST.fecha_primera_vista
            INTO #Recibidos
            FROM doc.Documento D
            INNER JOIN doc.Hilo H ON H.hilo_id = D.hilo_id AND H.uot_id = @nUot
            INNER JOIN doc.Destinatario DST ON DST.documento_id = D.documento_id
                                     AND DST.usuario_id = @nUsuario
            WHERE D.fecha_envio >= @tInicio AND D.fecha_envio < @tFin;

            /* Las evidencias ordinarias son distintas de los adjuntos de correspondencia. */
            SELECT A.archivo_id, CAST(DATEADD(HOUR,-5,A.fecha_carga) AS DATE) AS fecha,
                   CASE WHEN A.mime_type LIKE 'image/%' THEN N'Imagen'
                        WHEN A.mime_type = 'application/pdf' THEN N'PDF'
                        WHEN A.mime_type LIKE 'video/%' THEN N'Video'
                        ELSE N'Otro' END AS formato,
                   CASE WHEN EXISTS (
                       SELECT 1 FROM archivo.ArchivoVinculo V
                       WHERE V.archivo_id = A.archivo_id AND V.estado = 1
                         AND (V.predio_id IS NOT NULL OR V.parcela_id IS NOT NULL
                           OR V.parcela_cultivo_id IS NOT NULL OR V.visita_tecnica_id IS NOT NULL
                           OR V.salida_campo_id IS NOT NULL OR V.caso_fitosanitario_id IS NOT NULL
                           OR V.tratamiento_id IS NOT NULL OR V.evaluacion_agronomica_id IS NOT NULL
                           OR V.bien_inventario_id IS NOT NULL OR V.movimiento_inventario_id IS NOT NULL)
                    ) THEN 1 ELSE 0 END AS vinculado
            INTO #Documentos
            FROM archivo.Archivo A
            WHERE A.estado = 1 AND A.fecha_retiro IS NULL AND A.uot_id = @nUot
              AND A.fecha_carga >= @tInicio AND A.fecha_carga < @tFin
              AND NOT EXISTS (SELECT 1 FROM doc.DocumentoArchivo DA WHERE DA.archivo_id = A.archivo_id)
              AND (@nPredio IS NULL OR EXISTS (
                   SELECT 1 FROM archivo.ArchivoVinculo V
                   WHERE V.archivo_id = A.archivo_id AND V.estado = 1 AND V.predio_id = @nPredio))
              AND NOT EXISTS (
                   SELECT 1 FROM archivo.ArchivoVinculo V
                   WHERE V.archivo_id = A.archivo_id AND V.estado = 1
                     AND (V.campania_venta_id IS NOT NULL OR V.participacion_campania_socio_id IS NOT NULL
                       OR V.operativo_venta_id IS NOT NULL OR V.entrega_socio_id IS NOT NULL
                       OR V.liquidacion_socio_id IS NOT NULL OR V.pago_socio_id IS NOT NULL
                       OR V.cobro_comprador_id IS NOT NULL OR V.jaba_asignacion_id IS NOT NULL
                       OR V.jaba_devolucion_id IS NOT NULL OR V.ajuste_precio_socio_id IS NOT NULL
                       OR V.gasto_campania_id IS NOT NULL OR V.incidencia_operativa_id IS NOT NULL));

            INSERT INTO #Kpi(codigo,titulo,valor,unidad,orden)
            SELECT 'CORRESPONDENCIA', N'Documentos', COUNT_BIG(*), 'UND', 1 FROM #Correspondencia
            UNION ALL SELECT 'POR_LEER', N'Por leer', COUNT_BIG(*), 'UND', 2 FROM #Recibidos WHERE fecha_primera_vista IS NULL
            UNION ALL SELECT 'EVIDENCIAS', N'Evidencias', COUNT_BIG(*), 'UND', 3 FROM #Documentos
            UNION ALL SELECT 'VINCULADAS', N'Evidencias vinculadas', COUNT_BIG(*), 'UND', 4 FROM #Documentos WHERE vinculado = 1;

            INSERT INTO #Grafico(grafico,categoria,serie,valor,orden)
            SELECT 'ACTIVIDAD_DIA', CONVERT(VARCHAR(10),fecha,23), N'Documentos', COUNT_BIG(*), DATEDIFF(DAY,@dDesde,fecha)
            FROM #Correspondencia GROUP BY fecha;
            INSERT INTO #Grafico(grafico,categoria,serie,valor,orden)
            SELECT 'ACTIVIDAD_DIA', CONVERT(VARCHAR(10),fecha,23), N'Evidencias', COUNT_BIG(*), DATEDIFF(DAY,@dDesde,fecha)
            FROM #Documentos GROUP BY fecha;
            INSERT INTO #Grafico(grafico,categoria,serie,valor,orden)
            SELECT 'TIPOS_DOC', tipo, N'Documentos', COUNT_BIG(*), ROW_NUMBER() OVER (ORDER BY COUNT_BIG(*) DESC)
            FROM #Correspondencia GROUP BY tipo
            ORDER BY COUNT_BIG(*) DESC OFFSET 0 ROWS FETCH NEXT 7 ROWS ONLY;
            INSERT INTO #Grafico(grafico,categoria,serie,valor,orden)
            SELECT 'LECTURA_DOC', CASE WHEN fecha_primera_vista IS NULL THEN N'Por leer' ELSE N'Leídos' END,
                   N'Documentos', COUNT_BIG(*), ROW_NUMBER() OVER (ORDER BY COUNT_BIG(*) DESC)
            FROM #Recibidos GROUP BY CASE WHEN fecha_primera_vista IS NULL THEN N'Por leer' ELSE N'Leídos' END;
            INSERT INTO #Grafico(grafico,categoria,serie,valor,orden)
            SELECT 'FORMATOS_EVID', formato, N'Evidencias', COUNT_BIG(*), ROW_NUMBER() OVER (ORDER BY COUNT_BIG(*) DESC)
            FROM #Documentos GROUP BY formato;
        END;

        /* Contrato tipado para DatabaseRecordMapper.aggregate: cabecera, 4 KPI, puntos. */
        SELECT @dDesde AS desde, @dHasta AS hasta, @cTab AS tab, @nUot AS uotId;
        SELECT codigo, titulo, valor, unidad, orden FROM #Kpi ORDER BY orden;
        SELECT grafico, categoria, serie, valor, orden FROM #Grafico ORDER BY grafico, orden, categoria, serie;

        SET @bResultado = 1;
        SET @cMensaje = N'Consulta completada.';
        SET @cCodigoRespuesta = 'BI_CARGADO';
        SET @nHttpRespuesta = 200;
    END TRY
    BEGIN CATCH
        SET @bResultado = 0;
        SET @cMensaje = N'No se pudo cargar la información.';
        SET @cCodigoRespuesta = 'BI_ERROR_CONSULTA';
        SET @nHttpRespuesta = 500;
    END CATCH;
END;
GO
