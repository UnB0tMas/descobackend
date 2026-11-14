-- E3/APAPPSS: aptitud para campañas y retiro logico de fundos. No genera kilos de cosecha.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'prod.FundoHabilitacion',N'U') IS NULL
BEGIN
 CREATE TABLE prod.FundoHabilitacion(
  predio_id BIGINT NOT NULL REFERENCES prod.Predio(predio_id),
  convenio_id BIGINT NOT NULL REFERENCES org.ConvenioUOTOrganizacion(convenio_uot_organizacion_id),
  uot_id BIGINT NOT NULL REFERENCES org.UOT(uot_id),
  habilitado BIT NOT NULL CONSTRAINT DF_FundoHabilitacion_Habilitado DEFAULT(0),
  version BIGINT NOT NULL CONSTRAINT DF_FundoHabilitacion_Version DEFAULT(1),
  usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
  actualizado_en DATETIME2(0) NOT NULL CONSTRAINT DF_FundoHabilitacion_Fecha DEFAULT SYSUTCDATETIME(),
  CONSTRAINT PK_FundoHabilitacion PRIMARY KEY(predio_id,convenio_id)
 );
END;
GO
IF OBJECT_ID(N'prod.FundoAccionSolicitud',N'U') IS NULL
BEGIN
 CREATE TABLE prod.FundoAccionSolicitud(
  usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
  clave UNIQUEIDENTIFIER NOT NULL,
  tipo VARCHAR(20) NOT NULL,
  hash_peticion VARBINARY(32) NOT NULL,
  respuesta NVARCHAR(MAX) NOT NULL,
  fecha_hora DATETIME2(0) NOT NULL CONSTRAINT DF_FundoAccionSolicitud_Fecha DEFAULT SYSUTCDATETIME(),
  CONSTRAINT PK_FundoAccionSolicitud PRIMARY KEY(usuario_id,clave)
 );
END;
GO
IF OBJECT_ID(N'prod.FundoAccionHistorial',N'U') IS NULL
BEGIN
 CREATE TABLE prod.FundoAccionHistorial(
  historial_id BIGINT IDENTITY(1,1) PRIMARY KEY,
  predio_id BIGINT NOT NULL REFERENCES prod.Predio(predio_id),
  convenio_id BIGINT NOT NULL REFERENCES org.ConvenioUOTOrganizacion(convenio_uot_organizacion_id),
  accion VARCHAR(20) NOT NULL,
  motivo NVARCHAR(500) NULL,
  usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
  fecha_hora DATETIME2(0) NOT NULL CONSTRAINT DF_FundoAccionHistorial_Fecha DEFAULT SYSUTCDATETIME()
 );
