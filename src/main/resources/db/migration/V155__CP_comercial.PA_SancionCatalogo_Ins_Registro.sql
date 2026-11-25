IF OBJECT_ID(N'[comercial].[PA_SancionCatalogo_Ins_Registro]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_SancionCatalogo_Ins_Registro];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_SancionCatalogo_Ins_Registro
' Descripción            : Registra la información de sancion catalogo.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_SancionCatalogo_Ins_Registro
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
