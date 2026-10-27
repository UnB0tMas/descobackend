-- DESCO / V409 - Modulos especiales independientes por convenio y UOT.
-- No concede funciones a ninguna UOT automaticamente. La habilitacion es explicita.
IF OBJECT_ID(N'[seg].[ModuloEspecial]', N'U') IS NULL
BEGIN
    CREATE TABLE [seg].[ModuloEspecial]
    (
        [modulo_especial_id] int IDENTITY(1,1) NOT NULL CONSTRAINT [PK_ModuloEspecial] PRIMARY KEY,
        [codigo] varchar(60) COLLATE Modern_Spanish_CI_AS NOT NULL,
        [nombre] nvarchar(120) COLLATE Modern_Spanish_CI_AS NOT NULL,
        [descripcion] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
        [estado] bit NOT NULL CONSTRAINT [DF_ModuloEspecial_Estado] DEFAULT ((1)),
        CONSTRAINT [UQ_ModuloEspecial_Codigo] UNIQUE ([codigo])
    );
END;

IF OBJECT_ID(N'[org].[ConvenioModuloEspecial]', N'U') IS NULL
BEGIN
    CREATE TABLE [org].[ConvenioModuloEspecial]
    (
        [convenio_modulo_especial_id] bigint IDENTITY(1,1) NOT NULL CONSTRAINT [PK_ConvenioModuloEspecial] PRIMARY KEY,
        [convenio_uot_organizacion_id] bigint NOT NULL,
        [modulo_especial_id] int NOT NULL,
        [estado] bit NOT NULL CONSTRAINT [DF_ConvenioModuloEspecial_Estado] DEFAULT ((0)),
        [fecha_modificacion] datetime2(0) NOT NULL CONSTRAINT [DF_ConvenioModuloEspecial_Fecha] DEFAULT (sysutcdatetime()),
        [usuario_modificacion_id] bigint NULL,
        CONSTRAINT [UQ_ConvenioModuloEspecial] UNIQUE ([convenio_uot_organizacion_id], [modulo_especial_id]),
        CONSTRAINT [FK_ConvenioModuloEspecial_Convenio] FOREIGN KEY ([convenio_uot_organizacion_id]) REFERENCES [org].[ConvenioUOTOrganizacion]([convenio_uot_organizacion_id]),
        CONSTRAINT [FK_ConvenioModuloEspecial_Modulo] FOREIGN KEY ([modulo_especial_id]) REFERENCES [seg].[ModuloEspecial]([modulo_especial_id]),
        CONSTRAINT [FK_ConvenioModuloEspecial_Usuario] FOREIGN KEY ([usuario_modificacion_id]) REFERENCES [seg].[Usuario]([usuario_id])
    );
END;

IF OBJECT_ID(N'[seg].[ModuloEspecialPermiso]', N'U') IS NULL
BEGIN
    CREATE TABLE [seg].[ModuloEspecialPermiso]
    (
        [modulo_especial_id] int NOT NULL,
        [permiso_id] bigint NOT NULL,
        CONSTRAINT [PK_ModuloEspecialPermiso] PRIMARY KEY ([modulo_especial_id], [permiso_id]),
        CONSTRAINT [FK_ModuloEspecialPermiso_Modulo] FOREIGN KEY ([modulo_especial_id]) REFERENCES [seg].[ModuloEspecial]([modulo_especial_id]),
        CONSTRAINT [FK_ModuloEspecialPermiso_Permiso] FOREIGN KEY ([permiso_id]) REFERENCES [seg].[Permiso]([permiso_id])
    );
END;

IF NOT EXISTS (SELECT 1 FROM [seg].[ModuloEspecial] WHERE [codigo] = 'COMERCIALIZACION_ASOCIATIVA')
    INSERT INTO [seg].[ModuloEspecial] ([codigo], [nombre], [descripcion])
    VALUES ('COMERCIALIZACION_ASOCIATIVA', N'Comercialización asociativa', N'Socios, campañas, acopio, jabas, precios, incidencias y liquidación por convenio específico.');

-- Se mantiene PRODUCTORES_LISTAR/VER accesible para seleccionar titulares en predios.
-- El alta, edición y retiro de membresías sí requieren el módulo especial.
INSERT INTO [seg].[ModuloEspecialPermiso] ([modulo_especial_id], [permiso_id])
SELECT M.[modulo_especial_id], P.[permiso_id]
FROM [seg].[ModuloEspecial] M
CROSS JOIN [seg].[Permiso] P
WHERE M.[codigo] = 'COMERCIALIZACION_ASOCIATIVA'
  AND (
       P.[codigo] LIKE 'CAMPANIAS[_]%' OR P.[codigo] LIKE 'PARTICIPANTES[_]%'
    OR P.[codigo] LIKE 'OPERATIVOS[_]%' OR P.[codigo] LIKE 'ENTREGAS[_]%'
    OR P.[codigo] LIKE 'JABAS[_]%' OR P.[codigo] LIKE 'PRECIOS[_]%'
    OR P.[codigo] LIKE 'INCIDENCIAS[_]%' OR P.[codigo] LIKE 'AJUSTES[_]%'
    OR P.[codigo] LIKE 'GASTOS[_]%' OR P.[codigo] LIKE 'LIQUIDACIONES[_]%'
    OR P.[codigo] LIKE 'PAGOS[_]%' OR P.[codigo] LIKE 'COBROS[_]%'
    OR P.[codigo] IN ('PRODUCTORES_CREAR','PRODUCTORES_EDITAR','PRODUCTORES_RETIRAR')
  )
  AND NOT EXISTS (
      SELECT 1 FROM [seg].[ModuloEspecialPermiso] X
      WHERE X.[modulo_especial_id]=M.[modulo_especial_id] AND X.[permiso_id]=P.[permiso_id]
  );
GO
