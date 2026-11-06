SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'prod.PA_GP_Censo_Ins_Registro', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Censo_Ins_Registro;
GO
CREATE PROCEDURE prod.PA_GP_Censo_Ins_Registro
@Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT,@Cantidad INT=NULL,@Aproximado BIT=NULL,@Fecha DATE,@Observacion NVARCHAR(1000)=NULL,@Solicitud UNIQUEIDENTIFIER
AS
BEGIN
  SET NOCOUNT ON;
IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CENSOS_CREAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPActividad A JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.predio_id=A.predio_id JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot AND B.convenio_uot_organizacion_id IS NULL AND B.estado=1 WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot) THROW 51102,N'Actividad fuera del ámbito general.',1;
 IF @Fecha IS NULL OR (@Cantidad IS NULL AND @Aproximado IS NOT NULL) OR (@Cantidad IS NOT NULL AND (@Cantidad<0 OR @Aproximado IS NULL)) THROW 51103,N'Censo inválido.',1;
 SET XACT_ABORT ON;
 BEGIN TRAN;
 DECLARE @Id BIGINT;
 SELECT @Id=censo_id FROM prod.GPCenso WITH(UPDLOCK,HOLDLOCK) WHERE solicitud_id=@Solicitud;
 IF @Id IS NULL
 BEGIN
    INSERT prod.GPCenso(actividad_id,cantidad,aproximado,fecha,observacion,usuario_creacion_id,solicitud_id)
    VALUES(@Actividad,@Cantidad,@Aproximado,@Fecha,NULLIF(TRIM(@Observacion),N''),@Usuario,@Solicitud);
    SET @Id=SCOPE_IDENTITY();
 END;
 COMMIT;
 SELECT @Id AS id;
END;
GO
