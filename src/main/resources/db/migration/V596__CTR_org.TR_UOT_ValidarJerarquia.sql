IF OBJECT_ID(N'[org].[TR_UOT_ValidarJerarquia]') IS NOT NULL
    DROP TRIGGER [org].[TR_UOT_ValidarJerarquia];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : org.TR_UOT_ValidarJerarquia
' Descripción            : Valida la jerarquía de las UOT.
' Aplicativo / Módulo    : DESCO / Organización
*******************************************************************************************************/
CREATE TRIGGER org.TR_UOT_ValidarJerarquia
ON org.UOT AFTER INSERT,UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM inserted WHERE uot_padre_id=uot_id)
        THROW 51020,N'Una UOT no puede depender de sí misma.',1;

    ;WITH C AS
    (
        SELECT I.uot_id AS inicio,I.uot_padre_id AS actual,0 AS nivel FROM inserted I
        UNION ALL
        SELECT C.inicio,U.uot_padre_id,C.nivel+1
        FROM C JOIN org.UOT U ON U.uot_id=C.actual
        WHERE C.actual IS NOT NULL AND C.nivel<100
    )
    SELECT TOP(1) 1 AS ciclo INTO #ciclo FROM C WHERE actual=inicio;
    IF EXISTS(SELECT 1 FROM #ciclo)
        THROW 51021,N'La jerarquía de UOT produciría un ciclo.',1;
END;
GO
