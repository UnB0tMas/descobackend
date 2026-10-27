IF OBJECT_ID(N'[org].[PA_Empresa_Upd_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_Empresa_Upd_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_Empresa_Upd_Registro
' Descripción             : Actualiza los datos de empresas.
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
    EXEC [org].[PA_Empresa_Upd_Registro]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [org].[PA_Empresa_Upd_Registro]
    @cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @bResultado=0; SET @cMensaje=N'No se pudo actualizar la empresa.'; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),@nAud BIGINT,@nTrans BIGINT,
            @nId BIGINT,@nUotSolicitada BIGINT,@nUot BIGINT,@bGeneral BIT,@bUot BIT,@cUotMsg NVARCHAR(300),@cRazon NVARCHAR(200),@cNombre NVARCHAR(160),@cTel VARCHAR(30),@cCorreo VARCHAR(180),@cDistrito CHAR(6),@nCentro BIGINT,@cReferencia NVARCHAR(300),@nUbicacion BIGINT,@bUbi BIT,@cMsgUbi NVARCHAR(300),@cIdent NVARCHAR(200);
    BEGIN TRY
        EXEC seg.PA_Operacion_Ins_IniciarIdempotente @cJson,'ORGANIZACIONES_EDITAR','EMPRESA_EDITAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@nOp OUTPUT,@bRep OUTPUT,@cEstadoOp OUTPUT,@cIdRes OUTPUT,@cCodRes OUTPUT,@bIni OUTPUT,@cMsg OUTPUT;
        IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg; GOTO Salida; END;
        IF @bRep=1 BEGIN SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END; SET @cMensaje=CASE WHEN @bResultado=1 THEN N'La solicitud ya fue procesada.' ELSE N'La solicitud está en proceso.' END; GOTO Salida; END;
        SELECT @nId=empresaId,@nUotSolicitada=uotId,@cRazon=NULLIF(LTRIM(RTRIM(razonSocial)),N''),@cNombre=NULLIF(LTRIM(RTRIM(nombreComercial)),N''),@cTel=NULLIF(LTRIM(RTRIM(telefono)),''),@cCorreo=NULLIF(LTRIM(RTRIM(correo)),'') FROM OPENJSON(@cJson,'$.empresa') WITH(empresaId BIGINT '$.empresaId',uotId BIGINT '$.uotId',razonSocial NVARCHAR(200) '$.razonSocial',nombreComercial NVARCHAR(160) '$.nombreComercial',telefono VARCHAR(30) '$.telefono',correo VARCHAR(180) '$.correo');
        SELECT @cDistrito=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.empresa.ubicacion.distritoCodigo'))),''),@nCentro=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.empresa.ubicacion.centroPobladoId')),@cReferencia=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.empresa.ubicacion.referencia'))),N'');
        EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuario,@nSesion,@nUotSolicitada,'ORGANIZACIONES_EDITAR',1,@nUot OUTPUT,@bGeneral OUTPUT,@bUot OUTPUT,@cUotMsg OUTPUT;
        IF @bUot=0 BEGIN SET @cMensaje=@cUotMsg; GOTO Fallar; END;
        IF @nId IS NULL OR @cRazon IS NULL OR @cDistrito IS NULL OR NOT EXISTS(SELECT 1 FROM org.ConvenioUOTOrganizacion WHERE uot_id=@nUot AND empresa_id=@nId AND tipo_vinculo='EMPRESA' AND estado=1 AND fecha_fin IS NULL) BEGIN SET @cMensaje=N'La empresa no está disponible en esta UOT.'; GOTO Fallar; END;
        SELECT @nUbicacion=ubicacion_id FROM org.Empresa WHERE empresa_id=@nId AND estado=1;
        BEGIN TRANSACTION;
        IF @nUbicacion IS NULL EXEC geo.PA_Ubicacion_Ins_Interna @cDistrito,@nCentro,@cReferencia,NULL,NULL,NULL,@nUbicacion OUTPUT,@bUbi OUTPUT,@cMsgUbi OUTPUT;
        ELSE EXEC geo.PA_Ubicacion_Upd_Interna @nUbicacion,@cDistrito,@nCentro,@cReferencia,@bUbi OUTPUT,@cMsgUbi OUTPUT;
        IF ISNULL(@bUbi,0)=0 BEGIN ROLLBACK; SET @cMensaje=COALESCE(@cMsgUbi,N'La ubicación no es válida.'); GOTO Fallar; END;
        UPDATE org.Empresa SET razon_social=@cRazon,nombre_comercial=@cNombre,telefono=@cTel,correo=@cCorreo,ubicacion_id=@nUbicacion WHERE empresa_id=@nId;
        SET @cIdent=CONVERT(NVARCHAR(200),@nId);
        EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @nUsuario,@nSesion,@nDisp,@nModulo,'EDITAR','org','Empresa',@cIdent,NULL,NULL,NULL,NULL,NULL,NULL,@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
        EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOp,'COMPLETADA','org','Empresa',@cIdent,'EMPRESA_ACTUALIZADA',@bFin OUTPUT,@cMsgFin OUTPUT;
        IF ISNULL(@bFin,0)=0 THROW 51032,N'No se pudo confirmar la operación.',1;
        COMMIT; SET @bResultado=1; SET @cMensaje=N'Empresa actualizada.'; GOTO Salida;
Fallar:
        IF @nOp IS NOT NULL AND @bResultado=0 EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOp,'FALLIDA',NULL,NULL,NULL,'NO_PROCESADO',@bFin OUTPUT,@cMsgFin OUTPUT;
    END TRY
    BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; SET @bResultado=0; SET @cMensaje=N'No se pudo actualizar la empresa.'; END CATCH
Salida:
    SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido FROM config.FN_RespuestaUsuario(N'org.PA_Empresa_Upd_Registro',@bResultado,@cMensaje) R;
    RETURN CASE WHEN @bResultado=1 THEN 0 ELSE 1 END;
END;
GO
