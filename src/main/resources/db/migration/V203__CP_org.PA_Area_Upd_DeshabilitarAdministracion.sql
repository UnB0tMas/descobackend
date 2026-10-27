IF OBJECT_ID(N'[org].[PA_Area_Upd_DeshabilitarAdministracion]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_Area_Upd_DeshabilitarAdministracion];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_Area_Upd_DeshabilitarAdministracion
' Descripción             : Deshabilita un área desde la administración.
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
    EXEC [org].[PA_Area_Upd_DeshabilitarAdministracion]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [org].[PA_Area_Upd_DeshabilitarAdministracion]
    @cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @bResultado=0; SET @cMensaje=N'No se pudo deshabilitar el área.'; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),@nAud BIGINT,@nTrans BIGINT,@nId BIGINT,@nUotSolicitada BIGINT,@nUot BIGINT,@bGeneral BIT,@bUot BIT,@cUotMsg NVARCHAR(300),@cMotivo NVARCHAR(500),@cIdent NVARCHAR(200);
    BEGIN TRY
        EXEC seg.PA_Operacion_Ins_IniciarIdempotente @cJson,'ORGANIZACIONES_RETIRAR','AREA_DESHABILITAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@nOp OUTPUT,@bRep OUTPUT,@cEstadoOp OUTPUT,@cIdRes OUTPUT,@cCodRes OUTPUT,@bIni OUTPUT,@cMsg OUTPUT;
        IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg; GOTO Salida; END;
        IF @bRep=1 BEGIN SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END; SET @cMensaje=CASE WHEN @bResultado=1 THEN N'La solicitud ya fue procesada.' ELSE N'La solicitud está en proceso.' END; GOTO Salida; END;
        SELECT @nId=COALESCE(TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.area.areaId')),TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.areaId'))),@nUotSolicitada=TRY_CONVERT(BIGINT,COALESCE(JSON_VALUE(@cJson,'$.area.uotId'),JSON_VALUE(@cJson,'$.uotId'))),@cMotivo=NULLIF(LTRIM(RTRIM(COALESCE(JSON_VALUE(@cJson,'$.area.motivo'),JSON_VALUE(@cJson,'$.motivo')))),N'');
        IF @nUotSolicitada IS NULL SELECT @nUotSolicitada=uot_id FROM org.Area WHERE area_id=@nId;
        EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuario,@nSesion,@nUotSolicitada,'ORGANIZACIONES_RETIRAR',1,@nUot OUTPUT,@bGeneral OUTPUT,@bUot OUTPUT,@cUotMsg OUTPUT;
        IF @bUot=0 BEGIN SET @cMensaje=@cUotMsg; GOTO Fallar; END;
        IF @cMotivo IS NULL OR NOT EXISTS(SELECT 1 FROM org.Area WHERE area_id=@nId AND uot_id=@nUot AND estado=1) BEGIN SET @cMensaje=N'El área no está disponible o falta el motivo.'; GOTO Fallar; END;
        DECLARE @Areas TABLE(area_id BIGINT PRIMARY KEY);
        ;WITH Arbol AS (SELECT area_id FROM org.Area WHERE area_id=@nId AND uot_id=@nUot AND estado=1 UNION ALL SELECT A.area_id FROM org.Area A JOIN Arbol P ON A.area_padre_id=P.area_id WHERE A.uot_id=@nUot AND A.estado=1)
        INSERT @Areas(area_id) SELECT area_id FROM Arbol OPTION(MAXRECURSION 32767);
        BEGIN TRANSACTION;
        UPDATE EA SET estado=0,fecha_hasta=COALESCE(EA.fecha_hasta,CONVERT(date,SYSUTCDATETIME())) FROM org.EmpleadoArea EA JOIN @Areas X ON X.area_id=EA.area_id WHERE EA.estado=1 AND EA.fecha_hasta IS NULL;
        UPDATE A SET estado=0 FROM org.Area A JOIN @Areas X ON X.area_id=A.area_id WHERE A.uot_id=@nUot AND A.estado=1;
        SET @cIdent=CONVERT(NVARCHAR(200),@nId);
        EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @nUsuario,@nSesion,@nDisp,@nModulo,'RETIRAR','org','Area',@cIdent,NULL,NULL,@cMotivo,NULL,NULL,NULL,@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
        EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOp,'COMPLETADA','org','Area',@cIdent,'AREA_DESHABILITADA',@bFin OUTPUT,@cMsgFin OUTPUT;
        IF ISNULL(@bFin,0)=0 THROW 51037,N'No se pudo confirmar la operación.',1;
        COMMIT; SET @bResultado=1; SET @cMensaje=N'Área deshabilitada.'; GOTO Salida;
Fallar:
        IF @nOp IS NOT NULL AND @bResultado=0 EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOp,'FALLIDA',NULL,NULL,NULL,'NO_PROCESADO',@bFin OUTPUT,@cMsgFin OUTPUT;
    END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; SET @bResultado=0; SET @cMensaje=N'No se pudo deshabilitar el área.'; END CATCH
Salida:
    SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido FROM config.FN_RespuestaUsuario(N'org.PA_Area_Upd_DeshabilitarAdministracion',@bResultado,@cMensaje) R;
    RETURN CASE WHEN @bResultado=1 THEN 0 ELSE 1 END;
END;
GO
