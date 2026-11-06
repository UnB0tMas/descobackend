-- V497 | GP: catálogo, censos exactos, límites de parcela, evidencias múltiples.
-- No altera ni elimina datos de censos y eventos previos.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID('prod.GPCensoVariedad','U') IS NULL
BEGIN
 CREATE TABLE prod.GPCensoVariedad (
   censo_id BIGINT NOT NULL REFERENCES prod.GPCenso(censo_id),
   variedad_cultivo_id BIGINT NOT NULL REFERENCES prod.VariedadCultivo(variedad_cultivo_id),
   superficie_m2 DECIMAL(14,2) NOT NULL,
   CONSTRAINT PK_GPCensoVariedad PRIMARY KEY(censo_id,variedad_cultivo_id),
   CONSTRAINT CK_GPCensoVariedad_Superficie CHECK(superficie_m2>0)
 );
END;
GO
IF EXISTS(SELECT 1 FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID('prod.GPEventoFoto') AND name='UQ_GPEventoFoto_Evento')
 ALTER TABLE prod.GPEventoFoto DROP CONSTRAINT UQ_GPEventoFoto_Evento;
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('prod.GPEventoFoto') AND name='IX_GPEventoFoto_Evento')
 CREATE INDEX IX_GPEventoFoto_Evento ON prod.GPEventoFoto(evento_id,foto_id);
