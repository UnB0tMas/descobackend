IF OBJECT_ID(N'[archivo].[PA_Archivo_Ins_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [archivo].[PA_Archivo_Ins_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : archivo.PA_Archivo_Ins_Registro
' Descripción             : Registra un archivo y sus vínculos con entidades de DESCO.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Archivo
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo. Sustituir JSON, IDs y valores por datos válidos del entorno.
    DECLARE
        @nArchivoId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [archivo].[PA_Archivo_Ins_Registro]
        @cJson = N'{}',
        @nArchivoId = @nArchivoId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nArchivoId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [archivo].[PA_Archivo_Ins_Registro]
(
    @cJson NVARCHAR(MAX),
    @nArchivoId BIGINT OUTPUT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS
BEGIN
    SET @cMensaje=NULL; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;

    /* Respuesta explícita; mensajes públicos aprobados. */
    SET NOCOUNT ON;
    DECLARE @__DbTranEntrada INT = @@TRANCOUNT,
            @__DbTranAbierta BIT = 0,
            @__DbSavepoint VARCHAR(32) = REPLACE(CONVERT(VARCHAR(36),NEWID()),'-',''),
            @__DbMensaje NVARCHAR(300),
            @__DbError BIT = 0;
    SET @bResultado = 0;
    SET ANSI_NULLS ON;
    SET ANSI_PADDING ON;
    SET ANSI_WARNINGS ON;
    SET ARITHABORT ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET NUMERIC_ROUNDABORT OFF;

    BEGIN TRY

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,
        @gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
        @nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),
        @bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),@nAud BIGINT,@nTrans BIGINT,
        @cNombre NVARCHAR(255),@cMime VARCHAR(120),@cPublic NVARCHAR(255),@cUrl NVARCHAR(1000),
        @nTam BIGINT,@cTipo VARCHAR(40),@cCategoria VARCHAR(30),@cOrigen VARCHAR(20),
        @cDesc NVARCHAR(400),@dCaptura DATETIME2(0),@nLat DECIMAL(9,6),@nLon DECIMAL(9,6),
        @gPos GEOGRAPHY,@nVinculos INT,@cIdent NVARCHAR(200),@cPost NVARCHAR(MAX),
        @cAccionAuditoria VARCHAR(40),
        @nPredio BIGINT,@nSalida BIGINT,@nVisita BIGINT,@nCaso BIGINT,@nTrat BIGINT,@nEntrega BIGINT,
        @nInc BIGINT,@nAjuste BIGINT,@nGasto BIGINT,@nLiq BIGINT,@nPago BIGINT,@nCobro BIGINT,
        @nSocio BIGINT,@nEmpleado BIGINT,@nParcela BIGINT,@nCultivo BIGINT,@nCenso BIGINT,@nEval BIGINT,
        @nSeg BIGINT,@nProd BIGINT,@nCamp BIGINT,@nPrecio BIGINT,@nPart BIGINT,@nOper BIGINT,
        @nJA BIGINT,@nJD BIGINT,@nBien BIGINT,@nRecurso BIGINT;

    SELECT @bResultado=0,@cMensaje=N'No se pudo registrar el documento.';

    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente]
        @cJson=@cJson,@cCodigoPermiso='ARCHIVOS_CREAR',@cAmbito='ARCHIVO_REGISTRAR',
        @nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,
        @nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,
        @nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,
        @cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@nOperacionIdempotenteId=@nOp OUTPUT,
        @bEsRepetida=@bRep OUTPUT,@cEstadoOperacion=@cEstadoOp OUTPUT,
        @cIdentificadorResultado=@cIdRes OUTPUT,@cCodigoResultado=@cCodRes OUTPUT,
        @bResultado=@bIni OUTPUT,@cMensaje=@cMsg OUTPUT;

    IF @bIni=0 AND @bRep=0
    BEGIN
        SET @cMensaje=@cMsg;
        GOTO __DESCO_Salida;
    END;

    IF @bRep=1
    BEGIN
        SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END;
        SET @nArchivoId=CASE WHEN @cEstadoOp='COMPLETADA' THEN TRY_CONVERT(BIGINT,@cIdRes) ELSE NULL END;
        SET @cMensaje=CASE
            WHEN @cEstadoOp='COMPLETADA' THEN N'La solicitud ya fue procesada correctamente.'
            ELSE N'La solicitud ya se encuentra en proceso.'
        END;
        GOTO __DESCO_Salida;
    END;

    SET @nArchivoId=NULL;

    SELECT
        @cNombre=NULLIF(LTRIM(RTRIM(nombreOriginal)),N''),
        @cMime=NULLIF(LTRIM(RTRIM(mimeType)),''),
        @cPublic=NULLIF(LTRIM(RTRIM(cloudinaryPublicId)),N''),
        @cUrl=NULLIF(LTRIM(RTRIM(secureUrl)),N''),
        @nTam=tamanoBytes,
        @cTipo=UPPER(NULLIF(LTRIM(RTRIM(tipoEvidencia)),'')),
        @cCategoria=UPPER(NULLIF(LTRIM(RTRIM(categoria)),'')),
        @cOrigen=UPPER(NULLIF(LTRIM(RTRIM(origenCaptura)),'')),
        @cDesc=NULLIF(LTRIM(RTRIM(descripcion)),N''),
        @dCaptura=fechaCaptura,
        @nLat=latitudCaptura,
        @nLon=longitudCaptura
    FROM OPENJSON(@cJson,'$.archivo')
    WITH
    (
        nombreOriginal NVARCHAR(255) '$.nombreOriginal',
        mimeType VARCHAR(120) '$.mimeType',
        cloudinaryPublicId NVARCHAR(255) '$.cloudinaryPublicId',
        secureUrl NVARCHAR(1000) '$.secureUrl',
        tamanoBytes BIGINT '$.tamanoBytes',
        tipoEvidencia VARCHAR(40) '$.tipoEvidencia',
        categoria VARCHAR(30) '$.categoria',
        origenCaptura VARCHAR(20) '$.origenCaptura',
        descripcion NVARCHAR(400) '$.descripcion',
        fechaCaptura DATETIME2(0) '$.fechaCaptura',
        latitudCaptura DECIMAL(9,6) '$.latitudCaptura',
        longitudCaptura DECIMAL(9,6) '$.longitudCaptura'
    );

    IF @cOrigen IS NULL
        SET @cOrigen='CARGA';

    IF @cOrigen='ARCHIVO'
        SET @cOrigen='CARGA';

    IF @cOrigen NOT IN('CARGA','CAMARA')
    BEGIN
        SET @cMensaje=N'El origen del documento no es válido.';
        GOTO Fallar;
    END;

    IF @cCategoria IS NOT NULL
       AND @cCategoria NOT IN('FOTOGRAFIA','DOCUMENTO','TICKET','COMPROBANTE','OTRO')
    BEGIN
        SET @cMensaje=N'La categoría del documento no es válida.';
        GOTO Fallar;
    END;

    IF @cOrigen='CAMARA' AND @cCategoria IS NULL
        SET @cCategoria='FOTOGRAFIA';

    IF (@nLat IS NULL AND @nLon IS NOT NULL)
       OR (@nLat IS NOT NULL AND @nLon IS NULL)
       OR (@nLat IS NOT NULL AND (@nLat<-90 OR @nLat>90))
       OR (@nLon IS NOT NULL AND (@nLon<-180 OR @nLon>180))
    BEGIN
        SET @cMensaje=N'La ubicación de captura no es válida.';
        GOTO Fallar;
    END;

    IF @dCaptura IS NOT NULL AND @dCaptura>SYSUTCDATETIME()
    BEGIN
        SET @cMensaje=N'La fecha de captura no puede estar en el futuro.';
        GOTO Fallar;
    END;

    IF @cOrigen='CAMARA' AND @dCaptura IS NULL
        SET @dCaptura=SYSUTCDATETIME();

    IF @nLat IS NOT NULL AND @nLon IS NOT NULL
        SET @gPos=GEOGRAPHY::Point(CONVERT(FLOAT,@nLat),CONVERT(FLOAT,@nLon),4326);

    SELECT
        @nPredio=predioId,@nSalida=salidaCampoId,@nVisita=visitaTecnicaId,
        @nCaso=casoFitosanitarioId,@nTrat=tratamientoId,@nEntrega=entregaSocioId,
        @nInc=incidenciaOperativaId,@nAjuste=ajustePrecioSocioId,@nGasto=gastoCampaniaId,
        @nLiq=liquidacionSocioId,@nPago=pagoSocioId,@nCobro=cobroCompradorId,
        @nSocio=socioId,@nEmpleado=empleadoId,@nParcela=parcelaId,@nCultivo=parcelaCultivoId,
        @nCenso=censoPlantasId,@nEval=evaluacionAgronomicaId,@nSeg=seguimientoFitosanitarioId,
        @nProd=disponibilidadProduccionId,@nCamp=campaniaVentaId,@nPrecio=precioComercialId,
        @nPart=participacionCampaniaSocioId,@nOper=operativoVentaId,@nJA=jabaAsignacionId,
        @nJD=jabaDevolucionId,@nBien=bienInventarioId,@nRecurso=recursoProgramadoId
    FROM OPENJSON(@cJson,'$.vinculo')
    WITH
    (
        predioId BIGINT '$.predioId',
        salidaCampoId BIGINT '$.salidaCampoId',
        visitaTecnicaId BIGINT '$.visitaTecnicaId',
        casoFitosanitarioId BIGINT '$.casoFitosanitarioId',
        tratamientoId BIGINT '$.tratamientoId',
        entregaSocioId BIGINT '$.entregaSocioId',
        incidenciaOperativaId BIGINT '$.incidenciaOperativaId',
        ajustePrecioSocioId BIGINT '$.ajustePrecioSocioId',
        gastoCampaniaId BIGINT '$.gastoCampaniaId',
        liquidacionSocioId BIGINT '$.liquidacionSocioId',
        pagoSocioId BIGINT '$.pagoSocioId',
        cobroCompradorId BIGINT '$.cobroCompradorId',
        socioId BIGINT '$.socioId',
        empleadoId BIGINT '$.empleadoId',
        parcelaId BIGINT '$.parcelaId',
        parcelaCultivoId BIGINT '$.parcelaCultivoId',
        censoPlantasId BIGINT '$.censoPlantasId',
        evaluacionAgronomicaId BIGINT '$.evaluacionAgronomicaId',
        seguimientoFitosanitarioId BIGINT '$.seguimientoFitosanitarioId',
        disponibilidadProduccionId BIGINT '$.disponibilidadProduccionId',
        campaniaVentaId BIGINT '$.campaniaVentaId',
        precioComercialId BIGINT '$.precioComercialId',
        participacionCampaniaSocioId BIGINT '$.participacionCampaniaSocioId',
        operativoVentaId BIGINT '$.operativoVentaId',
        jabaAsignacionId BIGINT '$.jabaAsignacionId',
        jabaDevolucionId BIGINT '$.jabaDevolucionId',
        bienInventarioId BIGINT '$.bienInventarioId',
        recursoProgramadoId BIGINT '$.recursoProgramadoId'
    );

    SET @nVinculos=
        (CASE WHEN @nPredio IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nSalida IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nVisita IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nCaso IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nTrat IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nEntrega IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nInc IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nAjuste IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nGasto IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nLiq IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nPago IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nCobro IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nSocio IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nEmpleado IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nParcela IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nCultivo IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nCenso IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nEval IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nSeg IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nProd IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nCamp IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nPrecio IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nPart IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nOper IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nJA IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nJD IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nBien IS NULL THEN 0 ELSE 1 END)+
        (CASE WHEN @nRecurso IS NULL THEN 0 ELSE 1 END);

    IF @cNombre IS NULL
       OR @cMime IS NULL
       OR @cPublic IS NULL
       OR @cUrl IS NULL
       OR @cUrl NOT LIKE 'https://%'
       OR @nVinculos<>1
       OR (@nTam IS NOT NULL AND @nTam<0)
    BEGIN
        SET @cMensaje=N'Complete correctamente los datos del documento y seleccione un solo contexto.';
        GOTO Fallar;
    END;

    DECLARE @PermisosContexto TABLE(codigo VARCHAR(40) NOT NULL PRIMARY KEY);
    INSERT INTO @PermisosContexto(codigo)
    SELECT DISTINCT P.codigo
    FROM [seg].[UsuarioRol] UR
    INNER JOIN [seg].[Rol] R ON R.rol_id=UR.rol_id AND R.estado=1
    INNER JOIN [seg].[RolPermiso] RP ON RP.rol_id=R.rol_id AND RP.estado=1
    INNER JOIN [seg].[Permiso] P ON P.permiso_id=RP.permiso_id AND P.estado=1
    WHERE UR.usuario_id=@nUsuario
      AND UR.estado=1
      AND UR.fecha_desde<=SYSUTCDATETIME()
      AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta>=SYSUTCDATETIME());

    IF NOT
    (
        (@nSocio IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('PRODUCTORES_LISTAR','PRODUCTORES_VER')))
     OR (@nEmpleado IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('EMPLEADOS_LISTAR','EMPLEADOS_VER')))
     OR (@nPredio IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('PREDIOS_LISTAR','PREDIOS_VER')))
     OR ((@nParcela IS NOT NULL OR @nCultivo IS NOT NULL) AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('CULTIVOS_LISTAR','CULTIVOS_VER')))
     OR (@nCenso IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('CENSOS_LISTAR','CENSOS_VER')))
     OR (@nSalida IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('SALIDAS_LISTAR','SALIDAS_VER')))
     OR (@nVisita IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('VISITAS_LISTAR','VISITAS_VER')))
     OR (@nEval IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('EVALUACIONES_LISTAR','EVALUACIONES_VER')))
     OR ((@nCaso IS NOT NULL OR @nTrat IS NOT NULL OR @nSeg IS NOT NULL) AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('SANIDAD_LISTAR','SANIDAD_VER')))
     OR (@nProd IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('PRODUCCION_LISTAR','PRODUCCION_VER')))
     OR (@nCamp IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('CAMPANIAS_LISTAR','CAMPANIAS_VER')))
     OR (@nPrecio IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('PRECIOS_LISTAR','PRECIOS_VER')))
     OR (@nPart IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('PARTICIPANTES_LISTAR','PARTICIPANTES_VER')))
     OR (@nOper IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('OPERATIVOS_LISTAR','OPERATIVOS_VER')))
     OR ((@nJA IS NOT NULL OR @nJD IS NOT NULL) AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('JABAS_LISTAR','JABAS_VER')))
     OR (@nEntrega IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('ENTREGAS_LISTAR','ENTREGAS_VER')))
     OR (@nInc IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('INCIDENCIAS_LISTAR','INCIDENCIAS_VER')))
     OR (@nAjuste IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('AJUSTES_LISTAR','AJUSTES_VER')))
     OR (@nBien IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('INVENTARIO_LISTAR','INVENTARIO_VER')))
     OR (@nRecurso IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('RECURSOS_LISTAR','RECURSOS_VER')))
     OR (@nGasto IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('GASTOS_LISTAR','GASTOS_VER')))
     OR (@nLiq IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('LIQUIDACIONES_LISTAR','LIQUIDACIONES_VER')))
     OR (@nPago IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('PAGOS_LISTAR','PAGOS_VER')))
     OR (@nCobro IS NOT NULL AND EXISTS(SELECT 1 FROM @PermisosContexto WHERE codigo IN('COBROS_LISTAR','COBROS_VER')))
    )
    BEGIN
        SET @cMensaje=N'El contexto seleccionado no está disponible para su perfil.';
        GOTO Fallar;
    END;

    IF @cOrigen='CAMARA' AND @cMime NOT LIKE 'image/%'
    BEGIN
        SET @cMensaje=N'La captura de cámara debe corresponder a una imagen.';
        GOTO Fallar;
    END;

    IF
       (@nSalida IS NOT NULL AND EXISTS
        (
            SELECT 1 FROM [campo].[SalidaCampo]
            WHERE salida_campo_id=@nSalida
              AND estado=1
              AND estado_proceso IN('FINALIZADA','CANCELADA')
        ))
       OR
       (@nVisita IS NOT NULL AND EXISTS
        (
            SELECT 1 FROM [campo].[VisitaTecnica]
            WHERE visita_tecnica_id=@nVisita
              AND estado=1
              AND estado_proceso IN('FINALIZADA','ANULADA')
        ))
       OR
       (@nEval IS NOT NULL AND EXISTS
        (
            SELECT 1
            FROM [campo].[EvaluacionAgronomica] EA
            INNER JOIN [campo].[VisitaTecnica] V
                ON V.visita_tecnica_id=EA.visita_tecnica_id
            WHERE EA.evaluacion_agronomica_id=@nEval
              AND EA.estado=1
              AND V.estado=1
              AND V.estado_proceso IN('FINALIZADA','ANULADA')
        ))
       OR
       (@nCaso IS NOT NULL AND EXISTS
        (
            SELECT 1 FROM [sanidad].[CasoFitosanitario]
            WHERE caso_fitosanitario_id=@nCaso
              AND estado=1
              AND estado_caso='CERRADO'
        ))
       OR
       (@nTrat IS NOT NULL AND EXISTS
        (
            SELECT 1
            FROM [sanidad].[TratamientoFitosanitario] T
            INNER JOIN [sanidad].[CasoFitosanitario] C
                ON C.caso_fitosanitario_id=T.caso_fitosanitario_id
            WHERE T.tratamiento_fitosanitario_id=@nTrat
              AND T.estado=1
              AND C.estado=1
              AND C.estado_caso='CERRADO'
        ))
       OR
       (@nSeg IS NOT NULL AND EXISTS
        (
            SELECT 1
            FROM [sanidad].[SeguimientoFitosanitario] S
            INNER JOIN [sanidad].[CasoFitosanitario] C
                ON C.caso_fitosanitario_id=S.caso_fitosanitario_id
            WHERE S.seguimiento_fitosanitario_id=@nSeg
              AND S.estado=1
              AND C.estado=1
              AND C.estado_caso='CERRADO'
        ))
       OR
       (@nProd IS NOT NULL AND EXISTS
        (
            SELECT 1 FROM [prod].[DisponibilidadProduccion]
            WHERE disponibilidad_produccion_id=@nProd
              AND estado=1
              AND estado_estimacion IN('CONFIRMADA','DESCARTADA')
        ))
       OR
       (@nCultivo IS NOT NULL AND EXISTS
        (
            SELECT 1 FROM [prod].[ParcelaCultivo]
            WHERE parcela_cultivo_id=@nCultivo
              AND estado=1
              AND situacion_cultivo IN('FINALIZADO','ABANDONADO')
        ))
       OR
       (@nCenso IS NOT NULL AND EXISTS
        (
            SELECT 1
            FROM [prod].[CensoPlantas] C
            INNER JOIN [prod].[ParcelaCultivo] PC
                ON PC.parcela_cultivo_id=C.parcela_cultivo_id
            WHERE C.censo_plantas_id=@nCenso
              AND C.estado=1
              AND PC.estado=1
              AND PC.situacion_cultivo IN('FINALIZADO','ABANDONADO')
        ))
    BEGIN
        SET @cMensaje=N'El contexto seleccionado ya forma parte del historial cerrado y no admite nuevas evidencias.';
        GOTO Fallar;
    END;

    IF
       (@nCamp IS NOT NULL AND EXISTS(SELECT 1 FROM [comercial].[CampaniaVenta] WHERE campania_venta_id=@nCamp AND estado=1 AND estado_proceso IN('CERRADA','CANCELADA')))
       OR (@nPrecio IS NOT NULL AND EXISTS
           (SELECT 1 FROM [comercial].[PrecioComercial] P INNER JOIN [comercial].[CampaniaVenta] C ON C.campania_venta_id=P.campania_venta_id WHERE P.precio_comercial_id=@nPrecio AND (P.estado=0 OR C.estado_proceso IN('CERRADA','CANCELADA'))))
       OR (@nPart IS NOT NULL AND EXISTS
           (SELECT 1 FROM [comercial].[ParticipacionCampaniaSocio] P INNER JOIN [comercial].[CampaniaVenta] C ON C.campania_venta_id=P.campania_venta_id WHERE P.participacion_campania_socio_id=@nPart AND P.estado=1 AND (P.estado_participacion IN('RETIRADO','EXCLUIDO') OR C.estado_proceso IN('CERRADA','CANCELADA'))))
       OR (@nOper IS NOT NULL AND EXISTS(SELECT 1 FROM [comercial].[OperativoVenta] WHERE operativo_venta_id=@nOper AND estado=1 AND estado_proceso IN('CERRADO','CANCELADO')))
       OR (@nJA IS NOT NULL AND EXISTS
           (SELECT 1 FROM [comercial].[JabaAsignacion] JA INNER JOIN [comercial].[OperativoSocio] OS ON OS.operativo_socio_id=JA.operativo_socio_id INNER JOIN [comercial].[OperativoVenta] O ON O.operativo_venta_id=OS.operativo_venta_id WHERE JA.jaba_asignacion_id=@nJA AND (JA.estado=0 OR O.estado_proceso IN('CERRADO','CANCELADO'))))
       OR (@nJD IS NOT NULL AND EXISTS
           (SELECT 1 FROM [comercial].[JabaDevolucion] JD INNER JOIN [comercial].[JabaAsignacion] JA ON JA.jaba_asignacion_id=JD.jaba_asignacion_id INNER JOIN [comercial].[OperativoSocio] OS ON OS.operativo_socio_id=JA.operativo_socio_id INNER JOIN [comercial].[OperativoVenta] O ON O.operativo_venta_id=OS.operativo_venta_id WHERE JD.jaba_devolucion_id=@nJD AND (JD.estado=0 OR O.estado_proceso IN('CERRADO','CANCELADO'))))
       OR (@nEntrega IS NOT NULL AND EXISTS(SELECT 1 FROM [comercial].[EntregaSocio] WHERE entrega_socio_id=@nEntrega AND estado=1 AND estado_proceso IN('CONFIRMADA','ANULADA')))
       OR (@nInc IS NOT NULL AND EXISTS(SELECT 1 FROM [comercial].[IncidenciaOperativa] WHERE incidencia_operativa_id=@nInc AND estado=1 AND estado_incidencia IN('RESUELTA','ANULADA')))
       OR (@nAjuste IS NOT NULL AND EXISTS(SELECT 1 FROM [comercial].[AjustePrecioSocio] WHERE ajuste_precio_socio_id=@nAjuste AND estado=1 AND estado_ajuste='ANULADO'))
       OR (@nGasto IS NOT NULL AND EXISTS(SELECT 1 FROM [finanzas].[GastoCampania] WHERE gasto_campania_id=@nGasto AND estado=1 AND estado_proceso IN('APROBADO','ANULADO')))
       OR (@nLiq IS NOT NULL AND EXISTS(SELECT 1 FROM [finanzas].[LiquidacionSocio] WHERE liquidacion_socio_id=@nLiq AND estado=1 AND estado_proceso IN('APROBADA','PAGADA_PARCIAL','PAGADA','ANULADA')))
       OR (@nPago IS NOT NULL AND EXISTS(SELECT 1 FROM [finanzas].[PagoSocio] WHERE pago_socio_id=@nPago AND estado=1 AND estado_proceso IN('CONFIRMADO','ANULADO')))
       OR (@nCobro IS NOT NULL AND EXISTS(SELECT 1 FROM [finanzas].[CobroComprador] WHERE cobro_comprador_id=@nCobro AND estado=1 AND estado_proceso IN('CONFIRMADO','ANULADO')))
    BEGIN
        SET @cMensaje=N'El contexto seleccionado ya fue cerrado, confirmado o anulado y debe conservarse sin nuevas evidencias.';
        GOTO Fallar;
    END;

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        INSERT [archivo].[Archivo]
        (
            nombre_original,mime_type,cloudinary_public_id,secure_url,tamano_bytes,
            usuario_id,fecha_carga,estado,categoria,origen_captura,descripcion,
            fecha_captura,posicion_captura,tipo_evidencia
        )
        VALUES
        (
            @cNombre,@cMime,@cPublic,@cUrl,@nTam,
            @nUsuario,SYSUTCDATETIME(),1,@cCategoria,@cOrigen,@cDesc,
            @dCaptura,@gPos,@cTipo
        );

        SET @nArchivoId=CONVERT(BIGINT,SCOPE_IDENTITY());

        INSERT [archivo].[ArchivoVinculo]
        (
            archivo_id,predio_id,salida_campo_id,visita_tecnica_id,caso_fitosanitario_id,
            tratamiento_id,entrega_socio_id,incidencia_operativa_id,ajuste_precio_socio_id,
            gasto_campania_id,liquidacion_socio_id,pago_socio_id,cobro_comprador_id,
            socio_id,empleado_id,parcela_id,parcela_cultivo_id,censo_plantas_id,
            evaluacion_agronomica_id,seguimiento_fitosanitario_id,disponibilidad_produccion_id,
            campania_venta_id,precio_comercial_id,participacion_campania_socio_id,
            operativo_venta_id,jaba_asignacion_id,jaba_devolucion_id,bien_inventario_id,
            recurso_programado_id,estado
        )
        VALUES
        (
            @nArchivoId,@nPredio,@nSalida,@nVisita,@nCaso,
            @nTrat,@nEntrega,@nInc,@nAjuste,
            @nGasto,@nLiq,@nPago,@nCobro,
            @nSocio,@nEmpleado,@nParcela,@nCultivo,@nCenso,
            @nEval,@nSeg,@nProd,
            @nCamp,@nPrecio,@nPart,
            @nOper,@nJA,@nJD,@nBien,
            @nRecurso,1
        );

        SET @cIdent=CONVERT(NVARCHAR(200),@nArchivoId);

        SELECT @cPost=
        (
            SELECT
                @nArchivoId archivoId,
                @cNombre nombreOriginal,
                @cTipo tipoEvidencia,
                @cCategoria categoria,
                @cOrigen origenCaptura,
                @dCaptura fechaCaptura
            FOR JSON PATH,WITHOUT_ARRAY_WRAPPER
        );

        SET @cAccionAuditoria =
            CASE
                WHEN @cOrigen='CAMARA' THEN 'FOTOGRAFIA'
                ELSE 'SUBIR'
            END;

        EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio]
            @nUsuarioId=@nUsuario,
            @nSesionUsuarioId=@nSesion,
            @nDispositivoUsuarioId=@nDisp,
            @nModuloId=@nModulo,
            @cAccion=@cAccionAuditoria,
            @cEsquemaEntidad='archivo',
            @cNombreEntidad='Archivo',
            @cIdentificador=@cIdent,
            @cDatosAnteriores=NULL,
            @cDatosPosteriores=@cPost,
            @cMotivo=NULL,
            @cCampoEstado=NULL,
            @cEstadoAnterior=NULL,
            @cEstadoNuevo=NULL,
            @cIp=@cIp,
            @gCorrelacionId=@gCorr,
            @gSolicitudId=@gSol,
            @cEndpoint=@cEnd,
            @nAuditoriaEventoId=@nAud OUTPUT,
            @nTransicionEstadoId=@nTrans OUTPUT;

        /* Confirmar datos e idempotencia juntos. */

        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
            @nOperacionIdempotenteId=@nOp,
            @cEstadoOperacion='COMPLETADA',
            @cEsquemaEntidad='archivo',
            @cNombreEntidad='Archivo',
            @cIdentificadorResultado=@cIdent,
            @cCodigoResultado='ARCHIVO_REGISTRADO',
            @bResultado=@bFin OUTPUT,
            @cMensaje=@cMsgFin OUTPUT;
