IF OBJECT_ID(N'logistica.TR_Producto_SuministroIdentidad', N'TR') IS NOT NULL
BEGIN
    DROP TRIGGER logistica.TR_Producto_SuministroIdentidad;
END;
GO

-- Mantiene coherente la identidad del producto compartido con suministros.
CREATE TRIGGER logistica.TR_Producto_SuministroIdentidad
ON logistica.Producto
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT (UPDATE(nombre) OR UPDATE(unidad_medida)) RETURN;
    IF EXISTS (
        SELECT 1 FROM inserted I
        INNER JOIN deleted D ON D.producto_id=I.producto_id
        INNER JOIN logistica.Suministro S ON S.producto_id=I.producto_id
        WHERE I.unidad_medida<>D.unidad_medida
          AND EXISTS (SELECT 1 FROM logistica.SuministroMovimiento M
                      WHERE M.suministro_id=S.suministro_id)
    )
        THROW 51067,N'No puede cambiar la unidad de un producto con movimientos técnicos.',1;
    UPDATE S SET nombre=LEFT(I.nombre,150),unidad_medida=I.unidad_medida
    FROM logistica.Suministro S
    INNER JOIN inserted I ON I.producto_id=S.producto_id
    WHERE S.nombre<>LEFT(I.nombre,150) OR S.unidad_medida<>I.unidad_medida;
END;
GO
