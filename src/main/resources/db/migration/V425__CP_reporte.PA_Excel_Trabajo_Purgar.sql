IF OBJECT_ID(N'[reporte].[PA_Excel_Trabajo_Purgar]') IS NOT NULL
    DROP PROCEDURE [reporte].[PA_Excel_Trabajo_Purgar];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : reporte.PA_Excel_Trabajo_Purgar
' Descripción            : Ejecuta el proceso de excel trabajo purgar.
' Aplicativo / Módulo    : DESCO / reporte
*******************************************************************************************************/
CREATE   PROCEDURE reporte.PA_Excel_Trabajo_Purgar
AS
BEGIN
 SET NOCOUNT ON;
 DELETE FROM reporte.TrabajoExcel OUTPUT deleted.archivo_clave
 WHERE estado IN('LISTO','ERROR') AND creado_utc<DATEADD(DAY,-30,SYSUTCDATETIME());
END;
GO
