IF OBJECT_ID(N'[org].[TR_DESCO_SocioAsociacion_Vigencia]', N'TR') IS NOT NULL
    DROP TRIGGER [org].[TR_DESCO_SocioAsociacion_Vigencia];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : org.TR_DESCO_SocioAsociacion_Vigencia
' Descripción              : Controla la vigencia de asignaciones de socios a asociaciones.
' Tabla asociada          : org.SocioAsociacion
' Evento que lo dispara   : AFTER INSERT,UPDATE
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Organización
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE sobre org.SocioAsociacion.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[org].[TR_DESCO_SocioAsociacion_Vigencia]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER org.TR_DESCO_SocioAsociacion_Vigencia ON org.SocioAsociacion AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
  SELECT 1 FROM inserted I LEFT JOIN deleted D ON D.socio_asociacion_id=I.socio_asociacion_id
  WHERE I.estado=1 AND I.fecha_hasta IS NULL
    AND (D.socio_asociacion_id IS NULL OR I.socio_id<>D.socio_id OR I.estado<>D.estado OR ISNULL(I.fecha_hasta,'99991231')<>ISNULL(D.fecha_hasta,'99991231'))
    AND EXISTS(SELECT 1 FROM org.SocioAsociacion X WITH(UPDLOCK,HOLDLOCK) WHERE X.socio_id=I.socio_id AND X.estado=1 AND X.fecha_hasta IS NULL AND X.socio_asociacion_id<>I.socio_asociacion_id)
 ) THROW 51028,N'El socio ya tiene una afiliación vigente.',1;
END;
GO
