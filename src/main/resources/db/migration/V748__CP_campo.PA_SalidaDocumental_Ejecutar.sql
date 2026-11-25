IF OBJECT_ID(N'[campo].[PA_SalidaDocumental_Ejecutar]', N'P') IS NOT NULL
    DROP PROCEDURE [campo].[PA_SalidaDocumental_Ejecutar];
GO

-- Coordina E2 y la correspondencia real en una sola transacción SQL Server.
CREATE PROCEDURE campo.PA_SalidaDocumental_Ejecutar
    @cAccion VARCHAR(32),
    @cJson NVARCHAR(MAX),
    @cDatos NVARCHAR(MAX) OUTPUT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60) OUTPUT,
    @nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SELECT @cDatos=NULL, @bResultado=0, @cMensaje=N'No se pudo completar la operación.',
           @cCodigoRespuesta='SALIDA_DOC_ERROR', @nHttpRespuesta=400;

    IF ISJSON(@cJson)<>1 OR @cAccion NOT IN
       ('CONTEXTO','RESPONSABLES','GUARDAR_RESPONSABLE','SOLICITAR','ENVIAR_BORRADOR','CORREGIR','DECIDIR','CANCELAR','VINCULO','DOCUMENTO')
        RETURN;

    DECLARE @usuario BIGINT, @sesion BIGINT, @dispositivo BIGINT, @empleado BIGINT, @modulo INT,
            @correlacion UNIQUEIDENTIFIER, @solicitud UNIQUEIDENTIFIER, @ip VARCHAR(64),
            @endpoint NVARCHAR(250), @autorizado BIT, @mensajeAuth NVARCHAR(300),
            @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
            @salida BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.salidaId')),
            @documento BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.documentoId')),
            @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
            @permiso VARCHAR(40), @aprobador BIGINT, @solicitanteUsuario BIGINT,
            @tipoDocumento BIGINT, @documentoOrigen BIGINT, @hilo BIGINT,
            @texto NVARCHAR(3000), @asunto NVARCHAR(240), @modo VARCHAR(20),
            @docJson NVARCHAR(MAX), @docDatos NVARCHAR(MAX), @e2Datos NVARCHAR(MAX),
            @docOk BIT, @e2Ok BIT, @docMensaje NVARCHAR(300), @e2Mensaje NVARCHAR(300),
            @docCodigo VARCHAR(60), @e2Codigo VARCHAR(60), @docHttp SMALLINT, @e2Http SMALLINT,
            @funcion VARCHAR(20), @responsableId BIGINT, @destinatario BIGINT,
            @hash VARBINARY(32), @e2Accion VARCHAR(32),
            @prioridad SMALLINT, @suplente BIT, @activo BIT, @desde DATETIME2(0), @hasta DATETIME2(0);

    SET @permiso=CASE
        WHEN @cAccion IN('SOLICITAR','CONTEXTO') THEN 'SALIDAS_CREAR'
        WHEN @cAccion IN('CORREGIR','ENVIAR_BORRADOR') THEN 'SALIDAS_EDITAR'
        WHEN @cAccion='DECIDIR' THEN 'SALIDAS_CONFIRMAR'
        WHEN @cAccion='CANCELAR' THEN 'SALIDAS_RETIRAR'
        WHEN @cAccion IN('RESPONSABLES','GUARDAR_RESPONSABLE') THEN 'USUARIOS_EDITAR'
        ELSE 'SALIDAS_VER' END;

    BEGIN TRY
        EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,@permiso,
            @usuario OUTPUT,@sesion OUTPUT,@dispositivo OUTPUT,@empleado OUTPUT,@modulo OUTPUT,
            @correlacion OUTPUT,@solicitud OUTPUT,@ip OUTPUT,@endpoint OUTPUT,
            @autorizado OUTPUT,@mensajeAuth OUTPUT;
        IF ISNULL(@autorizado,0)<>1 OR @uot IS NULL
           OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,@permiso)<>1
            THROW 51060,N'No tiene permiso para esta operación.',1;
        IF JSON_VALUE(@cJson,'$.filtros.convenioId') IS NOT NULL
            THROW 51060,N'Esta opción solo corresponde a salidas generales.',1;

        IF @cAccion IN('RESPONSABLES','GUARDAR_RESPONSABLE')
           AND seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'SALIDAS_CONFIRMAR')<>1
            THROW 51060,N'No tiene permiso para configurar responsables.',1;

        IF @cAccion='CONTEXTO'
        BEGIN
            SELECT TOP(1) @aprobador=R.usuario_id
            FROM campo.SalidaResponsableUOT R
            JOIN seg.Usuario U ON U.usuario_id=R.usuario_id
               AND U.estado=1 AND U.estado_cuenta='ACTIVA'
            JOIN org.EmpleadoUOT EU ON EU.empleado_id=U.persona_id
               AND EU.uot_id=R.uot_id AND EU.estado=1 AND EU.es_principal=1
               AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
               AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
               AND (EU.fecha_cese IS NULL OR EU.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()))
            WHERE R.uot_id=@uot AND R.funcion='APROBADOR' AND R.estado=1
              AND R.fecha_desde<=SYSUTCDATETIME()
              AND (R.fecha_hasta IS NULL OR R.fecha_hasta>SYSUTCDATETIME())
              AND R.usuario_id<>@usuario
              AND seg.FN_Usuario_TienePermisoUOT(R.usuario_id,@uot,'SALIDAS_CONFIRMAR')=1
            ORDER BY R.suplente,R.prioridad,R.responsable_uot_id;
            SET @cDatos=(SELECT CAST(CASE WHEN @empleado IS NOT NULL
                AND seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'VISITAS_EDITAR')=1
                AND seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'SALIDAS_LISTAR')=1
                AND EXISTS(SELECT 1 FROM org.Empleado E
                    JOIN org.EmpleadoUOT EU ON EU.empleado_id=E.empleado_id
                    WHERE E.empleado_id=@empleado AND E.estado=1 AND EU.uot_id=@uot AND EU.estado=1
                      AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
                      AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME())))
                THEN 1 ELSE 0 END AS BIT) habilitado,
                CAST(CASE WHEN @aprobador IS NULL THEN 0 ELSE 1 END AS BIT) tieneAprobador,
                @uot uotId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
            SET @bResultado=1;
        END
        ELSE IF @cAccion='RESPONSABLES'
        BEGIN
            SET @cDatos=(SELECT R.responsable_uot_id responsableId,R.usuario_id usuarioId,
                U.nombre_usuario usuario,R.funcion,R.prioridad,R.suplente,R.fecha_desde fechaDesde,
                R.fecha_hasta fechaHasta,R.estado activo
                FROM campo.SalidaResponsableUOT R
                JOIN seg.Usuario U ON U.usuario_id=R.usuario_id
                WHERE R.uot_id=@uot
                ORDER BY R.funcion,R.suplente,R.prioridad,R.responsable_uot_id FOR JSON PATH);
            SET @bResultado=1;
        END
        ELSE IF @cAccion='GUARDAR_RESPONSABLE'
        BEGIN
            SELECT @responsableId=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.responsableId')),
                   @destinatario=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.usuarioId')),
                   @funcion=JSON_VALUE(@cJson,'$.datos.funcion'),
                   @prioridad=COALESCE(TRY_CONVERT(SMALLINT,JSON_VALUE(@cJson,'$.datos.prioridad')),1),
                   @suplente=CASE WHEN JSON_VALUE(@cJson,'$.datos.suplente')='true' THEN 1 ELSE 0 END,
                   @activo=CASE WHEN JSON_VALUE(@cJson,'$.datos.activo')='false' THEN 0 ELSE 1 END,
                   @desde=COALESCE(TRY_CONVERT(DATETIME2(0),JSON_VALUE(@cJson,'$.datos.fechaDesde')),SYSUTCDATETIME()),
                   @hasta=TRY_CONVERT(DATETIME2(0),JSON_VALUE(@cJson,'$.datos.fechaHasta'));
            IF @funcion NOT IN('APROBADOR','ENTREGA','INSPECTOR') OR @destinatario IS NULL
               OR @prioridad NOT BETWEEN 1 AND 100 OR (@hasta IS NOT NULL AND @hasta<=@desde)
                THROW 51066,N'Compruebe la configuración del responsable.',1;
            IF NOT EXISTS(SELECT 1 FROM seg.Usuario U JOIN org.Empleado E
                 ON E.empleado_id=U.persona_id AND E.estado=1
                 JOIN org.EmpleadoUOT EU ON EU.empleado_id=E.empleado_id AND EU.uot_id=@uot AND EU.estado=1
                 WHERE U.usuario_id=@destinatario AND U.estado=1 AND U.estado_cuenta='ACTIVA'
                   AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
                   AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
                   AND (EU.fecha_cese IS NULL OR EU.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()))
                   AND seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@uot,
                        CASE @funcion WHEN 'ENTREGA' THEN 'RECURSOS_CREAR' ELSE 'SALIDAS_CONFIRMAR' END)=1)
                THROW 51060,N'El responsable debe estar activo y autorizado en esta UOT.',1;
            BEGIN TRANSACTION;
            IF @responsableId IS NULL
            BEGIN
                SELECT @responsableId=responsable_uot_id FROM campo.SalidaResponsableUOT WITH(UPDLOCK,HOLDLOCK)
                WHERE uot_id=@uot AND usuario_id=@destinatario AND funcion=@funcion;
            END;
            IF @responsableId IS NULL
            BEGIN
                INSERT campo.SalidaResponsableUOT(uot_id,usuario_id,funcion,prioridad,suplente,
                    fecha_desde,fecha_hasta,estado,actualizado_por)
                VALUES(@uot,@destinatario,@funcion,@prioridad,@suplente,@desde,@hasta,@activo,@usuario);
                SET @responsableId=CONVERT(BIGINT,SCOPE_IDENTITY());
            END
            ELSE
            BEGIN
                UPDATE campo.SalidaResponsableUOT SET prioridad=@prioridad,suplente=@suplente,
                   fecha_desde=@desde,fecha_hasta=@hasta,estado=@activo,
                   actualizado_por=@usuario,fecha_actualizacion=SYSUTCDATETIME()
                WHERE responsable_uot_id=@responsableId AND uot_id=@uot
                  AND usuario_id=@destinatario AND funcion=@funcion;
                IF @@ROWCOUNT<>1 THROW 51066,N'La configuración no está disponible.',1;
            END;
            DECLARE @auditoria BIGINT,@transicion BIGINT;
            EXEC auditoria.PA_Operacion_Ins_RegistrarCambio
                 @nUsuarioId=@usuario,@nSesionUsuarioId=@sesion,@nDispositivoUsuarioId=@dispositivo,
                 @nModuloId=@modulo,@cAccion='CONFIGURAR',@cEsquemaEntidad=N'campo',
                 @cNombreEntidad=N'SalidaResponsableUOT',@cIdentificador=@responsableId,
                 @cIp=@ip,@gCorrelacionId=@correlacion,@gSolicitudId=@solicitud,
                 @cEndpoint=@endpoint,@nAuditoriaEventoId=@auditoria OUTPUT,
                 @nTransicionEstadoId=@transicion OUTPUT;
            COMMIT TRANSACTION;
            SET @cDatos=(SELECT @responsableId responsableId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
            SET @bResultado=1;
        END
        ELSE IF @cAccion IN('VINCULO','DOCUMENTO')
        BEGIN
            SET @cDatos=(SELECT V.salida_campo_id salidaId,V.documento_origen_id documentoId,
                V.hilo_id hiloId,E.estado,V.uot_id uotId
                FROM campo.SalidaDocumentoVinculo V
                JOIN campo.SalidaE2 E ON E.salida_campo_id=V.salida_campo_id
                WHERE V.uot_id=@uot
                  AND ((@cAccion='VINCULO' AND V.salida_campo_id=@salida)
                    OR (@cAccion='DOCUMENTO' AND V.documento_origen_id=@documento)
                    OR (@cAccion='DOCUMENTO' AND EXISTS(SELECT 1 FROM doc.Documento D
                            WHERE D.documento_id=@documento AND D.hilo_id=V.hilo_id
                              AND EXISTS(SELECT 1 FROM doc.ParticipanteUOT P
                                 WHERE P.hilo_id=D.hilo_id AND P.usuario_id=@usuario AND P.uot_id=@uot))))
                FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
            SET @bResultado=1;
        END
        ELSE
        BEGIN
            IF @clave IS NULL OR @empleado IS NULL
                THROW 51066,N'La solicitud no tiene una sesión válida.',1;
            SET @hash=HASHBYTES('SHA2_256',CONVERT(VARBINARY(MAX),COALESCE(JSON_QUERY(@cJson,'$.datos'),N'{}')));
            IF @cAccion IN('SOLICITAR','ENVIAR_BORRADOR')
               AND EXISTS(SELECT 1 FROM campo.SalidaDocumentoVinculo V
                      WHERE V.clave_idempotencia=@clave)
            BEGIN
                IF NOT EXISTS(SELECT 1 FROM campo.SalidaDocumentoVinculo V
                    JOIN campo.SalidaE2 E ON E.salida_campo_id=V.salida_campo_id
                    WHERE V.clave_idempotencia=@clave AND V.hash_peticion=@hash
                      AND V.uot_id=@uot AND E.solicitante_empleado_id=@empleado
                      AND (@cAccion='SOLICITAR' OR V.salida_campo_id=@salida))
                    THROW 51065,N'La clave ya se utilizó para otra solicitud.',1;
                SET @cDatos=(SELECT V.salida_campo_id salidaId,V.documento_origen_id documentoId,
                    V.hilo_id hiloId,E.estado FROM campo.SalidaDocumentoVinculo V
                    JOIN campo.SalidaE2 E ON E.salida_campo_id=V.salida_campo_id
                    WHERE V.clave_idempotencia=@clave FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
                SELECT @bResultado=1,@cMensaje=N'Solicitud registrada.',
                       @cCodigoRespuesta='SALIDA_DOC_REPETIDA',@nHttpRespuesta=200;
                RETURN;
            END;
            IF @cAccion IN('SOLICITAR','ENVIAR_BORRADOR','CORREGIR')
               AND (seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'VISITAS_EDITAR')<>1
                    OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'SALIDAS_LISTAR')<>1)
                THROW 51060,N'No tiene acceso técnico a las salidas.',1;
            IF @cAccion='SOLICITAR' AND JSON_VALUE(@cJson,'$.datos.borrador')='true'
                THROW 51066,N'Guarde el borrador desde Gestión Técnica.',1;
            IF @cAccion='CORREGIR' AND JSON_VALUE(@cJson,'$.datos.enviar')='false'
                THROW 51066,N'Guarde la corrección desde Gestión Técnica.',1;
            IF @cAccion='DECIDIR' AND JSON_VALUE(@cJson,'$.datos.decision') NOT IN
                ('APROBADA','OBSERVADA','RECHAZADA')
                THROW 51066,N'Seleccione una decisión válida.',1;

            SELECT @documentoOrigen=V.documento_origen_id,@hilo=V.hilo_id,
                   @solicitanteUsuario=U.usuario_id
            FROM campo.SalidaDocumentoVinculo V
            JOIN campo.SalidaE2 E ON E.salida_campo_id=V.salida_campo_id
            JOIN seg.Usuario U ON U.persona_id=E.solicitante_empleado_id AND U.estado=1
            WHERE V.salida_campo_id=@salida AND V.uot_id=@uot;

            IF @cAccion<>'SOLICITAR' AND @documentoOrigen IS NULL
                THROW 51066,N'La salida no tiene un expediente documental vinculado.',1;
            IF @cAccion IN('SOLICITAR','ENVIAR_BORRADOR') AND @documentoOrigen IS NOT NULL
                THROW 51066,N'El expediente ya fue enviado.',1;
            IF @cAccion='ENVIAR_BORRADOR' AND NOT EXISTS(
                SELECT 1 FROM campo.SalidaE2 E WITH(UPDLOCK,HOLDLOCK)
                WHERE E.salida_campo_id=@salida AND E.uot_id=@uot AND E.convenio_id IS NULL
                  AND E.estado='BORRADOR' AND E.solicitante_empleado_id=@empleado)
                THROW 51066,N'El borrador no está disponible.',1;
            IF @cAccion IN('SOLICITAR','ENVIAR_BORRADOR','CORREGIR')
            BEGIN
                SELECT TOP(1) @aprobador=R.usuario_id
                FROM campo.SalidaResponsableUOT R WITH(UPDLOCK,HOLDLOCK)
                JOIN seg.Usuario U ON U.usuario_id=R.usuario_id AND U.estado=1 AND U.estado_cuenta='ACTIVA'
                JOIN org.EmpleadoUOT EU ON EU.empleado_id=U.persona_id
                    AND EU.uot_id=@uot AND EU.estado=1 AND EU.es_principal=1
                    AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
                    AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
                WHERE R.uot_id=@uot AND R.funcion='APROBADOR' AND R.estado=1
                  AND R.fecha_desde<=SYSUTCDATETIME()
                  AND (R.fecha_hasta IS NULL OR R.fecha_hasta>SYSUTCDATETIME())
                  AND R.usuario_id<>@usuario
                  AND seg.FN_Usuario_TienePermisoUOT(R.usuario_id,@uot,'SALIDAS_CONFIRMAR')=1
                ORDER BY R.suplente,R.prioridad,R.responsable_uot_id;
                IF @aprobador IS NULL
                    THROW 51066,N'Esta UOT no tiene un aprobador disponible.',1;
            END;
            IF @cAccion='DECIDIR' AND (@solicitanteUsuario=@usuario OR NOT EXISTS(
                SELECT 1 FROM campo.SalidaResponsableUOT R
                WHERE R.uot_id=@uot AND R.usuario_id=@usuario AND R.funcion='APROBADOR'
                  AND R.estado=1 AND R.fecha_desde<=SYSUTCDATETIME()
                  AND (R.fecha_hasta IS NULL OR R.fecha_hasta>SYSUTCDATETIME())
            )) THROW 51060,N'No le corresponde resolver esta solicitud.',1;

            SELECT @tipoDocumento=tipo_documento_id FROM doc.TipoDocumento
            WHERE codigo='SOLICITUD_SALIDA_TECNICA' AND estado=1;
            IF @tipoDocumento IS NULL THROW 51066,N'El tipo de solicitud no está disponible.',1;

            BEGIN TRANSACTION;
            EXEC sys.sp_set_session_context @key=N'DESCO_SALIDA_DOC',@value=@clave;
            SET @e2Accion=CASE WHEN @cAccion='ENVIAR_BORRADOR' THEN 'CORREGIR' ELSE @cAccion END;
            EXEC campo.PA_SalidaOperativaE2_Ejecutar @e2Accion,@cJson,
                @e2Datos OUTPUT,@e2Ok OUTPUT,@e2Mensaje OUTPUT,@e2Codigo OUTPUT,@e2Http OUTPUT;
            EXEC sys.sp_set_session_context @key=N'DESCO_SALIDA_DOC',@value=NULL;
            IF ISNULL(@e2Ok,0)<>1
            BEGIN
                IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
                SELECT @cMensaje=LEFT(COALESCE(@e2Mensaje,N'No se pudo completar la salida.'),300),
                       @cCodigoRespuesta=COALESCE(@e2Codigo,'SALIDA_DOC_VALIDACION'),
                       @nHttpRespuesta=COALESCE(@e2Http,400);
                RETURN;
            END;
            IF @cAccion='SOLICITAR'
                SET @salida=TRY_CONVERT(BIGINT,JSON_VALUE(@e2Datos,'$.salidaId'));
            IF @salida IS NULL THROW 51066,N'No se pudo identificar la salida.',1;

            IF @cAccion IN('SOLICITAR','ENVIAR_BORRADOR')
            BEGIN
                SELECT @asunto=LEFT(CONCAT(N'Solicitud de salida técnica #',@salida,N' · ',
                     JSON_VALUE(@cJson,'$.datos.nombre')),240),
                       @texto=LEFT(CONCAT(N'Solicitud de salida técnica #',@salida,N'. ',
                          COALESCE(JSON_VALUE(@cJson,'$.datos.descripcion'),N'Se solicita autorización.')),3000),
                       @destinatario=@aprobador;
            END
            ELSE
            BEGIN
                SELECT @asunto=LEFT(CONCAT(N'Salida técnica #',@salida,N' · ',@cAccion),240),
                       @texto=CASE @cAccion
                          WHEN 'DECIDIR' THEN LEFT(CONCAT(N'Decisión: ',JSON_VALUE(@cJson,'$.datos.decision'),
                              N'. ',COALESCE(JSON_VALUE(@cJson,'$.datos.motivo'),N'Solicitud revisada.')),3000)
                          WHEN 'CANCELAR' THEN LEFT(CONCAT(N'Solicitud cancelada. ',
                              COALESCE(JSON_VALUE(@cJson,'$.datos.motivo'),N'')),3000)
                          ELSE LEFT(CONCAT(N'Solicitud corregida. ',
                              COALESCE(JSON_VALUE(@cJson,'$.datos.descripcion'),N'Se actualizó la solicitud.')),3000) END,
                       @destinatario=CASE WHEN @cAccion='CORREGIR' THEN @aprobador ELSE @solicitanteUsuario END;
                IF @cAccion='CANCELAR'
                    SELECT TOP(1) @destinatario=D.usuario_id FROM doc.Destinatario D
                    WHERE D.documento_id=@documentoOrigen ORDER BY D.usuario_id;
            END;

            SET @docJson=(SELECT JSON_QUERY(@cJson,'$.contexto') contexto,
                JSON_QUERY((SELECT @uot uotId,@uot destinoUotId,@documentoOrigen documentoPadreId,
                    @tipoDocumento tipoDocumentoId,@asunto asunto,@texto cuerpo,
                    JSON_QUERY(CONCAT('[',@destinatario,']')) destinatarioIds,
                    JSON_QUERY(CASE WHEN @cAccion IN('SOLICITAR','ENVIAR_BORRADOR')
                      THEN COALESCE(JSON_QUERY(@cJson,'$.datos.archivoIds'),N'[]') ELSE N'[]' END) archivoIds,
                    CAST(CASE WHEN @cAccion IN('SOLICITAR','ENVIAR_BORRADOR') THEN 1 ELSE 0 END AS BIT) requiereRespuesta,
                    CASE WHEN @cAccion IN('SOLICITAR','ENVIAR_BORRADOR') THEN NULL ELSE 'RESPUESTA' END tipoMovimiento
                    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)) datos
                FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
            EXEC doc.PA_Correspondencia_Ejecutar 'ENVIAR',@docJson,
                @docDatos OUTPUT,@docOk OUTPUT,@docMensaje OUTPUT,@docCodigo OUTPUT,@docHttp OUTPUT;
            IF ISNULL(@docOk,0)<>1
            BEGIN
                IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
                SELECT @cMensaje=LEFT(COALESCE(@docMensaje,N'No se pudo enviar la solicitud.'),300),
                       @cCodigoRespuesta='SALIDA_DOC_ENVIO',@nHttpRespuesta=COALESCE(@docHttp,400);
                RETURN;
            END;
            SET @documento=TRY_CONVERT(BIGINT,JSON_VALUE(@docDatos,'$.documentoId'));
            SELECT @hilo=D.hilo_id FROM doc.Documento D WHERE D.documento_id=@documento;
            IF @documento IS NULL OR @hilo IS NULL
                THROW 51066,N'No se pudo vincular el documento.',1;
            IF @cAccion IN('SOLICITAR','ENVIAR_BORRADOR')
            BEGIN
                INSERT campo.SalidaDocumentoVinculo(salida_campo_id,documento_origen_id,
                    hilo_id,uot_id,clave_idempotencia,hash_peticion)
                VALUES(@salida,@documento,@hilo,@uot,@clave,@hash);
            END
            ELSE IF @docCodigo<>'DOCS_ENVIO_REPETIDO'
            BEGIN
                INSERT doc.Evento(hilo_id,documento_id,usuario_id,tipo,detalle)
                VALUES(@hilo,@documento,@usuario,
                    CASE WHEN @cAccion='DECIDIR' THEN CONCAT('SALIDA_',JSON_VALUE(@cJson,'$.datos.decision'))
                         ELSE CONCAT('SALIDA_',@cAccion) END,
                    LEFT(@texto,400));
                IF @cAccion='DECIDIR'
                    UPDATE doc.Hilo SET estado=CASE WHEN JSON_VALUE(@cJson,'$.datos.decision')='OBSERVADA'
                        THEN 'OBSERVADO' ELSE 'EN_TRAMITE' END
                    WHERE hilo_id=@hilo AND estado NOT IN('FINALIZADO','ANULADO');
            END;
            COMMIT TRANSACTION;
            SET @cDatos=(SELECT @salida salidaId,@documento documentoId,@hilo hiloId,
                JSON_VALUE(@e2Datos,'$.estado') estado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
            SET @bResultado=1;
        END;

        IF @bResultado=1
            SELECT @cMensaje=N'Operación realizada.',@cCodigoRespuesta='SALIDA_DOC_OK',@nHttpRespuesta=200;
    END TRY
    BEGIN CATCH
        EXEC sys.sp_set_session_context @key=N'DESCO_SALIDA_DOC',@value=NULL;
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
        SELECT @bResultado=0,@cDatos=NULL,
               @nHttpRespuesta=CASE WHEN ERROR_NUMBER()=51060 THEN 403
                    WHEN ERROR_NUMBER() IN(2601,2627,51064,51065) THEN 409 ELSE 400 END,
               @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51060 AND 51067
                    THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo completar la operación.' END,
               @cCodigoRespuesta='SALIDA_DOC_VALIDACION';
    END CATCH;
END;
GO
