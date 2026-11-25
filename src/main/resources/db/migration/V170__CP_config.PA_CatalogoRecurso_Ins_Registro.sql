IF OBJECT_ID(N'[config].[PA_CatalogoRecurso_Ins_Registro]') IS NOT NULL
    DROP PROCEDURE [config].[PA_CatalogoRecurso_Ins_Registro];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : config.PA_CatalogoRecurso_Ins_Registro
' Descripción            : Registra la información de catalogo recurso.
' Aplicativo / Módulo    : DESCO / config
*******************************************************************************************************/
CREATE   PROCEDURE [config].[PA_CatalogoRecurso_Ins_Registro]
    @nUsuarioId BIGINT,
    @cCatalogo VARCHAR(40),
    @cCodigo VARCHAR(40),
    @cNombre NVARCHAR(150),
    @cDescripcion NVARCHAR(300)=NULL,
    @nCatalogoId BIGINT OUTPUT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        @nCatalogoId=NULL,
        @bResultado=0,
        @cMensaje=N'No se pudo registrar el valor.',
        @cCodigoRespuesta='CATALOGO_NO_CREADO',
        @nHttpRespuesta=400;

    SELECT
        @cCatalogo=UPPER(NULLIF(LTRIM(RTRIM(@cCatalogo)),'')),
        @cCodigo=UPPER(NULLIF(LTRIM(RTRIM(@cCodigo)),'')),
        @cNombre=NULLIF(LTRIM(RTRIM(@cNombre)),N''),
        @cDescripcion=NULLIF(LTRIM(RTRIM(@cDescripcion)),N'');

    IF @cCatalogo NOT IN
       (
           'TIPO_VEHICULO',
           'UNIDAD_MEDIDA',
           'CATEGORIA_PRODUCTO',
           'MONEDA',
           'CARGO_EMPLEADO',
           'TIPO_TITULARIDAD_PREDIO'
       )
       OR @cNombre IS NULL
    BEGIN
        SET @cMensaje=N'Complete correctamente los datos del catálogo.';
        RETURN 1;
    END;

    IF @cCatalogo IN('MONEDA','UNIDAD_MEDIDA','TIPO_TITULARIDAD_PREDIO')
       AND @cCodigo IS NULL
    BEGIN
        SET @cMensaje=N'Ingrese el código del valor.';
        RETURN 1;
    END;

    IF @cCatalogo='TIPO_TITULARIDAD_PREDIO' AND @cCodigo NOT IN ('PROPIETARIO','COPROPIETARIO','POSESIONARIO','ARRENDATARIO','OTRO')
    BEGIN SET @cMensaje=N'Seleccione un tipo de titularidad permitido.'; RETURN 1; END;

    IF @cCatalogo='TIPO_TITULARIDAD_PREDIO' AND (@cCodigo NOT LIKE '[A-Z]%' OR @cCodigo LIKE '%[^A-Z_]' OR LEN(@cCodigo)>20 OR LEN(@cCodigo)<2)
    BEGIN SET @cMensaje=N'Ingrese un código válido para el tipo de titularidad.'; RETURN 1; END;

    IF @cCatalogo='MONEDA'
       AND
       (
           LEN(@cCodigo)<>3
           OR @cCodigo LIKE '%[^A-Z]%'
       )
    BEGIN
        SET @cMensaje=N'El código de moneda debe tener tres letras.';
        RETURN 1;
    END;

    IF @cCatalogo='UNIDAD_MEDIDA'
       AND LEN(@cCodigo)>20
    BEGIN
        SET @cMensaje=N'El código de unidad de medida es demasiado largo.';
        RETURN 1;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM seg.UsuarioRol UR
        JOIN seg.Rol R
          ON R.rol_id=UR.rol_id
         AND R.estado=1
        JOIN seg.RolPermiso RP
          ON RP.rol_id=R.rol_id
         AND RP.estado=1
        JOIN seg.Permiso P
          ON P.permiso_id=RP.permiso_id
         AND P.estado=1
         AND P.codigo='CATALOGOS_CREAR'
        WHERE UR.usuario_id=@nUsuarioId
          AND UR.estado=1
          AND UR.fecha_desde<=SYSUTCDATETIME()
          AND
          (
              UR.fecha_hasta IS NULL
              OR UR.fecha_hasta>SYSUTCDATETIME()
          )
    )
    BEGIN
        SET @cMensaje=N'No tiene permiso para registrar catálogos.';
        SET @cCodigoRespuesta='NO_AUTORIZADO';
        SET @nHttpRespuesta=403;
        RETURN 1;
    END;

    IF @cCatalogo IN('TIPO_VEHICULO','CATEGORIA_PRODUCTO','CARGO_EMPLEADO')
    BEGIN
        SET @cCodigo=CONCAT(
            'TMP-',
            LEFT(
                REPLACE(
                    CONVERT(VARCHAR(36),NEWID()),
                    '-',
                    ''
                ),
                20
            )
        );
    END;

    IF EXISTS
    (
        SELECT 1
        FROM config.CatalogoRecursoValor
        WHERE catalogo=@cCatalogo
          AND codigo=@cCodigo
    )
    BEGIN
        SET @cMensaje=N'El código ya está registrado.';
        SET @cCodigoRespuesta='DATO_DUPLICADO';
        SET @nHttpRespuesta=409;
        RETURN 1;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT config.CatalogoRecursoValor
        (
            catalogo,
            codigo,
            nombre,
            descripcion,
            estado
        )
        VALUES
        (
            @cCatalogo,
            @cCodigo,
            @cNombre,
            @cDescripcion,
            1
        );

        SET @nCatalogoId=CONVERT(BIGINT,SCOPE_IDENTITY());

        IF @cCatalogo IN('TIPO_VEHICULO','CATEGORIA_PRODUCTO','CARGO_EMPLEADO')
        BEGIN
            SET @cCodigo=
                config.FN_CodigoCatalogo(
                    @cNombre,
                    @nCatalogoId
                );

            UPDATE config.CatalogoRecursoValor
               SET codigo=@cCodigo,
                   fecha_actualizacion=SYSUTCDATETIME()
             WHERE catalogo_recurso_valor_id=@nCatalogoId;
        END;

        COMMIT TRANSACTION;

        SELECT
            @bResultado=1,
            @cMensaje=N'Valor registrado.',
            @cCodigoRespuesta='CATALOGO_CREADO',
            @nHttpRespuesta=201;

        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0
            ROLLBACK TRANSACTION;

        SET @nCatalogoId=NULL;
        SET @cMensaje=N'No se pudo registrar el valor.';
        RETURN 1;
    END CATCH;
END;
GO