END;
GO
-- Solo consulta de habilitacion (no modifica datos).
CREATE OR ALTER PROCEDURE prod.PA_FundoHabilitacion_Sel_Estado
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigo VARCHAR(60) OUTPUT,@nHttp SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'Fundo no disponible.',@cCodigo='FUNDO_APTITUD_ERROR',@nHttp=400;
 DECLARE @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
  @conv BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.convenioId')),
  @predio BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.predioId')),
  @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
  @auth BIT,@authMsg NVARCHAR(300),@plantas BIGINT=0,@habilitado BIT=0,@version BIGINT=0;
 BEGIN TRY
  IF ISJSON(@cJson)<>1 OR @uot IS NULL OR @conv IS NULL OR @predio IS NULL THROW 51901,N'Indique fundo y convenio.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,'APAPPSS_PREDIOS_VER',
   @usuario OUTPUT,@sesion OUTPUT,@dispositivo OUTPUT,@empleado OUTPUT,@modulo OUTPUT,
   @corr OUTPUT,@sol OUTPUT,@ip OUTPUT,@endpoint OUTPUT,@auth OUTPUT,@authMsg OUTPUT;
  IF ISNULL(@auth,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'APAPPSS_PREDIOS_VER')<>1
   THROW 51902,N'No tiene permiso para consultar el fundo.',1;
  IF NOT EXISTS(SELECT 1 FROM prod.Predio P JOIN prod.PredioAmbito A ON A.predio_id=P.predio_id AND A.estado=1
   JOIN org.ConvenioUOTOrganizacion C ON C.convenio_uot_organizacion_id=A.convenio_uot_organizacion_id AND C.estado=1
   WHERE P.predio_id=@predio AND P.estado=1 AND A.uot_id=@uot AND A.convenio_uot_organizacion_id=@conv
    AND C.uot_id=@uot AND EXISTS(SELECT 1 FROM prod.PredioTitularidad T
     JOIN org.SocioAsociacion S ON S.socio_id=T.socio_id AND S.asociacion_id=C.empresa_id AND S.estado=1
     WHERE T.predio_id=P.predio_id AND T.estado=1 AND T.fecha_hasta IS NULL))
   THROW 51903,N'Fundo no vinculado a este convenio.',1;
  SELECT @plantas=COUNT_BIG(*) FROM prod.PlantaPaltaE3
   WHERE predio_id=@predio AND uot_id=@uot AND convenio_id=@conv AND activo=1 AND estado_actual IN('SIN_EVALUAR','SANA','ENFERMA');
  SELECT @habilitado=habilitado,@version=version FROM prod.FundoHabilitacion
   WHERE predio_id=@predio AND uot_id=@uot AND convenio_id=@conv;
  SET @cDatos=(SELECT @predio predioId,@habilitado habilitado,@plantas plantasActivas,@version version FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Aptitud consultada.',@cCodigo='FUNDO_APTITUD_OK',@nHttp=200;
 END TRY BEGIN CATCH
  SELECT @cDatos=NULL,@bResultado=0,@cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51901 AND 51999
   THEN ERROR_MESSAGE() ELSE N'No se pudo consultar la aptitud.' END,
   @cCodigo='FUNDO_APTITUD_ERROR',@nHttp=CASE WHEN ERROR_NUMBER() BETWEEN 51901 AND 51999 THEN 400 ELSE 503 END;
 END CATCH;
END;
GO
-- Solo cambio de aptitud; una planta activa es suficiente. No inventa produccion anual.
CREATE OR ALTER PROCEDURE prod.PA_FundoHabilitacion_Upd_Estado
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigo VARCHAR(60) OUTPUT,@nHttp SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo cambiar el estado.',@cCodigo='FUNDO_APTITUD_ERROR',@nHttp=400;
 DECLARE @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
  @conv BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.convenioId')),
  @predio BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.predioId')),
  @valor NVARCHAR(10)=JSON_VALUE(@cJson,'$.datos.habilitado'),@habilitar BIT,
  @esperada BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.version')),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
  @auth BIT,@authMsg NVARCHAR(300),@plantas BIGINT=0,@actual BIGINT=0,
  @hash VARBINARY(32),@hashPrev VARBINARY(32),@prev NVARCHAR(MAX);
 BEGIN TRY
  IF ISJSON(@cJson)<>1 OR @uot IS NULL OR @conv IS NULL OR @predio IS NULL OR @clave IS NULL
    OR @esperada IS NULL OR @esperada<0 OR @valor IS NULL OR @valor NOT IN(N'true',N'false')
   THROW 51911,N'La solicitud no es válida.',1;
  SET @habilitar=CASE WHEN @valor=N'true' THEN 1 ELSE 0 END;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,'APAPPSS_PREDIOS_EDITAR',
   @usuario OUTPUT,@sesion OUTPUT,@dispositivo OUTPUT,@empleado OUTPUT,@modulo OUTPUT,
   @corr OUTPUT,@sol OUTPUT,@ip OUTPUT,@endpoint OUTPUT,@auth OUTPUT,@authMsg OUTPUT;
  IF ISNULL(@auth,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'APAPPSS_PREDIOS_EDITAR')<>1
   THROW 51912,N'No tiene permiso para cambiar la aptitud.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(@predio,N'|',@conv,N'|',JSON_QUERY(@cJson,'$.datos')));
  BEGIN TRANSACTION;
  SELECT @hashPrev=hash_peticion,@prev=respuesta FROM prod.FundoAccionSolicitud WITH(UPDLOCK,HOLDLOCK)
   WHERE usuario_id=@usuario AND clave=@clave;
  IF @hashPrev IS NOT NULL
  BEGIN
   IF @hashPrev<>@hash THROW 51913,N'La solicitud ya fue utilizada.',1;
   COMMIT TRANSACTION;
   SELECT @cDatos=@prev,@bResultado=1,@cMensaje=N'Operación ya registrada.',@cCodigo='FUNDO_APTITUD_OK',@nHttp=200;
   RETURN;
  END;
  IF NOT EXISTS(SELECT 1 FROM prod.Predio P WITH(UPDLOCK,HOLDLOCK)
   JOIN prod.PredioAmbito A ON A.predio_id=P.predio_id AND A.estado=1
   JOIN org.ConvenioUOTOrganizacion C ON C.convenio_uot_organizacion_id=A.convenio_uot_organizacion_id AND C.estado=1
   WHERE P.predio_id=@predio AND P.estado=1 AND A.uot_id=@uot AND A.convenio_uot_organizacion_id=@conv
    AND C.uot_id=@uot AND EXISTS(SELECT 1 FROM prod.PredioTitularidad T
     JOIN org.SocioAsociacion S ON S.socio_id=T.socio_id AND S.asociacion_id=C.empresa_id AND S.estado=1
     WHERE T.predio_id=P.predio_id AND T.estado=1 AND T.fecha_hasta IS NULL))
   THROW 51914,N'Fundo no disponible para el convenio.',1;
  SELECT @plantas=COUNT_BIG(*) FROM prod.PlantaPaltaE3
   WHERE predio_id=@predio AND uot_id=@uot AND convenio_id=@conv AND activo=1 AND estado_actual IN('SIN_EVALUAR','SANA','ENFERMA');
  IF @habilitar=1 AND @plantas=0 THROW 51915,N'Registre al menos una planta activa.',1;
  SELECT @actual=version FROM prod.FundoHabilitacion WITH(UPDLOCK,HOLDLOCK)
   WHERE predio_id=@predio AND convenio_id=@conv;
  IF @actual<>@esperada THROW 51916,N'El estado cambió. Actualice el fundo.',1;
  IF @actual=0
   INSERT prod.FundoHabilitacion(predio_id,convenio_id,uot_id,habilitado,usuario_id)
    VALUES(@predio,@conv,@uot,@habilitar,@usuario);
  ELSE
   UPDATE prod.FundoHabilitacion SET habilitado=@habilitar,version=version+1,usuario_id=@usuario,
    actualizado_en=SYSUTCDATETIME() WHERE predio_id=@predio AND convenio_id=@conv;
  INSERT prod.FundoAccionHistorial(predio_id,convenio_id,accion,usuario_id)
   VALUES(@predio,@conv,CASE WHEN @habilitar=1 THEN 'HABILITAR' ELSE 'DESHABILITAR' END,@usuario);
  SELECT @actual=version FROM prod.FundoHabilitacion WHERE predio_id=@predio AND convenio_id=@conv;
  SET @cDatos=(SELECT @predio predioId,@habilitar habilitado,@plantas plantasActivas,@actual version FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT prod.FundoAccionSolicitud(usuario_id,clave,tipo,hash_peticion,respuesta)
   VALUES(@usuario,@clave,'APTITUD',@hash,@cDatos);
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cMensaje=N'Aptitud actualizada.',@cCodigo='FUNDO_APTITUD_OK',@nHttp=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,@cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51911 AND 51999
   THEN ERROR_MESSAGE() ELSE N'No se pudo cambiar el estado.' END,
   @cCodigo='FUNDO_APTITUD_ERROR',@nHttp=CASE WHEN ERROR_NUMBER() BETWEEN 51911 AND 51999 THEN 400 ELSE 503 END;
 END CATCH;
END;
GO
-- Retiro logico del fundo y registros operativos; no elimina historiales ni liquidaciones.
CREATE OR ALTER PROCEDURE prod.PA_Fundo_Upd_RetirarEnBloque
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigo VARCHAR(60) OUTPUT,@nHttp SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo retirar el fundo.',@cCodigo='FUNDO_RETIRO_ERROR',@nHttp=400;
 DECLARE @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
  @conv BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.convenioId')),
  @predio BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.predioId')),
  @motivo NVARCHAR(500)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.motivo'))),N''),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
  @auth BIT,@authMsg NVARCHAR(300),@fecha DATE=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())),
  @hash VARBINARY(32),@hashPrev VARBINARY(32),@prev NVARCHAR(MAX);
 BEGIN TRY
  IF ISJSON(@cJson)<>1 OR @uot IS NULL OR @conv IS NULL OR @predio IS NULL OR @clave IS NULL
   OR @motivo IS NULL OR LEN(@motivo)<5 OR LEN(@motivo)>500
   THROW 51921,N'Indique un motivo válido.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,'PREDIOS_RETIRAR',
   @usuario OUTPUT,@sesion OUTPUT,@dispositivo OUTPUT,@empleado OUTPUT,@modulo OUTPUT,
   @corr OUTPUT,@sol OUTPUT,@ip OUTPUT,@endpoint OUTPUT,@auth OUTPUT,@authMsg OUTPUT;
  IF ISNULL(@auth,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'PREDIOS_RETIRAR')<>1
   THROW 51922,N'No tiene permiso para eliminar fundos.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(@predio,N'|',@conv,N'|',JSON_QUERY(@cJson,'$.datos')));
  BEGIN TRANSACTION;
  SELECT @hashPrev=hash_peticion,@prev=respuesta FROM prod.FundoAccionSolicitud WITH(UPDLOCK,HOLDLOCK)
   WHERE usuario_id=@usuario AND clave=@clave;
  IF @hashPrev IS NOT NULL
  BEGIN
   IF @hashPrev<>@hash THROW 51923,N'La solicitud ya fue utilizada.',1;
   COMMIT TRANSACTION;
   SELECT @cDatos=@prev,@bResultado=1,@cMensaje=N'Operación ya registrada.',@cCodigo='FUNDO_RETIRADO',@nHttp=200;
   RETURN;
  END;
  IF NOT EXISTS(SELECT 1 FROM prod.Predio P WITH(UPDLOCK,HOLDLOCK)
    JOIN prod.PredioAmbito A ON A.predio_id=P.predio_id AND A.estado=1
    WHERE P.predio_id=@predio AND P.estado=1 AND A.uot_id=@uot AND A.convenio_uot_organizacion_id=@conv)
   THROW 51924,N'Fundo no disponible en este convenio.',1;
  IF EXISTS(SELECT 1 FROM prod.PredioAmbito WHERE predio_id=@predio AND estado=1
    AND (uot_id<>@uot OR convenio_uot_organizacion_id IS NULL OR convenio_uot_organizacion_id<>@conv))
   THROW 51925,N'El fundo está vinculado a otro ámbito.',1;
  IF EXISTS(SELECT 1 FROM comercial.EntregaSocio WHERE predio_id=@predio)
   THROW 51926,N'El fundo tiene entregas registradas.',1;
  IF EXISTS(SELECT 1 FROM campo.SalidaDestinoE2 D JOIN campo.SalidaE2 E ON E.salida_campo_id=D.salida_campo_id
     WHERE D.predio_id=@predio AND E.estado IN('APROBADA','EN_EJECUCION','EN_RETORNO'))
   THROW 51927,N'El fundo tiene salidas de campo pendientes.',1;
  IF EXISTS(SELECT 1 FROM comercial.ParticipacionCampaniaSocio PCS
    JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=PCS.socio_asociacion_id
    JOIN prod.PredioTitularidad T ON T.socio_id=SA.socio_id AND T.predio_id=@predio AND T.estado=1
    JOIN comercial.CampaniaVenta CV ON CV.campania_venta_id=PCS.campania_venta_id
     WHERE PCS.estado=1 AND CV.estado=1 AND CV.estado_proceso NOT IN('CERRADA','CANCELADA','ANULADA'))
   THROW 51928,N'Un titular está inscrito en una campaña vigente.',1;
  IF EXISTS(SELECT 1 FROM comercial.CampaniaJabaRecepcion R
    JOIN comercial.CampaniaJabaPlan J ON J.campania_jaba_plan_id=R.campania_jaba_plan_id
    JOIN comercial.ParticipacionCampaniaSocio PCS ON PCS.participacion_campania_socio_id=J.participacion_campania_socio_id
    JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=PCS.socio_asociacion_id
    JOIN prod.PredioTitularidad T ON T.socio_id=SA.socio_id AND T.predio_id=@predio AND T.estado=1)
   THROW 51929,N'El titular ya tiene jabas recibidas.',1;
  -- Se retiran actividades productivas vigentes; los eventos y revisiones quedan para auditoría.
  UPDATE T SET estado=0 FROM prod.GPIncidenciaTratamiento T
   JOIN prod.GPIncidencia I ON I.incidencia_id=T.incidencia_id
   JOIN prod.GPActividad A ON A.actividad_id=I.actividad_id
   WHERE A.predio_id=@predio AND T.estado=1;
  UPDATE I SET estado=0 FROM prod.GPIncidencia I
   JOIN prod.GPActividad A ON A.actividad_id=I.actividad_id
   WHERE A.predio_id=@predio AND I.estado=1;
  UPDATE prod.GPActividad SET estado=0 WHERE predio_id=@predio AND estado=1;
  UPDATE D SET estado=0 FROM prod.DisponibilidadProduccion D
   JOIN prod.ParcelaCultivo C ON C.parcela_cultivo_id=D.parcela_cultivo_id
   JOIN prod.Parcela P ON P.parcela_id=C.parcela_id WHERE P.predio_id=@predio AND D.estado=1;
  UPDATE CP SET estado=0 FROM prod.CensoPlantas CP
   JOIN prod.ParcelaCultivo C ON C.parcela_cultivo_id=CP.parcela_cultivo_id
   JOIN prod.Parcela P ON P.parcela_id=C.parcela_id
   WHERE P.predio_id=@predio AND CP.estado=1;
  UPDATE C SET estado=0 FROM prod.ParcelaCultivo C
   JOIN prod.Parcela P ON P.parcela_id=C.parcela_id WHERE P.predio_id=@predio AND C.estado=1;
  -- V660: toda planta inactiva debe tener estado MUERTA o ELIMINADA.
  -- Dar de baja los episodios vigentes, conservando tratamientos y evaluaciones anteriores.
  UPDATE E SET activo=0,eliminado_en=COALESCE(eliminado_en,SYSUTCDATETIME()),
   eliminado_por_usuario_id=COALESCE(eliminado_por_usuario_id,@usuario),
   motivo_cierre=COALESCE(motivo_cierre,@motivo)
   FROM sanidad.EpisodioPlantaE3 E
   JOIN prod.PlantaPaltaE3 PL ON PL.planta_id=E.planta_id
   WHERE PL.predio_id=@predio AND E.activo=1;
  UPDATE prod.PlantaPaltaE3 SET estado_actual='ELIMINADA',activo=0,version=version+1
   WHERE predio_id=@predio AND activo=1;
  UPDATE prod.Parcela SET estado=0 WHERE predio_id=@predio AND estado=1;
  UPDATE prod.PredioTitularidad SET estado=0,fecha_hasta=COALESCE(fecha_hasta,@fecha)
   WHERE predio_id=@predio AND estado=1;
  UPDATE prod.PredioVersion SET estado=0,
   fecha_hasta=CASE WHEN fecha_hasta IS NULL THEN CASE WHEN fecha_desde>@fecha THEN fecha_desde ELSE @fecha END ELSE fecha_hasta END
   WHERE predio_id=@predio AND estado=1;
  UPDATE prod.FundoHabilitacion SET habilitado=0,version=version+1,usuario_id=@usuario,
   actualizado_en=SYSUTCDATETIME() WHERE predio_id=@predio;
  UPDATE prod.FundoProduccionE3 SET estado_produccion='NO_DISPONIBLE',cantidad_disponible_kg=0,
   version=version+1,usuario_id=@usuario,actualizado_en=SYSUTCDATETIME()
   WHERE predio_id=@predio AND estado_produccion<>'NO_DISPONIBLE'
    AND fecha_hasta>=@fecha;
  UPDATE prod.PredioAmbito SET estado=0 WHERE predio_id=@predio AND estado=1;
  UPDATE prod.Predio SET estado=0 WHERE predio_id=@predio AND estado=1;
  INSERT prod.FundoAccionHistorial(predio_id,convenio_id,accion,motivo,usuario_id)
   VALUES(@predio,@conv,'RETIRAR',@motivo,@usuario);
  SET @cDatos=(SELECT @predio predioId,CONVERT(BIT,1) retirado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT prod.FundoAccionSolicitud(usuario_id,clave,tipo,hash_peticion,respuesta)
   VALUES(@usuario,@clave,'RETIRAR',@hash,@cDatos);
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cMensaje=N'Fundo retirado.',@cCodigo='FUNDO_RETIRADO',@nHttp=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,@cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51921 AND 51999
   THEN ERROR_MESSAGE() ELSE N'No fue posible retirar el fundo.' END,
   @cCodigo='FUNDO_RETIRO_ERROR',@nHttp=CASE WHEN ERROR_NUMBER() BETWEEN 51921 AND 51999 THEN 400 ELSE 503 END;
 END CATCH;
END;
GO

-- PA vigente de activacion: solo se amplia la fuente de aptitud, sin relajar otros controles.
CREATE OR ALTER PROCEDURE [comercial].[PA_CampaniaVenta_Upd_Activar](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
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
DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),@nAud BIGINT,@nTrans BIGINT,@nUotSolicitada BIGINT,@nUot BIGINT,@bModoGeneral BIT,@bUot BIT,@cUotMsg NVARCHAR(300),@nId BIGINT,@cMotivo NVARCHAR(500),@cIdent NVARCHAR(200),@dInicio DATE,@dFin DATE,@nAsociacion BIGINT;
    SELECT @bResultado=0,@cMensaje=N'No se pudo completar la acción.';
    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente] @cJson=@cJson,@cCodigoPermiso='CAMPANIAS_CONFIRMAR|CAMPANIAS_APROBAR',@cAmbito='CAMPANIA_ACTIVAR',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@nOperacionIdempotenteId=@nOp OUTPUT,@bEsRepetida=@bRep OUTPUT,@cEstadoOperacion=@cEstadoOp OUTPUT,@cIdentificadorResultado=@cIdRes OUTPUT,@cCodigoResultado=@cCodRes OUTPUT,@bResultado=@bIni OUTPUT,@cMensaje=@cMsg OUTPUT;
    IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;
    IF @bRep=1 BEGIN SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END;
