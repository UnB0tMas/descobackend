IF OBJECT_ID(N'[comercial].[PA_CampaniaSancion_Sel_Listado]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_CampaniaSancion_Sel_Listado];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_CampaniaSancion_Sel_Listado
' Descripción            : Consulta información de Campania Sancion (listado).
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_CampaniaSancion_Sel_Listado
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo completar la operación.',
   @cCodigoRespuesta='PA_CampaniaSancion_Sel_Listado_ERROR',@nHttpRespuesta=400;
 DECLARE @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
  @acceso BIT,@mensajeAcceso NVARCHAR(300),@lock INT,
  @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX);
 BEGIN TRY
  IF ISJSON(@cJson)<>1 THROW 52081,N'Solicitud inválida.',1;
  SELECT @uot=uot_id FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp AND estado=1;
  IF @uot IS NULL THROW 52086,N'La campaña no existe.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='SANCIONES_LISTAR',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'SANCIONES_LISTAR')<>1
    THROW 52082,N'No tiene permisos para esta operación.',1;
  SET @cDatos=(SELECT JSON_QUERY((SELECT T.campania_sancion_tarifa_id tarifaId,
      T.sancion_venta_id sancionId,S.codigo,S.nombre,T.descuento_precio_kg descuentoKg,T.activo,
      (SELECT COUNT_BIG(*) FROM comercial.CampaniaSocioSancion P WHERE P.campania_sancion_tarifa_id=T.campania_sancion_tarifa_id AND P.activo=1) socios
    FROM comercial.CampaniaSancionTarifa T JOIN comercial.CatalogoSancionVenta S ON S.sancion_venta_id=T.sancion_venta_id
    WHERE T.campania_venta_id=@camp ORDER BY S.nombre FOR JSON PATH)) items,
    JSON_QUERY((SELECT C.sancion_venta_id id,C.nombre FROM comercial.CatalogoSancionVenta C
      WHERE C.activo=1 ORDER BY C.nombre FOR JSON PATH)) disponibles FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Operación completada.',@cCodigoRespuesta='SANCION_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='SANCION_ERROR',
    @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 52080 AND 52099 THEN 409 ELSE 500 END,
    @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 52080 AND 52099 THEN LEFT(ERROR_MESSAGE(),300)
       ELSE N'No se pudo completar la operación de sanciones.' END;
 END CATCH;
END;
GO
