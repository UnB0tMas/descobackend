IF OBJECT_ID(N'[prod].[FN_Predio_VisibleSesion]') IS NOT NULL
    DROP FUNCTION [prod].[FN_Predio_VisibleSesion];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Función       : prod.FN_Predio_VisibleSesion
' Descripción            : Devuelve el resultado de predio visible sesion.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   FUNCTION prod.FN_Predio_VisibleSesion(@Sesion BIGINT,@Usuario BIGINT,@Predio BIGINT,@Permiso VARCHAR(100))
RETURNS BIT AS
BEGIN
 DECLARE @Uot BIGINT,@Modo VARCHAR(12);
 SELECT @Uot=uot_contexto_id,@Modo=modo_uot FROM seg.SesionUsuario WHERE sesion_usuario_id=@Sesion AND estado=1 AND fecha_revocacion IS NULL;
 RETURN CASE WHEN EXISTS(SELECT 1 FROM prod.PredioAmbito A WHERE A.predio_id=@Predio AND A.estado=1
  AND (@Modo='GENERAL' OR A.uot_id=@Uot)
  AND seg.FN_Usuario_TienePermisoUOT(@Usuario,A.uot_id,@Permiso)=1
  AND (A.convenio_uot_organizacion_id IS NULL OR seg.FN_Usuario_TienePermisoUOT(@Usuario,A.uot_id,'APAPPSS_PREDIOS_LISTAR')=1)) THEN 1 ELSE 0 END;
END;
GO
