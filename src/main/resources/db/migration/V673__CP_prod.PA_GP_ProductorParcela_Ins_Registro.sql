IF OBJECT_ID(N'[prod].[PA_GP_ProductorParcela_Ins_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [prod].[PA_GP_ProductorParcela_Ins_Registro];
GO

-- Da de alta la parcela y crea, si falta, su predio técnico interno de forma atómica.
CREATE PROCEDURE prod.PA_GP_ProductorParcela_Ins_Registro
    @Sesion UNIQUEIDENTIFIER,
    @Usuario BIGINT,
    @Uot BIGINT,
    @Persona BIGINT,
    @Nombre NVARCHAR(120),
    @Area DECIMAL(10,4),
    @Distrito CHAR(6),
    @Centro BIGINT = NULL,
    @Lat DECIMAL(9,6) = NULL,
    @Lon DECIMAL(9,6) = NULL,
    @Solicitud UNIQUEIDENTIFIER,
    @Referencia NVARCHAR(300) = NULL,
    @Observacion NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF prod.FN_GP_Permiso(@Sesion, @Usuario, @Uot, 'CULTIVOS_CREAR', 1) <> 1
        THROW 51101, N'Acceso no autorizado.', 1;
    IF @Solicitud IS NULL OR @Area IS NULL OR @Area <= 0 OR NULLIF(TRIM(@Nombre), N'') IS NULL
       OR @Distrito IS NULL OR (@Lat IS NULL AND @Lon IS NOT NULL)
       OR (@Lat IS NOT NULL AND @Lon IS NULL)
        THROW 51103, N'Complete los datos de la parcela.', 1;

    BEGIN TRAN;
    BEGIN TRY
        DECLARE @Predio BIGINT, @Parcela BIGINT, @Ubicacion BIGINT, @Ok BIT,
                @Mensaje NVARCHAR(300), @Secuencia BIGINT, @Codigo VARCHAR(40);
        -- La vinculación activa también serializa las altas concurrentes del mismo productor.
        IF NOT EXISTS (
            SELECT 1 FROM org.ProductorUOT PU WITH (UPDLOCK, HOLDLOCK)
            JOIN org.Productor PR ON PR.persona_id = PU.persona_id AND PR.estado = 1
            JOIN org.Persona PE ON PE.persona_id = PU.persona_id AND PE.estado = 1
            WHERE PU.persona_id = @Persona AND PU.uot_id = @Uot
              AND PU.estado = 1 AND PU.fecha_hasta IS NULL)
            THROW 51102, N'Productor no disponible.', 1;

        SELECT @Parcela = S.parcela_id
        FROM prod.GPParcelaSolicitud S WITH (UPDLOCK, HOLDLOCK)
        WHERE S.solicitud_id = @Solicitud;
        IF @Parcela IS NOT NULL
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM prod.Parcela P
                JOIN prod.PredioAmbito A ON A.predio_id = P.predio_id AND A.uot_id = @Uot
                     AND A.estado = 1 AND A.convenio_uot_organizacion_id IS NULL
                WHERE P.parcela_id = @Parcela AND
                (EXISTS (SELECT 1 FROM prod.ProductorPredioTecnico T
                         WHERE T.predio_id = P.predio_id AND T.persona_id = @Persona AND T.uot_id = @Uot)
                 OR EXISTS (SELECT 1 FROM prod.PredioTitularidad PT
                            WHERE PT.predio_id = P.predio_id AND PT.persona_id = @Persona
                                  AND PT.estado = 1 AND PT.fecha_hasta IS NULL)))
                THROW 51103, N'Solicitud utilizada para otra parcela.', 1;
            COMMIT;
            SELECT @Parcela AS id;
            RETURN;
        END;

        SELECT @Predio = T.predio_id
        FROM prod.ProductorPredioTecnico T WITH (UPDLOCK, HOLDLOCK)
        WHERE T.persona_id = @Persona AND T.uot_id = @Uot;

        IF @Predio IS NULL
        BEGIN
            EXEC geo.PA_Ubicacion_Ins_Interna @Distrito, @Centro, @Referencia, @Lat, @Lon, NULL,
                @Ubicacion OUTPUT, @Ok OUTPUT, @Mensaje OUTPUT;
            IF COALESCE(@Ok, 0) <> 1 OR @Ubicacion IS NULL
                THROW 51103, N'Ubicación no válida.', 1;

            SET @Secuencia = NEXT VALUE FOR prod.SQ_CodigoPredio;
            SET @Codigo = 'PRE-' + RIGHT(REPLICATE('0', 12) + CONVERT(VARCHAR(20), @Secuencia), 12);
            INSERT prod.Predio(codigo, nombre, ubicacion_id, uot_id)
            VALUES (@Codigo, N'Registro productivo', @Ubicacion, @Uot);
            SET @Predio = CONVERT(BIGINT, SCOPE_IDENTITY());

            INSERT prod.PredioAmbito(predio_id, uot_id, convenio_uot_organizacion_id, usuario_creacion_id)
            VALUES (@Predio, @Uot, NULL, @Usuario);
            INSERT prod.PredioTitularidad(predio_id, persona_id, tipo_titularidad, porcentaje, fecha_desde, rol_titularidad)
            VALUES (@Predio, @Persona, 'PROPIETARIO', 100, CONVERT(DATE, SYSUTCDATETIME()), 'PRINCIPAL');
            INSERT prod.ProductorPredioTecnico(persona_id, uot_id, predio_id)
            VALUES (@Persona, @Uot, @Predio);
        END;

        -- Los mismos controles de superficie, geografía e idempotencia de la parcela existente.
        EXEC prod.PA_GP_Parcela_Ins_Registro
            @Sesion = @Sesion, @Usuario = @Usuario, @Uot = @Uot, @Predio = @Predio,
            @Nombre = @Nombre, @Area = @Area, @Distrito = @Distrito, @Centro = @Centro,
            @Lat = @Lat, @Lon = @Lon, @Solicitud = @Solicitud,
            @Referencia = @Referencia, @Observacion = @Observacion,
            @IdResultado = @Parcela OUTPUT, @SoloRetorno = 1;
        IF @Parcela IS NULL THROW 51103, N'No se pudo registrar la parcela.', 1;
        COMMIT;
        SELECT @Parcela AS id;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO
