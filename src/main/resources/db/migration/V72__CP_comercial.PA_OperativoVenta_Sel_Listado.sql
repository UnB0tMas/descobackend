IF OBJECT_ID(N'[comercial].[PA_OperativoVenta_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_OperativoVenta_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_OperativoVenta_Sel_Listado
' Descripción             : Lista los operativos de venta.
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
    EXEC [comercial].[PA_OperativoVenta_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [comercial].[PA_OperativoVenta_Sel_Listado]
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

    BEGIN TRY

    SET NOCOUNT ON;
    DECLARE @nPaginaListado INT, @nTamanoListado INT, @nOffsetListado BIGINT;
    EXEC [seg].[PA_Consulta_Sel_ResolverPaginacion]
         @cJson = @cJson,
         @nPagina = @nPaginaListado OUTPUT,
         @nTamanoPagina = @nTamanoListado OUTPUT,
         @nOffset = @nOffsetListado OUTPUT;

    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,
            @gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
            @bCtx BIT,@cMsg NVARCHAR(300),@nCamp BIGINT,@cEstado VARCHAR(20);

    SELECT @bResultado=0,@cMensaje=N'No se pudieron consultar los operativos.';

    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
         @cJson=@cJson,@cCodigoPermiso='OPERATIVOS_LISTAR',
         @nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,
         @nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,
         @nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,
         @gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,
         @bResultado=@bCtx OUTPUT,@cMensaje=@cMsg OUTPUT;
    IF @bCtx=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;

    SELECT @nCamp=campaniaVentaId,
           @cEstado=UPPER(NULLIF(LTRIM(RTRIM(estadoProceso)),''))
    FROM OPENJSON(@cJson,'$.filtros')
    WITH(campaniaVentaId BIGINT '$.campaniaVentaId',estadoProceso VARCHAR(20) '$.estadoProceso');

    SELECT
        O.operativo_venta_id operativoVentaId,
        O.campania_venta_id campaniaVentaId,
        C.nombre campania,
        O.codigo,
        O.fecha_inicio_programada fechaInicioProgramada,
        O.fecha_fin_programada fechaFinProgramada,
        O.fecha_inicio_real fechaInicioReal,
        O.fecha_fin_real fechaFinReal,
        O.cantidad_jabas_recibidas cantidadJabasRecibidas,
        COALESCE(JA.jabasAsignadas,0) jabasAsignadas,
        COALESCE(JD.jabasDevueltas,0) jabasDevueltas,
        CASE WHEN O.cantidad_jabas_recibidas-COALESCE(JA.jabasAsignadas,0)<0 THEN 0
             ELSE O.cantidad_jabas_recibidas-COALESCE(JA.jabasAsignadas,0) END jabasDisponibles,
        CASE WHEN COALESCE(JA.jabasAsignadas,0)-COALESCE(JD.jabasDevueltas,0)<0 THEN 0
             ELSE COALESCE(JA.jabasAsignadas,0)-COALESCE(JD.jabasDevueltas,0) END jabasPendientes,
        COALESCE(EN.kilosNetos,0) kilosRecibidos,
        COALESCE(EN.kilosAceptados,0) kilosAceptados,
        COALESCE(EN.kilosRechazados,0) kilosRechazados,
        O.estado_proceso estadoProceso,
        O.observacion,
        COALESCE(OS.participantes,0) participantes,
        COALESCE(EN.entregas,0) entregas,
        COALESCE(INC.incidenciasPendientes,0) incidenciasPendientes
    , COUNT_BIG(*) OVER() AS totalRegistros FROM comercial.OperativoVenta O
    INNER JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id
    OUTER APPLY
    (
        SELECT COUNT_BIG(*) participantes
        FROM comercial.OperativoSocio X
        WHERE X.operativo_venta_id=O.operativo_venta_id AND X.estado=1
    ) OS
    OUTER APPLY
    (
        SELECT COALESCE(SUM(X.cantidad_asignada),0) jabasAsignadas
        FROM comercial.JabaAsignacion X
        INNER JOIN comercial.OperativoSocio S ON S.operativo_socio_id=X.operativo_socio_id
        WHERE S.operativo_venta_id=O.operativo_venta_id AND S.estado=1 AND X.estado=1
    ) JA
    OUTER APPLY
    (
        SELECT COALESCE(SUM(D.cantidad_llenas+D.cantidad_vacias),0) jabasDevueltas
        FROM comercial.JabaDevolucion D
        INNER JOIN comercial.JabaAsignacion A ON A.jaba_asignacion_id=D.jaba_asignacion_id
        INNER JOIN comercial.OperativoSocio S ON S.operativo_socio_id=A.operativo_socio_id
        WHERE S.operativo_venta_id=O.operativo_venta_id AND S.estado=1 AND A.estado=1 AND D.estado=1
    ) JD
    OUTER APPLY
    (
        SELECT COUNT_BIG(*) entregas,
               COALESCE(SUM(E.peso_neto_kg),0) kilosNetos,
               COALESCE(SUM(E.peso_aceptado_kg),0) kilosAceptados,
               COALESCE(SUM(E.peso_rechazado_kg),0) kilosRechazados
        FROM comercial.EntregaSocio E
        INNER JOIN comercial.OperativoSocio S ON S.operativo_socio_id=E.operativo_socio_id
        WHERE S.operativo_venta_id=O.operativo_venta_id
          AND S.estado=1
          AND E.estado=1
          AND E.estado_proceso<>'ANULADA'
    ) EN
    OUTER APPLY
    (
        SELECT COUNT_BIG(*) incidenciasPendientes
        FROM comercial.IncidenciaOperativa I
        WHERE I.operativo_venta_id=O.operativo_venta_id
          AND I.estado=1
          AND I.estado_incidencia IN('ABIERTA','EN_REVISION')
    ) INC
    WHERE O.estado=1
      AND (@nCamp IS NULL OR O.campania_venta_id=@nCamp)
      AND (@cEstado IS NULL OR O.estado_proceso=@cEstado)
    ORDER BY O.fecha_inicio_programada DESC,O.operativo_venta_id DESC OFFSET @nOffsetListado ROWS FETCH NEXT @nTamanoListado ROWS ONLY;

    SET @bResultado=1;
    SET @cMensaje=N'Operativos consultados correctamente.';

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
    @cProcedimiento = N'comercial.PA_OperativoVenta_Sel_Listado',
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
    @cProcedimiento = N'comercial.PA_OperativoVenta_Sel_Listado',
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
FROM config.FN_RespuestaUsuario(N'comercial.PA_OperativoVenta_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
