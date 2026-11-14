-- DESCO / APAPPSS: sanciones de venta (códigos automáticos, autorización granular y tarifas de campaña en lote).
-- V644 incremental. No reescribe migraciones ya aplicadas ni modifica pesajes o precios históricos.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
-- Submódulo lógico de Comercialización; visible_menu=0 porque la UI vive en Catálogos y Campañas.
DECLARE @moduloSancion INT;
SELECT @moduloSancion=modulo_id FROM seg.Modulo WHERE codigo='SANCIONES_VENTA';
IF @moduloSancion IS NULL
BEGIN
 INSERT seg.Modulo(modulo_padre_id,codigo,nombre,orden,estado,ruta,icono,visible_menu,es_grupo)
 SELECT M.modulo_id,'SANCIONES_VENTA',N'Sanciones de venta',70,1,NULL,'shield-alert',0,0
 FROM seg.Modulo M WHERE M.codigo='GRP_COMERCIAL';
 SELECT @moduloSancion=modulo_id FROM seg.Modulo WHERE codigo='SANCIONES_VENTA';
END;
IF @moduloSancion IS NULL THROW 52098,N'No existe el grupo de Gestión comercial.',1;
DECLARE @permisos TABLE(codigo VARCHAR(40) PRIMARY KEY,nombre NVARCHAR(100),accion VARCHAR(20));
INSERT @permisos(codigo,nombre,accion) VALUES
 ('SANCIONES_LISTAR',N'Consultar sanciones de venta','LISTAR'),
 ('SANCIONES_CREAR',N'Crear motivos de sanción','CREAR'),
 ('SANCIONES_EDITAR',N'Editar motivos de sanción','EDITAR'),
 ('SANCIONES_RETIRAR',N'Deshabilitar motivos de sanción','RETIRAR'),
 ('SANCIONES_CONFIGURAR',N'Configurar descuentos por campaña','EDITAR'),
 ('SANCIONES_APLICAR',N'Aplicar sanción al socio','EDITAR');
INSERT seg.Permiso(modulo_id,codigo,nombre,descripcion,estado,accion,es_sensible,requiere_motivo)
 SELECT @moduloSancion,X.codigo,X.nombre,N'Acción de sanciones comerciales APAPPSS.',1,X.accion,
  CASE WHEN X.codigo='SANCIONES_LISTAR' THEN 0 ELSE 1 END,
  0
 FROM @permisos X WHERE NOT EXISTS(SELECT 1 FROM seg.Permiso P WHERE P.codigo=X.codigo);
-- Requisitos de convenio APAPPSS aplican también a los nuevos permisos.
INSERT seg.ModuloEspecialPermiso(modulo_especial_id,permiso_id)
 SELECT E.modulo_especial_id,P.permiso_id
 FROM seg.ModuloEspecial E JOIN seg.Permiso P ON P.codigo LIKE 'SANCIONES[_]%'
 WHERE E.codigo='COMERCIALIZACION_ASOCIATIVA'
   AND NOT EXISTS(SELECT 1 FROM seg.ModuloEspecialPermiso MP
     WHERE MP.modulo_especial_id=E.modulo_especial_id AND MP.permiso_id=P.permiso_id);
