-- DESCO V416: normalizar la asociacion APAPPSS heredada a la UOT Sara Sara.
-- Contexto oficial de V2: Empresa RUC 20602771394; UOT Sara Sara codigo UOT_LEGACY_4.
-- No se habilita ninguna otra UOT; no se crean empresas, asociaciones ni usuarios.
-- Solo se corrige un vinculo legacy explicitamente identificado; deshabilitaciones anteriores se respetan.
SET NOCOUNT ON;

DECLARE @EmpresaId BIGINT, @UotSaraId BIGINT, @ConvenioId BIGINT,
        @ModuloId INT, @Legados INT, @Uots INT, @Empresas INT;

SELECT @Empresas=COUNT(*), @EmpresaId=MAX(empresa_id)
FROM [org].[Empresa]
WHERE ruc='20602771394' AND estado=1;

SELECT @Uots=COUNT(*), @UotSaraId=MAX(uot_id)
FROM [org].[UOT]
WHERE codigo='UOT_LEGACY_4' AND estado=1 AND es_raiz=0;

SELECT @ModuloId=modulo_especial_id
FROM [seg].[ModuloEspecial]
WHERE codigo='COMERCIALIZACION_ASOCIATIVA' AND estado=1;

IF @Empresas=1 AND @Uots=1 AND @ModuloId IS NOT NULL
   AND EXISTS (SELECT 1 FROM [org].[Asociacion]
               WHERE asociacion_id=@EmpresaId AND estado=1)
BEGIN
    SELECT @ConvenioId=MAX(convenio_uot_organizacion_id)
    FROM [org].[ConvenioUOTOrganizacion]
    WHERE uot_id=@UotSaraId AND empresa_id=@EmpresaId AND estado=1;

    IF @ConvenioId IS NULL
    BEGIN
        -- La base V2 ubico el convenio de APAPPSS en la UOT raiz por error.
        -- Solo se traslada el vinculo que marque explicitamente origen legacy.
        SELECT @Legados=COUNT(*), @ConvenioId=MAX(C.convenio_uot_organizacion_id)
        FROM [org].[ConvenioUOTOrganizacion] C
        JOIN [org].[UOT] U ON U.uot_id=C.uot_id AND U.es_raiz=1
        WHERE C.empresa_id=@EmpresaId AND C.estado=1
          AND C.numero_convenio IS NULL
          AND C.descripcion LIKE N'Vínculo migrado desde org.Asociacion%';

        IF @Legados=1
        BEGIN
            UPDATE [org].[ConvenioUOTOrganizacion]
               SET uot_id=@UotSaraId,
                   descripcion=N'Vínculo legado corregido a UOT Sara Sara (APAPPSS).'
             WHERE convenio_uot_organizacion_id=@ConvenioId;
        END
        ELSE
        BEGIN
            SET @ConvenioId=NULL;
            PRINT N'APAPPSS: no se encontró un único convenio legado verificable; no se creó ni habilitó uno nuevo.';
        END;
    END;

    IF @ConvenioId IS NOT NULL
       AND EXISTS (SELECT 1 FROM [org].[ConvenioUOTOrganizacion]
                   WHERE convenio_uot_organizacion_id=@ConvenioId AND estado=1
                     AND uot_id=@UotSaraId
                     AND (fecha_inicio IS NULL OR fecha_inicio<=CONVERT(date,SYSUTCDATETIME()))
                     AND (fecha_fin IS NULL OR fecha_fin>=CONVERT(date,SYSUTCDATETIME())))
       AND NOT EXISTS (SELECT 1 FROM [org].[ConvenioModuloEspecial]
                       WHERE convenio_uot_organizacion_id=@ConvenioId
                         AND modulo_especial_id=@ModuloId)
    BEGIN
        INSERT INTO [org].[ConvenioModuloEspecial]
            (convenio_uot_organizacion_id, modulo_especial_id, estado)
        VALUES (@ConvenioId, @ModuloId, 1);
        PRINT N'APAPPSS habilitado exclusivamente para el convenio vigente de UOT Sara Sara.';
    END;
    -- Un registro existente estado=0 representa deshabilitacion explicita: NO reactivar.
END
ELSE
    PRINT N'APAPPSS: faltan UOT Sara Sara, asociación o módulo identificables; no se alteraron convenios.';
GO
