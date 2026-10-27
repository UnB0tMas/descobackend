IF OBJECT_ID(N'[org].[PA_Socio_Ins_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_Socio_Ins_Registro];
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
CREATE PROCEDURE [org].[PA_Socio_Ins_Registro]
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

    IF @cTipo NOT IN('DNI','RUC','CE','PASAPORTE','OTRO') OR @cDoc IS NULL OR @cNom IS NULL OR @cAP IS NULL OR @cDistrito IS NULL
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
            ISNULL(@cNom,N'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cNomActual,N'') COLLATE Latin1_General_100_CI_AI OR
            ISNULL(@cAP,N'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cAPActual,N'') COLLATE Latin1_General_100_CI_AI OR
            ISNULL(@cAM,N'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cAMActual,N'') COLLATE Latin1_General_100_CI_AI OR
            ISNULL(@cTel,'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cTelActual,'') COLLATE Latin1_General_100_CI_AI OR
            ISNULL(@cCorreo,'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cCorreoActual,'') COLLATE Latin1_General_100_CI_AI OR
            ISNULL(@dNac,CONVERT(DATE,'19000101')) <> ISNULL(@dNacActual,CONVERT(DATE,'19000101')) OR
            ISNULL(@cDistrito,'') <> ISNULL(@cDistritoActual,'') OR
            ISNULL(@cReferencia,N'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cReferenciaActual,N'') COLLATE Latin1_General_100_CI_AI
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