GO
IF OBJECT_ID(N'prod.PA_GP_Actividad_Ins_Registro', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Actividad_Ins_Registro;
GO
CREATE PROCEDURE prod.PA_GP_Actividad_Ins_Registro
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Parcela BIGINT,
 @Rubro VARCHAR(8),@Cultivo INT=NULL,@Especie INT=NULL,
 @CantidadAproximada INT=NULL,@CantidadExacta INT=NULL,
 @SuperficieAprox DECIMAL(14,2)=NULL,@SuperficieExacta DECIMAL(14,2)=NULL,
 @RazasJson NVARCHAR(MAX)=NULL,@Solicitud UNIQUEIDENTIFIER,@Variedad BIGINT=NULL,
 @VariedadesJson NVARCHAR(MAX)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_CREAR',1)<>1
  THROW 51101,N'Acceso no autorizado.',1;
 IF @Solicitud IS NULL OR @Rubro NOT IN('CULTIVO','CRIANZA')
   OR (@Rubro='CULTIVO' AND (@Cultivo IS NULL OR @Especie IS NOT NULL OR
      (@SuperficieExacta IS NULL OR @SuperficieExacta<=0 OR @SuperficieAprox IS NOT NULL) OR
      @CantidadAproximada IS NOT NULL OR @CantidadExacta IS NOT NULL))
   OR (@Rubro='CRIANZA' AND (@Especie IS NULL OR @Cultivo IS NOT NULL OR
      (@CantidadExacta IS NULL OR @CantidadExacta<=0 OR @CantidadAproximada IS NOT NULL) OR
      @SuperficieAprox IS NOT NULL OR @SuperficieExacta IS NOT NULL))
   OR (@CantidadAproximada IS NOT NULL AND @CantidadAproximada<0)
   OR (@CantidadExacta IS NOT NULL AND @CantidadExacta<0)
   OR (@SuperficieAprox IS NOT NULL AND @SuperficieAprox<0)
   OR (@SuperficieExacta IS NOT NULL AND @SuperficieExacta<0)
  THROW 51103,N'Ingrese una cantidad o superficie exacta válida.',1;
 IF @Rubro='CULTIVO' AND NOT EXISTS(SELECT 1 FROM prod.Cultivo WHERE cultivo_id=@Cultivo AND estado=1)
  THROW 51103,N'El cultivo no está disponible.',1;
 IF @Variedad IS NOT NULL AND (@Rubro<>'CULTIVO' OR NOT EXISTS(
    SELECT 1 FROM prod.VariedadCultivo V WHERE V.variedad_cultivo_id=@Variedad
      AND V.cultivo_id=@Cultivo AND V.estado=1))
    THROW 51103,N'La variedad no corresponde al cultivo.',1;
 IF @Rubro='CRIANZA' AND NOT EXISTS(SELECT 1 FROM prod.EspeciePecuaria WHERE especie_pecuaria_id=@Especie AND estado=1)
  THROW 51103,N'La especie no está disponible.',1;
 IF @VariedadesJson IS NOT NULL AND ISJSON(@VariedadesJson)<>1
  THROW 51103,N'Detalle de variedades inválido.',1;
 IF @RazasJson IS NOT NULL AND ISJSON(@RazasJson)<>1
  THROW 51103,N'Detalle de razas inválido.',1;
 DECLARE @R TABLE(razaId INT,cantidadAproximada INT,cantidadExacta INT);
 IF @Rubro='CRIANZA' AND @RazasJson IS NOT NULL
  INSERT @R SELECT razaId,cantidadAproximada,cantidadExacta FROM OPENJSON(@RazasJson)
  WITH(razaId INT '$.razaId',cantidadAproximada INT '$.cantidadAproximada',cantidadExacta INT '$.cantidadExacta');
 IF EXISTS(SELECT 1 FROM @R WHERE razaId IS NULL OR cantidadExacta IS NULL OR cantidadAproximada IS NOT NULL
       OR cantidadExacta<0)
   OR EXISTS(SELECT 1 FROM @R GROUP BY razaId HAVING COUNT(*)>1)
   OR EXISTS(SELECT 1 FROM @R D LEFT JOIN prod.GPRaza R ON R.raza_id=D.razaId
       WHERE R.raza_id IS NULL OR R.especie_pecuaria_id<>@Especie OR R.estado=0)
   OR (@CantidadExacta IS NOT NULL AND (SELECT COALESCE(SUM(cantidadExacta),0) FROM @R)>@CantidadExacta)
  
  THROW 51103,N'Detalle de razas inválido o superior al total.',1;

 DECLARE @V TABLE(variedadId BIGINT PRIMARY KEY,superficieM2 DECIMAL(14,2));
 IF @Rubro='CULTIVO' AND @VariedadesJson IS NOT NULL
 BEGIN
   IF EXISTS(SELECT 1 FROM OPENJSON(@VariedadesJson) WITH(variedadId BIGINT '$.variedadId',superficieM2 DECIMAL(14,2) '$.superficieM2')
        WHERE variedadId IS NULL OR superficieM2 IS NULL OR superficieM2<=0)
       THROW 51103,N'Ingrese la variedad y una superficie válida.',1;
   IF EXISTS(SELECT variedadId FROM OPENJSON(@VariedadesJson) WITH(variedadId BIGINT '$.variedadId') GROUP BY variedadId HAVING COUNT(*)>1)
       THROW 51103,N'No repita variedades.',1;
   INSERT @V SELECT variedadId,superficieM2 FROM OPENJSON(@VariedadesJson)
      WITH(variedadId BIGINT '$.variedadId',superficieM2 DECIMAL(14,2) '$.superficieM2');
 END;
 IF (@Rubro='CRIANZA' AND EXISTS(SELECT 1 FROM @V))
    OR (@Rubro='CRIANZA' AND @VariedadesJson IS NOT NULL AND @VariedadesJson<>N'[]')
    OR EXISTS(SELECT 1 FROM @V D LEFT JOIN prod.VariedadCultivo V ON V.variedad_cultivo_id=D.variedadId
         WHERE V.variedad_cultivo_id IS NULL OR V.cultivo_id<>@Cultivo OR V.estado<>1)
    OR (SELECT COALESCE(SUM(superficieM2),0) FROM @V)>COALESCE(@SuperficieExacta,0)
    THROW 51103,N'La superficie por variedad excede la superficie sembrada o no corresponde al cultivo.',1;
 IF @Rubro='CULTIVO' AND @RazasJson IS NOT NULL AND @RazasJson<>N'[]' 
  THROW 51103,N'Un cultivo no puede tener razas.',1;
 DECLARE @Predio BIGINT;
 SELECT @Predio=P.predio_id FROM prod.Parcela P
 JOIN prod.PredioAmbito B ON B.predio_id=P.predio_id AND B.uot_id=@Uot
  AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
 WHERE P.parcela_id=@Parcela AND P.estado=1;
 IF @Predio IS NULL THROW 51102,N'Parcela fuera del ámbito general.',1;
 BEGIN TRAN;
 BEGIN TRY
  DECLARE @Id BIGINT,@Censo BIGINT;
  SELECT @Id=actividad_id FROM prod.GPActividad WITH(UPDLOCK,HOLDLOCK) WHERE solicitud_id=@Solicitud;
  IF @Id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.GPActividad WHERE actividad_id=@Id AND parcela_id=@Parcela AND uot_id=@Uot)
   THROW 51103,N'Clave de solicitud usada en otra actividad.',1;
  IF @Id IS NULL
  BEGIN
   -- Bloqueo de la parcela para serializar el control de superficie.
   IF @Rubro='CULTIVO'
   BEGIN
    DECLARE @LimiteM2 DECIMAL(18,2),@OcupadaM2 DECIMAL(18,2);
    SELECT @LimiteM2=CONVERT(DECIMAL(18,2),P.area_ha)*10000
      FROM prod.Parcela P WITH(UPDLOCK,HOLDLOCK) WHERE P.parcela_id=@Parcela;
    SELECT @OcupadaM2=COALESCE(SUM(COALESCE(C.superficie_exacta_m2,C.superficie_aproximada_m2,0)),0)
     FROM prod.GPActividad A
     OUTER APPLY(SELECT TOP(1) C.superficie_exacta_m2,C.superficie_aproximada_m2
                 FROM prod.GPCenso C WHERE C.actividad_id=A.actividad_id
                 ORDER BY C.fecha_registro DESC,C.censo_id DESC) C
     WHERE A.parcela_id=@Parcela AND A.estado=1 AND A.rubro='CULTIVO';
    IF @LimiteM2 IS NULL OR @OcupadaM2+@SuperficieExacta>@LimiteM2
      THROW 51103,N'La superficie sembrada supera el área disponible de la parcela.',1;
   END;
   INSERT prod.GPActividad(parcela_id,predio_id,uot_id,rubro,cultivo_id,especie_pecuaria_id,variedad_cultivo_id,nombre,
      fecha_inicio,usuario_creacion_id,solicitud_id)
   VALUES(@Parcela,@Predio,@Uot,@Rubro,@Cultivo,@Especie,@Variedad,NULL,
      CONVERT(DATE,(SYSUTCDATETIME() AT TIME ZONE 'UTC') AT TIME ZONE 'SA Pacific Standard Time'),@Usuario,@Solicitud);
   SET @Id=CONVERT(BIGINT,SCOPE_IDENTITY());
   INSERT prod.GPCenso(actividad_id,cantidad,aproximado,fecha,observacion,
      cantidad_aproximada,cantidad_exacta,superficie_aproximada_m2,superficie_exacta_m2,
      usuario_creacion_id,solicitud_id)
   VALUES(@Id,COALESCE(@CantidadAproximada,@CantidadExacta),
      CASE WHEN @Rubro='CULTIVO' THEN NULL WHEN @CantidadAproximada IS NULL THEN 0 ELSE 1 END,
      CONVERT(DATE,(SYSUTCDATETIME() AT TIME ZONE 'UTC') AT TIME ZONE 'SA Pacific Standard Time'),
      NULL,@CantidadAproximada,@CantidadExacta,@SuperficieAprox,@SuperficieExacta,@Usuario,NEWID());
   SET @Censo=CONVERT(BIGINT,SCOPE_IDENTITY());
   INSERT prod.GPCensoRaza(censo_id,raza_id,cantidad_aproximada,cantidad_exacta)
   SELECT @Censo,razaId,NULL,cantidadExacta FROM @R;
   INSERT prod.GPCensoVariedad(censo_id,variedad_cultivo_id,superficie_m2)
   SELECT @Censo,variedadId,superficieM2 FROM @V;
  END;
  COMMIT;
  SELECT @Id AS id;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
