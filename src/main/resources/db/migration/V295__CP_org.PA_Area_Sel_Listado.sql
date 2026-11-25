IF OBJECT_ID(N'[org].[PA_Area_Sel_Listado]') IS NOT NULL
    DROP PROCEDURE [org].[PA_Area_Sel_Listado];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : org.PA_Area_Sel_Listado
' Descripción            : Lista áreas de la organización.
' Aplicativo / Módulo    : DESCO / Organización
*******************************************************************************************************/
CREATE PROCEDURE [org].[PA_Area_Sel_Listado]
    @cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @bResultado=0; SET @cMensaje=N'No se pudieron consultar las áreas.'; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;
    BEGIN TRY
        DECLARE @nPagina INT,@nTamano INT,@nOffset BIGINT; EXEC seg.PA_Consulta_Sel_ResolverPaginacion @cJson,@nPagina OUTPUT,@nTamano OUTPUT,@nOffset OUTPUT;
        DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bCtx BIT,@cMsg NVARCHAR(300),@nUotSolicitada BIGINT=TRY_CONVERT(BIGINT,COALESCE(JSON_VALUE(@cJson,'$.filtros.uotId'),JSON_VALUE(@cJson,'$.uotId'))),@nUot BIGINT,@bGeneral BIT,@bUot BIT,@cUotMsg NVARCHAR(300);
        EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,'ORGANIZACIONES_LISTAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bCtx OUTPUT,@cMsg OUTPUT;
        IF @bCtx=0 BEGIN SET @cMensaje=@cMsg; GOTO Salida; END;
        EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuario,@nSesion,@nUotSolicitada,'ORGANIZACIONES_LISTAR',0,@nUot OUTPUT,@bGeneral OUTPUT,@bUot OUTPUT,@cUotMsg OUTPUT;
        IF @bUot=0 BEGIN SET @cMensaje=@cUotMsg; GOTO Salida; END;
        SELECT A.area_id areaId,A.uot_id uotId,U.codigo uotCodigo,U.nombre uotNombre,A.uot_id empresaId,U.nombre empresa,A.area_padre_id areaPadreId,P.nombre areaPadre,A.codigo,A.nombre,A.estado,COUNT_BIG(*) OVER() totalRegistros
        FROM org.Area A JOIN org.UOT U ON U.uot_id=A.uot_id LEFT JOIN org.Area P ON P.area_id=A.area_padre_id AND P.uot_id=A.uot_id
        WHERE A.estado=1 AND (@nUot IS NULL OR A.uot_id=@nUot) AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,A.uot_id,'ORGANIZACIONES_LISTAR')=1
        ORDER BY U.nombre,A.nombre,A.area_id OFFSET @nOffset ROWS FETCH NEXT @nTamano ROWS ONLY;
        SET @bResultado=1; SET @cMensaje=N'Áreas consultadas.';
    END TRY BEGIN CATCH SET @bResultado=0; SET @cMensaje=N'No se pudieron consultar las áreas.'; END CATCH
Salida:
    SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido FROM config.FN_RespuestaUsuario(N'org.PA_Area_Sel_Listado',@bResultado,@cMensaje) R;
    RETURN CASE WHEN @bResultado=1 THEN 0 ELSE 1 END;
END;
GO
