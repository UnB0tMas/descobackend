-- DESCO / APAPPSS E5: reglas de gastos y cierre financiero automático.
-- V664: ninguna migración previa se modifica.
-- NULL representa una acción de sistema, no una identidad de empleado inventada.
ALTER TABLE comercial.CierreCampaniaE5 ALTER COLUMN usuario_id BIGINT NULL;
GO
CREATE OR ALTER PROCEDURE finanzas.PA_E5_Campania_CierreAutomatico
 @campaniaId BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @hoy DATE=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()));
 -- Vencimiento comercial independiente del procesamiento financiero.
 UPDATE comercial.CampaniaVenta
 SET estado_proceso='VENCIDA'
 WHERE campania_venta_id=@campaniaId AND estado=1 AND estado_proceso='ACTIVA' AND fecha_fin<@hoy;
 IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta WITH(UPDLOCK,HOLDLOCK)
    WHERE campania_venta_id=@campaniaId AND estado=1 AND estado_proceso='VENCIDA' AND fecha_fin<@hoy) RETURN;
 IF EXISTS(SELECT 1 FROM comercial.CierreCampaniaE5 WHERE campania_venta_id=@campaniaId) RETURN;
 IF EXISTS(SELECT 1 FROM finanzas.GastoCampania G WHERE G.campania_venta_id=@campaniaId AND G.estado=1 AND G.estado_proceso<>'APROBADO') RETURN;
 IF EXISTS(SELECT 1 FROM finanzas.CobroComprador B WHERE B.campania_venta_id=@campaniaId AND B.estado=1 AND B.estado_proceso NOT IN('CONFIRMADO','ANULADO')) RETURN;
 IF EXISTS(SELECT 1 FROM comercial.OperativoVenta O JOIN comercial.OperativoSocio OS ON OS.operativo_venta_id=O.operativo_venta_id
    JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1
    WHERE O.campania_venta_id=@campaniaId AND E.estado_proceso<>'CONFIRMADA') RETURN;
 IF EXISTS(SELECT 1 FROM comercial.OperativoVenta O JOIN comercial.OperativoSocio OS ON OS.operativo_venta_id=O.operativo_venta_id
    JOIN comercial.JabaAsignacion A ON A.operativo_socio_id=OS.operativo_socio_id AND A.estado=1
    WHERE O.campania_venta_id=@campaniaId AND NOT EXISTS(SELECT 1 FROM comercial.JabaRetornoValidadoE4 V WHERE V.jaba_asignacion_id=A.jaba_asignacion_id)) RETURN;
 -- Todos los socios vendedores deben tener liquidación aprobada y saldo pagado o regularizado.
 IF EXISTS(
    SELECT 1 FROM comercial.ParticipacionCampaniaSocio P
    WHERE P.campania_venta_id=@campaniaId AND P.estado=1
      AND EXISTS(SELECT 1 FROM comercial.OperativoSocio OS
        JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
        JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1 AND D.kilogramos>0
        WHERE OS.participacion_campania_socio_id=P.participacion_campania_socio_id)
      AND NOT EXISTS(
        SELECT 1 FROM (
          SELECT TOP(1) L.liquidacion_socio_id,L.importe_neto,L.estado_proceso
          FROM finanzas.LiquidacionSocio L
          WHERE L.participacion_campania_socio_id=P.participacion_campania_socio_id AND L.estado=1 AND L.estado_proceso<>'ANULADA'
          ORDER BY L.version DESC
        ) Ult
        OUTER APPLY (SELECT COALESCE(SUM(PG.importe),0) importe
          FROM finanzas.PagoSocio PG WHERE PG.liquidacion_socio_id=Ult.liquidacion_socio_id AND PG.estado=1 AND PG.estado_proceso='CONFIRMADO') Q
        WHERE Ult.estado_proceso IN('APROBADA','PAGADA_PARCIAL','PAGADA') AND Ult.importe_neto>=0
          AND ROUND(Ult.importe_neto-Q.importe,2)=0
      )
 ) RETURN;
 -- Deben estar conciliados también los importes por cobrar al comprador.
 DECLARE @venta DECIMAL(19,4),@cobrado DECIMAL(19,4);
 SELECT @venta=COALESCE(SUM(D.importe),0)
 FROM comercial.EntregaDetalle D JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
 JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
 JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
 WHERE O.campania_venta_id=@campaniaId AND D.estado=1;
 SELECT @cobrado=COALESCE(SUM(B.importe),0) FROM finanzas.CobroComprador B
 WHERE B.campania_venta_id=@campaniaId AND B.estado=1 AND B.estado_proceso='CONFIRMADO';
 IF @cobrado<@venta RETURN;
 DECLARE @balance NVARCHAR(MAX)=(SELECT @campaniaId campaniaId,SYSUTCDATETIME() fecha,
   @venta ventaEfectiva,@cobrado cobros,
   (SELECT COALESCE(SUM(G.importe),0) FROM finanzas.GastoCampania G WHERE G.campania_venta_id=@campaniaId AND G.estado=1 AND G.estado_proceso='APROBADO') gastos,
   (SELECT COALESCE(SUM(L.importe_neto),0) FROM finanzas.LiquidacionSocio L
     JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
     WHERE P.campania_venta_id=@campaniaId AND L.estado=1 AND L.estado_proceso='APROBADA') netoAprobado
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 UPDATE comercial.CampaniaVenta SET estado_proceso='CERRADA'
 WHERE campania_venta_id=@campaniaId AND estado=1 AND estado_proceso='VENCIDA';
 IF @@ROWCOUNT<>1 RETURN;
 INSERT comercial.CierreCampaniaE5(campania_venta_id,usuario_id,observacion,excepcion_autorizada,balance_final)
 VALUES(@campaniaId,NULL,N'Cierre automático por vencimiento y obligaciones financieras concluidas.',0,@balance);
END;
GO
CREATE OR ALTER PROCEDURE finanzas.PA_APAPPSS_E5_Ejecutar
 @cAccion VARCHAR(40), @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT,
 @bResultado BIT OUTPUT, @cMensaje NVARCHAR(300) OUTPUT,
 @cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='E5_ERROR',@nHttpRespuesta=400,
   @cMensaje=N'No se pudo completar la operación financiera.';
 IF ISJSON(@cJson)<>1 OR @cAccion NOT IN
 ('TABLERO','GASTOS','REPARTIR','APROBAR_REPARTO','RECTIFICAR_REPARTO','REPARTO','LIQUIDAR','APROBAR','OBSERVAR',
 'LIQUIDACIONES','LIQUIDACION','PAGAR','REVERSAR','REPORTE','EXPORTAR','CIERRE_VALIDAR','COBROS')
 BEGIN SET @cMensaje=N'Operación no reconocida.';RETURN;END;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @gasto BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.gastoId')),
  @part BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.participacionId')),
  @liq BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.liquidacionId')),
  @pago BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.pagoId')),
  @uot BIGINT,@asociacion BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
  @ok BIT,@msg NVARCHAR(300),@perm VARCHAR(60),@fecha DATETIME2(0)=SYSUTCDATETIME(),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @hash VARBINARY(32),@hashAnterior VARBINARY(32),@resAnterior NVARCHAR(MAX),
  @mutacion BIT=0,@applock INT,@version INT,@id BIGINT,@cantidad INT,@centavos BIGINT,@baseCent BIGINT,@sobrante INT,
  @total DECIMAL(19,4),@moneda CHAR(3),@motivo NVARCHAR(800),@esperado BIGINT,
  @bruto DECIMAL(19,4),@efectivo DECIMAL(19,4),@ajuste DECIMAL(19,4),@cargos DECIMAL(19,4),
  @gastos DECIMAL(19,4),@descuentos DECIMAL(19,4),@bonos DECIMAL(19,4),@neto DECIMAL(19,4),
  @redondeo DECIMAL(19,4),@kilos DECIMAL(19,3),@pagado DECIMAL(19,4),@saldo DECIMAL(19,4),@importe DECIMAL(19,4),
  @fuentes NVARCHAR(MAX),@huella VARBINARY(32),@nuevoId BIGINT,@estado VARCHAR(30),
  @lockResource NVARCHAR(200),@balanceJson NVARCHAR(MAX),@excepcion BIT=0,@pendientes INT=0,@pagosPendientes INT=0,@cobrosPendientes DECIMAL(19,4)=0,
  @regla VARCHAR(30),@baseTotal DECIMAL(28,8);
 IF @liq IS NOT NULL SELECT @part=L.participacion_campania_socio_id FROM finanzas.LiquidacionSocio L WHERE L.liquidacion_socio_id=@liq;
 IF @pago IS NOT NULL SELECT @liq=P.liquidacion_socio_id FROM finanzas.PagoSocio P WHERE P.pago_socio_id=@pago;
 IF @liq IS NOT NULL SELECT @part=L.participacion_campania_socio_id FROM finanzas.LiquidacionSocio L WHERE L.liquidacion_socio_id=@liq;
 IF @part IS NOT NULL SELECT @camp=P.campania_venta_id FROM comercial.ParticipacionCampaniaSocio P WHERE P.participacion_campania_socio_id=@part AND P.estado=1;
 IF @gasto IS NOT NULL SELECT @camp=G.campania_venta_id FROM finanzas.GastoCampania G WHERE G.gasto_campania_id=@gasto AND G.estado=1;
 SELECT @uot=C.uot_id,@asociacion=C.asociacion_id FROM comercial.CampaniaVenta C WHERE C.campania_venta_id=@camp AND C.estado=1;
 IF @uot IS NULL BEGIN SET @cMensaje=N'Seleccione una campaña vigente.';RETURN;END;
 SET @perm=CASE @cAccion WHEN 'TABLERO' THEN 'LIQUIDACIONES_LISTAR' WHEN 'GASTOS' THEN 'GASTOS_LISTAR'
 WHEN 'REPARTO' THEN 'GASTOS_VER' WHEN 'REPARTIR' THEN 'GASTOS_CREAR'
 WHEN 'APROBAR_REPARTO' THEN 'GASTOS_APROBAR' WHEN 'RECTIFICAR_REPARTO' THEN 'GASTOS_APROBAR' WHEN 'LIQUIDACIONES' THEN 'LIQUIDACIONES_LISTAR'
 WHEN 'LIQUIDACION' THEN 'LIQUIDACIONES_VER' WHEN 'LIQUIDAR' THEN 'LIQUIDACIONES_CREAR'
 WHEN 'APROBAR' THEN 'LIQUIDACIONES_APROBAR' WHEN 'OBSERVAR' THEN 'LIQUIDACIONES_EDITAR'
 WHEN 'PAGAR' THEN 'PAGOS_CONFIRMAR' WHEN 'REVERSAR' THEN 'PAGOS_RETIRAR'
 WHEN 'REPORTE' THEN 'REPORTES_VER' WHEN 'EXPORTAR' THEN 'REPORTES_EXPORTAR' WHEN 'COBROS' THEN 'COBROS_VER'
 WHEN 'CIERRE_VALIDAR' THEN 'CAMPANIAS_VER' ELSE 'CAMPANIAS_ADMINISTRAR' END;
 BEGIN TRY
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso=@perm,
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@ok OUTPUT,@cMensaje=@msg OUTPUT;
  IF ISNULL(@ok,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,@perm)<>1
   THROW 51600,N'No dispone del permiso territorial solicitado.',1;
  IF NOT EXISTS(SELECT 1 FROM org.ConvenioUOTOrganizacion CU
     JOIN org.ConvenioModuloEspecial M ON M.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND M.estado=1
     JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=M.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
     WHERE CU.uot_id=@uot AND CU.empresa_id=@asociacion AND CU.estado=1
      AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,@fecha))
      AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,@fecha)))
   THROW 51601,N'El convenio APAPPSS no está habilitado para esta UOT.',1;
  SET @mutacion=CASE WHEN @cAccion IN('REPARTIR','APROBAR_REPARTO','RECTIFICAR_REPARTO','LIQUIDAR','APROBAR','OBSERVAR','PAGAR','REVERSAR','CERRAR') THEN 1 ELSE 0 END;
  IF @mutacion=1
  BEGIN
   IF @clave IS NULL THROW 51602,N'La operación necesita clave de idempotencia.',1;
   BEGIN TRANSACTION;
   SET @lockResource=CONCAT('APAPPSS_E5_CAMP_',@camp);
   EXEC @applock=sys.sp_getapplock @Resource=@lockResource,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
   IF @applock<0 THROW 51603,N'La campaña está siendo procesada. Vuelva a intentar.',1;
   SET @hash=HASHBYTES('SHA2_256',CONCAT(@cAccion,N'|',COALESCE(CONVERT(NVARCHAR(30),@gasto),N''),N'|',
     COALESCE(CONVERT(NVARCHAR(30),@part),N''),N'|',COALESCE(CONVERT(NVARCHAR(30),@liq),N''),N'|',
     COALESCE(CONVERT(NVARCHAR(30),@pago),N''),N'|',COALESCE(JSON_QUERY(@cJson,'$.datos'),N'{}')));
   SELECT @hashAnterior=S.huella,@resAnterior=S.respuesta FROM finanzas.SolicitudE5 S WITH(UPDLOCK,HOLDLOCK)
     WHERE S.usuario_id=@usuario AND S.clave=@clave;
   IF @hashAnterior IS NOT NULL
   BEGIN
     IF @hashAnterior<>@hash THROW 51604,N'La clave ya corresponde a una operación diferente.',1;
     SET @cDatos=@resAnterior;SET @bResultado=1;SET @cCodigoRespuesta='E5_REINTENTO';SET @cMensaje=N'Operación ya registrada.';
     SET @nHttpRespuesta=200;COMMIT TRANSACTION;RETURN;
   END;
   -- Las campañas sin activar o canceladas no generan movimientos financieros.
   -- Una campaña vencida/cerrada conserva las liquidaciones y pagos pendientes.
   IF NOT EXISTS (SELECT 1 FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK)
                  WHERE C.campania_venta_id=@camp AND C.estado=1
                    AND C.estado_proceso IN ('ACTIVA','VENCIDA','CERRADA'))
     THROW 51670,N'Active la campaña antes de registrar movimientos financieros.',1;
   IF @cAccion IN ('REPARTIR','APROBAR_REPARTO','RECTIFICAR_REPARTO')
      AND NOT EXISTS (SELECT 1 FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK)
                       WHERE C.campania_venta_id=@camp AND C.estado_proceso='ACTIVA'
                         AND CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())) BETWEEN C.fecha_inicio AND C.fecha_fin)
     THROW 51671,N'Los gastos y repartos solo se modifican durante la vigencia de la campaña.',1;
   IF EXISTS(SELECT 1 FROM comercial.CierreCampaniaE5 WHERE campania_venta_id=@camp)
    THROW 51605,N'El cierre financiero definitivo solo admite consultas.',1;
  END;

  IF @cAccion IN('TABLERO','REPORTE','EXPORTAR')
  BEGIN
    SET @cDatos=(SELECT C.campania_venta_id campaniaId,C.nombre,
     CASE WHEN C.estado_proceso='ACTIVA' AND C.fecha_fin<CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()))
          THEN 'VENCIDA' ELSE C.estado_proceso END estado,
     CONVERT(BIT,CASE WHEN X.campania_venta_id IS NULL THEN 0 ELSE 1 END) cerrada,
     (SELECT COUNT(DISTINCT OS.participacion_campania_socio_id) FROM comercial.EntregaSocio E
      JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
      JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1 AND D.kilogramos>0
      JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
      WHERE O.campania_venta_id=@camp AND E.estado=1 AND E.estado_proceso='CONFIRMADA') vendedores,
     (SELECT COALESCE(SUM(D.kilogramos),0) FROM comercial.EntregaDetalle D
      JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id
      JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
      JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
      WHERE O.campania_venta_id=@camp AND E.estado=1 AND E.estado_proceso='CONFIRMADA' AND D.estado=1) kilogramos,
     (SELECT COALESCE(SUM(D.kilogramos*D.precio_base),0) FROM comercial.EntregaDetalle D
      JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id
      JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
      JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
      WHERE O.campania_venta_id=@camp AND E.estado=1 AND E.estado_proceso='CONFIRMADA' AND D.estado=1) bruto,
     (SELECT COALESCE(SUM(D.importe),0) FROM comercial.EntregaDetalle D
      JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id
      JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
      JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
      WHERE O.campania_venta_id=@camp AND E.estado=1 AND E.estado_proceso='CONFIRMADA' AND D.estado=1) ventaAjustada,
     (SELECT COALESCE(SUM(L.importe_neto),0) FROM finanzas.LiquidacionSocio L
      JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
      WHERE P.campania_venta_id=@camp AND L.estado=1 AND L.estado_proceso='APROBADA') netoAprobado,
     (SELECT COALESCE(SUM(PG.importe),0) FROM finanzas.PagoSocio PG
      JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=PG.liquidacion_socio_id
      JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
      WHERE P.campania_venta_id=@camp AND PG.estado=1 AND PG.estado_proceso='CONFIRMADO') pagado,
     (SELECT COALESCE(SUM(G.importe),0) FROM finanzas.GastoCampania G WHERE G.campania_venta_id=@camp AND G.estado=1 AND G.estado_proceso='APROBADO') gastoComun,
     (SELECT COALESCE(SUM(CI.importe),0) FROM comercial.CargoIndividualE4 CI
      JOIN comercial.JabaAsignacion A ON A.jaba_asignacion_id=CI.jaba_asignacion_id
      JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
      JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
      WHERE O.campania_venta_id=@camp AND CI.estado=1) cargos,
     (SELECT COALESCE(SUM(A.cantidad_asignada),0) FROM comercial.JabaAsignacion A
      JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
      JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
      WHERE O.campania_venta_id=@camp AND A.estado=1) jabasAsignadas,
     (SELECT COUNT_BIG(1) FROM comercial.JabaUnidadE4 U
      JOIN comercial.JabaAsignacion A ON A.jaba_asignacion_id=U.jaba_asignacion_id
      JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
      JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
      WHERE O.campania_venta_id=@camp AND U.retorno_estado LIKE 'DEVUELTA%') jabasDevueltas,
     (SELECT COUNT_BIG(1) FROM comercial.JabaUnidadE4 U
      JOIN comercial.JabaAsignacion A ON A.jaba_asignacion_id=U.jaba_asignacion_id
      JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
      JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
      WHERE O.campania_venta_id=@camp AND U.retorno_estado='FALTANTE') jabasFaltantes,
     JSON_QUERY((SELECT P.participacion_campania_socio_id participacionId,
       SA.socio_asociacion_id socioId,
       CONCAT(PE.nombres,N' ',PE.apellido_paterno,N' ',COALESCE(PE.apellido_materno,N'')) socio,
       (SELECT COALESCE(SUM(D.kilogramos),0) FROM comercial.OperativoSocio OS
        JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
        JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1
        WHERE OS.participacion_campania_socio_id=P.participacion_campania_socio_id AND OS.estado=1) kilogramos,
       (SELECT COALESCE(SUM(D.kilogramos*D.precio_base),0)
        FROM comercial.OperativoSocio OS
        JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
        JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1
        WHERE OS.participacion_campania_socio_id=P.participacion_campania_socio_id AND OS.estado=1) bruto,
       (SELECT COALESCE(SUM(D.importe),0)
        FROM comercial.OperativoSocio OS
        JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
        JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1
        WHERE OS.participacion_campania_socio_id=P.participacion_campania_socio_id AND OS.estado=1) ventaEfectiva,
       (SELECT COALESCE(SUM(GP.importe_asignado),0)
        FROM finanzas.GastoProrrateoSocio GP JOIN finanzas.GastoCampania G ON G.gasto_campania_id=GP.gasto_campania_id
        WHERE GP.participacion_campania_socio_id=P.participacion_campania_socio_id AND GP.estado=1 AND G.estado=1 AND G.estado_proceso='APROBADO') gastos,
       (SELECT COALESCE(SUM(CI.importe),0)
        FROM comercial.CargoIndividualE4 CI JOIN comercial.JabaAsignacion JA ON JA.jaba_asignacion_id=CI.jaba_asignacion_id
        JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=JA.operativo_socio_id
        WHERE OS.participacion_campania_socio_id=P.participacion_campania_socio_id AND CI.estado=1 AND JA.estado=1) cargos,
       LS.liquidacion_socio_id liquidacionId,LS.version,LS.estado_proceso liquidacionEstado,
       LS.importe_neto neto,COALESCE(Q.pagado,0) pagado,
       CASE WHEN LS.importe_neto IS NULL THEN NULL ELSE LS.importe_neto-COALESCE(Q.pagado,0) END saldo
       FROM comercial.ParticipacionCampaniaSocio P
       JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=P.socio_asociacion_id
       JOIN org.Socio S ON S.socio_id=SA.socio_id
       JOIN org.Persona PE ON PE.persona_id=S.socio_id
       OUTER APPLY(SELECT TOP(1) L.liquidacion_socio_id,L.version,L.estado_proceso,L.importe_neto
         FROM finanzas.LiquidacionSocio L WHERE L.participacion_campania_socio_id=P.participacion_campania_socio_id
          AND L.estado=1 AND L.estado_proceso<>'ANULADA' ORDER BY L.version DESC) LS
       OUTER APPLY(SELECT SUM(PG.importe) pagado FROM finanzas.PagoSocio PG
         WHERE PG.liquidacion_socio_id=LS.liquidacion_socio_id AND PG.estado=1 AND PG.estado_proceso='CONFIRMADO') Q
       WHERE P.campania_venta_id=@camp AND P.estado=1 ORDER BY socio,P.participacion_campania_socio_id FOR JSON PATH)) socios,
     JSON_QUERY((SELECT D.variedad_palta_id variedadId,D.condicion_comercial_id condicionId,
        SUM(D.kilogramos) kilogramos,SUM(D.kilogramos*D.precio_base) bruto,SUM(D.importe) efectivo
       FROM comercial.EntregaDetalle D
       JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
       JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
       JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
       WHERE O.campania_venta_id=@camp AND D.estado=1
       GROUP BY D.variedad_palta_id,D.condicion_comercial_id FOR JSON PATH)) variedades,
     JSON_QUERY((SELECT R.reparto_id repartoId,G.concepto,R.version,R.importe,R.vendedores,R.estado
       FROM finanzas.GastoRepartoVersionE5 R JOIN finanzas.GastoCampania G ON G.gasto_campania_id=R.gasto_campania_id
       WHERE G.campania_venta_id=@camp ORDER BY G.gasto_campania_id,R.version FOR JSON PATH)) repartos
     FROM comercial.CampaniaVenta C LEFT JOIN comercial.CierreCampaniaE5 X ON X.campania_venta_id=C.campania_venta_id
     WHERE C.campania_venta_id=@camp FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='GASTOS'
  BEGIN
    SET @cDatos=(SELECT @camp campaniaId,JSON_QUERY((SELECT G.gasto_campania_id gastoId,G.concepto,G.importe,G.moneda,G.estado_proceso estado,
      G.fecha, R.reparto_id repartoId,R.version,R.estado repartoEstado,R.vendedores,RG.codigo reglaCodigo
      FROM finanzas.GastoCampania G JOIN finanzas.ReglaProrrateo RG ON RG.regla_prorrateo_id=G.regla_prorrateo_id OUTER APPLY(SELECT TOP(1) * FROM finanzas.GastoRepartoVersionE5 R
        WHERE R.gasto_campania_id=G.gasto_campania_id ORDER BY R.version DESC) R
      WHERE G.campania_venta_id=@camp AND G.estado=1 ORDER BY G.fecha,G.gasto_campania_id FOR JSON PATH)) gastos
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='REPARTO'
  BEGIN
   SET @cDatos=(SELECT @gasto gastoId,JSON_QUERY((SELECT R.reparto_id repartoId,R.version,R.estado,R.importe,R.moneda,R.vendedores,R.observacion,
     JSON_QUERY((SELECT X.participacion_id participacionId,X.monto FROM finanzas.GastoRepartoLineaE5 X
       WHERE X.reparto_id=R.reparto_id ORDER BY X.participacion_id FOR JSON PATH)) socios
     FROM finanzas.GastoRepartoVersionE5 R WHERE R.gasto_campania_id=@gasto
     ORDER BY R.version DESC FOR JSON PATH)) repartos FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion IN('REPARTIR','APROBAR_REPARTO','RECTIFICAR_REPARTO')
  BEGIN
   SELECT @total=G.importe,@moneda=G.moneda,@estado=G.estado_proceso,@regla=UPPER(RG.codigo)
   FROM finanzas.GastoCampania G WITH(UPDLOCK,HOLDLOCK)
   JOIN finanzas.ReglaProrrateo RG ON RG.regla_prorrateo_id=G.regla_prorrateo_id
   WHERE G.gasto_campania_id=@gasto AND G.estado=1;
   IF @regla IS NULL OR @regla NOT IN ('IGUAL','PESO_ACEPTADO','VENTA_BRUTA','MANUAL')
     THROW 51626,N'La regla de distribución no es válida.',1;
   IF @total IS NULL OR @total<=0 OR @moneda<>'PEN' THROW 51610,N'El gasto debe estar vigente, positivo y en soles.',1;
   IF @cAccion='RECTIFICAR_REPARTO'
   BEGIN
    SET @motivo=JSON_VALUE(@cJson,'$.datos.motivo');
    IF NULLIF(LTRIM(RTRIM(@motivo)),N'') IS NULL THROW 51621,N'Indique el motivo de rectificación.',1;
    IF EXISTS(SELECT 1 FROM finanzas.LiquidacionDetalle LD
       JOIN finanzas.GastoProrrateoSocio GP ON GP.gasto_prorrateo_socio_id=LD.gasto_prorrateo_socio_id
       JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=LD.liquidacion_socio_id
       WHERE GP.gasto_campania_id=@gasto AND L.estado=1 AND L.estado_proceso='APROBADA')
      THROW 51622,N'Existe una liquidación aprobada. Debe regularizarla antes de rectificar el reparto.',1;
    IF @estado<>'APROBADO' THROW 51623,N'Solo es posible rectificar un reparto aprobado.',1;
    UPDATE finanzas.GastoRepartoVersionE5 SET estado='RECTIFICADO',observacion=@motivo
      WHERE gasto_campania_id=@gasto AND estado='APROBADO';
    UPDATE finanzas.GastoProrrateoSocio SET estado=0 WHERE gasto_campania_id=@gasto AND estado=1;
    UPDATE finanzas.GastoCampania SET estado_proceso='REGISTRADO' WHERE gasto_campania_id=@gasto;
    SET @estado='REGISTRADO';
   END;
   IF @cAccion IN('REPARTIR','RECTIFICAR_REPARTO')
   BEGIN
    IF @estado<>'REGISTRADO' THROW 51611,N'El gasto aprobado no admite reparto nuevo sin rectificación formal.',1;
    IF EXISTS(SELECT 1 FROM finanzas.GastoRepartoVersionE5 WHERE gasto_campania_id=@gasto AND estado='PROPUESTO')
       THROW 51612,N'Ya existe un reparto pendiente. Revíselo antes de confirmar.',1;
    -- Una sola fuente de vendedores confirmados para todas las reglas.
    DECLARE @vendedores TABLE(participacion_id BIGINT NOT NULL PRIMARY KEY,base_calculo DECIMAL(28,8) NOT NULL);
    INSERT @vendedores(participacion_id,base_calculo)
    SELECT P.participacion_campania_socio_id,
       CASE @regla WHEN 'PESO_ACEPTADO' THEN CONVERT(DECIMAL(28,8),B.kilos)
                   WHEN 'VENTA_BRUTA' THEN CONVERT(DECIMAL(28,8),B.venta_bruta)
                   ELSE CONVERT(DECIMAL(28,8),1) END
    FROM comercial.ParticipacionCampaniaSocio P
    CROSS APPLY(
      SELECT COALESCE(SUM(D.kilogramos),0) kilos,
             COALESCE(SUM(D.kilogramos*D.precio_base),0) venta_bruta
      FROM comercial.OperativoSocio OS
      JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
      JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1
      WHERE OS.participacion_campania_socio_id=P.participacion_campania_socio_id AND OS.estado=1
    ) B
    WHERE P.campania_venta_id=@camp AND P.estado=1 AND B.kilos>0;
    SET @cantidad=(SELECT COUNT(1) FROM @vendedores);
    IF @cantidad=0 THROW 51613,N'No hay vendedores con kilos confirmados para prorratear.',1;
    SET @centavos=CONVERT(BIGINT,ROUND(@total*100,0));
    IF @centavos<>@total*100 THROW 51614,N'El reparto exige un gasto con precisión de céntimos.',1;
    DECLARE @cuotas TABLE(participacion_id BIGINT NOT NULL PRIMARY KEY,cuota_cent BIGINT NOT NULL,residuo DECIMAL(38,12) NOT NULL);
    IF @regla='MANUAL'
    BEGIN
      DECLARE @manual TABLE(participacion_id BIGINT NULL,monto DECIMAL(19,4) NULL);
      INSERT @manual(participacion_id,monto)
      SELECT participacionId,monto FROM OPENJSON(@cJson,'$.datos.cuotas') WITH
       (participacionId BIGINT '$.participacionId',monto DECIMAL(19,4) '$.monto');
      IF NOT EXISTS(SELECT 1 FROM @manual)
        OR EXISTS(SELECT 1 FROM @manual WHERE participacion_id IS NULL OR monto IS NULL OR monto<=0 OR monto<>ROUND(monto,2))
        OR (SELECT COUNT(1) FROM @manual)<>(SELECT COUNT(DISTINCT participacion_id) FROM @manual)
        OR EXISTS(SELECT 1 FROM @manual M LEFT JOIN @vendedores V ON V.participacion_id=M.participacion_id
                  WHERE V.participacion_id IS NULL)
        OR (SELECT COALESCE(SUM(monto),0) FROM @manual)<>@total
       THROW 51627,N'La distribución manual debe asignarse a socios de la campaña y sumar exactamente el gasto.',1;
      INSERT @cuotas(participacion_id,cuota_cent,residuo)
      SELECT participacion_id,CONVERT(BIGINT,monto*100),0 FROM @manual;
      SET @cantidad=(SELECT COUNT(1) FROM @cuotas);
    END
    ELSE
    BEGIN
      SELECT @baseTotal=SUM(base_calculo) FROM @vendedores WHERE base_calculo>0;
      IF ISNULL(@baseTotal,0)<=0 THROW 51628,N'No hay peso o venta bruta disponible para realizar la distribución.',1;
      INSERT @cuotas(participacion_id,cuota_cent,residuo)
      SELECT V.participacion_id,CONVERT(BIGINT,FLOOR(Q.exacto)),Q.exacto-FLOOR(Q.exacto)
      FROM @vendedores V
      CROSS APPLY(SELECT CONVERT(DECIMAL(38,12),
        CONVERT(DECIMAL(28,8),@centavos)*V.base_calculo/@baseTotal) exacto) Q
      WHERE V.base_calculo>0;
      SET @sobrante=CONVERT(INT,@centavos-(SELECT COALESCE(SUM(cuota_cent),0) FROM @cuotas));
      IF @sobrante<0 OR @sobrante>(SELECT COUNT(1) FROM @cuotas)
       THROW 51629,N'No se pudo conciliar el redondeo de la distribución.',1;
      ;WITH Orden AS
      (SELECT participacion_id,ROW_NUMBER() OVER(ORDER BY residuo DESC,participacion_id) orden FROM @cuotas)
      UPDATE Q SET cuota_cent=Q.cuota_cent+1
      FROM @cuotas Q JOIN Orden O ON O.participacion_id=Q.participacion_id
      WHERE O.orden<=@sobrante;
    END;
    IF (SELECT COALESCE(SUM(cuota_cent),0) FROM @cuotas)<>@centavos
      THROW 51615,N'La suma de cuotas no coincide con el gasto.',1;
    SELECT @version=COALESCE(MAX(version),0)+1 FROM finanzas.GastoRepartoVersionE5 WHERE gasto_campania_id=@gasto;
    INSERT finanzas.GastoRepartoVersionE5(gasto_campania_id,version,importe,moneda,vendedores,estado,usuario_id)
      VALUES(@gasto,@version,@total,@moneda,@cantidad,'PROPUESTO',@usuario);
    SET @id=SCOPE_IDENTITY();
    INSERT finanzas.GastoRepartoLineaE5(reparto_id,participacion_id,monto)
      SELECT @id,participacion_id,CONVERT(DECIMAL(19,4),cuota_cent/100.0)
      FROM @cuotas;
    IF (SELECT COALESCE(SUM(monto),0) FROM finanzas.GastoRepartoLineaE5 WHERE reparto_id=@id)<>@total
     THROW 51615,N'La suma de cuotas no coincide con el gasto.',1;
   END
   ELSE
   BEGIN
    SELECT TOP(1) @id=reparto_id,@version=version,@cantidad=vendedores FROM finanzas.GastoRepartoVersionE5 WITH(UPDLOCK,HOLDLOCK)
       WHERE gasto_campania_id=@gasto AND estado='PROPUESTO' ORDER BY version DESC;
    IF @id IS NULL THROW 51616,N'No existe reparto pendiente de aprobación.',1;
    IF EXISTS(SELECT 1 FROM finanzas.GastoProrrateoSocio P WHERE P.gasto_campania_id=@gasto AND P.estado=1)
     THROW 51617,N'Existen cuotas registradas; la rectificación debe revisar primero sus liquidaciones.',1;
    IF EXISTS(SELECT 1 FROM finanzas.GastoRepartoLineaE5 L WHERE L.reparto_id=@id
      AND NOT EXISTS(SELECT 1 FROM comercial.OperativoSocio OS
       JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
       JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1 AND D.kilogramos>0
       WHERE OS.participacion_campania_socio_id=L.participacion_id))
      THROW 51618,N'Cambió la composición de vendedores. Registre un nuevo reparto.',1;
    IF @regla<>'MANUAL' AND (SELECT COUNT(DISTINCT OS.participacion_campania_socio_id) FROM comercial.OperativoSocio OS
      JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
      JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1 AND D.kilogramos>0
      JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
      WHERE O.campania_venta_id=@camp)<>@cantidad
      THROW 51619,N'El número de vendedores cambió. Recalcule el prorrateo.',1;
    IF @regla<>'MANUAL' AND EXISTS(
      SELECT OS.participacion_campania_socio_id FROM comercial.OperativoSocio OS
      JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
      JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1 AND D.kilogramos>0
      JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
      WHERE O.campania_venta_id=@camp GROUP BY OS.participacion_campania_socio_id
      EXCEPT SELECT participacion_id FROM finanzas.GastoRepartoLineaE5 WHERE reparto_id=@id
    ) THROW 51625,N'Los vendedores actuales no coinciden con los del reparto.',1;
    INSERT finanzas.GastoProrrateoSocio(gasto_campania_id,participacion_campania_socio_id,importe_asignado,estado)
      SELECT @gasto,participacion_id,monto,1 FROM finanzas.GastoRepartoLineaE5 WHERE reparto_id=@id;
    UPDATE finanzas.GastoRepartoVersionE5 SET estado='APROBADO',aprobado_por=@usuario,aprobado=@fecha WHERE reparto_id=@id;
    UPDATE finanzas.GastoCampania SET estado_proceso='APROBADO' WHERE gasto_campania_id=@gasto AND estado_proceso='REGISTRADO';
    IF @@ROWCOUNT<>1 THROW 51620,N'El estado del gasto cambió.',1;
   END;
   SET @cDatos=(SELECT @id repartoId,@version version,@cantidad vendedores,@total importe,
     JSON_QUERY((SELECT participacion_id participacionId,monto FROM finanzas.GastoRepartoLineaE5
       WHERE reparto_id=@id ORDER BY participacion_id FOR JSON PATH)) socios FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='LIQUIDACIONES'
  BEGIN
   SET @cDatos=(SELECT @camp campaniaId,JSON_QUERY((SELECT L.liquidacion_socio_id liquidacionId,
     L.participacion_campania_socio_id participacionId,L.version,L.importe_neto neto,L.moneda,L.estado_proceso estado,
     COALESCE((SELECT SUM(P.importe) FROM finanzas.PagoSocio P WHERE P.liquidacion_socio_id=L.liquidacion_socio_id
       AND P.estado=1 AND P.estado_proceso='CONFIRMADO'),0) pagado
     FROM finanzas.LiquidacionSocio L JOIN comercial.ParticipacionCampaniaSocio P
       ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
     WHERE P.campania_venta_id=@camp AND L.estado=1 ORDER BY P.participacion_campania_socio_id,L.version DESC FOR JSON PATH)) liquidaciones
     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion IN('LIQUIDAR','APROBAR','OBSERVAR','LIQUIDACION','PAGAR','REVERSAR')
  BEGIN
   -- El desglose se deriva de los detalles oficiales de entrega, no de cifras introducidas por Angular.
   IF @part IS NULL THROW 51630,N'Seleccione un socio inscrito en esta campaña.',1;
   SELECT @kilos=COALESCE(SUM(D.kilogramos),0),@bruto=COALESCE(SUM(D.kilogramos*D.precio_base),0),
     @efectivo=COALESCE(SUM(D.importe),0)
   FROM comercial.OperativoSocio OS JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id
     AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
   JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1
   WHERE OS.participacion_campania_socio_id=@part AND OS.estado=1;
   SET @ajuste=ROUND(@bruto-@efectivo,4);
   SELECT @cargos=COALESCE(SUM(CI.importe),0) FROM comercial.CargoIndividualE4 CI
    JOIN comercial.JabaAsignacion A ON A.jaba_asignacion_id=CI.jaba_asignacion_id
    JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
    WHERE OS.participacion_campania_socio_id=@part AND CI.estado=1 AND A.estado=1;
   SELECT @gastos=COALESCE(SUM(GP.importe_asignado),0) FROM finanzas.GastoProrrateoSocio GP
     JOIN finanzas.GastoCampania G ON G.gasto_campania_id=GP.gasto_campania_id
       AND G.estado=1 AND G.estado_proceso='APROBADO'
     WHERE GP.participacion_campania_socio_id=@part AND GP.estado=1;
   SELECT @descuentos=COALESCE(SUM(CASE WHEN A.tipo_ajuste='DESCUENTO_PORCENTAJE'
        THEN ROUND(@bruto*COALESCE(A.porcentaje_ajuste,0)/100.0,4)
        WHEN A.tipo_ajuste='DESCUENTO_MONTO' THEN COALESCE(A.monto_ajuste,0) ELSE 0 END),0),
     @bonos=COALESCE(SUM(CASE WHEN A.tipo_ajuste='BONIFICACION' THEN COALESCE(A.monto_ajuste,0) ELSE 0 END),0)
     FROM comercial.AjustePrecioSocio A WHERE A.participacion_campania_socio_id=@part
       AND A.estado=1 AND A.estado_ajuste='VIGENTE';
   SET @neto=ROUND(@efectivo-@cargos-@gastos-@descuentos+@bonos,2);
   SET @redondeo=@neto-(@efectivo-@cargos-@gastos-@descuentos+@bonos);
   SET @fuentes=CONCAT(
    (SELECT D.entrega_detalle_id id,D.kilogramos kg,D.precio_base base,D.precio_aplicado efectivo,D.estado
     FROM comercial.OperativoSocio OS JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id
     JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id
     WHERE OS.participacion_campania_socio_id=@part AND E.estado=1 AND E.estado_proceso='CONFIRMADA' AND D.estado=1
     ORDER BY D.entrega_detalle_id FOR JSON PATH),
    (SELECT CI.cargo_id id,CI.importe FROM comercial.CargoIndividualE4 CI
      JOIN comercial.JabaAsignacion JA ON JA.jaba_asignacion_id=CI.jaba_asignacion_id
      JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=JA.operativo_socio_id
      WHERE OS.participacion_campania_socio_id=@part AND CI.estado=1 ORDER BY CI.cargo_id FOR JSON PATH),
    (SELECT GP.gasto_prorrateo_socio_id id,GP.importe_asignado FROM finanzas.GastoProrrateoSocio GP
      JOIN finanzas.GastoCampania G ON G.gasto_campania_id=GP.gasto_campania_id
      WHERE GP.participacion_campania_socio_id=@part AND GP.estado=1 AND G.estado=1 AND G.estado_proceso='APROBADO'
      ORDER BY GP.gasto_prorrateo_socio_id FOR JSON PATH),
    (SELECT A.ajuste_precio_socio_id id,A.tipo_ajuste,A.monto_ajuste,A.porcentaje_ajuste
      FROM comercial.AjustePrecioSocio A WHERE A.participacion_campania_socio_id=@part AND A.estado=1 AND A.estado_ajuste='VIGENTE'
      ORDER BY A.ajuste_precio_socio_id FOR JSON PATH));
   SET @huella=HASHBYTES('SHA2_256',@fuentes);
   IF @cAccion='LIQUIDAR'
   BEGIN
    IF EXISTS (SELECT 1 FROM finanzas.LiquidacionSocio L WITH(UPDLOCK,HOLDLOCK)
       WHERE L.participacion_campania_socio_id=@part AND L.estado=1
         AND L.estado_proceso='CALCULADA')
       THROW 51648,N'Ya existe una versión calculada pendiente de revisión.',1;
    IF @kilos<=0 THROW 51631,N'No hay kilos aceptados y confirmados.',1;
    IF EXISTS(SELECT 1 FROM comercial.OperativoSocio OS
       JOIN comercial.JabaAsignacion A ON A.operativo_socio_id=OS.operativo_socio_id AND A.estado=1
       WHERE OS.participacion_campania_socio_id=@part AND NOT EXISTS
       (SELECT 1 FROM comercial.JabaRetornoValidadoE4 V WHERE V.jaba_asignacion_id=A.jaba_asignacion_id))
       THROW 51632,N'Hay devoluciones de jabas sin validación física.',1;
    IF EXISTS(SELECT 1 FROM comercial.OperativoSocio OS
       JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1
       WHERE OS.participacion_campania_socio_id=@part AND E.estado_proceso<>'CONFIRMADA')
       THROW 51633,N'Hay entregas pendientes de confirmación.',1;
    IF EXISTS(SELECT 1 FROM comercial.OperativoSocio OS
      JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id
      JOIN comercial.SancionSocioE4 S ON S.entrega_socio_id=E.entrega_socio_id AND S.estado=1 AND S.aplicada_detalle=0
      WHERE OS.participacion_campania_socio_id=@part)
      THROW 51634,N'Existen sanciones cuyo precio todavía no se aplicó al detalle.',1;
    SELECT @nuevoId=MAX(L.liquidacion_socio_id) FROM finanzas.LiquidacionSocio L
      WHERE L.participacion_campania_socio_id=@part AND L.estado=1 AND L.estado_proceso IN('APROBADA','PAGADA_PARCIAL','PAGADA');
    IF @nuevoId IS NOT NULL
    BEGIN
      SET @motivo=JSON_VALUE(@cJson,'$.datos.motivoRectificacion');
      IF NULLIF(LTRIM(RTRIM(@motivo)),N'') IS NULL THROW 51635,N'Una liquidación aprobada exige rectificación motivada.',1;
      IF seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'LIQUIDACIONES_EDITAR')<>1
       THROW 51636,N'No dispone de autorización para rectificar liquidaciones.',1;
      IF EXISTS(SELECT 1 FROM finanzas.PagoSocio WHERE liquidacion_socio_id=@nuevoId AND estado=1 AND estado_proceso='CONFIRMADO')
       THROW 51637,N'La liquidación pagada requiere regularización formal antes de rectificar.',1;
      UPDATE finanzas.LiquidacionSocio SET estado_proceso='ANULADA' WHERE liquidacion_socio_id=@nuevoId;
      UPDATE finanzas.LiquidacionSnapshotE5 SET observacion=@motivo WHERE liquidacion_socio_id=@nuevoId;
    END;
    SELECT @version=COALESCE(MAX(version),0)+1 FROM finanzas.LiquidacionSocio WHERE participacion_campania_socio_id=@part;
    SET @moneda='PEN';
    INSERT finanzas.LiquidacionSocio(participacion_campania_socio_id,version,fecha_calculo,importe_bruto,
      total_ajustes,total_gastos,total_bonificaciones,importe_neto,moneda,estado_proceso,estado)
    VALUES(@part,@version,@fecha,@bruto,@ajuste+@descuentos+@cargos,@gastos,@bonos,@neto,@moneda,'CALCULADA',1);
    SET @liq=SCOPE_IDENTITY();
    INSERT finanzas.LiquidacionSnapshotE5(liquidacion_socio_id,campania_venta_id,peso_aceptado_kg,
      bruto_referencial,ajuste_precio,descuentos_adicionales,cargos,gastos,bonificaciones,venta_ajustada,
      neto,ajuste_redondeo,fuente_hash,moneda,creado_por)
    VALUES(@liq,@camp,@kilos,@bruto,@ajuste,@descuentos,@cargos,@gastos,@bonos,@efectivo,@neto,@redondeo,@huella,@moneda,@usuario);
    INSERT finanzas.LiquidacionDetalle(liquidacion_socio_id,tipo,entrega_detalle_id,gasto_prorrateo_socio_id,
      ajuste_precio_socio_id,concepto,importe,estado)
    SELECT @liq,'VENTA',D.entrega_detalle_id,NULL,NULL,N'Venta efectiva (precio histórico)',D.importe,1
     FROM comercial.OperativoSocio OS JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id
       AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
     JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1
     WHERE OS.participacion_campania_socio_id=@part;
    INSERT finanzas.LiquidacionDetalle(liquidacion_socio_id,tipo,entrega_detalle_id,gasto_prorrateo_socio_id,
      ajuste_precio_socio_id,concepto,importe,estado)
    SELECT @liq,'GASTO',NULL,GP.gasto_prorrateo_socio_id,NULL,G.concepto,-GP.importe_asignado,1
     FROM finanzas.GastoProrrateoSocio GP JOIN finanzas.GastoCampania G
       ON G.gasto_campania_id=GP.gasto_campania_id AND G.estado=1 AND G.estado_proceso='APROBADO'
     WHERE GP.participacion_campania_socio_id=@part AND GP.estado=1;
    INSERT finanzas.LiquidacionDetalle(liquidacion_socio_id,tipo,entrega_detalle_id,gasto_prorrateo_socio_id,
      ajuste_precio_socio_id,concepto,importe,estado)
    SELECT @liq,'OTRO',NULL,NULL,NULL,CONCAT(N'Cargo particular: ',C.motivo),-C.importe,1
     FROM comercial.CargoIndividualE4 C JOIN comercial.JabaAsignacion JA ON JA.jaba_asignacion_id=C.jaba_asignacion_id
     JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=JA.operativo_socio_id
     WHERE OS.participacion_campania_socio_id=@part AND C.estado=1;
    INSERT finanzas.LiquidacionDetalle(liquidacion_socio_id,tipo,entrega_detalle_id,gasto_prorrateo_socio_id,
      ajuste_precio_socio_id,concepto,importe,estado)
    SELECT @liq,CASE WHEN A.tipo_ajuste='BONIFICACION' THEN 'BONIFICACION' ELSE 'AJUSTE' END,
     NULL,NULL,A.ajuste_precio_socio_id,A.motivo,
     CASE WHEN A.tipo_ajuste='BONIFICACION' THEN COALESCE(A.monto_ajuste,0)
          WHEN A.tipo_ajuste='DESCUENTO_PORCENTAJE' THEN -ROUND(@bruto*COALESCE(A.porcentaje_ajuste,0)/100.0,4)
          ELSE -COALESCE(A.monto_ajuste,0) END,1
    FROM comercial.AjustePrecioSocio A WHERE A.participacion_campania_socio_id=@part
      AND A.estado=1 AND A.estado_ajuste='VIGENTE' AND A.tipo_ajuste IN('DESCUENTO_MONTO','DESCUENTO_PORCENTAJE','BONIFICACION');
    IF @redondeo<>0
      INSERT finanzas.LiquidacionDetalle(liquidacion_socio_id,tipo,entrega_detalle_id,gasto_prorrateo_socio_id,
       ajuste_precio_socio_id,concepto,importe,estado)
      VALUES(@liq,'OTRO',NULL,NULL,NULL,N'Ajuste de redondeo monetario',@redondeo,1);

   END
   ELSE IF @cAccion='APROBAR'
   BEGIN
    SELECT @estado=L.estado_proceso,@esperado=CONVERT(BIGINT,L.version) FROM finanzas.LiquidacionSocio L WITH(UPDLOCK,HOLDLOCK)
      WHERE L.liquidacion_socio_id=@liq AND L.estado=1;
    IF @estado<>'CALCULADA' THROW 51638,N'La liquidación ya no está pendiente de aprobación.',1;
    IF NOT EXISTS(SELECT 1 FROM finanzas.LiquidacionSnapshotE5 WHERE liquidacion_socio_id=@liq AND fuente_hash=@huella)
     THROW 51639,N'Cambió el origen de los cálculos. Registre una nueva versión.',1;
    IF EXISTS(SELECT 1 FROM finanzas.LiquidacionSocio WHERE participacion_campania_socio_id=@part AND version>@esperado AND estado=1 AND estado_proceso<>'ANULADA')
     THROW 51640,N'Existe una versión posterior.',1;
    UPDATE finanzas.LiquidacionSocio SET estado_proceso='APROBADA' WHERE liquidacion_socio_id=@liq;
    UPDATE finanzas.LiquidacionSnapshotE5 SET aprobado_por=@usuario,aprobado=@fecha WHERE liquidacion_socio_id=@liq;
   END
   ELSE IF @cAccion='OBSERVAR'
   BEGIN
    SET @motivo=JSON_VALUE(@cJson,'$.datos.motivo');
    IF NULLIF(LTRIM(RTRIM(@motivo)),N'') IS NULL THROW 51641,N'Indique el motivo de observación.',1;
    IF NOT EXISTS(SELECT 1 FROM finanzas.LiquidacionSocio WHERE liquidacion_socio_id=@liq AND estado_proceso='CALCULADA')
     THROW 51642,N'Solo se pueden observar liquidaciones pendientes.',1;
    UPDATE finanzas.LiquidacionSocio SET estado_proceso='OBSERVADA' WHERE liquidacion_socio_id=@liq;
    UPDATE finanzas.LiquidacionSnapshotE5 SET observacion=@motivo WHERE liquidacion_socio_id=@liq;
   END
   ELSE IF @cAccion='PAGAR'
   BEGIN
    SET @importe=TRY_CONVERT(DECIMAL(19,4),JSON_VALUE(@cJson,'$.datos.importe'));
    DECLARE @medio VARCHAR(30)=JSON_VALUE(@cJson,'$.datos.medioPago'),@referencia VARCHAR(100)=JSON_VALUE(@cJson,'$.datos.referencia');
    SELECT @neto=L.importe_neto,@estado=L.estado_proceso FROM finanzas.LiquidacionSocio L WITH(UPDLOCK,HOLDLOCK)
      WHERE L.liquidacion_socio_id=@liq AND L.estado=1;
    SELECT @pagado=COALESCE(SUM(P.importe),0) FROM finanzas.PagoSocio P WITH(UPDLOCK,HOLDLOCK)
      WHERE P.liquidacion_socio_id=@liq AND P.estado=1 AND P.estado_proceso='CONFIRMADO';
    SET @saldo=@neto-@pagado;
    IF @estado<>'APROBADA' OR @neto<=0 OR @importe IS NULL OR @importe<0.01 OR @importe<>ROUND(@importe,2) OR @importe>@saldo
      THROW 51643,N'El importe supera el saldo disponible o la liquidación no está aprobada.',1;
    IF @medio IS NULL OR NULLIF(LTRIM(RTRIM(@medio)),'') IS NULL OR LEN(@medio)>30
      THROW 51644,N'Seleccione un medio de pago válido.',1;
    IF @medio IN('TRANSFERENCIA','DEPOSITO') AND NULLIF(LTRIM(RTRIM(@referencia)),'') IS NULL
      THROW 51645,N'El medio seleccionado requiere referencia de operación.',1;
    INSERT finanzas.PagoSocio(liquidacion_socio_id,fecha_hora,importe,medio_pago,numero_operacion,estado_proceso,
      estado,fecha_confirmacion,usuario_confirmacion_id)
    VALUES(@liq,@fecha,@importe,@medio,@referencia,'CONFIRMADO',1,@fecha,@usuario);
    SET @pago=SCOPE_IDENTITY();
    INSERT finanzas.EventoPagoE5(pago_socio_id,accion,importe,usuario_id) VALUES(@pago,'PAGAR',@importe,@usuario);
   END
   ELSE IF @cAccion='REVERSAR'
   BEGIN
    SET @motivo=JSON_VALUE(@cJson,'$.datos.motivo');
    IF NULLIF(LTRIM(RTRIM(@motivo)),N'') IS NULL THROW 51646,N'La reversión exige justificación.',1;
    SELECT @importe=importe FROM finanzas.PagoSocio WITH(UPDLOCK,HOLDLOCK)
      WHERE pago_socio_id=@pago AND liquidacion_socio_id=@liq AND estado=1 AND estado_proceso='CONFIRMADO';
    IF @importe IS NULL THROW 51647,N'El pago no está confirmado o ya fue revertido.',1;
    UPDATE finanzas.PagoSocio SET estado_proceso='ANULADO',fecha_anulacion=@fecha,
      usuario_anulacion_id=@usuario,motivo_anulacion=@motivo WHERE pago_socio_id=@pago;
    INSERT finanzas.EventoPagoE5(pago_socio_id,accion,importe,usuario_id,motivo)
      VALUES(@pago,'REVERSAR',@importe,@usuario,@motivo);
   END;
   SELECT @pagado=COALESCE(SUM(P.importe),0) FROM finanzas.PagoSocio P
    WHERE P.liquidacion_socio_id=@liq AND P.estado=1 AND P.estado_proceso='CONFIRMADO';
   SET @cDatos=(SELECT L.liquidacion_socio_id liquidacionId,L.participacion_campania_socio_id participacionId,
      L.version,L.estado_proceso estado,L.moneda,L.importe_neto neto,@pagado pagado,L.importe_neto-@pagado saldo,
      S.peso_aceptado_kg kilogramos,S.bruto_referencial bruto,S.ajuste_precio ajustePrecio,
      S.venta_ajustada ventaAjustada,S.cargos,S.gastos,S.descuentos_adicionales descuentos,
      S.bonificaciones,S.ajuste_redondeo redondeo,S.creado,S.aprobado,S.observacion,
      JSON_QUERY((SELECT D.liquidacion_detalle_id detalleId,D.tipo,D.concepto,D.importe,
       D.entrega_detalle_id entregaDetalleId,D.gasto_prorrateo_socio_id gastoLineaId,
       D.ajuste_precio_socio_id ajusteId FROM finanzas.LiquidacionDetalle D
       WHERE D.liquidacion_socio_id=L.liquidacion_socio_id AND D.estado=1 ORDER BY D.liquidacion_detalle_id FOR JSON PATH)) detalle,
      JSON_QUERY((SELECT P.pago_socio_id pagoId,P.importe,P.medio_pago medioPago,P.numero_operacion referencia,
        P.estado_proceso estado,P.fecha_hora fecha FROM finanzas.PagoSocio P
        WHERE P.liquidacion_socio_id=L.liquidacion_socio_id ORDER BY P.pago_socio_id FOR JSON PATH)) pagos
     FROM finanzas.LiquidacionSocio L LEFT JOIN finanzas.LiquidacionSnapshotE5 S ON S.liquidacion_socio_id=L.liquidacion_socio_id
     WHERE L.liquidacion_socio_id=@liq FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='COBROS'
  BEGIN
   -- No confundir facturación con ingreso: solo suma cobros efectivamente confirmados.
   SET @cDatos=(SELECT @camp campaniaId,
      (SELECT COALESCE(SUM(D.importe),0) FROM comercial.EntregaDetalle D
       JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id
       JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
       JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
       WHERE O.campania_venta_id=@camp AND D.estado=1 AND E.estado=1 AND E.estado_proceso='CONFIRMADA') ventaComprador,
      (SELECT COALESCE(SUM(D.importe),0) FROM comercial.EntregaDetalle D
       JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id
       JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
       JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
       WHERE O.campania_venta_id=@camp AND D.estado=1 AND E.estado=1 AND E.estado_proceso='CONFIRMADA')
       -(SELECT COALESCE(SUM(importe),0) FROM finanzas.CobroComprador B
         WHERE B.campania_venta_id=@camp AND B.estado=1 AND B.estado_proceso='CONFIRMADO') saldoComprador,
      (SELECT COALESCE(SUM(importe),0) FROM finanzas.CobroComprador B
       WHERE B.campania_venta_id=@camp AND B.estado=1 AND B.estado_proceso='CONFIRMADO') cobrado,
      JSON_QUERY((SELECT B.cobro_comprador_id cobroId,B.importe,B.moneda,B.estado_proceso estado,
        B.fecha_hora fecha FROM finanzas.CobroComprador B
        WHERE B.campania_venta_id=@camp AND B.estado=1 ORDER BY B.cobro_comprador_id FOR JSON PATH)) movimientos
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion IN('CIERRE_VALIDAR','CERRAR')
  BEGIN
   DECLARE @problemas TABLE(codigo VARCHAR(50) NOT NULL,detalle NVARCHAR(200) NOT NULL);
   IF EXISTS(SELECT 1 FROM comercial.OperativoVenta O JOIN comercial.OperativoSocio OS ON OS.operativo_venta_id=O.operativo_venta_id
     JOIN comercial.JabaAsignacion A ON A.operativo_socio_id=OS.operativo_socio_id AND A.estado=1
     WHERE O.campania_venta_id=@camp AND NOT EXISTS(SELECT 1 FROM comercial.JabaRetornoValidadoE4 V
       WHERE V.jaba_asignacion_id=A.jaba_asignacion_id))
     INSERT @problemas VALUES('JABAS',N'Existen jabas sin retorno validado');
   IF EXISTS(SELECT 1 FROM comercial.OperativoVenta O JOIN comercial.OperativoSocio OS ON OS.operativo_venta_id=O.operativo_venta_id
    JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1
    WHERE O.campania_venta_id=@camp AND E.estado_proceso<>'CONFIRMADA')
    INSERT @problemas VALUES('ENTREGAS',N'Hay entregas sin confirmación');
   IF EXISTS(SELECT 1 FROM finanzas.GastoCampania G WHERE G.campania_venta_id=@camp AND G.estado=1 AND G.estado_proceso<>'APROBADO')
    INSERT @problemas VALUES('GASTOS',N'Hay gastos sin reparto y aprobación');
   IF EXISTS(SELECT 1 FROM finanzas.CobroComprador B WHERE B.campania_venta_id=@camp AND B.estado=1
       AND B.estado_proceso NOT IN('CONFIRMADO','ANULADO'))
      INSERT @problemas VALUES('COBROS_PENDIENTES',N'Existen cobros de comprador sin confirmar o anular');
   IF (SELECT COALESCE(SUM(D.importe),0) FROM comercial.EntregaDetalle D
      JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id
      JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
      JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
      WHERE O.campania_venta_id=@camp AND E.estado=1 AND E.estado_proceso='CONFIRMADA' AND D.estado=1)
      >(SELECT COALESCE(SUM(B.importe),0) FROM finanzas.CobroComprador B
        WHERE B.campania_venta_id=@camp AND B.estado=1 AND B.estado_proceso='CONFIRMADO')
      INSERT @problemas VALUES('SALDO_COMPRADOR',N'La venta registrada al comprador supera los cobros confirmados');

   IF EXISTS(SELECT 1 FROM comercial.OperativoVenta O JOIN comercial.OperativoSocio OS ON OS.operativo_venta_id=O.operativo_venta_id
    JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id
    JOIN comercial.SancionSocioE4 S ON S.entrega_socio_id=E.entrega_socio_id AND S.estado=1 AND S.aplicada_detalle=0
    WHERE O.campania_venta_id=@camp)
    INSERT @problemas VALUES('SANCION',N'Hay sanciones sin precio efectivo');
   IF EXISTS(SELECT 1 FROM comercial.ParticipacionCampaniaSocio P WHERE P.campania_venta_id=@camp AND P.estado=1
     AND EXISTS(SELECT 1 FROM comercial.OperativoSocio OS JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id
       AND E.estado=1 AND E.estado_proceso='CONFIRMADA' WHERE OS.participacion_campania_socio_id=P.participacion_campania_socio_id)
     AND NOT EXISTS(SELECT 1 FROM finanzas.LiquidacionSocio L WHERE L.participacion_campania_socio_id=P.participacion_campania_socio_id
       AND L.estado=1 AND L.estado_proceso='APROBADA'))
     INSERT @problemas VALUES('LIQUIDACIONES',N'Existen vendedores sin liquidación aprobada');
   IF EXISTS(SELECT 1 FROM finanzas.LiquidacionSocio L
      JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
      WHERE P.campania_venta_id=@camp AND L.estado=1 AND L.estado_proceso='APROBADA'
        AND L.importe_neto>COALESCE((SELECT SUM(PG.importe) FROM finanzas.PagoSocio PG
           WHERE PG.liquidacion_socio_id=L.liquidacion_socio_id AND PG.estado=1 AND PG.estado_proceso='CONFIRMADO'),0))
     INSERT @problemas VALUES('PAGOS',N'Quedan saldos por pagar a socios');
   IF EXISTS(SELECT 1 FROM finanzas.LiquidacionSocio L
      JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
      WHERE P.campania_venta_id=@camp AND L.estado=1 AND L.estado_proceso='APROBADA' AND L.importe_neto<0)
      INSERT @problemas VALUES('DEUDA',N'Existen saldos deudores que requieren regularización');
   IF EXISTS(SELECT 1 FROM comercial.OperativoVenta O
      JOIN comercial.OperativoSocio OS ON OS.operativo_venta_id=O.operativo_venta_id
      JOIN comercial.JabaAsignacion A ON A.operativo_socio_id=OS.operativo_socio_id AND A.estado=1
      JOIN comercial.IncidenciaFaltanteE4 I ON I.jaba_asignacion_id=A.jaba_asignacion_id AND I.estado='CONFIRMADA'
      WHERE O.campania_venta_id=@camp AND NOT EXISTS(SELECT 1 FROM comercial.CargoIndividualE4 CI
         WHERE CI.jaba_asignacion_id=A.jaba_asignacion_id AND CI.estado=1))
      INSERT @problemas VALUES('CARGOS',N'Hay faltantes confirmados sin cargo o regularización documentada');
   IF EXISTS(SELECT 1 FROM comercial.OperativoVenta O JOIN comercial.OperativoSocio OS ON OS.operativo_venta_id=O.operativo_venta_id
     JOIN comercial.JabaAsignacion A ON A.operativo_socio_id=OS.operativo_socio_id
     JOIN comercial.IncidenciaFaltanteE4 I ON I.jaba_asignacion_id=A.jaba_asignacion_id
     WHERE O.campania_venta_id=@camp AND I.estado<>'CONFIRMADA')
     INSERT @problemas VALUES('INCIDENCIAS',N'Existen incidencias de jabas sin confirmar');
   SET @pendientes=(SELECT COUNT(1) FROM @problemas);
   IF @cAccion='CERRAR'
   BEGIN
    THROW 51672,N'El cierre financiero es automático; no se permite el cierre manual.',1;
    SET @motivo=JSON_VALUE(@cJson,'$.datos.observacion');
    SET @excepcion=CASE WHEN JSON_VALUE(@cJson,'$.datos.excepcionAutorizada')='true' THEN 1 ELSE 0 END;
    IF NULLIF(LTRIM(RTRIM(@motivo)),N'') IS NULL THROW 51660,N'Indique observación de cierre.',1;
    IF @pendientes>0 AND (@excepcion=0 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'CAMPANIAS_ADMINISTRAR')<>1
         OR NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.motivoExcepcion'))),N'') IS NULL)
       THROW 51661,N'Existen diferencias pendientes. Se requiere excepción autorizada y documentada.',1;
    IF EXISTS(SELECT 1 FROM comercial.CierreCampaniaE5 WHERE campania_venta_id=@camp)
       THROW 51662,N'La campaña ya está cerrada.',1;
    SET @cDatos=(SELECT @camp campaniaId,@fecha fecha,
       JSON_QUERY((SELECT codigo,detalle FROM @problemas FOR JSON PATH)) diferencias
       FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    SET @balanceJson=(SELECT @camp campaniaId,@fecha fecha,@usuario responsableId,
      (SELECT COALESCE(SUM(D.kilogramos),0) FROM comercial.EntregaDetalle D
       JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id
       JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
       JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
       WHERE O.campania_venta_id=@camp AND E.estado=1 AND E.estado_proceso='CONFIRMADA' AND D.estado=1) kilos,
      (SELECT COALESCE(SUM(D.kilogramos*D.precio_base),0) FROM comercial.EntregaDetalle D
       JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id
       JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
       JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
       WHERE O.campania_venta_id=@camp AND E.estado=1 AND E.estado_proceso='CONFIRMADA' AND D.estado=1) ventaBruta,
      (SELECT COALESCE(SUM(D.importe),0) FROM comercial.EntregaDetalle D
       JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id
       JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
       JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
       WHERE O.campania_venta_id=@camp AND E.estado=1 AND E.estado_proceso='CONFIRMADA' AND D.estado=1) ventaEfectiva,
      (SELECT COALESCE(SUM(L.importe_neto),0) FROM finanzas.LiquidacionSocio L
       JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
       WHERE P.campania_venta_id=@camp AND L.estado=1 AND L.estado_proceso='APROBADA') netoAprobado,
      (SELECT COALESCE(SUM(PG.importe),0) FROM finanzas.PagoSocio PG
       JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=PG.liquidacion_socio_id
       JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
       WHERE P.campania_venta_id=@camp AND PG.estado=1 AND PG.estado_proceso='CONFIRMADO') pagos,
      (SELECT COALESCE(SUM(B.importe),0) FROM finanzas.CobroComprador B
       WHERE B.campania_venta_id=@camp AND B.estado=1 AND B.estado_proceso='CONFIRMADO') cobros,
      (SELECT COALESCE(SUM(G.importe),0) FROM finanzas.GastoCampania G
       WHERE G.campania_venta_id=@camp AND G.estado=1 AND G.estado_proceso='APROBADO') gastos,
      JSON_QUERY((SELECT codigo,detalle FROM @problemas FOR JSON PATH)) diferencias
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    UPDATE comercial.CampaniaVenta SET estado_proceso='CERRADA'
      WHERE campania_venta_id=@camp AND estado=1 AND estado_proceso='ACTIVA';
    IF @@ROWCOUNT<>1 THROW 51663,N'Solo una campaña activa puede cerrarse.',1;
    INSERT comercial.CierreCampaniaE5(campania_venta_id,usuario_id,observacion,excepcion_autorizada,motivo_excepcion,balance_final)
      VALUES(@camp,@usuario,@motivo,@excepcion,JSON_VALUE(@cJson,'$.datos.motivoExcepcion'),@balanceJson);
   END
   ELSE
   SET @cDatos=(SELECT @camp campaniaId,@pendientes pendientes,
      CONVERT(BIT,CASE WHEN @pendientes=0 THEN 1 ELSE 0 END) habilitado,
      JSON_QUERY((SELECT codigo,detalle FROM @problemas FOR JSON PATH)) diferencias
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END;
  IF @mutacion=1
  BEGIN
   -- El cierre automático solo ocurre al vencimiento y sin obligaciones pendientes.
   EXEC finanzas.PA_E5_Campania_CierreAutomatico @campaniaId=@camp;
   INSERT finanzas.SolicitudE5(usuario_id,clave,accion,huella,respuesta)
    VALUES(@usuario,@clave,@cAccion,@hash,COALESCE(@cDatos,N'{}'));
   DECLARE @auditId BIGINT,@transId BIGINT,@identificadorCampania NVARCHAR(200);
   SET @identificadorCampania=CONVERT(NVARCHAR(200),@camp);
   EXEC auditoria.PA_Operacion_Ins_RegistrarCambio
     @usuario,@sesion,@dispositivo,@modulo,@cAccion,'finanzas','APAPPSS_E5',@identificadorCampania,
     NULL,NULL,NULL,'operacion',NULL,@cAccion,@ip,@corr,@sol,@endpoint,@auditId OUTPUT,@transId OUTPUT;
   COMMIT TRANSACTION;
  END;
  SELECT @bResultado=1,@cCodigoRespuesta='E5_OK',@nHttpRespuesta=200,@cMensaje=N'Operación completada.';
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SET @bResultado=0;SET @cDatos=NULL;
  SET @cCodigoRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51600 AND 51699 THEN 'E5_VALIDACION' ELSE 'E5_BD_ERROR' END;
  SET @nHttpRespuesta=CASE WHEN ERROR_NUMBER() IN(51600,51601,51636) THEN 403
      WHEN ERROR_NUMBER() BETWEEN 51600 AND 51699 THEN 409 ELSE 503 END;
  SET @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51600 AND 51699 THEN LEFT(ERROR_MESSAGE(),300)
       ELSE N'No se pudo completar la operación. Verifique los datos y vuelva a intentar.' END;
 END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE comercial.PA_CampaniaVenta_Upd_Vencer
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @Vencidas TABLE
    (
        campania_venta_id BIGINT NOT NULL,
        estado_anterior VARCHAR(20) NOT NULL,
        estado_nuevo VARCHAR(20) NOT NULL,
        fecha_hora_utc DATETIME2(0) NOT NULL
    );
    -- Vencimiento comercial separado; el cierre financiero exige obligaciones conciliadas.
    BEGIN TRANSACTION;
    UPDATE C
       SET estado_proceso = 'VENCIDA'
    OUTPUT inserted.campania_venta_id, deleted.estado_proceso,
           inserted.estado_proceso, SYSUTCDATETIME()
      INTO @Vencidas
           (campania_venta_id, estado_anterior, estado_nuevo, fecha_hora_utc)
      FROM comercial.CampaniaVenta C
     WHERE C.estado = 1
       AND C.estado_proceso = 'ACTIVA'
       AND C.fecha_fin < CONVERT(DATE, DATEADD(HOUR, -5, SYSUTCDATETIME()));
    INSERT INTO comercial.CampaniaVencimientoLog
        (campania_venta_id, estado_anterior, estado_nuevo, fecha_hora_utc)
    SELECT campania_venta_id, estado_anterior, estado_nuevo, fecha_hora_utc
    FROM @Vencidas;
    DECLARE @c BIGINT;
    DECLARE vencidas_cursor CURSOR LOCAL FAST_FORWARD FOR
      SELECT campania_venta_id FROM @Vencidas
      UNION SELECT campania_venta_id FROM comercial.CampaniaVenta
      WHERE estado=1 AND estado_proceso='VENCIDA' AND fecha_fin<CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()));
    OPEN vencidas_cursor;
    FETCH NEXT FROM vencidas_cursor INTO @c;
    WHILE @@FETCH_STATUS=0
    BEGIN
        EXEC finanzas.PA_E5_Campania_CierreAutomatico @campaniaId=@c;
        FETCH NEXT FROM vencidas_cursor INTO @c;
    END;
    CLOSE vencidas_cursor;
    DEALLOCATE vencidas_cursor;
    COMMIT TRANSACTION;
    SELECT COUNT(*) AS vencidas FROM @Vencidas;
END;
GO
