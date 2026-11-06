SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'prod.PA_GP_Actividad_Upd_Registro', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Actividad_Upd_Registro;
GO
CREATE PROCEDURE prod.PA_GP_Actividad_Upd_Registro
@Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT,@Nombre NVARCHAR(120)=NULL,@Estado BIT,@Solicitud UNIQUEIDENTIFIER
AS
BEGIN
  SET NOCOUNT ON;
IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_EDITAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPActividad A JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.predio_id=A.predio_id JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot AND B.convenio_uot_organizacion_id IS NULL AND B.estado=1 WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot) THROW 51102,N'Actividad fuera del ámbito general.',1;
 -- Solo cambia metadatos; no se sobrescriben conteos ni historial.
 UPDATE prod.GPActividad SET nombre=NULLIF(TRIM(@Nombre),N''),estado=@Estado WHERE actividad_id=@Actividad AND uot_id=@Uot;
 SELECT @Actividad AS id;
END;
GO
