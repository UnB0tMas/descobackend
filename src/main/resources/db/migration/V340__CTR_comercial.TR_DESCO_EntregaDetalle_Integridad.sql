IF OBJECT_ID(N'[comercial].[TR_DESCO_EntregaDetalle_Integridad]', N'TR') IS NOT NULL
    DROP TRIGGER [comercial].[TR_DESCO_EntregaDetalle_Integridad];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : comercial.TR_DESCO_EntregaDetalle_Integridad
' Descripción              : Controla la integridad de los detalles de entrega.
' Tabla asociada          : comercial.EntregaDetalle
' Evento que lo dispara   : AFTER INSERT,UPDATE,DELETE
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
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE,DELETE sobre comercial.EntregaDetalle.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[comercial].[TR_DESCO_EntregaDetalle_Integridad]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER comercial.TR_DESCO_EntregaDetalle_Integridad
ON comercial.EntregaDetalle AFTER INSERT,UPDATE,DELETE AS
BEGIN
 IF ROWCOUNT_BIG()=0 RETURN;
 SET NOCOUNT ON;
 DECLARE @lock BIGINT;
 SELECT @lock=E.entrega_socio_id FROM comercial.EntregaSocio E WITH(UPDLOCK,HOLDLOCK)
 WHERE EXISTS(SELECT 1 FROM inserted I WHERE I.entrega_socio_id=E.entrega_socio_id)
 OR EXISTS(SELECT 1 FROM deleted D WHERE D.entrega_socio_id=E.entrega_socio_id);
 IF EXISTS(SELECT 1 FROM comercial.EntregaSocio E WHERE E.estado_proceso<>'REGISTRADA' AND
  (EXISTS(SELECT 1 FROM inserted I WHERE I.entrega_socio_id=E.entrega_socio_id)
   OR EXISTS(SELECT 1 FROM deleted D WHERE D.entrega_socio_id=E.entrega_socio_id)))
  THROW 51000,N'La entrega ya no admite cambios en su clasificación.',1;
 IF EXISTS(SELECT 1 FROM inserted I JOIN comercial.EntregaSocio E ON E.entrega_socio_id=I.entrega_socio_id
  JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
  JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
  JOIN comercial.PrecioComercial P ON P.precio_comercial_id=I.precio_comercial_id
  WHERE I.estado=1 AND (P.campania_venta_id<>O.campania_venta_id OR (P.operativo_venta_id IS NOT NULL AND P.operativo_venta_id<>O.operativo_venta_id)
   OR P.variedad_palta_id<>I.variedad_palta_id OR P.condicion_comercial_id<>I.condicion_comercial_id))
  THROW 51000,N'El precio no corresponde a la clasificación de la entrega.',1;
END;
GO
