IF OBJECT_ID(N'[archivo].[PA_Archivo_Sel_Detalle]', N'P') IS NOT NULL
    DROP PROCEDURE [archivo].[PA_Archivo_Sel_Detalle];
GO

/******************************************************************************************************
' Nombre del PA           : archivo.PA_Archivo_Sel_Detalle
' Descripción             : Consulta el detalle de un archivo y su información relacionada.
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
    EXEC [archivo].[PA_Archivo_Sel_Detalle]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [archivo].[PA_Archivo_Sel_Detalle]
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
        @bCtx BIT,@cMsg NVARCHAR(300),@nId BIGINT;

    SELECT @bResultado=0,@cMensaje=N'No se pudo consultar el documento.';

    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
        @cJson=@cJson,@cCodigoPermiso='ARCHIVOS_VER',
        @nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,
        @nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,
        @nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,
        @gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,
        @bResultado=@bCtx OUTPUT,@cMensaje=@cMsg OUTPUT;

    IF @bCtx=0
    BEGIN
        SET @cMensaje=@cMsg;
        GOTO __DESCO_Salida;
    END;

    SELECT @nId=archivoId
    FROM OPENJSON(@cJson,'$.archivo')
    WITH(archivoId BIGINT '$.archivoId');

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

    IF @nId IS NULL
       OR NOT EXISTS(SELECT 1 FROM [archivo].[Archivo] WHERE archivo_id=@nId AND estado=1)
    BEGIN
        SET @cMensaje=N'El documento seleccionado no está disponible.';
        GOTO __DESCO_Salida;
    END;

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
        GOTO __DESCO_Salida;
    END;

    SELECT
        A.archivo_id archivoId,
        A.nombre_original nombreOriginal,
        A.mime_type mimeType,
        A.cloudinary_public_id cloudinaryPublicId,
        A.secure_url secureUrl,
        A.tamano_bytes tamanoBytes,
        A.categoria,
        A.tipo_evidencia tipoEvidencia,
        A.origen_captura origenCaptura,
        A.descripcion,
        A.fecha_captura fechaCaptura,
        CASE WHEN A.posicion_captura IS NULL THEN NULL ELSE A.posicion_captura.Lat END latitudCaptura,
        CASE WHEN A.posicion_captura IS NULL THEN NULL ELSE A.posicion_captura.Long END longitudCaptura,
        A.fecha_carga fechaCarga,
        A.usuario_id usuarioId,
        U.nombre_usuario nombreUsuario
    FROM [archivo].[Archivo] A
    INNER JOIN [seg].[Usuario] U
        ON U.usuario_id=A.usuario_id
    WHERE A.archivo_id=@nId;

    SELECT
        V.archivo_vinculo_id archivoVinculoId,
        CASE
            WHEN V.socio_id IS NOT NULL THEN N'Productor / socio'
            WHEN V.empleado_id IS NOT NULL THEN N'Empleado'
            WHEN V.predio_id IS NOT NULL THEN N'Predio'
            WHEN V.parcela_id IS NOT NULL THEN N'Parcela'
            WHEN V.parcela_cultivo_id IS NOT NULL THEN N'Cultivo'
            WHEN V.censo_plantas_id IS NOT NULL THEN N'Censo de plantas'
            WHEN V.salida_campo_id IS NOT NULL THEN N'Salida de campo'
            WHEN V.visita_tecnica_id IS NOT NULL THEN N'Visita técnica'
            WHEN V.evaluacion_agronomica_id IS NOT NULL THEN N'Evaluación agronómica'
            WHEN V.caso_fitosanitario_id IS NOT NULL THEN N'Caso de sanidad vegetal'
            WHEN V.tratamiento_id IS NOT NULL THEN N'Tratamiento sanitario'
            WHEN V.seguimiento_fitosanitario_id IS NOT NULL THEN N'Seguimiento sanitario'
            WHEN V.disponibilidad_produccion_id IS NOT NULL THEN N'Producción disponible'
            WHEN V.campania_venta_id IS NOT NULL THEN N'Campaña de venta'
            WHEN V.precio_comercial_id IS NOT NULL THEN N'Precio comercial'
            WHEN V.participacion_campania_socio_id IS NOT NULL THEN N'Participación en campaña'
            WHEN V.operativo_venta_id IS NOT NULL THEN N'Operativo de venta'
            WHEN V.jaba_asignacion_id IS NOT NULL THEN N'Asignación de jabas'
            WHEN V.jaba_devolucion_id IS NOT NULL THEN N'Devolución de jabas'
            WHEN V.entrega_socio_id IS NOT NULL THEN N'Entrega del socio'
            WHEN V.incidencia_operativa_id IS NOT NULL THEN N'Incidencia operativa'
            WHEN V.ajuste_precio_socio_id IS NOT NULL THEN N'Ajuste de precio'
            WHEN V.bien_inventario_id IS NOT NULL THEN N'Bien de inventario'
            WHEN V.recurso_programado_id IS NOT NULL THEN N'Recurso programado'
            WHEN V.gasto_campania_id IS NOT NULL THEN N'Gasto de campaña'
            WHEN V.liquidacion_socio_id IS NOT NULL THEN N'Liquidación'
            WHEN V.pago_socio_id IS NOT NULL THEN N'Pago al socio'
            WHEN V.cobro_comprador_id IS NOT NULL THEN N'Cobro del comprador'
            ELSE N'Sin contexto'
        END tipoContexto,
        COALESCE
        (
            V.socio_id,V.empleado_id,V.predio_id,V.parcela_id,V.parcela_cultivo_id,V.censo_plantas_id,
            V.salida_campo_id,V.visita_tecnica_id,V.evaluacion_agronomica_id,V.caso_fitosanitario_id,
            V.tratamiento_id,V.seguimiento_fitosanitario_id,V.disponibilidad_produccion_id,
            V.campania_venta_id,V.precio_comercial_id,V.participacion_campania_socio_id,V.operativo_venta_id,
            V.jaba_asignacion_id,V.jaba_devolucion_id,V.entrega_socio_id,V.incidencia_operativa_id,
            V.ajuste_precio_socio_id,V.bien_inventario_id,V.recurso_programado_id,V.gasto_campania_id,
            V.liquidacion_socio_id,V.pago_socio_id,V.cobro_comprador_id
        ) contextoId,
        V.predio_id predioId,
        V.salida_campo_id salidaCampoId,
        V.visita_tecnica_id visitaTecnicaId,
        V.caso_fitosanitario_id casoFitosanitarioId,
        V.tratamiento_id tratamientoId,
        V.entrega_socio_id entregaSocioId,
        V.incidencia_operativa_id incidenciaOperativaId,
        V.ajuste_precio_socio_id ajustePrecioSocioId,
        V.gasto_campania_id gastoCampaniaId,
        V.liquidacion_socio_id liquidacionSocioId,
        V.pago_socio_id pagoSocioId,
        V.cobro_comprador_id cobroCompradorId,
        V.socio_id socioId,
        V.empleado_id empleadoId,
        V.parcela_id parcelaId,
        V.parcela_cultivo_id parcelaCultivoId,
        V.censo_plantas_id censoPlantasId,
        V.evaluacion_agronomica_id evaluacionAgronomicaId,
        V.seguimiento_fitosanitario_id seguimientoFitosanitarioId,
        V.disponibilidad_produccion_id disponibilidadProduccionId,
        V.campania_venta_id campaniaVentaId,
        V.precio_comercial_id precioComercialId,
        V.participacion_campania_socio_id participacionCampaniaSocioId,
        V.operativo_venta_id operativoVentaId,
        V.jaba_asignacion_id jabaAsignacionId,
        V.jaba_devolucion_id jabaDevolucionId,
        V.bien_inventario_id bienInventarioId,
        V.recurso_programado_id recursoProgramadoId
    FROM [archivo].[ArchivoVinculo] V
    WHERE V.archivo_id=@nId
      AND V.estado=1;

    SET @bResultado=1;
    SET @cMensaje=N'Documento consultado correctamente.';

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
    @cProcedimiento = N'archivo.PA_Archivo_Sel_Detalle',
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
    @cProcedimiento = N'archivo.PA_Archivo_Sel_Detalle',
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
FROM config.FN_RespuestaUsuario(N'archivo.PA_Archivo_Sel_Detalle',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
