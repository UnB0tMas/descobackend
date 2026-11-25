IF OBJECT_ID(N'[logistica].[TR_ProductoPrecio_ValidarMonedaRecurso]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_ProductoPrecio_ValidarMonedaRecurso];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_ProductoPrecio_ValidarMonedaRecurso
' Descripción            : Valida la moneda en los precios de productos.
' Aplicativo / Módulo    : DESCO / Logística
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_ProductoPrecio_ValidarMonedaRecurso ON logistica.ProductoPrecio AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I WHERE NOT EXISTS(SELECT 1 FROM config.CatalogoRecursoValor C WHERE C.catalogo='MONEDA' AND C.codigo=UPPER(I.moneda) AND C.estado=1)) THROW 51000,N'La moneda seleccionada no está disponible.',1;
END;
GO
