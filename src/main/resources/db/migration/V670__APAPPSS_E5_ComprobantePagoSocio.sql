-- E5 · Comprobante opcional de pago a socio, vinculado e inmutable.
-- Requiere V669. No modifica las reglas financieras de cálculo ni de aprobación.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF COL_LENGTH('finanzas.PagoBeneficiarioE5','comprobante_archivo_id') IS NULL
    ALTER TABLE finanzas.PagoBeneficiarioE5 ADD comprobante_archivo_id BIGINT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_E5_PagoBeneficiario_Comprobante')
    ALTER TABLE finanzas.PagoBeneficiarioE5 WITH CHECK ADD CONSTRAINT FK_E5_PagoBeneficiario_Comprobante
      FOREIGN KEY (comprobante_archivo_id) REFERENCES archivo.Archivo(archivo_id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('finanzas.PagoBeneficiarioE5')
  AND name='UX_E5_PagoBeneficiario_Comprobante')
    CREATE UNIQUE INDEX UX_E5_PagoBeneficiario_Comprobante
      ON finanzas.PagoBeneficiarioE5(comprobante_archivo_id) WHERE comprobante_archivo_id IS NOT NULL;
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
 SET @cDatos=(SELECT L.liquidacion_socio_id liquidacionId,C.uot_id uotId,PE.persona_id beneficiarioPersonaId,
  PE.numero_documento documento,CONCAT(PE.nombres,N' ',PE.apellido_paterno,N' ',COALESCE(PE.apellido_materno,N'')) nombre,
  JSON_QUERY((SELECT B.pago_socio_id pagoId,B.beneficiario_persona_id beneficiarioPersonaId,B.documento,B.nombre,
      B.usuario_registro_id usuarioId,B.fecha_registro fecha,B.motivo_entrega motivoEntrega,
      B.comprobante_archivo_id comprobanteArchivoId
      FROM finanzas.PagoBeneficiarioE5 B JOIN finanzas.PagoSocio PS ON PS.pago_socio_id=B.pago_socio_id
      WHERE PS.liquidacion_socio_id=L.liquidacion_socio_id ORDER BY B.fecha_registro DESC FOR JSON PATH)) historial
 FROM finanzas.LiquidacionSocio L
 JOIN comercial.ParticipacionCampaniaSocio PC ON PC.participacion_campania_socio_id=L.participacion_campania_socio_id
 JOIN comercial.CampaniaVenta C ON C.campania_venta_id=PC.campania_venta_id AND C.estado=1
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
   @comprobante BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.comprobanteArchivoId')),
   @motivo NVARCHAR(500)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.motivoEntrega')),N''),
   @titular BIGINT,@estadoCamp VARCHAR(30),
   @medio VARCHAR(30)=UPPER(JSON_VALUE(@cJson,'$.datos.medioPago')),
   @referencia VARCHAR(100)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.referencia')),''),
   @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
   @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@ok BIT,@msg NVARCHAR(300),
   @ret BIT,@respuesta NVARCHAR(MAX),@detalle NVARCHAR(300),@codigo VARCHAR(60),@http SMALLINT,
   @pagoId BIGINT;
 IF (@comprobante IS NULL AND JSON_VALUE(@cJson,'$.datos.comprobanteArchivoId') IS NOT NULL)
    OR (@comprobante IS NOT NULL AND @comprobante<1)
 BEGIN SET @cMensaje=N'Comprobante no válido.';RETURN;END;
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
 SELECT @uot=C.uot_id,@titular=PE.persona_id,@estadoCamp=C.estado_proceso FROM finanzas.LiquidacionSocio L
 JOIN comercial.ParticipacionCampaniaSocio PC ON PC.participacion_campania_socio_id=L.participacion_campania_socio_id
 JOIN comercial.CampaniaVenta C ON C.campania_venta_id=PC.campania_venta_id AND C.estado=1
 JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=PC.socio_asociacion_id
 JOIN org.Persona PE ON PE.persona_id=SA.socio_id AND PE.estado=1
 WHERE L.liquidacion_socio_id=@liq AND L.estado=1 AND L.estado_proceso='APROBADA';
 IF @uot IS NULL OR @estadoCamp<>'ACTIVA' OR
    CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())) NOT BETWEEN
    (SELECT fecha_inicio FROM comercial.CampaniaVenta WHERE campania_venta_id=
       (SELECT PC.campania_venta_id FROM finanzas.LiquidacionSocio L
        JOIN comercial.ParticipacionCampaniaSocio PC ON PC.participacion_campania_socio_id=L.participacion_campania_socio_id
        WHERE L.liquidacion_socio_id=@liq))
    AND (SELECT fecha_fin FROM comercial.CampaniaVenta WHERE campania_venta_id=
       (SELECT PC.campania_venta_id FROM finanzas.LiquidacionSocio L
        JOIN comercial.ParticipacionCampaniaSocio PC ON PC.participacion_campania_socio_id=L.participacion_campania_socio_id
        WHERE L.liquidacion_socio_id=@liq))
 BEGIN SET @cMensaje=N'Solo se pagan liquidaciones aprobadas de campañas vigentes.';RETURN;END;
 IF NOT EXISTS(SELECT 1 FROM org.Persona WHERE persona_id=@beneficiario AND estado=1)
 BEGIN SET @cMensaje=N'El receptor no existe o no está activo.';RETURN;END;
 IF @beneficiario<>@titular AND (@motivo IS NULL OR LEN(@motivo)<10)
 BEGIN SET @cMensaje=N'Detalle la autorización o motivo de entrega a una persona distinta del socio.';RETURN;END;
 BEGIN TRY
 EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='PAGOS_CONFIRMAR',
  @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
  @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
  @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
  @bResultado=@ok OUTPUT,@cMensaje=@msg OUTPUT;
 IF ISNULL(@ok,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'PAGOS_CONFIRMAR')<>1
  THROW 51720,N'No dispone de permiso para pagar a este socio.',1;
 BEGIN TRANSACTION;
 IF @comprobante IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM archivo.Archivo A WITH (UPDLOCK,HOLDLOCK)
    WHERE A.archivo_id=@comprobante AND A.uot_id=@uot AND A.usuario_id=@usuario
      AND A.estado=1 AND A.proveedor_almacenamiento='LOCAL' AND A.categoria='COMPROBANTE'
      AND A.mime_type IN ('application/pdf','image/jpeg','image/png','image/webp')
      AND A.tamano_bytes>0 AND A.tamano_bytes<=10485760
      AND NOT EXISTS(SELECT 1 FROM finanzas.PagoBeneficiarioE5 B WITH(UPDLOCK,HOLDLOCK)
                     WHERE B.comprobante_archivo_id=A.archivo_id)
 ) THROW 51723,N'El comprobante no está disponible para este pago.',1;
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
  INSERT finanzas.PagoBeneficiarioE5(pago_socio_id,beneficiario_persona_id,documento,nombre,usuario_registro_id,motivo_entrega,comprobante_archivo_id)
  SELECT @pagoId,PE.persona_id,CONCAT(PE.tipo_documento,':',PE.numero_documento),
    CONCAT(PE.nombres,N' ',PE.apellido_paterno,N' ',COALESCE(PE.apellido_materno,N'')),@usuario,
    CASE WHEN @beneficiario<>@titular THEN @motivo ELSE NULL END,@comprobante
  FROM org.Persona PE WHERE PE.persona_id=@beneficiario AND PE.estado=1;
  IF @@ROWCOUNT<>1 THROW 51722,N'El beneficiario ya no está activo.',1;
 END
 ELSE IF ISNULL((SELECT comprobante_archivo_id FROM finanzas.PagoBeneficiarioE5 WHERE pago_socio_id=@pagoId),0)
         <>ISNULL(@comprobante,0)
     THROW 51724,N'El comprobante de un pago confirmado no puede cambiarse.',1;
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
