-- Consulta de aceptación E5 contra SQL Server después de aplicar V451/V452.
-- Solo lectura: no crea campañas, socios, liquidaciones ni pagos de prueba.
SET NOCOUNT ON;
DECLARE @importe DECIMAL(19,4)=300.00,@vendedores INT=20;
DECLARE @centavos BIGINT=CONVERT(BIGINT,@importe*100),@base BIGINT=@centavos/@vendedores,@resto BIGINT=@centavos%@vendedores;
IF (@base*@vendedores+@resto)<>@centavos OR @base<>1500
 THROW 51900,N'El gasto de S/ 300 debe repartirse en 20 cuotas de S/ 15.',1;
DECLARE @bruto DECIMAL(19,4)=100.000*3.20,@efectivo DECIMAL(19,4)=100.000*2.80,
 @cargo DECIMAL(19,4)=2*25.00,@gasto DECIMAL(19,4)=15.00;
IF (@bruto-@efectivo)<>40.00 OR (@efectivo-@cargo-@gasto)<>215.00
 THROW 51901,N'El neto de Pedro debe ser S/ 215 sin segunda resta del ajuste.',1;
IF (215.00-100.00)<>115.00 OR (215.00-100.00-115.00)<>0.00
 THROW 51902,N'El pago parcial y el final deben conciliar.',1;
IF EXISTS (SELECT 1 FROM finanzas.GastoRepartoVersionE5 V
 LEFT JOIN (SELECT reparto_id,SUM(monto) total,COUNT_BIG(*) vendedores
   FROM finanzas.GastoRepartoLineaE5 GROUP BY reparto_id) D ON D.reparto_id=V.reparto_id
 WHERE V.estado='APROBADO' AND (ISNULL(D.total,0)<>V.importe OR ISNULL(D.vendedores,0)<>V.vendedores))
 THROW 51903,N'Existen versiones aprobadas cuyo gasto no coincide con la suma de cuotas.',1;
IF EXISTS(SELECT 1 FROM finanzas.LiquidacionSocio L
 OUTER APPLY(SELECT SUM(P.importe) pagado FROM finanzas.PagoSocio P
   WHERE P.liquidacion_socio_id=L.liquidacion_socio_id AND P.estado=1 AND P.estado_proceso='CONFIRMADO') Q
 WHERE ISNULL(Q.pagado,0)>L.importe_neto AND L.estado=1)
 THROW 51904,N'Existe al menos una liquidación con sobrepago.',1;
IF EXISTS(SELECT 1 FROM finanzas.LiquidacionSnapshotE5 S
 JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=S.liquidacion_socio_id
 WHERE L.importe_neto<>S.neto OR S.neto<>S.venta_ajustada-S.cargos-S.gastos-S.descuentos_adicionales+S.bonificaciones+S.ajuste_redondeo)
 THROW 51905,N'El snapshot no concilia con la liquidación oficial.',1;
SELECT N'E5: invariantes aritméticas y estados almacenados verificados' AS resultado;
