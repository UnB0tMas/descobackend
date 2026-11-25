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
         @destino BIGINT,@reemplazado BIGINT,@tipoMovimiento VARCHAR(20),@principalUot BIGINT;
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
        @tipoMovimiento=UPPER(NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.tipoMovimiento')),''));
 SET @perm=CASE WHEN @cAccion IN ('ENVIAR') THEN 'DOCS_ENVIAR'
     WHEN @cAccion IN ('VER','ABRIR','DESCARGAR') THEN 'DOCS_VER'
     WHEN @cAccion IN ('OBSERVAR','FINALIZAR') THEN 'DOCS_DECIDIR'
     WHEN @cAccion IN ('ANULAR','DESTINATARIOS','UOTS_DESTINO') THEN 'DOCS_ENVIAR'
     WHEN @cAccion IN ('HISTORIAL','LISTAR_ARCHIVOS') THEN 'DOCS_VER'
     WHEN @cAccion LIKE 'TIPO_%' AND @cAccion<>'TIPO_LISTAR' THEN
         CASE @cAccion WHEN 'TIPO_CREAR' THEN 'CATALOGOS_CREAR' WHEN 'TIPO_EDITAR' THEN 'CATALOGOS_EDITAR' ELSE 'CATALOGOS_RETIRAR' END
     WHEN @cAccion='TIPO_LISTAR' THEN 'CATALOGOS_LISTAR'
     ELSE 'DOCS_LISTAR' END;
 IF @cAccion='TIPOS' SET @perm='DOCS_LISTAR';
 EXEC seg.PA_Operacion_Sel_ContextoAutorizado
    @cJson=@cJson,@cCodigoPermiso=@perm,@nUsuarioId=@u OUTPUT,
    @nSesionUsuarioId=@s OUTPUT,@nDispositivoUsuarioId=@disp OUTPUT,
    @nEmpleadoId=@emp OUTPUT,@nModuloId=@mod OUTPUT,
    @gCorrelacionId=@corr OUTPUT,@gSolicitudId=@sol OUTPUT,
    @cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@ok OUTPUT,@cMensaje=@msg OUTPUT;
 IF ISNULL(@ok,0)<>1
 BEGIN SELECT @cMensaje=COALESCE(@msg,N'Sesión no autorizada.'),@cCodigo='DOCS_SIN_PERMISO',@nHttp=403; RETURN; END;
 -- Solo empleados vigentes pueden usar correspondencia; Catálogos permanece independiente.
 IF @cAccion NOT LIKE 'TIPO_%' AND NOT EXISTS(
    SELECT 1 FROM org.Empleado E WHERE E.empleado_id=@emp AND E.estado=1
      AND (E.fecha_cese IS NULL OR E.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME())))
 BEGIN SET @cMensaje=N'El usuario no tiene un empleado activo.';SET @nHttp=403;RETURN;END;
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
 IF @uot IS NULL OR @uot<=0 OR NOT EXISTS(SELECT 1 FROM org.UOT WHERE uot_id=@uot AND estado=1)
 BEGIN SET @cMensaje=N'Seleccione una UOT válida.';RETURN;END;
 -- Verifica además el contexto UOT de la sesión; no basta con pertenecer a otra unidad.
 DECLARE @uotSesion BIGINT,@modoGeneral BIT,@uotPermitida BIT,@mensajeUot NVARCHAR(300);
 EXEC seg.PA_UOT_Sel_ResolverContextoSesion
   @nUsuarioId=@u,@nSesionUsuarioId=@s,@nUotSolicitada=@uot,
   @cCodigoPermiso=@perm,@bRequiereUot=1,@nUotId=@uotSesion OUTPUT,
   @bModoGeneral=@modoGeneral OUTPUT,@bResultado=@uotPermitida OUTPUT,@cMensaje=@mensajeUot OUTPUT;
 IF ISNULL(@uotPermitida,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@u,@uot,@perm)<>1
 BEGIN SET @cMensaje=COALESCE(@mensajeUot,N'No tiene permiso en esta UOT.');SET @cCodigo='DOCS_SIN_PERMISO';SET @nHttp=403;RETURN;END;
 -- La principal real del empleado prevalece sobre accesos administrativos.
 SELECT TOP(1) @principalUot=EU.uot_id
 FROM org.EmpleadoUOT EU JOIN org.UOT T ON T.uot_id=EU.uot_id AND T.estado=1
 WHERE EU.empleado_id=@emp AND EU.estado=1 AND EU.es_principal=1
   AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
   AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
   AND (EU.fecha_cese IS NULL OR EU.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()))
 ORDER BY EU.empleado_uot_id DESC;
 IF @principalUot IS NULL
 BEGIN SET @cCodigo='DOCS_SIN_PRINCIPAL';SET @cMensaje=N'Configure la UOT principal vigente del empleado.';SET @nHttp=409;RETURN;END;
 IF @cAccion='TIPOS'
 BEGIN
  SET @cDatos=(SELECT tipo_documento_id id,codigo,nombre,descripcion FROM doc.TipoDocumento WHERE estado=1 ORDER BY nombre FOR JSON PATH);
  SELECT @bResultado=1,@cCodigo='DOCS_TIPOS_OK',@cMensaje=N'Tipos consultados.',@nHttp=200;RETURN;
 END;
 IF @cAccion='UOTS_DESTINO'
 BEGIN
  -- Solo unidades a las que el emisor pertenece realmente como empleado.
  SET @cDatos=(SELECT T.uot_id uotId,T.nombre FROM org.UOT T
   WHERE T.estado=1 AND EXISTS(SELECT 1 FROM org.EmpleadoUOT EU
    WHERE EU.empleado_id=@emp AND EU.uot_id=T.uot_id AND EU.estado=1
      AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
      AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
      AND (EU.fecha_cese IS NULL OR EU.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME())))
   ORDER BY CASE WHEN T.uot_id=@principalUot THEN 0 ELSE 1 END,T.nombre FOR JSON PATH);
  SELECT @bResultado=1,@cCodigo='DOCS_UOTS_OK',@cMensaje=N'Unidades consultadas.',@nHttp=200;RETURN;
 END;
 IF @cAccion='DESTINATARIOS'
 BEGIN
  SET @destino=COALESCE(@destino,@principalUot);
  IF NOT EXISTS(SELECT 1 FROM org.UOT WHERE uot_id=@destino AND estado=1)
  BEGIN SET @cMensaje=N'Unidad no disponible.';RETURN;END;
  IF NOT EXISTS(SELECT 1 FROM org.EmpleadoUOT EU WHERE EU.empleado_id=@emp
     AND EU.uot_id=@destino AND EU.estado=1
     AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
     AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
     AND (EU.fecha_cese IS NULL OR EU.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME())))
  BEGIN SET @nHttp=403;SET @cMensaje=N'La UOT de destino no está asignada al empleado.';RETURN;END;
  SET @cDatos=(SELECT E.empleado_id empleadoId,U.usuario_id usuarioId,
    U.nombre_usuario usuario,
    TRIM(CONCAT(P.nombres,N' ',P.apellido_paterno,N' ',COALESCE(P.apellido_materno,N''))) nombre,
    @destino uotId,
    CAST(CASE WHEN U.usuario_id IS NOT NULL AND U.usuario_id<>@u
      AND U.estado=1 AND U.estado_cuenta='ACTIVA' THEN 1 ELSE 0 END AS BIT) habilitado
   FROM org.Empleado E JOIN org.Persona P ON P.persona_id=E.empleado_id AND P.estado=1
   JOIN org.EmpleadoUOT ED ON ED.empleado_id=E.empleado_id AND ED.uot_id=@destino
     AND ED.estado=1 AND ED.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
     AND (ED.fecha_hasta IS NULL OR ED.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
     AND (ED.fecha_cese IS NULL OR ED.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()))
   LEFT JOIN seg.Usuario U ON U.persona_id=E.empleado_id AND U.estado=1
   WHERE E.estado=1 AND (E.fecha_cese IS NULL OR E.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()))
     AND (@destino=@principalUot OR EXISTS(
       SELECT 1 FROM org.EmpleadoUOT EO WHERE EO.empleado_id=E.empleado_id
        AND EO.uot_id=@principalUot AND EO.estado=1
        AND EO.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
        AND (EO.fecha_hasta IS NULL OR EO.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
        AND (EO.fecha_cese IS NULL OR EO.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()))))
   ORDER BY P.nombres,P.apellido_paterno,E.empleado_id FOR JSON PATH);
  SELECT @bResultado=1,@cCodigo='DOCS_USUARIOS_OK',@cMensaje=N'Destinatarios consultados.',@nHttp=200;RETURN;
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
   SET @cDatos=(SELECT COUNT_BIG(*) AS noLeidos
     FROM doc.Destinatario R JOIN doc.Documento D ON D.documento_id=R.documento_id
       JOIN doc.Hilo H ON H.hilo_id=D.hilo_id
     WHERE COALESCE(R.uot_id,H.uot_id)=@uot AND R.usuario_id=@u AND R.fecha_visto IS NULL FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  ELSE
  BEGIN
   SET @pagina=CASE WHEN @pagina BETWEEN 1 AND 1000000 THEN @pagina ELSE 1 END;
   SET @tam=CASE WHEN @tam BETWEEN 1 AND 100 THEN @tam ELSE 20 END;
   SET @filtro=CASE WHEN @filtro IN ('RECIBIDOS','ENVIADOS','TODOS') THEN @filtro ELSE 'RECIBIDOS' END;
   -- Consultar la bandeja NO marca vistos. El estado cambia exclusivamente al abrir.
   SET @cDatos=(SELECT @pagina pagina,@tam tamano,
    (SELECT COUNT_BIG(*) FROM doc.Documento D JOIN doc.Hilo H ON H.hilo_id=D.hilo_id
       WHERE (
         (@filtro='RECIBIDOS' AND EXISTS(SELECT 1 FROM doc.Destinatario R WHERE R.documento_id=D.documento_id AND R.usuario_id=@u AND COALESCE(R.uot_id,H.uot_id)=@uot)) OR
         (@filtro='ENVIADOS' AND D.emisor_usuario_id=@u AND COALESCE(D.uot_emisor_id,H.uot_id)=@uot) OR
         (@filtro='TODOS' AND EXISTS(SELECT 1 FROM doc.ParticipanteUOT P WHERE P.hilo_id=H.hilo_id AND P.usuario_id=@u AND P.uot_id=@uot))
       ) AND (@tipoFiltro IS NULL OR D.tipo_documento_id=@tipoFiltro)) total,
    JSON_QUERY((SELECT D.documento_id documentoId,D.hilo_id hiloId,D.asunto,T.nombre tipo,
          EU.nombre_usuario emisor, D.fecha_envio fechaEnvio,H.estado estadoTramite,D.tipo_documento_id tipoDocumentoId,
          COALESCE(D.uot_emisor_id,H.uot_id) uotEmisorId,D.reemplaza_documento_id reemplazaDocumentoId,
          CAST(CASE WHEN D.emisor_usuario_id=@u THEN 1 ELSE 0 END AS BIT) esEmisor,
          CASE WHEN D.emisor_usuario_id=@u THEN CAST(0 AS BIT)
               ELSE CAST(CASE WHEN EXISTS(SELECT 1 FROM doc.Destinatario R WHERE R.documento_id=D.documento_id AND R.usuario_id=@u AND R.fecha_visto IS NULL) THEN 1 ELSE 0 END AS BIT) END noLeido,
          (SELECT COUNT(*) FROM doc.Destinatario DR WHERE DR.documento_id=D.documento_id) cantidadDestinatarios,
          (SELECT COUNT(*) FROM doc.Destinatario DR WHERE DR.documento_id=D.documento_id AND DR.fecha_primera_vista IS NOT NULL) destinatariosAbiertos,
          (SELECT COUNT(*) FROM doc.Destinatario DR WHERE DR.documento_id=D.documento_id AND DR.fecha_entrega IS NOT NULL) destinatariosRecibidos
       FROM doc.Documento D JOIN doc.Hilo H ON H.hilo_id=D.hilo_id
       JOIN doc.TipoDocumento T ON T.tipo_documento_id=D.tipo_documento_id
       JOIN seg.Usuario EU ON EU.usuario_id=D.emisor_usuario_id
       WHERE (
         (@filtro='RECIBIDOS' AND EXISTS(SELECT 1 FROM doc.Destinatario R WHERE R.documento_id=D.documento_id AND R.usuario_id=@u AND COALESCE(R.uot_id,H.uot_id)=@uot)) OR
         (@filtro='ENVIADOS' AND D.emisor_usuario_id=@u AND COALESCE(D.uot_emisor_id,H.uot_id)=@uot) OR
         (@filtro='TODOS' AND EXISTS(SELECT 1 FROM doc.ParticipanteUOT P WHERE P.hilo_id=H.hilo_id AND P.usuario_id=@u AND P.uot_id=@uot))
       ) AND (@tipoFiltro IS NULL OR D.tipo_documento_id=@tipoFiltro)
       ORDER BY D.fecha_envio DESC,D.documento_id DESC
       OFFSET (@pagina-1)*@tam ROWS FETCH NEXT @tam ROWS ONLY FOR JSON PATH)) items
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END;
  SELECT @bResultado=1,@cCodigo='DOCS_BANDEJA_OK',@cMensaje=N'Bandeja consultada.',@nHttp=200;RETURN;
 END;
 IF @cAccion='ENVIAR'
 BEGIN
  IF @clave IS NULL OR @asunto IS NULL OR LEN(@asunto)>240 OR @tipo IS NULL
     OR @cuerpo IS NULL OR LEN(@cuerpo)>3000
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
  -- Nunca eximir al administrador de pertenencia real a ambas UOT.
  IF NOT EXISTS(SELECT 1 FROM org.EmpleadoUOT EU WHERE EU.empleado_id=@emp AND EU.uot_id=@destino
      AND EU.estado=1 AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
      AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
      AND (EU.fecha_cese IS NULL OR EU.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME())))
  BEGIN SET @cMensaje=N'La UOT de destino no está asignada al remitente.';SET @nHttp=403;RETURN;END;
  IF @padre IS NULL SET @tipoMovimiento='ENVIO';
  ELSE IF @reemplazado IS NOT NULL SET @tipoMovimiento='RECTIFICACION';
  ELSE IF @tipoMovimiento IS NULL SET @tipoMovimiento='RESPUESTA';
  ELSE IF @tipoMovimiento NOT IN ('RESPUESTA','REENVIO','DERIVACION')
  BEGIN SET @cMensaje=N'Tipo de movimiento no válido.';RETURN;END;
  DECLARE @receptores TABLE(usuarioId BIGINT PRIMARY KEY);
  IF ISJSON(JSON_QUERY(@cJson,'$.datos.destinatarioIds'))<>1 RETURN;
  IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.destinatarioIds') WHERE [type]<>2 OR TRY_CONVERT(BIGINT,[value]) IS NULL)
  BEGIN SET @cMensaje=N'Destinatarios inválidos.';RETURN;END;
  IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.destinatarioIds') GROUP BY TRY_CONVERT(BIGINT,[value]) HAVING COUNT_BIG(*)>1)
  BEGIN SET @cMensaje=N'Destinatarios duplicados.';RETURN;END;
  INSERT @receptores SELECT TRY_CONVERT(BIGINT,[value]) FROM OPENJSON(@cJson,'$.datos.destinatarioIds');
  IF (SELECT COUNT(*) FROM @receptores) NOT BETWEEN 1 AND 50 RETURN;
  IF EXISTS(SELECT 1 FROM @receptores R WHERE R.usuarioId=@u OR NOT EXISTS(
    SELECT 1 FROM seg.Usuario U JOIN org.Empleado E ON E.empleado_id=U.persona_id AND E.estado=1
    WHERE U.usuario_id=R.usuarioId AND U.estado=1 AND U.estado_cuenta='ACTIVA'
     AND (E.fecha_cese IS NULL OR E.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()))
     AND EXISTS(SELECT 1 FROM org.EmpleadoUOT ED WHERE ED.empleado_id=E.empleado_id AND ED.uot_id=@destino
       AND ED.estado=1 AND ED.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
       AND (ED.fecha_hasta IS NULL OR ED.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
       AND (ED.fecha_cese IS NULL OR ED.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME())))
     AND (@destino=@principalUot OR EXISTS(SELECT 1 FROM org.EmpleadoUOT EO
       WHERE EO.empleado_id=E.empleado_id AND EO.uot_id=@principalUot AND EO.estado=1
       AND EO.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
       AND (EO.fecha_hasta IS NULL OR EO.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
       AND (EO.fecha_cese IS NULL OR EO.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()))))))
  BEGIN SET @cMensaje=N'Uno o más destinatarios no cumplen las asignaciones UOT.';RETURN;END;
  -- Una respuesta formal vuelve exclusivamente a quien asignó la tarea.
  IF @tipoMovimiento='RESPUESTA' AND @padre IS NOT NULL
  BEGIN
    IF (SELECT COUNT(*) FROM @receptores)<>1 OR NOT EXISTS(
        SELECT 1 FROM doc.Documento PD JOIN @receptores R ON R.usuarioId=PD.emisor_usuario_id
        JOIN doc.Destinatario DR ON DR.documento_id=PD.documento_id AND DR.usuario_id=@u
        WHERE PD.documento_id=@padre AND PD.emisor_usuario_id<>@u)
    BEGIN SET @cMensaje=N'La respuesta debe dirigirse a quien le asignó la solicitud.';SET @nHttp=409;RETURN;END;
    IF EXISTS(SELECT 1 FROM doc.AsignacionPendiente AP WHERE AP.hilo_id=@hilo
        AND AP.responsable_usuario_id=@u AND AP.estado='PENDIENTE')
    BEGIN SET @cMensaje=N'Atienda las derivaciones pendientes antes de responder.';SET @nHttp=409;RETURN;END;
    IF EXISTS(SELECT 1 FROM doc.AsignacionPendiente AP WHERE AP.documento_origen_id=@padre
        AND AP.asignado_usuario_id=@u AND AP.estado<>'PENDIENTE')
    BEGIN SET @cMensaje=N'Esta solicitud ya fue respondida.';SET @nHttp=409;RETURN;END;
  END;
  IF @padre IS NOT NULL AND NOT EXISTS(SELECT 1 FROM doc.Documento PD WHERE PD.documento_id=@padre
     AND (PD.emisor_usuario_id=@u OR EXISTS(SELECT 1 FROM doc.Destinatario PR
       WHERE PR.documento_id=PD.documento_id AND PR.usuario_id=@u)))
  BEGIN SET @cMensaje=N'No puede gestionar un documento que no recibió.';SET @nHttp=403;RETURN;END;
  DECLARE @adjuntos TABLE(archivoId BIGINT PRIMARY KEY);
  IF ISJSON(JSON_QUERY(@cJson,'$.datos.archivoIds'))<>1 RETURN;
  IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.archivoIds') WHERE [type]<>2 OR TRY_CONVERT(BIGINT,[value]) IS NULL)
  BEGIN SET @cMensaje=N'Archivos inválidos.';RETURN;END;
  IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.archivoIds') GROUP BY TRY_CONVERT(BIGINT,[value]) HAVING COUNT_BIG(*)>1)
  BEGIN SET @cMensaje=N'Archivos repetidos.';RETURN;END;
  INSERT @adjuntos SELECT TRY_CONVERT(BIGINT,[value]) FROM OPENJSON(@cJson,'$.datos.archivoIds');
  -- Asunto y destinatario son suficientes: cuerpo y adjuntos son opcionales.
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
   INSERT doc.Documento(hilo_id,documento_padre_id,tipo_documento_id,asunto,cuerpo,emisor_usuario_id,clave_idempotencia,uot_emisor_id,reemplaza_documento_id)
     VALUES(@hilo,@padre,@tipo,@asunto,@cuerpo,@u,@clave,@uot,@reemplazado);
   SET @id=SCOPE_IDENTITY();
   INSERT doc.Destinatario(documento_id,usuario_id,uot_id) SELECT @id,usuarioId,@destino FROM @receptores;
   INSERT doc.Participante(hilo_id,usuario_id) SELECT @hilo,@u WHERE NOT EXISTS(SELECT 1 FROM doc.Participante WHERE hilo_id=@hilo AND usuario_id=@u);
   INSERT doc.Participante(hilo_id,usuario_id)
    SELECT @hilo,R.usuarioId FROM @receptores R WHERE NOT EXISTS(SELECT 1 FROM doc.Participante P WHERE P.hilo_id=@hilo AND P.usuario_id=R.usuarioId);
   INSERT doc.ParticipanteUOT(hilo_id,usuario_id,uot_id) SELECT @hilo,@u,@uot
      WHERE NOT EXISTS(SELECT 1 FROM doc.ParticipanteUOT WHERE hilo_id=@hilo AND usuario_id=@u AND uot_id=@uot);
   INSERT doc.ParticipanteUOT(hilo_id,usuario_id,uot_id) SELECT @hilo,R.usuarioId,@destino FROM @receptores R
      WHERE NOT EXISTS(SELECT 1 FROM doc.ParticipanteUOT P WHERE P.hilo_id=@hilo AND P.usuario_id=R.usuarioId AND P.uot_id=@destino);
   INSERT doc.DocumentoArchivo(documento_id,archivo_id) SELECT @id,archivoId FROM @adjuntos;
   -- Rectificar sustituye pendientes anteriores sin borrar el historial.
   IF @tipoMovimiento='RECTIFICACION' AND @padre IS NOT NULL
     UPDATE doc.AsignacionPendiente SET estado='SUSTITUIDA'
       WHERE documento_origen_id=@padre AND estado='PENDIENTE';
   -- Asignaciones formales por receptor; los reenvíos informativos no exigen respuesta.
   IF @tipoMovimiento IN ('ENVIO','DERIVACION','RECTIFICACION')
      INSERT doc.AsignacionPendiente(hilo_id,documento_origen_id,responsable_usuario_id,asignado_usuario_id)
        SELECT @hilo,@id,@u,R.usuarioId FROM @receptores R;
   IF @tipoMovimiento='RESPUESTA' AND @padre IS NOT NULL
   BEGIN
      UPDATE doc.AsignacionPendiente SET estado='RESPONDIDA',respuesta_documento_id=@id,
          fecha_respuesta=SYSUTCDATETIME()
      WHERE documento_origen_id=@padre AND asignado_usuario_id=@u AND estado='PENDIENTE';
      -- Documentos previos a esta migración conservan la compatibilidad histórica.
   END;

   IF @padre IS NOT NULL UPDATE doc.Hilo SET estado='EN_TRAMITE' WHERE hilo_id=@hilo AND estado='OBSERVADO';
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
 IF @cAccion IN ('OBSERVAR','FINALIZAR')
 BEGIN
  -- Solo el responsable del hilo puede observar o dar conformidad.
  IF NOT EXISTS(SELECT 1 FROM doc.Hilo WHERE hilo_id=@hilo AND creado_por_usuario_id=@u AND estado NOT IN('FINALIZADO','ANULADO'))
  BEGIN SET @cMensaje=N'No puede revisar este trámite.';SET @nHttp=403;RETURN;END;
  IF @cAccion='OBSERVAR' AND (@motivoDecision IS NULL OR LEN(@motivoDecision)>400 OR @clave IS NULL)
  BEGIN SET @cMensaje=N'Indique la observación.';RETURN;END;
  -- Genera una respuesta observable a quien respondió directamente al responsable.
  DECLARE @obsPadre BIGINT,@obsDestinatario BIGINT,@obsUot BIGINT,@obsTipo BIGINT,@obsAsunto NVARCHAR(240);
  IF @cAccion='OBSERVAR'
  BEGIN
   IF EXISTS(SELECT 1 FROM doc.Documento WHERE emisor_usuario_id=@u AND clave_idempotencia=@clave AND hilo_id=@hilo)
   BEGIN
    SELECT @id=documento_id FROM doc.Documento WHERE emisor_usuario_id=@u AND clave_idempotencia=@clave AND hilo_id=@hilo;
    SET @cDatos=(SELECT @id documentoId,@hilo hiloId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    SELECT @bResultado=1,@cCodigo='DOCS_OBSERVACION_REPETIDA',@cMensaje=N'Observación registrada.',@nHttp=200;RETURN;
   END;
   SELECT TOP(1) @obsPadre=D.documento_id,@obsDestinatario=D.emisor_usuario_id,
     @obsUot=COALESCE(D.uot_emisor_id,H.uot_id),@obsTipo=D.tipo_documento_id,
     @obsAsunto=LEFT(CONCAT(N'OBS: ',D.asunto),240)
   FROM doc.Documento D JOIN doc.Hilo H ON H.hilo_id=D.hilo_id
   JOIN doc.Destinatario R ON R.documento_id=D.documento_id AND R.usuario_id=@u
   WHERE D.hilo_id=@hilo AND D.emisor_usuario_id<>@u
   ORDER BY D.fecha_envio DESC,D.documento_id DESC;
   IF @obsPadre IS NULL
   BEGIN SET @cMensaje=N'Primero debe recibirse una respuesta para observar el trámite.';SET @nHttp=409;RETURN;END;
   IF EXISTS(SELECT 1 FROM doc.AsignacionPendiente AP WHERE AP.documento_origen_id IN
     (SELECT documento_id FROM doc.Documento WHERE documento_padre_id=@obsPadre AND emisor_usuario_id=@u)
     AND AP.estado='PENDIENTE')
   BEGIN SET @cMensaje=N'Ya existe una observación pendiente para esta respuesta.';SET @nHttp=409;RETURN;END;
  END;
  IF @cAccion='FINALIZAR' AND EXISTS(SELECT 1 FROM doc.AsignacionPendiente
      WHERE hilo_id=@hilo AND estado='PENDIENTE')
  BEGIN SET @cMensaje=N'Existen solicitudes o derivaciones sin respuesta.';SET @nHttp=409;RETURN;END;
  IF @cAccion='FINALIZAR' AND EXISTS(SELECT 1 FROM doc.Hilo WHERE hilo_id=@hilo AND estado='OBSERVADO')
  BEGIN SET @cMensaje=N'Debe atenderse la observación antes de finalizar.';SET @nHttp=409;RETURN;END;
  IF @cAccion='FINALIZAR' AND NOT EXISTS(SELECT 1 FROM doc.Documento WHERE hilo_id=@hilo AND emisor_usuario_id<>@u)
  BEGIN SET @cMensaje=N'Este trámite aún no tiene respuesta.';RETURN;END;
  BEGIN TRY
   BEGIN TRANSACTION;
   UPDATE doc.Hilo WITH(UPDLOCK,HOLDLOCK) SET estado=CASE WHEN @cAccion='OBSERVAR' THEN 'OBSERVADO' ELSE 'FINALIZADO' END,
    fecha_cierre=CASE WHEN @cAccion='FINALIZAR' THEN SYSUTCDATETIME() ELSE NULL END
    WHERE hilo_id=@hilo AND creado_por_usuario_id=@u AND estado NOT IN('FINALIZADO','ANULADO');
   IF @@ROWCOUNT<>1 THROW 51061,N'Trámite no disponible.',1;
   IF @cAccion='OBSERVAR'
   BEGIN
     INSERT doc.Documento(hilo_id,documento_padre_id,tipo_documento_id,asunto,cuerpo,
       emisor_usuario_id,clave_idempotencia,uot_emisor_id)
       VALUES(@hilo,@obsPadre,@obsTipo,@obsAsunto,@motivoDecision,@u,@clave,@uot);
     SET @id=SCOPE_IDENTITY();
     INSERT doc.Destinatario(documento_id,usuario_id,uot_id) VALUES(@id,@obsDestinatario,@obsUot);
     INSERT doc.AsignacionPendiente(hilo_id,documento_origen_id,responsable_usuario_id,asignado_usuario_id)
       VALUES(@hilo,@id,@u,@obsDestinatario);
     INSERT doc.Evento(hilo_id,documento_id,usuario_id,tipo,detalle)
       VALUES(@hilo,@id,@u,'OBSERVACION',@motivoDecision);
   END
   ELSE INSERT doc.Evento(hilo_id,documento_id,usuario_id,tipo,detalle)
       VALUES(@hilo,@id,@u,'CONFORMIDAD',@motivoDecision);
   COMMIT;
   IF @cAccion='OBSERVAR' SET @cDatos=(SELECT @id documentoId,@hilo hiloId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   SELECT @bResultado=1,@cCodigo='DOCS_REVISION_OK',@cMensaje=N'Trámite actualizado.',@nHttp=200;RETURN;
  END TRY
  BEGIN CATCH
   IF @@TRANCOUNT>0 ROLLBACK;
   SELECT @cMensaje=N'No se pudo actualizar el trámite.',@nHttp=409;RETURN;
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
    D.tipo_documento_id tipoDocumentoId,D.emisor_usuario_id emisorUsuarioId,
    EU.nombre_usuario emisor,D.fecha_envio fechaEnvio,
    JSON_QUERY((SELECT R.usuario_id usuarioId,U.nombre_usuario usuario,
            P.nombres+' '+P.apellido_paterno+' '+COALESCE(P.apellido_materno,'') nombre,
            COALESCE(R.uot_id,H.uot_id) uotId,R.fecha_entrega fechaEntrega,R.fecha_visto fechaVista,R.fecha_primera_vista fechaAbierto,
            CASE WHEN R.fecha_primera_vista IS NOT NULL THEN N'Abierto'
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
       JSON_QUERY((SELECT R.usuario_id usuarioId,UR.nombre_usuario usuario,COALESCE(R.uot_id,D.uot_emisor_id) uotId,
         R.fecha_entrega fechaEntrega,R.fecha_visto fechaVista,R.fecha_primera_vista fechaAbierto FROM doc.Destinatario R JOIN seg.Usuario UR ON UR.usuario_id=R.usuario_id
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
