-- DESCO GP | migracion aditiva, historiales inmutables.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_Incidencia_Ins_Registro;
GO
IF OBJECT_ID(N'prod.PA_GP_Incidencia_Ins_Registro', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Incidencia_Ins_Registro;
GO
CREATE PROCEDURE prod.PA_GP_Incidencia_Ins_Registro
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT,
 @Problema INT,@AfectadaM2 DECIMAL(14,2)=NULL,@AfectadosAnimales INT=NULL,
 @Descripcion NVARCHAR(2000),@Solicitud UNIQUEIDENTIFIER
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'SANIDAD_CREAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF @Solicitud IS NULL OR LEN(TRIM(COALESCE(@Descripcion,N'')))<3 THROW 51103,N'Explique la actuación.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPActividad A
 JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.estado=1
 JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
 WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot AND A.estado=1 AND A.estado_proceso='ACTIVA')
 THROW 51102,N'Actividad no disponible.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPProblema P JOIN prod.GPActividad A ON A.actividad_id=@Actividad
 WHERE P.problema_id=@Problema AND P.estado=1 AND
 ((A.rubro='CULTIVO' AND P.cultivo_id=A.cultivo_id) OR (A.rubro='CRIANZA' AND P.especie_pecuaria_id=A.especie_pecuaria_id)))
 THROW 51103,N'La enfermedad no corresponde a la actividad.',1;
 BEGIN TRAN;
 BEGIN TRY
  DECLARE @Id BIGINT,@Parcela BIGINT,@Rubro VARCHAR(8),@ActualM2 DECIMAL(14,2),@ActualAnimales INT;
  SELECT @Parcela=parcela_id,@Rubro=rubro FROM prod.GPActividad WHERE actividad_id=@Actividad;
  SELECT @Parcela=parcela_id FROM prod.Parcela WITH(UPDLOCK,HOLDLOCK) WHERE parcela_id=@Parcela;
  IF NOT EXISTS(SELECT 1 FROM prod.GPActividad WHERE actividad_id=@Actividad AND estado=1 AND estado_proceso='ACTIVA') THROW 51103,N'La actividad ya no está activa.',1;
  SELECT TOP(1) @ActualM2=superficie_exacta_m2,@ActualAnimales=cantidad_exacta
  FROM prod.GPCenso WHERE actividad_id=@Actividad ORDER BY fecha_registro DESC,censo_id DESC;
  IF (@Rubro='CULTIVO' AND (@AfectadaM2 IS NULL OR @AfectadaM2<=0 OR @AfectadosAnimales IS NOT NULL OR @AfectadaM2>COALESCE(@ActualM2,0)))
   OR (@Rubro='CRIANZA' AND (@AfectadosAnimales IS NULL OR @AfectadosAnimales<=0 OR @AfectadaM2 IS NOT NULL OR @AfectadosAnimales>COALESCE(@ActualAnimales,0)))
    THROW 51103,N'La afectación supera las existencias actuales.',1;
  SELECT @Id=evento_id FROM prod.GPEvento WITH(UPDLOCK,HOLDLOCK) WHERE solicitud_id=@Solicitud;
  IF @Id IS NULL
  BEGIN
   INSERT prod.GPEvento(actividad_id,tipo,problema_id,observacion,fecha_hecho,
     usuario_creacion_id,solicitud_id,cantidad_afectada,afectados_aproximado)
   VALUES(@Actividad,'INCIDENCIA',@Problema,TRIM(@Descripcion),SYSUTCDATETIME(),@Usuario,@Solicitud,@AfectadosAnimales,
     CASE WHEN @AfectadosAnimales IS NULL THEN NULL ELSE 0 END);
   SET @Id=CONVERT(BIGINT,SCOPE_IDENTITY());
   INSERT prod.GPIncidencia(incidencia_id,actividad_id,problema_id,afectada_m2,afectados_animales)
   VALUES(@Id,@Actividad,@Problema,@AfectadaM2,@AfectadosAnimales);
  END
  ELSE IF NOT EXISTS(SELECT 1 FROM prod.GPIncidencia WHERE incidencia_id=@Id AND actividad_id=@Actividad)
    THROW 51103,N'La solicitud ya se utilizó en otra actuación.',1;
  COMMIT;
  SELECT @Id AS id;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
END;
GO
