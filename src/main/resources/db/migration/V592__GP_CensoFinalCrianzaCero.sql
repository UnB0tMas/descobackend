-- Permite dejar cero animales antes del cierre; conserva las demás validaciones e historial.
-- DESCO GP | migracion aditiva, historiales inmutables.
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
 WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot AND A.estado=1 AND A.estado_proceso='ACTIVA';
 IF @Rubro IS NULL THROW 51102,N'Actividad fuera del ámbito general.',1;
 IF (@Rubro='CULTIVO' AND ((@SuperficieExacta IS NULL OR @SuperficieExacta<=0 OR @SuperficieAprox IS NOT NULL)
     OR @CantidadAproximada IS NOT NULL OR @CantidadExacta IS NOT NULL))
    OR (@Rubro='CRIANZA' AND ((@CantidadExacta IS NULL OR @CantidadExacta<0 OR @CantidadAproximada IS NOT NULL)
     OR @SuperficieAprox IS NOT NULL OR @SuperficieExacta IS NULL OR @SuperficieExacta<=0))
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
   -- Recalcular capacidad en cada versión, serializando altas por parcela.
   BEGIN
     DECLARE @LimiteM2 DECIMAL(18,2),@OcupadaM2 DECIMAL(18,2);
     SELECT @LimiteM2=CONVERT(DECIMAL(18,2),P.area_ha)*10000
       FROM prod.Parcela P WITH(UPDLOCK,HOLDLOCK) WHERE P.parcela_id=@Parcela;
     SELECT @OcupadaM2=COALESCE(SUM(COALESCE(C.superficie_exacta_m2,C.superficie_aproximada_m2,0)),0)
       FROM prod.GPActividad A
       OUTER APPLY(SELECT TOP(1) C.superficie_exacta_m2,C.superficie_aproximada_m2
          FROM prod.GPCenso C WHERE C.actividad_id=A.actividad_id
          ORDER BY C.fecha_registro DESC,C.censo_id DESC) C
       WHERE A.parcela_id=@Parcela AND A.actividad_id<>@Actividad AND A.estado=1 AND A.estado_proceso='ACTIVA' AND A.rubro IN('CULTIVO','CRIANZA');
     IF @LimiteM2 IS NULL OR @OcupadaM2+@SuperficieExacta>@LimiteM2
       THROW 51103,N'La suma de superficies de actividades supera el área de la parcela.',1;
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
