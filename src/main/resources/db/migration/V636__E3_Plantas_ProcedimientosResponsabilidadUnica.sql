CREATE OR ALTER PROCEDURE prod.PA_E3_Sel_ValidarContexto
 @cJson NVARCHAR(MAX), @cPermiso VARCHAR(60), @nUsuario BIGINT OUTPUT,
 @nPlanta BIGINT OUTPUT, @nEpisodio BIGINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
 @conv BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.convenioId')),
 @predio BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.predioId')),
 @parcelaContexto BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.parcelaCultivoId')),
 @sesion BIGINT,@disp BIGINT,@emp BIGINT,@modulo INT,@corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,
 @ip VARCHAR(64),@endpoint NVARCHAR(250),@auth BIT,@authMensaje NVARCHAR(300),@fecha DATE=CONVERT(DATE,SYSUTCDATETIME());
 SELECT @nPlanta=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.plantaId')),
        @nEpisodio=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.episodioId'));
 IF ISJSON(@cJson)<>1 OR @uot IS NULL OR @conv IS NULL OR @predio IS NULL OR @nPlanta IS NULL
    THROW 51210,N'El contexto de la planta no es válido.',1;
 EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,@cPermiso,
   @nUsuario OUTPUT,@sesion OUTPUT,@disp OUTPUT,@emp OUTPUT,@modulo OUTPUT,
   @corr OUTPUT,@sol OUTPUT,@ip OUTPUT,@endpoint OUTPUT,@auth OUTPUT,@authMensaje OUTPUT;
 IF ISNULL(@auth,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@nUsuario,@uot,@cPermiso)<>1
    THROW 51211,N'No tiene permisos para realizar esta operación.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.PredioAmbito A
  JOIN org.ConvenioUOTOrganizacion C ON C.convenio_uot_organizacion_id=A.convenio_uot_organizacion_id
  JOIN org.ConvenioModuloEspecial M ON M.convenio_uot_organizacion_id=C.convenio_uot_organizacion_id AND M.estado=1
  JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=M.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
  JOIN prod.Predio PD ON PD.predio_id=A.predio_id AND PD.estado=1
  WHERE A.predio_id=@predio AND A.uot_id=@uot AND A.convenio_uot_organizacion_id=@conv AND A.estado=1
   AND C.uot_id=@uot AND C.estado=1 AND (C.fecha_inicio IS NULL OR C.fecha_inicio<=@fecha)
   AND (C.fecha_fin IS NULL OR C.fecha_fin>=@fecha)
   AND EXISTS(SELECT 1 FROM prod.PredioTitularidad T
     JOIN org.Socio S ON S.socio_id=T.socio_id
     JOIN org.SocioAsociacion SA ON SA.socio_id=T.socio_id AND SA.asociacion_id=C.empresa_id
       AND SA.estado=1 AND SA.fecha_desde<=@fecha AND (SA.fecha_hasta IS NULL OR SA.fecha_hasta>=@fecha)
     WHERE T.predio_id=@predio AND T.estado=1 AND T.fecha_hasta IS NULL AND S.estado=1))
    THROW 51212,N'El predio no pertenece al convenio autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 P
    WHERE P.planta_id=@nPlanta AND P.predio_id=@predio AND P.uot_id=@uot AND P.convenio_id=@conv)
    THROW 51213,N'La planta no pertenece al contexto seleccionado.',1;
 IF @parcelaContexto IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 P
   WHERE P.planta_id=@nPlanta AND P.parcela_cultivo_id=@parcelaContexto)
    THROW 51218,N'Esta planta no pertenece a la parcela seleccionada.',1;
 IF @nEpisodio IS NOT NULL AND NOT EXISTS(SELECT 1 FROM sanidad.EpisodioPlantaE3 E
    WHERE E.episodio_id=@nEpisodio AND E.planta_id=@nPlanta)
    THROW 51214,N'La enfermedad no pertenece a esta planta.',1;
END;
GO

