-- Los archivos ya se almacenan en disco mediante LocalDocumentService.
-- Se añade un vínculo explícito por aplicación de tratamientos sin duplicar binarios.
IF OBJECT_ID(N'sanidad.TratamientoArchivoE4',N'U') IS NULL
BEGIN
 CREATE TABLE sanidad.TratamientoArchivoE4(
  tratamiento_archivo_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_E3_TratamientoArchivoE4 PRIMARY KEY,
  aplicacion_id BIGINT NOT NULL REFERENCES sanidad.TratamientoAplicacionE4(aplicacion_id),
  archivo_id BIGINT NOT NULL REFERENCES archivo.Archivo(archivo_id),
  usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
  fecha_registro DATETIME2(0) NOT NULL CONSTRAINT DF_E3_TratamientoArchivoFecha DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_E3_TratamientoArchivo UNIQUE(aplicacion_id,archivo_id)
 );
 CREATE INDEX IX_E3_TratamientoArchivoId ON sanidad.TratamientoArchivoE4(archivo_id);
END;
GO

-- La comprobación de estado terminal se centraliza en el validador usado
-- por los PA clínicos de escritura; las lecturas continúan habilitadas.
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
 IF @cPermiso='APAPPSS_PREDIOS_EDITAR' AND EXISTS(SELECT 1 FROM prod.PlantaPaltaE3
   WHERE planta_id=@nPlanta AND estado_actual IN('MUERTA','ELIMINADA'))
    THROW 51219,N'La planta fallecida o eliminada solo admite consultas.',1;
END;
GO

