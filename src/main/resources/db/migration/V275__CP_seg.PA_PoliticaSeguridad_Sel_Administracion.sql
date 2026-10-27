IF OBJECT_ID(N'[seg].[PA_PoliticaSeguridad_Sel_Administracion]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_PoliticaSeguridad_Sel_Administracion];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_PoliticaSeguridad_Sel_Administracion
' Descripción             : Consulta los parámetros de la política de seguridad para administración.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Seguridad
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
    EXEC [seg].[PA_PoliticaSeguridad_Sel_Administracion]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_PoliticaSeguridad_Sel_Administracion]
(
    @cJson NVARCHAR(MAX),
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET @bResultado=0;
    SET @cMensaje=N'No se pudo consultar la política de seguridad.';
    SET @cCodigoRespuesta=NULL;
    SET @nHttpRespuesta=NULL;

    DECLARE
        @nUsuarioId BIGINT,
        @nSesionUsuarioId BIGINT,
        @nDispositivoUsuarioId BIGINT,
        @nEmpleadoId BIGINT,
        @nModuloId INT,
        @gCorrelacionId UNIQUEIDENTIFIER,
        @gSolicitudId UNIQUEIDENTIFIER,
        @cIp VARCHAR(64),
        @cEndpoint NVARCHAR(250),
        @bContexto BIT,
        @cMensajeContexto NVARCHAR(300);

    BEGIN TRY
        IF @cJson IS NULL OR ISJSON(@cJson) <> 1
        BEGIN
            SET @cMensaje=N'La solicitud no es válida.';
            GOTO Salida;
        END;

        EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
             @cJson=@cJson,
             @cCodigoPermiso='USUARIOS_ADMINISTRAR',
             @nUsuarioId=@nUsuarioId OUTPUT,
             @nSesionUsuarioId=@nSesionUsuarioId OUTPUT,
             @nDispositivoUsuarioId=@nDispositivoUsuarioId OUTPUT,
             @nEmpleadoId=@nEmpleadoId OUTPUT,
             @nModuloId=@nModuloId OUTPUT,
             @gCorrelacionId=@gCorrelacionId OUTPUT,
             @gSolicitudId=@gSolicitudId OUTPUT,
             @cIp=@cIp OUTPUT,
             @cEndpoint=@cEndpoint OUTPUT,
             @bResultado=@bContexto OUTPUT,
             @cMensaje=@cMensajeContexto OUTPUT;

        IF ISNULL(@bContexto,0)=0
        BEGIN
            SET @cMensaje=COALESCE(@cMensajeContexto,N'No tiene autorización para consultar esta configuración.');
            GOTO Salida;
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM [seg].[PoliticaSeguridad]
            WHERE codigo='GENERAL'
              AND estado=1
              AND fecha_hasta IS NULL
              AND fecha_desde<=SYSUTCDATETIME()
        )
        BEGIN
            SET @cMensaje=N'La política de seguridad no está disponible.';
            GOTO Salida;
        END;

        SELECT TOP (1)
            PS.dias_dispositivo_reconocido AS diasDispositivoReconocido
        FROM [seg].[PoliticaSeguridad] PS
        WHERE PS.codigo='GENERAL'
          AND PS.estado=1
          AND PS.fecha_hasta IS NULL
          AND PS.fecha_desde<=SYSUTCDATETIME()
        ORDER BY PS.fecha_desde DESC, PS.politica_seguridad_id DESC;

        SET @bResultado=1;
        SET @cMensaje=N'Política de seguridad consultada.';
    END TRY
    BEGIN CATCH
        SET @bResultado=0;
        EXEC [config].[PA_Respuesta_ResolverError]
             @cProcedimiento=N'seg.PA_PoliticaSeguridad_Sel_Administracion',
             @cMensaje=@cMensaje OUTPUT,
             @cJson=@cJson,
             @bMensajePublicoGenerico=0;
    END CATCH;

Salida:
    SET @bResultado=ISNULL(@bResultado,0);
    SELECT
        @cMensaje=R.mensaje,
        @cCodigoRespuesta=R.codigo,
        @nHttpRespuesta=R.http_sugerido
    FROM config.FN_RespuestaUsuario(
        N'seg.PA_PoliticaSeguridad_Sel_Administracion',
        @bResultado,
        @cMensaje
    ) R;

    IF @bResultado=1 RETURN 0;
    RETURN 1;
END;
GO
