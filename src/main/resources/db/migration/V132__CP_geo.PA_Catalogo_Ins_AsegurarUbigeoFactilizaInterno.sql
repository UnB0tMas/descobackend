IF OBJECT_ID(N'[geo].[PA_Catalogo_Ins_AsegurarUbigeoFactilizaInterno]', N'P') IS NOT NULL
    DROP PROCEDURE [geo].[PA_Catalogo_Ins_AsegurarUbigeoFactilizaInterno];
GO

/******************************************************************************************************
' Nombre del PA           : geo.PA_Catalogo_Ins_AsegurarUbigeoFactilizaInterno
' Descripción             : Asegura el catálogo geográfico interno requerido por la integración Factiliza.
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
    DECLARE
        @nCentroPobladoId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [geo].[PA_Catalogo_Ins_AsegurarUbigeoFactilizaInterno]
        @cDepartamentoCodigo = '',
        @cDepartamentoNombre = N'',
        @cProvinciaCodigo = '',
        @cProvinciaNombre = N'',
        @cDistritoCodigo = '',
        @cDistritoNombre = N'',
        @cCentroPobladoNombre = N'',
        @cCentroPobladoCodigo = '',
        @nCentroPobladoId = @nCentroPobladoId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nCentroPobladoId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [geo].[PA_Catalogo_Ins_AsegurarUbigeoFactilizaInterno]
(
    @cDepartamentoCodigo CHAR(2),
    @cDepartamentoNombre NVARCHAR(100),
    @cProvinciaCodigo CHAR(4),
    @cProvinciaNombre NVARCHAR(100),
    @cDistritoCodigo CHAR(6),
    @cDistritoNombre NVARCHAR(100),
    @cCentroPobladoNombre NVARCHAR(150) = NULL,
    @cCentroPobladoCodigo VARCHAR(20) = NULL,
    @nCentroPobladoId BIGINT OUTPUT,
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
    SET ANSI_NULLS ON;
    SET ANSI_PADDING ON;
    SET ANSI_WARNINGS ON;
    SET ARITHABORT ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET NUMERIC_ROUNDABORT OFF;

    BEGIN TRY
BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

    SET NOCOUNT ON;

    DECLARE
        @cDepCodigo CHAR(2),
        @cProvCodigo CHAR(4),
        @cDistCodigo CHAR(6),
        @cDepNombre NVARCHAR(100),
        @cProvNombre NVARCHAR(100),
        @cDistNombre NVARCHAR(100),
        @cCpNombre NVARCHAR(150),
        @cCpCodigo VARCHAR(20);

    SELECT
        @bResultado = 0,
        @cMensaje = N'No fue posible normalizar la ubicación.',
        @nCentroPobladoId = NULL;

    SELECT
        @cDepCodigo = NULLIF(LTRIM(RTRIM(@cDepartamentoCodigo)), ''),
        @cProvCodigo = NULLIF(LTRIM(RTRIM(@cProvinciaCodigo)), ''),
        @cDistCodigo = NULLIF(LTRIM(RTRIM(@cDistritoCodigo)), ''),
        @cDepNombre = UPPER(NULLIF(LTRIM(RTRIM(@cDepartamentoNombre)), N'')),
        @cProvNombre = UPPER(NULLIF(LTRIM(RTRIM(@cProvinciaNombre)), N'')),
        @cDistNombre = UPPER(NULLIF(LTRIM(RTRIM(@cDistritoNombre)), N'')),
        @cCpNombre = UPPER(NULLIF(LTRIM(RTRIM(@cCentroPobladoNombre)), N'')),
        @cCpCodigo = UPPER(NULLIF(LTRIM(RTRIM(@cCentroPobladoCodigo)), ''));

    /*
     * Factiliza documenta un arreglo ubigeo jerárquico:
     * [departamento(2), provincia(4), distrito(6)].
     *
     * Para DESCO se usa esa jerarquía / ubigeo SUNAT porque coincide con
     * las PK CHAR(2), CHAR(4), CHAR(6) del catálogo geo.
     */
    IF @cDepCodigo IS NULL
       OR LEN(@cDepCodigo) <> 2
       OR @cDepCodigo LIKE '%[^0-9]%'
       OR @cProvCodigo IS NULL
       OR LEN(@cProvCodigo) <> 4
       OR @cProvCodigo LIKE '%[^0-9]%'
       OR @cDistCodigo IS NULL
       OR LEN(@cDistCodigo) <> 6
       OR @cDistCodigo LIKE '%[^0-9]%'
       OR LEFT(@cProvCodigo, 2) <> @cDepCodigo
       OR LEFT(@cDistCodigo, 4) <> @cProvCodigo
       OR @cDepNombre IS NULL
       OR @cProvNombre IS NULL
       OR @cDistNombre IS NULL
    BEGIN
        GOTO __DESCO_Salida;
    END;

    /*
     * No se permite que un mismo código termine asociado a otro nombre
     * materialmente diferente ni que el mismo nombre, ignorando mayúsculas,
     * minúsculas y tildes, termine con dos códigos distintos.
     */
    IF EXISTS
    (
        SELECT 1
        FROM [geo].[Departamento] WITH (UPDLOCK, HOLDLOCK)
        WHERE departamento_codigo = @cDepCodigo
          AND nombre COLLATE Latin1_General_100_CI_AI
              <> @cDepNombre COLLATE Latin1_General_100_CI_AI
    )
    OR EXISTS
    (
        SELECT 1
        FROM [geo].[Departamento] WITH (UPDLOCK, HOLDLOCK)
        WHERE nombre COLLATE Latin1_General_100_CI_AI
              = @cDepNombre COLLATE Latin1_General_100_CI_AI
          AND departamento_codigo <> @cDepCodigo
    )
    BEGIN
        GOTO __DESCO_Salida;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM [geo].[Provincia] WITH (UPDLOCK, HOLDLOCK)
        WHERE provincia_codigo = @cProvCodigo
          AND
          (
              departamento_codigo <> @cDepCodigo
              OR nombre COLLATE Latin1_General_100_CI_AI
                 <> @cProvNombre COLLATE Latin1_General_100_CI_AI
          )
    )
    OR EXISTS
    (
        SELECT 1
        FROM [geo].[Provincia] WITH (UPDLOCK, HOLDLOCK)
        WHERE departamento_codigo = @cDepCodigo
          AND nombre COLLATE Latin1_General_100_CI_AI
              = @cProvNombre COLLATE Latin1_General_100_CI_AI
          AND provincia_codigo <> @cProvCodigo
    )
    BEGIN
        GOTO __DESCO_Salida;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM [geo].[Distrito] WITH (UPDLOCK, HOLDLOCK)
        WHERE distrito_codigo = @cDistCodigo
          AND
          (
              provincia_codigo <> @cProvCodigo
              OR nombre COLLATE Latin1_General_100_CI_AI
                 <> @cDistNombre COLLATE Latin1_General_100_CI_AI
          )
    )
    OR EXISTS
    (
        SELECT 1
        FROM [geo].[Distrito] WITH (UPDLOCK, HOLDLOCK)
        WHERE provincia_codigo = @cProvCodigo
          AND nombre COLLATE Latin1_General_100_CI_AI
              = @cDistNombre COLLATE Latin1_General_100_CI_AI
          AND distrito_codigo <> @cDistCodigo
    )
    BEGIN
        GOTO __DESCO_Salida;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [geo].[Departamento] WITH (UPDLOCK, HOLDLOCK)
        WHERE departamento_codigo = @cDepCodigo
    )
    BEGIN
        INSERT INTO [geo].[Departamento]
        (
            departamento_codigo,
            nombre,
            estado
        )
        VALUES
        (
            @cDepCodigo,
            @cDepNombre,
            1
        );
    END
    ELSE
    BEGIN
        UPDATE [geo].[Departamento]
           SET nombre = @cDepNombre,
               estado = 1
         WHERE departamento_codigo = @cDepCodigo;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [geo].[Provincia] WITH (UPDLOCK, HOLDLOCK)
        WHERE provincia_codigo = @cProvCodigo
    )
    BEGIN
        INSERT INTO [geo].[Provincia]
        (
            provincia_codigo,
            departamento_codigo,
            nombre,
            estado
        )
        VALUES
        (
            @cProvCodigo,
            @cDepCodigo,
            @cProvNombre,
            1
        );
    END
    ELSE
    BEGIN
        UPDATE [geo].[Provincia]
           SET departamento_codigo = @cDepCodigo,
               nombre = @cProvNombre,
               estado = 1
         WHERE provincia_codigo = @cProvCodigo;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [geo].[Distrito] WITH (UPDLOCK, HOLDLOCK)
        WHERE distrito_codigo = @cDistCodigo
    )
    BEGIN
        INSERT INTO [geo].[Distrito]
        (
            distrito_codigo,
            provincia_codigo,
            nombre,
            estado
        )
        VALUES
        (
            @cDistCodigo,
            @cProvCodigo,
            @cDistNombre,
            1
        );
    END
    ELSE
    BEGIN
        UPDATE [geo].[Distrito]
           SET provincia_codigo = @cProvCodigo,
               nombre = @cDistNombre,
               estado = 1
         WHERE distrito_codigo = @cDistCodigo;
    END;

    /*
     * La documentación pública actual de DNI/RUC de Factiliza no muestra
     * un campo centro_poblado. Por eso solo se crea cuando el adapter recibe
     * un valor explícito; nunca se deduce desde "direccion".
     */
    IF @cCpNombre IS NOT NULL
    BEGIN
        SELECT TOP (1)
            @nCentroPobladoId = centro_poblado_id
        FROM [geo].[CentroPoblado] WITH (UPDLOCK, HOLDLOCK)
        WHERE distrito_codigo = @cDistCodigo
          AND nombre COLLATE Latin1_General_100_CI_AI
              = @cCpNombre COLLATE Latin1_General_100_CI_AI
        ORDER BY centro_poblado_id;

        IF @nCentroPobladoId IS NULL
        BEGIN
            INSERT INTO [geo].[CentroPoblado]
            (
                distrito_codigo,
                nombre,
                codigo_inei,
                estado
            )
            VALUES
            (
                @cDistCodigo,
                @cCpNombre,
                @cCpCodigo,
                1
            );

            SET @nCentroPobladoId =
                    CONVERT(BIGINT, SCOPE_IDENTITY());
        END
        ELSE
        BEGIN
            UPDATE [geo].[CentroPoblado]
               SET nombre = @cCpNombre,
                   codigo_inei = COALESCE(@cCpCodigo, codigo_inei),
                   estado = 1
             WHERE centro_poblado_id = @nCentroPobladoId;
        END;
    END;

    SET @bResultado = 1;
    SET @cMensaje = N'Ubicación normalizada correctamente.';

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
    @cProcedimiento = N'geo.PA_Catalogo_Ins_AsegurarUbigeoFactilizaInterno',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
    END CATCH;

__DESCO_Salida:
BEGIN TRY

IF @__DbTranAbierta = 1
BEGIN
    IF @__DbError = 0 AND @bResultado = 1 AND XACT_STATE() = 1
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;
    ELSE
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
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'geo.PA_Catalogo_Ins_AsegurarUbigeoFactilizaInterno',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bResultado,0) = 1
BEGIN
SET @bResultado = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
IF ISNULL(@bResultado,0) = 0 SELECT @nCentroPobladoId=NULL;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'geo.PA_Catalogo_Ins_AsegurarUbigeoFactilizaInterno',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
