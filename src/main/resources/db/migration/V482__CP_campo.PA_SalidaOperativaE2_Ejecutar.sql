-- E2. PA de coordinación, permisos efectivos, serialización, auditoría e idempotencia.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'campo.PA_SalidaOperativaE2_Ejecutar', N'P') IS NOT NULL DROP PROCEDURE campo.PA_SalidaOperativaE2_Ejecutar;
GO
CREATE PROCEDURE campo.PA_SalidaOperativaE2_Ejecutar
 @cAccion VARCHAR(35),@cJson NVARCHAR(MAX),
 @cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
 @cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo completar la operación.',@cCodigoRespuesta='E2_ERROR',@nHttpRespuesta=400;
 DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,
   @gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
   @bAuth BIT,@cAuth NVARCHAR(300),@uot BIGINT,@convenio BIGINT,@salida BIGINT,
   @permiso VARCHAR(40),@key UNIQUEIDENTIFIER,@hash VARBINARY(32),@hashPrev VARBINARY(32),
   @anterior NVARCHAR(MAX),@estado VARCHAR(24),@solicitante BIGINT,@socio BIT,
   @inicio DATETIME2(0),@fin DATETIME2(0),@motivo INT,@nombre NVARCHAR(180),@descripcion NVARCHAR(400),
   @obs NVARCHAR(1500),@detalle NVARCHAR(1200),@decision VARCHAR(25),@bien BIGINT,@recurso BIGINT,
   @id BIGINT,@predio BIGINT,@destino BIGINT,@tipo INT,@visita BIGINT,@cnt INT,@estadoBien VARCHAR(24),
   @fecha DATETIME2(0)=SYSUTCDATETIME(),
   @nombreAnterior NVARCHAR(180),@descripcionAnterior NVARCHAR(400);
 IF ISJSON(@cJson)<>1 OR @cAccion NOT IN('LISTAR','VER','CATALOGOS','SOLICITAR','DECIDIR','ENTREGAR','INICIAR','VISITAR','FINALIZAR_VISITA','RETORNAR','INSPECCIONAR','CERRAR','CORREGIR','CANCELAR','VINCULAR_DESTINO') RETURN;
 SELECT @uot=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
        @salida=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.salidaId')),
        @convenio=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.convenioId')),
        @key=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia'));
 SET @permiso=CASE WHEN @cAccion IN('LISTAR','CATALOGOS') THEN 'SALIDAS_LISTAR'
       WHEN @cAccion='VER' THEN 'SALIDAS_VER'
       WHEN @cAccion='SOLICITAR' THEN 'SALIDAS_CREAR'
       WHEN @cAccion IN('DECIDIR','INSPECCIONAR','CERRAR') THEN 'SALIDAS_CONFIRMAR'
       WHEN @cAccion='ENTREGAR' THEN 'RECURSOS_CREAR'
       WHEN @cAccion='VISITAR' THEN 'VISITAS_EDITAR'
       WHEN @cAccion='CANCELAR' THEN 'SALIDAS_RETIRAR'
       WHEN @cAccion='FINALIZAR_VISITA' THEN 'VISITAS_CONFIRMAR'
       ELSE 'SALIDAS_EDITAR' END;
 BEGIN TRY
 EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,@permiso,
    @nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,
    @gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bAuth OUTPUT,@cAuth OUTPUT;
 IF ISNULL(@bAuth,0)<>1 THROW 51060,N'El usuario no tiene permiso para esta operación.',1;
 IF @uot IS NULL OR @uot<1 OR seg.FN_Usuario_TienePermisoUOT(@nUsuario,@uot,@permiso)<>1
    THROW 51060,N'No tiene permiso en la unidad territorial indicada.',1;
 IF @convenio IS NOT NULL AND NOT EXISTS(SELECT 1 FROM org.ConvenioUOTOrganizacion C
    WHERE C.convenio_uot_organizacion_id=@convenio AND C.uot_id=@uot AND C.estado=1
    AND EXISTS(SELECT 1 FROM org.ConvenioModuloEspecial CM
          JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id
            AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
          WHERE CM.convenio_uot_organizacion_id=C.convenio_uot_organizacion_id AND CM.estado=1)
    AND (C.fecha_inicio IS NULL OR C.fecha_inicio<=CONVERT(DATE,@fecha))
    AND (C.fecha_fin IS NULL OR C.fecha_fin>=CONVERT(DATE,@fecha)))
    THROW 51060,N'El convenio no está vigente en esta unidad territorial.',1;
 IF @convenio IS NOT NULL AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,@uot,'APAPPSS_PREDIOS_VER')<>1
    THROW 51060,N'No tiene acceso al convenio indicado.',1;
 IF @cAccion='CATALOGOS'
 BEGIN
    SET @cDatos=(SELECT JSON_QUERY((SELECT motivo_salida_id id,nombre FROM campo.MotivoSalida WHERE estado=1 ORDER BY nombre FOR JSON PATH)) motivos,
      JSON_QUERY((SELECT tipo_visita_id id,nombre FROM campo.TipoVisitaE2 WHERE estado=1 ORDER BY nombre FOR JSON PATH)) tiposVisita,
      JSON_QUERY((SELECT bien_inventario_id id,nombre,codigo_patrimonial codigo FROM logistica.BienInventario B
       WHERE uot_id=@uot AND estado=1 AND estado_bien='DISPONIBLE' ORDER BY nombre FOR JSON PATH)) bienes
       FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    SET @bResultado=1;
 END
 ELSE IF @cAccion='LISTAR'
 BEGIN
   DECLARE @pagina INT=COALESCE(TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.filtros.pagina')),1),
           @tamano INT=COALESCE(TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.filtros.tamano')),20),
           @fEstado VARCHAR(24)=JSON_VALUE(@cJson,'$.filtros.estado');
   IF @pagina<1 OR @tamano<1 OR @tamano>100 THROW 51061,N'Paginación inválida.',1;
   SET @cDatos=(SELECT (SELECT COUNT_BIG(*) FROM campo.SalidaE2 E WHERE E.uot_id=@uot
      AND ((@convenio IS NULL AND E.convenio_id IS NULL) OR E.convenio_id=@convenio)
      AND (@fEstado IS NULL OR E.estado=@fEstado)) total,
      JSON_QUERY((SELECT E.salida_campo_id salidaId,E.nombre,E.estado,CONVERT(VARCHAR(19),E.fecha_solicitud,126)+'Z' fechaSolicitud,
          CASE WHEN E.fecha_fin_prevista IS NULL THEN NULL ELSE CONVERT(VARCHAR(19),E.fecha_fin_prevista,126)+'Z' END fechaFinPrevista,CONVERT(VARCHAR(19),S.fecha_hora_programada,126)+'Z' fechaInicioPrevista,
          E.solicitante_empleado_id solicitanteEmpleadoId
        FROM campo.SalidaE2 E JOIN campo.SalidaCampo S ON S.salida_campo_id=E.salida_campo_id
        WHERE E.uot_id=@uot AND ((@convenio IS NULL AND E.convenio_id IS NULL) OR E.convenio_id=@convenio)
        AND (@fEstado IS NULL OR E.estado=@fEstado)
        ORDER BY E.fecha_solicitud DESC,E.salida_campo_id DESC
        OFFSET (@pagina-1)*@tamano ROWS FETCH NEXT @tamano ROWS ONLY FOR JSON PATH)) items
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   SET @bResultado=1;
 END
 ELSE
 BEGIN
   IF @cAccion<>'SOLICITAR'
   BEGIN
      SELECT @estado=E.estado,@solicitante=E.solicitante_empleado_id
      FROM campo.SalidaE2 E WHERE E.salida_campo_id=@salida AND E.uot_id=@uot
        AND ((@convenio IS NULL AND E.convenio_id IS NULL) OR E.convenio_id=@convenio);
      IF @estado IS NULL THROW 51062,N'Salida no disponible en su ámbito.',1;
   END;
   IF @cAccion='VER'
   BEGIN
       SET @cDatos=(SELECT E.salida_campo_id salidaId,E.nombre,E.estado,E.uot_id uotId,E.convenio_id convenioId,
         E.solicitante_empleado_id solicitanteEmpleadoId,CONVERT(VARCHAR(19),E.fecha_solicitud,126)+'Z' fechaSolicitud,
         S.motivo_salida_id motivoSalidaId,S.descripcion,CONVERT(VARCHAR(19),S.fecha_hora_programada,126)+'Z' fechaInicioPrevista,
         CASE WHEN E.fecha_fin_prevista IS NULL THEN NULL ELSE CONVERT(VARCHAR(19),E.fecha_fin_prevista,126)+'Z' END fechaFinPrevista,CASE WHEN S.fecha_hora_salida_real IS NULL THEN NULL ELSE CONVERT(VARCHAR(19),S.fecha_hora_salida_real,126)+'Z' END fechaInicioReal,
         CASE WHEN S.fecha_hora_retorno_real IS NULL THEN NULL ELSE CONVERT(VARCHAR(19),S.fecha_hora_retorno_real,126)+'Z' END fechaFinReal,CASE WHEN E.fecha_aprobacion IS NULL THEN NULL ELSE CONVERT(VARCHAR(19),E.fecha_aprobacion,126)+'Z' END fechaAprobacion,
         JSON_QUERY((SELECT D.destino_id destinoId,D.predio_id predioId,D.referencia,D.orden
             FROM campo.SalidaDestinoE2 D WHERE D.salida_campo_id=@salida ORDER BY D.orden FOR JSON PATH)) destinos,
         JSON_QUERY((SELECT R.solicitud_recurso_id solicitudRecursoId,R.bien_inventario_id bienId,B.nombre,
             R.estado,R.resultado_declarado resultadoDeclarado,R.resultado_validado resultadoValidado,R.observacion
             FROM campo.SalidaRecursoE2 R JOIN logistica.BienInventario B ON B.bien_inventario_id=R.bien_inventario_id
             WHERE R.salida_campo_id=@salida FOR JSON PATH)) bienes,
         JSON_QUERY((SELECT V.visita_tecnica_id visitaId,V.predio_id predioId,CONVERT(VARCHAR(19),V.fecha_hora_inicio,126)+'Z' fechaInicio,
             CASE WHEN V.fecha_hora_fin IS NULL THEN NULL ELSE CONVERT(VARCHAR(19),V.fecha_hora_fin,126)+'Z' END fechaFin,V.estado_proceso estado,V.objetivo,V.resumen,T.nombre tipoVisita
             FROM campo.VisitaTecnica V JOIN campo.SalidaVisitaE2 X ON X.visita_tecnica_id=V.visita_tecnica_id
             JOIN campo.TipoVisitaE2 T ON T.tipo_visita_id=X.tipo_visita_id
             JOIN campo.SalidaDestinoE2 D ON D.destino_id=X.destino_id
             WHERE D.salida_campo_id=@salida ORDER BY V.visita_tecnica_id FOR JSON PATH)) visitas,
         JSON_QUERY((SELECT H.evento_id eventoId,H.tipo,H.detalle,H.usuario_id usuarioId,CONVERT(VARCHAR(19),H.fecha_hora,126)+'Z' fechaHora
             FROM campo.SalidaEventoE2 H WHERE H.salida_campo_id=@salida ORDER BY H.evento_id DESC FOR JSON PATH)) historial,
         (SELECT observacion_general FROM campo.SalidaRetornoE2 WHERE salida_campo_id=@salida) observacionRetorno
       FROM campo.SalidaE2 E JOIN campo.SalidaCampo S ON S.salida_campo_id=E.salida_campo_id WHERE E.salida_campo_id=@salida
       FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
       SET @bResultado=1;
   END
   ELSE
   BEGIN
     IF @key IS NULL THROW 51063,N'Falta la clave de idempotencia.',1;
     SET @hash=HASHBYTES('SHA2_256',CONCAT(@cAccion,N'|',ISNULL(JSON_QUERY(@cJson,'$.filtros'),N''),N'|',ISNULL(JSON_QUERY(@cJson,'$.datos'),N'')));
     BEGIN TRANSACTION;
     DECLARE @locked INT;
     DECLARE @recursoLock NVARCHAR(255)=CONCAT(N'DESCO:E2:',@nUsuario,N':',@cAccion,N':',CONVERT(NVARCHAR(36),@key));
     EXEC @locked=sys.sp_getapplock @Resource=@recursoLock,
       @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=5000;
     IF @locked<0 THROW 51064,N'La solicitud está siendo procesada.',1;
     SELECT @hashPrev=hash_peticion,@anterior=respuesta FROM campo.SalidaOperacionE2 WITH(UPDLOCK,HOLDLOCK)
      WHERE usuario_id=@nUsuario AND tipo=@cAccion AND idempotencia=@key;
     IF @hashPrev IS NOT NULL
     BEGIN
         IF @hashPrev<>@hash THROW 51065,N'La clave ya fue utilizada con otros datos.',1;
         SET @cDatos=@anterior;SET @bResultado=1;
     END
     ELSE
     BEGIN
       IF @cAccion='SOLICITAR'
       BEGIN
         SELECT @nombre=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.nombre'))),N''),
           @motivo=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.motivoSalidaId')),
           @inicio=TRY_CONVERT(DATETIME2(0),JSON_VALUE(@cJson,'$.datos.fechaInicioPrevista')),
           @fin=TRY_CONVERT(DATETIME2(0),JSON_VALUE(@cJson,'$.datos.fechaFinPrevista')),
           @descripcion=JSON_VALUE(@cJson,'$.datos.descripcion');
         IF @nEmp IS NULL OR @nombre IS NULL OR @motivo IS NULL OR @inicio IS NULL OR @fin<@inicio
           THROW 51066,N'Complete nombre, motivo, fecha inicial y fechas coherentes.',1;
         IF NOT EXISTS(SELECT 1 FROM campo.MotivoSalida WHERE motivo_salida_id=@motivo AND estado=1)
           THROW 51066,N'Motivo no válido.',1;
         IF NOT EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.destinos'))
           THROW 51066,N'Agregue al menos un destino.',1;
         IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.destinos') WITH(predioId BIGINT '$.predioId',referencia NVARCHAR(250) '$.referencia') D
           WHERE (D.predioId IS NULL AND NULLIF(TRIM(D.referencia),N'') IS NULL) OR
            (D.predioId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.PredioAmbito A WHERE A.predio_id=D.predioId
              AND A.uot_id=@uot AND A.estado=1 AND ((@convenio IS NULL AND A.convenio_uot_organizacion_id IS NULL) OR A.convenio_uot_organizacion_id=@convenio))))
           THROW 51066,N'Uno de los predios no pertenece al ámbito de la salida.',1;
         IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.bienes') WITH(bienId BIGINT '$.bienId') B
           LEFT JOIN logistica.BienInventario I ON I.bien_inventario_id=B.bienId WHERE B.bienId IS NULL OR I.uot_id<>@uot OR I.estado<>1)
           THROW 51066,N'Uno de los bienes no pertenece a esta UOT.',1;
         IF EXISTS(SELECT bienId FROM OPENJSON(@cJson,'$.datos.bienes') WITH(bienId BIGINT '$.bienId') GROUP BY bienId HAVING COUNT(*)>1)
           THROW 51066,N'No duplique bienes en la misma solicitud.',1;
         INSERT campo.SalidaCampo(motivo_salida_id,fecha_hora_programada,descripcion,estado_proceso,uot_id,estado)
          VALUES(@motivo,@inicio,@descripcion,'PROGRAMADA',@uot,1);
         SET @salida=CONVERT(BIGINT,SCOPE_IDENTITY());
         INSERT campo.SalidaE2(salida_campo_id,nombre,solicitante_empleado_id,uot_id,convenio_id,fecha_fin_prevista)
         VALUES(@salida,@nombre,@nEmp,@uot,@convenio,@fin);
         INSERT campo.SalidaParticipante(salida_campo_id,empleado_id,es_responsable,funcion,estado)
          VALUES(@salida,@nEmp,1,N'Responsable',1);
         INSERT campo.SalidaDestinoE2(salida_campo_id,predio_id,referencia,orden)
          SELECT @salida,predioId,referencia,CONVERT(INT,[key])+1 FROM OPENJSON(@cJson,'$.datos.destinos') J
          CROSS APPLY OPENJSON(J.value) WITH(predioId BIGINT '$.predioId',referencia NVARCHAR(250) '$.referencia');
         INSERT campo.SalidaRecursoE2(salida_campo_id,bien_inventario_id)
          SELECT @salida,TRY_CONVERT(BIGINT,JSON_VALUE(value,'$.bienId')) FROM OPENJSON(@cJson,'$.datos.bienes');
         SET @estado='SOLICITADA';
       END
       ELSE IF @cAccion='CORREGIR'
       BEGIN
          IF @estado<>'OBSERVADA' OR @solicitante<>@nEmp THROW 51066,N'Solo el solicitante puede corregir una solicitud observada.',1;
          SET @nombre=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.nombre')),N'');
          SET @detalle=JSON_VALUE(@cJson,'$.datos.descripcion');
          IF @nombre IS NULL THROW 51066,N'Ingrese un nombre para la solicitud.',1;
          SELECT @nombreAnterior=E.nombre,@descripcionAnterior=S.descripcion
            FROM campo.SalidaE2 E JOIN campo.SalidaCampo S ON S.salida_campo_id=E.salida_campo_id
            WHERE E.salida_campo_id=@salida;
          UPDATE campo.SalidaE2 SET nombre=@nombre,estado='SOLICITADA',fecha_solicitud=@fecha WHERE salida_campo_id=@salida;
          UPDATE campo.SalidaCampo SET descripcion=@detalle WHERE salida_campo_id=@salida;
          SET @estado='SOLICITADA';
       END
       ELSE IF @cAccion='CANCELAR'
       BEGIN
          SET @detalle=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.motivo')),N'');
          IF @estado NOT IN('SOLICITADA','OBSERVADA','RECHAZADA') OR @solicitante<>@nEmp OR @detalle IS NULL
            THROW 51066,N'No es posible cancelar esta salida o falta el motivo.',1;
          UPDATE campo.SalidaE2 SET estado='CANCELADA' WHERE salida_campo_id=@salida;
          UPDATE campo.SalidaCampo SET estado_proceso='CANCELADA' WHERE salida_campo_id=@salida;
          SET @estado='CANCELADA';
       END
       ELSE IF @cAccion='VINCULAR_DESTINO'
       BEGIN
         SET @destino=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.destinoId'));
         SET @predio=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.predioId'));
         IF @estado NOT IN('APROBADA','EN_EJECUCION') OR @solicitante<>@nEmp
            THROW 51066,N'El destino solo puede vincularse durante una salida aprobada.',1;
         IF NOT EXISTS(SELECT 1 FROM prod.PredioAmbito WHERE predio_id=@predio AND uot_id=@uot AND estado=1
             AND ((@convenio IS NULL AND convenio_uot_organizacion_id IS NULL) OR convenio_uot_organizacion_id=@convenio))
            THROW 51060,N'El predio no pertenece a su ámbito.',1;
         UPDATE campo.SalidaDestinoE2 SET predio_id=@predio WHERE destino_id=@destino
           AND salida_campo_id=@salida AND predio_id IS NULL;
         IF @@ROWCOUNT<>1 THROW 51066,N'El destino no está disponible para vincular.',1;
       END
       ELSE IF @cAccion='DECIDIR'
       BEGIN
         SET @decision=UPPER(JSON_VALUE(@cJson,'$.datos.decision'));
         SET @detalle=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.motivo')),N'');
         IF @estado<>'SOLICITADA' OR @decision NOT IN('APROBADA','OBSERVADA','RECHAZADA')
           THROW 51066,N'La solicitud no admite esta decisión.',1;
         IF @solicitante=@nEmp THROW 51060,N'El solicitante no puede aprobar su propia salida.',1;
         IF @decision<>'APROBADA' AND @detalle IS NULL THROW 51066,N'Debe indicar el motivo.',1;
         UPDATE campo.SalidaE2 SET estado=@decision,usuario_aprobador=@nUsuario,
              fecha_aprobacion=CASE WHEN @decision='APROBADA' THEN @fecha ELSE NULL END WHERE salida_campo_id=@salida;
         SET @estado=@decision;
       END
       ELSE IF @cAccion='ENTREGAR'
       BEGIN
         IF @estado<>'APROBADA' THROW 51066,N'Apruebe la solicitud antes de entregar bienes.',1;
         DECLARE c_bienes CURSOR LOCAL FAST_FORWARD FOR
          SELECT R.solicitud_recurso_id,R.bien_inventario_id FROM campo.SalidaRecursoE2 R
          WHERE R.salida_campo_id=@salida AND R.estado='SOLICITADO' ORDER BY R.solicitud_recurso_id;
         OPEN c_bienes; FETCH NEXT FROM c_bienes INTO @id,@bien;
         WHILE @@FETCH_STATUS=0
         BEGIN
           IF NOT EXISTS(SELECT 1 FROM logistica.BienInventario WITH(UPDLOCK,HOLDLOCK)
             WHERE bien_inventario_id=@bien AND uot_id=@uot AND estado=1 AND estado_bien='DISPONIBLE')
              THROW 51067,N'Un bien ya no está disponible para entrega.',1;
           INSERT logistica.RecursoProgramado(salida_campo_id,bien_inventario_id,cantidad_programada,estado_proceso,estado,usuario_programacion_id)
            VALUES(@salida,@bien,1,'PROGRAMADO',1,@nUsuario);
           SET @recurso=CONVERT(BIGINT,SCOPE_IDENTITY());
           UPDATE logistica.BienInventario SET estado_bien='ASIGNADO' WHERE bien_inventario_id=@bien AND estado_bien='DISPONIBLE';
           IF @@ROWCOUNT<>1 THROW 51067,N'El bien fue asignado en otra salida.',1;
           UPDATE logistica.RecursoProgramado SET estado_proceso='EN_EJECUCION' WHERE recurso_programado_id=@recurso;
           UPDATE campo.SalidaRecursoE2 SET recurso_programado_id=@recurso,estado='ENTREGADO' WHERE solicitud_recurso_id=@id;
           INSERT logistica.RecursoMovimiento(recurso_programado_id,tipo_movimiento,cantidad,usuario_id,observacion)
            VALUES(@recurso,'ASIGNACION',1,@nUsuario,N'Entrega física de salida E2');
           FETCH NEXT FROM c_bienes INTO @id,@bien;
         END;
         CLOSE c_bienes; DEALLOCATE c_bienes;
       END
       ELSE IF @cAccion='INICIAR'
       BEGIN
         IF @estado<>'APROBADA' OR @solicitante<>@nEmp THROW 51066,N'Salida no aprobada o usuario distinto del responsable.',1;
         IF EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 WHERE salida_campo_id=@salida AND estado<>'ENTREGADO')
           THROW 51066,N'Falta confirmar la entrega física de los bienes solicitados.',1;
         UPDATE campo.SalidaE2 SET estado='EN_EJECUCION' WHERE salida_campo_id=@salida;
         UPDATE campo.SalidaCampo SET estado_proceso='EN_CURSO',fecha_hora_salida_real=@fecha WHERE salida_campo_id=@salida;
         SET @estado='EN_EJECUCION';
       END
       ELSE IF @cAccion='VISITAR'
       BEGIN
         IF @estado<>'EN_EJECUCION' THROW 51066,N'La salida no está en ejecución.',1;
         SELECT @destino=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.destinoId')),
            @tipo=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.tipoVisitaId')),
            @detalle=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.objetivo')),N'');
         SELECT @predio=D.predio_id FROM campo.SalidaDestinoE2 D WHERE D.destino_id=@destino AND D.salida_campo_id=@salida;
         IF @predio IS NULL THROW 51066,N'Registre o vincule un predio al destino antes de iniciar la visita.',1;
         IF NOT EXISTS(SELECT 1 FROM campo.TipoVisitaE2 WHERE tipo_visita_id=@tipo AND estado=1) THROW 51066,N'Tipo de visita no válido.',1;
         IF NOT EXISTS(SELECT 1 FROM prod.PredioAmbito WHERE predio_id=@predio AND uot_id=@uot AND estado=1
             AND ((@convenio IS NULL AND convenio_uot_organizacion_id IS NULL) OR convenio_uot_organizacion_id=@convenio))
           THROW 51060,N'El predio no pertenece al contexto de salida.',1;
         DECLARE @part BIGINT=(SELECT TOP 1 salida_participante_id FROM campo.SalidaParticipante WHERE salida_campo_id=@salida AND empleado_id=@nEmp AND estado=1);
         IF @part IS NULL THROW 51060,N'El usuario no participa en esta salida.',1;
         DECLARE @pos GEOGRAPHY;
         SELECT @pos=U.posicion FROM prod.Predio P JOIN geo.Ubicacion U ON U.ubicacion_id=P.ubicacion_id
           WHERE P.predio_id=@predio;
         INSERT campo.VisitaTecnica(salida_participante_id,predio_id,fecha_hora_inicio,posicion_inicio,objetivo,estado_proceso,estado)
           VALUES(@part,@predio,@fecha,@pos,@detalle,'INICIADA',1);
         SET @visita=CONVERT(BIGINT,SCOPE_IDENTITY());
         INSERT campo.SalidaVisitaE2(visita_tecnica_id,destino_id,tipo_visita_id) VALUES(@visita,@destino,@tipo);
       END
       ELSE IF @cAccion='FINALIZAR_VISITA'
       BEGIN
         SET @visita=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.visitaId'));
         SET @detalle=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.resumen')),N'');
         IF @estado<>'EN_EJECUCION' OR @detalle IS NULL THROW 51066,N'Ingrese qué se hizo durante la visita.',1;
         SELECT @predio=V.predio_id FROM campo.VisitaTecnica V WITH(UPDLOCK,HOLDLOCK)
         JOIN campo.SalidaVisitaE2 X ON X.visita_tecnica_id=V.visita_tecnica_id
         JOIN campo.SalidaDestinoE2 D ON D.destino_id=X.destino_id
         JOIN campo.SalidaParticipante P ON P.salida_participante_id=V.salida_participante_id
         WHERE V.visita_tecnica_id=@visita AND D.salida_campo_id=@salida AND V.estado_proceso='INICIADA' AND P.empleado_id=@nEmp;
         IF @predio IS NULL THROW 51066,N'Visita no disponible.',1;
         UPDATE campo.VisitaTecnica SET resumen=@detalle,fecha_hora_fin=@fecha,estado_proceso='FINALIZADA' WHERE visita_tecnica_id=@visita;
         INSERT prod.ExpedienteActuacion(predio_id,uot_id,convenio_uot_organizacion_id,tipo,observacion,fecha_hecho,
           usuario_id,salida_campo_id,visita_tecnica_id,correlacion_id)
           VALUES(@predio,@uot,@convenio,'SEGUIMIENTO',@detalle,@fecha,@nUsuario,@salida,@visita,@gCorr);
       END
       ELSE IF @cAccion='RETORNAR'
       BEGIN
         SET @obs=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.observacionGeneral')),N'');
         IF @estado<>'EN_EJECUCION' OR @solicitante<>@nEmp OR @obs IS NULL
            THROW 51066,N'Ingrese una observación general antes de retornar.',1;
         IF EXISTS(SELECT 1 FROM campo.SalidaDestinoE2 D JOIN campo.SalidaVisitaE2 X ON X.destino_id=D.destino_id
                 JOIN campo.VisitaTecnica V ON V.visita_tecnica_id=X.visita_tecnica_id
                 WHERE D.salida_campo_id=@salida AND V.estado_proceso='INICIADA')
           THROW 51066,N'Finalice las visitas abiertas antes del retorno.',1;
         IF EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 R WHERE R.salida_campo_id=@salida AND R.estado='ENTREGADO'
           AND NOT EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.bienes') WITH(solicitudRecursoId BIGINT '$.solicitudRecursoId') J
               WHERE J.solicitudRecursoId=R.solicitud_recurso_id)) THROW 51066,N'Declare el estado de cada bien.',1;
         IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.bienes') WITH(solicitudRecursoId BIGINT '$.solicitudRecursoId',resultado VARCHAR(24) '$.resultado') J
            LEFT JOIN campo.SalidaRecursoE2 R ON R.solicitud_recurso_id=J.solicitudRecursoId AND R.salida_campo_id=@salida
            WHERE R.solicitud_recurso_id IS NULL OR J.resultado NOT IN('CONFORME','DANADO','FALTANTE'))
           THROW 51066,N'Estado de recurso inválido.',1;
         INSERT campo.SalidaRetornoE2(salida_campo_id,observacion_general,usuario_id) VALUES(@salida,@obs,@nUsuario);
         UPDATE R SET resultado_declarado=J.resultado,observacion=J.observacion
         FROM campo.SalidaRecursoE2 R JOIN OPENJSON(@cJson,'$.datos.bienes')
          WITH(solicitudRecursoId BIGINT '$.solicitudRecursoId',resultado VARCHAR(24) '$.resultado',observacion NVARCHAR(500) '$.observacion') J
          ON J.solicitudRecursoId=R.solicitud_recurso_id WHERE R.salida_campo_id=@salida;
         UPDATE campo.SalidaE2 SET estado='EN_RETORNO',fecha_retorno_declarado=@fecha WHERE salida_campo_id=@salida;
         UPDATE campo.SalidaCampo SET fecha_hora_retorno_real=@fecha WHERE salida_campo_id=@salida;
         SET @estado='EN_RETORNO';
       END
       ELSE IF @cAccion='INSPECCIONAR'
       BEGIN
         IF @estado<>'EN_RETORNO' OR @solicitante=@nEmp THROW 51066,N'El visto bueno requiere un inspector distinto del solicitante.',1;
         IF EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 R WHERE R.salida_campo_id=@salida AND R.estado='ENTREGADO'
          AND NOT EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.bienes') WITH(solicitudRecursoId BIGINT '$.solicitudRecursoId') J
          WHERE J.solicitudRecursoId=R.solicitud_recurso_id)) THROW 51066,N'Inspeccione todos los bienes pendientes.',1;
         IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.bienes') WITH(solicitudRecursoId BIGINT '$.solicitudRecursoId',resultado VARCHAR(24) '$.resultado') J
          LEFT JOIN campo.SalidaRecursoE2 R ON R.solicitud_recurso_id=J.solicitudRecursoId AND R.salida_campo_id=@salida AND R.estado='ENTREGADO'
          WHERE R.solicitud_recurso_id IS NULL OR J.resultado NOT IN('CONFORME','DANADO','FALTANTE')) THROW 51066,N'Inspección inválida.',1;
         DECLARE c_validar CURSOR LOCAL FAST_FORWARD FOR
          SELECT R.solicitud_recurso_id,R.recurso_programado_id,J.resultado
          FROM campo.SalidaRecursoE2 R JOIN OPENJSON(@cJson,'$.datos.bienes')
          WITH(solicitudRecursoId BIGINT '$.solicitudRecursoId',resultado VARCHAR(24) '$.resultado') J
           ON J.solicitudRecursoId=R.solicitud_recurso_id WHERE R.salida_campo_id=@salida AND R.estado='ENTREGADO';
         OPEN c_validar;FETCH NEXT FROM c_validar INTO @id,@recurso,@estadoBien;
         WHILE @@FETCH_STATUS=0
         BEGIN
           UPDATE campo.SalidaRecursoE2 SET estado=CASE WHEN @estadoBien='CONFORME' THEN 'VALIDADO' ELSE 'INCIDENCIA' END,
              resultado_validado=@estadoBien,fecha_validacion=@fecha,usuario_validacion=@nUsuario WHERE solicitud_recurso_id=@id;
           IF @estadoBien='CONFORME'
             INSERT logistica.RecursoMovimiento(recurso_programado_id,tipo_movimiento,cantidad,usuario_id,observacion)
               VALUES(@recurso,'DEVOLUCION',1,@nUsuario,N'Devolución conforme y validada E2');
           FETCH NEXT FROM c_validar INTO @id,@recurso,@estadoBien;
         END;
         CLOSE c_validar; DEALLOCATE c_validar;
       END
       ELSE IF @cAccion='CERRAR'
       BEGIN
         IF @estado<>'EN_RETORNO' OR EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 WHERE salida_campo_id=@salida AND estado='ENTREGADO')
           THROW 51066,N'Inspeccione todos los recursos antes de cerrar.',1;
         IF NOT EXISTS(SELECT 1 FROM campo.SalidaRetornoE2 WHERE salida_campo_id=@salida) THROW 51066,N'Retorno pendiente.',1;
         UPDATE campo.SalidaE2 SET estado='CERRADA',fecha_cierre=@fecha WHERE salida_campo_id=@salida;
         UPDATE campo.SalidaCampo SET estado_proceso='FINALIZADA' WHERE salida_campo_id=@salida;
         SET @estado='CERRADA';
       END;
       SET @detalle=CASE WHEN @cAccion='RETORNAR' THEN @obs WHEN @cAccion='DECIDIR' THEN JSON_VALUE(@cJson,'$.datos.motivo')
          WHEN @cAccion='INSPECCIONAR' THEN JSON_VALUE(@cJson,'$.datos.observacion')
          WHEN @cAccion='FINALIZAR_VISITA' THEN @detalle
          WHEN @cAccion='CANCELAR' THEN @detalle
          WHEN @cAccion='CORREGIR' THEN LEFT(CONCAT(N'Nombre anterior: ',@nombreAnterior,N' | Descripción anterior: ',
             COALESCE(@descripcionAnterior,N''),N' | Nombre nuevo: ',@nombre,N' | Descripción nueva: ',COALESCE(@detalle,N'')),1200)
          WHEN @cAccion='VINCULAR_DESTINO' THEN CONCAT(N'Destino ',@destino,N' vinculado a predio ',@predio)
          WHEN @cAccion='VISITAR' THEN CONCAT(N'Inicio de visita ',@visita,N', destino ',@destino,N', tipo ',@tipo)
          ELSE NULL END;
       DECLARE @auditId BIGINT,@transitionId BIGINT,@ident NVARCHAR(200)=CONVERT(NVARCHAR(200),@salida);
       EXEC auditoria.PA_Operacion_Ins_RegistrarCambio
         @nUsuarioId=@nUsuario,@nSesionUsuarioId=@nSesion,@nDispositivoUsuarioId=@nDisp,@nModuloId=@nModulo,
         @cAccion=@cAccion,@cEsquemaEntidad=N'campo',@cNombreEntidad=N'SalidaCampo',@cIdentificador=@ident,
         @cIp=@cIp,@gCorrelacionId=@gCorr,@gSolicitudId=@gSol,@cEndpoint=@cEnd,
         @nAuditoriaEventoId=@auditId OUTPUT,@nTransicionEstadoId=@transitionId OUTPUT;
       INSERT campo.SalidaEventoE2(salida_campo_id,tipo,detalle,usuario_id,correlacion_id)
        VALUES(@salida,@cAccion,@detalle,@nUsuario,@gCorr);
       SET @cDatos=(SELECT @salida salidaId,@visita visitaId,@estado estado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
       INSERT campo.SalidaOperacionE2(usuario_id,tipo,idempotencia,hash_peticion,respuesta)
          VALUES(@nUsuario,@cAccion,@key,@hash,@cDatos);
       SET @bResultado=1;
     END;
     COMMIT TRANSACTION;
   END;
 END;
 IF @bResultado=1 SELECT @cMensaje=N'Operación realizada.',@cCodigoRespuesta='E2_OK',@nHttpRespuesta=200;
 END TRY
 BEGIN CATCH
   IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
   SET @bResultado=0;SET @cDatos=NULL;
   SET @nHttpRespuesta=CASE WHEN ERROR_NUMBER() IN(51060,51062) THEN 403 WHEN ERROR_NUMBER() IN(51064,51065,51067,2601,2627) THEN 409 ELSE 400 END;
   SET @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51060 AND 51067 THEN LEFT(ERROR_MESSAGE(),300)
     ELSE N'No se pudo completar la operación. Revise los datos y el estado de la salida.' END;
   SET @cCodigoRespuesta='E2_VALIDACION';
 END CATCH;
END;
GO
