IF OBJECT_ID(N'[integracion].[PA_Identidad_Upd_ResultadoConsultaExterna]', N'P') IS NOT NULL
    DROP PROCEDURE [integracion].[PA_Identidad_Upd_ResultadoConsultaExterna];
GO

/******************************************************************************************************
' Nombre del PA           : integracion.PA_Identidad_Upd_ResultadoConsultaExterna
' Descripción             : Actualiza el resultado de una consulta externa de identidad.
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
    EXEC [integracion].[PA_Identidad_Upd_ResultadoConsultaExterna]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [integracion].[PA_Identidad_Upd_ResultadoConsultaExterna]
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
        @nUsuario BIGINT,
        @nSesion BIGINT,
        @nDisp BIGINT,
        @nEmp BIGINT,
        @nModulo INT,
        @gCorr UNIQUEIDENTIFIER,
        @gSol UNIQUEIDENTIFIER,
        @cIp VARCHAR(64),
        @cEnd NVARCHAR(250),
        @bCtx BIT,
        @cMsg NVARCHAR(300),
        @nAud BIGINT,
        @nTrans BIGINT;

    DECLARE
        @cEntidad VARCHAR(10),
        @cTipo VARCHAR(15),
        @cDoc VARCHAR(30),
        @cTipoExt VARCHAR(15),
        @cDocExt VARCHAR(30),
        @cClave VARCHAR(60),
        @bExito BIT = 0,
        @bEncontrado BIT = 0,
        @cCodigoError VARCHAR(60),
        @cDatosJson NVARCHAR(MAX),
        @cNombres NVARCHAR(100),
        @cAP NVARCHAR(80),
        @cAM NVARCHAR(80),
        @dNac DATE,
        @cRazon NVARCHAR(200),
        @cDireccion NVARCHAR(300),
        @cDireccionCompleta NVARCHAR(300),
        @cSexo VARCHAR(20),
        @cDepartamento NVARCHAR(100),
        @cProvincia NVARCHAR(100),
        @cDistrito NVARCHAR(100),
        @cDepartamentoCodigo CHAR(2),
        @cProvinciaCodigo CHAR(4),
        @cDistritoCodigo CHAR(6),
        @cCentroPoblado NVARCHAR(150),
        @cCentroPobladoCodigo VARCHAR(20),
        @cTipoContribuyente NVARCHAR(120),
        @cEstadoContribuyente VARCHAR(50),
        @cCondicionContribuyente VARCHAR(50),
        @nEntidadId BIGINT = NULL,
        @nCoin INT,
        @bBusca BIT,
        @cMsgBusca NVARCHAR(300),
        @cIdent NVARCHAR(200),
        @cAccion VARCHAR(20),
        @cPosterior NVARCHAR(MAX),
        @cNombreEntidadAuditoria SYSNAME,
        @bInsertado BIT = 0,
        @nUbicacionId BIGINT = NULL,
        @nCentroPobladoId BIGINT = NULL,
        @bGeo BIT = 0,
        @cMsgGeo NVARCHAR(300),
        @bTieneGeografiaCompleta BIT = 0;

    SELECT
        @bResultado = 0,
        @cMensaje = N'No fue posible completar la validación.';

    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
         @cJson = @cJson,
         @cCodigoPermiso = 'VALIDACIONIDENTIDAD_IMPORTAR',
         @nUsuarioId = @nUsuario OUTPUT,
         @nSesionUsuarioId = @nSesion OUTPUT,
         @nDispositivoUsuarioId = @nDisp OUTPUT,
         @nEmpleadoId = @nEmp OUTPUT,
         @nModuloId = @nModulo OUTPUT,
         @gCorrelacionId = @gCorr OUTPUT,
         @gSolicitudId = @gSol OUTPUT,
         @cIp = @cIp OUTPUT,
         @cEndpoint = @cEnd OUTPUT,
         @bResultado = @bCtx OUTPUT,
         @cMensaje = @cMsg OUTPUT;

    IF @bCtx = 0
    BEGIN
        SET @cMensaje = N'No tiene acceso a esta opción.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @cEntidad =
            UPPER(NULLIF(LTRIM(RTRIM(entidadObjetivo)), '')),
        @cTipo =
            UPPER(NULLIF(LTRIM(RTRIM(tipoDocumento)), '')),
        @cDoc =
            NULLIF(LTRIM(RTRIM(numeroDocumento)), '')
    FROM OPENJSON(@cJson, '$.consulta')
    WITH
    (
        entidadObjetivo VARCHAR(10) '$.entidadObjetivo',
        tipoDocumento VARCHAR(15) '$.tipoDocumento',
        numeroDocumento VARCHAR(30) '$.numeroDocumento'
    );

    SELECT
        @bExito = ISNULL(exito, 0),
        @bEncontrado = ISNULL(encontrado, 0),
        @cCodigoError =
            NULLIF(LTRIM(RTRIM(codigoError)), '')
    FROM OPENJSON(@cJson, '$.resultado')
    WITH
    (
        exito BIT '$.exito',
        encontrado BIT '$.encontrado',
        codigoError VARCHAR(60) '$.codigoError'
    );

    /*
     * Compatibilidad con ambos payloads:
     *   $.datos
     *   $.resultado.datos
     */
    SET @cDatosJson =
        COALESCE
        (
            JSON_QUERY(@cJson, '$.datos'),
            JSON_QUERY(@cJson, '$.resultado.datos')
        );

    SELECT
        @cNombres =
            NULLIF(LTRIM(RTRIM(nombres)), N''),
        @cAP =
            NULLIF(LTRIM(RTRIM(apellidoPaterno)), N''),
        @cAM =
            NULLIF(LTRIM(RTRIM(apellidoMaterno)), N''),
        @dNac =
            fechaNacimiento,
        @cRazon =
            NULLIF(LTRIM(RTRIM(razonSocial)), N''),
        @cDireccion =
            NULLIF(LTRIM(RTRIM(direccionFiscal)), N''),
        @cDireccionCompleta =
            NULLIF(LTRIM(RTRIM(direccionCompleta)), N''),
        @cSexo =
            UPPER(NULLIF(LTRIM(RTRIM(sexo)), '')),
        @cDepartamento =
            UPPER(NULLIF(LTRIM(RTRIM(departamento)), N'')),
        @cProvincia =
            UPPER(NULLIF(LTRIM(RTRIM(provincia)), N'')),
        @cDistrito =
            UPPER(NULLIF(LTRIM(RTRIM(distrito)), N'')),
        @cDepartamentoCodigo =
            NULLIF(LTRIM(RTRIM(departamentoCodigo)), ''),
        @cProvinciaCodigo =
            NULLIF(LTRIM(RTRIM(provinciaCodigo)), ''),
        @cDistritoCodigo =
            NULLIF(LTRIM(RTRIM(distritoCodigo)), ''),
        @cCentroPoblado =
            UPPER(NULLIF(LTRIM(RTRIM(centroPoblado)), N'')),
        @cCentroPobladoCodigo =
            UPPER(NULLIF(LTRIM(RTRIM(centroPobladoCodigo)), '')),
        @cTipoContribuyente =
            UPPER(NULLIF(LTRIM(RTRIM(tipoContribuyente)), N'')),
        @cEstadoContribuyente =
            UPPER(NULLIF(LTRIM(RTRIM(estadoContribuyente)), '')),
        @cCondicionContribuyente =
            UPPER(NULLIF(LTRIM(RTRIM(condicionContribuyente)), ''))
    FROM OPENJSON(@cDatosJson)
    WITH
    (
        nombres NVARCHAR(100) '$.nombres',
        apellidoPaterno NVARCHAR(80) '$.apellidoPaterno',
        apellidoMaterno NVARCHAR(80) '$.apellidoMaterno',
        fechaNacimiento DATE '$.fechaNacimiento',
        razonSocial NVARCHAR(200) '$.razonSocial',
        direccionFiscal NVARCHAR(300) '$.direccionFiscal',
        direccionCompleta NVARCHAR(300) '$.direccionCompleta',
        sexo VARCHAR(20) '$.sexo',
        departamento NVARCHAR(100) '$.departamento',
        provincia NVARCHAR(100) '$.provincia',
        distrito NVARCHAR(100) '$.distrito',
        departamentoCodigo VARCHAR(2) '$.departamentoCodigo',
        provinciaCodigo VARCHAR(4) '$.provinciaCodigo',
        distritoCodigo VARCHAR(6) '$.distritoCodigo',
        centroPoblado NVARCHAR(150) '$.centroPoblado',
        centroPobladoCodigo VARCHAR(20) '$.centroPobladoCodigo',
        tipoContribuyente NVARCHAR(120) '$.tipoContribuyente',
        estadoContribuyente VARCHAR(50) '$.estadoContribuyente',
        condicionContribuyente VARCHAR(50) '$.condicionContribuyente'
    );

    /*
     * La fecha de nacimiento no es requisito mínimo.
     * Si el proveedor entrega una fecha futura o inconsistente, se ignora
     * y el usuario podrá completarla posteriormente.
     */
    IF @dNac > CONVERT(DATE, SYSUTCDATETIME())
    BEGIN
        SET @dNac = NULL;
    END;

    SET @cDireccion =
        LEFT(
            COALESCE(
                @cDireccion,
                @cDireccionCompleta
            ),
            300
        );

    IF @cDistritoCodigo IS NOT NULL
       AND LEN(@cDistritoCodigo) = 6
       AND @cDistritoCodigo NOT LIKE '%[^0-9]%'
    BEGIN
        IF @cProvinciaCodigo IS NULL
           OR LEFT(@cDistritoCodigo, 4) <> @cProvinciaCodigo
        BEGIN
            SET @cProvinciaCodigo =
                LEFT(@cDistritoCodigo, 4);
        END;

        IF @cDepartamentoCodigo IS NULL
           OR LEFT(@cDistritoCodigo, 2) <> @cDepartamentoCodigo
        BEGIN
            SET @cDepartamentoCodigo =
                LEFT(@cDistritoCodigo, 2);
        END;
    END;

    SET @bTieneGeografiaCompleta =
        CASE
            WHEN @cDepartamentoCodigo IS NOT NULL
             AND @cProvinciaCodigo IS NOT NULL
             AND @cDistritoCodigo IS NOT NULL
             AND @cDepartamento IS NOT NULL
             AND @cProvincia IS NOT NULL
             AND @cDistrito IS NOT NULL
            THEN 1
            ELSE 0
        END;

    IF @cEntidad NOT IN ('PERSONA', 'EMPRESA')
       OR @cTipo NOT IN ('DNI', 'RUC')
       OR [org].[FN_Documento_EsValido]
          (
              @cTipo,
              @cDoc
          ) = 0
    BEGIN
        SET @cMensaje =
            N'El documento ingresado no es válido.';
        GOTO __DESCO_Salida;
    END;

    IF @cEntidad = 'EMPRESA'
    BEGIN
        IF @cTipo <> 'RUC'
           OR [org].[FN_Ruc_Naturaleza](@cDoc) <> 'JURIDICA'
        BEGIN
            SET @cMensaje =
                N'El documento ingresado no corresponde a una empresa.';
            GOTO __DESCO_Salida;
        END;

        SET @cTipoExt = 'RUC';
        SET @cDocExt = @cDoc;
        SET @cClave = 'RUC:' + @cDoc;
    END
    ELSE
    BEGIN
        IF @cTipo = 'RUC'
           AND [org].[FN_Ruc_Naturaleza](@cDoc) = 'JURIDICA'
        BEGIN
            SET @cMensaje =
                N'El documento ingresado corresponde a una empresa.';
            GOTO __DESCO_Salida;
        END;

        IF @cTipo = 'RUC'
           AND LEFT(@cDoc, 2) = '10'
        BEGIN
            SET @cTipoExt = 'DNI';
            SET @cDocExt = SUBSTRING(@cDoc, 3, 8);
            SET @cClave = 'DNI:' + @cDocExt;
        END
        ELSE IF @cTipo = 'DNI'
        BEGIN
            SET @cTipoExt = 'DNI';
            SET @cDocExt = @cDoc;
            SET @cClave = 'DNI:' + @cDoc;
        END
        ELSE
        BEGIN
            SET @cTipoExt = 'RUC';
            SET @cDocExt = @cDoc;
            SET @cClave = 'RUC:' + @cDoc;
        END;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [integracion].[ConsultaDocumento]
        WHERE entidad_objetivo = @cEntidad
          AND clave_documento = @cClave
          AND estado = 1
    )
    BEGIN
        SET @cMensaje =
            N'No fue posible completar la validación. Intente nuevamente.';
        GOTO __DESCO_Salida;
    END;

    /*
     * Fallo técnico del proveedor:
     * no insertar entidad parcial.
     * La respuesta HTTP al usuario seguirá siendo funcional y genérica.
     */
    IF @bExito = 0
    BEGIN
        UPDATE [integracion].[ConsultaDocumento]
           SET proveedor = 'FACTILIZA',
               estado_consulta = 'ERROR',
               bloqueo_hasta_utc = NULL,
               reintento_desde_utc =
                    DATEADD(
                        SECOND,
                        60,
                        SYSUTCDATETIME()
                    ),
               ultimo_codigo_error =
                    COALESCE(
                        @cCodigoError,
                        'ERROR_PROVEEDOR'
                    ),
               fecha_ultimo_intento_utc =
                    SYSUTCDATETIME()
         WHERE entidad_objetivo = @cEntidad
           AND clave_documento = @cClave;

        SELECT
            CONVERT(BIT, 0) insertado,
            CONVERT(BIT, 1) permiteCargaManual,
            CAST(NULL AS BIGINT) entidadId,
            'ERROR' estadoConsulta;

        SET @bResultado = 1;
        SET @cMensaje =
            N'No fue posible completar todos los datos automáticamente. Puede continuar con carga manual.';
        GOTO __DESCO_Salida;
    END;

    IF @bEncontrado = 0
    BEGIN
        UPDATE [integracion].[ConsultaDocumento]
           SET proveedor = 'FACTILIZA',
               estado_consulta = 'NO_ENCONTRADO',
               bloqueo_hasta_utc = NULL,
               reintento_desde_utc =
                    DATEADD(
                        MINUTE,
                        15,
                        SYSUTCDATETIME()
                    ),
               ultimo_codigo_error =
                    COALESCE(
                        @cCodigoError,
                        'NO_ENCONTRADO'
                    ),
               fecha_ultimo_intento_utc =
                    SYSUTCDATETIME()
         WHERE entidad_objetivo = @cEntidad
           AND clave_documento = @cClave;

        SELECT
            CONVERT(BIT, 0) insertado,
            CONVERT(BIT, 1) permiteCargaManual,
            CAST(NULL AS BIGINT) entidadId,
            'NO_ENCONTRADO' estadoConsulta;

        SET @bResultado = 1;
        SET @cMensaje =
            N'No se encontraron datos para completar el registro. Puede ingresar la información manualmente.';
        GOTO __DESCO_Salida;
    END;

    /*
     * Mínimos:
     * PERSONA: nombres + apellido paterno.
     * EMPRESA: razón social.
     *
     * Todo lo demás es opcional y puede completarse manualmente luego.
     */
    IF (@cEntidad = 'PERSONA'
        AND (@cNombres IS NULL OR @cAP IS NULL))
       OR (@cEntidad = 'EMPRESA'
           AND @cRazon IS NULL)
    BEGIN
        UPDATE [integracion].[ConsultaDocumento]
           SET proveedor = 'FACTILIZA',
               estado_consulta = 'DATOS_INSUFICIENTES',
               bloqueo_hasta_utc = NULL,
               reintento_desde_utc = NULL,
               ultimo_codigo_error =
                    'DATOS_INSUFICIENTES',
               fecha_ultimo_intento_utc =
                    SYSUTCDATETIME()
         WHERE entidad_objetivo = @cEntidad
           AND clave_documento = @cClave;

        SELECT
            CONVERT(BIT, 0) insertado,
            CONVERT(BIT, 1) permiteCargaManual,
            CAST(NULL AS BIGINT) entidadId,
            'DATOS_INSUFICIENTES' estadoConsulta;

        SET @bResultado = 1;
        SET @cMensaje =
            N'No fue posible completar todos los datos automáticamente. Puede continuar con carga manual.';
        GOTO __DESCO_Salida;
    END;

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        /*
         * La entidad se vuelve a buscar dentro de la transacción para cubrir
         * carreras entre solicitudes concurrentes.
         */
        IF @cEntidad = 'PERSONA'
        BEGIN
            EXEC [org].[PA_Persona_Sel_IdPorDocumentoInterno]
                 @cTipoDocumento = @cTipo,
                 @cNumeroDocumento = @cDoc,
                 @nExcluirPersonaId = NULL,
                 @nPersonaId = @nEntidadId OUTPUT,
                 @nCoincidencias = @nCoin OUTPUT,
                 @bResultado = @bBusca OUTPUT,
                 @cMensaje = @cMsgBusca OUTPUT;

            IF @bBusca = 0
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
                SET @cMensaje =
                    N'No fue posible completar la validación. Intente nuevamente.';
                GOTO __DESCO_Salida;
            END;

            IF @nEntidadId IS NULL
            BEGIN
                /*
                 * La ubicación es enriquecimiento opcional.
                 * Si la geografía no puede normalizarse de forma segura, la
                 * Persona se inserta sin ubicación y podrá completarse manualmente.
                 */
                IF @bTieneGeografiaCompleta = 1
                BEGIN
                    EXEC [geo].[PA_Catalogo_Ins_AsegurarUbigeoFactilizaInterno]
                         @cDepartamentoCodigo = @cDepartamentoCodigo,
                         @cDepartamentoNombre = @cDepartamento,
                         @cProvinciaCodigo = @cProvinciaCodigo,
                         @cProvinciaNombre = @cProvincia,
                         @cDistritoCodigo = @cDistritoCodigo,
                         @cDistritoNombre = @cDistrito,
                         @cCentroPobladoNombre = @cCentroPoblado,
                         @cCentroPobladoCodigo = @cCentroPobladoCodigo,
                         @nCentroPobladoId = @nCentroPobladoId OUTPUT,
                         @bResultado = @bGeo OUTPUT,
                         @cMensaje = @cMsgGeo OUTPUT;

                    IF @bGeo = 1
                    BEGIN
                        INSERT INTO [geo].[Ubicacion]
                        (
                            distrito_codigo,
                            centro_poblado_id,
                            referencia,
                            posicion,
                            altitud_m,
                            estado
                        )
                        VALUES
                        (
                            @cDistritoCodigo,
                            @nCentroPobladoId,
                            @cDireccion,
                            NULL,
                            NULL,
                            1
                        );

                        SET @nUbicacionId =
                            CONVERT(
                                BIGINT,
                                SCOPE_IDENTITY()
                            );
                    END;
                END;

                INSERT INTO [org].[Persona]
                (
                    tipo_persona,
                    tipo_documento,
                    numero_documento,
                    nombres,
                    apellido_paterno,
                    apellido_materno,
                    telefono,
                    correo,
                    fecha_nacimiento,
                    ubicacion_id,
                    estado,
                    fecha_creacion,
                    sexo
                )
                VALUES
                (
                    'NATURAL',
                    @cTipo,
                    @cDoc,
                    @cNombres,
                    @cAP,
                    @cAM,
                    NULL,
                    NULL,
                    @dNac,
                    @nUbicacionId,
                    1,
                    SYSUTCDATETIME(),
                    @cSexo
                );

                SET @nEntidadId =
                    CONVERT(
                        BIGINT,
                        SCOPE_IDENTITY()
                    );

                SET @bInsertado = 1;
            END;
        END
        ELSE
        BEGIN
            SELECT
                @nEntidadId = empresa_id
            FROM [org].[Empresa]
                 WITH (UPDLOCK, HOLDLOCK)
            WHERE ruc = @cDoc;

            IF @nEntidadId IS NULL
            BEGIN
                IF @bTieneGeografiaCompleta = 1
                BEGIN
                    EXEC [geo].[PA_Catalogo_Ins_AsegurarUbigeoFactilizaInterno]
                         @cDepartamentoCodigo = @cDepartamentoCodigo,
                         @cDepartamentoNombre = @cDepartamento,
                         @cProvinciaCodigo = @cProvinciaCodigo,
                         @cProvinciaNombre = @cProvincia,
                         @cDistritoCodigo = @cDistritoCodigo,
                         @cDistritoNombre = @cDistrito,
                         @cCentroPobladoNombre = @cCentroPoblado,
                         @cCentroPobladoCodigo = @cCentroPobladoCodigo,
                         @nCentroPobladoId = @nCentroPobladoId OUTPUT,
                         @bResultado = @bGeo OUTPUT,
                         @cMensaje = @cMsgGeo OUTPUT;

                    IF @bGeo = 1
                    BEGIN
                        INSERT INTO [geo].[Ubicacion]
                        (
                            distrito_codigo,
                            centro_poblado_id,
                            referencia,
                            posicion,
                            altitud_m,
                            estado
                        )
                        VALUES
                        (
                            @cDistritoCodigo,
                            @nCentroPobladoId,
                            @cDireccion,
                            NULL,
                            NULL,
                            1
                        );

                        SET @nUbicacionId =
                            CONVERT(
                                BIGINT,
                                SCOPE_IDENTITY()
                            );
                    END;
                END;

                INSERT INTO [org].[Empresa]
                (
                    ruc,
                    razon_social,
                    nombre_comercial,
                    telefono,
                    correo,
                    ubicacion_id,
                    fecha_creacion,
                    estado,
                    tipo_contribuyente,
                    estado_sunat,
                    condicion_sunat
                )
                VALUES
                (
                    @cDoc,
                    @cRazon,
                    NULL,
                    NULL,
                    NULL,
                    @nUbicacionId,
                    SYSUTCDATETIME(),
                    1,
                    @cTipoContribuyente,
                    @cEstadoContribuyente,
                    @cCondicionContribuyente
                );

                SET @nEntidadId =
                    CONVERT(
                        BIGINT,
                        SCOPE_IDENTITY()
                    );

                SET @bInsertado = 1;
            END;
        END;

        UPDATE [integracion].[ConsultaDocumento]
           SET proveedor = 'FACTILIZA',
               estado_consulta = 'EXITO',
               bloqueo_hasta_utc = NULL,
               reintento_desde_utc = NULL,
               fecha_ultimo_exito_utc =
                    SYSUTCDATETIME(),
               ultimo_codigo_error = NULL,
               fecha_ultimo_intento_utc =
                    SYSUTCDATETIME()
         WHERE entidad_objetivo = @cEntidad
           AND clave_documento = @cClave;

        IF @bInsertado = 1
        BEGIN
            SET @cIdent =
                CONVERT(
                    NVARCHAR(200),
                    @nEntidadId
                );

            SET @cAccion = 'CREAR';

            SET @cNombreEntidadAuditoria =
                CASE
                    WHEN @cEntidad = 'PERSONA'
                    THEN N'Persona'
                    ELSE N'Empresa'
                END;

            SELECT @cPosterior =
            (
                SELECT
                    @cEntidad AS entidadObjetivo,
                    @cTipo AS tipoDocumento,
                    @cDoc AS numeroDocumento,
                    'FACTILIZA' AS proveedor,
                    @nUbicacionId AS ubicacionId,
                    @cDistritoCodigo AS distritoCodigo,
                    @dNac AS fechaNacimiento
                FOR JSON PATH,
                    WITHOUT_ARRAY_WRAPPER
            );

            EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio]
                 @nUsuario,
                 @nSesion,
                 @nDisp,
                 @nModulo,
                 @cAccion,
                 'org',
                 @cNombreEntidadAuditoria,
                 @cIdent,
                 NULL,
                 @cPosterior,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 @cIp,
                 @gCorr,
                 @gSol,
                 @cEnd,
                 @nAud OUTPUT,
                 @nTrans OUTPUT;
        END;

        BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;
    END TRY
    BEGIN CATCH
