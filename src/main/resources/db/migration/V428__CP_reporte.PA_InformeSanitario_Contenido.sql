IF OBJECT_ID(N'[reporte].[PA_InformeSanitario_Contenido]') IS NOT NULL
    DROP PROCEDURE [reporte].[PA_InformeSanitario_Contenido];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : reporte.PA_InformeSanitario_Contenido
' Descripción            : Ejecuta el proceso de informe sanitario contenido.
' Aplicativo / Módulo    : DESCO / reporte
*******************************************************************************************************/
CREATE   PROCEDURE reporte.PA_InformeSanitario_Contenido @trabajoId BIGINT,@contenido NVARCHAR(MAX) OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @uot BIGINT,@convenio BIGINT,@predio BIGINT,@socio BIGINT,@tipo VARCHAR(30),@desde DATE,@hasta DATE;
 SELECT @uot=uot_id,@convenio=convenio_id,@predio=predio_id,@socio=socio_id,@tipo=tipo,@desde=fecha_desde,@hasta=fecha_hasta
 FROM reporte.TrabajoEspecial WHERE trabajo_id=@trabajoId AND estado='PROCESANDO' AND tipo IN('AP_SANIDAD','TEC_SANIDAD_DOC');
 IF @predio IS NULL THROW 51050,N'Informe no disponible.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.PredioAmbito WHERE predio_id=@predio AND uot_id=@uot AND estado=1
 AND ((@tipo='AP_SANIDAD' AND convenio_uot_organizacion_id=@convenio)
 OR (@tipo='TEC_SANIDAD_DOC' AND convenio_uot_organizacion_id IS NULL))) THROW 51050,N'Predio fuera del ámbito.',1;
 SET @contenido=(SELECT
  JSON_QUERY((SELECT P.nombre predio,P.codigo codigo,UOT.nombre unidad,
    D.nombre distrito,PR.nombre provincia,DP.nombre departamento,CP.nombre centroPoblado,
    CASE WHEN U.posicion IS NOT NULL THEN U.posicion.Lat END latitud,
    CASE WHEN U.posicion IS NOT NULL THEN U.posicion.Long END longitud,
    CASE WHEN @socio IS NULL THEN N'Todos los socios del predio' ELSE CONCAT(PE.nombres,N' ',PE.apellido_paterno,N' ',COALESCE(PE.apellido_materno,N'')) END socio
    FROM prod.Predio P JOIN org.UOT UOT ON UOT.uot_id=@uot
    JOIN geo.Ubicacion U ON U.ubicacion_id=P.ubicacion_id
    JOIN geo.Distrito D ON D.distrito_codigo=U.distrito_codigo
    JOIN geo.Provincia PR ON PR.provincia_codigo=D.provincia_codigo
    JOIN geo.Departamento DP ON DP.departamento_codigo=PR.departamento_codigo
    LEFT JOIN geo.CentroPoblado CP ON CP.centro_poblado_id=U.centro_poblado_id
    LEFT JOIN org.Persona PE ON PE.persona_id=@socio WHERE P.predio_id=@predio FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) cabecera,
  JSON_QUERY((SELECT V.nombre variedad,P.estado_actual estado,COUNT_BIG(*) cantidad
    FROM prod.PlantaPaltaE3 P JOIN prod.VariedadPalta V ON V.variedad_palta_id=P.variedad_palta_id
    WHERE @tipo='AP_SANIDAD' AND P.predio_id=@predio AND P.uot_id=@uot AND P.convenio_id=@convenio AND P.activo=1
      AND (@socio IS NULL OR P.socio_id=@socio)
    GROUP BY V.nombre,P.estado_actual FOR JSON PATH)) plantas,
  JSON_QUERY((SELECT COALESCE(VP.nombre,VC.nombre,N'Cultivo') variedad,C.plantas_totales cantidad,
     C.plantas_afectadas afectadas,C.plantas_muertas muertas,C.fecha_censo fecha
     FROM prod.Parcela P JOIN prod.ParcelaCultivo PC ON PC.parcela_id=P.parcela_id AND PC.estado=1
     OUTER APPLY (SELECT TOP(1) C.plantas_totales,C.plantas_afectadas,C.plantas_muertas,C.fecha_censo
       FROM prod.CensoPlantas C WHERE C.parcela_cultivo_id=PC.parcela_cultivo_id AND C.estado=1 AND C.fecha_censo<=@hasta
       ORDER BY C.fecha_censo DESC,C.censo_plantas_id DESC) C
     LEFT JOIN prod.VariedadPalta VP ON VP.variedad_palta_id=PC.variedad_palta_id
     LEFT JOIN prod.VariedadCultivo VC ON VC.variedad_cultivo_id=PC.variedad_cultivo_id
     WHERE @tipo='TEC_SANIDAD_DOC' AND P.predio_id=@predio AND C.fecha_censo IS NOT NULL
     ORDER BY variedad,fecha FOR JSON PATH)) censos,
  JSON_QUERY((SELECT V.visita_tecnica_id id,V.fecha_hora_inicio fecha,V.objetivo,V.resumen,V.recomendaciones
   FROM campo.VisitaTecnica V WHERE V.predio_id=@predio AND V.estado=1
    AND CONVERT(DATE,V.fecha_hora_inicio) BETWEEN @desde AND @hasta ORDER BY V.fecha_hora_inicio,V.visita_tecnica_id FOR JSON PATH)) visitas,
  JSON_QUERY((SELECT C.caso_fitosanitario_id id,C.fecha_deteccion fecha,T.nombre problema,C.severidad,C.estado_caso estado,
    C.plantas_afectadas cantidad,C.cantidad_estimada estimada,C.observacion
    FROM sanidad.CasoFitosanitario C JOIN prod.ParcelaCultivo PC ON PC.parcela_cultivo_id=C.parcela_cultivo_id
    JOIN prod.Parcela P ON P.parcela_id=PC.parcela_id AND P.predio_id=@predio
    JOIN sanidad.TipoProblemaFitosanitario T ON T.tipo_problema_fitosanitario_id=C.tipo_problema_fitosanitario_id
    WHERE C.estado=1 AND CONVERT(DATE,C.fecha_deteccion) BETWEEN @desde AND @hasta
    ORDER BY C.fecha_deteccion,C.caso_fitosanitario_id FOR JSON PATH)) casos,
  JSON_QUERY((SELECT S.seguimiento_fitosanitario_id id,S.fecha_hora fecha,S.resultado,S.observacion,S.severidad,
    T.nombre problema FROM sanidad.SeguimientoFitosanitario S JOIN sanidad.CasoFitosanitario C ON C.caso_fitosanitario_id=S.caso_fitosanitario_id
    JOIN sanidad.TipoProblemaFitosanitario T ON T.tipo_problema_fitosanitario_id=C.tipo_problema_fitosanitario_id
    JOIN prod.ParcelaCultivo PC ON PC.parcela_cultivo_id=C.parcela_cultivo_id JOIN prod.Parcela P ON P.parcela_id=PC.parcela_id AND P.predio_id=@predio
    WHERE S.estado=1 AND CONVERT(DATE,S.fecha_hora) BETWEEN @desde AND @hasta
    ORDER BY S.fecha_hora,S.seguimiento_fitosanitario_id FOR JSON PATH)) seguimientos,
  JSON_QUERY((SELECT T.tratamiento_fitosanitario_id id,T.fecha_hora fecha,T.tratamiento,T.producto,T.dosis,T.unidad_dosis,T.observacion
    FROM sanidad.TratamientoFitosanitario T JOIN sanidad.CasoFitosanitario C ON C.caso_fitosanitario_id=T.caso_fitosanitario_id
    JOIN prod.ParcelaCultivo PC ON PC.parcela_cultivo_id=C.parcela_cultivo_id JOIN prod.Parcela P ON P.parcela_id=PC.parcela_id AND P.predio_id=@predio
    WHERE T.estado=1 AND CONVERT(DATE,T.fecha_hora) BETWEEN @desde AND @hasta
    ORDER BY T.fecha_hora,T.tratamiento_fitosanitario_id FOR JSON PATH)) tratamientos,
  JSON_QUERY((SELECT E.episodio_id id,P.codigo planta,E.inicio fecha,COALESCE(T.nombre,G.nombre,N'Sin clasificación') problema,
    E.observacion,E.motivo_cierre cierre,E.fin fechaCierre
    FROM sanidad.EpisodioPlantaE3 E JOIN prod.PlantaPaltaE3 P ON P.planta_id=E.planta_id AND P.predio_id=@predio
     AND P.uot_id=@uot AND P.convenio_id=@convenio
    LEFT JOIN sanidad.TipoProblemaFitosanitario T ON T.tipo_problema_fitosanitario_id=E.tipo_problema_fitosanitario_id
    LEFT JOIN prod.GPProblema G ON G.problema_id=E.gp_problema_id
    WHERE @tipo='AP_SANIDAD' AND E.activo=1 AND E.eliminado_en IS NULL
      AND (@socio IS NULL OR P.socio_id=@socio) AND CONVERT(DATE,E.inicio) BETWEEN @desde AND @hasta
    ORDER BY E.inicio,E.episodio_id FOR JSON PATH)) episodios,
  JSON_QUERY((SELECT A.aplicacion_id id,P.codigo planta,A.fecha_aplicacion fecha,A.comentario,A.resultado
    FROM sanidad.TratamientoAplicacionE4 A JOIN sanidad.EpisodioPlantaE3 E ON E.episodio_id=A.episodio_id AND E.activo=1
    JOIN prod.PlantaPaltaE3 P ON P.planta_id=E.planta_id AND P.predio_id=@predio AND P.uot_id=@uot AND P.convenio_id=@convenio
    WHERE @tipo='AP_SANIDAD' AND (@socio IS NULL OR P.socio_id=@socio)
      AND A.fecha_aplicacion BETWEEN @desde AND @hasta
    ORDER BY A.fecha_aplicacion,A.aplicacion_id FOR JSON PATH)) aplicaciones,
  JSON_QUERY((SELECT E.evento_id id,P.codigo planta,E.fecha_hecho fecha,E.tipo,
    E.estado_anterior anterior,E.estado_nuevo nuevo,E.observacion
    FROM prod.PlantaEventoE3 E JOIN prod.PlantaPaltaE3 P ON P.planta_id=E.planta_id AND P.predio_id=@predio
      AND P.uot_id=@uot AND P.convenio_id=@convenio
    WHERE @tipo='AP_SANIDAD' AND (@socio IS NULL OR P.socio_id=@socio)
      AND CONVERT(DATE,E.fecha_hecho) BETWEEN @desde AND @hasta
    ORDER BY E.fecha_hecho,E.evento_id FOR JSON PATH)) eventosPlanta,
  JSON_QUERY((SELECT S.seguimiento_id id,P.codigo planta,S.fecha_hecho fecha,S.observacion,S.resultado
    FROM sanidad.PlantaSeguimientoE3 S JOIN prod.PlantaPaltaE3 P ON P.planta_id=S.planta_id AND P.predio_id=@predio
      AND P.uot_id=@uot AND P.convenio_id=@convenio
    WHERE @tipo='AP_SANIDAD' AND (@socio IS NULL OR P.socio_id=@socio)
      AND CONVERT(DATE,S.fecha_hecho) BETWEEN @desde AND @hasta
    ORDER BY S.fecha_hecho,S.seguimiento_id FOR JSON PATH)) seguimientosPlanta,
  JSON_QUERY((SELECT T.tratamiento_id id,P.codigo planta,T.fecha_aplicacion fecha,T.descripcion,T.comentario,T.resultado
    FROM sanidad.TratamientoPlantaE3 T JOIN sanidad.EpisodioPlantaE3 E ON E.episodio_id=T.episodio_id
    JOIN prod.PlantaPaltaE3 P ON P.planta_id=E.planta_id AND P.predio_id=@predio AND P.uot_id=@uot AND P.convenio_id=@convenio
    WHERE @tipo='AP_SANIDAD' AND (@socio IS NULL OR P.socio_id=@socio)
      AND CONVERT(DATE,T.fecha_aplicacion) BETWEEN @desde AND @hasta
    ORDER BY T.fecha_aplicacion,T.tratamiento_id FOR JSON PATH)) tratamientosPlanta,
  JSON_QUERY((SELECT TOP(24) X.id,X.nombre,X.mime,X.clave,X.url,X.planta,X.fecha
   FROM (
    SELECT F.archivo_id id,F.nombre_original nombre,F.mime_type mime,F.clave_almacenamiento clave,
     COALESCE(F.secure_url,F.url_almacenamiento) url,P.codigo planta,CONVERT(NVARCHAR(10),EV.fecha,23) fecha
    FROM prod.PlantaEvidenciaE3 EV JOIN prod.PlantaPaltaE3 P ON P.planta_id=EV.planta_id AND P.predio_id=@predio
      AND P.uot_id=@uot AND P.convenio_id=@convenio
    JOIN archivo.Archivo F ON F.archivo_id=EV.archivo_id AND F.estado=1 AND F.mime_type IN('image/jpeg','image/png')
    WHERE @tipo='AP_SANIDAD' AND (@socio IS NULL OR P.socio_id=@socio) AND CONVERT(DATE,EV.fecha) BETWEEN @desde AND @hasta
    UNION ALL
    SELECT F.archivo_id,F.nombre_original,F.mime_type,F.clave_almacenamiento,COALESCE(F.secure_url,F.url_almacenamiento),
      P.codigo,CONVERT(NVARCHAR(10),A.fecha_aplicacion,23)
    FROM sanidad.TratamientoArchivoE4 TA JOIN sanidad.TratamientoAplicacionE4 A ON A.aplicacion_id=TA.aplicacion_id
    JOIN sanidad.EpisodioPlantaE3 E ON E.episodio_id=A.episodio_id AND E.activo=1
    JOIN prod.PlantaPaltaE3 P ON P.planta_id=E.planta_id AND P.predio_id=@predio
      AND P.uot_id=@uot AND P.convenio_id=@convenio
    JOIN archivo.Archivo F ON F.archivo_id=TA.archivo_id AND F.estado=1 AND F.mime_type IN('image/jpeg','image/png')
    WHERE @tipo='AP_SANIDAD' AND (@socio IS NULL OR P.socio_id=@socio) AND A.fecha_aplicacion BETWEEN @desde AND @hasta
    UNION ALL
    SELECT F.archivo_id,F.nombre_original,F.mime_type,F.clave_almacenamiento,
      COALESCE(F.secure_url,F.url_almacenamiento),N'Predio',CONVERT(NVARCHAR(10),COALESCE(F.fecha_captura,F.fecha_carga),23)
    FROM archivo.ArchivoVinculo V JOIN archivo.Archivo F ON F.archivo_id=V.archivo_id AND F.estado=1
      AND F.mime_type IN('image/jpeg','image/png')
    WHERE @tipo='TEC_SANIDAD_DOC' AND V.estado=1
      AND (V.predio_id=@predio OR V.visita_tecnica_id IN(SELECT T.visita_tecnica_id FROM campo.VisitaTecnica T WHERE T.predio_id=@predio)
           OR V.caso_fitosanitario_id IN(SELECT S.caso_fitosanitario_id FROM sanidad.CasoFitosanitario S
            JOIN prod.ParcelaCultivo C ON C.parcela_cultivo_id=S.parcela_cultivo_id
            JOIN prod.Parcela P ON P.parcela_id=C.parcela_id WHERE P.predio_id=@predio)
           OR V.tratamiento_id IN(SELECT T.tratamiento_fitosanitario_id FROM sanidad.TratamientoFitosanitario T
             JOIN sanidad.CasoFitosanitario S ON S.caso_fitosanitario_id=T.caso_fitosanitario_id
             JOIN prod.ParcelaCultivo C ON C.parcela_cultivo_id=S.parcela_cultivo_id
             JOIN prod.Parcela P ON P.parcela_id=C.parcela_id WHERE P.predio_id=@predio))
      AND CONVERT(DATE,COALESCE(F.fecha_captura,F.fecha_carga)) BETWEEN @desde AND @hasta
   ) X ORDER BY X.fecha,X.id FOR JSON PATH)) anexos,
  @desde desde,@hasta hasta,@tipo tipo
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
END;
GO
