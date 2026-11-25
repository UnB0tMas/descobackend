IF OBJECT_ID(N'[campo].[TR_SalidaRecursoE2_ValidarEntrega]') IS NOT NULL
    DROP TRIGGER [campo].[TR_SalidaRecursoE2_ValidarEntrega];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : campo.TR_SalidaRecursoE2_ValidarEntrega
' Descripción            : Valida las reglas de salida recurso e2 validar entrega al modificar registros.
' Aplicativo / Módulo    : DESCO / campo
*******************************************************************************************************/
CREATE   TRIGGER campo.TR_SalidaRecursoE2_ValidarEntrega
ON campo.SalidaRecursoE2
AFTER UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
     SELECT 1 FROM inserted I
     JOIN deleted D ON D.solicitud_recurso_id=I.solicitud_recurso_id
     WHERE I.estado='ENTREGADO' AND D.estado<>'ENTREGADO'
       AND NULLIF(TRIM(I.observacion_entrega),N'') IS NULL
 ) THROW 51308,N'Antes del despacho documente el estado de entrega de cada recurso.',1;
END;
GO
