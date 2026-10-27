IF OBJECT_ID(N'[finanzas].[TR_DESCO_PagoSocio_Saldo]', N'TR') IS NOT NULL
    DROP TRIGGER [finanzas].[TR_DESCO_PagoSocio_Saldo];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : finanzas.TR_DESCO_PagoSocio_Saldo
' Descripción              : Valida saldos vinculados a pagos de socios.
' Tabla asociada          : finanzas.PagoSocio
' Evento que lo dispara   : AFTER INSERT,UPDATE,DELETE
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Finanzas
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE,DELETE sobre finanzas.PagoSocio.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[finanzas].[TR_DESCO_PagoSocio_Saldo]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER finanzas.TR_DESCO_PagoSocio_Saldo
ON finanzas.PagoSocio AFTER INSERT,UPDATE,DELETE AS
BEGIN
 IF ROWCOUNT_BIG()=0 RETURN;
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM deleted D LEFT JOIN inserted I ON I.pago_socio_id=D.pago_socio_id WHERE I.pago_socio_id IS NULL)
  THROW 51100,N'DESCO_PAGO_NO_EDITABLE',1;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.pago_socio_id=I.pago_socio_id
  WHERE I.liquidacion_socio_id<>D.liquidacion_socio_id OR I.importe<>D.importe OR I.medio_pago<>D.medio_pago
  OR ISNULL(I.numero_operacion,'')<>ISNULL(D.numero_operacion,'') OR I.estado<>D.estado
  OR (I.estado_proceso<>D.estado_proceso AND NOT
    ((D.estado_proceso='REGISTRADO' AND I.estado_proceso IN('CONFIRMADO','ANULADO')) OR (D.estado_proceso='CONFIRMADO' AND I.estado_proceso='ANULADO'))))
  THROW 51100,N'DESCO_PAGO_NO_EDITABLE',1;
 DECLARE @lock BIGINT;
 SELECT @lock=L.liquidacion_socio_id FROM finanzas.LiquidacionSocio L WITH(UPDLOCK,HOLDLOCK)
 WHERE EXISTS(SELECT 1 FROM inserted I WHERE I.liquidacion_socio_id=L.liquidacion_socio_id);
 IF EXISTS(SELECT 1 FROM inserted I JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=I.liquidacion_socio_id
 WHERE I.estado=1 AND I.estado_proceso IN('REGISTRADO','CONFIRMADO') AND
  (L.estado<>1 OR L.estado_proceso NOT IN('APROBADA','PAGADA_PARCIAL','PAGADA')))
  THROW 51000,N'La liquidación no está disponible para registrar pagos.',1;
 IF EXISTS(SELECT 1 FROM finanzas.LiquidacionSocio L CROSS APPLY(
  SELECT SUM(P.importe) total FROM finanzas.PagoSocio P WITH(READCOMMITTEDLOCK)
  WHERE P.liquidacion_socio_id=L.liquidacion_socio_id AND P.estado=1 AND P.estado_proceso IN('REGISTRADO','CONFIRMADO')) S
  WHERE EXISTS(SELECT 1 FROM inserted I WHERE I.liquidacion_socio_id=L.liquidacion_socio_id) AND S.total>L.importe_neto)
  THROW 51100,N'DESCO_PAGO_EXCESO',1;
 UPDATE L SET estado_proceso=CASE WHEN COALESCE(P.pagado,0)=0 THEN 'APROBADA'
  WHEN P.pagado=L.importe_neto THEN 'PAGADA' ELSE 'PAGADA_PARCIAL' END
 FROM finanzas.LiquidacionSocio L OUTER APPLY(SELECT SUM(P.importe) pagado FROM finanzas.PagoSocio P WITH(READCOMMITTEDLOCK)
  WHERE P.liquidacion_socio_id=L.liquidacion_socio_id AND P.estado=1 AND P.estado_proceso='CONFIRMADO') P
 WHERE L.estado=1 AND L.estado_proceso IN('APROBADA','PAGADA_PARCIAL','PAGADA')
 AND EXISTS(SELECT 1 FROM inserted I WHERE I.liquidacion_socio_id=L.liquidacion_socio_id);
END;
GO