-- INSERT: vincular un documento local a una aplicación ya registrada.
CREATE OR ALTER PROCEDURE sanidad.PA_E3_TratamientoArchivo_Ins_Vinculo
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo vincular el archivo.',
   @cCodigoRespuesta='E3_ERROR',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@planta BIGINT,@episodio BIGINT;
 BEGIN TRY
  EXEC prod.PA_E3_Sel_ValidarContexto @cJson,'APAPPSS_PREDIOS_EDITAR',
   @usuario OUTPUT,@planta OUTPUT,@episodio OUTPUT;
  DECLARE @archivo BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.archivoId')),
   @aplicacion BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.aplicacionId')),
   @predio BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.predioId')),
   @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
   @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
   @hash VARBINARY(32),@antes VARBINARY(32),@previo NVARCHAR(MAX),@id BIGINT;
  IF @episodio IS NULL OR @archivo IS NULL OR @aplicacion IS NULL OR @clave IS NULL
   THROW 51241,N'Datos de tratamiento o archivo no válidos.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'PA_E3_TratamientoArchivo_Ins_Vinculo|',
   JSON_QUERY(@cJson,'$.filtros'),N'|',JSON_QUERY(@cJson,'$.datos')));
  BEGIN TRANSACTION;
  SELECT @antes=hash_peticion,@previo=respuesta FROM prod.PlantaSolicitudE3 WITH(UPDLOCK,HOLDLOCK)
   WHERE usuario_id=@usuario AND accion='E3_TratArchivo_Ins_Vinculo' AND clave=@clave;
  IF @antes IS NOT NULL
  BEGIN
   IF @antes<>@hash THROW 51242,N'La clave ya fue utilizada con otros datos.',1;
   SELECT @cDatos=@previo,@bResultado=1,@cMensaje=N'Archivo previamente vinculado.',
    @cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
   COMMIT TRANSACTION;RETURN;
  END;
  IF NOT EXISTS(SELECT 1 FROM sanidad.TratamientoAplicacionE4 T
    JOIN sanidad.EpisodioPlantaE3 E ON E.episodio_id=T.episodio_id
    WHERE T.aplicacion_id=@aplicacion AND E.episodio_id=@episodio AND E.planta_id=@planta)
   THROW 51243,N'La aplicación no pertenece a esta enfermedad.',1;
  IF NOT EXISTS(SELECT 1 FROM archivo.Archivo A
    JOIN archivo.ArchivoVinculo V ON V.archivo_id=A.archivo_id AND V.predio_id=@predio AND V.estado=1
    WHERE A.archivo_id=@archivo AND A.estado=1 AND A.uot_id=@uot
      AND A.proveedor_almacenamiento='LOCAL' AND A.usuario_id=@usuario)
   THROW 51244,N'El archivo debe estar cargado en el servidor y vinculado al predio.',1;
  IF EXISTS(SELECT 1 FROM sanidad.TratamientoArchivoE4
   WHERE aplicacion_id=@aplicacion AND archivo_id=@archivo)
   THROW 51245,N'El archivo ya está vinculado a esta aplicación.',1;
  INSERT INTO sanidad.TratamientoArchivoE4(aplicacion_id,archivo_id,usuario_id)
   VALUES(@aplicacion,@archivo,@usuario);
  SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
  SET @cDatos=(SELECT @id tratamientoArchivoId,@archivo archivoId,@aplicacion aplicacionId
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT INTO prod.PlantaSolicitudE3(usuario_id,accion,clave,hash_peticion,respuesta)
   VALUES(@usuario,'E3_TratArchivo_Ins_Vinculo',@clave,@hash,@cDatos);
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cMensaje=N'Archivo vinculado al tratamiento.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN 400 ELSE 503 END,
   @cCodigoRespuesta='E3_ERROR',
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN ERROR_MESSAGE()
     ELSE N'No se pudo vincular el archivo.' END;
 END CATCH;
END;
GO

-- SELECT: listado unificado por planta (general y tratamientos), sin URLs externas nuevas.
CREATE OR ALTER PROCEDURE prod.PA_E3_Archivo_Sel_Listado
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudieron consultar los archivos.',
   @cCodigoRespuesta='E3_ERROR',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@planta BIGINT,@episodio BIGINT;
 BEGIN TRY
  EXEC prod.PA_E3_Sel_ValidarContexto @cJson,'APAPPSS_PREDIOS_VER',
   @usuario OUTPUT,@planta OUTPUT,@episodio OUTPUT;
  SET @cDatos=(SELECT JSON_QUERY((
   SELECT X.archivoId,X.nombre,X.mimeType,X.categoria,X.descripcion,X.tipo,
      X.aplicacionId,X.episodioId,X.enfermedad,X.fechaCarga,X.usuarioNombre,X.[local],X.url
   FROM (
     SELECT A.archivo_id archivoId,A.nombre_original nombre,A.mime_type mimeType,
       A.categoria,A.descripcion,CONVERT(VARCHAR(20),'GENERAL') tipo,
       CONVERT(BIGINT,NULL) aplicacionId,CONVERT(BIGINT,NULL) episodioId,
       CONVERT(NVARCHAR(120),NULL) enfermedad,
       CONVERT(VARCHAR(19),A.fecha_carga,126)+'Z' fechaCarga,
       U.nombre_usuario usuarioNombre,
       CONVERT(BIT,CASE WHEN A.proveedor_almacenamiento='LOCAL' THEN 1 ELSE 0 END) [local],
       A.secure_url url
     FROM prod.PlantaEvidenciaE3 E
     JOIN archivo.Archivo A ON A.archivo_id=E.archivo_id AND A.estado=1
     LEFT JOIN seg.Usuario U ON U.usuario_id=A.usuario_id
     WHERE E.planta_id=@planta
     UNION ALL
     SELECT A.archivo_id,A.nombre_original,A.mime_type,A.categoria,A.descripcion,
       CONVERT(VARCHAR(20),'TRATAMIENTO'),T.aplicacion_id,E.episodio_id,
       CONVERT(NVARCHAR(120),COALESCE(GP.nombre,TP.nombre)),
       CONVERT(VARCHAR(19),A.fecha_carga,126)+'Z',U.nombre_usuario,CONVERT(BIT,1),
       A.secure_url
     FROM sanidad.TratamientoArchivoE4 TA
     JOIN sanidad.TratamientoAplicacionE4 T ON T.aplicacion_id=TA.aplicacion_id
     JOIN sanidad.EpisodioPlantaE3 E ON E.episodio_id=T.episodio_id
     JOIN archivo.Archivo A ON A.archivo_id=TA.archivo_id AND A.estado=1 AND A.proveedor_almacenamiento='LOCAL'
     LEFT JOIN seg.Usuario U ON U.usuario_id=TA.usuario_id
     LEFT JOIN prod.GPProblema GP ON GP.problema_id=E.gp_problema_id
     LEFT JOIN sanidad.TipoProblemaFitosanitario TP ON TP.tipo_problema_fitosanitario_id=E.tipo_problema_fitosanitario_id
     WHERE E.planta_id=@planta
   ) X ORDER BY X.fechaCarga DESC,X.archivoId DESC FOR JSON PATH
  )) items FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Archivos consultados.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 END TRY
 BEGIN CATCH
  SELECT @cDatos=NULL,@bResultado=0,
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN 400 ELSE 503 END,
   @cCodigoRespuesta='E3_ERROR',
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN ERROR_MESSAGE()
     ELSE N'No se pudieron consultar los archivos.' END;
 END CATCH;
END;
GO
