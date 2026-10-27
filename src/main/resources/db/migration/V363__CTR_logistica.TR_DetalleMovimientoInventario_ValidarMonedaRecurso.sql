IF OBJECT_ID(N'[logistica].[TR_DetalleMovimientoInventario_ValidarMonedaRecurso]', N'TR') IS NOT NULL
    DROP TRIGGER [logistica].[TR_DetalleMovimientoInventario_ValidarMonedaRecurso];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : logistica.TR_DetalleMovimientoInventario_ValidarMonedaRecurso
' Descripción              : Valida moneda en los detalles de movimientos de inventario.
' Tabla asociada          : logistica.DetalleMovimientoInventario
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
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE sobre logistica.DetalleMovimientoInventario.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[logistica].[TR_DetalleMovimientoInventario_ValidarMonedaRecurso]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_DetalleMovimientoInventario_ValidarMonedaRecurso ON logistica.DetalleMovimientoInventario AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I WHERE I.moneda IS NOT NULL AND NOT EXISTS(SELECT 1 FROM config.CatalogoRecursoValor C WHERE C.catalogo='MONEDA' AND C.codigo=UPPER(I.moneda) AND C.estado=1)) THROW 51000,N'La moneda del movimiento no está disponible.',1;
END;
GO
