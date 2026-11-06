-- E3. Procedimiento único para lecturas, alta masiva, actuaciones y evidencia privada.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'prod.PA_PlantaPaltaE3_Ejecutar', N'P') IS NOT NULL DROP PROCEDURE prod.PA_PlantaPaltaE3_Ejecutar;
GO
CREATE PROCEDURE prod.PA_PlantaPaltaE3_Ejecutar
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
 @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
 @usuario BIGINT,@sesion BIGINT,@disp BIGINT,@emp BIGINT,@modulo INT,
 @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
 @auth BIT,@authMensaje NVARCHAR(300),@perm VARCHAR(60),@fecha DATETIME2(0)=SYSUTCDATETIME(),
 @hash VARBINARY(32),@hashViejo VARBINARY(32),@replay NVARCHAR(MAX),@lock INT,
 @lockResource NVARCHAR(255),
 @estadoPrev VARCHAR(16),@estado VARCHAR(16),@visita BIGINT,@episodio BIGINT,@diagnostico SMALLINT,
 @observacion NVARCHAR(1000),@id BIGINT,@cantidad INT,@variedad SMALLINT,@parcela BIGINT,
 @correlativo INT,@total INT=0,@archivo BIGINT,@evento BIGINT,
 @hecho DATETIME2(0),@plantacion DATE,@edad SMALLINT,@anio SMALLINT,
 @estimado DECIMAL(14,3),@real DECIMAL(14,3),@accionLog VARCHAR(30),@eventoObjetivo BIGINT,@version BIGINT,@versionActual BIGINT;
 IF ISJSON(@cJson)<>1 OR @uot IS NULL OR @conv IS NULL OR @predio IS NULL
 BEGIN SELECT @cMensaje=N'Indique UOT, convenio y predio válidos.',@nHttpRespuesta=400; RETURN; END;
 IF @cAccion NOT IN('CATALOGOS','LISTAR','VER','LOTE','FICHA','ESTADO','TRATAMIENTO','SEGUIMIENTO','PRODUCCION','EVIDENCIA')
 BEGIN SELECT @cMensaje=N'Operación de planta no admitida.',@nHttpRespuesta=400; RETURN; END;
 SET @perm=CASE WHEN @cAccion IN('CATALOGOS','LISTAR','VER') THEN 'APAPPSS_PREDIOS_VER'
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
  IF @cAccion='CATALOGOS'
  BEGIN
   SET @cDatos=(SELECT JSON_QUERY((SELECT V.variedad_palta_id id,V.nombre FROM prod.VariedadPalta V WHERE V.estado=1 ORDER BY V.nombre FOR JSON PATH)) variedades,
      JSON_QUERY((SELECT T.tipo_problema_fitosanitario_id id,T.nombre FROM sanidad.TipoProblemaFitosanitario T WHERE T.estado=1 ORDER BY T.nombre FOR JSON PATH)) diagnosticos,
      JSON_QUERY((SELECT PC.parcela_cultivo_id id,P.nombre nombre FROM prod.ParcelaCultivo PC
          JOIN prod.Parcela P ON P.parcela_id=PC.parcela_id AND P.predio_id=@predio
          WHERE PC.estado=1 AND PC.fecha_fin IS NULL ORDER BY P.nombre FOR JSON PATH)) parcelas
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   SET @bResultado=1;
  END
  ELSE IF @cAccion='LISTAR'
  BEGIN
   IF @pagina<1 OR @tamano NOT BETWEEN 1 AND 100 THROW 51102,N'Paginación inválida.',1;
   SET @cDatos=(SELECT (SELECT COUNT_BIG(*) FROM prod.PlantaPaltaE3 P WHERE P.predio_id=@predio AND P.convenio_id=@conv
        AND (@fEstado IS NULL OR P.estado_actual=@fEstado) AND (@fVar IS NULL OR P.variedad_palta_id=@fVar)
        AND (@buscar IS NULL OR P.codigo LIKE '%'+@buscar+'%')) total,
     JSON_QUERY((SELECT P.planta_id plantaId,P.codigo,V.nombre variedad,P.variedad_palta_id variedadId,P.estado_actual estado,
        P.parcela_cultivo_id parcelaCultivoId, P.version
       FROM prod.PlantaPaltaE3 P JOIN prod.VariedadPalta V ON V.variedad_palta_id=P.variedad_palta_id
       WHERE P.predio_id=@predio AND P.convenio_id=@conv
        AND (@fEstado IS NULL OR P.estado_actual=@fEstado) AND (@fVar IS NULL OR P.variedad_palta_id=@fVar)
        AND (@buscar IS NULL OR P.codigo LIKE '%'+@buscar+'%')
       ORDER BY P.planta_id OFFSET (@pagina-1)*@tamano ROWS FETCH NEXT @tamano ROWS ONLY FOR JSON PATH)) items,
     JSON_QUERY((SELECT V.variedad_palta_id variedadId,V.nombre variedad,COUNT_BIG(*) cantidad,
         SUM(CASE WHEN P.estado_actual='SIN_EVALUAR' THEN 1 ELSE 0 END) sinEvaluar
       FROM prod.PlantaPaltaE3 P JOIN prod.VariedadPalta V ON V.variedad_palta_id=P.variedad_palta_id
       WHERE P.predio_id=@predio AND P.convenio_id=@conv GROUP BY V.variedad_palta_id,V.nombre FOR JSON PATH)) resumen
     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   SET @bResultado=1;
  END
  ELSE IF @cAccion='VER'
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 WHERE planta_id=@planta AND predio_id=@predio AND convenio_id=@conv)
      THROW 51103,N'La planta no se encuentra en el predio.',1;
   SET @cDatos=(SELECT P.planta_id plantaId,P.predio_id predioId,P.codigo,V.nombre variedad,P.variedad_palta_id variedadId,
       P.estado_actual estado,P.fecha_plantacion fechaPlantacion,P.edad_referencia_anios edadReferenciaAnios,
       CASE WHEN P.fecha_plantacion IS NOT NULL THEN DATEDIFF(YEAR,P.fecha_plantacion,CONVERT(DATE,@fecha))
           - CASE WHEN DATEADD(YEAR,DATEDIFF(YEAR,P.fecha_plantacion,CONVERT(DATE,@fecha)),P.fecha_plantacion)>CONVERT(DATE,@fecha) THEN 1 ELSE 0 END
        WHEN P.edad_referencia_anios IS NOT NULL AND P.fecha_referencia IS NOT NULL
           THEN P.edad_referencia_anios+DATEDIFF(YEAR,P.fecha_referencia,CONVERT(DATE,@fecha))
           - CASE WHEN DATEADD(YEAR,DATEDIFF(YEAR,P.fecha_referencia,CONVERT(DATE,@fecha)),P.fecha_referencia)>CONVERT(DATE,@fecha) THEN 1 ELSE 0 END
        ELSE NULL END edadActual,
       P.version, P.parcela_cultivo_id parcelaCultivoId,
       JSON_QUERY((SELECT E.evento_id eventoId,E.tipo,E.estado_anterior estadoAnterior,E.estado_nuevo estadoNuevo,
        E.observacion,E.visita_tecnica_id visitaId,E.usuario_id usuarioId,
        CONVERT(VARCHAR(19),E.fecha_hecho,126)+'Z' fechaHora
        FROM prod.PlantaEventoE3 E WHERE E.planta_id=P.planta_id ORDER BY E.evento_id DESC FOR JSON PATH)) historial,
       JSON_QUERY((SELECT S.episodio_id episodioId,T.nombre diagnostico,S.tipo_problema_fitosanitario_id diagnosticoId,
           CONVERT(VARCHAR(19),S.inicio,126)+'Z' inicio,
           CASE WHEN S.fin IS NULL THEN NULL ELSE CONVERT(VARCHAR(19),S.fin,126)+'Z' END fin,S.observacion
           FROM sanidad.EpisodioPlantaE3 S JOIN sanidad.TipoProblemaFitosanitario T ON T.tipo_problema_fitosanitario_id=S.tipo_problema_fitosanitario_id
           WHERE S.planta_id=P.planta_id ORDER BY S.episodio_id DESC FOR JSON PATH)) episodios,
       JSON_QUERY((SELECT T.tratamiento_id tratamientoId,T.episodio_id episodioId,T.descripcion,T.resultado,
           CONVERT(VARCHAR(19),T.fecha_aplicacion,126)+'Z' fechaHora,T.visita_tecnica_id visitaId
           FROM sanidad.TratamientoPlantaE3 T JOIN sanidad.EpisodioPlantaE3 S ON S.episodio_id=T.episodio_id
           WHERE S.planta_id=P.planta_id ORDER BY T.tratamiento_id DESC FOR JSON PATH)) tratamientos,
       JSON_QUERY((SELECT R.produccion_id produccionId,R.anio,R.estimado_kg estimadoKg,R.real_kg realKg,R.observacion,
           CONVERT(VARCHAR(19),R.registrado_en,126)+'Z' fechaHora
           FROM prod.ProduccionPlantaE3 R WHERE R.planta_id=P.planta_id ORDER BY R.produccion_id DESC FOR JSON PATH)) producciones,
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
   IF @cAccion='LOTE'
   BEGIN
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
     DECLARE @insertados TABLE(planta_id BIGINT NOT NULL);
     DECLARE lote CURSOR LOCAL FAST_FORWARD FOR SELECT variedad,cantidad,parcela FROM @filas ORDER BY variedad;
     OPEN lote; FETCH NEXT FROM lote INTO @variedad,@cantidad,@parcela;
     WHILE @@FETCH_STATUS=0
     BEGIN
        SET @correlativo=NULL;
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
        INSERT INTO prod.PlantaPaltaE3(predio_id,uot_id,convenio_id,variedad_palta_id,parcela_cultivo_id,secuencia,codigo,creado_por_usuario_id)
        OUTPUT inserted.planta_id INTO @insertados(planta_id)
        SELECT @predio,@uot,@conv,@variedad,@parcela,@correlativo+CONVERT(INT,N.n),
          CONCAT('PAL-',@predio,'-',@variedad,'-',RIGHT(CONCAT('000000',@correlativo+N.n),6)),@usuario FROM N;
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
     SELECT @estadoPrev=estado_actual,@versionActual=version FROM prod.PlantaPaltaE3 WITH(UPDLOCK,HOLDLOCK)
       WHERE planta_id=@planta AND predio_id=@predio AND convenio_id=@conv AND uot_id=@uot;
     IF @estadoPrev IS NULL THROW 51103,N'La planta no pertenece a su predio y convenio.',1;
     SET @version=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.version'));
     IF @cAccion IN('FICHA','ESTADO') AND (@version IS NULL OR @version<>@versionActual)
       THROW 51117,N'La ficha fue modificada por otro usuario. Actualice antes de guardar.',1;
     IF @estadoPrev='MUERTA' AND @cAccion IN('ESTADO','TRATAMIENTO','SEGUIMIENTO')
        THROW 51108,N'Una planta muerta no admite evaluaciones ordinarias.',1;
     SET @visita=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.visitaId'));
     IF @visita IS NOT NULL AND NOT EXISTS(
       SELECT 1 FROM campo.VisitaTecnica V
       JOIN campo.SalidaParticipante SP ON SP.salida_participante_id=V.salida_participante_id
       JOIN campo.SalidaE2 E ON E.salida_campo_id=SP.salida_campo_id
       WHERE V.visita_tecnica_id=@visita AND V.predio_id=@predio AND SP.empleado_id=@emp
         AND E.uot_id=@uot AND E.convenio_id=@conv AND E.estado IN('EN_EJECUCION','EN_RETORNO','CERRADA'))
       THROW 51109,N'La visita no pertenece a una salida autorizada de este convenio.',1;
     SET @observacion=JSON_VALUE(@cJson,'$.datos.observacion');
     SET @hecho=COALESCE(TRY_CONVERT(DATETIME2(0),JSON_VALUE(@cJson,'$.datos.fechaHora')), @fecha);
     IF @hecho>DATEADD(MINUTE,5,@fecha) THROW 51110,N'La fecha no puede estar en el futuro.',1;
     IF @cAccion='FICHA'
     BEGIN
       SET @plantacion=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaPlantacion'));
       SET @edad=TRY_CONVERT(SMALLINT,JSON_VALUE(@cJson,'$.datos.edadReferenciaAnios'));
       IF @plantacion IS NULL AND @edad IS NULL THROW 51111,N'Indique fecha de plantación o edad de referencia.',1;
       IF @plantacion>CONVERT(DATE,@fecha) OR @edad NOT BETWEEN 0 AND 200 THROW 51111,N'La edad o fecha es inválida.',1;
       UPDATE prod.PlantaPaltaE3 SET fecha_plantacion=COALESCE(@plantacion,fecha_plantacion),
          edad_referencia_anios=CASE WHEN @plantacion IS NOT NULL THEN NULL ELSE COALESCE(@edad,edad_referencia_anios) END,
          fecha_referencia=CASE WHEN @plantacion IS NOT NULL THEN NULL WHEN @edad IS NOT NULL THEN CONVERT(DATE,@fecha) ELSE fecha_referencia END,
          version=version+1 WHERE planta_id=@planta;
       SET @accionLog='FICHA';
     END
     ELSE IF @cAccion='ESTADO'
     BEGIN
       SET @estado=JSON_VALUE(@cJson,'$.datos.estado');
       SET @diagnostico=TRY_CONVERT(SMALLINT,JSON_VALUE(@cJson,'$.datos.diagnosticoId'));
       IF @estado NOT IN('SANA','ENFERMA','MUERTA') THROW 51112,N'Estado no admitido.',1;
       IF @estado='ENFERMA' AND (@diagnostico IS NULL OR NOT EXISTS(SELECT 1 FROM sanidad.TipoProblemaFitosanitario WHERE tipo_problema_fitosanitario_id=@diagnostico AND estado=1))
          THROW 51112,N'El diagnóstico debe seleccionarse del catálogo.',1;
       IF @estado='MUERTA' AND NULLIF(LTRIM(RTRIM(@observacion)),N'') IS NULL
          THROW 51112,N'La muerte requiere observación.',1;
       IF @estadoPrev='ENFERMA' AND @estado='ENFERMA' THROW 51112,N'El episodio ya está abierto; registre un tratamiento o seguimiento.',1;
       IF @estadoPrev=@estado THROW 51112,N'La planta ya tiene el estado seleccionado.',1;
       IF @estadoPrev='ENFERMA'
       BEGIN
         IF EXISTS(SELECT 1 FROM sanidad.EpisodioPlantaE3 WHERE planta_id=@planta AND fin IS NULL AND inicio>@hecho)
          THROW 51112,N'El cierre no puede anteceder al inicio del diagnóstico.',1;
         UPDATE sanidad.EpisodioPlantaE3 SET fin=@hecho,usuario_cierre_id=@usuario
          WHERE planta_id=@planta AND fin IS NULL;
       END;
       IF @estado='ENFERMA'
         INSERT INTO sanidad.EpisodioPlantaE3(planta_id,tipo_problema_fitosanitario_id,inicio,observacion,usuario_apertura_id,visita_tecnica_id)
          VALUES(@planta,@diagnostico,@hecho,@observacion,@usuario,@visita);
       UPDATE prod.PlantaPaltaE3 SET estado_actual=@estado,version=version+1 WHERE planta_id=@planta;
       SET @accionLog='EVALUACION';
     END
     ELSE IF @cAccion='TRATAMIENTO'
     BEGIN
       SELECT @episodio=episodio_id FROM sanidad.EpisodioPlantaE3 WITH(UPDLOCK,HOLDLOCK) WHERE planta_id=@planta AND fin IS NULL;
       IF @estadoPrev<>'ENFERMA' OR @episodio IS NULL THROW 51113,N'Solo una planta enferma con episodio abierto admite tratamientos.',1;
       IF @hecho<(SELECT inicio FROM sanidad.EpisodioPlantaE3 WHERE episodio_id=@episodio)
        THROW 51113,N'El tratamiento no puede anteceder al diagnóstico.',1;
       IF NULLIF(JSON_VALUE(@cJson,'$.datos.descripcion'),N'') IS NULL THROW 51113,N'Describa el tratamiento.',1;
       INSERT sanidad.TratamientoPlantaE3(episodio_id,descripcion,resultado,fecha_aplicacion,visita_tecnica_id,usuario_id)
         VALUES(@episodio,JSON_VALUE(@cJson,'$.datos.descripcion'),JSON_VALUE(@cJson,'$.datos.resultado'),@hecho,@visita,@usuario);
       SET @accionLog='TRATAMIENTO';
     END
     ELSE IF @cAccion='SEGUIMIENTO'
     BEGIN
       IF @estadoPrev NOT IN('SANA','ENFERMA') THROW 51114,N'Evalúe primero la planta antes de registrar un seguimiento.',1;
       IF NULLIF(LTRIM(RTRIM(@observacion)),N'') IS NULL THROW 51114,N'Describa el seguimiento realizado.',1;
       SET @accionLog='SEGUIMIENTO';
     END
     ELSE IF @cAccion='PRODUCCION'
     BEGIN
       SET @anio=TRY_CONVERT(SMALLINT,JSON_VALUE(@cJson,'$.datos.anio'));
       SET @estimado=TRY_CONVERT(DECIMAL(14,3),JSON_VALUE(@cJson,'$.datos.estimadoKg'));
       SET @real=TRY_CONVERT(DECIMAL(14,3),JSON_VALUE(@cJson,'$.datos.realKg'));
       IF @anio NOT BETWEEN 2000 AND 2200 OR (@estimado IS NULL AND @real IS NULL)
        OR @estimado<0 OR @real<0 THROW 51115,N'Revise el año y la producción en kg.',1;
       INSERT prod.ProduccionPlantaE3(planta_id,anio,estimado_kg,real_kg,observacion,usuario_id)
        VALUES(@planta,@anio,@estimado,@real,@observacion,@usuario);
       SET @accionLog='PRODUCCION';
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
     WHEN ERROR_NUMBER() IN(51105,51106,51108,51112,51117) THEN 409 ELSE 400 END;
   SET @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51100 AND 51199 THEN ERROR_MESSAGE()
      ELSE N'No fue posible procesar la solicitud. Verifique los datos o contacte al administrador.' END;
 END CATCH;
END;
GO
