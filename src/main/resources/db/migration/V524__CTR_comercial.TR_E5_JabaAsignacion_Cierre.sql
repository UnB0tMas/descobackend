IF OBJECT_ID(N'[comercial].[TR_E5_JabaAsignacion_Cierre]') IS NOT NULL
    DROP TRIGGER [comercial].[TR_E5_JabaAsignacion_Cierre];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : comercial.TR_E5_JabaAsignacion_Cierre
' Descripción            : Controla las condiciones de cierre de e5 jaba asignacion cierre.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE TRIGGER comercial.TR_E5_JabaAsignacion_Cierre
ON comercial.JabaAsignacion AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM (SELECT operativo_socio_id FROM inserted UNION SELECT operativo_socio_id FROM deleted) X
 JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=X.operativo_socio_id
 JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
 JOIN comercial.CierreCampaniaE5 C ON C.campania_venta_id=O.campania_venta_id)
 THROW 51512,N'Las asignaciones de campañas cerradas son inmutables.',1;
END;
GO
