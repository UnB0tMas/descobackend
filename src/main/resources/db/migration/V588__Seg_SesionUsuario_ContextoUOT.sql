-- Compatibilidad de esquema con el contexto UOT que ya utiliza DESCO.
-- No concede permisos: AdministratorAccessBootstrap realiza esa sincronizacion.
SET NOCOUNT ON;
GO
IF OBJECT_ID(N'[seg].[SesionUsuario]', N'U') IS NULL
    THROW 51080, N'No existe seg.SesionUsuario. Verifique la base de datos seleccionada.', 1;
GO
IF COL_LENGTH(N'seg.SesionUsuario', N'uot_contexto_id') IS NULL
    ALTER TABLE [seg].[SesionUsuario] ADD [uot_contexto_id] BIGINT NULL;
GO
IF COL_LENGTH(N'seg.SesionUsuario', N'modo_uot') IS NULL
    ALTER TABLE [seg].[SesionUsuario]
        ADD [modo_uot] VARCHAR(12) COLLATE Modern_Spanish_CI_AS
            NOT NULL CONSTRAINT [DF_SesionUsuario_ModoUOT] DEFAULT ('ESPECIFICA') WITH VALUES;
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID(N'[seg].[SesionUsuario]')
      AND name = N'CK_SesionUsuario_ModoUOT'
)
    ALTER TABLE [seg].[SesionUsuario] WITH CHECK
        ADD CONSTRAINT [CK_SesionUsuario_ModoUOT]
        CHECK ([modo_uot] IN ('ESPECIFICA', 'GENERAL'));
GO
