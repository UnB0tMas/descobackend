IF OBJECT_ID(N'[prod].[PA_GP_ProductorParcela_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [prod].[PA_GP_ProductorParcela_Sel_Listado];
GO

-- Parcelas propias de un productor: integra históricas y nuevas, sin mostrar fundos.
CREATE PROCEDURE prod.PA_GP_ProductorParcela_Sel_Listado
    @Sesion UNIQUEIDENTIFIER,
    @Usuario BIGINT,
    @Uot BIGINT,
    @Persona BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    IF prod.FN_GP_Permiso(@Sesion, @Usuario, @Uot, 'CULTIVOS_LISTAR', 0) <> 1
        THROW 51101, N'Acceso no autorizado.', 1;
    IF NOT EXISTS (SELECT 1 FROM org.ProductorUOT WITH (NOLOCK)
                   WHERE persona_id = @Persona AND uot_id = @Uot AND estado = 1 AND fecha_hasta IS NULL)
        THROW 51102, N'Productor no disponible.', 1;

    SELECT P.parcela_id AS parcelaId, P.predio_id AS predioId, P.codigo, P.nombre,
           P.area_ha AS areaHa, P.estado,
           U.distrito_codigo AS distritoCodigo, U.centro_poblado_id AS centroPobladoId,
           U.referencia, P.observacion,
           CASE WHEN U.posicion IS NULL THEN NULL ELSE CONVERT(DECIMAL(9, 6), U.posicion.Lat) END AS latitud,
           CASE WHEN U.posicion IS NULL THEN NULL ELSE CONVERT(DECIMAL(9, 6), U.posicion.Long) END AS longitud
    FROM prod.Parcela P WITH (NOLOCK)
    JOIN prod.Predio PR WITH (NOLOCK) ON PR.predio_id = P.predio_id AND PR.estado = 1
    JOIN prod.PredioAmbito PA WITH (NOLOCK) ON PA.predio_id = P.predio_id
         AND PA.uot_id = @Uot AND PA.estado = 1 AND PA.convenio_uot_organizacion_id IS NULL
    LEFT JOIN geo.Ubicacion U WITH (NOLOCK) ON U.ubicacion_id = P.ubicacion_id
    WHERE P.estado = 1
      AND (EXISTS (SELECT 1 FROM prod.ProductorPredioTecnico T WITH (NOLOCK)
                   WHERE T.predio_id = P.predio_id AND T.persona_id = @Persona AND T.uot_id = @Uot)
        OR EXISTS (SELECT 1 FROM prod.PredioTitularidad PT WITH (NOLOCK)
                   WHERE PT.predio_id = P.predio_id AND PT.persona_id = @Persona
                     AND PT.estado = 1 AND PT.fecha_hasta IS NULL))
    ORDER BY P.nombre, P.parcela_id;
END;
GO
