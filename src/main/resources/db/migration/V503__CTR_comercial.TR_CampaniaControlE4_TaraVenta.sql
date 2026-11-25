IF OBJECT_ID(N'[comercial].[TR_CampaniaControlE4_TaraVenta]') IS NOT NULL
    DROP TRIGGER [comercial].[TR_CampaniaControlE4_TaraVenta];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : comercial.TR_CampaniaControlE4_TaraVenta
' Descripción            : Controla las modificaciones de campania control e4 tara venta mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   TRIGGER comercial.TR_CampaniaControlE4_TaraVenta
ON comercial.CampaniaControlE4
AFTER INSERT,UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT UPDATE(tara_kg) RETURN;
 DECLARE @cambios TABLE(campaniaId BIGINT NOT NULL PRIMARY KEY,valor DECIMAL(9,3) NOT NULL,usuario BIGINT NOT NULL);
 INSERT @cambios(campaniaId,valor,usuario)
 SELECT I.campania_venta_id,I.tara_kg,I.usuario_id
 FROM inserted I
 LEFT JOIN deleted D ON D.campania_venta_id=I.campania_venta_id
 WHERE D.campania_venta_id IS NULL OR I.tara_kg<>D.tara_kg;
 IF NOT EXISTS(SELECT 1 FROM @cambios) RETURN;
 -- Las configuraciones del aplicativo afectan una campaña por operación.
 IF (SELECT COUNT(*) FROM @cambios)>1 THROW 52077,N'Configure la tara de cada campaña por separado.',1;
 DECLARE @camp BIGINT,@tara DECIMAL(9,3),@usuario BIGINT;
 SELECT @camp=campaniaId,@tara=valor,@usuario=usuario FROM @cambios;
 IF EXISTS(SELECT 1 FROM comercial.CampaniaVenta C
     WHERE C.campania_venta_id=@camp AND ISNULL(C.descuento_jaba_kg,-1)<>@tara)
 BEGIN
   EXEC comercial.PA_CampaniaDescuentoJaba_Upd_Recalcular @camp,@tara,@usuario;
   UPDATE comercial.CampaniaVenta SET descuento_jaba_kg=@tara WHERE campania_venta_id=@camp;
 END;
END;
GO
