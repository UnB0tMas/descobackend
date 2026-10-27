IF OBJECT_ID(N'[comercial].[PA_OperativoVenta_Sel_DetalleCompleto]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_OperativoVenta_Sel_DetalleCompleto];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_OperativoVenta_Sel_DetalleCompleto
' Descripción             : Consulta el detalle completo de un operativo de venta.
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
    EXEC [comercial].[PA_OperativoVenta_Sel_DetalleCompleto]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [comercial].[PA_OperativoVenta_Sel_DetalleCompleto](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
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
    SELECT @bResultado=0,@cMensaje=N'No se pudo consultar el operativo.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado] @cJson=@cJson,@cCodigoPermiso='OPERATIVOS_VER',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@bResultado=@bCtx OUTPUT,@cMensaje=@cMsg OUTPUT;
    IF @bCtx=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
 DECLARE @nId BIGINT,@r INT,@a INT,@d INT,@p INT,@dispJ INT;
SELECT @nId=operativoVentaId FROM OPENJSON(@cJson,'$.operativo') WITH(operativoVentaId BIGINT '$.operativoVentaId');
IF NOT EXISTS(SELECT 1 FROM comercial.OperativoVenta WHERE operativo_venta_id=@nId AND estado=1) BEGIN SET @cMensaje=N'El operativo seleccionado no está disponible.';
GOTO __DESCO_Salida;
END;
EXEC comercial.PA_Jabas_Sel_SaldoInterno @nOperativoVentaId=@nId,@nOperativoSocioId=NULL,@nRecibidas=@r OUTPUT,@nAsignadas=@a OUTPUT,@nDevueltas=@d OUTPUT,@nPendientes=@p OUTPUT,@nDisponibles=@dispJ OUTPUT;
SELECT O.operativo_venta_id operativoVentaId,O.codigo,O.campania_venta_id campaniaVentaId,C.nombre campania,O.fecha_inicio_programada fechaInicioProgramada,O.fecha_fin_programada fechaFinProgramada,O.fecha_inicio_real fechaInicioReal,O.fecha_fin_real fechaFinReal,O.estado_proceso estadoProceso,O.observacion,@r jabasRecibidas,@a jabasAsignadas,@d jabasDevueltas,@p jabasPendientes,@dispJ jabasDisponibles FROM comercial.OperativoVenta O INNER JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id WHERE O.operativo_venta_id=@nId;
SELECT Z.zona_productiva_id zonaProductivaId,Z.codigo,Z.nombre FROM comercial.OperativoZona OZ INNER JOIN geo.ZonaProductiva Z ON Z.zona_productiva_id=OZ.zona_productiva_id WHERE OZ.operativo_venta_id=@nId AND OZ.estado=1;
SELECT OS.operativo_socio_id operativoSocioId,OS.estado_participacion estadoParticipacion,P.participacion_campania_socio_id participacionId,PE.numero_documento numeroDocumento,CONCAT(PE.nombres,N' ',PE.apellido_paterno,N' ',COALESCE(PE.apellido_materno,N'')) socioNombre FROM comercial.OperativoSocio OS INNER JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=OS.participacion_campania_socio_id INNER JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=P.socio_asociacion_id INNER JOIN org.Persona PE ON PE.persona_id=SA.socio_id WHERE OS.operativo_venta_id=@nId AND OS.estado=1 ORDER BY socioNombre;
SELECT entrega_socio_id entregaSocioId,codigo_lote codigoLote,fecha_hora fechaHora,peso_aceptado_kg pesoAceptadoKg,estado_control_calidad estadoControlCalidad,estado_proceso estadoProceso FROM comercial.EntregaSocio E INNER JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id WHERE OS.operativo_venta_id=@nId AND E.estado=1 ORDER BY E.fecha_hora;
SELECT incidencia_operativa_id incidenciaId,tipo_incidencia tipoIncidencia,severidad,descripcion,estado_incidencia estadoIncidencia FROM comercial.IncidenciaOperativa WHERE operativo_venta_id=@nId AND estado=1 ORDER BY fecha_hora DESC;
SET @bResultado=1;
SET @cMensaje=N'Operativo consultado correctamente.';
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
    @cProcedimiento = N'comercial.PA_OperativoVenta_Sel_DetalleCompleto',
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
    @cProcedimiento = N'comercial.PA_OperativoVenta_Sel_DetalleCompleto',
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
FROM config.FN_RespuestaUsuario(N'comercial.PA_OperativoVenta_Sel_DetalleCompleto',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
