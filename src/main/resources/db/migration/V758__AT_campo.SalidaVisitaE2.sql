-- Conserva los registros anteriores sin inventar autoría personal.
IF OBJECT_ID(N'[campo].[SalidaVisitaE2]', N'U') IS NULL
    THROW 51066, N'La relación de visitas E2 no está disponible.', 1;
GO
IF COL_LENGTH(N'campo.SalidaVisitaE2', N'usuario_inicio_id') IS NULL
BEGIN
    ALTER TABLE campo.SalidaVisitaE2 ADD usuario_inicio_id BIGINT NULL;
END;
GO
IF COL_LENGTH(N'campo.SalidaVisitaE2', N'usuario_fin_id') IS NULL
BEGIN
    ALTER TABLE campo.SalidaVisitaE2 ADD usuario_fin_id BIGINT NULL;
END;
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_SalidaVisitaE2_UsuarioInicio')
BEGIN
    ALTER TABLE campo.SalidaVisitaE2 WITH CHECK
        ADD CONSTRAINT FK_SalidaVisitaE2_UsuarioInicio
        FOREIGN KEY (usuario_inicio_id) REFERENCES seg.Usuario(usuario_id);
END;
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_SalidaVisitaE2_UsuarioFin')
BEGIN
    ALTER TABLE campo.SalidaVisitaE2 WITH CHECK
        ADD CONSTRAINT FK_SalidaVisitaE2_UsuarioFin
        FOREIGN KEY (usuario_fin_id) REFERENCES seg.Usuario(usuario_id);
END;
GO
