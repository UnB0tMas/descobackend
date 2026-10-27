IF OBJECT_ID(N'[logistica].[TR_BienInventario_SincronizarUOTLegacy]', N'TR') IS NOT NULL
    DROP TRIGGER [logistica].[TR_BienInventario_SincronizarUOTLegacy];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : logistica.TR_BienInventario_SincronizarUOTLegacy
' Descripción              : Sincroniza la UOT de bienes de inventario con su representación heredada.
' Tabla asociada          : logistica.BienInventario
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
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE sobre logistica.BienInventario.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[logistica].[TR_BienInventario_SincronizarUOTLegacy]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_BienInventario_SincronizarUOTLegacy
ON logistica.BienInventario AFTER INSERT,UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE B SET uot_id=COALESCE(B.uot_id,U.uot_id,R.uot_id)
    FROM logistica.BienInventario B JOIN inserted I ON I.bien_inventario_id=B.bien_inventario_id
    LEFT JOIN org.UOT U ON U.empresa_legacy_id=B.empresa_id
    OUTER APPLY(SELECT TOP(1) X.uot_id FROM org.UOT X WHERE X.es_raiz=1 AND X.estado=1 ORDER BY X.uot_id) R
    WHERE B.uot_id IS NULL;
    IF EXISTS(SELECT 1 FROM logistica.BienInventario B JOIN inserted I ON I.bien_inventario_id=B.bien_inventario_id WHERE B.uot_id IS NULL)
        THROW 51031,N'No fue posible resolver la UOT del bien.',1;
END;
GO
