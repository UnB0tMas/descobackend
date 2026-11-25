IF OBJECT_ID(N'[prod].[PA_GP_Incidencia_Sel_Listado]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_GP_Incidencia_Sel_Listado];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_GP_Incidencia_Sel_Listado
' Descripción            : Consulta información de GP Incidencia (listado).
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE PROCEDURE prod.PA_GP_Incidencia_Sel_Listado
@Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;

 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_VER',0)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPActividad A JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.estado=1
  JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
  WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot AND A.estado=1) THROW 51102,N'Actividad no disponible.',1;
 SELECT I.incidencia_id incidenciaId,I.actividad_id actividadId,I.problema_id problemaId,P.nombre problema,
   I.estado_seguimiento AS estado,I.resultado,I.afectada_m2 afectadaM2,I.afectados_animales afectadosAnimales,
   I.perdida_m2 perdidaM2,I.perdidos_animales perdidosAnimales,
   E.observacion descripcion,E.fecha_registro fechaRegistro,E.usuario_creacion_id usuarioId,
   I.fecha_cierre fechaCierre,I.descripcion_cierre descripcionCierre,I.usuario_cierre_id usuarioCierreId
 FROM prod.GPIncidencia I JOIN prod.GPEvento E ON E.evento_id=I.incidencia_id
 JOIN prod.GPProblema P ON P.problema_id=I.problema_id
 WHERE I.actividad_id=@Actividad AND I.estado=1 AND E.estado=1 ORDER BY I.incidencia_id DESC;
END;
GO
