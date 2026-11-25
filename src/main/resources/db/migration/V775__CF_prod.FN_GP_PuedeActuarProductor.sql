IF OBJECT_ID(N'[prod].[FN_GP_PuedeActuarProductor]', N'FN') IS NOT NULL
    DROP FUNCTION prod.FN_GP_PuedeActuarProductor;
GO

-- Control de actuaciones productivas por sesión, UOT y predio.
CREATE FUNCTION prod.FN_GP_PuedeActuarProductor
(
    @Sesion UNIQUEIDENTIFIER,
    @Usuario BIGINT,
    @Uot BIGINT,
    @Persona BIGINT
)
RETURNS BIT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM org.ProductorUOT PU
        JOIN org.Productor PR ON PR.persona_id = PU.persona_id AND PR.estado = 1
        WHERE PU.persona_id = @Persona AND PU.uot_id = @Uot AND PU.estado = 1 AND PU.fecha_hasta IS NULL)
        RETURN 0;
    IF prod.FN_GP_PuedeActuar(@Sesion, @Usuario, @Uot, NULL) = 1 RETURN 1;
    IF EXISTS (SELECT 1 FROM prod.Predio P
        WHERE P.estado = 1 AND prod.FN_GP_PuedeActuar(@Sesion, @Usuario, @Uot, P.predio_id) = 1
          AND (EXISTS (SELECT 1 FROM prod.ProductorPredioTecnico T WHERE T.predio_id = P.predio_id
              AND T.persona_id = @Persona AND T.uot_id = @Uot)
            OR EXISTS (SELECT 1 FROM prod.PredioTitularidad PT WHERE PT.predio_id = P.predio_id
              AND PT.persona_id = @Persona AND PT.estado = 1 AND PT.fecha_hasta IS NULL)))
        RETURN 1;
    RETURN 0;
END;
GO
