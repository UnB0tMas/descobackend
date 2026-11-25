IF OBJECT_ID(N'[comercial].[PA_CampaniaSancion_Upd_Lote]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_CampaniaSancion_Upd_Lote];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_CampaniaSancion_Upd_Lote
' Descripción            : Actualiza campania sancion para lote.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_CampaniaSancion_Upd_Lote
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo configurar las sanciones.',
  @cCodigoRespuesta='SANCION_LOTE_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
   @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
   @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
   @acceso BIT,@mensajeAcceso NVARCHAR(300),@lock INT,@recurso NVARCHAR(255),
   @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
   @hash VARBINARY(32),@anteriorHash VARBINARY(32),@respuesta NVARCHAR(MAX),@estado VARCHAR(30);
 BEGIN TRY
  IF ISJSON(@cJson)<>1 OR @camp IS NULL OR JSON_QUERY(@cJson,'$.datos.tarifas') IS NULL
   THROW 52081,N'La lista de sanciones es obligatoria.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='SANCIONES_CONFIGURAR',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 THROW 52082,N'Sin permiso para configurar sanciones.',1;
  IF @clave IS NULL THROW 52083,N'Falta la clave de idempotencia.',1;
  DECLARE @tarifas TABLE(sancionId BIGINT NULL,descuentoKg DECIMAL(14,4) NULL);
  INSERT @tarifas(sancionId,descuentoKg)
   SELECT TRY_CONVERT(BIGINT,JSON_VALUE(value,'$.sancionId')),
    TRY_CONVERT(DECIMAL(14,4),JSON_VALUE(value,'$.descuentoKg'))
   FROM OPENJSON(@cJson,'$.datos.tarifas');
  IF (SELECT COUNT_BIG(*) FROM @tarifas)>30 OR EXISTS(SELECT 1 FROM @tarifas WHERE sancionId IS NULL OR descuentoKg IS NULL OR descuentoKg<=0)
    OR EXISTS(SELECT 1 FROM @tarifas GROUP BY sancionId HAVING COUNT_BIG(*)>1)
     THROW 52092,N'Revise los motivos y descuentos de las sanciones.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'PA_CampaniaSancion_Upd_Lote|',
    COALESCE(JSON_QUERY(@cJson,'$.filtros'),N''),N'|',COALESCE(JSON_QUERY(@cJson,'$.datos'),N'')));
  BEGIN TRANSACTION;
  SELECT @uot=C.uot_id,@estado=C.estado_proceso
   FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK)
   WHERE C.campania_venta_id=@camp AND C.estado=1;
  IF @uot IS NULL THROW 52086,N'Campaña no disponible.',1;
  IF seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'SANCIONES_CONFIGURAR')<>1
    THROW 52082,N'Sin permiso en la UOT.',1;
  IF @estado NOT IN('PLANIFICACION','ACTIVA') THROW 52091,N'Esta campaña no permite cambios.',1;
  SET @recurso=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @lock=sys.sp_getapplock @Resource=@recurso,@LockMode='Exclusive',
       @LockOwner='Transaction',@LockTimeout=10000;
  IF @lock<0 THROW 52084,N'Otra operación está modificando esta campaña.',1;
  SELECT @anteriorHash=huella,@respuesta=respuesta
   FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK)
   WHERE usuario_id=@usuario AND clave=@clave;
  IF @anteriorHash IS NOT NULL
  BEGIN
   IF @anteriorHash<>@hash THROW 52085,N'Clave usada con datos diferentes.',1;
   SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Operación registrada previamente.',
       @cCodigoRespuesta='SANCION_LOTE_OK',@nHttpRespuesta=200;
   COMMIT TRANSACTION;RETURN;
  END;
  IF EXISTS(SELECT 1 FROM @tarifas R
    LEFT JOIN comercial.CatalogoSancionVenta S ON S.sancion_venta_id=R.sancionId AND S.activo=1
    WHERE S.sancion_venta_id IS NULL)
    THROW 52092,N'Una sanción ya no está activa.',1;
  IF EXISTS(SELECT 1 FROM @tarifas) AND NOT EXISTS(
    SELECT 1 FROM comercial.CampaniaCalibre G WHERE G.campania_venta_id=@camp AND G.activo=1)
    THROW 52093,N'Configure primero los calibres de la campaña.',1;
  IF EXISTS(SELECT 1 FROM @tarifas R JOIN comercial.CampaniaCalibre G
     ON G.campania_venta_id=@camp AND G.activo=1
     WHERE R.descuentoKg>=G.precio_kg)
     THROW 52094,N'El descuento debe ser menor al precio de todos los calibres.',1;
  IF EXISTS(SELECT 1 FROM comercial.CampaniaSancionTarifa T
    WHERE T.campania_venta_id=@camp
      AND (NOT EXISTS(SELECT 1 FROM @tarifas R WHERE R.sancionId=T.sancion_venta_id)
        OR EXISTS(SELECT 1 FROM @tarifas R WHERE R.sancionId=T.sancion_venta_id
          AND R.descuentoKg<>T.descuento_precio_kg))
      AND EXISTS(SELECT 1 FROM comercial.CampaniaSocioSancion A
         WHERE A.campania_sancion_tarifa_id=T.campania_sancion_tarifa_id AND A.activo=1))
    THROW 52095,N'Hay sanciones asignadas a socios que no pueden modificarse.',1;
  UPDATE T SET activo=0,usuario_modifica_id=@usuario,fecha_modifica=SYSUTCDATETIME()
   FROM comercial.CampaniaSancionTarifa T
   WHERE T.campania_venta_id=@camp AND T.activo=1 AND NOT EXISTS
    (SELECT 1 FROM @tarifas R WHERE R.sancionId=T.sancion_venta_id);
  UPDATE T SET activo=1,descuento_precio_kg=R.descuentoKg,
     usuario_modifica_id=@usuario,fecha_modifica=SYSUTCDATETIME()
   FROM comercial.CampaniaSancionTarifa T JOIN @tarifas R ON R.sancionId=T.sancion_venta_id
   WHERE T.campania_venta_id=@camp AND (T.activo=0 OR T.descuento_precio_kg<>R.descuentoKg);
  INSERT comercial.CampaniaSancionTarifa(campania_venta_id,sancion_venta_id,descuento_precio_kg,usuario_registro_id)
   SELECT @camp,R.sancionId,R.descuentoKg,@usuario FROM @tarifas R
   WHERE NOT EXISTS (SELECT 1 FROM comercial.CampaniaSancionTarifa T
      WHERE T.campania_venta_id=@camp AND T.sancion_venta_id=R.sancionId);
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
   VALUES(@camp,'CampaniaSancionTarifa',@camp,'CONFIGURAR_SANCIONES',
     (SELECT JSON_QUERY(@cJson,'$.datos.tarifas') tarifas FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario);
  SET @cDatos=(SELECT @camp campaniaId,(SELECT COUNT(*) FROM @tarifas) sanciones FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta)
     VALUES(@usuario,@clave,'CampaniaSancion_Upd_Lote',@hash,@cDatos);
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cMensaje=N'Sanciones de campaña guardadas.',@cCodigoRespuesta='SANCION_LOTE_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='SANCION_LOTE_ERROR',
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 52080 AND 52099 THEN 409 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 52080 AND 52099 THEN LEFT(ERROR_MESSAGE(),300)
    ELSE N'No se pudo configurar las sanciones.' END;
 END CATCH;
END;
GO
