IF OBJECT_ID(N'[logistica].[TR_DESCO_RecursoProgramado_Reserva]', N'TR') IS NOT NULL
    DROP TRIGGER [logistica].[TR_DESCO_RecursoProgramado_Reserva];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : logistica.TR_DESCO_RecursoProgramado_Reserva
' Descripción              : Controla reservas de recursos programados.
' Tabla asociada          : logistica.RecursoProgramado
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
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE,DELETE sobre logistica.RecursoProgramado.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[logistica].[TR_DESCO_RecursoProgramado_Reserva]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_DESCO_RecursoProgramado_Reserva
ON logistica.RecursoProgramado AFTER INSERT,UPDATE,DELETE AS
BEGIN
 IF ROWCOUNT_BIG()=0 RETURN;
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM deleted D LEFT JOIN inserted I ON I.recurso_programado_id=D.recurso_programado_id WHERE I.recurso_programado_id IS NULL)
  THROW 51100,N'DESCO_MOVIMIENTO_INMUTABLE',1;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.recurso_programado_id=I.recurso_programado_id
  WHERE D.cantidad_entregada>0 AND
   (ISNULL(I.bien_inventario_id,0)<>ISNULL(D.bien_inventario_id,0) OR ISNULL(I.suministro_id,0)<>ISNULL(D.suministro_id,0)
    OR I.cantidad_programada<>D.cantidad_programada OR ISNULL(I.campania_venta_id,0)<>ISNULL(D.campania_venta_id,0)
    OR ISNULL(I.operativo_venta_id,0)<>ISNULL(D.operativo_venta_id,0) OR ISNULL(I.salida_campo_id,0)<>ISNULL(D.salida_campo_id,0)))
  THROW 51100,N'DESCO_MOVIMIENTO_INMUTABLE',1;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.recurso_programado_id=I.recurso_programado_id
  WHERE I.estado_proceso<>D.estado_proceso AND NOT
   ((D.estado_proceso='PROGRAMADO' AND I.estado_proceso IN('EN_EJECUCION','CANCELADO'))
     OR (D.estado_proceso='EN_EJECUCION' AND I.estado_proceso='COMPLETADO')))
  THROW 51100,N'DESCO_RECURSO_NO_DISPONIBLE',1;
 IF EXISTS(SELECT 1 FROM inserted I LEFT JOIN deleted D ON D.recurso_programado_id=I.recurso_programado_id
  WHERE D.recurso_programado_id IS NULL AND (I.estado_proceso<>'PROGRAMADO' OR I.cantidad_entregada<>0 OR I.cantidad_devuelta<>0 OR I.cantidad_consumida<>0))
  THROW 51100,N'DESCO_RECURSO_NO_DISPONIBLE',1;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.recurso_programado_id=I.recurso_programado_id
  WHERE D.estado=1 AND I.estado=0 AND (D.estado_proceso='EN_EJECUCION' OR D.cantidad_pendiente>0))
  THROW 51100,N'DESCO_RECURSO_NO_DISPONIBLE',1;
 IF EXISTS(SELECT 1 FROM inserted I LEFT JOIN logistica.Suministro S ON S.suministro_id=I.suministro_id
  WHERE I.estado=1 AND I.estado_proceso IN('PROGRAMADO','EN_EJECUCION') AND I.suministro_id IS NOT NULL AND S.estado<>1)
  THROW 51100,N'DESCO_RECURSO_NO_DISPONIBLE',1;
 IF EXISTS(SELECT 1 FROM inserted WHERE (bien_inventario_id IS NOT NULL AND cantidad_programada<>1)
  OR (estado_proceso='COMPLETADO' AND (cantidad_entregada<=0 OR cantidad_pendiente<>0)))
  THROW 51100,N'DESCO_RECURSO_EXCESO',1;
 ;WITH X AS(
  SELECT suministro_id,CONVERT(DECIMAL(19,3),cantidad_programada) cantidad FROM inserted WHERE suministro_id IS NOT NULL AND estado=1 AND estado_proceso='PROGRAMADO'
  UNION ALL SELECT suministro_id,-CONVERT(DECIMAL(19,3),cantidad_programada) FROM deleted WHERE suministro_id IS NOT NULL AND estado=1 AND estado_proceso='PROGRAMADO'),
 D AS(SELECT suministro_id,SUM(cantidad) cantidad FROM X GROUP BY suministro_id)
 UPDATE S SET stock_reservado=S.stock_reservado+D.cantidad,fecha_actualizacion=SYSUTCDATETIME()
 FROM logistica.SuministroSaldo S JOIN D ON D.suministro_id=S.suministro_id WHERE D.cantidad<>0;
 IF EXISTS(SELECT 1 FROM inserted I WHERE I.suministro_id IS NOT NULL AND NOT EXISTS
  (SELECT 1 FROM logistica.SuministroSaldo S WHERE S.suministro_id=I.suministro_id))
  THROW 51100,N'DESCO_KARDEX_REVISAR',1;
END;
GO
