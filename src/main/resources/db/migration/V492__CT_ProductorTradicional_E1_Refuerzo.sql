-- E1: rol de productor tradicional separado de la membresía y ficha técnica progresiva.
-- V428-V431 ya pueden estar aplicadas; este refuerzo conserva todas sus filas históricas.

IF OBJECT_ID(N'org.Productor', N'U') IS NULL
BEGIN
    CREATE TABLE org.Productor
    (
        persona_id BIGINT NOT NULL,
        fecha_alta DATE NOT NULL CONSTRAINT DF_E1_ProductorFechaAlta DEFAULT CONVERT(DATE, SYSUTCDATETIME()),
        estado BIT NOT NULL CONSTRAINT DF_E1_ProductorEstado DEFAULT (1),
        usuario_creacion_id BIGINT NULL,
        fecha_creacion DATETIME2(0) NOT NULL CONSTRAINT DF_E1_ProductorFechaCreacion DEFAULT SYSUTCDATETIME(),
        version_fila ROWVERSION NOT NULL,
        CONSTRAINT PK_E1_Productor PRIMARY KEY (persona_id),
        CONSTRAINT FK_E1_ProductorPersona FOREIGN KEY (persona_id) REFERENCES org.Persona(persona_id),
        CONSTRAINT FK_E1_ProductorUsuario FOREIGN KEY (usuario_creacion_id) REFERENCES seg.Usuario(usuario_id)
    );
END;
GO

IF OBJECT_ID(N'org.ProductorUOT', N'U') IS NULL
BEGIN
    CREATE TABLE org.ProductorUOT
    (
        productor_uot_id BIGINT IDENTITY(1,1) NOT NULL,
        persona_id BIGINT NOT NULL,
        uot_id BIGINT NOT NULL,
        fecha_desde DATE NOT NULL CONSTRAINT DF_E1_ProductorUOTDesde DEFAULT CONVERT(DATE, SYSUTCDATETIME()),
        fecha_hasta DATE NULL,
        estado BIT NOT NULL CONSTRAINT DF_E1_ProductorUOTEstado DEFAULT (1),
        usuario_creacion_id BIGINT NULL,
        fecha_creacion DATETIME2(0) NOT NULL CONSTRAINT DF_E1_ProductorUOTCreacion DEFAULT SYSUTCDATETIME(),
        version_fila ROWVERSION NOT NULL,
        CONSTRAINT PK_E1_ProductorUOT PRIMARY KEY (productor_uot_id),
        CONSTRAINT FK_E1_ProductorUOTProductor FOREIGN KEY (persona_id) REFERENCES org.Productor(persona_id),
        CONSTRAINT FK_E1_ProductorUOTUOT FOREIGN KEY (uot_id) REFERENCES org.UOT(uot_id),
        CONSTRAINT FK_E1_ProductorUOTUsuario FOREIGN KEY (usuario_creacion_id) REFERENCES seg.Usuario(usuario_id),
        CONSTRAINT UQ_E1_ProductorUOTPeriodo UNIQUE (persona_id, uot_id, fecha_desde),
        CONSTRAINT CK_E1_ProductorUOTVigencia CHECK (fecha_hasta IS NULL OR fecha_hasta >= fecha_desde)
    );
END;
GO

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'org.ProductorUOT') AND name = N'UX_E1_ProductorUOTVigente'
)
    CREATE UNIQUE INDEX UX_E1_ProductorUOTVigente
        ON org.ProductorUOT(persona_id, uot_id)
        WHERE estado = 1 AND fecha_hasta IS NULL;
GO

-- Todo titular histórico es una persona productora, sea o no socio de una asociación.
INSERT org.Productor(persona_id, fecha_alta, usuario_creacion_id)
SELECT T.persona_id, MIN(T.fecha_desde), NULL
FROM prod.PredioTitularidad T
JOIN org.Persona P ON P.persona_id = T.persona_id
WHERE T.persona_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM org.Productor X WHERE X.persona_id = T.persona_id)
GROUP BY T.persona_id;
GO

INSERT org.ProductorUOT(persona_id, uot_id, fecha_desde, usuario_creacion_id)
SELECT T.persona_id, A.uot_id, MIN(COALESCE(T.fecha_desde, P.fecha_registro)), NULL
FROM prod.PredioTitularidad T
JOIN prod.Predio P ON P.predio_id = T.predio_id
JOIN prod.PredioAmbito A ON A.predio_id = P.predio_id AND A.estado = 1
JOIN org.Productor PR ON PR.persona_id = T.persona_id
WHERE T.persona_id IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1 FROM org.ProductorUOT X
      WHERE X.persona_id = T.persona_id AND X.uot_id = A.uot_id
        AND X.estado = 1 AND X.fecha_hasta IS NULL
  )
