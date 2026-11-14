-- DESCO / 2026-11-06 / Auditoría AL-01, AL-02, AL-04 y AL-06.
-- Respeta el ámbito efectivo de sesión antes de paginar y corrige cantidades logísticas.
-- Ejemplo: seleccionar UOT 1 no debe listar predios exclusivos de UOT 2.
CREATE OR ALTER FUNCTION prod.FN_Predio_VisibleSesion(@Sesion BIGINT,@Usuario BIGINT,@Predio BIGINT,@Permiso VARCHAR(100))
RETURNS BIT AS
BEGIN
 DECLARE @Uot BIGINT,@Modo VARCHAR(12);
 SELECT @Uot=uot_contexto_id,@Modo=modo_uot FROM seg.SesionUsuario WHERE sesion_usuario_id=@Sesion AND estado=1 AND fecha_revocacion IS NULL;
 RETURN CASE WHEN EXISTS(SELECT 1 FROM prod.PredioAmbito A WHERE A.predio_id=@Predio AND A.estado=1
  AND (@Modo='GENERAL' OR A.uot_id=@Uot)
  AND seg.FN_Usuario_TienePermisoUOT(@Usuario,A.uot_id,@Permiso)=1
  AND (A.convenio_uot_organizacion_id IS NULL OR seg.FN_Usuario_TienePermisoUOT(@Usuario,A.uot_id,'APAPPSS_PREDIOS_LISTAR')=1)) THEN 1 ELSE 0 END;
END;
GO

