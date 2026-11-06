-- DESCO GP | migracion aditiva, historiales inmutables.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_Tratamiento_Sel_Incidencia;
GO
IF OBJECT_ID(N'prod.PA_GP_Tratamiento_Sel_Incidencia', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Tratamiento_Sel_Incidencia;
GO
CREATE PROCEDURE prod.PA_GP_Tratamiento_Sel_Incidencia
@Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;

 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_VER',0)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPActividad A JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.estado=1
  JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
  WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot AND A.estado=1) THROW 51102,N'Actividad no disponible.',1;
 SELECT T.evento_id eventoId,T.incidencia_id incidenciaId,T.tratamiento_id tratamientoId,
   C.nombre tratamiento,E.observacion descripcion,T.fecha_inicio fechaInicio,
   T.fecha_fin_prevista fechaFinPrevista,T.fecha_fin_real fechaFinReal,
   T.descripcion_cierre descripcionCierre,E.usuario_creacion_id usuarioId
 FROM prod.GPIncidenciaTratamiento T JOIN prod.GPIncidencia I ON I.incidencia_id=T.incidencia_id
 JOIN prod.GPTratamiento C ON C.tratamiento_id=T.tratamiento_id
 JOIN prod.GPEvento E ON E.evento_id=T.evento_id
 WHERE I.actividad_id=@Actividad ORDER BY T.evento_id DESC;
END;
GO
