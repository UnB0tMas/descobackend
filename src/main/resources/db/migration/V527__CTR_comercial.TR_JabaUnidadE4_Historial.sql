IF OBJECT_ID(N'[comercial].[TR_JabaUnidadE4_Historial]') IS NOT NULL
    DROP TRIGGER [comercial].[TR_JabaUnidadE4_Historial];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : comercial.TR_JabaUnidadE4_Historial
' Descripción            : Controla las modificaciones de jaba unidad e4 historial mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE TRIGGER comercial.TR_JabaUnidadE4_Historial
ON comercial.JabaUnidadE4 AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO comercial.JabaPesajeHistorialE4
        (unidad_id,version_anterior,version_nueva,estado_anterior,estado_nuevo,
         peso_anterior,peso_nuevo,tara_anterior,tara_nueva,precio_anterior,precio_nuevo,motivo,usuario_id)
    SELECT I.unidad_id,D.version,I.version,D.pesaje_estado,I.pesaje_estado,
        D.peso_bruto_kg,I.peso_bruto_kg,D.tara_kg,I.tara_kg,D.precio_base,I.precio_base,
        TRY_CONVERT(NVARCHAR(400),SESSION_CONTEXT(N'e4_motivo')),I.usuario_pesaje_id
    FROM inserted I JOIN deleted D ON D.unidad_id=I.unidad_id
    WHERE I.pesaje_estado<>D.pesaje_estado OR ISNULL(I.peso_bruto_kg,-1)<>ISNULL(D.peso_bruto_kg,-1)
       OR ISNULL(I.tara_kg,-1)<>ISNULL(D.tara_kg,-1)
       OR ISNULL(I.precio_base,-1)<>ISNULL(D.precio_base,-1);
END;
GO
