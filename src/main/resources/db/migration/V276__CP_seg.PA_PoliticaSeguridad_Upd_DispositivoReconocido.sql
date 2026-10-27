IF OBJECT_ID(N'[seg].[PA_PoliticaSeguridad_Upd_DispositivoReconocido]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_PoliticaSeguridad_Upd_DispositivoReconocido];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_PoliticaSeguridad_Upd_DispositivoReconocido
' Descripción             : Actualiza la configuración de dispositivos reconocidos.
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
    EXEC [seg].[PA_PoliticaSeguridad_Upd_DispositivoReconocido]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_PoliticaSeguridad_Upd_DispositivoReconocido]
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
    SET XACT_ABORT ON;
    SET @bResultado=0;
    SET @cMensaje=N'No se pudo actualizar la política de seguridad.';
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
        @nOperacionIdempotenteId BIGINT,
        @bEsRepetida BIT,
        @cEstadoOperacion VARCHAR(20),
        @cIdentificadorResultado NVARCHAR(200),
        @cCodigoResultado VARCHAR(40),
        @bInicio BIT,
        @cMensajeInicio NVARCHAR(300),
        @bFin BIT,
        @cMensajeFin NVARCHAR(300),
        @nDias SMALLINT,
        @nDiasAnteriores SMALLINT,
        @nAuditoriaId BIGINT,
        @cAntes NVARCHAR(MAX),
        @cDespues NVARCHAR(MAX),
        @dAhora DATETIME2(0)=SYSUTCDATETIME(),
        @nTranEntrada INT=@@TRANCOUNT,
        @cSavepoint VARCHAR(32)=REPLACE(CONVERT(VARCHAR(36),NEWID()),'-',''),
        @bTranAbierta BIT=0;

    BEGIN TRY
        IF @cJson IS NULL OR ISJSON(@cJson) <> 1
        BEGIN
            SET @cMensaje=N'La solicitud no es válida.';
            GOTO Salida;
        END;

        EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente]
             @cJson=@cJson,
             @cCodigoPermiso='USUARIOS_ADMINISTRAR',
             @cAmbito='POLITICA_SEGURIDAD_DISPOSITIVO',
             @nUsuarioId=@nUsuarioId OUTPUT,
             @nSesionUsuarioId=@nSesionUsuarioId OUTPUT,
             @nDispositivoUsuarioId=@nDispositivoUsuarioId OUTPUT,
             @nEmpleadoId=@nEmpleadoId OUTPUT,
             @nModuloId=@nModuloId OUTPUT,
             @gCorrelacionId=@gCorrelacionId OUTPUT,
             @gSolicitudId=@gSolicitudId OUTPUT,
             @cIp=@cIp OUTPUT,
             @cEndpoint=@cEndpoint OUTPUT,
             @nOperacionIdempotenteId=@nOperacionIdempotenteId OUTPUT,
             @bEsRepetida=@bEsRepetida OUTPUT,
             @cEstadoOperacion=@cEstadoOperacion OUTPUT,
             @cIdentificadorResultado=@cIdentificadorResultado OUTPUT,
             @cCodigoResultado=@cCodigoResultado OUTPUT,
             @bResultado=@bInicio OUTPUT,
             @cMensaje=@cMensajeInicio OUTPUT;

        IF ISNULL(@bInicio,0)=0 AND ISNULL(@bEsRepetida,0)=0
        BEGIN
            SET @cMensaje=@cMensajeInicio;
            GOTO Salida;
        END;

        IF ISNULL(@bEsRepetida,0)=1
        BEGIN
            SET @bResultado=CASE WHEN @cEstadoOperacion='COMPLETADA' THEN 1 ELSE 0 END;
            SET @cMensaje=CASE
                WHEN @cEstadoOperacion='COMPLETADA' THEN N'La solicitud ya fue procesada correctamente.'
                ELSE N'La solicitud ya se encuentra en proceso.'
            END;
            GOTO Salida;
        END;

        SELECT @nDias=diasDispositivoReconocido
        FROM OPENJSON(@cJson)
        WITH (diasDispositivoReconocido SMALLINT '$.diasDispositivoReconocido');

        IF @nDias IS NULL OR @nDias<1 OR @nDias>365
        BEGIN
            SET @cMensaje=N'La vigencia debe estar entre 1 y 365 días.';
            GOTO Fallar;
        END;

        IF @nTranEntrada=0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION @cSavepoint;
        SET @bTranAbierta=1;

        SELECT TOP (1)
            @nDiasAnteriores=PS.dias_dispositivo_reconocido
        FROM [seg].[PoliticaSeguridad] PS WITH (UPDLOCK,HOLDLOCK)
        WHERE PS.codigo='GENERAL'
          AND PS.estado=1
          AND PS.fecha_hasta IS NULL
          AND PS.fecha_desde<=@dAhora
        ORDER BY PS.fecha_desde DESC, PS.politica_seguridad_id DESC;

        IF @nDiasAnteriores IS NULL
            THROW 51020,N'POLITICA_SEGURIDAD_NO_DISPONIBLE',1;

        UPDATE [seg].[PoliticaSeguridad]
        SET dias_dispositivo_reconocido=@nDias
        WHERE codigo='GENERAL'
          AND estado=1
          AND fecha_hasta IS NULL
          AND fecha_desde<=@dAhora;

        /* El historial del dispositivo se conserva; solo caduca la confianza. */
        UPDATE D
        SET
            D.es_reconocido=0,
            D.fecha_retiro_reconocimiento=COALESCE(D.fecha_retiro_reconocimiento,@dAhora)
        FROM [seg].[DispositivoUsuario] D
        WHERE D.estado=1
          AND D.es_reconocido=1
          AND D.fecha_reconocimiento IS NOT NULL
          AND DATEADD(DAY,@nDias,D.fecha_reconocimiento)<=@dAhora;

        SELECT @cAntes=(SELECT @nDiasAnteriores AS diasDispositivoReconocido FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
        SELECT @cDespues=(SELECT @nDias AS diasDispositivoReconocido FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);

        EXEC [auditoria].[PA_Auditoria_Ins_Evento]
             @nUsuarioId=@nUsuarioId,
             @nSesionUsuarioId=@nSesionUsuarioId,
             @nDispositivoUsuarioId=@nDispositivoUsuarioId,
             @nModuloId=@nModuloId,
             @cAccion='EDITAR',
             @cEsquemaEntidad=N'seg',
             @cNombreEntidad=N'PoliticaSeguridad',
             @cIdentificador=N'GENERAL',
             @cDatosAnteriores=@cAntes,
             @cDatosPosteriores=@cDespues,
             @cMotivo=N'Actualización de vigencia de dispositivos reconocidos.',
             @cIp=@cIp,
             @cResultado='EXITOSO',
             @gCorrelacionId=@gCorrelacionId,
             @gSolicitudId=@gSolicitudId,
             @cEndpoint=@cEndpoint,
             @nAuditoriaEventoId=@nAuditoriaId OUTPUT;

        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
             @nOperacionIdempotenteId=@nOperacionIdempotenteId,
             @cEstadoOperacion='COMPLETADA',
             @cEsquemaEntidad='seg',
             @cNombreEntidad='PoliticaSeguridad',
             @cIdentificadorResultado='GENERAL',
             @cCodigoResultado='POLITICA_SEGURIDAD_ACTUALIZADA',
             @bResultado=@bFin OUTPUT,
             @cMensaje=@cMensajeFin OUTPUT;

        IF ISNULL(@bFin,0)=0
            THROW 51003,N'DESCO_IDEMPOTENCIA_NO_CERRADA',1;

        IF @bTranAbierta=1 AND @nTranEntrada=0 COMMIT TRANSACTION;
        SET @bTranAbierta=0;

        SET @bResultado=1;
        SET @cMensaje=N'Política de seguridad actualizada.';
        GOTO Salida;

Fallar:
        IF @nOperacionIdempotenteId IS NOT NULL
        BEGIN
            EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
                 @nOperacionIdempotenteId=@nOperacionIdempotenteId,
                 @cEstadoOperacion='FALLIDA',
                 @cEsquemaEntidad=NULL,
                 @cNombreEntidad=NULL,
                 @cIdentificadorResultado=NULL,
                 @cCodigoResultado='NO_PROCESADO',
                 @bResultado=@bFin OUTPUT,
                 @cMensaje=@cMensajeFin OUTPUT;
        END;
    END TRY
    BEGIN CATCH
        IF @bTranAbierta=1 AND XACT_STATE()<>0
        BEGIN
            IF @nTranEntrada=0 ROLLBACK TRANSACTION;
            ELSE IF XACT_STATE()=1 ROLLBACK TRANSACTION @cSavepoint;
        END;
        SET @bTranAbierta=0;
        SET @bResultado=0;

        IF @nOperacionIdempotenteId IS NOT NULL AND ISNULL(@bEsRepetida,0)=0 AND XACT_STATE()<>-1
        BEGIN TRY
            EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
                 @nOperacionIdempotenteId=@nOperacionIdempotenteId,
                 @cEstadoOperacion='FALLIDA',
                 @cEsquemaEntidad=NULL,
                 @cNombreEntidad=NULL,
                 @cIdentificadorResultado=NULL,
                 @cCodigoResultado='NO_PROCESADO',
                 @bResultado=@bFin OUTPUT,
                 @cMensaje=@cMensajeFin OUTPUT;
        END TRY
        BEGIN CATCH
        END CATCH;

        EXEC [config].[PA_Respuesta_ResolverError]
             @cProcedimiento=N'seg.PA_PoliticaSeguridad_Upd_DispositivoReconocido',
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
        N'seg.PA_PoliticaSeguridad_Upd_DispositivoReconocido',
        @bResultado,
        @cMensaje
    ) R;

    IF @bResultado=1 RETURN 0;
    RETURN 1;
END;
GO
