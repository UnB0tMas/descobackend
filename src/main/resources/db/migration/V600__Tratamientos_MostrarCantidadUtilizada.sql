-- DESCO / 2026-11-06 / AL-03: cantidad utilizada distinta de la dosis.
-- Ejemplo: la ficha sanitaria muestra la cantidad liquidada de la entrega.
/******************************************************************************************************
' Nombre del PA           : sanidad.PA_CasoFitosanitario_Sel_DetalleCompleto
' Descripción             : Consulta el detalle completo de casos fitosanitarios.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Sanidad
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
    EXEC [sanidad].[PA_CasoFitosanitario_Sel_DetalleCompleto]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE OR ALTER PROCEDURE [sanidad].[PA_CasoFitosanitario_Sel_DetalleCompleto]
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
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bCtx BIT,@cMsg NVARCHAR(300),@nCaso BIGINT;
    SELECT @bResultado=0,@cMensaje=N'No se pudo consultar el caso sanitario.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado] @cJson=@cJson,@cCodigoPermiso='SANIDAD_VER',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@bResultado=@bCtx OUTPUT,@cMensaje=@cMsg OUTPUT;
    IF @bCtx=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    SELECT @nCaso=casoFitosanitarioId FROM OPENJSON(@cJson,'$.caso') WITH(casoFitosanitarioId BIGINT '$.casoFitosanitarioId');
    IF @nCaso IS NULL OR NOT EXISTS(SELECT 1 FROM [sanidad].[CasoFitosanitario] WHERE caso_fitosanitario_id=@nCaso AND estado=1) BEGIN SET @cMensaje=N'El caso sanitario seleccionado no está disponible.';
 GOTO __DESCO_Salida;
 END;
    SELECT CF.caso_fitosanitario_id casoFitosanitarioId,CF.parcela_cultivo_id parcelaCultivoId,CF.tipo_problema_fitosanitario_id tipoProblemaId,
           TP.codigo codigoProblema,TP.categoria,TP.nombre problema,CF.visita_deteccion_id visitaDeteccionId,CF.fecha_deteccion fechaDeteccion,
           CF.plantas_afectadas plantasAfectadas,CF.cantidad_estimada cantidadEstimada,CF.severidad,CF.estado_caso estadoCaso,CF.observacion,
           P.parcela_id parcelaId,P.nombre parcelaNombre,PR.predio_id predioId,PR.codigo predioCodigo,PR.nombre predioNombre,VP.nombre variedad
    FROM [sanidad].[CasoFitosanitario] CF INNER JOIN [sanidad].[TipoProblemaFitosanitario] TP ON TP.tipo_problema_fitosanitario_id=CF.tipo_problema_fitosanitario_id
    INNER JOIN [prod].[ParcelaCultivo] PC ON PC.parcela_cultivo_id=CF.parcela_cultivo_id INNER JOIN [prod].[Parcela] P ON P.parcela_id=PC.parcela_id
    INNER JOIN [prod].[Predio] PR ON PR.predio_id=P.predio_id INNER JOIN [prod].[VariedadPalta] VP ON VP.variedad_palta_id=PC.variedad_palta_id
    WHERE CF.caso_fitosanitario_id=@nCaso;
    SELECT T.tratamiento_fitosanitario_id tratamientoId,T.fecha_hora fechaHora,T.visita_tecnica_id visitaTecnicaId,T.responsable_empleado_id responsableEmpleadoId,
           CONCAT(PER.nombres,N' ',PER.apellido_paterno,N' ',COALESCE(PER.apellido_materno,N'')) responsable,T.tratamiento,T.producto,T.dosis,T.unidad_dosis unidadDosis,T.observacion,U.programacion_producto_id programacionProductoId,U.cantidad cantidadUtilizada,PR.unidad_medida unidadUtilizada
    FROM [sanidad].[TratamientoFitosanitario] T LEFT JOIN [org].[Persona] PER ON PER.persona_id=T.responsable_empleado_id
    LEFT JOIN logistica.UsoProductoTecnico U ON U.tipo_origen='SANIDAD' AND U.registro_id=T.tratamiento_fitosanitario_id
 LEFT JOIN logistica.ProgramacionProducto PP ON PP.programacion_producto_id=U.programacion_producto_id
 LEFT JOIN logistica.Producto PR ON PR.producto_id=PP.producto_id
    WHERE T.caso_fitosanitario_id=@nCaso AND T.estado=1 ORDER BY T.fecha_hora DESC;
    SELECT S.seguimiento_fitosanitario_id seguimientoId,S.fecha_hora fechaHora,S.visita_tecnica_id visitaTecnicaId,S.plantas_afectadas plantasAfectadas,
           S.cantidad_estimada cantidadEstimada,S.severidad,S.resultado,S.observacion
    FROM [sanidad].[SeguimientoFitosanitario] S WHERE S.caso_fitosanitario_id=@nCaso AND S.estado=1 ORDER BY S.fecha_hora DESC;
    SELECT A.archivo_id archivoId,A.nombre_original nombreOriginal,A.mime_type mimeType,A.secure_url secureUrl,A.categoria,A.origen_captura origenCaptura,A.descripcion,A.fecha_carga fechaCarga,A.fecha_captura fechaCaptura
    FROM [archivo].[ArchivoVinculo] AV INNER JOIN [archivo].[Archivo] A ON A.archivo_id=AV.archivo_id
    WHERE AV.caso_fitosanitario_id=@nCaso AND AV.estado=1 AND A.estado=1 ORDER BY A.fecha_carga DESC;
    SET @bResultado=1;
 SET @cMensaje=N'Detalle del caso cargado correctamente.';
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
    @cProcedimiento = N'sanidad.PA_CasoFitosanitario_Sel_DetalleCompleto',
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
    @cProcedimiento = N'sanidad.PA_CasoFitosanitario_Sel_DetalleCompleto',
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
FROM config.FN_RespuestaUsuario(N'sanidad.PA_CasoFitosanitario_Sel_DetalleCompleto',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
