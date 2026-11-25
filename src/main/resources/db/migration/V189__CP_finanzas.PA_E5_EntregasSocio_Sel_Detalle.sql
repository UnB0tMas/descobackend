IF OBJECT_ID(N'[finanzas].[PA_E5_EntregasSocio_Sel_Detalle]') IS NOT NULL
    DROP PROCEDURE [finanzas].[PA_E5_EntregasSocio_Sel_Detalle];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : finanzas.PA_E5_EntregasSocio_Sel_Detalle
' Descripción            : Consulta información de E5 Entregas Socio (detalle).
' Aplicativo / Módulo    : DESCO / finanzas
*******************************************************************************************************/
CREATE   PROCEDURE finanzas.PA_E5_EntregasSocio_Sel_Detalle
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
  -- Consultas históricas permitidas por permiso UOT, aun sin convenio vigente.

  SET @cDatos=(SELECT @part participacionId,
   JSON_QUERY((SELECT D.entregaId entregaId,
      CASE WHEN D.origen='CAMPANIA' THEN N'Recepción confirmada' ELSE N'Entrega confirmada' END lote,
      CONVERT(VARCHAR(19),MIN(D.fecha_hora),126) fecha,
      COUNT(1) jabas,SUM(D.pesoBruto) pesoBruto,SUM(D.tara) tara,
      CONVERT(DECIMAL(19,3),0) rechazado,SUM(D.kilogramos) aceptado
    FROM finanzas.V_E5_VentasConfirmadas D WHERE D.participacionId=@part
    GROUP BY D.entregaId,D.origen ORDER BY D.entregaId FOR JSON PATH)) entregas,
   JSON_QUERY((SELECT D.partidaId detalleId,D.entregaId,D.variedad,D.condicion_comercial_id condicionId,
      D.condicion,D.kilogramos,D.precio_base precioBase,D.precio_aplicado precioEfectivo,D.importe
    FROM finanzas.V_E5_VentasConfirmadas D WHERE D.participacionId=@part
    ORDER BY D.fecha_hora,D.partidaId FOR JSON PATH)) partidas,
   JSON_QUERY((SELECT D.entregaId entregaId,D.partidaId unidadId,D.numeroJaba numero,
      D.pesoBruto pesoBruto,D.tara,D.kilogramos pesoNeto
    FROM finanzas.V_E5_VentasConfirmadas D WHERE D.participacionId=@part AND D.origen='CAMPANIA'
    ORDER BY D.numeroJaba,D.partidaId FOR JSON PATH)) jabas
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Entregas consultadas.',@cCodigoRespuesta='E5_ENTREGAS_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  SELECT @bResultado=0,@cMensaje=N'No fue posible consultar las entregas.',
   @cCodigoRespuesta='E5_ENTREGAS_ERROR',@nHttpRespuesta=400;
 END CATCH;
END;
GO
