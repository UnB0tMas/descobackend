IF OBJECT_ID(N'[reporte].[PA_DashboardBI_Sel_Segmentadores]') IS NOT NULL
    DROP PROCEDURE [reporte].[PA_DashboardBI_Sel_Segmentadores];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : reporte.PA_DashboardBI_Sel_Segmentadores
' Descripción            : Consulta dashboard bi para segmentadores.
' Aplicativo / Módulo    : DESCO / reporte
*******************************************************************************************************/
CREATE   PROCEDURE reporte.PA_DashboardBI_Sel_Segmentadores
    @cJson NVARCHAR(MAX),
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60) = NULL OUTPUT,
    @nHttpRespuesta SMALLINT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @bResultado = 0;
    SET @cMensaje = N'No se pudieron cargar los filtros.';
    SET @cCodigoRespuesta = 'BI_FILTROS_NO_DISPONIBLES';
    SET @nHttpRespuesta = 400;
    BEGIN TRY
        DECLARE @nUsuario BIGINT, @nSesion BIGINT, @nDisp BIGINT, @nEmpleado BIGINT, @nModulo INT,
                @gCorr UNIQUEIDENTIFIER, @gSol UNIQUEIDENTIFIER, @cIp VARCHAR(64), @cEndpoint NVARCHAR(250),
                @bCtx BIT, @cMsg NVARCHAR(300), @nUot BIGINT, @cModo VARCHAR(12);
        EXEC seg.PA_Operacion_Sel_ContextoAutorizado
            @cJson = @cJson, @cCodigoPermiso = 'DASHBOARD_BI_VER',
            @nUsuarioId = @nUsuario OUTPUT,
            @nSesionUsuarioId = @nSesion OUTPUT,
            @nDispositivoUsuarioId = @nDisp OUTPUT,
            @nEmpleadoId = @nEmpleado OUTPUT, @nModuloId = @nModulo OUTPUT,
            @gCorrelacionId = @gCorr OUTPUT, @gSolicitudId = @gSol OUTPUT,
            @cIp = @cIp OUTPUT, @cEndpoint = @cEndpoint OUTPUT,
            @bResultado = @bCtx OUTPUT, @cMensaje = @cMsg OUTPUT;
        IF ISNULL(@bCtx,0) <> 1
        BEGIN
            SET @cMensaje = COALESCE(@cMsg,N'Sin permiso.');
            SET @cCodigoRespuesta = 'BI_NO_AUTORIZADO';
            SET @nHttpRespuesta = 403;
            RETURN;
        END;
        SELECT @nUot = S.uot_contexto_id, @cModo = S.modo_uot
        FROM seg.SesionUsuario S WHERE S.sesion_usuario_id = @nSesion AND S.usuario_id = @nUsuario AND S.estado = 1;
        IF @nUot IS NULL OR @cModo <> 'ESPECIFICA' OR
           ISNULL(seg.FN_Usuario_TienePermisoUOT(@nUsuario, @nUot, 'DASHBOARD_BI_VER'), 0) <> 1 OR NOT EXISTS (
            SELECT 1 FROM seg.UsuarioUOT UU
            WHERE UU.usuario_id = @nUsuario AND UU.uot_id = @nUot AND UU.estado = 1
              AND UU.fecha_desde <= SYSUTCDATETIME()
              AND (UU.fecha_hasta IS NULL OR UU.fecha_hasta >= SYSUTCDATETIME()))
        BEGIN
            SET @cMensaje = N'Seleccione una unidad autorizada.';
            SET @cCodigoRespuesta = 'BI_UOT_REQUERIDA';
            SET @nHttpRespuesta = 403;
            RETURN;
        END;
        DECLARE @PuedeAlmacen BIT=0, @PuedePredio BIT=0;
        SET @PuedeAlmacen = CASE WHEN seg.FN_Usuario_TienePermisoUOT(@nUsuario,@nUot,'VENTAS_REPORTES')=1
                                     OR seg.FN_Usuario_TienePermisoUOT(@nUsuario,@nUot,'INVENTARIO_LISTAR')=1
                                THEN 1 ELSE 0 END;
        SET @PuedePredio = CASE WHEN seg.FN_Usuario_TienePermisoUOT(@nUsuario,@nUot,'SALIDAS_LISTAR')=1
                                   OR seg.FN_Usuario_TienePermisoUOT(@nUsuario,@nUot,'ARCHIVOS_LISTAR')=1
                              THEN 1 ELSE 0 END;

        SELECT N'UOT autorizada' AS contexto;
        SELECT A.almacen_id AS id, A.nombre
        FROM logistica.Almacen A
        WHERE A.uot_propietaria_id=@nUot AND A.estado=1 AND ISNULL(@PuedeAlmacen,0)=1
        ORDER BY A.nombre;
        SELECT P.predio_id AS id, P.nombre
        FROM prod.Predio P
        WHERE P.uot_id=@nUot AND P.estado=1 AND @PuedePredio=1
          AND EXISTS (SELECT 1 FROM prod.PredioAmbito PA
                      WHERE PA.predio_id=P.predio_id AND PA.uot_id=@nUot
                        AND PA.convenio_uot_organizacion_id IS NULL AND PA.estado=1)
        ORDER BY P.nombre;
        SET @bResultado=1;
        SET @cMensaje=N'Filtros disponibles.';
        SET @cCodigoRespuesta='BI_FILTROS';
        SET @nHttpRespuesta=200;
    END TRY
    BEGIN CATCH
        SET @bResultado=0;
        SET @cMensaje=N'No se pudieron cargar los filtros.';
        SET @cCodigoRespuesta='BI_ERROR_SEGMENTADORES';
        SET @nHttpRespuesta=500;
    END CATCH;
END;
GO