SET @cMensaje=CASE WHEN @cEstadoOp='COMPLETADA' THEN N'La solicitud ya fue procesada correctamente.' ELSE N'La solicitud ya se encuentra en proceso.' END;
GOTO __DESCO_Salida;
END;
SELECT @nId=campaniaVentaId,@nUotSolicitada=uotId,@cMotivo=NULLIF(LTRIM(RTRIM(motivo)),N'')
FROM OPENJSON(@cJson,'$.campania')
WITH(campaniaVentaId BIGINT '$.campaniaVentaId',uotId BIGINT '$.uotId',motivo NVARCHAR(500) '$.motivo');
IF @nUotSolicitada IS NULL SELECT @nUotSolicitada=uot_id FROM comercial.CampaniaVenta WHERE campania_venta_id=@nId;
EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuario,@nSesion,@nUotSolicitada,NULL,1,@nUot OUTPUT,@bModoGeneral OUTPUT,@bUot OUTPUT,@cUotMsg OUTPUT;
IF @bUot=0 BEGIN SET @cMensaje=@cUotMsg; GOTO Fallar; END;
IF seg.FN_Usuario_TienePermisoUOT(@nUsuario,@nUot,'CAMPANIAS_CONFIRMAR')<>1
   AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,@nUot,'CAMPANIAS_APROBAR')<>1