-- Bootstrap del ADMINISTRADOR: permisos específicos más los existentes usados por el flujo.
DECLARE @administrador BIGINT=(SELECT TOP(1) rol_id FROM seg.Rol WHERE codigo='ADMINISTRADOR' AND estado=1);
IF @administrador IS NOT NULL
BEGIN
 INSERT seg.RolPermiso(rol_id,permiso_id,estado,fecha_asignacion,asignado_por_usuario_id,
     fecha_retiro,retirado_por_usuario_id,motivo_retiro)
 SELECT @administrador,P.permiso_id,1,SYSUTCDATETIME(),NULL,NULL,NULL,NULL
 FROM seg.Permiso P WHERE P.estado=1 AND (
   P.codigo LIKE 'SANCIONES[_]%' OR P.codigo IN
    ('CATALOGOS_LISTAR','CATALOGOS_CREAR','CATALOGOS_EDITAR','CATALOGOS_RETIRAR',
     'CAMPANIAS_LISTAR','CAMPANIAS_VER','CAMPANIAS_CREAR','CAMPANIAS_EDITAR',
     'JABAS_LISTAR','JABAS_CREAR','PRECIOS_CREAR','PRECIOS_EDITAR','PRECIOS_RETIRAR'))
 AND NOT EXISTS(SELECT 1 FROM seg.RolPermiso RP WHERE RP.rol_id=@administrador AND RP.permiso_id=P.permiso_id);
 UPDATE RP SET estado=1,fecha_retiro=NULL,retirado_por_usuario_id=NULL,motivo_retiro=NULL
 FROM seg.RolPermiso RP JOIN seg.Permiso P ON P.permiso_id=RP.permiso_id
 WHERE RP.rol_id=@administrador AND (P.codigo LIKE 'SANCIONES[_]%' OR P.codigo IN
    ('CATALOGOS_LISTAR','CATALOGOS_CREAR','CATALOGOS_EDITAR','CATALOGOS_RETIRAR',
     'CAMPANIAS_LISTAR','CAMPANIAS_VER','CAMPANIAS_CREAR','CAMPANIAS_EDITAR',
     'JABAS_LISTAR','JABAS_CREAR','PRECIOS_CREAR','PRECIOS_EDITAR','PRECIOS_RETIRAR')) AND RP.estado<>1;
END;
GO

CREATE OR ALTER PROCEDURE comercial.PA_SancionCatalogo_Sel_Listado
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo completar la operación.',
   @cCodigoRespuesta='PA_SancionCatalogo_Sel_Listado_ERROR',@nHttpRespuesta=400;
 DECLARE @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
  @acceso BIT,@mensajeAcceso NVARCHAR(300),@lock INT,
  @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX);
 BEGIN TRY
  IF ISJSON(@cJson)<>1 THROW 52081,N'Solicitud inválida.',1;
  -- Catálogo global: sin UOT; autorización mediante permisos de catálogo.
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='SANCIONES_LISTAR',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1
    THROW 52082,N'No tiene permisos para esta operación.',1;
  SET @cDatos=(SELECT JSON_QUERY((SELECT S.sancion_venta_id id,S.codigo,S.nombre,S.descripcion,S.activo,
      (SELECT COUNT_BIG(*) FROM comercial.CampaniaSancionTarifa T WHERE T.sancion_venta_id=S.sancion_venta_id) usos
    FROM comercial.CatalogoSancionVenta S ORDER BY S.nombre FOR JSON PATH)) items FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
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

CREATE OR ALTER PROCEDURE comercial.PA_SancionCatalogo_Ins_Registro
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo completar la operación.',
   @cCodigoRespuesta='PA_SancionCatalogo_Ins_Registro_ERROR',@nHttpRespuesta=400;
 DECLARE @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
  @acceso BIT,@mensajeAcceso NVARCHAR(300),@lock INT,
  @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX);
 BEGIN TRY
  IF ISJSON(@cJson)<>1 THROW 52081,N'Solicitud inválida.',1;
  -- Catálogo global: sin UOT; autorización mediante permisos de catálogo.
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='SANCIONES_CREAR',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1
    THROW 52082,N'No tiene permisos para esta operación.',1;
  IF @clave IS NULL THROW 52083,N'Falta la clave de solicitud.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'PA_SancionCatalogo_Ins_Registro|',COALESCE(JSON_QUERY(@cJson,'$.filtros'),N''),N'|',COALESCE(JSON_QUERY(@cJson,'$.datos'),N'')));
  BEGIN TRANSACTION;
  EXEC @lock=sys.sp_getapplock @Resource=N'DESCO:SANCION:CATALOGO',
    @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @lock<0 THROW 52084,N'Otra operación está modificando las sanciones.',1;
  SELECT @prev=huella,@respuesta=respuesta FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK)
    WHERE usuario_id=@usuario AND clave=@clave;
  IF @prev IS NOT NULL
  BEGIN
    IF @prev<>@hash THROW 52085,N'La clave de solicitud fue utilizada con otros datos.',1;
    SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Operación realizada previamente.',
       @cCodigoRespuesta='SANCION_OK',@nHttpRespuesta=200;
    COMMIT TRANSACTION;RETURN;
  END;
  DECLARE @codigo VARCHAR(40),
   @nombre NVARCHAR(120)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.nombre')),N''),
   @descripcion NVARCHAR(300)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.descripcion')),N''),@id BIGINT;
  IF @nombre IS NULL OR LEN(@nombre)>120 OR LEN(COALESCE(@descripcion,N''))>300
    THROW 52088,N'Indique un nombre válido para la sanción.',1;
  -- La clave temporal es única dentro de la transacción. El código definitivo usa la identidad real.
  INSERT comercial.CatalogoSancionVenta(codigo,nombre,descripcion,usuario_registro_id)
    VALUES(CONCAT('TMP-',REPLACE(CONVERT(VARCHAR(36),NEWID()),'-','')),@nombre,@descripcion,@usuario);
  SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
  SET @codigo=CONCAT('SAN-',CASE WHEN @id<1000000
    THEN RIGHT(CONCAT('000000',CONVERT(VARCHAR(20),@id)),6) ELSE CONVERT(VARCHAR(20),@id) END);
  UPDATE comercial.CatalogoSancionVenta SET codigo=@codigo WHERE sancion_venta_id=@id;
  SET @cDatos=(SELECT @id id,@codigo codigo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta)
    VALUES(@usuario,@clave,'SancionCatalogo_Ins_Registro',@hash,@cDatos);
  COMMIT TRANSACTION;
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

