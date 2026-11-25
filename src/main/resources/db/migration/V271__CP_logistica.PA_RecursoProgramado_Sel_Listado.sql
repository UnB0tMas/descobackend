IF OBJECT_ID(N'[logistica].[PA_RecursoProgramado_Sel_Listado]') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_RecursoProgramado_Sel_Listado];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : logistica.PA_RecursoProgramado_Sel_Listado
' Descripción            : Lista recurso programado.
' Aplicativo / Módulo    : DESCO / Logística
*******************************************************************************************************/
CREATE   PROCEDURE [logistica].[PA_RecursoProgramado_Sel_Listado](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
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
    DECLARE @nPaginaListado INT, @nTamanoListado INT, @nOffsetListado BIGINT;
    EXEC [seg].[PA_Consulta_Sel_ResolverPaginacion]
         @cJson = @cJson,
         @nPagina = @nPaginaListado OUTPUT,
         @nTamanoPagina = @nTamanoListado OUTPUT,
         @nOffset = @nOffsetListado OUTPUT;
DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bCtx BIT,@cMsg NVARCHAR(300);
SELECT @bResultado=0,@cMensaje=N'No se pudieron consultar los recursos programados.';
EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='RECURSOS_LISTAR',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@bResultado=@bCtx OUTPUT,@cMensaje=@cMsg OUTPUT;
IF @bCtx=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;
 DECLARE @cEstado VARCHAR(20),@nCamp BIGINT,@nOpVenta BIGINT,@nSalida BIGINT;
SELECT @cEstado=UPPER(NULLIF(LTRIM(RTRIM(estadoProceso)),'')),@nCamp=campaniaVentaId,@nOpVenta=operativoVentaId,@nSalida=salidaCampoId FROM OPENJSON(@cJson,'$.filtros') WITH(estadoProceso VARCHAR(20) '$.estadoProceso',campaniaVentaId BIGINT '$.campaniaVentaId',operativoVentaId BIGINT '$.operativoVentaId',salidaCampoId BIGINT '$.salidaCampoId');
SELECT R.recurso_programado_id recursoProgramadoId,R.campania_venta_id campaniaVentaId,R.operativo_venta_id operativoVentaId,R.salida_campo_id salidaCampoId,R.bien_inventario_id bienInventarioId,B.nombre bien,R.suministro_id suministroId,S.nombre suministro,R.cantidad_programada cantidadProgramada,R.cantidad_entregada cantidadEntregada,R.cantidad_devuelta cantidadDevuelta,R.cantidad_consumida cantidadConsumida,R.cantidad_pendiente cantidadPendiente,R.estado_proceso estadoProceso,R.fecha_programacion fechaProgramacion,R.observacion,R.cantidad_entregada cantidadEjecutada, COUNT_BIG(*) OVER() AS totalRegistros FROM logistica.RecursoProgramado R LEFT JOIN logistica.BienInventario B ON B.bien_inventario_id=R.bien_inventario_id LEFT JOIN logistica.Suministro S ON S.suministro_id=R.suministro_id WHERE R.estado=1 AND EXISTS(SELECT 1 FROM seg.SesionUsuario SS WHERE SS.sesion_usuario_id=@nSesion AND SS.estado=1 AND SS.fecha_revocacion IS NULL AND (SS.modo_uot='GENERAL' OR SS.uot_contexto_id=COALESCE(S.uot_id,B.uot_id)) AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,COALESCE(S.uot_id,B.uot_id),'RECURSOS_LISTAR')=1) AND (@cEstado IS NULL OR R.estado_proceso=@cEstado) AND (@nCamp IS NULL OR R.campania_venta_id=@nCamp) AND (@nOpVenta IS NULL OR R.operativo_venta_id=@nOpVenta) AND (@nSalida IS NULL OR R.salida_campo_id=@nSalida) ORDER BY R.fecha_programacion DESC,R.recurso_programado_id DESC OFFSET @nOffsetListado ROWS FETCH NEXT @nTamanoListado ROWS ONLY;
SET @bResultado=1;
SET @cMensaje=N'Recursos consultados correctamente.';
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
    @cProcedimiento = N'logistica.PA_RecursoProgramado_Sel_Listado',
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
    @cProcedimiento = N'logistica.PA_RecursoProgramado_Sel_Listado',
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
FROM config.FN_RespuestaUsuario(N'logistica.PA_RecursoProgramado_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