IF OBJECT_ID(N'prod.PA_GP_Censo_Ins_Registro', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Censo_Ins_Registro;
GO
CREATE PROCEDURE prod.PA_GP_Censo_Ins_Registro
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT,
 @CantidadAproximada INT=NULL,@CantidadExacta INT=NULL,
 @SuperficieAprox DECIMAL(14,2)=NULL,@SuperficieExacta DECIMAL(14,2)=NULL,
 @RazasJson NVARCHAR(MAX)=NULL,@Observacion NVARCHAR(1000),
 @VersionAnteriorId BIGINT=NULL,@Solicitud UNIQUEIDENTIFIER,
 @VariedadesJson NVARCHAR(MAX)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CENSOS_CREAR',1)<>1
  THROW 51101,N'Acceso no autorizado.',1;
 IF @Solicitud IS NULL OR LEN(TRIM(COALESCE(@Observacion,N'')))<3
  THROW 51103,N'Debe explicar el motivo de la nueva versión.',1;
 DECLARE @Rubro VARCHAR(8),@Especie INT,@Cultivo INT,@Parcela BIGINT;
 SELECT @Rubro=A.rubro,@Especie=A.especie_pecuaria_id,@Cultivo=A.cultivo_id,@Parcela=A.parcela_id FROM prod.GPActividad A
 JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot
  AND B.convenio_uot_organizacion_id IS NULL AND B.estado=1
 WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot AND A.estado=1;
 IF @Rubro IS NULL THROW 51102,N'Actividad fuera del ámbito general.',1;
 IF (@Rubro='CULTIVO' AND ((@SuperficieExacta IS NULL OR @SuperficieExacta<=0 OR @SuperficieAprox IS NOT NULL)
     OR @CantidadAproximada IS NOT NULL OR @CantidadExacta IS NOT NULL))
    OR (@Rubro='CRIANZA' AND ((@CantidadExacta IS NULL OR @CantidadExacta<=0 OR @CantidadAproximada IS NOT NULL)
     OR @SuperficieAprox IS NOT NULL OR @SuperficieExacta IS NOT NULL))
    OR (@CantidadAproximada IS NOT NULL AND @CantidadAproximada<0)
    OR (@CantidadExacta IS NOT NULL AND @CantidadExacta<0)
    OR (@SuperficieAprox IS NOT NULL AND @SuperficieAprox<0)
    OR (@SuperficieExacta IS NOT NULL AND @SuperficieExacta<0)
  THROW 51103,N'Ingrese una cantidad o superficie exacta válida.',1;
 IF @VariedadesJson IS NOT NULL AND ISJSON(@VariedadesJson)<>1
  THROW 51103,N'Detalle de variedades inválido.',1;
 IF @RazasJson IS NOT NULL AND ISJSON(@RazasJson)<>1
  THROW 51103,N'Detalle de razas inválido.',1;
 DECLARE @R TABLE(razaId INT,cantidadAproximada INT,cantidadExacta INT);
 IF @Rubro='CRIANZA' AND @RazasJson IS NOT NULL
  INSERT @R SELECT razaId,cantidadAproximada,cantidadExacta FROM OPENJSON(@RazasJson)
  WITH(razaId INT '$.razaId',cantidadAproximada INT '$.cantidadAproximada',cantidadExacta INT '$.cantidadExacta');
 IF (@Rubro='CULTIVO' AND @RazasJson IS NOT NULL AND @RazasJson<>N'[]')
    OR EXISTS(SELECT 1 FROM @R WHERE razaId IS NULL OR cantidadExacta IS NULL OR cantidadAproximada IS NOT NULL OR cantidadExacta<0)
    OR EXISTS(SELECT 1 FROM @R GROUP BY razaId HAVING COUNT(*)>1)
    OR EXISTS(SELECT 1 FROM @R D LEFT JOIN prod.GPRaza R ON R.raza_id=D.razaId
        WHERE R.raza_id IS NULL OR R.especie_pecuaria_id<>@Especie OR R.estado=0)
    OR (@CantidadExacta IS NOT NULL AND (SELECT COALESCE(SUM(cantidadExacta),0) FROM @R)>@CantidadExacta)

  THROW 51103,N'Detalle de razas inválido o mayor al total.',1;
 DECLARE @V TABLE(variedadId BIGINT PRIMARY KEY,superficieM2 DECIMAL(14,2));
 IF @Rubro='CULTIVO' AND @VariedadesJson IS NOT NULL
 BEGIN
   IF EXISTS(SELECT 1 FROM OPENJSON(@VariedadesJson) WITH(variedadId BIGINT '$.variedadId',superficieM2 DECIMAL(14,2) '$.superficieM2')
      WHERE variedadId IS NULL OR superficieM2 IS NULL OR superficieM2<=0)
      THROW 51103,N'Detalle de variedades inválido.',1;
   IF EXISTS(SELECT variedadId FROM OPENJSON(@VariedadesJson) WITH(variedadId BIGINT '$.variedadId') GROUP BY variedadId HAVING COUNT(*)>1)
      THROW 51103,N'No repita variedades.',1;
   INSERT @V SELECT variedadId,superficieM2 FROM OPENJSON(@VariedadesJson)
      WITH(variedadId BIGINT '$.variedadId',superficieM2 DECIMAL(14,2) '$.superficieM2');
 END;
 IF (@Rubro='CRIANZA' AND @VariedadesJson IS NOT NULL AND @VariedadesJson<>N'[]')
   OR EXISTS(SELECT 1 FROM @V D LEFT JOIN prod.VariedadCultivo V ON V.variedad_cultivo_id=D.variedadId
         WHERE V.variedad_cultivo_id IS NULL OR V.cultivo_id<>@Cultivo OR V.estado<>1)
   OR (SELECT COALESCE(SUM(superficieM2),0) FROM @V)>COALESCE(@SuperficieExacta,0)
     THROW 51103,N'Las variedades no corresponden al cultivo o exceden su superficie.',1;
 BEGIN TRAN;
 BEGIN TRY
  DECLARE @Id BIGINT,@Ultimo BIGINT,@Bloqueo BIGINT;
  SELECT @Id=censo_id FROM prod.GPCenso WITH(UPDLOCK,HOLDLOCK) WHERE solicitud_id=@Solicitud;
  IF @Id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.GPCenso WHERE censo_id=@Id AND actividad_id=@Actividad)
   THROW 51103,N'Solicitud correspondiente a otra actividad.',1;
  IF @Id IS NULL
  BEGIN
   IF @Rubro='CULTIVO'
   BEGIN
     DECLARE @LimiteM2 DECIMAL(18,2),@OcupadaM2 DECIMAL(18,2);
     SELECT @LimiteM2=CONVERT(DECIMAL(18,2),P.area_ha)*10000
       FROM prod.Parcela P WITH(UPDLOCK,HOLDLOCK) WHERE P.parcela_id=@Parcela;
     SELECT @OcupadaM2=COALESCE(SUM(COALESCE(C.superficie_exacta_m2,C.superficie_aproximada_m2,0)),0)
       FROM prod.GPActividad A
       OUTER APPLY(SELECT TOP(1) C.superficie_exacta_m2,C.superficie_aproximada_m2
          FROM prod.GPCenso C WHERE C.actividad_id=A.actividad_id
          ORDER BY C.fecha_registro DESC,C.censo_id DESC) C
       WHERE A.parcela_id=@Parcela AND A.actividad_id<>@Actividad AND A.estado=1 AND A.rubro='CULTIVO';
     IF @LimiteM2 IS NULL OR @OcupadaM2+@SuperficieExacta>@LimiteM2
       THROW 51103,N'La superficie sembrada supera el área de la parcela.',1;
   END;
   SELECT @Bloqueo=actividad_id FROM prod.GPActividad WITH(UPDLOCK,HOLDLOCK) WHERE actividad_id=@Actividad;
   SELECT TOP (1) @Ultimo=censo_id FROM prod.GPCenso
    WHERE actividad_id=@Actividad ORDER BY fecha_registro DESC,censo_id DESC;
   IF (@Ultimo IS NULL AND @VersionAnteriorId IS NOT NULL)
      OR (@Ultimo IS NOT NULL AND COALESCE(@VersionAnteriorId,-1)<>@Ultimo)
    THROW 51109,N'La medición cambió. Actualice la información antes de guardar.',1;
   INSERT prod.GPCenso(actividad_id,cantidad,aproximado,fecha,observacion,
      cantidad_aproximada,cantidad_exacta,superficie_aproximada_m2,superficie_exacta_m2,
      usuario_creacion_id,solicitud_id)
   VALUES(@Actividad,COALESCE(@CantidadAproximada,@CantidadExacta),
      CASE WHEN @Rubro='CULTIVO' THEN NULL WHEN @CantidadAproximada IS NULL THEN 0 ELSE 1 END,
      CONVERT(DATE,(SYSUTCDATETIME() AT TIME ZONE 'UTC') AT TIME ZONE 'SA Pacific Standard Time'),
      TRIM(@Observacion),@CantidadAproximada,@CantidadExacta,@SuperficieAprox,@SuperficieExacta,@Usuario,@Solicitud);
   SET @Id=CONVERT(BIGINT,SCOPE_IDENTITY());
   INSERT prod.GPCensoRaza(censo_id,raza_id,cantidad_aproximada,cantidad_exacta)
   SELECT @Id,razaId,NULL,cantidadExacta FROM @R;
   INSERT prod.GPCensoVariedad(censo_id,variedad_cultivo_id,superficie_m2)
   SELECT @Id,variedadId,superficieM2 FROM @V;
  END;
  COMMIT;
  SELECT @Id AS id;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
