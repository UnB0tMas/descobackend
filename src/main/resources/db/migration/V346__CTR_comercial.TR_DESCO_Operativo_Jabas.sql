IF OBJECT_ID(N'[comercial].[TR_DESCO_Operativo_Jabas]', N'TR') IS NOT NULL
    DROP TRIGGER [comercial].[TR_DESCO_Operativo_Jabas];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : comercial.TR_DESCO_Operativo_Jabas
' Descripción              : Controla relaciones de jabas con operativos de venta.
' Tabla asociada          : comercial.OperativoVenta
' Evento que lo dispara   : AFTER INSERT,UPDATE
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Comercial
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE sobre comercial.OperativoVenta.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[comercial].[TR_DESCO_Operativo_Jabas]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER comercial.TR_DESCO_Operativo_Jabas
ON comercial.OperativoVenta AFTER INSERT,UPDATE AS
BEGIN
 IF ROWCOUNT_BIG()=0 RETURN;
 SET NOCOUNT ON;
 INSERT comercial.JabaSaldoOperativo(operativo_venta_id)
 SELECT I.operativo_venta_id FROM inserted I WHERE NOT EXISTS(SELECT 1 FROM comercial.JabaSaldoOperativo S WHERE S.operativo_venta_id=I.operativo_venta_id);
 IF EXISTS(SELECT 1 FROM inserted I JOIN comercial.JabaSaldoOperativo S ON S.operativo_venta_id=I.operativo_venta_id
  WHERE I.estado_proceso IN('CERRADO','CANCELADO') AND S.pendientes<>0)
  THROW 51100,N'DESCO_OPERATIVO_PENDIENTES',1;
END;
GO
