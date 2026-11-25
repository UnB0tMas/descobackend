IF OBJECT_ID(N'[comercial].[TR_E5_Cargos_Cierre]') IS NOT NULL
    DROP TRIGGER [comercial].[TR_E5_Cargos_Cierre];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : comercial.TR_E5_Cargos_Cierre
' Descripción            : Controla las condiciones de cierre de e5 cargos cierre.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE TRIGGER comercial.TR_E5_Cargos_Cierre
ON comercial.CargoIndividualE4 AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM (SELECT jaba_asignacion_id FROM inserted UNION SELECT jaba_asignacion_id FROM deleted) X
 JOIN comercial.JabaAsignacion A ON A.jaba_asignacion_id=X.jaba_asignacion_id
 JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
 JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
 JOIN comercial.CierreCampaniaE5 C ON C.campania_venta_id=O.campania_venta_id)
 THROW 51506,N'La campaña cerrada no permite modificar cargos.',1;
END;
GO
