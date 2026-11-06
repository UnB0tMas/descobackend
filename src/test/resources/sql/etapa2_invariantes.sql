-- DESCO Etapa 2 - verificaciones de regresión no destructivas T05/T06/T07.
-- Ejecutar en una base de pruebas después de poblar solicitudes y registrar
-- aprobación, entrega, visita, retorno e inspección desde la API E2.
SET NOCOUNT ON;

-- T05: no debe existir visita operativa iniciada antes de autorización efectiva.
IF EXISTS (
    SELECT 1
    FROM campo.SalidaVisitaE2 SV
    JOIN campo.SalidaDestinoE2 D ON D.destino_id=SV.destino_id
    JOIN campo.SalidaE2 S ON S.salida_campo_id=D.salida_campo_id
    JOIN campo.VisitaTecnica V ON V.visita_tecnica_id=SV.visita_tecnica_id
    WHERE S.fecha_aprobacion IS NULL
       OR V.fecha_hora_inicio < S.fecha_aprobacion
)
    THROW 52005, N'T05: hay visitas sin aprobación vigente.', 1;

-- T06: un bien exclusivo no puede estar entregado simultáneamente en dos salidas.
IF EXISTS (
    SELECT 1 FROM campo.SalidaRecursoE2 SR
    WHERE SR.estado IN ('ENTREGADO','INCIDENCIA')
    GROUP BY SR.bien_inventario_id
    HAVING COUNT(DISTINCT SR.salida_campo_id)>1
)
    THROW 52006, N'T06: un mismo bien permanece ocupado por varias salidas.', 1;

-- T07: sólo una inspección conforme autoriza la devolución efectiva.
IF EXISTS (
    SELECT 1
    FROM campo.SalidaRecursoE2 SR
    JOIN logistica.RecursoProgramado RP ON RP.recurso_programado_id=SR.recurso_programado_id
    WHERE (SR.resultado_validado IN ('DANADO','FALTANTE') AND RP.cantidad_devuelta>0)
       OR (SR.estado='VALIDADO' AND SR.resultado_validado='CONFORME'
              AND (RP.cantidad_devuelta<>1 OR RP.cantidad_pendiente<>0))
)
    THROW 52007, N'T07: conciliación física incorrecta de recurso.', 1;

-- Guardas instaladas en las rutas de PA legado.
IF EXISTS (
    SELECT 1 FROM (VALUES
        ('campo.TR_E2_VisitaAutorizada'),
        ('campo.TR_E2_TransicionSalidaAutorizada'),
        ('logistica.TR_E2_ReservaSalidaAutorizada'),
        ('logistica.TR_E2_MovimientoSalidaAutorizada')
    ) A(nombre)
    WHERE OBJECT_ID(A.nombre,'TR') IS NULL
)
    THROW 52008, N'No se encontraron todas las guardas E2.', 1;

SELECT 'E2 T05-T07: invariantes persistidas sin diferencias' AS resultado;
