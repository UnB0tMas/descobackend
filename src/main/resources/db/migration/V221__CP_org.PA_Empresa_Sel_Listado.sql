IF OBJECT_ID(N'[org].[PA_Empresa_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_Empresa_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_Empresa_Sel_Listado
' Descripción             : Lista empresas.
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
    EXEC [org].[PA_Empresa_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [org].[PA_Empresa_Sel_Listado]
    @cJson NVARCHAR(MAX),
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @bResultado=0; SET @cMensaje=N'No se pudieron consultar las organizaciones.';
    SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;
    BEGIN TRY
        DECLARE @nPagina INT,@nTamano INT,@nOffset BIGINT;
        EXEC seg.PA_Consulta_Sel_ResolverPaginacion @cJson,@nPagina OUTPUT,@nTamano OUTPUT,@nOffset OUTPUT;
        DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bCtx BIT,@cMsg NVARCHAR(300);
        EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,'ORGANIZACIONES_LISTAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bCtx OUTPUT,@cMsg OUTPUT;
        IF @bCtx=0 BEGIN SET @cMensaje=@cMsg; GOTO Salida; END;

        DECLARE @nUotSolicitada BIGINT=TRY_CONVERT(BIGINT,COALESCE(JSON_VALUE(@cJson,'$.filtros.uotId'),JSON_VALUE(@cJson,'$.uotId'))),
                @nUot BIGINT,@bGeneral BIT,@bUot BIT,@cUotMsg NVARCHAR(300);
        EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuario,@nSesion,@nUotSolicitada,'ORGANIZACIONES_LISTAR',0,@nUot OUTPUT,@bGeneral OUTPUT,@bUot OUTPUT,@cUotMsg OUTPUT;
        IF @bUot=0 BEGIN SET @cMensaje=@cUotMsg; GOTO Salida; END;

        SELECT C.convenio_uot_organizacion_id convenioUotOrganizacionId,
               C.uot_id uotId,U.codigo uotCodigo,U.nombre uotNombre,C.tipo_vinculo tipoVinculo,
               E.empresa_id empresaId,E.ruc,E.razon_social razonSocial,E.nombre_comercial nombreComercial,
               E.telefono,E.correo,E.fecha_creacion fechaCreacion,E.estado,
               CONVERT(BIT,CASE WHEN C.tipo_vinculo='ASOCIACION' THEN 1 ELSE 0 END) esAsociacion,
               A.fecha_constitucion fechaConstitucion,A.numero_partida numeroPartida,
               COUNT_BIG(*) OVER() totalRegistros
        FROM org.ConvenioUOTOrganizacion C
        JOIN org.UOT U ON U.uot_id=C.uot_id AND U.estado=1
        JOIN org.Empresa E ON E.empresa_id=C.empresa_id AND E.estado=1
        LEFT JOIN org.Asociacion A ON A.asociacion_id=E.empresa_id AND A.estado=1 AND C.tipo_vinculo='ASOCIACION'
        WHERE C.estado=1 AND C.fecha_fin IS NULL
          AND (@nUot IS NULL OR C.uot_id=@nUot)
          AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,C.uot_id,'ORGANIZACIONES_LISTAR')=1
        ORDER BY U.nombre,E.razon_social,E.empresa_id
        OFFSET @nOffset ROWS FETCH NEXT @nTamano ROWS ONLY;

        SET @bResultado=1; SET @cMensaje=N'Organizaciones consultadas.';
    END TRY
    BEGIN CATCH
        SET @bResultado=0; SET @cMensaje=N'No se pudieron consultar las organizaciones.';
    END CATCH
Salida:
    SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
    FROM config.FN_RespuestaUsuario(N'org.PA_Empresa_Sel_Listado',@bResultado,@cMensaje) R;
    RETURN CASE WHEN @bResultado=1 THEN 0 ELSE 1 END;
END;
GO
