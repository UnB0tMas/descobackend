SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'prod.PA_GP_Actividad_Ins_Registro', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Actividad_Ins_Registro;
GO
CREATE PROCEDURE prod.PA_GP_Actividad_Ins_Registro
@Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Parcela BIGINT,@Rubro VARCHAR(8),@Cultivo INT=NULL,@Especie INT=NULL,@Nombre NVARCHAR(120)=NULL,@Fecha DATE=NULL,@Cantidad INT=NULL,@Aproximado BIT=NULL,@Solicitud UNIQUEIDENTIFIER
AS
BEGIN
  SET NOCOUNT ON;
IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_CREAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF @Parcela IS NULL OR @Rubro NOT IN('CULTIVO','CRIANZA') OR
    (@Rubro='CULTIVO' AND (@Cultivo IS NULL OR @Especie IS NOT NULL)) OR
    (@Rubro='CRIANZA' AND (@Especie IS NULL OR @Cultivo IS NOT NULL))
    THROW 51103,N'Actividad inválida.',1;
 IF (@Cantidad IS NULL AND @Aproximado IS NOT NULL) OR (@Cantidad IS NOT NULL AND (@Aproximado IS NULL OR @Cantidad<0))
    THROW 51103,N'Cantidad o tipo de conteo inválidos.',1;
 IF @Rubro='CULTIVO' AND NOT EXISTS(SELECT 1 FROM prod.Cultivo WHERE cultivo_id=@Cultivo AND estado=1) THROW 51103,N'Cultivo no disponible.',1;
 IF @Rubro='CRIANZA' AND NOT EXISTS(SELECT 1 FROM prod.EspeciePecuaria WHERE especie_pecuaria_id=@Especie AND estado=1) THROW 51103,N'Especie no disponible.',1;
 DECLARE @Predio BIGINT;
 SELECT @Predio=P.predio_id FROM prod.Parcela P JOIN prod.PredioAmbito B ON B.predio_id=P.predio_id AND B.uot_id=@Uot AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL WHERE P.parcela_id=@Parcela AND P.estado=1;
 IF @Predio IS NULL THROW 51102,N'Parcela fuera del ámbito general.',1;
 SET XACT_ABORT ON;
 BEGIN TRAN;
 DECLARE @Id BIGINT;
 SELECT @Id=actividad_id FROM prod.GPActividad WITH(UPDLOCK,HOLDLOCK) WHERE solicitud_id=@Solicitud;
 IF @Id IS NULL
 BEGIN
   INSERT prod.GPActividad(parcela_id,predio_id,uot_id,rubro,cultivo_id,especie_pecuaria_id,nombre,fecha_inicio,usuario_creacion_id,solicitud_id)
   VALUES(@Parcela,@Predio,@Uot,@Rubro,@Cultivo,@Especie,NULLIF(TRIM(@Nombre),N''),COALESCE(@Fecha,CONVERT(date,SYSUTCDATETIME())),@Usuario,@Solicitud);
   SET @Id=SCOPE_IDENTITY();
   IF @Cantidad IS NOT NULL
      INSERT prod.GPCenso(actividad_id,cantidad,aproximado,fecha,usuario_creacion_id,solicitud_id)
      VALUES(@Id,@Cantidad,@Aproximado,COALESCE(@Fecha,CONVERT(date,SYSUTCDATETIME())),@Usuario,NEWID());
 END;
 COMMIT;
 SELECT @Id AS id;
END;
GO
