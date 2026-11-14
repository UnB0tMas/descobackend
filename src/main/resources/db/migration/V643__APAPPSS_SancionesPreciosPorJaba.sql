-- DESCO APAPPSS. Sanciones comerciales por campaña y participante.
-- La sanción es una reducción por KG de peso NETO, no una deducción de peso.
-- V643 es posterior a V642: no modifica el historial de Flyway.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE TABLE comercial.CatalogoSancionVenta (
 sancion_venta_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_CatalogoSancionVenta PRIMARY KEY,
 codigo VARCHAR(40) NOT NULL CONSTRAINT UQ_CatalogoSancionVenta_Codigo UNIQUE,
 nombre NVARCHAR(120) NOT NULL,
 descripcion NVARCHAR(300) NULL,
 activo BIT NOT NULL CONSTRAINT DF_CatalogoSancionVenta_Activo DEFAULT(1),
 usuario_registro_id BIGINT NULL,
 fecha_registro DATETIME2(0) NOT NULL CONSTRAINT DF_CatalogoSancionVenta_Fecha DEFAULT(SYSUTCDATETIME()),
 usuario_modifica_id BIGINT NULL,
 fecha_modifica DATETIME2(0) NULL
);
GO
CREATE TABLE comercial.CampaniaSancionTarifa (
 campania_sancion_tarifa_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_CampaniaSancionTarifa PRIMARY KEY,
 campania_venta_id BIGINT NOT NULL REFERENCES comercial.CampaniaVenta(campania_venta_id),
 sancion_venta_id BIGINT NOT NULL REFERENCES comercial.CatalogoSancionVenta(sancion_venta_id),
 descuento_precio_kg DECIMAL(14,4) NOT NULL,
 activo BIT NOT NULL CONSTRAINT DF_CampaniaSancionTarifa_Activo DEFAULT(1),
 usuario_registro_id BIGINT NULL,
 fecha_registro DATETIME2(0) NOT NULL CONSTRAINT DF_CampaniaSancionTarifa_Fecha DEFAULT(SYSUTCDATETIME()),
 usuario_modifica_id BIGINT NULL,
 fecha_modifica DATETIME2(0) NULL,
 CONSTRAINT UQ_CampaniaSancionTarifa UNIQUE(campania_venta_id,sancion_venta_id),
 CONSTRAINT CK_CampaniaSancionTarifa_Descuento CHECK(descuento_precio_kg>0)
);
GO
CREATE TABLE comercial.CampaniaSocioSancion (
 campania_socio_sancion_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_CampaniaSocioSancion PRIMARY KEY,
 campania_sancion_tarifa_id BIGINT NOT NULL REFERENCES comercial.CampaniaSancionTarifa(campania_sancion_tarifa_id),
 participacion_campania_socio_id BIGINT NOT NULL REFERENCES comercial.ParticipacionCampaniaSocio(participacion_campania_socio_id),
 desde_numero INT NOT NULL,
 hasta_numero INT NULL,
 alcance VARCHAR(10) NOT NULL,
 comentario NVARCHAR(500) NOT NULL,
 activo BIT NOT NULL CONSTRAINT DF_CampaniaSocioSancion_Activo DEFAULT(1),
 usuario_registro_id BIGINT NULL,
 fecha_registro DATETIME2(0) NOT NULL CONSTRAINT DF_CampaniaSocioSancion_Fecha DEFAULT(SYSUTCDATETIME()),
 usuario_modifica_id BIGINT NULL,
 fecha_modifica DATETIME2(0) NULL,
 CONSTRAINT UQ_CampaniaSocioSancion_Socio UNIQUE(participacion_campania_socio_id),
 CONSTRAINT CK_CampaniaSocioSancion_Alcance CHECK(alcance IN('TODAS','CANTIDAD')),
 CONSTRAINT CK_CampaniaSocioSancion_Numero CHECK(desde_numero>=1 AND (hasta_numero IS NULL OR hasta_numero>=desde_numero))
);
GO
-- Snapshot por jaba. Los pesajes existentes NO se revalorizan al migrar.
CREATE TABLE comercial.CampaniaJabaPrecioSancion (
 campania_jaba_recepcion_id BIGINT NOT NULL CONSTRAINT PK_CampaniaJabaPrecioSancion PRIMARY KEY
   REFERENCES comercial.CampaniaJabaRecepcion(campania_jaba_recepcion_id),
 campania_socio_sancion_id BIGINT NULL REFERENCES comercial.CampaniaSocioSancion(campania_socio_sancion_id),
 precio_original_kg DECIMAL(14,4) NOT NULL,
 descuento_precio_kg DECIMAL(14,4) NOT NULL,
 precio_final_kg DECIMAL(14,4) NOT NULL,
 sancion_nombre NVARCHAR(120) NULL,
 fecha_precio DATETIME2(0) NOT NULL CONSTRAINT DF_CampaniaJabaPrecioSancion_Fecha DEFAULT(SYSUTCDATETIME()),
 CONSTRAINT CK_CampaniaJabaPrecioSancion_Precio CHECK(precio_original_kg>0 AND descuento_precio_kg>=0
     AND precio_final_kg>0 AND precio_original_kg-descuento_precio_kg=precio_final_kg)
);
GO
CREATE INDEX IX_CampaniaJabaPrecioSancion_Socio ON comercial.CampaniaJabaPrecioSancion(campania_socio_sancion_id);
GO
-- Misma transacción que registro/corrección. No genera ventas ni pagos automáticos.
CREATE OR ALTER TRIGGER comercial.TR_CampaniaJabaRecepcion_PrecioSancion
ON comercial.CampaniaJabaRecepcion AFTER INSERT, UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 -- Una modificación solo de tara, observación o versión no altera precios históricos.
 IF EXISTS(SELECT 1 FROM deleted) AND NOT UPDATE(campania_calibre_id) AND NOT UPDATE(peso_bruto_kg) RETURN;
 -- Una jaba que se corrige a vacía deja de tener precio de fruta.
 DELETE X FROM comercial.CampaniaJabaPrecioSancion X
 JOIN inserted I ON I.campania_jaba_recepcion_id=X.campania_jaba_recepcion_id
 WHERE I.peso_bruto_kg=0;
 IF NOT EXISTS(SELECT 1 FROM inserted WHERE peso_bruto_kg>0) RETURN;
 DECLARE @datos TABLE(jaba BIGINT PRIMARY KEY,sancion BIGINT NULL,precio DECIMAL(14,4),descuento DECIMAL(14,4),nombre NVARCHAR(120) NULL);
 INSERT @datos(jaba,sancion,precio,descuento,nombre)
 SELECT I.campania_jaba_recepcion_id, S.campania_socio_sancion_id,G.precio_kg,
        COALESCE(T.descuento_precio_kg,CONVERT(DECIMAL(14,4),0)), C.nombre
 FROM inserted I
 JOIN comercial.CampaniaCalibre G ON G.campania_calibre_id=I.campania_calibre_id
 JOIN comercial.CampaniaJabaPlan J ON J.campania_jaba_plan_id=I.campania_jaba_plan_id
 OUTER APPLY (
   SELECT TOP(1) A.campania_socio_sancion_id,A.campania_sancion_tarifa_id
   FROM comercial.CampaniaSocioSancion A
   WHERE A.participacion_campania_socio_id=J.participacion_campania_socio_id AND A.activo=1
      AND I.numero_jaba>=A.desde_numero AND (A.hasta_numero IS NULL OR I.numero_jaba<=A.hasta_numero)
   ORDER BY A.campania_socio_sancion_id DESC
 ) S
 LEFT JOIN comercial.CampaniaSancionTarifa T ON T.campania_sancion_tarifa_id=S.campania_sancion_tarifa_id
 LEFT JOIN comercial.CatalogoSancionVenta C ON C.sancion_venta_id=T.sancion_venta_id
 WHERE I.peso_bruto_kg>0;
 IF EXISTS(
   SELECT 1 FROM @datos D
   LEFT JOIN comercial.CampaniaJabaPrecioSancion X ON X.campania_jaba_recepcion_id=D.jaba
   JOIN inserted I ON I.campania_jaba_recepcion_id=D.jaba
   LEFT JOIN deleted O ON O.campania_jaba_recepcion_id=D.jaba
   WHERE D.precio<=D.descuento
     AND (X.campania_jaba_recepcion_id IS NULL OR I.campania_calibre_id<>O.campania_calibre_id)
 ) THROW 52080,N'El descuento de sanción debe ser menor al precio del calibre seleccionado.',1;
 UPDATE X SET campania_socio_sancion_id=D.sancion,precio_original_kg=D.precio,
    descuento_precio_kg=D.descuento,precio_final_kg=D.precio-D.descuento,
    sancion_nombre=D.nombre,fecha_precio=SYSUTCDATETIME()
 FROM comercial.CampaniaJabaPrecioSancion X JOIN @datos D ON D.jaba=X.campania_jaba_recepcion_id
 JOIN inserted I ON I.campania_jaba_recepcion_id=D.jaba
 JOIN deleted O ON O.campania_jaba_recepcion_id=D.jaba
 WHERE I.campania_calibre_id<>O.campania_calibre_id;
 INSERT comercial.CampaniaJabaPrecioSancion(campania_jaba_recepcion_id,campania_socio_sancion_id,precio_original_kg,descuento_precio_kg,precio_final_kg,sancion_nombre)
 SELECT D.jaba,D.sancion,D.precio,D.descuento,D.precio-D.descuento,D.nombre FROM @datos D
 WHERE NOT EXISTS(SELECT 1 FROM comercial.CampaniaJabaPrecioSancion X WHERE X.campania_jaba_recepcion_id=D.jaba);
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
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='CATALOGOS_LISTAR',
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
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='CATALOGOS_CREAR',
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
  DECLARE @codigo VARCHAR(40)=UPPER(NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.codigo')),'')),
   @nombre NVARCHAR(120)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.nombre')),N''),
   @descripcion NVARCHAR(300)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.descripcion')),N''),@id BIGINT;
  IF @codigo IS NULL OR @nombre IS NULL OR LEN(@codigo)>40 OR LEN(@nombre)>120
    OR @codigo LIKE '%[^A-Z0-9_]%' THROW 52088,N'Código y nombre válidos son obligatorios.',1;
  IF EXISTS(SELECT 1 FROM comercial.CatalogoSancionVenta WHERE codigo=@codigo)
    THROW 52089,N'El código de sanción ya existe.',1;
  INSERT comercial.CatalogoSancionVenta(codigo,nombre,descripcion,usuario_registro_id)
    VALUES(@codigo,@nombre,@descripcion,@usuario);
  SET @id=SCOPE_IDENTITY();
  SET @cDatos=(SELECT @id id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
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
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='CATALOGOS_EDITAR',
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
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='CATALOGOS_RETIRAR',
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
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='CAMPANIAS_VER',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'CAMPANIAS_VER')<>1
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
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='CAMPANIAS_EDITAR',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'CAMPANIAS_EDITAR')<>1
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
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='CAMPANIAS_EDITAR',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'CAMPANIAS_EDITAR')<>1
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
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='JABAS_LISTAR',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'JABAS_LISTAR')<>1
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
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='JABAS_CREAR',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'JABAS_CREAR')<>1
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
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='JABAS_CREAR',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'JABAS_CREAR')<>1
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

-- Lectura de precios por jaba sin modificar pesos ni confirmación de recepción.
CREATE OR ALTER PROCEDURE comercial.PA_CampaniaJabaRecepcion_Sel_Pagina
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
