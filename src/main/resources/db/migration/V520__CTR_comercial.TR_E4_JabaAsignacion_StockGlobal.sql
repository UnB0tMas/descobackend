IF OBJECT_ID(N'[comercial].[TR_E4_JabaAsignacion_StockGlobal]') IS NOT NULL
    DROP TRIGGER [comercial].[TR_E4_JabaAsignacion_StockGlobal];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : comercial.TR_E4_JabaAsignacion_StockGlobal
' Descripción            : Controla las modificaciones de e4 jaba asignacion stock global mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE TRIGGER comercial.TR_E4_JabaAsignacion_StockGlobal
ON comercial.JabaAsignacion AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF ROWCOUNT_BIG()=0 RETURN;
    DECLARE @ambitos TABLE(uot_id BIGINT PRIMARY KEY);
    INSERT @ambitos(uot_id)
    SELECT DISTINCT C.uot_id
    FROM inserted I
    JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=I.operativo_socio_id
    JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
    JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id
    JOIN comercial.CampaniaControlE4 K ON K.campania_venta_id=C.campania_venta_id;
    IF EXISTS (SELECT 1 FROM @ambitos U LEFT JOIN comercial.JabaStockUotE4 S WITH(UPDLOCK,HOLDLOCK)
          ON S.uot_id=U.uot_id WHERE S.uot_id IS NULL)
        THROW 51300,N'Certifique previamente la existencia real de jabas de la UOT.',1;
    IF EXISTS(SELECT 1 FROM @ambitos U
       JOIN comercial.JabaStockUotE4 S WITH(UPDLOCK,HOLDLOCK) ON S.uot_id=U.uot_id
       CROSS APPLY (
           SELECT COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-COALESCE(V.cantidad_validada,0)),0) AS retenidas
           FROM comercial.JabaAsignacion A
           JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
           JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
           JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id
           LEFT JOIN comercial.JabaRetornoValidadoE4 V ON V.jaba_asignacion_id=A.jaba_asignacion_id
           WHERE C.uot_id=U.uot_id AND A.estado=1
       ) C WHERE C.retenidas>S.existencia_certificada)
       THROW 51301,N'No hay stock físico certificado disponible para esta asignación.',1;
END;
GO