CREATE OR ALTER PROCEDURE comercial.PA_SancionCatalogo_Upd_Registro
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo completar la operación.',
   @cCodigoRespuesta='PA_SancionCatalogo_Upd_Registro_ERROR',@nHttpRespuesta=400;
 DECLARE @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
  @acceso BIT,@mensajeAcceso NVARCHAR(300),@lock INT,
  @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX);
 BEGIN TRY
  IF ISJSON(@cJson)<>1 THROW 52081,N'Solicitud inválida.',1;
  -- Catálogo global: sin UOT; autorización mediante permisos de catálogo.
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='SANCIONES_EDITAR',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1
    THROW 52082,N'No tiene permisos para esta operación.',1;
  IF @clave IS NULL THROW 52083,N'Falta la clave de solicitud.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'PA_SancionCatalogo_Upd_Registro|',COALESCE(JSON_QUERY(@cJson,'$.filtros'),N''),N'|',COALESCE(JSON_QUERY(@cJson,'$.datos'),N'')));
  BEGIN TRANSACTION;
  EXEC @lock=sys.sp_getapplock @Resource=N'DESCO:SANCION:CATALOGO',
    @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @lock<0 THROW 52084,N'Otra operación está modificando las sanciones.',1;
  SELECT @prev=huella,@respuesta=respuesta FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK)
    WHERE usuario_id=@usuario AND clave=@clave;
  IF @prev IS NOT NULL
  BEGIN
    IF @prev<>@hash THROW 52085,N'La clave de solicitud fue utilizada con otros datos.',1;
    SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Operación realizada previamente.',
       @cCodigoRespuesta='SANCION_OK',@nHttpRespuesta=200;
    COMMIT TRANSACTION;RETURN;
  END;
  DECLARE @id BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.id')),
   @nombre NVARCHAR(120)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.nombre')),N''),
   @descripcion NVARCHAR(300)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.descripcion')),N'');
  IF @nombre IS NULL OR LEN(@nombre)>120 THROW 52088,N'El nombre es obligatorio.',1;
  UPDATE comercial.CatalogoSancionVenta SET nombre=@nombre,descripcion=@descripcion,
    usuario_modifica_id=@usuario,fecha_modifica=SYSUTCDATETIME() WHERE sancion_venta_id=@id AND activo=1;
  IF @@ROWCOUNT<>1 THROW 52090,N'La sanción no está disponible.',1;
  SET @cDatos=(SELECT @id id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta)
    VALUES(@usuario,@clave,'SancionCatalogo_Upd_Registro',@hash,@cDatos);
  COMMIT TRANSACTION;
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

