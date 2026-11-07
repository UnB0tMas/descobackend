/* Restaura el generador de códigos sin modificar socios ni secuencias existentes.
   El primer valor supera todos los códigos SOC- numéricos ya registrados. */
IF NOT EXISTS(SELECT 1 FROM sys.sequences WHERE object_id=OBJECT_ID(N'org.SQ_CodigoSocio'))
BEGIN
    DECLARE @inicio BIGINT = (SELECT ISNULL(MAX(TRY_CONVERT(BIGINT,SUBSTRING(codigo_socio,5,20))),0)+1
                             FROM org.SocioAsociacion WHERE codigo_socio LIKE 'SOC-%');
    DECLARE @sql NVARCHAR(MAX)=N'CREATE SEQUENCE org.SQ_CodigoSocio AS BIGINT START WITH '+CONVERT(NVARCHAR(20),@inicio)+N' INCREMENT BY 1 NO CYCLE;';
    EXEC sys.sp_executesql @sql;
END;
GO
