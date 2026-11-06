SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_Censo_Sel_Historial;
GO
IF OBJECT_ID(N'prod.PA_GP_Censo_Sel_Historial', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Censo_Sel_Historial;
GO
CREATE PROCEDURE prod.PA_GP_Censo_Sel_Historial
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
 SELECT C.censo_id AS censoId,C.actividad_id AS actividadId,
  CASE WHEN A.rubro='CRIANZA' THEN COALESCE(C.cantidad_aproximada,C.cantidad) ELSE NULL END AS cantidadAproximada,
  CASE WHEN A.rubro='CRIANZA' THEN C.cantidad_exacta ELSE NULL END AS cantidadExacta,
  C.superficie_aproximada_m2 AS superficieAproximadaM2,C.superficie_exacta_m2 AS superficieExactaM2,
  C.fecha,C.observacion,C.fecha_registro AS fechaRegistro,C.usuario_creacion_id AS usuarioId
 FROM prod.GPCenso C JOIN prod.GPActividad A ON A.actividad_id=C.actividad_id
 WHERE C.actividad_id=@Actividad ORDER BY C.fecha_registro DESC,C.censo_id DESC;
END;
GO
