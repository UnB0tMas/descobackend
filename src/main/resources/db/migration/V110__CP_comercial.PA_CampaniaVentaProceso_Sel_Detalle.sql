IF OBJECT_ID(N'[comercial].[PA_CampaniaVentaProceso_Sel_Detalle]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_CampaniaVentaProceso_Sel_Detalle];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_CampaniaVentaProceso_Sel_Detalle
' Descripción            : Consulta información de Campania Venta Proceso (detalle).
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_CampaniaVentaProceso_Sel_Detalle
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo consultar la recepción.',@cCodigoRespuesta='RECEPCION_LISTADO_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),@uot BIGINT,
   @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
   @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300),
   @hoy DATE=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()));
 BEGIN TRY
  SELECT @uot=uot_id FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp AND estado=1;
  IF @uot IS NULL THROW 52001,N'La campaña no existe.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='CAMPANIAS_VER',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'CAMPANIAS_VER')<>1
    OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'JABAS_LISTAR')<>1
    THROW 52002,N'No tiene acceso al proceso de venta.',1;
  SET @cDatos=(SELECT C.campania_venta_id campaniaId,C.nombre,C.codigo,C.fecha_inicio fechaInicio,C.fecha_fin fechaFin,
    C.estado_proceso estadoProceso,C.descuento_jaba_kg descuentoJabaKg,
    CAST(CASE WHEN C.estado_proceso IN('ACTIVA','PLANIFICACION') AND @hoy BETWEEN C.fecha_inicio AND C.fecha_fin THEN 1 ELSE 0 END AS BIT) vigente,
    JSON_QUERY((SELECT G.campania_calibre_id calibreId,G.variedad_palta_id variedadPaltaId,V.nombre nombreVariedad,G.calibre,
        G.gramos_desde gramosDesde,G.gramos_hasta gramosHasta,G.precio_kg precioKg,G.version
       FROM comercial.CampaniaCalibre G JOIN prod.VariedadPalta V ON V.variedad_palta_id=G.variedad_palta_id
       WHERE G.campania_venta_id=@camp AND G.activo=1 ORDER BY G.variedad_palta_id,G.gramos_desde FOR JSON PATH)) calibres,
    JSON_QUERY((SELECT P.participacion_campania_socio_id participacionId,P.socio_asociacion_id socioAsociacionId,
       PE.numero_documento documento,
       CONCAT(PE.nombres,N' ',PE.apellido_paterno,N' ',COALESCE(PE.apellido_materno,N'')) socioNombre,J.cantidad asignadas,J.estado estadoJabas,CAST(J.recepcion_confirmada AS BIT) recepcionConfirmada,
       (SELECT COUNT_BIG(*) FROM comercial.CampaniaJabaRecepcion R WHERE R.campania_jaba_plan_id=J.campania_jaba_plan_id) devueltas,
       (SELECT COALESCE(SUM(R.peso_bruto_kg),0) FROM comercial.CampaniaJabaRecepcion R WHERE R.campania_jaba_plan_id=J.campania_jaba_plan_id) pesoBrutoKg,
       (SELECT COALESCE(SUM(R.descuento_jaba_kg),0) FROM comercial.CampaniaJabaRecepcion R WHERE R.campania_jaba_plan_id=J.campania_jaba_plan_id) descuentoTotalKg,
       (SELECT COALESCE(SUM(R.peso_neto_kg),0) FROM comercial.CampaniaJabaRecepcion R WHERE R.campania_jaba_plan_id=J.campania_jaba_plan_id) pesoNetoKg
      FROM comercial.ParticipacionCampaniaSocio P
      JOIN comercial.CampaniaJabaPlan J ON J.participacion_campania_socio_id=P.participacion_campania_socio_id AND J.activo=1
      JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=P.socio_asociacion_id
      JOIN org.Socio SO ON SO.socio_id=SA.socio_id
      JOIN org.Persona PE ON PE.persona_id=SO.socio_id
      WHERE P.campania_venta_id=@camp AND P.estado=1 AND P.estado_participacion='ACTIVO' AND J.cantidad>=1
      ORDER BY P.participacion_campania_socio_id FOR JSON PATH)) socios
   FROM comercial.CampaniaVenta C WHERE C.campania_venta_id=@camp FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Consulta realizada.',@cCodigoRespuesta='RECEPCION_LISTADO_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='RECEPCION_LISTADO_ERROR',
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN 409 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo consultar la recepción.' END;
 END CATCH;
END;
GO