BEGIN SET @cMensaje=N'No tiene permiso para activar la campaña en esta UOT.'; GOTO Fallar; END;
IF @nId IS NULL BEGIN SET @cMensaje=N'Seleccione una campaña.';
GOTO Fallar;
END;
SELECT @dInicio=fecha_inicio,@dFin=fecha_fin,@nAsociacion=asociacion_id
FROM comercial.CampaniaVenta
WHERE campania_venta_id=@nId AND uot_id=@nUot AND estado=1 AND estado_proceso='PLANIFICACION';
IF @nAsociacion IS NULL BEGIN SET @cMensaje=N'La campaña no se encuentra en un estado válido para activarla.';
GOTO Fallar;
END;
IF @dInicio IS NULL OR @dFin IS NULL OR @dFin<@dInicio
   OR @dFin<CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()))
BEGIN SET @cMensaje=N'La campaña ya venció o tiene fechas inválidas. Corrija la vigencia antes de activarla.';
GOTO Fallar;
END;
IF NOT EXISTS(SELECT 1 FROM comercial.ParticipacionCampaniaSocio WHERE campania_venta_id=@nId AND estado=1 AND estado_participacion='ACTIVO')
BEGIN SET @cMensaje=N'Incluya al menos un socio antes de activar la campaña.';
GOTO Fallar;
END;
IF NOT EXISTS(SELECT 1 FROM comercial.PrecioComercial WHERE campania_venta_id=@nId AND estado=1 AND CONVERT(DATE,fecha_vigencia_desde)<=COALESCE(@dFin,@dInicio) AND (fecha_vigencia_hasta IS NULL OR CONVERT(DATE,fecha_vigencia_hasta)>=@dInicio))
BEGIN SET @cMensaje=N'Registre al menos un precio vigente antes de activar la campaña.';
GOTO Fallar;
END;
-- Un socio participa cuando al menos uno de sus fundos tiene disponibilidad declarada
-- para la campaña. El expediente por planta no constituye por si solo disponibilidad.
IF NOT EXISTS
(
 SELECT 1
 FROM comercial.ParticipacionCampaniaSocio PCS
 JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=PCS.socio_asociacion_id
  AND SA.asociacion_id=@nAsociacion AND SA.estado=1
 JOIN prod.PredioTitularidad PT ON PT.socio_id=SA.socio_id AND PT.estado=1
  AND PT.fecha_desde<=@dFin AND (PT.fecha_hasta IS NULL OR PT.fecha_hasta>=@dInicio)
 JOIN prod.Predio PD0 ON PD0.predio_id=PT.predio_id AND PD0.estado=1
 JOIN prod.FundoProduccionE3 FP ON FP.predio_id=PT.predio_id AND FP.uot_id=@nUot
  AND FP.fecha_desde<=@dFin AND FP.fecha_hasta>=@dInicio
  AND FP.estado_produccion IN('DISPONIBLE','PARCIAL') AND FP.cantidad_disponible_kg>0
  AND NOT EXISTS(SELECT 1 FROM prod.FundoHabilitacion H0
    WHERE H0.predio_id=FP.predio_id AND H0.convenio_id=FP.convenio_id AND H0.habilitado=0)
 JOIN org.ConvenioUOTOrganizacion CUO ON CUO.convenio_uot_organizacion_id=FP.convenio_id
  AND CUO.empresa_id=@nAsociacion AND CUO.uot_id=@nUot AND CUO.estado=1
 WHERE PCS.campania_venta_id=@nId AND PCS.estado=1 AND PCS.estado_participacion='ACTIVO'
   AND EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 P
       WHERE P.predio_id=FP.predio_id AND P.convenio_id=FP.convenio_id
        AND P.uot_id=@nUot AND P.activo=1 AND P.estado_actual IN('SIN_EVALUAR','SANA','ENFERMA'))
)
AND NOT EXISTS
(
 -- Compatibilidad con declaraciones anteriores a la nueva ficha del fundo.
 SELECT 1 FROM comercial.ParticipacionCampaniaSocio PCS
 JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=PCS.socio_asociacion_id AND SA.estado=1
 JOIN prod.PredioTitularidad PT ON PT.socio_id=SA.socio_id AND PT.estado=1
 JOIN prod.Predio PD1 ON PD1.predio_id=PT.predio_id AND PD1.estado=1
 JOIN prod.Parcela P ON P.predio_id=PT.predio_id AND P.estado=1
 JOIN prod.ParcelaCultivo PC ON PC.parcela_id=P.parcela_id
  AND PC.estado=1 AND PC.situacion_cultivo='ACTIVO'
 JOIN prod.DisponibilidadProduccion DP ON DP.parcela_cultivo_id=PC.parcela_cultivo_id
  AND DP.estado=1 AND DP.estado_estimacion IN('ESTIMADA','CONFIRMADA')
 WHERE PCS.campania_venta_id=@nId AND PCS.estado=1 AND PCS.estado_participacion='ACTIVO'
  AND SA.asociacion_id=@nAsociacion
  AND PT.fecha_desde<=@dFin AND (PT.fecha_hasta IS NULL OR PT.fecha_hasta>=@dInicio)
  AND DP.cantidad_estimada_kg>0
  AND DP.disponible_desde<=@dFin AND (DP.disponible_hasta IS NULL OR DP.disponible_hasta>=@dInicio)
  AND NOT EXISTS(SELECT 1 FROM prod.FundoHabilitacion H0
    JOIN org.ConvenioUOTOrganizacion C0 ON C0.convenio_uot_organizacion_id=H0.convenio_id
      AND C0.empresa_id=@nAsociacion AND C0.uot_id=@nUot
    WHERE H0.predio_id=PT.predio_id AND H0.habilitado=0)
)
AND NOT EXISTS
(
 -- También acepta un fundo habilitado explícitamente con plantas activas, sin declarar kilos.
 SELECT 1 FROM comercial.ParticipacionCampaniaSocio PCS
 JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=PCS.socio_asociacion_id
  AND SA.asociacion_id=@nAsociacion AND SA.estado=1
 JOIN prod.PredioTitularidad T ON T.socio_id=SA.socio_id AND T.estado=1
  AND T.fecha_desde<=@dFin AND (T.fecha_hasta IS NULL OR T.fecha_hasta>=@dInicio)
 JOIN prod.Predio PD ON PD.predio_id=T.predio_id AND PD.estado=1
 JOIN prod.FundoHabilitacion H ON H.predio_id=PD.predio_id AND H.uot_id=@nUot AND H.habilitado=1
 JOIN prod.PredioAmbito A ON A.predio_id=PD.predio_id AND A.uot_id=@nUot
  AND A.convenio_uot_organizacion_id=H.convenio_id AND A.estado=1
 JOIN org.ConvenioUOTOrganizacion C ON C.convenio_uot_organizacion_id=H.convenio_id
  AND C.uot_id=@nUot AND C.empresa_id=@nAsociacion AND C.estado=1
 WHERE PCS.campania_venta_id=@nId AND PCS.estado=1 AND PCS.estado_participacion='ACTIVO'
 AND EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 P
  WHERE P.predio_id=PD.predio_id AND P.convenio_id=H.convenio_id AND P.uot_id=@nUot
   AND P.activo=1 AND P.estado_actual NOT IN('MUERTA','ELIMINADA'))
)
BEGIN
 SET @cMensaje=N'No hay producción disponible de los participantes para las fechas de la campaña.';
 GOTO Fallar;
