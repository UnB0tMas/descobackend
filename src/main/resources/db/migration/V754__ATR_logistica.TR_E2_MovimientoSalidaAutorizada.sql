IF OBJECT_ID(N'[logistica].[TR_E2_MovimientoSalidaAutorizada]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_E2_MovimientoSalidaAutorizada];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_E2_MovimientoSalidaAutorizada
' Descripción            : Controla las modificaciones de e2 movimiento salida autorizada mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / logistica
*******************************************************************************************************/
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
        (I.tipo_movimiento IN('ASIGNACION','ENTREGA') AND E.estado NOT IN('APROBADA','EN_EJECUCION')) OR
        (I.tipo_movimiento='DEVOLUCION' AND E.estado NOT IN('EN_RETORNO','CERRADA')) OR
        (I.tipo_movimiento='CONSUMO' AND E.estado NOT IN('EN_RETORNO','CERRADA','EN_EJECUCION')) OR
        (I.tipo_movimiento='DEVOLUCION' AND NOT EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 ER
           WHERE ER.recurso_programado_id=R.recurso_programado_id
             AND ((ER.resultado_validado='CONFORME' AND ER.estado='VALIDADO')
               OR (ER.suministro_id IS NOT NULL AND ER.cantidad_devuelta_validada>0 AND ER.estado IN('VALIDADO','INCIDENCIA'))))) OR
        (I.tipo_movimiento='CONSUMO' AND NOT EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 ER
           WHERE ER.recurso_programado_id=R.recurso_programado_id
             AND ER.suministro_id IS NOT NULL AND ER.estado='VALIDADO' AND ER.resultado_validado='CONSUMIDO')
           AND NOT (E.estado='EN_EJECUCION' AND EXISTS
               (SELECT 1 FROM campo.SalidaUsoSuministroE2 SU
                WHERE SU.recurso_programado_id=R.recurso_programado_id
                  AND SU.usuario_id=I.usuario_id AND SU.cantidad=I.cantidad
                  AND I.observacion=CONCAT(N'E2_USO:',SU.salida_uso_suministro_id)
                  AND SU.recurso_movimiento_id IS NULL))))
 ) THROW 51035,N'DESCO_SALIDA_NO_AUTORIZADA',1;
END;
GO
