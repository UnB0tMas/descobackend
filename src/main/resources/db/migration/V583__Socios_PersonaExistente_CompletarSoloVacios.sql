-- V583: Completar únicamente datos personales faltantes en alta de socio existente.
-- Conserva idempotencia, validaciones de documento, afiliación, permisos y auditoría.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_Socio_Ins_Registro
' Descripción             : Registra socios.
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
        @nSocioId BIGINT,
        @nSocioAsociacionId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [org].[PA_Socio_Ins_Registro]
        @cJson = N'{}',
        @nSocioId = @nSocioId OUTPUT,
        @nSocioAsociacionId = @nSocioAsociacionId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nSocioId, @nSocioAsociacionId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
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

    -- La persona existente puede no tener aún ubicación ni algunos datos de contacto.
    -- Para una identidad NUEVA se mantienen todos los requisitos anteriores.
    DECLARE @bDocumentoRegistrado BIT=CASE WHEN EXISTS (
        SELECT 1 FROM org.Persona WHERE tipo_documento=@cTipo AND numero_documento=@cDoc
          AND estado=1 AND tipo_persona='NATURAL'
    ) THEN 1 ELSE 0 END;
    IF @cTipo NOT IN('DNI','RUC','CE','PASAPORTE','OTRO') OR @cDoc IS NULL
       OR (@bDocumentoRegistrado=0 AND (@cNom IS NULL OR @cAP IS NULL OR @cDistrito IS NULL))
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

        -- Completar espacios vacíos no equivale a editar una identidad confirmada.
        IF @bPuedeEditarIdentidad=0 AND
        (
            (NULLIF(TRIM(@cNomActual),N'') IS NOT NULL AND @cNom IS NOT NULL AND
              @cNom COLLATE Latin1_General_100_CI_AI <> @cNomActual COLLATE Latin1_General_100_CI_AI) OR
            (NULLIF(TRIM(@cAPActual),N'') IS NOT NULL AND @cAP IS NOT NULL AND
              @cAP COLLATE Latin1_General_100_CI_AI <> @cAPActual COLLATE Latin1_General_100_CI_AI) OR
            (NULLIF(TRIM(@cAMActual),N'') IS NOT NULL AND @cAM IS NOT NULL AND
              @cAM COLLATE Latin1_General_100_CI_AI <> @cAMActual COLLATE Latin1_General_100_CI_AI) OR
            (NULLIF(TRIM(@cTelActual),'') IS NOT NULL AND @cTel IS NOT NULL AND
              @cTel COLLATE Latin1_General_100_CI_AI <> @cTelActual COLLATE Latin1_General_100_CI_AI) OR
            (NULLIF(TRIM(@cCorreoActual),'') IS NOT NULL AND @cCorreo IS NOT NULL AND
              @cCorreo COLLATE Latin1_General_100_CI_AI <> @cCorreoActual COLLATE Latin1_General_100_CI_AI) OR
            (@dNacActual IS NOT NULL AND @dNac IS NOT NULL AND @dNac<>@dNacActual) OR
            (@cDistritoActual IS NOT NULL AND @cDistrito IS NOT NULL AND @cDistrito<>@cDistritoActual) OR
            (NULLIF(TRIM(@cReferenciaActual),N'') IS NOT NULL AND @cReferencia IS NOT NULL AND
              @cReferencia COLLATE Latin1_General_100_CI_AI <> @cReferenciaActual COLLATE Latin1_General_100_CI_AI)
        )
        BEGIN
            SET @cMensaje=N'No puede modificar los datos de la persona con su acceso actual.';
            GOTO Fallar;
        END;

        /* La identidad existente prevalece; se completan solo los valores vacíos. */
        SELECT @cTipo=@cTipoActual,@cDoc=@cDocActual,
               @cNom=COALESCE(@cNom,NULLIF(TRIM(@cNomActual),N'')),
               @cAP=COALESCE(@cAP,NULLIF(TRIM(@cAPActual),N'')),
               @cAM=COALESCE(@cAM,NULLIF(TRIM(@cAMActual),N'')),
               @cTel=COALESCE(@cTel,NULLIF(TRIM(@cTelActual),'')),
               @cCorreo=COALESCE(@cCorreo,NULLIF(TRIM(@cCorreoActual),'')),
               @dNac=COALESCE(@dNac,@dNacActual),
               @cDistrito=COALESCE(@cDistrito,@cDistritoActual),
               @cReferencia=COALESCE(@cReferencia,NULLIF(TRIM(@cReferenciaActual),N''));
    END;

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        IF @nPersonaExistente IS NOT NULL
        BEGIN
            -- La persona ya existe. Se conserva su identificador; no se exige
            -- domicilio para afiliarla ni se sobrescriben valores existentes.
            SET @nSocioId=@nPersonaExistente;
            SET @bPersonaExistia=1;
            SET @bPersona=1;

            IF @cDistrito IS NOT NULL AND NOT EXISTS(
                SELECT 1 FROM geo.Distrito WHERE distrito_codigo=@cDistrito AND estado=1)
                THROW 51683,N'El distrito indicado no está disponible.',1;
            IF @nCentro IS NOT NULL AND (@cDistrito IS NULL OR NOT EXISTS(
                SELECT 1 FROM geo.CentroPoblado
                WHERE centro_poblado_id=@nCentro AND distrito_codigo=@cDistrito AND estado=1))
                THROW 51683,N'El centro poblado no corresponde al distrito.',1;

            IF @cCorreo IS NOT NULL AND EXISTS(
                SELECT 1 FROM org.Persona P WITH(UPDLOCK,HOLDLOCK)
                WHERE P.correo_clave_desco=LOWER(TRIM(@cCorreo)) COLLATE Latin1_General_100_CI_AS
                  AND P.persona_id<>@nSocioId)
                THROW 51683,N'El correo pertenece a otra persona.',1;

            DECLARE @nUbicacionExistente BIGINT=NULL;
            SELECT @nUbicacionExistente=ubicacion_id FROM org.Persona WITH(UPDLOCK,HOLDLOCK)
             WHERE persona_id=@nSocioId AND estado=1;
            IF @nUbicacionExistente IS NULL AND @cDistrito IS NOT NULL
            BEGIN
                DECLARE @bOkUbi BIT,@cMsgUbi NVARCHAR(300);
                EXEC geo.PA_Ubicacion_Ins_Interna
                   @cDistritoCodigo=@cDistrito,@nCentroPobladoId=@nCentro,@cReferencia=@cReferencia,
                   @nLatitud=NULL,@nLongitud=NULL,@nAltitudM=NULL,
                   @nUbicacionId=@nUbicacionExistente OUTPUT,
                   @bResultado=@bOkUbi OUTPUT,@cMensaje=@cMsgUbi OUTPUT;
                IF ISNULL(@bOkUbi,0)<>1 OR @nUbicacionExistente IS NULL
                    THROW 51683,N'No se pudo registrar la ubicación de la persona.',1;
            END;
            IF @nUbicacionExistente IS NOT NULL AND @cDistrito IS NOT NULL
            BEGIN
                IF EXISTS(SELECT 1 FROM geo.Ubicacion WHERE ubicacion_id=@nUbicacionExistente
                          AND distrito_codigo<>@cDistrito)
                    THROW 51683,N'La ubicación no coincide con la persona registrada.',1;
                UPDATE geo.Ubicacion
                   SET centro_poblado_id=COALESCE(centro_poblado_id,@nCentro),
                       referencia=CASE WHEN NULLIF(TRIM(referencia),N'') IS NULL THEN @cReferencia ELSE referencia END
                WHERE ubicacion_id=@nUbicacionExistente AND estado=1;
            END;
            UPDATE org.Persona
               SET nombres=CASE WHEN NULLIF(TRIM(nombres),N'') IS NULL THEN COALESCE(@cNom,nombres) ELSE nombres END,
                   apellido_paterno=CASE WHEN NULLIF(TRIM(apellido_paterno),N'') IS NULL THEN COALESCE(@cAP,apellido_paterno) ELSE apellido_paterno END,
                   apellido_materno=COALESCE(NULLIF(TRIM(apellido_materno),N''),@cAM),
                   telefono=COALESCE(NULLIF(TRIM(telefono),''),@cTel),
                   correo=COALESCE(NULLIF(TRIM(correo),''),@cCorreo),
                   fecha_nacimiento=COALESCE(fecha_nacimiento,@dNac),
                   ubicacion_id=COALESCE(ubicacion_id,@nUbicacionExistente)
             WHERE persona_id=@nSocioId AND estado=1;
        END
        ELSE
        BEGIN
            -- Se mantiene exactamente el procedimiento original de alta manual.
            EXEC [org].[PA_Persona_InsOUpd_DesdeFormulario]
                 @cTipoDocumento=@cTipo,@cNumeroDocumento=@cDoc,@cNombres=@cNom,
                 @cApellidoPaterno=@cAP,@cApellidoMaterno=@cAM,@cTelefono=@cTel,
                 @cCorreo=@cCorreo,@dFechaNacimiento=@dNac,@cDistritoCodigo=@cDistrito,
                 @nCentroPobladoId=@nCentro,@cReferencia=@cReferencia,@nPersonaEsperadaId=NULL,
                 @nPersonaId=@nSocioId OUTPUT,@bPersonaExistia=@bPersonaExistia OUTPUT,
                 @bResultado=@bPersona OUTPUT,@cMensaje=@cMsgPersona OUTPUT;
        END;

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

