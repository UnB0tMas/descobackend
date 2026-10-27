IF OBJECT_ID(N'[integracion].[PA_Identidad_Ins_ReservarConsultaExterna]', N'P') IS NOT NULL
    DROP PROCEDURE [integracion].[PA_Identidad_Ins_ReservarConsultaExterna];
GO

/******************************************************************************************************
' Nombre del PA           : integracion.PA_Identidad_Ins_ReservarConsultaExterna
' Descripción             : Reserva una consulta externa de identidad identidad documental.
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
    EXEC [integracion].[PA_Identidad_Ins_ReservarConsultaExterna]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [integracion].[PA_Identidad_Ins_ReservarConsultaExterna]
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

    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,
            @gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
            @bCtx BIT,@cMsg NVARCHAR(300);
    DECLARE @cEntidad VARCHAR(10),@cTipo VARCHAR(15),@cDoc VARCHAR(30),
            @cTipoExt VARCHAR(15),@cDocExt VARCHAR(30),@cClave VARCHAR(60),
            @nLocal BIGINT=NULL,@nCoin INT,@bBusca BIT,@cMsgBusca NVARCHAR(300),
            @nConsulta BIGINT=NULL,@cEstado VARCHAR(25)=NULL,@dBloqueo DATETIME2(0)=NULL,
            @dReintento DATETIME2(0)=NULL,@bPuede BIT=0;

    SELECT @bResultado=0,@cMensaje=N'No se pudo reservar la consulta externa.';

    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
         @cJson=@cJson,@cCodigoPermiso='VALIDACIONIDENTIDAD_CONSULTAR',
         @nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,
         @nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,
         @nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,
         @gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,
         @bResultado=@bCtx OUTPUT,@cMensaje=@cMsg OUTPUT;

    IF @bCtx=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;

    SELECT @cEntidad=UPPER(NULLIF(LTRIM(RTRIM(entidadObjetivo)),'')),
           @cTipo=UPPER(NULLIF(LTRIM(RTRIM(tipoDocumento)),'')),
           @cDoc=NULLIF(LTRIM(RTRIM(numeroDocumento)),'')
    FROM OPENJSON(@cJson,'$.consulta')
    WITH(entidadObjetivo VARCHAR(10) '$.entidadObjetivo',tipoDocumento VARCHAR(15) '$.tipoDocumento',numeroDocumento VARCHAR(30) '$.numeroDocumento');

    IF @cEntidad NOT IN('PERSONA','EMPRESA') OR @cTipo NOT IN('DNI','RUC')
       OR [org].[FN_Documento_EsValido](@cTipo,@cDoc)=0
    BEGIN
        SET @cMensaje=N'El documento no es válido para consulta externa.';
        GOTO __DESCO_Salida;
    END;

    IF @cEntidad='EMPRESA'
    BEGIN
        IF @cTipo<>'RUC' OR [org].[FN_Ruc_Naturaleza](@cDoc)<>'JURIDICA'
        BEGIN SET @cMensaje=N'Empresa requiere RUC jurídico válido.';
 GOTO __DESCO_Salida;
 END;

        SELECT @nLocal=empresa_id FROM [org].[Empresa] WHERE ruc=@cDoc;
        SET @cTipoExt='RUC';
 SET @cDocExt=@cDoc;
 SET @cClave='RUC:'+@cDoc;
    END
    ELSE
    BEGIN
        IF @cTipo='RUC' AND [org].[FN_Ruc_Naturaleza](@cDoc)='JURIDICA'
        BEGIN SET @cMensaje=N'El RUC jurídico debe consultarse como EMPRESA.';
 GOTO __DESCO_Salida;
 END;

        EXEC [org].[PA_Persona_Sel_IdPorDocumentoInterno]
             @cTipoDocumento=@cTipo,@cNumeroDocumento=@cDoc,@nExcluirPersonaId=NULL,
             @nPersonaId=@nLocal OUTPUT,@nCoincidencias=@nCoin OUTPUT,
             @bResultado=@bBusca OUTPUT,@cMensaje=@cMsgBusca OUTPUT;
        IF @bBusca=0 BEGIN SET @cMensaje=@cMsgBusca;
 GOTO __DESCO_Salida;
 END;

        IF @cTipo='RUC' AND LEFT(@cDoc,2)='10'
        BEGIN SET @cTipoExt='DNI';
 SET @cDocExt=SUBSTRING(@cDoc,3,8);
 SET @cClave='DNI:'+@cDocExt;
 END
        ELSE IF @cTipo='DNI'
        BEGIN SET @cTipoExt='DNI';
 SET @cDocExt=@cDoc;
 SET @cClave='DNI:'+@cDoc;
 END
        ELSE
        BEGIN SET @cTipoExt='RUC';
 SET @cDocExt=@cDoc;
 SET @cClave='RUC:'+@cDoc;
 END;
    END;

    IF @nLocal IS NOT NULL
    BEGIN
        SELECT CONVERT(BIT,0) puedeConsultar,@cTipoExt tipoDocumentoConsultaExterna,
               @cDocExt numeroDocumentoConsultaExterna,@cClave claveConsulta,
               CAST(NULL AS DATETIME2(0)) reintentoDesdeUtc;
        SET @bResultado=1;
        SET @cMensaje=N'La información ya se encuentra registrada.';
        GOTO __DESCO_Salida;
    END;

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        SELECT @nConsulta=consulta_documento_id,@cEstado=estado_consulta,
               @dBloqueo=bloqueo_hasta_utc,@dReintento=reintento_desde_utc
        FROM [integracion].[ConsultaDocumento] WITH (UPDLOCK,HOLDLOCK)
        WHERE entidad_objetivo=@cEntidad AND clave_documento=@cClave;

        IF @nConsulta IS NULL
        BEGIN
            INSERT [integracion].[ConsultaDocumento]
            (
                entidad_objetivo,clave_documento,tipo_documento_solicitado,
                numero_documento_solicitado,tipo_documento_externo,
                numero_documento_externo,proveedor,estado_consulta,cantidad_intentos,
                fecha_primera_solicitud_utc,fecha_ultimo_intento_utc,
                bloqueo_hasta_utc,reintento_desde_utc,estado
            )
            VALUES
            (
                @cEntidad,@cClave,@cTipo,@cDoc,@cTipoExt,@cDocExt,'FACTILIZA',
                'RESERVADA',1,SYSUTCDATETIME(),SYSUTCDATETIME(),
                DATEADD(SECOND,30,SYSUTCDATETIME()),NULL,1
            );
            SET @bPuede=1;
            SET @dReintento=NULL;
        END
        ELSE IF @cEstado='RESERVADA' AND @dBloqueo>SYSUTCDATETIME()
        BEGIN
            SET @bPuede=0;
            SET @dReintento=@dBloqueo;
        END
        ELSE IF @cEstado IN('ERROR','NO_ENCONTRADO') AND @dReintento>SYSUTCDATETIME()
        BEGIN
            SET @bPuede=0;
        END
        ELSE IF @cEstado='DATOS_INSUFICIENTES'
        BEGIN
            SET @bPuede=0;
            SET @dReintento=NULL;
        END
        ELSE
        BEGIN
            UPDATE [integracion].[ConsultaDocumento]
               SET tipo_documento_solicitado=@cTipo,
                   numero_documento_solicitado=@cDoc,
                   tipo_documento_externo=@cTipoExt,
                   numero_documento_externo=@cDocExt,
                   proveedor='FACTILIZA',
                   estado_consulta='RESERVADA',
                   cantidad_intentos=cantidad_intentos+1,
                   fecha_ultimo_intento_utc=SYSUTCDATETIME(),
                   bloqueo_hasta_utc=DATEADD(SECOND,30,SYSUTCDATETIME()),
                   reintento_desde_utc=NULL,
                   ultimo_codigo_error=NULL,
                   estado=1
             WHERE consulta_documento_id=@nConsulta;
            SET @bPuede=1;
            SET @dReintento=NULL;
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

        IF XACT_STATE()<>0 BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
        SET @cMensaje=N'No se pudo reservar la consulta externa.';
        
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'integracion.PA_Identidad_Ins_ReservarConsultaExterna',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
GOTO __DESCO_Salida;
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'integracion.PA_Identidad_Ins_ReservarConsultaExterna',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;

    SELECT @bPuede puedeConsultar,@cTipoExt tipoDocumentoConsultaExterna,
           @cDocExt numeroDocumentoConsultaExterna,@cClave claveConsulta,
           @dReintento reintentoDesdeUtc;

    SET @bResultado=1;
    SET @cMensaje=CASE WHEN @bPuede=1
                       THEN N'La validación automática fue reservada correctamente.'
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
    @cProcedimiento = N'integracion.PA_Identidad_Ins_ReservarConsultaExterna',
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
    @cProcedimiento = N'integracion.PA_Identidad_Ins_ReservarConsultaExterna',
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
FROM config.FN_RespuestaUsuario(N'integracion.PA_Identidad_Ins_ReservarConsultaExterna',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
