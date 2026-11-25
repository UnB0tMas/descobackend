IF OBJECT_ID(N'[comercial].[PA_CampaniaVenta_Upd_Vencer]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_CampaniaVenta_Upd_Vencer];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_CampaniaVenta_Upd_Vencer
' Descripción            : Actualiza campania venta para vencer.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_CampaniaVenta_Upd_Vencer
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @Vencidas TABLE
    (
        campania_venta_id BIGINT NOT NULL,
        estado_anterior VARCHAR(20) NOT NULL,
        estado_nuevo VARCHAR(20) NOT NULL,
        fecha_hora_utc DATETIME2(0) NOT NULL
    );
    -- Vencimiento comercial separado; el cierre financiero exige obligaciones conciliadas.
    BEGIN TRANSACTION;
    UPDATE C
       SET estado_proceso = 'VENCIDA'
    OUTPUT inserted.campania_venta_id, deleted.estado_proceso,
           inserted.estado_proceso, SYSUTCDATETIME()
      INTO @Vencidas
           (campania_venta_id, estado_anterior, estado_nuevo, fecha_hora_utc)
      FROM comercial.CampaniaVenta C
     WHERE C.estado = 1
       AND C.estado_proceso = 'ACTIVA'
       AND C.fecha_fin < CONVERT(DATE, DATEADD(HOUR, -5, SYSUTCDATETIME()));
    INSERT INTO comercial.CampaniaVencimientoLog
        (campania_venta_id, estado_anterior, estado_nuevo, fecha_hora_utc)
    SELECT campania_venta_id, estado_anterior, estado_nuevo, fecha_hora_utc
    FROM @Vencidas;
    DECLARE @c BIGINT;
    DECLARE vencidas_cursor CURSOR LOCAL FAST_FORWARD FOR
      SELECT campania_venta_id FROM @Vencidas
      UNION SELECT campania_venta_id FROM comercial.CampaniaVenta
      WHERE estado=1 AND estado_proceso='VENCIDA' AND fecha_fin<CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()));
    OPEN vencidas_cursor;
    FETCH NEXT FROM vencidas_cursor INTO @c;
    WHILE @@FETCH_STATUS=0
    BEGIN
        EXEC finanzas.PA_E5_Campania_CierreAutomatico @campaniaId=@c;
        FETCH NEXT FROM vencidas_cursor INTO @c;
    END;
    CLOSE vencidas_cursor;
    DEALLOCATE vencidas_cursor;
    COMMIT TRANSACTION;
    SELECT COUNT(*) AS vencidas FROM @Vencidas;
END;
GO
