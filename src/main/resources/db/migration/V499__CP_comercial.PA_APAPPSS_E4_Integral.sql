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
 @lockResource NVARCHAR(255),@id BIGINT,@nBruto DECIMAL(14,3),@nTara DECIMAL(14,3),@nKilos DECIMAL(14,3),@nRechazado DECIMAL(14,3),@importe DECIMAL(19,4),
 @tarifaId BIGINT,@concepto SMALLINT,@tarifa DECIMAL(14,4),@fecha DATETIME2(0)=SYSUTCDATETIME(),
 @stock INT,@stockAnterior INT,@validadas INT,@totales BIGINT,@versionEsperada BIGINT;
 IF ISJSON(@cJson)<>1 OR @cAccion NOT IN ('RESUMEN','CONFIGURAR','ASIGNAR','UNIDADES','PESAR','DEVOLVER','CONFIRMAR','SANCION','TARIFA','CARGO','BALANCE','VALIDAR_FALTANTE','SOCIOS','INCLUIR_SOCIOS','CLASIFICAR','STOCK','VALIDAR_RETORNO','PREPESAR','ANULAR_PESAJE','CORREGIR_PESAJE','HISTORIAL')
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
 WHEN 'CONFIGURAR' THEN 'CAMPANIAS_EDITAR' WHEN 'STOCK' THEN 'JABAS_ADMINISTRAR' WHEN 'HISTORIAL' THEN 'JABAS_VER' WHEN 'SOCIOS' THEN 'PARTICIPANTES_LISTAR' WHEN 'INCLUIR_SOCIOS' THEN 'PARTICIPANTES_CREAR' WHEN 'UNIDADES' THEN 'JABAS_VER'
 WHEN 'ASIGNAR' THEN 'JABAS_CREAR' WHEN 'PESAR' THEN 'ENTREGAS_CREAR' WHEN 'PREPESAR' THEN 'ENTREGAS_CREAR' WHEN 'CLASIFICAR' THEN 'ENTREGAS_CREAR'
 WHEN 'DEVOLVER' THEN 'JABAS_CREAR' WHEN 'CONFIRMAR' THEN 'ENTREGAS_CONFIRMAR' WHEN 'CORREGIR_PESAJE' THEN 'JABAS_APROBAR' WHEN 'ANULAR_PESAJE' THEN 'ENTREGAS_CONFIRMAR'
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
 IF @cAccion='SOCIOS'
 BEGIN
  SET @cDatos=(SELECT @camp campaniaId,
    JSON_QUERY((SELECT SA.socio_asociacion_id socioAsociacionId,
      CONCAT(PE.nombres,N' ',PE.apellido_paterno,N' ',COALESCE(PE.apellido_materno,N'')) nombre,
      PE.numero_documento numeroDocumento
     FROM org.SocioAsociacion SA
     JOIN org.Socio S ON S.socio_id=SA.socio_id AND S.estado=1
     JOIN org.Persona PE ON PE.persona_id=S.socio_id AND PE.estado=1
     WHERE SA.asociacion_id=@asociacion AND SA.estado=1 AND SA.situacion_membresia='ACTIVO'
       AND SA.fecha_desde<=CONVERT(DATE,@fecha)
       AND (SA.fecha_hasta IS NULL OR SA.fecha_hasta>=CONVERT(DATE,@fecha))
       AND NOT EXISTS(SELECT 1 FROM comercial.ParticipacionCampaniaSocio P
         WHERE P.campania_venta_id=@camp AND P.socio_asociacion_id=SA.socio_asociacion_id)
     ORDER BY PE.apellido_paterno,PE.nombres,SA.socio_asociacion_id
     FOR JSON PATH)) socios
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SET @bResultado=1;
 END
 ELSE IF @cAccion='RESUMEN'
 BEGIN
  SET @cDatos=(SELECT C.campania_venta_id campaniaId,C.nombre,C.estado_proceso estado,
   K.cupo_jabas cupoJabas,K.tara_kg taraKg, S.existencia_certificada stockFisico,
   (SELECT COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-COALESCE(V.cantidad_validada,0)),0)
     FROM comercial.JabaAsignacion A JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
     JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
     JOIN comercial.CampaniaVenta X ON X.campania_venta_id=O.campania_venta_id
     LEFT JOIN comercial.JabaRetornoValidadoE4 V ON V.jaba_asignacion_id=A.jaba_asignacion_id
     WHERE X.uot_id=@uot AND A.estado=1) stockRetenido,
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
   LEFT JOIN comercial.JabaStockUotE4 S ON S.uot_id=C.uot_id
   WHERE C.campania_venta_id=@camp FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SET @bResultado=1;
 END
 ELSE IF @cAccion='UNIDADES'
 BEGIN
  IF @asig IS NULL THROW 51202,N'Seleccione una asignación.',1;
  SET @cDatos=(SELECT A.jaba_asignacion_id asignacionId,A.cantidad_asignada asignadas,
   CONVERT(BIT,CASE WHEN EXISTS(SELECT 1 FROM comercial.JabaRetornoValidadoE4 V WHERE V.jaba_asignacion_id=@asig) THEN 1 ELSE 0 END) retornoValidado,
   (SELECT COUNT_BIG(1) FROM comercial.JabaUnidadE4 U WHERE U.jaba_asignacion_id=@asig AND U.pesaje_estado='PESADA') pesadas,
   (SELECT COUNT_BIG(1) FROM comercial.JabaUnidadE4 U WHERE U.jaba_asignacion_id=@asig AND U.retorno_estado LIKE 'DEVUELTA%') devueltas,
   (SELECT COUNT_BIG(1) FROM comercial.JabaUnidadE4 U WHERE U.jaba_asignacion_id=@asig AND U.retorno_estado='FALTANTE') faltantes,
   JSON_QUERY((SELECT U.unidad_id unidadId,U.numero,U.peso_bruto_kg pesoBrutoKg,U.tara_kg taraKg,U.peso_neto_kg pesoNetoKg,
     U.variedad_palta_id variedadId,U.condicion_comercial_id condicionId,U.precio_base precioBase,
     U.pesaje_estado pesaje,U.retorno_estado retorno,U.entrega_socio_id entregaId,U.version,
     JSON_QUERY((SELECT C.numero,C.peso_kg pesoKg,C.rechazada,C.variedad_palta_id variedadId,
       C.condicion_comercial_id condicionId,C.precio_base precioBase
       FROM comercial.JabaClasificacionE4 C WHERE C.unidad_id=U.unidad_id
       ORDER BY C.numero FOR JSON PATH)) clasificaciones
      FROM comercial.JabaUnidadE4 U WHERE U.jaba_asignacion_id=@asig ORDER BY U.numero FOR JSON PATH)) unidades
   FROM comercial.JabaAsignacion A WHERE A.jaba_asignacion_id=@asig FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SET @bResultado=1;
 END
 ELSE IF @cAccion='HISTORIAL'
 BEGIN
  IF @unidad IS NULL THROW 51302,N'Seleccione una unidad.',1;
  SET @cDatos=(SELECT @unidad unidadId,
   JSON_QUERY((SELECT H.historial_id historialId,H.version_anterior versionAnterior,
    H.version_nueva versionNueva,H.estado_anterior estadoAnterior,H.estado_nuevo estadoNuevo,
    H.peso_anterior pesoAnterior,H.peso_nuevo pesoNuevo,H.tara_anterior taraAnterior,
    H.tara_nueva taraNueva,H.precio_anterior precioAnterior,H.precio_nuevo precioNuevo,
    H.motivo,H.usuario_id usuarioId,H.fecha fechaHora
    FROM comercial.JabaPesajeHistorialE4 H WHERE H.unidad_id=@unidad
    ORDER BY H.historial_id FOR JSON PATH)) eventos FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SET @bResultado=1;
 END
 ELSE IF @cAccion='BALANCE'
 BEGIN
  SET @cDatos=(SELECT C.campania_venta_id campaniaId,
   COALESCE((SELECT SUM(CONVERT(DECIMAL(19,4),D.kilogramos*D.precio_base)) FROM comercial.EntregaDetalle D JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id
     JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
     WHERE O.campania_venta_id=@camp AND E.estado=1 AND E.estado_proceso='CONFIRMADA' AND D.estado=1),0) brutoConfirmado,
   COALESCE((SELECT SUM(CONVERT(DECIMAL(19,4),D.kilogramos*(D.precio_base-D.precio_aplicado)))
     FROM comercial.EntregaDetalle D JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id
     JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
     JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
     WHERE O.campania_venta_id=@camp AND E.estado=1 AND E.estado_proceso='CONFIRMADA' AND D.estado=1),0) descuentosPrecio,
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
  SET @lockResource=CONCAT(N'DESCO:E4:UOT:',@uot);
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
  IF @cAccion='STOCK'
  BEGIN
   SELECT @stock=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.existenciaCertificada')),
          @motivo=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.motivo'))),N'');
   IF @stock IS NULL OR @stock<0 OR @motivo IS NULL
     THROW 51303,N'Indique la cantidad de jabas físicamente verificadas y su motivo.',1;
   SELECT @stockAnterior=existencia_certificada FROM comercial.JabaStockUotE4 WITH(UPDLOCK,HOLDLOCK) WHERE uot_id=@uot;
   SELECT @totales=COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-COALESCE(V.cantidad_validada,0)),0)
   FROM comercial.JabaAsignacion A JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
   JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
   JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id
   LEFT JOIN comercial.JabaRetornoValidadoE4 V ON V.jaba_asignacion_id=A.jaba_asignacion_id
   WHERE C.uot_id=@uot AND A.estado=1;
   IF @stock<@totales THROW 51304,N'El inventario no puede ser inferior a las jabas todavía no validadas.',1;
   IF @stockAnterior IS NULL
     INSERT comercial.JabaStockUotE4(uot_id,existencia_certificada,actualizado_por) VALUES(@uot,@stock,@usuario);
   ELSE UPDATE comercial.JabaStockUotE4 SET existencia_certificada=@stock,version=version+1,
       actualizado_por=@usuario,actualizado_en=@fecha WHERE uot_id=@uot;
   INSERT comercial.JabaStockHistorialE4(uot_id,existencia_anterior,existencia_nueva,motivo,usuario_id)
     VALUES(@uot,@stockAnterior,@stock,@motivo,@usuario);
   SET @cDatos=(SELECT @uot uotId,@stock existenciaCertificada,@totales retenidas FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='INCLUIR_SOCIOS'
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta
     WHERE campania_venta_id=@camp AND estado=1 AND estado_proceso IN('PLANIFICACION','ACTIVA'))
     THROW 51240,N'La campaña no permite incorporar participantes.',1;
   DECLARE @ids TABLE (socio_asociacion_id BIGINT NOT NULL PRIMARY KEY);
   DECLARE @jsonIds NVARCHAR(MAX)=JSON_QUERY(@cJson,'$.datos.sociosIds');
   IF @jsonIds IS NULL OR LEFT(LTRIM(@jsonIds),1)<>'['
     THROW 51241,N'Seleccione los socios que participarán.',1;
   SELECT @cantidad=COUNT(1) FROM OPENJSON(@jsonIds);
   IF @cantidad NOT BETWEEN 1 AND 100
     THROW 51241,N'Seleccione entre 1 y 100 socios.',1;
   IF EXISTS(SELECT 1 FROM OPENJSON(@jsonIds)
       WHERE [type]<>2 OR TRY_CONVERT(BIGINT,[value]) IS NULL OR TRY_CONVERT(BIGINT,[value])<=0)
     THROW 51241,N'Los socios seleccionados no son válidos.',1;
   IF EXISTS(SELECT [value] FROM OPENJSON(@jsonIds) GROUP BY [value] HAVING COUNT(1)>1)
     THROW 51242,N'La selección contiene socios repetidos.',1;
   INSERT INTO @ids (socio_asociacion_id)
    SELECT CONVERT(BIGINT,[value]) FROM OPENJSON(@jsonIds);
   IF EXISTS(SELECT 1 FROM @ids I
     LEFT JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=I.socio_asociacion_id
       AND SA.asociacion_id=@asociacion AND SA.estado=1 AND SA.situacion_membresia='ACTIVO'
       AND SA.fecha_desde<=CONVERT(DATE,@fecha)
       AND (SA.fecha_hasta IS NULL OR SA.fecha_hasta>=CONVERT(DATE,@fecha))
     LEFT JOIN org.Socio S ON S.socio_id=SA.socio_id AND S.estado=1
     LEFT JOIN org.Persona PE ON PE.persona_id=S.socio_id AND PE.estado=1
     WHERE PE.persona_id IS NULL)
    THROW 51243,N'Uno o más socios no tienen membresía activa en esta asociación.',1;
   IF EXISTS(SELECT 1 FROM @ids I
     JOIN comercial.ParticipacionCampaniaSocio P WITH(UPDLOCK,HOLDLOCK)
       ON P.campania_venta_id=@camp AND P.socio_asociacion_id=I.socio_asociacion_id)
    THROW 51244,N'Uno de los socios ya está incluido en la campaña.',1;
   INSERT INTO comercial.ParticipacionCampaniaSocio
      (campania_venta_id,socio_asociacion_id,fecha_registro,estado_participacion,estado)
    SELECT @camp,I.socio_asociacion_id,@fecha,'ACTIVO',1 FROM @ids I;
   SET @cDatos=(SELECT @camp campaniaId,@cantidad incorporados FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE  IF @cAccion='CONFIGURAR'
  BEGIN
   SELECT @cupo=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.cupoJabas')),
    @tara=TRY_CONVERT(DECIMAL(10,3),JSON_VALUE(@cJson,'$.datos.taraKg'));
   IF @cupo IS NULL OR @cupo NOT BETWEEN 1 AND 100000 OR @tara IS NULL OR @tara<0 OR @tara>=10
    THROW 51206,N'Indique cupo y tara válidos.',1;
   SELECT @cantidadNueva=K.cupo_jabas FROM comercial.CampaniaControlE4 K WITH(UPDLOCK,HOLDLOCK)
     WHERE K.campania_venta_id=@camp;
   SELECT @ocupadas=COALESCE(SUM(A.cantidad_asignada-A.cantidad_devuelta),0) FROM comercial.JabaAsignacion A
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
   IF @cantidad IS NULL OR @cantidad NOT BETWEEN 1 AND 3000 OR @operativoSocio IS NULL OR @estado<>'EN_RECEPCION'
    THROW 51208,N'El operativo no admite esta asignación.',1;
   IF NOT EXISTS(SELECT 1 FROM comercial.OperativoSocio OS JOIN comercial.ParticipacionCampaniaSocio P
     ON P.participacion_campania_socio_id=OS.participacion_campania_socio_id AND P.estado=1 AND P.estado_participacion='ACTIVO'
     JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=P.socio_asociacion_id AND SA.estado=1 AND SA.asociacion_id=@asociacion
     WHERE OS.operativo_socio_id=@operativoSocio AND OS.estado_participacion='PROGRAMADO' AND OS.estado=1)
    THROW 51208,N'No es un socio participante activo de esta campaña.',1;
   SELECT @cupo=cupo_jabas FROM comercial.CampaniaControlE4 WITH(UPDLOCK,HOLDLOCK) WHERE campania_venta_id=@camp;
   IF @cupo IS NULL THROW 51209,N'Primero configure el cupo de campaña.',1;
   SELECT @ocupadas=COALESCE(SUM(A.cantidad_asignada-A.cantidad_devuelta),0) FROM comercial.JabaAsignacion A
    JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
    JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
    WHERE O.campania_venta_id=@camp AND A.estado=1;
   IF @cantidad+@ocupadas>@cupo THROW 51210,N'La asignación excede el cupo de campaña.',1;
   SELECT @stock=existencia_certificada FROM comercial.JabaStockUotE4 WITH(UPDLOCK,HOLDLOCK) WHERE uot_id=@uot;
   IF @stock IS NULL THROW 51300,N'No existe inventario de jabas verificado en la UOT.',1;
   SELECT @totales=COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-COALESCE(V.cantidad_validada,0)),0)
   FROM comercial.JabaAsignacion A JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
   JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
   JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id
   LEFT JOIN comercial.JabaRetornoValidadoE4 V ON V.jaba_asignacion_id=A.jaba_asignacion_id
   WHERE C.uot_id=@uot AND A.estado=1;
   IF @totales+@cantidad>@stock THROW 51301,N'La asignación supera el stock físico certificado disponible.',1;
   EXEC comercial.PA_Jabas_Sel_SaldoInterno @nOperativoVentaId=@op,@nOperativoSocioId=NULL,
    @nRecibidas=@saldo OUTPUT,@nAsignadas=@cantidadNueva OUTPUT,@nDevueltas=@devueltas OUTPUT,
    @nPendientes=@vacias OUTPUT,@nDisponibles=@llenas OUTPUT;
   IF @llenas<@cantidad THROW 51211,N'No hay jabas físicas disponibles en el operativo.',1;
   INSERT INTO comercial.JabaAsignacion(operativo_socio_id,fecha_hora,cantidad_asignada,observacion,estado,usuario_registro_id)
    VALUES(@operativoSocio,@fecha,@cantidad,NULL,1,@usuario);
   SET @asig=SCOPE_IDENTITY();

   SET @cDatos=(SELECT @asig asignacionId,@cantidad unidades FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='PREPESAR'
  BEGIN
   SELECT @peso=TRY_CONVERT(DECIMAL(14,3),JSON_VALUE(@cJson,'$.datos.pesoBrutoKg'));
   SELECT @tara=K.tara_kg FROM comercial.CampaniaControlE4 K WHERE K.campania_venta_id=@camp;
   IF @estado<>'EN_RECEPCION' OR @peso IS NULL OR @tara IS NULL OR @peso<=@tara
    THROW 51305,N'El peso preliminar debe superar la tara de campaña.',1;
   UPDATE comercial.JabaUnidadE4 SET peso_bruto_kg=@peso,tara_kg=@tara,
     pesaje_estado='PRELIMINAR',usuario_pesaje_id=@usuario,fecha_pesaje=@fecha,version=version+1
    WHERE unidad_id=@unidad AND pesaje_estado IN('SIN_PESAJE','ANULADA')
      AND entrega_socio_id IS NULL AND retorno_estado='PENDIENTE';
   IF @@ROWCOUNT<>1 THROW 51306,N'La jaba ya tiene pesaje o retorno.',1;
   SET @cDatos=(SELECT @unidad unidadId,@peso pesoBrutoKg,@tara taraKg,
    @peso-@tara pesoNetoKg,CONVERT(VARCHAR(16),'PRELIMINAR') estado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='ANULAR_PESAJE'
  BEGIN
   SELECT @motivo=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.motivo'))),N''),
    @versionEsperada=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.version'));
   IF @motivo IS NULL OR @versionEsperada IS NULL THROW 51307,N'Indique motivo y versión actual.',1;
   EXEC sys.sp_set_session_context @key=N'e4_motivo',@value=@motivo;
   UPDATE comercial.JabaUnidadE4 SET peso_bruto_kg=NULL,tara_kg=NULL,precio_base=NULL,
      precio_comercial_id=NULL,variedad_palta_id=NULL,condicion_comercial_id=NULL,
      pesaje_estado='ANULADA',usuario_pesaje_id=@usuario,fecha_pesaje=@fecha,version=version+1
   WHERE unidad_id=@unidad AND version=@versionEsperada AND pesaje_estado IN('PESADA','PRELIMINAR')
    AND retorno_estado='PENDIENTE' AND entrega_socio_id IS NULL;
   IF @@ROWCOUNT<>1 THROW 51308,N'El pesaje cambió o ya no puede anularse.',1;
   DECLARE @clasAnterior NVARCHAR(MAX)=(SELECT C.numero,C.peso_kg pesoKg,C.rechazada,
     C.variedad_palta_id variedadId,C.condicion_comercial_id condicionId,C.precio_base precioBase
     FROM comercial.JabaClasificacionE4 C WHERE C.unidad_id=@unidad ORDER BY C.numero FOR JSON PATH);
   INSERT INTO comercial.JabaClasificacionHistorialE4(unidad_id,version,anterior,actual,motivo,usuario_id)
    VALUES(@unidad,@versionEsperada+1,@clasAnterior,N'[]',@motivo,@usuario);
   DELETE FROM comercial.JabaClasificacionE4 WHERE unidad_id=@unidad;
   EXEC sys.sp_set_session_context @key=N'e4_motivo',@value=NULL;
   SET @cDatos=(SELECT @unidad unidadId,CONVERT(VARCHAR(16),'ANULADA') estado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion IN('PESAR','CORREGIR_PESAJE')
  BEGIN
   SELECT @peso=TRY_CONVERT(DECIMAL(14,3),JSON_VALUE(@cJson,'$.datos.pesoBrutoKg')),
    @variedad=TRY_CONVERT(SMALLINT,JSON_VALUE(@cJson,'$.datos.variedadId')),
    @condicion=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.condicionId'));
   SELECT @versionEsperada=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.version')),
     @motivo=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.motivo'))),N'');
   IF @peso IS NULL OR @peso<=0 OR @variedad IS NULL OR @condicion IS NULL OR @estado<>'EN_RECEPCION'
    THROW 51212,N'Peso, variedad y condición son obligatorios.',1;
   IF @cAccion='CORREGIR_PESAJE' AND (@motivo IS NULL OR @versionEsperada IS NULL)
    THROW 51309,N'La corrección necesita motivo y versión vigente.',1;
   SELECT @tara=K.tara_kg FROM comercial.CampaniaControlE4 K WHERE K.campania_venta_id=@camp;
   IF @cAccion='CORREGIR_PESAJE' AND JSON_VALUE(@cJson,'$.datos.taraExcepcionalKg') IS NOT NULL
   BEGIN
     SET @tara=TRY_CONVERT(DECIMAL(10,3),JSON_VALUE(@cJson,'$.datos.taraExcepcionalKg'));
     IF @tara IS NULL OR @tara<0 OR @tara>=10 OR @motivo IS NULL
       THROW 51313,N'La tara excepcional necesita autorización y motivo.',1;
   END;
   IF @tara IS NULL OR @peso<=@tara THROW 51213,N'El peso bruto debe superar la tara.',1;
   SELECT TOP(1) @precioId=P.precio_comercial_id,@precio=P.precio FROM comercial.PrecioComercial P
    WHERE P.campania_venta_id=@camp AND (P.operativo_venta_id=@op OR P.operativo_venta_id IS NULL)
     AND P.variedad_palta_id=@variedad AND P.condicion_comercial_id=@condicion AND P.estado=1
     AND P.fecha_vigencia_desde<=@fecha AND (P.fecha_vigencia_hasta IS NULL OR P.fecha_vigencia_hasta>=@fecha)
    ORDER BY CASE WHEN P.operativo_venta_id=@op THEN 0 ELSE 1 END,P.version DESC;
   IF @precioId IS NULL THROW 51214,N'La campaña no tiene precio vigente para esa clasificación.',1;
   IF @cAccion='CORREGIR_PESAJE'
      EXEC sys.sp_set_session_context @key=N'e4_motivo',@value=@motivo;
   UPDATE comercial.JabaUnidadE4 SET peso_bruto_kg=@peso,tara_kg=@tara,
    variedad_palta_id=@variedad,condicion_comercial_id=@condicion,precio_comercial_id=@precioId,
    precio_base=@precio,pesaje_estado='PESADA',usuario_pesaje_id=@usuario,fecha_pesaje=@fecha,version=version+1
    WHERE unidad_id=@unidad AND retorno_estado='PENDIENTE' AND entrega_socio_id IS NULL
      AND ((@cAccion='PESAR' AND pesaje_estado IN('SIN_PESAJE','PRELIMINAR','ANULADA'))
       OR (@cAccion='CORREGIR_PESAJE' AND pesaje_estado='PESADA' AND version=@versionEsperada));
   IF @@ROWCOUNT<>1 THROW 51215,N'La unidad cambió de versión, ya tiene pesaje o fue cerrada.',1;
   IF @cAccion='CORREGIR_PESAJE'
   BEGIN
    DECLARE @clasAntes NVARCHAR(MAX)=(SELECT C.numero,C.peso_kg pesoKg,C.rechazada,
      C.variedad_palta_id variedadId,C.condicion_comercial_id condicionId,C.precio_base precioBase
      FROM comercial.JabaClasificacionE4 C WHERE C.unidad_id=@unidad ORDER BY C.numero FOR JSON PATH);
    INSERT INTO comercial.JabaClasificacionHistorialE4(unidad_id,version,anterior,actual,motivo,usuario_id)
      VALUES(@unidad,@versionEsperada+1,@clasAntes,N'[]',@motivo,@usuario);
    DELETE FROM comercial.JabaClasificacionE4 WHERE unidad_id=@unidad;
    EXEC sys.sp_set_session_context @key=N'e4_motivo',@value=NULL;
   END;
   INSERT INTO comercial.JabaClasificacionE4
    (unidad_id,numero,peso_kg,rechazada,variedad_palta_id,condicion_comercial_id,
     precio_comercial_id,precio_base,usuario_id)
    VALUES(@unidad,1,@peso-@tara,0,@variedad,@condicion,@precioId,@precio,@usuario);
   SET @cDatos=(SELECT @unidad unidadId,@peso pesoBrutoKg,@tara taraKg,@peso-@tara pesoNetoKg,@precio precioBase FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='CLASIFICAR'
  BEGIN
   DECLARE @lineas TABLE(numero INT PRIMARY KEY,peso DECIMAL(14,3),rechazada BIT,
     variedad SMALLINT NULL,condicion BIGINT NULL);
   DECLARE @original NVARCHAR(MAX),@actual NVARCHAR(MAX),@pesoNeto DECIMAL(14,3),@versionClas BIGINT,@fechaPrecio DATETIME2(0);
   DECLARE @input NVARCHAR(MAX)=JSON_QUERY(@cJson,'$.datos.lineas');
   SET @motivo=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.motivo'))),N'');
   IF @input IS NULL OR LEFT(LTRIM(@input),1)<>'[' OR @motivo IS NULL
     THROW 51260,N'Indique la clasificación y el motivo.',1;
   INSERT INTO @lineas(numero,peso,rechazada,variedad,condicion)
   SELECT TRY_CONVERT(INT,J.[key])+1,L.pesoKg,L.rechazada,L.variedadId,L.condicionId
   FROM OPENJSON(@input) J CROSS APPLY OPENJSON(J.[value]) WITH(
      pesoKg DECIMAL(14,3) '$.pesoKg',rechazada BIT '$.rechazada',
      variedadId SMALLINT '$.variedadId',condicionId BIGINT '$.condicionId') L;
   SELECT @cantidad=COUNT(1),@nKilos=SUM(peso) FROM @lineas;
   SELECT @pesoNeto=U.peso_neto_kg,@versionClas=U.version,@fechaPrecio=U.fecha_pesaje
     FROM comercial.JabaUnidadE4 U WITH(UPDLOCK,HOLDLOCK)
     WHERE U.unidad_id=@unidad AND U.pesaje_estado='PESADA'
       AND U.retorno_estado IN('PENDIENTE','DEVUELTA_LLENA') AND U.entrega_socio_id IS NULL;
   IF @estado<>'EN_RECEPCION' OR @pesoNeto IS NULL OR @cantidad NOT BETWEEN 1 AND 10
      OR @nKilos<>@pesoNeto OR EXISTS(SELECT 1 FROM @lineas WHERE peso IS NULL OR peso<=0
        OR rechazada IS NULL OR (rechazada=0 AND (variedad IS NULL OR condicion IS NULL)))
     THROW 51261,N'Los pesos y clasificaciones deben sumar exactamente el neto de la jaba.',1;
   IF EXISTS(SELECT 1 FROM @lineas L OUTER APPLY (
        SELECT TOP(1) P.precio_comercial_id FROM comercial.PrecioComercial P
        WHERE P.campania_venta_id=@camp AND (P.operativo_venta_id=@op OR P.operativo_venta_id IS NULL)
          AND P.variedad_palta_id=L.variedad AND P.condicion_comercial_id=L.condicion
          AND P.estado=1 AND P.fecha_vigencia_desde<=@fechaPrecio
          AND (P.fecha_vigencia_hasta IS NULL OR P.fecha_vigencia_hasta>=@fechaPrecio)
        ORDER BY CASE WHEN P.operativo_venta_id=@op THEN 0 ELSE 1 END,P.version DESC
    ) P WHERE L.rechazada=0 AND P.precio_comercial_id IS NULL)
     THROW 51262,N'No existe precio vigente para alguna clasificación aceptada.',1;
   SET @original=(SELECT C.numero,C.peso_kg pesoKg,C.rechazada,
       C.variedad_palta_id variedadId,C.condicion_comercial_id condicionId,C.precio_base precioBase
       FROM comercial.JabaClasificacionE4 C WHERE C.unidad_id=@unidad ORDER BY C.numero FOR JSON PATH);
   DELETE FROM comercial.JabaClasificacionE4 WHERE unidad_id=@unidad;
   INSERT INTO comercial.JabaClasificacionE4
     (unidad_id,numero,peso_kg,rechazada,variedad_palta_id,condicion_comercial_id,
      precio_comercial_id,precio_base,usuario_id)
   SELECT @unidad,L.numero,L.peso,L.rechazada,
     CASE WHEN L.rechazada=1 THEN NULL ELSE L.variedad END,
     CASE WHEN L.rechazada=1 THEN NULL ELSE L.condicion END,
     CASE WHEN L.rechazada=1 THEN NULL ELSE P.precio_comercial_id END,
     CASE WHEN L.rechazada=1 THEN NULL ELSE P.precio END,@usuario
   FROM @lineas L OUTER APPLY (
     SELECT TOP(1) P.precio_comercial_id,P.precio FROM comercial.PrecioComercial P
     WHERE P.campania_venta_id=@camp AND (P.operativo_venta_id=@op OR P.operativo_venta_id IS NULL)
       AND P.variedad_palta_id=L.variedad AND P.condicion_comercial_id=L.condicion
       AND P.estado=1 AND P.fecha_vigencia_desde<=@fechaPrecio
       AND (P.fecha_vigencia_hasta IS NULL OR P.fecha_vigencia_hasta>=@fechaPrecio)
     ORDER BY CASE WHEN P.operativo_venta_id=@op THEN 0 ELSE 1 END,P.version DESC
   ) P;
   UPDATE comercial.JabaUnidadE4 SET version=version+1 WHERE unidad_id=@unidad;
   SET @actual=(SELECT C.numero,C.peso_kg pesoKg,C.rechazada,
       C.variedad_palta_id variedadId,C.condicion_comercial_id condicionId,C.precio_base precioBase
       FROM comercial.JabaClasificacionE4 C WHERE C.unidad_id=@unidad ORDER BY C.numero FOR JSON PATH);
   INSERT INTO comercial.JabaClasificacionHistorialE4
     (unidad_id,version,anterior,actual,motivo,usuario_id)
      VALUES(@unidad,@versionClas+1,@original,@actual,@motivo,@usuario);
   SET @cDatos=(SELECT @unidad unidadId,@cantidad lineas,
     COALESCE((SELECT SUM(peso) FROM @lineas WHERE rechazada=0),0) kilosAceptados,
     COALESCE((SELECT SUM(peso) FROM @lineas WHERE rechazada=1),0) kilosRechazados
     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
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
   IF EXISTS(SELECT 1 FROM comercial.JabaUnidadE4 WHERE jaba_asignacion_id=@asig AND pesaje_estado='PRELIMINAR')
    THROW 51314,N'Confirme o anule todos los pesajes preliminares antes de la devolución.',1;
   UPDATE comercial.JabaUnidadE4 SET retorno_estado='DEVUELTA_LLENA',usuario_retorno_id=@usuario,fecha_retorno=@fecha,version=version+1
    WHERE jaba_asignacion_id=@asig AND pesaje_estado='PESADA' AND retorno_estado='PENDIENTE';
   ;WITH V AS(SELECT TOP(@vacias) unidad_id FROM comercial.JabaUnidadE4
    WHERE jaba_asignacion_id=@asig AND pesaje_estado IN('SIN_PESAJE','ANULADA') AND retorno_estado='PENDIENTE' ORDER BY numero)
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
  ELSE IF @cAccion='VALIDAR_RETORNO'
  BEGIN
   SELECT @motivo=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.motivo'))),N'');
   SELECT @cantidad=COUNT(1) FROM comercial.JabaUnidadE4
     WHERE jaba_asignacion_id=@asig AND retorno_estado LIKE 'DEVUELTA%';
   IF @asig IS NULL OR @cantidad=0 OR NOT EXISTS(SELECT 1 FROM comercial.JabaDevolucion
     WHERE jaba_asignacion_id=@asig AND estado=1)
     THROW 51310,N'No existe devolución física declarada para inspeccionar.',1;
   IF EXISTS(SELECT 1 FROM comercial.JabaRetornoValidadoE4 WHERE jaba_asignacion_id=@asig)
     THROW 51311,N'La devolución ya fue inspeccionada y validada.',1;
   INSERT comercial.JabaRetornoValidadoE4(jaba_asignacion_id,cantidad_validada,observacion,validado_por)
    VALUES(@asig,@cantidad,@motivo,@usuario);
   SET @cDatos=(SELECT @asig asignacionId,@cantidad validadas FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
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
   IF EXISTS(SELECT 1 FROM comercial.JabaUnidadE4 U
     OUTER APPLY(SELECT SUM(C.peso_kg) clasificados FROM comercial.JabaClasificacionE4 C WHERE C.unidad_id=U.unidad_id) X
     WHERE U.jaba_asignacion_id=@asig AND U.pesaje_estado='PESADA'
       AND (X.clasificados IS NULL OR X.clasificados<>U.peso_neto_kg))
    THROW 51263,N'No puede confirmar jabas sin clasificar completamente.',1;
   SELECT @nRechazado=COALESCE(SUM(C.peso_kg),0) FROM comercial.JabaClasificacionE4 C
    JOIN comercial.JabaUnidadE4 U ON U.unidad_id=C.unidad_id
    WHERE U.jaba_asignacion_id=@asig AND C.rechazada=1;
   SET @nKilos=@nKilos-@nRechazado;
   IF @nKilos<=0 THROW 51264,N'La entrega debe contener kilos aceptados.',1;
   INSERT INTO comercial.EntregaSocio(operativo_socio_id,predio_id,codigo_lote,fecha_hora,peso_bruto_kg,tara_kg,peso_rechazado_kg,
     estado_control_calidad,ticket_balanza,observacion,estado_proceso,estado)
    VALUES(@operativoSocio,NULL,CONCAT('E4-',@asig),@fecha,@nBruto,@nTara,@nRechazado,CASE WHEN @nRechazado>0 THEN 'OBSERVADO' ELSE 'CONFORME' END,NULL,N'Acopio individual APAPPSS E4','REGISTRADA',1);
   SET @entrega=SCOPE_IDENTITY();
   INSERT INTO comercial.EntregaDetalle(entrega_socio_id,variedad_palta_id,condicion_comercial_id,precio_comercial_id,kilogramos,precio_base,precio_aplicado,estado)
    SELECT @entrega,C.variedad_palta_id,C.condicion_comercial_id,C.precio_comercial_id,
      SUM(C.peso_kg),C.precio_base,C.precio_base,1
    FROM comercial.JabaClasificacionE4 C
    JOIN comercial.JabaUnidadE4 U ON U.unidad_id=C.unidad_id
    WHERE U.jaba_asignacion_id=@asig AND U.pesaje_estado='PESADA' AND C.rechazada=0
    GROUP BY C.variedad_palta_id,C.condicion_comercial_id,C.precio_comercial_id,C.precio_base;
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
   IF EXISTS(SELECT 1 FROM comercial.EntregaDetalle D
     WHERE D.entrega_socio_id=@entrega AND D.estado=1
       AND (@condicion IS NULL OR D.condicion_comercial_id=@condicion)
       AND (@variedad IS NULL OR D.variedad_palta_id=@variedad)
       AND D.precio_aplicado<>D.precio_base)
    THROW 51245,N'No puede sancionarse de nuevo un precio que ya se ajustó.',1;
   INSERT INTO comercial.SancionSocioE4(entrega_socio_id,condicion_comercial_id,variedad_palta_id,kilos_afectados,precio_original,precio_nuevo,motivo,usuario_id)
    VALUES(@entrega,@condicion,@variedad,@nKilos,@precio,@nuevo,@motivo,@usuario);
   SET @id=SCOPE_IDENTITY();
   UPDATE D SET precio_aplicado=@nuevo
    FROM comercial.EntregaDetalle D
    WHERE D.entrega_socio_id=@entrega AND D.estado=1
      AND (@condicion IS NULL OR D.condicion_comercial_id=@condicion)
      AND (@variedad IS NULL OR D.variedad_palta_id=@variedad)
      AND D.precio_aplicado=D.precio_base;
   IF @@ROWCOUNT=0 THROW 51312,N'El precio efectivo ya fue corregido por otra operación.',1;
   UPDATE comercial.SancionSocioE4 SET aplicada_detalle=1 WHERE sancion_id=@id;
   SET @cDatos=(SELECT @id sancionId,@nKilos kilosAfectados,@precio precioOriginal,@nuevo precioNuevo,
     CONVERT(DECIMAL(19,4),@nKilos*(@precio-@nuevo)) descuento FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='TARIFA'
  BEGIN
   SELECT @concepto=concepto_id FROM comercial.CargoConceptoE4
    WHERE codigo='JABA_PERDIDA' AND activo=1;
   SELECT @tarifa=TRY_CONVERT(DECIMAL(14,4),JSON_VALUE(@cJson,'$.datos.precioUnitario'));
   IF @tarifa IS NULL OR @tarifa<0 OR @concepto IS NULL OR NOT EXISTS(SELECT 1 FROM comercial.CargoConceptoE4 WHERE concepto_id=@concepto AND activo=1)
    THROW 51226,N'El concepto o tarifa no es válido.',1;
   UPDATE comercial.CargoTarifaE4 SET vigente_hasta=@fecha WHERE concepto_id=@concepto AND campania_venta_id=@camp AND vigente_hasta IS NULL;
   INSERT comercial.CargoTarifaE4(concepto_id,precio_unitario,vigente_desde,usuario_id,campania_venta_id) VALUES(@concepto,@tarifa,@fecha,@usuario,@camp);
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
    WHERE concepto_id=@concepto AND campania_venta_id=@camp AND vigente_desde<=@fecha AND (vigente_hasta IS NULL OR vigente_hasta>@fecha)
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
  @cMensaje=CASE WHEN @cAccion IN('RESUMEN','UNIDADES','BALANCE','SOCIOS','HISTORIAL') THEN N'Información consultada.' ELSE N'Operación comercial registrada.' END;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  EXEC sys.sp_set_session_context @key=N'e4_motivo',@value=NULL;
  SELECT @bResultado=0,@cCodigoRespuesta='E4_ERROR',@nHttpRespuesta=CASE WHEN ERROR_NUMBER() IN (51200,51201) THEN 403 WHEN ERROR_NUMBER() IN (1205,51204,51205,51207,51210,51211,51215,51217,51220,51223,51230,51231,51244,51261,51263,51301,51304,51306,51308,51311,51312) THEN 409 ELSE 400 END,
   @cDatos=NULL,@cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN LEFT(ERROR_MESSAGE(),300)
   ELSE N'No se pudo completar la operación. Compruebe los datos e inténtelo nuevamente.' END;
 END CATCH;
END;
GO