IF OBJECT_ID(N'prod.PA_GP_Foto_Ins_Registro', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Foto_Ins_Registro;
GO
CREATE PROCEDURE prod.PA_GP_Foto_Ins_Registro
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Evento BIGINT,
 @Archivo VARCHAR(65),@Mime VARCHAR(30),@Tamano BIGINT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF @Tamano NOT BETWEEN 1 AND 5242880 OR @Mime NOT IN('image/jpeg','image/png','image/webp')
    THROW 51103,N'La fotografía no cumple las restricciones.',1;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'SANIDAD_CREAR',1)<>1
    AND prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'EVALUACIONES_CREAR',1)<>1
    AND prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'PREDIOS_EDITAR',1)<>1
    THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPEvento E
    JOIN prod.GPActividad A ON A.actividad_id=E.actividad_id AND A.uot_id=@Uot
    JOIN prod.PredioAmbito P ON P.predio_id=A.predio_id AND P.uot_id=@Uot AND P.estado=1 AND P.convenio_uot_organizacion_id IS NULL
    WHERE E.evento_id=@Evento AND E.usuario_creacion_id=@Usuario)
    THROW 51102,N'Actuación no autorizada para asociar fotografía.',1;
 BEGIN TRAN;
 INSERT prod.GPEventoFoto(evento_id,archivo_interno,mime_type,tamano_bytes,usuario_creacion_id)
 VALUES(@Evento,@Archivo,@Mime,@Tamano,@Usuario);
 SELECT CONVERT(BIGINT,SCOPE_IDENTITY()) AS id;
 COMMIT;
