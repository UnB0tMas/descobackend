-- V649: reparar permisos de navegación APAPPSS sin ampliar acceso a otros convenios.
-- El catálogo original ya contiene estos permisos en V2, V413 y V601.
-- Solo se crean permisos inexistentes; no se reactivan permisos o módulos deshabilitados.
-- El rol y las concesiones individuales por UOT se sincronizan en AdministratorAccessBootstrap.
SET XACT_ABORT ON;
GO
DECLARE @PermisosMenu TABLE (
    codigo VARCHAR(40) NOT NULL PRIMARY KEY,
    modulo VARCHAR(60) NOT NULL,
    nombre NVARCHAR(100) NOT NULL
);

INSERT INTO @PermisosMenu (codigo, modulo, nombre) VALUES
    ('APAPPSS_SOCIOS_LISTAR', 'APAPPSS', N'APAPPSS - Listar socios'),
    ('APAPPSS_PREDIOS_LISTAR', 'APAPPSS', N'APAPPSS - Listar predios'),
    ('APAPPSS_COMPRADORES_LISTAR', 'APAPPSS', N'APAPPSS - Listar compradores'),
    ('CAMPANIAS_LISTAR', 'CAMPANIAS', N'Listar campañas de venta'),
    ('PARTICIPANTES_LISTAR', 'PARTICIPANTES', N'Listar participantes'),
    ('OPERATIVOS_LISTAR', 'OPERATIVOS', N'Listar operativos'),
    ('ENTREGAS_LISTAR', 'ENTREGAS', N'Listar entregas'),
    ('JABAS_LISTAR', 'JABAS', N'Listar jabas'),
    ('PRECIOS_LISTAR', 'PRECIOS', N'Listar precios'),
    ('INCIDENCIAS_LISTAR', 'INCIDENCIAS', N'Listar incidencias'),
    ('AJUSTES_LISTAR', 'AJUSTES', N'Listar ajustes de precio'),
    ('GASTOS_LISTAR', 'GASTOS', N'Listar gastos'),
    ('LIQUIDACIONES_LISTAR', 'LIQUIDACIONES', N'Listar liquidaciones'),
    ('PAGOS_LISTAR', 'PAGOS', N'Listar pagos'),
    ('COBROS_LISTAR', 'COBROS', N'Listar cobros');

IF EXISTS (
    SELECT 1
    FROM @PermisosMenu X
    LEFT JOIN [seg].[Permiso] P ON P.codigo=X.codigo
    LEFT JOIN [seg].[Modulo] M ON M.codigo=X.modulo AND M.estado=1
    WHERE P.permiso_id IS NULL AND M.modulo_id IS NULL
)
    THROW 51090, N'No se pueden crear permisos de APAPPSS: falta un módulo base activo.', 1;

INSERT INTO [seg].[Permiso]
    ([modulo_id], [codigo], [nombre], [descripcion], [estado], [accion], [es_sensible], [requiere_motivo])
SELECT M.modulo_id, X.codigo, X.nombre,
       N'Permiso de consulta para un módulo existente de DESCO.', 1, 'LISTAR', 0, 0
FROM @PermisosMenu X
JOIN [seg].[Modulo] M ON M.codigo=X.modulo AND M.estado=1
WHERE NOT EXISTS (
    SELECT 1 FROM [seg].[Permiso] P WITH (UPDLOCK, HOLDLOCK)
    WHERE P.codigo=X.codigo
);

-- La restricción por convenio ya existe en V409/V413/V601; completar solo vínculos ausentes.
INSERT INTO [seg].[ModuloEspecialPermiso] ([modulo_especial_id], [permiso_id])
SELECT ME.modulo_especial_id, P.permiso_id
FROM @PermisosMenu X
JOIN [seg].[Permiso] P ON P.codigo=X.codigo AND P.estado=1
JOIN [seg].[ModuloEspecial] ME
  ON ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
WHERE NOT EXISTS (
    SELECT 1 FROM [seg].[ModuloEspecialPermiso] MP WITH (UPDLOCK, HOLDLOCK)
    WHERE MP.modulo_especial_id=ME.modulo_especial_id AND MP.permiso_id=P.permiso_id
);
GO
