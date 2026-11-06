/*
 DESCO / Logistica / 2026-10-27
 Crea la secuencia utilizada por PA_Recurso_Sel_CodigoSugerido y el alta de
 suministros. Las migraciones anteriores la referencian, pero no la crean.
 Conserva una secuencia existente y los codigos ya registrados.
 Ejemplo de consulta sin consumir un codigo:
 SELECT current_value FROM sys.sequences
 WHERE object_id=OBJECT_ID(N'logistica.SEQ_CodigoAutomatico', N'SO');
*/
IF SCHEMA_ID(N'logistica') IS NULL
    THROW 51080, N'No existe el esquema logistica.', 1;
GO
IF OBJECT_ID(N'logistica.SEQ_CodigoAutomatico', N'SO') IS NULL
BEGIN
    DECLARE @Inicio BIGINT;
    SELECT @Inicio=COALESCE(MAX(numero),0)+1
    FROM (
        SELECT TRY_CONVERT(BIGINT,RIGHT(codigo_patrimonial,10)) numero FROM logistica.BienInventario
        UNION ALL SELECT TRY_CONVERT(BIGINT,RIGHT(codigo,10)) FROM logistica.Producto
        UNION ALL SELECT TRY_CONVERT(BIGINT,RIGHT(codigo,10)) FROM logistica.Almacen
        UNION ALL SELECT TRY_CONVERT(BIGINT,RIGHT(codigo,10)) FROM logistica.Suministro
    ) existentes;
    IF @Inicio>9999999999
        THROW 51080, N'Se agoto el rango de codigos automaticos de diez digitos.', 1;
    DECLARE @Sql NVARCHAR(400)=N'CREATE SEQUENCE logistica.SEQ_CodigoAutomatico AS BIGINT START WITH '
        + CONVERT(NVARCHAR(20),@Inicio)
        + N' INCREMENT BY 1 MINVALUE 1 MAXVALUE 9999999999 NO CYCLE CACHE 50';
    EXEC sys.sp_executesql @Sql;
END;
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE class=1 AND major_id=OBJECT_ID(N'logistica.SEQ_CodigoAutomatico', N'SO')
      AND minor_id=0 AND name=N'MS_Description'
)
    EXEC sys.sp_addextendedproperty @name=N'MS_Description',
        @value=N'Secuencia compartida de codigos de bienes, productos, almacenes y suministros. No reiniciar ni eliminar al actualizar.',
        @level0type=N'SCHEMA', @level0name=N'logistica',
        @level1type=N'SEQUENCE', @level1name=N'SEQ_CodigoAutomatico';
GO
