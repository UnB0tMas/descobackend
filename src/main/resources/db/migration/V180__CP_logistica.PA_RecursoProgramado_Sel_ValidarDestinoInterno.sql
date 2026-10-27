IF OBJECT_ID(N'[logistica].[PA_RecursoProgramado_Sel_ValidarDestinoInterno]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_RecursoProgramado_Sel_ValidarDestinoInterno];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_RecursoProgramado_Sel_ValidarDestinoInterno
' Descripción             : Valida internamente el destino de un recurso programado.
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
    DECLARE
        @bValido BIT,
        @cMensaje NVARCHAR(300),
        @bResultado BIT,
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [logistica].[PA_RecursoProgramado_Sel_ValidarDestinoInterno]
        @nCampaniaVentaId = 0,
        @nOperativoVentaId = 0,
        @nSalidaCampoId = 0,
        @cMomento = '',
        @bValido = @bValido OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bValido, @cMensaje, @bResultado, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [logistica].[PA_RecursoProgramado_Sel_ValidarDestinoInterno]
(
    @nCampaniaVentaId BIGINT = NULL,
    @nOperativoVentaId BIGINT = NULL,
    @nSalidaCampoId BIGINT = NULL,
    @cMomento VARCHAR(20),
    @bValido BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @bResultado BIT=NULL OUTPUT,
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
    SET @bValido = 0;

    SET @bResultado=0;
BEGIN TRY

    SET NOCOUNT ON;

    DECLARE @nDestinos TINYINT =
        (CASE WHEN @nCampaniaVentaId IS NULL THEN 0 ELSE 1 END) +
        (CASE WHEN @nOperativoVentaId IS NULL THEN 0 ELSE 1 END) +
        (CASE WHEN @nSalidaCampoId IS NULL THEN 0 ELSE 1 END);

    SET @bValido=0;
    SET @cMensaje=N'La actividad seleccionada no está disponible para esta operación.';
    SET @cMomento=UPPER(NULLIF(LTRIM(RTRIM(@cMomento)),''));

    IF @nDestinos<>1 OR @cMomento IS NULL OR @cMomento NOT IN('PROGRAMAR','EDITAR','ASIGNAR')
    BEGIN
        SET @cMensaje=N'Seleccione una actividad válida para el recurso.';
        GOTO __DESCO_Salida;
    END;

    IF @nCampaniaVentaId IS NOT NULL
    BEGIN
        IF @cMomento IN('PROGRAMAR','EDITAR')
           AND EXISTS
           (
               SELECT 1 FROM [comercial].[CampaniaVenta]
               WHERE campania_venta_id=@nCampaniaVentaId
                 AND estado=1
                 AND estado_proceso IN('PLANIFICACION','ACTIVA')
           )
        BEGIN
            SET @bValido=1;
            SET @cMensaje=N'Campaña disponible para programación de recursos.';
            GOTO __DESCO_Salida;
        END;

        IF @cMomento='ASIGNAR'
           AND EXISTS
           (
               SELECT 1 FROM [comercial].[CampaniaVenta]
               WHERE campania_venta_id=@nCampaniaVentaId
                 AND estado=1
                 AND estado_proceso='ACTIVA'
           )
        BEGIN
            SET @bValido=1;
            SET @cMensaje=N'Campaña disponible para asignación de recursos.';
            GOTO __DESCO_Salida;
        END;

        SET @cMensaje=N'La campaña ya no permite programar o asignar recursos.';
        GOTO __DESCO_Salida;
    END;

    IF @nOperativoVentaId IS NOT NULL
    BEGIN
        IF @cMomento IN('PROGRAMAR','EDITAR')
           AND EXISTS
           (
               SELECT 1
               FROM [comercial].[OperativoVenta] O
               INNER JOIN [comercial].[CampaniaVenta] C
                   ON C.campania_venta_id=O.campania_venta_id
                  AND C.estado=1
                  AND C.estado_proceso IN('PLANIFICACION','ACTIVA')
               WHERE O.operativo_venta_id=@nOperativoVentaId
                 AND O.estado=1
                 AND O.estado_proceso IN('PLANIFICADO','EN_RECEPCION')
           )
        BEGIN
            SET @bValido=1;
            SET @cMensaje=N'Operativo disponible para programación de recursos.';
            GOTO __DESCO_Salida;
        END;

        IF @cMomento='ASIGNAR'
           AND EXISTS
           (
               SELECT 1
               FROM [comercial].[OperativoVenta] O
               INNER JOIN [comercial].[CampaniaVenta] C
                   ON C.campania_venta_id=O.campania_venta_id
                  AND C.estado=1
                  AND C.estado_proceso='ACTIVA'
               WHERE O.operativo_venta_id=@nOperativoVentaId
                 AND O.estado=1
                 AND O.estado_proceso IN('PLANIFICADO','EN_RECEPCION')
           )
        BEGIN
            SET @bValido=1;
            SET @cMensaje=N'Operativo disponible para asignación de recursos.';
            GOTO __DESCO_Salida;
        END;

        SET @cMensaje=N'El operativo ya no permite programar o asignar recursos.';
        GOTO __DESCO_Salida;
    END;

    IF @nSalidaCampoId IS NOT NULL
    BEGIN
        IF @cMomento IN('PROGRAMAR','EDITAR')
           AND EXISTS
           (
               SELECT 1 FROM [campo].[SalidaCampo]
               WHERE salida_campo_id=@nSalidaCampoId
                 AND estado=1
                 AND estado_proceso IN('BORRADOR','PROGRAMADA')
           )
        BEGIN
            SET @bValido=1;
            SET @cMensaje=N'Salida disponible para programación de recursos.';
            GOTO __DESCO_Salida;
        END;

        IF @cMomento='ASIGNAR'
           AND EXISTS
           (
               SELECT 1 FROM [campo].[SalidaCampo]
               WHERE salida_campo_id=@nSalidaCampoId
                 AND estado=1
                 AND estado_proceso IN('PROGRAMADA','EN_CURSO')
           )
        BEGIN
            SET @bValido=1;
            SET @cMensaje=N'Salida disponible para asignación de recursos.';
            GOTO __DESCO_Salida;
        END;

        SET @cMensaje=N'La salida ya no permite programar o asignar recursos.';
        GOTO __DESCO_Salida;
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
SET @bValido = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'logistica.PA_RecursoProgramado_Sel_ValidarDestinoInterno',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = NULL,
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
IF ISNULL(@bValido,0) = 1 OR NULLIF(@cMensaje,N'') IS NULL SET @cMensaje = N'La operación no se completó y sus cambios fueron revertidos.';
SET @bValido = 0;
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
SET @bValido = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'logistica.PA_RecursoProgramado_Sel_ValidarDestinoInterno',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bValido,0) = 1
BEGIN
SET @bValido = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
SET @bResultado=CASE WHEN @__DbError=0 THEN ISNULL(@bValido,0) ELSE 0 END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'logistica.PA_RecursoProgramado_Sel_ValidarDestinoInterno',@bResultado,@cMensaje) R;
IF @__DbError=1 AND @@NESTLEVEL>1 THROW 51000,@cMensaje,1;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
