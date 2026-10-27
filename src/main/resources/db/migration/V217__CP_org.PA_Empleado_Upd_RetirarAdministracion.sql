IF OBJECT_ID(N'[org].[PA_Empleado_Upd_RetirarAdministracion]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_Empleado_Upd_RetirarAdministracion];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_Empleado_Upd_RetirarAdministracion
' Descripción             : Retira un empleado desde la administración.
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
    EXEC [org].[PA_Empleado_Upd_RetirarAdministracion]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [org].[PA_Empleado_Upd_RetirarAdministracion]
    @cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @bResultado=0; SET @cMensaje=N'No se pudo retirar al empleado.'; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmpSesion BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),@nAud BIGINT,@nTrans BIGINT,
            @nId BIGINT,@nUotSolicitada BIGINT,@nUot BIGINT,@bGeneral BIT,@bUot BIT,@cUotMsg NVARCHAR(300),@dCese DATE,@cMotivo NVARCHAR(500),@nUsuarioObjetivo BIGINT,@cIdent NVARCHAR(200),@dAhora DATETIME2(0)=SYSUTCDATETIME();
    BEGIN TRY
        EXEC seg.PA_Operacion_Ins_IniciarIdempotente @cJson,'EMPLEADOS_RETIRAR','EMPLEADO_RETIRAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmpSesion OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@nOp OUTPUT,@bRep OUTPUT,@cEstadoOp OUTPUT,@cIdRes OUTPUT,@cCodRes OUTPUT,@bIni OUTPUT,@cMsg OUTPUT;
        IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg; GOTO Salida; END;
        IF @bRep=1 BEGIN SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END; SET @cMensaje=CASE WHEN @bResultado=1 THEN N'La solicitud ya fue procesada.' ELSE N'La solicitud está en proceso.' END; GOTO Salida; END;
        SELECT @nId=empleadoId,@nUotSolicitada=uotId,@dCese=fechaCese,@cMotivo=NULLIF(LTRIM(RTRIM(motivo)),N'') FROM OPENJSON(@cJson,'$.empleado') WITH(empleadoId BIGINT '$.empleadoId',uotId BIGINT '$.uotId',fechaCese DATE '$.fechaCese',motivo NVARCHAR(500) '$.motivo');
        SET @dCese=COALESCE(@dCese,CONVERT(date,@dAhora));
        EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuario,@nSesion,@nUotSolicitada,'EMPLEADOS_RETIRAR',1,@nUot OUTPUT,@bGeneral OUTPUT,@bUot OUTPUT,@cUotMsg OUTPUT;
        IF @bUot=0 BEGIN SET @cMensaje=@cUotMsg; GOTO Fallar; END;
        IF @nId=@nEmpSesion BEGIN SET @cMensaje=N'No puede retirar su propio registro.'; GOTO Fallar; END;
        IF @cMotivo IS NULL OR NOT EXISTS(SELECT 1 FROM org.EmpleadoUOT WHERE empleado_id=@nId AND uot_id=@nUot AND estado=1 AND fecha_hasta IS NULL) BEGIN SET @cMensaje=N'El empleado no está disponible o falta el motivo.'; GOTO Fallar; END;
        SELECT @nUsuarioObjetivo=usuario_id FROM seg.Usuario WHERE persona_id=@nId;
        BEGIN TRANSACTION;
        UPDATE EA SET estado=0,fecha_hasta=COALESCE(EA.fecha_hasta,@dCese) FROM org.EmpleadoArea EA JOIN org.Area A ON A.area_id=EA.area_id AND A.uot_id=@nUot WHERE EA.empleado_id=@nId AND EA.estado=1 AND EA.fecha_hasta IS NULL;
        UPDATE org.EmpleadoUOT SET estado=0,fecha_hasta=COALESCE(fecha_hasta,@dCese),fecha_cese=COALESCE(fecha_cese,@dCese),es_principal=0 WHERE empleado_id=@nId AND uot_id=@nUot AND estado=1 AND fecha_hasta IS NULL;
        IF NOT EXISTS(SELECT 1 FROM org.EmpleadoUOT WHERE empleado_id=@nId AND estado=1 AND fecha_hasta IS NULL AND es_principal=1)
           AND EXISTS(SELECT 1 FROM org.EmpleadoUOT WHERE empleado_id=@nId AND estado=1 AND fecha_hasta IS NULL)
        BEGIN
            UPDATE org.EmpleadoUOT SET es_principal=1
            WHERE empleado_uot_id=(SELECT TOP(1) empleado_uot_id FROM org.EmpleadoUOT WHERE empleado_id=@nId AND estado=1 AND fecha_hasta IS NULL ORDER BY fecha_desde,empleado_uot_id);
        END;
        IF @nUsuarioObjetivo IS NOT NULL
        BEGIN
            DECLARE @UU TABLE(id BIGINT PRIMARY KEY); INSERT @UU SELECT usuario_uot_id FROM seg.UsuarioUOT WHERE usuario_id=@nUsuarioObjetivo AND uot_id=@nUot AND estado=1 AND fecha_hasta IS NULL;
            UPDATE P SET estado=0,fecha_hasta=COALESCE(P.fecha_hasta,@dAhora) FROM seg.UsuarioUOTPermiso P JOIN @UU X ON X.id=P.usuario_uot_id WHERE P.estado=1 AND P.fecha_hasta IS NULL;
            UPDATE R SET estado=0,fecha_hasta=COALESCE(R.fecha_hasta,@dAhora) FROM seg.UsuarioUOTRol R JOIN @UU X ON X.id=R.usuario_uot_id WHERE R.estado=1 AND R.fecha_hasta IS NULL;
            UPDATE seg.UsuarioUOT SET estado=0,fecha_hasta=COALESCE(fecha_hasta,@dAhora),es_predeterminada=0 WHERE usuario_id=@nUsuarioObjetivo AND uot_id=@nUot AND estado=1 AND fecha_hasta IS NULL;
            DECLARE @nUotAlterna BIGINT=(SELECT TOP(1) UU.uot_id FROM seg.UsuarioUOT UU JOIN org.UOT U ON U.uot_id=UU.uot_id AND U.estado=1 WHERE UU.usuario_id=@nUsuarioObjetivo AND UU.estado=1 AND UU.fecha_hasta IS NULL ORDER BY UU.es_predeterminada DESC,UU.usuario_uot_id);
            IF @nUotAlterna IS NOT NULL
                UPDATE seg.SesionUsuario SET modo_uot='ESPECIFICA',uot_contexto_id=@nUotAlterna,fecha_ultima_actividad=@dAhora WHERE usuario_id=@nUsuarioObjetivo AND estado=1 AND fecha_revocacion IS NULL AND uot_contexto_id=@nUot;
        END;
        IF NOT EXISTS(SELECT 1 FROM org.EmpleadoUOT WHERE empleado_id=@nId AND estado=1 AND fecha_hasta IS NULL)
        BEGIN
            UPDATE org.Empleado SET estado=0,fecha_cese=@dCese WHERE empleado_id=@nId;
            IF @nUsuarioObjetivo IS NOT NULL
            BEGIN
                UPDATE seg.SesionUsuario SET estado=0,fecha_revocacion=COALESCE(fecha_revocacion,@dAhora),motivo_revocacion=@cMotivo WHERE usuario_id=@nUsuarioObjetivo AND estado=1;
                UPDATE seg.Usuario SET estado=0,estado_cuenta='RETIRADA',token_version=token_version+1,bloqueado_hasta=NULL WHERE usuario_id=@nUsuarioObjetivo;
                UPDATE seg.UsuarioRol SET estado=0,fecha_hasta=COALESCE(fecha_hasta,@dAhora),retirado_por_usuario_id=@nUsuario,motivo_retiro=@cMotivo WHERE usuario_id=@nUsuarioObjetivo AND estado=1 AND fecha_hasta IS NULL;
            END;
        END;
        SET @cIdent=CONVERT(NVARCHAR(200),@nId);
        EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @nUsuario,@nSesion,@nDisp,@nModulo,'RETIRAR','org','EmpleadoUOT',@cIdent,NULL,NULL,@cMotivo,NULL,NULL,NULL,@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
        EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOp,'COMPLETADA','org','EmpleadoUOT',@cIdent,'EMPLEADO_RETIRADO_UOT',@bFin OUTPUT,@cMsgFin OUTPUT;
        IF ISNULL(@bFin,0)=0 THROW 51038,N'No se pudo confirmar la operación.',1;
        COMMIT; SET @bResultado=1; SET @cMensaje=N'Empleado retirado de la UOT.'; GOTO Salida;
Fallar:
        IF @nOp IS NOT NULL AND @bResultado=0 EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOp,'FALLIDA',NULL,NULL,NULL,'NO_PROCESADO',@bFin OUTPUT,@cMsgFin OUTPUT;
    END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; SET @bResultado=0; SET @cMensaje=N'No se pudo retirar al empleado.'; END CATCH
Salida:
    SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido FROM config.FN_RespuestaUsuario(N'org.PA_Empleado_Upd_RetirarAdministracion',@bResultado,@cMensaje) R;
    RETURN CASE WHEN @bResultado=1 THEN 0 ELSE 1 END;
END;
GO
