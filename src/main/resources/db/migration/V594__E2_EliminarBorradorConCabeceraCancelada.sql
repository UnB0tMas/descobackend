/* El borrador eliminado conserva su trazabilidad y cancela su cabecera histórica. */
CREATE OR ALTER TRIGGER campo.TR_E2_TransicionSalidaAutorizada
ON campo.SalidaCampo AFTER UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
   SELECT 1 FROM inserted I JOIN deleted D ON D.salida_campo_id=I.salida_campo_id
   LEFT JOIN campo.SalidaE2 E ON E.salida_campo_id=I.salida_campo_id
   WHERE I.estado_proceso<>D.estado_proceso AND
    ((I.estado_proceso='EN_CURSO' AND (E.salida_campo_id IS NULL OR E.estado<>'EN_EJECUCION'))
    OR (I.estado_proceso='FINALIZADA' AND (E.salida_campo_id IS NULL OR E.estado<>'CERRADA'))
    OR (I.estado_proceso='CANCELADA' AND (E.salida_campo_id IS NULL OR E.estado NOT IN('CANCELADA','ELIMINADA'))))
 ) THROW 51035,N'DESCO_SALIDA_NO_AUTORIZADA',1;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.salida_campo_id=I.salida_campo_id
    JOIN campo.SalidaE2 E ON E.salida_campo_id=I.salida_campo_id
    WHERE E.estado IN('APROBADA','EN_EJECUCION','EN_RETORNO','CERRADA')
      AND (I.motivo_salida_id<>D.motivo_salida_id OR I.fecha_hora_programada<>D.fecha_hora_programada
        OR ISNULL(I.descripcion,N'')<>ISNULL(D.descripcion,N'') OR ISNULL(I.uot_id,0)<>ISNULL(D.uot_id,0)))
    THROW 51035,N'DESCO_SALIDA_APROBADA_INMUTABLE',1;
END;
GO
