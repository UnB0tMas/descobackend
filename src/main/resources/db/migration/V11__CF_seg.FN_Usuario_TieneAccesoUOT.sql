IF OBJECT_ID(N'[seg].[FN_Usuario_TieneAccesoUOT]') IS NOT NULL
    DROP FUNCTION [seg].[FN_Usuario_TieneAccesoUOT];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Función       : seg.FN_Usuario_TieneAccesoUOT
' Descripción            : Comprueba el acceso vigente de un usuario a una UOT.
' Aplicativo / Módulo    : DESCO / Seguridad
*******************************************************************************************************/
CREATE FUNCTION seg.FN_Usuario_TieneAccesoUOT(@usuario_id BIGINT,@uot_id BIGINT)
RETURNS BIT
AS
BEGIN
    DECLARE @R BIT=0;
    IF EXISTS
    (
        SELECT 1 FROM seg.UsuarioUOT UU
        JOIN org.UOT U ON U.uot_id=UU.uot_id AND U.estado=1
        WHERE UU.usuario_id=@usuario_id AND UU.uot_id=@uot_id
          AND UU.estado=1 AND UU.fecha_hasta IS NULL
          AND UU.fecha_desde<=SYSUTCDATETIME()
    ) SET @R=1;
    RETURN @R;
END;
GO
