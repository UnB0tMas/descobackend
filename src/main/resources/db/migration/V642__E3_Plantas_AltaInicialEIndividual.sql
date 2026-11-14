-- V637: mantiene las operaciones de V624, limitando el contexto y separando eliminación de MUERTA.
-- E3: consolidación Etapa 3 posterior a V447; no reescribir migraciones ejecutadas.
-- E3. Procedimiento único para lecturas, alta masiva, actuaciones y evidencia privada.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE prod.PA_PlantaPaltaE3_Ejecutar
 @cAccion VARCHAR(30), @cJson NVARCHAR(MAX),
 @cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No fue posible procesar las plantas.',@cCodigoRespuesta='E3_ERROR',@nHttpRespuesta=400;
 DECLARE @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
 @conv BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.convenioId')),
 @predio BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.predioId')),
 @planta BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.plantaId')),
 @pagina INT=COALESCE(TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.filtros.pagina')),1),
 @tamano INT=COALESCE(TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.filtros.tamano')),20),
 @buscar NVARCHAR(100)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.filtros.buscar'))),''),
 @fEstado VARCHAR(16)=NULLIF(JSON_VALUE(@cJson,'$.filtros.estado'),''),
 @fVar SMALLINT=TRY_CONVERT(SMALLINT,JSON_VALUE(@cJson,'$.filtros.variedadId')),
 @fParcela BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.parcelaCultivoId')),
 @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
 @usuario BIGINT,@sesion BIGINT,@disp BIGINT,@emp BIGINT,@modulo INT,
 @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
 @auth BIT,@authMensaje NVARCHAR(300),@perm VARCHAR(60),@fecha DATETIME2(0)=SYSUTCDATETIME(),
 @hash VARBINARY(32),@hashViejo VARBINARY(32),@replay NVARCHAR(MAX),@lock INT,
 @lockResource NVARCHAR(255),
 @estadoPrev VARCHAR(16),@estado VARCHAR(16),@visita BIGINT,@episodio BIGINT,@diagnostico INT,
 @observacion NVARCHAR(1000),@id BIGINT,@cantidad INT,@variedad SMALLINT,@parcela BIGINT,
 @correlativo INT,@total INT=0,@archivo BIGINT,@evento BIGINT,
 @hecho DATETIME2(0),@plantacion DATE,@edad SMALLINT,@anio SMALLINT,
 @estimado DECIMAL(14,3),@real DECIMAL(14,3),@accionLog VARCHAR(30),@eventoObjetivo BIGINT,@version BIGINT,@versionActual BIGINT,
 @porcentaje DECIMAL(6,3),@nSeleccion INT,@nDistintos INT,
 @socio BIGINT,@socioSolicitado BIGINT,@socioCantidad INT,@seguimientoTipo VARCHAR(20),
 @resultado NVARCHAR(600),@tipoProduccion VARCHAR(12),@fechaEvento DATE,@correccion BIT,
 @variedadNueva SMALLINT,@variedadVieja SMALLINT,@parcelaNueva BIGINT,@tratamientoCatalogo INT,
 @desde DATE,@hasta DATE;
 IF ISJSON(@cJson)<>1 OR @uot IS NULL OR @conv IS NULL OR @predio IS NULL
 BEGIN SELECT @cMensaje=N'Indique UOT, convenio y predio válidos.',@nHttpRespuesta=400; RETURN; END;
 IF @cAccion NOT IN('CATALOGOS','LISTAR','VER','LOTE','FICHA','ESTADO','TRATAMIENTO','SEGUIMIENTO','PRODUCCION','EVIDENCIA','MASIVO','MEDIR','MEDICIONES','RESUMEN')
 BEGIN SELECT @cMensaje=N'Operación de planta no admitida.',@nHttpRespuesta=400; RETURN; END;
 SET @perm=CASE WHEN @cAccion IN('CATALOGOS','LISTAR','VER','MEDICIONES','RESUMEN') THEN 'APAPPSS_PREDIOS_VER'
     WHEN @cAccion='LOTE' THEN 'APAPPSS_PREDIOS_CREAR' ELSE 'APAPPSS_PREDIOS_EDITAR' END;
 BEGIN TRY
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,@perm,
   @usuario OUTPUT,@sesion OUTPUT,@disp OUTPUT,@emp OUTPUT,@modulo OUTPUT,
   @corr OUTPUT,@sol OUTPUT,@ip OUTPUT,@endpoint OUTPUT,@auth OUTPUT,@authMensaje OUTPUT;
  IF ISNULL(@auth,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,@perm)<>1
     THROW 51100,N'No tiene permisos APAPPSS en esta unidad territorial.',1;
  IF NOT EXISTS(SELECT 1 FROM prod.PredioAmbito A
    JOIN org.ConvenioUOTOrganizacion C ON C.convenio_uot_organizacion_id=A.convenio_uot_organizacion_id
    JOIN org.ConvenioModuloEspecial M ON M.convenio_uot_organizacion_id=C.convenio_uot_organizacion_id AND M.estado=1
    JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=M.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
    JOIN prod.Predio P ON P.predio_id=A.predio_id AND P.estado=1
    WHERE A.predio_id=@predio AND A.uot_id=@uot AND A.convenio_uot_organizacion_id=@conv AND A.estado=1
      AND C.uot_id=@uot AND C.estado=1 AND (C.fecha_inicio IS NULL OR C.fecha_inicio<=CONVERT(DATE,@fecha))
      AND (C.fecha_fin IS NULL OR C.fecha_fin>=CONVERT(DATE,@fecha))
      AND EXISTS(SELECT 1 FROM prod.PredioTitularidad T JOIN org.Socio S ON S.socio_id=T.socio_id
        JOIN org.SocioAsociacion SA ON SA.socio_id=S.socio_id AND SA.asociacion_id=C.empresa_id AND SA.estado=1 AND SA.fecha_desde<=CONVERT(DATE,@fecha) AND (SA.fecha_hasta IS NULL OR SA.fecha_hasta>=CONVERT(DATE,@fecha))
        WHERE T.predio_id=@predio AND T.estado=1 AND T.fecha_hasta IS NULL AND S.estado=1))
     THROW 51101,N'El predio o sus socios no pertenecen al convenio autorizado.',1;
  IF @fParcela IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.ParcelaCultivo PC
    JOIN prod.Parcela PA ON PA.parcela_id=PC.parcela_id
    WHERE PC.parcela_cultivo_id=@fParcela AND PA.predio_id=@predio AND PC.estado=1 AND PC.fecha_fin IS NULL)
    THROW 51101,N'La parcela no pertenece al predio seleccionado.',1;
  IF @cAccion='CATALOGOS'
  BEGIN
   SET @cDatos=(SELECT JSON_QUERY((SELECT V.variedad_palta_id id,V.nombre FROM prod.VariedadPalta V WHERE V.estado=1 ORDER BY V.nombre FOR JSON PATH)) variedades,
      JSON_QUERY((SELECT GP.problema_id id,GP.nombre FROM prod.GPProblema GP
       JOIN prod.Cultivo C ON C.cultivo_id=GP.cultivo_id AND C.estado=1
       WHERE GP.estado=1 AND (UPPER(C.codigo)='PALTA' OR UPPER(C.nombre)=N'PALTA')
       ORDER BY GP.nombre FOR JSON PATH)) diagnosticos,
      JSON_QUERY((SELECT T.tratamiento_id id,T.nombre,R.problema_id problemaId
        FROM prod.GPTratamiento T JOIN prod.GPProblemaTratamiento R ON R.tratamiento_id=T.tratamiento_id
        JOIN prod.GPProblema GP ON GP.problema_id=R.problema_id AND GP.estado=1
        JOIN prod.Cultivo C ON C.cultivo_id=GP.cultivo_id AND C.estado=1
        WHERE T.estado=1 AND (UPPER(C.codigo)='PALTA' OR UPPER(C.nombre)=N'PALTA')
        ORDER BY T.nombre FOR JSON PATH)) tratamientos,
      JSON_QUERY((SELECT PC.parcela_cultivo_id id,P.nombre nombre FROM prod.ParcelaCultivo PC
          JOIN prod.Parcela P ON P.parcela_id=PC.parcela_id AND P.predio_id=@predio
          WHERE PC.estado=1 AND PC.fecha_fin IS NULL ORDER BY P.nombre FOR JSON PATH)) parcelas,
      JSON_QUERY((SELECT DISTINCT T.socio_id id,
          CONCAT(PER.nombres,N' ',PER.apellido_paterno,N' ',ISNULL(PER.apellido_materno,N'')) nombre
          FROM prod.PredioTitularidad T JOIN org.Persona PER ON PER.persona_id=T.socio_id
          JOIN org.SocioAsociacion SA ON SA.socio_id=T.socio_id AND SA.estado=1
          JOIN org.ConvenioUOTOrganizacion C ON C.convenio_uot_organizacion_id=@conv AND C.empresa_id=SA.asociacion_id
          WHERE T.predio_id=@predio AND T.estado=1 AND T.fecha_hasta IS NULL
            AND SA.fecha_desde<=CONVERT(DATE,@fecha) AND (SA.fecha_hasta IS NULL OR SA.fecha_hasta>=CONVERT(DATE,@fecha))
          FOR JSON PATH)) socios
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   SET @bResultado=1;
  END
ELSE IF @cAccion='RESUMEN'
BEGIN
  SET @desde=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.desde'));
  SET @hasta=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.hasta'));
  IF @desde IS NULL OR @hasta IS NULL OR @hasta<@desde
     OR @hasta>CONVERT(DATE,@fecha) OR DATEDIFF(DAY,@desde,@hasta)>366
     THROW 51102,N'Seleccione un periodo válido de hasta un año.',1;
  IF @fEstado IS NOT NULL AND @fEstado NOT IN('SANA','ENFERMA','MUERTA')
     THROW 51102,N'El estado seleccionado no es válido.',1;
  IF @planta IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 P
     WHERE P.planta_id=@planta AND P.predio_id=@predio AND P.uot_id=@uot AND P.convenio_id=@conv)
     THROW 51103,N'La planta no pertenece a este predio.',1;
  SET @cDatos=(SELECT CONVERT(VARCHAR(10),@desde,23) desde,CONVERT(VARCHAR(10),@hasta,23) hasta,
    (SELECT COUNT_BIG(*) FROM prod.PlantaPaltaE3 P WHERE P.predio_id=@predio AND (@fParcela IS NULL OR P.parcela_cultivo_id=@fParcela) AND P.uot_id=@uot AND P.convenio_id=@conv AND (@planta IS NULL OR P.planta_id=@planta)
     AND P.estado_actual NOT IN('MUERTA','ELIMINADA') AND (@fEstado IS NULL OR P.estado_actual=@fEstado)) vivas,
    (SELECT COUNT_BIG(*) FROM prod.PlantaPaltaE3 P WHERE P.predio_id=@predio AND (@fParcela IS NULL OR P.parcela_cultivo_id=@fParcela) AND P.uot_id=@uot AND P.convenio_id=@conv AND (@planta IS NULL OR P.planta_id=@planta)
     AND P.estado_actual='SANA' AND (@fEstado IS NULL OR P.estado_actual=@fEstado)) sanas,
    (SELECT COUNT_BIG(*) FROM prod.PlantaPaltaE3 P WHERE P.predio_id=@predio AND (@fParcela IS NULL OR P.parcela_cultivo_id=@fParcela) AND P.uot_id=@uot AND P.convenio_id=@conv AND (@planta IS NULL OR P.planta_id=@planta)
     AND P.estado_actual='ENFERMA' AND (@fEstado IS NULL OR P.estado_actual=@fEstado)) enfermas,
    (SELECT COUNT_BIG(*) FROM prod.PlantaPaltaE3 P WHERE P.predio_id=@predio AND (@fParcela IS NULL OR P.parcela_cultivo_id=@fParcela) AND P.uot_id=@uot AND P.convenio_id=@conv AND (@planta IS NULL OR P.planta_id=@planta)
     AND P.estado_actual='MUERTA' AND (@fEstado IS NULL OR P.estado_actual=@fEstado)) muertas,
    (SELECT COUNT_BIG(*) FROM sanidad.EpisodioPlantaE3 E JOIN prod.PlantaPaltaE3 P ON P.planta_id=E.planta_id
     WHERE P.predio_id=@predio AND (@fParcela IS NULL OR P.parcela_cultivo_id=@fParcela) AND P.uot_id=@uot AND P.convenio_id=@conv AND (@planta IS NULL OR P.planta_id=@planta)
       AND E.inicio>=@desde AND E.inicio<DATEADD(DAY,1,@hasta)
       AND P.estado_actual<>'ELIMINADA' AND (@fEstado IS NULL OR P.estado_actual=@fEstado)) casosPeriodo,
    (SELECT COUNT_BIG(*) FROM sanidad.TratamientoPlantaE3 T
     JOIN sanidad.EpisodioPlantaE3 E ON E.episodio_id=T.episodio_id
     JOIN prod.PlantaPaltaE3 P ON P.planta_id=E.planta_id
     WHERE P.predio_id=@predio AND (@fParcela IS NULL OR P.parcela_cultivo_id=@fParcela) AND P.uot_id=@uot AND P.convenio_id=@conv AND (@planta IS NULL OR P.planta_id=@planta)
       AND T.fecha_aplicacion>=@desde AND T.fecha_aplicacion<DATEADD(DAY,1,@hasta)
       AND P.estado_actual<>'ELIMINADA' AND (@fEstado IS NULL OR P.estado_actual=@fEstado)) tratamientosPeriodo,
    JSON_QUERY((SELECT CONVERT(VARCHAR(10),CAST(H.fecha_hecho AS DATE),23) fecha,
      SUM(CASE WHEN H.estado_nuevo='ENFERMA' THEN 1 ELSE 0 END) nuevosCasos,
      SUM(CASE WHEN H.estado_nuevo='SANA' AND H.estado_anterior='ENFERMA' THEN 1 ELSE 0 END) recuperadas,
      SUM(CASE WHEN H.estado_nuevo='MUERTA' THEN 1 ELSE 0 END) bajas
     FROM prod.PlantaEventoE3 H JOIN prod.PlantaPaltaE3 P ON P.planta_id=H.planta_id
     WHERE P.predio_id=@predio AND (@fParcela IS NULL OR P.parcela_cultivo_id=@fParcela) AND P.uot_id=@uot AND P.convenio_id=@conv AND (@planta IS NULL OR P.planta_id=@planta)
       AND H.tipo='EVALUACION' AND H.fecha_hecho>=@desde AND H.fecha_hecho<DATEADD(DAY,1,@hasta)
       AND (@fEstado IS NULL OR P.estado_actual=@fEstado)
     GROUP BY CAST(H.fecha_hecho AS DATE) ORDER BY CAST(H.fecha_hecho AS DATE) FOR JSON PATH)) serie
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SET @bResultado=1;
END
  ELSE IF @cAccion='LISTAR'
  BEGIN
   IF @pagina<1 OR @tamano NOT BETWEEN 1 AND 100 THROW 51102,N'Paginación inválida.',1;
   SET @cDatos=(SELECT (SELECT COUNT_BIG(*) FROM prod.PlantaPaltaE3 P WHERE P.predio_id=@predio AND (@fParcela IS NULL OR P.parcela_cultivo_id=@fParcela) AND P.convenio_id=@conv AND P.uot_id=@uot
        AND (@fEstado IS NULL OR P.estado_actual=@fEstado) AND (@fEstado='ELIMINADA' OR P.estado_actual<>'ELIMINADA') AND (@fVar IS NULL OR P.variedad_palta_id=@fVar)
        AND (@buscar IS NULL OR P.codigo LIKE '%'+@buscar+'%')) total,
     JSON_QUERY((SELECT P.planta_id plantaId,P.codigo,V.nombre variedad,P.variedad_palta_id variedadId,P.estado_actual estado,
        P.parcela_cultivo_id parcelaCultivoId, P.socio_id socioId, P.version
       FROM prod.PlantaPaltaE3 P JOIN prod.VariedadPalta V ON V.variedad_palta_id=P.variedad_palta_id
       WHERE P.predio_id=@predio AND (@fParcela IS NULL OR P.parcela_cultivo_id=@fParcela) AND P.convenio_id=@conv AND P.uot_id=@uot
        AND (@fEstado IS NULL OR P.estado_actual=@fEstado) AND (@fEstado='ELIMINADA' OR P.estado_actual<>'ELIMINADA') AND (@fVar IS NULL OR P.variedad_palta_id=@fVar)
        AND (@buscar IS NULL OR P.codigo LIKE '%'+@buscar+'%')
       ORDER BY P.planta_id OFFSET (@pagina-1)*@tamano ROWS FETCH NEXT @tamano ROWS ONLY FOR JSON PATH)) items,
     JSON_QUERY((SELECT V.variedad_palta_id variedadId,V.nombre variedad,COUNT_BIG(*) cantidad,
         SUM(CASE WHEN P.estado_actual='SIN_EVALUAR' THEN CONVERT(BIGINT,1) ELSE 0 END) sinEvaluar,
         SUM(CASE WHEN P.estado_actual='SANA' THEN CONVERT(BIGINT,1) ELSE 0 END) sanas,
         SUM(CASE WHEN P.estado_actual='ENFERMA' THEN CONVERT(BIGINT,1) ELSE 0 END) enfermas,
         SUM(CASE WHEN P.estado_actual='MUERTA' THEN CONVERT(BIGINT,1) ELSE 0 END) muertas,
         COUNT(DISTINCT CASE WHEN Y.tiene_estimacion=1 THEN P.planta_id END) plantasConEstimacion,
         COUNT(DISTINCT CASE WHEN Y.tiene_real=1 THEN P.planta_id END) plantasConCosecha,
         SUM(ISNULL(Y.estimado_kg,0)) estimadoKg,
         SUM(ISNULL(Y.real_kg,0)) realKg
       FROM prod.PlantaPaltaE3 P JOIN prod.VariedadPalta V ON V.variedad_palta_id=P.variedad_palta_id
       LEFT JOIN prod.VW_PlantaProduccionResumenE3 Y ON Y.planta_id=P.planta_id AND Y.anio=YEAR(@fecha)
       WHERE P.predio_id=@predio AND (@fParcela IS NULL OR P.parcela_cultivo_id=@fParcela) AND P.convenio_id=@conv AND P.uot_id=@uot AND P.estado_actual<>'ELIMINADA'
       GROUP BY V.variedad_palta_id,V.nombre FOR JSON PATH)) resumen,
     YEAR(@fecha) anioResumen,
     JSON_QUERY((SELECT P.parcela_cultivo_id parcelaCultivoId,V.variedad_palta_id variedadId,V.nombre variedad,
       COUNT_BIG(*) cantidad,COUNT(DISTINCT CASE WHEN Y.tiene_estimacion=1 THEN P.planta_id END) plantasConEstimacion,
       COUNT(DISTINCT CASE WHEN Y.tiene_real=1 THEN P.planta_id END) plantasConCosecha,
       SUM(ISNULL(Y.estimado_kg,0)) estimadoKg,SUM(ISNULL(Y.real_kg,0)) realKg
       FROM prod.PlantaPaltaE3 P JOIN prod.VariedadPalta V ON V.variedad_palta_id=P.variedad_palta_id
       LEFT JOIN prod.VW_PlantaProduccionResumenE3 Y ON Y.planta_id=P.planta_id AND Y.anio=YEAR(@fecha)
       WHERE P.predio_id=@predio AND (@fParcela IS NULL OR P.parcela_cultivo_id=@fParcela) AND P.convenio_id=@conv AND P.uot_id=@uot AND P.estado_actual<>'ELIMINADA'
       GROUP BY P.parcela_cultivo_id,V.variedad_palta_id,V.nombre FOR JSON PATH)) resumenParcelas
     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   SET @bResultado=1;
  END
  ELSE IF @cAccion='MEDICIONES'
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM prod.PlantaPaltaE3
     WHERE planta_id=@planta AND predio_id=@predio AND uot_id=@uot AND convenio_id=@conv)
      THROW 51103,N'La planta no se encuentra en el predio.',1;
   SET @cDatos=(SELECT JSON_QUERY((SELECT M.medicion_id medicionId,M.planta_id plantaId,
      M.porcentaje,M.visita_tecnica_id visitaId,M.observacion,
      CONVERT(VARCHAR(19),M.fecha_hecho,126)+'Z' fechaHora,M.usuario_id usuarioId
      FROM prod.PlantaMedicionE3 M WHERE M.planta_id=@planta
      ORDER BY M.fecha_hecho DESC,M.medicion_id DESC FOR JSON PATH)) items
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   SET @bResultado=1;
  END
  ELSE IF @cAccion='VER' 
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 WHERE planta_id=@planta AND predio_id=@predio AND convenio_id=@conv AND uot_id=@uot)
      THROW 51103,N'La planta no se encuentra en el predio.',1;
   SET @cDatos=(SELECT P.planta_id plantaId,P.predio_id predioId,P.codigo,V.nombre variedad,P.variedad_palta_id variedadId,
       P.estado_actual estado,P.socio_id socioId,P.creado_por_usuario_id registradoPorUsuarioId,
       CONVERT(VARCHAR(19),P.creado_en,126)+'Z' registradoEn,
       P.fecha_plantacion fechaPlantacion,P.edad_referencia_anios edadReferenciaAnios,
       CASE WHEN P.fecha_plantacion IS NOT NULL THEN DATEDIFF(YEAR,P.fecha_plantacion,CONVERT(DATE,@fecha))
           - CASE WHEN DATEADD(YEAR,DATEDIFF(YEAR,P.fecha_plantacion,CONVERT(DATE,@fecha)),P.fecha_plantacion)>CONVERT(DATE,@fecha) THEN 1 ELSE 0 END
        WHEN P.edad_referencia_anios IS NOT NULL AND P.fecha_referencia IS NOT NULL
           THEN P.edad_referencia_anios+DATEDIFF(YEAR,P.fecha_referencia,CONVERT(DATE,@fecha))
           - CASE WHEN DATEADD(YEAR,DATEDIFF(YEAR,P.fecha_referencia,CONVERT(DATE,@fecha)),P.fecha_referencia)>CONVERT(DATE,@fecha) THEN 1 ELSE 0 END
        ELSE NULL END edadActual,
       P.version, P.parcela_cultivo_id parcelaCultivoId,
       JSON_QUERY((SELECT E.evento_id eventoId,E.tipo,E.estado_anterior estadoAnterior,E.estado_nuevo estadoNuevo,
        E.observacion,E.visita_tecnica_id visitaId,E.usuario_id usuarioId,U.nombre_usuario usuarioNombre,
        CONVERT(VARCHAR(19),E.fecha_hecho,126)+'Z' fechaHora
        FROM prod.PlantaEventoE3 E LEFT JOIN seg.Usuario U ON U.usuario_id=E.usuario_id WHERE E.planta_id=P.planta_id ORDER BY E.evento_id DESC FOR JSON PATH)) historial,
       JSON_QUERY((SELECT F.ficha_id fichaId,F.fecha_plantacion fechaPlantacion,
           F.edad_referencia_anios edadReferenciaAnios,F.fecha_referencia fechaReferencia,
           F.version,F.usuario_id usuarioId,U.nombre_usuario usuarioNombre,CONVERT(VARCHAR(19),F.fecha_registro,126)+'Z' fechaHora
           FROM prod.PlantaFichaHistorialE3 F LEFT JOIN seg.Usuario U ON U.usuario_id=F.usuario_id WHERE F.planta_id=P.planta_id
           ORDER BY F.ficha_id DESC FOR JSON PATH)) fichas,
       JSON_QUERY((SELECT S.episodio_id episodioId,COALESCE(GP.nombre,T.nombre) diagnostico,
             COALESCE(CONVERT(BIGINT,S.gp_problema_id),CONVERT(BIGINT,S.tipo_problema_fitosanitario_id)) diagnosticoId,
           CONVERT(VARCHAR(19),S.inicio,126)+'Z' inicio,
           CASE WHEN S.fin IS NULL THEN NULL ELSE CONVERT(VARCHAR(19),S.fin,126)+'Z' END fin,S.observacion,
           S.usuario_apertura_id usuarioAperturaId,UA.nombre_usuario usuarioApertura,
           S.usuario_cierre_id usuarioCierreId,UC.nombre_usuario usuarioCierre
           FROM sanidad.EpisodioPlantaE3 S
           LEFT JOIN sanidad.TipoProblemaFitosanitario T ON T.tipo_problema_fitosanitario_id=S.tipo_problema_fitosanitario_id
           LEFT JOIN prod.GPProblema GP ON GP.problema_id=S.gp_problema_id
           LEFT JOIN seg.Usuario UA ON UA.usuario_id=S.usuario_apertura_id
           LEFT JOIN seg.Usuario UC ON UC.usuario_id=S.usuario_cierre_id
           WHERE S.planta_id=P.planta_id ORDER BY S.episodio_id DESC FOR JSON PATH)) episodios,
       JSON_QUERY((SELECT SE.seguimiento_id seguimientoId,SE.episodio_id episodioId,
           SE.tipo,SE.observacion,SE.resultado,SE.evento_id eventoId,
           SE.visita_tecnica_id visitaId,SE.usuario_id usuarioId,U.nombre_usuario usuarioNombre,
           CONVERT(VARCHAR(19),SE.fecha_hecho,126)+'Z' fechaHora
           FROM sanidad.PlantaSeguimientoE3 SE LEFT JOIN seg.Usuario U ON U.usuario_id=SE.usuario_id
           WHERE SE.planta_id=P.planta_id
           ORDER BY SE.seguimiento_id DESC FOR JSON PATH)) seguimientos,
       JSON_QUERY((SELECT T.tratamiento_id tratamientoId,T.episodio_id episodioId,T.descripcion,T.resultado,
           T.gp_tratamiento_id catalogoTratamientoId,GP.nombre catalogoTratamiento,
           T.usuario_id usuarioId,U.nombre_usuario usuarioNombre,
           CONVERT(VARCHAR(19),T.fecha_aplicacion,126)+'Z' fechaHora,T.visita_tecnica_id visitaId
           FROM sanidad.TratamientoPlantaE3 T JOIN sanidad.EpisodioPlantaE3 S ON S.episodio_id=T.episodio_id
           LEFT JOIN prod.GPTratamiento GP ON GP.tratamiento_id=T.gp_tratamiento_id
           LEFT JOIN seg.Usuario U ON U.usuario_id=T.usuario_id
           WHERE S.planta_id=P.planta_id ORDER BY T.tratamiento_id DESC FOR JSON PATH)) tratamientos,
       JSON_QUERY((SELECT R.produccion_id produccionId,R.anio,R.tipo_registro tipo,
           R.estimado_kg estimadoKg,R.real_kg realKg,R.observacion,R.fecha_evento fechaEvento,
           R.visita_tecnica_id visitaId,CONVERT(VARCHAR(19),R.registrado_en,126)+'Z' fechaHora
           FROM prod.ProduccionPlantaE3 R WHERE R.planta_id=P.planta_id
           ORDER BY R.produccion_id DESC FOR JSON PATH)) producciones,
       JSON_QUERY((SELECT R.anio,R.estimado_kg estimadoKg,R.real_kg realKg,
           R.tiene_estimacion tieneEstimacion,R.tiene_real tieneReal
           FROM prod.VW_PlantaProduccionResumenE3 R WHERE R.planta_id=P.planta_id
           ORDER BY R.anio DESC FOR JSON PATH)) produccionResumen,
       JSON_QUERY((SELECT E.archivo_id archivoId,E.evento_id eventoId,A.nombre_original nombre,A.mime_type mimeType,
           A.secure_url url,E.tipo FROM prod.PlantaEvidenciaE3 E JOIN archivo.Archivo A ON A.archivo_id=E.archivo_id AND A.estado=1
           WHERE E.planta_id=P.planta_id FOR JSON PATH)) evidencias
    FROM prod.PlantaPaltaE3 P JOIN prod.VariedadPalta V ON V.variedad_palta_id=P.variedad_palta_id
    WHERE P.planta_id=@planta FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
   SET @bResultado=1;
  END
  ELSE
  BEGIN
   IF @clave IS NULL THROW 51104,N'Falta la clave de idempotencia.',1;
   SET @hash=HASHBYTES('SHA2_256',CONCAT(@cAccion,N'|',JSON_QUERY(@cJson,'$.filtros'),N'|',JSON_QUERY(@cJson,'$.datos')));
   BEGIN TRANSACTION;
   SET @lockResource=CONCAT(N'DESCO:E3:',CONVERT(NVARCHAR(20),@usuario),N':',CONVERT(NVARCHAR(36),@clave));
   EXEC @lock=sys.sp_getapplock
    @Resource=@lockResource,
    @LockMode='Exclusive',
    @LockOwner='Transaction',
    @LockTimeout=5000;
   IF @lock<0 THROW 51105,N'Operación en curso, reintente.',1;
   SELECT @hashViejo=hash_peticion,@replay=respuesta FROM prod.PlantaSolicitudE3 WITH(UPDLOCK,HOLDLOCK)
     WHERE usuario_id=@usuario AND accion=@cAccion AND clave=@clave;
   IF @hashViejo IS NOT NULL
   BEGIN
     IF @hash<>@hashViejo THROW 51106,N'La clave de idempotencia ya fue usada para otros datos.',1;
     SET @cDatos=@replay;SET @bResultado=1;
     SELECT @cCodigoRespuesta='E3_OK',@cMensaje=N'Operación ya registrada.',@nHttpRespuesta=200;
     COMMIT TRANSACTION;RETURN;
   END;
   IF @cAccion='MASIVO'
   BEGIN
     SET @observacion=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.observacion'))),N'');
     SET @visita=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.visitaId'));
     SELECT @nSeleccion=COUNT(*),@nDistintos=COUNT(DISTINCT TRY_CONVERT(BIGINT,[value]))
       FROM OPENJSON(@cJson,'$.datos.plantasIds');
     IF @nSeleccion NOT BETWEEN 1 AND 100 OR @nSeleccion<>@nDistintos OR @observacion IS NULL
        OR LEN(@observacion)>1000 OR @visita IS NULL
        THROW 51130,N'Seleccione hasta 100 plantas y una visita con observación.',1;
     IF NOT EXISTS(SELECT 1 FROM campo.VisitaTecnica V
       JOIN campo.SalidaParticipante SP ON SP.salida_participante_id=V.salida_participante_id
       JOIN campo.SalidaE2 E ON E.salida_campo_id=SP.salida_campo_id
       WHERE V.visita_tecnica_id=@visita AND V.predio_id=@predio AND SP.empleado_id=@emp
         AND E.uot_id=@uot AND E.convenio_id=@conv
         AND E.estado IN('EN_EJECUCION','EN_RETORNO','CERRADA'))
        THROW 51109,N'La visita no pertenece a una salida autorizada.',1;
     DECLARE @seleccion TABLE(planta_id BIGINT NOT NULL PRIMARY KEY);
     INSERT INTO @seleccion(planta_id)
       SELECT TRY_CONVERT(BIGINT,[value]) FROM OPENJSON(@cJson,'$.datos.plantasIds');
     IF (SELECT COUNT(*) FROM prod.PlantaPaltaE3 P WITH(UPDLOCK,HOLDLOCK)
         JOIN @seleccion X ON X.planta_id=P.planta_id
         WHERE P.predio_id=@predio AND P.uot_id=@uot AND P.convenio_id=@conv
           AND P.estado_actual NOT IN('MUERTA','ELIMINADA'))<>@nSeleccion
       THROW 51131,N'Seleccione sólo plantas del predio que no estén muertas.',1;
     SET @seguimientoTipo=COALESCE(JSON_VALUE(@cJson,'$.datos.tipo'),'OTRO');
     SET @resultado=JSON_VALUE(@cJson,'$.datos.resultado');
     IF @seguimientoTipo NOT IN('SANITARIO','PREVENTIVO','PODA','RIEGO','FERTILIZACION','OTRO')
       THROW 51130,N'La categoría de actuación no es válida.',1;
     DECLARE @eventosNuevos TABLE(evento_id BIGINT PRIMARY KEY,planta_id BIGINT NOT NULL);
     INSERT INTO prod.PlantaEventoE3(planta_id,tipo,estado_anterior,estado_nuevo,
       observacion,visita_tecnica_id,usuario_id,fecha_hecho,correlacion_id)
       OUTPUT inserted.evento_id,inserted.planta_id INTO @eventosNuevos(evento_id,planta_id)
       SELECT P.planta_id,'SEGUIMIENTO',P.estado_actual,P.estado_actual,
         @observacion,@visita,@usuario,@fecha,@corr
       FROM prod.PlantaPaltaE3 P JOIN @seleccion X ON X.planta_id=P.planta_id;
     INSERT INTO sanidad.PlantaSeguimientoE3(planta_id,episodio_id,evento_id,tipo,observacion,
          resultado,visita_tecnica_id,fecha_hecho,usuario_id)
       SELECT N.planta_id,EP.episodio_id,N.evento_id,@seguimientoTipo,@observacion,
          @resultado,@visita,@fecha,@usuario
       FROM @eventosNuevos N LEFT JOIN sanidad.EpisodioPlantaE3 EP ON EP.planta_id=N.planta_id AND EP.fin IS NULL;

     SET @cDatos=(SELECT @nSeleccion procesadas FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   END
   ELSE IF @cAccion='LOTE' 
   BEGIN
     -- La carga inicial se permite una sola vez por predio, incluso si después se eliminaron árboles.
     -- El bloqueo del predio serializa dos solicitudes iniciales con claves diferentes.
     IF NOT EXISTS(SELECT 1 FROM prod.Predio WITH(UPDLOCK,HOLDLOCK) WHERE predio_id=@predio)
       THROW 51135,N'El predio seleccionado no está disponible.',1;
     IF EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 WHERE predio_id=@predio)
       THROW 51135,N'La carga inicial de plantas ya fue realizada. Registre las siguientes individualmente.',1;
     DECLARE @filas TABLE (variedad SMALLINT PRIMARY KEY,cantidad INT NOT NULL,parcela BIGINT NULL);
     INSERT INTO @filas(variedad,cantidad,parcela)
       SELECT TRY_CONVERT(SMALLINT,variedadId),TRY_CONVERT(INT,cantidad),TRY_CONVERT(BIGINT,parcelaCultivoId)
       FROM OPENJSON(@cJson,'$.datos.filas') WITH(variedadId INT '$.variedadId',cantidad INT '$.cantidad',parcelaCultivoId BIGINT '$.parcelaCultivoId');
     IF NOT EXISTS(SELECT 1 FROM @filas) OR EXISTS(SELECT 1 FROM @filas WHERE cantidad NOT BETWEEN 1 AND 1000)
       OR (SELECT SUM(cantidad) FROM @filas)>2000 THROW 51107,N'Revise cantidades: máximo 2000 plantas por solicitud.',1;
     IF EXISTS(SELECT 1 FROM @filas F LEFT JOIN prod.VariedadPalta V ON V.variedad_palta_id=F.variedad AND V.estado=1
       WHERE V.variedad_palta_id IS NULL) THROW 51107,N'La variedad elegida no está vigente.',1;
     IF EXISTS(SELECT 1 FROM @filas F WHERE F.parcela IS NOT NULL AND NOT EXISTS(
       SELECT 1 FROM prod.ParcelaCultivo PC JOIN prod.Parcela PA ON PA.parcela_id=PC.parcela_id
       WHERE PC.parcela_cultivo_id=F.parcela AND PA.predio_id=@predio AND PC.estado=1 AND PC.fecha_fin IS NULL
         AND PC.variedad_palta_id=F.variedad)) THROW 51107,N'La parcela no corresponde a la variedad y predio.',1;
     SET @socioSolicitado=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.socioId'));
     SELECT @socioCantidad=COUNT(DISTINCT T.socio_id),@socio=MIN(T.socio_id)
     FROM prod.PredioTitularidad T
     JOIN org.SocioAsociacion SA ON SA.socio_id=T.socio_id AND SA.estado=1
     JOIN org.ConvenioUOTOrganizacion C ON C.convenio_uot_organizacion_id=@conv AND SA.asociacion_id=C.empresa_id
     WHERE T.predio_id=@predio AND T.estado=1 AND T.fecha_hasta IS NULL
       AND SA.fecha_desde<=CONVERT(DATE,@fecha) AND (SA.fecha_hasta IS NULL OR SA.fecha_hasta>=CONVERT(DATE,@fecha))
       AND (@socioSolicitado IS NULL OR T.socio_id=@socioSolicitado);
     IF ISNULL(@socioCantidad,0)<>1 THROW 51134,N'El fundo tiene varios socios o no tiene socio vigente: seleccione el socio titular.',1;
     DECLARE @insertados TABLE(planta_id BIGINT NOT NULL);
     DECLARE lote CURSOR LOCAL FAST_FORWARD FOR SELECT variedad,cantidad,parcela FROM @filas ORDER BY variedad;
     OPEN lote; FETCH NEXT FROM lote INTO @variedad,@cantidad,@parcela;
     WHILE @@FETCH_STATUS=0
     BEGIN
        SET @correlativo=NULL;
        SET @lockResource=CONCAT(N'DESCO:E3:CORR:',@predio,N':',@variedad);
        EXEC @lock=sys.sp_getapplock @Resource=@lockResource,
          @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=5000;
        IF @lock<0 THROW 51105,N'Otro registro está actualizando las plantas.',1;
        SELECT @correlativo=ultimo FROM prod.PlantaCorrelativoE3 WITH(UPDLOCK,HOLDLOCK)
         WHERE predio_id=@predio AND variedad_palta_id=@variedad;
        IF @correlativo IS NULL
        BEGIN
           SELECT @correlativo=ISNULL(MAX(secuencia),0) FROM prod.PlantaPaltaE3 WITH(UPDLOCK,HOLDLOCK)
            WHERE predio_id=@predio AND variedad_palta_id=@variedad;
           INSERT INTO prod.PlantaCorrelativoE3(predio_id,variedad_palta_id,ultimo) VALUES(@predio,@variedad,@correlativo+@cantidad);
        END
        ELSE UPDATE prod.PlantaCorrelativoE3 SET ultimo=@correlativo+@cantidad WHERE predio_id=@predio AND variedad_palta_id=@variedad;
        ;WITH N AS (SELECT TOP (@cantidad) ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) n
            FROM sys.all_objects A CROSS JOIN sys.all_objects B)
        INSERT INTO prod.PlantaPaltaE3(predio_id,uot_id,convenio_id,socio_id,variedad_palta_id,parcela_cultivo_id,secuencia,codigo,estado_actual,creado_por_usuario_id)
        OUTPUT inserted.planta_id INTO @insertados(planta_id)
        SELECT @predio,@uot,@conv,@socio,@variedad,@parcela,@correlativo+CONVERT(INT,N.n),
          CONCAT('PAL-',@predio,'-',@variedad,'-',RIGHT(CONCAT('000000000',@correlativo+N.n),9)),'SIN_EVALUAR',@usuario FROM N;
        SET @total=@total+@cantidad;
        FETCH NEXT FROM lote INTO @variedad,@cantidad,@parcela;
     END;
     CLOSE lote;DEALLOCATE lote;
     INSERT INTO prod.PlantaEventoE3(planta_id,tipo,estado_nuevo,usuario_id,fecha_hecho,correlacion_id)
        SELECT planta_id,'ALTA','SIN_EVALUAR',@usuario,@fecha,@corr FROM @insertados;
     SET @cDatos=(SELECT @total total,JSON_QUERY((SELECT V.variedad_palta_id variedadId,V.nombre variedad,COUNT(*) cantidad
       FROM prod.PlantaPaltaE3 P JOIN prod.VariedadPalta V ON V.variedad_palta_id=P.variedad_palta_id
       WHERE P.planta_id IN(SELECT planta_id FROM @insertados) GROUP BY V.variedad_palta_id,V.nombre FOR JSON PATH)) resumen
       FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   END
   ELSE
   BEGIN
     SELECT @estadoPrev=estado_actual,@versionActual=version,@variedadVieja=variedad_palta_id
       FROM prod.PlantaPaltaE3 WITH(UPDLOCK,HOLDLOCK)
       WHERE planta_id=@planta AND predio_id=@predio AND convenio_id=@conv AND uot_id=@uot;
     IF @estadoPrev IS NULL THROW 51103,N'La planta no pertenece a su predio y convenio.',1;
     SET @version=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.version'));
     IF @cAccion IN('FICHA','ESTADO') AND (@version IS NULL OR @version<>@versionActual)
       THROW 51117,N'La ficha fue modificada por otro usuario. Actualice antes de guardar.',1;
     SET @correccion=0;
     IF @estadoPrev IN('MUERTA','ELIMINADA')
       THROW 51108,N'La planta muerta conserva su historial y no admite modificaciones.',1;
     SET @visita=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.visitaId'));
     IF @visita IS NOT NULL AND NOT EXISTS(
       SELECT 1 FROM campo.VisitaTecnica V
       JOIN campo.SalidaParticipante SP ON SP.salida_participante_id=V.salida_participante_id
       JOIN campo.SalidaE2 E ON E.salida_campo_id=SP.salida_campo_id
       WHERE V.visita_tecnica_id=@visita AND V.predio_id=@predio AND SP.empleado_id=@emp
         AND E.uot_id=@uot AND E.convenio_id=@conv AND E.estado IN('EN_EJECUCION','EN_RETORNO','CERRADA'))
       THROW 51109,N'La visita no pertenece a una salida autorizada de este convenio.',1;
     SET @observacion=JSON_VALUE(@cJson,'$.datos.observacion');
     SET @hecho=CASE WHEN @cAccion IN('ESTADO','TRATAMIENTO') THEN @fecha
       ELSE COALESCE(TRY_CONVERT(DATETIME2(0),JSON_VALUE(@cJson,'$.datos.fechaHora')), @fecha) END;
     IF @hecho>DATEADD(MINUTE,5,@fecha) THROW 51110,N'La fecha no puede estar en el futuro.',1;
IF @cAccion='FICHA'
BEGIN
  SET @plantacion=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaPlantacion'));
  SET @edad=TRY_CONVERT(SMALLINT,JSON_VALUE(@cJson,'$.datos.edadReferenciaAnios'));
  SET @variedadNueva=TRY_CONVERT(SMALLINT,JSON_VALUE(@cJson,'$.datos.variedadId'));
  SET @parcelaNueva=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.parcelaCultivoId'));
  IF @parcelaNueva IS NOT NULL THROW 51111,N'La parcela se gestiona desde su propio detalle.',1;
  IF @plantacion IS NULL AND @edad IS NULL AND @variedadNueva IS NULL AND @parcelaNueva IS NULL
    THROW 51111,N'Ingrese al menos un dato para actualizar la planta.',1;
  IF @plantacion>CONVERT(DATE,@fecha) OR @edad NOT BETWEEN 0 AND 200
    THROW 51111,N'La edad o fecha de plantación no es válida.',1;
  IF @variedadNueva IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.VariedadPalta V
    WHERE V.variedad_palta_id=@variedadNueva AND V.estado=1)
    THROW 51111,N'La variedad no está disponible.',1;
  IF @parcelaNueva IS NOT NULL AND NOT EXISTS(
     SELECT 1 FROM prod.ParcelaCultivo PC JOIN prod.Parcela PA ON PA.parcela_id=PC.parcela_id
     WHERE PC.parcela_cultivo_id=@parcelaNueva AND PA.predio_id=@predio
     AND PC.variedad_palta_id=COALESCE(@variedadNueva,@variedadVieja)
     AND PC.estado=1 AND PC.fecha_fin IS NULL)
    THROW 51111,N'La parcela no corresponde al predio y variedad.',1;
  IF @variedadNueva IS NOT NULL AND @variedadNueva<>@variedadVieja
  BEGIN
    IF @parcelaNueva IS NULL AND EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 P
      WHERE P.planta_id=@planta AND P.parcela_cultivo_id IS NOT NULL)
      THROW 51111,N'Seleccione una parcela compatible con la nueva variedad.',1;
    SET @lockResource=CONCAT(N'DESCO:E3:CORR:',@predio,N':',@variedadNueva);
    EXEC @lock=sys.sp_getapplock @Resource=@lockResource,
      @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=5000;
    IF @lock<0 THROW 51105,N'Otro registro está actualizando las plantas.',1;
    SELECT @correlativo=ultimo FROM prod.PlantaCorrelativoE3 WITH(UPDLOCK,HOLDLOCK)
      WHERE predio_id=@predio AND variedad_palta_id=@variedadNueva;
    IF @correlativo IS NULL
    BEGIN
      SELECT @correlativo=ISNULL(MAX(secuencia),0) FROM prod.PlantaPaltaE3 WITH(UPDLOCK,HOLDLOCK)
        WHERE predio_id=@predio AND variedad_palta_id=@variedadNueva;
      INSERT prod.PlantaCorrelativoE3(predio_id,variedad_palta_id,ultimo)
       VALUES(@predio,@variedadNueva,@correlativo+1);
    END
    ELSE UPDATE prod.PlantaCorrelativoE3 SET ultimo=@correlativo+1
        WHERE predio_id=@predio AND variedad_palta_id=@variedadNueva;
    UPDATE prod.PlantaPaltaE3 SET variedad_palta_id=@variedadNueva,secuencia=@correlativo+1
      WHERE planta_id=@planta;
  END;
  UPDATE prod.PlantaPaltaE3
  SET fecha_plantacion=COALESCE(@plantacion,fecha_plantacion),
      edad_referencia_anios=CASE WHEN @plantacion IS NOT NULL THEN NULL ELSE COALESCE(@edad,edad_referencia_anios) END,
      fecha_referencia=CASE WHEN @plantacion IS NOT NULL THEN NULL WHEN @edad IS NOT NULL THEN CONVERT(DATE,@fecha) ELSE fecha_referencia END,
      parcela_cultivo_id=COALESCE(@parcelaNueva,parcela_cultivo_id),version=version+1
  WHERE planta_id=@planta;
  INSERT INTO prod.PlantaFichaHistorialE3(planta_id,fecha_plantacion,edad_referencia_anios,
      fecha_referencia,version,usuario_id)
    SELECT planta_id,fecha_plantacion,edad_referencia_anios,fecha_referencia,version,@usuario
    FROM prod.PlantaPaltaE3 WHERE planta_id=@planta;
  SET @observacion=CONCAT(N'Ficha actualizada.',
     CASE WHEN @variedadNueva IS NOT NULL THEN CONCAT(N' Variedad: ',@variedadNueva,N'.') ELSE N'' END,
     CASE WHEN @parcelaNueva IS NOT NULL THEN CONCAT(N' Parcela: ',@parcelaNueva,N'.') ELSE N'' END,
     CASE WHEN @plantacion IS NOT NULL THEN CONCAT(N' Plantación: ',CONVERT(VARCHAR(10),@plantacion,23),N'.')
          WHEN @edad IS NOT NULL THEN CONCAT(N' Edad: ',@edad,N' años.') ELSE N'' END);
  SET @accionLog='FICHA';
END
     ELSE IF @cAccion='ESTADO'
     BEGIN
       SET @estado=JSON_VALUE(@cJson,'$.datos.estado');
       SET @diagnostico=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.diagnosticoId'));
IF @estado NOT IN('SANA','ENFERMA','MUERTA') OR @correccion<>0
  THROW 51112,N'El estado no está permitido.',1;
IF @estado='ENFERMA' AND (@diagnostico IS NULL OR NOT EXISTS(
   SELECT 1 FROM prod.GPProblema GP JOIN prod.Cultivo C ON C.cultivo_id=GP.cultivo_id
   WHERE GP.problema_id=@diagnostico AND GP.estado=1 AND C.estado=1
     AND (UPPER(C.codigo)='PALTA' OR UPPER(C.nombre)=N'PALTA')))
  THROW 51112,N'Seleccione una enfermedad del catálogo de palta.',1;
IF @estado='MUERTA' AND NULLIF(LTRIM(RTRIM(@observacion)),N'') IS NULL
  THROW 51112,N'Describa el motivo de la baja.',1;
       IF @estadoPrev='ENFERMA' AND @estado='ENFERMA' THROW 51112,N'El episodio ya está abierto; registre un tratamiento o seguimiento.',1;
       IF @estadoPrev=@estado THROW 51112,N'La planta ya tiene el estado seleccionado.',1;
       IF @estadoPrev='ENFERMA'
       BEGIN
         IF EXISTS(SELECT 1 FROM sanidad.EpisodioPlantaE3 WHERE planta_id=@planta AND fin IS NULL AND activo=1 AND inicio>@hecho)
          THROW 51112,N'El cierre no puede anteceder al inicio del diagnóstico.',1;
         UPDATE sanidad.EpisodioPlantaE3 SET fin=@hecho,usuario_cierre_id=@usuario
          WHERE planta_id=@planta AND fin IS NULL AND activo=1;
       END;
       IF @estado='ENFERMA'
         INSERT INTO sanidad.EpisodioPlantaE3(planta_id,gp_problema_id,inicio,observacion,usuario_apertura_id,visita_tecnica_id)
          VALUES(@planta,@diagnostico,@hecho,@observacion,@usuario,@visita);
       UPDATE prod.PlantaPaltaE3 SET estado_actual=@estado,
           activo=CASE WHEN @estado='MUERTA' THEN 0 ELSE 1 END,version=version+1
       WHERE planta_id=@planta;
       SET @accionLog='EVALUACION';
     END
     ELSE IF @cAccion='TRATAMIENTO'
     BEGIN
       IF (SELECT COUNT_BIG(*) FROM sanidad.EpisodioPlantaE3 WHERE planta_id=@planta AND fin IS NULL AND activo=1)>1
        THROW 51113,N'Hay varias enfermedades vigentes. Registre el tratamiento desde el detalle de la enfermedad.',1;
       SELECT @episodio=episodio_id FROM sanidad.EpisodioPlantaE3 WITH(UPDLOCK,HOLDLOCK) WHERE planta_id=@planta AND fin IS NULL AND activo=1;
       IF @estadoPrev<>'ENFERMA' OR @episodio IS NULL THROW 51113,N'Solo una planta enferma con episodio abierto admite tratamientos.',1;
       IF @hecho<(SELECT inicio FROM sanidad.EpisodioPlantaE3 WHERE episodio_id=@episodio)
        THROW 51113,N'El tratamiento no puede anteceder al diagnóstico.',1;
       SET @tratamientoCatalogo=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.catalogoTratamientoId'));
       IF @tratamientoCatalogo IS NULL OR NOT EXISTS(
         SELECT 1 FROM sanidad.EpisodioPlantaE3 E
         JOIN prod.GPProblemaTratamiento R ON R.problema_id=E.gp_problema_id
           AND R.tratamiento_id=@tratamientoCatalogo
         JOIN prod.GPTratamiento T ON T.tratamiento_id=R.tratamiento_id AND T.estado=1
         WHERE E.episodio_id=@episodio)
          THROW 51113,N'Seleccione un tratamiento correspondiente a la enfermedad.',1;
       INSERT sanidad.TratamientoPlantaE3(episodio_id,gp_tratamiento_id,descripcion,resultado,
          fecha_aplicacion,visita_tecnica_id,usuario_id)
       SELECT @episodio,T.tratamiento_id,T.nombre,JSON_VALUE(@cJson,'$.datos.resultado'),@hecho,@visita,@usuario
       FROM prod.GPTratamiento T WHERE T.tratamiento_id=@tratamientoCatalogo;
       SET @accionLog='TRATAMIENTO';
     END
     ELSE IF @cAccion='SEGUIMIENTO'
     BEGIN
       IF @estadoPrev IN('MUERTA','ELIMINADA') THROW 51114,N'La planta muerta no admite seguimientos.',1;
       SET @seguimientoTipo=COALESCE(JSON_VALUE(@cJson,'$.datos.tipo'),'OTRO');
       SET @resultado=JSON_VALUE(@cJson,'$.datos.resultado');
       IF @seguimientoTipo NOT IN('SANITARIO','PREVENTIVO','PODA','RIEGO','FERTILIZACION','OTRO')
          THROW 51114,N'El tipo de actuación no está permitido.',1;
       IF NULLIF(LTRIM(RTRIM(@observacion)),N'') IS NULL THROW 51114,N'Describa el seguimiento realizado.',1;
       SET @accionLog='SEGUIMIENTO';
     END
     ELSE IF @cAccion='PRODUCCION'
     BEGIN
       SET @anio=TRY_CONVERT(SMALLINT,JSON_VALUE(@cJson,'$.datos.anio'));
       SET @estimado=TRY_CONVERT(DECIMAL(14,3),JSON_VALUE(@cJson,'$.datos.estimadoKg'));
       SET @real=TRY_CONVERT(DECIMAL(14,3),JSON_VALUE(@cJson,'$.datos.realKg'));
       SET @tipoProduccion=JSON_VALUE(@cJson,'$.datos.tipo');
       SET @fechaEvento=COALESCE(TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaEvento')),CONVERT(DATE,@fecha));
       IF @anio NOT BETWEEN 2000 AND 2200 OR @fechaEvento>CONVERT(DATE,@fecha)
         OR YEAR(@fechaEvento)<>@anio OR @tipoProduccion NOT IN('ESTIMACION','COSECHA')
         OR (@tipoProduccion='ESTIMACION' AND (@estimado IS NULL OR @real IS NOT NULL))
         OR (@tipoProduccion='COSECHA' AND (@real IS NULL OR @estimado IS NOT NULL))
         OR @estimado<0 OR @real<0
           THROW 51115,N'Indique una estimación o cosecha real con fecha y kilos válidos.',1;
       INSERT prod.ProduccionPlantaE3(planta_id,anio,estimado_kg,real_kg,observacion,usuario_id,tipo_registro,fecha_evento,visita_tecnica_id)
        VALUES(@planta,@anio,@estimado,@real,@observacion,@usuario,@tipoProduccion,@fechaEvento,@visita);
       SET @observacion=CONCAT(CASE WHEN @tipoProduccion='COSECHA' THEN N'Cosecha: ' ELSE N'Estimación: ' END,
             CONVERT(VARCHAR(40),COALESCE(@real,@estimado)),N' kg, ',CONVERT(VARCHAR(10),@fechaEvento,23),
             CASE WHEN NULLIF(@observacion,N'') IS NULL THEN N'' ELSE CONCAT(N'. ',@observacion) END);
       SET @accionLog='PRODUCCION';
     END
     ELSE IF @cAccion='MEDIR'
     BEGIN
       SET @porcentaje=TRY_CONVERT(DECIMAL(6,3),JSON_VALUE(@cJson,'$.datos.porcentaje'));
       IF @estadoPrev IN('MUERTA','ELIMINADA') OR @porcentaje IS NULL OR @porcentaje NOT BETWEEN 0 AND 100
           OR @visita IS NULL
         THROW 51132,N'La medición requiere una planta viva, un porcentaje válido y una visita.',1;
       INSERT INTO prod.PlantaMedicionE3(planta_id,visita_tecnica_id,porcentaje,
           observacion,usuario_id,fecha_hecho)
         VALUES(@planta,@visita,@porcentaje,@observacion,@usuario,@hecho);
       SET @observacion=CONCAT(N'Materia seca ',CONVERT(VARCHAR(30),@porcentaje),N'%. ',ISNULL(@observacion,N''));
       SET @accionLog='SEGUIMIENTO';
     END
     ELSE IF @cAccion='EVIDENCIA' 
     BEGIN
       SET @archivo=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.archivoId'));
       SET @eventoObjetivo=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.eventoId'));
       IF @eventoObjetivo IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.PlantaEventoE3
          WHERE evento_id=@eventoObjetivo AND planta_id=@planta)
          THROW 51116,N'El evento seleccionado no pertenece a esta planta.',1;
       IF NOT EXISTS(SELECT 1 FROM archivo.Archivo A JOIN archivo.ArchivoVinculo V ON V.archivo_id=A.archivo_id AND V.predio_id=@predio AND V.estado=1
          WHERE A.archivo_id=@archivo AND A.estado=1 AND A.uot_id=@uot
            AND (A.usuario_id=@usuario OR EXISTS(SELECT 1 FROM campo.VisitaTecnica VV
              JOIN campo.SalidaParticipante SP ON SP.salida_participante_id=VV.salida_participante_id
              JOIN campo.SalidaE2 EE ON EE.salida_campo_id=SP.salida_campo_id
              WHERE VV.visita_tecnica_id=V.visita_tecnica_id AND VV.predio_id=@predio
                AND EE.uot_id=@uot AND EE.convenio_id=@conv)))
         THROW 51116,N'El archivo debe estar registrado y vinculado al predio en su UOT.',1;
       IF EXISTS(SELECT 1 FROM prod.PlantaEvidenciaE3 WHERE planta_id=@planta AND archivo_id=@archivo)
         THROW 51116,N'El archivo ya está asociado a esta planta.',1;
       INSERT prod.PlantaEvidenciaE3(planta_id,archivo_id,tipo,usuario_id)
        VALUES(@planta,@archivo,'PLANTA',@usuario);
       SET @accionLog='EVIDENCIA';
     END;
     INSERT prod.PlantaEventoE3(planta_id,tipo,estado_anterior,estado_nuevo,observacion,visita_tecnica_id,usuario_id,fecha_hecho,correlacion_id)
       VALUES(@planta,@accionLog,@estadoPrev,CASE WHEN @cAccion='ESTADO' THEN @estado ELSE @estadoPrev END,
         @observacion,@visita,@usuario,@hecho,@corr);
     SET @evento=CONVERT(BIGINT,SCOPE_IDENTITY());
     IF @cAccion='SEGUIMIENTO'
     BEGIN
       SELECT @episodio=episodio_id FROM sanidad.EpisodioPlantaE3
         WHERE planta_id=@planta AND fin IS NULL;
       INSERT INTO sanidad.PlantaSeguimientoE3(planta_id,episodio_id,evento_id,tipo,observacion,
               resultado,visita_tecnica_id,fecha_hecho,usuario_id)
       VALUES(@planta,@episodio,@evento,@seguimientoTipo,@observacion,@resultado,@visita,@hecho,@usuario);
     END;
     IF @cAccion='EVIDENCIA' UPDATE prod.PlantaEvidenciaE3 SET evento_id=COALESCE(@eventoObjetivo,@evento) WHERE planta_id=@planta AND archivo_id=@archivo;
     SET @cDatos=(SELECT @planta plantaId,@evento eventoId,CASE WHEN @cAccion='ESTADO' THEN @estado ELSE @estadoPrev END estado
        FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   END;
   INSERT INTO prod.PlantaSolicitudE3(usuario_id,accion,clave,hash_peticion,respuesta)
      VALUES(@usuario,@cAccion,@clave,@hash,@cDatos);
   COMMIT TRANSACTION;
   SET @bResultado=1;
  END;
  SELECT @cMensaje=N'Operación realizada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 END TRY
 BEGIN CATCH
   IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
   SET @bResultado=0;SET @cDatos=NULL;
   SET @cCodigoRespuesta='E3_ERROR';
   SET @nHttpRespuesta=CASE WHEN ERROR_NUMBER() IN(51100,51101,51109) THEN 403 WHEN ERROR_NUMBER() IN(51103) THEN 404
     WHEN ERROR_NUMBER() IN(51105,51106,51108,51112,51117,51131) THEN 409 ELSE 400 END;
   SET @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51100 AND 51199 THEN ERROR_MESSAGE()
      ELSE N'No fue posible procesar la solicitud. Verifique los datos o contacte al administrador.' END;
 END CATCH;
END;
GO

-- Validación compartida de ámbito, sin asociar otra planta ni otro predio.
CREATE OR ALTER PROCEDURE prod.PA_E3_Sel_ValidarPredio
 @cJson NVARCHAR(MAX),@cPermiso VARCHAR(60),@nUsuario BIGINT OUTPUT,
 @nUot BIGINT OUTPUT,@nConvenio BIGINT OUTPUT,@nPredio BIGINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @nUot=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
  @nConvenio=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.convenioId')),
  @nPredio=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.predioId'));
 IF ISJSON(@cJson)<>1 OR @nUot IS NULL OR @nConvenio IS NULL OR @nPredio IS NULL
  THROW 51310,N'Indique un predio, convenio y UOT válidos.',1;
 DECLARE @sesion BIGINT,@disp BIGINT,@emp BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
  @auth BIT,@msg NVARCHAR(300),@fecha DATE=CONVERT(DATE,SYSUTCDATETIME());
 EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,@cPermiso,
  @nUsuario OUTPUT,@sesion OUTPUT,@disp OUTPUT,@emp OUTPUT,@modulo OUTPUT,
  @corr OUTPUT,@sol OUTPUT,@ip OUTPUT,@endpoint OUTPUT,@auth OUTPUT,@msg OUTPUT;
 IF ISNULL(@auth,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@nUsuario,@nUot,@cPermiso)<>1
  THROW 51311,N'No tiene autorización para registrar plantas.',1;
 IF NOT EXISTS (SELECT 1 FROM prod.PredioAmbito A
   JOIN org.ConvenioUOTOrganizacion C ON C.convenio_uot_organizacion_id=A.convenio_uot_organizacion_id
   JOIN org.ConvenioModuloEspecial M ON M.convenio_uot_organizacion_id=C.convenio_uot_organizacion_id AND M.estado=1
   JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=M.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
   JOIN prod.Predio P ON P.predio_id=A.predio_id AND P.estado=1
   WHERE A.predio_id=@nPredio AND A.uot_id=@nUot AND A.convenio_uot_organizacion_id=@nConvenio AND A.estado=1
    AND C.uot_id=@nUot AND C.estado=1 AND (C.fecha_inicio IS NULL OR C.fecha_inicio<=@fecha)
    AND (C.fecha_fin IS NULL OR C.fecha_fin>=@fecha)
    AND EXISTS(SELECT 1 FROM prod.PredioTitularidad T
     JOIN org.Socio S ON S.socio_id=T.socio_id AND S.estado=1
     JOIN org.SocioAsociacion SA ON SA.socio_id=T.socio_id AND SA.asociacion_id=C.empresa_id
      AND SA.estado=1 AND SA.fecha_desde<=@fecha AND (SA.fecha_hasta IS NULL OR SA.fecha_hasta>=@fecha)
     WHERE T.predio_id=@nPredio AND T.estado=1 AND T.fecha_hasta IS NULL))
  THROW 51312,N'El predio no pertenece al convenio autorizado.',1;
END;
GO
-- Solo lectura: el frontend muestra alta inicial únicamente si no existe ningún árbol histórico.
CREATE OR ALTER PROCEDURE prod.PA_E3_Planta_Sel_AltaInicial
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @bResultado=0,@cDatos=NULL,@cCodigoRespuesta='E3_ERROR',@cMensaje=N'No se pudo consultar el registro.',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@uot BIGINT,@conv BIGINT,@predio BIGINT;
 BEGIN TRY
  EXEC prod.PA_E3_Sel_ValidarPredio @cJson,'APAPPSS_PREDIOS_VER',@usuario OUTPUT,@uot OUTPUT,@conv OUTPUT,@predio OUTPUT;
  DECLARE @total BIGINT=(SELECT COUNT_BIG(*) FROM prod.PlantaPaltaE3 WHERE predio_id=@predio);
  SET @cDatos=(SELECT @total totalHistorico,CONVERT(BIT,CASE WHEN @total=0 THEN 1 ELSE 0 END) puedeCargaInicial FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Consulta realizada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  SELECT @bResultado=0,@cDatos=NULL,@cCodigoRespuesta='E3_ERROR',
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51300 AND 51399 THEN ERROR_MESSAGE() ELSE N'No se pudo consultar el registro.' END,
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51300 AND 51399 THEN 400 ELSE 503 END;
 END CATCH;
END;
GO
-- Responsabilidad única: insertar exactamente una planta después de la carga inicial.
CREATE OR ALTER PROCEDURE prod.PA_E3_Planta_Ins_Individual
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @bResultado=0,@cDatos=NULL,@cCodigoRespuesta='E3_ERROR',@cMensaje=N'No se pudo registrar la planta.',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@uot BIGINT,@conv BIGINT,@predio BIGINT,
  @variedad SMALLINT=TRY_CONVERT(SMALLINT,JSON_VALUE(@cJson,'$.datos.variedadId')),
  @socioSolicitado BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.socioId')),
  @socio BIGINT,@socios INT,
  @observacion NVARCHAR(1000)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.observacion')),N''),
  @plantacion DATE=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaPlantacion')),
  @edad SMALLINT=TRY_CONVERT(SMALLINT,JSON_VALUE(@cJson,'$.datos.edadReferenciaAnios')),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @hash VARBINARY(32),@hashAnterior VARBINARY(32),@replay NVARCHAR(MAX),
  @correlativo INT,@planta BIGINT,@codigo VARCHAR(80),@bloqueo INT,
  @fecha DATETIME2(0)=SYSUTCDATETIME();
 BEGIN TRY
  EXEC prod.PA_E3_Sel_ValidarPredio @cJson,'APAPPSS_PREDIOS_CREAR',@usuario OUTPUT,@uot OUTPUT,@conv OUTPUT,@predio OUTPUT;
  IF @variedad IS NULL OR NOT EXISTS(SELECT 1 FROM prod.VariedadPalta WHERE variedad_palta_id=@variedad AND estado=1)
   THROW 51320,N'Seleccione una variedad vigente.',1;
  IF @edad IS NOT NULL AND @edad NOT BETWEEN 0 AND 200 THROW 51320,N'La edad debe estar entre 0 y 200 años.',1;
  IF @plantacion IS NOT NULL AND (@plantacion>CONVERT(DATE,@fecha) OR @edad IS NOT NULL)
   THROW 51320,N'Indique una fecha de plantación válida o una edad, no ambas.',1;
  IF LEN(@observacion)>1000 THROW 51320,N'La observación excede el límite permitido.',1;
  IF @clave IS NULL THROW 51320,N'La solicitud no tiene identificador para evitar duplicaciones.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT('E3_INDIVIDUAL|',JSON_QUERY(@cJson,'$.filtros'),N'|',JSON_QUERY(@cJson,'$.datos')));
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM prod.Predio WITH(UPDLOCK,HOLDLOCK) WHERE predio_id=@predio)
   THROW 51312,N'El predio no está disponible.',1;
  SELECT @hashAnterior=hash_peticion,@replay=respuesta FROM prod.PlantaSolicitudE3 WITH(UPDLOCK,HOLDLOCK)
   WHERE usuario_id=@usuario AND accion='ALTA_INDIVIDUAL' AND clave=@clave;
  IF @hashAnterior IS NOT NULL BEGIN
   IF @hashAnterior<>@hash THROW 51321,N'La solicitud ya fue utilizada con otros datos.',1;
   SELECT @cDatos=@replay,@bResultado=1,@cCodigoRespuesta='E3_OK',@cMensaje=N'Planta previamente registrada.',@nHttpRespuesta=200;
   COMMIT TRANSACTION;RETURN;
  END;
  IF NOT EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 WHERE predio_id=@predio)
   THROW 51322,N'Primero debe registrar la cantidad inicial de plantas del predio.',1;
  SELECT @socios=COUNT(DISTINCT T.socio_id),@socio=MIN(T.socio_id)
   FROM prod.PredioTitularidad T
   JOIN org.SocioAsociacion SA ON SA.socio_id=T.socio_id AND SA.estado=1
   JOIN org.ConvenioUOTOrganizacion C ON C.convenio_uot_organizacion_id=@conv AND SA.asociacion_id=C.empresa_id
   WHERE T.predio_id=@predio AND T.estado=1 AND T.fecha_hasta IS NULL
    AND SA.fecha_desde<=CONVERT(DATE,@fecha) AND (SA.fecha_hasta IS NULL OR SA.fecha_hasta>=CONVERT(DATE,@fecha))
    AND (@socioSolicitado IS NULL OR T.socio_id=@socioSolicitado);
  IF ISNULL(@socios,0)<>1 THROW 51323,N'Seleccione el socio titular del predio.',1;
  DECLARE @recurso NVARCHAR(255)=CONCAT(N'DESCO:E3:CORR:',@predio,N':',@variedad);
  EXEC @bloqueo=sys.sp_getapplock @Resource=@recurso,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=5000;
  IF @bloqueo<0 THROW 51324,N'Hay un registro de plantas en curso. Vuelva a intentarlo.',1;
  SELECT @correlativo=ultimo FROM prod.PlantaCorrelativoE3 WITH(UPDLOCK,HOLDLOCK)
    WHERE predio_id=@predio AND variedad_palta_id=@variedad;
  IF @correlativo IS NULL BEGIN
   SELECT @correlativo=ISNULL(MAX(secuencia),0) FROM prod.PlantaPaltaE3 WITH(UPDLOCK,HOLDLOCK)
    WHERE predio_id=@predio AND variedad_palta_id=@variedad;
   INSERT INTO prod.PlantaCorrelativoE3(predio_id,variedad_palta_id,ultimo) VALUES(@predio,@variedad,@correlativo+1);
  END ELSE UPDATE prod.PlantaCorrelativoE3 SET ultimo=@correlativo+1 WHERE predio_id=@predio AND variedad_palta_id=@variedad;
  SET @codigo=CONCAT('PAL-',@predio,'-',@variedad,'-',RIGHT(CONCAT('000000000',@correlativo+1),9));
  INSERT INTO prod.PlantaPaltaE3(predio_id,uot_id,convenio_id,socio_id,variedad_palta_id,secuencia,codigo,estado_actual,
    fecha_plantacion,edad_referencia_anios,fecha_referencia,creado_por_usuario_id)
  VALUES(@predio,@uot,@conv,@socio,@variedad,@correlativo+1,@codigo,'SIN_EVALUAR',@plantacion,@edad,
    CASE WHEN @edad IS NOT NULL THEN CONVERT(DATE,@fecha) ELSE NULL END,@usuario);
  SET @planta=CONVERT(BIGINT,SCOPE_IDENTITY());
  INSERT INTO prod.PlantaEventoE3(planta_id,tipo,estado_nuevo,observacion,usuario_id,fecha_hecho)
   VALUES(@planta,'ALTA','SIN_EVALUAR',@observacion,@usuario,@fecha);
  SET @cDatos=(SELECT @planta plantaId,@codigo codigo,'SIN_EVALUAR' estado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT INTO prod.PlantaSolicitudE3(usuario_id,accion,clave,hash_peticion,respuesta)
   VALUES(@usuario,'ALTA_INDIVIDUAL',@clave,@hash,@cDatos);
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cCodigoRespuesta='E3_OK',@cMensaje=N'Planta registrada.',@nHttpRespuesta=201;
 END TRY BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
  SELECT @bResultado=0,@cDatos=NULL,@cCodigoRespuesta='E3_ERROR',
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51300 AND 51399 THEN ERROR_MESSAGE() ELSE N'No se pudo registrar la planta.' END,
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51300 AND 51399 THEN 400 ELSE 503 END;
 END CATCH;
END;
GO
