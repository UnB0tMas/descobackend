IF OBJECT_ID(N'[logistica].[TR_E2_ReservaSalidaAutorizada]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_E2_ReservaSalidaAutorizada];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_E2_ReservaSalidaAutorizada
' Descripción            : Controla las modificaciones de e2 reserva salida autorizada mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / logistica
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_E2_ReservaSalidaAutorizada
ON logistica.RecursoProgramado AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
    SELECT 1 FROM inserted I
    LEFT JOIN campo.SalidaE2 E ON E.salida_campo_id=I.salida_campo_id
    WHERE I.salida_campo_id IS NOT NULL AND I.estado=1 AND I.estado_proceso IN('PROGRAMADO','EN_EJECUCION')
      AND (E.salida_campo_id IS NULL OR E.estado NOT IN('APROBADA','EN_EJECUCION','EN_RETORNO')
       OR NOT EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 R
             WHERE R.salida_campo_id=I.salida_campo_id
               AND ((I.bien_inventario_id IS NOT NULL AND R.bien_inventario_id=I.bien_inventario_id)
                 OR (I.suministro_id IS NOT NULL AND R.suministro_id=I.suministro_id))))
 ) THROW 51035,N'DESCO_SALIDA_NO_AUTORIZADA',1;
END;
GO
