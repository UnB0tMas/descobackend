-- APAPPSS E5. Cada procedimiento consulta un único agregado.
-- La regla transversal de caja se protege en la tabla de pagos, incluso ante llamadas directas a otros PAs.
CREATE OR ALTER PROCEDURE finanzas.PA_E5_EntregasSocio_Sel_Detalle
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @bResultado=0,@cDatos=NULL,@cMensaje=N'No se pudo consultar la liquidación.',
  @cCodigoRespuesta='E5_ENTREGAS_ERROR',@nHttpRespuesta=400;
 IF ISJSON(@cJson)<>1 RETURN;
 DECLARE @part BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.participacionId')),
  @uot BIGINT,@asociacion BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@ok BIT,@msg NVARCHAR(300);
 SELECT @uot=C.uot_id,@asociacion=C.asociacion_id
 FROM comercial.ParticipacionCampaniaSocio P
 JOIN comercial.CampaniaVenta C ON C.campania_venta_id=P.campania_venta_id AND C.estado=1
 WHERE P.participacion_campania_socio_id=@part AND P.estado=1;
 IF @uot IS NULL BEGIN SET @cMensaje=N'Socio no encontrado en la campaña.';RETURN;END;
 BEGIN TRY
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='LIQUIDACIONES_LISTAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@ok OUTPUT,@cMensaje=@msg OUTPUT;
  IF ISNULL(@ok,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'LIQUIDACIONES_LISTAR')<>1
   THROW 51740,N'No dispone de acceso a las liquidaciones.',1;
  IF NOT EXISTS(SELECT 1 FROM org.ConvenioUOTOrganizacion CU
     JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND CM.estado=1
     JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
     WHERE CU.uot_id=@uot AND CU.empresa_id=@asociacion AND CU.estado=1
      AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,SYSUTCDATETIME()))
      AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,SYSUTCDATETIME())))
   THROW 51741,N'El convenio de la campaña no está habilitado.',1;
  SET @cDatos=(SELECT @part participacionId,
   JSON_QUERY((SELECT E.entrega_socio_id entregaId,E.codigo_lote lote,
      CONVERT(VARCHAR(19),E.fecha_hora,126) fecha,
      (SELECT COUNT(1) FROM comercial.JabaUnidadE4 U
       WHERE U.entrega_socio_id=E.entrega_socio_id AND U.pesaje_estado='PESADA') jabas,
      E.peso_bruto_kg pesoBruto,E.tara_kg tara,E.peso_rechazado_kg rechazado,E.peso_aceptado_kg aceptado
     FROM comercial.EntregaSocio E
     JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id AND OS.estado=1
     WHERE OS.participacion_campania_socio_id=@part AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
     ORDER BY E.fecha_hora,E.entrega_socio_id FOR JSON PATH)) entregas,
   JSON_QUERY((SELECT D.entrega_detalle_id detalleId,D.entrega_socio_id entregaId,
      V.nombre variedad,D.condicion_comercial_id condicionId,CC.nombre condicion,D.kilogramos,
      D.precio_base precioBase,D.precio_aplicado precioEfectivo,D.importe
     FROM comercial.EntregaDetalle D
     JOIN prod.VariedadPalta V ON V.variedad_palta_id=D.variedad_palta_id
     JOIN comercial.CondicionComercial CC ON CC.condicion_comercial_id=D.condicion_comercial_id
     JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
     JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id AND OS.estado=1
     WHERE OS.participacion_campania_socio_id=@part AND D.estado=1
     ORDER BY E.fecha_hora,D.entrega_detalle_id FOR JSON PATH)) partidas,
   JSON_QUERY((SELECT U.unidad_id unidadId,U.numero,U.peso_bruto_kg pesoBruto,
      U.tara_kg tara,U.peso_neto_kg pesoNeto
     FROM comercial.JabaUnidadE4 U
     JOIN comercial.EntregaSocio E ON E.entrega_socio_id=U.entrega_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
     JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id AND OS.estado=1
     WHERE OS.participacion_campania_socio_id=@part AND U.pesaje_estado='PESADA'
     ORDER BY U.unidad_id FOR JSON PATH)) jabas
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Entregas consultadas.',@cCodigoRespuesta='E5_ENTREGAS_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  SELECT @bResultado=0,@cMensaje=N'No fue posible consultar las entregas.',
   @cCodigoRespuesta='E5_ENTREGAS_ERROR',@nHttpRespuesta=400;
 END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE finanzas.PA_E5_CobrosCampania_Sel_Detalle
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @bResultado=0,@cDatos=NULL,@cMensaje=N'No se pudieron consultar los cobros.',
  @cCodigoRespuesta='E5_COBROS_ERROR',@nHttpRespuesta=400;
 IF ISJSON(@cJson)<>1 RETURN;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @uot BIGINT,@asociacion BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@ok BIT,@msg NVARCHAR(300);
 SELECT @uot=C.uot_id,@asociacion=C.asociacion_id
 FROM comercial.CampaniaVenta C WHERE C.campania_venta_id=@camp AND C.estado=1;
 IF @uot IS NULL BEGIN SET @cMensaje=N'Campaña no encontrada.';RETURN;END;
 BEGIN TRY
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='COBROS_VER',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@ok OUTPUT,@cMensaje=@msg OUTPUT;
  IF ISNULL(@ok,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'COBROS_VER')<>1
   THROW 51742,N'No dispone de acceso a los cobros.',1;
  IF NOT EXISTS(SELECT 1 FROM org.ConvenioUOTOrganizacion CU
     JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND CM.estado=1
     JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
     WHERE CU.uot_id=@uot AND CU.empresa_id=@asociacion AND CU.estado=1
      AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,SYSUTCDATETIME()))
      AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,SYSUTCDATETIME())))
   THROW 51743,N'El convenio de la campaña no está habilitado.',1;
  SET @cDatos=(SELECT @camp campaniaId,
   JSON_QUERY((SELECT B.cobro_comprador_id cobroId,CONVERT(VARCHAR(19),B.fecha_hora,126) fecha,
      B.importe,B.moneda,B.estado_proceso estado,B.medio_pago medioPago,B.numero_operacion numeroOperacion
    FROM finanzas.CobroComprador B WHERE B.campania_venta_id=@camp AND B.estado=1
    ORDER BY B.fecha_hora DESC,B.cobro_comprador_id DESC FOR JSON PATH)) movimientos
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Cobros consultados.',@cCodigoRespuesta='E5_COBROS_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  SELECT @bResultado=0,@cMensaje=N'No fue posible consultar los cobros.',
   @cCodigoRespuesta='E5_COBROS_ERROR',@nHttpRespuesta=400;
 END CATCH;
END;
GO

-- Invariante de caja: los pagos confirmados a socios más los gastos aprobados
-- no pueden superar la suma de los cobros confirmados del comprador.
-- Trigger necesario porque existen varios PAs que registran pagos (incluido pago por beneficiario).
CREATE OR ALTER TRIGGER finanzas.TR_E5_PagoSocio_ValidaCaja
ON finanzas.PagoSocio
AFTER INSERT,UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (
  SELECT 1 FROM (
   SELECT DISTINCT S.campania_venta_id
   FROM inserted I JOIN finanzas.LiquidacionSnapshotE5 S
    ON S.liquidacion_socio_id=I.liquidacion_socio_id
  ) Camp
  WHERE
   COALESCE((SELECT SUM(P.importe)
     FROM finanzas.PagoSocio P JOIN finanzas.LiquidacionSnapshotE5 S
      ON S.liquidacion_socio_id=P.liquidacion_socio_id
     WHERE S.campania_venta_id=Camp.campania_venta_id
      AND P.estado=1 AND P.estado_proceso='CONFIRMADO'),0)
   +COALESCE((SELECT SUM(G.importe)
     FROM finanzas.GastoCampania G
     WHERE G.campania_venta_id=Camp.campania_venta_id
      AND G.estado=1 AND G.estado_proceso='APROBADO'),0)
   >COALESCE((SELECT SUM(B.importe)
     FROM finanzas.CobroComprador B
     WHERE B.campania_venta_id=Camp.campania_venta_id
      AND B.estado=1 AND B.estado_proceso='CONFIRMADO'),0)
 )
 THROW 51744,N'Fondos insuficientes: los cobros confirmados no cubren los pagos y gastos aprobados.',1;
END;
GO
