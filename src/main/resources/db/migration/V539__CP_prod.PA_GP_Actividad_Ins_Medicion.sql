SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_Actividad_Ins_Registro;
GO
IF OBJECT_ID(N'prod.PA_GP_Actividad_Ins_Registro', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Actividad_Ins_Registro;
GO
CREATE PROCEDURE prod.PA_GP_Actividad_Ins_Registro
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Parcela BIGINT,
 @Rubro VARCHAR(8),@Cultivo INT=NULL,@Especie INT=NULL,
 @CantidadAproximada INT=NULL,@CantidadExacta INT=NULL,
 @SuperficieAprox DECIMAL(14,2)=NULL,@SuperficieExacta DECIMAL(14,2)=NULL,
 @RazasJson NVARCHAR(MAX)=NULL,@Solicitud UNIQUEIDENTIFIER
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
   INSERT prod.GPActividad(parcela_id,predio_id,uot_id,rubro,cultivo_id,especie_pecuaria_id,nombre,
      fecha_inicio,usuario_creacion_id,solicitud_id)
   VALUES(@Parcela,@Predio,@Uot,@Rubro,@Cultivo,@Especie,NULL,
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
