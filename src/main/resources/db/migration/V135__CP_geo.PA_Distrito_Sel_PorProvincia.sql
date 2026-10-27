IF OBJECT_ID(N'[geo].[PA_Distrito_Sel_PorProvincia]', N'P') IS NOT NULL
    DROP PROCEDURE [geo].[PA_Distrito_Sel_PorProvincia];
GO

/******************************************************************************************************
' Nombre del PA           : geo.PA_Distrito_Sel_PorProvincia
' Descripción             : Lista los distritos de una provincia.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Geografía
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
    EXEC [geo].[PA_Distrito_Sel_PorProvincia]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [geo].[PA_Distrito_Sel_PorProvincia]
(
    @cJson NVARCHAR(MAX),
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

    ------------------------------------------------------------
    -- 1. VARIABLES
    ------------------------------------------------------------
    DECLARE @cProvinciaCodigo CHAR(4);

    ------------------------------------------------------------
    -- 2. VALIDAR JSON
    ------------------------------------------------------------
    IF @cJson IS NULL
       OR ISJSON(@cJson) <> 1
    BEGIN
        THROW 50001, 'El JSON enviado no es válido.', 1;
    END;

    ------------------------------------------------------------
    -- 3. OBTENER PARÁMETROS DEL JSON
    ------------------------------------------------------------
    SELECT
        @cProvinciaCodigo =
            NULLIF(LTRIM(RTRIM(provinciaCodigo)), '')
    FROM OPENJSON(@cJson)
    WITH
    (
        provinciaCodigo CHAR(4) '$.provinciaCodigo'
    );

    ------------------------------------------------------------
    -- 4. VALIDAR PARÁMETRO
    ------------------------------------------------------------
    IF @cProvinciaCodigo IS NULL
    BEGIN
        THROW 50002, 'El código de provincia es obligatorio.', 1;
    END;

    ------------------------------------------------------------
    -- 5. VALIDAR PROVINCIA
    ------------------------------------------------------------
    IF NOT EXISTS
    (
        SELECT 1
        FROM [geo].[Provincia] P
        WHERE P.provincia_codigo = @cProvinciaCodigo
          AND P.estado = 1
    )
    BEGIN
        THROW 50003, 'La provincia no existe o se encuentra inactiva.', 1;
    END;

    ------------------------------------------------------------
    -- 6. LISTAR DISTRITOS
    ------------------------------------------------------------
    SELECT
        D.distrito_codigo AS distritoCodigo,
        D.nombre AS distritoNombre
    FROM [geo].[Distrito] D
    WHERE D.provincia_codigo = @cProvinciaCodigo
      AND D.estado = 1
    ORDER BY
        D.nombre;

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
    @cProcedimiento = N'geo.PA_Distrito_Sel_PorProvincia',
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
    @cProcedimiento = N'geo.PA_Distrito_Sel_PorProvincia',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
SET @bResultado=0; SET @cMensaje=@__DbMensaje;
END CATCH;
SET @bResultado=CASE WHEN @__DbError=0 THEN 1 ELSE 0 END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'geo.PA_Distrito_Sel_PorProvincia',@bResultado,@cMensaje) R;
IF @bResultado=0 AND @@NESTLEVEL>1 THROW 51000,@cMensaje,1;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
