IF OBJECT_ID(N'[finanzas].[PA_E5_CobrosCampania_Sel_Detalle]') IS NOT NULL
    DROP PROCEDURE [finanzas].[PA_E5_CobrosCampania_Sel_Detalle];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : finanzas.PA_E5_CobrosCampania_Sel_Detalle
' Descripción            : Consulta información de E5 Cobros Campania (detalle).
' Aplicativo / Módulo    : DESCO / finanzas
*******************************************************************************************************/
CREATE   PROCEDURE finanzas.PA_E5_CobrosCampania_Sel_Detalle
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
