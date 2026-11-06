SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'comercial.PA_APAPPSS_E4_Ejecutar', N'P') IS NOT NULL DROP PROCEDURE comercial.PA_APAPPSS_E4_Ejecutar;
GO
CREATE PROCEDURE comercial.PA_APAPPSS_E4_Ejecutar
 @cAccion VARCHAR(32), @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
 @cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo completar la operación comercial.',
 @cCodigoRespuesta='E4_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
 @asig BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.asignacionId')),
 @unidad BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.unidadId')),
 @operativoSocio BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.operativoSocioId')),
 @entrega BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.entregaId')),
 @uot BIGINT,@asociacion BIGINT,@op BIGINT,@participacion BIGINT,@estado VARCHAR(20),
 @perm VARCHAR(50),@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
 @correlacion UNIQUEIDENTIFIER,@solicitud UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
 @acceso BIT,@mensajeAcceso NVARCHAR(300),@clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
 @hash VARBINARY(32),@hashPrev VARBINARY(32),@respuestaPrev NVARCHAR(MAX),@appLock INT,
 @cupo INT,@tara DECIMAL(10,3),@cantidad INT,@cantidadNueva INT,@saldo INT,@ocupadas INT,
 @peso DECIMAL(14,3),@precio DECIMAL(14,4),@precioId BIGINT,@variedad SMALLINT,@condicion BIGINT,
 @nuevo DECIMAL(14,4),@motivo NVARCHAR(400),@llenas INT,@vacias INT,@devueltas INT,
 @lockResource NVARCHAR(255),@id BIGINT,@nBruto DECIMAL(14,3),@nTara DECIMAL(14,3),@nKilos DECIMAL(14,3),@importe DECIMAL(19,4),
 @tarifaId BIGINT,@concepto SMALLINT,@tarifa DECIMAL(14,4),@fecha DATETIME2(0)=SYSUTCDATETIME();
 IF ISJSON(@cJson)<>1 OR @cAccion NOT IN ('RESUMEN','CONFIGURAR','ASIGNAR','UNIDADES','PESAR','DEVOLVER','CONFIRMAR','SANCION','TARIFA','CARGO','BALANCE','VALIDAR_FALTANTE')
 BEGIN SET @cMensaje=N'Solicitud no válida.'; RETURN; END;
 IF @asig IS NOT NULL
 BEGIN
  SELECT @operativoSocio=A.operativo_socio_id FROM comercial.JabaAsignacion A WHERE A.jaba_asignacion_id=@asig AND A.estado=1;
 END;
 IF @unidad IS NOT NULL
 BEGIN
  SELECT @asig=U.jaba_asignacion_id FROM comercial.JabaUnidadE4 U WHERE U.unidad_id=@unidad;
  SELECT @operativoSocio=A.operativo_socio_id FROM comercial.JabaAsignacion A WHERE A.jaba_asignacion_id=@asig AND A.estado=1;
 END;
 IF @entrega IS NOT NULL
 BEGIN
  SELECT @operativoSocio=E.operativo_socio_id FROM comercial.EntregaSocio E WHERE E.entrega_socio_id=@entrega AND E.estado=1;
 END;
 IF @operativoSocio IS NOT NULL
 BEGIN
  SELECT @camp=O.campania_venta_id,@op=O.operativo_venta_id,@participacion=OS.participacion_campania_socio_id,
   @estado=O.estado_proceso FROM comercial.OperativoSocio OS
   JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id AND O.estado=1
   WHERE OS.operativo_socio_id=@operativoSocio AND OS.estado=1;
 END;
 SELECT @uot=C.uot_id,@asociacion=C.asociacion_id FROM comercial.CampaniaVenta C WHERE C.campania_venta_id=@camp AND C.estado=1;
 IF @camp IS NULL OR @uot IS NULL BEGIN SET @cMensaje=N'No se encuentra la campaña o el operativo autorizado.';RETURN;END;
 SET @perm=CASE @cAccion WHEN 'RESUMEN' THEN 'CAMPANIAS_VER' WHEN 'BALANCE' THEN 'CAMPANIAS_VER'
 WHEN 'CONFIGURAR' THEN 'CAMPANIAS_EDITAR' WHEN 'UNIDADES' THEN 'JABAS_VER'
 WHEN 'ASIGNAR' THEN 'JABAS_CREAR' WHEN 'PESAR' THEN 'ENTREGAS_CREAR'
 WHEN 'DEVOLVER' THEN 'JABAS_CREAR' WHEN 'CONFIRMAR' THEN 'ENTREGAS_CONFIRMAR'
 WHEN 'SANCION' THEN 'AJUSTES_CREAR' WHEN 'TARIFA' THEN 'JABAS_ADMINISTRAR'
 ELSE 'JABAS_APROBAR' END;
 BEGIN TRY
 EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso=@perm,
 @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
 @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@correlacion OUTPUT,
 @gSolicitudId=@solicitud OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
 @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
 IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,@perm)<>1
  THROW 51200,N'No dispone del permiso territorial solicitado.',1;
 IF NOT EXISTS(SELECT 1 FROM org.ConvenioUOTOrganizacion CU
    JOIN org.ConvenioModuloEspecial M ON M.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND M.estado=1
    JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=M.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
    WHERE CU.uot_id=@uot AND CU.empresa_id=@asociacion AND CU.estado=1
      AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,@fecha))
      AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,@fecha)))
  THROW 51201,N'La campaña no pertenece a un convenio APAPPSS vigente.',1;
 IF @cAccion='RESUMEN'
 BEGIN
  SET @cDatos=(SELECT C.campania_venta_id campaniaId,C.nombre,C.estado_proceso estado,
   K.cupo_jabas cupoJabas,K.tara_kg taraKg,
   (SELECT COALESCE(SUM(A.cantidad_asignada-A.cantidad_devuelta),0)
     FROM comercial.JabaAsignacion A JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
     JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
     WHERE O.campania_venta_id=@camp AND A.estado=1) jabasPendientes,
   (SELECT COUNT_BIG(1) FROM comercial.JabaUnidadE4 U JOIN comercial.JabaAsignacion A ON A.jaba_asignacion_id=U.jaba_asignacion_id
     JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
     JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
     WHERE O.campania_venta_id=@camp) unidades,
   JSON_QUERY((SELECT P.variedad_palta_id variedadId,P.condicion_comercial_id condicionId,P.precio,P.version
     FROM comercial.PrecioComercial P WHERE P.campania_venta_id=@camp AND P.estado=1
       AND P.fecha_vigencia_desde<=@fecha AND (P.fecha_vigencia_hasta IS NULL OR P.fecha_vigencia_hasta>=@fecha)
     ORDER BY P.variedad_palta_id,P.condicion_comercial_id,P.version DESC FOR JSON PATH)) precios
   FROM comercial.CampaniaVenta C LEFT JOIN comercial.CampaniaControlE4 K ON K.campania_venta_id=C.campania_venta_id
   WHERE C.campania_venta_id=@camp FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SET @bResultado=1;
 END
 ELSE IF @cAccion='UNIDADES'
 BEGIN
  IF @asig IS NULL THROW 51202,N'Seleccione una asignación.',1;
  SET @cDatos=(SELECT A.jaba_asignacion_id asignacionId,A.cantidad_asignada asignadas,
   (SELECT COUNT_BIG(1) FROM comercial.JabaUnidadE4 U WHERE U.jaba_asignacion_id=@asig AND U.pesaje_estado='PESADA') pesadas,
   (SELECT COUNT_BIG(1) FROM comercial.JabaUnidadE4 U WHERE U.jaba_asignacion_id=@asig AND U.retorno_estado LIKE 'DEVUELTA%') devueltas,
   (SELECT COUNT_BIG(1) FROM comercial.JabaUnidadE4 U WHERE U.jaba_asignacion_id=@asig AND U.retorno_estado='FALTANTE') faltantes,
   JSON_QUERY((SELECT U.unidad_id unidadId,U.numero,U.peso_bruto_kg pesoBrutoKg,U.tara_kg taraKg,U.peso_neto_kg pesoNetoKg,
     U.variedad_palta_id variedadId,U.condicion_comercial_id condicionId,U.precio_base precioBase,
     U.pesaje_estado pesaje,U.retorno_estado retorno,U.entrega_socio_id entregaId,U.version
      FROM comercial.JabaUnidadE4 U WHERE U.jaba_asignacion_id=@asig ORDER BY U.numero FOR JSON PATH)) unidades
   FROM comercial.JabaAsignacion A WHERE A.jaba_asignacion_id=@asig FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SET @bResultado=1;
 END
 ELSE IF @cAccion='BALANCE'
 BEGIN
  SET @cDatos=(SELECT C.campania_venta_id campaniaId,
   COALESCE((SELECT SUM(D.importe) FROM comercial.EntregaDetalle D JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id
     JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
     WHERE O.campania_venta_id=@camp AND E.estado=1 AND E.estado_proceso='CONFIRMADA' AND D.estado=1),0) brutoConfirmado,
   COALESCE((SELECT SUM(S.diferencia) FROM comercial.SancionSocioE4 S JOIN comercial.EntregaSocio E ON E.entrega_socio_id=S.entrega_socio_id
     JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
     WHERE O.campania_venta_id=@camp AND S.estado=1),0) descuentosPrecio,
   COALESCE((SELECT SUM(X.importe) FROM comercial.CargoIndividualE4 X JOIN comercial.JabaAsignacion A ON A.jaba_asignacion_id=X.jaba_asignacion_id
     JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
     WHERE O.campania_venta_id=@camp AND X.estado=1),0) cargosIndividuales
   FROM comercial.CampaniaVenta C WHERE C.campania_venta_id=@camp FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SET @bResultado=1;
 END
 ELSE
 BEGIN
  IF @clave IS NULL THROW 51203,N'La mutación requiere clave de idempotencia.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(@cAccion,N'|',JSON_QUERY(@cJson,'$.filtros'),N'|',JSON_QUERY(@cJson,'$.datos')));
  BEGIN TRANSACTION;
  SET @lockResource=CONCAT(N'DESCO:E4:CAMPAÑA:',@camp);
  EXEC @appLock=sys.sp_getapplock @Resource=@lockResource,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @appLock<0 THROW 51204,N'Existe otra operación comercial en curso.',1;
  SELECT @hashPrev=huella,@respuestaPrev=respuesta FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK)
   WHERE usuario_id=@usuario AND clave=@clave;
  IF @hashPrev IS NOT NULL
  BEGIN
   IF @hashPrev<>@hash THROW 51205,N'La clave ya corresponde a otra solicitud.',1;
   SET @cDatos=@respuestaPrev;SET @bResultado=1;COMMIT TRANSACTION;
   SELECT @cCodigoRespuesta='E4_OK',@nHttpRespuesta=200,@cMensaje=N'Operación previamente registrada.';RETURN;
  END;
  IF @cAccion='CONFIGURAR'
  BEGIN
   SELECT @cupo=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.cupoJabas')),
    @tara=TRY_CONVERT(DECIMAL(10,3),JSON_VALUE(@cJson,'$.datos.taraKg'));
   IF @cupo NOT BETWEEN 1 AND 100000 OR @tara IS NULL OR @tara<0 OR @tara>=10
    THROW 51206,N'Indique cupo y tara válidos.',1;
   SELECT @ocupadas=COALESCE(SUM(A.cantidad_asignada),0) FROM comercial.JabaAsignacion A
    JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
    JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
    WHERE O.campania_venta_id=@camp AND A.estado=1;
   IF @cupo<@ocupadas THROW 51207,N'El cupo es inferior a las jabas ya asignadas.',1;
   IF EXISTS(SELECT 1 FROM comercial.CampaniaControlE4 WHERE campania_venta_id=@camp)
    UPDATE comercial.CampaniaControlE4 SET cupo_jabas=@cupo,tara_kg=@tara,version=version+1,
     usuario_id=@usuario,actualizado_en=@fecha WHERE campania_venta_id=@camp;
   ELSE INSERT INTO comercial.CampaniaControlE4(campania_venta_id,cupo_jabas,tara_kg,usuario_id)
    VALUES(@camp,@cupo,@tara,@usuario);
   SET @cDatos=(SELECT @camp campaniaId,@cupo cupoJabas,@tara taraKg FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='ASIGNAR'
  BEGIN
   SELECT @cantidad=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.cantidad'));
   IF @cantidad NOT BETWEEN 1 AND 3000 OR @operativoSocio IS NULL OR @estado<>'EN_RECEPCION'
    THROW 51208,N'El operativo no admite esta asignación.',1;
   IF NOT EXISTS(SELECT 1 FROM comercial.OperativoSocio OS JOIN comercial.ParticipacionCampaniaSocio P
     ON P.participacion_campania_socio_id=OS.participacion_campania_socio_id AND P.estado=1 AND P.estado_participacion='ACTIVO'
     JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=P.socio_asociacion_id AND SA.estado=1 AND SA.asociacion_id=@asociacion
     WHERE OS.operativo_socio_id=@operativoSocio AND OS.estado_participacion='PROGRAMADO' AND OS.estado=1)
    THROW 51208,N'No es un socio participante activo de esta campaña.',1;
   SELECT @cupo=cupo_jabas FROM comercial.CampaniaControlE4 WITH(UPDLOCK,HOLDLOCK) WHERE campania_venta_id=@camp;
   IF @cupo IS NULL THROW 51209,N'Primero configure el cupo de campaña.',1;
   SELECT @ocupadas=COALESCE(SUM(A.cantidad_asignada),0) FROM comercial.JabaAsignacion A
    JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
    JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
    WHERE O.campania_venta_id=@camp AND A.estado=1;
   IF @cantidad+@ocupadas>@cupo THROW 51210,N'La asignación excede el cupo de campaña.',1;
   EXEC comercial.PA_Jabas_Sel_SaldoInterno @nOperativoVentaId=@op,@nOperativoSocioId=NULL,
    @nRecibidas=@saldo OUTPUT,@nAsignadas=@cantidadNueva OUTPUT,@nDevueltas=@devueltas OUTPUT,
    @nPendientes=@vacias OUTPUT,@nDisponibles=@llenas OUTPUT;
   IF @llenas<@cantidad THROW 51211,N'No hay jabas físicas disponibles en el operativo.',1;
   INSERT INTO comercial.JabaAsignacion(operativo_socio_id,fecha_hora,cantidad_asignada,observacion,estado,usuario_registro_id)
    VALUES(@operativoSocio,@fecha,@cantidad,NULL,1,@usuario);
   SET @asig=SCOPE_IDENTITY();
   ;WITH N AS(SELECT TOP(@cantidad) ROW_NUMBER() OVER(ORDER BY A.object_id,B.object_id) n
      FROM sys.all_objects A CROSS JOIN sys.all_objects B)
   INSERT INTO comercial.JabaUnidadE4(jaba_asignacion_id,numero) SELECT @asig,n FROM N;
   SET @cDatos=(SELECT @asig asignacionId,@cantidad unidades FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='PESAR'
  BEGIN
   SELECT @peso=TRY_CONVERT(DECIMAL(14,3),JSON_VALUE(@cJson,'$.datos.pesoBrutoKg')),
    @variedad=TRY_CONVERT(SMALLINT,JSON_VALUE(@cJson,'$.datos.variedadId')),
    @condicion=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.condicionId'));
   IF @peso IS NULL OR @variedad IS NULL OR @condicion IS NULL OR @estado<>'EN_RECEPCION'
    THROW 51212,N'Peso, variedad y condición son obligatorios.',1;
   SELECT @tara=K.tara_kg FROM comercial.CampaniaControlE4 K WHERE K.campania_venta_id=@camp;
   IF @tara IS NULL OR @peso<=@tara THROW 51213,N'El peso bruto debe superar la tara.',1;
   SELECT TOP(1) @precioId=P.precio_comercial_id,@precio=P.precio FROM comercial.PrecioComercial P
    WHERE P.campania_venta_id=@camp AND (P.operativo_venta_id=@op OR P.operativo_venta_id IS NULL)
     AND P.variedad_palta_id=@variedad AND P.condicion_comercial_id=@condicion AND P.estado=1
     AND P.fecha_vigencia_desde<=@fecha AND (P.fecha_vigencia_hasta IS NULL OR P.fecha_vigencia_hasta>=@fecha)
    ORDER BY CASE WHEN P.operativo_venta_id=@op THEN 0 ELSE 1 END,P.version DESC;
   IF @precioId IS NULL THROW 51214,N'La campaña no tiene precio vigente para esa clasificación.',1;
   UPDATE comercial.JabaUnidadE4 SET peso_bruto_kg=@peso,tara_kg=@tara,
    variedad_palta_id=@variedad,condicion_comercial_id=@condicion,precio_comercial_id=@precioId,
    precio_base=@precio,pesaje_estado='PESADA',usuario_pesaje_id=@usuario,fecha_pesaje=@fecha,version=version+1
    WHERE unidad_id=@unidad AND pesaje_estado='SIN_PESAJE' AND retorno_estado='PENDIENTE' AND entrega_socio_id IS NULL;
   IF @@ROWCOUNT<>1 THROW 51215,N'La unidad ya tiene pesaje o fue cerrada.',1;
   SET @cDatos=(SELECT @unidad unidadId,@peso pesoBrutoKg,@tara taraKg,@peso-@tara pesoNetoKg,@precio precioBase FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='DEVOLVER'
  BEGIN
   SELECT @llenas=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.llenas')),
    @vacias=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.vacias'));
   SELECT @cantidad=A.cantidad_asignada FROM comercial.JabaAsignacion A WITH(UPDLOCK,HOLDLOCK) WHERE A.jaba_asignacion_id=@asig;
   IF @estado<>'EN_RECEPCION' OR @llenas IS NULL OR @vacias IS NULL OR @llenas<0 OR @vacias<0 OR @llenas+@vacias>@cantidad
    THROW 51216,N'Las cantidades devueltas no son válidas.',1;
   IF EXISTS(SELECT 1 FROM comercial.JabaDevolucion WHERE jaba_asignacion_id=@asig AND estado=1)
    THROW 51217,N'La devolución ya fue registrada; revise el historial.',1;
   IF (SELECT COUNT_BIG(1) FROM comercial.JabaUnidadE4 WHERE jaba_asignacion_id=@asig AND pesaje_estado='PESADA')<>@llenas
    THROW 51218,N'La cantidad de jabas llenas debe coincidir con los pesajes registrados.',1;
   UPDATE comercial.JabaUnidadE4 SET retorno_estado='DEVUELTA_LLENA',usuario_retorno_id=@usuario,fecha_retorno=@fecha,version=version+1
    WHERE jaba_asignacion_id=@asig AND pesaje_estado='PESADA' AND retorno_estado='PENDIENTE';
   ;WITH V AS(SELECT TOP(@vacias) unidad_id FROM comercial.JabaUnidadE4
    WHERE jaba_asignacion_id=@asig AND pesaje_estado='SIN_PESAJE' AND retorno_estado='PENDIENTE' ORDER BY numero)
   UPDATE U SET retorno_estado='DEVUELTA_VACIA',usuario_retorno_id=@usuario,fecha_retorno=@fecha,version=version+1
    FROM comercial.JabaUnidadE4 U JOIN V ON V.unidad_id=U.unidad_id;
   UPDATE comercial.JabaUnidadE4 SET retorno_estado='FALTANTE',usuario_retorno_id=@usuario,fecha_retorno=@fecha,version=version+1
    WHERE jaba_asignacion_id=@asig AND retorno_estado='PENDIENTE';
   INSERT INTO comercial.JabaDevolucion(jaba_asignacion_id,entrega_socio_id,fecha_hora,cantidad_llenas,cantidad_vacias,observacion,estado,usuario_registro_id)
     VALUES(@asig,NULL,@fecha,@llenas,@vacias,N'Reconciliación individual E4',1,@usuario);
   IF @cantidad-@llenas-@vacias>0
      INSERT INTO comercial.IncidenciaFaltanteE4(jaba_asignacion_id,cantidad,registrado_por)
        VALUES(@asig,@cantidad-@llenas-@vacias,@usuario);
   SET @cDatos=(SELECT @asig asignacionId,@llenas llenas,@vacias vacias,@cantidad-@llenas-@vacias faltantes FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='CONFIRMAR'
  BEGIN
   SELECT @cantidad=COUNT(1),@nBruto=SUM(U.peso_bruto_kg),@nTara=SUM(U.tara_kg),@nKilos=SUM(U.peso_neto_kg)
    FROM comercial.JabaUnidadE4 U WHERE U.jaba_asignacion_id=@asig AND U.pesaje_estado='PESADA' AND U.retorno_estado='DEVUELTA_LLENA';
   IF @cantidad<=0 OR @nKilos<=0 OR @estado<>'EN_RECEPCION' OR EXISTS(
     SELECT 1 FROM comercial.JabaUnidadE4 WHERE jaba_asignacion_id=@asig AND retorno_estado='PENDIENTE')
    THROW 51219,N'Concílie la devolución y complete los pesajes antes de confirmar.',1;
   IF EXISTS(SELECT 1 FROM comercial.JabaUnidadE4 WHERE jaba_asignacion_id=@asig AND entrega_socio_id IS NOT NULL)
    THROW 51220,N'La asignación ya tiene una entrega confirmada.',1;
   INSERT INTO comercial.EntregaSocio(operativo_socio_id,predio_id,codigo_lote,fecha_hora,peso_bruto_kg,tara_kg,peso_rechazado_kg,
     estado_control_calidad,ticket_balanza,observacion,estado_proceso,estado)
    VALUES(@operativoSocio,NULL,CONCAT('E4-',@asig),@fecha,@nBruto,@nTara,0,'CONFORME',NULL,N'Acopio individual APAPPSS E4','REGISTRADA',1);
   SET @entrega=SCOPE_IDENTITY();
   INSERT INTO comercial.EntregaDetalle(entrega_socio_id,variedad_palta_id,condicion_comercial_id,precio_comercial_id,kilogramos,precio_base,precio_aplicado,estado)
    SELECT @entrega,U.variedad_palta_id,U.condicion_comercial_id,U.precio_comercial_id,SUM(U.peso_neto_kg),U.precio_base,U.precio_base,1
    FROM comercial.JabaUnidadE4 U WHERE U.jaba_asignacion_id=@asig AND U.pesaje_estado='PESADA'
    GROUP BY U.variedad_palta_id,U.condicion_comercial_id,U.precio_comercial_id,U.precio_base;
   UPDATE comercial.EntregaSocio SET estado_proceso='CONFIRMADA' WHERE entrega_socio_id=@entrega;
   UPDATE comercial.OperativoSocio SET estado_participacion='PARTICIPO' WHERE operativo_socio_id=@operativoSocio;
   UPDATE comercial.JabaUnidadE4 SET entrega_socio_id=@entrega,version=version+1 WHERE jaba_asignacion_id=@asig AND pesaje_estado='PESADA';
   SET @cDatos=(SELECT @entrega entregaId,@nKilos kilosAceptados,@cantidad llenas FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='SANCION'
  BEGIN
   SELECT @nuevo=TRY_CONVERT(DECIMAL(14,4),JSON_VALUE(@cJson,'$.datos.precioNuevo')),
    @condicion=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.condicionId')),
    @variedad=TRY_CONVERT(SMALLINT,JSON_VALUE(@cJson,'$.datos.variedadId')),
    @motivo=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.motivo'))),N'');
   IF @nuevo IS NULL OR @nuevo<0 OR @motivo IS NULL OR @entrega IS NULL
    THROW 51221,N'Indique entrega, precio sancionado y motivo.',1;
   IF NOT EXISTS(SELECT 1 FROM comercial.EntregaSocio WHERE entrega_socio_id=@entrega AND estado=1 AND estado_proceso='CONFIRMADA')
    THROW 51222,N'La entrega debe estar confirmada.',1;
   IF EXISTS(SELECT 1 FROM comercial.SancionSocioE4 S WHERE S.entrega_socio_id=@entrega AND S.estado=1
      AND (S.condicion_comercial_id IS NULL OR @condicion IS NULL OR S.condicion_comercial_id=@condicion)
      AND (S.variedad_palta_id IS NULL OR @variedad IS NULL OR S.variedad_palta_id=@variedad))
    THROW 51223,N'Ya existe una sanción en el mismo alcance de la entrega.',1;
   SELECT @nKilos=SUM(D.kilogramos),@precio=MIN(D.precio_base)
    FROM comercial.EntregaDetalle D WHERE D.entrega_socio_id=@entrega AND D.estado=1
    AND (@condicion IS NULL OR D.condicion_comercial_id=@condicion)
    AND (@variedad IS NULL OR D.variedad_palta_id=@variedad);
   IF @nKilos IS NULL OR @precio IS NULL OR EXISTS(SELECT 1 FROM comercial.EntregaDetalle D
      WHERE D.entrega_socio_id=@entrega AND D.estado=1
       AND (@condicion IS NULL OR D.condicion_comercial_id=@condicion)
       AND (@variedad IS NULL OR D.variedad_palta_id=@variedad) AND D.precio_base<>@precio)
    THROW 51224,N'Seleccione una clasificación con un único precio original.',1;
   IF @nuevo>@precio THROW 51225,N'El precio sancionado no puede superar el original.',1;
   INSERT INTO comercial.SancionSocioE4(entrega_socio_id,condicion_comercial_id,variedad_palta_id,kilos_afectados,precio_original,precio_nuevo,motivo,usuario_id)
    VALUES(@entrega,@condicion,@variedad,@nKilos,@precio,@nuevo,@motivo,@usuario);
   SET @id=SCOPE_IDENTITY();
   SET @cDatos=(SELECT @id sancionId,@nKilos kilosAfectados,@precio precioOriginal,@nuevo precioNuevo,
     CONVERT(DECIMAL(19,4),@nKilos*(@precio-@nuevo)) descuento FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='TARIFA'
  BEGIN
   SELECT @concepto=TRY_CONVERT(SMALLINT,JSON_VALUE(@cJson,'$.datos.conceptoId')),
    @tarifa=TRY_CONVERT(DECIMAL(14,4),JSON_VALUE(@cJson,'$.datos.precioUnitario'));
   IF @tarifa IS NULL OR @tarifa<0 OR NOT EXISTS(SELECT 1 FROM comercial.CargoConceptoE4 WHERE concepto_id=@concepto AND activo=1)
    THROW 51226,N'El concepto o tarifa no es válido.',1;
   UPDATE comercial.CargoTarifaE4 SET vigente_hasta=@fecha WHERE concepto_id=@concepto AND vigente_hasta IS NULL;
   INSERT comercial.CargoTarifaE4(concepto_id,precio_unitario,vigente_desde,usuario_id) VALUES(@concepto,@tarifa,@fecha,@usuario);
   SET @tarifaId=SCOPE_IDENTITY();
   SET @cDatos=(SELECT @tarifaId tarifaId,@tarifa precioUnitario FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='VALIDAR_FALTANTE'
  BEGIN
    UPDATE comercial.IncidenciaFaltanteE4 SET estado='CONFIRMADA',confirmado_por=@usuario,
      confirmado_en=@fecha,observacion=NULLIF(JSON_VALUE(@cJson,'$.datos.motivo'),N'')
    WHERE jaba_asignacion_id=@asig AND estado='REGISTRADA';
    IF @@ROWCOUNT<>1 THROW 51231,N'La incidencia está confirmada o no existe.',1;
    SET @cDatos=(SELECT @asig asignacionId,CONVERT(VARCHAR(16),'CONFIRMADA') estado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='CARGO'
  BEGIN
   SELECT @motivo=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.motivo'))),N'');
   IF @motivo IS NULL THROW 51227,N'Indique el motivo del cargo autorizado.',1;
   SELECT @concepto=concepto_id FROM comercial.CargoConceptoE4 WHERE codigo='JABA_PERDIDA';
   SELECT @cantidad=COUNT(1) FROM comercial.JabaUnidadE4 WHERE jaba_asignacion_id=@asig AND retorno_estado='FALTANTE';
   IF @cantidad<=0 OR NOT EXISTS(SELECT 1 FROM comercial.IncidenciaFaltanteE4
       WHERE jaba_asignacion_id=@asig AND estado='CONFIRMADA' AND cantidad=@cantidad)
    THROW 51228,N'No existe una incidencia de faltantes confirmada para cobrar.',1;
   SELECT TOP(1) @tarifaId=tarifa_id,@tarifa=precio_unitario FROM comercial.CargoTarifaE4
    WHERE concepto_id=@concepto AND vigente_desde<=@fecha AND (vigente_hasta IS NULL OR vigente_hasta>@fecha)
    ORDER BY vigente_desde DESC,tarifa_id DESC;
   IF @tarifaId IS NULL THROW 51229,N'Configure antes la tarifa vigente por jaba perdida.',1;
   IF EXISTS(SELECT 1 FROM comercial.CargoIndividualE4 WHERE jaba_asignacion_id=@asig AND concepto_id=@concepto)
    THROW 51230,N'Ya existe un cargo por faltantes de esta asignación.',1;
   INSERT INTO comercial.CargoIndividualE4(jaba_asignacion_id,concepto_id,tarifa_id,cantidad,precio_unitario,motivo,usuario_id)
    VALUES(@asig,@concepto,@tarifaId,@cantidad,@tarifa,@motivo,@usuario);
   SET @id=SCOPE_IDENTITY();
   SET @cDatos=(SELECT @id cargoId,@cantidad cantidad,@tarifa precioUnitario,
    CONVERT(DECIMAL(19,4),@cantidad*@tarifa) importe FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END;
  INSERT INTO comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta) VALUES(@usuario,@clave,@cAccion,@hash,@cDatos);
  INSERT INTO comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
   VALUES(@camp,@cAccion,COALESCE(@entrega,@unidad,@asig,@camp),@cAccion,@cDatos,@usuario);
  COMMIT TRANSACTION;
  SET @bResultado=1;
 END;
 SELECT @cCodigoRespuesta='E4_OK',@nHttpRespuesta=200,
  @cMensaje=CASE WHEN @cAccion IN('RESUMEN','UNIDADES','BALANCE') THEN N'Información consultada.' ELSE N'Operación comercial registrada.' END;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @bResultado=0,@cCodigoRespuesta='E4_ERROR',@nHttpRespuesta=CASE WHEN ERROR_NUMBER()=1205 THEN 409 ELSE 400 END,
   @cDatos=NULL,@cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN LEFT(ERROR_MESSAGE(),300)
   ELSE N'No se pudo completar la operación. Compruebe los datos e inténtelo nuevamente.' END;
 END CATCH;
END;
GO
