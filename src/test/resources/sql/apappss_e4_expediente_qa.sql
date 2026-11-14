-- QA E4/APAPPSS. SOLO LECTURA: no crea, modifica ni elimina datos.
-- Ejecutar despues de V644 en una BD de pruebas con datos representativos.
SET NOCOUNT ON;
IF OBJECT_ID(N'prod.PredioMateriaSecaGlobalE4',N'U') IS NULL
 OR OBJECT_ID(N'prod.PlantaMateriaSecaIndividualE4',N'U') IS NULL
 OR OBJECT_ID(N'sanidad.EpisodioNotaE4',N'U') IS NULL
 OR OBJECT_ID(N'sanidad.TratamientoAplicacionE4',N'U') IS NULL
 OR OBJECT_ID(N'prod.PA_E3_ExpedienteE4_Ejecutar',N'P') IS NULL
 THROW 51401,N'Faltan objetos E4. Ejecutar la migracion V644.',1;

IF EXISTS(SELECT 1 FROM prod.PredioMateriaSecaGlobalE4 G
 WHERE G.cantidad_plantas<1 OR G.cantidad_plantas>G.total_plantas_activas
    OR (G.cobertura='TOTAL' AND G.cantidad_plantas<>G.total_plantas_activas)
    OR (G.cobertura='PARCIAL' AND G.cantidad_plantas>=G.total_plantas_activas))
 THROW 51402,N'Inconsistencia en el alcance de materia seca global.',1;

IF EXISTS(SELECT 1 FROM prod.PlantaMateriaSecaIndividualE4 M
 JOIN prod.PlantaPaltaE3 P ON P.planta_id=M.planta_id
 WHERE M.porcentaje<=0 OR M.porcentaje>100 OR P.predio_id IS NULL)
 THROW 51403,N'Medicion individual invalida o planta inexistente.',1;

IF EXISTS(SELECT 1 FROM sanidad.TratamientoPlantaE3 T
 JOIN sanidad.TratamientoAplicacionE4 A ON A.aplicacion_id=T.aplicacion_id
 JOIN sanidad.EpisodioPlantaE3 E ON E.episodio_id=T.episodio_id
 WHERE T.episodio_id<>A.episodio_id OR T.fecha_aplicacion<E.inicio
   OR CONVERT(DATE,T.fecha_aplicacion)<>A.fecha_aplicacion)
 THROW 51404,N'La aplicacion y el tratamiento no pertenecen al mismo episodio o fecha.',1;

IF EXISTS(SELECT 1 FROM sanidad.TratamientoAplicacionE4 A
 WHERE NOT EXISTS(SELECT 1 FROM sanidad.TratamientoPlantaE3 T WHERE T.aplicacion_id=A.aplicacion_id))
 THROW 51405,N'Una aplicacion de tratamientos no tiene elementos.',1;

IF EXISTS(SELECT 1 FROM sanidad.EpisodioNotaE4 N
 JOIN sanidad.EpisodioPlantaE3 E ON E.episodio_id=N.episodio_id
 WHERE N.fecha_registro<E.inicio)
 THROW 51406,N'Comentario fechado antes de abrir la enfermedad.',1;

IF (SELECT COUNT(*) FROM seg.Permiso WHERE codigo IN
 ('APAPPSS_PLANTAS_SALUD_COMENTAR','APAPPSS_PLANTAS_TRATAMIENTO_LOTE',
  'APAPPSS_PLANTAS_SECA_REGISTRAR','APAPPSS_PREDIOS_SECA_LOTE') AND estado=1)<>4
 THROW 51407,N'Faltan permisos granulares del expediente.',1;

IF EXISTS(SELECT 1 FROM seg.Permiso P
 WHERE P.codigo IN ('APAPPSS_PLANTAS_SALUD_COMENTAR','APAPPSS_PLANTAS_TRATAMIENTO_LOTE',
    'APAPPSS_PLANTAS_SECA_REGISTRAR','APAPPSS_PREDIOS_SECA_LOTE')
  AND NOT EXISTS(SELECT 1 FROM seg.RolPermiso RP JOIN seg.Rol R ON R.rol_id=RP.rol_id
   WHERE RP.permiso_id=P.permiso_id AND R.codigo='ADMINISTRADOR' AND R.estado=1 AND RP.estado=1))
 THROW 51408,N'ADMINISTRADOR no tiene todos los permisos E4.',1;

SELECT 'QA_OK' resultado,
 (SELECT COUNT(*) FROM sanidad.EpisodioNotaE4) notas_enfermedad,
 (SELECT COUNT(*) FROM sanidad.TratamientoAplicacionE4) aplicaciones,
 (SELECT COUNT(*) FROM prod.PlantaMateriaSecaIndividualE4) mediciones_individuales,
 (SELECT COUNT(*) FROM prod.PredioMateriaSecaGlobalE4) informes_globales,
 (SELECT COUNT(*) FROM prod.PredioMateriaSecaGlobalE4 WHERE cobertura='PARCIAL') informes_parciales;
