-- E5. Refuerzo incremental: inmutabilidad por socio, gasto común congelado,
-- beneficiario auditado y lecturas analíticas con filtros desde el PA.
-- No modifica versiones Flyway aplicadas anteriormente.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'finanzas.PagoBeneficiarioE5',N'U') IS NULL
BEGIN
    CREATE TABLE finanzas.PagoBeneficiarioE5 (
        pago_socio_id BIGINT NOT NULL CONSTRAINT PK_PagoBeneficiarioE5 PRIMARY KEY
            REFERENCES finanzas.PagoSocio(pago_socio_id),
        beneficiario_persona_id BIGINT NOT NULL REFERENCES org.Persona(persona_id),
        documento VARCHAR(60) NOT NULL,
        nombre NVARCHAR(290) NOT NULL,
        usuario_registro_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
        fecha_registro DATETIME2(0) NOT NULL CONSTRAINT DF_PagoBeneficiarioE5_Fecha DEFAULT SYSUTCDATETIME()
    );
END;
GO
CREATE OR ALTER TRIGGER finanzas.TR_E5_Gasto_NoModificarConLiquidacion
ON finanzas.GastoCampania AFTER INSERT,UPDATE,DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM (SELECT campania_venta_id FROM inserted UNION SELECT campania_venta_id FROM deleted) X
        JOIN comercial.ParticipacionCampaniaSocio PC ON PC.campania_venta_id=X.campania_venta_id
        JOIN finanzas.LiquidacionSocio L ON L.participacion_campania_socio_id=PC.participacion_campania_socio_id
        WHERE L.estado=1 AND L.estado_proceso IN ('APROBADA','PAGADA_PARCIAL','PAGADA')
    ) THROW 51700,N'Los gastos comunes están congelados porque ya existe una liquidación aprobada.',1;
END;
GO
CREATE OR ALTER TRIGGER finanzas.TR_E5_GastoProrrateo_NoModificarConLiquidacion
ON finanzas.GastoProrrateoSocio AFTER INSERT,UPDATE,DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM (SELECT gasto_campania_id FROM inserted UNION SELECT gasto_campania_id FROM deleted) X
        JOIN finanzas.GastoCampania G ON G.gasto_campania_id=X.gasto_campania_id
        JOIN comercial.ParticipacionCampaniaSocio PC ON PC.campania_venta_id=G.campania_venta_id
        JOIN finanzas.LiquidacionSocio L ON L.participacion_campania_socio_id=PC.participacion_campania_socio_id
        WHERE L.estado=1 AND L.estado_proceso IN ('APROBADA','PAGADA_PARCIAL','PAGADA')
    ) THROW 51701,N'El reparto ya forma parte de liquidaciones aprobadas y no puede modificarse.',1;
END;
GO
CREATE OR ALTER TRIGGER finanzas.TR_E5_RepartoVersion_NoCambiarLiquidado
ON finanzas.GastoRepartoVersionE5 AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (
  SELECT 1 FROM (SELECT gasto_campania_id FROM inserted UNION SELECT gasto_campania_id FROM deleted) X
  JOIN finanzas.GastoCampania G ON G.gasto_campania_id=X.gasto_campania_id
  JOIN comercial.ParticipacionCampaniaSocio PC ON PC.campania_venta_id=G.campania_venta_id
  JOIN finanzas.LiquidacionSocio L ON L.participacion_campania_socio_id=PC.participacion_campania_socio_id
  WHERE L.estado=1 AND L.estado_proceso IN ('APROBADA','PAGADA_PARCIAL','PAGADA')
 ) THROW 51705,N'La versión del reparto es inmutable tras una liquidación aprobada.',1;
