IF OBJECT_ID(N'[org].[PA_Area_Upd_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_Area_Upd_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_Area_Upd_Registro
' Descripción             : Actualiza los datos de áreas de la organización.
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
    EXEC [org].[PA_Area_Upd_Registro]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [org].[PA_Area_Upd_Registro]
    @cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @bResultado=0; SET @cMensaje=N'No se pudo actualizar el área.'; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),@nAud BIGINT,@nTrans BIGINT,@nId BIGINT,@nUotSolicitada BIGINT,@nUot BIGINT,@bGeneral BIT,@bUot BIT,@cUotMsg NVARCHAR(300),@nPadre BIGINT,@cNombre NVARCHAR(120),@cIdent NVARCHAR(200);
    BEGIN TRY
        EXEC seg.PA_Operacion_Ins_IniciarIdempotente @cJson,'ORGANIZACIONES_EDITAR','AREA_EDITAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@nOp OUTPUT,@bRep OUTPUT,@cEstadoOp OUTPUT,@cIdRes OUTPUT,@cCodRes OUTPUT,@bIni OUTPUT,@cMsg OUTPUT;
        IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg; GOTO Salida; END;
        IF @bRep=1 BEGIN SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END; SET @cMensaje=CASE WHEN @bResultado=1 THEN N'La solicitud ya fue procesada.' ELSE N'La solicitud está en proceso.' END; GOTO Salida; END;
        SELECT @nId=areaId,@nUotSolicitada=uotId,@nPadre=areaPadreId,@cNombre=NULLIF(LTRIM(RTRIM(nombre)),N'') FROM OPENJSON(@cJson,'$.area') WITH(areaId BIGINT '$.areaId',uotId BIGINT '$.uotId',areaPadreId BIGINT '$.areaPadreId',nombre NVARCHAR(120) '$.nombre');
        IF @nUotSolicitada IS NULL SELECT @nUotSolicitada=uot_id FROM org.Area WHERE area_id=@nId;
        EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuario,@nSesion,@nUotSolicitada,'ORGANIZACIONES_EDITAR',1,@nUot OUTPUT,@bGeneral OUTPUT,@bUot OUTPUT,@cUotMsg OUTPUT;
        IF @bUot=0 BEGIN SET @cMensaje=@cUotMsg; GOTO Fallar; END;
        IF @nId IS NULL OR @cNombre IS NULL OR @nPadre=@nId OR NOT EXISTS(SELECT 1 FROM org.Area WHERE area_id=@nId AND uot_id=@nUot AND estado=1) BEGIN SET @cMensaje=N'El área no está disponible.'; GOTO Fallar; END;
        IF @nPadre IS NOT NULL AND NOT EXISTS(SELECT 1 FROM org.Area WHERE area_id=@nPadre AND uot_id=@nUot AND estado=1) BEGIN SET @cMensaje=N'El área superior no corresponde a la UOT.'; GOTO Fallar; END;
        IF @nPadre IS NOT NULL
        BEGIN
            DECLARE @bPadreEsDescendiente BIT=0;
            ;WITH Arbol AS
            (
                SELECT area_id
                FROM org.Area
                WHERE area_padre_id=@nId AND uot_id=@nUot AND estado=1
                UNION ALL
                SELECT A.area_id
                FROM org.Area A
                INNER JOIN Arbol P ON A.area_padre_id=P.area_id
                WHERE A.uot_id=@nUot AND A.estado=1
            )
            SELECT @bPadreEsDescendiente=CASE WHEN EXISTS(SELECT 1 FROM Arbol WHERE area_id=@nPadre) THEN 1 ELSE 0 END;
            IF @bPadreEsDescendiente=1 BEGIN SET @cMensaje=N'El área superior no puede ser una subárea.'; GOTO Fallar; END;
        END;
        BEGIN TRANSACTION;
        UPDATE org.Area SET area_padre_id=@nPadre,nombre=@cNombre WHERE area_id=@nId AND uot_id=@nUot;
        SET @cIdent=CONVERT(NVARCHAR(200),@nId);
        EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @nUsuario,@nSesion,@nDisp,@nModulo,'EDITAR','org','Area',@cIdent,NULL,NULL,NULL,NULL,NULL,NULL,@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
        EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOp,'COMPLETADA','org','Area',@cIdent,'AREA_ACTUALIZADA',@bFin OUTPUT,@cMsgFin OUTPUT;
        IF ISNULL(@bFin,0)=0 THROW 51036,N'No se pudo confirmar la operación.',1;
        COMMIT; SET @bResultado=1; SET @cMensaje=N'Área actualizada.'; GOTO Salida;
Fallar:
        IF @nOp IS NOT NULL AND @bResultado=0 EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOp,'FALLIDA',NULL,NULL,NULL,'NO_PROCESADO',@bFin OUTPUT,@cMsgFin OUTPUT;
    END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; SET @bResultado=0; SET @cMensaje=N'No se pudo actualizar el área.'; END CATCH
Salida:
    SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido FROM config.FN_RespuestaUsuario(N'org.PA_Area_Upd_Registro',@bResultado,@cMensaje) R;
    RETURN CASE WHEN @bResultado=1 THEN 0 ELSE 1 END;
END;
GO
