-- E2: completa recursos mixtos, retorno general e inspección sin alterar migraciones aplicadas.
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
GO

IF COL_LENGTH(N'campo.SalidaRecursoE2', N'suministro_id') IS NULL
    ALTER TABLE campo.SalidaRecursoE2 ADD suministro_id BIGINT NULL;
GO
-- La columna puede existir por una ejecución histórica: verificar la relación por separado.
IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns fkc
    JOIN sys.foreign_keys fk ON fk.object_id = fkc.constraint_object_id
    JOIN sys.columns c ON c.object_id = fkc.parent_object_id AND c.column_id = fkc.parent_column_id
    WHERE fk.parent_object_id = OBJECT_ID(N'campo.SalidaRecursoE2')
      AND c.name = N'suministro_id'
      AND fk.referenced_object_id = OBJECT_ID(N'logistica.Suministro')
)
    ALTER TABLE campo.SalidaRecursoE2 WITH CHECK ADD CONSTRAINT FK_E2_SalidaRecursoSuministro
        FOREIGN KEY (suministro_id) REFERENCES logistica.Suministro(suministro_id);
GO

IF COL_LENGTH(N'campo.SalidaRecursoE2', N'cantidad_solicitada') IS NULL
    ALTER TABLE campo.SalidaRecursoE2 ADD cantidad_solicitada DECIMAL(14,3) NOT NULL
        CONSTRAINT DF_E2_RecursoCantidadSolicitada DEFAULT (1);
GO
IF COL_LENGTH(N'campo.SalidaRecursoE2', N'cantidad_devuelta_declarada') IS NULL
    ALTER TABLE campo.SalidaRecursoE2 ADD cantidad_devuelta_declarada DECIMAL(14,3) NULL;
GO
IF COL_LENGTH(N'campo.SalidaRecursoE2', N'cantidad_devuelta_validada') IS NULL
    ALTER TABLE campo.SalidaRecursoE2 ADD cantidad_devuelta_validada DECIMAL(14,3) NULL;
GO
IF COL_LENGTH(N'campo.SalidaRecursoE2', N'observacion_validacion') IS NULL
    ALTER TABLE campo.SalidaRecursoE2 ADD observacion_validacion NVARCHAR(500) NULL;
GO

IF EXISTS (SELECT 1 FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID(N'campo.SalidaRecursoE2') AND name=N'UQ_E2_SalidaRecurso')
    ALTER TABLE campo.SalidaRecursoE2 DROP CONSTRAINT UQ_E2_SalidaRecurso;
