IF OBJECT_ID(N'[seg].[FN_Usuario_NombreCompleto]', N'FN') IS NOT NULL
    DROP FUNCTION [seg].[FN_Usuario_NombreCompleto];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- Nombre y apellidos del usuario que generó un registro; conserva la identidad histórica.
CREATE FUNCTION seg.FN_Usuario_NombreCompleto(@UsuarioId BIGINT)
RETURNS NVARCHAR(280)
AS
BEGIN
    DECLARE @Nombre NVARCHAR(280);
    SELECT @Nombre = NULLIF(LTRIM(RTRIM(CONCAT(P.nombres, N' ', P.apellido_paterno,
        N' ', COALESCE(P.apellido_materno, N'')))), N'')
    FROM seg.Usuario U WITH (NOLOCK)
    INNER JOIN org.Persona P WITH (NOLOCK) ON P.persona_id = U.persona_id
    WHERE U.usuario_id = @UsuarioId;
    RETURN @Nombre;
END;
GO
