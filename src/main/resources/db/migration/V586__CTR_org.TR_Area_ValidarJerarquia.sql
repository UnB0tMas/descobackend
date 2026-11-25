IF OBJECT_ID(N'[org].[TR_Area_ValidarJerarquia]') IS NOT NULL
    DROP TRIGGER [org].[TR_Area_ValidarJerarquia];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : org.TR_Area_ValidarJerarquia
' Descripción            : Valida relaciones jerárquicas de áreas.
' Aplicativo / Módulo    : DESCO / Organización
*******************************************************************************************************/
CREATE TRIGGER [org].[TR_Area_ValidarJerarquia]
ON [org].[Area]
AFTER INSERT, UPDATE
AS
BEGIN
    IF ROWCOUNT_BIG() = 0 RETURN;
    SET NOCOUNT ON;
    IF NOT (UPDATE(area_padre_id) OR UPDATE(empresa_id)) RETURN;
    DECLARE @nBloqueo BIGINT, @bCiclo BIT = 0;
    -- La jerarquía es pequeña; serializar su inspección evita dos enlaces cruzados simultáneos.
    SELECT @nBloqueo = COUNT_BIG(*) FROM [org].[Area] WITH (UPDLOCK,HOLDLOCK);
    ;WITH Ruta AS
    (
        SELECT I.area_id AS origen, I.area_id, I.area_padre_id,
               CONVERT(VARCHAR(MAX), '/' + CONVERT(VARCHAR(20),I.area_id) + '/') AS ruta,
               CONVERT(BIT,0) AS ciclo
        FROM inserted I
        UNION ALL
        SELECT R.origen, A.area_id, A.area_padre_id,
               CONVERT(VARCHAR(MAX), R.ruta + CONVERT(VARCHAR(20),A.area_id) + '/'),
               CONVERT(BIT, CASE WHEN CHARINDEX('/'+CONVERT(VARCHAR(20),A.area_id)+'/',R.ruta)>0 THEN 1 ELSE 0 END)
        FROM Ruta R JOIN [org].[Area] A ON A.area_id = R.area_padre_id
        WHERE R.ciclo = 0
    )
    SELECT @bCiclo = CONVERT(BIT, MAX(CONVERT(INT,ciclo))) FROM Ruta
    OPTION (MAXRECURSION 32767);
    IF @bCiclo = 1 THROW 51001, N'DESCO_AREA_CICLICA', 1;
END;
GO