END;
GO
IF OBJECT_ID(N'prod.PA_GP_Evento_Sel_Historial', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Evento_Sel_Historial;
GO
CREATE PROCEDURE prod.PA_GP_Evento_Sel_Historial
@Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT
AS
BEGIN
  SET NOCOUNT ON;
IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'PREDIOS_VER',0)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPActividad A JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.predio_id=A.predio_id JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot AND B.convenio_uot_organizacion_id IS NULL AND B.estado=1 WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot) THROW 51102,N'Actividad fuera del ámbito general.',1;
 SELECT E.evento_id AS eventoId,E.actividad_id AS actividadId,E.tipo,E.observacion,E.fecha_hecho AS fechaHecho,
 E.fecha_registro AS fechaRegistro,E.usuario_creacion_id AS usuarioId,E.respuesta_a_id AS respuestaAId,
 E.problema_id AS problemaId,P.nombre AS problema,E.tratamiento_id AS tratamientoId,T.nombre AS tratamiento,
 E.cantidad_afectada AS cantidadAfectada,E.afectados_aproximado AS afectadosAproximado,
 F.foto_id AS fotoId
 FROM prod.GPEvento E LEFT JOIN prod.GPProblema P ON P.problema_id=E.problema_id
 LEFT JOIN prod.GPTratamiento T ON T.tratamiento_id=E.tratamiento_id
 OUTER APPLY(SELECT TOP (1) F.foto_id FROM prod.GPEventoFoto F
   WHERE F.evento_id=E.evento_id ORDER BY F.foto_id) F
 WHERE E.actividad_id=@Actividad ORDER BY E.fecha_hecho DESC,E.evento_id DESC;
