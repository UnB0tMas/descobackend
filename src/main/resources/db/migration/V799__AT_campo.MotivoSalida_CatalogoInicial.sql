-- Motivos adicionales de salida, independientes de usuarios y UOT.
INSERT INTO campo.MotivoSalida (codigo, nombre, estado)
SELECT X.codigo, X.nombre, 1
FROM (VALUES
    ('MONITOREO_RIEGO', N'Monitoreo de riego'),
    ('MUESTREO_SUELO', N'Muestreo de suelo'),
    ('CAPACITACION_CAMPO', N'Capacitación a productores'),
    ('SEGUIMIENTO_COSECHA', N'Seguimiento de cosecha')
) X(codigo, nombre)
WHERE NOT EXISTS (
    SELECT 1 FROM campo.MotivoSalida M WITH (UPDLOCK, HOLDLOCK)
    WHERE M.codigo = X.codigo OR M.nombre = X.nombre
);
GO
