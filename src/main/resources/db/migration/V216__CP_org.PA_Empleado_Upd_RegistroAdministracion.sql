IF OBJECT_ID(N'[org].[PA_Empleado_Upd_RegistroAdministracion]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_Empleado_Upd_RegistroAdministracion];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_Empleado_Upd_RegistroAdministracion
' Descripción             : Actualiza un empleado desde la administración.
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
    EXEC [org].[PA_Empleado_Upd_RegistroAdministracion]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [org].[PA_Empleado_Upd_RegistroAdministracion]
(
    @cJson NVARCHAR(MAX),
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

    DECLARE
        @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,
        @gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
        @nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),
        @bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),
        @nAud BIGINT,@nTrans BIGINT,@nId BIGINT,@cIdent NVARCHAR(200),
        @cTipoIn VARCHAR(15),@cDocIn VARCHAR(30),@cNomIn NVARCHAR(100),@cAPIn NVARCHAR(80),
        @cAMIn NVARCHAR(80),@cTelIn VARCHAR(30),@cCorreoIn VARCHAR(180),@dNacIn DATE,
        @nUotIn BIGINT,@cCodigoIn VARCHAR(30),@dIngresoIn DATE,@nAreaIn BIGINT,
        @cCargoIn NVARCHAR(120),@dFechaAreaIn DATE,
        @cTipo VARCHAR(15),@cDoc VARCHAR(30),@cNom NVARCHAR(100),@cAP NVARCHAR(80),
        @cAM NVARCHAR(80),@cTel VARCHAR(30),@cCorreo VARCHAR(180),@dNac DATE,
        @nEmpresa BIGINT,@nUotActual BIGINT,@nUot BIGINT,@bModoGeneral BIT,@bUot BIT,@cUotMsg NVARCHAR(300),@cCodigo VARCHAR(30),@dIngreso DATE,
        @nAreaActual BIGINT,@cCargoActual NVARCHAR(120),@dAreaActual DATE,
        @nAreaObjetivo BIGINT,@cCargoObjetivo NVARCHAR(120),@dFechaArea DATE,
        @cDistrito CHAR(6),@nCentroPoblado BIGINT,@cReferencia NVARCHAR(300),
        @nUbicacionActual BIGINT,@bPuedeEditarIdentidad BIT=0,
        @cTipoActual VARCHAR(15),@cDocActual VARCHAR(30),@cNomActual NVARCHAR(100),
        @cAPActual NVARCHAR(80),@cAMActual NVARCHAR(80),@cTelActual VARCHAR(30),
        @cCorreoActual VARCHAR(180),@dNacActual DATE,@cDistritoActual CHAR(6),
        @cReferenciaActual NVARCHAR(300);

    SELECT @bResultado=0,@cMensaje=N'No se pudo actualizar el empleado.';

    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente]
         @cJson=@cJson,@cCodigoPermiso='EMPLEADOS_EDITAR',@cAmbito='EMPLEADO_EDITAR',
         @nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,
         @nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,
         @nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,
         @gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,
         @nOperacionIdempotenteId=@nOp OUTPUT,@bEsRepetida=@bRep OUTPUT,
         @cEstadoOperacion=@cEstadoOp OUTPUT,@cIdentificadorResultado=@cIdRes OUTPUT,
         @cCodigoResultado=@cCodRes OUTPUT,@bResultado=@bIni OUTPUT,@cMensaje=@cMsg OUTPUT;

    IF @bIni=0 AND @bRep=0
    BEGIN
        SET @cMensaje=@cMsg;
        GOTO __DESCO_Salida;
    END;

    IF @bRep=1
    BEGIN
        SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END;
        SET @cMensaje=CASE WHEN @cEstadoOp='COMPLETADA'
                           THEN N'La solicitud ya fue procesada correctamente.'
                           ELSE N'La solicitud ya se encuentra en proceso.' END;
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nId=empleadoId,
        @cTipoIn=UPPER(NULLIF(LTRIM(RTRIM(tipoDocumento)),'')),
        @cDocIn=NULLIF(LTRIM(RTRIM(numeroDocumento)),''),
        @cNomIn=NULLIF(LTRIM(RTRIM(nombres)),N''),
        @cAPIn=NULLIF(LTRIM(RTRIM(apellidoPaterno)),N''),
        @cAMIn=NULLIF(LTRIM(RTRIM(apellidoMaterno)),N''),
        @cTelIn=NULLIF(LTRIM(RTRIM(telefono)),''),
        @cCorreoIn=NULLIF(LTRIM(RTRIM(correo)),''),
        @dNacIn=fechaNacimiento,
        @nUotIn=uotId,
        @cCodigoIn=UPPER(NULLIF(LTRIM(RTRIM(codigoEmpleado)),'')),
        @dIngresoIn=fechaIngreso,
        @nAreaIn=areaId,
        @cCargoIn=NULLIF(LTRIM(RTRIM(cargo)),N''),
        @dFechaAreaIn=fechaAsignacionArea
    FROM OPENJSON(@cJson,'$.empleado')
    WITH
    (
        empleadoId BIGINT '$.empleadoId',
        tipoDocumento VARCHAR(15) '$.tipoDocumento',
        numeroDocumento VARCHAR(30) '$.numeroDocumento',
        nombres NVARCHAR(100) '$.nombres',
        apellidoPaterno NVARCHAR(80) '$.apellidoPaterno',
        apellidoMaterno NVARCHAR(80) '$.apellidoMaterno',
        telefono VARCHAR(30) '$.telefono',
        correo VARCHAR(180) '$.correo',
        fechaNacimiento DATE '$.fechaNacimiento',
        uotId BIGINT '$.uotId',
        codigoEmpleado VARCHAR(30) '$.codigoEmpleado',
        fechaIngreso DATE '$.fechaIngreso',
        areaId BIGINT '$.areaId',
        cargo NVARCHAR(120) '$.cargo',
        fechaAsignacionArea DATE '$.fechaAsignacionArea'
    );

    SELECT
        @cTipo=P.tipo_documento,@cDoc=P.numero_documento,@cNom=P.nombres,
        @cAP=P.apellido_paterno,@cAM=P.apellido_materno,@cTel=P.telefono,
        @cCorreo=P.correo,@dNac=P.fecha_nacimiento,@nUbicacionActual=P.ubicacion_id,
        @nEmpresa=E.empresa_id,@cCodigo=E.codigo_empleado,@dIngreso=E.fecha_ingreso
    FROM [org].[Empleado] E
    INNER JOIN [org].[Persona] P ON P.persona_id=E.empleado_id
    WHERE E.empleado_id=@nId AND E.estado=1 AND P.estado=1;

    IF @cTipo IS NULL
    BEGIN
        SET @cMensaje=N'El empleado seleccionado no está disponible.';
        GOTO Fallar;
    END;

    SET @nUot=@nUotIn;
    EXEC [seg].[PA_UOT_Sel_ResolverContextoSesion]
         @nUsuarioId=@nUsuario,@nSesionUsuarioId=@nSesion,@nUotSolicitada=@nUot,
         @cCodigoPermiso='EMPLEADOS_EDITAR',@bRequiereUot=1,@nUotId=@nUot OUTPUT,
         @bModoGeneral=@bModoGeneral OUTPUT,@bResultado=@bUot OUTPUT,@cMensaje=@cUotMsg OUTPUT;
    IF @bUot=0 BEGIN SET @cMensaje=@cUotMsg; GOTO Fallar; END;
    IF NOT EXISTS(SELECT 1 FROM [org].[EmpleadoUOT] WHERE empleado_id=@nId AND uot_id=@nUot AND estado=1 AND fecha_hasta IS NULL)
    BEGIN SET @cMensaje=N'El empleado no pertenece a la UOT seleccionada.'; GOTO Fallar; END;
    SELECT @nEmpresa=U.empresa_legacy_id,
           @cCodigo=COALESCE(EU.codigo_empleado,E.codigo_empleado),
           @dIngreso=COALESCE(EU.fecha_ingreso,E.fecha_ingreso)
    FROM [org].[EmpleadoUOT] EU
    JOIN [org].[Empleado] E ON E.empleado_id=EU.empleado_id
    JOIN [org].[UOT] U ON U.uot_id=EU.uot_id AND U.estado=1
    WHERE EU.empleado_id=@nId AND EU.uot_id=@nUot AND EU.estado=1 AND EU.fecha_hasta IS NULL;

    SELECT @cTipoActual=@cTipo,@cDocActual=@cDoc,@cNomActual=@cNom,@cAPActual=@cAP,
           @cAMActual=@cAM,@cTelActual=@cTel,@cCorreoActual=@cCorreo,@dNacActual=@dNac;

    SELECT @cDistritoActual=U.distrito_codigo,@cReferenciaActual=U.referencia
    FROM [geo].[Ubicacion] U
    WHERE U.ubicacion_id=@nUbicacionActual;

    IF (@cTipoIn IS NOT NULL AND @cTipoIn<>@cTipoActual)
       OR (@cDocIn IS NOT NULL AND @cDocIn<>@cDocActual)
    BEGIN
        SET @cMensaje=N'El documento de la persona no puede modificarse.';
        GOTO Fallar;
    END;


    IF @dIngresoIn IS NOT NULL
       AND @dIngresoIn<>@dIngreso
    BEGIN
        SET @cMensaje=N'La fecha de ingreso no puede modificarse.';
        GOTO Fallar;
    END;

    IF @cCodigoIn IS NOT NULL
       AND @cCodigoIn<>@cCodigo
    BEGIN
        SET @cMensaje=N'El código de empleado no puede modificarse.';
        GOTO Fallar;
    END;


    SELECT TOP(1)
        @nAreaActual=EA.area_id,@cCargoActual=EA.cargo,@dAreaActual=EA.fecha_desde
    FROM [org].[EmpleadoArea] EA
    JOIN [org].[Area] AX ON AX.area_id=EA.area_id AND AX.uot_id=@nUot
    WHERE EA.empleado_id=@nId AND EA.estado=1 AND EA.fecha_hasta IS NULL
    ORDER BY EA.fecha_desde DESC,EA.empleado_area_id DESC;

    SELECT
        @cTipo=COALESCE(@cTipoIn,@cTipo),
        @cDoc=COALESCE(@cDocIn,@cDoc),
        @cNom=COALESCE(@cNomIn,@cNom),
        @cAP=COALESCE(@cAPIn,@cAP),
        @cAM=COALESCE(@cAMIn,@cAM),
        @cTel=COALESCE(@cTelIn,@cTel),
        @cCorreo=COALESCE(@cCorreoIn,@cCorreo),
        @dNac=COALESCE(@dNacIn,@dNac),
        @nAreaObjetivo=@nAreaIn,
        @cCargoObjetivo=CASE
            WHEN @nAreaIn IS NULL THEN NULL
            ELSE @cCargoIn
        END,
        @dFechaArea=@dFechaAreaIn;

    SELECT
        @cDistrito=COALESCE(
            NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.empleado.ubicacion.distritoCodigo'))),''),
            NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.persona.ubicacion.distritoCodigo'))),''),
            NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.ubicacion.distritoCodigo'))),'')
        ),
        @nCentroPoblado=TRY_CONVERT(BIGINT,COALESCE(
            JSON_VALUE(@cJson,'$.empleado.ubicacion.centroPobladoId'),
            JSON_VALUE(@cJson,'$.persona.ubicacion.centroPobladoId'),
            JSON_VALUE(@cJson,'$.ubicacion.centroPobladoId')
        )),
        @cReferencia=COALESCE(
            NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.empleado.ubicacion.referencia'))),N''),
            NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.persona.ubicacion.referencia'))),N''),
            NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.ubicacion.referencia'))),N'')
        );


    /* Documento inmutable incluso para usuarios con permiso de edición de identidad. */
    SET @cTipo=@cTipoActual;
    SET @cDoc=@cDocActual;

    IF @cTipo NOT IN('DNI','RUC','CE','PASAPORTE','OTRO')
       OR @cDoc IS NULL OR @cNom IS NULL OR @cAP IS NULL
       OR @nUot IS NULL OR @cCodigo IS NULL OR @dIngreso IS NULL
       OR @cDistrito IS NULL
    BEGIN
        SET @cMensaje=N'Complete correctamente los datos del empleado.';
        GOTO Fallar;
    END;

    IF @cTipo IN('DNI','RUC') AND [org].[FN_Documento_EsValido](@cTipo,@cDoc)=0
    BEGIN
        SET @cMensaje=N'El DNI o RUC no supera la validación de integridad.';
        GOTO Fallar;
    END;

    IF @cTipo='RUC' AND [org].[FN_Ruc_Naturaleza](@cDoc)<>'NATURAL'
    BEGIN
        SET @cMensaje=N'El RUC corresponde a una persona jurídica. No puede asignarse a un empleado.';
        GOTO Fallar;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [geo].[Distrito]
        WHERE distrito_codigo=@cDistrito AND estado=1
    )
    BEGIN
        SET @cMensaje=N'El distrito seleccionado no está disponible.';
        GOTO Fallar;
    END;

    IF @nCentroPoblado IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM [geo].[CentroPoblado]
           WHERE centro_poblado_id=@nCentroPoblado
             AND distrito_codigo=@cDistrito
             AND estado=1
       )
    BEGIN
        SET @cMensaje=N'El centro poblado no corresponde al distrito seleccionado.';
        GOTO Fallar;
    END;

    IF @dNac IS NOT NULL AND @dNac>CONVERT(DATE,SYSUTCDATETIME())
    BEGIN
        SET @cMensaje=N'Ingrese una fecha de nacimiento válida.';
        GOTO Fallar;
    END;

    IF @dNacIn IS NOT NULL
       AND ISNULL(@dNacIn,CONVERT(DATE,'19000101'))
           <>ISNULL(@dNacActual,CONVERT(DATE,'19000101'))
       AND DATEADD(YEAR,18,@dNac)>@dIngreso
    BEGIN
        SET @cMensaje=N'La persona debe ser mayor de edad en la fecha de ingreso.';
        GOTO Fallar;
    END;

    IF @cCorreo IS NOT NULL AND @cCorreo NOT LIKE '%_@_%._%'
    BEGIN
        SET @cMensaje=N'Ingrese un correo válido.';
        GOTO Fallar;
    END;

    DECLARE @nConflictoPersona BIGINT,@nCoinDocumento INT,@bBuscaDocumento BIT,@cMsgDocumento NVARCHAR(300);
    EXEC [org].[PA_Persona_Sel_IdPorDocumentoInterno]
         @cTipoDocumento=@cTipo,@cNumeroDocumento=@cDoc,@nExcluirPersonaId=@nId,
         @nPersonaId=@nConflictoPersona OUTPUT,@nCoincidencias=@nCoinDocumento OUTPUT,
         @bResultado=@bBuscaDocumento OUTPUT,@cMensaje=@cMsgDocumento OUTPUT;
    IF @bBuscaDocumento=0 OR @nCoinDocumento>0
    BEGIN
        SET @cMensaje=CASE WHEN @bBuscaDocumento=0 THEN @cMsgDocumento ELSE N'El documento pertenece a otra persona registrada.' END;
        GOTO Fallar;
    END;

    IF EXISTS
    (
        SELECT 1 FROM [org].[Empleado] E
        JOIN [org].[EmpleadoUOT] EU ON EU.empleado_id=E.empleado_id AND EU.estado=1 AND EU.fecha_hasta IS NULL
        WHERE EU.uot_id=@nUot AND COALESCE(EU.codigo_empleado,E.codigo_empleado)=@cCodigo AND E.empleado_id<>@nId AND E.estado=1
    )
    BEGIN
        SET @cMensaje=N'El código de empleado ya está registrado en la UOT.';
        GOTO Fallar;
    END;

    IF @nAreaObjetivo IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1 FROM [org].[Area]
           WHERE area_id=@nAreaObjetivo AND uot_id=@nUot AND estado=1
       )
    BEGIN
        SET @cMensaje=N'El área seleccionada no corresponde a la UOT.';
        GOTO Fallar;
    END;

    IF @nAreaObjetivo IS NOT NULL AND @cCargoObjetivo IS NULL
    BEGIN
        SET @cMensaje=N'Ingrese el cargo del empleado.';
        GOTO Fallar;
    END;

    IF @nAreaObjetivo IS NOT NULL
       AND COALESCE(@cCargoObjetivo,N'')<>COALESCE(@cCargoActual,N'')
       AND NOT EXISTS
       (
           SELECT 1
           FROM [config].[CatalogoRecursoValor] C
           WHERE C.catalogo='CARGO_EMPLEADO'
             AND C.estado=1
             AND C.nombre=@cCargoObjetivo
       )
    BEGIN
        SET @cMensaje=N'El cargo seleccionado no está disponible.';
        GOTO Fallar;
    END;

    DECLARE @bCambioAsignacion BIT =
        CASE
            WHEN COALESCE(@nAreaObjetivo,-1)
                 <>COALESCE(@nAreaActual,-1)
              OR COALESCE(@cCargoObjetivo,N'')
                 <>COALESCE(@cCargoActual,N'')
            THEN 1
            ELSE 0
        END;

    IF @bCambioAsignacion=1
       AND @dFechaArea IS NULL
    BEGIN
        SET @cMensaje=N'Indique la fecha efectiva del cambio de área o cargo.';
        GOTO Fallar;
    END;

    IF @bCambioAsignacion=1
       AND @dFechaArea<@dIngreso
    BEGIN
        SET @cMensaje=N'La fecha efectiva del cambio no puede ser anterior al ingreso del empleado.';
        GOTO Fallar;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM [org].[EmpleadoArea] EAH
        JOIN [org].[Area] AH ON AH.area_id=EAH.area_id AND AH.uot_id=@nUot
        WHERE EAH.empleado_id=@nId
          AND EAH.fecha_desde<@dIngreso
    )
    BEGIN
        SET @cMensaje=N'La fecha de ingreso no puede quedar después de una asignación de área ya registrada.';
        GOTO Fallar;
    END;

    IF @bCambioAsignacion=1
       AND @dAreaActual IS NOT NULL
       AND @dFechaArea<@dAreaActual
    BEGIN
        SET @cMensaje=N'La nueva asignación de área no puede iniciar antes de la asignación vigente.';
        GOTO Fallar;
    END;

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        IF @nUbicacionActual IS NULL
        BEGIN
            INSERT [geo].[Ubicacion]
            (
                distrito_codigo,centro_poblado_id,referencia,estado
            )
            VALUES
            (
                @cDistrito,@nCentroPoblado,@cReferencia,1
            );

            SET @nUbicacionActual=CONVERT(BIGINT,SCOPE_IDENTITY());
        END
        ELSE
        BEGIN
            UPDATE [geo].[Ubicacion]
            SET distrito_codigo=@cDistrito,
                centro_poblado_id=@nCentroPoblado,
                referencia=@cReferencia,
                estado=1
            WHERE ubicacion_id=@nUbicacionActual;
        END;

        UPDATE [org].[Persona]
        SET tipo_persona='NATURAL',
            tipo_documento=@cTipo,
            numero_documento=@cDoc,
            nombres=@cNom,
            apellido_paterno=@cAP,
            apellido_materno=@cAM,
            telefono=@cTel,
            correo=@cCorreo,
            fecha_nacimiento=@dNac,
            ubicacion_id=@nUbicacionActual
        WHERE persona_id=@nId;

        UPDATE [org].[EmpleadoUOT]
           SET fecha_cese=NULL
         WHERE empleado_id=@nId
           AND uot_id=@nUot
           AND estado=1
           AND fecha_hasta IS NULL;

        IF EXISTS
        (
            SELECT 1
            FROM [org].[EmpleadoUOT]
            WHERE empleado_id=@nId
              AND uot_id=@nUot
              AND es_principal=1
              AND estado=1
              AND fecha_hasta IS NULL
        )
        BEGIN
            UPDATE [org].[Empleado]
               SET empresa_id=COALESCE(@nEmpresa,empresa_id),
                   fecha_cese=NULL
             WHERE empleado_id=@nId;
        END;

        IF @bCambioAsignacion=1
        BEGIN
            UPDATE EA
               SET fecha_hasta=@dFechaArea,
                   estado=0
            FROM [org].[EmpleadoArea] EA
            JOIN [org].[Area] AX ON AX.area_id=EA.area_id AND AX.uot_id=@nUot
            WHERE EA.empleado_id=@nId AND EA.estado=1 AND EA.fecha_hasta IS NULL;

            IF @nAreaObjetivo IS NOT NULL
            BEGIN
                INSERT [org].[EmpleadoArea]
                (
                    empleado_id,area_id,cargo,fecha_desde,fecha_hasta,estado
                )
                VALUES
                (
                    @nId,@nAreaObjetivo,@cCargoObjetivo,@dFechaArea,NULL,1
                );
            END;
        END;

        SET @cIdent=CONVERT(NVARCHAR(200),@nId);

        EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio]
             @nUsuario,@nSesion,@nDisp,@nModulo,'EDITAR','org','Empleado',@cIdent,
             NULL,NULL,NULL,NULL,NULL,NULL,@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;

        /* Confirmar datos e idempotencia juntos. */

        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
             @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='COMPLETADA',
             @cEsquemaEntidad='org',@cNombreEntidad='Empleado',
             @cIdentificadorResultado=@cIdent,@cCodigoResultado='EMPLEADO_ACTUALIZADO',
             @bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
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
        SET @cMensaje=N'Empleado actualizado.';
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
        SET @cMensaje=N'No se pudo actualizar el empleado. Intente nuevamente.';

IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'org.PA_Empleado_Upd_RegistroAdministracion',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;

Fallar:
    IF @nOp IS NOT NULL AND @bResultado=0
        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
             @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='FALLIDA',
             @cEsquemaEntidad=NULL,@cNombreEntidad=NULL,@cIdentificadorResultado=NULL,
             @cCodigoResultado='NO_PROCESADO',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;

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
    @cProcedimiento = N'org.PA_Empleado_Upd_RegistroAdministracion',
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
    @cProcedimiento = N'org.PA_Empleado_Upd_RegistroAdministracion',
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
    @cProcedimiento = N'org.PA_Empleado_Upd_RegistroAdministracion',
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
FROM config.FN_RespuestaUsuario(N'org.PA_Empleado_Upd_RegistroAdministracion',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
