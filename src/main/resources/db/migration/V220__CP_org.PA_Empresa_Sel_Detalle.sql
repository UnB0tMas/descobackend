IF OBJECT_ID(N'[org].[PA_Empresa_Sel_Detalle]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_Empresa_Sel_Detalle];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_Empresa_Sel_Detalle
' Descripción             : Consulta el detalle de empresas.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Organización
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
    EXEC [org].[PA_Empresa_Sel_Detalle]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [org].[PA_Empresa_Sel_Detalle]
    @cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @bResultado=0; SET @cMensaje=N'No se pudo consultar la organización.';
    SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;
    BEGIN TRY
        DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bCtx BIT,@cMsg NVARCHAR(300);
        EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,'ORGANIZACIONES_VER',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bCtx OUTPUT,@cMsg OUTPUT;
        IF @bCtx=0 BEGIN SET @cMensaje=@cMsg; GOTO Salida; END;
        DECLARE @nId BIGINT=COALESCE(TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.organizacion.empresaId')),TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.empresa.empresaId')),TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.empresaId')),TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.empresaId'))),
                @nUotSolicitada BIGINT=TRY_CONVERT(BIGINT,COALESCE(JSON_VALUE(@cJson,'$.organizacion.uotId'),JSON_VALUE(@cJson,'$.filtros.uotId'),JSON_VALUE(@cJson,'$.uotId'))),
                @nUot BIGINT,@bGeneral BIT,@bUot BIT,@cUotMsg NVARCHAR(300);
        EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuario,@nSesion,@nUotSolicitada,'ORGANIZACIONES_VER',1,@nUot OUTPUT,@bGeneral OUTPUT,@bUot OUTPUT,@cUotMsg OUTPUT;
        IF @bUot=0 BEGIN SET @cMensaje=@cUotMsg; GOTO Salida; END;
        IF NOT EXISTS(SELECT 1 FROM org.ConvenioUOTOrganizacion WHERE empresa_id=@nId AND uot_id=@nUot AND estado=1 AND fecha_fin IS NULL)
        BEGIN SET @cMensaje=N'La organización no está disponible en esta UOT.'; GOTO Salida; END;

        SELECT C.convenio_uot_organizacion_id convenioUotOrganizacionId,C.uot_id uotId,UO.codigo uotCodigo,UO.nombre uotNombre,C.tipo_vinculo tipoVinculo,
               E.empresa_id empresaId,E.ruc,E.razon_social razonSocial,E.nombre_comercial nombreComercial,E.telefono,E.correo,E.fecha_creacion fechaCreacion,E.estado,
               CONVERT(BIT,CASE WHEN C.tipo_vinculo='ASOCIACION' THEN 1 ELSE 0 END) esAsociacion,A.fecha_constitucion fechaConstitucion,A.numero_partida numeroPartida,
               UB.distrito_codigo distritoCodigo,D.nombre distritoNombre,UB.centro_poblado_id centroPobladoId,CP.nombre centroPobladoNombre,UB.referencia referencia,
               UB.altitud_m altitudM,CASE WHEN UB.posicion IS NULL THEN NULL ELSE UB.posicion.STAsText() END posicionWkt,
               CASE WHEN UB.posicion IS NULL THEN NULL ELSE UB.posicion.STSrid END posicionSrid
        FROM org.ConvenioUOTOrganizacion C
        JOIN org.UOT UO ON UO.uot_id=C.uot_id
        JOIN org.Empresa E ON E.empresa_id=C.empresa_id
        LEFT JOIN org.Asociacion A ON A.asociacion_id=E.empresa_id AND A.estado=1 AND C.tipo_vinculo='ASOCIACION'
        LEFT JOIN geo.Ubicacion UB ON UB.ubicacion_id=E.ubicacion_id
        LEFT JOIN geo.Distrito D ON D.distrito_codigo=UB.distrito_codigo
        LEFT JOIN geo.CentroPoblado CP ON CP.centro_poblado_id=UB.centro_poblado_id AND CP.distrito_codigo=UB.distrito_codigo
        WHERE C.empresa_id=@nId AND C.uot_id=@nUot AND C.estado=1 AND C.fecha_fin IS NULL;

        /* Compatibilidad temporal: resultados secundarios vacíos; Area/Empleado ya no son hijos de Empresa. */
        SELECT TOP(0) CAST(NULL AS BIGINT) areaId,CAST(NULL AS BIGINT) uotId,CAST(NULL AS NVARCHAR(160)) uotNombre,CAST(NULL AS BIGINT) areaPadreId,CAST(NULL AS NVARCHAR(120)) areaPadre,CAST(NULL AS VARCHAR(30)) codigo,CAST(NULL AS NVARCHAR(120)) nombre,CAST(NULL AS BIT) estado;
        SELECT TOP(0) CAST(NULL AS BIGINT) empleadoId,CAST(NULL AS VARCHAR(30)) codigoEmpleado,CAST(NULL AS VARCHAR(30)) numeroDocumento,CAST(NULL AS NVARCHAR(300)) empleado;

        SET @bResultado=1; SET @cMensaje=N'Organización consultada.';
    END TRY
    BEGIN CATCH SET @bResultado=0; SET @cMensaje=N'No se pudo consultar la organización.'; END CATCH
Salida:
    SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
    FROM config.FN_RespuestaUsuario(N'org.PA_Empresa_Sel_Detalle',@bResultado,@cMensaje) R;
    RETURN CASE WHEN @bResultado=1 THEN 0 ELSE 1 END;
END;
GO
