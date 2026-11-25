IF OBJECT_ID(N'[seg].[PA_UsuarioUOT_Ins_AsignarAccesoCompleto]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_UsuarioUOT_Ins_AsignarAccesoCompleto];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- Asigna pertenencia UOT y rol en una única transacción.
CREATE PROCEDURE [seg].[PA_UsuarioUOT_Ins_AsignarAccesoCompleto]
    @nActorUsuarioId BIGINT,
    @nUsuarioId BIGINT,
    @nUotId BIGINT,
    @nRolId BIGINT,
    @bPredeterminada BIT = 0,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT @bResultado = 0,
           @cMensaje = N'No se pudo asignar el acceso.';

    IF @nActorUsuarioId IS NULL OR @nUsuarioId IS NULL OR @nUotId IS NULL OR @nRolId IS NULL
        RETURN;

    IF ISNULL(seg.FN_Usuario_TienePermisoUOT(@nActorUsuarioId, @nUotId, 'UOT_ADMINISTRAR_ACCESOS'), 0) <> 1
    BEGIN
        SET @cMensaje = N'No tiene permiso para asignar accesos en esta UOT.';
        RETURN;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM seg.Usuario U
        WHERE U.usuario_id = @nUsuarioId AND U.estado = 1
    ) OR NOT EXISTS (
        SELECT 1 FROM org.UOT T
        WHERE T.uot_id = @nUotId AND T.estado = 1
    ) OR NOT EXISTS (
        SELECT 1 FROM seg.Rol R
        WHERE R.rol_id = @nRolId AND R.estado = 1
    )
    BEGIN
        SET @cMensaje = N'La selección ya no está disponible.';
        RETURN;
    END;

    DECLARE @cRolesJson NVARCHAR(MAX),
            @bDelegable BIT = 0,
            @cMensajeDelegacion NVARCHAR(300),
            @bPaso BIT = 0,
            @cMensajePaso NVARCHAR(300);

    SET @cRolesJson = (SELECT @nRolId AS rolId FOR JSON PATH);

    EXEC seg.PA_Autorizacion_Sel_ValidarDelegacionRoles
        @nUsuarioActorId = @nActorUsuarioId,
        @cRolesJson = @cRolesJson,
        @bRequerirAlMenosUno = 1,
        @bResultado = @bDelegable OUTPUT,
        @cMensaje = @cMensajeDelegacion OUTPUT;

    IF ISNULL(@bDelegable, 0) <> 1
    BEGIN
        SET @cMensaje = COALESCE(@cMensajeDelegacion, N'No puede asignar el rol seleccionado.');
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC seg.PA_UsuarioUOT_Ins_Asignar
            @nActorUsuarioId = @nActorUsuarioId,
            @nUsuarioId = @nUsuarioId,
            @nUotId = @nUotId,
            @bPredeterminada = @bPredeterminada,
            @bResultado = @bPaso OUTPUT,
            @cMensaje = @cMensajePaso OUTPUT;

        IF ISNULL(@bPaso, 0) <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @cMensaje = COALESCE(@cMensajePaso, N'No se pudo asignar la UOT.');
            RETURN;
        END;

        SET @bPaso = 0;
        SET @cMensajePaso = NULL;

        EXEC seg.PA_UsuarioUOTRol_Ins_Asignar
            @nActorUsuarioId = @nActorUsuarioId,
            @nUsuarioId = @nUsuarioId,
            @nUotId = @nUotId,
            @nRolId = @nRolId,
            @bResultado = @bPaso OUTPUT,
            @cMensaje = @cMensajePaso OUTPUT;

        IF ISNULL(@bPaso, 0) <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @cMensaje = COALESCE(@cMensajePaso, N'No se pudo asignar el rol.');
            RETURN;
        END;

        COMMIT TRANSACTION;
        SET @bResultado = 1;
        SET @cMensaje = N'Acceso y rol asignados correctamente.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        SET @bResultado = 0;
        SET @cMensaje = N'No se pudo asignar el acceso.';
    END CATCH;
END;
GO
