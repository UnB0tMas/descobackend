IF OBJECT_ID(N'[campo].[TR_E2_VisitaAutorizada]') IS NOT NULL
    DROP TRIGGER [campo].[TR_E2_VisitaAutorizada];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : campo.TR_E2_VisitaAutorizada
' Descripción            : Controla las modificaciones de e2 visita autorizada mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / campo
*******************************************************************************************************/
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
