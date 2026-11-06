-- E2: protege el camino legado: una visita no puede iniciar automáticamente salidas pendientes.
-- El trigger valida la misma condición sin depender del controlador que invoque el INSERT.
IF OBJECT_ID(N'campo.TR_E2_VisitaAutorizada', N'TR') IS NOT NULL DROP TRIGGER campo.TR_E2_VisitaAutorizada;
GO
CREATE TRIGGER campo.TR_E2_VisitaAutorizada
ON campo.VisitaTecnica AFTER INSERT AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
    SELECT 1 FROM inserted I
    JOIN campo.SalidaParticipante SP ON SP.salida_participante_id=I.salida_participante_id
    JOIN campo.SalidaCampo SC ON SC.salida_campo_id=SP.salida_campo_id
    LEFT JOIN campo.SalidaE2 E ON E.salida_campo_id=SC.salida_campo_id
    WHERE E.estado<>'EN_EJECUCION' OR E.salida_campo_id IS NULL OR SC.estado_proceso<>'EN_CURSO'
      OR NOT EXISTS(SELECT 1 FROM campo.SalidaDestinoE2 D
          WHERE D.salida_campo_id=SC.salida_campo_id AND D.predio_id=I.predio_id)
 ) THROW 51035,N'DESCO_SALIDA_NO_AUTORIZADA',1;
END;
GO
IF OBJECT_ID(N'campo.TR_E2_TransicionSalidaAutorizada', N'TR') IS NOT NULL DROP TRIGGER campo.TR_E2_TransicionSalidaAutorizada;
GO
CREATE TRIGGER campo.TR_E2_TransicionSalidaAutorizada
ON campo.SalidaCampo AFTER UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
   SELECT 1 FROM inserted I JOIN deleted D ON D.salida_campo_id=I.salida_campo_id
   LEFT JOIN campo.SalidaE2 E ON E.salida_campo_id=I.salida_campo_id
   WHERE I.estado_proceso<>D.estado_proceso AND
    ((I.estado_proceso='EN_CURSO' AND (E.salida_campo_id IS NULL OR E.estado<>'EN_EJECUCION'))
    OR (I.estado_proceso='FINALIZADA' AND (E.salida_campo_id IS NULL OR E.estado<>'CERRADA'))
    OR (I.estado_proceso='CANCELADA' AND (E.salida_campo_id IS NULL OR E.estado<>'CANCELADA')))
 ) THROW 51035,N'DESCO_SALIDA_NO_AUTORIZADA',1;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.salida_campo_id=I.salida_campo_id
    JOIN campo.SalidaE2 E ON E.salida_campo_id=I.salida_campo_id
    WHERE E.estado IN('APROBADA','EN_EJECUCION','EN_RETORNO','CERRADA')
      AND (I.motivo_salida_id<>D.motivo_salida_id OR I.fecha_hora_programada<>D.fecha_hora_programada
        OR ISNULL(I.descripcion,N'')<>ISNULL(D.descripcion,N'') OR ISNULL(I.uot_id,0)<>ISNULL(D.uot_id,0)))
    THROW 51035,N'DESCO_SALIDA_APROBADA_INMUTABLE',1;
END;
GO
IF OBJECT_ID(N'logistica.TR_E2_ReservaSalidaAutorizada', N'TR') IS NOT NULL DROP TRIGGER logistica.TR_E2_ReservaSalidaAutorizada;
GO
CREATE TRIGGER logistica.TR_E2_ReservaSalidaAutorizada
ON logistica.RecursoProgramado AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
    SELECT 1 FROM inserted I
    LEFT JOIN campo.SalidaE2 E ON E.salida_campo_id=I.salida_campo_id
    WHERE I.salida_campo_id IS NOT NULL AND I.estado=1 AND I.estado_proceso IN('PROGRAMADO','EN_EJECUCION')
      AND (E.salida_campo_id IS NULL OR E.estado NOT IN('APROBADA','EN_EJECUCION','EN_RETORNO')
       OR (I.bien_inventario_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 R
             WHERE R.salida_campo_id=I.salida_campo_id AND R.bien_inventario_id=I.bien_inventario_id)))
 ) THROW 51035,N'DESCO_SALIDA_NO_AUTORIZADA',1;
END;
GO
IF OBJECT_ID(N'logistica.TR_E2_MovimientoSalidaAutorizada', N'TR') IS NOT NULL DROP TRIGGER logistica.TR_E2_MovimientoSalidaAutorizada;
GO
CREATE TRIGGER logistica.TR_E2_MovimientoSalidaAutorizada
ON logistica.RecursoMovimiento AFTER INSERT AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
    SELECT 1 FROM inserted I
    JOIN logistica.RecursoProgramado R ON R.recurso_programado_id=I.recurso_programado_id
    LEFT JOIN campo.SalidaE2 E ON E.salida_campo_id=R.salida_campo_id
    WHERE R.salida_campo_id IS NOT NULL
      AND (E.salida_campo_id IS NULL OR
        NOT EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 ER WHERE ER.recurso_programado_id=R.recurso_programado_id) OR
        (I.tipo_movimiento='DEVOLUCION' AND NOT EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 ER
           WHERE ER.recurso_programado_id=R.recurso_programado_id AND ER.estado='VALIDADO' AND ER.resultado_validado='CONFORME')) OR
        (I.tipo_movimiento IN('ASIGNACION','ENTREGA') AND E.estado NOT IN('APROBADA','EN_EJECUCION')) OR
        (I.tipo_movimiento='DEVOLUCION' AND E.estado NOT IN('EN_RETORNO','CERRADA')))
 ) THROW 51035,N'DESCO_SALIDA_NO_AUTORIZADA',1;
END;
GO