END;
GO
CREATE OR ALTER TRIGGER finanzas.TR_E5_RepartoLinea_NoCambiarLiquidado
ON finanzas.GastoRepartoLineaE5 AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (
  SELECT 1 FROM (SELECT reparto_id FROM inserted UNION SELECT reparto_id FROM deleted) X
  JOIN finanzas.GastoRepartoVersionE5 R ON R.reparto_id=X.reparto_id
  JOIN finanzas.GastoCampania G ON G.gasto_campania_id=R.gasto_campania_id
  JOIN comercial.ParticipacionCampaniaSocio PC ON PC.campania_venta_id=G.campania_venta_id
  JOIN finanzas.LiquidacionSocio L ON L.participacion_campania_socio_id=PC.participacion_campania_socio_id
  WHERE L.estado=1 AND L.estado_proceso IN ('APROBADA','PAGADA_PARCIAL','PAGADA')
 ) THROW 51706,N'Las cuotas distribuidas no pueden cambiar después de aprobar una liquidación.',1;
END;
GO
CREATE OR ALTER TRIGGER finanzas.TR_E5_Liquidacion_BloqueoAprobadas
ON finanzas.LiquidacionSocio AFTER INSERT,UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- La liquidación aún calculada puede observarse; una aprobada jamás se anula
    -- para recalcular, ni puede cambiar sus montos. Sus pagos se registran aparte.
    IF EXISTS (
        SELECT 1 FROM inserted I
        JOIN deleted D ON D.liquidacion_socio_id=I.liquidacion_socio_id
        WHERE D.estado_proceso IN ('APROBADA','PAGADA_PARCIAL','PAGADA')
          AND (I.estado_proceso NOT IN ('APROBADA','PAGADA_PARCIAL','PAGADA')
            OR I.importe_bruto<>D.importe_bruto OR I.importe_neto<>D.importe_neto
            OR I.total_gastos<>D.total_gastos OR I.total_ajustes<>D.total_ajustes
            OR I.total_bonificaciones<>D.total_bonificaciones OR I.estado<>D.estado)
    ) THROW 51702,N'La liquidación aprobada es inmutable, incluso para administradores.',1;
    IF EXISTS (
        SELECT 1 FROM inserted I
        JOIN finanzas.LiquidacionSocio L ON L.participacion_campania_socio_id=I.participacion_campania_socio_id
          AND L.liquidacion_socio_id<>I.liquidacion_socio_id AND L.estado=1
          AND L.estado_proceso IN ('APROBADA','PAGADA_PARCIAL','PAGADA')
        WHERE NOT EXISTS (SELECT 1 FROM deleted D WHERE D.liquidacion_socio_id=I.liquidacion_socio_id)
    ) THROW 51703,N'El socio ya tiene una liquidación aprobada; no se permite otra versión.',1;
    IF EXISTS (
        SELECT 1 FROM inserted I
        JOIN comercial.ParticipacionCampaniaSocio PC ON PC.participacion_campania_socio_id=I.participacion_campania_socio_id
        JOIN finanzas.GastoCampania G ON G.campania_venta_id=PC.campania_venta_id AND G.estado=1
        WHERE I.estado=1 AND I.estado_proceso='CALCULADA' AND G.estado_proceso<>'APROBADO'
    ) THROW 51704,N'Apruebe primero todos los gastos y sus repartos antes de liquidar.',1;
