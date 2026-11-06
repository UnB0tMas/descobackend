-- DESCO APAPPSS Etapa 4: invariantes verificables contra una BD de pruebas ya migrada.
-- No modifica datos. Ejecutar sobre una BD controlada después de Flyway; fallará ante inconsistencias.
SET NOCOUNT ON;
IF EXISTS (
    SELECT 1 FROM comercial.JabaAsignacion A
    JOIN comercial.JabaUnidadE4 U ON U.jaba_asignacion_id=A.jaba_asignacion_id
    WHERE A.estado=1
    GROUP BY A.jaba_asignacion_id,A.cantidad_asignada
    HAVING COUNT_BIG(*)<>A.cantidad_asignada
) THROW 51400,N'No coincide cantidad asignada con unidades físicas identificadas.',1;
IF EXISTS (
    SELECT 1 FROM comercial.CampaniaControlE4 K
    CROSS APPLY (
        SELECT COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-A.cantidad_devuelta),0) usadas
        FROM comercial.JabaAsignacion A
        JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
        JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
        WHERE O.campania_venta_id=K.campania_venta_id AND A.estado=1
    ) S WHERE S.usadas>K.cupo_jabas
) THROW 51401,N'Una campaña ha excedido su cupo de jabas.',1;
IF EXISTS (
    SELECT 1 FROM comercial.JabaStockUotE4 S
    CROSS APPLY (
        SELECT COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-COALESCE(V.cantidad_validada,0)),0) retenidas
        FROM comercial.JabaAsignacion A
        JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
        JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
        JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id
        LEFT JOIN comercial.JabaRetornoValidadoE4 V ON V.jaba_asignacion_id=A.jaba_asignacion_id
        WHERE C.uot_id=S.uot_id AND A.estado=1
    ) T WHERE T.retenidas>S.existencia_certificada
) THROW 51402,N'Hay jabas retenidas en exceso del stock físico de UOT.',1;
IF EXISTS (
    SELECT 1 FROM comercial.JabaUnidadE4 U
    WHERE U.pesaje_estado='PESADA'
      AND (U.peso_bruto_kg<=U.tara_kg OR U.peso_neto_kg<>U.peso_bruto_kg-U.tara_kg)
) THROW 51403,N'Existe un pesaje con tara o neto inconsistente.',1;
IF EXISTS (
    SELECT 1 FROM comercial.JabaUnidadE4 U
    JOIN comercial.JabaClasificacionE4 C ON C.unidad_id=U.unidad_id
    GROUP BY U.unidad_id,U.peso_neto_kg
    HAVING SUM(C.peso_kg)<>U.peso_neto_kg
) THROW 51404,N'Hay clasificación distinta del neto de la jaba.',1;
IF EXISTS (
    SELECT 1 FROM comercial.CargoIndividualE4 C
    JOIN comercial.CargoTarifaE4 T ON T.tarifa_id=C.tarifa_id
    WHERE C.precio_unitario<>T.precio_unitario
) THROW 51405,N'Un cargo no conserva el precio unitario de la tarifa histórica.',1;
SELECT N'E4: invariantes de inventario, cupo, pesaje y tarifas verificadas.' AS resultado;
