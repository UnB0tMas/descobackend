IF OBJECT_ID(N'[logistica].[TR_BienInventario_ValidarMonedaRecurso]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_BienInventario_ValidarMonedaRecurso];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_BienInventario_ValidarMonedaRecurso
' Descripción            : Valida la moneda de bienes de inventario.
' Aplicativo / Módulo    : DESCO / Logística
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_BienInventario_ValidarMonedaRecurso ON logistica.BienInventario AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I WHERE I.moneda_adquisicion IS NOT NULL AND NOT EXISTS(SELECT 1 FROM config.CatalogoRecursoValor C WHERE C.catalogo='MONEDA' AND C.codigo=UPPER(I.moneda_adquisicion) AND C.estado=1)) THROW 51000,N'La moneda de adquisición no está disponible.',1;
END;
GO
