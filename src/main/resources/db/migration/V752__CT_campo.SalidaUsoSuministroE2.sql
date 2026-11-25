IF OBJECT_ID(N'[campo].[SalidaUsoSuministroE2]', N'U') IS NOT NULL
    DROP TABLE campo.SalidaUsoSuministroE2;
GO

-- Consumo bajo custodia E2: el almacén se debitó durante la entrega.
CREATE TABLE campo.SalidaUsoSuministroE2
(
    salida_uso_suministro_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    salida_campo_id BIGINT NOT NULL REFERENCES campo.SalidaE2(salida_campo_id),
    solicitud_recurso_id BIGINT NOT NULL REFERENCES campo.SalidaRecursoE2(solicitud_recurso_id),
    recurso_programado_id BIGINT NOT NULL REFERENCES logistica.RecursoProgramado(recurso_programado_id),
    visita_tecnica_id BIGINT NOT NULL REFERENCES campo.VisitaTecnica(visita_tecnica_id),
    predio_id BIGINT NOT NULL REFERENCES prod.Predio(predio_id),
    tratamiento_id BIGINT NOT NULL UNIQUE REFERENCES sanidad.TratamientoFitosanitario(tratamiento_fitosanitario_id),
    recurso_movimiento_id BIGINT NULL UNIQUE REFERENCES logistica.RecursoMovimiento(recurso_movimiento_id),
    cantidad DECIMAL(19,3) NOT NULL CHECK (cantidad>0),
    unidad_medida VARCHAR(20) NOT NULL,
    lote NVARCHAR(100) NULL,
    usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
    clave_idempotencia UNIQUEIDENTIFIER NOT NULL UNIQUE,
    fecha_registro DATETIME2(0) NOT NULL CONSTRAINT DF_SalidaUso_Fecha DEFAULT SYSUTCDATETIME()
);
GO
