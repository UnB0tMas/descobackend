IF OBJECT_ID(N'[logistica].[TR_DESCO_RecursoProgramado_Unicidad]', N'TR') IS NOT NULL
    DROP TRIGGER [logistica].[TR_DESCO_RecursoProgramado_Unicidad];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : logistica.TR_DESCO_RecursoProgramado_Unicidad
' Descripción              : Controla reglas de unicidad de recursos programados.
' Tabla asociada          : logistica.RecursoProgramado
' Evento que lo dispara   : AFTER INSERT,UPDATE
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE sobre logistica.RecursoProgramado.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[logistica].[TR_DESCO_RecursoProgramado_Unicidad]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_DESCO_RecursoProgramado_Unicidad ON logistica.RecursoProgramado AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
  SELECT 1 FROM inserted I LEFT JOIN deleted D ON D.recurso_programado_id=I.recurso_programado_id
  WHERE I.bien_inventario_id IS NOT NULL AND I.estado=1 AND I.estado_proceso IN('PROGRAMADO','EN_EJECUCION')
    AND (D.recurso_programado_id IS NULL OR ISNULL(I.bien_inventario_id,-1)<>ISNULL(D.bien_inventario_id,-1) OR I.estado<>D.estado OR ISNULL(I.estado_proceso,'')<>ISNULL(D.estado_proceso,''))
    AND EXISTS(SELECT 1 FROM logistica.RecursoProgramado X WITH(UPDLOCK,HOLDLOCK) WHERE X.bien_inventario_id=I.bien_inventario_id AND X.estado=1 AND X.estado_proceso IN('PROGRAMADO','EN_EJECUCION') AND X.recurso_programado_id<>I.recurso_programado_id)
 ) THROW 51033,N'El recurso ya tiene una programación activa.',1;
END;
GO
