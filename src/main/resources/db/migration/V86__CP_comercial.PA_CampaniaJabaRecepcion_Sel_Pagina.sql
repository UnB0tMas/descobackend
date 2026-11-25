IF OBJECT_ID(N'[comercial].[PA_CampaniaJabaRecepcion_Sel_Pagina]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_CampaniaJabaRecepcion_Sel_Pagina];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_CampaniaJabaRecepcion_Sel_Pagina
' Descripción            : Consulta campania jaba recepcion para pagina.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_CampaniaJabaRecepcion_Sel_Pagina
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo consultar las jabas.',@cCodigoRespuesta='RECEPCION_PAGINA_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
   @part BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.participacionId')),
   @pagina INT=COALESCE(TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.filtros.pagina')),1),
   @tamano INT=COALESCE(TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.filtros.tamano')),25),
   @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
   @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300),@plan BIGINT,@cantidad INT;
 BEGIN TRY
  IF @pagina<1 OR @tamano NOT BETWEEN 1 AND 100 OR @part IS NULL THROW 52003,N'Paginación inválida.',1;
  SELECT @uot=C.uot_id,@plan=J.campania_jaba_plan_id,@cantidad=J.cantidad FROM comercial.CampaniaVenta C
   JOIN comercial.ParticipacionCampaniaSocio P ON P.campania_venta_id=C.campania_venta_id AND P.participacion_campania_socio_id=@part AND P.estado=1
   JOIN comercial.CampaniaJabaPlan J ON J.participacion_campania_socio_id=P.participacion_campania_socio_id AND J.activo=1
   WHERE C.campania_venta_id=@camp AND C.estado=1;
  IF @plan IS NULL THROW 52004,N'No se encontró la asignación de jabas.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='JABAS_LISTAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'JABAS_LISTAR')<>1 THROW 52005,N'Acceso no autorizado.',1;
  DECLARE @desde BIGINT=(CONVERT(BIGINT,@pagina)-1)*@tamano+1,@hasta BIGINT=CONVERT(BIGINT,@pagina)*@tamano;
  SET @cDatos=(SELECT @part participacionId,@cantidad asignadas,@pagina pagina,@tamano tamano,
    JSON_QUERY((SELECT R.numero_jaba numero,R.peso_bruto_kg pesoBrutoKg,R.descuento_jaba_kg descuentoKg,
        R.peso_neto_kg pesoNetoKg,R.campania_calibre_id calibreId,R.observacion,R.version,
        X.precio_original_kg precioOriginalKg,X.descuento_precio_kg descuentoSancionKg,
        X.precio_final_kg precioFinalKg,CONVERT(DECIMAL(18,4),R.peso_neto_kg*X.precio_final_kg) importeFinalSoles,
        X.campania_socio_sancion_id sancionAplicacionId,X.sancion_nombre sancionNombre
      FROM comercial.CampaniaJabaRecepcion R
      LEFT JOIN comercial.CampaniaJabaPrecioSancion X ON X.campania_jaba_recepcion_id=R.campania_jaba_recepcion_id
      WHERE R.campania_jaba_plan_id=@plan
      AND R.numero_jaba BETWEEN @desde AND @hasta ORDER BY R.numero_jaba FOR JSON PATH)) registros
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Consulta realizada.',@cCodigoRespuesta='RECEPCION_PAGINA_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='RECEPCION_PAGINA_ERROR',
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN 409 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudieron consultar las jabas.' END;
 END CATCH;
END;
GO
