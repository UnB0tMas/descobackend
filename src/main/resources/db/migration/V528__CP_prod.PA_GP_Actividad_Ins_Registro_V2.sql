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
 @CantidadAproximada INT,@CantidadExacta INT=NULL,@Solicitud UNIQUEIDENTIFIER
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_CREAR',1)<>1
     THROW 51101,N'Acceso no autorizado.',1;
 IF @Solicitud IS NULL OR @CantidadAproximada IS NULL OR @CantidadAproximada<0
     OR (@CantidadExacta IS NOT NULL AND @CantidadExacta<0)
     OR NOT ((@Rubro='CULTIVO' AND @Cultivo IS NOT NULL AND @Especie IS NULL)
         OR (@Rubro='CRIANZA' AND @Especie IS NOT NULL AND @Cultivo IS NULL))
     THROW 51103,N'El rubro y la cantidad aproximada son obligatorios.',1;
 IF @Rubro='CULTIVO' AND NOT EXISTS(SELECT 1 FROM prod.Cultivo WHERE cultivo_id=@Cultivo AND estado=1)
     THROW 51103,N'Cultivo no disponible.',1;
 IF @Rubro='CRIANZA' AND NOT EXISTS(SELECT 1 FROM prod.EspeciePecuaria WHERE especie_pecuaria_id=@Especie AND estado=1)
     THROW 51103,N'Especie no disponible.',1;
 DECLARE @Predio BIGINT;
 SELECT @Predio=P.predio_id FROM prod.Parcela P
 JOIN prod.PredioAmbito B ON B.predio_id=P.predio_id AND B.uot_id=@Uot
  AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
 WHERE P.parcela_id=@Parcela AND P.estado=1;
 IF @Predio IS NULL THROW 51102,N'Parcela fuera del ámbito general.',1;
 BEGIN TRAN;
 BEGIN TRY
  DECLARE @Id BIGINT;
  SELECT @Id=actividad_id FROM prod.GPActividad WITH(UPDLOCK,HOLDLOCK) WHERE solicitud_id=@Solicitud;
  IF @Id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.GPActividad WHERE actividad_id=@Id
       AND parcela_id=@Parcela AND uot_id=@Uot)
      THROW 51103,N'Clave de solicitud usada en otra actividad.',1;
  IF @Id IS NULL
  BEGIN
   INSERT prod.GPActividad(parcela_id,predio_id,uot_id,rubro,cultivo_id,
      especie_pecuaria_id,nombre,fecha_inicio,usuario_creacion_id,solicitud_id)
   VALUES(@Parcela,@Predio,@Uot,@Rubro,@Cultivo,@Especie,NULL,
      CONVERT(DATE,(SYSUTCDATETIME() AT TIME ZONE 'UTC') AT TIME ZONE 'SA Pacific Standard Time'),
      @Usuario,@Solicitud);
   SET @Id=CONVERT(BIGINT,SCOPE_IDENTITY());
   INSERT prod.GPCenso(actividad_id,cantidad,aproximado,fecha,observacion,
      cantidad_aproximada,cantidad_exacta,usuario_creacion_id,solicitud_id)
   VALUES(@Id,@CantidadAproximada,1,
      CONVERT(DATE,(SYSUTCDATETIME() AT TIME ZONE 'UTC') AT TIME ZONE 'SA Pacific Standard Time'),
      NULL,@CantidadAproximada,@CantidadExacta,@Usuario,NEWID());
  END;
  COMMIT;
  SELECT @Id AS id;
 END TRY BEGIN CATCH
   IF XACT_STATE()<>0 ROLLBACK;
   THROW;
 END CATCH;
END;
GO