GO
-- Solo relajar la nulabilidad cuando el esquema realmente la mantiene NOT NULL.
-- En bases locales ya integradas es NULL y puede estar indexada: alterar de nuevo
-- la columna provoca SQL Server 4922 por las dependencias existentes.
IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'campo.SalidaRecursoE2')
      AND name = N'bien_inventario_id' AND is_nullable = 0
)
BEGIN
    DECLARE @fkBien sysname;
    DECLARE @cantidadFK INT;

    -- V481 creó una FK simple. No sustituir reglas desconocidas de cascada.
    SELECT @cantidadFK = COUNT(*)
    FROM sys.foreign_key_columns fkc
    JOIN sys.columns c ON c.object_id=fkc.parent_object_id AND c.column_id=fkc.parent_column_id
    WHERE fkc.parent_object_id=OBJECT_ID(N'campo.SalidaRecursoE2')
      AND c.name=N'bien_inventario_id';
    IF @cantidadFK > 1
        THROW 51094, N'V494: hay varias FK sobre bien_inventario_id; revisar dependencias antes de modificar.', 1;

    IF EXISTS (
        SELECT 1 FROM sys.foreign_keys fk
        JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
        JOIN sys.columns c ON c.object_id=fkc.parent_object_id AND c.column_id=fkc.parent_column_id
        WHERE fk.parent_object_id=OBJECT_ID(N'campo.SalidaRecursoE2')
          AND c.name=N'bien_inventario_id'
          AND (fk.referenced_object_id<>OBJECT_ID(N'logistica.BienInventario')
               OR fk.delete_referential_action<>0 OR fk.update_referential_action<>0)
    ) THROW 51094, N'V494: FK de bien_inventario_id con reglas no previstas; no se modifica.', 1;

    SELECT @fkBien=fk.name
    FROM sys.foreign_keys fk
    JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
    JOIN sys.columns c ON c.object_id=fkc.parent_object_id AND c.column_id=fkc.parent_column_id
    WHERE fk.parent_object_id=OBJECT_ID(N'campo.SalidaRecursoE2') AND c.name=N'bien_inventario_id';

    -- Evitar eliminar índices ajenos. El único índice previsto sobre esta columna
    -- es UX_E2_SalidaBien (la UNIQUE original fue retirada en el bloque anterior).
    IF EXISTS (
        SELECT 1 FROM sys.indexes i
        JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id
        JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
        WHERE i.object_id=OBJECT_ID(N'campo.SalidaRecursoE2')
          AND c.name=N'bien_inventario_id'
          AND i.name<>N'UX_E2_SalidaBien'
    ) THROW 51094, N'V494: índice adicional sobre bien_inventario_id; revisión necesaria.', 1;

    IF EXISTS (SELECT 1 FROM sys.indexes
        WHERE object_id=OBJECT_ID(N'campo.SalidaRecursoE2') AND name=N'UX_E2_SalidaBien')
        DROP INDEX UX_E2_SalidaBien ON campo.SalidaRecursoE2;

    IF EXISTS (SELECT 1 FROM sys.check_constraints
        WHERE parent_object_id=OBJECT_ID(N'campo.SalidaRecursoE2') AND name=N'CK_E2_RecursoTipo')
        ALTER TABLE campo.SalidaRecursoE2 DROP CONSTRAINT CK_E2_RecursoTipo;

    IF @fkBien IS NOT NULL
    BEGIN
        DECLARE @sqlFk NVARCHAR(MAX);
        SET @sqlFk = N'ALTER TABLE campo.SalidaRecursoE2 DROP CONSTRAINT ' + QUOTENAME(@fkBien);
        EXEC sys.sp_executesql @sqlFk;
    END;

    ALTER TABLE campo.SalidaRecursoE2 ALTER COLUMN bien_inventario_id BIGINT NULL;

    IF @fkBien IS NOT NULL
    BEGIN
        SET @sqlFk = N'ALTER TABLE campo.SalidaRecursoE2 WITH CHECK ADD CONSTRAINT '
            + QUOTENAME(@fkBien)
            + N' FOREIGN KEY (bien_inventario_id) REFERENCES logistica.BienInventario(bien_inventario_id)';
        EXEC sys.sp_executesql @sqlFk;
    END;
    -- Los CHECK y el índice filtrado se restituyen en los bloques siguientes.
END;
GO
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'campo.SalidaRecursoE2') AND name=N'CK_E2_RecursoDeclarado')
    ALTER TABLE campo.SalidaRecursoE2 DROP CONSTRAINT CK_E2_RecursoDeclarado;
GO
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'campo.SalidaRecursoE2') AND name=N'CK_E2_RecursoValidado')
    ALTER TABLE campo.SalidaRecursoE2 DROP CONSTRAINT CK_E2_RecursoValidado;
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'campo.SalidaRecursoE2') AND name=N'CK_E2_RecursoTipo')
    ALTER TABLE campo.SalidaRecursoE2 ADD CONSTRAINT CK_E2_RecursoTipo CHECK
        ((bien_inventario_id IS NOT NULL AND suministro_id IS NULL AND cantidad_solicitada=1)
          OR (bien_inventario_id IS NULL AND suministro_id IS NOT NULL AND cantidad_solicitada>0));
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'campo.SalidaRecursoE2') AND name=N'CK_E2_RecursoCantidades')
    ALTER TABLE campo.SalidaRecursoE2 ADD CONSTRAINT CK_E2_RecursoCantidades CHECK
        ((cantidad_devuelta_declarada IS NULL OR cantidad_devuelta_declarada BETWEEN 0 AND cantidad_solicitada)
         AND (cantidad_devuelta_validada IS NULL OR cantidad_devuelta_validada BETWEEN 0 AND cantidad_solicitada));
GO
ALTER TABLE campo.SalidaRecursoE2 ADD CONSTRAINT CK_E2_RecursoDeclarado CHECK
    (resultado_declarado IS NULL OR resultado_declarado IN('CONFORME','DANADO','FALTANTE','CONSUMIDO'));
GO
ALTER TABLE campo.SalidaRecursoE2 ADD CONSTRAINT CK_E2_RecursoValidado CHECK
    (resultado_validado IS NULL OR resultado_validado IN('CONFORME','DANADO','FALTANTE','CONSUMIDO'));
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'campo.SalidaRecursoE2') AND name=N'UX_E2_SalidaBien')
    CREATE UNIQUE INDEX UX_E2_SalidaBien ON campo.SalidaRecursoE2(salida_campo_id,bien_inventario_id)
        WHERE bien_inventario_id IS NOT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'campo.SalidaRecursoE2') AND name=N'UX_E2_SalidaSuministro')
    CREATE UNIQUE INDEX UX_E2_SalidaSuministro ON campo.SalidaRecursoE2(salida_campo_id,suministro_id)
        WHERE suministro_id IS NOT NULL;