CREATE OR ALTER PROCEDURE prod.PA_E3_Planta_Upd_Eliminar
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No fue posible completar la operación.',@cCodigoRespuesta='E3_ERROR',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@planta BIGINT,@episodio BIGINT,@now DATETIME2(0)=SYSUTCDATETIME();
 BEGIN TRY
 EXEC prod.PA_E3_Sel_ValidarContexto @cJson,'APAPPSS_PREDIOS_EDITAR',@usuario OUTPUT,@planta OUTPUT,@episodio OUTPUT;
 DECLARE @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
   @hash VARBINARY(32),@anterior VARBINARY(32),@previo NVARCHAR(MAX);
 IF @clave IS NULL THROW 51216,N'Falta la clave de la operación.',1;
 SET @hash=HASHBYTES('SHA2_256',CONCAT('PA_E3_Planta_Upd_Eliminar',N'|',JSON_QUERY(@cJson,'$.filtros'),N'|',JSON_QUERY(@cJson,'$.datos')));
 BEGIN TRANSACTION;
 SELECT @anterior=hash_peticion,@previo=respuesta FROM prod.PlantaSolicitudE3 WITH(UPDLOCK,HOLDLOCK)
 WHERE usuario_id=@usuario AND accion='E3_Planta_Upd_Eliminar' AND clave=@clave;
 IF @anterior IS NOT NULL
 BEGIN
  IF @anterior<>@hash THROW 51217,N'La operación ya fue utilizada con otros datos.',1;
  SELECT @cDatos=@previo,@bResultado=1,@cMensaje=N'Operación previamente registrada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
  COMMIT TRANSACTION;RETURN;
 END;

 DECLARE @motivo NVARCHAR(1000)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.motivo'))),N''),@prev VARCHAR(16),@version BIGINT;
 IF @motivo IS NULL OR LEN(@motivo)<5 THROW 51220,N'Indique el motivo de eliminación (mínimo 5 caracteres).',1;
 SELECT @prev=estado_actual,@version=version FROM prod.PlantaPaltaE3 WITH(UPDLOCK,HOLDLOCK) WHERE planta_id=@planta;
 IF @prev='ELIMINADA' THROW 51221,N'La planta ya está eliminada.',1;
 IF @version<>TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.version')) THROW 51222,N'La planta cambió. Actualice antes de eliminar.',1;
 UPDATE prod.PlantaPaltaE3 SET estado_actual='ELIMINADA',activo=0,version=version+1 WHERE planta_id=@planta;
 INSERT INTO prod.PlantaEventoE3(planta_id,tipo,estado_anterior,estado_nuevo,observacion,usuario_id,fecha_hecho)
 VALUES(@planta,'ELIMINACION',@prev,'ELIMINADA',@motivo,@usuario,@now);
 SET @cDatos=(SELECT @planta plantaId,SCOPE_IDENTITY() eventoId,'ELIMINADA' estado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);

 SELECT @bResultado=1,@cMensaje=N'Operación realizada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 INSERT INTO prod.PlantaSolicitudE3(usuario_id,accion,clave,hash_peticion,respuesta)
 VALUES(@usuario,'E3_Planta_Upd_Eliminar',@clave,@hash,COALESCE(@cDatos,N'{}'));
 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
  SELECT @bResultado=0,@cDatos=NULL,@nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN 400 ELSE 503 END,
    @cCodigoRespuesta='E3_ERROR',
    @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN ERROR_MESSAGE() ELSE N'No se pudo completar la operación.' END;
 END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE prod.PA_E3_Comentario_Ins_Registro
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No fue posible completar la operación.',@cCodigoRespuesta='E3_ERROR',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@planta BIGINT,@episodio BIGINT,@now DATETIME2(0)=SYSUTCDATETIME();
 BEGIN TRY
 EXEC prod.PA_E3_Sel_ValidarContexto @cJson,'APAPPSS_PREDIOS_EDITAR',@usuario OUTPUT,@planta OUTPUT,@episodio OUTPUT;
 DECLARE @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
   @hash VARBINARY(32),@anterior VARBINARY(32),@previo NVARCHAR(MAX);
 IF @clave IS NULL THROW 51216,N'Falta la clave de la operación.',1;
 SET @hash=HASHBYTES('SHA2_256',CONCAT('PA_E3_Comentario_Ins_Registro',N'|',JSON_QUERY(@cJson,'$.filtros'),N'|',JSON_QUERY(@cJson,'$.datos')));
 BEGIN TRANSACTION;
 SELECT @anterior=hash_peticion,@previo=respuesta FROM prod.PlantaSolicitudE3 WITH(UPDLOCK,HOLDLOCK)
 WHERE usuario_id=@usuario AND accion='E3_Comentario_Ins_Registro' AND clave=@clave;
 IF @anterior IS NOT NULL
 BEGIN
  IF @anterior<>@hash THROW 51217,N'La operación ya fue utilizada con otros datos.',1;
  SELECT @cDatos=@previo,@bResultado=1,@cMensaje=N'Operación previamente registrada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
  COMMIT TRANSACTION;RETURN;
 END;

 DECLARE @comentario NVARCHAR(1500)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.comentario'))),N''),@id BIGINT;
 IF @comentario IS NULL THROW 51223,N'Escriba un comentario.',1;
 IF EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 WHERE planta_id=@planta AND estado_actual='ELIMINADA')
  THROW 51224,N'La planta eliminada solo admite consultas.',1;
 INSERT INTO prod.PlantaComentarioE3(planta_id,comentario,usuario_id) VALUES(@planta,@comentario,@usuario);
 SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
 INSERT INTO prod.PlantaEventoE3(planta_id,tipo,observacion,usuario_id,fecha_hecho)
 VALUES(@planta,'COMENTARIO',LEFT(@comentario,1000),@usuario,@now);
 SET @cDatos=(SELECT @id comentarioId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);

 SELECT @bResultado=1,@cMensaje=N'Operación realizada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 INSERT INTO prod.PlantaSolicitudE3(usuario_id,accion,clave,hash_peticion,respuesta)
 VALUES(@usuario,'E3_Comentario_Ins_Registro',@clave,@hash,COALESCE(@cDatos,N'{}'));
 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
  SELECT @bResultado=0,@cDatos=NULL,@nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN 400 ELSE 503 END,
    @cCodigoRespuesta='E3_ERROR',
    @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN ERROR_MESSAGE() ELSE N'No se pudo completar la operación.' END;
 END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE prod.PA_E3_Comentario_Sel_Listado
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No fue posible completar la operación.',@cCodigoRespuesta='E3_ERROR',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@planta BIGINT,@episodio BIGINT,@now DATETIME2(0)=SYSUTCDATETIME();
 BEGIN TRY
 EXEC prod.PA_E3_Sel_ValidarContexto @cJson,'APAPPSS_PREDIOS_VER',@usuario OUTPUT,@planta OUTPUT,@episodio OUTPUT;

 SET @cDatos=(SELECT JSON_QUERY((SELECT C.comentario_id comentarioId,C.comentario,C.usuario_id usuarioId,
  U.nombre_usuario usuarioNombre,CONVERT(VARCHAR(19),C.creado_en,126)+'Z' fechaHora
  FROM prod.PlantaComentarioE3 C LEFT JOIN seg.Usuario U ON U.usuario_id=C.usuario_id
  WHERE C.planta_id=@planta ORDER BY C.comentario_id DESC FOR JSON PATH)) items
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);

 SELECT @bResultado=1,@cMensaje=N'Operación realizada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
  SELECT @bResultado=0,@cDatos=NULL,@nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN 400 ELSE 503 END,
    @cCodigoRespuesta='E3_ERROR',
    @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN ERROR_MESSAGE() ELSE N'No se pudo completar la operación.' END;
 END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE prod.PA_E3_Enfermedad_Ins_Registro
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No fue posible completar la operación.',@cCodigoRespuesta='E3_ERROR',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@planta BIGINT,@episodio BIGINT,@now DATETIME2(0)=SYSUTCDATETIME();
 BEGIN TRY
 EXEC prod.PA_E3_Sel_ValidarContexto @cJson,'APAPPSS_PREDIOS_EDITAR',@usuario OUTPUT,@planta OUTPUT,@episodio OUTPUT;
 DECLARE @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
   @hash VARBINARY(32),@anterior VARBINARY(32),@previo NVARCHAR(MAX);
 IF @clave IS NULL THROW 51216,N'Falta la clave de la operación.',1;
 SET @hash=HASHBYTES('SHA2_256',CONCAT('PA_E3_Enfermedad_Ins_Registro',N'|',JSON_QUERY(@cJson,'$.filtros'),N'|',JSON_QUERY(@cJson,'$.datos')));
 BEGIN TRANSACTION;
 SELECT @anterior=hash_peticion,@previo=respuesta FROM prod.PlantaSolicitudE3 WITH(UPDLOCK,HOLDLOCK)
 WHERE usuario_id=@usuario AND accion='E3_Enfermedad_Ins_Registro' AND clave=@clave;
 IF @anterior IS NOT NULL
 BEGIN
  IF @anterior<>@hash THROW 51217,N'La operación ya fue utilizada con otros datos.',1;
  SELECT @cDatos=@previo,@bResultado=1,@cMensaje=N'Operación previamente registrada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
  COMMIT TRANSACTION;RETURN;
 END;

 DECLARE @diagnostico INT=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.diagnosticoId')),
  @comentario NVARCHAR(1000)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.observacion'))),N''),
  @inicio DATETIME2(0)=COALESCE(TRY_CONVERT(DATETIME2(0),JSON_VALUE(@cJson,'$.datos.inicio')),@now),
  @estadoPrev VARCHAR(16),@id BIGINT;
 SELECT @estadoPrev=estado_actual FROM prod.PlantaPaltaE3 WITH(UPDLOCK,HOLDLOCK) WHERE planta_id=@planta;
 IF @estadoPrev IN('MUERTA','ELIMINADA') THROW 51225,N'No se puede registrar una enfermedad en una planta inactiva.',1;
 IF @inicio>@now OR @inicio<DATEADD(YEAR,-100,@now) THROW 51226,N'La fecha de diagnóstico no es válida.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPProblema GP JOIN prod.Cultivo C ON C.cultivo_id=GP.cultivo_id AND C.estado=1
   WHERE GP.problema_id=@diagnostico AND GP.estado=1 AND (UPPER(C.codigo)='PALTA' OR UPPER(C.nombre)=N'PALTA'))
  THROW 51227,N'Seleccione una enfermedad válida del catálogo.',1;
 IF EXISTS(SELECT 1 FROM sanidad.EpisodioPlantaE3 WITH(UPDLOCK,HOLDLOCK)
  WHERE planta_id=@planta AND gp_problema_id=@diagnostico AND fin IS NULL AND activo=1)
  THROW 51228,N'La enfermedad ya está vigente en esta planta.',1;
 INSERT INTO sanidad.EpisodioPlantaE3(planta_id,gp_problema_id,inicio,observacion,usuario_apertura_id)
 VALUES(@planta,@diagnostico,@inicio,@comentario,@usuario);
 SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
 UPDATE prod.PlantaPaltaE3 SET estado_actual='ENFERMA',version=version+1 WHERE planta_id=@planta;
 INSERT INTO prod.PlantaEventoE3(planta_id,tipo,estado_anterior,estado_nuevo,observacion,usuario_id,fecha_hecho)
 VALUES(@planta,'ENFERMEDAD',@estadoPrev,'ENFERMA',@comentario,@usuario,@now);
 SET @cDatos=(SELECT @id episodioId,@planta plantaId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);

 SELECT @bResultado=1,@cMensaje=N'Operación realizada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 INSERT INTO prod.PlantaSolicitudE3(usuario_id,accion,clave,hash_peticion,respuesta)
 VALUES(@usuario,'E3_Enfermedad_Ins_Registro',@clave,@hash,COALESCE(@cDatos,N'{}'));
 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
  SELECT @bResultado=0,@cDatos=NULL,@nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN 400 ELSE 503 END,
    @cCodigoRespuesta='E3_ERROR',
    @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN ERROR_MESSAGE() ELSE N'No se pudo completar la operación.' END;
 END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE prod.PA_E3_Enfermedad_Upd_Registro
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No fue posible completar la operación.',@cCodigoRespuesta='E3_ERROR',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@planta BIGINT,@episodio BIGINT,@now DATETIME2(0)=SYSUTCDATETIME();
 BEGIN TRY
 EXEC prod.PA_E3_Sel_ValidarContexto @cJson,'APAPPSS_PREDIOS_EDITAR',@usuario OUTPUT,@planta OUTPUT,@episodio OUTPUT;
 IF @episodio IS NULL THROW 51215,N'Seleccione una enfermedad válida.',1;
 DECLARE @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
   @hash VARBINARY(32),@anterior VARBINARY(32),@previo NVARCHAR(MAX);
 IF @clave IS NULL THROW 51216,N'Falta la clave de la operación.',1;
 SET @hash=HASHBYTES('SHA2_256',CONCAT('PA_E3_Enfermedad_Upd_Registro',N'|',JSON_QUERY(@cJson,'$.filtros'),N'|',JSON_QUERY(@cJson,'$.datos')));
 BEGIN TRANSACTION;
 SELECT @anterior=hash_peticion,@previo=respuesta FROM prod.PlantaSolicitudE3 WITH(UPDLOCK,HOLDLOCK)
 WHERE usuario_id=@usuario AND accion='E3_Enfermedad_Upd_Registro' AND clave=@clave;
 IF @anterior IS NOT NULL
 BEGIN
  IF @anterior<>@hash THROW 51217,N'La operación ya fue utilizada con otros datos.',1;
  SELECT @cDatos=@previo,@bResultado=1,@cMensaje=N'Operación previamente registrada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
  COMMIT TRANSACTION;RETURN;
 END;

 DECLARE @texto NVARCHAR(1000)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.observacion'))),N''),
  @diagnostico INT=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.diagnosticoId'));
 IF EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 WHERE planta_id=@planta AND estado_actual IN('MUERTA','ELIMINADA'))
   THROW 51229,N'No se puede editar una enfermedad en una planta inactiva.',1;
 IF NOT EXISTS(SELECT 1 FROM sanidad.EpisodioPlantaE3 WITH(UPDLOCK,HOLDLOCK)
   WHERE episodio_id=@episodio AND activo=1) THROW 51230,N'La enfermedad está eliminada.',1;
 IF @diagnostico IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.GPProblema GP JOIN prod.Cultivo C ON C.cultivo_id=GP.cultivo_id
   WHERE GP.problema_id=@diagnostico AND GP.estado=1 AND C.estado=1 AND (UPPER(C.codigo)='PALTA' OR UPPER(C.nombre)=N'PALTA'))
  THROW 51227,N'Seleccione una enfermedad válida.',1;
 IF @diagnostico IS NOT NULL AND EXISTS(SELECT 1 FROM sanidad.EpisodioPlantaE3
   WHERE planta_id=@planta AND episodio_id<>@episodio AND gp_problema_id=@diagnostico AND fin IS NULL AND activo=1)
  THROW 51228,N'La enfermedad ya está vigente en esta planta.',1;
 UPDATE sanidad.EpisodioPlantaE3 SET observacion=COALESCE(@texto,observacion),gp_problema_id=COALESCE(@diagnostico,gp_problema_id)
  WHERE episodio_id=@episodio;
 INSERT INTO prod.PlantaEventoE3(planta_id,tipo,observacion,usuario_id,fecha_hecho)
 VALUES(@planta,'ENFERMEDAD',N'Datos de la enfermedad actualizados.',@usuario,@now);
 SET @cDatos=(SELECT @episodio episodioId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);

 SELECT @bResultado=1,@cMensaje=N'Operación realizada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 INSERT INTO prod.PlantaSolicitudE3(usuario_id,accion,clave,hash_peticion,respuesta)
 VALUES(@usuario,'E3_Enfermedad_Upd_Registro',@clave,@hash,COALESCE(@cDatos,N'{}'));
 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
  SELECT @bResultado=0,@cDatos=NULL,@nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN 400 ELSE 503 END,
    @cCodigoRespuesta='E3_ERROR',
    @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN ERROR_MESSAGE() ELSE N'No se pudo completar la operación.' END;
 END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE prod.PA_E3_Enfermedad_Upd_Recuperar
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No fue posible completar la operación.',@cCodigoRespuesta='E3_ERROR',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@planta BIGINT,@episodio BIGINT,@now DATETIME2(0)=SYSUTCDATETIME();
 BEGIN TRY
 EXEC prod.PA_E3_Sel_ValidarContexto @cJson,'APAPPSS_PREDIOS_EDITAR',@usuario OUTPUT,@planta OUTPUT,@episodio OUTPUT;
 IF @episodio IS NULL THROW 51215,N'Seleccione una enfermedad válida.',1;
 DECLARE @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
   @hash VARBINARY(32),@anterior VARBINARY(32),@previo NVARCHAR(MAX);
 IF @clave IS NULL THROW 51216,N'Falta la clave de la operación.',1;
 SET @hash=HASHBYTES('SHA2_256',CONCAT('PA_E3_Enfermedad_Upd_Recuperar',N'|',JSON_QUERY(@cJson,'$.filtros'),N'|',JSON_QUERY(@cJson,'$.datos')));
 BEGIN TRANSACTION;
 SELECT @anterior=hash_peticion,@previo=respuesta FROM prod.PlantaSolicitudE3 WITH(UPDLOCK,HOLDLOCK)
 WHERE usuario_id=@usuario AND accion='E3_Enfermedad_Upd_Recuperar' AND clave=@clave;
 IF @anterior IS NOT NULL
 BEGIN
  IF @anterior<>@hash THROW 51217,N'La operación ya fue utilizada con otros datos.',1;
  SELECT @cDatos=@previo,@bResultado=1,@cMensaje=N'Operación previamente registrada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
  COMMIT TRANSACTION;RETURN;
 END;

 DECLARE @fin DATETIME2(0)=COALESCE(TRY_CONVERT(DATETIME2(0),JSON_VALUE(@cJson,'$.datos.fechaCuracion')),@now),
  @motivo NVARCHAR(600)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.comentario'))),N''),
  @inicio DATETIME2(0),@prev VARCHAR(16),@nuevo VARCHAR(16);
 SELECT @prev=estado_actual FROM prod.PlantaPaltaE3 WITH(UPDLOCK,HOLDLOCK) WHERE planta_id=@planta;
 IF @prev IN('MUERTA','ELIMINADA') THROW 51231,N'La planta inactiva no admite cambios sanitarios.',1;
 SELECT @inicio=inicio FROM sanidad.EpisodioPlantaE3 WITH(UPDLOCK,HOLDLOCK)
  WHERE episodio_id=@episodio AND activo=1 AND fin IS NULL;
 IF @inicio IS NULL THROW 51232,N'La enfermedad ya no está vigente.',1;
 IF @fin<@inicio OR @fin>@now THROW 51233,N'La fecha de recuperación no es válida.',1;
 UPDATE sanidad.EpisodioPlantaE3 SET fin=@fin,usuario_cierre_id=@usuario,motivo_cierre=@motivo WHERE episodio_id=@episodio;
 SET @nuevo=CASE WHEN EXISTS(SELECT 1 FROM sanidad.EpisodioPlantaE3
  WHERE planta_id=@planta AND fin IS NULL AND activo=1) THEN 'ENFERMA' ELSE 'SANA' END;
 UPDATE prod.PlantaPaltaE3 SET estado_actual=@nuevo,version=version+1 WHERE planta_id=@planta;
 INSERT INTO prod.PlantaEventoE3(planta_id,tipo,estado_anterior,estado_nuevo,observacion,usuario_id,fecha_hecho)
 VALUES(@planta,'ENFERMEDAD',@prev,@nuevo,COALESCE(@motivo,N'Recuperación registrada.'),@usuario,@now);
 SET @cDatos=(SELECT @episodio episodioId,@nuevo estado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);

 SELECT @bResultado=1,@cMensaje=N'Operación realizada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 INSERT INTO prod.PlantaSolicitudE3(usuario_id,accion,clave,hash_peticion,respuesta)
 VALUES(@usuario,'E3_Enfermedad_Upd_Recuperar',@clave,@hash,COALESCE(@cDatos,N'{}'));
 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
  SELECT @bResultado=0,@cDatos=NULL,@nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN 400 ELSE 503 END,
    @cCodigoRespuesta='E3_ERROR',
    @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN ERROR_MESSAGE() ELSE N'No se pudo completar la operación.' END;
 END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE prod.PA_E3_Enfermedad_Upd_Eliminar
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No fue posible completar la operación.',@cCodigoRespuesta='E3_ERROR',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@planta BIGINT,@episodio BIGINT,@now DATETIME2(0)=SYSUTCDATETIME();
 BEGIN TRY
 EXEC prod.PA_E3_Sel_ValidarContexto @cJson,'APAPPSS_PREDIOS_EDITAR',@usuario OUTPUT,@planta OUTPUT,@episodio OUTPUT;
 IF @episodio IS NULL THROW 51215,N'Seleccione una enfermedad válida.',1;
 DECLARE @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
   @hash VARBINARY(32),@anterior VARBINARY(32),@previo NVARCHAR(MAX);
 IF @clave IS NULL THROW 51216,N'Falta la clave de la operación.',1;
 SET @hash=HASHBYTES('SHA2_256',CONCAT('PA_E3_Enfermedad_Upd_Eliminar',N'|',JSON_QUERY(@cJson,'$.filtros'),N'|',JSON_QUERY(@cJson,'$.datos')));
 BEGIN TRANSACTION;
 SELECT @anterior=hash_peticion,@previo=respuesta FROM prod.PlantaSolicitudE3 WITH(UPDLOCK,HOLDLOCK)
 WHERE usuario_id=@usuario AND accion='E3_Enfermedad_Upd_Eliminar' AND clave=@clave;
 IF @anterior IS NOT NULL
 BEGIN
  IF @anterior<>@hash THROW 51217,N'La operación ya fue utilizada con otros datos.',1;
  SELECT @cDatos=@previo,@bResultado=1,@cMensaje=N'Operación previamente registrada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
  COMMIT TRANSACTION;RETURN;
 END;

 DECLARE @motivo NVARCHAR(600)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.motivo'))),N''),
  @prev VARCHAR(16),@nuevo VARCHAR(16);
 IF @motivo IS NULL OR LEN(@motivo)<5 THROW 51234,N'Indique el motivo para retirar la enfermedad.',1;
 SELECT @prev=estado_actual FROM prod.PlantaPaltaE3 WITH(UPDLOCK,HOLDLOCK) WHERE planta_id=@planta;
 IF @prev='ELIMINADA' THROW 51235,N'La planta eliminada solo admite consultas.',1;
 IF NOT EXISTS(SELECT 1 FROM sanidad.EpisodioPlantaE3 WITH(UPDLOCK,HOLDLOCK)
   WHERE episodio_id=@episodio AND activo=1) THROW 51236,N'La enfermedad ya fue retirada.',1;
 UPDATE sanidad.EpisodioPlantaE3 SET activo=0,eliminado_en=@now,eliminado_por_usuario_id=@usuario
   WHERE episodio_id=@episodio;
 SET @nuevo=CASE WHEN EXISTS(SELECT 1 FROM sanidad.EpisodioPlantaE3 WHERE planta_id=@planta AND fin IS NULL AND activo=1)
  THEN 'ENFERMA' ELSE CASE WHEN @prev='ENFERMA' THEN 'SANA' ELSE @prev END END;
 IF @prev<>'MUERTA' UPDATE prod.PlantaPaltaE3 SET estado_actual=@nuevo,version=version+1 WHERE planta_id=@planta;
 INSERT INTO prod.PlantaEventoE3(planta_id,tipo,estado_anterior,estado_nuevo,observacion,usuario_id,fecha_hecho)
 VALUES(@planta,'ENFERMEDAD',@prev,@nuevo,CONCAT(N'Enfermedad retirada: ',@motivo),@usuario,@now);
 SET @cDatos=(SELECT @episodio episodioId,@nuevo estado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);

 SELECT @bResultado=1,@cMensaje=N'Operación realizada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 INSERT INTO prod.PlantaSolicitudE3(usuario_id,accion,clave,hash_peticion,respuesta)
 VALUES(@usuario,'E3_Enfermedad_Upd_Eliminar',@clave,@hash,COALESCE(@cDatos,N'{}'));
 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
  SELECT @bResultado=0,@cDatos=NULL,@nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN 400 ELSE 503 END,
    @cCodigoRespuesta='E3_ERROR',
    @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN ERROR_MESSAGE() ELSE N'No se pudo completar la operación.' END;
 END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE prod.PA_E3_Enfermedad_Sel_Listado
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No fue posible completar la operación.',@cCodigoRespuesta='E3_ERROR',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@planta BIGINT,@episodio BIGINT,@now DATETIME2(0)=SYSUTCDATETIME();
 BEGIN TRY
 EXEC prod.PA_E3_Sel_ValidarContexto @cJson,'APAPPSS_PREDIOS_VER',@usuario OUTPUT,@planta OUTPUT,@episodio OUTPUT;

 SET @cDatos=(SELECT JSON_QUERY((SELECT E.episodio_id episodioId,E.gp_problema_id diagnosticoId,
  COALESCE(GP.nombre,TP.nombre) enfermedad,
  CASE WHEN E.activo=0 THEN 'ELIMINADA' WHEN E.fin IS NULL THEN 'VIGENTE' ELSE 'RECUPERADA' END estado,
  CONVERT(VARCHAR(19),E.inicio,126)+'Z' fechaDiagnostico,
  CASE WHEN E.fin IS NULL THEN NULL ELSE CONVERT(VARCHAR(19),E.fin,126)+'Z' END fechaCuracion,
  DATEDIFF(DAY,CONVERT(DATE,E.inicio),CONVERT(DATE,COALESCE(E.fin,@now)))+1 diasEnferma,
  E.usuario_apertura_id usuarioRegistroId,U.nombre_usuario registradoPor,
  (SELECT COUNT_BIG(*) FROM sanidad.TratamientoPlantaE3 T WHERE T.episodio_id=E.episodio_id) totalTratamientos
  FROM sanidad.EpisodioPlantaE3 E
  LEFT JOIN prod.GPProblema GP ON GP.problema_id=E.gp_problema_id
  LEFT JOIN sanidad.TipoProblemaFitosanitario TP ON TP.tipo_problema_fitosanitario_id=E.tipo_problema_fitosanitario_id
  LEFT JOIN seg.Usuario U ON U.usuario_id=E.usuario_apertura_id
  WHERE E.planta_id=@planta ORDER BY E.episodio_id DESC FOR JSON PATH)) items
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);

 SELECT @bResultado=1,@cMensaje=N'Operación realizada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
  SELECT @bResultado=0,@cDatos=NULL,@nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN 400 ELSE 503 END,
    @cCodigoRespuesta='E3_ERROR',
    @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN ERROR_MESSAGE() ELSE N'No se pudo completar la operación.' END;
 END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE prod.PA_E3_Enfermedad_Sel_Detalle
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No fue posible completar la operación.',@cCodigoRespuesta='E3_ERROR',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@planta BIGINT,@episodio BIGINT,@now DATETIME2(0)=SYSUTCDATETIME();
 BEGIN TRY
 EXEC prod.PA_E3_Sel_ValidarContexto @cJson,'APAPPSS_PREDIOS_VER',@usuario OUTPUT,@planta OUTPUT,@episodio OUTPUT;
 IF @episodio IS NULL THROW 51215,N'Seleccione una enfermedad válida.',1;

 SET @cDatos=(SELECT E.episodio_id episodioId,E.planta_id plantaId,E.gp_problema_id diagnosticoId,
  COALESCE(GP.nombre,TP.nombre) enfermedad,
  CASE WHEN E.activo=0 THEN 'ELIMINADA' WHEN E.fin IS NULL THEN 'VIGENTE' ELSE 'RECUPERADA' END estado,
  E.observacion, E.motivo_cierre motivoCierre,
  CONVERT(VARCHAR(19),E.inicio,126)+'Z' fechaDiagnostico,
  CASE WHEN E.fin IS NULL THEN NULL ELSE CONVERT(VARCHAR(19),E.fin,126)+'Z' END fechaCuracion,
  DATEDIFF(DAY,CONVERT(DATE,E.inicio),CONVERT(DATE,COALESCE(E.fin,@now)))+1 diasEnferma,
  E.usuario_apertura_id usuarioRegistroId,UA.nombre_usuario registradoPor,
  E.usuario_cierre_id usuarioCuracionId,UC.nombre_usuario curadoPor,
  E.eliminado_por_usuario_id usuarioEliminacionId,UE.nombre_usuario eliminadoPor,
  CASE WHEN E.eliminado_en IS NULL THEN NULL ELSE CONVERT(VARCHAR(19),E.eliminado_en,126)+'Z' END fechaEliminacion,
  JSON_QUERY((SELECT T.tratamiento_id tratamientoId,T.gp_tratamiento_id catalogoTratamientoId,
   T.descripcion,T.resultado,T.comentario,
   CONVERT(VARCHAR(19),T.fecha_aplicacion,126)+'Z' fechaAplicacion,
   CONVERT(VARCHAR(19),T.fecha_registro,126)+'Z' fechaRegistro,
   T.usuario_id usuarioId,UT.nombre_usuario usuarioNombre
   FROM sanidad.TratamientoPlantaE3 T LEFT JOIN seg.Usuario UT ON UT.usuario_id=T.usuario_id
   WHERE T.episodio_id=E.episodio_id ORDER BY T.fecha_aplicacion DESC,T.tratamiento_id DESC FOR JSON PATH)) tratamientos
  FROM sanidad.EpisodioPlantaE3 E
  LEFT JOIN prod.GPProblema GP ON GP.problema_id=E.gp_problema_id
  LEFT JOIN sanidad.TipoProblemaFitosanitario TP ON TP.tipo_problema_fitosanitario_id=E.tipo_problema_fitosanitario_id
  LEFT JOIN seg.Usuario UA ON UA.usuario_id=E.usuario_apertura_id
  LEFT JOIN seg.Usuario UC ON UC.usuario_id=E.usuario_cierre_id
  LEFT JOIN seg.Usuario UE ON UE.usuario_id=E.eliminado_por_usuario_id
  WHERE E.episodio_id=@episodio FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);

 SELECT @bResultado=1,@cMensaje=N'Operación realizada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
  SELECT @bResultado=0,@cDatos=NULL,@nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN 400 ELSE 503 END,
    @cCodigoRespuesta='E3_ERROR',
    @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN ERROR_MESSAGE() ELSE N'No se pudo completar la operación.' END;
 END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE prod.PA_E3_Tratamiento_Ins_Registro
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No fue posible completar la operación.',@cCodigoRespuesta='E3_ERROR',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@planta BIGINT,@episodio BIGINT,@now DATETIME2(0)=SYSUTCDATETIME();
 BEGIN TRY
 EXEC prod.PA_E3_Sel_ValidarContexto @cJson,'APAPPSS_PREDIOS_EDITAR',@usuario OUTPUT,@planta OUTPUT,@episodio OUTPUT;
 IF @episodio IS NULL THROW 51215,N'Seleccione una enfermedad válida.',1;
 DECLARE @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
   @hash VARBINARY(32),@anterior VARBINARY(32),@previo NVARCHAR(MAX);
 IF @clave IS NULL THROW 51216,N'Falta la clave de la operación.',1;
 SET @hash=HASHBYTES('SHA2_256',CONCAT('PA_E3_Tratamiento_Ins_Registro',N'|',JSON_QUERY(@cJson,'$.filtros'),N'|',JSON_QUERY(@cJson,'$.datos')));
 BEGIN TRANSACTION;
 SELECT @anterior=hash_peticion,@previo=respuesta FROM prod.PlantaSolicitudE3 WITH(UPDLOCK,HOLDLOCK)
 WHERE usuario_id=@usuario AND accion='E3_Tratamiento_Ins_Registro' AND clave=@clave;
 IF @anterior IS NOT NULL
 BEGIN
  IF @anterior<>@hash THROW 51217,N'La operación ya fue utilizada con otros datos.',1;
  SELECT @cDatos=@previo,@bResultado=1,@cMensaje=N'Operación previamente registrada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
  COMMIT TRANSACTION;RETURN;
 END;

 DECLARE @catalogo INT=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.catalogoTratamientoId')),
  @fecha DATETIME2(0)=COALESCE(TRY_CONVERT(DATETIME2(0),JSON_VALUE(@cJson,'$.datos.fechaAplicacion')),@now),
  @comentario NVARCHAR(1000)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.comentario'))),N''),
  @resultado NVARCHAR(600)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.resultado'))),N''),@id BIGINT,@inicio DATETIME2(0);
 IF EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 WHERE planta_id=@planta AND estado_actual IN('MUERTA','ELIMINADA'))
  THROW 51240,N'No se puede tratar una planta inactiva.',1;
 SELECT @inicio=inicio FROM sanidad.EpisodioPlantaE3 WITH(UPDLOCK,HOLDLOCK)
   WHERE episodio_id=@episodio AND planta_id=@planta AND activo=1 AND fin IS NULL;
 IF @inicio IS NULL THROW 51241,N'El tratamiento requiere una enfermedad vigente.',1;
 IF @fecha<@inicio OR @fecha>@now THROW 51242,N'La fecha del tratamiento debe ser posterior al diagnóstico y no futura.',1;
 IF NOT EXISTS(SELECT 1 FROM sanidad.EpisodioPlantaE3 E
  JOIN prod.GPProblemaTratamiento PT ON PT.problema_id=E.gp_problema_id AND PT.tratamiento_id=@catalogo
  JOIN prod.GPTratamiento T ON T.tratamiento_id=PT.tratamiento_id AND T.estado=1 WHERE E.episodio_id=@episodio)
  THROW 51243,N'El tratamiento no corresponde a esta enfermedad.',1;
 INSERT INTO sanidad.TratamientoPlantaE3(episodio_id,gp_tratamiento_id,descripcion,resultado,comentario,
  fecha_aplicacion,usuario_id)
 SELECT @episodio,T.tratamiento_id,T.nombre,@resultado,@comentario,@fecha,@usuario
 FROM prod.GPTratamiento T WHERE T.tratamiento_id=@catalogo;
 SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
 INSERT INTO prod.PlantaEventoE3(planta_id,tipo,observacion,usuario_id,fecha_hecho)
 VALUES(@planta,'TRATAMIENTO',CONCAT(N'Tratamiento aplicado a enfermedad ',@episodio),@usuario,@now);
 SET @cDatos=(SELECT @id tratamientoId,@episodio episodioId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);

 SELECT @bResultado=1,@cMensaje=N'Operación realizada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 INSERT INTO prod.PlantaSolicitudE3(usuario_id,accion,clave,hash_peticion,respuesta)
 VALUES(@usuario,'E3_Tratamiento_Ins_Registro',@clave,@hash,COALESCE(@cDatos,N'{}'));
 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
  SELECT @bResultado=0,@cDatos=NULL,@nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN 400 ELSE 503 END,
    @cCodigoRespuesta='E3_ERROR',
    @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN ERROR_MESSAGE() ELSE N'No se pudo completar la operación.' END;
 END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE prod.PA_E3_Tratamiento_Sel_Listado
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No fue posible completar la operación.',@cCodigoRespuesta='E3_ERROR',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@planta BIGINT,@episodio BIGINT,@now DATETIME2(0)=SYSUTCDATETIME();
 BEGIN TRY
 EXEC prod.PA_E3_Sel_ValidarContexto @cJson,'APAPPSS_PREDIOS_VER',@usuario OUTPUT,@planta OUTPUT,@episodio OUTPUT;
 IF @episodio IS NULL THROW 51215,N'Seleccione una enfermedad válida.',1;

 SET @cDatos=(SELECT JSON_QUERY((SELECT T.tratamiento_id tratamientoId,T.gp_tratamiento_id catalogoTratamientoId,
  T.descripcion,T.resultado,T.comentario,
  CONVERT(VARCHAR(19),T.fecha_aplicacion,126)+'Z' fechaAplicacion,
  CONVERT(VARCHAR(19),T.fecha_registro,126)+'Z' fechaRegistro,
  T.usuario_id usuarioId,U.nombre_usuario usuarioNombre
  FROM sanidad.TratamientoPlantaE3 T LEFT JOIN seg.Usuario U ON U.usuario_id=T.usuario_id
  WHERE T.episodio_id=@episodio ORDER BY T.tratamiento_id DESC FOR JSON PATH)) items
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);

 SELECT @bResultado=1,@cMensaje=N'Operación realizada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
  SELECT @bResultado=0,@cDatos=NULL,@nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN 400 ELSE 503 END,
    @cCodigoRespuesta='E3_ERROR',
    @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN ERROR_MESSAGE() ELSE N'No se pudo completar la operación.' END;
 END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE prod.PA_E3_Planta_Sel_AnalisisSanitario
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No fue posible completar la operación.',@cCodigoRespuesta='E3_ERROR',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@planta BIGINT,@episodio BIGINT,@now DATETIME2(0)=SYSUTCDATETIME();
 BEGIN TRY
 EXEC prod.PA_E3_Sel_ValidarContexto @cJson,'APAPPSS_PREDIOS_VER',@usuario OUTPUT,@planta OUTPUT,@episodio OUTPUT;

 SET @cDatos=(SELECT @planta plantaId,
  (SELECT COUNT_BIG(*) FROM sanidad.EpisodioPlantaE3 E WHERE E.planta_id=@planta AND E.activo=1) totalEnfermedades,
  (SELECT COUNT_BIG(*) FROM sanidad.EpisodioPlantaE3 E WHERE E.planta_id=@planta AND E.activo=1 AND E.fin IS NULL) enfermedadesVigentes,
  (SELECT COUNT_BIG(*) FROM sanidad.EpisodioPlantaE3 E WHERE E.planta_id=@planta AND E.activo=1 AND E.fin IS NOT NULL) enfermedadesRecuperadas,
  (SELECT COUNT_BIG(*) FROM sanidad.TratamientoPlantaE3 T JOIN sanidad.EpisodioPlantaE3 E ON E.episodio_id=T.episodio_id
   WHERE E.planta_id=@planta AND E.activo=1) tratamientosAplicados,
  (SELECT MAX(T.fecha_aplicacion) FROM sanidad.TratamientoPlantaE3 T JOIN sanidad.EpisodioPlantaE3 E ON E.episodio_id=T.episodio_id
   WHERE E.planta_id=@planta AND E.activo=1) ultimoTratamiento,
  (SELECT COUNT_BIG(*) FROM prod.PlantaComentarioE3 C WHERE C.planta_id=@planta) totalComentarios,
  (SELECT TOP(1) P.estado_actual FROM prod.PlantaPaltaE3 P WHERE P.planta_id=@planta) estadoPlanta
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);

 SELECT @bResultado=1,@cMensaje=N'Operación realizada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
  SELECT @bResultado=0,@cDatos=NULL,@nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN 400 ELSE 503 END,
    @cCodigoRespuesta='E3_ERROR',
    @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN ERROR_MESSAGE() ELSE N'No se pudo completar la operación.' END;
 END CATCH;
END;
GO
