SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_CensoRaza_Sel_Historial;
GO
IF OBJECT_ID(N'prod.PA_GP_CensoRaza_Sel_Historial', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_CensoRaza_Sel_Historial;
GO
CREATE PROCEDURE prod.PA_GP_CensoRaza_Sel_Historial
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CENSOS_LISTAR',0)<>1
  THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPActividad A JOIN prod.PredioAmbito B
  ON B.predio_id=A.predio_id AND B.uot_id=@Uot AND B.estado=1
  AND B.convenio_uot_organizacion_id IS NULL
  WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot)
  THROW 51102,N'Actividad fuera del ámbito general.',1;
 SELECT C.censo_id AS censoId,R.raza_id AS razaId,R.nombre AS raza,
  D.cantidad_aproximada AS cantidadAproximada,D.cantidad_exacta AS cantidadExacta
 FROM prod.GPCenso C JOIN prod.GPCensoRaza D ON D.censo_id=C.censo_id
 JOIN prod.GPRaza R ON R.raza_id=D.raza_id
 WHERE C.actividad_id=@Actividad ORDER BY C.censo_id DESC,R.nombre;
END;
GO
