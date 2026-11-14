-- APAPPSS: variedad visible en recepción y recálculo auditable de descuento histórico.
-- Nueva migración, sin editar V622 ni V630 existentes. Mantener los pesos brutos originales.

-- Recalcular únicamente descuentos de peso; no altera pesajes brutos ni calibres.
-- Se invoca dentro de la transacción y del bloqueo UOT de los procedimientos de campaña.
CREATE OR ALTER PROCEDURE comercial.PA_CampaniaDescuentoJaba_Upd_Recalcular
 @camp BIGINT,@valor DECIMAL(9,3),@usuario BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 IF @@TRANCOUNT=0 THROW 52071,N'La actualización requiere una operación activa.',1;
 IF @valor IS NOT NULL AND (@valor<0 OR @valor>9.999)
   THROW 52072,N'El descuento por jaba no es válido.',1;
 -- No alterar valores incorporados a una liquidación no anulada.
 IF EXISTS(SELECT 1 FROM finanzas.LiquidacionSocio L
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
    WHERE P.campania_venta_id=@camp AND L.estado=1 AND L.estado_proceso NOT IN('ANULADA','CANCELADA'))
   THROW 52073,N'Esta campaña tiene liquidaciones en curso. Revise las liquidaciones antes de cambiar el descuento.',1;
 DECLARE @cambios TABLE (id BIGINT NOT NULL,planId BIGINT NOT NULL,numero INT NOT NULL,
   bruto DECIMAL(12,3) NOT NULL,anterior DECIMAL(9,3) NOT NULL,nuevo DECIMAL(9,3) NOT NULL,
   versionAnterior INT NOT NULL,versionNueva INT NOT NULL);
 UPDATE R SET descuento_jaba_kg=
     CASE WHEN R.peso_bruto_kg=0 THEN 0
       WHEN R.peso_bruto_kg<COALESCE(@valor,0) THEN CONVERT(DECIMAL(9,3),R.peso_bruto_kg)
       ELSE COALESCE(@valor,0) END,
   version=R.version+1,usuario_modifica_id=@usuario,fecha_modifica=SYSUTCDATETIME()
 OUTPUT inserted.campania_jaba_recepcion_id,inserted.campania_jaba_plan_id,inserted.numero_jaba,
   inserted.peso_bruto_kg,deleted.descuento_jaba_kg,inserted.descuento_jaba_kg,deleted.version,inserted.version
 INTO @cambios(id,planId,numero,bruto,anterior,nuevo,versionAnterior,versionNueva)
 FROM comercial.CampaniaJabaRecepcion R WITH(UPDLOCK,HOLDLOCK)
 JOIN comercial.CampaniaJabaPlan J ON J.campania_jaba_plan_id=R.campania_jaba_plan_id
 JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
 WHERE P.campania_venta_id=@camp AND R.descuento_jaba_kg<>
    CASE WHEN R.peso_bruto_kg=0 THEN 0
      WHEN R.peso_bruto_kg<COALESCE(@valor,0) THEN CONVERT(DECIMAL(9,3),R.peso_bruto_kg)
      ELSE COALESCE(@valor,0) END;
 INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
 SELECT @camp,'CampaniaJabaRecepcion',A.id,'RECALCULAR_TARA',
    (SELECT A.planId planId,A.numero numeroJaba,A.bruto pesoBrutoKg,A.anterior descuentoAnteriorKg,
      A.nuevo descuentoNuevoKg,A.versionAnterior versionAnterior,A.versionNueva versionNueva
     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario
 FROM @cambios A;
END;
GO

CREATE OR ALTER PROCEDURE comercial.PA_CampaniaDescuentoJaba_Upd_Configurar
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo guardar el descuento.',@cCodigoRespuesta='DESCUENTO_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @valor DECIMAL(9,3)=TRY_CONVERT(DECIMAL(9,3),JSON_VALUE(@cJson,'$.datos.descuentoJabaKg')),
  @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300),@appLock INT;
 BEGIN TRY
  IF @valor IS NOT NULL AND (@valor<0 OR @valor>9.999) THROW 52021,N'El descuento debe estar entre 0 y 9.999 kg.',1;
  SELECT @uot=uot_id FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp AND estado=1;
  IF @uot IS NULL THROW 52022,N'La campaña no existe.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='CAMPANIAS_EDITAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'CAMPANIAS_EDITAR')<>1 THROW 52023,N'Sin permiso para editar campañas.',1;
  BEGIN TRANSACTION;
  DECLARE @lockResource NVARCHAR(255)=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @appLock=sys.sp_getapplock @Resource=@lockResource,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @appLock<0 THROW 52024,N'La campaña está siendo modificada.',1;
  -- El nuevo descuento también actualiza los pesajes existentes con auditoría.
  UPDATE comercial.CampaniaVenta SET descuento_jaba_kg=@valor WHERE campania_venta_id=@camp AND estado_proceso IN('PLANIFICACION','ACTIVA');
  IF @@ROWCOUNT<>1 THROW 52026,N'La campaña no admite modificaciones.',1;
  EXEC comercial.PA_CampaniaDescuentoJaba_Upd_Recalcular @camp,@valor,@usuario;
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
    VALUES(@camp,'CampaniaVenta',@camp,'CONFIGURAR_DESCUENTO',(SELECT @valor descuentoJabaKg FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES),@usuario);
  COMMIT TRANSACTION;
  SET @cDatos=(SELECT @camp campaniaId,@valor descuentoJabaKg FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
  SELECT @bResultado=1,@cMensaje=N'Descuento actualizado.',@cCodigoRespuesta='DESCUENTO_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='DESCUENTO_ERROR',
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN 409 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo guardar el descuento.' END;
 END CATCH;
END;
GO


CREATE OR ALTER PROCEDURE comercial.PA_CampaniaPlan_Upd_Datos
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo actualizar la campaña.',@cCodigoRespuesta='CAMPANIA_EDICION_INVALIDA',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @comprador BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.compradorId')),
  @empresa BIGINT,@uot BIGINT,@asociacion BIGINT,@estado VARCHAR(24),@usuario BIGINT,@sesion BIGINT,
  @dispositivo BIGINT,@empleado BIGINT,@modulo INT,@corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,
  @ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300),
  @nombre NVARCHAR(180)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.nombre')),N''),
  @inicio DATE=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaInicio')),
  @fin DATE=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaFin')),
  @observacion NVARCHAR(400)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.observacion')),N''),
  @descuento DECIMAL(9,3)=TRY_CONVERT(DECIMAL(9,3),JSON_VALUE(@cJson,'$.datos.descuentoJabaKg')),
  @hoy DATE=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX),@appLock INT,
  @antes NVARCHAR(MAX),@despues NVARCHAR(MAX),@aud BIGINT,@trans BIGINT,
  @inicioAnterior DATE,@finAnterior DATE,@compradorAnterior BIGINT,@descuentoAnterior DECIMAL(9,3),
  @recursoLock NVARCHAR(255),@identificador NVARCHAR(200);
 BEGIN TRY
  IF ISJSON(@cJson)<>1 OR @clave IS NULL OR @camp IS NULL OR @comprador IS NULL
    OR @nombre IS NULL OR LEN(@nombre)>180 OR @inicio IS NULL OR @fin IS NULL
    OR @fin<@hoy OR @fin<@inicio OR (@descuento IS NOT NULL AND @descuento NOT BETWEEN 0 AND 9.999)
    OR LEN(COALESCE(@observacion,N''))>400
    THROW 51901,N'Complete correctamente el comprador, nombre y fechas de la campaña.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='CAMPANIAS_EDITAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 THROW 51902,N'No tiene permiso para editar campañas.',1;
  SELECT @uot=C.uot_id,@asociacion=C.asociacion_id FROM comercial.CampaniaVenta C
    WHERE C.campania_venta_id=@camp AND C.estado=1;
  IF @uot IS NULL OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'CAMPANIAS_EDITAR')<>1
    THROW 51902,N'No tiene acceso a esta campaña.',1;
  IF NOT EXISTS (SELECT 1 FROM org.ConvenioUOTOrganizacion CU
    JOIN org.Empresa AE ON AE.empresa_id=CU.empresa_id AND AE.ruc='20602771394' AND AE.estado=1
    JOIN org.Asociacion A ON A.asociacion_id=AE.empresa_id AND A.estado=1
    JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND CM.estado=1
    JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
    WHERE CU.uot_id=@uot AND CU.empresa_id=@asociacion AND CU.estado=1 AND CU.tipo_vinculo='ASOCIACION'
      AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=@hoy)
      AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=@hoy))
    THROW 51903,N'La UOT no tiene convenio APAPPSS vigente.',1;
  SELECT @empresa=CASE WHEN B.tipo='EMPRESA' THEN B.empresa_id ELSE NULL END
  FROM comercial.CompradorAPAPPSS B
  LEFT JOIN org.Empresa E ON E.empresa_id=B.empresa_id
  LEFT JOIN org.Persona P ON P.persona_id=B.persona_id
  WHERE B.comprador_apappss_id=@comprador AND B.uot_id=@uot AND B.estado=1
    AND ((B.tipo='EMPRESA' AND E.empresa_id IS NOT NULL AND E.estado=1)
      OR (B.tipo='PERSONA' AND P.persona_id IS NOT NULL AND P.estado=1));
  IF @@ROWCOUNT<>1 OR (@empresa IS NOT NULL AND @empresa=@asociacion)
    THROW 51904,N'El comprador no está disponible para esta UOT.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'CAMPANIA_EDICION|',@camp,N'|',JSON_QUERY(@cJson,'$.datos')));
  BEGIN TRANSACTION;
  SET @recursoLock=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @appLock=sys.sp_getapplock @Resource=@recursoLock,
    @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @appLock<0 THROW 51905,N'La campaña está siendo modificada. Reintente.',1;
  SELECT @prev=huella,@respuesta=respuesta FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK)
    WHERE usuario_id=@usuario AND clave=@clave;
  IF @prev IS NOT NULL
  BEGIN
    IF @prev<>@hash THROW 51906,N'La clave corresponde a otra operación.',1;
    SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Edición procesada anteriormente.',@cCodigoRespuesta='CAMPANIA_ACTUALIZADA',@nHttpRespuesta=200;
    COMMIT TRANSACTION; RETURN;
  END;
  SELECT @estado=C.estado_proceso,@inicioAnterior=C.fecha_inicio,@finAnterior=C.fecha_fin,
     @compradorAnterior=C.comprador_apappss_id,@descuentoAnterior=C.descuento_jaba_kg
    FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK)
    WHERE C.campania_venta_id=@camp AND C.uot_id=@uot AND C.estado=1;
  IF @estado IS NULL OR @estado NOT IN('PLANIFICACION','ACTIVA')
    THROW 51907,N'La campaña ya no admite cambios.',1;
  IF @inicio<@hoy AND @inicio<>@inicioAnterior
    THROW 51908,N'No puede cambiar el inicio a una fecha anterior a hoy.',1;
  -- En campaña activa solo se actualizan nombre y observación; se respeta la relación comercial.
  IF @estado='ACTIVA' AND (@inicio<>@inicioAnterior OR @fin<>@finAnterior
       OR ISNULL(@comprador,-1)<>ISNULL(@compradorAnterior,-1))
    THROW 51909,N'En una campaña activa solo puede modificar nombre y observación.',1;
  -- Se permite actualizar la tara de las jabas registradas mientras no exista liquidación vigente.
  SET @antes=(SELECT campania_venta_id,comprador_apappss_id,empresa_compradora_id,nombre,fecha_inicio,fecha_fin,observacion,descuento_jaba_kg
    FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  UPDATE comercial.CampaniaVenta SET comprador_apappss_id=@comprador,empresa_compradora_id=@empresa,
   nombre=@nombre,fecha_inicio=@inicio,fecha_fin=@fin,observacion=@observacion,descuento_jaba_kg=@descuento
   WHERE campania_venta_id=@camp;
  IF COALESCE(@descuento,-1)<>COALESCE(@descuentoAnterior,-1)
    EXEC comercial.PA_CampaniaDescuentoJaba_Upd_Recalcular @camp,@descuento,@usuario;
  SET @despues=(SELECT campania_venta_id,comprador_apappss_id,empresa_compradora_id,nombre,fecha_inicio,fecha_fin,observacion,descuento_jaba_kg
    FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SET @identificador=CONVERT(NVARCHAR(200),@camp);
  EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @usuario,@sesion,@dispositivo,@modulo,
    'EDITAR','comercial','CampaniaVenta',@identificador,@antes,@despues,
    NULL,NULL,NULL,NULL,@ip,@corr,@sol,@endpoint,@aud OUTPUT,@trans OUTPUT;
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
   VALUES(@camp,'CampaniaVenta',@camp,'EDITAR_DATOS',@despues,@usuario);
  SET @cDatos=(SELECT @camp campaniaVentaId,@comprador compradorId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta)
    VALUES(@usuario,@clave,'EDITAR_CAMPANIA',@hash,@cDatos);
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cMensaje=N'Campaña actualizada.',@cCodigoRespuesta='CAMPANIA_ACTUALIZADA',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='CAMPANIA_EDICION_ERROR',
    @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51901 AND 51999 OR ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN 409 ELSE 500 END,
    @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51901 AND 51999 OR ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN LEFT(ERROR_MESSAGE(),300)
       ELSE N'No se pudo actualizar la campaña.' END;
 END CATCH;
END;
GO


CREATE OR ALTER PROCEDURE comercial.PA_CampaniaVentaProceso_Sel_Detalle
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo consultar la recepción.',@cCodigoRespuesta='RECEPCION_LISTADO_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),@uot BIGINT,
   @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
   @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300),
   @hoy DATE=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()));
 BEGIN TRY
  SELECT @uot=uot_id FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp AND estado=1;
  IF @uot IS NULL THROW 52001,N'La campaña no existe.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='CAMPANIAS_VER',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'CAMPANIAS_VER')<>1
    OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'JABAS_LISTAR')<>1
    THROW 52002,N'No tiene acceso al proceso de venta.',1;
  SET @cDatos=(SELECT C.campania_venta_id campaniaId,C.nombre,C.codigo,C.fecha_inicio fechaInicio,C.fecha_fin fechaFin,
    C.estado_proceso estadoProceso,C.descuento_jaba_kg descuentoJabaKg,
    CAST(CASE WHEN C.estado_proceso IN('ACTIVA','PLANIFICACION') AND @hoy BETWEEN C.fecha_inicio AND C.fecha_fin THEN 1 ELSE 0 END AS BIT) vigente,
    JSON_QUERY((SELECT G.campania_calibre_id calibreId,G.variedad_palta_id variedadPaltaId,V.nombre nombreVariedad,G.calibre,
        G.gramos_desde gramosDesde,G.gramos_hasta gramosHasta,G.precio_kg precioKg,G.version
       FROM comercial.CampaniaCalibre G JOIN prod.VariedadPalta V ON V.variedad_palta_id=G.variedad_palta_id
       WHERE G.campania_venta_id=@camp AND G.activo=1 ORDER BY G.variedad_palta_id,G.gramos_desde FOR JSON PATH)) calibres,
    JSON_QUERY((SELECT P.participacion_campania_socio_id participacionId,P.socio_asociacion_id socioAsociacionId,
       PE.numero_documento documento,
       CONCAT(PE.nombres,N' ',PE.apellido_paterno,N' ',COALESCE(PE.apellido_materno,N'')) socioNombre,J.cantidad asignadas,J.estado estadoJabas,CAST(J.recepcion_confirmada AS BIT) recepcionConfirmada,
       (SELECT COUNT_BIG(*) FROM comercial.CampaniaJabaRecepcion R WHERE R.campania_jaba_plan_id=J.campania_jaba_plan_id) devueltas,
       (SELECT COALESCE(SUM(R.peso_bruto_kg),0) FROM comercial.CampaniaJabaRecepcion R WHERE R.campania_jaba_plan_id=J.campania_jaba_plan_id) pesoBrutoKg,
       (SELECT COALESCE(SUM(R.descuento_jaba_kg),0) FROM comercial.CampaniaJabaRecepcion R WHERE R.campania_jaba_plan_id=J.campania_jaba_plan_id) descuentoTotalKg,
       (SELECT COALESCE(SUM(R.peso_neto_kg),0) FROM comercial.CampaniaJabaRecepcion R WHERE R.campania_jaba_plan_id=J.campania_jaba_plan_id) pesoNetoKg
      FROM comercial.ParticipacionCampaniaSocio P
      JOIN comercial.CampaniaJabaPlan J ON J.participacion_campania_socio_id=P.participacion_campania_socio_id AND J.activo=1
      JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=P.socio_asociacion_id
      JOIN org.Socio SO ON SO.socio_id=SA.socio_id
      JOIN org.Persona PE ON PE.persona_id=SO.socio_id
      WHERE P.campania_venta_id=@camp AND P.estado=1 AND P.estado_participacion='ACTIVO' AND J.cantidad>=1
      ORDER BY P.participacion_campania_socio_id FOR JSON PATH)) socios
   FROM comercial.CampaniaVenta C WHERE C.campania_venta_id=@camp FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Consulta realizada.',@cCodigoRespuesta='RECEPCION_LISTADO_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='RECEPCION_LISTADO_ERROR',
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN 409 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo consultar la recepción.' END;
 END CATCH;
END;
GO
