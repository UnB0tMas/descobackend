IF OBJECT_ID(N'[finanzas].[PA_E5_Beneficiario_Sel_Liquidacion]') IS NOT NULL
    DROP PROCEDURE [finanzas].[PA_E5_Beneficiario_Sel_Liquidacion];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : finanzas.PA_E5_Beneficiario_Sel_Liquidacion
' Descripción            : Consulta e5 beneficiario para liquidacion.
' Aplicativo / Módulo    : DESCO / finanzas
*******************************************************************************************************/
CREATE   PROCEDURE finanzas.PA_E5_Beneficiario_Sel_Liquidacion
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
