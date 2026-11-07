-- DESCO / 2026-11-06: retiro de Recursos programados y Producción disponible.
-- Se conserva la trazabilidad y el motor de existencias utilizado por Salidas de campo.
-- Las solicitudes de productos siguen dentro de Almacenes para su uso técnico.
DECLARE @Almacenes INT=(SELECT modulo_id FROM seg.Modulo WHERE codigo='ALMACENES');
IF @Almacenes IS NULL THROW 51103,N'No se encontró el módulo de almacenes.',1;
UPDATE seg.Permiso SET modulo_id=@Almacenes WHERE codigo LIKE 'RECURSOS[_]%';
UPDATE seg.Permiso SET estado=0 WHERE modulo_id IN(SELECT modulo_id FROM seg.Modulo WHERE codigo='PRODUCCION');
UPDATE seg.Modulo SET estado=0,visible_menu=0,ruta=NULL WHERE codigo IN('RECURSOS','RECURSOS_PROGRAMADOS','PRODUCCION');
GO
-- Ejemplo: un bien puede tener una empresa activa como proveedor, nunca una persona o asociación.
CREATE OR ALTER TRIGGER logistica.TR_BienInventario_ProveedorSoloEmpresa
ON logistica.BienInventario AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF NOT(UPDATE(proveedor_persona_id) OR UPDATE(proveedor_empresa_id)) RETURN;
 IF EXISTS(SELECT 1 FROM inserted I WHERE I.proveedor_persona_id IS NOT NULL OR
  (I.proveedor_empresa_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM org.Empresa E
    WHERE E.empresa_id=I.proveedor_empresa_id AND E.estado=1
      AND NOT EXISTS(SELECT 1 FROM org.Asociacion A WHERE A.asociacion_id=E.empresa_id))))
 THROW 51156,N'El proveedor debe ser una empresa activa registrada en Administración.',1;
END;
GO
INSERT config.MensajeUsuario(texto_origen,mensaje,codigo_error,http_error)
SELECT N'El proveedor debe ser una empresa activa registrada en Administración.',
       N'El proveedor debe ser una empresa activa registrada en Administración.','PROVEEDOR_EMPRESA_INVALIDO',400
WHERE NOT EXISTS(SELECT 1 FROM config.MensajeUsuario WHERE texto_origen=N'El proveedor debe ser una empresa activa registrada en Administración.');
GO
