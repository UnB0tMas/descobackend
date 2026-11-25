IF OBJECT_ID(N'[campo].[PA_SalidaPersonal_Consultar]', N'P') IS NOT NULL
    DROP PROCEDURE campo.PA_SalidaPersonal_Consultar;
GO

-- Consultas de lectura personales: la identidad se resuelve de la sesión, nunca del navegador.
CREATE PROCEDURE campo.PA_SalidaPersonal_Consultar
    @cAccion VARCHAR(20),
    @cJson NVARCHAR(MAX),
    @cDatos NVARCHAR(MAX) OUTPUT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60) OUTPUT,
    @nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT @cDatos = NULL, @bResultado = 0,
           @cMensaje = N'No se pudo completar la consulta.',
           @cCodigoRespuesta = 'SALIDA_PERSONAL_ERROR', @nHttpRespuesta = 400;

    IF ISJSON(@cJson) <> 1 OR @cAccion NOT IN ('LISTAR','DETALLE')
        RETURN;

    DECLARE @nUsuario BIGINT, @nSesion BIGINT, @nDispositivo BIGINT,
            @nEmpleado BIGINT, @nModulo INT, @gCorrelacion UNIQUEIDENTIFIER,
            @gSolicitud UNIQUEIDENTIFIER, @cIp VARCHAR(64), @cEndpoint NVARCHAR(250),
            @bAutorizado BIT, @cAutorizacion NVARCHAR(300),
            @nUot BIGINT = TRY_CONVERT(BIGINT, JSON_VALUE(@cJson,'$.filtros.uotId')),
            @nSalida BIGINT = TRY_CONVERT(BIGINT, JSON_VALUE(@cJson,'$.filtros.salidaId')),
            @nPagina INT = COALESCE(TRY_CONVERT(INT, JSON_VALUE(@cJson,'$.filtros.pagina')),1),
            @nTamano INT = COALESCE(TRY_CONVERT(INT, JSON_VALUE(@cJson,'$.filtros.tamano')),20),
            @cEstado VARCHAR(24) = NULLIF(TRIM(JSON_VALUE(@cJson,'$.filtros.estado')),''),
            @cBuscar NVARCHAR(120) = NULLIF(TRIM(JSON_VALUE(@cJson,'$.filtros.buscar')),N''),
            @cPermiso VARCHAR(40) = CASE WHEN @cAccion='LISTAR' THEN 'SALIDAS_LISTAR' ELSE 'SALIDAS_VER' END,
            @nTotal BIGINT;

    BEGIN TRY
        EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson, @cPermiso,
            @nUsuario OUTPUT, @nSesion OUTPUT, @nDispositivo OUTPUT,
            @nEmpleado OUTPUT, @nModulo OUTPUT, @gCorrelacion OUTPUT,
            @gSolicitud OUTPUT, @cIp OUTPUT, @cEndpoint OUTPUT,
            @bAutorizado OUTPUT, @cAutorizacion OUTPUT;

        IF ISNULL(@bAutorizado,0) <> 1 OR @nEmpleado IS NULL OR @nUot IS NULL
           OR seg.FN_Usuario_TienePermisoUOT(@nUsuario,@nUot,@cPermiso) <> 1
           OR seg.FN_Usuario_TienePermisoUOT(@nUsuario,@nUot,
                CASE WHEN @cAccion='LISTAR' THEN 'VISITAS_LISTAR' ELSE 'VISITAS_VER' END) <> 1
            THROW 51060, N'No tiene permiso para consultar estas salidas.', 1;
        IF NOT EXISTS (SELECT 1 FROM org.Empleado E
                JOIN org.EmpleadoUOT EU ON EU.empleado_id=E.empleado_id
                WHERE E.empleado_id=@nEmpleado AND E.estado=1 AND EU.uot_id=@nUot
                  AND EU.estado=1 AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
                  AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
                  AND (EU.fecha_cese IS NULL OR EU.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME())))
            THROW 51060, N'No tiene una asignación vigente en esta unidad.', 1;

        IF @cAccion='LISTAR'
        BEGIN
            IF @nPagina NOT BETWEEN 1 AND 100000 OR @nTamano NOT BETWEEN 1 AND 100
                THROW 51061, N'Revise la paginación solicitada.', 1;
            IF @cEstado IS NOT NULL AND @cEstado NOT IN
                ('BORRADOR','SOLICITADA','OBSERVADA','RECHAZADA','APROBADA',
                 'EN_EJECUCION','EN_RETORNO','CERRADA','CANCELADA')
                THROW 51061, N'Seleccione un estado válido.', 1;

            -- COUNT y elementos usan exactamente el mismo conjunto, ordenado de forma estable.
            DECLARE @Filtradas TABLE
            (
                salida_campo_id BIGINT NOT NULL PRIMARY KEY,
                fecha_solicitud DATETIME2(0) NOT NULL
            );
            INSERT @Filtradas(salida_campo_id,fecha_solicitud)
            SELECT E.salida_campo_id,E.fecha_solicitud
            FROM campo.SalidaE2 E
            WHERE E.uot_id=@nUot AND E.convenio_id IS NULL
              AND E.solicitante_empleado_id=@nEmpleado AND E.estado<>'ELIMINADA'
              AND (@cEstado IS NULL OR E.estado=@cEstado)
              AND (@cBuscar IS NULL OR E.nombre LIKE N'%'+@cBuscar+N'%'
                    OR CONVERT(VARCHAR(25),E.salida_campo_id) LIKE N'%'+@cBuscar+N'%')
              AND EXISTS (SELECT 1 FROM campo.SalidaEventoE2 H
                    WHERE H.salida_campo_id=E.salida_campo_id AND H.usuario_id=@nUsuario
                      AND H.tipo='SOLICITAR');

            SELECT @nTotal=COUNT_BIG(*) FROM @Filtradas;
            SET @cDatos=(
                SELECT @nTotal total,
                    JSON_QUERY((
                        SELECT E.salida_campo_id salidaId,
                            CONVERT(VARCHAR(25),E.salida_campo_id) codigo,
                            E.nombre,E.estado,
                            CONVERT(VARCHAR(19),E.fecha_solicitud,126)+'Z' fechaSolicitud,
                            CONVERT(VARCHAR(19),S.fecha_hora_programada,126)+'Z' fechaInicioPrevista,
                            CASE WHEN E.fecha_fin_prevista IS NULL THEN NULL ELSE
                                 CONVERT(VARCHAR(19),E.fecha_fin_prevista,126)+'Z' END fechaFinPrevista,
                            (SELECT STRING_AGG(COALESCE(P.nombre,NULLIF(TRIM(D.referencia),N''),
                                         CONCAT(N'Predio ',D.predio_id)),N' · ')
                                    WITHIN GROUP (ORDER BY D.orden)
                             FROM campo.SalidaDestinoE2 D
                             LEFT JOIN prod.Predio P ON P.predio_id=D.predio_id
                             WHERE D.salida_campo_id=E.salida_campo_id) destinosResumen,
                            (SELECT COUNT_BIG(*) FROM campo.SalidaDestinoE2 D
                             JOIN campo.SalidaVisitaE2 X ON X.destino_id=D.destino_id
                             WHERE D.salida_campo_id=E.salida_campo_id) visitas,
                            CAST(CASE WHEN E.estado='SOLICITADA' AND E.usuario_aprobador IS NULL
                              AND E.fecha_aprobacion IS NULL
                              AND NOT EXISTS(SELECT 1 FROM campo.SalidaEventoE2 H
                                  WHERE H.salida_campo_id=E.salida_campo_id AND H.tipo IN
                                   ('DECIDIR','ENTREGAR','INICIAR','VISITAR','FINALIZAR_VISITA',
                                    'RETORNAR','INSPECCIONAR','CERRAR'))
                              AND NOT EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 R
                                  WHERE R.salida_campo_id=E.salida_campo_id AND R.estado<>'SOLICITADO')
                              AND NOT EXISTS(SELECT 1 FROM campo.SalidaDestinoE2 D
                                  JOIN campo.SalidaVisitaE2 X ON X.destino_id=D.destino_id
                                  WHERE D.salida_campo_id=E.salida_campo_id)
                              AND NOT EXISTS(SELECT 1 FROM campo.SalidaUsoSuministroE2 U
                                  WHERE U.salida_campo_id=E.salida_campo_id)
                              THEN 1 ELSE 0 END AS BIT) puedeCancelar
                        FROM @Filtradas F
                        JOIN campo.SalidaE2 E ON E.salida_campo_id=F.salida_campo_id
                        JOIN campo.SalidaCampo S ON S.salida_campo_id=E.salida_campo_id
                        ORDER BY F.fecha_solicitud DESC,F.salida_campo_id DESC
                        OFFSET (@nPagina-1)*@nTamano ROWS FETCH NEXT @nTamano ROWS ONLY
                        FOR JSON PATH,INCLUDE_NULL_VALUES
                    )) items
                FOR JSON PATH,WITHOUT_ARRAY_WRAPPER
            );
        END
        ELSE
        BEGIN
            IF @nSalida IS NULL OR NOT EXISTS (
                SELECT 1 FROM campo.SalidaE2 E
                WHERE E.salida_campo_id=@nSalida AND E.uot_id=@nUot
                  AND E.convenio_id IS NULL AND E.solicitante_empleado_id=@nEmpleado
                  AND E.estado<>'ELIMINADA'
                  AND EXISTS(SELECT 1 FROM campo.SalidaEventoE2 H
                    WHERE H.salida_campo_id=E.salida_campo_id
                      AND H.usuario_id=@nUsuario AND H.tipo='SOLICITAR'))
                THROW 51062, N'Esta salida no está disponible.', 1;

            SET @cDatos=(
                SELECT E.salida_campo_id salidaId,CONVERT(VARCHAR(25),E.salida_campo_id) codigo,
                    E.nombre,E.estado,E.uot_id uotId,
                    (SELECT LEFT(CONCAT(P.nombres,N' ',P.apellido_paterno,
                        COALESCE(N' '+P.apellido_materno,N'')),260)
                        FROM org.Persona P WHERE P.persona_id=E.solicitante_empleado_id) solicitanteNombre,
                    CONVERT(VARCHAR(19),E.fecha_solicitud,126)+'Z' fechaSolicitud,
                    CONVERT(VARCHAR(19),S.fecha_hora_programada,126)+'Z' fechaInicioPrevista,
                    CASE WHEN E.fecha_fin_prevista IS NULL THEN NULL ELSE
                         CONVERT(VARCHAR(19),E.fecha_fin_prevista,126)+'Z' END fechaFinPrevista,
                    CASE WHEN S.fecha_hora_salida_real IS NULL THEN NULL ELSE
                         CONVERT(VARCHAR(19),S.fecha_hora_salida_real,126)+'Z' END fechaInicioReal,
                    CASE WHEN S.fecha_hora_retorno_real IS NULL THEN NULL ELSE
                         CONVERT(VARCHAR(19),S.fecha_hora_retorno_real,126)+'Z' END fechaFinReal,
                    CAST(CASE WHEN E.estado='SOLICITADA' AND E.usuario_aprobador IS NULL
                         AND E.fecha_aprobacion IS NULL
                         AND NOT EXISTS(SELECT 1 FROM campo.SalidaEventoE2 H
                             WHERE H.salida_campo_id=@nSalida AND H.tipo IN
                              ('DECIDIR','ENTREGAR','INICIAR','VISITAR','FINALIZAR_VISITA',
                               'RETORNAR','INSPECCIONAR','CERRAR'))
                         AND NOT EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 R
                             WHERE R.salida_campo_id=@nSalida AND R.estado<>'SOLICITADO')
                         AND NOT EXISTS(SELECT 1 FROM campo.SalidaDestinoE2 D
                             JOIN campo.SalidaVisitaE2 X ON X.destino_id=D.destino_id
                             WHERE D.salida_campo_id=@nSalida)
                         AND NOT EXISTS(SELECT 1 FROM campo.SalidaUsoSuministroE2 U
                             WHERE U.salida_campo_id=@nSalida)
                         THEN 1 ELSE 0 END AS BIT) puedeCancelar,
                    CASE WHEN EXISTS(SELECT 1 FROM campo.SalidaDocumentoVinculo L
                            JOIN doc.Hilo H ON H.hilo_id=L.hilo_id
                            WHERE L.salida_campo_id=@nSalida AND L.uot_id=@nUot
                              AND (H.creado_por_usuario_id=@nUsuario OR EXISTS(
                                  SELECT 1 FROM doc.ParticipanteUOT DP
                                  WHERE DP.hilo_id=L.hilo_id AND DP.usuario_id=@nUsuario
                                    AND DP.uot_id=@nUot)))
                         THEN (SELECT TOP(1) L.documento_origen_id FROM campo.SalidaDocumentoVinculo L
                               WHERE L.salida_campo_id=@nSalida AND L.uot_id=@nUot)
                         ELSE NULL END documentoId,
                    JSON_QUERY((SELECT D.destino_id destinoId,D.predio_id predioId,
                        P.nombre nombrePredio,P.codigo codigoPredio,D.referencia,
                        D.actividad_prevista actividadPrevista,D.orden
                        FROM campo.SalidaDestinoE2 D
                        LEFT JOIN prod.Predio P ON P.predio_id=D.predio_id
                        WHERE D.salida_campo_id=@nSalida ORDER BY D.orden
                        FOR JSON PATH,INCLUDE_NULL_VALUES)) destinos,
                    JSON_QUERY((SELECT X.visita_tecnica_id visitaId,V.predio_id predioId,
                        T.nombre tipoVisita,
                        CASE WHEN X.usuario_inicio_id=@nUsuario THEN V.objetivo ELSE NULL END objetivo,
                        CASE WHEN X.usuario_fin_id=@nUsuario THEN V.resumen ELSE NULL END resumen,
                        CASE WHEN X.usuario_fin_id=@nUsuario THEN V.recomendaciones ELSE NULL END recomendaciones,
                        V.estado_proceso estado,
                        CONVERT(VARCHAR(19),V.fecha_hora_inicio,126)+'Z' fechaInicio,
                        CASE WHEN X.usuario_fin_id=@nUsuario AND V.fecha_hora_fin IS NOT NULL THEN
                             CONVERT(VARCHAR(19),V.fecha_hora_fin,126)+'Z' ELSE NULL END fechaFin,
                        CAST(CASE WHEN X.usuario_inicio_id=@nUsuario THEN 1 ELSE 0 END AS BIT) iniciadaPorMi,
                        CAST(CASE WHEN X.usuario_fin_id=@nUsuario THEN 1 ELSE 0 END AS BIT) finalizadaPorMi
                        FROM campo.SalidaVisitaE2 X
                        JOIN campo.SalidaDestinoE2 D ON D.destino_id=X.destino_id AND D.salida_campo_id=@nSalida
                        JOIN campo.VisitaTecnica V ON V.visita_tecnica_id=X.visita_tecnica_id
                            AND V.predio_id=D.predio_id
                        JOIN campo.SalidaParticipante SP ON SP.salida_participante_id=V.salida_participante_id
                            AND SP.salida_campo_id=@nSalida AND SP.empleado_id=@nEmpleado
                        JOIN campo.TipoVisitaE2 T ON T.tipo_visita_id=X.tipo_visita_id
                        WHERE X.usuario_inicio_id=@nUsuario OR X.usuario_fin_id=@nUsuario
                        ORDER BY V.fecha_hora_inicio,X.visita_tecnica_id
                        FOR JSON PATH,INCLUDE_NULL_VALUES)) visitas,
                    JSON_QUERY((SELECT A.expediente_actuacion_id actuacionId,A.visita_tecnica_id visitaId,
                        A.predio_id predioId,A.tipo,A.observacion,
                        CONVERT(VARCHAR(19),A.fecha_hecho,126)+'Z' fecha
                        FROM prod.ExpedienteActuacion A
                        WHERE A.salida_campo_id=@nSalida AND A.uot_id=@nUot
                          AND A.usuario_id=@nUsuario AND A.visita_tecnica_id IS NOT NULL
                          AND EXISTS(SELECT 1 FROM campo.SalidaVisitaE2 X
                              JOIN campo.SalidaDestinoE2 D ON D.destino_id=X.destino_id
                              JOIN campo.VisitaTecnica V ON V.visita_tecnica_id=X.visita_tecnica_id
                              WHERE D.salida_campo_id=@nSalida
                                AND X.visita_tecnica_id=A.visita_tecnica_id
                                AND V.predio_id=A.predio_id AND D.predio_id=A.predio_id)
                        ORDER BY A.fecha_hecho,A.expediente_actuacion_id
                        FOR JSON PATH)) actuaciones,
                    JSON_QUERY((SELECT U.salida_uso_suministro_id consumoId,
                        U.visita_tecnica_id visitaId,U.predio_id predioId,
                        U.tratamiento_id tratamientoId,U.solicitud_recurso_id solicitudRecursoId,
                        S.nombre suministro,U.cantidad,U.unidad_medida unidad,U.lote,
                        R.cantidad_solicitada cantidadSolicitadaSalida,
                        R.cantidad_devuelta_validada cantidadDevueltaValidadaSalida,
                        TF.tratamiento,
                        CONVERT(VARCHAR(19),U.fecha_registro,126)+'Z' fecha
                        FROM campo.SalidaUsoSuministroE2 U
                        JOIN campo.SalidaRecursoE2 R ON R.solicitud_recurso_id=U.solicitud_recurso_id
                            AND R.salida_campo_id=U.salida_campo_id
                        JOIN logistica.Suministro S ON S.suministro_id=R.suministro_id AND S.uot_id=@nUot
                        JOIN sanidad.TratamientoFitosanitario TF ON TF.tratamiento_fitosanitario_id=U.tratamiento_id
                            AND TF.visita_tecnica_id=U.visita_tecnica_id
                        WHERE U.salida_campo_id=@nSalida AND U.usuario_id=@nUsuario
                          AND EXISTS(SELECT 1 FROM campo.SalidaVisitaE2 X
                              JOIN campo.SalidaDestinoE2 D ON D.destino_id=X.destino_id
                              JOIN campo.VisitaTecnica V ON V.visita_tecnica_id=X.visita_tecnica_id
                              WHERE D.salida_campo_id=@nSalida
                                AND X.visita_tecnica_id=U.visita_tecnica_id
                                AND V.predio_id=U.predio_id AND D.predio_id=U.predio_id)
                        ORDER BY U.fecha_registro,U.salida_uso_suministro_id
                        FOR JSON PATH)) consumos,
                    JSON_QUERY((SELECT A.archivo_id archivoId,A.nombre_original nombre,
                        A.descripcion,AV.visita_tecnica_id visitaId,AV.predio_id predioId,
                        CONVERT(VARCHAR(19),A.fecha_carga,126)+'Z' fecha
                        FROM archivo.ArchivoVinculo AV
                        JOIN archivo.Archivo A ON A.archivo_id=AV.archivo_id
                        WHERE AV.salida_campo_id=@nSalida AND AV.estado=1 AND A.estado=1
                          AND A.usuario_id=@nUsuario AND (A.uot_id=@nUot OR A.uot_id IS NULL)
                          AND (AV.visita_tecnica_id IS NULL AND AV.predio_id IS NULL OR EXISTS
                              (SELECT 1 FROM campo.SalidaVisitaE2 X
                               JOIN campo.SalidaDestinoE2 D ON D.destino_id=X.destino_id
                               JOIN campo.VisitaTecnica V ON V.visita_tecnica_id=X.visita_tecnica_id
                               WHERE D.salida_campo_id=@nSalida
                                 AND X.visita_tecnica_id=AV.visita_tecnica_id
                                 AND V.predio_id=D.predio_id
                                 AND (AV.predio_id IS NULL OR AV.predio_id=V.predio_id)))
                        ORDER BY A.fecha_carga,A.archivo_id
                        FOR JSON PATH,INCLUDE_NULL_VALUES)) evidencias,
                    JSON_QUERY((SELECT H.evento_id eventoId,H.tipo,H.detalle,
                        H.usuario_id usuarioId,
                        CONVERT(VARCHAR(19),H.fecha_hora,126)+'Z' fecha
                        FROM campo.SalidaEventoE2 H
                        WHERE H.salida_campo_id=@nSalida AND H.usuario_id=@nUsuario
                        ORDER BY H.fecha_hora,H.evento_id
                        FOR JSON PATH,INCLUDE_NULL_VALUES)) historialPropio,
                    JSON_QUERY((SELECT H.evento_id eventoId,H.tipo,H.detalle,
                        H.usuario_id usuarioId,U.nombre_usuario usuario,
                        CONVERT(VARCHAR(19),H.fecha_hora,126)+'Z' fecha
                        FROM campo.SalidaEventoE2 H
                        JOIN seg.Usuario U ON U.usuario_id=H.usuario_id
                        WHERE H.salida_campo_id=@nSalida
                        ORDER BY H.fecha_hora,H.evento_id
                        FOR JSON PATH,INCLUDE_NULL_VALUES)) historialExpediente
                FROM campo.SalidaE2 E
                JOIN campo.SalidaCampo S ON S.salida_campo_id=E.salida_campo_id
                WHERE E.salida_campo_id=@nSalida AND E.uot_id=@nUot
                FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES
            );
        END;

        SELECT @bResultado=1,@cMensaje=N'Consulta realizada.',
               @cCodigoRespuesta='SALIDA_PERSONAL_OK',@nHttpRespuesta=200;
    END TRY
    BEGIN CATCH
        SELECT @bResultado=0,@cDatos=NULL,
               @nHttpRespuesta=CASE WHEN ERROR_NUMBER()=51060 THEN 403
                    WHEN ERROR_NUMBER()=51062 THEN 404 ELSE 400 END,
               @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51060 AND 51062
                    THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo consultar la salida.' END,
               @cCodigoRespuesta='SALIDA_PERSONAL_VALIDACION';
    END CATCH;
END;
GO