END;
GO
CREATE OR ALTER PROCEDURE finanzas.PA_E5_Graficos_Sel_Indicadores
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @bResultado=0,@cDatos=NULL,@cMensaje=N'No se pudieron consultar los gráficos.',@cCodigoRespuesta='E5_GRAFICOS_ERROR',@nHttpRespuesta=400;
 IF ISJSON(@cJson)<>1 RETURN;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @inicio DATE=TRY_CONVERT(DATE,NULLIF(JSON_VALUE(@cJson,'$.datos.fechaInicio'),'')),
  @fin DATE=TRY_CONVERT(DATE,NULLIF(JSON_VALUE(@cJson,'$.datos.fechaFin'),'')),
  @variedad SMALLINT=TRY_CONVERT(SMALLINT,JSON_VALUE(@cJson,'$.datos.variedadPaltaId')),
  @uot BIGINT,@asoc BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@ok BIT,@msg NVARCHAR(300);
 SELECT @uot=C.uot_id,@asoc=C.asociacion_id,@inicio=COALESCE(@inicio,C.fecha_inicio),
  @fin=COALESCE(@fin,C.fecha_fin,CONVERT(DATE,SYSUTCDATETIME()))
 FROM comercial.CampaniaVenta C WHERE C.campania_venta_id=@camp AND C.estado=1;
 IF @uot IS NULL OR @inicio IS NULL OR @fin IS NULL OR @fin<@inicio OR DATEDIFF(DAY,@inicio,@fin)>366
 BEGIN SET @cMensaje=N'Campaña o rango de fechas inválido.';RETURN; END;
 BEGIN TRY
 EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='LIQUIDACIONES_LISTAR',
  @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
  @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
  @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
  @bResultado=@ok OUTPUT,@cMensaje=@msg OUTPUT;
 IF ISNULL(@ok,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'LIQUIDACIONES_LISTAR')<>1
  THROW 51710,N'No dispone de acceso territorial a esta campaña.',1;
 IF NOT EXISTS(SELECT 1 FROM org.ConvenioUOTOrganizacion CU
    JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND CM.estado=1
    JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
    WHERE CU.uot_id=@uot AND CU.empresa_id=@asoc AND CU.estado=1
    AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,SYSUTCDATETIME()))
    AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,SYSUTCDATETIME())))
  THROW 51711,N'El convenio de la campaña no está habilitado.',1;
 SET @cDatos=(SELECT @camp campaniaId,@inicio fechaInicio,@fin fechaFin,@variedad variedadPaltaId,
  JSON_QUERY((SELECT CONVERT(CHAR(10),CONVERT(DATE,E.fecha_hora),126) fecha,
   CONVERT(DECIMAL(19,3),SUM(D.kilogramos)) kilogramos,
   CONVERT(DECIMAL(19,2),SUM(D.importe)) ventaEfectiva
   FROM comercial.EntregaDetalle D
   JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
   JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id AND OS.estado=1
   JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
   WHERE O.campania_venta_id=@camp AND D.estado=1 AND E.fecha_hora>=@inicio AND E.fecha_hora<DATEADD(DAY,1,@fin)
     AND (@variedad IS NULL OR D.variedad_palta_id=@variedad)
   GROUP BY CONVERT(DATE,E.fecha_hora) ORDER BY CONVERT(DATE,E.fecha_hora) FOR JSON PATH)) porDia,
  JSON_QUERY((SELECT D.variedad_palta_id variedadId,V.nombre variedad,
    CONVERT(DECIMAL(19,3),SUM(D.kilogramos)) kilogramos,
    CONVERT(DECIMAL(19,2),SUM(D.importe)) ventaEfectiva
   FROM comercial.EntregaDetalle D
   JOIN prod.VariedadPalta V ON V.variedad_palta_id=D.variedad_palta_id
   JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
   JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id AND OS.estado=1
   JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
   WHERE O.campania_venta_id=@camp AND D.estado=1 AND E.fecha_hora>=@inicio AND E.fecha_hora<DATEADD(DAY,1,@fin)
     AND (@variedad IS NULL OR D.variedad_palta_id=@variedad)
   GROUP BY D.variedad_palta_id,V.nombre ORDER BY V.nombre FOR JSON PATH)) porVariedad
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 SELECT @bResultado=1,@cMensaje=N'Indicadores consultados.',@cCodigoRespuesta='E5_GRAFICOS_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  SELECT @bResultado=0,@cMensaje=N'No fue posible consultar los gráficos.',@cCodigoRespuesta='E5_GRAFICOS_ERROR',@nHttpRespuesta=400;
 END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE finanzas.PA_E5_Beneficiario_Sel_Liquidacion
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @bResultado=0,@cDatos=NULL,@cMensaje=N'Liquidación no disponible.',@cCodigoRespuesta='E5_BENEFICIARIO_ERROR',@nHttpRespuesta=400;
 IF ISJSON(@cJson)<>1 RETURN;
 DECLARE @liq BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.liquidacionId')),
  @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@ok BIT,@msg NVARCHAR(300);
 SELECT @uot=C.uot_id FROM finanzas.LiquidacionSocio L
 JOIN comercial.ParticipacionCampaniaSocio PC ON PC.participacion_campania_socio_id=L.participacion_campania_socio_id
 JOIN comercial.CampaniaVenta C ON C.campania_venta_id=PC.campania_venta_id AND C.estado=1
 WHERE L.liquidacion_socio_id=@liq AND L.estado=1;
 IF @uot IS NULL RETURN;
 EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='PAGOS_LISTAR',
  @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
  @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
  @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
  @bResultado=@ok OUTPUT,@cMensaje=@msg OUTPUT;
 IF ISNULL(@ok,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'PAGOS_LISTAR')<>1 RETURN;
 SET @cDatos=(SELECT L.liquidacion_socio_id liquidacionId,PE.persona_id beneficiarioPersonaId,
  PE.numero_documento documento,CONCAT(PE.nombres,N' ',PE.apellido_paterno,N' ',COALESCE(PE.apellido_materno,N'')) nombre,
  JSON_QUERY((SELECT B.pago_socio_id pagoId,B.beneficiario_persona_id beneficiarioPersonaId,B.documento,B.nombre,
      B.usuario_registro_id usuarioId,B.fecha_registro fecha
      FROM finanzas.PagoBeneficiarioE5 B JOIN finanzas.PagoSocio PS ON PS.pago_socio_id=B.pago_socio_id
      WHERE PS.liquidacion_socio_id=L.liquidacion_socio_id ORDER BY B.fecha_registro DESC FOR JSON PATH)) historial
 FROM finanzas.LiquidacionSocio L
 JOIN comercial.ParticipacionCampaniaSocio PC ON PC.participacion_campania_socio_id=L.participacion_campania_socio_id
 JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=PC.socio_asociacion_id
 JOIN org.Persona PE ON PE.persona_id=SA.socio_id AND PE.estado=1
 WHERE L.liquidacion_socio_id=@liq AND L.estado=1 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 IF @cDatos IS NULL RETURN;
 SELECT @bResultado=1,@cMensaje=N'Beneficiario verificado.',@cCodigoRespuesta='E5_BENEFICIARIO_OK',@nHttpRespuesta=200;
END;
GO
CREATE OR ALTER PROCEDURE finanzas.PA_E5_PagoBeneficiario_Ins_Confirmado
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @bResultado=0,@cDatos=NULL,@cMensaje=N'No fue posible registrar el pago.',@cCodigoRespuesta='E5_PAGO_ERROR',@nHttpRespuesta=400;
 IF ISJSON(@cJson)<>1 RETURN;
 DECLARE @liq BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.liquidacionId')),
   @beneficiario BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.beneficiarioPersonaId')),
   @medio VARCHAR(30)=UPPER(JSON_VALUE(@cJson,'$.datos.medioPago')),
   @referencia VARCHAR(100)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.referencia')),''),
   @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
   @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@ok BIT,@msg NVARCHAR(300),
   @ret BIT,@respuesta NVARCHAR(MAX),@detalle NVARCHAR(300),@codigo VARCHAR(60),@http SMALLINT,
   @pagoId BIGINT;
 IF @medio NOT IN ('YAPE','PLIN','EFECTIVO','DEPOSITO') OR @beneficiario IS NULL
 BEGIN SET @cMensaje=N'Indique un beneficiario y un método de pago válido.';RETURN;END;
 IF @medio='YAPE' AND (@referencia IS NULL OR LEN(@referencia)<>3 OR @referencia LIKE '%[^0-9]%')
 BEGIN SET @cMensaje=N'Yape requiere los tres dígitos de verificación de la operación.';RETURN;END;
 IF @medio='DEPOSITO' AND @referencia IS NULL
 BEGIN SET @cMensaje=N'El depósito requiere un número de operación bancaria.';RETURN;END;
 IF @medio='PLIN' AND @referencia IS NOT NULL AND LEN(@referencia)>60
 BEGIN SET @cMensaje=N'La referencia de Plin contiene caracteres no permitidos.';RETURN;END;
 IF @medio='EFECTIVO' AND @referencia IS NOT NULL
 BEGIN SET @cMensaje=N'El pago en efectivo no debe llevar número de operación.';RETURN;END;
 SELECT @uot=C.uot_id FROM finanzas.LiquidacionSocio L
 JOIN comercial.ParticipacionCampaniaSocio PC ON PC.participacion_campania_socio_id=L.participacion_campania_socio_id
 JOIN comercial.CampaniaVenta C ON C.campania_venta_id=PC.campania_venta_id AND C.estado=1
 JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=PC.socio_asociacion_id
 JOIN org.Persona PE ON PE.persona_id=SA.socio_id AND PE.estado=1 AND PE.persona_id=@beneficiario
 WHERE L.liquidacion_socio_id=@liq AND L.estado=1 AND L.estado_proceso='APROBADA';
 IF @uot IS NULL BEGIN SET @cMensaje=N'El beneficiario debe ser el socio de la liquidación aprobada.';RETURN;END;
 BEGIN TRY
 EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='PAGOS_CONFIRMAR',
  @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
  @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
  @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
  @bResultado=@ok OUTPUT,@cMensaje=@msg OUTPUT;
 IF ISNULL(@ok,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'PAGOS_CONFIRMAR')<>1
  THROW 51720,N'No dispone de permiso para pagar a este socio.',1;
 BEGIN TRANSACTION;
 -- Un solo pago: se reutiliza la operación E5 idempotente y transaccional.
 EXEC finanzas.PA_APAPPSS_E5_Ejecutar @cAccion='PAGAR',@cJson=@cJson,
  @cDatos=@respuesta OUTPUT,@bResultado=@ret OUTPUT,@cMensaje=@detalle OUTPUT,
  @cCodigoRespuesta=@codigo OUTPUT,@nHttpRespuesta=@http OUTPUT;
 IF ISNULL(@ret,0)<>1
 BEGIN ROLLBACK TRANSACTION;SELECT @cMensaje=@detalle,@cCodigoRespuesta=@codigo,@nHttpRespuesta=@http;RETURN;END;
 SELECT @pagoId=MAX(TRY_CONVERT(BIGINT,JSON_VALUE(J.value,'$.pagoId')))
 FROM OPENJSON(@respuesta,'$.pagos') J;
 IF @pagoId IS NULL THROW 51721,N'No se identificó el pago confirmado.',1;
 IF NOT EXISTS(SELECT 1 FROM finanzas.PagoBeneficiarioE5 WHERE pago_socio_id=@pagoId)
 BEGIN
  INSERT finanzas.PagoBeneficiarioE5(pago_socio_id,beneficiario_persona_id,documento,nombre,usuario_registro_id)
  SELECT @pagoId,PE.persona_id,CONCAT(PE.tipo_documento,':',PE.numero_documento),
    CONCAT(PE.nombres,N' ',PE.apellido_paterno,N' ',COALESCE(PE.apellido_materno,N'')),@usuario
  FROM org.Persona PE WHERE PE.persona_id=@beneficiario AND PE.estado=1;
  IF @@ROWCOUNT<>1 THROW 51722,N'El beneficiario ya no está activo.',1;
 END;
 COMMIT TRANSACTION;
 SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Pago realizado y beneficiario auditado.',
  @cCodigoRespuesta='E5_PAGO_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @bResultado=0,@cMensaje=N'No fue posible registrar el pago. Revise el estado de la liquidación.',
   @cCodigoRespuesta='E5_PAGO_ERROR',@nHttpRespuesta=409;
 END CATCH;
END;
GO
