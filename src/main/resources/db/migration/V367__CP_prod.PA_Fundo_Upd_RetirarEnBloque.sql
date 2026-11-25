IF OBJECT_ID(N'[prod].[PA_Fundo_Upd_RetirarEnBloque]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_Fundo_Upd_RetirarEnBloque];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_Fundo_Upd_RetirarEnBloque
' Descripción            : Gestiona fundo: retirar en bloque.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_Fundo_Upd_RetirarEnBloque
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
