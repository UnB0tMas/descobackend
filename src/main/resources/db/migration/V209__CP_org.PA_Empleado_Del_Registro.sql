IF OBJECT_ID(N'[org].[PA_Empleado_Del_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_Empleado_Del_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_Empleado_Del_Registro
' Descripción             : Elimina un registro de empleados.
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
    EXEC [org].[PA_Empleado_Del_Registro]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [org].[PA_Empleado_Del_Registro]
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

    IF @cJson IS NULL OR ISJSON(@cJson)<>1
    BEGIN
        SELECT @bResultado=0,@cMensaje=N'No se pudo procesar la solicitud.';
        GOTO __DESCO_Salida;
    END;

    DECLARE @cNormalizado NVARCHAR(MAX)=@cJson;

    IF JSON_QUERY(@cNormalizado,'$.empleado') IS NULL
        SET @cNormalizado=JSON_MODIFY(@cNormalizado,'$.empleado',JSON_QUERY('{}'));

    IF JSON_QUERY(@cNormalizado,'$.contexto') IS NULL
        SET @cNormalizado=JSON_MODIFY(@cNormalizado,'$.contexto',JSON_QUERY('{}'));

    SET @cNormalizado=JSON_MODIFY(@cNormalizado,'$.empleado.empleadoId',JSON_VALUE(@cJson,'$.empleadoId'));
    SET @cNormalizado=JSON_MODIFY(@cNormalizado,'$.empleado.fechaCese',JSON_VALUE(@cJson,'$.fechaCese'));
    SET @cNormalizado=JSON_MODIFY(@cNormalizado,'$.empleado.motivo',JSON_VALUE(@cJson,'$.motivo'));

    IF JSON_VALUE(@cNormalizado,'$.contexto.sesionPublicaId') IS NULL
        SET @cNormalizado=JSON_MODIFY(@cNormalizado,'$.contexto.sesionPublicaId',JSON_VALUE(@cJson,'$.sesionPublicaId'));
    IF JSON_VALUE(@cNormalizado,'$.contexto.correlacionId') IS NULL
        SET @cNormalizado=JSON_MODIFY(@cNormalizado,'$.contexto.correlacionId',JSON_VALUE(@cJson,'$.correlacionId'));
    IF JSON_VALUE(@cNormalizado,'$.contexto.claveIdempotencia') IS NULL
        SET @cNormalizado=JSON_MODIFY(@cNormalizado,'$.contexto.claveIdempotencia',COALESCE(JSON_VALUE(@cJson,'$.claveIdempotencia'),JSON_VALUE(@cJson,'$.correlacionId')));
    IF JSON_VALUE(@cNormalizado,'$.contexto.ip') IS NULL
        SET @cNormalizado=JSON_MODIFY(@cNormalizado,'$.contexto.ip',JSON_VALUE(@cJson,'$.ip'));

    EXEC [org].[PA_Empleado_Upd_RetirarAdministracion]
         @cJson=@cNormalizado,
         @bResultado=@bResultado OUTPUT,
         @cMensaje=@cMensaje OUTPUT;

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
    @cProcedimiento = N'org.PA_Empleado_Del_Registro',
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
    @cProcedimiento = N'org.PA_Empleado_Del_Registro',
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
FROM config.FN_RespuestaUsuario(N'org.PA_Empleado_Del_Registro',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
