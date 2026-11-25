IF OBJECT_ID(N'[prod].[PA_GP_Productor_Upd_Datos]', N'P') IS NOT NULL
    DROP PROCEDURE [prod].[PA_GP_Productor_Upd_Datos];
GO

-- Actualiza org.Persona y conserva la asociación del productor con su UOT.
CREATE PROCEDURE prod.PA_GP_Productor_Upd_Datos
    @Sesion UNIQUEIDENTIFIER,
    @Usuario BIGINT,
    @Uot BIGINT,
    @Persona BIGINT,
    @Nombres NVARCHAR(100),
    @Paterno NVARCHAR(80),
    @Materno NVARCHAR(80) = NULL,
    @Telefono VARCHAR(30) = NULL,
    @Correo VARCHAR(180) = NULL,
    @Distrito CHAR(6) = NULL,
    @Centro BIGINT = NULL,
    @Referencia NVARCHAR(300) = NULL,
    @Solicitud UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF prod.FN_GP_Permiso(@Sesion, @Usuario, @Uot, 'PREDIOS_EDITAR', 1) <> 1
        THROW 51101, N'Acceso no autorizado.', 1;
    IF @Solicitud IS NULL OR NULLIF(TRIM(@Nombres), N'') IS NULL OR NULLIF(TRIM(@Paterno), N'') IS NULL
        THROW 51103, N'Complete los nombres y apellidos.', 1;
    IF @Correo IS NOT NULL AND TRIM(@Correo) <> '' AND @Correo NOT LIKE '%_@_%._%'
        THROW 51103, N'Ingrese un correo válido.', 1;

    DECLARE @Hash VARBINARY(32) = HASHBYTES('SHA2_256', CONCAT(
        @Persona, '|', @Uot, '|', TRIM(@Nombres), '|', TRIM(@Paterno), '|',
        COALESCE(TRIM(@Materno), N''), '|', COALESCE(TRIM(@Telefono), ''), '|',
        COALESCE(TRIM(@Correo), ''), '|', COALESCE(@Distrito, ''), '|',
        COALESCE(@Centro, 0), '|', COALESCE(TRIM(@Referencia), N'')));

    BEGIN TRAN;
    BEGIN TRY
        DECLARE @Anterior VARBINARY(32), @Accion VARCHAR(16), @PersonaAnterior BIGINT,
                @UotAnterior BIGINT, @Ubicacion BIGINT, @Ok BIT, @Mensaje NVARCHAR(300);
        SELECT @Anterior = hash_datos, @Accion = accion,
               @PersonaAnterior = persona_id, @UotAnterior = uot_id
        FROM prod.GPProductorSolicitud WITH (UPDLOCK, HOLDLOCK)
        WHERE solicitud_id = @Solicitud;

        IF @Anterior IS NOT NULL
        BEGIN
            IF @Anterior <> @Hash OR @Accion <> 'EDITAR' OR @PersonaAnterior <> @Persona OR @UotAnterior <> @Uot
                THROW 51103, N'Solicitud utilizada para otros datos.', 1;
            COMMIT;
            SELECT @Persona AS id;
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1 FROM org.ProductorUOT PU WITH (UPDLOCK, HOLDLOCK)
            JOIN org.Persona P ON P.persona_id = PU.persona_id AND P.estado = 1
            WHERE PU.persona_id = @Persona AND PU.uot_id = @Uot
              AND PU.estado = 1 AND PU.fecha_hasta IS NULL)
            THROW 51102, N'Productor no disponible.', 1;

        SELECT @Ubicacion = P.ubicacion_id FROM org.Persona P WITH (UPDLOCK, HOLDLOCK)
        WHERE P.persona_id = @Persona;
        IF @Distrito IS NOT NULL
        BEGIN
            EXEC geo.PA_Ubicacion_Ins_Interna @Distrito, @Centro, @Referencia, NULL, NULL, NULL,
                 @Ubicacion OUTPUT, @Ok OUTPUT, @Mensaje OUTPUT;
            IF COALESCE(@Ok, 0) <> 1
                THROW 51103, N'Ubicación no válida.', 1;
        END;
        IF NULLIF(TRIM(@Correo), '') IS NOT NULL AND EXISTS (
            SELECT 1 FROM org.Persona WITH (UPDLOCK, HOLDLOCK)
            WHERE correo_clave_desco = LOWER(TRIM(@Correo)) COLLATE Latin1_General_100_CI_AS
              AND persona_id <> @Persona)
            THROW 51103, N'El correo ya está registrado.', 1;

        UPDATE org.Persona
        SET nombres = TRIM(@Nombres), apellido_paterno = TRIM(@Paterno),
            apellido_materno = NULLIF(TRIM(@Materno), N''),
            telefono = NULLIF(TRIM(@Telefono), ''), correo = NULLIF(TRIM(@Correo), ''),
            ubicacion_id = COALESCE(@Ubicacion, ubicacion_id)
        WHERE persona_id = @Persona AND estado = 1;

        INSERT prod.GPProductorSolicitud (solicitud_id, accion, persona_id, uot_id, hash_datos)
        VALUES (@Solicitud, 'EDITAR', @Persona, @Uot, @Hash);
        COMMIT;
        SELECT @Persona AS id;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO
