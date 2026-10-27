IF OBJECT_ID(N'[campo].[PA_VisitaTecnica_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [campo].[PA_VisitaTecnica_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : campo.PA_VisitaTecnica_Sel_Listado
' Descripción             : Consulta las visitas técnicas según los filtros recibidos.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Campo
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
    EXEC [campo].[PA_VisitaTecnica_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [campo].[PA_VisitaTecnica_Sel_Listado]
(
    @cJson NVARCHAR(MAX), @bResultado BIT OUTPUT, @cMensaje NVARCHAR(300) OUTPUT,
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

    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,
            @gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
            @bCtx BIT,@cMsg NVARCHAR(300),@nPagina INT=1,@nTam INT=20,@nPredio BIGINT=NULL,
            @nEmpleado BIGINT=NULL,@nSalida BIGINT=NULL,@cEstado VARCHAR(20)=NULL,
            @dDesde DATETIME2(0)=NULL,@dHasta DATETIME2(0)=NULL,@cBuscar NVARCHAR(120)=NULL;

    SET @bResultado=0;
 SET @cMensaje=N'No se pudieron consultar las visitas.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
        @cJson,'VISITAS_LISTAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,
        @nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bCtx OUTPUT,@cMsg OUTPUT;
    IF @bCtx=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;

    SELECT @nPagina=ISNULL(NULLIF(pagina,0),1),@nTam=ISNULL(NULLIF(tamanoPagina,0),20),
           @nPredio=predioId,@nEmpleado=empleadoId,@nSalida=salidaCampoId,
           @cEstado=UPPER(NULLIF(LTRIM(RTRIM(estadoProceso)),'')),
           @dDesde=fechaDesde,@dHasta=fechaHasta,
           @cBuscar=NULLIF(LTRIM(RTRIM(buscar)),N'')
    FROM OPENJSON(@cJson,'$.filtros') WITH
    (pagina INT '$.pagina',tamanoPagina INT '$.tamanoPagina',predioId BIGINT '$.predioId',
     empleadoId BIGINT '$.empleadoId',salidaCampoId BIGINT '$.salidaCampoId',
     estadoProceso VARCHAR(20) '$.estadoProceso',fechaDesde DATETIME2(0) '$.fechaDesde',
     fechaHasta DATETIME2(0) '$.fechaHasta',buscar NVARCHAR(120) '$.buscar');
    IF @nPagina<1 SET @nPagina=1;
 IF @nTam<1 SET @nTam=20;
 IF @nTam>200 SET @nTam=200;

    ;
WITH Q AS
    (
        SELECT V.visita_tecnica_id,V.salida_participante_id,SP.salida_campo_id,SP.empleado_id,
               CONCAT(PER.nombres,N' ',PER.apellido_paterno,
                      CASE WHEN PER.apellido_materno IS NULL THEN N'' ELSE N' '+PER.apellido_materno END) tecnico,
               V.predio_id,PR.codigo codigo_predio,PR.nombre predio,
               V.fecha_hora_inicio,V.fecha_hora_fin,V.objetivo,V.estado_proceso,
               CASE WHEN V.posicion_inicio IS NULL THEN NULL ELSE V.posicion_inicio.Lat END latitud,
               CASE WHEN V.posicion_inicio IS NULL THEN NULL ELSE V.posicion_inicio.Long END longitud,
               COUNT(*) OVER() total_registros
        FROM [campo].[VisitaTecnica] V
        INNER JOIN [campo].[SalidaParticipante] SP ON SP.salida_participante_id=V.salida_participante_id
        INNER JOIN [org].[Empleado] E ON E.empleado_id=SP.empleado_id
        INNER JOIN [org].[Persona] PER ON PER.persona_id=E.empleado_id
        INNER JOIN [prod].[Predio] PR ON PR.predio_id=V.predio_id
        WHERE V.estado=1
          AND (@nPredio IS NULL OR V.predio_id=@nPredio)
          AND (@nEmpleado IS NULL OR SP.empleado_id=@nEmpleado)
          AND (@nSalida IS NULL OR SP.salida_campo_id=@nSalida)
          AND (@cEstado IS NULL OR V.estado_proceso=@cEstado)
          AND (@dDesde IS NULL OR V.fecha_hora_inicio>=@dDesde)
          AND (@dHasta IS NULL OR V.fecha_hora_inicio<DATEADD(DAY,1,@dHasta))
          AND (@cBuscar IS NULL OR PR.codigo LIKE N'%'+@cBuscar+N'%' OR PR.nombre LIKE N'%'+@cBuscar+N'%'
               OR PER.nombres LIKE N'%'+@cBuscar+N'%' OR PER.apellido_paterno LIKE N'%'+@cBuscar+N'%')
    )
    SELECT visita_tecnica_id AS visitaTecnicaId,salida_participante_id AS salidaParticipanteId,
           salida_campo_id AS salidaCampoId,empleado_id AS empleadoId,tecnico,
           predio_id AS predioId,codigo_predio AS codigoPredio,predio,
           fecha_hora_inicio AS fechaHoraInicio,fecha_hora_fin AS fechaHoraFin,objetivo,
           estado_proceso AS estadoProceso,latitud,longitud,total_registros AS totalRegistros
    FROM Q
    ORDER BY fecha_hora_inicio DESC,visita_tecnica_id DESC
    OFFSET (@nPagina-1)*@nTam ROWS FETCH NEXT @nTam ROWS ONLY;

    SET @bResultado=1;
 SET @cMensaje=N'Consulta realizada correctamente.';

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
    @cProcedimiento = N'campo.PA_VisitaTecnica_Sel_Listado',
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
    @cProcedimiento = N'campo.PA_VisitaTecnica_Sel_Listado',
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
FROM config.FN_RespuestaUsuario(N'campo.PA_VisitaTecnica_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
