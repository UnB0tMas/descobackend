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
DROP PROCEDURE IF EXISTS prod.PA_GP_Parcela_Ins_Registro;
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
                THROW 51103,N'El área de las parcelas supera el área disponible del predio.',1;
            EXEC geo.PA_Ubicacion_Ins_Interna @Distrito,@Centro,NULL,@Lat,@Lon,NULL,
                @Ubicacion OUTPUT,@Ok OUTPUT,@Msg OUTPUT;
            IF COALESCE(@Ok,0)<>1 THROW 51103,N'Ubicación inválida: compruebe el distrito y centro poblado.',1;
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
