-- E2 read-only verification after T05/T06/T07 API scenarios and V441.
SET NOCOUNT ON;
IF EXISTS (
  SELECT 1 FROM campo.SalidaE2 E JOIN campo.SalidaCampo S ON S.salida_campo_id=E.salida_campo_id
  WHERE (E.estado IN('EN_EJECUCION','EN_RETORNO','CERRADA') AND E.fecha_aprobacion IS NULL)
     OR (E.estado='CERRADA' AND (E.fecha_fin_prevista IS NULL OR S.fecha_hora_retorno_real IS NULL))
) THROW 52011,N'E2: salida ejecutada sin aprobación o cerrada sin fecha.',1;
IF EXISTS (
  SELECT 1 FROM campo.SalidaRecursoE2 R JOIN logistica.BienInventario B
    ON B.bien_inventario_id=R.bien_inventario_id
  WHERE R.estado IN('ENTREGADO','INCIDENCIA') AND B.estado_bien='DISPONIBLE'
) THROW 52012,N'E2: bien prestado o en incidencia figura como disponible.',1;
IF EXISTS (
  SELECT A.bien_inventario_id
  FROM campo.SalidaRecursoE2 A JOIN campo.SalidaE2 E ON E.salida_campo_id=A.salida_campo_id
  WHERE E.estado IN('APROBADA','EN_EJECUCION','EN_RETORNO') AND A.estado IN('SOLICITADO','ENTREGADO')
  GROUP BY A.bien_inventario_id HAVING COUNT_BIG(*)>1
) THROW 52013,N'E2: hay reservas exclusivas simultáneas.',1;
IF EXISTS (
  SELECT M.recurso_programado_id,M.tipo_movimiento FROM logistica.RecursoMovimiento M
  JOIN campo.SalidaRecursoE2 R ON R.recurso_programado_id=M.recurso_programado_id
  WHERE M.tipo_movimiento IN('ASIGNACION','DEVOLUCION')
  GROUP BY M.recurso_programado_id,M.tipo_movimiento HAVING COUNT_BIG(*)>1
) THROW 52014,N'E2: movimiento físico duplicado.',1;
SELECT N'E2: invariantes de autorización, exclusividad y devolución verificadas' AS resultado;
