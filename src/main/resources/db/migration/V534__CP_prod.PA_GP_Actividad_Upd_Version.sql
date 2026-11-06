SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_Actividad_Upd_Registro;
GO
IF OBJECT_ID(N'prod.PA_GP_Actividad_Upd_Registro', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Actividad_Upd_Registro;
GO
CREATE PROCEDURE prod.PA_GP_Actividad_Upd_Registro
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT,
 @Nombre NVARCHAR(120)=NULL,@Estado BIT,@Motivo NVARCHAR(1000),@Solicitud UNIQUEIDENTIFIER
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_EDITAR',1)<>1
    THROW 51101,N'Acceso no autorizado.',1;
 IF @Solicitud IS NULL OR @Estado IS NULL OR LEN(TRIM(COALESCE(@Motivo,N'')))<3
    THROW 51103,N'El motivo del cambio es obligatorio.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPActividad A JOIN prod.Parcela P
    ON P.parcela_id=A.parcela_id AND P.predio_id=A.predio_id
    JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot
    AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
    WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot)
    THROW 51102,N'Actividad fuera del ámbito general.',1;
 BEGIN TRAN;
 BEGIN TRY
  DECLARE @Id BIGINT,@Anterior NVARCHAR(120),@AnteriorEstado BIT,@Nuevo NVARCHAR(120)=NULLIF(TRIM(@Nombre),N'');
  SELECT @Id=revision_id FROM prod.GPActividadRevision WITH(UPDLOCK,HOLDLOCK)
   WHERE solicitud_id=@Solicitud;
  IF @Id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.GPActividadRevision
     WHERE revision_id=@Id AND actividad_id=@Actividad)
     THROW 51103,N'Solicitud perteneciente a otro expediente.',1;
  IF @Id IS NULL
  BEGIN
    SELECT @Anterior=nombre,@AnteriorEstado=estado FROM prod.GPActividad WITH(UPDLOCK,HOLDLOCK)
     WHERE actividad_id=@Actividad;
    IF (COALESCE(@Anterior,N'')=COALESCE(@Nuevo,N'') AND @AnteriorEstado=@Estado)
     THROW 51103,N'No hay cambios para registrar.',1;
    UPDATE prod.GPActividad SET nombre=@Nuevo,estado=@Estado WHERE actividad_id=@Actividad;
    INSERT prod.GPActividadRevision(actividad_id,nombre_anterior,nombre_nuevo,
      estado_anterior,estado_nuevo,motivo,usuario_id,solicitud_id)
    VALUES(@Actividad,@Anterior,@Nuevo,@AnteriorEstado,@Estado,TRIM(@Motivo),@Usuario,@Solicitud);
  END;
  COMMIT;
  SELECT @Actividad AS id;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
