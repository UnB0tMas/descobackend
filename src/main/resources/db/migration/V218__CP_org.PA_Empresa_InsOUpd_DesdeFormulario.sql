IF OBJECT_ID(N'[org].[PA_Empresa_InsOUpd_DesdeFormulario]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_Empresa_InsOUpd_DesdeFormulario];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_Empresa_InsOUpd_DesdeFormulario
' Descripción             : Registra o actualiza una empresa a partir de los datos del formulario.
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
        @nEmpresaId BIGINT,
        @bEmpresaExistia BIT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [org].[PA_Empresa_InsOUpd_DesdeFormulario]
        @cRuc = '',
        @cRazonSocial = N'',
        @cNombreComercial = N'',
        @cTelefono = '',
        @cCorreo = '',
        @cDistritoCodigo = '',
        @nCentroPobladoId = 0,
        @cReferencia = N'',
        @nEmpresaId = @nEmpresaId OUTPUT,
        @bEmpresaExistia = @bEmpresaExistia OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nEmpresaId, @bEmpresaExistia, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [org].[PA_Empresa_InsOUpd_DesdeFormulario]
(
    @cRuc VARCHAR(30),
    @cRazonSocial NVARCHAR(200),
    @cNombreComercial NVARCHAR(160)=NULL,
    @cTelefono VARCHAR(30)=NULL,
    @cCorreo VARCHAR(180)=NULL,
    @cDistritoCodigo CHAR(6),
    @nCentroPobladoId BIGINT=NULL,
    @cReferencia NVARCHAR(300)=NULL,
    @nEmpresaId BIGINT OUTPUT,
    @bEmpresaExistia BIT OUTPUT,
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

    DECLARE @cR VARCHAR(30)=NULLIF(LTRIM(RTRIM(@cRuc)),'');
    DECLARE @cRazon NVARCHAR(200)=NULLIF(LTRIM(RTRIM(@cRazonSocial)),N'');
    DECLARE @cNombre NVARCHAR(160)=NULLIF(LTRIM(RTRIM(@cNombreComercial)),N'');
    DECLARE @cTel VARCHAR(30)=NULLIF(LTRIM(RTRIM(@cTelefono)),'');
    DECLARE @cMail VARCHAR(180)=NULLIF(LTRIM(RTRIM(@cCorreo)),'');
    DECLARE @cDistrito CHAR(6)=NULLIF(LTRIM(RTRIM(@cDistritoCodigo)),'');
    DECLARE @cRef NVARCHAR(300)=NULLIF(LTRIM(RTRIM(@cReferencia)),N'');
    DECLARE @nUbicacionId BIGINT=NULL;
    DECLARE @bUbi BIT,@cMsgUbi NVARCHAR(300);

    SELECT @nEmpresaId=NULL,@bEmpresaExistia=0,@bResultado=0,
           @cMensaje=N'No se pudo completar la empresa.';

    IF @cR IS NULL
       OR LEN(@cR)<>11
       OR @cR LIKE '%[^0-9]%'
    BEGIN
        SET @cMensaje=N'El RUC debe tener 11 dígitos.';
        GOTO __DESCO_Salida;
    END;

    IF @cRazon IS NULL OR @cDistrito IS NULL
    BEGIN
        SET @cMensaje=N'Complete razón social y distrito.';
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

    SELECT @nEmpresaId=empresa_id,@nUbicacionId=ubicacion_id
    FROM [org].[Empresa] WITH (UPDLOCK,HOLDLOCK)
    WHERE ruc=@cR;

    SET @bEmpresaExistia=CASE WHEN @nEmpresaId IS NULL THEN 0 ELSE 1 END;
    IF @cMail IS NOT NULL AND EXISTS
    (
        SELECT 1 FROM [org].[Empresa] WITH (UPDLOCK, HOLDLOCK)
        WHERE correo_clave_desco = LOWER(LTRIM(RTRIM(@cMail))) COLLATE Latin1_General_100_CI_AS
          AND (@nEmpresaId IS NULL OR empresa_id <> @nEmpresaId)
    )
    BEGIN
        SET @cMensaje = N'El correo electrónico ya pertenece a otra organización registrada.';
        GOTO __DESCO_Salida;
    END;

    IF @nEmpresaId IS NULL
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

        INSERT [org].[Empresa]
        (ruc,razon_social,nombre_comercial,telefono,correo,ubicacion_id,fecha_creacion,estado)
        VALUES
        (@cR,@cRazon,@cNombre,@cTel,@cMail,@nUbicacionId,SYSUTCDATETIME(),1);

        SET @nEmpresaId=CONVERT(BIGINT,SCOPE_IDENTITY());
    END
    ELSE
    BEGIN
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

        UPDATE [org].[Empresa]
           SET razon_social=@cRazon,
               nombre_comercial=@cNombre,
               telefono=@cTel,
               correo=@cMail,
               ubicacion_id=@nUbicacionId,
               estado=1
         WHERE empresa_id=@nEmpresaId;
    END;

    SET @bResultado=1;
    SET @cMensaje=CASE WHEN @bEmpresaExistia=1
                       THEN N'Empresa existente completada correctamente.'
                       ELSE N'Empresa registrada correctamente.' END;

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
    @cProcedimiento = N'org.PA_Empresa_InsOUpd_DesdeFormulario',
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
    @cProcedimiento = N'org.PA_Empresa_InsOUpd_DesdeFormulario',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bResultado,0) = 1
BEGIN
SET @bResultado = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
IF ISNULL(@bResultado,0) = 0 SELECT @nEmpresaId=NULL;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'org.PA_Empresa_InsOUpd_DesdeFormulario',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
