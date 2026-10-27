IF OBJECT_ID(N'[logistica].[PA_SuministroUOT_Ins_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_SuministroUOT_Ins_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_SuministroUOT_Ins_Registro
' Descripción             : Registra suministro por UOT.
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
    DECLARE
        @nSuministroId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [logistica].[PA_SuministroUOT_Ins_Registro]
        @nUsuarioId = 0,
        @nSesionUsuarioId = 0,
        @nUotId = 0,
        @cCodigo = '',
        @cNombre = N'',
        @cUnidad = '',
        @nStockInicial = 0,
        @nStockMinimo = 0,
        @nSuministroId = @nSuministroId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nSuministroId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [logistica].[PA_SuministroUOT_Ins_Registro]
    @nUsuarioId BIGINT,
    @nSesionUsuarioId BIGINT,
    @nUotId BIGINT,
    @cCodigo VARCHAR(40),
    @cNombre NVARCHAR(150),
    @cUnidad VARCHAR(20),
    @nStockInicial DECIMAL(19,3) = 0,
    @nStockMinimo DECIMAL(19,3) = 0,
    @nSuministroId BIGINT OUTPUT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60) = NULL OUTPUT,
    @nHttpRespuesta SMALLINT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT
        @nSuministroId = NULL,
        @bResultado = 0,
        @cMensaje = N'No se pudo registrar el suministro.',
        @cCodigoRespuesta = 'SUMINISTRO_NO_CREADO',
        @nHttpRespuesta = 400;

    DECLARE
        @nUotResuelta BIGINT = @nUotId,
        @bModoGeneral BIT,
        @bContextoOk BIT,
        @cMensajeContexto NVARCHAR(300);

    EXEC [seg].[PA_UOT_Sel_ResolverContextoSesion]
        @nUsuarioId = @nUsuarioId,
        @nSesionUsuarioId = @nSesionUsuarioId,
        @nUotSolicitada = @nUotResuelta,
        @cCodigoPermiso = 'INVENTARIO_CREAR',
        @bRequiereUot = 1,
        @nUotId = @nUotResuelta OUTPUT,
        @bModoGeneral = @bModoGeneral OUTPUT,
        @bResultado = @bContextoOk OUTPUT,
        @cMensaje = @cMensajeContexto OUTPUT;

    IF ISNULL(@bContextoOk, 0) = 0
    BEGIN
        SET @cMensaje = COALESCE(NULLIF(@cMensajeContexto, N''), @cMensaje);
        RETURN 1;
    END;

    SET @cCodigo = UPPER(NULLIF(LTRIM(RTRIM(@cCodigo)), ''));
    SET @cNombre = NULLIF(LTRIM(RTRIM(@cNombre)), N'');
    SET @cUnidad = UPPER(NULLIF(LTRIM(RTRIM(@cUnidad)), ''));
    SET @nStockInicial = COALESCE(@nStockInicial, 0);
    SET @nStockMinimo = COALESCE(@nStockMinimo, 0);

    /* El código definitivo depende del ID. */
    SET @cCodigo =
        CONCAT(
            'TMP-S-',
            REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', '')
        );

    IF @cNombre IS NULL OR @cUnidad IS NULL
       OR @nStockInicial < 0 OR @nStockMinimo < 0
    BEGIN
        SET @cMensaje = N'Complete correctamente los datos del suministro.';
        RETURN 1;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [config].[CatalogoRecursoValor]
        WHERE catalogo = 'UNIDAD_MEDIDA'
          AND codigo = @cUnidad
          AND estado = 1
    )
    BEGIN
        SET @cMensaje = N'La unidad de medida seleccionada no está disponible.';
        RETURN 1;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM [logistica].[Suministro]
        WHERE uot_id = @nUotResuelta
          AND codigo = @cCodigo
    )
    BEGIN
        SELECT
            @cMensaje = N'El código del suministro ya está registrado en esta UOT.',
            @cCodigoRespuesta = 'SUMINISTRO_DUPLICADO',
            @nHttpRespuesta = 409;
        RETURN 1;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO [logistica].[Suministro]
        (
            uot_id,
            codigo,
            nombre,
            unidad_medida,
            estado,
            stock_minimo
        )
        VALUES
        (
            @nUotResuelta,
            @cCodigo,
            @cNombre,
            @cUnidad,
            1,
            @nStockMinimo
        );

        SET @nSuministroId = CONVERT(BIGINT, SCOPE_IDENTITY());

        SET @cCodigo =
            [logistica].[FN_CodigoRecursoUOT]
            (
                @nUotResuelta,
                @cNombre,
                @nSuministroId
            );

        UPDATE [logistica].[Suministro]
           SET codigo = @cCodigo
         WHERE suministro_id = @nSuministroId;


        IF @nStockInicial > 0
        BEGIN
            INSERT INTO [logistica].[SuministroMovimiento]
            (
                suministro_id,
                uot_id,
                recurso_programado_id,
                tipo_movimiento,
                cantidad,
                fecha_hora,
                usuario_id,
                documento_referencia,
                observacion,
                estado
            )
            VALUES
            (
                @nSuministroId,
                @nUotResuelta,
                NULL,
                'ENTRADA',
                @nStockInicial,
                SYSUTCDATETIME(),
                @nUsuarioId,
                N'STOCK_INICIAL',
                N'Stock inicial.',
                1
            );
        END
        ELSE IF NOT EXISTS
        (
            SELECT 1
            FROM [logistica].[SuministroSaldo]
            WHERE suministro_id = @nSuministroId
        )
        BEGIN
            INSERT INTO [logistica].[SuministroSaldo]
            (
                suministro_id,
                stock_actual,
                stock_reservado,
                fecha_actualizacion
            )
            VALUES
            (
                @nSuministroId,
                0,
                0,
                SYSUTCDATETIME()
            );
        END;

        COMMIT TRANSACTION;

        SELECT
            @bResultado = 1,
            @cMensaje = N'Suministro registrado correctamente.',
            @cCodigoRespuesta = 'SUMINISTRO_CREADO',
            @nHttpRespuesta = 201;

        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        SET @nSuministroId = NULL;
        SET @bResultado = 0;

        IF ERROR_NUMBER() IN (2601, 2627)
        BEGIN
            SELECT
                @cMensaje = N'El código del suministro ya está registrado en esta UOT.',
                @cCodigoRespuesta = 'SUMINISTRO_DUPLICADO',
                @nHttpRespuesta = 409;
        END
        ELSE
        BEGIN
            SELECT
                @cMensaje = N'No se pudo registrar el suministro. Revise los datos e intente nuevamente.',
                @cCodigoRespuesta = 'SUMINISTRO_NO_CREADO',
                @nHttpRespuesta = 400;
        END;

        RETURN 1;
    END CATCH;
END;
GO
