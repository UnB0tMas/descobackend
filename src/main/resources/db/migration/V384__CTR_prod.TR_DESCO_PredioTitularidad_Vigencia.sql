IF OBJECT_ID(N'[prod].[TR_DESCO_PredioTitularidad_Vigencia]', N'TR') IS NOT NULL
    DROP TRIGGER [prod].[TR_DESCO_PredioTitularidad_Vigencia];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : prod.TR_DESCO_PredioTitularidad_Vigencia
' Descripción              : Controla la vigencia de titularidades de predios.
' Tabla asociada          : prod.PredioTitularidad
' Evento que lo dispara   : AFTER INSERT,UPDATE
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Producción
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE sobre prod.PredioTitularidad.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[prod].[TR_DESCO_PredioTitularidad_Vigencia]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER prod.TR_DESCO_PredioTitularidad_Vigencia ON prod.PredioTitularidad AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
  SELECT 1 FROM inserted I LEFT JOIN deleted D ON D.predio_titularidad_id=I.predio_titularidad_id
  WHERE I.estado=1 AND I.fecha_hasta IS NULL
    AND (D.predio_titularidad_id IS NULL OR I.predio_id<>D.predio_id OR I.socio_id<>D.socio_id OR I.estado<>D.estado OR ISNULL(I.fecha_hasta,'99991231')<>ISNULL(D.fecha_hasta,'99991231'))
    AND EXISTS(SELECT 1 FROM prod.PredioTitularidad X WITH(UPDLOCK,HOLDLOCK) WHERE X.predio_id=I.predio_id AND X.socio_id=I.socio_id AND X.estado=1 AND X.fecha_hasta IS NULL AND X.predio_titularidad_id<>I.predio_titularidad_id)
 ) THROW 51030,N'El titular ya tiene una vigencia abierta en el predio.',1;
END;
GO
