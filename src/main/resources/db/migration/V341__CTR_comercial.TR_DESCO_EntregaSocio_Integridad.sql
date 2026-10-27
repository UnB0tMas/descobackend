IF OBJECT_ID(N'[comercial].[TR_DESCO_EntregaSocio_Integridad]', N'TR') IS NOT NULL
    DROP TRIGGER [comercial].[TR_DESCO_EntregaSocio_Integridad];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : comercial.TR_DESCO_EntregaSocio_Integridad
' Descripción              : Controla la integridad de las entregas registradas por socio.
' Tabla asociada          : comercial.EntregaSocio
' Evento que lo dispara   : AFTER INSERT,UPDATE,DELETE
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Comercial
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE,DELETE sobre comercial.EntregaSocio.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[comercial].[TR_DESCO_EntregaSocio_Integridad]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER comercial.TR_DESCO_EntregaSocio_Integridad
ON comercial.EntregaSocio AFTER INSERT,UPDATE,DELETE AS
BEGIN
 IF ROWCOUNT_BIG()=0 RETURN;
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM deleted D LEFT JOIN inserted I ON I.entrega_socio_id=D.entrega_socio_id WHERE I.entrega_socio_id IS NULL)
  THROW 51000,N'Anule la entrega para conservar su historial.',1;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.entrega_socio_id=I.entrega_socio_id
  WHERE D.estado_proceso='CONFIRMADA' AND (I.operativo_socio_id<>D.operativo_socio_id
   OR ISNULL(I.predio_id,0)<>ISNULL(D.predio_id,0) OR I.codigo_lote<>D.codigo_lote
   OR I.peso_bruto_kg<>D.peso_bruto_kg OR I.tara_kg<>D.tara_kg OR I.peso_rechazado_kg<>D.peso_rechazado_kg
   OR I.fecha_hora<>D.fecha_hora OR I.estado_control_calidad<>D.estado_control_calidad))
  THROW 51000,N'La entrega confirmada no admite cambios de cantidades ni de origen.',1;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.entrega_socio_id=I.entrega_socio_id
  WHERE I.estado_proceso<>D.estado_proceso AND NOT
   ((D.estado_proceso='REGISTRADA' AND I.estado_proceso IN('CONFIRMADA','ANULADA'))
    OR (D.estado_proceso='CONFIRMADA' AND I.estado_proceso='ANULADA')))
  THROW 51000,N'La entrega no está disponible para esta acción.',1;
 DECLARE @C TABLE(id BIGINT PRIMARY KEY);
 INSERT @C SELECT DISTINCT O.campania_venta_id FROM comercial.OperativoVenta O
 JOIN comercial.OperativoSocio OS ON OS.operativo_venta_id=O.operativo_venta_id
 WHERE EXISTS(SELECT 1 FROM inserted I WHERE I.operativo_socio_id=OS.operativo_socio_id)
 OR EXISTS(SELECT 1 FROM deleted D WHERE D.operativo_socio_id=OS.operativo_socio_id);
 DECLARE @lock BIGINT;
 SELECT @lock=C.campania_venta_id FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK) JOIN @C T ON T.id=C.campania_venta_id;
 IF EXISTS(SELECT 1 FROM inserted I OUTER APPLY(SELECT SUM(D.kilogramos) peso FROM comercial.EntregaDetalle D
  WHERE D.entrega_socio_id=I.entrega_socio_id AND D.estado=1) X
  WHERE I.estado=1 AND I.estado_proceso='CONFIRMADA' AND
   (I.estado_control_calidad='PENDIENTE' OR ABS(I.peso_aceptado_kg-COALESCE(X.peso,0))>0.001
    OR EXISTS(SELECT 1 FROM comercial.IncidenciaOperativa N WHERE N.entrega_socio_id=I.entrega_socio_id AND N.estado=1 AND N.estado_incidencia IN('ABIERTA','EN_REVISION'))))
  THROW 51000,N'Revise el peso, la clasificación y el control de calidad antes de confirmar.',1;
 IF EXISTS(SELECT 1 FROM inserted I WHERE I.estado=1 AND I.estado_proceso='CONFIRMADA' AND EXISTS(
  SELECT 1 FROM comercial.EntregaDetalle D WHERE D.entrega_socio_id=I.entrega_socio_id AND D.estado=1 AND D.precio_comercial_id IS NULL))
  THROW 51000,N'Complete los precios de la entrega antes de confirmar.',1;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.entrega_socio_id=I.entrega_socio_id
  WHERE D.estado_proceso='CONFIRMADA' AND D.estado=1 AND (I.estado_proceso<>'CONFIRMADA' OR I.estado<>1)
  AND EXISTS(SELECT 1 FROM comercial.EntregaDetalle E JOIN finanzas.LiquidacionDetalle LD ON LD.entrega_detalle_id=E.entrega_detalle_id
   JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=LD.liquidacion_socio_id
   WHERE E.entrega_socio_id=I.entrega_socio_id AND LD.estado=1 AND L.estado=1 AND L.estado_proceso IN('APROBADA','PAGADA_PARCIAL','PAGADA')))
  THROW 51000,N'La entrega pertenece a una liquidación aprobada.',1;
 ;WITH V AS(SELECT O.campania_venta_id,P.moneda,SUM(D.importe) total FROM comercial.OperativoVenta O
  JOIN @C T ON T.id=O.campania_venta_id JOIN comercial.OperativoSocio OS ON OS.operativo_venta_id=O.operativo_venta_id
  JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
  JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1
  JOIN comercial.PrecioComercial P ON P.precio_comercial_id=D.precio_comercial_id GROUP BY O.campania_venta_id,P.moneda),
  C AS(SELECT C.campania_venta_id,C.moneda,SUM(C.importe) total FROM finanzas.CobroComprador C WITH(READCOMMITTEDLOCK)
  JOIN @C T ON T.id=C.campania_venta_id WHERE C.estado=1 AND C.estado_proceso IN('REGISTRADO','CONFIRMADO') GROUP BY C.campania_venta_id,C.moneda)
 SELECT @lock=CASE WHEN EXISTS(SELECT 1 FROM C LEFT JOIN V ON V.campania_venta_id=C.campania_venta_id AND V.moneda=C.moneda
  WHERE C.total>COALESCE(V.total,0)) THEN -1 ELSE 0 END;
 IF @lock=-1 THROW 51000,N'La entrega respalda cobros registrados. Revise los cobros antes de anularla.',1;
 IF EXISTS(SELECT 1 FROM (SELECT DISTINCT OS.operativo_venta_id FROM comercial.OperativoSocio OS
  WHERE EXISTS(SELECT 1 FROM inserted I WHERE I.operativo_socio_id=OS.operativo_socio_id)
  OR EXISTS(SELECT 1 FROM deleted D WHERE D.operativo_socio_id=OS.operativo_socio_id)) O
  CROSS APPLY(SELECT C.moneda,SUM(C.importe) total FROM finanzas.CobroComprador C WITH(READCOMMITTEDLOCK)
   WHERE C.operativo_venta_id=O.operativo_venta_id AND C.estado=1 AND C.estado_proceso IN('REGISTRADO','CONFIRMADO') GROUP BY C.moneda) C
  OUTER APPLY(SELECT SUM(D.importe) total FROM comercial.OperativoSocio OS
   JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
   JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1
   JOIN comercial.PrecioComercial P ON P.precio_comercial_id=D.precio_comercial_id AND P.moneda=C.moneda
   WHERE OS.operativo_venta_id=O.operativo_venta_id) V WHERE C.total>COALESCE(V.total,0))
  THROW 51000,N'La entrega respalda cobros registrados. Revise los cobros antes de anularla.',1;
END;
GO