END;
BEGIN TRY BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
UPDATE comercial.CampaniaVenta SET estado_proceso='ACTIVA' WHERE campania_venta_id=@nId AND uot_id=@nUot;
SET @cIdent=CONVERT(NVARCHAR(200),@nId);
EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @nUsuario,@nSesion,@nDisp,@nModulo,'ACTIVA','comercial','CampaniaVenta',@cIdent,NULL,NULL,@cMotivo,'estado_proceso','PLANIFICACION','ACTIVA',@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
/* Confirmar datos e idempotencia juntos. */EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='COMPLETADA',@cEsquemaEntidad='comercial',@cNombreEntidad='CampaniaVenta',@cIdentificadorResultado=@cIdent,@cCodigoResultado='CAMPANIA_ACTIVA',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
IF ISNULL(@bFin,0) = 0
    THROW 51003, N'DESCO_IDEMPOTENCIA_NO_CERRADA', 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @bResultado=1;
SET @cMensaje=N'Campaña activada.';
GOTO __DESCO_Salida;
 END TRY BEGIN CATCH
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
SET @cMensaje=N'No se pudo completar la acción. Intente nuevamente.';
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'comercial.PA_CampaniaVenta_Upd_Activar',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;
Fallar:
    IF @nOp IS NOT NULL AND @bResultado=0 EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='FALLIDA',@cEsquemaEntidad=NULL,@cNombreEntidad=NULL,@cIdentificadorResultado=NULL,@cCodigoResultado='NO_PROCESADO',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;

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
    @cProcedimiento = N'comercial.PA_CampaniaVenta_Upd_Activar',
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

    IF @bResultado = 0 AND @nOp IS NOT NULL AND XACT_STATE() <> -1
    BEGIN
        IF ISNULL(@bRep,0) = 0
        BEGIN
        BEGIN TRY
            EXEC [auditoria].[PA_OperacionIdempotente_Upd_MensajeFallido]
                 @nOperacionIdempotenteId = @nOp, @cMensajeResultado = @cMensaje;
        END TRY
        BEGIN CATCH
            -- No sustituir el motivo funcional por un fallo de registro secundario.
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'comercial.PA_CampaniaVenta_Upd_Activar',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
        END CATCH;
        END
        ELSE
        BEGIN
            SELECT @cMensaje = COALESCE(mensaje_resultado,
                CASE WHEN estado_operacion = 'FALLIDA'
                     THEN N'La solicitud anterior no se completó. Corrija los datos y envíe una nueva solicitud.'
                     ELSE N'La solicitud todavía se está procesando. Consulte el resultado antes de repetirla.' END)
            FROM [auditoria].[OperacionIdempotente]
            WHERE operacion_idempotente_id = @nOp;
        END;
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
    @cProcedimiento = N'comercial.PA_CampaniaVenta_Upd_Activar',
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
FROM config.FN_RespuestaUsuario(N'comercial.PA_CampaniaVenta_Upd_Activar',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
