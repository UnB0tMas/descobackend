IF OBJECT_ID(N'[prod].[TR_PredioTitularidad_ValidarTotal]') IS NOT NULL
    DROP TRIGGER [prod].[TR_PredioTitularidad_ValidarTotal];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : prod.TR_PredioTitularidad_ValidarTotal
' Descripción            : Valida el total de participaciones de titularidad de un predio.
' Aplicativo / Módulo    : DESCO / Producción
*******************************************************************************************************/
CREATE TRIGGER [prod].[TR_PredioTitularidad_ValidarTotal]
ON [prod].[PredioTitularidad]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    IF ROWCOUNT_BIG() = 0 RETURN;
    SET NOCOUNT ON;
    DECLARE @nBloqueo BIGINT;
    -- Se bloquean los predios afectados, no solo la fila individual de titularidad.
    SELECT @nBloqueo = COUNT_BIG(*)
    FROM [prod].[Predio] P WITH (UPDLOCK,HOLDLOCK)
    WHERE EXISTS (SELECT 1 FROM inserted I WHERE I.predio_id=P.predio_id)
       OR EXISTS (SELECT 1 FROM deleted D WHERE D.predio_id=P.predio_id);
    IF EXISTS
    (
        SELECT T.predio_id FROM [prod].[PredioTitularidad] T WITH (UPDLOCK,HOLDLOCK)
        WHERE T.estado=1 AND T.fecha_hasta IS NULL
          AND (EXISTS (SELECT 1 FROM inserted I WHERE I.predio_id=T.predio_id)
            OR EXISTS (SELECT 1 FROM deleted D WHERE D.predio_id=T.predio_id))
        GROUP BY T.predio_id
        HAVING SUM(CONVERT(DECIMAL(19,2),COALESCE(T.porcentaje,0))) > 100
    ) THROW 51002, N'DESCO_TITULARIDAD_EXCESO', 1;
END;
GO
