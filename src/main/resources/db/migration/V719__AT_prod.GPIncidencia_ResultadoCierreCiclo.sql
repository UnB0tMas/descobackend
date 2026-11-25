-- Aceptar cierre administrativo por finalización de ciclo, distinto de recuperación.
IF OBJECT_ID(N'[prod].[GPIncidencia]',N'U') IS NOT NULL
BEGIN
    IF OBJECT_ID(N'[prod].[CK_GPIncidencia_Resultado]',N'C') IS NOT NULL
    BEGIN
        ALTER TABLE [prod].[GPIncidencia] DROP CONSTRAINT [CK_GPIncidencia_Resultado];
    END;

    ALTER TABLE [prod].[GPIncidencia] WITH CHECK ADD CONSTRAINT [CK_GPIncidencia_Resultado]
        CHECK ([resultado] IS NULL OR [resultado] IN
            ('PERDIDA_TOTAL','PERDIDA_PARCIAL','RECUPERADA','CIERRE_CICLO'));
END;
GO
