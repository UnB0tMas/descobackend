IF OBJECT_ID(N'[reporte].[PA_Excel_Trabajo_Reservar]') IS NOT NULL
    DROP PROCEDURE [reporte].[PA_Excel_Trabajo_Reservar];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : reporte.PA_Excel_Trabajo_Reservar
' Descripción            : Reserva el siguiente trabajo y devuelve su propietario para el aviso SSE.
' Aplicativo / Módulo    : DESCO / reporte
*******************************************************************************************************/
CREATE PROCEDURE reporte.PA_Excel_Trabajo_Reservar
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    ;WITH C AS (
        SELECT TOP (1)
            trabajo_id, usuario_id, uot_id, codigo, fecha_desde, fecha_hasta, estado, actualizado_utc
        FROM reporte.TrabajoExcel WITH (UPDLOCK, READPAST, ROWLOCK)
        WHERE estado = 'PENDIENTE'
            OR (estado = 'PROCESANDO' AND actualizado_utc < DATEADD(HOUR, -2, SYSUTCDATETIME()))
        ORDER BY creado_utc, trabajo_id
    )
    UPDATE C
    SET estado = 'PROCESANDO', actualizado_utc = SYSUTCDATETIME()
    OUTPUT inserted.trabajo_id AS id, inserted.codigo, inserted.fecha_desde AS desde,
        inserted.fecha_hasta AS hasta, inserted.usuario_id AS usuarioId, inserted.uot_id AS uotId;
END;
GO
