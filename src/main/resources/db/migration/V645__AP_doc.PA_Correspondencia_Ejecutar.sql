IF OBJECT_ID(N'[doc].[PA_Correspondencia_Ejecutar]') IS NOT NULL
    DROP PROCEDURE [doc].[PA_Correspondencia_Ejecutar];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : doc.PA_Correspondencia_Ejecutar
' Descripción            : Gestiona la correspondencia, las bandejas, el seguimiento y las autorizaciones documentarias.
' Aplicativo / Módulo    : DESCO / Gestión documentaria
*******************************************************************************************************/
CREATE PROCEDURE doc.PA_Correspondencia_Ejecutar
    @cAccion VARCHAR(30), @cJson NVARCHAR(MAX),
    @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT, @cCodigo VARCHAR(60) OUTPUT,
    @nHttp SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo completar la operación.',
        @cCodigo='DOCS_ERROR',@nHttp=400;
 IF ISJSON(@cJson)<>1 RETURN;
 DECLARE @u BIGINT,@s BIGINT,@disp BIGINT,@emp BIGINT,@mod INT,
         @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
         @ok BIT,@msg NVARCHAR(300),@perm VARCHAR(40),@uot BIGINT,@id BIGINT,
         @padre BIGINT,@hilo BIGINT,@tipo BIGINT,@asunto NVARCHAR(240),
         @cuerpo NVARCHAR(3000),@clave UNIQUEIDENTIFIER,@pagina INT,@tam INT,@filtro VARCHAR(20),@tipoFiltro BIGINT,@estadoHilo VARCHAR(25),@motivoDecision NVARCHAR(400),
         @destino BIGINT,@reemplazado BIGINT,@tipoMovimiento VARCHAR(20),@principalUot BIGINT,
         @sid UNIQUEIDENTIFIER,@requiereRespuesta BIT=0,@respuestaACreador BIT=0,
         @fechaLimite DATETIME2(0);
 SELECT @uot=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.uotId')),
        @id=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.documentoId')),
        @padre=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.documentoPadreId')),
        @tipo=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.tipoDocumentoId')),
        @asunto=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.asunto'))),''),
        @cuerpo=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.cuerpo'))),''),
        @clave=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
        @pagina=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.pagina')),
        @tam=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.tamano')),
        @filtro=JSON_VALUE(@cJson,'$.datos.bandeja'),
        @tipoFiltro=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.tipoFiltroId')),
        @motivoDecision=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.motivo')),N''),
        @destino=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.destinoUotId')),
        @reemplazado=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.reemplazaDocumentoId')),
        @tipoMovimiento=UPPER(NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.tipoMovimiento')),'')),
        @requiereRespuesta=CASE WHEN JSON_VALUE(@cJson,'$.datos.requiereRespuesta')='true' THEN 1 ELSE 0 END,
        @fechaLimite=TRY_CONVERT(DATETIME2(0),LEFT(JSON_VALUE(@cJson,'$.datos.fechaLimite'),19),126),
        @sid=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.sesionPublicaId'));
 -- Catálogos mantiene sus permisos. La correspondencia es universal para cuentas activas.
 IF @cAccion IN ('TIPO_LISTAR','TIPO_CREAR','TIPO_EDITAR','TIPO_DESHABILITAR')
 BEGIN
    SET @perm=CASE @cAccion WHEN 'TIPO_LISTAR' THEN 'CATALOGOS_LISTAR'
        WHEN 'TIPO_CREAR' THEN 'CATALOGOS_CREAR'
        WHEN 'TIPO_EDITAR' THEN 'CATALOGOS_EDITAR' ELSE 'CATALOGOS_RETIRAR' END;
    EXEC seg.PA_Operacion_Sel_ContextoAutorizado
        @cJson=@cJson,@cCodigoPermiso=@perm,@nUsuarioId=@u OUTPUT,
        @nSesionUsuarioId=@s OUTPUT,@nDispositivoUsuarioId=@disp OUTPUT,
        @nEmpleadoId=@emp OUTPUT,@nModuloId=@mod OUTPUT,
        @gCorrelacionId=@corr OUTPUT,@gSolicitudId=@sol OUTPUT,
        @cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
        @bResultado=@ok OUTPUT,@cMensaje=@msg OUTPUT;
    IF ISNULL(@ok,0)<>1
    BEGIN
        SELECT @cMensaje=N'No tiene acceso a esta opción.',@cCodigo='DOCS_SIN_PERMISO',@nHttp=403;
        RETURN;
    END;
 END
 ELSE
 BEGIN
    -- Sesión, cuenta y empleado vigentes: nunca confiar en el usuario recibido del cliente.
    SELECT TOP(1) @u=U.usuario_id,@s=S.sesion_usuario_id,@emp=E.empleado_id
    FROM seg.SesionUsuario S
    JOIN seg.Usuario U ON U.usuario_id=S.usuario_id
    JOIN org.Empleado E WITH (NOLOCK) ON E.empleado_id=U.persona_id AND E.estado=1
    JOIN org.Persona P WITH (NOLOCK) ON P.persona_id=E.empleado_id AND P.estado=1
    WHERE S.sesion_publica_id=@sid AND S.estado=1 AND S.fecha_revocacion IS NULL
        AND S.fecha_expiracion_renovacion>SYSUTCDATETIME()
        AND S.token_version=U.token_version AND U.estado=1 AND U.estado_cuenta='ACTIVA'
        AND (U.bloqueado_hasta IS NULL OR U.bloqueado_hasta<=SYSUTCDATETIME())
        AND (E.fecha_cese IS NULL OR E.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()));
    IF @u IS NULL
    BEGIN
        SELECT @cMensaje=N'La sesión no está disponible.',@cCodigo='DOCS_SESION_INVALIDA',@nHttp=401;
        RETURN;
    END;
 END;
 IF @cAccion='TIPO_LISTAR'
 BEGIN
    SET @cDatos=(SELECT tipo_documento_id id,codigo,nombre,descripcion,estado
       FROM doc.TipoDocumento ORDER BY nombre FOR JSON PATH);
    SELECT @bResultado=1,@cMensaje=N'Tipos consultados.',@cCodigo='DOCS_TIPOS_OK',@nHttp=200;
    RETURN;
 END;
 IF @cAccion IN ('TIPO_CREAR','TIPO_EDITAR','TIPO_DESHABILITAR')
 BEGIN
    DECLARE @cod VARCHAR(40)=UPPER(NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.codigo'))),'')),
      @nom NVARCHAR(120)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.nombre'))),''),
      @desc NVARCHAR(300)=JSON_VALUE(@cJson,'$.datos.descripcion');
    IF @cAccion='TIPO_CREAR' AND (@cod IS NULL OR @nom IS NULL OR LEN(@cod)>40 OR LEN(@nom)>120) RETURN;
    IF @cAccion='TIPO_EDITAR' AND (@id IS NULL OR @nom IS NULL OR LEN(@nom)>120) RETURN;
    IF @cAccion='TIPO_DESHABILITAR' AND @id IS NULL RETURN;
    IF @cAccion='TIPO_CREAR'
    BEGIN
      IF EXISTS(SELECT 1 FROM doc.TipoDocumento WHERE codigo=@cod)
      BEGIN SET @cMensaje=N'El código ya existe.';SET @nHttp=409;RETURN;END;
      INSERT doc.TipoDocumento(codigo,nombre,descripcion) VALUES(@cod,@nom,@desc);
      SET @id=SCOPE_IDENTITY();
    END
    ELSE IF @cAccion='TIPO_EDITAR'
      UPDATE doc.TipoDocumento SET nombre=@nom,descripcion=@desc WHERE tipo_documento_id=@id AND estado=1;
    ELSE
    BEGIN
      IF EXISTS(SELECT 1 FROM doc.Documento WHERE tipo_documento_id=@id)
      BEGIN SET @cMensaje=N'El tipo ya está en uso y no se puede deshabilitar.'; SET @nHttp=409;RETURN;END;
      UPDATE doc.TipoDocumento SET estado=0 WHERE tipo_documento_id=@id AND estado=1;
    END;
    IF @cAccion<>'TIPO_CREAR' AND @@ROWCOUNT=0 BEGIN SET @cMensaje=N'Tipo no disponible.';SET @nHttp=404;RETURN;END;
    SET @cDatos=(SELECT @id AS id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    SELECT @bResultado=1,@cCodigo='DOCS_TIPO_GUARDADO',@cMensaje=N'Catálogo actualizado.',@nHttp=200;
    RETURN;
 END;
 -- La UOT principal se usa por defecto. Puede elegir otra UOT autorizada de su cuenta.
 SELECT TOP(1) @principalUot=EU.uot_id
 FROM org.EmpleadoUOT EU WITH (NOLOCK)
 JOIN org.UOT T WITH (NOLOCK) ON T.uot_id=EU.uot_id AND T.estado=1
 WHERE EU.empleado_id=@emp AND EU.estado=1 AND EU.es_principal=1
    AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
    AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
    AND (EU.fecha_cese IS NULL OR EU.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()))
 ORDER BY EU.empleado_uot_id DESC;
 IF @principalUot IS NULL
 BEGIN
    SELECT @cMensaje=N'No tiene una unidad principal activa.',@cCodigo='DOCS_SIN_PRINCIPAL',@nHttp=409;
    RETURN;
 END;
 IF @uot IS NULL SET @uot=@principalUot;
 IF NOT EXISTS(
     SELECT 1 FROM seg.UsuarioUOT UU WITH (NOLOCK)
     JOIN org.UOT T WITH (NOLOCK) ON T.uot_id=UU.uot_id AND T.estado=1
     WHERE UU.usuario_id=@u AND UU.uot_id=@uot AND UU.estado=1
         AND UU.fecha_desde<=SYSUTCDATETIME()
         AND (UU.fecha_hasta IS NULL OR UU.fecha_hasta>SYSUTCDATETIME())
 )
 BEGIN
     SELECT @cMensaje=N'No tiene acceso a la unidad seleccionada.',@cCodigo='DOCS_UOT_NO_AUTORIZADA',@nHttp=403;
     RETURN;
 END;
 IF @cAccion='CONTEXTO'
 BEGIN
    SET @cDatos=(SELECT @principalUot uotId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    SELECT @bResultado=1,@cCodigo='DOCS_CONTEXTO_OK',@cMensaje=N'Unidad consultada.',@nHttp=200;
    RETURN;
 END;
 IF @cAccion='TIPOS'
 BEGIN
  SET @cDatos=(SELECT tipo_documento_id id,codigo,nombre,descripcion FROM doc.TipoDocumento WHERE estado=1 ORDER BY nombre FOR JSON PATH);
  SELECT @bResultado=1,@cCodigo='DOCS_TIPOS_OK',@cMensaje=N'Tipos consultados.',@nHttp=200;RETURN;
 END;
 -- Descubrimiento seguro: unidad principal, puente válido o interlocutor directo del hilo.
 IF @cAccion IN ('UOTS_DESTINO','DESTINATARIOS')
 BEGIN
     IF @padre IS NOT NULL
     BEGIN
         SELECT @hilo=D.hilo_id
         FROM doc.Documento D WITH (NOLOCK)
         WHERE D.documento_id=@padre
           AND EXISTS(SELECT 1 FROM doc.Participante P WITH (NOLOCK)
               WHERE P.hilo_id=D.hilo_id AND P.usuario_id=@u);
         IF @hilo IS NULL
         BEGIN
             SELECT @cMensaje=N'No puede consultar los destinatarios de este trámite.',@nHttp=403;
             RETURN;
         END;
     END;
 END;
 IF @cAccion='UOTS_DESTINO'
 BEGIN
     SET @cDatos=(
         SELECT T.uot_id uotId,T.nombre
         FROM org.UOT T WITH (NOLOCK)
         WHERE T.estado=1 AND
         (
             T.uot_id=@uot
             OR EXISTS(
                 SELECT 1 FROM org.EmpleadoUOT EP WITH (NOLOCK)
                 JOIN org.Empleado E WITH (NOLOCK) ON E.empleado_id=EP.empleado_id AND E.estado=1
                 JOIN seg.Usuario U WITH (NOLOCK) ON U.persona_id=E.empleado_id
                     AND U.estado=1 AND U.estado_cuenta='ACTIVA' AND U.usuario_id<>@u
                 JOIN org.EmpleadoUOT EA WITH (NOLOCK) ON EA.empleado_id=E.empleado_id
                     AND EA.uot_id=@uot AND EA.estado=1
                     AND EA.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
                     AND (EA.fecha_hasta IS NULL OR EA.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
                     AND (EA.fecha_cese IS NULL OR EA.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()))
                 WHERE EP.uot_id=T.uot_id AND EP.uot_id<>@uot
                     AND EP.es_principal=1 AND EP.estado=1
                     AND EP.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
                     AND (EP.fecha_hasta IS NULL OR EP.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
                     AND (EP.fecha_cese IS NULL OR EP.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()))
                     AND (E.fecha_cese IS NULL OR E.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()))
             )
             OR (@hilo IS NOT NULL AND EXISTS(
                 SELECT 1 FROM doc.Documento D WITH (NOLOCK)
                 JOIN doc.Destinatario R WITH (NOLOCK) ON R.documento_id=D.documento_id
                 JOIN seg.Usuario U WITH (NOLOCK) ON U.usuario_id=CASE
                     WHEN D.emisor_usuario_id=@u THEN R.usuario_id
                     WHEN R.usuario_id=@u THEN D.emisor_usuario_id END
                     AND U.estado=1 AND U.estado_cuenta='ACTIVA'
                 JOIN org.EmpleadoUOT EP WITH (NOLOCK) ON EP.empleado_id=U.persona_id
                    AND EP.uot_id=T.uot_id AND EP.es_principal=1 AND EP.estado=1
                    AND EP.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
                    AND (EP.fecha_hasta IS NULL OR EP.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
                 WHERE D.hilo_id=@hilo AND (D.emisor_usuario_id=@u OR R.usuario_id=@u)
             ))
         )
         ORDER BY CASE WHEN T.uot_id=@uot THEN 0 ELSE 1 END,T.nombre FOR JSON PATH);
     SELECT @bResultado=1,@cCodigo='DOCS_UOTS_OK',@cMensaje=N'Unidades consultadas.',@nHttp=200;
     RETURN;
 END;
 IF @cAccion='DESTINATARIOS'
 BEGIN
     SET @destino=COALESCE(@destino,@uot);
     IF NOT EXISTS(SELECT 1 FROM org.UOT T WITH (NOLOCK) WHERE T.uot_id=@destino AND T.estado=1)
     BEGIN SELECT @cMensaje=N'Unidad no disponible.',@nHttp=404;RETURN;END;
     SET @cDatos=(SELECT E.empleado_id empleadoId,U.usuario_id usuarioId,
         U.nombre_usuario usuario,
         TRIM(CONCAT(P.nombres,N' ',P.apellido_paterno,N' ',COALESCE(P.apellido_materno,N''))) nombre,
         ED.uot_id uotId,CAST(1 AS BIT) habilitado
         FROM org.Empleado E WITH (NOLOCK)
         JOIN org.Persona P WITH (NOLOCK) ON P.persona_id=E.empleado_id AND P.estado=1
         JOIN org.EmpleadoUOT ED WITH (NOLOCK) ON ED.empleado_id=E.empleado_id AND ED.es_principal=1
             AND ED.estado=1 AND ED.uot_id=@destino
             AND ED.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
             AND (ED.fecha_hasta IS NULL OR ED.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
             AND (ED.fecha_cese IS NULL OR ED.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()))
         JOIN org.UOT T WITH (NOLOCK) ON T.uot_id=ED.uot_id AND T.estado=1
         JOIN seg.Usuario U WITH (NOLOCK) ON U.persona_id=E.empleado_id
             AND U.estado=1 AND U.estado_cuenta='ACTIVA' AND U.usuario_id<>@u
         WHERE E.estado=1 AND (E.fecha_cese IS NULL OR E.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()))
           AND (ED.uot_id=@uot
             OR EXISTS(SELECT 1 FROM org.EmpleadoUOT EA WITH (NOLOCK)
                 WHERE EA.empleado_id=E.empleado_id AND EA.uot_id=@uot AND EA.estado=1
                   AND EA.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
                   AND (EA.fecha_hasta IS NULL OR EA.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
                   AND (EA.fecha_cese IS NULL OR EA.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME())))
             OR (@hilo IS NOT NULL AND EXISTS(
                 SELECT 1 FROM doc.Documento D WITH (NOLOCK)
                 JOIN doc.Destinatario R WITH (NOLOCK) ON R.documento_id=D.documento_id
                 WHERE D.hilo_id=@hilo
                   AND ((D.emisor_usuario_id=@u AND R.usuario_id=U.usuario_id)
                     OR (D.emisor_usuario_id=U.usuario_id AND R.usuario_id=@u)))))
         ORDER BY P.nombres,P.apellido_paterno,E.empleado_id FOR JSON PATH);
     SELECT @bResultado=1,@cCodigo='DOCS_USUARIOS_OK',@cMensaje=N'Destinatarios consultados.',@nHttp=200;
     RETURN;
 END;
 -- Borradores personales: nunca se mezclan con documentos enviados.
 IF @cAccion='BORRADORES'
 BEGIN
     SET @cDatos=(SELECT B.borrador_id borradorId,JSON_QUERY(B.contenido) contenido,
                         B.fecha_actualizacion fechaActualizacion
                  FROM doc.Borrador B WITH (NOLOCK)
                  WHERE B.usuario_id=@u
                  ORDER BY B.fecha_actualizacion DESC,B.borrador_id DESC FOR JSON PATH);
     SELECT @bResultado=1,@cCodigo='DOCS_BORRADORES_OK',@cMensaje=N'Borradores consultados.',@nHttp=200;
     RETURN;
 END;
 IF @cAccion='BORRADOR_GUARDAR'
 BEGIN
     DECLARE @borradorId BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.borradorId')),
             @contenido NVARCHAR(MAX)=JSON_QUERY(@cJson,'$.datos.contenido');
     IF @contenido IS NULL OR LEN(@contenido)>20000
     BEGIN
         SELECT @cMensaje=N'No se pudo guardar el borrador.',@nHttp=400;
         RETURN;
     END;
     IF @borradorId IS NOT NULL AND NOT EXISTS(
         SELECT 1 FROM doc.Borrador B WHERE B.borrador_id=@borradorId AND B.usuario_id=@u)
     BEGIN
         SELECT @cMensaje=N'Borrador no disponible.',@nHttp=404;
         RETURN;
     END;
     IF @borradorId IS NULL
     BEGIN
         INSERT doc.Borrador(usuario_id,contenido) VALUES(@u,@contenido);
         SET @borradorId=SCOPE_IDENTITY();
     END
     ELSE
     BEGIN
         UPDATE doc.Borrador SET contenido=@contenido,fecha_actualizacion=SYSUTCDATETIME()
         WHERE borrador_id=@borradorId AND usuario_id=@u;
     END;
     SET @cDatos=(SELECT @borradorId borradorId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
     SELECT @bResultado=1,@cCodigo='DOCS_BORRADOR_GUARDADO',@cMensaje=N'Borrador guardado.',@nHttp=200;
     RETURN;
 END;
 IF @cAccion='BORRADOR_ELIMINAR'
 BEGIN
     DECLARE @borradorEliminar BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.borradorId'));
     IF @borradorEliminar IS NULL
     BEGIN SELECT @cMensaje=N'Borrador no disponible.',@nHttp=400;RETURN;END;
     DELETE FROM doc.Borrador WHERE borrador_id=@borradorEliminar AND usuario_id=@u;
     SELECT @bResultado=1,@cCodigo='DOCS_BORRADOR_ELIMINADO',@cMensaje=N'Borrador descartado.',@nHttp=200;
     RETURN;
 END;
 IF @cAccion='LISTAR_ARCHIVOS'
 BEGIN
  SET @pagina=CASE WHEN @pagina BETWEEN 1 AND 1000000 THEN @pagina ELSE 1 END;
  SET @tam=CASE WHEN @tam BETWEEN 1 AND 100 THEN @tam ELSE 20 END;
  SET @cDatos=(SELECT @pagina pagina,@tam tamano,
   (SELECT COUNT_BIG(*) FROM doc.DocumentoArchivo DA
    JOIN archivo.Archivo A ON A.archivo_id=DA.archivo_id AND A.estado=1
    JOIN doc.Documento D ON D.documento_id=DA.documento_id
    JOIN doc.Hilo H ON H.hilo_id=D.hilo_id
    WHERE EXISTS(SELECT 1 FROM doc.ParticipanteUOT PU WHERE PU.hilo_id=H.hilo_id
       AND PU.usuario_id=@u AND PU.uot_id=@uot)) total,
   JSON_QUERY((SELECT DA.archivo_id archivoId,DA.documento_id documentoId,
        D.hilo_id hiloId,D.asunto,A.nombre_original nombre,A.mime_type mimeType,
        A.tamano_bytes tamanoBytes,D.fecha_envio fechaEnvio,
        T.nombre tipo,H.estado estadoTramite
    FROM doc.DocumentoArchivo DA
    JOIN doc.Documento D ON D.documento_id=DA.documento_id
    JOIN doc.Hilo H ON H.hilo_id=D.hilo_id
    JOIN archivo.Archivo A ON A.archivo_id=DA.archivo_id AND A.estado=1
    JOIN doc.TipoDocumento T ON T.tipo_documento_id=D.tipo_documento_id
    WHERE EXISTS(SELECT 1 FROM doc.ParticipanteUOT PU WHERE PU.hilo_id=H.hilo_id
       AND PU.usuario_id=@u AND PU.uot_id=@uot)
    ORDER BY D.fecha_envio DESC,DA.archivo_id DESC
    OFFSET (@pagina-1)*@tam ROWS FETCH NEXT @tam ROWS ONLY FOR JSON PATH)) items
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cCodigo='DOCS_ARCHIVOS_OK',@cMensaje=N'Inventario consultado.',@nHttp=200;RETURN;
 END;
 IF @cAccion IN ('LISTAR','CONTADOR')
 BEGIN
     IF @cAccion='CONTADOR'
     BEGIN
         SET @cDatos=(
             SELECT
                 (SELECT COUNT_BIG(1)
                  FROM doc.Destinatario R WITH (NOLOCK)
                  JOIN doc.Documento D WITH (NOLOCK) ON D.documento_id=R.documento_id
                  JOIN doc.Hilo H WITH (NOLOCK) ON H.hilo_id=D.hilo_id
                  WHERE R.usuario_id=@u AND COALESCE(R.uot_id,H.uot_id)=@uot
                    AND R.fecha_visto IS NULL) noLeidos,
                 (SELECT COUNT_BIG(1)
                  FROM doc.AsignacionPendiente AP WITH (NOLOCK)
                  WHERE AP.asignado_usuario_id=@u AND AP.estado='PENDIENTE'
                    AND EXISTS(SELECT 1 FROM doc.ParticipanteUOT PU
                               WHERE PU.hilo_id=AP.hilo_id AND PU.usuario_id=@u AND PU.uot_id=@uot)) pendientes,
                 (SELECT COUNT_BIG(1)
                  FROM doc.Hilo H WITH (NOLOCK)
                  WHERE H.estado='FINALIZADO' AND EXISTS(
                      SELECT 1 FROM doc.ParticipanteUOT PU
                      WHERE PU.hilo_id=H.hilo_id AND PU.usuario_id=@u AND PU.uot_id=@uot)) finalizados,
                 (SELECT COUNT_BIG(1)
                  FROM doc.AsignacionPendiente AP WITH (NOLOCK)
                  JOIN doc.Documento D WITH (NOLOCK) ON D.documento_id=AP.documento_origen_id
                  WHERE AP.asignado_usuario_id=@u AND AP.estado='PENDIENTE'
                    AND D.fecha_limite<SYSUTCDATETIME()
                    AND EXISTS(SELECT 1 FROM doc.ParticipanteUOT PU
                               WHERE PU.hilo_id=AP.hilo_id AND PU.usuario_id=@u AND PU.uot_id=@uot)) vencidos
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
         SELECT @bResultado=1,@cCodigo='DOCS_CONTADOR_OK',@cMensaje=N'Indicadores consultados.',@nHttp=200;
         RETURN;
     END;

     SET @pagina=CASE WHEN @pagina BETWEEN 1 AND 1000000 THEN @pagina ELSE 1 END;
     SET @tam=CASE WHEN @tam BETWEEN 1 AND 100 THEN @tam ELSE 20 END;
     SET @filtro=CASE WHEN @filtro IN ('RECIBIDOS','ENVIADOS','TODOS','PENDIENTES','FINALIZADOS','DOCUMENTOS')
                      THEN @filtro ELSE 'RECIBIDOS' END;
     DECLARE @buscar NVARCHAR(240)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.buscar')),N''),
             @estadoFiltro VARCHAR(40)=NULLIF(UPPER(TRIM(JSON_VALUE(@cJson,'$.datos.estadoFiltro'))),''),
             @destinatario NVARCHAR(120)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.destinatario')),N''),
             @unidad NVARCHAR(120)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.unidad')),N''),
             @desde DATE=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.desde')),
             @hasta DATE=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.hasta'));
     DECLARE @lista TABLE(documentoId BIGINT NOT NULL PRIMARY KEY, hiloId BIGINT NOT NULL);

     -- Enviados conserva cada emisión individual, incluso las respuestas del mismo hilo.
     IF @filtro='ENVIADOS'
     BEGIN
         INSERT @lista(documentoId,hiloId)
         SELECT D.documento_id,D.hilo_id
         FROM doc.Documento D WITH (NOLOCK)
         JOIN doc.Hilo H WITH (NOLOCK) ON H.hilo_id=D.hilo_id
         WHERE D.emisor_usuario_id=@u AND COALESCE(D.uot_emisor_id,H.uot_id)=@uot
           AND EXISTS(SELECT 1 FROM doc.ParticipanteUOT PU
                      WHERE PU.hilo_id=H.hilo_id AND PU.usuario_id=@u AND PU.uot_id=@uot)
           AND (@tipoFiltro IS NULL OR D.tipo_documento_id=@tipoFiltro)
           AND (@desde IS NULL OR D.fecha_envio>=@desde)
           AND (@hasta IS NULL OR D.fecha_envio<DATEADD(DAY,1,@hasta))
           AND (@estadoFiltro IS NULL
                OR (@estadoFiltro='FINALIZADOS' AND H.estado='FINALIZADO')
                OR (@estadoFiltro='OBSERVADOS' AND H.estado='OBSERVADO')
                OR (@estadoFiltro='CON_DOCUMENTOS' AND EXISTS(
                    SELECT 1 FROM doc.DocumentoArchivo DA WITH (NOLOCK) WHERE DA.documento_id=D.documento_id))
                OR (@estadoFiltro='ESPERANDO_RESPUESTA' AND EXISTS(
                    SELECT 1 FROM doc.AsignacionPendiente AP WITH (NOLOCK)
                    WHERE AP.documento_origen_id=D.documento_id AND AP.responsable_usuario_id=@u AND AP.estado='PENDIENTE'))
                OR (@estadoFiltro='EN_ATENCION' AND EXISTS(
                    SELECT 1 FROM doc.Destinatario DR WITH (NOLOCK)
                    WHERE DR.documento_id=D.documento_id AND DR.fecha_atencion IS NOT NULL)))
           AND (@buscar IS NULL OR D.asunto LIKE N'%'+@buscar+N'%'
                OR D.cuerpo LIKE N'%'+@buscar+N'%'
                OR EXISTS(SELECT 1 FROM seg.Usuario US WITH (NOLOCK)
                          WHERE US.usuario_id=D.emisor_usuario_id AND US.nombre_usuario LIKE N'%'+@buscar+N'%')
                OR EXISTS(SELECT 1 FROM doc.DocumentoArchivo DA WITH (NOLOCK)
                          JOIN archivo.Archivo A WITH (NOLOCK) ON A.archivo_id=DA.archivo_id
                          WHERE DA.documento_id=D.documento_id AND A.nombre_original LIKE N'%'+@buscar+N'%'))
           AND (@destinatario IS NULL OR EXISTS(
                SELECT 1 FROM doc.Destinatario DR WITH (NOLOCK)
                JOIN seg.Usuario UR WITH (NOLOCK) ON UR.usuario_id=DR.usuario_id
                JOIN org.Persona P WITH (NOLOCK) ON P.persona_id=UR.persona_id
                WHERE DR.documento_id=D.documento_id
                  AND (UR.nombre_usuario LIKE N'%'+@destinatario+N'%'
                       OR CONCAT(P.nombres,N' ',P.apellido_paterno,N' ',COALESCE(P.apellido_materno,N'')) LIKE N'%'+@destinatario+N'%')))
           AND (@unidad IS NULL OR EXISTS(
                SELECT 1 FROM doc.Destinatario DR WITH (NOLOCK)
                JOIN org.UOT T WITH (NOLOCK) ON T.uot_id=COALESCE(DR.uot_id,H.uot_id)
                WHERE DR.documento_id=D.documento_id AND T.nombre LIKE N'%'+@unidad+N'%'));
     END
     ELSE
     BEGIN
         -- Recibidos: una fila por hilo; último mensaje real, incluso si fue derivado
         -- a otro empleado. No se mezclan hilos y la visibilidad sigue restringida
         -- al participante de su unidad principal.
         INSERT @lista(documentoId,hiloId)
         SELECT Ultimo.documento_id,H.hilo_id
         FROM doc.Hilo H WITH (NOLOCK)
         CROSS APPLY (
             SELECT TOP (1) D.documento_id,D.fecha_envio,D.tipo_documento_id
             FROM doc.Documento D WITH (NOLOCK)
             WHERE D.hilo_id=H.hilo_id
             ORDER BY D.fecha_envio DESC,D.documento_id DESC
         ) Ultimo
         WHERE EXISTS(SELECT 1 FROM doc.ParticipanteUOT PU
                      WHERE PU.hilo_id=H.hilo_id AND PU.usuario_id=@u AND PU.uot_id=@uot)
           AND (@filtro<>'RECIBIDOS' OR EXISTS(
               SELECT 1 FROM doc.Documento M WITH (NOLOCK)
               WHERE M.hilo_id=H.hilo_id AND M.emisor_usuario_id<>@u))
           AND (@filtro<>'PENDIENTES' OR EXISTS(
               SELECT 1 FROM doc.AsignacionPendiente AP WITH (NOLOCK)
               WHERE AP.hilo_id=H.hilo_id AND AP.estado='PENDIENTE'
                 AND (AP.asignado_usuario_id=@u OR AP.responsable_usuario_id=@u)))
           AND (@filtro<>'FINALIZADOS' OR H.estado='FINALIZADO')
           AND (@filtro<>'DOCUMENTOS' OR EXISTS(
               SELECT 1 FROM doc.Documento D WITH (NOLOCK)
               JOIN doc.DocumentoArchivo DA WITH (NOLOCK) ON DA.documento_id=D.documento_id
               JOIN archivo.Archivo A WITH (NOLOCK) ON A.archivo_id=DA.archivo_id AND A.estado=1
               WHERE D.hilo_id=H.hilo_id))
           AND (@tipoFiltro IS NULL OR Ultimo.tipo_documento_id=@tipoFiltro)
           AND (@desde IS NULL OR Ultimo.fecha_envio>=@desde)
           AND (@hasta IS NULL OR Ultimo.fecha_envio<DATEADD(DAY,1,@hasta))
           AND (@estadoFiltro IS NULL
                OR (@estadoFiltro='NO_LEIDOS' AND EXISTS(
                    SELECT 1 FROM doc.Destinatario R WITH (NOLOCK)
                    JOIN doc.Documento D WITH (NOLOCK) ON D.documento_id=R.documento_id
                    WHERE D.hilo_id=H.hilo_id AND R.usuario_id=@u
                      AND COALESCE(R.uot_id,H.uot_id)=@uot AND R.fecha_visto IS NULL))
                OR (@estadoFiltro='EN_ATENCION' AND EXISTS(
                    SELECT 1 FROM doc.Destinatario R WITH (NOLOCK)
                    JOIN doc.Documento D WITH (NOLOCK) ON D.documento_id=R.documento_id
                    WHERE D.hilo_id=H.hilo_id AND R.fecha_atencion IS NOT NULL))
                OR (@estadoFiltro='ESPERANDO_RESPUESTA' AND EXISTS(
                    SELECT 1 FROM doc.AsignacionPendiente AP WITH (NOLOCK)
                    WHERE AP.hilo_id=H.hilo_id AND AP.responsable_usuario_id=@u AND AP.estado='PENDIENTE'))
                OR (@estadoFiltro='OBSERVADOS' AND H.estado='OBSERVADO')
                OR (@estadoFiltro='FINALIZADOS' AND H.estado='FINALIZADO')
                OR (@estadoFiltro='CON_DOCUMENTOS' AND EXISTS(
                    SELECT 1 FROM doc.Documento D WITH (NOLOCK)
                    JOIN doc.DocumentoArchivo DA WITH (NOLOCK) ON DA.documento_id=D.documento_id
                    WHERE D.hilo_id=H.hilo_id)))
           AND (@buscar IS NULL OR H.asunto LIKE N'%'+@buscar+N'%'
                OR EXISTS(SELECT 1 FROM doc.Documento M WITH (NOLOCK)
                          JOIN seg.Usuario US WITH (NOLOCK) ON US.usuario_id=M.emisor_usuario_id
                          WHERE M.hilo_id=H.hilo_id AND (M.asunto LIKE N'%'+@buscar+N'%'
                          OR M.cuerpo LIKE N'%'+@buscar+N'%' OR US.nombre_usuario LIKE N'%'+@buscar+N'%'))
                OR EXISTS(SELECT 1 FROM doc.DocumentoArchivo DA WITH (NOLOCK)
                          JOIN doc.Documento M WITH (NOLOCK) ON M.documento_id=DA.documento_id
                          JOIN archivo.Archivo A WITH (NOLOCK) ON A.archivo_id=DA.archivo_id
                          WHERE M.hilo_id=H.hilo_id AND A.nombre_original LIKE N'%'+@buscar+N'%'))
           AND (@destinatario IS NULL OR EXISTS(
                SELECT 1 FROM doc.Documento M WITH (NOLOCK)
                JOIN doc.Destinatario DR WITH (NOLOCK) ON DR.documento_id=M.documento_id
                JOIN seg.Usuario UR WITH (NOLOCK) ON UR.usuario_id=DR.usuario_id
                JOIN org.Persona P WITH (NOLOCK) ON P.persona_id=UR.persona_id
                WHERE M.hilo_id=H.hilo_id
                  AND (UR.nombre_usuario LIKE N'%'+@destinatario+N'%'
                  OR CONCAT(P.nombres,N' ',P.apellido_paterno,N' ',COALESCE(P.apellido_materno,N'')) LIKE N'%'+@destinatario+N'%')))
           AND (@unidad IS NULL OR EXISTS(
                SELECT 1 FROM doc.Documento M WITH (NOLOCK)
                JOIN doc.Destinatario DR WITH (NOLOCK) ON DR.documento_id=M.documento_id
                JOIN org.UOT T WITH (NOLOCK) ON T.uot_id=COALESCE(DR.uot_id,H.uot_id)
                WHERE M.hilo_id=H.hilo_id AND T.nombre LIKE N'%'+@unidad+N'%'));
     END;

     SET @cDatos=(SELECT @pagina pagina,@tam tamano,
         (SELECT COUNT_BIG(1) FROM @lista) total,
         JSON_QUERY((SELECT D.documento_id documentoId,D.hilo_id hiloId,D.asunto,T.nombre tipo,
                U.nombre_usuario emisor,D.fecha_envio fechaEnvio,H.estado estadoTramite,
                D.tipo_documento_id tipoDocumentoId,D.tipo_movimiento tipoMovimiento,
                D.requiere_respuesta requiereRespuesta,D.fecha_limite fechaLimite,
                CASE WHEN H.estado IN ('FINALIZADO','ANULADO') THEN H.estado
                     WHEN H.estado='OBSERVADO' THEN 'OBSERVADO'
                     WHEN D.tipo_movimiento='REENVIO' THEN 'REENVIADO'
                     WHEN D.tipo_movimiento='RESPUESTA' THEN 'RESPONDIDO'
                     WHEN EXISTS(SELECT 1 FROM doc.Destinatario DR WITH (NOLOCK)
                          WHERE DR.documento_id=D.documento_id AND DR.fecha_atencion IS NOT NULL)
                          THEN 'EN_ATENCION' ELSE 'ENVIADO' END estadoEnvio,
                CAST(CASE WHEN D.emisor_usuario_id=@u THEN 1 ELSE 0 END AS BIT) esEmisor,
                CAST(CASE WHEN @filtro='ENVIADOS' THEN 0
                     WHEN EXISTS(SELECT 1 FROM doc.Destinatario R WITH (NOLOCK)
                          JOIN doc.Documento M WITH (NOLOCK) ON M.documento_id=R.documento_id
                          WHERE M.hilo_id=D.hilo_id AND R.usuario_id=@u
                            AND COALESCE(R.uot_id,H.uot_id)=@uot AND R.fecha_visto IS NULL)
                     THEN 1 ELSE 0 END AS BIT) noLeido,
                CAST(CASE WHEN EXISTS(SELECT 1 FROM doc.AsignacionPendiente AP WITH (NOLOCK)
                          WHERE AP.hilo_id=D.hilo_id AND AP.estado='PENDIENTE'
                            AND (AP.asignado_usuario_id=@u OR AP.responsable_usuario_id=@u))
                     THEN 1 ELSE 0 END AS BIT) tienePendientes,
                CAST(CASE WHEN EXISTS(SELECT 1 FROM doc.Documento M WITH (NOLOCK)
                          JOIN doc.DocumentoArchivo DA WITH (NOLOCK) ON DA.documento_id=M.documento_id
                          WHERE M.hilo_id=D.hilo_id)
                     THEN 1 ELSE 0 END AS BIT) tieneAdjuntos,
                LEFT(COALESCE(D.cuerpo,N''),180) resumen,
                (SELECT COUNT_BIG(1) FROM doc.Destinatario DR WITH (NOLOCK)
                 WHERE DR.documento_id=D.documento_id) cantidadDestinatarios,
                (SELECT COUNT_BIG(1) FROM doc.Destinatario DR WITH (NOLOCK)
                 WHERE DR.documento_id=D.documento_id AND DR.fecha_primera_vista IS NOT NULL) destinatariosAbiertos,
                (SELECT COUNT_BIG(1) FROM doc.Destinatario DR WITH (NOLOCK)
                 WHERE DR.documento_id=D.documento_id AND DR.fecha_entrega IS NOT NULL) destinatariosRecibidos,
                Inicial.documento_id primerDocumentoId,Inicial.asunto asuntoInicial,
                Inicial.cuerpo primerMensaje,Inicial.fecha_envio fechaInicio,
                UI.nombre_usuario emisorInicial,
                (SELECT COUNT_BIG(1) FROM doc.Documento M WITH (NOLOCK)
                 JOIN doc.DocumentoArchivo DA WITH (NOLOCK) ON DA.documento_id=M.documento_id
                 JOIN archivo.Archivo A WITH (NOLOCK) ON A.archivo_id=DA.archivo_id AND A.estado=1
                 WHERE M.hilo_id=D.hilo_id) cantidadArchivos
             FROM @lista L
             JOIN doc.Documento D WITH (NOLOCK) ON D.documento_id=L.documentoId
             JOIN doc.Hilo H WITH (NOLOCK) ON H.hilo_id=D.hilo_id
             JOIN doc.TipoDocumento T WITH (NOLOCK) ON T.tipo_documento_id=D.tipo_documento_id
             JOIN seg.Usuario U WITH (NOLOCK) ON U.usuario_id=D.emisor_usuario_id
             CROSS APPLY (SELECT TOP (1) M.documento_id,M.asunto,M.cuerpo,M.fecha_envio,M.emisor_usuario_id
                          FROM doc.Documento M WITH (NOLOCK) WHERE M.hilo_id=D.hilo_id
                          ORDER BY M.fecha_envio,M.documento_id) Inicial
             JOIN seg.Usuario UI WITH (NOLOCK) ON UI.usuario_id=Inicial.emisor_usuario_id
             ORDER BY D.fecha_envio DESC,D.documento_id DESC
             OFFSET (@pagina-1)*@tam ROWS FETCH NEXT @tam ROWS ONLY
             FOR JSON PATH)) items
         FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
     SELECT @bResultado=1,@cCodigo='DOCS_BANDEJA_OK',@cMensaje=N'Bandeja consultada.',@nHttp=200;
     RETURN;
 END;
 IF @cAccion='ENVIAR'
 BEGIN
  IF @clave IS NULL OR @asunto IS NULL OR LEN(@asunto)>240 OR @tipo IS NULL
     OR LEN(COALESCE(@cuerpo,N''))>3000
     OR NOT EXISTS(SELECT 1 FROM doc.TipoDocumento WHERE tipo_documento_id=@tipo AND estado=1)
  BEGIN SET @cMensaje=N'Complete tipo, asunto y datos de envío.';RETURN;END;
  IF EXISTS(SELECT 1 FROM doc.Documento WHERE emisor_usuario_id=@u AND clave_idempotencia=@clave)
  BEGIN
    SET @id=(SELECT documento_id FROM doc.Documento WHERE emisor_usuario_id=@u AND clave_idempotencia=@clave);
    SET @cDatos=(SELECT @id documentoId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    SELECT @bResultado=1,@cCodigo='DOCS_ENVIO_REPETIDO',@cMensaje=N'El envío ya estaba registrado.',@nHttp=200;RETURN;
  END;
  IF @padre IS NOT NULL
  BEGIN
   SELECT @hilo=H.hilo_id,@estadoHilo=H.estado FROM doc.Documento D JOIN doc.Hilo H ON H.hilo_id=D.hilo_id
    WHERE D.documento_id=@padre
      AND EXISTS(SELECT 1 FROM doc.ParticipanteUOT P WHERE P.hilo_id=H.hilo_id AND P.usuario_id=@u AND P.uot_id=@uot);
   IF @hilo IS NULL BEGIN SET @cMensaje=N'No participa en el expediente de respuesta.';SET @nHttp=404;RETURN;END;
   IF @estadoHilo IN ('FINALIZADO','ANULADO') BEGIN SET @cMensaje=N'El trámite está cerrado.';SET @nHttp=409;RETURN;END;
  END;
  IF @reemplazado IS NOT NULL AND NOT EXISTS(SELECT 1 FROM doc.Documento D
      WHERE D.documento_id=@reemplazado AND D.documento_id=@padre AND D.emisor_usuario_id=@u
        AND D.hilo_id=@hilo)
  BEGIN SET @cMensaje=N'No puede rectificar este documento.';SET @nHttp=403;RETURN;END;
  SET @destino=COALESCE(@destino,@uot);
  IF NOT EXISTS(SELECT 1 FROM org.UOT WHERE uot_id=@destino AND estado=1)
  BEGIN SET @cMensaje=N'Unidad no disponible.';RETURN;END;
  -- El destinatario debe pertenecer a SU UOT principal; el remitente no necesita pertenecer a ella.
  IF @padre IS NULL SET @tipoMovimiento='ENVIO';
  ELSE IF @reemplazado IS NOT NULL SET @tipoMovimiento='RECTIFICACION';
  ELSE IF @tipoMovimiento IS NULL SET @tipoMovimiento='RESPUESTA';
  ELSE IF @tipoMovimiento NOT IN ('RESPUESTA','REENVIO','DERIVACION','OBSERVACION')
  BEGIN SET @cMensaje=N'Tipo de mensaje no válido.';RETURN;END;
  IF @requiereRespuesta=1 AND @fechaLimite IS NOT NULL AND @fechaLimite<=SYSUTCDATETIME()
  BEGIN SET @cMensaje=N'Indique una fecha límite futura.';RETURN;END;
  IF @tipoMovimiento='OBSERVACION'
  BEGIN
      IF @cuerpo IS NULL
      BEGIN SET @cMensaje=N'Escriba la observación antes de enviarla.';RETURN;END;
      SET @requiereRespuesta=1;
  END;
  DECLARE @receptores TABLE(usuarioId BIGINT PRIMARY KEY,uotId BIGINT NOT NULL);
  IF ISJSON(JSON_QUERY(@cJson,'$.datos.destinatarioIds'))<>1 RETURN;
  IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.destinatarioIds')
      WHERE [type]<>2 OR TRY_CONVERT(BIGINT,[value]) IS NULL)
  BEGIN SET @cMensaje=N'Destinatarios inválidos.';RETURN;END;
  IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.destinatarioIds')
      GROUP BY TRY_CONVERT(BIGINT,[value]) HAVING COUNT_BIG(1)>1)
  BEGIN SET @cMensaje=N'Destinatarios duplicados.';RETURN;END;
  INSERT @receptores(usuarioId,uotId)
  SELECT U.usuario_id,EU.uot_id
  FROM OPENJSON(@cJson,'$.datos.destinatarioIds') R
  JOIN seg.Usuario U WITH (NOLOCK) ON U.usuario_id=TRY_CONVERT(BIGINT,R.[value])
      AND U.estado=1 AND U.estado_cuenta='ACTIVA' AND U.usuario_id<>@u
  JOIN org.Empleado E WITH (NOLOCK) ON E.empleado_id=U.persona_id AND E.estado=1
      AND (E.fecha_cese IS NULL OR E.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()))
  JOIN org.EmpleadoUOT EU WITH (NOLOCK) ON EU.empleado_id=E.empleado_id
      AND EU.es_principal=1 AND EU.estado=1
      AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
      AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
      AND (EU.fecha_cese IS NULL OR EU.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()))
  JOIN org.UOT T WITH (NOLOCK) ON T.uot_id=EU.uot_id AND T.estado=1;
  IF (SELECT COUNT_BIG(1) FROM @receptores)<> (
       SELECT COUNT_BIG(1) FROM OPENJSON(@cJson,'$.datos.destinatarioIds'))
     OR (SELECT COUNT_BIG(1) FROM @receptores) NOT BETWEEN 1 AND 50
  BEGIN SET @cMensaje=N'Uno o más destinatarios no están disponibles.';RETURN;END;
  IF @padre IS NOT NULL AND NOT EXISTS(SELECT 1 FROM doc.Documento PD WITH (NOLOCK)
      WHERE PD.documento_id=@padre AND (PD.emisor_usuario_id=@u
          OR EXISTS(SELECT 1 FROM doc.Destinatario PR WITH (NOLOCK)
              WHERE PR.documento_id=@padre AND PR.usuario_id=@u)))
  BEGIN SET @cMensaje=N'No puede gestionar este mensaje.';SET @nHttp=403;RETURN;END;
  -- Una solicitud grupal queda atendida con la primera respuesta válida.
  IF @tipoMovimiento IN ('RESPUESTA','REENVIO') AND @padre IS NOT NULL
      AND EXISTS(SELECT 1 FROM doc.AsignacionPendiente AP WITH (NOLOCK)
          JOIN @receptores R ON R.usuarioId=AP.responsable_usuario_id
          WHERE AP.hilo_id=@hilo AND AP.asignado_usuario_id=@u AND AP.estado='PENDIENTE')
      SET @respuestaACreador=1;
  IF @tipoMovimiento='RESPUESTA' AND @padre IS NOT NULL AND @respuestaACreador=0
      AND NOT EXISTS(SELECT 1 FROM doc.Documento D WITH (NOLOCK)
          JOIN @receptores R ON R.usuarioId=D.emisor_usuario_id
          WHERE D.documento_id=@padre AND D.emisor_usuario_id<>@u)
      AND NOT EXISTS(SELECT 1 FROM doc.Documento D WITH (NOLOCK)
          JOIN doc.Destinatario DR WITH (NOLOCK) ON DR.documento_id=D.documento_id
          JOIN @receptores R ON R.usuarioId=CASE WHEN D.emisor_usuario_id=@u
               THEN DR.usuario_id ELSE D.emisor_usuario_id END
          WHERE D.hilo_id=@hilo AND (D.emisor_usuario_id=@u OR DR.usuario_id=@u))
  BEGIN SET @cMensaje=N'La respuesta debe dirigirse a un interlocutor del trámite.';SET @nHttp=409;RETURN;END;
  IF @tipoMovimiento='OBSERVACION'
  BEGIN
      -- Reenviar la observación a todas las personas originalmente encargadas.
      DECLARE @asignacionObservada BIGINT;
      SELECT TOP(1) @asignacionObservada=AP.documento_origen_id
      FROM doc.AsignacionPendiente AP WITH (NOLOCK)
      WHERE AP.hilo_id=@hilo AND AP.responsable_usuario_id=@u
          AND AP.respuesta_documento_id=@padre AND AP.estado='RESPONDIDA'
      ORDER BY AP.asignacion_id DESC;
      IF @asignacionObservada IS NULL
      BEGIN SET @cMensaje=N'Seleccione una respuesta recibida para observar.';SET @nHttp=409;RETURN;END;
      DELETE FROM @receptores;
      INSERT @receptores(usuarioId,uotId)
      SELECT DISTINCT R.usuario_id,EU.uot_id
      FROM doc.Destinatario R WITH (NOLOCK)
      JOIN seg.Usuario U WITH (NOLOCK) ON U.usuario_id=R.usuario_id AND U.estado=1 AND U.estado_cuenta='ACTIVA'
      JOIN org.EmpleadoUOT EU WITH (NOLOCK) ON EU.empleado_id=U.persona_id AND EU.estado=1
          AND EU.es_principal=1 AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
          AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
      WHERE R.documento_id=@asignacionObservada;
      IF NOT EXISTS(SELECT 1 FROM @receptores)
      BEGIN SET @cMensaje=N'No hay destinatarios disponibles.';RETURN;END;
      SELECT TOP(1) @destino=R.uotId FROM @receptores R ORDER BY R.usuarioId;
  END;
  -- El envío se dirige únicamente a la UOT principal de los destinatarios.
  IF EXISTS(SELECT 1 FROM @receptores R WHERE R.uotId<>@destino)
  BEGIN SET @cMensaje=N'Seleccione destinatarios de la unidad indicada.';SET @nHttp=403;RETURN;END;
  -- Entre UOT solo se permite un receptor. Debe tener acceso vigente a la
  -- UOT principal de quien envía, salvo respuesta entre interlocutores directos del mismo hilo.
  IF @destino<>@uot
  BEGIN
      IF (SELECT COUNT_BIG(1) FROM @receptores)<>1
      BEGIN SET @cMensaje=N'Entre unidades solo puede elegir un destinatario.';SET @nHttp=409;RETURN;END;
      IF EXISTS(SELECT 1 FROM @receptores R
          JOIN seg.Usuario U WITH (NOLOCK) ON U.usuario_id=R.usuarioId
          WHERE NOT EXISTS(
              SELECT 1 FROM org.EmpleadoUOT EU WITH (NOLOCK)
              WHERE EU.empleado_id=U.persona_id AND EU.uot_id=@uot AND EU.estado=1
                AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
                AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
                AND (EU.fecha_cese IS NULL OR EU.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME())))
            AND NOT (@padre IS NOT NULL AND EXISTS(
                SELECT 1 FROM doc.Documento D WITH (NOLOCK)
                JOIN doc.Destinatario DR WITH (NOLOCK) ON DR.documento_id=D.documento_id
                WHERE D.hilo_id=@hilo AND
                    ((D.emisor_usuario_id=@u AND DR.usuario_id=R.usuarioId)
                      OR (D.emisor_usuario_id=R.usuarioId AND DR.usuario_id=@u)))))
      BEGIN
          SELECT @cMensaje=N'El destinatario no tiene acceso a su unidad.',@nHttp=403;
          RETURN;
      END;
  END;
  DECLARE @adjuntos TABLE(archivoId BIGINT PRIMARY KEY);
  IF ISJSON(JSON_QUERY(@cJson,'$.datos.archivoIds'))<>1 RETURN;
  IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.archivoIds') WHERE [type]<>2 OR TRY_CONVERT(BIGINT,[value]) IS NULL)
  BEGIN SET @cMensaje=N'Archivos inválidos.';RETURN;END;
  IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.archivoIds') GROUP BY TRY_CONVERT(BIGINT,[value]) HAVING COUNT_BIG(*)>1)
  BEGIN SET @cMensaje=N'Archivos repetidos.';RETURN;END;
  INSERT @adjuntos SELECT TRY_CONVERT(BIGINT,[value]) FROM OPENJSON(@cJson,'$.datos.archivoIds');
  -- El contenido o al menos un adjunto es necesario; ambos son opcionales individualmente.
  IF @cuerpo IS NULL AND NOT EXISTS(SELECT 1 FROM @adjuntos)
  BEGIN SET @cMensaje=N'Escriba un mensaje o adjunte un archivo.';RETURN;END;
  IF (SELECT COUNT(*) FROM @adjuntos)>10
  BEGIN SET @cMensaje=N'Máximo 10 archivos adjuntos.';RETURN;END;
  IF EXISTS(SELECT 1 FROM @adjuntos A WHERE NOT EXISTS(
    SELECT 1 FROM archivo.Archivo F WHERE F.archivo_id=A.archivoId AND F.usuario_id=@u
     AND F.uot_id=@uot AND F.estado=1 AND F.proveedor_almacenamiento='LOCAL'
     AND F.categoria='CORRESPONDENCIA'
     AND NOT EXISTS(SELECT 1 FROM doc.DocumentoArchivo DA WHERE DA.archivo_id=F.archivo_id)))
  BEGIN SET @cMensaje=N'Los adjuntos deben ser archivos internos propios y no enviados anteriormente.';RETURN;END;
  BEGIN TRY
   BEGIN TRANSACTION;
   IF @padre IS NOT NULL AND NOT EXISTS(SELECT 1 FROM doc.Hilo WITH(UPDLOCK,HOLDLOCK)
      WHERE hilo_id=@hilo AND estado NOT IN ('FINALIZADO','ANULADO'))
      THROW 51060,N'El trámite está finalizado.',1;
   IF @padre IS NULL
   BEGIN
      INSERT doc.Hilo(uot_id,asunto,creado_por_usuario_id) VALUES(@uot,@asunto,@u);
      SET @hilo=SCOPE_IDENTITY();
   END;
   INSERT doc.Documento(hilo_id,documento_padre_id,tipo_documento_id,asunto,cuerpo,emisor_usuario_id,clave_idempotencia,uot_emisor_id,reemplaza_documento_id,tipo_movimiento,requiere_respuesta,fecha_limite)
     VALUES(@hilo,@padre,@tipo,@asunto,@cuerpo,@u,@clave,@uot,@reemplazado,@tipoMovimiento,@requiereRespuesta,@fechaLimite);
   SET @id=SCOPE_IDENTITY();
   INSERT doc.Destinatario(documento_id,usuario_id,uot_id) SELECT @id,usuarioId,uotId FROM @receptores;
   INSERT doc.Participante(hilo_id,usuario_id) SELECT @hilo,@u WHERE NOT EXISTS(SELECT 1 FROM doc.Participante WHERE hilo_id=@hilo AND usuario_id=@u);
   INSERT doc.Participante(hilo_id,usuario_id)
    SELECT @hilo,R.usuarioId FROM @receptores R WHERE NOT EXISTS(SELECT 1 FROM doc.Participante P WHERE P.hilo_id=@hilo AND P.usuario_id=R.usuarioId);
   INSERT doc.ParticipanteUOT(hilo_id,usuario_id,uot_id) SELECT @hilo,@u,@uot
      WHERE NOT EXISTS(SELECT 1 FROM doc.ParticipanteUOT WHERE hilo_id=@hilo AND usuario_id=@u AND uot_id=@uot);
   INSERT doc.ParticipanteUOT(hilo_id,usuario_id,uot_id) SELECT @hilo,R.usuarioId,R.uotId FROM @receptores R
      WHERE NOT EXISTS(SELECT 1 FROM doc.ParticipanteUOT P WHERE P.hilo_id=@hilo AND P.usuario_id=R.usuarioId AND P.uot_id=R.uotId);
   INSERT doc.DocumentoArchivo(documento_id,archivo_id) SELECT @id,archivoId FROM @adjuntos;
   -- Los reenvíos incluyen los adjuntos del mensaje citado sin duplicar el archivo físico.
   IF @tipoMovimiento='REENVIO' AND @padre IS NOT NULL
      INSERT doc.DocumentoArchivo(documento_id,archivo_id)
      SELECT @id,DA.archivo_id FROM doc.DocumentoArchivo DA
      WHERE DA.documento_id=@padre
        AND NOT EXISTS(SELECT 1 FROM @adjuntos A WHERE A.archivoId=DA.archivo_id);
   -- Una sola respuesta atiende a todo el grupo encargado en el envío original.
   IF @respuestaACreador=1
   BEGIN
       DECLARE @origenRespondido BIGINT;
       SELECT TOP(1) @origenRespondido=AP.documento_origen_id
       FROM doc.AsignacionPendiente AP WITH (UPDLOCK,HOLDLOCK)
       JOIN @receptores R ON R.usuarioId=AP.responsable_usuario_id
       WHERE AP.hilo_id=@hilo AND AP.asignado_usuario_id=@u AND AP.estado='PENDIENTE'
       ORDER BY AP.asignacion_id DESC;
       UPDATE AP SET estado='RESPONDIDA',respuesta_documento_id=@id,fecha_respuesta=SYSUTCDATETIME()
       FROM doc.AsignacionPendiente AP
       WHERE AP.hilo_id=@hilo AND AP.documento_origen_id=@origenRespondido AND AP.estado='PENDIENTE';
   END;
   IF @tipoMovimiento='RECTIFICACION' AND @padre IS NOT NULL
       UPDATE doc.AsignacionPendiente SET estado='SUSTITUIDA'
       WHERE documento_origen_id=@padre AND estado='PENDIENTE';
   IF @requiereRespuesta=1 AND @respuestaACreador=0 AND @tipoMovimiento<>'RESPUESTA'
       INSERT doc.AsignacionPendiente(hilo_id,documento_origen_id,responsable_usuario_id,asignado_usuario_id)
       SELECT @hilo,@id,@u,R.usuarioId FROM @receptores R;
   IF @tipoMovimiento='OBSERVACION'
       UPDATE doc.Hilo SET estado='OBSERVADO' WHERE hilo_id=@hilo AND estado NOT IN ('FINALIZADO','ANULADO');
   ELSE IF @respuestaACreador=1 AND EXISTS(
       SELECT 1 FROM doc.AsignacionPendiente AP
       JOIN doc.Documento OD ON OD.documento_id=AP.documento_origen_id
       WHERE AP.hilo_id=@hilo AND AP.respuesta_documento_id=@id
         AND OD.tipo_movimiento='OBSERVACION')
       UPDATE doc.Hilo SET estado='EN_TRAMITE' WHERE hilo_id=@hilo AND estado='OBSERVADO';
   INSERT doc.Evento(hilo_id,documento_id,usuario_id,tipo,detalle)
      VALUES(@hilo,@id,@u,@tipoMovimiento,
         CASE WHEN @destino<>@uot THEN N'Enviado a otra unidad.' ELSE N'Documento enviado.' END);
   COMMIT;
   SET @cDatos=(SELECT @id documentoId,@hilo hiloId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   SELECT @bResultado=1,@cCodigo='DOCS_ENVIADO',@cMensaje=N'Documento enviado.',@nHttp=201;RETURN;
  END TRY
  BEGIN CATCH
   IF @@TRANCOUNT>0 ROLLBACK;
   IF ERROR_NUMBER() IN (2601,2627) AND EXISTS(SELECT 1 FROM doc.Documento WHERE emisor_usuario_id=@u AND clave_idempotencia=@clave)
   BEGIN
      SET @id=(SELECT documento_id FROM doc.Documento WHERE emisor_usuario_id=@u AND clave_idempotencia=@clave);
      SET @cDatos=(SELECT @id documentoId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
      SELECT @bResultado=1,@cCodigo='DOCS_ENVIO_REPETIDO',@cMensaje=N'El envío ya estaba registrado.',@nHttp=200;RETURN;
   END;
   SELECT @cMensaje=N'No pudo registrarse el envío.',@cCodigo='DOCS_ENVIO_ERROR',@nHttp=409;RETURN;
  END CATCH;
 END;
 -- Acciones sobre documentos: el ID y la UOT siempre se validan contra la sesión.
 SELECT @hilo=H.hilo_id FROM doc.Documento D JOIN doc.Hilo H ON H.hilo_id=D.hilo_id
  WHERE D.documento_id=@id
   AND EXISTS(SELECT 1 FROM doc.ParticipanteUOT P WHERE P.hilo_id=H.hilo_id AND P.usuario_id=@u AND P.uot_id=@uot);
 IF @hilo IS NULL BEGIN SET @cMensaje=N'Documento no disponible.';SET @nHttp=404;RETURN;END;
 -- Los avisos se distribuyen solo a participantes registrados de este hilo.
 IF @cAccion='AVISOS'
 BEGIN
     SET @cDatos=(SELECT DISTINCT PU.usuario_id usuarioId
                  FROM doc.ParticipanteUOT PU
                  WHERE PU.hilo_id=@hilo FOR JSON PATH);
     SELECT @bResultado=1,@cCodigo='DOCS_AVISOS_OK',@cMensaje=N'Avisos consultados.',@nHttp=200;
     RETURN;
 END;
 IF @cAccion='ABRIR_HILO'
 BEGIN
     DECLARE @abiertos TABLE(documentoId BIGINT NOT NULL PRIMARY KEY);
     UPDATE R SET fecha_primera_vista=SYSUTCDATETIME(),
                  fecha_visto=COALESCE(R.fecha_visto,SYSUTCDATETIME())
         OUTPUT inserted.documento_id INTO @abiertos(documentoId)
     FROM doc.Destinatario R
     JOIN doc.Documento D ON D.documento_id=R.documento_id
     JOIN doc.Hilo H ON H.hilo_id=D.hilo_id
     WHERE D.hilo_id=@hilo AND R.usuario_id=@u
       AND COALESCE(R.uot_id,H.uot_id)=@uot AND R.fecha_primera_vista IS NULL;
     INSERT doc.Evento(hilo_id,documento_id,usuario_id,tipo,detalle)
     SELECT @hilo,A.documentoId,@u,'PRIMERA_VISTA',N'Mensaje abierto.' FROM @abiertos A;
     SELECT @bResultado=1,@cCodigo='DOCS_HILO_ABIERTO',@cMensaje=N'Conversación revisada.',@nHttp=200;
     RETURN;
 END;
 IF @cAccion='RECORDAR'
 BEGIN
     IF NOT EXISTS(SELECT 1 FROM doc.Documento D WITH (NOLOCK)
                   WHERE D.documento_id=@id AND D.emisor_usuario_id=@u)
         OR EXISTS(SELECT 1 FROM doc.Hilo H WITH (NOLOCK)
                   WHERE H.hilo_id=@hilo AND H.estado IN ('FINALIZADO','ANULADO'))
     BEGIN
         SELECT @cMensaje=N'No puede enviar este recordatorio.',@nHttp=403;
         RETURN;
     END;
     INSERT doc.Recordatorio(documento_id,emisor_usuario_id,destinatario_usuario_id)
     SELECT DISTINCT @id,@u,AP.asignado_usuario_id
     FROM doc.AsignacionPendiente AP
     WHERE AP.documento_origen_id=@id AND AP.responsable_usuario_id=@u
       AND AP.estado='PENDIENTE'
       AND NOT EXISTS(SELECT 1 FROM doc.Recordatorio R
                      WHERE R.documento_id=@id AND R.emisor_usuario_id=@u
                        AND R.destinatario_usuario_id=AP.asignado_usuario_id
                        AND R.fecha_envio>DATEADD(HOUR,-24,SYSUTCDATETIME()));
     IF @@ROWCOUNT=0
     BEGIN
         SELECT @cMensaje=N'No hay recordatorios pendientes o ya se notificó recientemente.',@nHttp=409;
         RETURN;
     END;
     INSERT doc.Evento(hilo_id,documento_id,usuario_id,tipo,detalle)
     VALUES(@hilo,@id,@u,'RECORDATORIO',N'Se recordó la atención pendiente.');
     SELECT @bResultado=1,@cCodigo='DOCS_RECORDATORIO_OK',@cMensaje=N'Recordatorio enviado.',@nHttp=200;
     RETURN;
 END;
 IF @cAccion='ANULAR'
 BEGIN
  IF @motivoDecision IS NULL OR LEN(@motivoDecision)>400 OR NOT EXISTS(SELECT 1 FROM doc.Hilo
       WHERE hilo_id=@hilo AND creado_por_usuario_id=@u AND estado NOT IN('FINALIZADO','ANULADO'))
  BEGIN SET @cMensaje=N'No se puede anular este trámite.';SET @nHttp=403;RETURN;END;
  BEGIN TRY
   BEGIN TRANSACTION;
   UPDATE doc.Hilo WITH(UPDLOCK,HOLDLOCK) SET estado='ANULADO',fecha_cierre=SYSUTCDATETIME(),motivo_anulacion=@motivoDecision
   WHERE hilo_id=@hilo AND creado_por_usuario_id=@u AND estado NOT IN ('FINALIZADO','ANULADO');
   IF @@ROWCOUNT<>1 THROW 51061,N'Trámite no disponible.',1;
   INSERT doc.Evento(hilo_id,documento_id,usuario_id,tipo,detalle)
   VALUES(@hilo,@id,@u,'ANULACION',@motivoDecision);
   COMMIT;
   SELECT @bResultado=1,@cCodigo='DOCS_ANULADO',@cMensaje=N'Trámite anulado.',@nHttp=200;RETURN;
  END TRY
  BEGIN CATCH
   IF @@TRANCOUNT>0 ROLLBACK;
   SELECT @cMensaje=N'No se pudo anular el trámite.',@nHttp=409;RETURN;
  END CATCH;
 END;
 IF @cAccion='OBSERVAR'
 BEGIN
    SELECT @cMensaje=N'Escriba y envíe la observación para registrarla.',@cCodigo='DOCS_OBSERVACION_ENVIO',@nHttp=409;
    RETURN;
 END;
 IF @cAccion='FINALIZAR'
 BEGIN
    IF NOT EXISTS(SELECT 1 FROM doc.Hilo H
        WHERE H.hilo_id=@hilo AND H.creado_por_usuario_id=@u AND H.estado NOT IN('FINALIZADO','ANULADO'))
    BEGIN SET @cMensaje=N'No puede finalizar este trámite.';SET @nHttp=403;RETURN;END;
    BEGIN TRY
        BEGIN TRANSACTION;
        -- Una respuesta es suficiente para el autor del hilo, aunque existan
        -- delegaciones internas o destinatarios adicionales aún pendientes.
        IF EXISTS(SELECT 1 FROM doc.AsignacionPendiente AP WITH (UPDLOCK,HOLDLOCK)
            JOIN doc.Documento OD ON OD.documento_id=AP.documento_origen_id
            WHERE AP.hilo_id=@hilo AND AP.responsable_usuario_id=@u
              AND OD.documento_padre_id IS NULL)
           AND NOT EXISTS(SELECT 1 FROM doc.AsignacionPendiente AP WITH (UPDLOCK,HOLDLOCK)
            JOIN doc.Documento OD ON OD.documento_id=AP.documento_origen_id
            WHERE AP.hilo_id=@hilo AND AP.responsable_usuario_id=@u
              AND OD.documento_padre_id IS NULL AND AP.estado='RESPONDIDA')
            THROW 51061,N'Aún no ha recibido una respuesta.',1;
        IF EXISTS(SELECT 1 FROM doc.Hilo WITH (UPDLOCK,HOLDLOCK)
            WHERE hilo_id=@hilo AND estado='OBSERVADO')
            THROW 51062,N'La observación debe atenderse.',1;
        UPDATE doc.Hilo WITH (UPDLOCK,HOLDLOCK)
        SET estado='FINALIZADO',fecha_cierre=SYSUTCDATETIME()
        WHERE hilo_id=@hilo AND creado_por_usuario_id=@u AND estado NOT IN('FINALIZADO','ANULADO');
        IF @@ROWCOUNT<>1 THROW 51063,N'El trámite no está disponible.',1;
        -- Conserva todo el historial; impide nuevas tareas aunque no todos respondieran.
        UPDATE doc.AsignacionPendiente SET estado='SUSTITUIDA'
        WHERE hilo_id=@hilo AND estado='PENDIENTE';
        INSERT doc.Evento(hilo_id,documento_id,usuario_id,tipo,detalle)
        VALUES(@hilo,@id,@u,'CONFORMIDAD',@motivoDecision);
        COMMIT;
        SELECT @bResultado=1,@cCodigo='DOCS_FINALIZADO',@cMensaje=N'Trámite finalizado.',@nHttp=200;
        RETURN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        SELECT @cMensaje=N'Hay respuestas u observaciones pendientes.',@nHttp=409;
        RETURN;
    END CATCH;
 END;
 IF @cAccion='CONFORMAR'
 BEGIN
    -- La conformidad intermedia conserva el hilo abierto para responder al iniciador.
    IF NOT EXISTS(SELECT 1 FROM doc.AsignacionPendiente AP
        WHERE AP.hilo_id=@hilo AND AP.responsable_usuario_id=@u
            AND AP.respuesta_documento_id=@id AND AP.estado='RESPONDIDA')
    BEGIN SELECT @cMensaje=N'Esta respuesta no requiere su conformidad.',@nHttp=403;RETURN;END;
    IF NOT EXISTS(SELECT 1 FROM doc.Evento WHERE hilo_id=@hilo AND documento_id=@id
        AND usuario_id=@u AND tipo='CONFORMIDAD_INTERMEDIA')
        INSERT doc.Evento(hilo_id,documento_id,usuario_id,tipo,detalle)
        VALUES(@hilo,@id,@u,'CONFORMIDAD_INTERMEDIA',N'Respuesta vista y conforme.');
    SELECT @bResultado=1,@cCodigo='DOCS_CONFORME',@cMensaje=N'Respuesta conforme.',@nHttp=200;
    RETURN;
 END;
 IF @cAccion='ATENDER'
 BEGIN
    IF NOT EXISTS(SELECT 1 FROM doc.Destinatario WHERE documento_id=@id AND usuario_id=@u)
    BEGIN SELECT @cMensaje=N'Este mensaje no está dirigido a usted.',@nHttp=403;RETURN;END;
    IF EXISTS(SELECT 1 FROM doc.Hilo WHERE hilo_id=@hilo AND estado IN ('FINALIZADO','ANULADO'))
    BEGIN SELECT @cMensaje=N'El trámite está cerrado.',@nHttp=409;RETURN;END;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE doc.Destinatario WITH (UPDLOCK,ROWLOCK)
        SET fecha_primera_vista=COALESCE(fecha_primera_vista,SYSUTCDATETIME()),
            fecha_visto=COALESCE(fecha_visto,SYSUTCDATETIME()),
            fecha_atencion=COALESCE(fecha_atencion,SYSUTCDATETIME())
        WHERE documento_id=@id AND usuario_id=@u AND fecha_atencion IS NULL
            AND EXISTS(SELECT 1 FROM doc.Hilo WHERE hilo_id=@hilo AND estado NOT IN('FINALIZADO','ANULADO'));
        IF @@ROWCOUNT=1
            INSERT doc.Evento(hilo_id,documento_id,usuario_id,tipo,detalle)
            VALUES(@hilo,@id,@u,'ATENCION',N'El destinatario inició la atención.');
        COMMIT;
        SELECT @bResultado=1,@cCodigo='DOCS_EN_ATENCION',@cMensaje=N'En atención.',@nHttp=200;
        RETURN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        SELECT @cMensaje=N'No fue posible actualizar el estado.',@nHttp=409;
        RETURN;
    END CATCH;
 END;
 IF @cAccion='ABRIR'
 BEGIN
  UPDATE doc.Destinatario SET fecha_primera_vista=SYSUTCDATETIME(),fecha_visto=COALESCE(fecha_visto,SYSUTCDATETIME())
   WHERE documento_id=@id AND usuario_id=@u AND fecha_primera_vista IS NULL;
  IF @@ROWCOUNT>0 INSERT doc.Evento(hilo_id,documento_id,usuario_id,tipo,detalle)
    VALUES(@hilo,@id,@u,'PRIMERA_VISTA',N'Destinatario abrió el documento.');
  SELECT @bResultado=1,@cCodigo='DOCS_ABIERTO',@cMensaje=N'Documento revisado.',@nHttp=200;RETURN;
 END;
 IF @cAccion='DESCARGAR'
 BEGIN
  DECLARE @archivoId BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.archivoId'));
  IF NOT EXISTS(SELECT 1 FROM doc.DocumentoArchivo WHERE documento_id=@id AND archivo_id=@archivoId)
  BEGIN SET @nHttp=404;SET @cMensaje=N'Adjunto no disponible.';RETURN;END;
  UPDATE doc.Destinatario SET fecha_primera_vista=COALESCE(fecha_primera_vista,SYSUTCDATETIME()),
    fecha_visto=COALESCE(fecha_visto,SYSUTCDATETIME())
    WHERE documento_id=@id AND usuario_id=@u;
  INSERT doc.Evento(hilo_id,documento_id,usuario_id,tipo,detalle)
     VALUES(@hilo,@id,@u,'DESCARGA',N'Adjunto consultado.');
  SELECT @bResultado=1,@cCodigo='DOCS_DESCARGA',@cMensaje=N'Acceso autorizado.',@nHttp=200;RETURN;
 END;
 IF @cAccion='VER'
 BEGIN
   SET @cDatos=(SELECT D.documento_id documentoId,D.hilo_id hiloId,H.uot_id uotId,
    D.documento_padre_id documentoPadreId,D.reemplaza_documento_id reemplazaDocumentoId,
    COALESCE(D.uot_emisor_id,H.uot_id) uotEmisorId,D.asunto,D.cuerpo,T.nombre tipo,
    H.estado estadoTramite,H.creado_por_usuario_id responsableUsuarioId,H.fecha_cierre fechaCierre,H.motivo_anulacion motivoAnulacion,
    CAST(CASE WHEN EXISTS(SELECT 1 FROM doc.AsignacionPendiente AP
        WHERE AP.hilo_id=H.hilo_id AND AP.responsable_usuario_id=@u
            AND AP.respuesta_documento_id=D.documento_id AND AP.estado='RESPONDIDA')
        THEN 1 ELSE 0 END AS BIT) puedeConformar,
    D.tipo_documento_id tipoDocumentoId,D.emisor_usuario_id emisorUsuarioId,
    D.tipo_movimiento tipoMovimiento,D.requiere_respuesta requiereRespuesta,
    EU.nombre_usuario emisor,D.fecha_envio fechaEnvio,
    JSON_QUERY((SELECT R.usuario_id usuarioId,U.nombre_usuario usuario,
            P.nombres+' '+P.apellido_paterno+' '+COALESCE(P.apellido_materno,'') nombre,
            COALESCE(R.uot_id,H.uot_id) uotId,R.fecha_entrega fechaEntrega,R.fecha_visto fechaVista,R.fecha_primera_vista fechaAbierto,
            R.fecha_atencion fechaAtencion,
            CASE WHEN R.fecha_atencion IS NOT NULL THEN N'En atención' WHEN R.fecha_primera_vista IS NOT NULL THEN N'Leído'
             WHEN R.fecha_visto IS NOT NULL THEN N'Visto' ELSE N'Recibido' END estado
            FROM doc.Destinatario R JOIN seg.Usuario U ON U.usuario_id=R.usuario_id
            JOIN org.Persona P ON P.persona_id=U.persona_id
            WHERE R.documento_id=D.documento_id ORDER BY R.usuario_id FOR JSON PATH)) destinatarios,
    JSON_QUERY((SELECT DA.archivo_id archivoId,A.nombre_original nombre,A.mime_type mimeType,
          A.tamano_bytes tamanoBytes FROM doc.DocumentoArchivo DA JOIN archivo.Archivo A ON A.archivo_id=DA.archivo_id
          WHERE DA.documento_id=D.documento_id ORDER BY DA.archivo_id FOR JSON PATH)) adjuntos
    FROM doc.Documento D JOIN doc.Hilo H ON H.hilo_id=D.hilo_id
     JOIN doc.TipoDocumento T ON T.tipo_documento_id=D.tipo_documento_id
     JOIN seg.Usuario EU ON EU.usuario_id=D.emisor_usuario_id
    WHERE D.documento_id=@id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   SELECT @bResultado=1,@cCodigo='DOCS_DETALLE_OK',@cMensaje=N'Detalle consultado.',@nHttp=200;RETURN;
 END;
 IF @cAccion='HISTORIAL'
 BEGIN
  SET @cDatos=(SELECT @hilo hiloId,
      (SELECT asunto FROM doc.Hilo WHERE hilo_id=@hilo) asunto,
      (SELECT estado FROM doc.Hilo WHERE hilo_id=@hilo) estadoTramite,
      (SELECT creado_por_usuario_id FROM doc.Hilo WHERE hilo_id=@hilo) responsableUsuarioId,
      (SELECT fecha_cierre FROM doc.Hilo WHERE hilo_id=@hilo) fechaCierre,
      (SELECT motivo_anulacion FROM doc.Hilo WHERE hilo_id=@hilo) motivoAnulacion,
     JSON_QUERY((SELECT D.documento_id documentoId,D.documento_padre_id documentoPadreId,
       D.reemplaza_documento_id reemplazaDocumentoId,COALESCE(D.uot_emisor_id,H.uot_id) uotEmisorId,
       D.asunto,D.cuerpo,T.nombre tipo,U.nombre_usuario emisor,D.fecha_envio fechaEnvio,
       D.emisor_usuario_id emisorUsuarioId,
       D.tipo_movimiento tipoMovimiento,D.requiere_respuesta requiereRespuesta,D.fecha_limite fechaLimite,
       CAST(CASE WHEN EXISTS(SELECT 1 FROM doc.AsignacionPendiente AP WITH (NOLOCK)
           WHERE AP.hilo_id=D.hilo_id AND AP.responsable_usuario_id=@u
             AND AP.respuesta_documento_id=D.documento_id AND AP.estado='RESPONDIDA')
           THEN 1 ELSE 0 END AS BIT) puedeConformar,
       JSON_QUERY((SELECT DA.archivo_id archivoId,A.nombre_original nombre,A.mime_type mimeType,A.tamano_bytes tamanoBytes
         FROM doc.DocumentoArchivo DA JOIN archivo.Archivo A ON A.archivo_id=DA.archivo_id AND A.estado=1
         WHERE DA.documento_id=D.documento_id ORDER BY DA.archivo_id FOR JSON PATH)) adjuntos,
       JSON_QUERY((SELECT R.usuario_id usuarioId,UR.nombre_usuario usuario,COALESCE(R.uot_id,D.uot_emisor_id) uotId,
         R.fecha_entrega fechaEntrega,R.fecha_visto fechaVista,R.fecha_primera_vista fechaAbierto,
         R.fecha_atencion fechaAtencion FROM doc.Destinatario R JOIN seg.Usuario UR ON UR.usuario_id=R.usuario_id
         WHERE R.documento_id=D.documento_id FOR JSON PATH)) destinatarios
       FROM doc.Documento D JOIN doc.Hilo H ON H.hilo_id=D.hilo_id
       JOIN doc.TipoDocumento T ON T.tipo_documento_id=D.tipo_documento_id
        JOIN seg.Usuario U ON U.usuario_id=D.emisor_usuario_id
       WHERE D.hilo_id=@hilo ORDER BY D.fecha_envio,D.documento_id FOR JSON PATH)) documentos,
     JSON_QUERY((SELECT E.evento_id eventoId,E.documento_id documentoId,E.tipo,E.detalle,
        U.nombre_usuario usuario,E.fecha_evento fecha
        FROM doc.Evento E JOIN seg.Usuario U ON U.usuario_id=E.usuario_id
        WHERE E.hilo_id=@hilo ORDER BY E.fecha_evento,E.evento_id FOR JSON PATH)) eventos,
     JSON_QUERY((SELECT P.usuario_id usuarioId,U.nombre_usuario usuario FROM doc.Participante P
        JOIN seg.Usuario U ON U.usuario_id=P.usuario_id WHERE P.hilo_id=@hilo ORDER BY P.fecha_incorporacion FOR JSON PATH)) participantes
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cCodigo='DOCS_HISTORIAL_OK',@cMensaje=N'Seguimiento consultado.',@nHttp=200;RETURN;
 END;
 SELECT @cMensaje=N'Acción no soportada.',@nHttp=400;
END;
GO
