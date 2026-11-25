IF OBJECT_ID(N'[prod].[FN_GP_Permiso]') IS NOT NULL
    DROP FUNCTION [prod].[FN_GP_Permiso];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Función       : prod.FN_GP_Permiso
' Descripción            : Devuelve el resultado de gp permiso.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE FUNCTION prod.FN_GP_Permiso (
    @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Permiso VARCHAR(70),@Escritura BIT)
RETURNS BIT
AS
BEGIN
    DECLARE @OK BIT=0;
    IF EXISTS (
      SELECT 1 FROM seg.SesionUsuario S
      WHERE S.sesion_publica_id=@Sesion AND S.usuario_id=@Usuario
        AND S.estado=1 AND S.fecha_revocacion IS NULL
        AND (@Escritura=0 OR (S.modo_uot='ESPECIFICA' AND S.uot_contexto_id=@Uot))
        AND (S.modo_uot='GENERAL' OR S.uot_contexto_id=@Uot)
        AND seg.FN_Usuario_TienePermisoUOT(@Usuario,@Uot,@Permiso)=1
    ) SET @OK=1;
    RETURN @OK;
END;
GO
