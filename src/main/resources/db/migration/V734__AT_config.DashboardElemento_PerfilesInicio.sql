-- Inicio: catálogo de indicadores y gráficos reales, extensible por rol.
SET NOCOUNT ON;
DECLARE @Catalogo TABLE (
    codigo VARCHAR(80) PRIMARY KEY,
    tipo VARCHAR(12), titulo NVARCHAR(180), subtitulo NVARCHAR(300),
    permiso_codigo VARCHAR(80), unidad NVARCHAR(30), tipo_grafico VARCHAR(20),
    permite_fechas BIT, ancho TINYINT, orden SMALLINT
);
INSERT INTO @Catalogo (codigo,tipo,titulo,subtitulo,permiso_codigo,unidad,tipo_grafico,permite_fechas,ancho,orden)
VALUES
        (N'KPI_PRODUCTORES_ACTIVOS', N'KPI', N'Productores activos', NULL, N'PRODUCTORES_LISTAR', NULL, NULL, 0, 1, 10),
        (N'KPI_SALIDAS_PROGRAMADAS', N'KPI', N'Salidas programadas', NULL, N'SALIDAS_LISTAR', NULL, NULL, 0, 1, 20),
        (N'KPI_SANIDAD_ABIERTA', N'KPI', N'Casos por atender', NULL, N'SANIDAD_LISTAR', NULL, NULL, 0, 1, 30),
        (N'GRAF_VISITAS_ESTADO', N'GRAFICO', N'Visitas técnicas', N'Distribución de visitas', N'VISITAS_LISTAR', NULL, N'DONUT', 1, 1, 40),
        (N'GRAF_CAMPANIAS_ESTADO', N'GRAFICO', N'Campañas comerciales', N'Seguimiento de campañas', N'CAMPANIAS_LISTAR', NULL, N'COLUMN', 1, 1, 50),
        (N'KPI_CENSOS_PERIODO', N'KPI', N'Censos realizados', NULL, N'CENSOS_LISTAR', NULL, NULL, 1, 1, 10),
        (N'GRAF_PRODUCCION_MENSUAL', N'GRAFICO', N'Producción mensual', N'Producción confirmada', N'PRODUCCION_LISTAR', N'kg', N'AREA', 1, 1, 50),
        (N'KPI_POS_VENTAS_PERIODO', N'KPI', N'Mis ventas', NULL, N'CAJAS_LISTAR', NULL, NULL, 1, 1, 10),
        (N'KPI_POS_MONTO_PERIODO', N'KPI', N'Monto de mis ventas', NULL, N'CAJAS_LISTAR', N'PEN', NULL, 1, 1, 20),
        (N'KPI_POS_CAJA_ABIERTA', N'KPI', N'Mis cajas abiertas', NULL, N'CAJAS_LISTAR', NULL, NULL, 0, 1, 30),
        (N'GRAF_POS_VENTAS_DIAS', N'GRAFICO', N'Ventas por día', N'Ventas confirmadas propias', N'CAJAS_LISTAR', N'PEN', N'AREA', 1, 1, 40),
        (N'GRAF_POS_ESTADOS', N'GRAFICO', N'Estado de ventas', N'Ventas propias del periodo', N'CAJAS_LISTAR', NULL, N'DONUT', 1, 1, 50);

INSERT INTO config.DashboardElemento
    (codigo,tipo,titulo,subtitulo,permiso_id,unidad,tipo_grafico,permite_fechas,ancho,orden,estado)
SELECT C.codigo,C.tipo,C.titulo,C.subtitulo,P.permiso_id,C.unidad,C.tipo_grafico,
       C.permite_fechas,C.ancho,C.orden,1
FROM @Catalogo C
INNER JOIN seg.Permiso P WITH (NOLOCK) ON P.codigo=C.permiso_codigo AND P.estado=1
WHERE NOT EXISTS (
    SELECT 1 FROM config.DashboardElemento E WITH (NOLOCK) WHERE E.codigo=C.codigo
);
