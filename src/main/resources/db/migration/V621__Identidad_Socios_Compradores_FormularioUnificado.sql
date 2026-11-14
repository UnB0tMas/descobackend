-- V621: flujo de identificación, socios y compradores.
-- Sólo nuevos CREATE OR ALTER; no se modifican migraciones ejecutadas.
-- La consulta de Factiliza sigue bajo el módulo de identidades vigente.

CREATE OR ALTER PROCEDURE [org].[PA_Persona_InsOUpd_DesdeFormulario]
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
       OR @cDoc IS NULL OR @cNom IS NULL OR @cAP IS NULL
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

    IF @cDistrito IS NOT NULL AND NOT EXISTS(SELECT 1 FROM [geo].[Distrito] WHERE distrito_codigo=@cDistrito AND estado=1)
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

    IF @nPersonaId IS NULL AND @cDistrito IS NULL
    BEGIN
        SET @cMensaje=N'Indique un distrito para una persona nueva.';
        GOTO __DESCO_Salida;
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

        IF @cDistrito IS NULL
        BEGIN
            SET @bUbi=1;
        END
        ELSE IF @nUbicacionId IS NULL
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

CREATE OR ALTER PROCEDURE [org].[PA_Socio_Ins_Registro]
(
    @cJson NVARCHAR(MAX),
    @nSocioId BIGINT OUTPUT,
    @nSocioAsociacionId BIGINT OUTPUT,
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
    SET XACT_ABORT ON;

    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,
            @gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
            @nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),
            @bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),
            @cTipo VARCHAR(15),@cDoc VARCHAR(30),@cNom NVARCHAR(100),@cAP NVARCHAR(80),
            @cAM NVARCHAR(80),@cTel VARCHAR(30),@cCorreo VARCHAR(180),@dNac DATE,
            @dAlta DATE,@nAsoc BIGINT,@cCodigo VARCHAR(30),@nCodigoConsecutivo BIGINT,@dDesde DATE,@cSituacion VARCHAR(20),
            @cDistrito CHAR(6),@nCentro BIGINT,@cReferencia NVARCHAR(300),
            @bPersonaExistia BIT,@bPersona BIT,@cMsgPersona NVARCHAR(300),
            @cPosterior NVARCHAR(MAX),@cIdent NVARCHAR(200),@nAud BIGINT,@nTrans BIGINT,
            @bPuedeEditarIdentidad BIT=0,@nPersonaExistente BIGINT=NULL,@nCoinPersona INT=0,
            @bBuscaPersona BIT=0,@cMsgBuscaPersona NVARCHAR(300),
            @cTipoActual VARCHAR(15),@cDocActual VARCHAR(30),@cNomActual NVARCHAR(100),
            @cAPActual NVARCHAR(80),@cAMActual NVARCHAR(80),@cTelActual VARCHAR(30),
            @cCorreoActual VARCHAR(180),@dNacActual DATE,@cDistritoActual CHAR(6),
            @cReferenciaActual NVARCHAR(300);

    SELECT @nSocioId=NULL,@nSocioAsociacionId=NULL,@bResultado=0,@cMensaje=N'No se pudo registrar el socio.';

    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente]
         @cJson=@cJson,@cCodigoPermiso='PRODUCTORES_CREAR',@cAmbito='SOCIO_CREAR',
         @nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,
         @nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,
         @gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,
         @nOperacionIdempotenteId=@nOp OUTPUT,@bEsRepetida=@bRep OUTPUT,@cEstadoOperacion=@cEstadoOp OUTPUT,
         @cIdentificadorResultado=@cIdRes OUTPUT,@cCodigoResultado=@cCodRes OUTPUT,
         @bResultado=@bIni OUTPUT,@cMensaje=@cMsg OUTPUT;

    IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    IF @bRep=1
    BEGIN
        IF @cEstadoOp='COMPLETADA'
        BEGIN
            SET @nSocioId=TRY_CONVERT(BIGINT,@cIdRes);
            SELECT TOP(1) @nSocioAsociacionId=socio_asociacion_id
            FROM [org].[SocioAsociacion]
            WHERE socio_id=@nSocioId
            ORDER BY CASE WHEN estado=1 AND fecha_hasta IS NULL THEN 0 ELSE 1 END,fecha_desde DESC,socio_asociacion_id DESC;
            SET @bResultado=1;
 SET @cMensaje=N'La solicitud ya fue procesada correctamente.';
        END
        ELSE SET @cMensaje=N'La solicitud ya se encuentra en proceso.';
        GOTO __DESCO_Salida;
    END;

    SELECT @cTipo=UPPER(NULLIF(LTRIM(RTRIM(tipoDocumento)),'')),@cDoc=NULLIF(LTRIM(RTRIM(numeroDocumento)),''),
           @cNom=NULLIF(LTRIM(RTRIM(nombres)),N''),@cAP=NULLIF(LTRIM(RTRIM(apellidoPaterno)),N''),
           @cAM=NULLIF(LTRIM(RTRIM(apellidoMaterno)),N''),@cTel=NULLIF(LTRIM(RTRIM(telefono)),''),
           @cCorreo=NULLIF(LTRIM(RTRIM(correo)),''),@dNac=fechaNacimiento
    FROM OPENJSON(@cJson,'$.persona')
    WITH(tipoDocumento VARCHAR(15) '$.tipoDocumento',numeroDocumento VARCHAR(30) '$.numeroDocumento',
         nombres NVARCHAR(100) '$.nombres',apellidoPaterno NVARCHAR(80) '$.apellidoPaterno',
         apellidoMaterno NVARCHAR(80) '$.apellidoMaterno',telefono VARCHAR(30) '$.telefono',
         correo VARCHAR(180) '$.correo',fechaNacimiento DATE '$.fechaNacimiento');

    SELECT @dAlta=fechaAlta,@nAsoc=asociacionId,
           @dDesde=fechaDesde,@cSituacion=UPPER(NULLIF(LTRIM(RTRIM(situacionMembresia)),''))
    FROM OPENJSON(@cJson,'$.socio')
    WITH(fechaAlta DATE '$.fechaAlta',asociacionId BIGINT '$.asociacionId',
         fechaDesde DATE '$.fechaDesde',situacionMembresia VARCHAR(20) '$.situacionMembresia');

    SELECT @cDistrito=COALESCE(NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.persona.ubicacion.distritoCodigo'))),''),NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.socio.ubicacion.distritoCodigo'))),''),NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.ubicacion.distritoCodigo'))),'')),
           @nCentro=TRY_CONVERT(BIGINT,COALESCE(JSON_VALUE(@cJson,'$.persona.ubicacion.centroPobladoId'),JSON_VALUE(@cJson,'$.socio.ubicacion.centroPobladoId'),JSON_VALUE(@cJson,'$.ubicacion.centroPobladoId'))),
           @cReferencia=COALESCE(NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.persona.ubicacion.referencia'))),N''),NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.socio.ubicacion.referencia'))),N''),NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.ubicacion.referencia'))),N''));

    IF @dDesde IS NULL SET @dDesde=@dAlta;
    IF @cSituacion IS NULL SET @cSituacion='ACTIVO';

    IF @cTipo NOT IN('DNI','RUC','CE','PASAPORTE','OTRO') OR @cDoc IS NULL OR @cNom IS NULL OR @cAP IS NULL
       OR @dAlta IS NULL OR @nAsoc IS NULL OR @dDesde IS NULL
       OR @cSituacion NOT IN('ACTIVO','SUSPENDIDO') OR @dDesde<@dAlta
    BEGIN SET @cMensaje=N'Complete correctamente los datos obligatorios y de afiliación del socio.';
 GOTO Fallar;
 END;

    IF NOT EXISTS(SELECT 1 FROM [org].[Asociacion] A INNER JOIN [org].[Empresa] E ON E.empresa_id=A.asociacion_id WHERE A.asociacion_id=@nAsoc AND A.estado=1 AND E.estado=1)
    BEGIN SET @cMensaje=N'La asociación seleccionada no está disponible.';
 GOTO Fallar;
 END;

    SET @bPuedeEditarIdentidad = CASE WHEN EXISTS(
            SELECT 1
            FROM [seg].[UsuarioRol] UR
            INNER JOIN [seg].[Rol] R
                    ON R.rol_id=UR.rol_id
                   AND R.estado=1
            INNER JOIN [seg].[RolPermiso] RP
                    ON RP.rol_id=UR.rol_id
                   AND RP.estado=1
            INNER JOIN [seg].[Permiso] PM
                    ON PM.permiso_id=RP.permiso_id
                   AND PM.estado=1
            WHERE UR.usuario_id=@nUsuario
              AND UR.estado=1
              AND UR.fecha_desde<=SYSUTCDATETIME()
              AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta>SYSUTCDATETIME())
              AND PM.codigo='VALIDACIONIDENTIDAD_EDITAR'
        ) THEN 1 ELSE 0 END;

    EXEC [org].[PA_Persona_Sel_IdPorDocumentoInterno]
         @cTipoDocumento=@cTipo,@cNumeroDocumento=@cDoc,@nExcluirPersonaId=NULL,
         @nPersonaId=@nPersonaExistente OUTPUT,@nCoincidencias=@nCoinPersona OUTPUT,
         @bResultado=@bBuscaPersona OUTPUT,@cMensaje=@cMsgBuscaPersona OUTPUT;

    IF @bBuscaPersona=0
    BEGIN SET @cMensaje=@cMsgBuscaPersona;
 GOTO Fallar;
 END;

    IF @nPersonaExistente IS NOT NULL
    BEGIN
        SELECT @cTipoActual=P.tipo_documento,@cDocActual=P.numero_documento,
               @cNomActual=P.nombres,@cAPActual=P.apellido_paterno,@cAMActual=P.apellido_materno,
               @cTelActual=P.telefono,@cCorreoActual=P.correo,@dNacActual=P.fecha_nacimiento,
               @cDistritoActual=U.distrito_codigo,@cReferenciaActual=U.referencia
        FROM [org].[Persona] P
        LEFT JOIN [geo].[Ubicacion] U ON U.ubicacion_id=P.ubicacion_id
        WHERE P.persona_id=@nPersonaExistente AND P.estado=1;

        IF @bPuedeEditarIdentidad=0 AND
        (
            (NULLIF(LTRIM(RTRIM(@cNomActual)),N'') IS NOT NULL AND ISNULL(@cNom,N'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cNomActual,N'') COLLATE Latin1_General_100_CI_AI) OR
            (NULLIF(LTRIM(RTRIM(@cAPActual)),N'') IS NOT NULL AND ISNULL(@cAP,N'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cAPActual,N'') COLLATE Latin1_General_100_CI_AI) OR
            (NULLIF(LTRIM(RTRIM(@cAMActual)),N'') IS NOT NULL AND ISNULL(@cAM,N'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cAMActual,N'') COLLATE Latin1_General_100_CI_AI) OR
            (NULLIF(LTRIM(RTRIM(@cTelActual)),'') IS NOT NULL AND ISNULL(@cTel,'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cTelActual,'') COLLATE Latin1_General_100_CI_AI) OR
            (NULLIF(LTRIM(RTRIM(@cCorreoActual)),'') IS NOT NULL AND ISNULL(@cCorreo,'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cCorreoActual,'') COLLATE Latin1_General_100_CI_AI) OR
            (@dNacActual IS NOT NULL AND ISNULL(@dNac,CONVERT(DATE,'19000101')) <> @dNacActual) OR
            (NULLIF(LTRIM(RTRIM(@cDistritoActual)),'') IS NOT NULL AND ISNULL(@cDistrito,'') <> ISNULL(@cDistritoActual,'')) OR
            (NULLIF(LTRIM(RTRIM(@cReferenciaActual)),N'') IS NOT NULL AND ISNULL(@cReferencia,N'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cReferenciaActual,N'') COLLATE Latin1_General_100_CI_AI)
        )
        BEGIN
            SET @cMensaje=N'No puede modificar los datos de la persona con su acceso actual.';
            GOTO Fallar;
        END;

        /* El documento de una persona existente nunca se modifica desde Productores / socios. */
        SET @cTipo=@cTipoActual;
        SET @cDoc=@cDocActual;
    END;

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        EXEC [org].[PA_Persona_InsOUpd_DesdeFormulario]
             @cTipoDocumento=@cTipo,@cNumeroDocumento=@cDoc,@cNombres=@cNom,
             @cApellidoPaterno=@cAP,@cApellidoMaterno=@cAM,@cTelefono=@cTel,
             @cCorreo=@cCorreo,@dFechaNacimiento=@dNac,@cDistritoCodigo=@cDistrito,
             @nCentroPobladoId=@nCentro,@cReferencia=@cReferencia,@nPersonaEsperadaId=NULL,
             @nPersonaId=@nSocioId OUTPUT,@bPersonaExistia=@bPersonaExistia OUTPUT,
             @bResultado=@bPersona OUTPUT,@cMensaje=@cMsgPersona OUTPUT;

        IF @bPersona=0 BEGIN BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
 SET @cMensaje=@cMsgPersona;
 GOTO Fallar;
 END;

        IF EXISTS(SELECT 1 FROM [org].[Socio] WHERE socio_id=@nSocioId)
        BEGIN BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
 SET @cMensaje=N'La persona ya se encuentra registrada como socio.';
 GOTO Fallar;
 END;

        INSERT [org].[Socio](socio_id,fecha_alta,estado) VALUES(@nSocioId,@dAlta,1);

        /* Código de socio generado por el sistema. */
        WHILE 1=1
        BEGIN
            SET @nCodigoConsecutivo = NEXT VALUE FOR [org].[SQ_CodigoSocio];
            SET @cCodigo = 'SOC-' + RIGHT(REPLICATE('0',12) + CONVERT(VARCHAR(20),@nCodigoConsecutivo),12);
            IF NOT EXISTS
            (
                SELECT 1
                FROM [org].[SocioAsociacion]
                WHERE asociacion_id=@nAsoc AND codigo_socio=@cCodigo
            ) BREAK;
        END;

        INSERT [org].[SocioAsociacion](socio_id,asociacion_id,codigo_socio,fecha_desde,fecha_hasta,situacion_membresia,estado)
        VALUES(@nSocioId,@nAsoc,@cCodigo,@dDesde,NULL,@cSituacion,1);
        SET @nSocioAsociacionId=CONVERT(BIGINT,SCOPE_IDENTITY());

        SELECT @cPosterior=(SELECT @nSocioId socioId,@cTipo tipoDocumento,@cDoc numeroDocumento,
                                   @nAsoc asociacionId,@cCodigo codigoSocio,@cSituacion situacionMembresia
                            FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
        SET @cIdent=CONVERT(NVARCHAR(200),@nSocioId);
        EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio]
             @nUsuario,@nSesion,@nDisp,@nModulo,'CREAR','org','Socio',@cIdent,
             NULL,@cPosterior,NULL,'estado',NULL,'1',@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;

        /* Confirmar datos e idempotencia juntos. */

        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
             @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='COMPLETADA',
             @cEsquemaEntidad='org',@cNombreEntidad='Socio',@cIdentificadorResultado=@cIdent,
             @cCodigoResultado='SOCIO_CREADO',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
IF ISNULL(@bFin,0) = 0
    THROW 51003, N'DESCO_IDEMPOTENCIA_NO_CERRADA', 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;

        SET @bResultado=1;
        SET @cMensaje=CASE WHEN @bPersonaExistia=1
                           THEN N'Socio registrado reutilizando la persona existente.'
                           ELSE N'Socio registrado correctamente.' END;
        GOTO __DESCO_Salida;
    END TRY
    BEGIN CATCH
SET @bResultado = 0;

        IF XACT_STATE()<>0 BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
        SET @cMensaje=N'No se pudo registrar el socio. Intente nuevamente.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'org.PA_Socio_Ins_Registro',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;

Fallar:
    IF @nOp IS NOT NULL AND @bResultado=0
        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
             @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='FALLIDA',@cEsquemaEntidad=NULL,
             @cNombreEntidad=NULL,@cIdentificadorResultado=NULL,@cCodigoResultado='NO_PROCESADO',
             @bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;

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
    @cProcedimiento = N'org.PA_Socio_Ins_Registro',
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

    IF @bResultado = 0 AND @nOp IS NOT NULL AND XACT_STATE() <> -1
    BEGIN
        IF ISNULL(@bRep,0) = 0
        BEGIN
        BEGIN TRY
            EXEC [auditoria].[PA_OperacionIdempotente_Upd_MensajeFallido]
                 @nOperacionIdempotenteId = @nOp, @cMensajeResultado = @cMensaje;
        END TRY
        BEGIN CATCH
            -- No sustituir el motivo funcional por un fallo de registro secundario.
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'org.PA_Socio_Ins_Registro',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
        END CATCH;
        END
        ELSE
        BEGIN
            SELECT @cMensaje = COALESCE(mensaje_resultado,
                CASE WHEN estado_operacion = 'FALLIDA'
                     THEN N'La solicitud anterior no se completó. Corrija los datos y envíe una nueva solicitud.'
                     ELSE N'La solicitud todavía se está procesando. Consulte el resultado antes de repetirla.' END)
            FROM [auditoria].[OperacionIdempotente]
            WHERE operacion_idempotente_id = @nOp;
        END;
    END;
IF @bResultado = 0
    SELECT @nSocioId = NULL, @nSocioAsociacionId = NULL;

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
    @cProcedimiento = N'org.PA_Socio_Ins_Registro',
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
FROM config.FN_RespuestaUsuario(N'org.PA_Socio_Ins_Registro',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO

CREATE OR ALTER PROCEDURE [org].[PA_Socio_Upd_Registro]
(
    @cJson NVARCHAR(MAX), @bResultado BIT OUTPUT, @cMensaje NVARCHAR(300) OUTPUT,
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
 SET XACT_ABORT ON;
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
            @nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),
            @nSocio BIGINT,@cTipoDoc VARCHAR(15),@cNumDoc VARCHAR(30),@cNombres NVARCHAR(100),@cApePat NVARCHAR(80),@cApeMat NVARCHAR(80),@cTel VARCHAR(30),@cCorreo VARCHAR(180),@dNac DATE,
            @dAlta DATE,@nAsoc BIGINT,@cCodigo VARCHAR(30),@nCodigoConsecutivo BIGINT,@dDesde DATE,@cSituacion VARCHAR(20),@nSA BIGINT,@nAsocActual BIGINT,@dDesdeActual DATE,
            @cAnterior NVARCHAR(MAX),@cPosterior NVARCHAR(MAX),@cIdent NVARCHAR(200),@nAud BIGINT,@nTrans BIGINT,
            @cDistrito CHAR(6),@nCentroPoblado BIGINT,@cReferencia NVARCHAR(300),@nUbicacionActual BIGINT,
            @bPuedeEditarIdentidad BIT=0,@cTipoActual VARCHAR(15),@cDocActual VARCHAR(30),
            @cNomActual NVARCHAR(100),@cAPActual NVARCHAR(80),@cAMActual NVARCHAR(80),
            @cTelActual VARCHAR(30),@cCorreoActual VARCHAR(180),@dNacActual DATE,
            @cDistritoActual CHAR(6),@cReferenciaActual NVARCHAR(300);
    SELECT @bResultado=0,@cMensaje=N'No se pudo actualizar el socio.';
    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente] @cJson,'PRODUCTORES_EDITAR','SOCIO_EDITAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@nOp OUTPUT,@bRep OUTPUT,@cEstadoOp OUTPUT,@cIdRes OUTPUT,@cCodRes OUTPUT,@bIni OUTPUT,@cMsg OUTPUT;
    IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    IF @bRep=1 BEGIN IF @cEstadoOp='COMPLETADA' BEGIN SET @bResultado=1;
 SET @cMensaje=N'La solicitud ya fue procesada correctamente.';
 END ELSE SET @cMensaje=N'La solicitud ya se encuentra en proceso.';
 GOTO __DESCO_Salida;
 END;

    SELECT @nSocio=socioId,@cTipoDoc=UPPER(NULLIF(LTRIM(RTRIM(tipoDocumento)),'')),@cNumDoc=NULLIF(LTRIM(RTRIM(numeroDocumento)),''),@cNombres=NULLIF(LTRIM(RTRIM(nombres)),N''),@cApePat=NULLIF(LTRIM(RTRIM(apellidoPaterno)),N''),@cApeMat=NULLIF(LTRIM(RTRIM(apellidoMaterno)),N''),@cTel=NULLIF(LTRIM(RTRIM(telefono)),''),@cCorreo=NULLIF(LTRIM(RTRIM(correo)),''),@dNac=fechaNacimiento
    FROM OPENJSON(@cJson,'$.persona') WITH (socioId BIGINT '$.socioId',tipoDocumento VARCHAR(15) '$.tipoDocumento',numeroDocumento VARCHAR(30) '$.numeroDocumento',nombres NVARCHAR(100) '$.nombres',apellidoPaterno NVARCHAR(80) '$.apellidoPaterno',apellidoMaterno NVARCHAR(80) '$.apellidoMaterno',telefono VARCHAR(30) '$.telefono',correo VARCHAR(180) '$.correo',fechaNacimiento DATE '$.fechaNacimiento');
    IF @nSocio IS NULL SELECT @nSocio=socioId FROM OPENJSON(@cJson,'$.socio') WITH (socioId BIGINT '$.socioId');
    SELECT @nAsoc=asociacionId,@dDesde=fechaDesde,@cSituacion=UPPER(NULLIF(LTRIM(RTRIM(situacionMembresia)),''))
    FROM OPENJSON(@cJson,'$.socio') WITH (asociacionId BIGINT '$.asociacionId',fechaDesde DATE '$.fechaDesde',situacionMembresia VARCHAR(20) '$.situacionMembresia');

    SELECT
        @cDistrito=COALESCE(
            NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.persona.ubicacion.distritoCodigo'))),''),
            NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.socio.ubicacion.distritoCodigo'))),''),
            NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.ubicacion.distritoCodigo'))),'')
        ),
        @nCentroPoblado=TRY_CONVERT(BIGINT,COALESCE(
            JSON_VALUE(@cJson,'$.persona.ubicacion.centroPobladoId'),
            JSON_VALUE(@cJson,'$.socio.ubicacion.centroPobladoId'),
            JSON_VALUE(@cJson,'$.ubicacion.centroPobladoId')
        )),
        @cReferencia=COALESCE(
            NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.persona.ubicacion.referencia'))),N''),
            NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.socio.ubicacion.referencia'))),N''),
            NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.ubicacion.referencia'))),N'')
        );
    IF @nSocio IS NULL OR @cTipoDoc IS NULL OR @cTipoDoc NOT IN('DNI','RUC','CE','PASAPORTE','OTRO') OR @cNumDoc IS NULL OR @cNombres IS NULL OR @cApePat IS NULL OR @nAsoc IS NULL OR @dDesde IS NULL OR @cSituacion IS NULL OR @cSituacion NOT IN('ACTIVO','SUSPENDIDO') BEGIN SET @cMensaje=N'Complete correctamente los datos del socio.';
 GOTO Fallar;
 END;
    IF @cTipoDoc IN('DNI','RUC') AND [org].[FN_Documento_EsValido](@cTipoDoc,@cNumDoc)=0 BEGIN SET @cMensaje=N'El DNI o RUC no supera la validación de integridad.';
 GOTO Fallar;
 END;
    IF @cTipoDoc='RUC' AND [org].[FN_Ruc_Naturaleza](@cNumDoc)<>'NATURAL' BEGIN SET @cMensaje=N'El RUC corresponde a una persona jurídica. No puede asignarse a un socio.';
 GOTO Fallar;
 END;
    IF @cDistrito IS NOT NULL AND NOT EXISTS(SELECT 1 FROM [geo].[Distrito] WHERE distrito_codigo=@cDistrito AND estado=1) BEGIN SET @cMensaje=N'El distrito seleccionado no está disponible.';
 GOTO Fallar;
 END;
    IF @nCentroPoblado IS NOT NULL AND NOT EXISTS(SELECT 1 FROM [geo].[CentroPoblado] WHERE centro_poblado_id=@nCentroPoblado AND distrito_codigo=@cDistrito AND estado=1) BEGIN SET @cMensaje=N'El centro poblado no corresponde al distrito seleccionado.';
 GOTO Fallar;
 END;
    SELECT @cTipoActual=P.tipo_documento,@cDocActual=P.numero_documento,
           @cNomActual=P.nombres,@cAPActual=P.apellido_paterno,@cAMActual=P.apellido_materno,
           @cTelActual=P.telefono,@cCorreoActual=P.correo,@dNacActual=P.fecha_nacimiento,
           @dAlta=S.fecha_alta,
           @nUbicacionActual=P.ubicacion_id,@cDistritoActual=U.distrito_codigo,@cReferenciaActual=U.referencia
    FROM [org].[Socio] S
    INNER JOIN [org].[Persona] P ON P.persona_id=S.socio_id
    LEFT JOIN [geo].[Ubicacion] U ON U.ubicacion_id=P.ubicacion_id
    WHERE S.socio_id=@nSocio AND S.estado=1 AND P.estado=1;

    IF @cTipoActual IS NULL BEGIN SET @cMensaje=N'El socio seleccionado no está disponible.';
 GOTO Fallar;
 END;

    IF @dNac>CONVERT(DATE,SYSUTCDATETIME()) OR @dDesde<@dAlta BEGIN SET @cMensaje=N'Las fechas ingresadas no son válidas.';
 GOTO Fallar;
 END;

    IF @cTipoDoc<>@cTipoActual OR @cNumDoc<>@cDocActual
    BEGIN SET @cMensaje=N'El documento de la persona no puede modificarse.';
 GOTO Fallar;
 END;

    SET @bPuedeEditarIdentidad = CASE WHEN EXISTS(
            SELECT 1
            FROM [seg].[UsuarioRol] UR
            INNER JOIN [seg].[Rol] R
                    ON R.rol_id=UR.rol_id
                   AND R.estado=1
            INNER JOIN [seg].[RolPermiso] RP
                    ON RP.rol_id=UR.rol_id
                   AND RP.estado=1
            INNER JOIN [seg].[Permiso] PM
                    ON PM.permiso_id=RP.permiso_id
                   AND PM.estado=1
            WHERE UR.usuario_id=@nUsuario
              AND UR.estado=1
              AND UR.fecha_desde<=SYSUTCDATETIME()
              AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta>SYSUTCDATETIME())
              AND PM.codigo='VALIDACIONIDENTIDAD_EDITAR'
        ) THEN 1 ELSE 0 END;

    IF @bPuedeEditarIdentidad=0 AND
    (
        (NULLIF(LTRIM(RTRIM(@cNomActual)),N'') IS NOT NULL AND ISNULL(@cNombres,N'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cNomActual,N'') COLLATE Latin1_General_100_CI_AI) OR
        (NULLIF(LTRIM(RTRIM(@cAPActual)),N'') IS NOT NULL AND ISNULL(@cApePat,N'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cAPActual,N'') COLLATE Latin1_General_100_CI_AI) OR
        (NULLIF(LTRIM(RTRIM(@cAMActual)),N'') IS NOT NULL AND ISNULL(@cApeMat,N'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cAMActual,N'') COLLATE Latin1_General_100_CI_AI) OR
        (NULLIF(LTRIM(RTRIM(@cTelActual)),'') IS NOT NULL AND ISNULL(@cTel,'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cTelActual,'') COLLATE Latin1_General_100_CI_AI) OR
        (NULLIF(LTRIM(RTRIM(@cCorreoActual)),'') IS NOT NULL AND ISNULL(@cCorreo,'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cCorreoActual,'') COLLATE Latin1_General_100_CI_AI) OR
        (@dNacActual IS NOT NULL AND ISNULL(@dNac,CONVERT(DATE,'19000101')) <> @dNacActual) OR
        (NULLIF(LTRIM(RTRIM(@cDistritoActual)),'') IS NOT NULL AND ISNULL(@cDistrito,'') <> ISNULL(@cDistritoActual,'')) OR
        (NULLIF(LTRIM(RTRIM(@cReferenciaActual)),N'') IS NOT NULL AND ISNULL(@cReferencia,N'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cReferenciaActual,N'') COLLATE Latin1_General_100_CI_AI)
    )
    BEGIN SET @cMensaje=N'No puede modificar los datos de la persona con su acceso actual.';
 GOTO Fallar;
 END;
    DECLARE @nConflictoPersona BIGINT,@nCoinDocumento INT,@bBuscaDocumento BIT,@cMsgDocumento NVARCHAR(300);
    EXEC [org].[PA_Persona_Sel_IdPorDocumentoInterno] @cTipoDocumento=@cTipoDoc,@cNumeroDocumento=@cNumDoc,@nExcluirPersonaId=@nSocio,@nPersonaId=@nConflictoPersona OUTPUT,@nCoincidencias=@nCoinDocumento OUTPUT,@bResultado=@bBuscaDocumento OUTPUT,@cMensaje=@cMsgDocumento OUTPUT;
    IF @bBuscaDocumento=0 OR @nCoinDocumento>0 BEGIN SET @cMensaje=CASE WHEN @bBuscaDocumento=0 THEN @cMsgDocumento ELSE N'El documento pertenece a otra persona registrada.' END;
 GOTO Fallar;
 END;
    IF NOT EXISTS(SELECT 1 FROM [org].[Asociacion] A INNER JOIN [org].[Empresa] E ON E.empresa_id=A.asociacion_id WHERE A.asociacion_id=@nAsoc AND A.estado=1 AND E.estado=1) BEGIN SET @cMensaje=N'La asociación seleccionada no está disponible.';
 GOTO Fallar;
 END;
    SELECT TOP(1) @nSA=socio_asociacion_id,@nAsocActual=asociacion_id,@cCodigo=codigo_socio,@dDesdeActual=fecha_desde FROM [org].[SocioAsociacion] WHERE socio_id=@nSocio AND estado=1 AND fecha_hasta IS NULL ORDER BY fecha_desde DESC;
    IF @nSA IS NULL BEGIN SET @cMensaje=N'El socio no cuenta con una afiliación vigente.';
 GOTO Fallar;
 END;
    IF @nAsocActual<>@nAsoc AND @dDesde<=@dDesdeActual BEGIN SET @cMensaje=N'La nueva afiliación debe iniciar después de la afiliación actual.';
 GOTO Fallar;
 END;

    BEGIN TRY
      BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
      SELECT @cAnterior=(SELECT S.socio_id,P.tipo_documento,P.numero_documento,P.nombres,P.apellido_paterno,P.apellido_materno,P.telefono,P.correo,P.fecha_nacimiento,S.fecha_alta,SA.asociacion_id,SA.codigo_socio,SA.fecha_desde,SA.situacion_membresia FROM [org].[Socio] S INNER JOIN [org].[Persona] P ON P.persona_id=S.socio_id LEFT JOIN [org].[SocioAsociacion] SA ON SA.socio_asociacion_id=@nSA WHERE S.socio_id=@nSocio FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
      IF @cDistrito IS NULL
      BEGIN
        -- Conservar la ubicación existente si no se informó distrito nuevo.
        SELECT @nUbicacionActual=@nUbicacionActual;
      END
      ELSE IF @nUbicacionActual IS NULL
      BEGIN
        INSERT [geo].[Ubicacion](distrito_codigo,centro_poblado_id,referencia,estado) VALUES(@cDistrito,@nCentroPoblado,@cReferencia,1);
        SET @nUbicacionActual=CONVERT(BIGINT,SCOPE_IDENTITY());
      END
      ELSE
      BEGIN
        UPDATE [geo].[Ubicacion] SET distrito_codigo=@cDistrito,centro_poblado_id=@nCentroPoblado,referencia=@cReferencia,estado=1 WHERE ubicacion_id=@nUbicacionActual;
      END;
      UPDATE [org].[Persona] SET tipo_persona='NATURAL',tipo_documento=@cTipoDoc,numero_documento=@cNumDoc,nombres=@cNombres,apellido_paterno=@cApePat,apellido_materno=@cApeMat,telefono=@cTel,correo=@cCorreo,fecha_nacimiento=@dNac,ubicacion_id=@nUbicacionActual WHERE persona_id=@nSocio AND estado=1;
      IF @nAsocActual=@nAsoc
        UPDATE [org].[SocioAsociacion] SET fecha_desde=@dDesde,situacion_membresia=@cSituacion WHERE socio_asociacion_id=@nSA AND estado=1;
      ELSE
      BEGIN
        UPDATE [org].[SocioAsociacion] SET fecha_hasta=DATEADD(DAY,-1,@dDesde),situacion_membresia='RETIRADO',estado=0 WHERE socio_asociacion_id=@nSA;

        /* Una nueva afiliación recibe un nuevo código de socio. */
        WHILE 1=1
        BEGIN
            SET @nCodigoConsecutivo = NEXT VALUE FOR [org].[SQ_CodigoSocio];
            SET @cCodigo = 'SOC-' + RIGHT(REPLICATE('0',12) + CONVERT(VARCHAR(20),@nCodigoConsecutivo),12);
            IF NOT EXISTS
            (
                SELECT 1
                FROM [org].[SocioAsociacion]
                WHERE asociacion_id=@nAsoc AND codigo_socio=@cCodigo
            ) BREAK;
        END;

        INSERT [org].[SocioAsociacion](socio_id,asociacion_id,codigo_socio,fecha_desde,fecha_hasta,situacion_membresia) VALUES(@nSocio,@nAsoc,@cCodigo,@dDesde,NULL,@cSituacion);
      END;
      SELECT @cPosterior=(SELECT S.socio_id,P.tipo_documento,P.numero_documento,P.nombres,P.apellido_paterno,P.apellido_materno,P.telefono,P.correo,P.fecha_nacimiento,S.fecha_alta,SA.asociacion_id,SA.codigo_socio,SA.fecha_desde,SA.situacion_membresia FROM [org].[Socio] S INNER JOIN [org].[Persona] P ON P.persona_id=S.socio_id OUTER APPLY(SELECT TOP(1) X.* FROM [org].[SocioAsociacion] X WHERE X.socio_id=S.socio_id AND X.estado=1 AND X.fecha_hasta IS NULL ORDER BY X.fecha_desde DESC) SA WHERE S.socio_id=@nSocio FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
      SET @cIdent=CONVERT(NVARCHAR(200),@nSocio);
      EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio] @nUsuario,@nSesion,@nDisp,@nModulo,'EDITAR','org','Socio',@cIdent,@cAnterior,@cPosterior,NULL,NULL,NULL,NULL,@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
      /* Confirmar datos e idempotencia juntos. */
      EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOp,'COMPLETADA','org','Socio',@cIdent,'SOCIO_ACTUALIZADO',@bFin OUTPUT,@cMsgFin OUTPUT;
IF ISNULL(@bFin,0) = 0
    THROW 51003, N'DESCO_IDEMPOTENCIA_NO_CERRADA', 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;

      SET @bResultado=1;
 SET @cMensaje=N'Socio actualizado correctamente.';
 GOTO __DESCO_Salida;
    END TRY
    BEGIN CATCH
SET @bResultado = 0;
 IF XACT_STATE()<>0 BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
 SET @cMensaje=N'No se pudo actualizar el socio. Intente nuevamente.';
 
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'org.PA_Socio_Upd_Registro',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;
Fallar:
    IF @nOp IS NOT NULL AND @bResultado=0 EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOp,'FALLIDA',NULL,NULL,NULL,'NO_PROCESADO',@bFin OUTPUT,@cMsgFin OUTPUT;

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
    @cProcedimiento = N'org.PA_Socio_Upd_Registro',
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

    IF @bResultado = 0 AND @nOp IS NOT NULL AND XACT_STATE() <> -1
    BEGIN
        IF ISNULL(@bRep,0) = 0
        BEGIN
        BEGIN TRY
            EXEC [auditoria].[PA_OperacionIdempotente_Upd_MensajeFallido]
                 @nOperacionIdempotenteId = @nOp, @cMensajeResultado = @cMensaje;
        END TRY
        BEGIN CATCH
            -- No sustituir el motivo funcional por un fallo de registro secundario.
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'org.PA_Socio_Upd_Registro',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
        END CATCH;
        END
        ELSE
        BEGIN
            SELECT @cMensaje = COALESCE(mensaje_resultado,
                CASE WHEN estado_operacion = 'FALLIDA'
                     THEN N'La solicitud anterior no se completó. Corrija los datos y envíe una nueva solicitud.'
                     ELSE N'La solicitud todavía se está procesando. Consulte el resultado antes de repetirla.' END)
            FROM [auditoria].[OperacionIdempotente]
            WHERE operacion_idempotente_id = @nOp;
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
    @cProcedimiento = N'org.PA_Socio_Upd_Registro',
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
FROM config.FN_RespuestaUsuario(N'org.PA_Socio_Upd_Registro',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO

CREATE OR ALTER PROCEDURE comercial.PA_APAPPSS_Comprador_Ins_Registro
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT, @cCodigoRespuesta VARCHAR(60) OUTPUT, @nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo registrar al comprador.',
   @cCodigoRespuesta='APAPPSS_COMPRADOR_ERROR',@nHttpRespuesta=400;
 DECLARE @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
   @tipo VARCHAR(10)=UPPER(NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.tipo')),'')),
   @tipoDocumento VARCHAR(15)=UPPER(NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.tipoDocumento')),'')),
   @doc VARCHAR(30)=UPPER(NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.documento')),'')),
   @nombres NVARCHAR(100)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.nombres')),N''),
   @paterno NVARCHAR(80)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.apellidoPaterno')),N''),
   @materno NVARCHAR(80)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.apellidoMaterno')),N''),
   @razon NVARCHAR(200)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.razonSocial')),N''),
   @comercial NVARCHAR(160)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.nombreComercial')),N''),
   @telefono VARCHAR(30)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.telefono')),''),
   @correo VARCHAR(180)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.correo')),''),
   @fecha DATE=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaNacimiento'),23),
   @sexo VARCHAR(20)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.sexo')),''),
   @distrito CHAR(6)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.distritoCodigo')),''),
   @centro BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.centroPobladoId')),
   @referencia NVARCHAR(300)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.referencia')),N''),
   @persona BIGINT=NULL,@empresa BIGINT=NULL,@id BIGINT=NULL,@ubicacion BIGINT=NULL,@locked INT,
   @okUbicacion BIT,@msgUbicacion NVARCHAR(300),
   @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
   @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
   @acceso BIT,@mensajeAcceso NVARCHAR(300);
 BEGIN TRY
   IF @uot IS NULL OR @tipo NOT IN('PERSONA','EMPRESA') OR @doc IS NULL OR @tipoDocumento IS NULL
      THROW 51821,N'Identifique el comprador y la UOT.',1;
   IF (@tipoDocumento='RUC' AND @tipo<>'EMPRESA') OR (@tipoDocumento<>'RUC' AND @tipo<>'PERSONA')
      OR LEN(@tipoDocumento) NOT BETWEEN 2 AND 15
      OR @tipoDocumento LIKE '%[^A-Z0-9_]%' OR @doc LIKE '%[^A-Z0-9]%'
      OR (@tipoDocumento='DNI' AND (LEN(@doc)<>8 OR @doc LIKE '%[^0-9]%'))
      OR (@tipoDocumento='RUC' AND (LEN(@doc)<>11 OR @doc LIKE '%[^0-9]%'))
      OR (@tipoDocumento='CE' AND LEN(@doc) NOT BETWEEN 6 AND 20)
      OR (@tipoDocumento NOT IN('DNI','RUC','CE') AND LEN(@doc) NOT BETWEEN 5 AND 30)
      THROW 51822,N'El documento o tipo de persona no es válido.',1;
   IF NOT EXISTS(SELECT 1 FROM config.TipoDocumentoComprador WHERE codigo=@tipoDocumento AND estado=1)
      THROW 51822,N'El tipo de documento no está habilitado en Administración.',1;
   IF @correo IS NOT NULL AND @correo NOT LIKE '%_@_%._%'
      THROW 51822,N'Ingrese un correo válido.',1;
   IF @fecha>CONVERT(DATE,SYSUTCDATETIME()) OR
      (JSON_VALUE(@cJson,'$.datos.fechaNacimiento') IS NOT NULL AND @fecha IS NULL)
      THROW 51822,N'La fecha de nacimiento no es válida.',1;
   IF @distrito IS NOT NULL AND NOT EXISTS(SELECT 1 FROM geo.Distrito WHERE distrito_codigo=@distrito AND estado=1)
      THROW 51822,N'El distrito seleccionado no existe.',1;
   IF @centro IS NOT NULL AND (@distrito IS NULL OR NOT EXISTS(
      SELECT 1 FROM geo.CentroPoblado WHERE centro_poblado_id=@centro AND distrito_codigo=@distrito AND estado=1))
      THROW 51822,N'El centro poblado no corresponde al distrito.',1;
   EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='APAPPSS_COMPRADORES_CREAR',
     @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
     @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
     @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
     @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
   IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'APAPPSS_COMPRADORES_CREAR')<>1
      THROW 51823,N'No tiene permiso para registrar compradores.',1;
   IF NOT EXISTS (SELECT 1 FROM org.ConvenioUOTOrganizacion CU
      JOIN org.Empresa E ON E.empresa_id=CU.empresa_id AND E.ruc='20602771394' AND E.estado=1
      JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND CM.estado=1
      JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
      JOIN org.UOT U ON U.uot_id=CU.uot_id AND U.estado=1 AND U.es_raiz=0
      WHERE CU.uot_id=@uot AND CU.estado=1 AND CU.tipo_vinculo='ASOCIACION'
      AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())))
      AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()))))
      THROW 51824,N'La UOT no tiene convenio vigente con APAPPSS.',1;
   BEGIN TRANSACTION;
   DECLARE @lockName NVARCHAR(255)=CONCAT(N'APAPPSS:COMPRADOR:',@tipo,N':',@tipoDocumento,N':',@doc);
   EXEC @locked=sys.sp_getapplock @Resource=@lockName,@LockMode='Exclusive',
     @LockOwner='Transaction',@LockTimeout=5000;
   IF @locked<0 THROW 51825,N'El comprador está siendo registrado por otro usuario.',1;

   IF @tipo='PERSONA'
   BEGIN
     SELECT TOP(1) @persona=P.persona_id,@ubicacion=P.ubicacion_id
       FROM org.Persona P WITH(UPDLOCK,HOLDLOCK)
       WHERE P.tipo_documento=@tipoDocumento AND P.numero_documento=@doc
       ORDER BY P.persona_id;
     IF @persona IS NULL AND (@nombres IS NULL OR @paterno IS NULL)
       THROW 51822,N'Complete los nombres y apellido paterno de la persona.',1;
     IF @persona IS NOT NULL AND NOT EXISTS(SELECT 1 FROM org.Persona WHERE persona_id=@persona AND estado=1)
       THROW 51826,N'La persona existe pero está inactiva.',1;
   END
   ELSE
   BEGIN
     IF @doc='20602771394' THROW 51827,N'La asociación APAPPSS no puede ser su propio comprador.',1;
     SELECT TOP(1) @empresa=E.empresa_id,@ubicacion=E.ubicacion_id
       FROM org.Empresa E WITH(UPDLOCK,HOLDLOCK) WHERE E.ruc=@doc ORDER BY E.empresa_id;
     IF @empresa IS NULL AND @razon IS NULL
       THROW 51822,N'Ingrese la razón social de la empresa.',1;
     IF @empresa IS NOT NULL AND NOT EXISTS(SELECT 1 FROM org.Empresa WHERE empresa_id=@empresa AND estado=1)
       THROW 51828,N'La empresa existe pero está inactiva.',1;
   END;

   -- Sólo completar la ubicación si aún no existe o si se facilitan campos vacíos compatibles.
   IF @ubicacion IS NULL AND @distrito IS NOT NULL
   BEGIN
     EXEC geo.PA_Ubicacion_Ins_Interna @cDistritoCodigo=@distrito,
       @nCentroPobladoId=@centro,@cReferencia=@referencia,
       @nLatitud=NULL,@nLongitud=NULL,@nAltitudM=NULL,
       @nUbicacionId=@ubicacion OUTPUT,@bResultado=@okUbicacion OUTPUT,@cMensaje=@msgUbicacion OUTPUT;
     IF ISNULL(@okUbicacion,0)<>1 OR @ubicacion IS NULL
       THROW 51829,N'No se pudo registrar la ubicación del comprador.',1;
   END
   ELSE IF @ubicacion IS NOT NULL AND @distrito IS NOT NULL
   BEGIN
     IF EXISTS(SELECT 1 FROM geo.Ubicacion U WHERE U.ubicacion_id=@ubicacion AND U.distrito_codigo<>@distrito)
       THROW 51829,N'La ubicación existente no coincide con el distrito ingresado.',1;
     UPDATE geo.Ubicacion
       SET centro_poblado_id=COALESCE(centro_poblado_id,@centro),
           referencia=CASE WHEN NULLIF(TRIM(referencia),N'') IS NULL THEN @referencia ELSE referencia END
     WHERE ubicacion_id=@ubicacion AND estado=1
       AND ((centro_poblado_id IS NULL AND @centro IS NOT NULL)
         OR (NULLIF(TRIM(referencia),N'') IS NULL AND @referencia IS NOT NULL));
   END;

   IF @tipo='PERSONA'
   BEGIN
     IF @persona IS NULL
     BEGIN
       INSERT org.Persona(tipo_persona,tipo_documento,numero_documento,nombres,apellido_paterno,
         apellido_materno,telefono,correo,fecha_nacimiento,sexo,ubicacion_id,estado)
       VALUES('NATURAL',@tipoDocumento,@doc,@nombres,@paterno,@materno,@telefono,@correo,
         @fecha,@sexo,@ubicacion,1);
       SET @persona=CONVERT(BIGINT,SCOPE_IDENTITY());
     END
     ELSE
       UPDATE org.Persona SET
         nombres=CASE WHEN NULLIF(TRIM(nombres),N'') IS NULL THEN COALESCE(@nombres,nombres) ELSE nombres END,
         apellido_paterno=CASE WHEN NULLIF(TRIM(apellido_paterno),N'') IS NULL THEN COALESCE(@paterno,apellido_paterno) ELSE apellido_paterno END,
         apellido_materno=CASE WHEN NULLIF(TRIM(apellido_materno),N'') IS NULL THEN COALESCE(@materno,apellido_materno) ELSE apellido_materno END,
         telefono=CASE WHEN NULLIF(TRIM(telefono),'') IS NULL THEN COALESCE(@telefono,telefono) ELSE telefono END,
         correo=CASE WHEN NULLIF(TRIM(correo),'') IS NULL THEN COALESCE(@correo,correo) ELSE correo END,
         fecha_nacimiento=COALESCE(fecha_nacimiento,@fecha),sexo=COALESCE(NULLIF(TRIM(sexo),''),@sexo),
         ubicacion_id=COALESCE(ubicacion_id,@ubicacion)
       WHERE persona_id=@persona AND estado=1;
   END
   ELSE
   BEGIN
     IF @empresa IS NULL
     BEGIN
       INSERT org.Empresa(ruc,razon_social,nombre_comercial,telefono,correo,ubicacion_id,estado)
       VALUES(@doc,@razon,@comercial,@telefono,@correo,@ubicacion,1);
       SET @empresa=CONVERT(BIGINT,SCOPE_IDENTITY());
     END
     ELSE
       UPDATE org.Empresa SET
         razon_social=CASE WHEN NULLIF(TRIM(razon_social),N'') IS NULL THEN COALESCE(@razon,razon_social) ELSE razon_social END,
         nombre_comercial=CASE WHEN NULLIF(TRIM(nombre_comercial),N'') IS NULL THEN COALESCE(@comercial,nombre_comercial) ELSE nombre_comercial END,
         telefono=CASE WHEN NULLIF(TRIM(telefono),'') IS NULL THEN COALESCE(@telefono,telefono) ELSE telefono END,
         correo=CASE WHEN NULLIF(TRIM(correo),'') IS NULL THEN COALESCE(@correo,correo) ELSE correo END,
         ubicacion_id=COALESCE(ubicacion_id,@ubicacion)
       WHERE empresa_id=@empresa AND estado=1;
   END;

   SELECT @id=B.comprador_apappss_id FROM comercial.CompradorAPAPPSS B WITH(UPDLOCK,HOLDLOCK)
     WHERE B.uot_id=@uot AND ((@tipo='PERSONA' AND B.persona_id=@persona)
       OR (@tipo='EMPRESA' AND B.empresa_id=@empresa));
   IF @id IS NULL
   BEGIN
     INSERT comercial.CompradorAPAPPSS(uot_id,tipo,persona_id,empresa_id,estado)
       VALUES(@uot,@tipo,@persona,@empresa,1);
     SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
   END
   ELSE THROW 51830,N'El comprador ya se encuentra registrado.',1;
   SET @cDatos=(SELECT @id compradorId,@tipo tipo,@persona personaId,@empresa empresaId
     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
   COMMIT TRANSACTION;
   SELECT @bResultado=1,@cMensaje=N'Comprador registrado.',
     @cCodigoRespuesta='APAPPSS_COMPRADOR_OK',@nHttpRespuesta=201;
 END TRY BEGIN CATCH
   IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
   SELECT @cDatos=NULL,@bResultado=0,
     @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51820 AND 51849 THEN LEFT(ERROR_MESSAGE(),300)
       ELSE N'No se pudo registrar al comprador.' END,
     @cCodigoRespuesta='APAPPSS_COMPRADOR_ERROR',
     @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51820 AND 51849 OR ERROR_NUMBER() IN(2601,2627) THEN 409 ELSE 500 END;
 END CATCH;
END;
GO

-- La edición ordinaria conserva su comportamiento; completarDatos=1 solo rellena vacíos.
CREATE OR ALTER PROCEDURE comercial.PA_APAPPSS_Comprador_Upd_Datos
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT, @cCodigoRespuesta VARCHAR(60) OUTPUT, @nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo actualizar el comprador.',
   @cCodigoRespuesta='APAPPSS_COMPRADOR_EDICION_ERROR',@nHttpRespuesta=400;
 DECLARE @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
   @id BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.compradorId')),
   @nombres NVARCHAR(100)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.nombres')),N''),
   @paterno NVARCHAR(80)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.apellidoPaterno')),N''),
   @materno NVARCHAR(80)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.apellidoMaterno')),N''),
   @razon NVARCHAR(200)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.razonSocial')),N''),
   @comercial NVARCHAR(160)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.nombreComercial')),N''),
   @telefono VARCHAR(30)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.telefono')),''),
   @correo VARCHAR(180)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.correo')),''),
   @soloCompletar BIT=ISNULL(TRY_CONVERT(BIT,JSON_VALUE(@cJson,'$.datos.completarDatos')),0),
   @fechaRaw VARCHAR(40)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.fechaNacimiento')),''),
   @fecha DATE=TRY_CONVERT(DATE,NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.fechaNacimiento')),''),23),
   @sexo VARCHAR(20)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.sexo')),''),
   @distrito CHAR(6)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.distritoCodigo')),''),
   @centro BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.centroPobladoId')),
   @referencia NVARCHAR(300)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.referencia')),N''),
   @tipo VARCHAR(10)=NULL,@persona BIGINT=NULL,@empresa BIGINT=NULL,
   @ubicacionAnterior BIGINT=NULL,@ubicacionNueva BIGINT=NULL,@locked INT,
   @okUbicacion BIT,@msgUbicacion NVARCHAR(300),
   @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
   @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
   @acceso BIT,@mensajeAcceso NVARCHAR(300);
 BEGIN TRY
   IF @uot IS NULL OR @uot<1 OR @id IS NULL OR @id<1
     THROW 51860,N'Identifique el comprador y la UOT.',1;
   IF @correo IS NOT NULL AND @correo NOT LIKE '%_@_%._%'
     THROW 51861,N'Ingrese un correo válido.',1;
   IF (@fechaRaw IS NOT NULL AND @fecha IS NULL) OR @fecha>CONVERT(DATE,SYSUTCDATETIME())
     THROW 51861,N'La fecha de nacimiento no es válida.',1;
   IF @distrito IS NOT NULL AND NOT EXISTS(SELECT 1 FROM geo.Distrito WHERE distrito_codigo=@distrito AND estado=1)
     THROW 51861,N'El distrito no está disponible.',1;
   IF @centro IS NOT NULL AND (@distrito IS NULL OR NOT EXISTS(
      SELECT 1 FROM geo.CentroPoblado WHERE centro_poblado_id=@centro AND distrito_codigo=@distrito AND estado=1))
     THROW 51861,N'El centro poblado no corresponde al distrito.',1;
   EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,
     @cCodigoPermiso='APAPPSS_COMPRADORES_EDITAR',
     @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,
     @nDispositivoUsuarioId=@dispositivo OUTPUT,@nEmpleadoId=@empleado OUTPUT,
     @nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,@gSolicitudId=@sol OUTPUT,
     @cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,@bResultado=@acceso OUTPUT,
     @cMensaje=@mensajeAcceso OUTPUT;
   IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'APAPPSS_COMPRADORES_EDITAR')<>1
     THROW 51862,N'No tiene permiso para editar compradores.',1;
   IF NOT EXISTS (SELECT 1 FROM org.ConvenioUOTOrganizacion CU
      JOIN org.Empresa E ON E.empresa_id=CU.empresa_id AND E.ruc='20602771394' AND E.estado=1
      JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND CM.estado=1
      JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
      JOIN org.UOT U ON U.uot_id=CU.uot_id AND U.estado=1 AND U.es_raiz=0
      WHERE CU.uot_id=@uot AND CU.estado=1 AND CU.tipo_vinculo='ASOCIACION'
      AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())))
      AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()))))
      THROW 51863,N'La UOT no tiene convenio APAPPSS vigente.',1;
   BEGIN TRANSACTION;
   SELECT @tipo=B.tipo,@persona=B.persona_id,@empresa=B.empresa_id
   FROM comercial.CompradorAPAPPSS B WITH(UPDLOCK,HOLDLOCK)
   WHERE B.comprador_apappss_id=@id AND B.uot_id=@uot AND B.estado=1;
   IF @tipo IS NULL THROW 51864,N'El comprador no está disponible en la UOT.',1;
   IF (@tipo='PERSONA' AND (@nombres IS NULL OR @paterno IS NULL))
      OR (@tipo='EMPRESA' AND @razon IS NULL)
      THROW 51865,N'Complete los datos de identificación obligatorios.',1;
   IF @tipo='PERSONA'
   BEGIN
     SELECT @ubicacionAnterior=P.ubicacion_id FROM org.Persona P WITH(UPDLOCK,HOLDLOCK)
     WHERE P.persona_id=@persona AND P.estado=1;
     IF @@ROWCOUNT<>1 THROW 51864,N'La identidad no está disponible.',1;
   END
   ELSE
   BEGIN
     SELECT @ubicacionAnterior=E.ubicacion_id FROM org.Empresa E WITH(UPDLOCK,HOLDLOCK)
     WHERE E.empresa_id=@empresa AND E.estado=1;
     IF @@ROWCOUNT<>1 THROW 51864,N'La empresa no está disponible.',1;
   END;
   SET @ubicacionNueva=@ubicacionAnterior;
   IF @soloCompletar=1 AND @ubicacionAnterior IS NOT NULL
   BEGIN
     -- Reutilizar los datos de ubicación que ya estaban registrados.
     SELECT @distrito=COALESCE(U.distrito_codigo,@distrito),
            @centro=COALESCE(U.centro_poblado_id,@centro),
            @referencia=COALESCE(NULLIF(TRIM(U.referencia),N''),@referencia)
     FROM geo.Ubicacion U WHERE U.ubicacion_id=@ubicacionAnterior AND U.estado=1;
   END;
   IF @distrito IS NOT NULL AND NOT EXISTS(SELECT 1 FROM geo.Ubicacion U
       WHERE U.ubicacion_id=@ubicacionAnterior AND U.distrito_codigo=@distrito
         AND ISNULL(U.centro_poblado_id,-1)=ISNULL(@centro,-1)
         AND ISNULL(U.referencia,N'')=ISNULL(@referencia,N''))
   BEGIN
     -- Una ubicación referenciada por otras entidades nunca se edita en sitio.
     EXEC geo.PA_Ubicacion_Ins_Interna @cDistritoCodigo=@distrito,
       @nCentroPobladoId=@centro,@cReferencia=@referencia,
       @nLatitud=NULL,@nLongitud=NULL,@nAltitudM=NULL,
       @nUbicacionId=@ubicacionNueva OUTPUT,@bResultado=@okUbicacion OUTPUT,
       @cMensaje=@msgUbicacion OUTPUT;
     IF ISNULL(@okUbicacion,0)<>1 OR @ubicacionNueva IS NULL
       THROW 51866,N'No se pudo actualizar la ubicación.',1;
   END;
   IF @tipo='PERSONA'
   BEGIN
     UPDATE org.Persona SET
       nombres=CASE WHEN @soloCompletar=1 THEN COALESCE(NULLIF(TRIM(nombres),N''),@nombres) ELSE @nombres END,
       apellido_paterno=CASE WHEN @soloCompletar=1 THEN COALESCE(NULLIF(TRIM(apellido_paterno),N''),@paterno) ELSE @paterno END,
       apellido_materno=CASE WHEN @soloCompletar=1 THEN COALESCE(NULLIF(TRIM(apellido_materno),N''),@materno) ELSE @materno END,
       telefono=CASE WHEN @soloCompletar=1 THEN COALESCE(NULLIF(TRIM(telefono),''),@telefono) ELSE @telefono END,
       correo=CASE WHEN @soloCompletar=1 THEN COALESCE(NULLIF(TRIM(correo),''),@correo) ELSE @correo END,
       fecha_nacimiento=CASE WHEN @soloCompletar=1 THEN COALESCE(fecha_nacimiento,@fecha) ELSE @fecha END,
       sexo=CASE WHEN @soloCompletar=1 THEN COALESCE(NULLIF(TRIM(sexo),''),@sexo) ELSE @sexo END,
       ubicacion_id=@ubicacionNueva
     WHERE persona_id=@persona AND estado=1;
   END
   ELSE
   BEGIN
     UPDATE org.Empresa SET
       razon_social=CASE WHEN @soloCompletar=1 THEN COALESCE(NULLIF(TRIM(razon_social),N''),@razon) ELSE @razon END,
       nombre_comercial=CASE WHEN @soloCompletar=1 THEN COALESCE(NULLIF(TRIM(nombre_comercial),N''),@comercial) ELSE @comercial END,
       telefono=CASE WHEN @soloCompletar=1 THEN COALESCE(NULLIF(TRIM(telefono),''),@telefono) ELSE @telefono END,
       correo=CASE WHEN @soloCompletar=1 THEN COALESCE(NULLIF(TRIM(correo),''),@correo) ELSE @correo END,
       ubicacion_id=@ubicacionNueva
     WHERE empresa_id=@empresa AND estado=1;
   END;
   SET @cDatos=(SELECT @id compradorId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   COMMIT TRANSACTION;
   SELECT @bResultado=1,@cCodigoRespuesta='APAPPSS_COMPRADOR_ACTUALIZADO',
     @cMensaje=N'Comprador actualizado.',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
   IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
   SELECT @cDatos=NULL,@bResultado=0,
     @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51860 AND 51869 THEN LEFT(ERROR_MESSAGE(),300)
       ELSE N'No se pudo actualizar al comprador.' END,
     @cCodigoRespuesta='APAPPSS_COMPRADOR_EDICION_ERROR',
     @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51860 AND 51869 THEN 409 ELSE 500 END;
 END CATCH;
END;
GO
