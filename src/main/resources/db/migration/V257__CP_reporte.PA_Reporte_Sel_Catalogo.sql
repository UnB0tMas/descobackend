IF OBJECT_ID(N'[reporte].[PA_Reporte_Sel_Catalogo]', N'P') IS NOT NULL
    DROP PROCEDURE [reporte].[PA_Reporte_Sel_Catalogo];
GO

/******************************************************************************************************
' Nombre del PA           : reporte.PA_Reporte_Sel_Catalogo
' Descripción             : Consulta el catálogo de reportes disponibles.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Reportes
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
    EXEC [reporte].[PA_Reporte_Sel_Catalogo]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [reporte].[PA_Reporte_Sel_Catalogo]
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
    SET ANSI_NULLS ON;
    SET ANSI_PADDING ON;
    SET ANSI_WARNINGS ON;
    SET ARITHABORT ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET NUMERIC_ROUNDABORT OFF;

    BEGIN TRY

    SET NOCOUNT ON;

    DECLARE
        @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,
        @gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
        @bCtx BIT,@cMsg NVARCHAR(300);

    SELECT
        @bResultado=0,
        @cMensaje=N'No se pudieron consultar los reportes.';

    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
        @cJson=@cJson,
        @cCodigoPermiso='REPORTES_LISTAR',
        @nUsuarioId=@nUsuario OUTPUT,
        @nSesionUsuarioId=@nSesion OUTPUT,
        @nDispositivoUsuarioId=@nDisp OUTPUT,
        @nEmpleadoId=@nEmp OUTPUT,
        @nModuloId=@nModulo OUTPUT,
        @gCorrelacionId=@gCorr OUTPUT,
        @gSolicitudId=@gSol OUTPUT,
        @cIp=@cIp OUTPUT,
        @cEndpoint=@cEnd OUTPUT,
        @bResultado=@bCtx OUTPUT,
        @cMensaje=@cMsg OUTPUT;

    IF @bCtx=0
    BEGIN
        SET @cMensaje=@cMsg;
        GOTO __DESCO_Salida;
    END;

    DECLARE @Permisos TABLE
    (
        codigo VARCHAR(40) NOT NULL PRIMARY KEY
    );

    INSERT INTO @Permisos(codigo)
    SELECT DISTINCT P.codigo
    FROM [seg].[UsuarioRol] UR
    INNER JOIN [seg].[Rol] R
        ON R.rol_id=UR.rol_id
       AND R.estado=1
    INNER JOIN [seg].[RolPermiso] RP
        ON RP.rol_id=R.rol_id
       AND RP.estado=1
    INNER JOIN [seg].[Permiso] P
        ON P.permiso_id=RP.permiso_id
       AND P.estado=1
    WHERE UR.usuario_id=@nUsuario
      AND UR.estado=1
      AND UR.fecha_desde<=SYSUTCDATETIME()
      AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta>=SYSUTCDATETIME());

    DECLARE @bSupervisionTransversal BIT =
        CASE WHEN EXISTS(SELECT 1 FROM @Permisos WHERE codigo='AUDITORIA_VER') THEN 1 ELSE 0 END;

    SELECT codigo,nombre,grupo,descripcion
    FROM
    (
        SELECT
            'TECNICO' codigo,
            N'Reporte técnico' nombre,
            N'Técnico' grupo,
            N'Productores, predios, cultivos, evaluaciones, sanidad y producción.' descripcion,
            10 orden
        WHERE @bSupervisionTransversal=1
           OR
           (
               EXISTS(SELECT 1 FROM @Permisos WHERE codigo='PRODUCTORES_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='PREDIOS_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='EVALUACIONES_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='SANIDAD_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='PRODUCCION_LISTAR')
           )

        UNION ALL

        SELECT
            'PLANIFICACION',
            N'Reporte de planificación',
            N'Planificación',
            N'Salidas, visitas y recursos programados frente a ejecución.',
            20
        WHERE @bSupervisionTransversal=1
           OR
           (
               EXISTS(SELECT 1 FROM @Permisos WHERE codigo='SALIDAS_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='RECURSOS_LISTAR')
           )

        UNION ALL

        SELECT
            'COMERCIAL',
            N'Reporte comercial',
            N'Comercial',
            N'Campañas, operativos, jabas, acopio e incidencias.',
            30
        WHERE @bSupervisionTransversal=1
           OR
           (
               EXISTS(SELECT 1 FROM @Permisos WHERE codigo='CAMPANIAS_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='OPERATIVOS_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='JABAS_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='ENTREGAS_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='INCIDENCIAS_LISTAR')
           )

        UNION ALL

        SELECT
            'FINANCIERO',
            N'Reporte financiero',
            N'Finanzas',
            N'Gastos, liquidaciones, pagos, cobros y saldos.',
            40
        WHERE @bSupervisionTransversal=1
           OR
           (
               EXISTS(SELECT 1 FROM @Permisos WHERE codigo='GASTOS_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='LIQUIDACIONES_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='PAGOS_LISTAR')
               AND EXISTS(SELECT 1 FROM @Permisos WHERE codigo='COBROS_LISTAR')
           )
    ) X
    ORDER BY orden;

    SET @bResultado=1;
    SET @cMensaje=N'Reportes consultados correctamente.';

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
    @cProcedimiento = N'reporte.PA_Reporte_Sel_Catalogo',
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
    @cProcedimiento = N'reporte.PA_Reporte_Sel_Catalogo',
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
FROM config.FN_RespuestaUsuario(N'reporte.PA_Reporte_Sel_Catalogo',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
