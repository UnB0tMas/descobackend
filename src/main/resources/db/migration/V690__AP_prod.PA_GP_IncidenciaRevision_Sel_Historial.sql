IF OBJECT_ID(N'[prod].[PA_GP_IncidenciaRevision_Sel_Historial]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_GP_IncidenciaRevision_Sel_Historial];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_GP_IncidenciaRevision_Sel_Historial
' Descripción            : Consulta información de GP Incidencia Revision (historial).
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_GP_IncidenciaRevision_Sel_Historial
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Incidencia BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_VER',0)<>1
  THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPIncidencia I
    JOIN prod.GPActividad A ON A.actividad_id=I.actividad_id AND A.uot_id=@Uot
    JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.estado=1
    JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot
      AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
    WHERE I.incidencia_id=@Incidencia)
    THROW 51102,N'Incidencia fuera del ámbito.',1;
 SELECT revision_id AS revisionId,incidencia_id AS incidenciaId,accion,motivo,
    usuario_id AS usuarioId,seg.FN_Usuario_NombreCompleto(usuario_id) AS usuarioNombre,
    fecha_registro AS fechaRegistro,
    problema_anterior AS problemaAnterior,problema_nuevo AS problemaNuevo,
    afectada_anterior AS afectadaAnterior,afectada_nueva AS afectadaNueva,
    animales_anteriores AS animalesAnteriores,animales_nuevos AS animalesNuevos,
    descripcion_anterior AS descripcionAnterior,descripcion_nueva AS descripcionNueva
 FROM prod.GPIncidenciaRevision WHERE incidencia_id=@Incidencia
 ORDER BY revision_id DESC;
END;
GO
