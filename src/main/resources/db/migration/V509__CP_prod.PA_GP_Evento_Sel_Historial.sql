SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'prod.PA_GP_Evento_Sel_Historial', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Evento_Sel_Historial;
GO
CREATE PROCEDURE prod.PA_GP_Evento_Sel_Historial
@Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT
AS
BEGIN
  SET NOCOUNT ON;
IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'PREDIOS_VER',0)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPActividad A JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.predio_id=A.predio_id JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot AND B.convenio_uot_organizacion_id IS NULL AND B.estado=1 WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot) THROW 51102,N'Actividad fuera del ámbito general.',1;
 SELECT E.evento_id AS eventoId,E.actividad_id AS actividadId,E.tipo,E.observacion,E.fecha_hecho AS fechaHecho,
 E.fecha_registro AS fechaRegistro,E.usuario_creacion_id AS usuarioId,E.respuesta_a_id AS respuestaAId,
 E.problema_id AS problemaId,P.nombre AS problema,E.tratamiento_id AS tratamientoId,T.nombre AS tratamiento
 FROM prod.GPEvento E LEFT JOIN prod.GPProblema P ON P.problema_id=E.problema_id
 LEFT JOIN prod.GPTratamiento T ON T.tratamiento_id=E.tratamiento_id
 WHERE E.actividad_id=@Actividad ORDER BY E.fecha_hecho DESC,E.evento_id DESC;
END;
GO
