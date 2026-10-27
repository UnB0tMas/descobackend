IF OBJECT_ID(N'[prod].[PA_Predio_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [prod].[PA_Predio_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : prod.PA_Predio_Sel_Listado
' Descripción             : Lista predios.
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
    EXEC [prod].[PA_Predio_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [prod].[PA_Predio_Sel_Listado]
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
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bOk BIT,@cMsg NVARCHAR(300);
    DECLARE @cBuscar NVARCHAR(160),@nSocio BIGINT,@cDistrito CHAR(6),@nPagina INT=1,@nTam INT=20,@bSoloActivos BIT=NULL;
    SET @bResultado=0;
 SET @cMensaje=N'No se pudo cargar la información.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado] @cJson,'PREDIOS_LISTAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bOk OUTPUT,@cMsg OUTPUT;
    IF @bOk=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    SELECT @cBuscar=NULLIF(LTRIM(RTRIM(buscar)),N''),@nSocio=socioId,@cDistrito=NULLIF(LTRIM(RTRIM(distritoCodigo)),''),@nPagina=ISNULL(pagina,1),@nTam=ISNULL(tamanoPagina,20),@bSoloActivos=soloActivos
    FROM OPENJSON(@cJson,'$.filtros') WITH (buscar NVARCHAR(160) '$.buscar',socioId BIGINT '$.socioId',distritoCodigo CHAR(6) '$.distritoCodigo',pagina INT '$.pagina',tamanoPagina INT '$.tamanoPagina',soloActivos BIT '$.soloActivos');
    IF @nPagina<1 SET @nPagina=1;
 IF @nTam<1 SET @nTam=20;
 IF @nTam>200 SET @nTam=200;
    ;
WITH Q AS
    (
      SELECT PR.predio_id,PR.codigo,PR.nombre,PR.fecha_registro,PR.estado,U.distrito_codigo,U.centro_poblado_id,U.referencia,
             PV.area_total_ha,PV.area_cultivable_ha,PV.tipo_riego,
             T.titulares,COUNT_BIG(*) OVER() totalRegistros
      FROM [prod].[Predio] PR
      INNER JOIN [geo].[Ubicacion] U ON U.ubicacion_id=PR.ubicacion_id
      OUTER APPLY(SELECT TOP(1) V.* FROM [prod].[PredioVersion] V WHERE V.predio_id=PR.predio_id AND V.estado=1 AND V.fecha_hasta IS NULL ORDER BY V.fecha_desde DESC) PV
      OUTER APPLY
      (
        SELECT STRING_AGG(CONCAT(P.nombres,N' ',P.apellido_paterno,N' ',ISNULL(P.apellido_materno,N'')),N', ') titulares
        FROM [prod].[PredioTitularidad] PT INNER JOIN [org].[Persona] P ON P.persona_id=PT.socio_id
        WHERE PT.predio_id=PR.predio_id AND PT.estado=1 AND PT.fecha_hasta IS NULL
      ) T
      WHERE (@bSoloActivos IS NULL OR PR.estado=@bSoloActivos)
        AND (@cDistrito IS NULL OR U.distrito_codigo=@cDistrito)
        AND (@nSocio IS NULL OR EXISTS(SELECT 1 FROM [prod].[PredioTitularidad] X WHERE X.predio_id=PR.predio_id AND X.socio_id=@nSocio AND X.estado=1 AND X.fecha_hasta IS NULL))
        AND (@cBuscar IS NULL OR PR.codigo LIKE '%'+@cBuscar+'%' OR PR.nombre LIKE N'%'+@cBuscar+N'%' OR T.titulares LIKE N'%'+@cBuscar+N'%')
    )
    SELECT * FROM Q ORDER BY nombre,predio_id OFFSET (@nPagina-1)*@nTam ROWS FETCH NEXT @nTam ROWS ONLY;
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
    @cProcedimiento = N'prod.PA_Predio_Sel_Listado',
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
    @cProcedimiento = N'prod.PA_Predio_Sel_Listado',
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
FROM config.FN_RespuestaUsuario(N'prod.PA_Predio_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