SET @bResultado = 0;

        IF XACT_STATE() <> 0
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
        END;

        UPDATE [integracion].[ConsultaDocumento]
           SET proveedor = 'FACTILIZA',
               estado_consulta = 'ERROR',
               bloqueo_hasta_utc = NULL,
               reintento_desde_utc =
                    DATEADD(
                        SECOND,
                        60,
                        SYSUTCDATETIME()
                    ),
               ultimo_codigo_error =
                    'ERROR_PERSISTENCIA',
               fecha_ultimo_intento_utc =
                    SYSUTCDATETIME()
         WHERE entidad_objetivo = @cEntidad
           AND clave_documento = @cClave;

        SET @cMensaje =
            N'No fue posible completar la validación. Intente nuevamente.';
        
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'integracion.PA_Identidad_Upd_ResultadoConsultaExterna',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
GOTO __DESCO_Salida;
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'integracion.PA_Identidad_Upd_ResultadoConsultaExterna',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;

    SELECT
        @bInsertado AS insertado,
        CONVERT(BIT, 0) AS permiteCargaManual,
        @nEntidadId AS entidadId,
        'EXITO' AS estadoConsulta;

    SET @bResultado = 1;

    SET @cMensaje =
        CASE
            WHEN @bInsertado = 1
            THEN N'Los datos disponibles fueron validados y guardados correctamente.'
            ELSE N'La información ya se encuentra registrada.'
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
    @cProcedimiento = N'integracion.PA_Identidad_Upd_ResultadoConsultaExterna',
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
    @cProcedimiento = N'integracion.PA_Identidad_Upd_ResultadoConsultaExterna',
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
FROM config.FN_RespuestaUsuario(N'integracion.PA_Identidad_Upd_ResultadoConsultaExterna',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
