IF OBJECT_ID(N'[logistica].[TR_Producto_ValidarCatalogosRecurso]', N'TR') IS NOT NULL
    DROP TRIGGER [logistica].[TR_Producto_ValidarCatalogosRecurso];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : logistica.TR_Producto_ValidarCatalogosRecurso
' Descripción              : Valida los catálogos y recursos asociados a productos.
' Tabla asociada          : logistica.Producto
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
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE sobre logistica.Producto.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[logistica].[TR_Producto_ValidarCatalogosRecurso]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_Producto_ValidarCatalogosRecurso ON logistica.Producto AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I WHERE NOT EXISTS(SELECT 1 FROM config.CatalogoRecursoValor C WHERE C.catalogo='UNIDAD_MEDIDA' AND C.codigo=UPPER(I.unidad_medida) AND C.estado=1)) THROW 51000,N'La unidad de medida del producto no está disponible.',1;
 IF EXISTS(SELECT 1 FROM inserted I WHERE NULLIF(LTRIM(RTRIM(I.categoria)),N'') IS NOT NULL AND NOT EXISTS(SELECT 1 FROM config.CatalogoRecursoValor C WHERE C.catalogo='CATEGORIA_PRODUCTO' AND C.codigo=UPPER(CONVERT(VARCHAR(100),I.categoria)) AND C.estado=1)) THROW 51000,N'La categoría del producto no está disponible.',1;
END;
GO
