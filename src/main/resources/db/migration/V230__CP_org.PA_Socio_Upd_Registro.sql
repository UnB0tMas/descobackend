IF OBJECT_ID(N'[org].[PA_Socio_Upd_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_Socio_Upd_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_Socio_Upd_Registro
' Descripción             : Actualiza los datos de socios.
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
    EXEC [org].[PA_Socio_Upd_Registro]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [org].[PA_Socio_Upd_Registro]
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
    IF @nSocio IS NULL OR @cTipoDoc IS NULL OR @cTipoDoc NOT IN('DNI','RUC','CE','PASAPORTE','OTRO') OR @cNumDoc IS NULL OR @cNombres IS NULL OR @cApePat IS NULL OR @nAsoc IS NULL OR @dDesde IS NULL OR @cSituacion IS NULL OR @cSituacion NOT IN('ACTIVO','SUSPENDIDO') OR @cDistrito IS NULL BEGIN SET @cMensaje=N'Complete correctamente los datos del socio, incluido el distrito.';
 GOTO Fallar;
 END;
    IF @cTipoDoc IN('DNI','RUC') AND [org].[FN_Documento_EsValido](@cTipoDoc,@cNumDoc)=0 BEGIN SET @cMensaje=N'El DNI o RUC no supera la validación de integridad.';
 GOTO Fallar;
 END;
    IF @cTipoDoc='RUC' AND [org].[FN_Ruc_Naturaleza](@cNumDoc)<>'NATURAL' BEGIN SET @cMensaje=N'El RUC corresponde a una persona jurídica. No puede asignarse a un socio.';
 GOTO Fallar;
 END;
    IF NOT EXISTS(SELECT 1 FROM [geo].[Distrito] WHERE distrito_codigo=@cDistrito AND estado=1) BEGIN SET @cMensaje=N'El distrito seleccionado no está disponible.';
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
        ISNULL(@cNombres,N'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cNomActual,N'') COLLATE Latin1_General_100_CI_AI OR
        ISNULL(@cApePat,N'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cAPActual,N'') COLLATE Latin1_General_100_CI_AI OR
        ISNULL(@cApeMat,N'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cAMActual,N'') COLLATE Latin1_General_100_CI_AI OR
        ISNULL(@cTel,'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cTelActual,'') COLLATE Latin1_General_100_CI_AI OR
        ISNULL(@cCorreo,'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cCorreoActual,'') COLLATE Latin1_General_100_CI_AI OR
        ISNULL(@dNac,CONVERT(DATE,'19000101')) <> ISNULL(@dNacActual,CONVERT(DATE,'19000101')) OR
        ISNULL(@cDistrito,'') <> ISNULL(@cDistritoActual,'') OR
        ISNULL(@cReferencia,N'') COLLATE Latin1_General_100_CI_AI <> ISNULL(@cReferenciaActual,N'') COLLATE Latin1_General_100_CI_AI
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
      IF @nUbicacionActual IS NULL
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