IF ISNULL(@bFin,0) = 0
    THROW 51003, N'DESCO_IDEMPOTENCIA_NO_CERRADA', 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;

        SET @bResultado=1;
        SET @cMensaje=CASE
            WHEN @cOrigen='CAMARA' THEN N'Fotografía registrada correctamente.'
            ELSE N'Documento registrado correctamente.'
        END;
        GOTO __DESCO_Salida;
    END TRY
    BEGIN CATCH
SET @bResultado = 0;

        IF XACT_STATE()<>0
            BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;

        SET @cMensaje=N'No se pudo registrar el documento. Verifique el contexto seleccionado e intente nuevamente.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'archivo.PA_Archivo_Ins_Registro',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;

Fallar:
    IF @nOp IS NOT NULL AND @bResultado=0
        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
            @nOperacionIdempotenteId=@nOp,
            @cEstadoOperacion='FALLIDA',
            @cEsquemaEntidad=NULL,
            @cNombreEntidad=NULL,
            @cIdentificadorResultado=NULL,
            @cCodigoResultado='NO_PROCESADO',
            @bResultado=@bFin OUTPUT,
            @cMensaje=@cMsgFin OUTPUT;

    END TRY
    BEGIN CATCH

        SET @__DbError = 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'archivo.PA_Archivo_Ins_Registro',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
    END CATCH;