-- sanidad.PA_CasoFitosanitario_Sel_Listado
/******************************************************************************************************
' Nombre del PA           : sanidad.PA_CasoFitosanitario_Sel_Listado
' Descripción             : Lista casos fitosanitarios.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Sanidad
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo: sustituir identificadores y valores por datos válidos.
    -- El JSON mostrado es ilustrativo y debe ajustarse al contrato del PA.
    DECLARE
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [sanidad].[PA_CasoFitosanitario_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE OR ALTER PROCEDURE [sanidad].[PA_CasoFitosanitario_Sel_Listado]
(
    @cJson NVARCHAR(MAX), @bResultado BIT OUTPUT, @cMensaje NVARCHAR(300) OUTPUT,
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
    BEGIN TRY
    SET NOCOUNT ON;
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,
            @cIp VARCHAR(64),@cEnd NVARCHAR(250),@bCtx BIT,@cMsg NVARCHAR(300),@cEstado VARCHAR(20),@cSeveridad VARCHAR(10),
            @nPredio BIGINT,@nSocio BIGINT,@nTipo SMALLINT,@dDesde DATE,@dHasta DATE,@nPagina INT=1,@nTam INT=25,@nOffset INT;
    SELECT @bResultado=0,@cMensaje=N'No se pudo consultar la sanidad vegetal.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado] @cJson=@cJson,@cCodigoPermiso='SANIDAD_LISTAR',@nUsuarioId=@nUsuario OUTPUT,
        @nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,
        @gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@bResultado=@bCtx OUTPUT,@cMensaje=@cMsg OUTPUT;
    IF @bCtx=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    SELECT @cEstado=UPPER(NULLIF(LTRIM(RTRIM(estadoCaso)),'')),@cSeveridad=UPPER(NULLIF(LTRIM(RTRIM(severidad)),'')),@nPredio=predioId,
           @nSocio=socioId,@nTipo=tipoProblemaId,@dDesde=fechaDesde,@dHasta=fechaHasta
    FROM OPENJSON(@cJson,'$.filtros') WITH(estadoCaso VARCHAR(20) '$.estadoCaso',severidad VARCHAR(10) '$.severidad',predioId BIGINT '$.predioId',socioId BIGINT '$.socioId',tipoProblemaId SMALLINT '$.tipoProblemaId',fechaDesde DATE '$.fechaDesde',fechaHasta DATE '$.fechaHasta');
    SELECT @nPagina=COALESCE(pagina,1),@nTam=COALESCE(tamano,25) FROM OPENJSON(@cJson,'$.paginacion') WITH(pagina INT '$.pagina',tamano INT '$.tamano');
    IF @nPagina<1 SET @nPagina=1;
 IF @nTam<1 SET @nTam=25;
 IF @nTam>200 SET @nTam=200;
 SET @nOffset=(@nPagina-1)*@nTam;
    SELECT CF.caso_fitosanitario_id casoFitosanitarioId,CF.fecha_deteccion fechaDeteccion,CF.estado_caso estadoCaso,CF.severidad,
           CF.plantas_afectadas plantasAfectadas,CF.cantidad_estimada cantidadEstimada,TP.codigo codigoProblema,TP.nombre problema,
           PC.parcela_cultivo_id parcelaCultivoId,P.parcela_id parcelaId,P.nombre parcelaNombre,PR.predio_id predioId,PR.codigo predioCodigo,PR.nombre predioNombre,
           S.socio_id socioId,PER.numero_documento numeroDocumento,CONCAT(PER.nombres,N' ',PER.apellido_paterno,N' ',COALESCE(PER.apellido_materno,N'')) socioNombre,
           (SELECT COUNT_BIG(*) FROM [archivo].[ArchivoVinculo] AV INNER JOIN [archivo].[Archivo] A ON A.archivo_id=AV.archivo_id AND A.estado=1 WHERE AV.caso_fitosanitario_id=CF.caso_fitosanitario_id AND AV.estado=1) evidencias,
           COUNT_BIG(*) OVER() totalRegistros
    FROM [sanidad].[CasoFitosanitario] CF
    INNER JOIN [sanidad].[TipoProblemaFitosanitario] TP ON TP.tipo_problema_fitosanitario_id=CF.tipo_problema_fitosanitario_id
    INNER JOIN [prod].[ParcelaCultivo] PC ON PC.parcela_cultivo_id=CF.parcela_cultivo_id
    INNER JOIN [prod].[Parcela] P ON P.parcela_id=PC.parcela_id
    INNER JOIN [prod].[Predio] PR ON PR.predio_id=P.predio_id
    OUTER APPLY(SELECT TOP(1) PT.socio_id FROM [prod].[PredioTitularidad] PT WHERE PT.predio_id=PR.predio_id AND PT.estado=1 AND PT.fecha_hasta IS NULL ORDER BY PT.fecha_desde DESC) T
    LEFT JOIN [org].[Socio] S ON S.socio_id=T.socio_id LEFT JOIN [org].[Persona] PER ON PER.persona_id=S.socio_id
    WHERE CF.estado=1 AND prod.FN_Predio_VisibleSesion(@nSesion,@nUsuario,PR.predio_id,'SANIDAD_LISTAR')=1 AND (@cEstado IS NULL OR CF.estado_caso=@cEstado) AND (@cSeveridad IS NULL OR CF.severidad=@cSeveridad)
      AND (@nPredio IS NULL OR PR.predio_id=@nPredio) AND (@nSocio IS NULL OR S.socio_id=@nSocio)
      AND (@nTipo IS NULL OR CF.tipo_problema_fitosanitario_id=@nTipo)
      AND (@dDesde IS NULL OR CONVERT(DATE,CF.fecha_deteccion)>=@dDesde) AND (@dHasta IS NULL OR CONVERT(DATE,CF.fecha_deteccion)<=@dHasta)
    ORDER BY CF.fecha_deteccion DESC,CF.caso_fitosanitario_id DESC OFFSET @nOffset ROWS FETCH NEXT @nTam ROWS ONLY;
    SET @bResultado=1;
 SET @cMensaje=N'Casos sanitarios cargados correctamente.';
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
    @cProcedimiento = N'sanidad.PA_CasoFitosanitario_Sel_Listado',
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
    @cProcedimiento = N'sanidad.PA_CasoFitosanitario_Sel_Listado',
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
FROM config.FN_RespuestaUsuario(N'sanidad.PA_CasoFitosanitario_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO

-- prod.PA_DisponibilidadProduccion_Sel_Listado
/******************************************************************************************************
' Nombre del PA           : prod.PA_DisponibilidadProduccion_Sel_Listado
' Descripción             : Lista disponibilidades de producción.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Producción
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo: sustituir identificadores y valores por datos válidos.
    -- El JSON mostrado es ilustrativo y debe ajustarse al contrato del PA.
    DECLARE
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [prod].[PA_DisponibilidadProduccion_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE OR ALTER PROCEDURE [prod].[PA_DisponibilidadProduccion_Sel_Listado]
(
    @cJson NVARCHAR(MAX),
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
    BEGIN TRY
    SET NOCOUNT ON;
    DECLARE
        @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,
        @gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
        @bCtx BIT,@cMsg NVARCHAR(300),@cEstado VARCHAR(20),@nZona BIGINT,@nPredio BIGINT,
        @nSocio BIGINT,@nAsociacion BIGINT,@nVariedad SMALLINT,@cOrigen VARCHAR(20),
        @dDesde DATE,@dHasta DATE,@nPagina INT=1,@nTam INT=25,@nOffset INT;
    SELECT
        @bResultado=0,
        @cMensaje=N'No se pudo consultar la producción disponible.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
        @cJson,'PRODUCCION_LISTAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,
        @nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bCtx OUTPUT,@cMsg OUTPUT;
    IF @bCtx=0
    BEGIN
        SET @cMensaje=@cMsg;
        GOTO __DESCO_Salida;
    END;
    SELECT
        @cEstado=UPPER(NULLIF(LTRIM(RTRIM(estadoEstimacion)),'')),
        @nZona=zonaProductivaId,
        @nPredio=predioId,
        @nSocio=socioId,
        @nAsociacion=asociacionId,
        @nVariedad=variedadPaltaId,
        @cOrigen=UPPER(NULLIF(LTRIM(RTRIM(origen)),'')),
        @dDesde=disponibleDesde,
        @dHasta=disponibleHasta
    FROM OPENJSON(@cJson,'$.filtros')
    WITH
    (
        estadoEstimacion VARCHAR(20) '$.estadoEstimacion',
        zonaProductivaId BIGINT '$.zonaProductivaId',
        predioId BIGINT '$.predioId',
        socioId BIGINT '$.socioId',
        asociacionId BIGINT '$.asociacionId',
        variedadPaltaId SMALLINT '$.variedadPaltaId',
        origen VARCHAR(20) '$.origen',
        disponibleDesde DATE '$.disponibleDesde',
        disponibleHasta DATE '$.disponibleHasta'
    );
    IF @cEstado IS NOT NULL AND @cEstado NOT IN('ESTIMADA','CONFIRMADA','DESCARTADA')
    BEGIN
        SET @cMensaje=N'Seleccione un estado de producción válido.';
        GOTO __DESCO_Salida;
    END;
    IF @cOrigen IS NOT NULL AND @cOrigen NOT IN('DIRECTA','VISITA')
    BEGIN
        SET @cMensaje=N'Seleccione un origen de estimación válido.';
        GOTO __DESCO_Salida;
    END;
    IF @dDesde IS NOT NULL AND @dHasta IS NOT NULL AND @dHasta<@dDesde
    BEGIN
        SET @cMensaje=N'El rango de fechas seleccionado no es válido.';
        GOTO __DESCO_Salida;
    END;
    SELECT
        @nPagina=COALESCE(pagina,1),
        @nTam=COALESCE(tamano,25)
    FROM OPENJSON(@cJson,'$.paginacion')
    WITH
    (
        pagina INT '$.pagina',
        tamano INT '$.tamano'
    );
    IF @nPagina<1 SET @nPagina=1;
    IF @nTam<1 SET @nTam=25;
    IF @nTam>200 SET @nTam=200;
    SET @nOffset=(@nPagina-1)*@nTam;
    SELECT
        DP.disponibilidad_produccion_id disponibilidadProduccionId,
        DP.fecha_estimacion fechaEstimacion,
        DP.disponible_desde disponibleDesde,
        DP.disponible_hasta disponibleHasta,
        DP.cantidad_estimada_kg cantidadEstimadaKg,
        DP.estado_estimacion estadoEstimacion,
        DP.observacion,
        PC.parcela_cultivo_id parcelaCultivoId,
        VP.variedad_palta_id variedadPaltaId,
        VP.nombre variedad,
        P.parcela_id parcelaId,
        P.nombre parcelaNombre,
        PR.predio_id predioId,
        PR.codigo predioCodigo,
        PR.nombre predioNombre,
        ZP.zona_productiva_id zonaProductivaId,
        ZP.nombre zonaProductiva,
        TIT.socio_id socioId,
        LTRIM(RTRIM(CONCAT(COALESCE(PER.nombres,N''),N' ',COALESCE(PER.apellido_paterno,N''),N' ',COALESCE(PER.apellido_materno,N'')))) socioNombre,
        SA.asociacion_id asociacionId,
        EMP.razon_social asociacionNombre,
        DP.visita_tecnica_id visitaTecnicaId,
        CASE WHEN DP.visita_tecnica_id IS NULL THEN N'Estimación directa' ELSE N'Visita técnica' END origenEstimacion,
        COUNT_BIG(*) OVER() totalRegistros
    FROM [prod].[DisponibilidadProduccion] DP
    INNER JOIN [prod].[ParcelaCultivo] PC
        ON PC.parcela_cultivo_id=DP.parcela_cultivo_id
    INNER JOIN [prod].[VariedadPalta] VP
        ON VP.variedad_palta_id=PC.variedad_palta_id
    INNER JOIN [prod].[Parcela] P
        ON P.parcela_id=PC.parcela_id
    INNER JOIN [prod].[Predio] PR
        ON PR.predio_id=P.predio_id
    OUTER APPLY
    (
        SELECT TOP(1) X.zona_productiva_id
        FROM [geo].[ZonaProductivaPredio] X
        WHERE X.predio_id=PR.predio_id
          AND X.estado=1
          AND X.fecha_hasta IS NULL
        ORDER BY X.fecha_desde DESC
    ) ZPX
    LEFT JOIN [geo].[ZonaProductiva] ZP
        ON ZP.zona_productiva_id=ZPX.zona_productiva_id
    OUTER APPLY
    (
        SELECT TOP(1) PT.socio_id,PT.persona_id
        FROM [prod].[PredioTitularidad] PT
        WHERE PT.predio_id=PR.predio_id
          AND PT.estado=1
          AND PT.fecha_hasta IS NULL
        ORDER BY PT.fecha_desde DESC,PT.predio_titularidad_id DESC
    ) TIT
    LEFT JOIN [org].[Socio] S
        ON S.socio_id=TIT.socio_id
       AND S.estado=1
    LEFT JOIN [org].[Persona] PER
        ON PER.persona_id=COALESCE(TIT.persona_id,TIT.socio_id)
    OUTER APPLY
    (
        SELECT TOP(1) X.asociacion_id
        FROM [org].[SocioAsociacion] X
        WHERE X.socio_id=TIT.socio_id
          AND X.estado=1
          AND X.fecha_hasta IS NULL
        ORDER BY X.fecha_desde DESC,X.socio_asociacion_id DESC
    ) SA
    LEFT JOIN [org].[Empresa] EMP
        ON EMP.empresa_id=SA.asociacion_id
       AND EMP.estado=1
    WHERE DP.estado=1 AND prod.FN_Predio_VisibleSesion(@nSesion,@nUsuario,PR.predio_id,'PRODUCCION_LISTAR')=1
      AND (@cEstado IS NULL OR DP.estado_estimacion=@cEstado)
      AND (@nZona IS NULL OR ZP.zona_productiva_id=@nZona)
      AND (@nPredio IS NULL OR PR.predio_id=@nPredio)
      AND (@nVariedad IS NULL OR VP.variedad_palta_id=@nVariedad)
      AND (@cOrigen IS NULL OR (@cOrigen='DIRECTA' AND DP.visita_tecnica_id IS NULL) OR (@cOrigen='VISITA' AND DP.visita_tecnica_id IS NOT NULL))
      AND
      (
          @nSocio IS NULL
          OR EXISTS
          (
              SELECT 1
              FROM [prod].[PredioTitularidad] PTX
              WHERE PTX.predio_id=PR.predio_id
                AND PTX.socio_id=@nSocio
                AND PTX.estado=1
                AND PTX.fecha_hasta IS NULL
          )
      )
      AND
      (
          @nAsociacion IS NULL
          OR EXISTS
          (
              SELECT 1
              FROM [prod].[PredioTitularidad] PTX
              INNER JOIN [org].[SocioAsociacion] SAX
                  ON SAX.socio_id=PTX.socio_id
                 AND SAX.estado=1
                 AND SAX.fecha_hasta IS NULL
              WHERE PTX.predio_id=PR.predio_id
                AND PTX.estado=1
                AND PTX.fecha_hasta IS NULL
                AND SAX.asociacion_id=@nAsociacion
          )
      )
      AND (@dDesde IS NULL OR COALESCE(DP.disponible_hasta,DP.disponible_desde)>=@dDesde)
      AND (@dHasta IS NULL OR DP.disponible_desde<=@dHasta)
    ORDER BY DP.disponible_desde,PR.nombre,DP.disponibilidad_produccion_id
    OFFSET @nOffset ROWS FETCH NEXT @nTam ROWS ONLY;
    SET @bResultado=1;
    SET @cMensaje=N'Producción disponible cargada correctamente.';
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
    @cProcedimiento = N'prod.PA_DisponibilidadProduccion_Sel_Listado',
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
    @cProcedimiento = N'prod.PA_DisponibilidadProduccion_Sel_Listado',
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
FROM config.FN_RespuestaUsuario(N'prod.PA_DisponibilidadProduccion_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO

-- campo.PA_EvaluacionAgronomica_Sel_Listado
/******************************************************************************************************
' Nombre del PA           : campo.PA_EvaluacionAgronomica_Sel_Listado
' Descripción             : Consulta evaluaciones agronómicas según los filtros recibidos.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Campo
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo. Sustituir JSON, IDs y valores por datos válidos del entorno.
    DECLARE
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [campo].[PA_EvaluacionAgronomica_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE OR ALTER PROCEDURE [campo].[PA_EvaluacionAgronomica_Sel_Listado]
(
    @cJson NVARCHAR(MAX), @bResultado BIT OUTPUT, @cMensaje NVARCHAR(300) OUTPUT,
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
    BEGIN TRY
    SET NOCOUNT ON;
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,
            @gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
            @bCtx BIT,@cMsg NVARCHAR(300),@nPagina INT=1,@nTam INT=20,@nVisita BIGINT=NULL,@nCultivo BIGINT=NULL,
            @nTipo SMALLINT=NULL,@dDesde DATETIME2(0)=NULL,@dHasta DATETIME2(0)=NULL;
    SET @bResultado=0;
 SET @cMensaje=N'No se pudieron consultar las evaluaciones.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
        @cJson,'EVALUACIONES_LISTAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,
        @nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bCtx OUTPUT,@cMsg OUTPUT;
    IF @bCtx=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    SELECT @nPagina=ISNULL(NULLIF(pagina,0),1),@nTam=ISNULL(NULLIF(tamanoPagina,0),20),
           @nVisita=visitaTecnicaId,@nCultivo=parcelaCultivoId,@nTipo=tipoEvaluacionId,@dDesde=fechaDesde,@dHasta=fechaHasta
    FROM OPENJSON(@cJson,'$.filtros') WITH
    (pagina INT '$.pagina',tamanoPagina INT '$.tamanoPagina',visitaTecnicaId BIGINT '$.visitaTecnicaId',
     parcelaCultivoId BIGINT '$.parcelaCultivoId',tipoEvaluacionId SMALLINT '$.tipoEvaluacionId',
     fechaDesde DATETIME2(0) '$.fechaDesde',fechaHasta DATETIME2(0) '$.fechaHasta');
    IF @nPagina<1 SET @nPagina=1;
 IF @nTam<1 SET @nTam=20;
 IF @nTam>200 SET @nTam=200;
    ;
WITH Q AS
    (
      SELECT EA.evaluacion_agronomica_id,EA.visita_tecnica_id,EA.parcela_cultivo_id,EA.tipo_evaluacion_id,
             TE.codigo codigo_tipo,TE.nombre tipo_evaluacion,EA.fecha_hora,EA.resultado,EA.observacion,
             EMS.porcentaje_materia_seca,EMS.numero_muestras,V.predio_id,PR.codigo codigo_predio,PR.nombre predio,
             COUNT(*) OVER() total_registros
      FROM [campo].[EvaluacionAgronomica] EA
      INNER JOIN [campo].[TipoEvaluacion] TE ON TE.tipo_evaluacion_id=EA.tipo_evaluacion_id
      INNER JOIN [campo].[VisitaTecnica] V ON V.visita_tecnica_id=EA.visita_tecnica_id
      INNER JOIN [prod].[Predio] PR ON PR.predio_id=V.predio_id
      LEFT JOIN [campo].[EvaluacionMateriaSeca] EMS ON EMS.evaluacion_materia_seca_id=EA.evaluacion_agronomica_id AND EMS.estado=1
      WHERE EA.estado=1 AND prod.FN_Predio_VisibleSesion(@nSesion,@nUsuario,PR.predio_id,'EVALUACIONES_LISTAR')=1
        AND (@nVisita IS NULL OR EA.visita_tecnica_id=@nVisita)
        AND (@nCultivo IS NULL OR EA.parcela_cultivo_id=@nCultivo)
        AND (@nTipo IS NULL OR EA.tipo_evaluacion_id=@nTipo)
        AND (@dDesde IS NULL OR EA.fecha_hora>=@dDesde)
        AND (@dHasta IS NULL OR EA.fecha_hora<DATEADD(DAY,1,@dHasta))
    )
    SELECT evaluacion_agronomica_id AS evaluacionAgronomicaId,visita_tecnica_id AS visitaTecnicaId,
           parcela_cultivo_id AS parcelaCultivoId,tipo_evaluacion_id AS tipoEvaluacionId,
           codigo_tipo AS codigoTipoEvaluacion,tipo_evaluacion AS tipoEvaluacion,fecha_hora AS fechaHora,
           resultado,observacion,porcentaje_materia_seca AS porcentajeMateriaSeca,numero_muestras AS numeroMuestras,
           predio_id AS predioId,codigo_predio AS codigoPredio,predio,total_registros AS totalRegistros
    FROM Q ORDER BY fecha_hora DESC,evaluacion_agronomica_id DESC
    OFFSET (@nPagina-1)*@nTam ROWS FETCH NEXT @nTam ROWS ONLY;
    SET @bResultado=1;
 SET @cMensaje=N'Consulta realizada correctamente.';
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
    @cProcedimiento = N'campo.PA_EvaluacionAgronomica_Sel_Listado',
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
    @cProcedimiento = N'campo.PA_EvaluacionAgronomica_Sel_Listado',
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
FROM config.FN_RespuestaUsuario(N'campo.PA_EvaluacionAgronomica_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO

-- prod.PA_ParcelaCultivo_Sel_Listado
/******************************************************************************************************
' Nombre del PA           : prod.PA_ParcelaCultivo_Sel_Listado
' Descripción             : Lista parcelas de cultivo.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Producción
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo: sustituir identificadores y valores por datos válidos.
    -- El JSON mostrado es ilustrativo y debe ajustarse al contrato del PA.
    DECLARE
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [prod].[PA_ParcelaCultivo_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE OR ALTER PROCEDURE [prod].[PA_ParcelaCultivo_Sel_Listado]
(
    @cJson NVARCHAR(MAX), @bResultado BIT OUTPUT, @cMensaje NVARCHAR(300) OUTPUT,
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
    BEGIN TRY
    SET NOCOUNT ON;
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bOk BIT,@cMsg NVARCHAR(300),
            @nPredio BIGINT,@nSocio BIGINT,@nVariedad SMALLINT,@cSituacion VARCHAR(20),@cBuscar NVARCHAR(150),@nPagina INT=1,@nTam INT=20;
    SET @bResultado=0;
 SET @cMensaje=N'No se pudo cargar la información.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado] @cJson,'CULTIVOS_LISTAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bOk OUTPUT,@cMsg OUTPUT;
    IF @bOk=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    SELECT @nPredio=predioId,@nSocio=socioId,@nVariedad=variedadPaltaId,@cSituacion=UPPER(NULLIF(LTRIM(RTRIM(situacionCultivo)),'')),@cBuscar=NULLIF(LTRIM(RTRIM(buscar)),N''),@nPagina=ISNULL(pagina,1),@nTam=ISNULL(tamanoPagina,20)
    FROM OPENJSON(@cJson,'$.filtros') WITH (predioId BIGINT '$.predioId',socioId BIGINT '$.socioId',variedadPaltaId SMALLINT '$.variedadPaltaId',situacionCultivo VARCHAR(20) '$.situacionCultivo',buscar NVARCHAR(150) '$.buscar',pagina INT '$.pagina',tamanoPagina INT '$.tamanoPagina');
    IF @nPagina<1 SET @nPagina=1;
 IF @nTam<1 SET @nTam=20;
 IF @nTam>200 SET @nTam=200;
    ;
WITH Q AS
    (
      SELECT PA.parcela_id,PA.predio_id,PR.codigo predioCodigo,PR.nombre predioNombre,PA.codigo parcelaCodigo,PA.nombre parcelaNombre,PA.area_ha,PA.ubicacion_id,PA.estado parcelaEstado,
             PC.parcela_cultivo_id,PC.variedad_palta_id,VP.nombre variedad,PC.fecha_inicio,PC.fecha_fin,PC.situacion_cultivo,PC.estado cultivoEstado,
             COUNT_BIG(*) OVER() totalRegistros
      FROM [prod].[Parcela] PA INNER JOIN [prod].[Predio] PR ON PR.predio_id=PA.predio_id
      LEFT JOIN [prod].[ParcelaCultivo] PC ON PC.parcela_id=PA.parcela_id AND PC.estado=1
      LEFT JOIN [prod].[VariedadPalta] VP ON VP.variedad_palta_id=PC.variedad_palta_id
      WHERE PA.estado=1 AND PR.estado=1 AND prod.FN_Predio_VisibleSesion(@nSesion,@nUsuario,PR.predio_id,'CULTIVOS_LISTAR')=1
        AND (@nPredio IS NULL OR PA.predio_id=@nPredio)
        AND (@nVariedad IS NULL OR PC.variedad_palta_id=@nVariedad)
        AND (@cSituacion IS NULL OR PC.situacion_cultivo=@cSituacion)
        AND (@nSocio IS NULL OR EXISTS(SELECT 1 FROM [prod].[PredioTitularidad] PT WHERE PT.predio_id=PR.predio_id AND PT.socio_id=@nSocio AND PT.estado=1 AND PT.fecha_hasta IS NULL))
        AND (@cBuscar IS NULL OR PA.codigo LIKE '%'+@cBuscar+'%' OR PA.nombre LIKE N'%'+@cBuscar+N'%' OR PR.codigo LIKE '%'+@cBuscar+'%' OR PR.nombre LIKE N'%'+@cBuscar+N'%')
    )
    SELECT * FROM Q ORDER BY predioNombre,parcelaNombre,fecha_inicio DESC OFFSET (@nPagina-1)*@nTam ROWS FETCH NEXT @nTam ROWS ONLY;
    SET @bResultado=1;
 SET @cMensaje=N'Información cargada correctamente.';
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
    @cProcedimiento = N'prod.PA_ParcelaCultivo_Sel_Listado',
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
    @cProcedimiento = N'prod.PA_ParcelaCultivo_Sel_Listado',
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
FROM config.FN_RespuestaUsuario(N'prod.PA_ParcelaCultivo_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO

-- logistica.PA_RecursoProgramado_Sel_Listado
/******************************************************************************************************
' Nombre del PA           : logistica.PA_RecursoProgramado_Sel_Listado
' Descripción             : Lista recurso programado.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo: sustituir identificadores y valores por datos válidos.
    -- El JSON mostrado es ilustrativo y debe ajustarse al contrato del PA.
    DECLARE
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [logistica].[PA_RecursoProgramado_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE OR ALTER PROCEDURE [logistica].[PA_RecursoProgramado_Sel_Listado](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS BEGIN
    SET @cMensaje=NULL; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;
    /* Respuesta explícita; mensajes públicos aprobados. */
    SET NOCOUNT ON;
    DECLARE @__DbTranEntrada INT = @@TRANCOUNT,
            @__DbTranAbierta BIT = 0,
            @__DbSavepoint VARCHAR(32) = REPLACE(CONVERT(VARCHAR(36),NEWID()),'-',''),
            @__DbMensaje NVARCHAR(300),
            @__DbError BIT = 0;
    SET @bResultado = 0;
    BEGIN TRY
  SET NOCOUNT ON;
    DECLARE @nPaginaListado INT, @nTamanoListado INT, @nOffsetListado BIGINT;
    EXEC [seg].[PA_Consulta_Sel_ResolverPaginacion]
         @cJson = @cJson,
         @nPagina = @nPaginaListado OUTPUT,
         @nTamanoPagina = @nTamanoListado OUTPUT,
         @nOffset = @nOffsetListado OUTPUT;
DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bCtx BIT,@cMsg NVARCHAR(300);
SELECT @bResultado=0,@cMensaje=N'No se pudieron consultar los recursos programados.';
EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='RECURSOS_LISTAR',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@bResultado=@bCtx OUTPUT,@cMensaje=@cMsg OUTPUT;
IF @bCtx=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;
 DECLARE @cEstado VARCHAR(20),@nCamp BIGINT,@nOpVenta BIGINT,@nSalida BIGINT;
SELECT @cEstado=UPPER(NULLIF(LTRIM(RTRIM(estadoProceso)),'')),@nCamp=campaniaVentaId,@nOpVenta=operativoVentaId,@nSalida=salidaCampoId FROM OPENJSON(@cJson,'$.filtros') WITH(estadoProceso VARCHAR(20) '$.estadoProceso',campaniaVentaId BIGINT '$.campaniaVentaId',operativoVentaId BIGINT '$.operativoVentaId',salidaCampoId BIGINT '$.salidaCampoId');
SELECT R.recurso_programado_id recursoProgramadoId,R.campania_venta_id campaniaVentaId,R.operativo_venta_id operativoVentaId,R.salida_campo_id salidaCampoId,R.bien_inventario_id bienInventarioId,B.nombre bien,R.suministro_id suministroId,S.nombre suministro,R.cantidad_programada cantidadProgramada,R.cantidad_entregada cantidadEntregada,R.cantidad_devuelta cantidadDevuelta,R.cantidad_consumida cantidadConsumida,R.cantidad_pendiente cantidadPendiente,R.estado_proceso estadoProceso,R.fecha_programacion fechaProgramacion,R.observacion,R.cantidad_entregada cantidadEjecutada, COUNT_BIG(*) OVER() AS totalRegistros FROM logistica.RecursoProgramado R LEFT JOIN logistica.BienInventario B ON B.bien_inventario_id=R.bien_inventario_id LEFT JOIN logistica.Suministro S ON S.suministro_id=R.suministro_id WHERE R.estado=1 AND EXISTS(SELECT 1 FROM seg.SesionUsuario SS WHERE SS.sesion_usuario_id=@nSesion AND SS.estado=1 AND SS.fecha_revocacion IS NULL AND (SS.modo_uot='GENERAL' OR SS.uot_contexto_id=COALESCE(S.uot_id,B.uot_id)) AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,COALESCE(S.uot_id,B.uot_id),'RECURSOS_LISTAR')=1) AND (@cEstado IS NULL OR R.estado_proceso=@cEstado) AND (@nCamp IS NULL OR R.campania_venta_id=@nCamp) AND (@nOpVenta IS NULL OR R.operativo_venta_id=@nOpVenta) AND (@nSalida IS NULL OR R.salida_campo_id=@nSalida) ORDER BY R.fecha_programacion DESC,R.recurso_programado_id DESC OFFSET @nOffsetListado ROWS FETCH NEXT @nTamanoListado ROWS ONLY;
SET @bResultado=1;
SET @cMensaje=N'Recursos consultados correctamente.';
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
    @cProcedimiento = N'logistica.PA_RecursoProgramado_Sel_Listado',
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
    @cProcedimiento = N'logistica.PA_RecursoProgramado_Sel_Listado',
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
FROM config.FN_RespuestaUsuario(N'logistica.PA_RecursoProgramado_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO

-- campo.PA_VisitaTecnica_Sel_Listado
/******************************************************************************************************
' Nombre del PA           : campo.PA_VisitaTecnica_Sel_Listado
' Descripción             : Consulta las visitas técnicas según los filtros recibidos.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Campo
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo. Sustituir JSON, IDs y valores por datos válidos del entorno.
    DECLARE
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [campo].[PA_VisitaTecnica_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE OR ALTER PROCEDURE [campo].[PA_VisitaTecnica_Sel_Listado]
(
    @cJson NVARCHAR(MAX), @bResultado BIT OUTPUT, @cMensaje NVARCHAR(300) OUTPUT,
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
    BEGIN TRY
    SET NOCOUNT ON;
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,
            @gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
            @bCtx BIT,@cMsg NVARCHAR(300),@nPagina INT=1,@nTam INT=20,@nPredio BIGINT=NULL,
            @nEmpleado BIGINT=NULL,@nSalida BIGINT=NULL,@cEstado VARCHAR(20)=NULL,
            @dDesde DATETIME2(0)=NULL,@dHasta DATETIME2(0)=NULL,@cBuscar NVARCHAR(120)=NULL;
    SET @bResultado=0;
 SET @cMensaje=N'No se pudieron consultar las visitas.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
        @cJson,'VISITAS_LISTAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,
        @nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bCtx OUTPUT,@cMsg OUTPUT;
    IF @bCtx=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    SELECT @nPagina=ISNULL(NULLIF(pagina,0),1),@nTam=ISNULL(NULLIF(tamanoPagina,0),20),
           @nPredio=predioId,@nEmpleado=empleadoId,@nSalida=salidaCampoId,
           @cEstado=UPPER(NULLIF(LTRIM(RTRIM(estadoProceso)),'')),
           @dDesde=fechaDesde,@dHasta=fechaHasta,
           @cBuscar=NULLIF(LTRIM(RTRIM(buscar)),N'')
    FROM OPENJSON(@cJson,'$.filtros') WITH
    (pagina INT '$.pagina',tamanoPagina INT '$.tamanoPagina',predioId BIGINT '$.predioId',
     empleadoId BIGINT '$.empleadoId',salidaCampoId BIGINT '$.salidaCampoId',
     estadoProceso VARCHAR(20) '$.estadoProceso',fechaDesde DATETIME2(0) '$.fechaDesde',
     fechaHasta DATETIME2(0) '$.fechaHasta',buscar NVARCHAR(120) '$.buscar');
    IF @nPagina<1 SET @nPagina=1;
 IF @nTam<1 SET @nTam=20;
 IF @nTam>200 SET @nTam=200;
    ;
WITH Q AS
    (
        SELECT V.visita_tecnica_id,V.salida_participante_id,SP.salida_campo_id,SP.empleado_id,
               CONCAT(PER.nombres,N' ',PER.apellido_paterno,
                      CASE WHEN PER.apellido_materno IS NULL THEN N'' ELSE N' '+PER.apellido_materno END) tecnico,
               V.predio_id,PR.codigo codigo_predio,PR.nombre predio,
               V.fecha_hora_inicio,V.fecha_hora_fin,V.objetivo,V.estado_proceso,
               CASE WHEN V.posicion_inicio IS NULL THEN NULL ELSE V.posicion_inicio.Lat END latitud,
               CASE WHEN V.posicion_inicio IS NULL THEN NULL ELSE V.posicion_inicio.Long END longitud,
               COUNT(*) OVER() total_registros
        FROM [campo].[VisitaTecnica] V
        INNER JOIN [campo].[SalidaParticipante] SP ON SP.salida_participante_id=V.salida_participante_id
        INNER JOIN [org].[Empleado] E ON E.empleado_id=SP.empleado_id
        INNER JOIN [org].[Persona] PER ON PER.persona_id=E.empleado_id
        INNER JOIN [prod].[Predio] PR ON PR.predio_id=V.predio_id
        WHERE V.estado=1 AND prod.FN_Predio_VisibleSesion(@nSesion,@nUsuario,PR.predio_id,'VISITAS_LISTAR')=1
          AND (@nPredio IS NULL OR V.predio_id=@nPredio)
          AND (@nEmpleado IS NULL OR SP.empleado_id=@nEmpleado)
          AND (@nSalida IS NULL OR SP.salida_campo_id=@nSalida)
          AND (@cEstado IS NULL OR V.estado_proceso=@cEstado)
          AND (@dDesde IS NULL OR V.fecha_hora_inicio>=@dDesde)
          AND (@dHasta IS NULL OR V.fecha_hora_inicio<DATEADD(DAY,1,@dHasta))
          AND (@cBuscar IS NULL OR PR.codigo LIKE N'%'+@cBuscar+N'%' OR PR.nombre LIKE N'%'+@cBuscar+N'%'
               OR PER.nombres LIKE N'%'+@cBuscar+N'%' OR PER.apellido_paterno LIKE N'%'+@cBuscar+N'%')
    )
    SELECT visita_tecnica_id AS visitaTecnicaId,salida_participante_id AS salidaParticipanteId,
           salida_campo_id AS salidaCampoId,empleado_id AS empleadoId,tecnico,
           predio_id AS predioId,codigo_predio AS codigoPredio,predio,
           fecha_hora_inicio AS fechaHoraInicio,fecha_hora_fin AS fechaHoraFin,objetivo,
           estado_proceso AS estadoProceso,latitud,longitud,total_registros AS totalRegistros
    FROM Q
    ORDER BY fecha_hora_inicio DESC,visita_tecnica_id DESC
    OFFSET (@nPagina-1)*@nTam ROWS FETCH NEXT @nTam ROWS ONLY;
    SET @bResultado=1;
 SET @cMensaje=N'Consulta realizada correctamente.';
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
    @cProcedimiento = N'campo.PA_VisitaTecnica_Sel_Listado',
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
    @cProcedimiento = N'campo.PA_VisitaTecnica_Sel_Listado',
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
FROM config.FN_RespuestaUsuario(N'campo.PA_VisitaTecnica_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO

-- prod.PA_CensoPlantas_Sel_Historial
/******************************************************************************************************
' Nombre del PA           : prod.PA_CensoPlantas_Sel_Historial
' Descripción             : Consulta el historial de censos de plantas.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Producción
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo: sustituir identificadores y valores por datos válidos.
    -- El JSON mostrado es ilustrativo y debe ajustarse al contrato del PA.
    DECLARE
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [prod].[PA_CensoPlantas_Sel_Historial]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE OR ALTER PROCEDURE [prod].[PA_CensoPlantas_Sel_Historial]
(
    @cJson NVARCHAR(MAX), @bResultado BIT OUTPUT, @cMensaje NVARCHAR(300) OUTPUT,
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
    BEGIN TRY
     SET NOCOUNT ON;
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bOk BIT,@cMsg NVARCHAR(300),@nCultivo BIGINT,@nParcela BIGINT,@dDesde DATE,@dHasta DATE,@nPagina INT=1,@nTam INT=30;
    SET @bResultado=0;
 SET @cMensaje=N'No se pudo cargar los censos.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado] @cJson,'CENSOS_LISTAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bOk OUTPUT,@cMsg OUTPUT;
    IF @bOk=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    SELECT @nCultivo=parcelaCultivoId,@nParcela=parcelaId,@dDesde=fechaDesde,@dHasta=fechaHasta,@nPagina=ISNULL(pagina,1),@nTam=ISNULL(tamanoPagina,30) FROM OPENJSON(@cJson,'$.filtros') WITH (parcelaCultivoId BIGINT '$.parcelaCultivoId',parcelaId BIGINT '$.parcelaId',fechaDesde DATE '$.fechaDesde',fechaHasta DATE '$.fechaHasta',pagina INT '$.pagina',tamanoPagina INT '$.tamanoPagina');
    IF @nPagina<1 SET @nPagina=1;
 IF @nTam<1 SET @nTam=30;
 IF @nTam>200 SET @nTam=200;
    ;
WITH Q AS
    (
      SELECT C.censo_plantas_id,C.parcela_cultivo_id,PC.parcela_id,PA.codigo parcelaCodigo,PA.nombre parcelaNombre,VP.nombre variedad,C.fecha_censo,C.plantas_totales,C.plantas_productivas,C.plantas_no_productivas,C.plantas_nuevas,C.plantas_muertas,C.plantas_afectadas,C.observacion,C.estado,COUNT_BIG(*) OVER() totalRegistros
      FROM [prod].[CensoPlantas] C INNER JOIN [prod].[ParcelaCultivo] PC ON PC.parcela_cultivo_id=C.parcela_cultivo_id INNER JOIN [prod].[Parcela] PA ON PA.parcela_id=PC.parcela_id INNER JOIN [prod].[VariedadPalta] VP ON VP.variedad_palta_id=PC.variedad_palta_id
      WHERE prod.FN_Predio_VisibleSesion(@nSesion,@nUsuario,PA.predio_id,'CENSOS_LISTAR')=1 AND (@nCultivo IS NULL OR C.parcela_cultivo_id=@nCultivo) AND (@nParcela IS NULL OR PC.parcela_id=@nParcela) AND (@dDesde IS NULL OR C.fecha_censo>=@dDesde) AND (@dHasta IS NULL OR C.fecha_censo<=@dHasta)
    )
    SELECT * FROM Q ORDER BY fecha_censo DESC,censo_plantas_id DESC OFFSET (@nPagina-1)*@nTam ROWS FETCH NEXT @nTam ROWS ONLY;
    SET @bResultado=1;
 SET @cMensaje=N'Censos cargados correctamente.';
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
    @cProcedimiento = N'prod.PA_CensoPlantas_Sel_Historial',
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
    @cProcedimiento = N'prod.PA_CensoPlantas_Sel_Historial',
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
FROM config.FN_RespuestaUsuario(N'prod.PA_CensoPlantas_Sel_Historial',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO

-- logistica.PA_ProgramacionProducto_Ins_Solicitar
CREATE OR ALTER PROCEDURE logistica.PA_ProgramacionProducto_Ins_Solicitar
 @nUsuarioId BIGINT,@nUotId BIGINT,@nAlmacenId BIGINT,@nProductoId BIGINT,@nEmpleadoId BIGINT,
 @nCantidad DECIMAL(19,3),@cActividad NVARCHAR(250),@cLugar NVARCHAR(300),
 @dInicio DATETIME2(0),@dFin DATETIME2(0)=NULL,@nArchivoId BIGINT=NULL,
 @cObservacion NVARCHAR(500)=NULL,@gClaveIdempotencia UNIQUEIDENTIFIER,
 @nProgramacionId BIGINT OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @nProgramacionId=NULL,@bResultado=0,@cMensaje=N'No se pudo registrar la solicitud.';
 SET @cActividad=NULLIF(LTRIM(RTRIM(@cActividad)),N'');
 SET @cLugar=NULLIF(LTRIM(RTRIM(@cLugar)),N'');
 IF @nCantidad IS NULL OR @nCantidad<=0 OR @cActividad IS NULL OR @cLugar IS NULL OR @dInicio IS NULL
  OR (@dFin IS NOT NULL AND @dFin<@dInicio) OR @gClaveIdempotencia IS NULL
 BEGIN SET @cMensaje=N'Complete correctamente los datos de la solicitud.';RETURN;END;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'RECURSOS_CREAR')=0
 BEGIN SET @cMensaje=N'No tiene permiso para solicitar recursos en esta UOT.';RETURN;END;
 IF NOT EXISTS(SELECT 1 FROM logistica.Almacen WHERE almacen_id=@nAlmacenId AND uot_propietaria_id=@nUotId AND estado=1)
 BEGIN SET @cMensaje=N'El almacén seleccionado no está disponible en esta UOT.';RETURN;END;
 IF NOT EXISTS(SELECT 1 FROM logistica.AlmacenUOT WHERE almacen_id=@nAlmacenId AND uot_id=@nUotId
 AND estado=1 AND fecha_hasta IS NULL AND permite_salida=1)
 BEGIN SET @cMensaje=N'El almacén no permite entregar recursos en esta UOT.';RETURN;END;
 IF NOT EXISTS(SELECT 1 FROM logistica.Producto P JOIN logistica.ProductoUOTPolitica U ON U.producto_id=P.producto_id AND U.uot_id=@nUotId
 WHERE P.producto_id=@nProductoId AND P.estado=1 AND U.estado=1 AND U.permite_uso_interno=1)
 BEGIN SET @cMensaje=N'El producto no está habilitado para uso interno en esta UOT.';RETURN;END;
 IF NOT EXISTS(SELECT 1 FROM org.Empleado E JOIN org.EmpleadoUOT EU ON EU.empleado_id=E.empleado_id
 WHERE E.empleado_id=@nEmpleadoId AND E.estado=1 AND (E.fecha_cese IS NULL OR E.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME())) AND EU.uot_id=@nUotId AND EU.estado=1 AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
   AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME())))
 BEGIN SET @cMensaje=N'El técnico no pertenece a esta UOT.';RETURN;END;
 IF @nArchivoId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM archivo.Archivo WHERE archivo_id=@nArchivoId AND uot_id=@nUotId AND estado=1
  AND proveedor_almacenamiento='LOCAL' AND clave_almacenamiento IS NOT NULL)
 BEGIN SET @cMensaje=N'El documento de autorización no está disponible en esta UOT.';RETURN;END;
 BEGIN TRY
  SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;BEGIN TRAN;
  SELECT @nProgramacionId=programacion_producto_id FROM logistica.ProgramacionProducto WITH(UPDLOCK,HOLDLOCK) WHERE clave_idempotencia=@gClaveIdempotencia;
  IF @nProgramacionId IS NOT NULL
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM logistica.ProgramacionProducto WHERE programacion_producto_id=@nProgramacionId AND uot_id=@nUotId AND almacen_id=@nAlmacenId AND producto_id=@nProductoId AND empleado_id=@nEmpleadoId AND cantidad_programada=@nCantidad AND actividad=@cActividad AND lugar_destino=@cLugar AND fecha_inicio=@dInicio AND (fecha_fin=@dFin OR (fecha_fin IS NULL AND @dFin IS NULL)) AND (observacion=@cObservacion OR (observacion IS NULL AND @cObservacion IS NULL)) AND (archivo_autorizacion_id=@nArchivoId OR (archivo_autorizacion_id IS NULL AND @nArchivoId IS NULL)) AND usuario_solicitante_id=@nUsuarioId)
      THROW 51001,N'CLAVE_REUTILIZADA',1;
   COMMIT;SET @bResultado=1;SET @cMensaje=N'La solicitud ya fue registrada.';RETURN;
  END;
  IF NOT EXISTS(SELECT 1 FROM logistica.AlmacenProductoStock WITH(UPDLOCK,HOLDLOCK)
   WHERE almacen_id=@nAlmacenId AND producto_id=@nProductoId AND estado=1)
  BEGIN SET @cMensaje=N'El producto debe estar incorporado y activo en el almacén seleccionado.';THROW 51121,@cMensaje,1;END;
  INSERT logistica.ProgramacionProducto(uot_id,almacen_id,producto_id,empleado_id,cantidad_programada,actividad,lugar_destino,fecha_inicio,fecha_fin,
   observacion,archivo_autorizacion_id,usuario_solicitante_id,clave_idempotencia)
  VALUES(@nUotId,@nAlmacenId,@nProductoId,@nEmpleadoId,@nCantidad,@cActividad,@cLugar,@dInicio,@dFin,@cObservacion,@nArchivoId,@nUsuarioId,@gClaveIdempotencia);
  SET @nProgramacionId=CONVERT(BIGINT,SCOPE_IDENTITY());
  COMMIT;SET @bResultado=1;SET @cMensaje=N'Solicitud registrada correctamente.';
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;SET @nProgramacionId=NULL;
  SET @cMensaje=CASE WHEN ERROR_NUMBER()=51121 THEN ERROR_MESSAGE() WHEN ERROR_MESSAGE() LIKE '%CLAVE_REUTILIZADA%' THEN N'La solicitud ya fue utilizada para otra operación.'
  ELSE N'No se pudo registrar la solicitud.' END;
 END CATCH;
END;
GO
