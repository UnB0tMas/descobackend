IF OBJECT_ID(N'[org].[TR_UOT_ValidarJerarquia]', N'TR') IS NOT NULL
    DROP TRIGGER [org].[TR_UOT_ValidarJerarquia];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : org.TR_UOT_ValidarJerarquia
' Descripción              : Valida la jerarquía de las UOT.
' Tabla asociada          : org.UOT
' Evento que lo dispara   : AFTER INSERT,UPDATE
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Organización
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE sobre org.UOT.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[org].[TR_UOT_ValidarJerarquia]', N'TR');
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