CREATE OR ALTER PROCEDURE comercial.PA_SancionCatalogo_Upd_Deshabilitar
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo completar la operación.',
   @cCodigoRespuesta='PA_SancionCatalogo_Upd_Deshabilitar_ERROR',@nHttpRespuesta=400;
 DECLARE @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
  @acceso BIT,@mensajeAcceso NVARCHAR(300),@lock INT,
  @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX);
 BEGIN TRY
  IF ISJSON(@cJson)<>1 THROW 52081,N'Solicitud inválida.',1;
  -- Catálogo global: sin UOT; autorización mediante permisos de catálogo.
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='SANCIONES_RETIRAR',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1
    THROW 52082,N'No tiene permisos para esta operación.',1;
  IF @clave IS NULL THROW 52083,N'Falta la clave de solicitud.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'PA_SancionCatalogo_Upd_Deshabilitar|',COALESCE(JSON_QUERY(@cJson,'$.filtros'),N''),N'|',COALESCE(JSON_QUERY(@cJson,'$.datos'),N'')));
  BEGIN TRANSACTION;
  EXEC @lock=sys.sp_getapplock @Resource=N'DESCO:SANCION:CATALOGO',
    @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @lock<0 THROW 52084,N'Otra operación está modificando las sanciones.',1;
  SELECT @prev=huella,@respuesta=respuesta FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK)
    WHERE usuario_id=@usuario AND clave=@clave;
  IF @prev IS NOT NULL
  BEGIN
    IF @prev<>@hash THROW 52085,N'La clave de solicitud fue utilizada con otros datos.',1;
    SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Operación realizada previamente.',
       @cCodigoRespuesta='SANCION_OK',@nHttpRespuesta=200;
    COMMIT TRANSACTION;RETURN;
  END;
  DECLARE @id BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.id'));
  UPDATE comercial.CatalogoSancionVenta SET activo=0,usuario_modifica_id=@usuario,
    fecha_modifica=SYSUTCDATETIME() WHERE sancion_venta_id=@id AND activo=1;
  IF @@ROWCOUNT<>1 THROW 52090,N'La sanción no está disponible.',1;
  SET @cDatos=(SELECT @id id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta)
    VALUES(@usuario,@clave,'SancionCatalogo_Upd_Deshabilitar',@hash,@cDatos);
  COMMIT TRANSACTION;
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

CREATE OR ALTER PROCEDURE comercial.PA_CampaniaSancion_Sel_Listado
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