GO

IF COL_LENGTH(N'campo.SalidaRetornoE2', N'justificacion_sin_visita') IS NULL
    ALTER TABLE campo.SalidaRetornoE2 ADD justificacion_sin_visita NVARCHAR(1200) NULL;
GO

IF OBJECT_ID(N'campo.SalidaInspeccionE2', N'U') IS NULL
BEGIN
    CREATE TABLE campo.SalidaInspeccionE2
    (
        salida_campo_id BIGINT NOT NULL CONSTRAINT PK_E2_SalidaInspeccion PRIMARY KEY
            REFERENCES campo.SalidaCampo(salida_campo_id),
        observacion_general NVARCHAR(1200) NULL,
        usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
        fecha_hora DATETIME2(0) NOT NULL CONSTRAINT DF_E2_InspeccionFecha DEFAULT SYSUTCDATETIME()
    );
END;
GO

INSERT campo.TipoVisitaE2(codigo,nombre)
SELECT V.codigo,V.nombre FROM (VALUES
 ('PECUARIA',N'Evaluación pecuaria'),
 ('PRODUCCION',N'Control de producción')
) V(codigo,nombre)
WHERE NOT EXISTS (SELECT 1 FROM campo.TipoVisitaE2 T WHERE T.codigo=V.codigo);
GO
IF OBJECT_ID(N'logistica.TR_E2_ReservaSalidaAutorizada', N'TR') IS NOT NULL DROP TRIGGER logistica.TR_E2_ReservaSalidaAutorizada;
GO
CREATE TRIGGER logistica.TR_E2_ReservaSalidaAutorizada
ON logistica.RecursoProgramado AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
    SELECT 1 FROM inserted I
    LEFT JOIN campo.SalidaE2 E ON E.salida_campo_id=I.salida_campo_id
    WHERE I.salida_campo_id IS NOT NULL AND I.estado=1 AND I.estado_proceso IN('PROGRAMADO','EN_EJECUCION')
      AND (E.salida_campo_id IS NULL OR E.estado NOT IN('APROBADA','EN_EJECUCION','EN_RETORNO')
       OR NOT EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 R
             WHERE R.salida_campo_id=I.salida_campo_id
               AND ((I.bien_inventario_id IS NOT NULL AND R.bien_inventario_id=I.bien_inventario_id)
                 OR (I.suministro_id IS NOT NULL AND R.suministro_id=I.suministro_id))))
 ) THROW 51035,N'DESCO_SALIDA_NO_AUTORIZADA',1;
END;
GO
IF OBJECT_ID(N'logistica.TR_E2_MovimientoSalidaAutorizada', N'TR') IS NOT NULL DROP TRIGGER logistica.TR_E2_MovimientoSalidaAutorizada;
GO
CREATE TRIGGER logistica.TR_E2_MovimientoSalidaAutorizada
ON logistica.RecursoMovimiento AFTER INSERT AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
    SELECT 1 FROM inserted I
    JOIN logistica.RecursoProgramado R ON R.recurso_programado_id=I.recurso_programado_id
    LEFT JOIN campo.SalidaE2 E ON E.salida_campo_id=R.salida_campo_id
    WHERE R.salida_campo_id IS NOT NULL
      AND (E.salida_campo_id IS NULL OR
        NOT EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 ER WHERE ER.recurso_programado_id=R.recurso_programado_id) OR
        (I.tipo_movimiento IN('ASIGNACION','ENTREGA') AND E.estado NOT IN('APROBADA','EN_EJECUCION')) OR
        (I.tipo_movimiento IN('DEVOLUCION','CONSUMO') AND E.estado NOT IN('EN_RETORNO','CERRADA')) OR
        (I.tipo_movimiento='DEVOLUCION' AND NOT EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 ER
           WHERE ER.recurso_programado_id=R.recurso_programado_id
             AND ((ER.resultado_validado='CONFORME' AND ER.estado='VALIDADO')
               OR (ER.suministro_id IS NOT NULL AND ER.cantidad_devuelta_validada>0 AND ER.estado IN('VALIDADO','INCIDENCIA'))))) OR
        (I.tipo_movimiento='CONSUMO' AND NOT EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 ER
           WHERE ER.recurso_programado_id=R.recurso_programado_id
             AND ER.suministro_id IS NOT NULL AND ER.estado='VALIDADO' AND ER.resultado_validado='CONSUMIDO')))
 ) THROW 51035,N'DESCO_SALIDA_NO_AUTORIZADA',1;
END;
GO
