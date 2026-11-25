IF OBJECT_ID(N'[logistica].[TR_DESCO_TransferenciaAlmacen_AmbitoUOT]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_DESCO_TransferenciaAlmacen_AmbitoUOT];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_DESCO_TransferenciaAlmacen_AmbitoUOT
' Descripción            : Valida almacenes, UOT y salidas/entradas vinculadas.
' Aplicativo / Módulo    : DESCO / Logística
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_DESCO_TransferenciaAlmacen_AmbitoUOT
ON logistica.TransferenciaAlmacen AFTER INSERT,UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted I
        JOIN logistica.Almacen A ON A.almacen_id=I.almacen_origen_id
        JOIN logistica.Almacen B ON B.almacen_id=I.almacen_destino_id
        JOIN logistica.MovimientoInventario MS ON MS.movimiento_inventario_id=I.movimiento_salida_id
        JOIN logistica.MovimientoInventario ME ON ME.movimiento_inventario_id=I.movimiento_entrada_id
        WHERE A.uot_propietaria_id<>I.uot_origen_id OR B.uot_propietaria_id<>I.uot_destino_id
          OR I.almacen_origen_id=I.almacen_destino_id
          OR MS.almacen_id<>I.almacen_origen_id OR ME.almacen_id<>I.almacen_destino_id
          OR MS.naturaleza<>'S' OR ME.naturaleza<>'E'
          OR MS.tipo_movimiento<>'TRANSFERENCIA' OR ME.tipo_movimiento<>'TRANSFERENCIA')
        THROW 51215,N'La transferencia tiene almacenes o movimientos incompatibles.',1;
END;
GO
