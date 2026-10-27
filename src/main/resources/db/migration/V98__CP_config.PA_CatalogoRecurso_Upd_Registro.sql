IF OBJECT_ID(N'[config].[PA_CatalogoRecurso_Upd_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [config].[PA_CatalogoRecurso_Upd_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : config.PA_CatalogoRecurso_Upd_Registro
' Descripción             : Actualiza los datos de catálogo de recursos.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Configuración
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo: sustituir identificadores y valores por datos válidos.
    DECLARE
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [config].[PA_CatalogoRecurso_Upd_Registro]
        @nUsuarioId = 0,
        @cCatalogo = '',
        @nCatalogoId = 0,
        @cNombre = N'',
        @cDescripcion = N'',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [config].[PA_CatalogoRecurso_Upd_Registro]
    @nUsuarioId BIGINT,
    @cCatalogo VARCHAR(40),
    @nCatalogoId BIGINT,
    @cNombre NVARCHAR(150),
    @cDescripcion NVARCHAR(300)=NULL,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        @bResultado=0,
        @cMensaje=N'No se pudo actualizar el valor.',
        @cCodigoRespuesta='CATALOGO_NO_ACTUALIZADO',
        @nHttpRespuesta=400;

    SELECT
        @cCatalogo=UPPER(NULLIF(LTRIM(RTRIM(@cCatalogo)),'')),
        @cNombre=NULLIF(LTRIM(RTRIM(@cNombre)),N''),
        @cDescripcion=NULLIF(LTRIM(RTRIM(@cDescripcion)),N'');

    IF @cCatalogo NOT IN
       (
           'TIPO_VEHICULO',
           'UNIDAD_MEDIDA',
           'CATEGORIA_PRODUCTO',
           'MONEDA',
           'CARGO_EMPLEADO'
       )
       OR @nCatalogoId IS NULL
       OR @cNombre IS NULL
    BEGIN
        SET @cMensaje=N'Complete correctamente los datos del catálogo.';
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
         AND P.codigo='CATALOGOS_EDITAR'
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
        SET @cMensaje=N'No tiene permiso para actualizar catálogos.';
        SET @cCodigoRespuesta='NO_AUTORIZADO';
        SET @nHttpRespuesta=403;
        RETURN 1;
    END;

    DECLARE
        @cCodigoAnterior VARCHAR(40),
        @cCodigoNuevo VARCHAR(40),
        @cNombreAnterior NVARCHAR(150);

    SELECT
        @cCodigoAnterior=codigo,
        @cNombreAnterior=nombre
    FROM config.CatalogoRecursoValor
    WHERE catalogo_recurso_valor_id=@nCatalogoId
      AND catalogo=@cCatalogo
      AND estado=1;

    IF @cCodigoAnterior IS NULL
    BEGIN
        SET @cMensaje=N'El valor seleccionado no está disponible.';
        SET @cCodigoRespuesta='NO_ENCONTRADO';
        SET @nHttpRespuesta=404;
        RETURN 1;
    END;

    SET @cCodigoNuevo=
        CASE
            WHEN @cCatalogo IN
                 (
                     'TIPO_VEHICULO',
                     'CATEGORIA_PRODUCTO',
                     'CARGO_EMPLEADO'
                 )
            THEN config.FN_CodigoCatalogo(
                     @cNombre,
                     @nCatalogoId
                 )
            ELSE @cCodigoAnterior
        END;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @cCatalogo='TIPO_VEHICULO'
           AND @cCodigoNuevo<>@cCodigoAnterior
        BEGIN
            UPDATE logistica.Vehiculo
               SET tipo_vehiculo=@cCodigoNuevo
             WHERE UPPER(tipo_vehiculo)=UPPER(@cCodigoAnterior);
        END;

        IF @cCatalogo='CATEGORIA_PRODUCTO'
           AND @cCodigoNuevo<>@cCodigoAnterior
        BEGIN
            UPDATE logistica.Producto
               SET categoria=@cCodigoNuevo
             WHERE UPPER(CONVERT(VARCHAR(100),categoria))
                   =UPPER(@cCodigoAnterior);
        END;

        IF @cCatalogo='CARGO_EMPLEADO'
           AND ISNULL(@cNombreAnterior,N'')<>ISNULL(@cNombre,N'')
        BEGIN
            UPDATE org.EmpleadoArea
               SET cargo=@cNombre
             WHERE cargo=@cNombreAnterior;
        END;

        UPDATE config.CatalogoRecursoValor
           SET codigo=@cCodigoNuevo,
               nombre=@cNombre,
               descripcion=@cDescripcion,
               fecha_actualizacion=SYSUTCDATETIME()
         WHERE catalogo_recurso_valor_id=@nCatalogoId
           AND catalogo=@cCatalogo
           AND estado=1;

        IF @@ROWCOUNT=0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @cMensaje=N'El valor seleccionado no está disponible.';
            SET @cCodigoRespuesta='NO_ENCONTRADO';
            SET @nHttpRespuesta=404;
            RETURN 1;
        END;

        COMMIT TRANSACTION;

        SELECT
            @bResultado=1,
            @cMensaje=N'Valor actualizado.',
            @cCodigoRespuesta='CATALOGO_ACTUALIZADO',
            @nHttpRespuesta=200;

        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0
            ROLLBACK TRANSACTION;

        SET @cMensaje=N'No se pudo actualizar el valor.';
        RETURN 1;
    END CATCH;
END;
GO