CREATE OR ALTER PROCEDURE comercial.PA_CampaniaSancion_Upd_Configurar
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo completar la operación.',
   @cCodigoRespuesta='PA_CampaniaSancion_Upd_Configurar_ERROR',@nHttpRespuesta=400;
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
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='SANCIONES_CONFIGURAR',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'SANCIONES_CONFIGURAR')<>1
    THROW 52082,N'No tiene permisos para esta operación.',1;
  IF @clave IS NULL THROW 52083,N'Falta la clave de solicitud.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'PA_CampaniaSancion_Upd_Configurar|',COALESCE(JSON_QUERY(@cJson,'$.filtros'),N''),N'|',COALESCE(JSON_QUERY(@cJson,'$.datos'),N'')));
  BEGIN TRANSACTION;
  DECLARE @recursoBloqueo NVARCHAR(255)=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @lock=sys.sp_getapplock @Resource=@recursoBloqueo,
    @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @lock<0 THROW 52084,N'Otra operación está modificando las sanciones.',1;
  SELECT @prev=huella,@respuesta=respuesta FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK)
    WHERE usuario_id=@usuario AND clave=@clave;
  IF @prev IS NOT NULL
  BEGIN
    IF @prev<>@hash THROW 52085,N'La clave de solicitud fue utilizada con otros datos.',1;
    SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Operación realizada previamente.',
       @cCodigoRespuesta='SANCION_OK',@nHttpRespuesta=200;
    COMMIT TRANSACTION;RETURN;
  END;
  DECLARE @sancion BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.sancionId')),
    @descuento DECIMAL(14,4)=TRY_CONVERT(DECIMAL(14,4),JSON_VALUE(@cJson,'$.datos.descuentoKg')),
    @tarifa BIGINT;
  IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp
     AND estado_proceso IN('PLANIFICACION','ACTIVA')) THROW 52091,N'La campaña no permite editar sanciones.',1;
  IF @descuento IS NULL OR @descuento<=0 OR NOT EXISTS(SELECT 1 FROM comercial.CatalogoSancionVenta WHERE sancion_venta_id=@sancion AND activo=1)
    THROW 52092,N'Seleccione una sanción activa y un descuento positivo por kilogramo.',1;
  IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaCalibre WHERE campania_venta_id=@camp AND activo=1)
    THROW 52093,N'Configure primero los precios de los calibres.',1;
  IF EXISTS(SELECT 1 FROM comercial.CampaniaCalibre WHERE campania_venta_id=@camp AND activo=1 AND precio_kg<=@descuento)
    THROW 52094,N'El descuento debe ser menor al precio de todos los calibres de la campaña.',1;
  SELECT @tarifa=campania_sancion_tarifa_id FROM comercial.CampaniaSancionTarifa WITH(UPDLOCK,HOLDLOCK)
    WHERE campania_venta_id=@camp AND sancion_venta_id=@sancion;
  IF @tarifa IS NOT NULL AND EXISTS(SELECT 1 FROM comercial.CampaniaSocioSancion WHERE campania_sancion_tarifa_id=@tarifa AND activo=1)
    THROW 52095,N'No puede cambiar la sanción: ya está asignada a socios.',1;
  IF @tarifa IS NULL
  BEGIN
    INSERT comercial.CampaniaSancionTarifa(campania_venta_id,sancion_venta_id,descuento_precio_kg,usuario_registro_id)
      VALUES(@camp,@sancion,@descuento,@usuario);
    SET @tarifa=SCOPE_IDENTITY();
  END
  ELSE UPDATE comercial.CampaniaSancionTarifa SET descuento_precio_kg=@descuento,activo=1,
    usuario_modifica_id=@usuario,fecha_modifica=SYSUTCDATETIME() WHERE campania_sancion_tarifa_id=@tarifa;
  SET @cDatos=(SELECT @tarifa tarifaId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta)
    VALUES(@usuario,@clave,'CampaniaSancion_Upd_Configurar',@hash,@cDatos);
  COMMIT TRANSACTION;
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

CREATE OR ALTER PROCEDURE comercial.PA_CampaniaSancion_Upd_Deshabilitar
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo completar la operación.',
   @cCodigoRespuesta='PA_CampaniaSancion_Upd_Deshabilitar_ERROR',@nHttpRespuesta=400;
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
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='SANCIONES_CONFIGURAR',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'SANCIONES_CONFIGURAR')<>1
    THROW 52082,N'No tiene permisos para esta operación.',1;
  IF @clave IS NULL THROW 52083,N'Falta la clave de solicitud.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'PA_CampaniaSancion_Upd_Deshabilitar|',COALESCE(JSON_QUERY(@cJson,'$.filtros'),N''),N'|',COALESCE(JSON_QUERY(@cJson,'$.datos'),N'')));
  BEGIN TRANSACTION;
  DECLARE @recursoBloqueo NVARCHAR(255)=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @lock=sys.sp_getapplock @Resource=@recursoBloqueo,
    @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @lock<0 THROW 52084,N'Otra operación está modificando las sanciones.',1;
  SELECT @prev=huella,@respuesta=respuesta FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK)
    WHERE usuario_id=@usuario AND clave=@clave;
  IF @prev IS NOT NULL
  BEGIN
    IF @prev<>@hash THROW 52085,N'La clave de solicitud fue utilizada con otros datos.',1;
    SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Operación realizada previamente.',
       @cCodigoRespuesta='SANCION_OK',@nHttpRespuesta=200;
    COMMIT TRANSACTION;RETURN;
  END;
  DECLARE @tarifa BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.tarifaId'));
  IF EXISTS(SELECT 1 FROM comercial.CampaniaSocioSancion WHERE campania_sancion_tarifa_id=@tarifa AND activo=1)
    THROW 52095,N'Esta sanción ya está asignada a socios.',1;
  UPDATE comercial.CampaniaSancionTarifa SET activo=0,usuario_modifica_id=@usuario,
    fecha_modifica=SYSUTCDATETIME() WHERE campania_sancion_tarifa_id=@tarifa AND campania_venta_id=@camp AND activo=1;
  IF @@ROWCOUNT<>1 THROW 52090,N'La sanción no está activa en esta campaña.',1;
  SET @cDatos=(SELECT @tarifa tarifaId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta)
    VALUES(@usuario,@clave,'CampaniaSancion_Upd_Deshabilitar',@hash,@cDatos);
  COMMIT TRANSACTION;
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

