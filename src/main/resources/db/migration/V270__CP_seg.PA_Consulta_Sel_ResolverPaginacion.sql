IF OBJECT_ID(N'[seg].[PA_Consulta_Sel_ResolverPaginacion]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Consulta_Sel_ResolverPaginacion];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Consulta_Sel_ResolverPaginacion
' Descripción             : Resuelve los parámetros de paginación para consultas.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Seguridad
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
        @nPagina INT,
        @nTamanoPagina INT,
        @nOffset BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [seg].[PA_Consulta_Sel_ResolverPaginacion]
        @cJson = N'{}',
        @nPagina = @nPagina OUTPUT,
        @nTamanoPagina = @nTamanoPagina OUTPUT,
        @nOffset = @nOffset OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nPagina, @nTamanoPagina, @nOffset, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_Consulta_Sel_ResolverPaginacion]
(
    @cJson NVARCHAR(MAX),
    @nPagina INT OUTPUT,
    @nTamanoPagina INT OUTPUT,
    @nOffset BIGINT OUTPUT,
    @bResultado BIT=NULL OUTPUT,
    @cMensaje NVARCHAR(300)=NULL OUTPUT,
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

    SET @bResultado=0;
BEGIN TRY

    SET NOCOUNT ON;

    DECLARE
        @nPaginaP INT,
        @nTamanoP INT,
        @nPaginaF INT,
        @nTamanoF INT;

    SELECT
        @nPagina = 1,
        @nTamanoPagina = 20,
        @nOffset = 0;

    IF @cJson IS NOT NULL AND ISJSON(@cJson) = 1
    BEGIN
        SELECT
            @nPaginaP = pagina,
            @nTamanoP = COALESCE(tamanoPagina, tamano)
        FROM OPENJSON(@cJson, '$.paginacion')
        WITH
        (
            pagina INT '$.pagina',
            tamanoPagina INT '$.tamanoPagina',
            tamano INT '$.tamano'
        );

        SELECT
            @nPaginaF = pagina,
            @nTamanoF = COALESCE(tamanoPagina, tamano)
        FROM OPENJSON(@cJson, '$.filtros')
        WITH
        (
            pagina INT '$.pagina',
            tamanoPagina INT '$.tamanoPagina',
            tamano INT '$.tamano'
        );

        SET @nPagina = COALESCE(@nPaginaP, @nPaginaF, 1);
        SET @nTamanoPagina = COALESCE(@nTamanoP, @nTamanoF, 20);
    END;

    IF @nPagina < 1 SET @nPagina = 1;
    IF @nTamanoPagina < 1 SET @nTamanoPagina = 20;
    IF @nTamanoPagina > 200 SET @nTamanoPagina = 200;

    SET @nOffset = (CONVERT(BIGINT, @nPagina) - 1) * CONVERT(BIGINT, @nTamanoPagina);

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
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_Consulta_Sel_ResolverPaginacion',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
SET @bResultado=0; SET @cMensaje=@__DbMensaje;
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
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_Consulta_Sel_ResolverPaginacion',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
SET @bResultado=0; SET @cMensaje=@__DbMensaje;
END CATCH;
SET @bResultado=CASE WHEN @__DbError=0 THEN 1 ELSE 0 END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'seg.PA_Consulta_Sel_ResolverPaginacion',@bResultado,@cMensaje) R;
IF @bResultado=0 AND @@NESTLEVEL>1 THROW 51000,@cMensaje,1;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
