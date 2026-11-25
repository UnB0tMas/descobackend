IF OBJECT_ID(N'[reporte].[PA_ReporteTemporal_ConfirmarDescarga]', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE [reporte].[PA_ReporteTemporal_ConfirmarDescarga];
END;
GO

-- Confirma la recepción y retira exclusivamente el trabajo propio y listo.
CREATE PROCEDURE reporte.PA_ReporteTemporal_ConfirmarDescarga
    @cAccion VARCHAR(16),
    @cJson NVARCHAR(MAX),
    @cDatos NVARCHAR(MAX) OUTPUT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @nHttp SMALLINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT @cDatos = NULL, @bResultado = 0,
           @cMensaje = N'No se pudo completar la solicitud.', @nHttp = 400;

    IF @cAccion NOT IN ('EXCEL', 'ESPECIAL') OR ISJSON(@cJson) <> 1
    BEGIN
        RETURN;
    END;

    DECLARE @usuario BIGINT, @sesion BIGINT, @dispositivo BIGINT, @empleado BIGINT,
            @modulo INT, @uot BIGINT, @id BIGINT, @modo VARCHAR(12),
            @corr UNIQUEIDENTIFIER, @sol UNIQUEIDENTIFIER, @ip VARCHAR(64),
            @endpoint NVARCHAR(250), @autorizado BIT, @mensaje NVARCHAR(300),
            @codigo VARCHAR(35), @formato VARCHAR(5), @perm VARCHAR(40),
            @clave NVARCHAR(250);

    BEGIN TRY
        SET @id = TRY_CONVERT(BIGINT, JSON_VALUE(@cJson, '$.datos.id'));
        IF @id IS NULL OR @id <= 0
        BEGIN
            RETURN;
        END;

        EXEC seg.PA_Operacion_Sel_ContextoAutorizado
            @cJson = @cJson,
            @cCodigoPermiso = 'REPORTES_LISTAR',
            @nUsuarioId = @usuario OUTPUT,
            @nSesionUsuarioId = @sesion OUTPUT,
            @nDispositivoUsuarioId = @dispositivo OUTPUT,
            @nEmpleadoId = @empleado OUTPUT,
            @nModuloId = @modulo OUTPUT,
            @gCorrelacionId = @corr OUTPUT,
            @gSolicitudId = @sol OUTPUT,
            @cIp = @ip OUTPUT,
            @cEndpoint = @endpoint OUTPUT,
            @bResultado = @autorizado OUTPUT,
            @cMensaje = @mensaje OUTPUT;

        IF ISNULL(@autorizado, 0) <> 1
        BEGIN
            SELECT @cMensaje = N'No tiene acceso a esta sección.', @nHttp = 403;
            RETURN;
        END;

        SELECT @uot = S.uot_contexto_id, @modo = S.modo_uot
        FROM seg.SesionUsuario S
        WHERE S.sesion_usuario_id = @sesion
          AND S.usuario_id = @usuario
          AND S.estado = 1
          AND S.fecha_revocacion IS NULL;

        IF @uot IS NULL OR @modo <> 'ESPECIFICA'
           OR ISNULL(seg.FN_Usuario_TienePermisoUOT(@usuario, @uot, 'REPORTES_CONTROL_VER'), 0) <> 1
           OR ISNULL(seg.FN_Usuario_TienePermisoUOT(@usuario, @uot, 'REPORTES_LISTAR'), 0) <> 1
           OR ISNULL(seg.FN_Usuario_TienePermisoUOT(@usuario, @uot, 'REPORTES_EXPORTAR'), 0) <> 1
           OR NOT EXISTS (
               SELECT 1 FROM seg.UsuarioUOT U
               WHERE U.usuario_id = @usuario AND U.uot_id = @uot AND U.estado = 1
                 AND U.fecha_desde <= SYSUTCDATETIME()
                 AND (U.fecha_hasta IS NULL OR U.fecha_hasta >= SYSUTCDATETIME())
           )
        BEGIN
            SELECT @cMensaje = N'No tiene acceso a esta sección.', @nHttp = 403;
            RETURN;
        END;

        BEGIN TRANSACTION;

        IF @cAccion = 'EXCEL'
        BEGIN
            SELECT @codigo = T.codigo, @clave = T.archivo_clave
            FROM reporte.TrabajoExcel T WITH (UPDLOCK, HOLDLOCK, ROWLOCK)
            WHERE T.trabajo_id = @id AND T.usuario_id = @usuario
              AND T.uot_id = @uot AND T.estado = 'LISTO';

            SET @perm = CASE
                WHEN @codigo LIKE 'POS[_]%' THEN 'VENTAS_REPORTES'
                WHEN @codigo = 'TEC_VISITAS' THEN 'VISITAS_LISTAR'
                WHEN @codigo = 'TEC_SALIDAS' THEN 'SALIDAS_LISTAR'
                WHEN @codigo = 'TEC_SANIDAD' THEN 'SANIDAD_LISTAR'
                WHEN @codigo LIKE 'REC[_]%' THEN 'INVENTARIO_LISTAR'
                WHEN @codigo = 'DOC_EVIDENCIAS' THEN 'ARCHIVOS_LISTAR'
                ELSE 'DOCS_VER'
            END;

            IF @codigo IS NULL OR @clave IS NULL
               OR @clave <> CONCAT(N'exports/', @id, N'.xlsx')
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT @cMensaje = N'El archivo no está disponible.', @nHttp = 404;
                RETURN;
            END;

            IF ISNULL(seg.FN_Usuario_TienePermisoUOT(@usuario, @uot, @perm), 0) <> 1
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT @cMensaje = N'No tiene acceso a este reporte.', @nHttp = 403;
                RETURN;
            END;

            DELETE FROM reporte.TrabajoExcel
            WHERE trabajo_id = @id AND usuario_id = @usuario
              AND uot_id = @uot AND estado = 'LISTO';
        END
        ELSE
        BEGIN
            SELECT @codigo = T.tipo, @formato = T.formato, @clave = T.archivo_clave
            FROM reporte.TrabajoEspecial T WITH (UPDLOCK, HOLDLOCK, ROWLOCK)
            WHERE T.trabajo_id = @id AND T.usuario_id = @usuario
              AND T.uot_id = @uot AND T.estado = 'LISTO';

            SET @perm = CASE
                WHEN @codigo = 'AP_SOCIOS' THEN 'APAPPSS_SOCIOS_LISTAR'
                WHEN @codigo = 'AP_PREDIOS' THEN 'APAPPSS_PREDIOS_LISTAR'
                WHEN @codigo = 'AP_CAMPANIAS' THEN 'CAMPANIAS_LISTAR'
                WHEN @codigo = 'AP_VENTAS' THEN 'ENTREGAS_LISTAR'
                WHEN @codigo = 'AP_COMPRADORES' THEN 'COMPRADORES_LISTAR'
                WHEN @codigo = 'AP_LIQUIDACIONES' THEN 'LIQUIDACIONES_LISTAR'
                WHEN @codigo = 'AP_PAGOS' THEN 'PAGOS_LISTAR'
                WHEN @codigo = 'AP_SANIDAD' THEN 'APAPPSS_PREDIOS_VER'
                ELSE 'SANIDAD_LISTAR'
            END;

            IF @codigo IS NULL OR @clave IS NULL OR @formato NOT IN ('XLSX', 'PDF', 'DOCX')
               OR @clave <> CONCAT(N'reports-special/', @id, N'.', LOWER(@formato))
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT @cMensaje = N'El archivo no está disponible.', @nHttp = 404;
                RETURN;
            END;

            IF ISNULL(seg.FN_Usuario_TienePermisoUOT(@usuario, @uot, @perm), 0) <> 1
               OR (@codigo LIKE 'AP[_]%' AND
                   ISNULL(seg.FN_Usuario_TienePermisoUOT(@usuario, @uot, 'REPORTES_APAPPSS_VER'), 0) <> 1)
               OR (@codigo IN ('AP_SANIDAD', 'TEC_SANIDAD_DOC') AND
                   ISNULL(seg.FN_Usuario_TienePermisoUOT(@usuario, @uot, 'REPORTES_SANIDAD_DOC_VER'), 0) <> 1)
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT @cMensaje = N'No tiene acceso a este informe.', @nHttp = 403;
                RETURN;
            END;

            DELETE FROM reporte.TrabajoEspecial
            WHERE trabajo_id = @id AND usuario_id = @usuario
              AND uot_id = @uot AND estado = 'LISTO';
        END;

        COMMIT TRANSACTION;
        SELECT @cDatos = @clave, @bResultado = 1, @nHttp = 200,
               @cMensaje = N'Descarga confirmada.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;
        SELECT @bResultado = 0, @cDatos = NULL, @nHttp = 500,
               @cMensaje = N'No se pudo completar la solicitud.';
        THROW;
    END CATCH;
END;
GO
