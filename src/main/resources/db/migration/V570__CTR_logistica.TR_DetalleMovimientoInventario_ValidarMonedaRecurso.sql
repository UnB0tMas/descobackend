IF OBJECT_ID(N'[logistica].[TR_DetalleMovimientoInventario_ValidarMonedaRecurso]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_DetalleMovimientoInventario_ValidarMonedaRecurso];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_DetalleMovimientoInventario_ValidarMonedaRecurso
' Descripción            : Valida moneda en los detalles de movimientos de inventario.
' Aplicativo / Módulo    : DESCO / Logística
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_DetalleMovimientoInventario_ValidarMonedaRecurso ON logistica.DetalleMovimientoInventario AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I WHERE I.moneda IS NOT NULL AND NOT EXISTS(SELECT 1 FROM config.CatalogoRecursoValor C WHERE C.catalogo='MONEDA' AND C.codigo=UPPER(I.moneda) AND C.estado=1)) THROW 51000,N'La moneda del movimiento no está disponible.',1;
END;
GO
