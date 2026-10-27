IF OBJECT_ID(N'[auditoria].[PA_OperacionIdempotente_Ins_Iniciar]', N'P') IS NOT NULL
    DROP PROCEDURE [auditoria].[PA_OperacionIdempotente_Ins_Iniciar];
GO

/******************************************************************************************************
' Nombre del PA           : auditoria.PA_OperacionIdempotente_Ins_Iniciar
' Descripción             : Inicia o reutiliza una operación usando una clave idempotente.
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
        @nOperacionIdempotenteId BIGINT,
        @bEsRepetida BIT,
        @cEstadoOperacion VARCHAR(20),
        @cIdentificadorResultado NVARCHAR(200),
        @cCodigoResultado VARCHAR(40),
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    DECLARE @gClaveIdempotencia UNIQUEIDENTIFIER = NEWID();
    EXEC [auditoria].[PA_OperacionIdempotente_Ins_Iniciar]
        @nUsuarioId = 1,
        @gClaveIdempotencia = @gClaveIdempotencia,
        @cAmbito = 'ARCHIVO_REGISTRAR',
        @nOperacionIdempotenteId = @nOperacionIdempotenteId OUTPUT,
        @bEsRepetida = @bEsRepetida OUTPUT,
        @cEstadoOperacion = @cEstadoOperacion OUTPUT,
        @cIdentificadorResultado = @cIdentificadorResultado OUTPUT,
        @cCodigoResultado = @cCodigoResultado OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nOperacionIdempotenteId, @bEsRepetida, @cEstadoOperacion, @cIdentificadorResultado, @cCodigoResultado, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [auditoria].[PA_OperacionIdempotente_Ins_Iniciar]
(
    @nUsuarioId                 BIGINT,
    @gClaveIdempotencia         UNIQUEIDENTIFIER,
    @cAmbito                    VARCHAR(100),
    @cRequestHashHex            VARCHAR(128) = NULL,
    @nMinutosVigencia           INT = 1440,
    @nOperacionIdempotenteId    BIGINT OUTPUT,
    @bEsRepetida                BIT OUTPUT,
    @cEstadoOperacion           VARCHAR(20) OUTPUT,
    @cIdentificadorResultado    NVARCHAR(200) OUTPUT,
    @cCodigoResultado           VARCHAR(40) OUTPUT,
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

    /* DESCO_SEGURIDAD_V2_20260825 */
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @binRequestHash VARBINARY(64);
    DECLARE @binRequestHashExistente VARBINARY(64);
    DECLARE @dAhora DATETIME2(0) = SYSUTCDATETIME();

    SET @nOperacionIdempotenteId = NULL;
    SET @bEsRepetida = 0;
    SET @cEstadoOperacion = NULL;
    SET @cIdentificadorResultado = NULL;
    SET @cCodigoResultado = NULL;
    SET @bResultado = 0;
    SET @cMensaje = N'No se pudo iniciar la operacion.';

    SET @cAmbito = NULLIF(LTRIM(RTRIM(@cAmbito)), '');

    IF @nUsuarioId IS NULL
       OR @gClaveIdempotencia IS NULL
       OR @cAmbito IS NULL
    BEGIN
        SET @cMensaje = N'La solicitud no es valida.';
        GOTO __DESCO_Salida;
    END;

    IF @cRequestHashHex IS NOT NULL
    BEGIN
        SET @binRequestHash = TRY_CONVERT(VARBINARY(64), @cRequestHashHex, 2);

        IF @binRequestHash IS NULL
        BEGIN
            SET @cMensaje = N'La solicitud no es valida.';
            GOTO __DESCO_Salida;
        END;
    END;

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        SELECT TOP (1)
            @nOperacionIdempotenteId = O.operacion_idempotente_id,
            @cEstadoOperacion = O.estado_operacion,
            @cIdentificadorResultado = O.identificador_resultado,
            @cCodigoResultado = O.codigo_resultado,
            @binRequestHashExistente = O.request_hash
        FROM [auditoria].[OperacionIdempotente] O WITH (UPDLOCK, HOLDLOCK)
        WHERE O.usuario_id = @nUsuarioId
          AND O.ambito = @cAmbito
          AND O.clave_idempotencia = @gClaveIdempotencia
          ;
 /* La clave no se reutiliza aunque el registro esté desactivado. */

        IF @nOperacionIdempotenteId IS NOT NULL
        BEGIN
            /*
               Una clave idempotente identifica una solicitud, no solo una operación.
               Si el backend envía hash en ambos intentos, el contenido debe coincidir.
            */
            IF (@binRequestHash IS NOT NULL AND @binRequestHashExistente IS NULL)
               OR (@binRequestHash IS NULL AND @binRequestHashExistente IS NOT NULL)
               OR @binRequestHash <> @binRequestHashExistente
            BEGIN
                /* Un hash distinto es rechazo, nunca repetición exitosa.
                   No se devuelve el ID ajeno al contenido de esta solicitud. */
                SET @bEsRepetida = 0;
                SET @nOperacionIdempotenteId = NULL;
                SET @cEstadoOperacion = NULL;
                SET @cIdentificadorResultado = NULL;
                SET @cCodigoResultado = NULL;
                SET @bResultado = 0;
                SET @cMensaje = N'La clave de la solicitud ya fue utilizada con un contenido diferente.';
                BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;
                GOTO __DESCO_Salida;
            END;

            SET @bEsRepetida = 1;
            SET @bResultado = CASE WHEN @cEstadoOperacion = 'COMPLETADA' THEN 1 ELSE 0 END;
            SET @cMensaje =
                CASE
                    WHEN @cEstadoOperacion = 'COMPLETADA'
                        THEN N'La operacion ya fue procesada.'
                    WHEN @cEstadoOperacion = 'EN_PROCESO'
                        THEN N'La operacion ya se esta procesando.'
                    ELSE N'La operacion ya fue registrada anteriormente.'
                END;

            BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;
            GOTO __DESCO_Salida;
        END;

        INSERT INTO [auditoria].[OperacionIdempotente]
        (
            usuario_id,
            clave_idempotencia,
            ambito,
            request_hash,
            fecha_inicio,
            estado_operacion,
            fecha_expiracion,
            estado
        )
        VALUES
        (
            @nUsuarioId,
            @gClaveIdempotencia,
            @cAmbito,
            @binRequestHash,
            @dAhora,
            'EN_PROCESO',
            DATEADD(MINUTE, CASE WHEN @nMinutosVigencia < 1 THEN 1440 ELSE @nMinutosVigencia END, @dAhora),
            1
        );

        SET @nOperacionIdempotenteId = SCOPE_IDENTITY();
        SET @cEstadoOperacion = 'EN_PROCESO';
        SET @bResultado = 1;
        SET @cMensaje = N'Operacion iniciada correctamente.';

        BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;
    END TRY
    BEGIN CATCH
SET @bResultado = 0;

        IF XACT_STATE() <> 0 BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;

        SET @bResultado = 0;
        SET @cMensaje = N'No se pudo iniciar la operacion.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'auditoria.PA_OperacionIdempotente_Ins_Iniciar',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;

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
    @cProcedimiento = N'auditoria.PA_OperacionIdempotente_Ins_Iniciar',
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
    @cProcedimiento = N'auditoria.PA_OperacionIdempotente_Ins_Iniciar',
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
FROM config.FN_RespuestaUsuario(N'auditoria.PA_OperacionIdempotente_Ins_Iniciar',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
