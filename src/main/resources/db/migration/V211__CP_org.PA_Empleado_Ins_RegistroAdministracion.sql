IF OBJECT_ID(N'[org].[PA_Empleado_Ins_RegistroAdministracion]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_Empleado_Ins_RegistroAdministracion];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_Empleado_Ins_RegistroAdministracion
' Descripción             : Registra un empleado desde la administración.
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
        @nEmpleadoId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [org].[PA_Empleado_Ins_RegistroAdministracion]
        @cJson = N'{}',
        @nEmpleadoId = @nEmpleadoId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nEmpleadoId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [org].[PA_Empleado_Ins_RegistroAdministracion]
(
    @cJson NVARCHAR(MAX),
    @nEmpleadoId BIGINT OUTPUT,
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
            @nAud BIGINT,@nTrans BIGINT,@cTipo VARCHAR(15),@cDoc VARCHAR(30),
            @cNom NVARCHAR(100),@cAP NVARCHAR(80),@cAM NVARCHAR(80),@cTel VARCHAR(30),
            @cCorreo VARCHAR(180),@dNac DATE,@nEmpresa BIGINT,@nUotSolicitada BIGINT,@nUot BIGINT,@bModoGeneral BIT,@bUot BIT,@cUotMsg NVARCHAR(300),@cCodigo VARCHAR(30),
            @dIngreso DATE,@nArea BIGINT,@cCargo NVARCHAR(120),@cDistrito CHAR(6),
            @nCentro BIGINT,@cReferencia NVARCHAR(300),@bPersonaExistia BIT,@bPersona BIT,
            @cMsgPersona NVARCHAR(300),@cIdent NVARCHAR(200),
            @bPuedeEditarIdentidad BIT=0,@nPersonaExistente BIGINT=NULL,@nCoinPersona INT=0,
            @bBuscaPersona BIT=0,@cMsgBuscaPersona NVARCHAR(300),
            @cTipoActual VARCHAR(15),@cDocActual VARCHAR(30),@cNomActual NVARCHAR(100),
            @cAPActual NVARCHAR(80),@cAMActual NVARCHAR(80),@cTelActual VARCHAR(30),
            @cCorreoActual VARCHAR(180),@dNacActual DATE,@cDistritoActual CHAR(6),
            @cReferenciaActual NVARCHAR(300);

    SELECT @nEmpleadoId=NULL,@bResultado=0,@cMensaje=N'No se pudo registrar el empleado.';

    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente]
         @cJson=@cJson,@cCodigoPermiso='EMPLEADOS_CREAR',@cAmbito='EMPLEADO_CREAR',
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
        IF @cEstadoOp='COMPLETADA' SET @nEmpleadoId=TRY_CONVERT(BIGINT,@cIdRes);
        SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END;
        SET @cMensaje=CASE WHEN @cEstadoOp='COMPLETADA' THEN N'La solicitud ya fue procesada correctamente.' ELSE N'La solicitud ya se encuentra en proceso.' END;
        GOTO __DESCO_Salida;
    END;

    SELECT @cTipo=UPPER(NULLIF(LTRIM(RTRIM(tipoDocumento)),'')),@cDoc=NULLIF(LTRIM(RTRIM(numeroDocumento)),''),
           @cNom=NULLIF(LTRIM(RTRIM(nombres)),N''),@cAP=NULLIF(LTRIM(RTRIM(apellidoPaterno)),N''),
           @cAM=NULLIF(LTRIM(RTRIM(apellidoMaterno)),N''),@cTel=NULLIF(LTRIM(RTRIM(telefono)),''),
           @cCorreo=NULLIF(LTRIM(RTRIM(correo)),''),@dNac=fechaNacimiento,@nUotSolicitada=uotId,
           @cCodigo=UPPER(NULLIF(LTRIM(RTRIM(codigoEmpleado)),'')),@dIngreso=fechaIngreso,
           @nArea=areaId,@cCargo=NULLIF(LTRIM(RTRIM(cargo)),N'')
    FROM OPENJSON(@cJson,'$.empleado')
    WITH(tipoDocumento VARCHAR(15) '$.tipoDocumento',numeroDocumento VARCHAR(30) '$.numeroDocumento',
         nombres NVARCHAR(100) '$.nombres',apellidoPaterno NVARCHAR(80) '$.apellidoPaterno',
         apellidoMaterno NVARCHAR(80) '$.apellidoMaterno',telefono VARCHAR(30) '$.telefono',
         correo VARCHAR(180) '$.correo',fechaNacimiento DATE '$.fechaNacimiento',uotId BIGINT '$.uotId',
         codigoEmpleado VARCHAR(30) '$.codigoEmpleado',fechaIngreso DATE '$.fechaIngreso',areaId BIGINT '$.areaId',cargo NVARCHAR(120) '$.cargo');

    SELECT @cDistrito=COALESCE(NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.empleado.ubicacion.distritoCodigo'))),''),NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.persona.ubicacion.distritoCodigo'))),''),NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.ubicacion.distritoCodigo'))),'')),
           @nCentro=TRY_CONVERT(BIGINT,COALESCE(JSON_VALUE(@cJson,'$.empleado.ubicacion.centroPobladoId'),JSON_VALUE(@cJson,'$.persona.ubicacion.centroPobladoId'),JSON_VALUE(@cJson,'$.ubicacion.centroPobladoId'))),
           @cReferencia=COALESCE(NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.empleado.ubicacion.referencia'))),N''),NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.persona.ubicacion.referencia'))),N''),NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.ubicacion.referencia'))),N''));

    EXEC [seg].[PA_UOT_Sel_ResolverContextoSesion]
         @nUsuarioId=@nUsuario,@nSesionUsuarioId=@nSesion,@nUotSolicitada=@nUotSolicitada,
         @cCodigoPermiso='EMPLEADOS_CREAR',@bRequiereUot=1,@nUotId=@nUot OUTPUT,
         @bModoGeneral=@bModoGeneral OUTPUT,@bResultado=@bUot OUTPUT,@cMensaje=@cUotMsg OUTPUT;
    IF @bUot=0 BEGIN SET @cMensaje=@cUotMsg; GOTO Fallar; END;

    SELECT @nEmpresa=empresa_legacy_id FROM [org].[UOT] WHERE uot_id=@nUot AND estado=1;

    IF @cTipo NOT IN('DNI','RUC','CE','PASAPORTE','OTRO') OR @cDoc IS NULL OR @cNom IS NULL OR @cAP IS NULL
       OR @nUot IS NULL OR @cCodigo IS NULL OR @dIngreso IS NULL OR @cDistrito IS NULL
    BEGIN SET @cMensaje=N'Complete correctamente los datos requeridos del empleado.';
 GOTO Fallar;
 END;

    IF @cTipo='RUC' AND LEFT(@cDoc,2)<>'10'
    BEGIN
        SET @cMensaje=N'Para empleados se admite DNI o RUC10.';
        GOTO Fallar;
    END;

    IF @dIngreso<CONVERT(DATE,SYSUTCDATETIME())
    BEGIN
        SET @cMensaje=N'La fecha de ingreso debe ser hoy o posterior.';
        GOTO Fallar;
    END;

    IF @dNac IS NOT NULL
       AND DATEADD(YEAR,18,@dNac)>@dIngreso
    BEGIN
        SET @cMensaje=N'La persona debe ser mayor de edad en la fecha de ingreso.';
        GOTO Fallar;
    END;

    IF @nArea IS NOT NULL AND NOT EXISTS(SELECT 1 FROM [org].[Area] WHERE area_id=@nArea AND uot_id=@nUot AND estado=1)
    BEGIN SET @cMensaje=N'El área seleccionada no corresponde a la UOT.';
 GOTO Fallar;
 END;
    IF @nArea IS NOT NULL AND @cCargo IS NULL
    BEGIN SET @cMensaje=N'Ingrese el cargo del empleado para el área seleccionada.';
 GOTO Fallar;
 END;

    IF @nArea IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM [config].[CatalogoRecursoValor] C
           WHERE C.catalogo='CARGO_EMPLEADO'
             AND C.estado=1
             AND C.nombre=@cCargo
       )
    BEGIN
        SET @cMensaje=N'El cargo seleccionado no está disponible.';
        GOTO Fallar;
    END;


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


        /* El documento de una persona existente nunca se modifica desde Empleados. */
        SET @cTipo=@cTipoActual;
        SET @cDoc=@cDocActual;
    END;

    /* DNI y RUC10 representan la misma persona natural. */
    IF @nPersonaExistente IS NOT NULL
       AND EXISTS
       (
           SELECT 1
           FROM [org].[EmpleadoUOT]
           WHERE empleado_id=@nPersonaExistente
             AND uot_id=@nUot
             AND estado=1
             AND fecha_hasta IS NULL
       )
    BEGIN
        SET @cMensaje=N'El empleado ya pertenece a la UOT seleccionada.';
        GOTO Fallar;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM [org].[Empleado] E
        JOIN [org].[EmpleadoUOT] EU
          ON EU.empleado_id=E.empleado_id
         AND EU.estado=1
         AND EU.fecha_hasta IS NULL
        WHERE EU.uot_id=@nUot
          AND COALESCE(EU.codigo_empleado,E.codigo_empleado)=@cCodigo
          AND (
              @nPersonaExistente IS NULL
              OR E.empleado_id<>@nPersonaExistente
          )
          AND E.estado=1
    )
    BEGIN
        SET @cMensaje=N'El código de empleado ya está registrado en la UOT.';
        GOTO Fallar;
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
             @nCentroPobladoId=@nCentro,@cReferencia=@cReferencia,@nPersonaEsperadaId=@nPersonaExistente,
             @nPersonaId=@nEmpleadoId OUTPUT,@bPersonaExistia=@bPersonaExistia OUTPUT,
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


        IF EXISTS(SELECT 1 FROM [org].[Empleado] WHERE empleado_id=@nEmpleadoId)
        BEGIN
            IF EXISTS(
                SELECT 1 FROM [org].[EmpleadoUOT]
                WHERE empleado_id=@nEmpleadoId AND uot_id=@nUot AND estado=1 AND fecha_hasta IS NULL
            )
            BEGIN
                BEGIN
                    IF @__DbTranAbierta = 1
                    BEGIN
                        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
                        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION @__DbSavepoint;
                        SET @__DbTranAbierta = 0;
                    END;
                END;
                SET @cMensaje=N'El empleado ya pertenece a la UOT seleccionada.';
                GOTO Fallar;
            END;
            UPDATE [org].[Empleado]
               SET estado=1, fecha_cese=NULL
             WHERE empleado_id=@nEmpleadoId;
        END
        ELSE
        BEGIN
            INSERT [org].[Empleado](empleado_id,empresa_id,codigo_empleado,fecha_ingreso,fecha_cese,estado)
            VALUES(@nEmpleadoId,@nEmpresa,@cCodigo,@dIngreso,NULL,1);
        END;

        DECLARE @bPrincipal BIT = CASE WHEN EXISTS(
            SELECT 1 FROM [org].[EmpleadoUOT]
            WHERE empleado_id=@nEmpleadoId AND estado=1 AND fecha_hasta IS NULL
        ) THEN 0 ELSE 1 END;

        INSERT [org].[EmpleadoUOT](empleado_id,uot_id,es_principal,fecha_desde,fecha_hasta,estado,codigo_empleado,fecha_ingreso,fecha_cese)
        VALUES(@nEmpleadoId,@nUot,@bPrincipal,@dIngreso,NULL,1,@cCodigo,@dIngreso,NULL);

        IF @nArea IS NOT NULL
            INSERT [org].[EmpleadoArea](empleado_id,area_id,cargo,fecha_desde,fecha_hasta,estado)
            VALUES(@nEmpleadoId,@nArea,@cCargo,@dIngreso,NULL,1);

        SET @cIdent=CONVERT(NVARCHAR(200),@nEmpleadoId);
        EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio]
             @nUsuario,@nSesion,@nDisp,@nModulo,'CREAR','org','Empleado',@cIdent,
             NULL,NULL,NULL,NULL,NULL,NULL,@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;

        /* Confirmar datos e idempotencia juntos. */

        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
             @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='COMPLETADA',
             @cEsquemaEntidad='org',@cNombreEntidad='Empleado',@cIdentificadorResultado=@cIdent,
             @cCodigoResultado='EMPLEADO_CREADO',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
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
                           THEN N'Empleado registrado en la UOT.'
                           ELSE N'Empleado registrado en la UOT.' END;
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
        SET @cMensaje=N'No se pudo registrar el empleado. Intente nuevamente.';

IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'org.PA_Empleado_Ins_RegistroAdministracion',
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
    @cProcedimiento = N'org.PA_Empleado_Ins_RegistroAdministracion',
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
    @cProcedimiento = N'org.PA_Empleado_Ins_RegistroAdministracion',
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
    SELECT @nEmpleadoId = NULL;

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
    @cProcedimiento = N'org.PA_Empleado_Ins_RegistroAdministracion',
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
FROM config.FN_RespuestaUsuario(N'org.PA_Empleado_Ins_RegistroAdministracion',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
