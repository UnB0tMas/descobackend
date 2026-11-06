-- V579. Alta tradicional de personas: completar campos faltantes, conservar identidad autorizada.
-- La API de identidad ya persiste primero datos de Factiliza; esta mutación solo complementa nulos.
CREATE OR ALTER PROCEDURE prod.PA_ExpedienteProductivo_Ejecutar
    @cOperacion VARCHAR(30), @cJson NVARCHAR(MAX),
    @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT, @cCodigoRespuesta VARCHAR(60) OUTPUT,
    @nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @bResultado=0; SET @cDatos=NULL; SET @cMensaje=N'No se completó la operación.';
    SET @cCodigoRespuesta='EXPEDIENTE_NO_DISPONIBLE'; SET @nHttpRespuesta=400;
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,
      @gCorr UNIQUEIDENTIFIER,@gSolicitud UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEndpoint NVARCHAR(250),
      @bAuth BIT,@cMsgAuth NVARCHAR(300),@nUot BIGINT,@nConvenio BIGINT,@nPredio BIGINT,
      @nPersona BIGINT,@nEntidad BIGINT,@nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),
      @cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bInicio BIT,@cMsgInicio NVARCHAR(300),
      @bFin BIT,@cMsgFin NVARCHAR(300),@nAud BIGINT,@nTrans BIGINT,
      @cPermiso VARCHAR(40),@cNombre NVARCHAR(150),@cDistrito CHAR(6),@nCentroPoblado BIGINT,
      @cDoc VARCHAR(30),@cTipoDoc VARCHAR(15),@cNombres NVARCHAR(100),@cPaterno NVARCHAR(80),
      @cMaterno NVARCHAR(80),@cRef NVARCHAR(300),@nLat DECIMAL(9,6),@nLon DECIMAL(9,6),
      @nUbicacion BIGINT,@bUbi BIT,@cMsgUbi NVARCHAR(300),@nEspecie INT,@nLote BIGINT,
      @nCultivo INT,@nVariedad BIGINT,@nParcela BIGINT,@nCultivoParcela BIGINT,
      @nCantidad INT,@cNota NVARCHAR(2000),@cTipo VARCHAR(40),@dFecha DATE,
      @fHecho DATETIME2(0),@nArea DECIMAL(10,4),@nAreaCult DECIMAL(10,4),
      @cRiego VARCHAR(30),@nVersion BIGINT,@cCodigo VARCHAR(40),@nConsecutivo BIGINT,
      @cIdEntidad NVARCHAR(200),@bFallo BIT,@cMsgFallo NVARCHAR(300);
    IF ISJSON(@cJson)<>1 OR @cOperacion IS NULL RETURN;
    SELECT @nUot=uotId,@nConvenio=convenioId,@nPredio=predioId
    FROM OPENJSON(@cJson,'$.filtros') WITH (uotId BIGINT '$.uotId',convenioId BIGINT '$.convenioId',predioId BIGINT '$.predioId');
    SET @cPermiso=CASE
      WHEN @cOperacion IN('PERSONAS','PREDIOS','EXPEDIENTE','CATALOGOS','CONVENIOS') THEN 'PREDIOS_VER'
      WHEN @cOperacion IN('PERSONA_CREAR','PREDIO_CREAR','AMBITO_VINCULAR') THEN 'PREDIOS_CREAR'
      WHEN @cOperacion='CULTIVO_CREAR' THEN 'CULTIVOS_CREAR'
      ELSE 'PREDIOS_EDITAR' END;
    BEGIN TRY
      IF @cOperacion IN('PERSONAS','PREDIOS','EXPEDIENTE','CATALOGOS','CONVENIOS')
        EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,@cPermiso,
          @nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,
          @gCorr OUTPUT,@gSolicitud OUTPUT,@cIp OUTPUT,@cEndpoint OUTPUT,@bAuth OUTPUT,@cMsgAuth OUTPUT;
      ELSE
      BEGIN
        EXEC seg.PA_Operacion_Ins_IniciarIdempotente @cJson,@cPermiso,'EXPEDIENTE_E1',
          @nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,
          @gCorr OUTPUT,@gSolicitud OUTPUT,@cIp OUTPUT,@cEndpoint OUTPUT,
          @nOp OUTPUT,@bRep OUTPUT,@cEstadoOp OUTPUT,@cIdRes OUTPUT,@cCodRes OUTPUT,
          @bInicio OUTPUT,@cMsgInicio OUTPUT;
        SET @bAuth=@bInicio;
        SET @cMsgAuth=@cMsgInicio;
        IF @bRep=1 AND @cEstadoOp='COMPLETADA'
        BEGIN
          SET @bResultado=1; SET @cMensaje=N'Operación ya aplicada.'; SET @cCodigoRespuesta='IDEMPOTENTE';
          SET @nHttpRespuesta=200;
          SET @cDatos=(SELECT TRY_CONVERT(BIGINT,@cIdRes) AS id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
          RETURN;
        END;
        IF @bRep=1
        BEGIN
          SET @bResultado=0;
          SET @cMensaje=CASE WHEN @cEstadoOp='EN_PROCESO'
                             THEN N'La misma solicitud todavía se encuentra en proceso.'
                             ELSE N'La misma solicitud ya fue rechazada; genere una nueva solicitud para reintentar.' END;
          SET @cCodigoRespuesta='IDEMPOTENCIA_CONFLICTO';
          SET @nHttpRespuesta=409;
          RETURN;
        END;
      END;
      IF ISNULL(@bAuth,0)=0
      BEGIN
        SET @cMensaje=ISNULL(@cMsgAuth,N'Acceso no permitido.'); SET @nHttpRespuesta=403;
        IF @nOp IS NOT NULL EXEC auditoria.PA_OperacionIdempotente_Upd_MensajeFallido
          @nOperacionIdempotenteId=@nOp,@cMensajeResultado=@cMensaje,
          @bResultado=@bFallo OUTPUT,@cMensaje=@cMsgFallo OUTPUT;
        RETURN;
      END;
      IF @nUot IS NULL OR [seg].[FN_Usuario_TienePermisoUOT](@nUsuario,@nUot,@cPermiso)<>1
      BEGIN
        SET @cMensaje=N'No tiene acceso a esta unidad territorial.'; SET @nHttpRespuesta=403;
        IF @nOp IS NOT NULL EXEC auditoria.PA_OperacionIdempotente_Upd_MensajeFallido
          @nOperacionIdempotenteId=@nOp,@cMensajeResultado=@cMensaje,
          @bResultado=@bFallo OUTPUT,@cMensaje=@cMsgFallo OUTPUT;
        RETURN;
      END;
      IF @nConvenio IS NOT NULL AND
         seg.FN_Usuario_TienePermisoUOT(@nUsuario,@nUot,
             CASE WHEN @cOperacion IN('PERSONAS','PREDIOS','CATALOGOS','EXPEDIENTE','CONVENIOS') THEN 'APAPPSS_PREDIOS_VER'
                  WHEN @cOperacion IN('PREDIO_CREAR','AMBITO_VINCULAR') THEN 'APAPPSS_PREDIOS_CREAR'
                  ELSE 'APAPPSS_PREDIOS_EDITAR' END)<>1
      BEGIN
        SET @cMensaje=N'No tiene permiso APAPPSS en este convenio.'; SET @nHttpRespuesta=403;
        IF @nOp IS NOT NULL EXEC auditoria.PA_OperacionIdempotente_Upd_MensajeFallido
          @nOperacionIdempotenteId=@nOp,@cMensajeResultado=@cMensaje,
          @bResultado=@bFallo OUTPUT,@cMensaje=@cMsgFallo OUTPUT;
        RETURN;
      END;
      IF @nConvenio IS NOT NULL AND NOT EXISTS(
         SELECT 1 FROM org.ConvenioUOTOrganizacion C
         JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=C.convenio_uot_organizacion_id AND CM.estado=1
         JOIN seg.ModuloEspecial M ON M.modulo_especial_id=CM.modulo_especial_id AND M.codigo='COMERCIALIZACION_ASOCIATIVA' AND M.estado=1
         WHERE C.convenio_uot_organizacion_id=@nConvenio AND C.uot_id=@nUot AND C.estado=1
           AND (C.fecha_inicio IS NULL OR C.fecha_inicio<=CONVERT(DATE,SYSUTCDATETIME()))
           AND (C.fecha_fin IS NULL OR C.fecha_fin>=CONVERT(DATE,SYSUTCDATETIME())))
      BEGIN
        SET @cMensaje=N'El convenio no está habilitado para esta UOT.'; SET @nHttpRespuesta=403;
        IF @nOp IS NOT NULL EXEC auditoria.PA_OperacionIdempotente_Upd_MensajeFallido
          @nOperacionIdempotenteId=@nOp,@cMensajeResultado=@cMensaje,
          @bResultado=@bFallo OUTPUT,@cMensaje=@cMsgFallo OUTPUT;
        RETURN;
      END;
      IF @cOperacion IN('EXPEDIENTE','CULTIVO_CREAR','CRIANZA_CREAR','CONTEO_CREAR','ACTUACION_CREAR','FICHA_COMPLETAR','AMBITO_VINCULAR')
         AND NOT EXISTS (SELECT 1 FROM prod.PredioAmbito A WITH(HOLDLOCK) WHERE A.predio_id=@nPredio AND A.uot_id=@nUot AND A.estado=1
             AND ((@nConvenio IS NULL AND A.convenio_uot_organizacion_id IS NULL) OR A.convenio_uot_organizacion_id=@nConvenio))
      BEGIN
         IF @cOperacion<>'AMBITO_VINCULAR'
         BEGIN
           SET @cMensaje=N'El predio no pertenece al ámbito solicitado.'; SET @nHttpRespuesta=404;
           IF @nOp IS NOT NULL EXEC auditoria.PA_OperacionIdempotente_Upd_MensajeFallido
             @nOperacionIdempotenteId=@nOp,@cMensajeResultado=@cMensaje,
             @bResultado=@bFallo OUTPUT,@cMensaje=@cMsgFallo OUTPUT;
           RETURN;
         END;
      END;
      IF @cOperacion='PERSONAS'
      BEGIN
        DECLARE @cBuscarPersona NVARCHAR(120)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.filtros.buscar'))),N'');
        SET @cDatos=(SELECT JSON_QUERY((SELECT TOP (30) persona_id personaId,tipo_documento tipoDocumento,numero_documento numeroDocumento,
           CONCAT(nombres,N' ',apellido_paterno,N' ',ISNULL(apellido_materno,N'')) nombreCompleto
           FROM org.Persona WHERE estado=1 AND (@cBuscarPersona IS NOT NULL AND
           (numero_documento LIKE @cBuscarPersona+'%' OR CONCAT(nombres,N' ',apellido_paterno,N' ',ISNULL(apellido_materno,N'')) LIKE N'%'+@cBuscarPersona+N'%'))
           ORDER BY nombres,apellido_paterno FOR JSON PATH)) AS items FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
      END
      ELSE IF @cOperacion='CONVENIOS'
      BEGIN
        SET @cDatos=(SELECT JSON_QUERY((SELECT C.convenio_uot_organizacion_id id,
            COALESCE(C.numero_convenio,EM.razon_social) nombre
            FROM org.ConvenioUOTOrganizacion C
            JOIN org.Empresa EM ON EM.empresa_id=C.empresa_id
            JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=C.convenio_uot_organizacion_id AND CM.estado=1
            JOIN seg.ModuloEspecial M ON M.modulo_especial_id=CM.modulo_especial_id AND M.codigo='COMERCIALIZACION_ASOCIATIVA' AND M.estado=1
            WHERE C.uot_id=@nUot AND C.estado=1
              AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,@nUot,'APAPPSS_PREDIOS_VER')=1
              AND (C.fecha_inicio IS NULL OR C.fecha_inicio<=CONVERT(DATE,SYSUTCDATETIME()))
              AND (C.fecha_fin IS NULL OR C.fecha_fin>=CONVERT(DATE,SYSUTCDATETIME()))
            ORDER BY EM.razon_social FOR JSON PATH)) items FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
      END
      ELSE IF @cOperacion='CATALOGOS'
      BEGIN
        SET @cDatos=(SELECT JSON_QUERY((SELECT cultivo_id id,nombre FROM prod.Cultivo WHERE estado=1 ORDER BY nombre FOR JSON PATH)) cultivos,
          JSON_QUERY((SELECT variedad_cultivo_id id,cultivo_id padreId,nombre FROM prod.VariedadCultivo WHERE estado=1 ORDER BY nombre FOR JSON PATH)) variedades,
          JSON_QUERY((SELECT especie_pecuaria_id id,nombre FROM prod.EspeciePecuaria WHERE estado=1 ORDER BY nombre FOR JSON PATH)) especies
          FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
      END
      ELSE IF @cOperacion='PREDIOS'
      BEGIN
        EXEC prod.PA_E1_Predio_Sel_Listar @cJson,@nUot,@nConvenio,@cDatos OUTPUT;
      END
      ELSE IF @cOperacion='EXPEDIENTE'
      BEGIN
        SET @cDatos=(SELECT P.predio_id predioId,P.codigo,P.nombre,U.distrito_codigo distritoCodigo,U.referencia,
          CASE WHEN U.posicion IS NULL THEN NULL ELSE U.posicion.Lat END latitud,
          CASE WHEN U.posicion IS NULL THEN NULL ELSE U.posicion.Long END longitud,
          V.area_total_ha areaTotalHa,V.area_cultivable_ha areaCultivableHa,V.tipo_riego tipoRiego,
          CAST(CASE WHEN V.area_total_ha IS NULL OR V.tipo_riego IS NULL THEN 0 ELSE 1 END AS BIT) fichaCompleta,
          JSON_QUERY((SELECT T.persona_id personaId,T.socio_id socioId,PE.numero_documento numeroDocumento,
              CONCAT(PE.nombres,N' ',PE.apellido_paterno,N' ',ISNULL(PE.apellido_materno,N'')) nombreCompleto,
              T.tipo_titularidad tipoTitularidad,T.porcentaje
              FROM prod.PredioTitularidad T JOIN org.Persona PE ON PE.persona_id=T.persona_id
              WHERE T.predio_id=P.predio_id AND T.estado=1 AND T.fecha_hasta IS NULL FOR JSON PATH)) titulares,
          JSON_QUERY((SELECT PC.parcela_cultivo_id id,C.nombre cultivo,VC.nombre variedad,PA.nombre parcela,
              PC.fecha_inicio fechaInicio,PC.fecha_fin fechaFin
              FROM prod.Parcela PA JOIN prod.ParcelaCultivo PC ON PC.parcela_id=PA.parcela_id
              LEFT JOIN prod.VariedadCultivo VC ON VC.variedad_cultivo_id=PC.variedad_cultivo_id
              LEFT JOIN prod.Cultivo C ON C.cultivo_id=COALESCE(PC.cultivo_id,VC.cultivo_id)
              WHERE PA.predio_id=P.predio_id ORDER BY PC.fecha_inicio DESC FOR JSON PATH)) cultivos,
          JSON_QUERY((SELECT L.crianza_lote_id id,E.nombre especie,L.nombre lote,L.fecha_inicio fechaInicio,
            (SELECT TOP 1 CC.cantidad FROM prod.CrianzaConteo CC WHERE CC.crianza_lote_id=L.crianza_lote_id ORDER BY CC.fecha_observacion DESC,CC.crianza_conteo_id DESC) cantidadActual
            FROM prod.CrianzaLote L JOIN prod.EspeciePecuaria E ON E.especie_pecuaria_id=L.especie_pecuaria_id
            WHERE L.predio_id=P.predio_id ORDER BY L.fecha_inicio DESC FOR JSON PATH)) crianzas,
          JSON_QUERY((SELECT H.id,H.tipo,H.observacion,H.fechaHecho,H.fechaRegistro,H.autor,
                 H.cultivoId,H.crianzaId,H.salidaId,H.visitaId
              FROM (SELECT A.expediente_actuacion_id id,A.tipo,A.observacion,A.fecha_hecho fechaHecho,
                A.fecha_registro fechaRegistro,CONCAT(PE.nombres,N' ',PE.apellido_paterno) autor,
                A.parcela_cultivo_id cultivoId,A.crianza_lote_id crianzaId,A.salida_campo_id salidaId,A.visita_tecnica_id visitaId
                FROM prod.ExpedienteActuacion A JOIN seg.Usuario US ON US.usuario_id=A.usuario_id
                JOIN org.Persona PE ON PE.persona_id=US.persona_id
                WHERE A.predio_id=P.predio_id AND A.uot_id=@nUot AND
                  ((@nConvenio IS NULL AND A.convenio_uot_organizacion_id IS NULL) OR A.convenio_uot_organizacion_id=@nConvenio)
                UNION ALL
                SELECT -V.visita_tecnica_id,'VISITA',COALESCE(V.resumen,V.objetivo,N'Visita técnica'),
                   V.fecha_hora_inicio,V.fecha_hora_inicio,CONCAT(PER.nombres,N' ',PER.apellido_paterno),
                   CAST(NULL AS BIGINT),CAST(NULL AS BIGINT),S.salida_campo_id,V.visita_tecnica_id
                FROM campo.VisitaTecnica V JOIN campo.SalidaParticipante SP ON SP.salida_participante_id=V.salida_participante_id
                JOIN campo.SalidaCampo S ON S.salida_campo_id=SP.salida_campo_id
                JOIN org.Persona PER ON PER.persona_id=SP.empleado_id
                WHERE V.predio_id=P.predio_id AND S.uot_id=@nUot AND @nConvenio IS NULL AND V.estado=1
              ) H ORDER BY H.fechaHecho DESC,H.id DESC FOR JSON PATH)) historial,
          JSON_QUERY((SELECT CP.censo_plantas_id id,C.nombre cultivo,CP.fecha_censo fecha,
               CP.plantas_totales total,CP.plantas_productivas productivas,CP.observacion
               FROM prod.CensoPlantas CP JOIN prod.ParcelaCultivo PC ON PC.parcela_cultivo_id=CP.parcela_cultivo_id
               JOIN prod.Parcela PA ON PA.parcela_id=PC.parcela_id
               LEFT JOIN prod.Cultivo C ON C.cultivo_id=PC.cultivo_id
               WHERE PA.predio_id=P.predio_id AND CP.estado=1 ORDER BY CP.fecha_censo DESC FOR JSON PATH)) censos,
          JSON_QUERY((SELECT CC.crianza_conteo_id id,CC.crianza_lote_id crianzaId,CC.cantidad,CC.fecha_observacion fechaHecho,
            CC.observacion FROM prod.CrianzaConteo CC JOIN prod.CrianzaLote L ON L.crianza_lote_id=CC.crianza_lote_id
            WHERE L.predio_id=P.predio_id ORDER BY CC.fecha_observacion DESC,CC.crianza_conteo_id DESC FOR JSON PATH)) conteos
          FROM prod.Predio P JOIN geo.Ubicacion U ON U.ubicacion_id=P.ubicacion_id
          OUTER APPLY(SELECT TOP 1 * FROM prod.PredioVersion X WHERE X.predio_id=P.predio_id AND X.estado=1 AND X.fecha_hasta IS NULL ORDER BY X.fecha_desde DESC) V
          WHERE P.predio_id=@nPredio FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
      END
      ELSE
      BEGIN
        BEGIN TRANSACTION;
        IF @cOperacion='PERSONA_CREAR'
        BEGIN
          SELECT @cTipoDoc=tipoDocumento,@cDoc=numeroDocumento,@cNombres=nombres,@cPaterno=apellidoPaterno,@cMaterno=apellidoMaterno
          FROM OPENJSON(@cJson,'$.datos') WITH(tipoDocumento VARCHAR(15),numeroDocumento VARCHAR(30),nombres NVARCHAR(100),apellidoPaterno NVARCHAR(80),apellidoMaterno NVARCHAR(80));
          SET @cDoc=LTRIM(RTRIM(@cDoc));
          IF @cTipoDoc NOT IN('DNI','CE','PASAPORTE') OR @cDoc IS NULL OR LEN(@cDoc)<5 OR
             (@cTipoDoc='DNI' AND (@cDoc NOT LIKE REPLICATE('[0-9]',8) OR LEN(@cDoc)<>8)) OR
             NULLIF(LTRIM(RTRIM(@cNombres)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@cPaterno)),N'') IS NULL
             THROW 51052,N'Documento y nombres obligatorios.',1;
          SELECT TOP 1 @nEntidad=persona_id FROM org.Persona WITH(UPDLOCK,HOLDLOCK)
          WHERE tipo_documento=@cTipoDoc AND numero_documento=@cDoc;
          IF @nEntidad IS NULL
          BEGIN
            INSERT org.Persona(tipo_documento,numero_documento,nombres,apellido_paterno,apellido_materno)
            VALUES(@cTipoDoc,@cDoc,@cNombres,@cPaterno,@cMaterno);
            SET @nEntidad=SCOPE_IDENTITY();
          END
          ELSE
          BEGIN
            -- No permitir que un registro manual asocie silenciosamente otro nombre al DNI existente.
            IF EXISTS (SELECT 1 FROM org.Persona P WHERE P.persona_id=@nEntidad AND (
                (NULLIF(TRIM(P.nombres),N'') IS NOT NULL AND TRIM(P.nombres)<>TRIM(@cNombres))
                OR (NULLIF(TRIM(P.apellido_paterno),N'') IS NOT NULL AND TRIM(P.apellido_paterno)<>TRIM(@cPaterno))
                OR (NULLIF(TRIM(P.apellido_materno),N'') IS NOT NULL AND NULLIF(TRIM(@cMaterno),N'') IS NOT NULL
                    AND TRIM(P.apellido_materno)<>TRIM(@cMaterno))
            )) THROW 51052,N'El documento ya pertenece a una persona con otros datos. Seleccione la persona existente.',1;
            -- Factiliza/local pudieron dejar información incompleta. Solo rellenar nulos/vacios;
            -- nunca reemplazar atributos previamente obtenidos ni alterar el documento.
            UPDATE org.Persona
            SET nombres=CASE WHEN NULLIF(TRIM(nombres),N'') IS NULL THEN @cNombres ELSE nombres END,
                apellido_paterno=CASE WHEN NULLIF(TRIM(apellido_paterno),N'') IS NULL THEN @cPaterno ELSE apellido_paterno END,
                apellido_materno=CASE WHEN NULLIF(TRIM(apellido_materno),N'') IS NULL AND NULLIF(TRIM(@cMaterno),N'') IS NOT NULL
                        THEN @cMaterno ELSE apellido_materno END
            WHERE persona_id=@nEntidad AND estado=1;
            IF @@ROWCOUNT<>1 THROW 51052,N'La persona existente no se encuentra activa.',1;
          END;
        END
        ELSE IF @cOperacion='PREDIO_CREAR'
        BEGIN
          EXEC prod.PA_E1_Predio_Ins_Registrar @cJson,@nUot,@nConvenio,@nUsuario,
            @nPredio OUTPUT,@nEntidad OUTPUT;
        END
        ELSE IF @cOperacion='AMBITO_VINCULAR'
        BEGIN
          EXEC prod.PA_E1_Predio_Ins_VincularConvenio @cJson,@nUot,@nConvenio,@nPredio,
            @nUsuario,@nEntidad OUTPUT;
        END
        ELSE IF @cOperacion='CULTIVO_CREAR'
        BEGIN
          SELECT @nCultivo=cultivoId,@nVariedad=variedadId,@nParcela=parcelaId,@cNombre=parcelaNombre,@dFecha=fecha
          FROM OPENJSON(@cJson,'$.datos') WITH(cultivoId INT,variedadId BIGINT,parcelaId BIGINT,parcelaNombre NVARCHAR(150),fecha DATE);
          IF @dFecha IS NULL SET @dFecha=CONVERT(DATE,SYSUTCDATETIME());
          IF NOT EXISTS(SELECT 1 FROM prod.Cultivo WHERE cultivo_id=@nCultivo AND estado=1) OR
             (@nVariedad IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.VariedadCultivo WHERE variedad_cultivo_id=@nVariedad AND cultivo_id=@nCultivo AND estado=1))
             THROW 51057,N'Cultivo o variedad inválidos.',1;
          IF @nParcela IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.Parcela WHERE parcela_id=@nParcela AND predio_id=@nPredio AND estado=1)
             THROW 51058,N'La parcela no pertenece al predio.',1;
          IF @nParcela IS NULL
          BEGIN
            SET @nConsecutivo=NEXT VALUE FOR prod.SQ_CodigoParcela;
            INSERT prod.Parcela(predio_id,codigo,nombre,area_ha) VALUES(@nPredio,'PAR-'+RIGHT(REPLICATE('0',12)+CONVERT(VARCHAR(20),@nConsecutivo),12),
                COALESCE(NULLIF(@cNombre,N''),N'Parcela técnica'),NULL);
            SET @nParcela=SCOPE_IDENTITY();
          END;
          INSERT prod.ParcelaCultivo(parcela_id,cultivo_id,variedad_cultivo_id,variedad_palta_id,fecha_inicio,situacion_cultivo)
          SELECT @nParcela,@nCultivo,@nVariedad,VC.variedad_palta_legacy_id,@dFecha,'ACTIVO'
          FROM (SELECT 1 uno) X LEFT JOIN prod.VariedadCultivo VC ON VC.variedad_cultivo_id=@nVariedad;
          SET @nEntidad=SCOPE_IDENTITY();
        END
        ELSE IF @cOperacion='CRIANZA_CREAR'
        BEGIN
          SELECT @nEspecie=especieId,@cNombre=nombre,@nCantidad=cantidad,@dFecha=fecha,@cNota=observacion
          FROM OPENJSON(@cJson,'$.datos') WITH(especieId INT,nombre NVARCHAR(100),cantidad INT,fecha DATE,observacion NVARCHAR(2000));
          IF @dFecha IS NULL SET @dFecha=CONVERT(DATE,SYSUTCDATETIME());
          IF NOT EXISTS(SELECT 1 FROM prod.EspeciePecuaria WHERE especie_pecuaria_id=@nEspecie AND estado=1) OR @nCantidad<0
             THROW 51059,N'Especie o cantidad inválida.',1;
          INSERT prod.CrianzaLote(predio_id,especie_pecuaria_id,nombre,fecha_inicio) VALUES(@nPredio,@nEspecie,@cNombre,@dFecha);
          SET @nEntidad=SCOPE_IDENTITY();
          IF @nCantidad IS NOT NULL OR NULLIF(@cNota,N'') IS NOT NULL
            INSERT prod.CrianzaConteo(crianza_lote_id,cantidad,fecha_observacion,observacion,usuario_id)
            VALUES(@nEntidad,@nCantidad,@dFecha,@cNota,@nUsuario);
        END
        ELSE IF @cOperacion='CONTEO_CREAR'
        BEGIN
          SELECT @nLote=loteId,@nCantidad=cantidad,@dFecha=fecha,@cNota=observacion
          FROM OPENJSON(@cJson,'$.datos') WITH(loteId BIGINT,cantidad INT,fecha DATE,observacion NVARCHAR(2000));
          IF @dFecha IS NULL SET @dFecha=CONVERT(DATE,SYSUTCDATETIME());
          IF NOT EXISTS(SELECT 1 FROM prod.CrianzaLote WHERE crianza_lote_id=@nLote AND predio_id=@nPredio AND estado=1) OR @nCantidad<0
             THROW 51060,N'Lote o cantidad inválida.',1;
          INSERT prod.CrianzaConteo(crianza_lote_id,cantidad,fecha_observacion,observacion,usuario_id)
          VALUES(@nLote,@nCantidad,@dFecha,@cNota,@nUsuario);
          SET @nEntidad=SCOPE_IDENTITY();
        END
        ELSE IF @cOperacion='FICHA_COMPLETAR'
        BEGIN
          EXEC prod.PA_E1_Predio_Upd_Ficha @cJson,@nPredio,@nEntidad OUTPUT;
        END
        ELSE IF @cOperacion='ACTUACION_CREAR'
        BEGIN
          SELECT @cTipo=tipo,@cNota=observacion,@fHecho=fechaHecho,@nLote=crianzaId,@nCultivoParcela=cultivoId
          FROM OPENJSON(@cJson,'$.datos') WITH(tipo VARCHAR(40),observacion NVARCHAR(2000),fechaHecho DATETIME2(0),crianzaId BIGINT,cultivoId BIGINT);
          IF @fHecho IS NULL SET @fHecho=SYSUTCDATETIME();
          IF @fHecho>DATEADD(HOUR,1,SYSUTCDATETIME()) OR @cTipo NOT IN('GENERAL','CULTIVO','CRIANZA','SANIDAD','NECESIDAD','SEGUIMIENTO')
             OR LEN(NULLIF(LTRIM(RTRIM(@cNota)),''))<3 OR
             (@nLote IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.CrianzaLote WHERE crianza_lote_id=@nLote AND predio_id=@nPredio)) OR
             (@nCultivoParcela IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.ParcelaCultivo PC JOIN prod.Parcela PA ON PA.parcela_id=PC.parcela_id WHERE PC.parcela_cultivo_id=@nCultivoParcela AND PA.predio_id=@nPredio))
             THROW 51062,N'Actuación inválida.',1;
          INSERT prod.ExpedienteActuacion(predio_id,uot_id,convenio_uot_organizacion_id,parcela_cultivo_id,crianza_lote_id,
             tipo,observacion,fecha_hecho,usuario_id,correlacion_id)
          VALUES(@nPredio,@nUot,@nConvenio,@nCultivoParcela,@nLote,@cTipo,@cNota,@fHecho,@nUsuario,@gCorr);
          SET @nEntidad=SCOPE_IDENTITY();
        END
        ELSE THROW 51063,N'Operación de expediente desconocida.',1;
        -- Cada alta o nueva versión incorpora un acto fechado: no se reescribe lo anterior.
        IF @cOperacion IN('PREDIO_CREAR','AMBITO_VINCULAR','CULTIVO_CREAR','CRIANZA_CREAR','CONTEO_CREAR','FICHA_COMPLETAR')
            INSERT prod.ExpedienteActuacion(predio_id,uot_id,convenio_uot_organizacion_id,parcela_cultivo_id,crianza_lote_id,
                   tipo,observacion,fecha_hecho,usuario_id,correlacion_id)
            VALUES(@nPredio,@nUot,@nConvenio,
                   CASE WHEN @cOperacion='CULTIVO_CREAR' THEN @nEntidad END,
                   CASE WHEN @cOperacion='CRIANZA_CREAR' THEN @nEntidad WHEN @cOperacion='CONTEO_CREAR' THEN @nLote END,
                   CASE WHEN @cOperacion='CULTIVO_CREAR' THEN 'CULTIVO'
                        WHEN @cOperacion IN('CRIANZA_CREAR','CONTEO_CREAR') THEN 'CRIANZA' ELSE 'GENERAL' END,
                   CASE @cOperacion
                     WHEN 'PREDIO_CREAR' THEN N'Ficha de fundo registrada.'
                     WHEN 'AMBITO_VINCULAR' THEN N'Predio vinculado al convenio.'
                     WHEN 'CULTIVO_CREAR' THEN N'Nuevo cultivo registrado.'
                     WHEN 'CRIANZA_CREAR' THEN N'Actividad pecuaria registrada.'
                     WHEN 'CONTEO_CREAR' THEN N'Conteo pecuario incorporado al historial.'
                     ELSE N'Información complementaria de ficha versionada.' END,
                   COALESCE(CONVERT(DATETIME2(0),@dFecha),SYSUTCDATETIME()),@nUsuario,@gCorr);
        -- Se guarda el identificador en idempotencia y la actuación queda auditada.
        SET @cDatos=(SELECT @nEntidad id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
        SET @cIdEntidad = CONVERT(NVARCHAR(200), @nEntidad);
        EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @nUsuario,@nSesion,@nDisp,@nModulo,'CREAR','prod',
           'ExpedienteProductivo',@cIdEntidad,NULL,@cDatos,NULL,'estado',NULL,'1',@cIp,@gCorr,@gSolicitud,@cEndpoint,@nAud OUTPUT,@nTrans OUTPUT;
        EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOp,'COMPLETADA','prod','ExpedienteProductivo',
            @cIdEntidad,'EXPEDIENTE_OK',@bFin OUTPUT,@cMsgFin OUTPUT;
        IF ISNULL(@bFin,0)=0 THROW 51064,N'No se pudo finalizar la operación idempotente.',1;
        COMMIT TRANSACTION;
      END;
      SET @bResultado=1; SET @nHttpRespuesta=200; SET @cCodigoRespuesta='EXPEDIENTE_OK'; SET @cMensaje=N'Operación completada.';
    END TRY
    BEGIN CATCH
      -- Capturar contexto antes de cualquier operacion adicional.
      DECLARE @__NumeroE1 INT=ERROR_NUMBER(),@__MensajeE1 NVARCHAR(2048)=ERROR_MESSAGE(),
              @__ProcE1 NVARCHAR(256)=ERROR_PROCEDURE(),@__LineaE1 INT=ERROR_LINE();
      IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
      SET @bResultado=0; SET @cDatos=NULL;
      -- Diagnostico para soporte: el usuario nunca recibe la excepcion interna.
      BEGIN TRY
        INSERT auditoria.ExpedienteErrorTecnico
          (correlacion_id,operacion,uot_id,convenio_id,persona_id,numero_sql,procedimiento,linea_sql,mensaje_sql)
        VALUES(@gCorr,@cOperacion,@nUot,@nConvenio,
               TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.personaId')),
               @__NumeroE1,@__ProcE1,@__LineaE1,@__MensajeE1);
      END TRY BEGIN CATCH
        SET @cMensaje=@cMensaje; -- El fallo del registro técnico no altera la respuesta original.
      END CATCH;
      SET @nHttpRespuesta=CASE WHEN @__NumeroE1=51068 THEN 500
          WHEN @__NumeroE1 IN(51053,51054,51056,51058) THEN 403
          WHEN @__NumeroE1 IN(2601,2627) THEN 409
          WHEN @__NumeroE1 IN(547,515,8115,51029) THEN 400 ELSE 400 END;
      SET @cCodigoRespuesta=CASE WHEN @__NumeroE1=51068 THEN 'EXPEDIENTE_RESPUESTA_INVALIDA'
          WHEN @__NumeroE1 IN(2601,2627) THEN 'EXPEDIENTE_DUPLICADO'
          WHEN @__NumeroE1=547 THEN 'EXPEDIENTE_REFERENCIA_INVALIDA'
          WHEN @__NumeroE1=515 THEN 'EXPEDIENTE_DATO_OBLIGATORIO'
          WHEN @__NumeroE1=8115 THEN 'EXPEDIENTE_VALOR_FUERA_RANGO'
          WHEN @__NumeroE1=51029 THEN 'EXPEDIENTE_VERSION_VIGENTE'
          ELSE 'EXPEDIENTE_ERROR' END;
      SET @cMensaje=CASE WHEN @__NumeroE1 BETWEEN 51050 AND 51067 THEN LEFT(@__MensajeE1,300)
          WHEN @__NumeroE1 IN(2601,2627) THEN N'Ya existe un registro con estos datos. Revise si el fundo esta registrado.'
          WHEN @__NumeroE1=547 THEN N'Alguna referencia de titular, distrito o centro poblado no esta vigente.'
          WHEN @__NumeroE1=515 THEN N'Falta un dato obligatorio para completar el registro del predio.'
          WHEN @__NumeroE1=8115 THEN N'Un valor numerico excede el rango permitido.'
          WHEN @__NumeroE1=51029 THEN N'El predio ya tiene una ficha tecnica vigente.'
          ELSE N'No se pudo completar la operación. Informe la referencia de la solicitud a soporte.' END;
      IF @nOp IS NOT NULL AND ISNULL(@bRep,0)=0
        EXEC auditoria.PA_OperacionIdempotente_Upd_MensajeFallido
          @nOperacionIdempotenteId=@nOp,@cMensajeResultado=@cMensaje,
          @bResultado=@bFallo OUTPUT,@cMensaje=@cMsgFallo OUTPUT;
    END CATCH;
END;
GO
