IF OBJECT_ID(N'[seg].[PA_UsuarioAdmin_Sel_Detalle]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_UsuarioAdmin_Sel_Detalle];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_UsuarioAdmin_Sel_Detalle
' Descripción             : Consulta el detalle de una cuenta de usuario desde administración.
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
    EXEC [seg].[PA_UsuarioAdmin_Sel_Detalle]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_UsuarioAdmin_Sel_Detalle](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS BEGIN
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
DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bCtx BIT,@cMsg NVARCHAR(300);
SELECT @bResultado=0,@cMensaje=N'No se pudo consultar el usuario.';
EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='USUARIOS_VER',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@bResultado=@bCtx OUTPUT,@cMensaje=@cMsg OUTPUT;
IF @bCtx=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;
 DECLARE @nId BIGINT;
SELECT @nId=COALESCE(TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.usuario.usuarioId')),TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.usuarioId')),TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.usuarioId')));
IF NOT EXISTS(SELECT 1 FROM seg.Usuario WHERE usuario_id=@nId) BEGIN SET @cMensaje=N'El usuario seleccionado no está disponible.';
GOTO __DESCO_Salida;
END;
SELECT U.usuario_id usuarioId,U.nombre_usuario nombreUsuario,U.estado_cuenta estadoCuenta,U.estado,U.fecha_creacion fechaCreacion,U.ultimo_acceso_correcto ultimoAccesoCorrecto,U.fecha_cambio_password fechaCambioPassword,U.requiere_cambio_password requiereCambioPassword,U.segundo_factor_habilitado segundoFactorHabilitado,E.empleado_id empleadoId,P.numero_documento numeroDocumento,CONCAT(P.nombres,N' ',P.apellido_paterno,N' ',COALESCE(P.apellido_materno,N'')) empleado FROM seg.Usuario U INNER JOIN org.Empleado E ON E.empleado_id=U.persona_id INNER JOIN org.Persona P ON P.persona_id=U.persona_id WHERE U.usuario_id=@nId;
SELECT R.rol_id rolId,R.codigo,R.nombre,UR.fecha_desde fechaDesde,UR.fecha_hasta fechaHasta,UR.estado FROM seg.UsuarioRol UR INNER JOIN seg.Rol R ON R.rol_id=UR.rol_id WHERE UR.usuario_id=@nId ORDER BY UR.fecha_desde DESC;
SELECT D.dispositivo_usuario_id dispositivoUsuarioId,D.navegador,D.sistema_operativo sistemaOperativo,D.fecha_primera_deteccion primeraDeteccion,D.fecha_ultima_actividad ultimaActividad,D.es_reconocido esReconocido,D.fecha_reconocimiento fechaReconocimiento,D.fecha_retiro_reconocimiento fechaRetiroReconocimiento,D.estado FROM seg.DispositivoUsuario D WHERE D.usuario_id=@nId ORDER BY D.fecha_ultima_actividad DESC;
SET @bResultado=1;
SET @cMensaje=N'Usuario consultado correctamente.';
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
    @cProcedimiento = N'seg.PA_UsuarioAdmin_Sel_Detalle',
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
    @cProcedimiento = N'seg.PA_UsuarioAdmin_Sel_Detalle',
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
FROM config.FN_RespuestaUsuario(N'seg.PA_UsuarioAdmin_Sel_Detalle',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
