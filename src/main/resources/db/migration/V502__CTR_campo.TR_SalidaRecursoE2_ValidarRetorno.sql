IF OBJECT_ID(N'[campo].[TR_SalidaRecursoE2_ValidarRetorno]') IS NOT NULL
    DROP TRIGGER [campo].[TR_SalidaRecursoE2_ValidarRetorno];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : campo.TR_SalidaRecursoE2_ValidarRetorno
' Descripción            : Valida las reglas de salida recurso e2 validar retorno al modificar registros.
' Aplicativo / Módulo    : DESCO / campo
*******************************************************************************************************/
CREATE   TRIGGER campo.TR_SalidaRecursoE2_ValidarRetorno
ON campo.SalidaRecursoE2
AFTER UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (SELECT 1 FROM inserted I
    JOIN deleted D ON D.solicitud_recurso_id=I.solicitud_recurso_id
    WHERE I.resultado_declarado IS NOT NULL AND D.resultado_declarado IS NULL
      AND NULLIF(TRIM(I.observacion),N'') IS NULL)
    THROW 51332,N'Indique cómo retorna cada recurso y cuánto consumible se utilizó.',1;
END;
GO
