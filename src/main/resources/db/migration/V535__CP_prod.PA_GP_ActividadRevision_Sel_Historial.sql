SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_ActividadRevision_Sel_Historial;
GO
IF OBJECT_ID(N'prod.PA_GP_ActividadRevision_Sel_Historial', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_ActividadRevision_Sel_Historial;
GO
CREATE PROCEDURE prod.PA_GP_ActividadRevision_Sel_Historial
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_VER',0)<>1
    THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPActividad A JOIN prod.Parcela P
  ON P.parcela_id=A.parcela_id AND P.predio_id=A.predio_id
  JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot
   AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
  WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot)
     THROW 51102,N'Actividad fuera del ámbito general.',1;
 SELECT R.revision_id AS revisionId,R.actividad_id AS actividadId,
   R.nombre_anterior AS nombreAnterior,R.nombre_nuevo AS nombreNuevo,
   R.estado_anterior AS estadoAnterior,R.estado_nuevo AS estadoNuevo,
   R.motivo,R.usuario_id AS usuarioId,R.fecha_registro AS fechaRegistro
 FROM prod.GPActividadRevision R WHERE R.actividad_id=@Actividad
 ORDER BY R.revision_id DESC;
END;
GO
