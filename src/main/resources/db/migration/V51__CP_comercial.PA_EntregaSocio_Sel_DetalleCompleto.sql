IF OBJECT_ID(N'[comercial].[PA_EntregaSocio_Sel_DetalleCompleto]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_EntregaSocio_Sel_DetalleCompleto];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_EntregaSocio_Sel_DetalleCompleto
' Descripción             : Obtiene el detalle completo de una entrega de socio.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Comercial
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo de referencia: reemplazar valores e identificadores por datos válidos.
    -- El JSON debe incluir el contexto y los campos exigidos por este PA.
    DECLARE
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [comercial].[PA_EntregaSocio_Sel_DetalleCompleto]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [comercial].[PA_EntregaSocio_Sel_DetalleCompleto](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
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

    BEGIN TRY
  SET NOCOUNT ON;
DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bCtx BIT,@cMsg NVARCHAR(300);
SELECT @bResultado=0,@cMensaje=N'No se pudo consultar la entrega.';
EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='ENTREGAS_VER',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@bResultado=@bCtx OUTPUT,@cMensaje=@cMsg OUTPUT;
IF @bCtx=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;
 DECLARE @nId BIGINT;
SELECT @nId=entregaSocioId FROM OPENJSON(@cJson,'$.entrega') WITH(entregaSocioId BIGINT '$.entregaSocioId');
IF NOT EXISTS(SELECT 1 FROM comercial.EntregaSocio WHERE entrega_socio_id=@nId AND estado=1) BEGIN SET @cMensaje=N'La entrega seleccionada no está disponible.';
GOTO __DESCO_Salida;
END;
SELECT E.entrega_socio_id entregaSocioId,E.codigo_lote codigoLote,E.fecha_hora fechaHora,E.peso_bruto_kg pesoBrutoKg,E.tara_kg taraKg,E.peso_neto_kg pesoNetoKg,E.peso_rechazado_kg pesoRechazadoKg,E.peso_aceptado_kg pesoAceptadoKg,E.estado_control_calidad estadoControlCalidad,E.ticket_balanza ticketBalanza,E.observacion,E.estado_proceso estadoProceso,E.predio_id predioId,PR.codigo predioCodigo,O.operativo_venta_id operativoVentaId,O.codigo operativo,PE.numero_documento numeroDocumento,CONCAT(PE.nombres,N' ',PE.apellido_paterno,N' ',COALESCE(PE.apellido_materno,N'')) socioNombre FROM comercial.EntregaSocio E INNER JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id INNER JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id INNER JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=OS.participacion_campania_socio_id INNER JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=P.socio_asociacion_id INNER JOIN org.Persona PE ON PE.persona_id=SA.socio_id LEFT JOIN prod.Predio PR ON PR.predio_id=E.predio_id WHERE E.entrega_socio_id=@nId;
SELECT D.entrega_detalle_id entregaDetalleId,D.variedad_palta_id variedadPaltaId,V.nombre variedad,D.condicion_comercial_id condicionComercialId,C.nombre condicion,D.precio_comercial_id precioComercialId,D.kilogramos,D.precio_base precioBase,D.precio_aplicado precioAplicado,D.importe FROM comercial.EntregaDetalle D INNER JOIN prod.VariedadPalta V ON V.variedad_palta_id=D.variedad_palta_id INNER JOIN comercial.CondicionComercial C ON C.condicion_comercial_id=D.condicion_comercial_id WHERE D.entrega_socio_id=@nId AND D.estado=1;
SELECT I.incidencia_operativa_id incidenciaId,I.tipo_incidencia tipoIncidencia,I.severidad,I.peso_afectado_kg pesoAfectadoKg,I.descripcion,I.estado_incidencia estadoIncidencia FROM comercial.IncidenciaOperativa I WHERE I.entrega_socio_id=@nId AND I.estado=1;
SELECT A.archivo_id archivoId,A.nombre_original nombreOriginal,A.mime_type mimeType,A.secure_url secureUrl,A.categoria,A.descripcion,A.fecha_carga fechaCarga FROM archivo.ArchivoVinculo V INNER JOIN archivo.Archivo A ON A.archivo_id=V.archivo_id AND A.estado=1 WHERE V.entrega_socio_id=@nId AND V.estado=1;
SET @bResultado=1;
SET @cMensaje=N'Entrega consultada correctamente.';
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
    @cProcedimiento = N'comercial.PA_EntregaSocio_Sel_DetalleCompleto',
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
    @cProcedimiento = N'comercial.PA_EntregaSocio_Sel_DetalleCompleto',
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
FROM config.FN_RespuestaUsuario(N'comercial.PA_EntregaSocio_Sel_DetalleCompleto',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
