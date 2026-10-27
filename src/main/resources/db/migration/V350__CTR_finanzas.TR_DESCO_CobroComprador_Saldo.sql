IF OBJECT_ID(N'[finanzas].[TR_DESCO_CobroComprador_Saldo]', N'TR') IS NOT NULL
    DROP TRIGGER [finanzas].[TR_DESCO_CobroComprador_Saldo];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : finanzas.TR_DESCO_CobroComprador_Saldo
' Descripción              : Valida saldos vinculados a cobros de compradores.
' Tabla asociada          : finanzas.CobroComprador
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
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE,DELETE sobre finanzas.CobroComprador.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[finanzas].[TR_DESCO_CobroComprador_Saldo]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER finanzas.TR_DESCO_CobroComprador_Saldo
ON finanzas.CobroComprador AFTER INSERT,UPDATE,DELETE AS
BEGIN
 IF ROWCOUNT_BIG()=0 RETURN;
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM deleted D LEFT JOIN inserted I ON I.cobro_comprador_id=D.cobro_comprador_id WHERE I.cobro_comprador_id IS NULL)
  THROW 51100,N'DESCO_MOVIMIENTO_INMUTABLE',1;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.cobro_comprador_id=I.cobro_comprador_id
  WHERE I.campania_venta_id<>D.campania_venta_id OR ISNULL(I.operativo_venta_id,0)<>ISNULL(D.operativo_venta_id,0)
  OR I.importe<>D.importe OR I.moneda<>D.moneda OR I.medio_pago<>D.medio_pago
  OR ISNULL(I.numero_operacion,'')<>ISNULL(D.numero_operacion,'') OR I.estado<>D.estado
  OR (I.estado_proceso<>D.estado_proceso AND NOT
    ((D.estado_proceso='REGISTRADO' AND I.estado_proceso IN('CONFIRMADO','ANULADO')) OR (D.estado_proceso='CONFIRMADO' AND I.estado_proceso='ANULADO'))))
  THROW 51100,N'DESCO_MOVIMIENTO_INMUTABLE',1;
 DECLARE @lock BIGINT;
 SELECT @lock=C.campania_venta_id FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK)
 WHERE EXISTS(SELECT 1 FROM inserted I WHERE I.campania_venta_id=C.campania_venta_id);
 IF EXISTS(SELECT 1 FROM inserted I WHERE I.operativo_venta_id IS NOT NULL AND NOT EXISTS
  (SELECT 1 FROM comercial.OperativoVenta O WHERE O.operativo_venta_id=I.operativo_venta_id AND O.campania_venta_id=I.campania_venta_id))
  THROW 51000,N'El operativo no corresponde a la campaña.',1;
 -- No sumar monedas diferentes. Se usa la moneda del precio que respalda cada entrega.
 IF EXISTS(SELECT 1 FROM inserted I WHERE I.estado=1 AND I.estado_proceso IN('REGISTRADO','CONFIRMADO') AND EXISTS(
  SELECT 1 FROM comercial.OperativoVenta O JOIN comercial.OperativoSocio OS ON OS.operativo_venta_id=O.operativo_venta_id
  JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
  JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1
  LEFT JOIN comercial.PrecioComercial P ON P.precio_comercial_id=D.precio_comercial_id
  WHERE O.campania_venta_id=I.campania_venta_id AND (I.operativo_venta_id IS NULL OR O.operativo_venta_id=I.operativo_venta_id)
  AND P.precio_comercial_id IS NULL))
  THROW 51000,N'Complete los precios de las entregas antes de registrar el cobro.',1;
 ;WITH V AS(SELECT O.campania_venta_id,P.moneda,SUM(D.importe) total
  FROM comercial.OperativoVenta O JOIN comercial.OperativoSocio OS ON OS.operativo_venta_id=O.operativo_venta_id
  JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
  JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1
  JOIN comercial.PrecioComercial P ON P.precio_comercial_id=D.precio_comercial_id
  GROUP BY O.campania_venta_id,P.moneda),
 C AS(SELECT campania_venta_id,moneda,SUM(importe) total FROM finanzas.CobroComprador WITH(READCOMMITTEDLOCK)
  WHERE estado=1 AND estado_proceso IN('REGISTRADO','CONFIRMADO') GROUP BY campania_venta_id,moneda)
 SELECT @lock=CASE WHEN EXISTS(SELECT 1 FROM C LEFT JOIN V ON V.campania_venta_id=C.campania_venta_id AND V.moneda=C.moneda
  WHERE C.total>COALESCE(V.total,0) AND EXISTS(SELECT 1 FROM inserted I WHERE I.campania_venta_id=C.campania_venta_id)) THEN -1 ELSE 0 END;
 IF @lock=-1 THROW 51100,N'DESCO_COBRO_EXCESO',1;
 -- Un cobro por operativo también debe respetar el importe de ese operativo.
 IF EXISTS(SELECT 1 FROM (SELECT DISTINCT operativo_venta_id,moneda FROM inserted WHERE operativo_venta_id IS NOT NULL) I
  OUTER APPLY(SELECT SUM(D.importe) total FROM comercial.OperativoSocio OS
   JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
   JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1
   JOIN comercial.PrecioComercial P ON P.precio_comercial_id=D.precio_comercial_id AND P.moneda=I.moneda
   WHERE OS.operativo_venta_id=I.operativo_venta_id) V
  OUTER APPLY(SELECT SUM(C.importe) total FROM finanzas.CobroComprador C WITH(READCOMMITTEDLOCK)
   WHERE C.operativo_venta_id=I.operativo_venta_id AND C.moneda=I.moneda AND C.estado=1 AND C.estado_proceso IN('REGISTRADO','CONFIRMADO')) C
  WHERE C.total>COALESCE(V.total,0)) THROW 51100,N'DESCO_COBRO_EXCESO',1;
END;
GO
