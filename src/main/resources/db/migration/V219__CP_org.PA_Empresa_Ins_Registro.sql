IF OBJECT_ID(N'[org].[PA_Empresa_Ins_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_Empresa_Ins_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_Empresa_Ins_Registro
' Descripción             : Registra empresas.
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
        @nEmpresaId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [org].[PA_Empresa_Ins_Registro]
        @cJson = N'{}',
        @nEmpresaId = @nEmpresaId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nEmpresaId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [org].[PA_Empresa_Ins_Registro]
    @cJson NVARCHAR(MAX),@nEmpresaId BIGINT OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    SET @nEmpresaId=NULL; SET @bResultado=0; SET @cMensaje=N'No se pudo registrar la empresa.';
    SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
            @nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),
            @nAud BIGINT,@nTrans BIGINT,@cRuc VARCHAR(30),@cRazon NVARCHAR(200),@cNombre NVARCHAR(160),@cTel VARCHAR(30),@cCorreo VARCHAR(180),
            @cDistrito CHAR(6),@nCentro BIGINT,@cReferencia NVARCHAR(300),@bExistia BIT,@bBase BIT,@cMsgBase NVARCHAR(300),@cIdent NVARCHAR(200),
            @nUotSolicitada BIGINT,@nUot BIGINT,@bGeneral BIT,@bUot BIT,@cUotMsg NVARCHAR(300);
    BEGIN TRY
        EXEC seg.PA_Operacion_Ins_IniciarIdempotente @cJson,'ORGANIZACIONES_CREAR','EMPRESA_CREAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@nOp OUTPUT,@bRep OUTPUT,@cEstadoOp OUTPUT,@cIdRes OUTPUT,@cCodRes OUTPUT,@bIni OUTPUT,@cMsg OUTPUT;
        IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg; GOTO Salida; END;
        IF @bRep=1 BEGIN SET @nEmpresaId=CASE WHEN @cEstadoOp='COMPLETADA' THEN TRY_CONVERT(BIGINT,@cIdRes) END; SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END; SET @cMensaje=CASE WHEN @bResultado=1 THEN N'La solicitud ya fue procesada.' ELSE N'La solicitud está en proceso.' END; GOTO Salida; END;

        SELECT @nUotSolicitada=uotId,@cRuc=NULLIF(LTRIM(RTRIM(ruc)),''),@cRazon=NULLIF(LTRIM(RTRIM(razonSocial)),N''),@cNombre=NULLIF(LTRIM(RTRIM(nombreComercial)),N''),@cTel=NULLIF(LTRIM(RTRIM(telefono)),''),@cCorreo=NULLIF(LTRIM(RTRIM(correo)),'')
        FROM OPENJSON(@cJson,'$.empresa') WITH(uotId BIGINT '$.uotId',ruc VARCHAR(30) '$.ruc',razonSocial NVARCHAR(200) '$.razonSocial',nombreComercial NVARCHAR(160) '$.nombreComercial',telefono VARCHAR(30) '$.telefono',correo VARCHAR(180) '$.correo');
        SELECT @cDistrito=COALESCE(NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.empresa.ubicacion.distritoCodigo'))),''),NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.ubicacion.distritoCodigo'))),'')),
               @nCentro=TRY_CONVERT(BIGINT,COALESCE(JSON_VALUE(@cJson,'$.empresa.ubicacion.centroPobladoId'),JSON_VALUE(@cJson,'$.ubicacion.centroPobladoId'))),
               @cReferencia=COALESCE(NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.empresa.ubicacion.referencia'))),N''),NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.ubicacion.referencia'))),N''));
        EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuario,@nSesion,@nUotSolicitada,'ORGANIZACIONES_CREAR',1,@nUot OUTPUT,@bGeneral OUTPUT,@bUot OUTPUT,@cUotMsg OUTPUT;
        IF @bUot=0 BEGIN SET @cMensaje=@cUotMsg; GOTO Fallar; END;
        IF @cRuc IS NULL OR @cRazon IS NULL OR @cDistrito IS NULL BEGIN SET @cMensaje=N'Complete los datos obligatorios.'; GOTO Fallar; END;

        BEGIN TRANSACTION;
        EXEC org.PA_Empresa_InsOUpd_DesdeFormulario @cRuc,@cRazon,@cNombre,@cTel,@cCorreo,@cDistrito,@nCentro,@cReferencia,@nEmpresaId OUTPUT,@bExistia OUTPUT,@bBase OUTPUT,@cMsgBase OUTPUT;
        IF @bBase=0 BEGIN ROLLBACK; SET @cMensaje=@cMsgBase; GOTO Fallar; END;
        IF EXISTS(SELECT 1 FROM org.Asociacion WHERE asociacion_id=@nEmpresaId AND estado=1) BEGIN ROLLBACK; SET @cMensaje=N'La organización ya está registrada como asociación.'; GOTO Fallar; END;
        IF EXISTS(SELECT 1 FROM org.ConvenioUOTOrganizacion WHERE uot_id=@nUot AND empresa_id=@nEmpresaId AND estado=1 AND fecha_fin IS NULL) BEGIN ROLLBACK; SET @cMensaje=N'La organización ya está vinculada a esta UOT.'; GOTO Fallar; END;
        INSERT org.ConvenioUOTOrganizacion(uot_id,empresa_id,tipo_vinculo,numero_convenio,fecha_inicio,fecha_fin,descripcion,estado,fecha_creacion)
        VALUES(@nUot,@nEmpresaId,'EMPRESA',NULL,CONVERT(date,SYSUTCDATETIME()),NULL,N'Contrato directo con la UOT.',1,SYSUTCDATETIME());
        SET @cIdent=CONVERT(NVARCHAR(200),@nEmpresaId);
        EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @nUsuario,@nSesion,@nDisp,@nModulo,'CREAR','org','ConvenioUOTOrganizacion',@cIdent,NULL,NULL,NULL,NULL,NULL,NULL,@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
        EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOp,'COMPLETADA','org','Empresa',@cIdent,'EMPRESA_CREADA',@bFin OUTPUT,@cMsgFin OUTPUT;
        IF ISNULL(@bFin,0)=0 THROW 51030,N'No se pudo confirmar la operación.',1;
        COMMIT;
        SET @bResultado=1; SET @cMensaje=N'Empresa registrada en la UOT.'; GOTO Salida;
Fallar:
        IF @nOp IS NOT NULL AND @bResultado=0 EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOp,'FALLIDA',NULL,NULL,NULL,'NO_PROCESADO',@bFin OUTPUT,@cMsgFin OUTPUT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK;
        SET @nEmpresaId=NULL; SET @bResultado=0; SET @cMensaje=N'No se pudo registrar la empresa.';
        IF @nOp IS NOT NULL BEGIN TRY EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOp,'FALLIDA',NULL,NULL,NULL,'NO_PROCESADO',@bFin OUTPUT,@cMsgFin OUTPUT; END TRY BEGIN CATCH END CATCH;
    END CATCH
Salida:
    SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido FROM config.FN_RespuestaUsuario(N'org.PA_Empresa_Ins_Registro',@bResultado,@cMensaje) R;
    RETURN CASE WHEN @bResultado=1 THEN 0 ELSE 1 END;
END;
GO
