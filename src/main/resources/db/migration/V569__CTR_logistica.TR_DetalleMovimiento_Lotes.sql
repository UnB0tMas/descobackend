IF OBJECT_ID(N'[logistica].[TR_DetalleMovimiento_Lotes]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_DetalleMovimiento_Lotes];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_DetalleMovimiento_Lotes
' Descripción            : Controla las modificaciones de detalle movimiento lotes mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / logistica
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_DetalleMovimiento_Lotes ON logistica.DetalleMovimientoInventario AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM deleted) THROW 51120,N'Los datos del movimiento son históricos. Registre una corrección trazable.',1;
 DECLARE @Detalle BIGINT;
 DECLARE detalles CURSOR LOCAL FAST_FORWARD FOR SELECT detalle_movimiento_inventario_id FROM inserted ORDER BY producto_id,detalle_movimiento_inventario_id;
 OPEN detalles;FETCH NEXT FROM detalles INTO @Detalle;
 WHILE @@FETCH_STATUS=0
 BEGIN EXEC logistica.PA_DetalleMovimiento_Ins_Lotes @Detalle;FETCH NEXT FROM detalles INTO @Detalle;END;
 CLOSE detalles;DEALLOCATE detalles;
END;
GO