CREATE OR ALTER PROCEDURE comercial.PA_CampaniaSocioSancion_Sel_Detalle
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo completar la operación.',
   @cCodigoRespuesta='PA_CampaniaSocioSancion_Sel_Detalle_ERROR',@nHttpRespuesta=400;
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
  IF NOT EXISTS(SELECT 1 FROM comercial.ParticipacionCampaniaSocio WHERE participacion_campania_socio_id=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.participacionId')) AND campania_venta_id=@camp AND estado=1 AND estado_participacion='ACTIVO') THROW 52087,N'Socio fuera de la campaña.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='SANCIONES_LISTAR',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'SANCIONES_LISTAR')<>1
    THROW 52082,N'No tiene permisos para esta operación.',1;
  DECLARE @part BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.participacionId'));
  SET @cDatos=(SELECT
    JSON_QUERY((SELECT S.campania_socio_sancion_id asignacionId,S.campania_sancion_tarifa_id tarifaId,
      C.nombre,S.alcance,S.desde_numero desdeNumero,S.hasta_numero hastaNumero,S.comentario,
      T.descuento_precio_kg descuentoKg,S.activo
      FROM comercial.CampaniaSocioSancion S JOIN comercial.CampaniaSancionTarifa T ON T.campania_sancion_tarifa_id=S.campania_sancion_tarifa_id
      JOIN comercial.CatalogoSancionVenta C ON C.sancion_venta_id=T.sancion_venta_id
      WHERE S.participacion_campania_socio_id=@part FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) asignacion,
    (SELECT COUNT_BIG(*) FROM comercial.CampaniaJabaRecepcion R JOIN comercial.CampaniaJabaPlan J ON J.campania_jaba_plan_id=R.campania_jaba_plan_id
      WHERE J.participacion_campania_socio_id=@part) jabasRegistradas,
    (SELECT COALESCE(SUM(R.peso_neto_kg*X.descuento_precio_kg),0) FROM comercial.CampaniaJabaRecepcion R
      JOIN comercial.CampaniaJabaPrecioSancion X ON X.campania_jaba_recepcion_id=R.campania_jaba_recepcion_id
      JOIN comercial.CampaniaJabaPlan J ON J.campania_jaba_plan_id=R.campania_jaba_plan_id
      WHERE J.participacion_campania_socio_id=@part) totalDescuentoSoles
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
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

CREATE OR ALTER PROCEDURE comercial.PA_CampaniaSocioSancion_Upd_Asignar
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo completar la operación.',
   @cCodigoRespuesta='PA_CampaniaSocioSancion_Upd_Asignar_ERROR',@nHttpRespuesta=400;
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
  IF NOT EXISTS(SELECT 1 FROM comercial.ParticipacionCampaniaSocio WHERE participacion_campania_socio_id=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.participacionId')) AND campania_venta_id=@camp AND estado=1 AND estado_participacion='ACTIVO') THROW 52087,N'Socio fuera de la campaña.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='SANCIONES_APLICAR',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'SANCIONES_APLICAR')<>1
    THROW 52082,N'No tiene permisos para esta operación.',1;
  IF @clave IS NULL THROW 52083,N'Falta la clave de solicitud.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'PA_CampaniaSocioSancion_Upd_Asignar|',COALESCE(JSON_QUERY(@cJson,'$.filtros'),N''),N'|',COALESCE(JSON_QUERY(@cJson,'$.datos'),N'')));
  BEGIN TRANSACTION;
  DECLARE @recursoBloqueo NVARCHAR(255)=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @lock=sys.sp_getapplock @Resource=@recursoBloqueo,
    @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @lock<0 THROW 52084,N'Otra operación está modificando las sanciones.',1;
  SELECT @prev=huella,@respuesta=respuesta FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK)
    WHERE usuario_id=@usuario AND clave=@clave;
  IF @prev IS NOT NULL
  BEGIN
    IF @prev<>@hash THROW 52085,N'La clave de solicitud fue utilizada con otros datos.',1;
    SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Operación realizada previamente.',
       @cCodigoRespuesta='SANCION_OK',@nHttpRespuesta=200;
    COMMIT TRANSACTION;RETURN;
  END;
  DECLARE @part BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.participacionId')),
   @tarifa BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.tarifaId')),
   @alcance VARCHAR(10)=JSON_VALUE(@cJson,'$.datos.alcance'),
   @cantidad INT=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.cantidad')),
   @comentario NVARCHAR(500)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.comentario')),N''),
   @cantidadPlan INT,@numeroInicio INT,@numeroFin INT,@socioSancion BIGINT;
  IF @comentario IS NULL OR LEN(@comentario)<10 OR @alcance IS NULL OR @alcance NOT IN('TODAS','CANTIDAD')
    THROW 52096,N'Indique el motivo de la sanción (mínimo 10 caracteres) y su alcance.',1;
  IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp AND estado_proceso IN('ACTIVA','PLANIFICACION'))
    THROW 52091,N'La campaña está cerrada.',1;
  IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaSancionTarifa T JOIN comercial.CatalogoSancionVenta C
     ON C.sancion_venta_id=T.sancion_venta_id WHERE T.campania_sancion_tarifa_id=@tarifa AND T.campania_venta_id=@camp AND T.activo=1 AND C.activo=1)
    THROW 52092,N'La sanción no está habilitada en esta campaña.',1;
  SELECT @cantidadPlan=J.cantidad FROM comercial.CampaniaJabaPlan J WITH(UPDLOCK,HOLDLOCK)
   WHERE J.participacion_campania_socio_id=@part AND J.activo=1 AND J.recepcion_confirmada=0;
  IF @cantidadPlan IS NULL THROW 52097,N'El socio ya confirmó su recepción o no tiene jabas.',1;
  SELECT @numeroInicio=COALESCE(MAX(R.numero_jaba),0)+1 FROM comercial.CampaniaJabaRecepcion R
    JOIN comercial.CampaniaJabaPlan J ON J.campania_jaba_plan_id=R.campania_jaba_plan_id
    WHERE J.participacion_campania_socio_id=@part;
  IF @numeroInicio>@cantidadPlan THROW 52097,N'No quedan jabas por registrar.',1;
  IF @alcance='CANTIDAD' AND (@cantidad IS NULL OR @cantidad<1 OR @cantidad>@cantidadPlan-@numeroInicio+1)
    THROW 52098,N'La cantidad supera las jabas pendientes del socio.',1;
  -- 'TODAS' cubre las jabas asignadas AHORA, no futuras ampliaciones del cupo.
  SET @numeroFin=CASE WHEN @alcance='TODAS' THEN @cantidadPlan ELSE @numeroInicio+@cantidad-1 END;
  SELECT @socioSancion=campania_socio_sancion_id FROM comercial.CampaniaSocioSancion WITH(UPDLOCK,HOLDLOCK)
   WHERE participacion_campania_socio_id=@part;
  IF @socioSancion IS NOT NULL AND EXISTS(SELECT 1 FROM comercial.CampaniaJabaPrecioSancion WHERE campania_socio_sancion_id=@socioSancion)
    THROW 52099,N'La sanción ya afectó pesajes: el histórico es inmutable.',1;
  IF @socioSancion IS NULL
  BEGIN
    INSERT comercial.CampaniaSocioSancion(campania_sancion_tarifa_id,participacion_campania_socio_id,desde_numero,hasta_numero,alcance,comentario,usuario_registro_id)
      VALUES(@tarifa,@part,@numeroInicio,@numeroFin,@alcance,@comentario,@usuario);
    SET @socioSancion=SCOPE_IDENTITY();
  END
  ELSE UPDATE comercial.CampaniaSocioSancion SET campania_sancion_tarifa_id=@tarifa,desde_numero=@numeroInicio,
    hasta_numero=@numeroFin,alcance=@alcance,comentario=@comentario,activo=1,
    usuario_modifica_id=@usuario,fecha_modifica=SYSUTCDATETIME() WHERE campania_socio_sancion_id=@socioSancion;
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
    VALUES(@camp,'CampaniaSocioSancion',@socioSancion,'ASIGNAR_SANCION',
      (SELECT @part participacionId,@tarifa tarifaId,@numeroInicio desdeNumero,@numeroFin hastaNumero,@alcance alcance,@comentario comentario FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario);
  SET @cDatos=(SELECT @socioSancion asignacionId,@numeroInicio desdeNumero,@numeroFin hastaNumero FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta)
    VALUES(@usuario,@clave,'CampaniaSocioSancion_Upd_Asignar',@hash,@cDatos);
  COMMIT TRANSACTION;
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

CREATE OR ALTER PROCEDURE comercial.PA_CampaniaSocioSancion_Upd_Retirar
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo completar la operación.',
   @cCodigoRespuesta='PA_CampaniaSocioSancion_Upd_Retirar_ERROR',@nHttpRespuesta=400;
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
  IF NOT EXISTS(SELECT 1 FROM comercial.ParticipacionCampaniaSocio WHERE participacion_campania_socio_id=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.participacionId')) AND campania_venta_id=@camp AND estado=1 AND estado_participacion='ACTIVO') THROW 52087,N'Socio fuera de la campaña.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='SANCIONES_APLICAR',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'SANCIONES_APLICAR')<>1
    THROW 52082,N'No tiene permisos para esta operación.',1;
  IF @clave IS NULL THROW 52083,N'Falta la clave de solicitud.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'PA_CampaniaSocioSancion_Upd_Retirar|',COALESCE(JSON_QUERY(@cJson,'$.filtros'),N''),N'|',COALESCE(JSON_QUERY(@cJson,'$.datos'),N'')));
  BEGIN TRANSACTION;
  DECLARE @recursoBloqueo NVARCHAR(255)=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @lock=sys.sp_getapplock @Resource=@recursoBloqueo,
    @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @lock<0 THROW 52084,N'Otra operación está modificando las sanciones.',1;
  SELECT @prev=huella,@respuesta=respuesta FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK)
    WHERE usuario_id=@usuario AND clave=@clave;
  IF @prev IS NOT NULL
  BEGIN
    IF @prev<>@hash THROW 52085,N'La clave de solicitud fue utilizada con otros datos.',1;
    SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Operación realizada previamente.',
       @cCodigoRespuesta='SANCION_OK',@nHttpRespuesta=200;
    COMMIT TRANSACTION;RETURN;
  END;
  DECLARE @part BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.participacionId')),
   @motivo NVARCHAR(500)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.motivo')),N''),@id BIGINT;
  IF @motivo IS NULL OR LEN(@motivo)<10 THROW 52096,N'Indique el motivo de retiro de la sanción.',1;
  SELECT @id=campania_socio_sancion_id FROM comercial.CampaniaSocioSancion WITH(UPDLOCK,HOLDLOCK)
    WHERE participacion_campania_socio_id=@part AND activo=1;
  IF @id IS NULL THROW 52090,N'No hay sanción activa para retirar.',1;
  IF EXISTS(SELECT 1 FROM comercial.CampaniaJabaPrecioSancion WHERE campania_socio_sancion_id=@id)
    THROW 52099,N'La sanción ya afectó pesajes y no puede retirarse.',1;
  UPDATE comercial.CampaniaSocioSancion SET activo=0,usuario_modifica_id=@usuario,
    fecha_modifica=SYSUTCDATETIME() WHERE campania_socio_sancion_id=@id;
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
   VALUES(@camp,'CampaniaSocioSancion',@id,'RETIRAR_SANCION',
      (SELECT @part participacionId,@motivo motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario);
  SET @cDatos=(SELECT @id asignacionId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta)
    VALUES(@usuario,@clave,'CampaniaSocioSancion_Upd_Retirar',@hash,@cDatos);
  COMMIT TRANSACTION;
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

-- Configuración atómica de tarifas de la campaña: sincroniza solo las tarifas de sanción.
CREATE OR ALTER PROCEDURE comercial.PA_CampaniaSancion_Upd_Lote
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
