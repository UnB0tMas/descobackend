IF OBJECT_ID(N'[auditoria].[PA_Auditoria_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [auditoria].[PA_Auditoria_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : auditoria.PA_Auditoria_Sel_Listado
' Descripción             : Consulta eventos de auditoría con filtros y paginación.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Auditoría
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
    EXEC [auditoria].[PA_Auditoria_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [auditoria].[PA_Auditoria_Sel_Listado](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
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
    SELECT @bResultado=0,@cMensaje=N'No se pudo consultar la auditoría.';
    EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='AUDITORIA_LISTAR',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@bResultado=@bCtx OUTPUT,@cMensaje=@cMsg OUTPUT;
    IF @bCtx=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;
DECLARE @dDesde DATETIME2(0),@dHasta DATETIME2(0),@nUsuarioFiltro BIGINT,@nModuloFiltro INT,@cAccion VARCHAR(40),@cEsq SYSNAME,@cEnt SYSNAME,@cResultado VARCHAR(20),@nPagina INT=1,@nTam INT=50,@nOffset INT;
SELECT @dDesde=fechaDesde,@dHasta=fechaHasta,@nUsuarioFiltro=usuarioId,@nModuloFiltro=moduloId,@cAccion=UPPER(NULLIF(LTRIM(RTRIM(accion)),'')),@cEsq=NULLIF(LTRIM(RTRIM(esquemaEntidad)),N''),@cEnt=NULLIF(LTRIM(RTRIM(nombreEntidad)),N''),@cResultado=UPPER(NULLIF(LTRIM(RTRIM(resultado)),'')) FROM OPENJSON(@cJson,'$.filtros') WITH(fechaDesde DATETIME2(0) '$.fechaDesde',fechaHasta DATETIME2(0) '$.fechaHasta',usuarioId BIGINT '$.usuarioId',moduloId INT '$.moduloId',accion VARCHAR(40) '$.accion',esquemaEntidad SYSNAME '$.esquemaEntidad',nombreEntidad SYSNAME '$.nombreEntidad',resultado VARCHAR(20) '$.resultado');
SELECT @nPagina=COALESCE(pagina,1),@nTam=COALESCE(tamano,50) FROM OPENJSON(@cJson,'$.paginacion') WITH(pagina INT '$.pagina',tamano INT '$.tamano');
IF @nPagina<1 SET @nPagina=1;
IF @nTam<1 SET @nTam=50;
IF @nTam>200 SET @nTam=200;
SET @nOffset=(@nPagina-1)*@nTam;
IF @dDesde IS NOT NULL AND @dHasta IS NOT NULL AND @dHasta<@dDesde BEGIN SET @cMensaje=N'El rango de fechas seleccionado no es válido.';
GOTO __DESCO_Salida;
END;
SELECT AE.auditoria_evento_id auditoriaEventoId,AE.fecha_hora fechaHoraUtc,AE.usuario_id usuarioId,U.nombre_usuario nombreUsuario,LTRIM(RTRIM(CONCAT(COALESCE(P.nombres,N''),N' ',COALESCE(P.apellido_paterno,N''),N' ',COALESCE(P.apellido_materno,N'')))) nombrePersona,AE.modulo_id moduloId,M.codigo codigoModulo,M.nombre nombreModulo,AE.accion,AE.esquema_entidad esquemaEntidad,AE.nombre_entidad nombreEntidad,AE.identificador,AE.motivo,AE.resultado,AE.endpoint,AE.ip,AE.sesion_usuario_id sesionUsuarioId,AE.dispositivo_usuario_id dispositivoUsuarioId,AE.correlacion_id correlacionId,AE.solicitud_id solicitudId,COUNT_BIG(*) OVER() totalRegistros FROM auditoria.AuditoriaEvento AE LEFT JOIN seg.Usuario U ON U.usuario_id=AE.usuario_id LEFT JOIN org.Persona P ON P.persona_id=U.persona_id LEFT JOIN seg.Modulo M ON M.modulo_id=AE.modulo_id WHERE AE.estado=1 AND (@dDesde IS NULL OR AE.fecha_hora>=@dDesde) AND (@dHasta IS NULL OR AE.fecha_hora<=@dHasta) AND (@nUsuarioFiltro IS NULL OR AE.usuario_id=@nUsuarioFiltro) AND (@nModuloFiltro IS NULL OR AE.modulo_id=@nModuloFiltro) AND (@cAccion IS NULL OR AE.accion=@cAccion) AND (@cEsq IS NULL OR AE.esquema_entidad=@cEsq) AND (@cEnt IS NULL OR AE.nombre_entidad=@cEnt) AND (@cResultado IS NULL OR AE.resultado=@cResultado) ORDER BY AE.fecha_hora DESC,AE.auditoria_evento_id DESC OFFSET @nOffset ROWS FETCH NEXT @nTam ROWS ONLY;
SET @bResultado=1;
SET @cMensaje=N'Auditoría consultada correctamente.';
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
    @cProcedimiento = N'auditoria.PA_Auditoria_Sel_Listado',
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
    @cProcedimiento = N'auditoria.PA_Auditoria_Sel_Listado',
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
FROM config.FN_RespuestaUsuario(N'auditoria.PA_Auditoria_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
