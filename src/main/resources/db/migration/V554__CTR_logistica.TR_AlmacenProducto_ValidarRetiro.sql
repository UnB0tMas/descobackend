IF OBJECT_ID(N'[logistica].[TR_AlmacenProducto_ValidarRetiro]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_AlmacenProducto_ValidarRetiro];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_AlmacenProducto_ValidarRetiro
' Descripción            : Valida las reglas de almacen producto validar retiro al modificar registros.
' Aplicativo / Módulo    : DESCO / logistica
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_AlmacenProducto_ValidarRetiro ON logistica.AlmacenProductoStock AFTER DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM deleted D WHERE D.stock_actual<>0 OR D.stock_reservado<>0 OR logistica.FN_AlmacenProducto_TieneHistorial(D.almacen_id,D.producto_id)=1)
 THROW 51080,N'No puede retirar una asociacion con stock, reservas o historial operativo.',1;
END;
GO
