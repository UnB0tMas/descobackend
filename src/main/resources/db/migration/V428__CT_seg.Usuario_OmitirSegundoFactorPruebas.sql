/*
 DESCO / Seguridad / 2026-10-27
 Permite omitir temporalmente el segundo factor en una cuenta local de pruebas.
 Desactivado por defecto: no cambia el comportamiento de cuentas existentes.
 Ejemplo de reactivacion del segundo factor:
 UPDATE seg.Usuario SET omitir_segundo_factor_pruebas=0 WHERE usuario_id=@UsuarioId;
*/
IF OBJECT_ID(N'seg.Usuario', N'U') IS NULL
    THROW 51080, N'No existe seg.Usuario.', 1;
GO
IF COL_LENGTH(N'seg.Usuario', N'omitir_segundo_factor_pruebas') IS NULL
    ALTER TABLE seg.Usuario ADD omitir_segundo_factor_pruebas BIT NOT NULL
        CONSTRAINT DF_Usuario_OmitirSegundoFactorPruebas DEFAULT (0) WITH VALUES;
GO
EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Excepcion temporal por usuario para pruebas locales. 0 conserva MFA; 1 permite login sin OTP. No habilitar en produccion.',
    @level0type=N'SCHEMA', @level0name=N'seg',
    @level1type=N'TABLE', @level1name=N'Usuario',
    @level2type=N'COLUMN', @level2name=N'omitir_segundo_factor_pruebas';
GO
