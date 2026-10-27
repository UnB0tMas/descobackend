-- V413 / APAPPSS: usa la habilitacion por convenio de V409, sin rehacer migraciones aplicadas.
-- APAPPSS es el nombre visible del modulo especial comercial ya registrado.
UPDATE [seg].[ModuloEspecial]
SET [nombre] = N'APAPPSS',
    [descripcion] = N'Gestion asociativa de socios, predios y comercializacion habilitada por convenio.'
WHERE [codigo] = 'COMERCIALIZACION_ASOCIATIVA'
  AND ([nombre] <> N'APAPPSS' OR [descripcion] IS NULL);

-- Permisos especificos para el acceso a predios y socios DENTRO de APAPPSS.
-- Se conservan los permisos generales PREDIOS_* sin ligarlos al convenio.
IF NOT EXISTS (SELECT 1 FROM [seg].[Modulo] WHERE [codigo] = 'APAPPSS')
    INSERT INTO [seg].[Modulo] ([codigo],[nombre],[orden],[estado],[ruta],[icono],[visible_menu],[es_grupo])
    VALUES ('APAPPSS', N'APAPPSS', 90, 1, NULL, 'handshake', 0, 0);

;WITH NuevosPermisos AS (
    SELECT V.codigo, V.nombre, V.accion
    FROM (VALUES
        (CAST('APAPPSS_SOCIOS_LISTAR' AS varchar(40)), CAST(N'APAPPSS - Listar socios' AS nvarchar(100)), CAST('LISTAR' AS varchar(20))),
        ('APAPPSS_SOCIOS_VER', N'APAPPSS - Ver socios', 'VER'),
        ('APAPPSS_PREDIOS_LISTAR', N'APAPPSS - Listar predios', 'LISTAR'),
        ('APAPPSS_PREDIOS_VER', N'APAPPSS - Ver predios', 'VER'),
        ('APAPPSS_PREDIOS_CREAR', N'APAPPSS - Registrar predios', 'CREAR'),
        ('APAPPSS_PREDIOS_EDITAR', N'APAPPSS - Editar predios', 'EDITAR'),
        ('APAPPSS_PREDIOS_RETIRAR', N'APAPPSS - Retirar predios', 'RETIRAR')
    ) V(codigo,nombre,accion)
)
INSERT INTO [seg].[Permiso] ([modulo_id],[codigo],[nombre],[descripcion],[estado],[accion],[es_sensible],[requiere_motivo])
SELECT M.modulo_id, P.codigo, P.nombre, N'Acceso individual dentro del modulo especial APAPPSS.', 1, P.accion,
       CASE WHEN P.accion IN ('CREAR','EDITAR','RETIRAR') THEN 1 ELSE 0 END,
       CASE WHEN P.accion = 'RETIRAR' THEN 1 ELSE 0 END
FROM NuevosPermisos P
CROSS JOIN [seg].[Modulo] M
WHERE M.codigo='APAPPSS'
  AND NOT EXISTS (SELECT 1 FROM [seg].[Permiso] X WHERE X.codigo=P.codigo);

INSERT INTO [seg].[ModuloEspecialPermiso] ([modulo_especial_id],[permiso_id])
SELECT M.modulo_especial_id, P.permiso_id
FROM [seg].[ModuloEspecial] M
CROSS JOIN [seg].[Permiso] P
WHERE M.codigo = 'COMERCIALIZACION_ASOCIATIVA'
  AND P.codigo LIKE 'APAPPSS[_]%'
  AND NOT EXISTS (
      SELECT 1 FROM [seg].[ModuloEspecialPermiso] MP
      WHERE MP.modulo_especial_id=M.modulo_especial_id AND MP.permiso_id=P.permiso_id
  );
-- Sin asignaciones por defecto: el administrador de la UOT autorizara a cada empleado.
GO
