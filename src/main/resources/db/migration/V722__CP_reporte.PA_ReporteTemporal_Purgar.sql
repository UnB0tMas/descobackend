IF OBJECT_ID(N'[reporte].[PA_ReporteTemporal_Purgar]', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE [reporte].[PA_ReporteTemporal_Purgar];
END;
GO

-- Retira trabajos temporales abandonados y devuelve sus archivos para eliminación.
CREATE PROCEDURE reporte.PA_ReporteTemporal_Purgar
    @nLote INT = 200
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @nLote IS NULL OR @nLote < 1 OR @nLote > 500
    BEGIN
        SET @nLote = 200;
    END;

    DECLARE @Archivos TABLE (clave NVARCHAR(250) NULL);
    DECLARE @Limite DATETIME2(0) = DATEADD(HOUR, -48, SYSUTCDATETIME());

    BEGIN TRANSACTION;

    DELETE TOP (@nLote) FROM reporte.TrabajoExcel
    OUTPUT deleted.archivo_clave INTO @Archivos (clave)
    WHERE actualizado_utc < @Limite
      AND estado IN ('PENDIENTE', 'PROCESANDO', 'LISTO', 'ERROR');

    DELETE TOP (@nLote) FROM reporte.TrabajoEspecial
    OUTPUT deleted.archivo_clave INTO @Archivos (clave)
    WHERE actualizado_utc < @Limite
      AND estado IN ('PENDIENTE', 'PROCESANDO', 'LISTO', 'ERROR');

    COMMIT TRANSACTION;

    SELECT A.clave
    FROM @Archivos A
    WHERE A.clave IS NOT NULL AND A.clave <> N'';
END;
GO
