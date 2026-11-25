-- Registrar un pendiente por venta, dentro de la transacción de registro.
IF OBJECT_ID(N'comercial.TR_Venta_ComprobanteFiscalPendiente', N'TR') IS NOT NULL
    DROP TRIGGER comercial.TR_Venta_ComprobanteFiscalPendiente;
GO
CREATE TRIGGER comercial.TR_Venta_ComprobanteFiscalPendiente
ON comercial.Venta
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT comercial.ComprobanteFiscalPendiente (venta_id, uot_id, estado_fiscal)
    SELECT I.venta_id, I.uot_id, 'PENDIENTE'
    FROM inserted I
    WHERE NOT EXISTS
    (
        SELECT 1 FROM comercial.ComprobanteFiscalPendiente CF WITH (UPDLOCK, HOLDLOCK)
        WHERE CF.venta_id = I.venta_id
    );
END;
GO
