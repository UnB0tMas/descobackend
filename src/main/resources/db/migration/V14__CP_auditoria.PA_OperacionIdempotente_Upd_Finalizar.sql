IF OBJECT_ID(N'[auditoria].[PA_OperacionIdempotente_Upd_Finalizar]', N'P') IS NOT NULL
    DROP PROCEDURE [auditoria].[PA_OperacionIdempotente_Upd_Finalizar];
GO

/******************************************************************************************************
' Nombre del PA           : auditoria.PA_OperacionIdempotente_Upd_Finalizar
' Descripción             : Finaliza una operación idempotente y almacena su resultado.
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
    EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
        @nOperacionIdempotenteId = 1,
        @cEstadoOperacion = 'COMPLETADA',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
(
    @nOperacionIdempotenteId    BIGINT,
    @cEstadoOperacion           VARCHAR(20),
    @cEsquemaEntidad            SYSNAME = NULL,
    @cNombreEntidad             SYSNAME = NULL,
    @cIdentificadorResultado    NVARCHAR(200) = NULL,
    @cCodigoResultado           VARCHAR(40) = NULL,
    @bResultado                 BIT OUTPUT,
    @cMensaje                   NVARCHAR(300) OUTPUT,
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
    SET ANSI_NULLS ON;
    SET ANSI_PADDING ON;
    SET ANSI_WARNINGS ON;
    SET ARITHABORT ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET NUMERIC_ROUNDABORT OFF;

    BEGIN TRY

    IF XACT_STATE() = -1
    BEGIN
        SET @bResultado = 0;
        SET @cMensaje = N'La transacción debe revertirse antes de finalizar la solicitud.';
        GOTO __DESCO_Salida;
    END;

    /* DESCO_SEGURIDAD_V2_20260825 */
    SET NOCOUNT ON;

    SET @bResultado = 0;
    SET @cMensaje = N'No se pudo finalizar la operacion.';
    SET @cEstadoOperacion = UPPER(NULLIF(LTRIM(RTRIM(@cEstadoOperacion)), ''));

    IF @nOperacionIdempotenteId IS NULL
       OR @cEstadoOperacion NOT IN ('COMPLETADA','FALLIDA')
    BEGIN
        SET @cMensaje = N'La solicitud no es valida.';
        GOTO __DESCO_Salida;
    END;

    UPDATE [auditoria].[OperacionIdempotente]
    SET
        estado_operacion = @cEstadoOperacion,
        fecha_fin = SYSUTCDATETIME(),
        esquema_entidad = @cEsquemaEntidad,
        nombre_entidad = @cNombreEntidad,
        identificador_resultado = @cIdentificadorResultado,
        codigo_resultado = @cCodigoResultado
    WHERE operacion_idempotente_id = @nOperacionIdempotenteId
      AND estado = 1
      AND estado_operacion = 'EN_PROCESO';

    IF @@ROWCOUNT = 0
    BEGIN
        SET @cMensaje = N'La operacion ya fue finalizada o no esta disponible.';
        GOTO __DESCO_Salida;
    END;

    SET @bResultado = 1;
    SET @cMensaje = N'Operacion finalizada correctamente.';

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
    @cProcedimiento = N'auditoria.PA_OperacionIdempotente_Upd_Finalizar',
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
    @cProcedimiento = N'auditoria.PA_OperacionIdempotente_Upd_Finalizar',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bResultado,0) = 1
BEGIN
SET @bResultado = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'auditoria.PA_OperacionIdempotente_Upd_Finalizar',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