GROUP BY T.persona_id, A.uot_id;
GO
IF OBJECT_ID(N'prod.TR_E1_TitularRegistrarProductor', N'TR') IS NOT NULL DROP TRIGGER prod.TR_E1_TitularRegistrarProductor;
GO
CREATE TRIGGER prod.TR_E1_TitularRegistrarProductor
ON prod.PredioTitularidad
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT org.Productor(persona_id, fecha_alta, usuario_creacion_id)
    SELECT I.persona_id, MIN(I.fecha_desde), NULL
    FROM inserted I
    JOIN org.Persona P ON P.persona_id = I.persona_id
    WHERE I.persona_id IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM org.Productor X WITH (UPDLOCK, HOLDLOCK) WHERE X.persona_id = I.persona_id)
    GROUP BY I.persona_id;

    INSERT org.ProductorUOT(persona_id, uot_id, fecha_desde, usuario_creacion_id)
    SELECT I.persona_id, A.uot_id, MIN(I.fecha_desde), A.usuario_creacion_id
    FROM inserted I
    JOIN prod.PredioAmbito A ON A.predio_id = I.predio_id AND A.estado = 1
    JOIN org.Productor P ON P.persona_id = I.persona_id
    WHERE I.persona_id IS NOT NULL
      AND I.estado = 1
      AND NOT EXISTS
      (
          SELECT 1 FROM org.ProductorUOT X WITH (UPDLOCK, HOLDLOCK)
          WHERE X.persona_id = I.persona_id AND X.uot_id = A.uot_id
            AND X.estado = 1 AND X.fecha_hasta IS NULL
      )
    GROUP BY I.persona_id, A.uot_id, A.usuario_creacion_id;
END;
GO
IF OBJECT_ID(N'prod.TR_E1_AmbitoRegistrarProductorUOT', N'TR') IS NOT NULL DROP TRIGGER prod.TR_E1_AmbitoRegistrarProductorUOT;
GO
CREATE TRIGGER prod.TR_E1_AmbitoRegistrarProductorUOT
ON prod.PredioAmbito
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT org.ProductorUOT(persona_id, uot_id, fecha_desde, usuario_creacion_id)
    SELECT T.persona_id, I.uot_id, MIN(T.fecha_desde), I.usuario_creacion_id
    FROM inserted I
    JOIN prod.PredioTitularidad T ON T.predio_id = I.predio_id
        AND T.estado = 1 AND T.fecha_hasta IS NULL
    JOIN org.Productor P ON P.persona_id = T.persona_id
    WHERE I.estado = 1
      AND NOT EXISTS
      (
          SELECT 1 FROM org.ProductorUOT X WITH (UPDLOCK, HOLDLOCK)
          WHERE X.persona_id = T.persona_id AND X.uot_id = I.uot_id
            AND X.estado = 1 AND X.fecha_hasta IS NULL
      )
    GROUP BY T.persona_id, I.uot_id, I.usuario_creacion_id;
END;
GO

-- Los campos omitidos en una ampliación conservan la última información conocida.
-- Se mantiene una nueva fila/version para no sobrescribir la actuación anterior.
IF OBJECT_ID(N'prod.TR_E1_PredioVersion_CompletarProgresivo', N'TR') IS NOT NULL DROP TRIGGER prod.TR_E1_PredioVersion_CompletarProgresivo;
GO
CREATE TRIGGER prod.TR_E1_PredioVersion_CompletarProgresivo
ON prod.PredioVersion
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE V
       SET area_total_ha = COALESCE(V.area_total_ha, A.area_total_ha),
           area_cultivable_ha = COALESCE(V.area_cultivable_ha, A.area_cultivable_ha),
           tipo_riego = COALESCE(NULLIF(V.tipo_riego, ''), A.tipo_riego),
           fuente_agua = COALESCE(NULLIF(V.fuente_agua, N''), A.fuente_agua),
           infraestructura = COALESCE(NULLIF(V.infraestructura, N''), A.infraestructura),
           observacion = COALESCE(NULLIF(V.observacion, N''), A.observacion)
    FROM prod.PredioVersion V
    JOIN inserted I ON I.predio_version_id = V.predio_version_id
    OUTER APPLY
    (
        SELECT TOP (1) X.area_total_ha, X.area_cultivable_ha, X.tipo_riego,
               X.fuente_agua, X.infraestructura, X.observacion
        FROM prod.PredioVersion X
        WHERE X.predio_id = I.predio_id
          AND X.predio_version_id <> I.predio_version_id
        ORDER BY X.fecha_desde DESC, X.revision DESC, X.predio_version_id DESC
    ) A;

    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        JOIN prod.PredioVersion V ON V.predio_version_id = I.predio_version_id
        WHERE V.area_total_ha IS NULL
          AND V.area_cultivable_ha IS NULL
          AND NULLIF(V.tipo_riego, '') IS NULL
          AND NULLIF(V.fuente_agua, N'') IS NULL
          AND NULLIF(V.infraestructura, N'') IS NULL
          AND NULLIF(V.observacion, N'') IS NULL
    )
        THROW 51066, N'La ficha técnica no contiene cambios para guardar.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        JOIN prod.PredioVersion V ON V.predio_version_id = I.predio_version_id
        WHERE V.area_total_ha IS NOT NULL AND V.area_total_ha <= 0
           OR V.area_cultivable_ha IS NOT NULL AND
              (V.area_cultivable_ha < 0 OR V.area_total_ha IS NOT NULL AND V.area_cultivable_ha > V.area_total_ha)
    )
        THROW 51067, N'Las áreas de la ficha técnica no son válidas.', 1;
END;
GO

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'prod.ExpedienteActuacion') AND name = N'IX_E1_ActuacionCorrelacion'
)
    CREATE INDEX IX_E1_ActuacionCorrelacion
        ON prod.ExpedienteActuacion(correlacion_id)
        WHERE correlacion_id IS NOT NULL;
GO
