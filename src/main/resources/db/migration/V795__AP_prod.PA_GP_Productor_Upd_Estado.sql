IF OBJECT_ID(N'[prod].[PA_GP_Productor_Upd_Estado]', N'P') IS NOT NULL
    DROP PROCEDURE prod.PA_GP_Productor_Upd_Estado;
GO

-- Control de actuaciones productivas por sesión, UOT y predio.
CREATE PROCEDURE prod.PA_GP_Productor_Upd_Estado
    @Sesion UNIQUEIDENTIFIER,
    @Usuario BIGINT,
    @Uot BIGINT,
    @Persona BIGINT,
    @Motivo NVARCHAR(500),
    @Solicitud UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF prod.FN_GP_Permiso(@Sesion, @Usuario, @Uot, 'PREDIOS_RETIRAR', 1) <> 1
        THROW 51101, N'Acceso no autorizado.', 1;
    IF prod.FN_GP_PuedeActuarProductor(@Sesion, @Usuario, @Uot, @Persona) <> 1
        THROW 51101, N'Debe iniciar una visita a un predio del productor desde una salida aprobada.', 1;

    IF @Solicitud IS NULL OR LEN(TRIM(COALESCE(@Motivo, N''))) < 3
        THROW 51103, N'Indique el motivo del retiro.', 1;

    DECLARE @Hash VARBINARY(32) = HASHBYTES('SHA2_256', CONCAT(@Persona, '|', @Uot, '|', TRIM(@Motivo)));
    BEGIN TRAN;
    BEGIN TRY
        DECLARE @Anterior VARBINARY(32), @Accion VARCHAR(16), @PersonaAnterior BIGINT, @UotAnterior BIGINT;
        SELECT @Anterior = hash_datos, @Accion = accion,
               @PersonaAnterior = persona_id, @UotAnterior = uot_id
        FROM prod.GPProductorSolicitud WITH (UPDLOCK, HOLDLOCK)
        WHERE solicitud_id = @Solicitud;

        IF @Anterior IS NOT NULL
        BEGIN
            IF @Anterior <> @Hash OR @Accion <> 'RETIRAR' OR @PersonaAnterior <> @Persona OR @UotAnterior <> @Uot
                THROW 51103, N'Solicitud utilizada para otro registro.', 1;
            COMMIT;
            SELECT @Persona AS id;
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM org.ProductorUOT WITH (UPDLOCK, HOLDLOCK)
                       WHERE persona_id = @Persona AND uot_id = @Uot
                         AND estado = 1 AND fecha_hasta IS NULL)
            THROW 51102, N'Productor no disponible.', 1;

        UPDATE org.ProductorUOT
        SET estado = 0, fecha_hasta = CONVERT(DATE, SYSUTCDATETIME())
        WHERE persona_id = @Persona AND uot_id = @Uot AND estado = 1 AND fecha_hasta IS NULL;

        INSERT prod.GPProductorSolicitud (solicitud_id, accion, persona_id, uot_id, hash_datos)
        VALUES (@Solicitud, 'RETIRAR', @Persona, @Uot, @Hash);
        COMMIT;
        SELECT @Persona AS id;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO
