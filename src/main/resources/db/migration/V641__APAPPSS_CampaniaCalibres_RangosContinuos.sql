-- DESCO/APAPPSS. Calibres por variedad: permitir acotar 120 g+ al registrar 180 g+.
-- V641 modifica solo el PA de edición de calibres; V629 conserva su checksum.
-- Los rangos existentes con pesajes se mantienen inmutables.
CREATE OR ALTER PROCEDURE comercial.PA_CampaniaCalibre_Upd_Lista
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudieron guardar los calibres.',
        @cCodigoRespuesta='CALIBRES_EDICION_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
   @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
   @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
   @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
   @acceso BIT,@mensajeAcceso NVARCHAR(300),@appLock INT,
   @hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX),
   @retirados INT=0,@agregados INT=0,@versionados INT=0;
 DECLARE @lineas TABLE(
   fila INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
   calibre_id BIGINT NULL,version INT NULL,variedad SMALLINT NULL,calibre VARCHAR(12) NULL,
   desde INT NULL,hasta INT NULL,precio DECIMAL(14,4) NULL
 );
 DECLARE @nuevosPrecios TABLE(calibre_id BIGINT NOT NULL,version INT NOT NULL,precio DECIMAL(14,4) NOT NULL);
 BEGIN TRY
  IF ISJSON(@cJson)<>1 OR @clave IS NULL OR @camp IS NULL OR JSON_QUERY(@cJson,'$.datos.calibres') IS NULL
    THROW 52101,N'La información de calibres está incompleta.',1;
  INSERT @lineas(calibre_id,version,variedad,calibre,desde,hasta,precio)
    SELECT calibreId,version,variedadPaltaId,calibre,gramosDesde,gramosHasta,precioKg
    FROM OPENJSON(@cJson,'$.datos.calibres')
    WITH(calibreId BIGINT '$.calibreId',version INT '$.version',variedadPaltaId SMALLINT '$.variedadPaltaId',
         calibre VARCHAR(12) '$.calibre',gramosDesde INT '$.gramosDesde',gramosHasta INT '$.gramosHasta',precioKg DECIMAL(14,4) '$.precioKg');
  IF (SELECT COUNT(1) FROM @lineas) NOT BETWEEN 1 AND 20
    THROW 52102,N'La campaña requiere entre 1 y 20 calibres.',1;
  IF EXISTS(SELECT 1 FROM @lineas WHERE variedad IS NULL OR calibre NOT IN('PRIMERA','SEGUNDA','DESCARTE')
    OR desde IS NULL OR desde<0 OR (hasta IS NOT NULL AND hasta<desde) OR precio IS NULL OR precio<=0
    OR (calibre_id IS NOT NULL AND (version IS NULL OR version<1)))
    THROW 52103,N'Revise variedad, calibre, rango en gramos y precio.',1;
  IF EXISTS(SELECT 1 FROM @lineas A JOIN @lineas B ON A.fila<B.fila AND A.variedad=B.variedad
    AND (A.calibre=B.calibre OR (A.desde<=COALESCE(B.hasta,2147483647) AND B.desde<=COALESCE(A.hasta,2147483647))))
    THROW 52104,N'Hay calibres duplicados o rangos superpuestos.',1;
  IF EXISTS(SELECT calibre_id FROM @lineas WHERE calibre_id IS NOT NULL GROUP BY calibre_id HAVING COUNT(1)>1)
    THROW 52105,N'Hay calibres repetidos en la lista.',1;
  SELECT @uot=C.uot_id FROM comercial.CampaniaVenta C WHERE C.campania_venta_id=@camp AND C.estado=1;
  IF @uot IS NULL THROW 52106,N'La campaña no existe.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='CAMPANIAS_EDITAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'CAMPANIAS_EDITAR')<>1
    THROW 52107,N'No tiene permiso para editar la campaña.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'CAMPANIA_CALIBRES_LISTA|',@camp,N'|',JSON_QUERY(@cJson,'$.datos.calibres')));
  BEGIN TRANSACTION;
  DECLARE @lockResource NVARCHAR(255)=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @appLock=sys.sp_getapplock @Resource=@lockResource,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @appLock<0 THROW 52108,N'La campaña está siendo modificada.',1;
  SELECT @prev=huella,@respuesta=respuesta FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK)
   WHERE usuario_id=@usuario AND clave=@clave;
  IF @prev IS NOT NULL
  BEGIN
    IF @prev<>@hash THROW 52109,N'La solicitud ya fue utilizada con otros datos.',1;
    SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Cambios guardados anteriormente.',
      @cCodigoRespuesta='CALIBRES_EDICION_OK',@nHttpRespuesta=200;
    COMMIT TRANSACTION;RETURN;
  END;
  IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK)
    WHERE C.campania_venta_id=@camp AND C.estado=1 AND C.estado_proceso IN('PLANIFICACION','ACTIVA'))
    THROW 52110,N'La campaña ya no permite cambios.',1;
  IF EXISTS(SELECT 1 FROM @lineas L LEFT JOIN prod.VariedadPalta V ON V.variedad_palta_id=L.variedad AND V.estado=1 WHERE V.variedad_palta_id IS NULL)
    THROW 52111,N'Una de las variedades no está disponible.',1;
  IF EXISTS(SELECT 1 FROM @lineas L WHERE L.calibre_id IS NOT NULL AND NOT EXISTS(
    SELECT 1 FROM comercial.CampaniaCalibre G WITH(UPDLOCK,HOLDLOCK)
    WHERE G.campania_calibre_id=L.calibre_id AND G.campania_venta_id=@camp AND G.activo=1
      AND G.variedad_palta_id=L.variedad AND G.calibre=L.calibre AND G.version=L.version))
    THROW 52112,N'Algún calibre ha cambiado. Actualice la campaña.',1;
  -- No reclasificar jabas ya pesadas al cambiar intervalos de una variedad.
  IF EXISTS(SELECT 1 FROM @lineas L JOIN comercial.CampaniaCalibre G WITH(UPDLOCK,HOLDLOCK)
      ON G.campania_calibre_id=L.calibre_id AND G.campania_venta_id=@camp AND G.activo=1
      WHERE (G.gramos_desde<>L.desde OR ISNULL(G.gramos_hasta,-1)<>ISNULL(L.hasta,-1))
      AND EXISTS(SELECT 1 FROM comercial.CampaniaJabaRecepcion R WHERE R.campania_calibre_id=G.campania_calibre_id))
    THROW 52118,N'No se puede modificar el rango de un calibre con jabas ya registradas.',1;
  IF EXISTS(SELECT 1 FROM comercial.CampaniaCalibre G WITH(UPDLOCK,HOLDLOCK)
    WHERE G.campania_venta_id=@camp AND G.activo=1
      AND NOT EXISTS(SELECT 1 FROM @lineas L WHERE L.calibre_id=G.campania_calibre_id)
      AND EXISTS(SELECT 1 FROM comercial.CampaniaJabaRecepcion R WHERE R.campania_calibre_id=G.campania_calibre_id))
    THROW 52113,N'No se puede quitar un calibre que tiene pesajes registrados.',1;
  IF EXISTS(SELECT 1 FROM @lineas L WHERE L.calibre_id IS NULL
     AND EXISTS(SELECT 1 FROM comercial.CampaniaCalibre G
       WHERE G.campania_venta_id=@camp AND G.variedad_palta_id=L.variedad AND G.calibre=L.calibre
       AND G.activo=0 AND EXISTS(SELECT 1 FROM comercial.CampaniaJabaRecepcion R WHERE R.campania_calibre_id=G.campania_calibre_id)))
    THROW 52114,N'No se puede reutilizar un calibre que conserva pesajes.',1;
  IF EXISTS(SELECT 1 FROM @lineas WHERE calibre_id IS NULL)
    AND seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'PRECIOS_CREAR')<>1
    THROW 52115,N'No tiene permiso para agregar calibres.',1;
  IF EXISTS(SELECT 1 FROM comercial.CampaniaCalibre G WHERE G.campania_venta_id=@camp AND G.activo=1
      AND NOT EXISTS(SELECT 1 FROM @lineas L WHERE L.calibre_id=G.campania_calibre_id))
    AND seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'PRECIOS_RETIRAR')<>1
    THROW 52116,N'No tiene permiso para quitar calibres.',1;
  IF EXISTS(SELECT 1 FROM @lineas L JOIN comercial.CampaniaCalibre G ON G.campania_calibre_id=L.calibre_id
      WHERE G.precio_kg<>L.precio OR G.gramos_desde<>L.desde OR ISNULL(G.gramos_hasta,-1)<>ISNULL(L.hasta,-1))
    AND seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'PRECIOS_EDITAR')<>1
    THROW 52117,N'No tiene permiso para cambiar precios.',1;

  UPDATE G SET activo=0 FROM comercial.CampaniaCalibre G
   WHERE G.campania_venta_id=@camp AND G.activo=1
     AND NOT EXISTS(SELECT 1 FROM @lineas L WHERE L.calibre_id=G.campania_calibre_id);
  SET @retirados=@@ROWCOUNT;

  UPDATE G SET activo=1,gramos_desde=L.desde,gramos_hasta=L.hasta,precio_kg=L.precio,version=G.version+1
    OUTPUT inserted.campania_calibre_id,inserted.version,inserted.precio_kg INTO @nuevosPrecios
    FROM comercial.CampaniaCalibre G JOIN @lineas L ON L.calibre_id IS NULL AND L.variedad=G.variedad_palta_id
      AND L.calibre=G.calibre WHERE G.campania_venta_id=@camp AND G.activo=0;
  SET @agregados=@@ROWCOUNT;

  INSERT comercial.CampaniaCalibre(campania_venta_id,variedad_palta_id,calibre,gramos_desde,gramos_hasta,precio_kg,usuario_registro_id,activo)
    OUTPUT inserted.campania_calibre_id,inserted.version,inserted.precio_kg INTO @nuevosPrecios
    SELECT @camp,L.variedad,L.calibre,L.desde,L.hasta,L.precio,@usuario,1
    FROM @lineas L WHERE L.calibre_id IS NULL AND NOT EXISTS(
      SELECT 1 FROM comercial.CampaniaCalibre G WHERE G.campania_venta_id=@camp AND G.variedad_palta_id=L.variedad AND G.calibre=L.calibre);
  SET @agregados=@agregados+@@ROWCOUNT;

  UPDATE G SET precio_kg=L.precio,gramos_desde=L.desde,gramos_hasta=L.hasta,version=G.version+1
    OUTPUT inserted.campania_calibre_id,inserted.version,inserted.precio_kg INTO @nuevosPrecios
    FROM comercial.CampaniaCalibre G JOIN @lineas L ON L.calibre_id=G.campania_calibre_id
    WHERE G.campania_venta_id=@camp AND G.activo=1 AND
      (G.precio_kg<>L.precio OR G.gramos_desde<>L.desde OR ISNULL(G.gramos_hasta,-1)<>ISNULL(L.hasta,-1));
  SET @versionados=@@ROWCOUNT;
  INSERT comercial.CampaniaCalibrePrecioVersion(campania_calibre_id,version,precio_kg,usuario_id)
    SELECT C.calibre_id,C.version,C.precio,@usuario FROM @nuevosPrecios C;
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
   VALUES(@camp,'CampaniaCalibre',@camp,'EDITAR_CALIBRES',
    (SELECT @retirados retirados,@agregados agregados,@versionados calibresActualizados FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario);
  SET @cDatos=(SELECT @camp campaniaId,
    (SELECT COUNT(1) FROM comercial.CampaniaCalibre WHERE campania_venta_id=@camp AND activo=1) calibres
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta)
    VALUES(@usuario,@clave,'CAMPANIA_CALIBRES_LISTA',@hash,@cDatos);
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cMensaje=N'Calibres actualizados.',@cCodigoRespuesta='CALIBRES_EDICION_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='CALIBRES_EDICION_ERROR',
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 52101 AND 52199 THEN 409 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 52101 AND 52199 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudieron guardar los calibres.' END;
 END CATCH;
END;
GO
