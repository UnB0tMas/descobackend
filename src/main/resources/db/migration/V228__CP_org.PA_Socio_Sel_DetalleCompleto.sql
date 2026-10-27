IF OBJECT_ID(N'[org].[PA_Socio_Sel_DetalleCompleto]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_Socio_Sel_DetalleCompleto];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_Socio_Sel_DetalleCompleto
' Descripción             : Consulta el detalle completo de socios.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Organización
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
    EXEC [org].[PA_Socio_Sel_DetalleCompleto]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [org].[PA_Socio_Sel_DetalleCompleto]
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
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bOk BIT,@cMsg NVARCHAR(300),@nSocio BIGINT;
    SET @bResultado=0;
 SET @cMensaje=N'No se pudo cargar el detalle.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado] @cJson,'PRODUCTORES_VER',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bOk OUTPUT,@cMsg OUTPUT;
    IF @bOk=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    SELECT @nSocio=socioId FROM OPENJSON(@cJson,'$.filtros') WITH (socioId BIGINT '$.socioId');
    IF @nSocio IS NULL OR NOT EXISTS(SELECT 1 FROM [org].[Socio] WHERE socio_id=@nSocio) BEGIN SET @cMensaje=N'El socio seleccionado no está disponible.';
 GOTO __DESCO_Salida;
 END;

    /* 1. Ficha principal */
    SELECT S.socio_id,P.tipo_documento,P.numero_documento,P.nombres,P.apellido_paterno,P.apellido_materno,P.telefono,P.correo,P.fecha_nacimiento,S.fecha_alta,S.estado,
           SA.socio_asociacion_id,SA.asociacion_id,SA.codigo_socio,SA.fecha_desde,SA.situacion_membresia,E.razon_social asociacionNombre,
           UB.distrito_codigo distritoCodigo,D.nombre distritoNombre,UB.centro_poblado_id centroPobladoId,CP.nombre centroPobladoNombre,UB.referencia referencia
    FROM [org].[Socio] S INNER JOIN [org].[Persona] P ON P.persona_id=S.socio_id
    OUTER APPLY(SELECT TOP(1) X.* FROM [org].[SocioAsociacion] X WHERE X.socio_id=S.socio_id AND X.estado=1 AND X.fecha_hasta IS NULL ORDER BY X.fecha_desde DESC) SA
    LEFT JOIN [org].[Empresa] E ON E.empresa_id=SA.asociacion_id
    LEFT JOIN [geo].[Ubicacion] UB ON UB.ubicacion_id=P.ubicacion_id
    LEFT JOIN [geo].[Distrito] D ON D.distrito_codigo=UB.distrito_codigo
    LEFT JOIN [geo].[CentroPoblado] CP ON CP.centro_poblado_id=UB.centro_poblado_id AND CP.distrito_codigo=UB.distrito_codigo
    WHERE S.socio_id=@nSocio;

    /* 2. Historial de membresía */
    SELECT SA.socio_asociacion_id,SA.asociacion_id,E.razon_social asociacionNombre,SA.codigo_socio,SA.fecha_desde,SA.fecha_hasta,SA.situacion_membresia,SA.estado
    FROM [org].[SocioAsociacion] SA INNER JOIN [org].[Empresa] E ON E.empresa_id=SA.asociacion_id WHERE SA.socio_id=@nSocio ORDER BY SA.fecha_desde DESC;

    /* 3. Predios */
    SELECT DISTINCT PR.predio_id,PR.codigo,PR.nombre,PR.fecha_registro,PR.estado,PT.tipo_titularidad,PT.porcentaje,PT.fecha_desde,PT.fecha_hasta
    FROM [prod].[PredioTitularidad] PT INNER JOIN [prod].[Predio] PR ON PR.predio_id=PT.predio_id WHERE PT.socio_id=@nSocio ORDER BY PR.nombre;

    /* 4. Campañas históricas */
    SELECT PCS.participacion_campania_socio_id,C.campania_venta_id,C.codigo,C.nombre,C.fecha_inicio,C.fecha_fin,C.estado_proceso,PCS.estado_participacion,PCS.fecha_registro
    FROM [org].[SocioAsociacion] SA INNER JOIN [comercial].[ParticipacionCampaniaSocio] PCS ON PCS.socio_asociacion_id=SA.socio_asociacion_id
    INNER JOIN [comercial].[CampaniaVenta] C ON C.campania_venta_id=PCS.campania_venta_id WHERE SA.socio_id=@nSocio ORDER BY C.fecha_inicio DESC;

    SET @bResultado=1;
 SET @cMensaje=N'Detalle cargado correctamente.';

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
    @cProcedimiento = N'org.PA_Socio_Sel_DetalleCompleto',
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
    @cProcedimiento = N'org.PA_Socio_Sel_DetalleCompleto',
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
FROM config.FN_RespuestaUsuario(N'org.PA_Socio_Sel_DetalleCompleto',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
