-- Verificación manual/CI de Etapa 1 después de aplicar Flyway.
IF OBJECT_ID(N'org.Productor', N'U') IS NULL THROW 52001, N'Falta org.Productor.', 1;
IF OBJECT_ID(N'org.ProductorUOT', N'U') IS NULL THROW 52002, N'Falta org.ProductorUOT.', 1;
IF OBJECT_ID(N'prod.PredioAmbito', N'U') IS NULL THROW 52003, N'Falta prod.PredioAmbito.', 1;
IF OBJECT_ID(N'prod.CrianzaLote', N'U') IS NULL THROW 52004, N'Falta prod.CrianzaLote.', 1;
IF OBJECT_ID(N'prod.CrianzaConteo', N'U') IS NULL THROW 52005, N'Falta prod.CrianzaConteo.', 1;
IF OBJECT_ID(N'prod.ExpedienteActuacion', N'U') IS NULL THROW 52006, N'Falta prod.ExpedienteActuacion.', 1;
IF OBJECT_DEFINITION(OBJECT_ID(N'prod.PA_ExpedienteProductivo_Ejecutar')) NOT LIKE '%IDEMPOTENCIA_CONFLICTO%'
   OR OBJECT_DEFINITION(OBJECT_ID(N'prod.PA_ExpedienteProductivo_Ejecutar')) NOT LIKE '%PA_OperacionIdempotente_Upd_MensajeFallido%'
    THROW 52011, N'Falta el cierre idempotente de rechazos E1.', 1;

IF EXISTS
(
    SELECT 1 FROM prod.PredioTitularidad T
    LEFT JOIN org.Productor P ON P.persona_id = T.persona_id
    WHERE T.persona_id IS NOT NULL AND P.persona_id IS NULL
)
    THROW 52007, N'Existe un titular sin rol de productor.', 1;

IF EXISTS
(
    SELECT 1 FROM prod.PredioTitularidad T
    LEFT JOIN org.Persona P ON P.persona_id = T.persona_id
    WHERE T.persona_id IS NULL OR P.persona_id IS NULL
)
    THROW 52008, N'Existe una titularidad sin identidad válida.', 1;

IF EXISTS
(
    SELECT 1 FROM prod.ParcelaCultivo
    WHERE cultivo_id IS NULL AND variedad_cultivo_id IS NULL AND variedad_palta_id IS NULL
)
    THROW 52009, N'Existe un cultivo sin catálogo identificable.', 1;

IF EXISTS
(
    SELECT persona_id, uot_id
    FROM org.ProductorUOT
    WHERE estado = 1 AND fecha_hasta IS NULL
    GROUP BY persona_id, uot_id
    HAVING COUNT_BIG(*) > 1
)
    THROW 52010, N'Existe más de un vínculo productor/UOT vigente.', 1;
