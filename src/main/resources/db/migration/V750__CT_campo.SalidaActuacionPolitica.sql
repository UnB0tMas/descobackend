IF OBJECT_ID(N'[campo].[SalidaActuacionPolitica]', N'U') IS NOT NULL
    DROP TABLE campo.SalidaActuacionPolitica;
GO

-- Matriz configurable por UOT y permiso de escritura; la ausencia exige salida.
CREATE TABLE campo.SalidaActuacionPolitica
(
    uot_id BIGINT NOT NULL REFERENCES org.UOT(uot_id),
    permiso_id BIGINT NOT NULL REFERENCES seg.Permiso(permiso_id),
    requiere_salida BIT NOT NULL CONSTRAINT DF_SalidaPolitica_Requiere DEFAULT (1),
    administrador_exento BIT NOT NULL CONSTRAINT DF_SalidaPolitica_Admin DEFAULT (1),
    estado BIT NOT NULL CONSTRAINT DF_SalidaPolitica_Estado DEFAULT (1),
    actualizado_por BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
    fecha_actualizacion DATETIME2(0) NOT NULL CONSTRAINT DF_SalidaPolitica_Fecha DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_SalidaActuacionPolitica PRIMARY KEY (uot_id,permiso_id)
);
GO
