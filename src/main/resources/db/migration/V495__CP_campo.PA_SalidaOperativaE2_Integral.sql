-- E2: coordinación integral de solicitudes, autorización, visitas, recursos y retorno.
-- Reemplaza el procedimiento aplicado en V433 sin modificar su historial.
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
   @obs NVARCHAR(1500),@detalle NVARCHAR(1200),@decision VARCHAR(25),@bien BIGINT,@suministro BIGINT,
   @recurso BIGINT,@cantidad DECIMAL(14,3),
   @id BIGINT,@predio BIGINT,@destino BIGINT,@tipo INT,@visita BIGINT,@cnt INT,@estadoBien VARCHAR(24),
   @fecha DATETIME2(0)=SYSUTCDATETIME(),
   @nombreAnterior NVARCHAR(180),@descripcionAnterior NVARCHAR(400);
 IF ISJSON(@cJson)<>1 OR @cAccion NOT IN('LISTAR','VER','CATALOGOS','SOLICITAR','DECIDIR','ENTREGAR','INICIAR','VISITAR','FINALIZAR_VISITA','RETORNAR','INSPECCIONAR','CERRAR','CORREGIR','CANCELAR','VINCULAR_DESTINO','REGULARIZAR_FIN') RETURN;
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
      JSON_QUERY((SELECT tipo_visita_id id,nombre,codigo FROM campo.TipoVisitaE2
       WHERE estado=1 AND (codigo<>'MATERIA_SECA' OR @convenio IS NOT NULL) ORDER BY nombre FOR JSON PATH)) tiposVisita,
      JSON_QUERY((SELECT X.id,X.tipo,X.nombre,X.codigo,X.unidad,X.disponible FROM (
       SELECT B.bien_inventario_id id,T.codigo tipo,B.nombre,B.codigo_patrimonial codigo,
         CONVERT(VARCHAR(20),'UNIDAD') unidad,CONVERT(DECIMAL(14,3),1) disponible
       FROM logistica.BienInventario B JOIN logistica.TipoBien T ON T.tipo_bien_id=B.tipo_bien_id
       WHERE B.uot_id=@uot AND B.estado=1 AND B.estado_bien='DISPONIBLE'
         AND NOT EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 R
          JOIN campo.SalidaE2 E ON E.salida_campo_id=R.salida_campo_id
          WHERE R.bien_inventario_id=B.bien_inventario_id
           AND R.estado IN('SOLICITADO','ENTREGADO')
           AND E.estado IN('APROBADA','EN_EJECUCION','EN_RETORNO'))
         AND NOT EXISTS(SELECT 1 FROM logistica.RecursoProgramado RP
          WHERE RP.bien_inventario_id=B.bien_inventario_id AND RP.estado=1
           AND RP.estado_proceso IN('PROGRAMADO','EN_EJECUCION'))
       UNION ALL
       SELECT S.suministro_id,'CONSUMIBLE',S.nombre,S.codigo,S.unidad_medida,
         CONVERT(DECIMAL(14,3),S.stock_disponible)
       FROM logistica.VW_SuministroExistencia S
       WHERE S.estado=1 AND S.stock_disponible>0) X ORDER BY X.tipo,X.nombre FOR JSON PATH)) bienes,
      JSON_QUERY((SELECT E.empleado_id id,
          CONCAT(P.nombres,N' ',P.apellido_paterno,
            CASE WHEN NULLIF(P.apellido_materno,N'') IS NULL THEN N'' ELSE N' '+P.apellido_materno END) nombre,
          COALESCE(U.codigo_empleado,E.codigo_empleado) codigo
        FROM org.EmpleadoUOT U JOIN org.Empleado E ON E.empleado_id=U.empleado_id
        JOIN org.Persona P ON P.persona_id=E.empleado_id
        WHERE U.uot_id=@uot AND U.estado=1 AND E.estado=1 AND P.estado=1
          AND (U.fecha_desde IS NULL OR U.fecha_desde<=CONVERT(DATE,@fecha))
          AND (U.fecha_hasta IS NULL OR U.fecha_hasta>=CONVERT(DATE,@fecha))
        ORDER BY P.nombres,P.apellido_paterno FOR JSON PATH)) participantes
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
         JSON_QUERY((SELECT P.empleado_id empleadoId,
             CONCAT(O.nombres,N' ',O.apellido_paterno,
               CASE WHEN NULLIF(O.apellido_materno,N'') IS NULL THEN N'' ELSE N' '+O.apellido_materno END) nombre,
             P.funcion,P.es_responsable responsable
             FROM campo.SalidaParticipante P JOIN org.Persona O ON O.persona_id=P.empleado_id
             WHERE P.salida_campo_id=@salida AND P.estado=1 ORDER BY P.es_responsable DESC,nombre FOR JSON PATH)) participantes,
         JSON_QUERY((SELECT R.solicitud_recurso_id solicitudRecursoId,R.bien_inventario_id bienId,
             R.suministro_id suministroId,CASE WHEN R.suministro_id IS NULL THEN T.codigo ELSE 'CONSUMIBLE' END tipo,
             COALESCE(B.codigo_patrimonial,U.codigo) codigo,COALESCE(B.nombre,U.nombre) nombre,
             CASE WHEN R.suministro_id IS NULL THEN 'UNIDAD' ELSE U.unidad_medida END unidad,
             R.cantidad_solicitada cantidadSolicitada,R.cantidad_devuelta_declarada cantidadDevueltaDeclarada,
             R.cantidad_devuelta_validada cantidadDevueltaValidada,R.estado,
             R.resultado_declarado resultadoDeclarado,R.resultado_validado resultadoValidado,R.observacion,
             R.observacion_validacion observacionValidacion
             FROM campo.SalidaRecursoE2 R
             LEFT JOIN logistica.BienInventario B ON B.bien_inventario_id=R.bien_inventario_id
             LEFT JOIN logistica.TipoBien T ON T.tipo_bien_id=B.tipo_bien_id
             LEFT JOIN logistica.Suministro U ON U.suministro_id=R.suministro_id
             WHERE R.salida_campo_id=@salida FOR JSON PATH)) bienes,
         JSON_QUERY((SELECT V.visita_tecnica_id visitaId,X.destino_id destinoId,V.predio_id predioId,
             CONVERT(VARCHAR(19),V.fecha_hora_inicio,126)+'Z' fechaInicio,
             CASE WHEN V.fecha_hora_fin IS NULL THEN NULL ELSE CONVERT(VARCHAR(19),V.fecha_hora_fin,126)+'Z' END fechaFin,
             V.estado_proceso estado,V.objetivo,V.resumen,V.recomendaciones,T.nombre tipoVisita
             FROM campo.VisitaTecnica V JOIN campo.SalidaVisitaE2 X ON X.visita_tecnica_id=V.visita_tecnica_id
             JOIN campo.TipoVisitaE2 T ON T.tipo_visita_id=X.tipo_visita_id
             JOIN campo.SalidaDestinoE2 D ON D.destino_id=X.destino_id
             WHERE D.salida_campo_id=@salida ORDER BY V.visita_tecnica_id FOR JSON PATH)) visitas,
         JSON_QUERY((SELECT H.evento_id eventoId,H.tipo,H.detalle,H.usuario_id usuarioId,CONVERT(VARCHAR(19),H.fecha_hora,126)+'Z' fechaHora
             FROM campo.SalidaEventoE2 H WHERE H.salida_campo_id=@salida ORDER BY H.evento_id DESC FOR JSON PATH)) historial,
         (SELECT observacion_general FROM campo.SalidaRetornoE2 WHERE salida_campo_id=@salida) observacionRetorno,
         (SELECT justificacion_sin_visita FROM campo.SalidaRetornoE2 WHERE salida_campo_id=@salida) justificacionSinVisita,
         (SELECT observacion_general FROM campo.SalidaInspeccionE2 WHERE salida_campo_id=@salida) observacionInspeccion
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
       IF @cAccion<>'SOLICITAR'
       BEGIN
         SELECT @estado=E.estado,@solicitante=E.solicitante_empleado_id
         FROM campo.SalidaE2 E WITH(UPDLOCK,HOLDLOCK)
         WHERE E.salida_campo_id=@salida AND E.uot_id=@uot
           AND ((@convenio IS NULL AND E.convenio_id IS NULL) OR E.convenio_id=@convenio);
         IF @estado IS NULL THROW 51062,N'Salida no disponible en su ámbito.',1;
       END;
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
         IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.bienes') WITH(
              bienId BIGINT '$.bienId',suministroId BIGINT '$.suministroId',cantidad DECIMAL(14,3) '$.cantidad') R
           WHERE (R.bienId IS NULL AND R.suministroId IS NULL) OR (R.bienId IS NOT NULL AND R.suministroId IS NOT NULL)
             OR R.cantidad IS NULL OR R.cantidad<=0 OR (R.bienId IS NOT NULL AND R.cantidad<>1))
           THROW 51066,N'La selección de recursos o sus cantidades no es válida.',1;
         IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.bienes') WITH(
              bienId BIGINT '$.bienId',suministroId BIGINT '$.suministroId') R
           LEFT JOIN logistica.BienInventario I ON I.bien_inventario_id=R.bienId
           LEFT JOIN logistica.Suministro U ON U.suministro_id=R.suministroId
           WHERE (R.bienId IS NOT NULL AND (I.bien_inventario_id IS NULL OR I.uot_id<>@uot OR I.estado<>1))
              OR (R.suministroId IS NOT NULL AND (U.suministro_id IS NULL OR U.estado<>1)))
           THROW 51066,N'Uno de los recursos no está habilitado para este ámbito.',1;
         IF EXISTS(SELECT COALESCE(bienId,-suministroId),COUNT(*) FROM OPENJSON(@cJson,'$.datos.bienes')
             WITH(bienId BIGINT '$.bienId',suministroId BIGINT '$.suministroId')
             GROUP BY COALESCE(bienId,-suministroId) HAVING COUNT(*)>1)
           THROW 51066,N'No duplique recursos en la misma solicitud.',1;
         IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.participantes')
             WITH(empleadoId BIGINT '$.empleadoId') P
             WHERE P.empleadoId IS NULL OR NOT EXISTS(SELECT 1 FROM org.Empleado E
                JOIN org.EmpleadoUOT U ON U.empleado_id=E.empleado_id
                WHERE E.empleado_id=P.empleadoId AND E.estado=1 AND U.uot_id=@uot AND U.estado=1
                  AND (U.fecha_desde IS NULL OR U.fecha_desde<=CONVERT(DATE,@fecha))
                  AND (U.fecha_hasta IS NULL OR U.fecha_hasta>=CONVERT(DATE,@fecha))))
           THROW 51060,N'Uno de los participantes no está activo en esta UOT.',1;
         IF EXISTS(SELECT empleadoId FROM OPENJSON(@cJson,'$.datos.participantes')
             WITH(empleadoId BIGINT '$.empleadoId') GROUP BY empleadoId HAVING COUNT(*)>1)
           THROW 51066,N'No duplique participantes.',1;
         INSERT campo.SalidaCampo(motivo_salida_id,fecha_hora_programada,descripcion,estado_proceso,uot_id,estado)
          VALUES(@motivo,@inicio,@descripcion,'PROGRAMADA',@uot,1);
         SET @salida=CONVERT(BIGINT,SCOPE_IDENTITY());
         INSERT campo.SalidaE2(salida_campo_id,nombre,solicitante_empleado_id,uot_id,convenio_id,fecha_fin_prevista)
         VALUES(@salida,@nombre,@nEmp,@uot,@convenio,@fin);
         INSERT campo.SalidaParticipante(salida_campo_id,empleado_id,es_responsable,funcion,estado)
          VALUES(@salida,@nEmp,1,N'Responsable',1);
         INSERT campo.SalidaParticipante(salida_campo_id,empleado_id,es_responsable,funcion,estado)
          SELECT @salida,P.empleadoId,0,NULLIF(TRIM(P.funcion),N''),1
          FROM OPENJSON(@cJson,'$.datos.participantes')
            WITH(empleadoId BIGINT '$.empleadoId',funcion NVARCHAR(120) '$.funcion') P
          WHERE P.empleadoId<>@nEmp;
         INSERT campo.SalidaDestinoE2(salida_campo_id,predio_id,referencia,orden)
          SELECT @salida,predioId,referencia,CONVERT(INT,[key])+1 FROM OPENJSON(@cJson,'$.datos.destinos') J
          CROSS APPLY OPENJSON(J.value) WITH(predioId BIGINT '$.predioId',referencia NVARCHAR(250) '$.referencia');
         INSERT campo.SalidaRecursoE2(salida_campo_id,bien_inventario_id,suministro_id,cantidad_solicitada)
          SELECT @salida,R.bienId,R.suministroId,R.cantidad
          FROM OPENJSON(@cJson,'$.datos.bienes')
            WITH(bienId BIGINT '$.bienId',suministroId BIGINT '$.suministroId',cantidad DECIMAL(14,3) '$.cantidad') R;
         SET @estado='SOLICITADA';
       END
       ELSE IF @cAccion='CORREGIR'
       BEGIN
          IF @estado NOT IN('OBSERVADA','RECHAZADA') OR @solicitante<>@nEmp
              THROW 51066,N'Solo el solicitante puede corregir una solicitud observada o rechazada.',1;
          SELECT @nombre=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.nombre')),N''),
              @detalle=JSON_VALUE(@cJson,'$.datos.descripcion'),
              @motivo=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.motivoSalidaId')),
              @inicio=TRY_CONVERT(DATETIME2(0),JSON_VALUE(@cJson,'$.datos.fechaInicioPrevista')),
              @fin=TRY_CONVERT(DATETIME2(0),JSON_VALUE(@cJson,'$.datos.fechaFinPrevista'));
          IF @nombre IS NULL THROW 51066,N'Ingrese un nombre para la solicitud.',1;
          SELECT @nombreAnterior=E.nombre,@descripcionAnterior=S.descripcion
            FROM campo.SalidaE2 E JOIN campo.SalidaCampo S ON S.salida_campo_id=E.salida_campo_id
            WHERE E.salida_campo_id=@salida;
          IF @motivo IS NOT NULL AND NOT EXISTS(SELECT 1 FROM campo.MotivoSalida WHERE motivo_salida_id=@motivo AND estado=1)
              THROW 51066,N'El motivo de salida no es válido.',1;
          IF @inicio IS NOT NULL OR @fin IS NOT NULL
          BEGIN
            SELECT @inicio=COALESCE(@inicio,S.fecha_hora_programada),@fin=COALESCE(@fin,E.fecha_fin_prevista)
            FROM campo.SalidaCampo S JOIN campo.SalidaE2 E ON E.salida_campo_id=S.salida_campo_id
            WHERE S.salida_campo_id=@salida;
            IF @fin IS NOT NULL AND @fin<@inicio THROW 51066,N'La fecha final es anterior al inicio.',1;
          END;
          IF JSON_QUERY(@cJson,'$.datos.destinos') IS NOT NULL
          BEGIN
            IF NOT EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.destinos'))
               THROW 51066,N'Agregue al menos un destino.',1;
            IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.destinos')
              WITH(predioId BIGINT '$.predioId',referencia NVARCHAR(250) '$.referencia') D
              WHERE (D.predioId IS NULL AND NULLIF(TRIM(D.referencia),N'') IS NULL)
                 OR (D.predioId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.PredioAmbito A
                    WHERE A.predio_id=D.predioId AND A.uot_id=@uot AND A.estado=1 AND
                     ((@convenio IS NULL AND A.convenio_uot_organizacion_id IS NULL)
                      OR A.convenio_uot_organizacion_id=@convenio))))
               THROW 51060,N'Hay un predio fuera del ámbito de la salida.',1;
            DELETE FROM campo.SalidaDestinoE2 WHERE salida_campo_id=@salida;
            INSERT campo.SalidaDestinoE2(salida_campo_id,predio_id,referencia,orden)
              SELECT @salida,D.predioId,D.referencia,CONVERT(INT,J.[key])+1
              FROM OPENJSON(@cJson,'$.datos.destinos') J
              CROSS APPLY OPENJSON(J.value) WITH(predioId BIGINT '$.predioId',referencia NVARCHAR(250) '$.referencia') D;
          END;
          IF JSON_QUERY(@cJson,'$.datos.bienes') IS NOT NULL
          BEGIN
            IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.bienes') WITH(
                bienId BIGINT '$.bienId',suministroId BIGINT '$.suministroId',cantidad DECIMAL(14,3) '$.cantidad') R
              WHERE (R.bienId IS NULL AND R.suministroId IS NULL) OR (R.bienId IS NOT NULL AND R.suministroId IS NOT NULL)
                OR R.cantidad IS NULL OR R.cantidad<=0 OR (R.bienId IS NOT NULL AND R.cantidad<>1))
              THROW 51066,N'La selección de recursos o sus cantidades no es válida.',1;
            IF EXISTS(SELECT COALESCE(bienId,-suministroId) FROM OPENJSON(@cJson,'$.datos.bienes')
                WITH(bienId BIGINT '$.bienId',suministroId BIGINT '$.suministroId')
                GROUP BY COALESCE(bienId,-suministroId) HAVING COUNT(*)>1)
              THROW 51066,N'No repita recursos.',1;
            IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.bienes') WITH(
                bienId BIGINT '$.bienId',suministroId BIGINT '$.suministroId') R
              LEFT JOIN logistica.BienInventario I ON I.bien_inventario_id=R.bienId
              LEFT JOIN logistica.Suministro U ON U.suministro_id=R.suministroId
              WHERE (R.bienId IS NOT NULL AND (I.bien_inventario_id IS NULL OR I.uot_id<>@uot OR I.estado<>1))
                 OR (R.suministroId IS NOT NULL AND (U.suministro_id IS NULL OR U.estado<>1)))
              THROW 51060,N'Hay un recurso fuera del ámbito.',1;
            DELETE FROM campo.SalidaRecursoE2 WHERE salida_campo_id=@salida AND estado='SOLICITADO';
            INSERT campo.SalidaRecursoE2(salida_campo_id,bien_inventario_id,suministro_id,cantidad_solicitada)
              SELECT @salida,R.bienId,R.suministroId,R.cantidad FROM OPENJSON(@cJson,'$.datos.bienes')
                WITH(bienId BIGINT '$.bienId',suministroId BIGINT '$.suministroId',cantidad DECIMAL(14,3) '$.cantidad') R;
          END;
          IF JSON_QUERY(@cJson,'$.datos.participantes') IS NOT NULL
          BEGIN
            IF EXISTS(SELECT empleadoId FROM OPENJSON(@cJson,'$.datos.participantes')
                WITH(empleadoId BIGINT '$.empleadoId') GROUP BY empleadoId HAVING COUNT(*)>1)
              THROW 51066,N'No repita participantes.',1;
            IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.participantes')
                WITH(empleadoId BIGINT '$.empleadoId') P
              WHERE P.empleadoId IS NULL OR NOT EXISTS(SELECT 1 FROM org.Empleado E
                JOIN org.EmpleadoUOT U ON U.empleado_id=E.empleado_id
                WHERE E.empleado_id=P.empleadoId AND E.estado=1 AND U.uot_id=@uot AND U.estado=1
                  AND (U.fecha_desde IS NULL OR U.fecha_desde<=CONVERT(DATE,@fecha))
                  AND (U.fecha_hasta IS NULL OR U.fecha_hasta>=CONVERT(DATE,@fecha))))
              THROW 51060,N'Hay un participante fuera de la UOT.',1;
            DELETE FROM campo.SalidaParticipante WHERE salida_campo_id=@salida AND es_responsable=0;
            INSERT campo.SalidaParticipante(salida_campo_id,empleado_id,es_responsable,funcion,estado)
              SELECT @salida,P.empleadoId,0,NULLIF(TRIM(P.funcion),N''),1
              FROM OPENJSON(@cJson,'$.datos.participantes')
                WITH(empleadoId BIGINT '$.empleadoId',funcion NVARCHAR(120) '$.funcion') P
              WHERE P.empleadoId<>@nEmp;
          END;
          UPDATE campo.SalidaE2 SET nombre=@nombre,estado='SOLICITADA',fecha_solicitud=@fecha,
              fecha_fin_prevista=COALESCE(@fin,fecha_fin_prevista) WHERE salida_campo_id=@salida;
          UPDATE campo.SalidaCampo SET descripcion=@detalle,
              motivo_salida_id=COALESCE(@motivo,motivo_salida_id),
              fecha_hora_programada=COALESCE(@inicio,fecha_hora_programada)
              WHERE salida_campo_id=@salida;
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
         IF @decision='APROBADA'
         BEGIN
           DECLARE @reservaLock INT;
           EXEC @reservaLock=sys.sp_getapplock
              @Resource=N'DESCO:E2:RESERVAS',@LockMode='Exclusive',
              @LockOwner='Transaction',@LockTimeout=5000;
           IF @reservaLock<0 THROW 51064,N'Hay una aprobación concurrente. Reintente.',1;
           IF EXISTS (SELECT 1 FROM campo.SalidaRecursoE2 R
                JOIN logistica.BienInventario B WITH(UPDLOCK,HOLDLOCK)
                  ON B.bien_inventario_id=R.bien_inventario_id
                WHERE R.salida_campo_id=@salida AND R.bien_inventario_id IS NOT NULL
                 AND (B.estado<>1 OR B.uot_id<>@uot OR B.estado_bien<>'DISPONIBLE'
                 OR EXISTS(SELECT 1 FROM logistica.RecursoProgramado RP WITH(UPDLOCK,HOLDLOCK)
                   WHERE RP.bien_inventario_id=R.bien_inventario_id AND RP.estado=1
                   AND RP.estado_proceso IN('PROGRAMADO','EN_EJECUCION'))
                 OR EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 X WITH(UPDLOCK,HOLDLOCK)
                   JOIN campo.SalidaE2 T ON T.salida_campo_id=X.salida_campo_id
                   WHERE X.bien_inventario_id=R.bien_inventario_id AND X.salida_campo_id<>@salida
                     AND X.estado IN('SOLICITADO','ENTREGADO')
                     AND T.estado IN('APROBADA','EN_EJECUCION','EN_RETORNO'))))
              THROW 51067,N'Un bien ya está reservado o prestado para otra salida.',1;
           IF EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 R
               LEFT JOIN logistica.Suministro U ON U.suministro_id=R.suministro_id
               LEFT JOIN logistica.SuministroSaldo S WITH(UPDLOCK,HOLDLOCK) ON S.suministro_id=R.suministro_id
               WHERE R.salida_campo_id=@salida AND R.suministro_id IS NOT NULL
                 AND (U.suministro_id IS NULL OR U.estado<>1 OR S.suministro_id IS NULL
                   OR S.stock_disponible<R.cantidad_solicitada))
             THROW 51067,N'La existencia disponible de un consumible ya no cubre la solicitud.',1;

           UPDATE campo.SalidaE2 SET estado='APROBADA',usuario_aprobador=@nUsuario,
             fecha_aprobacion=@fecha WHERE salida_campo_id=@salida;
           DECLARE c_reservar CURSOR LOCAL FAST_FORWARD FOR
             SELECT R.solicitud_recurso_id,R.bien_inventario_id,R.suministro_id,R.cantidad_solicitada
             FROM campo.SalidaRecursoE2 R WHERE R.salida_campo_id=@salida
               AND R.estado='SOLICITADO' AND R.recurso_programado_id IS NULL
             ORDER BY R.solicitud_recurso_id;
           OPEN c_reservar; FETCH NEXT FROM c_reservar INTO @id,@bien,@suministro,@cantidad;
           WHILE @@FETCH_STATUS=0
           BEGIN
             INSERT logistica.RecursoProgramado(salida_campo_id,bien_inventario_id,suministro_id,
                 cantidad_programada,estado_proceso,estado,usuario_programacion_id)
               VALUES(@salida,@bien,@suministro,@cantidad,'PROGRAMADO',1,@nUsuario);
             SET @recurso=CONVERT(BIGINT,SCOPE_IDENTITY());
             UPDATE campo.SalidaRecursoE2 SET recurso_programado_id=@recurso
               WHERE solicitud_recurso_id=@id AND recurso_programado_id IS NULL;
             IF @@ROWCOUNT<>1 THROW 51067,N'No fue posible reservar uno de los recursos.',1;
             FETCH NEXT FROM c_reservar INTO @id,@bien,@suministro,@cantidad;
           END;
           CLOSE c_reservar; DEALLOCATE c_reservar;
         END;
         ELSE
           UPDATE campo.SalidaE2 SET estado=@decision,usuario_aprobador=@nUsuario,
             fecha_aprobacion=NULL WHERE salida_campo_id=@salida;
         SET @estado=@decision;
       END
       ELSE IF @cAccion='ENTREGAR'
       BEGIN
         IF @estado<>'APROBADA' THROW 51066,N'Apruebe la solicitud antes de entregar recursos.',1;
         DECLARE @entregaLock INT;
         EXEC @entregaLock=sys.sp_getapplock
             @Resource=N'DESCO:E2:RESERVAS',@LockMode='Exclusive',
             @LockOwner='Transaction',@LockTimeout=5000;
         IF @entregaLock<0 THROW 51064,N'Hay una entrega concurrente. Reintente.',1;
         IF EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 R LEFT JOIN logistica.RecursoProgramado P
             ON P.recurso_programado_id=R.recurso_programado_id
             WHERE R.salida_campo_id=@salida AND R.estado='SOLICITADO'
               AND (P.recurso_programado_id IS NULL OR P.estado<>1 OR P.estado_proceso<>'PROGRAMADO'))
           THROW 51067,N'La reserva de recursos no es válida para la entrega.',1;
         DECLARE c_entregar CURSOR LOCAL FAST_FORWARD FOR
          SELECT R.solicitud_recurso_id,R.recurso_programado_id,R.bien_inventario_id,
            R.suministro_id,R.cantidad_solicitada FROM campo.SalidaRecursoE2 R
          WHERE R.salida_campo_id=@salida AND R.estado='SOLICITADO' ORDER BY R.solicitud_recurso_id;
         OPEN c_entregar; FETCH NEXT FROM c_entregar INTO @id,@recurso,@bien,@suministro,@cantidad;
         WHILE @@FETCH_STATUS=0
         BEGIN
           IF @bien IS NOT NULL
           BEGIN
             UPDATE logistica.BienInventario SET estado_bien='ASIGNADO'
               WHERE bien_inventario_id=@bien AND uot_id=@uot AND estado=1 AND estado_bien='DISPONIBLE';
             IF @@ROWCOUNT<>1 THROW 51067,N'El bien ya no está disponible para entrega.',1;
           END;
           UPDATE logistica.RecursoProgramado SET estado_proceso='EN_EJECUCION' WHERE recurso_programado_id=@recurso;
           INSERT logistica.RecursoMovimiento(recurso_programado_id,tipo_movimiento,cantidad,usuario_id,observacion)
            VALUES(@recurso,CASE WHEN @bien IS NULL THEN 'ENTREGA' ELSE 'ASIGNACION' END,
              @cantidad,@nUsuario,N'Entrega física de salida E2');
           UPDATE campo.SalidaRecursoE2 SET estado='ENTREGADO' WHERE solicitud_recurso_id=@id;
           FETCH NEXT FROM c_entregar INTO @id,@recurso,@bien,@suministro,@cantidad;
         END;
         CLOSE c_entregar; DEALLOCATE c_entregar;
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
         IF NOT EXISTS(SELECT 1 FROM campo.TipoVisitaE2 WHERE tipo_visita_id=@tipo AND estado=1
              AND (codigo<>'MATERIA_SECA' OR @convenio IS NOT NULL))
           THROW 51066,N'Tipo de visita no permitido en este contexto.',1;
         IF NOT EXISTS(SELECT 1 FROM prod.PredioAmbito WHERE predio_id=@predio AND uot_id=@uot AND estado=1
             AND ((@convenio IS NULL AND convenio_uot_organizacion_id IS NULL) OR convenio_uot_organizacion_id=@convenio))
           THROW 51060,N'El predio no pertenece al contexto de salida.',1;
         DECLARE @part BIGINT=(SELECT TOP 1 salida_participante_id FROM campo.SalidaParticipante WHERE salida_campo_id=@salida AND empleado_id=@nEmp AND estado=1);
         IF @part IS NULL THROW 51060,N'El usuario no participa en esta salida.',1;
         DECLARE @pos GEOGRAPHY;
         DECLARE @lat DECIMAL(9,6)=TRY_CONVERT(DECIMAL(9,6),JSON_VALUE(@cJson,'$.datos.latitud')),
                 @lon DECIMAL(9,6)=TRY_CONVERT(DECIMAL(9,6),JSON_VALUE(@cJson,'$.datos.longitud')),
                 @gpsAutorizado BIT=COALESCE(TRY_CONVERT(BIT,JSON_VALUE(@cJson,'$.datos.ubicacionAutorizada')),0);
         IF (@lat IS NULL AND @lon IS NOT NULL) OR (@lat IS NOT NULL AND @lon IS NULL)
           OR ((@lat IS NOT NULL OR @lon IS NOT NULL) AND @gpsAutorizado<>1)
           THROW 51066,N'La ubicación GPS requiere coordenadas completas y autorización expresa.',1;
         IF @gpsAutorizado=1 AND (@lat IS NULL OR @lon IS NULL OR @lat NOT BETWEEN -90 AND 90 OR @lon NOT BETWEEN -180 AND 180)
           THROW 51066,N'Las coordenadas GPS no son válidas.',1;
         IF @gpsAutorizado=1 SET @pos=GEOGRAPHY::Point(@lat,@lon,4326);
         ELSE SELECT @pos=U.posicion FROM prod.Predio P JOIN geo.Ubicacion U ON U.ubicacion_id=P.ubicacion_id
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
         DECLARE @recomendaciones NVARCHAR(600)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.recomendaciones')),N''),
                 @tipoActuacion VARCHAR(30);
         SELECT @predio=V.predio_id,@tipoActuacion=CASE T.codigo
           WHEN 'SANIDAD' THEN 'SANIDAD' WHEN 'PECUARIA' THEN 'CRIANZA' ELSE 'SEGUIMIENTO' END
         FROM campo.VisitaTecnica V WITH(UPDLOCK,HOLDLOCK)
         JOIN campo.SalidaVisitaE2 X ON X.visita_tecnica_id=V.visita_tecnica_id
         JOIN campo.TipoVisitaE2 T ON T.tipo_visita_id=X.tipo_visita_id
         JOIN campo.SalidaDestinoE2 D ON D.destino_id=X.destino_id
         JOIN campo.SalidaParticipante P ON P.salida_participante_id=V.salida_participante_id
         WHERE V.visita_tecnica_id=@visita AND D.salida_campo_id=@salida AND V.estado_proceso='INICIADA' AND P.empleado_id=@nEmp;
         IF @predio IS NULL THROW 51066,N'Visita no disponible.',1;
         UPDATE campo.VisitaTecnica SET resumen=@detalle,recomendaciones=@recomendaciones,
           fecha_hora_fin=@fecha,estado_proceso='FINALIZADA' WHERE visita_tecnica_id=@visita;
         INSERT prod.ExpedienteActuacion(predio_id,uot_id,convenio_uot_organizacion_id,tipo,observacion,fecha_hecho,
           usuario_id,salida_campo_id,visita_tecnica_id,correlacion_id)
           VALUES(@predio,@uot,@convenio,@tipoActuacion,
             LEFT(CONCAT(@detalle,CASE WHEN @recomendaciones IS NULL THEN N'' ELSE N' | Recomendaciones: '+@recomendaciones END),1200),
             @fecha,@nUsuario,@salida,@visita,@gCorr);
       END
       ELSE IF @cAccion='RETORNAR'
       BEGIN
         SET @obs=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.observacionGeneral')),N'');
         DECLARE @justificacion NVARCHAR(1200)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.justificacionSinVisita')),N'');
         IF @estado<>'EN_EJECUCION' OR @solicitante<>@nEmp OR @obs IS NULL
            THROW 51066,N'Ingrese una observación general antes de retornar.',1;
         IF EXISTS(SELECT 1 FROM campo.SalidaDestinoE2 D JOIN campo.SalidaVisitaE2 X ON X.destino_id=D.destino_id
                 JOIN campo.VisitaTecnica V ON V.visita_tecnica_id=X.visita_tecnica_id
                 WHERE D.salida_campo_id=@salida AND V.estado_proceso='INICIADA')
           THROW 51066,N'Finalice las visitas abiertas antes del retorno.',1;
         IF @justificacion IS NULL AND EXISTS(SELECT 1 FROM campo.SalidaDestinoE2 D
             WHERE D.salida_campo_id=@salida AND NOT EXISTS(SELECT 1 FROM campo.SalidaVisitaE2 X
               JOIN campo.VisitaTecnica V ON V.visita_tecnica_id=X.visita_tecnica_id
               WHERE X.destino_id=D.destino_id AND V.estado_proceso='FINALIZADA'))
           THROW 51066,N'Justifique los destinos que no cuentan con una visita finalizada.',1;
         IF EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 R WHERE R.salida_campo_id=@salida AND R.estado='ENTREGADO'
           AND NOT EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.bienes') WITH(solicitudRecursoId BIGINT '$.solicitudRecursoId') J
               WHERE J.solicitudRecursoId=R.solicitud_recurso_id)) THROW 51066,N'Declare el estado de cada recurso entregado.',1;
         IF EXISTS(SELECT solicitudRecursoId FROM OPENJSON(@cJson,'$.datos.bienes')
             WITH(solicitudRecursoId BIGINT '$.solicitudRecursoId') GROUP BY solicitudRecursoId HAVING COUNT(*)>1)
           THROW 51066,N'No repita recursos en la devolución.',1;
         IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.bienes') WITH(
              solicitudRecursoId BIGINT '$.solicitudRecursoId',resultado VARCHAR(24) '$.resultado',
              cantidadDevuelta DECIMAL(14,3) '$.cantidadDevuelta') J
            LEFT JOIN campo.SalidaRecursoE2 R ON R.solicitud_recurso_id=J.solicitudRecursoId AND R.salida_campo_id=@salida
            WHERE R.solicitud_recurso_id IS NULL OR R.estado<>'ENTREGADO'
              OR J.resultado NOT IN('CONFORME','DANADO','FALTANTE','CONSUMIDO')
              OR (R.bien_inventario_id IS NOT NULL AND J.resultado='CONSUMIDO')
              OR COALESCE(J.cantidadDevuelta,CASE WHEN J.resultado IN('CONFORME','DANADO') THEN R.cantidad_solicitada ELSE 0 END)<0
              OR COALESCE(J.cantidadDevuelta,CASE WHEN J.resultado IN('CONFORME','DANADO') THEN R.cantidad_solicitada ELSE 0 END)>R.cantidad_solicitada
              OR (R.bien_inventario_id IS NOT NULL AND COALESCE(J.cantidadDevuelta,
                   CASE WHEN J.resultado IN('CONFORME','DANADO') THEN 1 ELSE 0 END)<>
                   CASE WHEN J.resultado IN('CONFORME','DANADO') THEN 1 ELSE 0 END)
              OR (R.suministro_id IS NOT NULL AND J.resultado='CONFORME'
                   AND COALESCE(J.cantidadDevuelta,R.cantidad_solicitada)<>R.cantidad_solicitada)
              OR (R.suministro_id IS NOT NULL AND J.resultado IN('FALTANTE','CONSUMIDO')
                   AND COALESCE(J.cantidadDevuelta,0)>=R.cantidad_solicitada))
           THROW 51066,N'Estado de recurso inválido.',1;
         INSERT campo.SalidaRetornoE2(salida_campo_id,observacion_general,justificacion_sin_visita,usuario_id)
           VALUES(@salida,@obs,@justificacion,@nUsuario);
         UPDATE R SET resultado_declarado=J.resultado,observacion=J.observacion,
           cantidad_devuelta_declarada=COALESCE(J.cantidadDevuelta,
             CASE WHEN J.resultado IN('CONFORME','DANADO') THEN R.cantidad_solicitada ELSE 0 END)
         FROM campo.SalidaRecursoE2 R JOIN OPENJSON(@cJson,'$.datos.bienes')
          WITH(solicitudRecursoId BIGINT '$.solicitudRecursoId',resultado VARCHAR(24) '$.resultado',
            cantidadDevuelta DECIMAL(14,3) '$.cantidadDevuelta',observacion NVARCHAR(500) '$.observacion') J
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
         IF EXISTS(SELECT solicitudRecursoId FROM OPENJSON(@cJson,'$.datos.bienes')
             WITH(solicitudRecursoId BIGINT '$.solicitudRecursoId') GROUP BY solicitudRecursoId HAVING COUNT(*)>1)
           THROW 51066,N'No repita recursos en la inspección.',1;
         IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.bienes') WITH(
              solicitudRecursoId BIGINT '$.solicitudRecursoId',resultado VARCHAR(24) '$.resultado',
              cantidadDevuelta DECIMAL(14,3) '$.cantidadDevuelta') J
          LEFT JOIN campo.SalidaRecursoE2 R ON R.solicitud_recurso_id=J.solicitudRecursoId AND R.salida_campo_id=@salida AND R.estado='ENTREGADO'
          WHERE R.solicitud_recurso_id IS NULL OR J.resultado NOT IN('CONFORME','DANADO','FALTANTE','CONSUMIDO')
            OR (R.bien_inventario_id IS NOT NULL AND J.resultado='CONSUMIDO')
            OR COALESCE(J.cantidadDevuelta,R.cantidad_devuelta_declarada)<0
            OR COALESCE(J.cantidadDevuelta,R.cantidad_devuelta_declarada)>R.cantidad_solicitada
            OR (R.bien_inventario_id IS NOT NULL AND COALESCE(J.cantidadDevuelta,R.cantidad_devuelta_declarada)<>
                 CASE WHEN J.resultado IN('CONFORME','DANADO') THEN 1 ELSE 0 END)
            OR (R.suministro_id IS NOT NULL AND J.resultado='CONFORME'
                 AND COALESCE(J.cantidadDevuelta,R.cantidad_devuelta_declarada)<>R.cantidad_solicitada)
            OR (R.suministro_id IS NOT NULL AND J.resultado IN('FALTANTE','CONSUMIDO')
                 AND COALESCE(J.cantidadDevuelta,R.cantidad_devuelta_declarada)>=R.cantidad_solicitada))
           THROW 51066,N'Inspección inválida.',1;
         INSERT campo.SalidaInspeccionE2(salida_campo_id,observacion_general,usuario_id)
           VALUES(@salida,NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.observacion')),N''),@nUsuario);
         DECLARE c_validar CURSOR LOCAL FAST_FORWARD FOR
          SELECT R.solicitud_recurso_id,R.recurso_programado_id,R.bien_inventario_id,R.suministro_id,
            R.cantidad_solicitada,J.resultado,COALESCE(J.cantidadDevuelta,R.cantidad_devuelta_declarada),J.observacion
          FROM campo.SalidaRecursoE2 R JOIN OPENJSON(@cJson,'$.datos.bienes')
          WITH(solicitudRecursoId BIGINT '$.solicitudRecursoId',resultado VARCHAR(24) '$.resultado',
            cantidadDevuelta DECIMAL(14,3) '$.cantidadDevuelta',observacion NVARCHAR(500) '$.observacion') J
           ON J.solicitudRecursoId=R.solicitud_recurso_id WHERE R.salida_campo_id=@salida AND R.estado='ENTREGADO';
         DECLARE @cantidadSolicitada DECIMAL(14,3),@cantidadDevuelta DECIMAL(14,3),@obsRecurso NVARCHAR(500);
         OPEN c_validar;FETCH NEXT FROM c_validar INTO @id,@recurso,@bien,@suministro,
           @cantidadSolicitada,@estadoBien,@cantidadDevuelta,@obsRecurso;
         WHILE @@FETCH_STATUS=0
         BEGIN
           UPDATE campo.SalidaRecursoE2 SET estado=CASE
                WHEN @estadoBien='CONFORME' OR (@suministro IS NOT NULL AND @estadoBien='CONSUMIDO') THEN 'VALIDADO'
                ELSE 'INCIDENCIA' END,
              resultado_validado=@estadoBien,cantidad_devuelta_validada=@cantidadDevuelta,
              observacion_validacion=@obsRecurso,fecha_validacion=@fecha,usuario_validacion=@nUsuario
              WHERE solicitud_recurso_id=@id;
           IF (@estadoBien='CONFORME' OR (@suministro IS NOT NULL AND @estadoBien IN('FALTANTE','CONSUMIDO')))
              AND @cantidadDevuelta>0
             INSERT logistica.RecursoMovimiento(recurso_programado_id,tipo_movimiento,cantidad,usuario_id,observacion)
               VALUES(@recurso,'DEVOLUCION',@cantidadDevuelta,@nUsuario,N'Devolución física validada E2');
           IF @suministro IS NOT NULL AND @estadoBien='CONSUMIDO'
             INSERT logistica.RecursoMovimiento(recurso_programado_id,tipo_movimiento,cantidad,usuario_id,observacion)
               VALUES(@recurso,'CONSUMO',@cantidadSolicitada-@cantidadDevuelta,@nUsuario,N'Consumo validado en salida E2');
           FETCH NEXT FROM c_validar INTO @id,@recurso,@bien,@suministro,
             @cantidadSolicitada,@estadoBien,@cantidadDevuelta,@obsRecurso;
         END;
         CLOSE c_validar; DEALLOCATE c_validar;
       END
       ELSE IF @cAccion='REGULARIZAR_FIN'
       BEGIN
         SET @fin=TRY_CONVERT(DATETIME2(0),JSON_VALUE(@cJson,'$.datos.fechaFinPrevista'));
         SELECT @inicio=S.fecha_hora_programada FROM campo.SalidaCampo S WHERE S.salida_campo_id=@salida;
         IF @estado<>'EN_RETORNO' OR @fin IS NULL OR @fin<@inicio OR @solicitante<>@nEmp
           THROW 51066,N'Solo el solicitante puede regularizar la fecha prevista antes del cierre.',1;
         UPDATE campo.SalidaE2 SET fecha_fin_prevista=@fin WHERE salida_campo_id=@salida;
       END
       ELSE IF @cAccion='CERRAR'
       BEGIN
         DECLARE @autorizarPendientes BIT=COALESCE(TRY_CONVERT(BIT,JSON_VALUE(@cJson,'$.datos.autorizarPendientes')),0),
                 @motivoExcepcion NVARCHAR(1200)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.motivoExcepcion')),N'');
         IF @estado<>'EN_RETORNO' OR EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 WHERE salida_campo_id=@salida AND estado='ENTREGADO')
           THROW 51066,N'Inspeccione todos los recursos antes de cerrar.',1;
         IF EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 WHERE salida_campo_id=@salida AND estado='INCIDENCIA')
            AND (@autorizarPendientes<>1 OR @motivoExcepcion IS NULL)
           THROW 51066,N'Existen recursos pendientes; regularícelos o autorice y motive expresamente la excepción.',1;
         IF NOT EXISTS(SELECT 1 FROM campo.SalidaRetornoE2 WHERE salida_campo_id=@salida) THROW 51066,N'Retorno pendiente.',1;
         IF NOT EXISTS(SELECT 1 FROM campo.SalidaE2 E JOIN campo.SalidaCampo S
             ON S.salida_campo_id=E.salida_campo_id WHERE E.salida_campo_id=@salida
             AND E.fecha_fin_prevista IS NOT NULL AND S.fecha_hora_retorno_real IS NOT NULL
             AND S.fecha_hora_retorno_real>=S.fecha_hora_salida_real)
             THROW 51066,N'Regularice la fecha final y registre el retorno antes de cerrar.',1;
         UPDATE campo.SalidaE2 SET estado='CERRADA',fecha_cierre=@fecha WHERE salida_campo_id=@salida;
         UPDATE campo.SalidaCampo SET estado_proceso='FINALIZADA' WHERE salida_campo_id=@salida;
         SET @detalle=CASE WHEN @autorizarPendientes=1 THEN N'Cierre excepcional autorizado: '+@motivoExcepcion
              ELSE N'Cierre sin pendientes.' END;
         SET @estado='CERRADA';
       END;
       SET @detalle=CASE WHEN @cAccion='RETORNAR' THEN @obs WHEN @cAccion='DECIDIR' THEN JSON_VALUE(@cJson,'$.datos.motivo')
          WHEN @cAccion='INSPECCIONAR' THEN JSON_VALUE(@cJson,'$.datos.observacion')
          WHEN @cAccion='FINALIZAR_VISITA' THEN @detalle
          WHEN @cAccion='CANCELAR' THEN @detalle
          WHEN @cAccion='CORREGIR' THEN LEFT(CONCAT(N'Nombre anterior: ',@nombreAnterior,N' | Descripción anterior: ',
             COALESCE(@descripcionAnterior,N''),N' | Nombre nuevo: ',@nombre,N' | Descripción nueva: ',COALESCE(@detalle,N'')),1200)
          WHEN @cAccion='REGULARIZAR_FIN' THEN CONCAT(N'Fecha final prevista regularizada: ',CONVERT(NVARCHAR(30),@fin,126))
          WHEN @cAccion='VINCULAR_DESTINO' THEN CONCAT(N'Destino ',@destino,N' vinculado a predio ',@predio)
          WHEN @cAccion='VISITAR' THEN CONCAT(N'Inicio de visita ',@visita,N', destino ',@destino,N', tipo ',@tipo)
          WHEN @cAccion='CERRAR' THEN @detalle
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
