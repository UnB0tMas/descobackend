-- Catálogo de cultivos extensible. Las operaciones actuales de palta permanecen compatibles.
IF OBJECT_ID(N'[prod].[Cultivo]', N'U') IS NULL
BEGIN
    CREATE TABLE [prod].[Cultivo]
    (
        [cultivo_id] int IDENTITY(1,1) NOT NULL CONSTRAINT [PK_Cultivo] PRIMARY KEY,
        [codigo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
        [nombre] nvarchar(120) COLLATE Modern_Spanish_CI_AS NOT NULL,
        [estado] bit NOT NULL CONSTRAINT [DF_Cultivo_Estado] DEFAULT ((1)),
        CONSTRAINT [UQ_Cultivo_Codigo] UNIQUE ([codigo])
    );
END;
IF OBJECT_ID(N'[prod].[VariedadCultivo]', N'U') IS NULL
BEGIN
    CREATE TABLE [prod].[VariedadCultivo]
    (
        [variedad_cultivo_id] bigint IDENTITY(1,1) NOT NULL CONSTRAINT [PK_VariedadCultivo] PRIMARY KEY,
        [cultivo_id] int NOT NULL,
        [codigo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
        [nombre] nvarchar(120) COLLATE Modern_Spanish_CI_AS NOT NULL,
        [variedad_palta_legacy_id] smallint NULL,
        [estado] bit NOT NULL CONSTRAINT [DF_VariedadCultivo_Estado] DEFAULT ((1)),
        CONSTRAINT [UQ_VariedadCultivo_Codigo] UNIQUE ([cultivo_id],[codigo]),
        CONSTRAINT [FK_VariedadCultivo_Cultivo] FOREIGN KEY ([cultivo_id]) REFERENCES [prod].[Cultivo]([cultivo_id]),
        CONSTRAINT [FK_VariedadCultivo_Palta] FOREIGN KEY ([variedad_palta_legacy_id]) REFERENCES [prod].[VariedadPalta]([variedad_palta_id])
    );
    CREATE UNIQUE INDEX [UX_VariedadCultivo_Legacy] ON [prod].[VariedadCultivo] ([variedad_palta_legacy_id]) WHERE [variedad_palta_legacy_id] IS NOT NULL;
END;
IF NOT EXISTS (SELECT 1 FROM [prod].[Cultivo] WHERE [codigo]='PALTA')
    INSERT INTO [prod].[Cultivo] ([codigo],[nombre]) VALUES ('PALTA',N'Palta');
IF NOT EXISTS (SELECT 1 FROM [prod].[Cultivo] WHERE [codigo]='PAPA')
    INSERT INTO [prod].[Cultivo] ([codigo],[nombre]) VALUES ('PAPA',N'Papa');
INSERT INTO [prod].[VariedadCultivo] ([cultivo_id],[codigo],[nombre],[variedad_palta_legacy_id],[estado])
SELECT C.[cultivo_id],P.[codigo],P.[nombre],P.[variedad_palta_id],P.[estado]
FROM [prod].[VariedadPalta] P CROSS JOIN [prod].[Cultivo] C
WHERE C.[codigo]='PALTA'
AND NOT EXISTS (SELECT 1 FROM [prod].[VariedadCultivo] V WHERE V.[variedad_palta_legacy_id]=P.[variedad_palta_id]);
IF COL_LENGTH('prod.ParcelaCultivo','variedad_cultivo_id') IS NULL
    ALTER TABLE [prod].[ParcelaCultivo] ADD [variedad_cultivo_id] bigint NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_ParcelaCultivo_VariedadCultivo')
    ALTER TABLE [prod].[ParcelaCultivo] ADD CONSTRAINT [FK_ParcelaCultivo_VariedadCultivo]
        FOREIGN KEY ([variedad_cultivo_id]) REFERENCES [prod].[VariedadCultivo]([variedad_cultivo_id]);
UPDATE PC SET [variedad_cultivo_id]=VC.[variedad_cultivo_id]
FROM [prod].[ParcelaCultivo] PC
JOIN [prod].[VariedadCultivo] VC ON VC.[variedad_palta_legacy_id]=PC.[variedad_palta_id]
WHERE PC.[variedad_cultivo_id] IS NULL;
-- La columna legado variedad_palta_id sigue NOT NULL hasta migrar los procedimientos y formularios.
GO
