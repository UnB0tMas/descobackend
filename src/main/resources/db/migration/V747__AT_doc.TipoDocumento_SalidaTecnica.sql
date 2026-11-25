-- Tipo especial en el catálogo documental existente; no se crean mensajes paralelos.
IF NOT EXISTS (SELECT 1 FROM doc.TipoDocumento WHERE codigo='SOLICITUD_SALIDA_TECNICA')
BEGIN
    INSERT INTO doc.TipoDocumento(codigo, nombre, descripcion, estado)
    VALUES ('SOLICITUD_SALIDA_TECNICA', N'Solicitud de salida técnica',
            N'Expediente operativo E2 vinculado a correspondencia interna', 1);
END;
GO