END;
GO
IF OBJECT_ID(N'prod.PA_GP_CensoVariedad_Sel_Historial', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_CensoVariedad_Sel_Historial;
GO
CREATE PROCEDURE prod.PA_GP_CensoVariedad_Sel_Historial
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CENSOS_LISTAR',0)<>1
   THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPActividad A JOIN prod.PredioAmbito B
   ON B.predio_id=A.predio_id AND B.uot_id=@Uot AND B.estado=1
    AND B.convenio_uot_organizacion_id IS NULL
   WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot)
   THROW 51102,N'Actividad fuera del ámbito general.',1;
 SELECT C.censo_id AS censoId,V.variedad_cultivo_id AS variedadId,
   V.nombre,D.superficie_m2 AS superficieM2
 FROM prod.GPCenso C JOIN prod.GPCensoVariedad D ON D.censo_id=C.censo_id
 JOIN prod.VariedadCultivo V ON V.variedad_cultivo_id=D.variedad_cultivo_id
 WHERE C.actividad_id=@Actividad ORDER BY C.censo_id DESC,V.nombre;
END;
GO
IF OBJECT_ID(N'prod.PA_GP_EventoFoto_Sel_Listado', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_EventoFoto_Sel_Listado;
GO
CREATE PROCEDURE prod.PA_GP_EventoFoto_Sel_Listado
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'PREDIOS_VER',0)<>1
    THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPActividad A JOIN prod.PredioAmbito B
   ON B.predio_id=A.predio_id AND B.uot_id=@Uot AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
   WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot)
    THROW 51102,N'Actividad fuera del ámbito general.',1;
 SELECT F.evento_id AS eventoId,F.foto_id AS fotoId
 FROM prod.GPEvento E JOIN prod.GPEventoFoto F ON F.evento_id=E.evento_id
 WHERE E.actividad_id=@Actividad ORDER BY F.evento_id,F.foto_id;
