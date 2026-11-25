-- Autoriza proveedores persona y empresa registrados para la misma UOT.
IF OBJECT_ID(N'logistica.TR_BienInventario_ProveedorSoloEmpresa', N'TR') IS NOT NULL
BEGIN
    DROP TRIGGER logistica.TR_BienInventario_ProveedorSoloEmpresa;
END;
GO
CREATE TRIGGER logistica.TR_BienInventario_ProveedorSoloEmpresa
ON logistica.BienInventario
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar solo al asignar o modificar proveedor, sin invalidar referencias históricas sin cambio.
    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        LEFT JOIN deleted D ON D.bien_inventario_id = I.bien_inventario_id
        WHERE
        (
            ISNULL(I.proveedor_persona_id, -1) <> ISNULL(D.proveedor_persona_id, -1)
            OR ISNULL(I.proveedor_empresa_id, -1) <> ISNULL(D.proveedor_empresa_id, -1)
        )
        AND
        (
            (I.proveedor_persona_id IS NOT NULL AND I.proveedor_empresa_id IS NOT NULL)
            OR
            (I.proveedor_persona_id IS NOT NULL AND NOT EXISTS
            (
                SELECT 1
                FROM org.ProveedorUOT P
                INNER JOIN org.Persona R ON R.persona_id = P.persona_id
                WHERE P.uot_id = I.uot_id
                  AND P.persona_id = I.proveedor_persona_id
                  AND P.estado = 1 AND R.estado = 1
            ))
            OR
            (I.proveedor_empresa_id IS NOT NULL AND NOT EXISTS
            (
                SELECT 1
                FROM org.ProveedorUOT P
                INNER JOIN org.Empresa E ON E.empresa_id = P.empresa_id
                WHERE P.uot_id = I.uot_id
                  AND P.empresa_id = I.proveedor_empresa_id
                  AND P.estado = 1 AND E.estado = 1
            ))
        )
    )
    BEGIN
        THROW 51156, N'Seleccione un proveedor activo en la UOT del bien.', 1;
    END;
END;
GO
