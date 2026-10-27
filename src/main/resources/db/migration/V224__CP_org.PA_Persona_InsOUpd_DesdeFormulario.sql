IF OBJECT_ID(N'[org].[PA_Persona_InsOUpd_DesdeFormulario]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_Persona_InsOUpd_DesdeFormulario];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_Persona_InsOUpd_DesdeFormulario
' Descripción             : Registra o actualiza una persona a partir de los datos del formulario.
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
        @bPersonaExistia BIT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [org].[PA_Persona_InsOUpd_DesdeFormulario]
        @cTipoDocumento = '',
        @cNumeroDocumento = '',
        @cNombres = N'',
        @cApellidoPaterno = N'',
        @cApellidoMaterno = N'',
        @cTelefono = '',
        @cCorreo = '',
        @dFechaNacimiento = '2026-10-11',
        @cDistritoCodigo = '',
        @nCentroPobladoId = 0,
        @cReferencia = N'',
        @nPersonaEsperadaId = 0,
        @nPersonaId = @nPersonaId OUTPUT,
        @bPersonaExistia = @bPersonaExistia OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nPersonaId, @bPersonaExistia, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [org].[PA_Persona_InsOUpd_DesdeFormulario]
(
    @cTipoDocumento VARCHAR(15),
    @cNumeroDocumento VARCHAR(30),
    @cNombres NVARCHAR(100),
    @cApellidoPaterno NVARCHAR(80),
    @cApellidoMaterno NVARCHAR(80)=NULL,
    @cTelefono VARCHAR(30)=NULL,
    @cCorreo VARCHAR(180)=NULL,
    @dFechaNacimiento DATE=NULL,
    @cDistritoCodigo CHAR(6),
    @nCentroPobladoId BIGINT=NULL,
    @cReferencia NVARCHAR(300)=NULL,
    @nPersonaEsperadaId BIGINT=NULL,
    @nPersonaId BIGINT OUTPUT,
    @bPersonaExistia BIT OUTPUT,
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

    DECLARE @cTipo VARCHAR(15)=UPPER(NULLIF(LTRIM(RTRIM(@cTipoDocumento)),''));
    DECLARE @cDoc VARCHAR(30)=NULLIF(LTRIM(RTRIM(@cNumeroDocumento)),'');
    DECLARE @cNom NVARCHAR(100)=NULLIF(LTRIM(RTRIM(@cNombres)),N'');
    DECLARE @cAP NVARCHAR(80)=NULLIF(LTRIM(RTRIM(@cApellidoPaterno)),N'');
    DECLARE @cAM NVARCHAR(80)=NULLIF(LTRIM(RTRIM(@cApellidoMaterno)),N'');
    DECLARE @cTel VARCHAR(30)=NULLIF(LTRIM(RTRIM(@cTelefono)),'');
    DECLARE @cMail VARCHAR(180)=NULLIF(LTRIM(RTRIM(@cCorreo)),'');
    DECLARE @cDistrito CHAR(6)=NULLIF(LTRIM(RTRIM(@cDistritoCodigo)),'');
    DECLARE @cRef NVARCHAR(300)=NULLIF(LTRIM(RTRIM(@cReferencia)),N'');
    DECLARE @nCoincidencias INT,@bBusca BIT,@cMsgBusca NVARCHAR(300);
    DECLARE @nOtroPersonaId BIGINT=NULL;
    DECLARE @nUbicacionId BIGINT=NULL;
    DECLARE @bUbi BIT,@cMsgUbi NVARCHAR(300);

    SELECT @nPersonaId=NULL,@bPersonaExistia=0,@bResultado=0,
           @cMensaje=N'No se pudo completar la persona.';

    IF @cTipo NOT IN('DNI','RUC','CE','PASAPORTE','OTRO')
       OR @cDoc IS NULL OR @cNom IS NULL OR @cAP IS NULL OR @cDistrito IS NULL
    BEGIN
        SET @cMensaje=N'Complete correctamente los datos obligatorios de la persona.';
        GOTO __DESCO_Salida;
    END;

    IF @cTipo IN ('DNI','RUC') AND [org].[FN_Documento_EsValido](@cTipo,@cDoc)=0
    BEGIN
        SET @cMensaje=N'El DNI o RUC no supera la validación de integridad.';
        GOTO __DESCO_Salida;
    END;

    IF @cTipo='RUC' AND [org].[FN_Ruc_Naturaleza](@cDoc)<>'NATURAL'
    BEGIN
        SET @cMensaje=N'El RUC corresponde a una persona jurídica. Regístrelo como empresa, no como empleado/socio.';
        GOTO __DESCO_Salida;
    END;

    IF @dFechaNacimiento IS NOT NULL AND @dFechaNacimiento>CONVERT(DATE,SYSUTCDATETIME())
    BEGIN
        SET @cMensaje=N'Ingrese una fecha de nacimiento válida.';
        GOTO __DESCO_Salida;
    END;

    IF @cMail IS NOT NULL AND @cMail NOT LIKE '%_@_%._%'
    BEGIN
        SET @cMensaje=N'Ingrese un correo válido.';
        GOTO __DESCO_Salida;
    END;

    IF NOT EXISTS(SELECT 1 FROM [geo].[Distrito] WHERE distrito_codigo=@cDistrito AND estado=1)
    BEGIN
        SET @cMensaje=N'El distrito seleccionado no está disponible.';
        GOTO __DESCO_Salida;
    END;

    IF @nCentroPobladoId IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1 FROM [geo].[CentroPoblado]
           WHERE centro_poblado_id=@nCentroPobladoId
             AND distrito_codigo=@cDistrito
             AND estado=1
       )
    BEGIN
        SET @cMensaje=N'El centro poblado no corresponde al distrito seleccionado.';
        GOTO __DESCO_Salida;
    END;

    IF @nPersonaEsperadaId IS NOT NULL
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM [org].[Persona] WHERE persona_id=@nPersonaEsperadaId)
        BEGIN
            SET @cMensaje=N'La persona seleccionada no está disponible.';
            GOTO __DESCO_Salida;
        END;

        EXEC [org].[PA_Persona_Sel_IdPorDocumentoInterno]
             @cTipoDocumento=@cTipo,
             @cNumeroDocumento=@cDoc,
             @nExcluirPersonaId=@nPersonaEsperadaId,
             @nPersonaId=@nOtroPersonaId OUTPUT,
             @nCoincidencias=@nCoincidencias OUTPUT,
             @bResultado=@bBusca OUTPUT,
             @cMensaje=@cMsgBusca OUTPUT;

        IF @bBusca=0 OR @nCoincidencias>0
        BEGIN
            SET @cMensaje=CASE WHEN @bBusca=0 THEN @cMsgBusca
                               ELSE N'El documento pertenece a otra persona registrada.' END;
            GOTO __DESCO_Salida;
        END;

        SET @nPersonaId=@nPersonaEsperadaId;
        SET @bPersonaExistia=1;
    END
    ELSE
    BEGIN
        EXEC [org].[PA_Persona_Sel_IdPorDocumentoInterno]
             @cTipoDocumento=@cTipo,
             @cNumeroDocumento=@cDoc,
             @nExcluirPersonaId=NULL,
             @nPersonaId=@nPersonaId OUTPUT,
             @nCoincidencias=@nCoincidencias OUTPUT,
             @bResultado=@bBusca OUTPUT,
             @cMensaje=@cMsgBusca OUTPUT;

        IF @bBusca=0
        BEGIN
            SET @cMensaje=@cMsgBusca;
            GOTO __DESCO_Salida;
        END;

        SET @bPersonaExistia=CASE WHEN @nPersonaId IS NULL THEN 0 ELSE 1 END;
    END;

    -- Un correo puede repetirse para la misma persona, no para otra identidad.
    IF @cMail IS NOT NULL AND EXISTS
    (
        SELECT 1 FROM [org].[Persona] WITH (UPDLOCK, HOLDLOCK)
        WHERE correo_clave_desco = LOWER(LTRIM(RTRIM(@cMail))) COLLATE Latin1_General_100_CI_AS
          AND (@nPersonaId IS NULL OR persona_id <> @nPersonaId)
    )
    BEGIN
        SET @cMensaje = N'El correo electrónico ya pertenece a otra persona registrada.';
        GOTO __DESCO_Salida;
    END;

    IF @nPersonaId IS NOT NULL
    BEGIN
        IF EXISTS
        (
            SELECT 1 FROM [org].[Persona]
            WHERE persona_id=@nPersonaId AND tipo_persona<>'NATURAL'
        )
        BEGIN
            SET @cMensaje=N'La identidad encontrada no es una persona natural.';
            GOTO __DESCO_Salida;
        END;

        SELECT @nUbicacionId=ubicacion_id
        FROM [org].[Persona]
        WHERE persona_id=@nPersonaId;

        IF @nUbicacionId IS NULL
        BEGIN
            EXEC [geo].[PA_Ubicacion_Ins_Interna]
                 @cDistritoCodigo=@cDistrito,
                 @nCentroPobladoId=@nCentroPobladoId,
                 @cReferencia=@cRef,
                 @nLatitud=NULL,@nLongitud=NULL,@nAltitudM=NULL,
                 @nUbicacionId=@nUbicacionId OUTPUT,
                 @bResultado=@bUbi OUTPUT,
                 @cMensaje=@cMsgUbi OUTPUT;
        END
        ELSE
        BEGIN
            EXEC [geo].[PA_Ubicacion_Upd_Interna]
                 @nUbicacionId=@nUbicacionId,
                 @cDistritoCodigo=@cDistrito,
                 @nCentroPobladoId=@nCentroPobladoId,
                 @cReferencia=@cRef,
                 @bResultado=@bUbi OUTPUT,
                 @cMensaje=@cMsgUbi OUTPUT;
        END;

        IF @bUbi=0
        BEGIN
            SET @cMensaje=@cMsgUbi;
            GOTO __DESCO_Salida;
        END;

        UPDATE [org].[Persona]
           SET tipo_documento=CASE WHEN @nPersonaEsperadaId IS NULL THEN tipo_documento ELSE @cTipo END,
               numero_documento=CASE WHEN @nPersonaEsperadaId IS NULL THEN numero_documento ELSE @cDoc END,
               tipo_persona='NATURAL',
               nombres=@cNom,
               apellido_paterno=@cAP,
               apellido_materno=@cAM,
               telefono=@cTel,
               correo=@cMail,
               fecha_nacimiento=@dFechaNacimiento,
               ubicacion_id=@nUbicacionId,
               estado=1
         WHERE persona_id=@nPersonaId;
    END
    ELSE
    BEGIN
        EXEC [geo].[PA_Ubicacion_Ins_Interna]
             @cDistritoCodigo=@cDistrito,
             @nCentroPobladoId=@nCentroPobladoId,
             @cReferencia=@cRef,
             @nLatitud=NULL,@nLongitud=NULL,@nAltitudM=NULL,
             @nUbicacionId=@nUbicacionId OUTPUT,
             @bResultado=@bUbi OUTPUT,
             @cMensaje=@cMsgUbi OUTPUT;

        IF @bUbi=0
        BEGIN
            SET @cMensaje=@cMsgUbi;
            GOTO __DESCO_Salida;
        END;

        INSERT [org].[Persona]
        (
            tipo_persona,tipo_documento,numero_documento,nombres,
            apellido_paterno,apellido_materno,telefono,correo,
            fecha_nacimiento,ubicacion_id,estado,fecha_creacion
        )
        VALUES
        (
            'NATURAL',@cTipo,@cDoc,@cNom,@cAP,@cAM,@cTel,@cMail,
            @dFechaNacimiento,@nUbicacionId,1,SYSUTCDATETIME()
        );

        SET @nPersonaId=CONVERT(BIGINT,SCOPE_IDENTITY());
        SET @bPersonaExistia=0;
    END;

    SET @bResultado=1;
    SET @cMensaje=CASE WHEN @bPersonaExistia=1
                       THEN N'Persona existente completada correctamente.'
                       ELSE N'Persona registrada correctamente.' END;

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
    @cProcedimiento = N'org.PA_Persona_InsOUpd_DesdeFormulario',
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
    @cProcedimiento = N'org.PA_Persona_InsOUpd_DesdeFormulario',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bResultado,0) = 1
BEGIN
SET @bResultado = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
IF ISNULL(@bResultado,0) = 0 SELECT @nPersonaId=NULL;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'org.PA_Persona_InsOUpd_DesdeFormulario',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
