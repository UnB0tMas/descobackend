IF OBJECT_ID(N'[comercial].[PA_CampaniaJabaPlan_Sel_Detalle]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_CampaniaJabaPlan_Sel_Detalle];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_CampaniaJabaPlan_Sel_Detalle
' Descripción            : Consulta información de Campania Jaba Plan (detalle).
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_CampaniaJabaPlan_Sel_Detalle
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo consultar la campaña.',@cCodigoRespuesta='JABAS_PLAN_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
 @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
 @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300);
 BEGIN TRY
  IF @camp IS NULL THROW 51410,N'Seleccione una campaña.',1;
  SELECT @uot=uot_id FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp AND estado=1;
  IF @uot IS NULL THROW 51411,N'Campaña no disponible.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='CAMPANIAS_VER',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'CAMPANIAS_VER')<>1
     OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'PARTICIPANTES_LISTAR')<>1
    THROW 51412,N'No puede consultar los participantes de esta campaña.',1;
  SET @cDatos=(SELECT C.campania_venta_id campaniaId,C.modalidad_venta_id modalidadVentaId,C.origen_jabas origenJabas,
    C.comprador_apappss_id compradorId,B.tipo tipoComprador,
    COALESCE(CASE WHEN B.tipo='PERSONA' THEN NULLIF(TRIM(CONCAT(P.nombres,N' ',P.apellido_paterno,N' ',COALESCE(P.apellido_materno,N''))),N'') ELSE EB.razon_social END,EC.razon_social) compradorNombre,
    (SELECT TOP(1) CC.condicion_comercial_id FROM comercial.CondicionComercial CC
     WHERE CC.modalidad_venta_id=C.modalidad_venta_id
      AND CC.codigo=CONCAT('APAPPSS_MODALIDAD_',CONVERT(VARCHAR(12),C.modalidad_venta_id)) AND CC.estado=1) condicionComercialId,
    K.cupo_jabas cupoJabas,K.tara_kg taraKg,
   S.existencia_certificada stockFisico,
   (SELECT COALESCE(SUM(CONVERT(BIGINT,J.cantidad)+CASE WHEN J.cantidad_ajuste_pendiente>0 THEN CONVERT(BIGINT,J.cantidad_ajuste_pendiente) ELSE 0 END),0) FROM comercial.CampaniaJabaPlan J
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
    WHERE P.campania_venta_id=@camp AND J.activo=1 AND J.estado<>'DEVUELTA') jabasComprometidas,
   (SELECT COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-A.cantidad_devuelta),0)
    FROM comercial.JabaAsignacion A JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
    JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
    WHERE O.campania_venta_id=@camp AND A.estado=1) jabasOperativo,
   JSON_QUERY((SELECT P.participacion_campania_socio_id participacionId,
     SA.socio_asociacion_id socioAsociacionId,PE.numero_documento documento,
     CONCAT(PE.nombres,N' ',PE.apellido_paterno,N' ',COALESCE(PE.apellido_materno,N'')) socioNombre,
     P.estado_participacion estadoParticipacion,J.campania_jaba_plan_id asignacionId,
     J.cantidad cantidadJabas,
     CASE WHEN J.estado='ENTREGADA' AND J.cantidad_ajuste_pendiente>0 THEN 'PENDIENTE_RECOJO'
          WHEN J.estado='ENTREGADA' AND J.cantidad_ajuste_pendiente<0 THEN 'PENDIENTE_DEVOLUCION'
          ELSE J.estado END estadoJabas,
     J.cantidad+J.cantidad_ajuste_pendiente cantidadObjetivo,
     J.cantidad_ajuste_pendiente cantidadAjustePendiente,
     J.comentario_ajuste_pendiente comentarioAjustePendiente,J.version versionJabas
     FROM comercial.ParticipacionCampaniaSocio P JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=P.socio_asociacion_id
     JOIN org.Socio SO ON SO.socio_id=SA.socio_id
     JOIN org.Persona PE ON PE.persona_id=SO.socio_id
     LEFT JOIN comercial.CampaniaJabaPlan J ON J.participacion_campania_socio_id=P.participacion_campania_socio_id AND J.activo=1
     WHERE P.campania_venta_id=@camp AND P.estado=1 AND P.estado_participacion='ACTIVO'
     ORDER BY PE.apellido_paterno,PE.nombres,P.participacion_campania_socio_id FOR JSON PATH)) participantes
   FROM comercial.CampaniaVenta C
   LEFT JOIN comercial.CompradorAPAPPSS B ON B.comprador_apappss_id=C.comprador_apappss_id AND B.uot_id=C.uot_id
   LEFT JOIN org.Persona P ON P.persona_id=B.persona_id
   LEFT JOIN org.Empresa EB ON EB.empresa_id=B.empresa_id
   LEFT JOIN org.Empresa EC ON EC.empresa_id=C.empresa_compradora_id
   LEFT JOIN comercial.CampaniaControlE4 K ON K.campania_venta_id=C.campania_venta_id
   LEFT JOIN comercial.JabaStockUotE4 S ON S.uot_id=C.uot_id WHERE C.campania_venta_id=@camp
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Plan de jabas consultado.',@cCodigoRespuesta='JABAS_PLAN_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  SELECT @bResultado=0,@cCodigoRespuesta='JABAS_PLAN_ERROR',@cDatos=NULL,
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51400 AND 51499 THEN 400 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51400 AND 51499 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo consultar el plan de jabas.' END;
 END CATCH;
END;
GO