__DESCO_Salida:
BEGIN TRY

IF @__DbTranAbierta = 1
BEGIN
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
IF ISNULL(@bResultado,0) = 1 OR NULLIF(@cMensaje,N'') IS NULL SET @cMensaje = N'La operación no se completó y sus cambios fueron revertidos.';
SET @bResultado = 0;
END;

    IF @bResultado = 0 AND @nOp IS NOT NULL AND XACT_STATE() <> -1
    BEGIN
        IF ISNULL(@bRep,0) = 0
        BEGIN
        BEGIN TRY
            EXEC [auditoria].[PA_OperacionIdempotente_Upd_MensajeFallido]
                 @nOperacionIdempotenteId = @nOp, @cMensajeResultado = @cMensaje;
        END TRY
        BEGIN CATCH
            -- No sustituir el motivo funcional por un fallo de registro secundario.
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'archivo.PA_Archivo_Ins_Registro',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
        END CATCH;
        END
        ELSE
        BEGIN
            SELECT @cMensaje = COALESCE(mensaje_resultado,
                CASE WHEN estado_operacion = 'FALLIDA'
                     THEN N'La solicitud anterior no se completó. Corrija los datos y envíe una nueva solicitud.'
                     ELSE N'La solicitud todavía se está procesando. Consulte el resultado antes de repetirla.' END)
            FROM [auditoria].[OperacionIdempotente]
            WHERE operacion_idempotente_id = @nOp;
        END;
    END;
IF @bResultado = 0
    SELECT @nArchivoId = NULL;

END TRY
BEGIN CATCH

        SET @__DbError = 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'archivo.PA_Archivo_Ins_Registro',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bResultado,0) = 1
BEGIN
SET @bResultado = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'archivo.PA_Archivo_Ins_Registro',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
