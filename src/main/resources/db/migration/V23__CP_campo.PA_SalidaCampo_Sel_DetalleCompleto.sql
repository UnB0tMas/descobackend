IF OBJECT_ID(N'[campo].[PA_SalidaCampo_Sel_DetalleCompleto]', N'P') IS NOT NULL
    DROP PROCEDURE [campo].[PA_SalidaCampo_Sel_DetalleCompleto];
GO

/******************************************************************************************************
' Nombre del PA           : campo.PA_SalidaCampo_Sel_DetalleCompleto
' Descripción             : Consulta el detalle completo de una salida de campo.
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
    EXEC [campo].[PA_SalidaCampo_Sel_DetalleCompleto]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [campo].[PA_SalidaCampo_Sel_DetalleCompleto]
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
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bOk BIT,@cMsg NVARCHAR(300),@nSalida BIGINT;
    SET @bResultado=0;
 SET @cMensaje=N'No se pudo cargar el detalle de la salida.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado] @cJson,'SALIDAS_VER',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bOk OUTPUT,@cMsg OUTPUT;
    IF @bOk=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    SELECT @nSalida=salidaCampoId FROM OPENJSON(@cJson,'$.filtros') WITH (salidaCampoId BIGINT '$.salidaCampoId');
    IF @nSalida IS NULL OR NOT EXISTS(SELECT 1 FROM [campo].[SalidaCampo] WHERE salida_campo_id=@nSalida) BEGIN SET @cMensaje=N'La salida seleccionada no está disponible.';
 GOTO __DESCO_Salida;
 END;
    /* 1. Cabecera */
    SELECT S.salida_campo_id,S.motivo_salida_id,M.codigo motivoCodigo,M.nombre motivo,S.fecha_hora_programada,S.fecha_hora_salida_real,S.fecha_hora_retorno_real,S.descripcion,S.estado_proceso,S.estado FROM [campo].[SalidaCampo] S INNER JOIN [campo].[MotivoSalida] M ON M.motivo_salida_id=S.motivo_salida_id WHERE S.salida_campo_id=@nSalida;
    /* 2. Participantes */
    SELECT SP.salida_participante_id,SP.empleado_id,E.codigo_empleado,P.nombres,P.apellido_paterno,P.apellido_materno,SP.funcion,SP.es_responsable,SP.estado FROM [campo].[SalidaParticipante] SP INNER JOIN [org].[Empleado] E ON E.empleado_id=SP.empleado_id INNER JOIN [org].[Persona] P ON P.persona_id=SP.empleado_id WHERE SP.salida_campo_id=@nSalida ORDER BY SP.es_responsable DESC,P.apellido_paterno;
    /* 3. Recursos programados */
    SELECT RP.recurso_programado_id,RP.bien_inventario_id,BI.codigo_patrimonial,BI.nombre bienNombre,RP.suministro_id,SU.codigo suministroCodigo,SU.nombre suministroNombre,SU.unidad_medida,RP.cantidad_programada,RP.observacion,RP.estado,
           ISNULL((SELECT SUM(CASE WHEN RM.tipo_movimiento IN('ASIGNACION','ENTREGA','CONSUMO') THEN RM.cantidad WHEN RM.tipo_movimiento='DEVOLUCION' THEN -RM.cantidad ELSE 0 END) FROM [logistica].[RecursoMovimiento] RM WHERE RM.recurso_programado_id=RP.recurso_programado_id AND RM.estado=1),0) cantidadEjecutada
    FROM [logistica].[RecursoProgramado] RP LEFT JOIN [logistica].[BienInventario] BI ON BI.bien_inventario_id=RP.bien_inventario_id LEFT JOIN [logistica].[Suministro] SU ON SU.suministro_id=RP.suministro_id WHERE RP.salida_campo_id=@nSalida ORDER BY RP.recurso_programado_id;
    /* 4. Bienes entregados/devoluciones */
    SELECT SB.salida_bien_id,SB.bien_inventario_id,BI.codigo_patrimonial,BI.nombre,SB.fecha_hora_entrega,SB.fecha_hora_devolucion,SB.estado_entrega,SB.estado_devolucion,SB.observacion,SB.estado FROM [logistica].[SalidaBien] SB INNER JOIN [logistica].[BienInventario] BI ON BI.bien_inventario_id=SB.bien_inventario_id WHERE SB.salida_campo_id=@nSalida ORDER BY SB.fecha_hora_entrega;
    /* 5. Visitas relacionadas */
    SELECT V.visita_tecnica_id,V.salida_participante_id,V.predio_id,PR.codigo predioCodigo,PR.nombre predioNombre,V.fecha_hora_inicio,V.fecha_hora_fin,V.estado_proceso,V.estado FROM [campo].[VisitaTecnica] V INNER JOIN [prod].[Predio] PR ON PR.predio_id=V.predio_id INNER JOIN [campo].[SalidaParticipante] SP ON SP.salida_participante_id=V.salida_participante_id WHERE SP.salida_campo_id=@nSalida ORDER BY V.fecha_hora_inicio;
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
    @cProcedimiento = N'campo.PA_SalidaCampo_Sel_DetalleCompleto',
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
    @cProcedimiento = N'campo.PA_SalidaCampo_Sel_DetalleCompleto',
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
FROM config.FN_RespuestaUsuario(N'campo.PA_SalidaCampo_Sel_DetalleCompleto',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
