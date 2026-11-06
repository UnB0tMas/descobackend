IF OBJECT_ID(N'[logistica].[PA_BienInventario_Sel_Detalle]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_BienInventario_Sel_Detalle];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_BienInventario_Sel_Detalle
' Descripción             : Consulta el detalle de bien de inventario.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
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
    EXEC [logistica].[PA_BienInventario_Sel_Detalle]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
IF OBJECT_ID(N'[logistica].[PA_BienInventario_Sel_Detalle]', N'P') IS NOT NULL DROP PROCEDURE [logistica].[PA_BienInventario_Sel_Detalle];
GO
CREATE PROCEDURE [logistica].[PA_BienInventario_Sel_Detalle](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
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
SELECT @bResultado=0,@cMensaje=N'No se pudo consultar el bien.';
EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='INVENTARIO_VER',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@bResultado=@bCtx OUTPUT,@cMensaje=@cMsg OUTPUT;
IF @bCtx=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;
 DECLARE @nId BIGINT;
SELECT @nId=bienInventarioId FROM OPENJSON(@cJson,'$.bien') WITH(bienInventarioId BIGINT '$.bienInventarioId');
IF NOT EXISTS(SELECT 1 FROM logistica.BienInventario WHERE bien_inventario_id=@nId AND estado=1) BEGIN SET @cMensaje=N'El bien seleccionado no está disponible.';
GOTO __DESCO_Salida;
END;
SELECT B.*,E.razon_social empresa,T.nombre tipoBien,V.placa,V.tipo_vehiculo tipoVehiculo,V.kilometraje_km kilometrajeKm,V.color color FROM logistica.BienInventario B INNER JOIN org.Empresa E ON E.empresa_id=B.empresa_id INNER JOIN logistica.TipoBien T ON T.tipo_bien_id=B.tipo_bien_id LEFT JOIN logistica.Vehiculo V ON V.vehiculo_id=B.bien_inventario_id AND V.estado=1 WHERE B.bien_inventario_id=@nId;
SELECT R.recurso_programado_id recursoProgramadoId,R.estado_proceso estadoProceso,R.cantidad_programada cantidadProgramada,R.fecha_programacion fechaProgramacion,R.campania_venta_id campaniaVentaId,R.operativo_venta_id operativoVentaId,R.salida_campo_id salidaCampoId FROM logistica.RecursoProgramado R WHERE R.bien_inventario_id=@nId AND R.estado=1 ORDER BY R.fecha_programacion DESC;
SELECT M.recurso_movimiento_id recursoMovimientoId,M.tipo_movimiento tipoMovimiento,M.cantidad,M.fecha_hora fechaHora,M.observacion FROM logistica.RecursoMovimiento M INNER JOIN logistica.RecursoProgramado R ON R.recurso_programado_id=M.recurso_programado_id WHERE R.bien_inventario_id=@nId AND M.estado=1 ORDER BY M.fecha_hora DESC;
SET @bResultado=1;
SET @cMensaje=N'Bien consultado correctamente.';
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
    @cProcedimiento = N'logistica.PA_BienInventario_Sel_Detalle',
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
    @cProcedimiento = N'logistica.PA_BienInventario_Sel_Detalle',
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
FROM config.FN_RespuestaUsuario(N'logistica.PA_BienInventario_Sel_Detalle',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=N'Consulta patrimonial incluyendo el color opcional del vehiculo.',@level0type=N'SCHEMA',@level0name=N'logistica',@level1type=N'PROCEDURE',@level1name=N'PA_BienInventario_Sel_Detalle';
GO
