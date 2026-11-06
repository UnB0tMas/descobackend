-- DESCO GP | migracion aditiva, historiales inmutables.
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
      @SuperficieAprox IS NOT NULL OR @SuperficieExacta IS NULL OR @SuperficieExacta<=0))
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
   -- La parcela reserva superficie para todas sus actividades activas.
   BEGIN
    DECLARE @LimiteM2 DECIMAL(18,2),@OcupadaM2 DECIMAL(18,2);
    SELECT @LimiteM2=CONVERT(DECIMAL(18,2),P.area_ha)*10000
      FROM prod.Parcela P WITH(UPDLOCK,HOLDLOCK) WHERE P.parcela_id=@Parcela;
    SELECT @OcupadaM2=COALESCE(SUM(COALESCE(C.superficie_exacta_m2,C.superficie_aproximada_m2,0)),0)
     FROM prod.GPActividad A
     OUTER APPLY(SELECT TOP(1) C.superficie_exacta_m2,C.superficie_aproximada_m2
                 FROM prod.GPCenso C WHERE C.actividad_id=A.actividad_id
                 ORDER BY C.fecha_registro DESC,C.censo_id DESC) C
     WHERE A.parcela_id=@Parcela AND A.estado=1 AND A.estado_proceso='ACTIVA' AND A.rubro IN('CULTIVO','CRIANZA');
    IF @LimiteM2 IS NULL OR @OcupadaM2+@SuperficieExacta>@LimiteM2
      THROW 51103,N'Las actividades superan la superficie disponible de la parcela.',1;
   END;
   -- Identidad productiva: una misma parcela no duplica el mismo cultivo y variedad
   -- (ni especie y raza) mientras el ciclo está activo. Diferentes variedades/razas
   -- se permiten; un lote sin desglose se considera ambiguo y bloquea repetición.
   IF EXISTS(
     SELECT 1 FROM prod.GPActividad A
     OUTER APPLY (SELECT TOP(1) C.censo_id FROM prod.GPCenso C
       WHERE C.actividad_id=A.actividad_id AND C.estado=1
       ORDER BY C.fecha_registro DESC,C.censo_id DESC) Ultima
     WHERE A.parcela_id=@Parcela AND A.uot_id=@Uot AND A.estado=1 AND A.estado_proceso='ACTIVA'
       AND (
         (@Rubro='CULTIVO' AND A.rubro='CULTIVO' AND A.cultivo_id=@Cultivo
           AND (NOT EXISTS(SELECT 1 FROM @V)
             OR NOT EXISTS(SELECT 1 FROM prod.GPCensoVariedad D WHERE D.censo_id=Ultima.censo_id)
             OR EXISTS(SELECT 1 FROM prod.GPCensoVariedad D JOIN @V V
                 ON V.variedadId=D.variedad_cultivo_id WHERE D.censo_id=Ultima.censo_id)
             OR EXISTS(SELECT 1 FROM @V V WHERE V.variedadId=A.variedad_cultivo_id)))
         OR
         (@Rubro='CRIANZA' AND A.rubro='CRIANZA' AND A.especie_pecuaria_id=@Especie
           AND (NOT EXISTS(SELECT 1 FROM @R)
             OR NOT EXISTS(SELECT 1 FROM prod.GPCensoRaza D WHERE D.censo_id=Ultima.censo_id)
             OR EXISTS(SELECT 1 FROM prod.GPCensoRaza D JOIN @R R
                 ON R.razaId=D.raza_id WHERE D.censo_id=Ultima.censo_id)))
       )
   )
    THROW 51103,N'Ya existe una actividad activa del mismo cultivo/variedad o especie/raza. Actualiza la existente o diferencia el desglose.',1;
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
