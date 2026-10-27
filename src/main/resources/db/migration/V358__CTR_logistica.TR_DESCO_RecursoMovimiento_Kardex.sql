IF OBJECT_ID(N'[logistica].[TR_DESCO_RecursoMovimiento_Kardex]', N'TR') IS NOT NULL
    DROP TRIGGER [logistica].[TR_DESCO_RecursoMovimiento_Kardex];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : logistica.TR_DESCO_RecursoMovimiento_Kardex
' Descripción              : Mantiene el kardex de movimientos de recursos.
' Tabla asociada          : logistica.RecursoMovimiento
' Evento que lo dispara   : AFTER INSERT,UPDATE,DELETE
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE,DELETE sobre logistica.RecursoMovimiento.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[logistica].[TR_DESCO_RecursoMovimiento_Kardex]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_DESCO_RecursoMovimiento_Kardex
ON logistica.RecursoMovimiento AFTER INSERT,UPDATE,DELETE AS
BEGIN
 IF ROWCOUNT_BIG()=0 RETURN;
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM deleted) THROW 51100,N'DESCO_MOVIMIENTO_INMUTABLE',1;
 IF EXISTS(SELECT 1 FROM inserted WHERE tipo_movimiento='AJUSTE')
  THROW 51000,N'Registre una devolución o un consumo para ajustar el recurso.',1;
 IF EXISTS(SELECT 1 FROM inserted I JOIN logistica.RecursoProgramado R ON R.recurso_programado_id=I.recurso_programado_id
  WHERE I.estado<>1 OR R.estado<>1 OR R.estado_proceso<>'EN_EJECUCION'
   OR (R.bien_inventario_id IS NOT NULL AND (I.cantidad<>1 OR I.tipo_movimiento NOT IN('ASIGNACION','DEVOLUCION')))
   OR (R.suministro_id IS NOT NULL AND I.tipo_movimiento='ASIGNACION'))
  THROW 51100,N'DESCO_RECURSO_NO_DISPONIBLE',1;
 ;WITH D AS(SELECT recurso_programado_id,
  SUM(CASE WHEN tipo_movimiento IN('ASIGNACION','ENTREGA') THEN CONVERT(DECIMAL(19,3),cantidad) ELSE 0 END) entregada,
  SUM(CASE WHEN tipo_movimiento='DEVOLUCION' THEN CONVERT(DECIMAL(19,3),cantidad) ELSE 0 END) devuelta,
  SUM(CASE WHEN tipo_movimiento='CONSUMO' THEN CONVERT(DECIMAL(19,3),cantidad) ELSE 0 END) consumida
  FROM inserted GROUP BY recurso_programado_id)
 UPDATE R SET cantidad_entregada=R.cantidad_entregada+D.entregada,
  cantidad_devuelta=R.cantidad_devuelta+D.devuelta,cantidad_consumida=R.cantidad_consumida+D.consumida
 FROM logistica.RecursoProgramado R JOIN D ON D.recurso_programado_id=R.recurso_programado_id;
 INSERT logistica.SuministroMovimiento(suministro_id,recurso_programado_id,recurso_movimiento_id,
  tipo_movimiento,cantidad,fecha_hora,usuario_id,observacion,estado)
 SELECT R.suministro_id,I.recurso_programado_id,I.recurso_movimiento_id,
  CASE WHEN I.tipo_movimiento='ENTREGA' THEN 'SALIDA' ELSE 'DEVOLUCION' END,
  I.cantidad,I.fecha_hora,I.usuario_id,I.observacion,1
 FROM inserted I JOIN logistica.RecursoProgramado R ON R.recurso_programado_id=I.recurso_programado_id
 WHERE R.suministro_id IS NOT NULL AND I.tipo_movimiento IN('ENTREGA','DEVOLUCION');
 -- El consumo no vuelve a descontar: la salida física se contabilizó al entregar.
 UPDATE R SET estado_proceso='COMPLETADO' FROM logistica.RecursoProgramado R
 WHERE R.estado_proceso='EN_EJECUCION' AND R.cantidad_entregada>0 AND R.cantidad_pendiente=0
 AND EXISTS(SELECT 1 FROM inserted I WHERE I.recurso_programado_id=R.recurso_programado_id);
 UPDATE B SET estado_bien='DISPONIBLE' FROM logistica.BienInventario B
 JOIN logistica.RecursoProgramado R ON R.bien_inventario_id=B.bien_inventario_id
 WHERE R.estado_proceso='COMPLETADO' AND B.estado_bien='ASIGNADO'
 AND EXISTS(SELECT 1 FROM inserted I WHERE I.recurso_programado_id=R.recurso_programado_id AND I.tipo_movimiento='DEVOLUCION');
END;
GO
