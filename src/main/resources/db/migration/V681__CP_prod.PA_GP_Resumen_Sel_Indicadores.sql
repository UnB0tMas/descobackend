IF OBJECT_ID(N'[prod].[PA_GP_Resumen_Sel_Indicadores]', N'P') IS NOT NULL
    DROP PROCEDURE [prod].[PA_GP_Resumen_Sel_Indicadores];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- Resumen productivo con período y tipo de actuación. Solo el ámbito general autorizado.
CREATE PROCEDURE [prod].[PA_GP_Resumen_Sel_Indicadores]
    @Sesion UNIQUEIDENTIFIER,
    @Usuario BIGINT,
    @Uot BIGINT,
    @Actividad BIGINT,
    @Periodo VARCHAR(5) = '12M',
    @TipoEvento VARCHAR(20) = 'TODOS'
AS
BEGIN
    SET NOCOUNT ON;

    IF @Periodo NOT IN ('90D', '12M', 'TODO') OR @Periodo IS NULL
        THROW 51103, N'Período inválido.', 1;

    IF @TipoEvento NOT IN ('TODOS', 'OBSERVACION', 'EVALUACION', 'INCIDENCIA', 'TRATAMIENTO', 'RESPUESTA') OR @TipoEvento IS NULL
        THROW 51103, N'Tipo de registro inválido.', 1;

    IF prod.FN_GP_Permiso(@Sesion, @Usuario, @Uot, 'CULTIVOS_VER', 0) <> 1
        OR prod.FN_GP_Permiso(@Sesion, @Usuario, @Uot, 'CENSOS_LISTAR', 0) <> 1
        OR prod.FN_GP_Permiso(@Sesion, @Usuario, @Uot, 'PREDIOS_VER', 0) <> 1
    BEGIN
        THROW 51101, N'Acceso no autorizado.', 1;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM prod.GPActividad A WITH (NOLOCK)
        INNER JOIN prod.Parcela P WITH (NOLOCK) ON P.parcela_id = A.parcela_id AND P.estado = 1
        INNER JOIN prod.PredioAmbito U WITH (NOLOCK) ON U.predio_id = A.predio_id
            AND U.uot_id = @Uot AND U.estado = 1 AND U.convenio_uot_organizacion_id IS NULL
        WHERE A.actividad_id = @Actividad AND A.uot_id = @Uot AND A.estado = 1
    )
    BEGIN
        THROW 51102, N'Actividad no disponible.', 1;
    END;

    DECLARE @Desde DATE = CASE @Periodo
        WHEN '90D' THEN DATEADD(DAY, -90, CONVERT(DATE, SYSUTCDATETIME()))
        WHEN '12M' THEN DATEADD(MONTH, -12, CONVERT(DATE, SYSUTCDATETIME()))
        ELSE NULL
    END;
    DECLARE @Hasta DATE = CONVERT(DATE, SYSUTCDATETIME());
    DECLARE @Datos NVARCHAR(MAX);

    SELECT @Datos = (
        SELECT
            (SELECT COUNT_BIG(1)
             FROM prod.GPCenso C WITH (NOLOCK)
             WHERE C.actividad_id = @Actividad AND C.estado = 1
                 AND (@Desde IS NULL OR C.fecha >= @Desde) AND C.fecha <= @Hasta) AS mediciones,
            (SELECT COUNT_BIG(1)
             FROM prod.GPEvento E WITH (NOLOCK)
             WHERE E.actividad_id = @Actividad AND E.estado = 1
                 AND (@Desde IS NULL OR E.fecha_hecho >= @Desde)
                 AND E.fecha_hecho < DATEADD(DAY, 1, @Hasta)
                 AND (@TipoEvento = 'TODOS' OR E.tipo = @TipoEvento)) AS seguimientos,
            (SELECT COUNT_BIG(1)
             FROM prod.GPIncidencia I WITH (NOLOCK)
             INNER JOIN prod.GPEvento E WITH (NOLOCK) ON E.evento_id = I.incidencia_id AND E.estado = 1
             WHERE I.actividad_id = @Actividad AND I.estado = 1 AND I.estado_seguimiento = 'ABIERTA'
                 AND (@Desde IS NULL OR E.fecha_hecho >= @Desde)
                 AND E.fecha_hecho < DATEADD(DAY, 1, @Hasta)) AS incidenciasAbiertas,
            JSON_QUERY((
                SELECT T.fecha, T.valor
                FROM (
                    SELECT TOP (48) C.censo_id, C.fecha,
                        CONVERT(DECIMAL(14,2), CASE WHEN A.rubro = 'CRIANZA'
                            THEN COALESCE(C.cantidad_exacta, C.cantidad_aproximada, C.cantidad)
                            ELSE COALESCE(C.superficie_exacta_m2, C.superficie_aproximada_m2)
                        END) AS valor
                    FROM prod.GPCenso C WITH (NOLOCK)
                    INNER JOIN prod.GPActividad A WITH (NOLOCK) ON A.actividad_id = C.actividad_id
                    WHERE C.actividad_id = @Actividad AND C.estado = 1
                        AND (@Desde IS NULL OR C.fecha >= @Desde) AND C.fecha <= @Hasta
                    ORDER BY C.fecha DESC, C.censo_id DESC
                ) T
                WHERE T.valor IS NOT NULL
                ORDER BY T.fecha, T.censo_id
                FOR JSON PATH
            )) AS evolucion,
            JSON_QUERY((
                SELECT E.tipo, COUNT_BIG(1) AS total
                FROM prod.GPEvento E WITH (NOLOCK)
                WHERE E.actividad_id = @Actividad AND E.estado = 1
                    AND (@Desde IS NULL OR E.fecha_hecho >= @Desde)
                    AND E.fecha_hecho < DATEADD(DAY, 1, @Hasta)
                    AND (@TipoEvento = 'TODOS' OR E.tipo = @TipoEvento)
                GROUP BY E.tipo
                ORDER BY E.tipo
                FOR JSON PATH
            )) AS tiposSeguimiento
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );

    SELECT @Datos AS datos;
END;
GO