-- E1: mismos criterios de completado opcional para titulares de fundos.
-- V580: misma ficha de identidad en Gestión Técnica y socios APAPPSS.
-- Completar solo campos faltantes, sin alterar datos de una identidad existente.
CREATE OR ALTER PROCEDURE prod.PA_E1_Persona_Ins_Completa
  @cJson NVARCHAR(MAX),
  @nPersonaId BIGINT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @tipo VARCHAR(15), @numero VARCHAR(30), @nombres NVARCHAR(100),
          @paterno NVARCHAR(80), @materno NVARCHAR(80),
          @telefono VARCHAR(30), @correo VARCHAR(180), @fecha DATE,
          @distrito CHAR(6), @centro BIGINT, @referencia NVARCHAR(300),
          @ubicacion BIGINT, @existe BIT = 0, @ok BIT, @mensaje NVARCHAR(300);

  SELECT @tipo=UPPER(TRIM(tipoDocumento)),@numero=TRIM(numeroDocumento),
         @nombres=NULLIF(TRIM(nombres),N''),@paterno=NULLIF(TRIM(apellidoPaterno),N''),
         @materno=NULLIF(TRIM(apellidoMaterno),N''),
         @telefono=NULLIF(TRIM(telefono),''),@correo=NULLIF(TRIM(correo),''),
         @fecha=fechaNacimiento,@distrito=NULLIF(TRIM(distritoCodigo),''),
         @centro=centroPobladoId,@referencia=NULLIF(TRIM(referencia),N'')
  FROM OPENJSON(@cJson,'$.datos') WITH (
    tipoDocumento VARCHAR(15),numeroDocumento VARCHAR(30),
    nombres NVARCHAR(100),apellidoPaterno NVARCHAR(80),apellidoMaterno NVARCHAR(80),
    telefono VARCHAR(30),correo VARCHAR(180),fechaNacimiento DATE,
    distritoCodigo CHAR(6),centroPobladoId BIGINT,referencia NVARCHAR(300));

  IF @tipo IS NULL OR @tipo NOT IN('DNI','CE','PASAPORTE') OR @numero IS NULL OR LEN(@numero)<5 OR
      (@tipo='DNI' AND (@numero NOT LIKE REPLICATE('[0-9]',8) OR LEN(@numero)<>8))
    THROW 51052,N'Indique un documento válido para la persona.',1;

  -- Una persona existente puede continuar sin completar su información opcional.
  SET @nPersonaId=NULL;
  SELECT TOP (1) @nPersonaId=persona_id,@ubicacion=ubicacion_id
    FROM org.Persona WITH (UPDLOCK,HOLDLOCK)
    WHERE tipo_documento=@tipo AND numero_documento=@numero;
  SET @existe=CASE WHEN @nPersonaId IS NULL THEN 0 ELSE 1 END;
  IF @existe=1
  BEGIN
    SELECT @nombres=COALESCE(@nombres,NULLIF(TRIM(P.nombres),N'')),
           @paterno=COALESCE(@paterno,NULLIF(TRIM(P.apellido_paterno),N'')),
           @distrito=COALESCE(@distrito,U.distrito_codigo)
      FROM org.Persona P LEFT JOIN geo.Ubicacion U ON U.ubicacion_id=P.ubicacion_id
      WHERE P.persona_id=@nPersonaId AND P.estado=1;
  END;
  IF @existe=0 AND (@nombres IS NULL OR @paterno IS NULL OR @distrito IS NULL)
    THROW 51052,N'Complete los datos obligatorios de la persona.',1;
  IF @distrito IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM geo.Distrito WHERE distrito_codigo=@distrito AND estado=1)
    THROW 51052,N'Seleccione un distrito válido para la persona.',1;
  IF @centro IS NOT NULL AND (@distrito IS NULL OR NOT EXISTS (
    SELECT 1 FROM geo.CentroPoblado WHERE centro_poblado_id=@centro
      AND distrito_codigo=@distrito AND estado=1))
    THROW 51052,N'El centro poblado no corresponde al distrito indicado.',1;
  IF @fecha>CONVERT(DATE,SYSUTCDATETIME())
    THROW 51052,N'La fecha de nacimiento no puede ser futura.',1;
  IF @correo IS NOT NULL AND @correo NOT LIKE '%_@_%._%'
    THROW 51052,N'Ingrese un correo electrónico válido.',1;

  IF @existe=1
  BEGIN
    IF EXISTS(SELECT 1 FROM org.Persona WHERE persona_id=@nPersonaId
      AND (estado<>1 OR tipo_persona<>'NATURAL'))
      THROW 51052,N'La persona no está disponible para este registro.',1;
    IF EXISTS(SELECT 1 FROM org.Persona WHERE persona_id=@nPersonaId AND (
       (NULLIF(TRIM(nombres),N'') IS NOT NULL AND TRIM(nombres) COLLATE Latin1_General_100_CI_AI
          <> @nombres COLLATE Latin1_General_100_CI_AI)
       OR (NULLIF(TRIM(apellido_paterno),N'') IS NOT NULL AND TRIM(apellido_paterno) COLLATE Latin1_General_100_CI_AI
          <> @paterno COLLATE Latin1_General_100_CI_AI)
       OR (NULLIF(TRIM(apellido_materno),N'') IS NOT NULL AND @materno IS NOT NULL
          AND TRIM(apellido_materno) COLLATE Latin1_General_100_CI_AI <> @materno COLLATE Latin1_General_100_CI_AI)
    )) THROW 51052,N'El documento pertenece a otra identidad. Seleccione la persona existente.',1;
    IF @ubicacion IS NOT NULL
    BEGIN
      IF NOT EXISTS(SELECT 1 FROM geo.Ubicacion WHERE ubicacion_id=@ubicacion AND estado=1 AND distrito_codigo=@distrito)
        THROW 51052,N'El distrito no coincide con la ubicación de la persona registrada.',1;
      IF @centro IS NOT NULL AND EXISTS(SELECT 1 FROM geo.Ubicacion WHERE ubicacion_id=@ubicacion
          AND centro_poblado_id IS NOT NULL AND centro_poblado_id<>@centro)
        THROW 51052,N'El centro poblado es distinto al registrado para esta persona.',1;
      -- Solo completar datos geográficos vacíos, nunca cambiar ubicaciones existentes.
      UPDATE geo.Ubicacion
         SET centro_poblado_id=COALESCE(centro_poblado_id,@centro),
             referencia=CASE WHEN NULLIF(TRIM(referencia),N'') IS NULL THEN @referencia ELSE referencia END
       WHERE ubicacion_id=@ubicacion AND estado=1;
    END;
  END;

  IF @ubicacion IS NULL AND @distrito IS NOT NULL
  BEGIN
    EXEC geo.PA_Ubicacion_Ins_Interna
      @cDistritoCodigo=@distrito,@nCentroPobladoId=@centro,@cReferencia=@referencia,
      @nLatitud=NULL,@nLongitud=NULL,@nAltitudM=NULL,
      @nUbicacionId=@ubicacion OUTPUT,@bResultado=@ok OUTPUT,@cMensaje=@mensaje OUTPUT;
    IF ISNULL(@ok,0)<>1 OR @ubicacion IS NULL
      THROW 51052,N'No se pudo registrar la ubicación de la persona.',1;
  END;

  IF @existe=0
  BEGIN
    INSERT org.Persona (tipo_persona,tipo_documento,numero_documento,nombres,
      apellido_paterno,apellido_materno,telefono,correo,fecha_nacimiento,ubicacion_id,estado)
    VALUES ('NATURAL',@tipo,@numero,@nombres,@paterno,@materno,@telefono,@correo,@fecha,@ubicacion,1);
    SET @nPersonaId=CONVERT(BIGINT,SCOPE_IDENTITY());
  END
  ELSE
  BEGIN
    -- Los datos ya presentes, incluidos los recuperados automáticamente, no se sobrescriben.
    UPDATE org.Persona
       SET nombres=CASE WHEN NULLIF(TRIM(nombres),N'') IS NULL THEN @nombres ELSE nombres END,
           apellido_paterno=CASE WHEN NULLIF(TRIM(apellido_paterno),N'') IS NULL THEN @paterno ELSE apellido_paterno END,
           apellido_materno=CASE WHEN NULLIF(TRIM(apellido_materno),N'') IS NULL THEN @materno ELSE apellido_materno END,
           telefono=CASE WHEN NULLIF(TRIM(telefono),'') IS NULL THEN @telefono ELSE telefono END,
           correo=CASE WHEN NULLIF(TRIM(correo),'') IS NULL THEN @correo ELSE correo END,
           fecha_nacimiento=COALESCE(fecha_nacimiento,@fecha),
           ubicacion_id=COALESCE(ubicacion_id,@ubicacion)
     WHERE persona_id=@nPersonaId AND estado=1;
  END;
