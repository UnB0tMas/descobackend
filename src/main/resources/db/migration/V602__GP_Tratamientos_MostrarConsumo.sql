-- DESCO / 2026-11-06 / AL-03: mostrar producto y cantidad utilizada en el historial productivo.
-- Ejemplo: un tratamiento vinculado a una entrega muestra 2 UND utilizadas.
CREATE OR ALTER PROCEDURE prod.PA_GP_Tratamiento_Sel_Incidencia
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
   T.descripcion_cierre descripcionCierre,E.usuario_creacion_id usuarioId,P.nombre producto,U.cantidad cantidadUtilizada,P.unidad_medida unidadUtilizada
 FROM prod.GPIncidenciaTratamiento T JOIN prod.GPIncidencia I ON I.incidencia_id=T.incidencia_id
 JOIN prod.GPTratamiento C ON C.tratamiento_id=T.tratamiento_id
 JOIN prod.GPEvento E ON E.evento_id=T.evento_id
 LEFT JOIN logistica.UsoProductoTecnico U ON U.tipo_origen='GP' AND U.registro_id=T.evento_id
 LEFT JOIN logistica.ProgramacionProducto PP ON PP.programacion_producto_id=U.programacion_producto_id
 LEFT JOIN logistica.Producto P ON P.producto_id=PP.producto_id
 WHERE I.actividad_id=@Actividad AND I.estado=1 AND T.estado=1 AND E.estado=1 ORDER BY T.evento_id DESC;
END;
GO
