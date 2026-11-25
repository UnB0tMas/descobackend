-- Enlace auditable entre salida comercial, stock técnico y salida E2.
IF OBJECT_ID(N'logistica.TransferenciaSuministroTecnico', N'U') IS NULL
BEGIN
    CREATE TABLE logistica.TransferenciaSuministroTecnico
    (
        transferencia_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_TransferenciaSuministroTecnico PRIMARY KEY,
        salida_campo_id BIGINT NOT NULL,
        uot_id BIGINT NOT NULL,
        suministro_id BIGINT NOT NULL,
        producto_id BIGINT NOT NULL,
        almacen_id BIGINT NOT NULL,
        movimiento_inventario_id BIGINT NOT NULL,
        suministro_movimiento_id BIGINT NULL,
        cantidad DECIMAL(19,3) NOT NULL,
        usuario_id BIGINT NOT NULL,
        fecha_hora DATETIME2(0) NOT NULL
            CONSTRAINT DF_TransferenciaSuministroTecnico_Fecha DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT CK_TransferenciaSuministroTecnico_Cantidad CHECK(cantidad>0),
        CONSTRAINT UX_TransferenciaSuministroTecnico_Origen
            UNIQUE(salida_campo_id,suministro_id,almacen_id)
    );
END;
