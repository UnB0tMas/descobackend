IF OBJECT_ID(N'[comercial].[TR_E5_Sanciones_Cierre]') IS NOT NULL
    DROP TRIGGER [comercial].[TR_E5_Sanciones_Cierre];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : comercial.TR_E5_Sanciones_Cierre
' Descripción            : Controla las condiciones de cierre de e5 sanciones cierre.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE TRIGGER comercial.TR_E5_Sanciones_Cierre
ON comercial.SancionSocioE4 AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM (SELECT entrega_socio_id FROM inserted UNION SELECT entrega_socio_id FROM deleted) X
 JOIN comercial.EntregaSocio E ON E.entrega_socio_id=X.entrega_socio_id
 JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
 JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
 JOIN comercial.CierreCampaniaE5 C ON C.campania_venta_id=O.campania_venta_id)
 THROW 51507,N'La campaña cerrada no permite modificar sanciones.',1;
END;
GO
