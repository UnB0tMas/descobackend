IF OBJECT_ID(N'[comercial].[TR_CampaniaJabaRecepcion_PrecioSancion]') IS NOT NULL
    DROP TRIGGER [comercial].[TR_CampaniaJabaRecepcion_PrecioSancion];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : comercial.TR_CampaniaJabaRecepcion_PrecioSancion
' Descripción            : Controla las modificaciones de campania jaba recepcion precio sancion mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   TRIGGER comercial.TR_CampaniaJabaRecepcion_PrecioSancion
ON comercial.CampaniaJabaRecepcion AFTER INSERT, UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 -- Una modificación solo de tara, observación o versión no altera precios históricos.
 IF EXISTS(SELECT 1 FROM deleted) AND NOT UPDATE(campania_calibre_id) AND NOT UPDATE(peso_bruto_kg) RETURN;
 -- Una jaba que se corrige a vacía deja de tener precio de fruta.
 DELETE X FROM comercial.CampaniaJabaPrecioSancion X
 JOIN inserted I ON I.campania_jaba_recepcion_id=X.campania_jaba_recepcion_id
 WHERE I.peso_bruto_kg=0;
 IF NOT EXISTS(SELECT 1 FROM inserted WHERE peso_bruto_kg>0) RETURN;
 DECLARE @datos TABLE(jaba BIGINT PRIMARY KEY,sancion BIGINT NULL,precio DECIMAL(14,4),descuento DECIMAL(14,4),nombre NVARCHAR(120) NULL);
 INSERT @datos(jaba,sancion,precio,descuento,nombre)
 SELECT I.campania_jaba_recepcion_id, S.campania_socio_sancion_id,G.precio_kg,
        COALESCE(T.descuento_precio_kg,CONVERT(DECIMAL(14,4),0)), C.nombre
 FROM inserted I
 JOIN comercial.CampaniaCalibre G ON G.campania_calibre_id=I.campania_calibre_id
 JOIN comercial.CampaniaJabaPlan J ON J.campania_jaba_plan_id=I.campania_jaba_plan_id
 OUTER APPLY (
   SELECT TOP(1) A.campania_socio_sancion_id,A.campania_sancion_tarifa_id
   FROM comercial.CampaniaSocioSancion A
   WHERE A.participacion_campania_socio_id=J.participacion_campania_socio_id AND A.activo=1
      AND I.numero_jaba>=A.desde_numero AND (A.hasta_numero IS NULL OR I.numero_jaba<=A.hasta_numero)
   ORDER BY A.campania_socio_sancion_id DESC
 ) S
 LEFT JOIN comercial.CampaniaSancionTarifa T ON T.campania_sancion_tarifa_id=S.campania_sancion_tarifa_id
 LEFT JOIN comercial.CatalogoSancionVenta C ON C.sancion_venta_id=T.sancion_venta_id
 WHERE I.peso_bruto_kg>0;
 IF EXISTS(
   SELECT 1 FROM @datos D
   LEFT JOIN comercial.CampaniaJabaPrecioSancion X ON X.campania_jaba_recepcion_id=D.jaba
   JOIN inserted I ON I.campania_jaba_recepcion_id=D.jaba
   LEFT JOIN deleted O ON O.campania_jaba_recepcion_id=D.jaba
   WHERE D.precio<=D.descuento
     AND (X.campania_jaba_recepcion_id IS NULL OR I.campania_calibre_id<>O.campania_calibre_id)
 ) THROW 52080,N'El descuento de sanción debe ser menor al precio del calibre seleccionado.',1;
 UPDATE X SET campania_socio_sancion_id=D.sancion,precio_original_kg=D.precio,
    descuento_precio_kg=D.descuento,precio_final_kg=D.precio-D.descuento,
    sancion_nombre=D.nombre,fecha_precio=SYSUTCDATETIME()
 FROM comercial.CampaniaJabaPrecioSancion X JOIN @datos D ON D.jaba=X.campania_jaba_recepcion_id
 JOIN inserted I ON I.campania_jaba_recepcion_id=D.jaba
 JOIN deleted O ON O.campania_jaba_recepcion_id=D.jaba
 WHERE I.campania_calibre_id<>O.campania_calibre_id;
 INSERT comercial.CampaniaJabaPrecioSancion(campania_jaba_recepcion_id,campania_socio_sancion_id,precio_original_kg,descuento_precio_kg,precio_final_kg,sancion_nombre)
 SELECT D.jaba,D.sancion,D.precio,D.descuento,D.precio-D.descuento,D.nombre FROM @datos D
 WHERE NOT EXISTS(SELECT 1 FROM comercial.CampaniaJabaPrecioSancion X WHERE X.campania_jaba_recepcion_id=D.jaba);
END;
GO
