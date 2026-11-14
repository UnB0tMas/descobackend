-- APAPPSS: una modalidad por campaña. Se conserva CondicionComercial para relaciones e historial existentes.
SET NOCOUNT ON;
IF COL_LENGTH(N'comercial.CampaniaVenta',N'modalidad_venta_id') IS NULL
  ALTER TABLE comercial.CampaniaVenta ADD modalidad_venta_id SMALLINT NULL;
GO
IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_CampaniaVenta_ModalidadVenta')
  ALTER TABLE comercial.CampaniaVenta ADD CONSTRAINT FK_CampaniaVenta_ModalidadVenta
    FOREIGN KEY(modalidad_venta_id) REFERENCES comercial.ModalidadVenta(modalidad_venta_id);
GO
-- Una única referencia técnica por modalidad; los usuarios ya no gestionan condiciones.
INSERT comercial.CondicionComercial(modalidad_venta_id,codigo,nombre,descripcion,peso_minimo_g,peso_maximo_g,estado)
SELECT M.modalidad_venta_id,
  CONCAT('APAPPSS_MODALIDAD_',CONVERT(VARCHAR(12),M.modalidad_venta_id)),
  M.nombre,N'Referencia interna para precios de APAPPSS',NULL,NULL,1
FROM comercial.ModalidadVenta M
WHERE M.estado=1 AND NOT EXISTS
 (SELECT 1 FROM comercial.CondicionComercial C
   WHERE C.codigo=CONCAT('APAPPSS_MODALIDAD_',CONVERT(VARCHAR(12),M.modalidad_venta_id)));
GO
-- Sólo completar campañas históricas con modalidad única demostrable, sin modificar precios.
;WITH Unicas AS (
 SELECT P.campania_venta_id,MIN(C.modalidad_venta_id) modalidad_venta_id
 FROM comercial.PrecioComercial P
 JOIN comercial.CondicionComercial C ON C.condicion_comercial_id=P.condicion_comercial_id
 GROUP BY P.campania_venta_id
 HAVING MIN(C.modalidad_venta_id)=MAX(C.modalidad_venta_id)
)
UPDATE CV SET modalidad_venta_id=U.modalidad_venta_id
FROM comercial.CampaniaVenta CV JOIN Unicas U ON U.campania_venta_id=CV.campania_venta_id
WHERE CV.modalidad_venta_id IS NULL;
GO
-- Impedir precios de una modalidad diferente dentro de campañas que ya tengan modalidad definida.
CREATE OR ALTER TRIGGER comercial.trg_PrecioComercial_ModalidadCampania
ON comercial.PrecioComercial AFTER INSERT,UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
  SELECT 1 FROM inserted I
  JOIN comercial.CampaniaVenta CV ON CV.campania_venta_id=I.campania_venta_id
  LEFT JOIN comercial.CondicionComercial C ON C.condicion_comercial_id=I.condicion_comercial_id
  WHERE CV.modalidad_venta_id IS NOT NULL
    AND (C.modalidad_venta_id IS NULL OR C.modalidad_venta_id<>CV.modalidad_venta_id)
 ) THROW 51607,N'El precio no corresponde a la modalidad de venta de la campaña.',1;
 IF EXISTS (
  SELECT 1 FROM inserted I
  LEFT JOIN deleted D ON D.precio_comercial_id=I.precio_comercial_id
  JOIN comercial.CampaniaVenta CV ON CV.campania_venta_id=I.campania_venta_id
  JOIN comercial.PrecioComercial P ON P.campania_venta_id=I.campania_venta_id
    AND P.variedad_palta_id=I.variedad_palta_id AND P.precio_comercial_id<>I.precio_comercial_id
    AND ((P.operativo_venta_id=I.operativo_venta_id) OR (P.operativo_venta_id IS NULL AND I.operativo_venta_id IS NULL))
    AND P.estado=1 AND P.fecha_vigencia_hasta IS NULL
  WHERE D.precio_comercial_id IS NULL AND CV.modalidad_venta_id IS NOT NULL AND I.estado=1 AND I.fecha_vigencia_hasta IS NULL
 ) THROW 51608,N'Ya existe un precio para esta variedad de la campaña.',1;
END;
GO
