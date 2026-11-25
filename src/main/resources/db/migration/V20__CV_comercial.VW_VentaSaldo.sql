IF OBJECT_ID(N'[comercial].[VW_VentaSaldo]') IS NOT NULL
    DROP VIEW [comercial].[VW_VentaSaldo];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Vista         : comercial.VW_VentaSaldo
' Descripción            : Consulta el total, los pagos registrados y el saldo de las ventas.
' Aplicativo / Módulo    : DESCO / Comercial
*******************************************************************************************************/
CREATE VIEW comercial.VW_VentaSaldo
AS
SELECT V.venta_id,V.uot_id,V.almacen_id,V.fecha_hora,V.estado_venta,V.moneda,V.total,
       COALESCE(P.pagado,0) pagado,
       CONVERT(DECIMAL(19,4),V.total-COALESCE(P.pagado,0)) saldo
FROM comercial.Venta V
OUTER APPLY(SELECT SUM(PV.importe) pagado FROM comercial.PagoVenta PV WHERE PV.venta_id=V.venta_id AND PV.estado=1 AND PV.estado_pago='CONFIRMADO') P;
GO
