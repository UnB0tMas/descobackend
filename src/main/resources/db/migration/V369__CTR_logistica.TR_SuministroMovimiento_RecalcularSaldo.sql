IF OBJECT_ID(N'[logistica].[TR_SuministroMovimiento_RecalcularSaldo]', N'TR') IS NOT NULL
    DROP TRIGGER [logistica].[TR_SuministroMovimiento_RecalcularSaldo];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : logistica.TR_SuministroMovimiento_RecalcularSaldo
' Descripción              : Recalcula saldos por movimientos de suministros.
' Tabla asociada          : logistica.SuministroMovimiento
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
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE,DELETE sobre logistica.SuministroMovimiento.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[logistica].[TR_SuministroMovimiento_RecalcularSaldo]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_SuministroMovimiento_RecalcularSaldo
ON logistica.SuministroMovimiento
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON;

 /* Las actualizaciones internas del propio trigger solo completan uot_id. */
 IF TRIGGER_NESTLEVEL()>1 RETURN;

 /* El Kardex es historico: no se edita. Una correccion se registra mediante
    un movimiento compensatorio/anulacion, nunca reescribiendo el movimiento. */
 IF EXISTS(SELECT 1 FROM deleted)
 BEGIN
     THROW 51100,N'DESCO_MOVIMIENTO_INMUTABLE',1;
 END;

 /* Una UOT explicita nunca puede diferir de la UOT propietaria del suministro. */
 IF EXISTS(
     SELECT 1
     FROM inserted I
     JOIN logistica.Suministro S ON S.suministro_id=I.suministro_id
     WHERE I.uot_id IS NOT NULL AND I.uot_id<>S.uot_id
 )
 BEGIN
     THROW 51091,N'El movimiento no pertenece a la UOT del suministro.',1;
 END;

 /* Compatibilidad con PA legacy que aun no envian uot_id. */
 UPDATE M
    SET uot_id=S.uot_id
 FROM logistica.SuministroMovimiento M
 JOIN inserted I ON I.suministro_movimiento_id=M.suministro_movimiento_id
 JOIN logistica.Suministro S ON S.suministro_id=M.suministro_id
 WHERE M.uot_id IS NULL;

 DECLARE @Afectados TABLE(suministro_id BIGINT PRIMARY KEY);
 INSERT @Afectados
 SELECT DISTINCT suministro_id FROM inserted WHERE suministro_id IS NOT NULL;
 INSERT @Afectados
 SELECT DISTINCT D.suministro_id
 FROM deleted D
 WHERE D.suministro_id IS NOT NULL
   AND NOT EXISTS(SELECT 1 FROM @Afectados A WHERE A.suministro_id=D.suministro_id);

 MERGE logistica.SuministroSaldo AS T
 USING(
   SELECT A.suministro_id,
          CONVERT(DECIMAL(19,3),COALESCE(SUM(
              CASE WHEN M.estado=1
                   THEN CASE WHEN M.tipo_movimiento IN('ENTRADA','DEVOLUCION','AJUSTE_ENTRADA','TRANSFERENCIA_ENTRADA')
                             THEN M.cantidad ELSE -M.cantidad END
                   ELSE 0 END),0)) stock_actual
   FROM @Afectados A
   LEFT JOIN logistica.SuministroMovimiento M ON M.suministro_id=A.suministro_id
   GROUP BY A.suministro_id
 ) S ON S.suministro_id=T.suministro_id
 WHEN MATCHED THEN UPDATE
      SET stock_actual=S.stock_actual,
          stock_reservado=CASE WHEN T.stock_reservado>S.stock_actual THEN 0 ELSE T.stock_reservado END,
          fecha_actualizacion=SYSUTCDATETIME()
 WHEN NOT MATCHED THEN
      INSERT(suministro_id,stock_actual,stock_reservado,fecha_actualizacion)
      VALUES(S.suministro_id,S.stock_actual,0,SYSUTCDATETIME());
END;
GO
