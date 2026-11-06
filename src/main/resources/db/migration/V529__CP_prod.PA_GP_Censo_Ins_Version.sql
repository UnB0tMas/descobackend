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
 @CantidadAproximada INT,@CantidadExacta INT=NULL,@Observacion NVARCHAR(1000),
 @VersionAnteriorId BIGINT=NULL,@Solicitud UNIQUEIDENTIFIER
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CENSOS_CREAR',1)<>1
     THROW 51101,N'Acceso no autorizado.',1;
 IF @Solicitud IS NULL OR @CantidadAproximada IS NULL OR @CantidadAproximada<0
    OR (@CantidadExacta IS NOT NULL AND @CantidadExacta<0)
    OR LEN(TRIM(COALESCE(@Observacion,N'')))<3
    THROW 51103,N'Indique cantidad aproximada y motivo de actualización.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPActividad A
 JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.predio_id=A.predio_id
 JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot
 AND B.convenio_uot_organizacion_id IS NULL AND B.estado=1
 WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot AND A.estado=1)
    THROW 51102,N'Actividad fuera del ámbito general.',1;
 BEGIN TRAN;
 BEGIN TRY
  DECLARE @Id BIGINT,@Ultimo BIGINT;
  SELECT @Id=censo_id FROM prod.GPCenso WITH(UPDLOCK,HOLDLOCK) WHERE solicitud_id=@Solicitud;
  IF @Id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.GPCenso WHERE censo_id=@Id AND actividad_id=@Actividad)
      THROW 51103,N'Solicitud correspondiente a otra actividad.',1;
  IF @Id IS NULL
  BEGIN
   -- Serializa cambios simultáneos del mismo expediente.
   DECLARE @Bloqueo BIGINT;
   SELECT @Bloqueo=actividad_id FROM prod.GPActividad WITH(UPDLOCK,HOLDLOCK) WHERE actividad_id=@Actividad;
   SELECT TOP (1) @Ultimo=censo_id FROM prod.GPCenso
    WHERE actividad_id=@Actividad ORDER BY fecha_registro DESC,censo_id DESC;
   IF (@Ultimo IS NULL AND @VersionAnteriorId IS NOT NULL)
      OR (@Ultimo IS NOT NULL AND COALESCE(@VersionAnteriorId,-1)<>@Ultimo)
      THROW 51109,N'El conteo cambió desde su última consulta. Actualice la información.',1;
   INSERT prod.GPCenso(actividad_id,cantidad,aproximado,fecha,observacion,
     cantidad_aproximada,cantidad_exacta,usuario_creacion_id,solicitud_id)
   VALUES(@Actividad,@CantidadAproximada,1,
     CONVERT(DATE,(SYSUTCDATETIME() AT TIME ZONE 'UTC') AT TIME ZONE 'SA Pacific Standard Time'),
     TRIM(@Observacion),@CantidadAproximada,@CantidadExacta,@Usuario,@Solicitud);
   SET @Id=CONVERT(BIGINT,SCOPE_IDENTITY());
  END;
  COMMIT;
  SELECT @Id AS id;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
