IF OBJECT_ID(N'[seg].[TR_DESCO_UsuarioCorreoSeguridad_Unicidad]', N'TR') IS NOT NULL
    DROP TRIGGER [seg].[TR_DESCO_UsuarioCorreoSeguridad_Unicidad];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : seg.TR_DESCO_UsuarioCorreoSeguridad_Unicidad
' Descripción              : Controla la unicidad de correos de seguridad de usuarios.
' Tabla asociada          : seg.UsuarioCorreoSeguridad
' Evento que lo dispara   : AFTER INSERT,UPDATE
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Seguridad
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE sobre seg.UsuarioCorreoSeguridad.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[seg].[TR_DESCO_UsuarioCorreoSeguridad_Unicidad]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER seg.TR_DESCO_UsuarioCorreoSeguridad_Unicidad ON seg.UsuarioCorreoSeguridad AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
  SELECT 1 FROM inserted I LEFT JOIN deleted D ON D.usuario_correo_seguridad_id=I.usuario_correo_seguridad_id
  WHERE I.estado=1 AND I.fecha_hasta IS NULL AND I.correo_clave_desco IS NOT NULL
    AND (D.usuario_correo_seguridad_id IS NULL OR ISNULL(I.correo_clave_desco,'')<>ISNULL(D.correo_clave_desco,'') OR I.estado<>D.estado OR ISNULL(I.fecha_hasta,'99991231')<>ISNULL(D.fecha_hasta,'99991231'))
    AND EXISTS(SELECT 1 FROM seg.UsuarioCorreoSeguridad X WITH(UPDLOCK,HOLDLOCK) WHERE X.estado=1 AND X.fecha_hasta IS NULL AND X.correo_clave_desco=I.correo_clave_desco AND X.usuario_correo_seguridad_id<>I.usuario_correo_seguridad_id)
 ) THROW 51025,N'El correo ya está registrado.',1;
 IF EXISTS(
  SELECT 1 FROM inserted I LEFT JOIN deleted D ON D.usuario_correo_seguridad_id=I.usuario_correo_seguridad_id
  WHERE I.estado=1 AND I.fecha_hasta IS NULL AND I.es_principal=1
    AND (D.usuario_correo_seguridad_id IS NULL OR I.usuario_id<>D.usuario_id OR I.estado<>D.estado OR I.es_principal<>D.es_principal OR ISNULL(I.fecha_hasta,'99991231')<>ISNULL(D.fecha_hasta,'99991231'))
    AND EXISTS(SELECT 1 FROM seg.UsuarioCorreoSeguridad X WITH(UPDLOCK,HOLDLOCK) WHERE X.usuario_id=I.usuario_id AND X.estado=1 AND X.fecha_hasta IS NULL AND X.es_principal=1 AND X.usuario_correo_seguridad_id<>I.usuario_correo_seguridad_id)
 ) THROW 51026,N'La cuenta ya tiene un correo principal.',1;
END;
GO
