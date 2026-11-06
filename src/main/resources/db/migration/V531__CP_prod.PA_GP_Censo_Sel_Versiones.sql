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
 IF NOT EXISTS(SELECT 1 FROM prod.GPActividad A
 JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.predio_id=A.predio_id
 JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot
  AND B.convenio_uot_organizacion_id IS NULL AND B.estado=1
 WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot)
     THROW 51102,N'Actividad fuera del ámbito general.',1;
 SELECT C.censo_id AS censoId,C.actividad_id AS actividadId,
  COALESCE(C.cantidad_aproximada,C.cantidad) AS cantidadAproximada,
  C.cantidad_exacta AS cantidadExacta,C.fecha,
  C.observacion,C.fecha_registro AS fechaRegistro,C.usuario_creacion_id AS usuarioId
 FROM prod.GPCenso C WHERE C.actividad_id=@Actividad
 ORDER BY C.fecha_registro DESC,C.censo_id DESC;
END;
GO
