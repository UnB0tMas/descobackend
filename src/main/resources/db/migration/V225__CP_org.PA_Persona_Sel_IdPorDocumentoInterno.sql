IF OBJECT_ID(N'[org].[PA_Persona_Sel_IdPorDocumentoInterno]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_Persona_Sel_IdPorDocumentoInterno];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_Persona_Sel_IdPorDocumentoInterno
' Descripción             : Consulta el identificador interno de una persona según su documento.
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
    DECLARE
        @nPersonaId BIGINT,
        @nCoincidencias INT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [org].[PA_Persona_Sel_IdPorDocumentoInterno]
        @cTipoDocumento = '',
        @cNumeroDocumento = '',
        @nExcluirPersonaId = 0,
        @nPersonaId = @nPersonaId OUTPUT,
        @nCoincidencias = @nCoincidencias OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nPersonaId, @nCoincidencias, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [org].[PA_Persona_Sel_IdPorDocumentoInterno]
(
    @cTipoDocumento VARCHAR(15),
    @cNumeroDocumento VARCHAR(30),
    @nExcluirPersonaId BIGINT = NULL,
    @nPersonaId BIGINT OUTPUT,
    @nCoincidencias INT OUTPUT,
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

    SET NOCOUNT ON;

    DECLARE @cTipo VARCHAR(15)=UPPER(NULLIF(LTRIM(RTRIM(@cTipoDocumento)),''));
    DECLARE @cDoc VARCHAR(30)=NULLIF(LTRIM(RTRIM(@cNumeroDocumento)),'');
    DECLARE @cDniEquivalente VARCHAR(8)=NULL;
    DECLARE @cRucEquivalente VARCHAR(11)=NULL;

    SELECT @nPersonaId=NULL,@nCoincidencias=0,@bResultado=0,
           @cMensaje=N'No se pudo resolver la identidad personal.';

    IF [org].[FN_Documento_EsValido](@cTipo,@cDoc)=0
       AND @cTipo IN ('DNI','RUC')
    BEGIN
        SET @cMensaje=N'El DNI o RUC no supera la validación de integridad.';
        GOTO __DESCO_Salida;
    END;

    IF @cTipo='DNI'
        SET @cRucEquivalente=[org].[FN_Ruc_DesdeDni](@cDoc);
    ELSE IF @cTipo='RUC' AND LEFT(@cDoc,2)='10'
        SET @cDniEquivalente=SUBSTRING(@cDoc,3,8);

    DECLARE @T TABLE(persona_id BIGINT PRIMARY KEY);

    INSERT @T(persona_id)
    SELECT P.persona_id
    FROM [org].[Persona] P WITH (UPDLOCK,HOLDLOCK)
    WHERE (@nExcluirPersonaId IS NULL OR P.persona_id<>@nExcluirPersonaId)
      AND
      (
          (P.tipo_documento=@cTipo AND P.numero_documento=@cDoc)
          OR
          (@cTipo='DNI' AND @cRucEquivalente IS NOT NULL
             AND P.tipo_documento='RUC' AND P.numero_documento=@cRucEquivalente)
          OR
          (@cTipo='RUC' AND @cDniEquivalente IS NOT NULL
             AND P.tipo_documento='DNI' AND P.numero_documento=@cDniEquivalente)
      );

    SELECT @nCoincidencias=COUNT(*),@nPersonaId=MIN(persona_id) FROM @T;

    IF @nCoincidencias>1
    BEGIN
        SET @nPersonaId=NULL;
        SET @cMensaje=N'Existen identidades duplicadas equivalentes (DNI/RUC10). Deben depurarse antes de continuar.';
        GOTO __DESCO_Salida;
    END;

    SET @bResultado=1;
    SET @cMensaje=N'Identidad resuelta correctamente.';

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
    @cProcedimiento = N'org.PA_Persona_Sel_IdPorDocumentoInterno',
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
    @cProcedimiento = N'org.PA_Persona_Sel_IdPorDocumentoInterno',
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
FROM config.FN_RespuestaUsuario(N'org.PA_Persona_Sel_IdPorDocumentoInterno',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