END;
GO
IF OBJECT_ID(N'prod.PA_GP_Parcela_Upd_Registro', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Parcela_Upd_Registro;
GO
CREATE PROCEDURE prod.PA_GP_Parcela_Upd_Registro
    @Sesion UNIQUEIDENTIFIER, @Usuario BIGINT, @Uot BIGINT, @Parcela BIGINT,
    @Nombre NVARCHAR(120), @Area DECIMAL(10,4), @Distrito CHAR(6),
    @Centro BIGINT = NULL, @Lat DECIMAL(9,6) = NULL, @Lon DECIMAL(9,6) = NULL,
    @Solicitud UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_EDITAR',1)<>1
        THROW 51101,N'Acceso no autorizado.',1;
    IF @Solicitud IS NULL OR NULLIF(TRIM(@Nombre),N'') IS NULL OR @Area IS NULL OR @Area<=0
       OR @Distrito IS NULL OR (@Lat IS NULL AND @Lon IS NOT NULL)
       OR (@Lat IS NOT NULL AND @Lon IS NULL)
       OR (@Lat IS NOT NULL AND (@Lat NOT BETWEEN -90 AND 90 OR @Lon NOT BETWEEN -180 AND 180))
        THROW 51103,N'Datos de parcela inválidos.',1;
    BEGIN TRAN;
    BEGIN TRY
        DECLARE @Id BIGINT, @Predio BIGINT, @Ubi BIGINT, @Ok BIT, @Msg NVARCHAR(300),
                @Limite DECIMAL(10,4),@Usado DECIMAL(18,4),@Bloqueo BIGINT;
        SELECT @Id=parcela_id FROM prod.GPParcelaSolicitud WITH(UPDLOCK,HOLDLOCK)
        WHERE solicitud_id=@Solicitud;
        IF @Id IS NOT NULL AND @Id<>@Parcela THROW 51103,N'Solicitud reutilizada para otra parcela.',1;
        SELECT @Predio=P.predio_id FROM prod.Parcela P WITH(UPDLOCK,HOLDLOCK)
          JOIN prod.PredioAmbito B ON B.predio_id=P.predio_id AND B.uot_id=@Uot
           AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
          WHERE P.parcela_id=@Parcela AND P.estado=1;
        IF @Predio IS NULL THROW 51102,N'Parcela fuera del ámbito general.',1;
        IF @Id IS NULL
        BEGIN
            SELECT @Bloqueo=predio_id FROM prod.Predio WITH(UPDLOCK,HOLDLOCK) WHERE predio_id=@Predio;
            SELECT TOP (1) @Limite=COALESCE(area_cultivable_ha,area_total_ha)
              FROM prod.PredioVersion WHERE predio_id=@Predio AND estado=1 AND fecha_hasta IS NULL
              ORDER BY fecha_desde DESC;
            SELECT @Usado=COALESCE(SUM(area_ha),0) FROM prod.Parcela
                WHERE predio_id=@Predio AND estado=1 AND parcela_id<>@Parcela;
            IF @Limite IS NOT NULL AND @Usado+@Area>@Limite
                BEGIN
                DECLARE @Restante DECIMAL(18,4)=CASE WHEN @Limite>@Usado THEN @Limite-@Usado ELSE 0 END;
                DECLARE @AreaError NVARCHAR(2048)=CONCAT(N'La superficie excede las hectáreas disponibles para este predio. Disponible: ',CONVERT(NVARCHAR(40),@Restante),N' ha.');
                THROW 51103,@AreaError,1;
            END;
            DECLARE @AreaSembrada DECIMAL(18,2);
            SELECT @AreaSembrada=COALESCE(SUM(COALESCE(C.superficie_exacta_m2,C.superficie_aproximada_m2,0)),0)
              FROM prod.GPActividad A
              OUTER APPLY(SELECT TOP(1) C.superficie_exacta_m2,C.superficie_aproximada_m2
                 FROM prod.GPCenso C WHERE C.actividad_id=A.actividad_id
                 ORDER BY C.fecha_registro DESC,C.censo_id DESC) C
              WHERE A.parcela_id=@Parcela AND A.rubro='CULTIVO' AND A.estado=1;
            IF @AreaSembrada>@Area*10000
               THROW 51103,N'La nueva superficie de la parcela es menor a la superficie sembrada.',1;
            -- Una ubicación nueva evita modificar una geo.Ubicacion que otro recurso comparte.
            EXEC geo.PA_Ubicacion_Ins_Interna @Distrito,@Centro,NULL,@Lat,@Lon,NULL,
                @Ubi OUTPUT,@Ok OUTPUT,@Msg OUTPUT;
            IF COALESCE(@Ok,0)<>1
            BEGIN
                DECLARE @GeoError NVARCHAR(2048)=CASE
                    WHEN @Msg IN (N'El distrito seleccionado no está disponible.',N'Seleccione un distrito.',
                                  N'El centro poblado seleccionado no corresponde al distrito.',
                                  N'La ubicación seleccionada no es válida.') THEN @Msg
                    ELSE N'Ubicación geográfica inválida.' END;
                THROW 51103,@GeoError,1;
            END;
            UPDATE prod.Parcela SET nombre=TRIM(@Nombre),area_ha=@Area,ubicacion_id=@Ubi
                WHERE parcela_id=@Parcela;
            INSERT prod.GPParcelaSolicitud(solicitud_id,parcela_id,usuario_id)
                VALUES(@Solicitud,@Parcela,@Usuario);
        END;
        COMMIT;
        SELECT @Parcela AS id;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO
IF OBJECT_ID(N'prod.PA_GP_Actividad_Upd_Registro', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Actividad_Upd_Registro;
GO
CREATE PROCEDURE prod.PA_GP_Actividad_Upd_Registro
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT,
 @Nombre NVARCHAR(120)=NULL,@Estado BIT,@Motivo NVARCHAR(1000),@Solicitud UNIQUEIDENTIFIER
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_EDITAR',1)<>1
    THROW 51101,N'Acceso no autorizado.',1;
 IF @Solicitud IS NULL OR @Estado IS NULL OR LEN(TRIM(COALESCE(@Motivo,N'')))<3
    THROW 51103,N'El motivo del cambio es obligatorio.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPActividad A JOIN prod.Parcela P
    ON P.parcela_id=A.parcela_id AND P.predio_id=A.predio_id
    JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot
    AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
    WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot)
    THROW 51102,N'Actividad fuera del ámbito general.',1;
 BEGIN TRAN;
 BEGIN TRY
  DECLARE @Id BIGINT,@Anterior NVARCHAR(120),@AnteriorEstado BIT,@Nuevo NVARCHAR(120)=NULLIF(TRIM(@Nombre),N'');
  SELECT @Id=revision_id FROM prod.GPActividadRevision WITH(UPDLOCK,HOLDLOCK)
   WHERE solicitud_id=@Solicitud;
  IF @Id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.GPActividadRevision
     WHERE revision_id=@Id AND actividad_id=@Actividad)
     THROW 51103,N'Solicitud perteneciente a otro expediente.',1;
  IF @Id IS NULL
  BEGIN
    DECLARE @ParcelaId BIGINT,@ParcelaM2 DECIMAL(18,2),@RubroActual VARCHAR(8),@SuperficieM2 DECIMAL(18,2),@UsadoM2 DECIMAL(18,2);
    SELECT @ParcelaId=A.parcela_id,@RubroActual=A.rubro FROM prod.GPActividad A WHERE A.actividad_id=@Actividad;
    SELECT @ParcelaM2=CONVERT(DECIMAL(18,2),P.area_ha)*10000
       FROM prod.Parcela P WITH(UPDLOCK,HOLDLOCK) WHERE P.parcela_id=@ParcelaId;
    SELECT @Anterior=nombre,@AnteriorEstado=estado FROM prod.GPActividad WITH(UPDLOCK,HOLDLOCK)
     WHERE actividad_id=@Actividad;
    IF @Estado=1 AND @AnteriorEstado=0 AND @RubroActual='CULTIVO'
    BEGIN
       SELECT TOP(1) @SuperficieM2=COALESCE(C.superficie_exacta_m2,C.superficie_aproximada_m2,0)
          FROM prod.GPCenso C WHERE C.actividad_id=@Actividad
          ORDER BY C.fecha_registro DESC,C.censo_id DESC;
       SELECT @UsadoM2=COALESCE(SUM(COALESCE(C.superficie_exacta_m2,C.superficie_aproximada_m2,0)),0)
         FROM prod.GPActividad A
         OUTER APPLY (SELECT TOP(1) C.superficie_exacta_m2,C.superficie_aproximada_m2
            FROM prod.GPCenso C WHERE C.actividad_id=A.actividad_id
            ORDER BY C.fecha_registro DESC,C.censo_id DESC) C
         WHERE A.parcela_id=@ParcelaId AND A.rubro='CULTIVO' AND A.estado=1 AND A.actividad_id<>@Actividad;
       IF @ParcelaM2 IS NULL OR @UsadoM2+COALESCE(@SuperficieM2,0)>@ParcelaM2
          THROW 51103,N'La superficie sembrada supera el área de la parcela.',1;
    END;
    IF (COALESCE(@Anterior,N'')=COALESCE(@Nuevo,N'') AND @AnteriorEstado=@Estado)
     THROW 51103,N'No hay cambios para registrar.',1;
    UPDATE prod.GPActividad SET nombre=@Nuevo,estado=@Estado WHERE actividad_id=@Actividad;
    INSERT prod.GPActividadRevision(actividad_id,nombre_anterior,nombre_nuevo,
      estado_anterior,estado_nuevo,motivo,usuario_id,solicitud_id)
    VALUES(@Actividad,@Anterior,@Nuevo,@AnteriorEstado,@Estado,TRIM(@Motivo),@Usuario,@Solicitud);
  END;
  COMMIT;
  SELECT @Actividad AS id;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