END;
GO

-- Origen Factiliza: proteger valores existentes, permitir completar campos realmente vacíos.
CREATE OR ALTER TRIGGER org.TR_Persona_ProtegerOrigenFactiliza
ON org.Persona
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        JOIN deleted D
          ON D.persona_id=I.persona_id
        JOIN integracion.IdentidadCampoOrigen O
          ON O.entidad_objetivo='PERSONA'
         AND O.entidad_id=I.persona_id
         AND O.proveedor='FACTILIZA'
         AND O.estado=1
        WHERE
             (O.campo='NOMBRES' AND NULLIF(TRIM(D.nombres),N'') IS NOT NULL
              AND ISNULL(I.nombres,N'') COLLATE Latin1_General_100_CI_AI
                  <> ISNULL(D.nombres,N'') COLLATE Latin1_General_100_CI_AI)
          OR (O.campo='APELLIDO_PATERNO' AND NULLIF(TRIM(D.apellido_paterno),N'') IS NOT NULL
              AND ISNULL(I.apellido_paterno,N'') COLLATE Latin1_General_100_CI_AI
                  <> ISNULL(D.apellido_paterno,N'') COLLATE Latin1_General_100_CI_AI)
          OR (O.campo='APELLIDO_MATERNO' AND NULLIF(TRIM(D.apellido_materno),N'') IS NOT NULL
              AND ISNULL(I.apellido_materno,N'') COLLATE Latin1_General_100_CI_AI
                  <> ISNULL(D.apellido_materno,N'') COLLATE Latin1_General_100_CI_AI)
          OR (O.campo='FECHA_NACIMIENTO' AND D.fecha_nacimiento IS NOT NULL
              AND ISNULL(I.fecha_nacimiento,CONVERT(DATE,'19000101'))
                  <> ISNULL(D.fecha_nacimiento,CONVERT(DATE,'19000101')))
          OR (O.campo IN('GEOGRAFIA','CENTRO_POBLADO','REFERENCIA') AND D.ubicacion_id IS NOT NULL
              AND ISNULL(I.ubicacion_id,-1)<>ISNULL(D.ubicacion_id,-1))
    )
    BEGIN
        THROW 51060,
              N'Los datos validados automáticamente no pueden modificarse.',
              1;
    END;
END;
GO
