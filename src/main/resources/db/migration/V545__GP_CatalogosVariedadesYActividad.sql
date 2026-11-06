-- V496 — Gestión productiva: variedades, descripciones y mantenimiento de catálogos.
-- Conserva las mediciones versionadas y no elimina registros históricos.
IF COL_LENGTH('prod.VariedadCultivo','descripcion') IS NULL
 ALTER TABLE prod.VariedadCultivo ADD descripcion NVARCHAR(500) NULL;
GO
IF COL_LENGTH('prod.GPRaza','descripcion') IS NULL
 ALTER TABLE prod.GPRaza ADD descripcion NVARCHAR(500) NULL;
GO
IF COL_LENGTH('prod.GPActividad','variedad_cultivo_id') IS NULL
 ALTER TABLE prod.GPActividad ADD variedad_cultivo_id BIGINT NULL;
GO
IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name='FK_GPActividad_VariedadCultivo')
 ALTER TABLE prod.GPActividad ADD CONSTRAINT FK_GPActividad_VariedadCultivo FOREIGN KEY(variedad_cultivo_id)
 REFERENCES prod.VariedadCultivo(variedad_cultivo_id);
GO
IF OBJECT_ID(N'prod.PA_GP_Variedad_Ins_Catalogo', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Variedad_Ins_Catalogo;
GO
CREATE PROCEDURE prod.PA_GP_Variedad_Ins_Catalogo
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,
 @Cultivo INT,@Codigo VARCHAR(40),@Nombre NVARCHAR(120),@Descripcion NVARCHAR(500)=NULL
AS
BEGIN
 SET NOCOUNT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CATALOGOS_CREAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF @Cultivo IS NULL OR LEN(TRIM(COALESCE(@Codigo,'')))<2 OR LEN(TRIM(COALESCE(@Nombre,N'')))<2
   THROW 51103,N'Cultivo, código y variedad son obligatorios.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.Cultivo WHERE cultivo_id=@Cultivo AND estado=1)
   THROW 51103,N'Cultivo no disponible.',1;
 IF EXISTS(SELECT 1 FROM prod.VariedadCultivo WHERE cultivo_id=@Cultivo AND codigo=UPPER(TRIM(@Codigo)))
   THROW 51103,N'La variedad ya existe para este cultivo.',1;
 INSERT prod.VariedadCultivo(cultivo_id,codigo,nombre,descripcion)
 VALUES(@Cultivo,UPPER(TRIM(@Codigo)),TRIM(@Nombre),NULLIF(TRIM(@Descripcion),N''));
 SELECT CONVERT(BIGINT,SCOPE_IDENTITY()) AS id;
END;
GO
IF OBJECT_ID(N'prod.PA_GP_Raza_Ins_Catalogo', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Raza_Ins_Catalogo;
GO
CREATE PROCEDURE prod.PA_GP_Raza_Ins_Catalogo
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,
 @Especie INT,@Nombre NVARCHAR(120),@Descripcion NVARCHAR(500)=NULL
AS
BEGIN
 SET NOCOUNT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CATALOGOS_CREAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF @Especie IS NULL OR LEN(TRIM(COALESCE(@Nombre,N'')))<2 THROW 51103,N'Especie y raza obligatorias.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.EspeciePecuaria WHERE especie_pecuaria_id=@Especie AND estado=1)
   THROW 51103,N'La especie seleccionada no está activa.',1;
 IF EXISTS(SELECT 1 FROM prod.GPRaza WHERE especie_pecuaria_id=@Especie AND nombre=TRIM(@Nombre))
   THROW 51103,N'La raza ya existe para la especie.',1;
 INSERT prod.GPRaza(especie_pecuaria_id,nombre,descripcion,usuario_creacion_id)
 VALUES(@Especie,TRIM(@Nombre),NULLIF(TRIM(@Descripcion),N''),@Usuario);
 SELECT CONVERT(BIGINT,SCOPE_IDENTITY()) AS id;
END;
GO
IF OBJECT_ID(N'prod.PA_GP_Catalogo_Sel_Listado', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Catalogo_Sel_Listado;
GO
CREATE PROCEDURE prod.PA_GP_Catalogo_Sel_Listado
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'PREDIOS_VER',0)<>1
   AND prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CATALOGOS_LISTAR',0)<>1
   THROW 51101,N'Acceso no autorizado.',1;
 SELECT 'CULTIVO' tipo,CONVERT(BIGINT,cultivo_id) id,CONVERT(BIGINT,NULL) padreId,
 nombre COLLATE DATABASE_DEFAULT nombre,CONVERT(NVARCHAR(1000),NULL) descripcion,
 CONVERT(VARCHAR(40),codigo) COLLATE DATABASE_DEFAULT codigo FROM prod.Cultivo WHERE estado=1
 UNION ALL
 SELECT 'CRIANZA',CONVERT(BIGINT,especie_pecuaria_id),NULL,nombre COLLATE DATABASE_DEFAULT,NULL,
 CONVERT(VARCHAR(40),codigo) COLLATE DATABASE_DEFAULT FROM prod.EspeciePecuaria WHERE estado=1
 UNION ALL
 SELECT 'VARIEDAD',variedad_cultivo_id,CONVERT(BIGINT,cultivo_id),nombre COLLATE DATABASE_DEFAULT,
 CONVERT(NVARCHAR(1000),descripcion),codigo COLLATE DATABASE_DEFAULT FROM prod.VariedadCultivo WHERE estado=1
 UNION ALL
 SELECT 'RAZA',CONVERT(BIGINT,raza_id),CONVERT(BIGINT,especie_pecuaria_id),nombre COLLATE DATABASE_DEFAULT,
 CONVERT(NVARCHAR(1000),descripcion),CONVERT(VARCHAR(40),NULL) FROM prod.GPRaza WHERE estado=1
 UNION ALL
 SELECT 'PROBLEMA_CULTIVO',CONVERT(BIGINT,problema_id),CONVERT(BIGINT,cultivo_id),nombre COLLATE DATABASE_DEFAULT,
 NULL,NULL FROM prod.GPProblema WHERE cultivo_id IS NOT NULL AND estado=1
 UNION ALL
 SELECT 'PROBLEMA_CRIANZA',CONVERT(BIGINT,problema_id),CONVERT(BIGINT,especie_pecuaria_id),nombre COLLATE DATABASE_DEFAULT,
 NULL,NULL FROM prod.GPProblema WHERE especie_pecuaria_id IS NOT NULL AND estado=1
 UNION ALL
 SELECT 'TRATAMIENTO',CONVERT(BIGINT,tratamiento_id),NULL,nombre COLLATE DATABASE_DEFAULT,
 descripcion,NULL FROM prod.GPTratamiento WHERE estado=1
 UNION ALL
 SELECT 'RELACION',CONVERT(BIGINT,tratamiento_id),CONVERT(BIGINT,problema_id),CONVERT(NVARCHAR(160),NULL),NULL,NULL
 FROM prod.GPProblemaTratamiento
 ORDER BY tipo,nombre;
END;
GO
IF OBJECT_ID(N'prod.PA_GP_Catalogo_Upd_Registro', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Catalogo_Upd_Registro;
GO
CREATE PROCEDURE prod.PA_GP_Catalogo_Upd_Registro
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Tipo VARCHAR(24),@Id BIGINT,
 @Padre BIGINT=NULL,@Codigo VARCHAR(40)=NULL,@Nombre NVARCHAR(160)=NULL,
 @Descripcion NVARCHAR(1000)=NULL,@Estado BIT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CATALOGOS_EDITAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF @Id<1 OR @Estado IS NULL THROW 51103,N'Datos del catálogo inválidos.',1;
 IF @Tipo NOT IN ('CULTIVO','CRIANZA','VARIEDAD','RAZA','PROBLEMA_CULTIVO','PROBLEMA_CRIANZA','TRATAMIENTO','RELACION')
   THROW 51103,N'Tipo de catálogo no admitido.',1;
 IF @Estado=0 AND @Tipo='CULTIVO' AND EXISTS(SELECT 1 FROM prod.GPActividad WHERE cultivo_id=@Id AND estado=1)
   THROW 51103,N'No se puede desactivar un cultivo con actividades activas.',1;
 IF @Estado=0 AND @Tipo='CRIANZA' AND EXISTS(SELECT 1 FROM prod.GPActividad WHERE especie_pecuaria_id=@Id AND estado=1)
   THROW 51103,N'No se puede desactivar una especie con actividades activas.',1;
 IF @Estado=1 AND LEN(TRIM(COALESCE(@Nombre,N'')))<2 THROW 51103,N'Ingrese un nombre válido.',1;
 IF @Estado=1 AND @Tipo IN ('CULTIVO','CRIANZA','VARIEDAD') AND LEN(TRIM(COALESCE(@Codigo,'')))<2
   THROW 51103,N'Ingrese un código válido.',1;
 BEGIN TRAN;
 BEGIN TRY
  DECLARE @N INT=0;
  IF @Tipo='CULTIVO'
   UPDATE prod.Cultivo SET nombre=CASE WHEN @Estado=1 THEN TRIM(@Nombre) ELSE nombre END,
     codigo=CASE WHEN @Estado=1 THEN UPPER(TRIM(@Codigo)) ELSE codigo END,estado=@Estado WHERE cultivo_id=@Id;
  ELSE IF @Tipo='CRIANZA'
   UPDATE prod.EspeciePecuaria SET nombre=CASE WHEN @Estado=1 THEN TRIM(@Nombre) ELSE nombre END,
     codigo=CASE WHEN @Estado=1 THEN UPPER(TRIM(@Codigo)) ELSE codigo END,estado=@Estado WHERE especie_pecuaria_id=@Id;
  ELSE IF @Tipo='VARIEDAD'
   UPDATE prod.VariedadCultivo SET nombre=CASE WHEN @Estado=1 THEN TRIM(@Nombre) ELSE nombre END,
     codigo=CASE WHEN @Estado=1 THEN UPPER(TRIM(@Codigo)) ELSE codigo END,
     descripcion=CASE WHEN @Estado=1 THEN NULLIF(TRIM(@Descripcion),N'') ELSE descripcion END,
     estado=@Estado WHERE variedad_cultivo_id=@Id AND (@Padre IS NULL OR cultivo_id=@Padre);
  ELSE IF @Tipo='RAZA'
   UPDATE prod.GPRaza SET nombre=CASE WHEN @Estado=1 THEN TRIM(@Nombre) ELSE nombre END,
     descripcion=CASE WHEN @Estado=1 THEN NULLIF(TRIM(@Descripcion),N'') ELSE descripcion END,
     estado=@Estado WHERE raza_id=@Id AND (@Padre IS NULL OR especie_pecuaria_id=@Padre);
  ELSE IF @Tipo IN('PROBLEMA_CULTIVO','PROBLEMA_CRIANZA')
   UPDATE prod.GPProblema SET nombre=CASE WHEN @Estado=1 THEN TRIM(@Nombre) ELSE nombre END,
     estado=@Estado WHERE problema_id=@Id AND
     ((@Tipo='PROBLEMA_CULTIVO' AND cultivo_id IS NOT NULL) OR
      (@Tipo='PROBLEMA_CRIANZA' AND especie_pecuaria_id IS NOT NULL));
  ELSE IF @Tipo='TRATAMIENTO'
   UPDATE prod.GPTratamiento SET nombre=CASE WHEN @Estado=1 THEN TRIM(@Nombre) ELSE nombre END,
      descripcion=CASE WHEN @Estado=1 THEN NULLIF(TRIM(@Descripcion),N'') ELSE descripcion END,
      estado=@Estado WHERE tratamiento_id=@Id;
  ELSE IF @Tipo='RELACION' AND @Estado=0
   DELETE FROM prod.GPProblemaTratamiento WHERE tratamiento_id=@Id AND problema_id=@Padre;
  ELSE THROW 51103,N'La asociación se administra desde Nuevo valor.',1;
  SET @N=@@ROWCOUNT;
  IF @N<>1 THROW 51103,N'El registro no existe o no corresponde al catálogo.',1;
  COMMIT;
  SELECT @Id AS id;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'prod.PA_GP_Actividad_Ins_Registro', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Actividad_Ins_Registro;
GO
CREATE PROCEDURE prod.PA_GP_Actividad_Ins_Registro
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Parcela BIGINT,
 @Rubro VARCHAR(8),@Cultivo INT=NULL,@Especie INT=NULL,
 @CantidadAproximada INT=NULL,@CantidadExacta INT=NULL,
 @SuperficieAprox DECIMAL(14,2)=NULL,@SuperficieExacta DECIMAL(14,2)=NULL,
 @RazasJson NVARCHAR(MAX)=NULL,@Solicitud UNIQUEIDENTIFIER,@Variedad BIGINT=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_CREAR',1)<>1
  THROW 51101,N'Acceso no autorizado.',1;
 IF @Solicitud IS NULL OR @Rubro NOT IN('CULTIVO','CRIANZA')
   OR (@Rubro='CULTIVO' AND (@Cultivo IS NULL OR @Especie IS NOT NULL OR
      (@SuperficieAprox IS NULL AND @SuperficieExacta IS NULL) OR
      @CantidadAproximada IS NOT NULL OR @CantidadExacta IS NOT NULL))
   OR (@Rubro='CRIANZA' AND (@Especie IS NULL OR @Cultivo IS NOT NULL OR
      (@CantidadAproximada IS NULL AND @CantidadExacta IS NULL) OR
      @SuperficieAprox IS NOT NULL OR @SuperficieExacta IS NOT NULL))
   OR (@CantidadAproximada IS NOT NULL AND @CantidadAproximada<0)
   OR (@CantidadExacta IS NOT NULL AND @CantidadExacta<0)
   OR (@SuperficieAprox IS NOT NULL AND @SuperficieAprox<0)
   OR (@SuperficieExacta IS NOT NULL AND @SuperficieExacta<0)
  THROW 51103,N'Indique una medición exacta o aproximada compatible con el rubro.',1;
 IF @Rubro='CULTIVO' AND NOT EXISTS(SELECT 1 FROM prod.Cultivo WHERE cultivo_id=@Cultivo AND estado=1)
  THROW 51103,N'El cultivo no está disponible.',1;
 IF @Variedad IS NOT NULL AND (@Rubro<>'CULTIVO' OR NOT EXISTS(
    SELECT 1 FROM prod.VariedadCultivo V WHERE V.variedad_cultivo_id=@Variedad
      AND V.cultivo_id=@Cultivo AND V.estado=1))
    THROW 51103,N'La variedad no corresponde al cultivo.',1;
 IF @Rubro='CRIANZA' AND NOT EXISTS(SELECT 1 FROM prod.EspeciePecuaria WHERE especie_pecuaria_id=@Especie AND estado=1)
  THROW 51103,N'La especie no está disponible.',1;
 IF @RazasJson IS NOT NULL AND ISJSON(@RazasJson)<>1
  THROW 51103,N'Detalle de razas inválido.',1;
 DECLARE @R TABLE(razaId INT,cantidadAproximada INT,cantidadExacta INT);
 IF @Rubro='CRIANZA' AND @RazasJson IS NOT NULL
  INSERT @R SELECT razaId,cantidadAproximada,cantidadExacta FROM OPENJSON(@RazasJson)
  WITH(razaId INT '$.razaId',cantidadAproximada INT '$.cantidadAproximada',cantidadExacta INT '$.cantidadExacta');
 IF EXISTS(SELECT 1 FROM @R WHERE razaId IS NULL OR (cantidadAproximada IS NULL AND cantidadExacta IS NULL)
       OR cantidadAproximada<0 OR cantidadExacta<0)
   OR EXISTS(SELECT 1 FROM @R GROUP BY razaId HAVING COUNT(*)>1)
   OR EXISTS(SELECT 1 FROM @R D LEFT JOIN prod.GPRaza R ON R.raza_id=D.razaId
       WHERE R.raza_id IS NULL OR R.especie_pecuaria_id<>@Especie OR R.estado=0)
   OR (@CantidadExacta IS NOT NULL AND (SELECT COALESCE(SUM(cantidadExacta),0) FROM @R)>@CantidadExacta)
   OR (@CantidadAproximada IS NOT NULL AND (SELECT COALESCE(SUM(cantidadAproximada),0) FROM @R)>@CantidadAproximada)
  THROW 51103,N'Detalle de razas inválido o superior al total.',1;
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
   SELECT @Censo,razaId,cantidadAproximada,cantidadExacta FROM @R;
  END;
  COMMIT;
  SELECT @Id AS id;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'prod.PA_GP_Actividad_Sel_Listado', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Actividad_Sel_Listado;
GO
CREATE PROCEDURE prod.PA_GP_Actividad_Sel_Listado
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Parcela BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_VER',0)<>1
  THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.Parcela P JOIN prod.PredioAmbito B ON B.predio_id=P.predio_id
  AND B.uot_id=@Uot AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
  WHERE P.parcela_id=@Parcela)
  THROW 51102,N'Parcela fuera del ámbito general.',1;
 SELECT A.actividad_id AS actividadId,A.parcela_id AS parcelaId,A.predio_id AS predioId,
  A.rubro,A.cultivo_id AS cultivoId,A.especie_pecuaria_id AS especieId,
  A.variedad_cultivo_id AS variedadId,VC.nombre AS variedadNombre,
  COALESCE(A.nombre COLLATE DATABASE_DEFAULT,C.nombre COLLATE DATABASE_DEFAULT,E.nombre COLLATE DATABASE_DEFAULT) AS nombre,
  A.fecha_inicio AS fechaInicio,A.estado,
  CASE WHEN A.rubro='CRIANZA' THEN COALESCE(X.cantidad_aproximada,X.cantidad) ELSE NULL END AS cantidadAproximada,
  CASE WHEN A.rubro='CRIANZA' THEN X.cantidad_exacta ELSE NULL END AS cantidadExacta,
  X.superficie_aproximada_m2 AS superficieAproximadaM2,
  X.superficie_exacta_m2 AS superficieExactaM2,
  X.censo_id AS versionActualId,X.fecha AS fechaUltimoCenso
 FROM prod.GPActividad A
 LEFT JOIN prod.Cultivo C ON C.cultivo_id=A.cultivo_id
 LEFT JOIN prod.VariedadCultivo VC ON VC.variedad_cultivo_id=A.variedad_cultivo_id
 LEFT JOIN prod.EspeciePecuaria E ON E.especie_pecuaria_id=A.especie_pecuaria_id
 OUTER APPLY(SELECT TOP(1) N.cantidad_aproximada,N.cantidad_exacta,N.cantidad,
     N.superficie_aproximada_m2,N.superficie_exacta_m2,N.censo_id,N.fecha
   FROM prod.GPCenso N WHERE N.actividad_id=A.actividad_id
   ORDER BY N.fecha_registro DESC,N.censo_id DESC) X
 WHERE A.parcela_id=@Parcela AND A.uot_id=@Uot
 ORDER BY A.estado DESC,A.actividad_id DESC;
END;
GO
