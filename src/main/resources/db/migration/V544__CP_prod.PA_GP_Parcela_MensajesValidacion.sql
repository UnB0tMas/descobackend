-- V495: diagnósticos de parcelas; conserva superficie máxima, permisos, geografía, idempotencia y transacciones.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'prod.GPParcelaSolicitud',N'U') IS NULL
BEGIN
    CREATE TABLE prod.GPParcelaSolicitud (
        solicitud_id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        parcela_id BIGINT NOT NULL REFERENCES prod.Parcela(parcela_id),
        usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
        fecha_registro DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
GO
IF OBJECT_ID(N'prod.PA_GP_Parcela_Ins_Registro', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Parcela_Ins_Registro;
GO
CREATE PROCEDURE prod.PA_GP_Parcela_Ins_Registro
    @Sesion UNIQUEIDENTIFIER, @Usuario BIGINT, @Uot BIGINT, @Predio BIGINT,
    @Nombre NVARCHAR(120), @Area DECIMAL(10,4), @Distrito CHAR(6),
    @Centro BIGINT = NULL, @Lat DECIMAL(9,6) = NULL, @Lon DECIMAL(9,6) = NULL,
    @Solicitud UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_CREAR',1) <> 1
        THROW 51101,N'Acceso no autorizado.',1;
    IF @Solicitud IS NULL OR NULLIF(TRIM(@Nombre),N'') IS NULL OR @Area IS NULL OR @Area <= 0
       OR @Distrito IS NULL OR (@Lat IS NULL AND @Lon IS NOT NULL)
       OR (@Lat IS NOT NULL AND @Lon IS NULL)
       OR (@Lat IS NOT NULL AND (@Lat NOT BETWEEN -90 AND 90 OR @Lon NOT BETWEEN -180 AND 180))
        THROW 51103,N'Datos de parcela o georreferencia inválidos.',1;
    IF NOT EXISTS (
        SELECT 1 FROM prod.Predio P
        JOIN prod.PredioAmbito B ON B.predio_id=P.predio_id AND B.uot_id=@Uot
          AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
        WHERE P.predio_id=@Predio AND P.estado=1)
        THROW 51102,N'Predio fuera del ámbito general.',1;
    BEGIN TRAN;
    BEGIN TRY
        DECLARE @Id BIGINT, @Ubicacion BIGINT, @Ok BIT, @Msg NVARCHAR(300),
                @Limite DECIMAL(10,4), @Usado DECIMAL(18,4), @Sec BIGINT, @Codigo VARCHAR(40);
        SELECT @Id=parcela_id FROM prod.GPParcelaSolicitud WITH(UPDLOCK,HOLDLOCK) WHERE solicitud_id=@Solicitud;
        IF @Id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM prod.Parcela
          WHERE parcela_id=@Id AND predio_id=@Predio)
            THROW 51103,N'Solicitud utilizada para otro predio.',1;
        IF @Id IS NULL
        BEGIN
            -- Bloqueo del predio para calcular superficie sin carreras entre técnicos.
            DECLARE @BloqueoPredio BIGINT;
            SELECT @BloqueoPredio=predio_id FROM prod.Predio WITH(UPDLOCK,HOLDLOCK) WHERE predio_id=@Predio;
            SELECT TOP (1) @Limite=COALESCE(area_cultivable_ha,area_total_ha)
              FROM prod.PredioVersion WHERE predio_id=@Predio AND estado=1 AND fecha_hasta IS NULL
              ORDER BY fecha_desde DESC;
            SELECT @Usado=COALESCE(SUM(area_ha),0) FROM prod.Parcela WHERE predio_id=@Predio AND estado=1;
            IF @Limite IS NOT NULL AND @Usado+@Area>@Limite
                BEGIN
                DECLARE @Restante DECIMAL(18,4)=CASE WHEN @Limite>@Usado THEN @Limite-@Usado ELSE 0 END;
                DECLARE @AreaError NVARCHAR(2048)=CONCAT(N'La superficie excede las hectáreas disponibles para este predio. Disponible: ',CONVERT(NVARCHAR(40),@Restante),N' ha.');
                THROW 51103,@AreaError,1;
            END;
            EXEC geo.PA_Ubicacion_Ins_Interna @Distrito,@Centro,NULL,@Lat,@Lon,NULL,
                @Ubicacion OUTPUT,@Ok OUTPUT,@Msg OUTPUT;
            IF COALESCE(@Ok,0)<>1
            BEGIN
                DECLARE @GeoError NVARCHAR(2048)=CASE
                    WHEN @Msg IN (N'El distrito seleccionado no está disponible.',N'Seleccione un distrito.',
                                  N'El centro poblado seleccionado no corresponde al distrito.',
                                  N'La ubicación seleccionada no es válida.') THEN @Msg
                    ELSE N'Ubicación inválida: compruebe el distrito y centro poblado.' END;
                THROW 51103,@GeoError,1;
            END;
            SET @Sec=NEXT VALUE FOR prod.SQ_CodigoParcela;
            SET @Codigo='PAR-'+RIGHT(REPLICATE('0',12)+CONVERT(VARCHAR(20),@Sec),12);
            INSERT prod.Parcela(predio_id,codigo,nombre,area_ha,ubicacion_id)
            VALUES(@Predio,@Codigo,TRIM(@Nombre),@Area,@Ubicacion);
            SET @Id=CONVERT(BIGINT,SCOPE_IDENTITY());
            -- Idempotencia propia del procedimiento sin duplicar operaciones.
            INSERT prod.GPParcelaSolicitud(solicitud_id,parcela_id,usuario_id)
            VALUES(@Solicitud,@Id,@Usuario);
        END;
        COMMIT;
        SELECT @Id AS id;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'prod.PA_GP_Parcela_Upd_Registro', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Parcela_Upd_Registro;
GO
CREATE PROCEDURE prod.PA_GP_Parcela_Upd_Registro
    @Sesion UNIQUEIDENTIFIER, @Usuario BIGINT, @Uot BIGINT, @Parcela BIGINT,
    @Nombre NVARCHAR(120), @Area DECIMAL(10,4), @Distrito CHAR(6),
    @Centro BIGINT = NULL, @Lat DECIMAL(9,6) = NULL, @Lon DECIMAL(9,6) = NULL,
    @Solicitud UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_EDITAR',1)<>1
        THROW 51101,N'Acceso no autorizado.',1;
    IF @Solicitud IS NULL OR NULLIF(TRIM(@Nombre),N'') IS NULL OR @Area IS NULL OR @Area<=0
       OR @Distrito IS NULL OR (@Lat IS NULL AND @Lon IS NOT NULL)
       OR (@Lat IS NOT NULL AND @Lon IS NULL)
       OR (@Lat IS NOT NULL AND (@Lat NOT BETWEEN -90 AND 90 OR @Lon NOT BETWEEN -180 AND 180))
        THROW 51103,N'Datos de parcela inválidos.',1;
    BEGIN TRAN;
    BEGIN TRY
        DECLARE @Id BIGINT, @Predio BIGINT, @Ubi BIGINT, @Ok BIT, @Msg NVARCHAR(300),
                @Limite DECIMAL(10,4),@Usado DECIMAL(18,4),@Bloqueo BIGINT;
        SELECT @Id=parcela_id FROM prod.GPParcelaSolicitud WITH(UPDLOCK,HOLDLOCK)
        WHERE solicitud_id=@Solicitud;
        IF @Id IS NOT NULL AND @Id<>@Parcela THROW 51103,N'Solicitud reutilizada para otra parcela.',1;
        SELECT @Predio=P.predio_id FROM prod.Parcela P WITH(UPDLOCK,HOLDLOCK)
          JOIN prod.PredioAmbito B ON B.predio_id=P.predio_id AND B.uot_id=@Uot
           AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
          WHERE P.parcela_id=@Parcela AND P.estado=1;
        IF @Predio IS NULL THROW 51102,N'Parcela fuera del ámbito general.',1;
        IF @Id IS NULL
        BEGIN
            SELECT @Bloqueo=predio_id FROM prod.Predio WITH(UPDLOCK,HOLDLOCK) WHERE predio_id=@Predio;
            SELECT TOP (1) @Limite=COALESCE(area_cultivable_ha,area_total_ha)
              FROM prod.PredioVersion WHERE predio_id=@Predio AND estado=1 AND fecha_hasta IS NULL
              ORDER BY fecha_desde DESC;
            SELECT @Usado=COALESCE(SUM(area_ha),0) FROM prod.Parcela
                WHERE predio_id=@Predio AND estado=1 AND parcela_id<>@Parcela;
            IF @Limite IS NOT NULL AND @Usado+@Area>@Limite
                BEGIN
                DECLARE @Restante DECIMAL(18,4)=CASE WHEN @Limite>@Usado THEN @Limite-@Usado ELSE 0 END;
                DECLARE @AreaError NVARCHAR(2048)=CONCAT(N'La superficie excede las hectáreas disponibles para este predio. Disponible: ',CONVERT(NVARCHAR(40),@Restante),N' ha.');
                THROW 51103,@AreaError,1;
            END;
            -- Una ubicación nueva evita modificar una geo.Ubicacion que otro recurso comparte.
            EXEC geo.PA_Ubicacion_Ins_Interna @Distrito,@Centro,NULL,@Lat,@Lon,NULL,
                @Ubi OUTPUT,@Ok OUTPUT,@Msg OUTPUT;
            IF COALESCE(@Ok,0)<>1
            BEGIN
                DECLARE @GeoError NVARCHAR(2048)=CASE
                    WHEN @Msg IN (N'El distrito seleccionado no está disponible.',N'Seleccione un distrito.',
                                  N'El centro poblado seleccionado no corresponde al distrito.',
                                  N'La ubicación seleccionada no es válida.') THEN @Msg
                    ELSE N'Ubicación geográfica inválida.' END;
                THROW 51103,@GeoError,1;
            END;
            UPDATE prod.Parcela SET nombre=TRIM(@Nombre),area_ha=@Area,ubicacion_id=@Ubi
                WHERE parcela_id=@Parcela;
            INSERT prod.GPParcelaSolicitud(solicitud_id,parcela_id,usuario_id)
                VALUES(@Solicitud,@Parcela,@Usuario);
        END;
        COMMIT;
        SELECT @Parcela AS id;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO
