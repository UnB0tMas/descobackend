IF OBJECT_ID(N'[seg].[TR_DESCO_Usuario_Unicidad]') IS NOT NULL
    DROP TRIGGER [seg].[TR_DESCO_Usuario_Unicidad];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : seg.TR_DESCO_Usuario_Unicidad
' Descripción            : Controla la unicidad de usuarios.
' Aplicativo / Módulo    : DESCO / Seguridad
*******************************************************************************************************/
CREATE TRIGGER seg.TR_DESCO_Usuario_Unicidad ON seg.Usuario AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
  SELECT 1 FROM inserted I LEFT JOIN deleted D ON D.usuario_id=I.usuario_id
  WHERE I.usuario_clave_desco IS NOT NULL
    AND (D.usuario_id IS NULL OR ISNULL(I.usuario_clave_desco,'')<>ISNULL(D.usuario_clave_desco,''))
    AND EXISTS(SELECT 1 FROM seg.Usuario X WITH(UPDLOCK,HOLDLOCK) WHERE X.usuario_clave_desco=I.usuario_clave_desco AND X.usuario_id<>I.usuario_id)
 ) THROW 51024,N'El nombre de usuario ya está registrado.',1;
END;
GO
