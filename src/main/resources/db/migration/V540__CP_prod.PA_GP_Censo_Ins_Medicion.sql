SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_Censo_Ins_Registro;
GO
IF OBJECT_ID(N'prod.PA_GP_Censo_Ins_Registro', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Censo_Ins_Registro;
GO
CREATE PROCEDURE prod.PA_GP_Censo_Ins_Registro
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT,
 @CantidadAproximada INT=NULL,@CantidadExacta INT=NULL,
 @SuperficieAprox DECIMAL(14,2)=NULL,@SuperficieExacta DECIMAL(14,2)=NULL,
 @RazasJson NVARCHAR(MAX)=NULL,@Observacion NVARCHAR(1000),
 @VersionAnteriorId BIGINT=NULL,@Solicitud UNIQUEIDENTIFIER
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CENSOS_CREAR',1)<>1
  THROW 51101,N'Acceso no autorizado.',1;
 IF @Solicitud IS NULL OR LEN(TRIM(COALESCE(@Observacion,N'')))<3
  THROW 51103,N'Debe explicar el motivo de la nueva versión.',1;
 DECLARE @Rubro VARCHAR(8),@Especie INT;
 SELECT @Rubro=A.rubro,@Especie=A.especie_pecuaria_id FROM prod.GPActividad A
 JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot
  AND B.convenio_uot_organizacion_id IS NULL AND B.estado=1
 WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot AND A.estado=1;
 IF @Rubro IS NULL THROW 51102,N'Actividad fuera del ámbito general.',1;
 IF (@Rubro='CULTIVO' AND ((@SuperficieAprox IS NULL AND @SuperficieExacta IS NULL)
     OR @CantidadAproximada IS NOT NULL OR @CantidadExacta IS NOT NULL))
    OR (@Rubro='CRIANZA' AND ((@CantidadAproximada IS NULL AND @CantidadExacta IS NULL)
     OR @SuperficieAprox IS NOT NULL OR @SuperficieExacta IS NOT NULL))
    OR (@CantidadAproximada IS NOT NULL AND @CantidadAproximada<0)
    OR (@CantidadExacta IS NOT NULL AND @CantidadExacta<0)
    OR (@SuperficieAprox IS NOT NULL AND @SuperficieAprox<0)
    OR (@SuperficieExacta IS NOT NULL AND @SuperficieExacta<0)
  THROW 51103,N'Indique medición exacta o aproximada según el tipo de actividad.',1;
 IF @RazasJson IS NOT NULL AND ISJSON(@RazasJson)<>1
  THROW 51103,N'Detalle de razas inválido.',1;
 DECLARE @R TABLE(razaId INT,cantidadAproximada INT,cantidadExacta INT);
 IF @Rubro='CRIANZA' AND @RazasJson IS NOT NULL
  INSERT @R SELECT razaId,cantidadAproximada,cantidadExacta FROM OPENJSON(@RazasJson)
  WITH(razaId INT '$.razaId',cantidadAproximada INT '$.cantidadAproximada',cantidadExacta INT '$.cantidadExacta');
 IF (@Rubro='CULTIVO' AND @RazasJson IS NOT NULL AND @RazasJson<>N'[]')
    OR EXISTS(SELECT 1 FROM @R WHERE razaId IS NULL OR (cantidadAproximada IS NULL AND cantidadExacta IS NULL)
       OR cantidadAproximada<0 OR cantidadExacta<0)
    OR EXISTS(SELECT 1 FROM @R GROUP BY razaId HAVING COUNT(*)>1)
    OR EXISTS(SELECT 1 FROM @R D LEFT JOIN prod.GPRaza R ON R.raza_id=D.razaId
        WHERE R.raza_id IS NULL OR R.especie_pecuaria_id<>@Especie OR R.estado=0)
    OR (@CantidadExacta IS NOT NULL AND (SELECT COALESCE(SUM(cantidadExacta),0) FROM @R)>@CantidadExacta)
    OR (@CantidadAproximada IS NOT NULL AND (SELECT COALESCE(SUM(cantidadAproximada),0) FROM @R)>@CantidadAproximada)
  THROW 51103,N'Detalle de razas inválido o mayor al total.',1;
 BEGIN TRAN;
 BEGIN TRY
  DECLARE @Id BIGINT,@Ultimo BIGINT,@Bloqueo BIGINT;
  SELECT @Id=censo_id FROM prod.GPCenso WITH(UPDLOCK,HOLDLOCK) WHERE solicitud_id=@Solicitud;
  IF @Id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.GPCenso WHERE censo_id=@Id AND actividad_id=@Actividad)
   THROW 51103,N'Solicitud correspondiente a otra actividad.',1;
  IF @Id IS NULL
  BEGIN
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
   SELECT @Id,razaId,cantidadAproximada,cantidadExacta FROM @R;
  END;
  COMMIT;
  SELECT @Id AS id;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
