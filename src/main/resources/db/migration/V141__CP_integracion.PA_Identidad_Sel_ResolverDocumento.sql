IF OBJECT_ID(N'[integracion].[PA_Identidad_Sel_ResolverDocumento]', N'P') IS NOT NULL
    DROP PROCEDURE [integracion].[PA_Identidad_Sel_ResolverDocumento];
GO

/******************************************************************************************************
' Nombre del PA           : integracion.PA_Identidad_Sel_ResolverDocumento
' Descripción             : Resuelve la información de identidad a partir de un documento.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Integraciones
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
    EXEC [integracion].[PA_Identidad_Sel_ResolverDocumento]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [integracion].[PA_Identidad_Sel_ResolverDocumento]
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

    BEGIN TRY

    SET NOCOUNT ON;

    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,
            @gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
            @bCtx BIT,@cMsg NVARCHAR(300);
    DECLARE @cEntidad VARCHAR(10),@cTipo VARCHAR(15),@cDoc VARCHAR(30),
            @cTipoExterno VARCHAR(15),@cDocExterno VARCHAR(30),@cClave VARCHAR(60),
            @nEntidadId BIGINT=NULL,@cTipoPersona VARCHAR(12)=NULL,
            @bEmpleado BIT=0,@bSocio BIT=0,@bAsociacion BIT=0,@bEstadoEntidad BIT=NULL,
            @nCoincidencias INT,@bBusca BIT,@cMsgBusca NVARCHAR(300),@cRucDni VARCHAR(11),
            @cEstadoPrevio VARCHAR(25)=NULL,@cEstadoSalida VARCHAR(300)=NULL,@dReintento DATETIME2(0)=NULL,@dBloqueo DATETIME2(0)=NULL,
            @bRequiereExterno BIT=0;

    SELECT @bResultado=0,@cMensaje=N'No se pudo resolver el documento.';

    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
         @cJson=@cJson,@cCodigoPermiso='VALIDACIONIDENTIDAD_CONSULTAR',
         @nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,
         @nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,
         @nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,
         @gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,
         @bResultado=@bCtx OUTPUT,@cMensaje=@cMsg OUTPUT;

    IF @bCtx=0
    BEGIN
        SET @cMensaje=@cMsg;
        GOTO __DESCO_Salida;
    END;

    SELECT
        @cEntidad=UPPER(NULLIF(LTRIM(RTRIM(entidadObjetivo)),'')),
        @cTipo=UPPER(NULLIF(LTRIM(RTRIM(tipoDocumento)),'')),
        @cDoc=NULLIF(LTRIM(RTRIM(numeroDocumento)),'')
    FROM OPENJSON(@cJson,'$.consulta')
    WITH
    (
        entidadObjetivo VARCHAR(10) '$.entidadObjetivo',
        tipoDocumento VARCHAR(15) '$.tipoDocumento',
        numeroDocumento VARCHAR(30) '$.numeroDocumento'
    );

    IF @cEntidad NOT IN('PERSONA','EMPRESA') OR @cTipo NOT IN('DNI','RUC')
    BEGIN
        SET @cMensaje=N'La solicitud de validación no es válida.';
        GOTO __DESCO_Salida;
    END;

    IF @cEntidad='EMPRESA'
    BEGIN
        IF @cTipo<>'RUC'
           OR LEN(@cDoc)<>11
           OR @cDoc LIKE '%[^0-9]%'
        BEGIN
            SET @cMensaje=N'El RUC debe tener 11 dígitos.';
            GOTO __DESCO_Salida;
        END;

        SELECT @nEntidadId=E.empresa_id,@bEstadoEntidad=E.estado,
               @bAsociacion=CASE WHEN A.asociacion_id IS NULL THEN 0 ELSE 1 END
        FROM [org].[Empresa] E
        LEFT JOIN [org].[Asociacion] A ON A.asociacion_id=E.empresa_id
        WHERE E.ruc=@cDoc;

        SET @cTipoPersona='JURIDICA';
        SET @cTipoExterno='RUC';
        SET @cDocExterno=@cDoc;
        SET @cClave='RUC:'+@cDoc;
    END
    ELSE
    BEGIN
        IF [org].[FN_Documento_EsValido](@cTipo,@cDoc)=0
        BEGIN
            SET @cMensaje=N'El documento ingresado no es válido.';
            GOTO __DESCO_Salida;
        END;

        IF @cTipo='RUC' AND [org].[FN_Ruc_Naturaleza](@cDoc)='JURIDICA'
        BEGIN
            SET @cMensaje=N'El RUC corresponde a una persona jurídica. Realice la búsqueda como EMPRESA.';
            GOTO __DESCO_Salida;
        END;

        EXEC [org].[PA_Persona_Sel_IdPorDocumentoInterno]
             @cTipoDocumento=@cTipo,
             @cNumeroDocumento=@cDoc,
             @nExcluirPersonaId=NULL,
             @nPersonaId=@nEntidadId OUTPUT,
             @nCoincidencias=@nCoincidencias OUTPUT,
             @bResultado=@bBusca OUTPUT,
             @cMensaje=@cMsgBusca OUTPUT;

        IF @bBusca=0
        BEGIN
            SET @cMensaje=@cMsgBusca;
            GOTO __DESCO_Salida;
        END;

        IF @nEntidadId IS NOT NULL
        BEGIN
            SELECT @cTipoPersona=P.tipo_persona,@bEstadoEntidad=P.estado
            FROM [org].[Persona] P WHERE P.persona_id=@nEntidadId;
            SET @bEmpleado=CASE WHEN EXISTS(SELECT 1 FROM [org].[Empleado] WHERE empleado_id=@nEntidadId) THEN 1 ELSE 0 END;
            SET @bSocio=CASE WHEN EXISTS(SELECT 1 FROM [org].[Socio] WHERE socio_id=@nEntidadId) THEN 1 ELSE 0 END;
        END
        ELSE
            SET @cTipoPersona='NATURAL';

        IF @cTipo='RUC' AND LEFT(@cDoc,2)='10'
        BEGIN
            SET @cTipoExterno='DNI';
            SET @cDocExterno=SUBSTRING(@cDoc,3,8);
            SET @cClave='DNI:'+@cDocExterno;
        END
        ELSE IF @cTipo='DNI'
        BEGIN
            SET @cTipoExterno='DNI';
            SET @cDocExterno=@cDoc;
            SET @cClave='DNI:'+@cDoc;
        END
        ELSE
        BEGIN
            /* RUC 15/17: persona natural sin DNI derivable de forma segura. */
            SET @cTipoExterno='RUC';
            SET @cDocExterno=@cDoc;
            SET @cClave='RUC:'+@cDoc;
        END;
    END;

    SELECT TOP(1)
           @cEstadoPrevio=CD.estado_consulta,
           @dReintento=CD.reintento_desde_utc,
           @dBloqueo=CD.bloqueo_hasta_utc
    FROM [integracion].[ConsultaDocumento] CD
    WHERE CD.entidad_objetivo=@cEntidad
      AND CD.clave_documento=@cClave
      AND CD.estado=1
    ORDER BY CD.consulta_documento_id DESC;

    IF @nEntidadId IS NOT NULL
    BEGIN
        SET @bRequiereExterno=0;
    END
    ELSE
    BEGIN
        SELECT @cEstadoPrevio=estado_consulta,
               @dReintento=reintento_desde_utc,
               @dBloqueo=bloqueo_hasta_utc
        FROM [integracion].[ConsultaDocumento]
        WHERE entidad_objetivo=@cEntidad AND clave_documento=@cClave AND estado=1;

        SET @bRequiereExterno=1;

        IF @cEstadoPrevio='RESERVADA' AND @dBloqueo>SYSUTCDATETIME()
            SET @bRequiereExterno=0;
        ELSE IF @cEstadoPrevio IN('ERROR','NO_ENCONTRADO') AND @dReintento>SYSUTCDATETIME()
            SET @bRequiereExterno=0;
        ELSE IF @cEstadoPrevio='DATOS_INSUFICIENTES'
            SET @bRequiereExterno=0;
    END;

    IF @cEntidad='PERSONA' AND @nEntidadId IS NOT NULL
    BEGIN
        SET @cEstadoSalida=@cEstadoPrevio;

        IF @cEstadoPrevio='EXITO'
        BEGIN
            DECLARE @cCamposFactiliza VARCHAR(240);

            SELECT @cCamposFactiliza=
                STRING_AGG(C.campo, ',')
                    WITHIN GROUP (ORDER BY C.campo)
            FROM [integracion].[IdentidadCampoOrigen] C
            WHERE C.entidad_objetivo='PERSONA'
              AND C.entidad_id=@nEntidadId
              AND C.proveedor='FACTILIZA'
              AND C.estado=1;

            IF NULLIF(@cCamposFactiliza,'') IS NOT NULL
                SET @cEstadoSalida='EXITO|'+@cCamposFactiliza;
        END;

        SELECT
            CONVERT(BIT,1) encontradoLocal,
            @cEntidad entidadObjetivo,
            P.persona_id entidadId,
            P.tipo_persona tipoPersona,
            P.tipo_documento tipoDocumento,
            P.numero_documento numeroDocumento,
            P.nombres,
            P.apellido_paterno apellidoPaterno,
            P.apellido_materno apellidoMaterno,
            P.telefono telefono,
            P.correo correo,
            CAST(NULL AS NVARCHAR(200)) razonSocial,
            P.fecha_nacimiento fechaNacimiento,
            P.sexo,
            P.ubicacion_id ubicacionId,
            RTRIM(DEP.departamento_codigo) departamentoCodigo,
            DEP.nombre departamentoNombre,
            RTRIM(PR.provincia_codigo) provinciaCodigo,
            PR.nombre provinciaNombre,
            RTRIM(D.distrito_codigo) distritoCodigo,
            D.nombre distritoNombre,
            U.centro_poblado_id centroPobladoId,
            CP.nombre centroPobladoNombre,
            U.referencia referenciaUbicacion,
            P.estado estadoEntidad,
            @bEmpleado esEmpleado,
            @bSocio esSocio,
            CONVERT(BIT,0) esAsociacion,
            CONVERT(BIT,0) requiereConsultaExterna,
            @cTipoExterno tipoDocumentoConsultaExterna,
            @cDocExterno numeroDocumentoConsultaExterna,
            @cClave claveConsulta,
            @cEstadoSalida estadoConsultaPrevia,
            @dReintento reintentoDesdeUtc,
            @dBloqueo bloqueoHastaUtc
        FROM [org].[Persona] P
        LEFT JOIN [geo].[Ubicacion] U
               ON U.ubicacion_id = P.ubicacion_id
        LEFT JOIN [geo].[Distrito] D
               ON D.distrito_codigo = U.distrito_codigo
        LEFT JOIN [geo].[Provincia] PR
               ON PR.provincia_codigo = D.provincia_codigo
        LEFT JOIN [geo].[Departamento] DEP
               ON DEP.departamento_codigo = PR.departamento_codigo
        LEFT JOIN [geo].[CentroPoblado] CP
               ON CP.centro_poblado_id = U.centro_poblado_id
        WHERE P.persona_id=@nEntidadId;
    END
    ELSE IF @cEntidad='EMPRESA' AND @nEntidadId IS NOT NULL
    BEGIN
        SELECT
            CONVERT(BIT,1) encontradoLocal,
            @cEntidad entidadObjetivo,
            E.empresa_id entidadId,
            'JURIDICA' tipoPersona,
            'RUC' tipoDocumento,
            RTRIM(E.ruc) numeroDocumento,
            CAST(NULL AS NVARCHAR(100)) nombres,
            CAST(NULL AS NVARCHAR(80)) apellidoPaterno,
            CAST(NULL AS NVARCHAR(80)) apellidoMaterno,
            E.telefono telefono,
            E.correo correo,
            E.razon_social razonSocial,
            CAST(NULL AS DATE) fechaNacimiento,
            CAST(NULL AS VARCHAR(20)) sexo,
            E.ubicacion_id ubicacionId,
            RTRIM(DEP.departamento_codigo) departamentoCodigo,
            DEP.nombre departamentoNombre,
            RTRIM(PR.provincia_codigo) provinciaCodigo,
            PR.nombre provinciaNombre,
            RTRIM(D.distrito_codigo) distritoCodigo,
            D.nombre distritoNombre,
            U.centro_poblado_id centroPobladoId,
            CP.nombre centroPobladoNombre,
            U.referencia referenciaUbicacion,
            E.estado estadoEntidad,
            CONVERT(BIT,0) esEmpleado,
            CONVERT(BIT,0) esSocio,
            @bAsociacion esAsociacion,
            CONVERT(BIT,0) requiereConsultaExterna,
            @cTipoExterno tipoDocumentoConsultaExterna,
            @cDocExterno numeroDocumentoConsultaExterna,
            @cClave claveConsulta,
            @cEstadoPrevio estadoConsultaPrevia,
            @dReintento reintentoDesdeUtc,
            @dBloqueo bloqueoHastaUtc
        FROM [org].[Empresa] E
        LEFT JOIN [geo].[Ubicacion] U
               ON U.ubicacion_id = E.ubicacion_id
        LEFT JOIN [geo].[Distrito] D
               ON D.distrito_codigo = U.distrito_codigo
        LEFT JOIN [geo].[Provincia] PR
               ON PR.provincia_codigo = D.provincia_codigo
        LEFT JOIN [geo].[Departamento] DEP
               ON DEP.departamento_codigo = PR.departamento_codigo
        LEFT JOIN [geo].[CentroPoblado] CP
               ON CP.centro_poblado_id = U.centro_poblado_id
        WHERE E.empresa_id=@nEntidadId;
    END
    ELSE
    BEGIN
        SELECT
            CONVERT(BIT,0) encontradoLocal,
            @cEntidad entidadObjetivo,
            CAST(NULL AS BIGINT) entidadId,
            @cTipoPersona tipoPersona,
            @cTipo tipoDocumento,
            @cDoc numeroDocumento,
            CAST(NULL AS NVARCHAR(100)) nombres,
            CAST(NULL AS NVARCHAR(80)) apellidoPaterno,
            CAST(NULL AS NVARCHAR(80)) apellidoMaterno,
            CAST(NULL AS VARCHAR(30)) telefono,
            CAST(NULL AS VARCHAR(180)) correo,
            CAST(NULL AS NVARCHAR(200)) razonSocial,
            CAST(NULL AS DATE) fechaNacimiento,
            CAST(NULL AS VARCHAR(20)) sexo,
            CAST(NULL AS BIGINT) ubicacionId,
            CAST(NULL AS VARCHAR(2)) departamentoCodigo,
            CAST(NULL AS NVARCHAR(100)) departamentoNombre,
            CAST(NULL AS VARCHAR(4)) provinciaCodigo,
            CAST(NULL AS NVARCHAR(100)) provinciaNombre,
            CAST(NULL AS VARCHAR(6)) distritoCodigo,
            CAST(NULL AS NVARCHAR(100)) distritoNombre,
            CAST(NULL AS BIGINT) centroPobladoId,
            CAST(NULL AS NVARCHAR(150)) centroPobladoNombre,
            CAST(NULL AS NVARCHAR(300)) referenciaUbicacion,
            CAST(NULL AS BIT) estadoEntidad,
            CONVERT(BIT,0) esEmpleado,
            CONVERT(BIT,0) esSocio,
            CONVERT(BIT,0) esAsociacion,
            @bRequiereExterno requiereConsultaExterna,
            @cTipoExterno tipoDocumentoConsultaExterna,
            @cDocExterno numeroDocumentoConsultaExterna,
            @cClave claveConsulta,
            @cEstadoPrevio estadoConsultaPrevia,
            @dReintento reintentoDesdeUtc,
            @dBloqueo bloqueoHastaUtc;
    END;

    SET @bResultado=1;
    SET @cMensaje=CASE WHEN @nEntidadId IS NOT NULL
                       THEN N'La información ya se encuentra registrada.'
                       WHEN @bRequiereExterno=1
                       THEN N'La información no existe localmente y puede validarse automáticamente.'
                       ELSE N'La validación automática no está disponible en este momento. Puede continuar con carga manual.' END;

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
    @cProcedimiento = N'integracion.PA_Identidad_Sel_ResolverDocumento',
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
    @cProcedimiento = N'integracion.PA_Identidad_Sel_ResolverDocumento',
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
FROM config.FN_RespuestaUsuario(N'integracion.PA_Identidad_Sel_ResolverDocumento',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
