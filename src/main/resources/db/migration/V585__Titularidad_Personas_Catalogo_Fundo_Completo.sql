-- V585: Titular principal por defecto (PROPIETARIO, 100%); catálogo limitado de titularidad y personas sin afiliación obligatoria.
-- No se modifica ningún dato histórico ni se insertan personas ficticias.
SET NOCOUNT ON;
IF OBJECT_ID(N'config.CatalogoRecursoValor', N'U') IS NULL
    THROW 51050, N'No existe el catálogo base.', 1;

-- El catálogo base admite cinco categorías. Antes de incorporar la titularidad,
-- ampliar su restricción manteniendo todas las categorías anteriores y la validación activa.
-- No usar NOCHECK: los registros históricos deben continuar cumpliendo la restricción.
IF NOT EXISTS
(
    SELECT 1
    FROM sys.check_constraints AS CC
    WHERE CC.parent_object_id = OBJECT_ID(N'config.CatalogoRecursoValor', N'U')
      AND CC.name = N'CK_CatalogoRecursoValor_Catalogo'
      AND CC.definition LIKE N'%TIPO_TITULARIDAD_PREDIO%'
      AND CC.is_disabled = 0
      AND CC.is_not_trusted = 0
)
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.check_constraints AS CC
        WHERE CC.parent_object_id = OBJECT_ID(N'config.CatalogoRecursoValor', N'U')
          AND CC.name = N'CK_CatalogoRecursoValor_Catalogo'
    )
        ALTER TABLE config.CatalogoRecursoValor
            DROP CONSTRAINT CK_CatalogoRecursoValor_Catalogo;

    ALTER TABLE config.CatalogoRecursoValor WITH CHECK
        ADD CONSTRAINT CK_CatalogoRecursoValor_Catalogo
        CHECK (catalogo IN
        (
            'TIPO_VEHICULO',
            'UNIDAD_MEDIDA',
            'CATEGORIA_PRODUCTO',
            'MONEDA',
            'CARGO_EMPLEADO',
            'TIPO_TITULARIDAD_PREDIO'
        ));
END;

INSERT config.CatalogoRecursoValor(catalogo,codigo,nombre,descripcion,estado)
SELECT V.catalogo,V.codigo,V.nombre,V.descripcion,1
FROM (VALUES
('TIPO_TITULARIDAD_PREDIO','PROPIETARIO',N'Propietario',N'Titularidad por propiedad'),
('TIPO_TITULARIDAD_PREDIO','COPROPIETARIO',N'Copropietario',N'Propiedad compartida'),
('TIPO_TITULARIDAD_PREDIO','POSESIONARIO',N'Posesionario',N'Posesión declarada'),
('TIPO_TITULARIDAD_PREDIO','ARRENDATARIO',N'Arrendatario',N'Arrendamiento'),
('TIPO_TITULARIDAD_PREDIO','OTRO',N'Otro',N'Otra relación documentada')) V(catalogo,codigo,nombre,descripcion)
WHERE NOT EXISTS(SELECT 1 FROM config.CatalogoRecursoValor C WHERE C.catalogo=V.catalogo AND C.codigo=V.codigo);
GO

-- V95 actualización compatible
CREATE OR ALTER PROCEDURE [config].[PA_CatalogoRecurso_Ins_Registro]
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


-- V96 actualización compatible
CREATE OR ALTER PROCEDURE [config].[PA_CatalogoRecurso_Sel_Listado]
    @nUsuarioId BIGINT,
    @cCatalogo VARCHAR(40),
    @nPagina INT=1,
    @nTamano INT=20,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @bResultado=0,@cMensaje=N'No se pudo consultar el catálogo.',@cCodigoRespuesta='CATALOGO_NO_LISTADO',@nHttpRespuesta=400;
    SET @cCatalogo=UPPER(NULLIF(LTRIM(RTRIM(@cCatalogo)),''));
    SET @nPagina=CASE WHEN ISNULL(@nPagina,0)<1 THEN 1 ELSE @nPagina END;
    SET @nTamano=CASE WHEN ISNULL(@nTamano,0)<1 THEN 20 WHEN @nTamano>100 THEN 100 ELSE @nTamano END;
    IF @cCatalogo NOT IN('TIPO_VEHICULO','UNIDAD_MEDIDA','CATEGORIA_PRODUCTO','MONEDA','CARGO_EMPLEADO','TIPO_TITULARIDAD_PREDIO') BEGIN SET @cMensaje=N'El catálogo seleccionado no está disponible.'; RETURN 1; END;
    IF NOT EXISTS(
        SELECT 1 FROM seg.UsuarioRol UR JOIN seg.Rol R ON R.rol_id=UR.rol_id AND R.estado=1
        JOIN seg.RolPermiso RP ON RP.rol_id=R.rol_id AND RP.estado=1
        JOIN seg.Permiso P ON P.permiso_id=RP.permiso_id AND P.estado=1 AND P.codigo='REFERENCIAS_LISTAR'
        WHERE UR.usuario_id=@nUsuarioId AND UR.estado=1 AND UR.fecha_desde<=SYSUTCDATETIME()
          AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta>SYSUTCDATETIME())
    ) BEGIN SET @cMensaje=N'No tiene permiso para consultar catálogos.'; SET @cCodigoRespuesta='NO_AUTORIZADO'; SET @nHttpRespuesta=403; RETURN 1; END;

    ;WITH C AS(
        SELECT V.*,
          CONVERT(BIGINT,
             CASE V.catalogo
              WHEN 'TIPO_VEHICULO' THEN (SELECT COUNT_BIG(*) FROM logistica.Vehiculo X WHERE UPPER(X.tipo_vehiculo)=V.codigo)
              WHEN 'UNIDAD_MEDIDA' THEN (SELECT COUNT_BIG(*) FROM logistica.Producto X WHERE UPPER(X.unidad_medida)=V.codigo)+(SELECT COUNT_BIG(*) FROM logistica.Suministro X WHERE UPPER(X.unidad_medida)=V.codigo)
              WHEN 'CATEGORIA_PRODUCTO' THEN (SELECT COUNT_BIG(*) FROM logistica.Producto X WHERE UPPER(CONVERT(VARCHAR(100),X.categoria))=V.codigo)
              WHEN 'MONEDA' THEN (SELECT COUNT_BIG(*) FROM logistica.ProductoPrecio X WHERE UPPER(X.moneda)=V.codigo)+(SELECT COUNT_BIG(*) FROM logistica.DetalleMovimientoInventario X WHERE UPPER(X.moneda)=V.codigo)+(SELECT COUNT_BIG(*) FROM logistica.BienInventario X WHERE UPPER(X.moneda_adquisicion)=V.codigo)
              WHEN 'TIPO_TITULARIDAD_PREDIO' THEN (SELECT COUNT_BIG(*) FROM prod.PredioTitularidad T WHERE T.tipo_titularidad COLLATE DATABASE_DEFAULT = V.codigo COLLATE DATABASE_DEFAULT)
              WHEN 'CARGO_EMPLEADO' THEN (SELECT COUNT_BIG(*) FROM org.EmpleadoArea X WHERE X.cargo COLLATE DATABASE_DEFAULT
                    = V.nombre COLLATE DATABASE_DEFAULT)
              ELSE 0 END) cantidadUso
        FROM config.CatalogoRecursoValor V WHERE V.catalogo=@cCatalogo
    )
    SELECT catalogo_recurso_valor_id id,codigo,nombre,descripcion,estado,cantidadUso,
           CONVERT(BIT,CASE WHEN cantidadUso>0 THEN 1 ELSE 0 END) enUso,COUNT_BIG(*) OVER() totalRegistros
    FROM C
    ORDER BY nombre,catalogo_recurso_valor_id
    OFFSET (@nPagina-1)*@nTamano ROWS FETCH NEXT @nTamano ROWS ONLY;

    SELECT @bResultado=1,@cMensaje=N'Catálogo consultado.',@cCodigoRespuesta='CATALOGO_LISTADO',@nHttpRespuesta=200;
    RETURN 0;
END;
GO


-- V97 actualización compatible
CREATE OR ALTER PROCEDURE [config].[PA_CatalogoRecurso_Upd_Deshabilitar]
    @nUsuarioId BIGINT,@cCatalogo VARCHAR(40),@nCatalogoId BIGINT,@cMotivo NVARCHAR(300),
    @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @bResultado=0,@cMensaje=N'No se pudo deshabilitar el valor.',@cCodigoRespuesta='CATALOGO_NO_DESHABILITADO',@nHttpRespuesta=400;
    SELECT @cCatalogo=UPPER(NULLIF(LTRIM(RTRIM(@cCatalogo)),'')),@cMotivo=NULLIF(LTRIM(RTRIM(@cMotivo)),N'');
    IF @cCatalogo NOT IN('TIPO_VEHICULO','UNIDAD_MEDIDA','CATEGORIA_PRODUCTO','MONEDA','TIPO_TITULARIDAD_PREDIO') OR @nCatalogoId IS NULL OR @cMotivo IS NULL BEGIN SET @cMensaje=N'Seleccione el valor e indique el motivo.'; RETURN 1; END;
    IF NOT EXISTS(
        SELECT 1 FROM seg.UsuarioRol UR JOIN seg.Rol R ON R.rol_id=UR.rol_id AND R.estado=1 JOIN seg.RolPermiso RP ON RP.rol_id=R.rol_id AND RP.estado=1 JOIN seg.Permiso P ON P.permiso_id=RP.permiso_id AND P.estado=1 AND P.codigo='CATALOGOS_RETIRAR'
        WHERE UR.usuario_id=@nUsuarioId AND UR.estado=1 AND UR.fecha_desde<=SYSUTCDATETIME() AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta>SYSUTCDATETIME())
    ) BEGIN SET @cMensaje=N'No tiene permiso para deshabilitar catálogos.'; SET @cCodigoRespuesta='NO_AUTORIZADO'; SET @nHttpRespuesta=403; RETURN 1; END;
    DECLARE @cCodigo VARCHAR(40);
    SELECT @cCodigo=codigo FROM config.CatalogoRecursoValor WHERE catalogo_recurso_valor_id=@nCatalogoId AND catalogo=@cCatalogo AND estado=1;
    IF @cCodigo IS NULL BEGIN SET @cMensaje=N'El valor seleccionado no está disponible.'; SET @cCodigoRespuesta='NO_ENCONTRADO'; SET @nHttpRespuesta=404; RETURN 1; END;
    IF @cCatalogo='TIPO_TITULARIDAD_PREDIO'
    BEGIN SET @cMensaje=N'Los tipos de titularidad son valores definidos del sistema.'; RETURN 1; END;
    UPDATE config.CatalogoRecursoValor SET estado=0,fecha_actualizacion=SYSUTCDATETIME() WHERE catalogo_recurso_valor_id=@nCatalogoId;
    SELECT @bResultado=1,@cMensaje=N'Valor deshabilitado.',@cCodigoRespuesta='CATALOGO_DESHABILITADO',@nHttpRespuesta=200; RETURN 0;
END;
GO


-- V98 actualización compatible
CREATE OR ALTER PROCEDURE [config].[PA_CatalogoRecurso_Upd_Registro]
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
           'CARGO_EMPLEADO',
           'TIPO_TITULARIDAD_PREDIO'
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


-- Catálogo para formularios
CREATE OR ALTER PROCEDURE [config].[PA_Catalogo_Sel_Listado]
(
    @cJson NVARCHAR(MAX),
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS
BEGIN
    SET @cMensaje=NULL; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;

    /* Respuesta explícita; mensajes públicos aprobados. */
    SET NOCOUNT ON;
    DECLARE @__DbTranEntrada INT = @@TRANCOUNT,
            @__DbTranAbierta BIT = 0,
            @__DbSavepoint VARCHAR(32) = REPLACE(CONVERT(VARCHAR(36),NEWID()),'-',''),
            @__DbMensaje NVARCHAR(300),
            @__DbError BIT = 0;
    SET @bResultado = 0;

    BEGIN TRY

    /* DESCO_CIERRE_FINAL_CATALOGO_USO_V1_20260829 */
    SET NOCOUNT ON;

    DECLARE
        @nPaginaListado INT,
        @nTamanoListado INT,
        @nOffsetListado BIGINT;

    EXEC [seg].[PA_Consulta_Sel_ResolverPaginacion]
         @cJson = @cJson,
         @nPagina = @nPaginaListado OUTPUT,
         @nTamanoPagina = @nTamanoListado OUTPUT,
         @nOffset = @nOffsetListado OUTPUT;

    DECLARE
        @nUsuario BIGINT,
        @nSesion BIGINT,
        @nDisp BIGINT,
        @nEmp BIGINT,
        @nModulo INT,
        @gCorr UNIQUEIDENTIFIER,
        @gSol UNIQUEIDENTIFIER,
        @cIp VARCHAR(64),
        @cEnd NVARCHAR(250),
        @bCtx BIT,
        @cMsg NVARCHAR(300);

    SELECT
        @bResultado = 0,
        @cMensaje = N'No se pudo consultar el catálogo.';

    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
         @cJson = @cJson,
         @cCodigoPermiso = 'CATALOGOS_LISTAR',
         @nUsuarioId = @nUsuario OUTPUT,
         @nSesionUsuarioId = @nSesion OUTPUT,
         @nDispositivoUsuarioId = @nDisp OUTPUT,
         @nEmpleadoId = @nEmp OUTPUT,
         @nModuloId = @nModulo OUTPUT,
         @gCorrelacionId = @gCorr OUTPUT,
         @gSolicitudId = @gSol OUTPUT,
         @cIp = @cIp OUTPUT,
         @cEndpoint = @cEnd OUTPUT,
         @bResultado = @bCtx OUTPUT,
         @cMensaje = @cMsg OUTPUT;

    IF @bCtx = 0
    BEGIN
        SET @cMensaje = @cMsg;
        GOTO __DESCO_Salida;
    END;

    DECLARE @cCat VARCHAR(40);

    SELECT
        @cCat = UPPER(NULLIF(LTRIM(RTRIM(catalogo)), ''))
    FROM OPENJSON(@cJson, '$.filtros')
    WITH
    (
        catalogo VARCHAR(40) '$.catalogo'
    );

    IF @cCat IS NULL
    BEGIN
        SET @cMensaje = N'Seleccione un catálogo.';
        GOTO __DESCO_Salida;
    END;

    IF @cCat = 'MOTIVO_SALIDA'
    BEGIN
        SELECT
            M.motivo_salida_id AS id,
            M.codigo,
            M.nombre,
            CAST(NULL AS NVARCHAR(300)) AS descripcion,
            M.estado,
            U.cantidadUso,
            CONVERT(BIT, CASE WHEN U.cantidadUso > 0 THEN 1 ELSE 0 END) AS enUso,
            COUNT_BIG(*) OVER() AS totalRegistros
        FROM [campo].[MotivoSalida] M
        CROSS APPLY
        (
            SELECT COUNT_BIG(*) AS cantidadUso
            FROM [campo].[SalidaCampo] S
            WHERE S.motivo_salida_id = M.motivo_salida_id
        ) U
        ORDER BY M.nombre, M.motivo_salida_id
        OFFSET @nOffsetListado ROWS
        FETCH NEXT @nTamanoListado ROWS ONLY;
    END
    ELSE IF @cCat = 'TIPO_EVALUACION'
    BEGIN
        SELECT
            T.tipo_evaluacion_id AS id,
            T.codigo,
            T.nombre,
            CAST(NULL AS NVARCHAR(300)) AS descripcion,
            T.estado,
            U.cantidadUso,
            CONVERT(BIT, CASE WHEN U.cantidadUso > 0 THEN 1 ELSE 0 END) AS enUso,
            COUNT_BIG(*) OVER() AS totalRegistros
        FROM [campo].[TipoEvaluacion] T
        CROSS APPLY
        (
            SELECT COUNT_BIG(*) AS cantidadUso
            FROM [campo].[EvaluacionAgronomica] E
            WHERE E.tipo_evaluacion_id = T.tipo_evaluacion_id
        ) U
        ORDER BY T.nombre, T.tipo_evaluacion_id
        OFFSET @nOffsetListado ROWS
        FETCH NEXT @nTamanoListado ROWS ONLY;
    END
    ELSE IF @cCat = 'VARIEDAD_PALTA'
    BEGIN
        SELECT
            V.variedad_palta_id AS id,
            V.codigo,
            V.nombre,
            CAST(NULL AS NVARCHAR(300)) AS descripcion,
            V.estado,
            U.cantidadUso,
            CONVERT(BIT, CASE WHEN U.cantidadUso > 0 THEN 1 ELSE 0 END) AS enUso,
            COUNT_BIG(*) OVER() AS totalRegistros
        FROM [prod].[VariedadPalta] V
        CROSS APPLY
        (
            SELECT
                (SELECT COUNT_BIG(*) FROM [prod].[ParcelaCultivo] PC WHERE PC.variedad_palta_id = V.variedad_palta_id)
                +
                (SELECT COUNT_BIG(*) FROM [comercial].[PrecioComercial] P WHERE P.variedad_palta_id = V.variedad_palta_id)
                AS cantidadUso
        ) U
        ORDER BY V.nombre, V.variedad_palta_id
        OFFSET @nOffsetListado ROWS
        FETCH NEXT @nTamanoListado ROWS ONLY;
    END
    ELSE IF @cCat = 'PROBLEMA_FITOSANITARIO'
    BEGIN
        SELECT
            T.tipo_problema_fitosanitario_id AS id,
            T.codigo,
            T.nombre,
            CONCAT(N'Categoría: ', T.categoria) AS descripcion,
            T.estado,
            U.cantidadUso,
            CONVERT(BIT, CASE WHEN U.cantidadUso > 0 THEN 1 ELSE 0 END) AS enUso,
            COUNT_BIG(*) OVER() AS totalRegistros
        FROM [sanidad].[TipoProblemaFitosanitario] T
        CROSS APPLY
        (
            SELECT COUNT_BIG(*) AS cantidadUso
            FROM [sanidad].[CasoFitosanitario] C
            WHERE C.tipo_problema_fitosanitario_id = T.tipo_problema_fitosanitario_id
        ) U
        ORDER BY T.categoria, T.nombre, T.tipo_problema_fitosanitario_id
        OFFSET @nOffsetListado ROWS
        FETCH NEXT @nTamanoListado ROWS ONLY;
    END
    ELSE IF @cCat = 'MODALIDAD_VENTA'
    BEGIN
        SELECT
            M.modalidad_venta_id AS id,
            M.codigo,
            M.nombre,
            CAST(NULL AS NVARCHAR(300)) AS descripcion,
            M.estado,
            U.cantidadUso,
            CONVERT(BIT, CASE WHEN U.cantidadUso > 0 THEN 1 ELSE 0 END) AS enUso,
            COUNT_BIG(*) OVER() AS totalRegistros
        FROM [comercial].[ModalidadVenta] M
        CROSS APPLY
        (
            SELECT COUNT_BIG(*) AS cantidadUso
            FROM [comercial].[CondicionComercial] C
            WHERE C.modalidad_venta_id = M.modalidad_venta_id
        ) U
        ORDER BY M.nombre, M.modalidad_venta_id
        OFFSET @nOffsetListado ROWS
        FETCH NEXT @nTamanoListado ROWS ONLY;
    END
    ELSE IF @cCat = 'TIPO_GASTO'
    BEGIN
        SELECT
            T.tipo_gasto_id AS id,
            T.codigo,
            T.nombre,
            CAST(NULL AS NVARCHAR(300)) AS descripcion,
            T.estado,
            U.cantidadUso,
            CONVERT(BIT, CASE WHEN U.cantidadUso > 0 THEN 1 ELSE 0 END) AS enUso,
            COUNT_BIG(*) OVER() AS totalRegistros
        FROM [finanzas].[TipoGasto] T
        CROSS APPLY
        (
            SELECT COUNT_BIG(*) AS cantidadUso
            FROM [finanzas].[GastoCampania] G
            WHERE G.tipo_gasto_id = T.tipo_gasto_id
        ) U
        ORDER BY T.nombre, T.tipo_gasto_id
        OFFSET @nOffsetListado ROWS
        FETCH NEXT @nTamanoListado ROWS ONLY;
    END
    ELSE IF @cCat = 'REGLA_PRORRATEO'
    BEGIN
        SELECT
            R.regla_prorrateo_id AS id,
            R.codigo,
            R.nombre,
            CAST(NULL AS NVARCHAR(300)) AS descripcion,
            R.estado,
            U.cantidadUso,
            CONVERT(BIT, CASE WHEN U.cantidadUso > 0 THEN 1 ELSE 0 END) AS enUso,
            COUNT_BIG(*) OVER() AS totalRegistros
        FROM [finanzas].[ReglaProrrateo] R
        CROSS APPLY
        (
            SELECT COUNT_BIG(*) AS cantidadUso
            FROM [finanzas].[GastoCampania] G
            WHERE G.regla_prorrateo_id = R.regla_prorrateo_id
        ) U
        ORDER BY R.nombre, R.regla_prorrateo_id
        OFFSET @nOffsetListado ROWS
        FETCH NEXT @nTamanoListado ROWS ONLY;
    END
    ELSE IF @cCat = 'TIPO_TITULARIDAD_PREDIO'
    BEGIN
        SELECT V.catalogo_recurso_valor_id id, V.codigo, V.nombre, V.descripcion, V.estado,
           (SELECT COUNT_BIG(*) FROM prod.PredioTitularidad T WHERE T.tipo_titularidad COLLATE DATABASE_DEFAULT=V.codigo COLLATE DATABASE_DEFAULT) cantidadUso,
           CONVERT(BIT, CASE WHEN EXISTS(SELECT 1 FROM prod.PredioTitularidad T WHERE T.tipo_titularidad COLLATE DATABASE_DEFAULT=V.codigo COLLATE DATABASE_DEFAULT) THEN 1 ELSE 0 END) enUso,
           COUNT_BIG(*) OVER() totalRegistros
        FROM config.CatalogoRecursoValor V WHERE V.catalogo='TIPO_TITULARIDAD_PREDIO' AND V.codigo IN ('PROPIETARIO','COPROPIETARIO','POSESIONARIO','ARRENDATARIO','OTRO')
        ORDER BY CASE WHEN V.codigo='PROPIETARIO' THEN 0 ELSE 1 END,V.nombre,V.catalogo_recurso_valor_id
        OFFSET @nOffsetListado ROWS FETCH NEXT @nTamanoListado ROWS ONLY;
    END
    ELSE IF @cCat = 'TIPO_BIEN'
    BEGIN
        SELECT
            T.tipo_bien_id AS id,
            T.codigo,
            T.nombre,
            CAST(NULL AS NVARCHAR(300)) AS descripcion,
            T.estado,
            U.cantidadUso,
            CONVERT(BIT, CASE WHEN U.cantidadUso > 0 THEN 1 ELSE 0 END) AS enUso,
            COUNT_BIG(*) OVER() AS totalRegistros
        FROM [logistica].[TipoBien] T
        CROSS APPLY
        (
            SELECT COUNT_BIG(*) AS cantidadUso
            FROM [logistica].[BienInventario] B
            WHERE B.tipo_bien_id = T.tipo_bien_id
        ) U
        ORDER BY T.nombre, T.tipo_bien_id
        OFFSET @nOffsetListado ROWS
        FETCH NEXT @nTamanoListado ROWS ONLY;
    END
    ELSE IF @cCat = 'ZONA_PRODUCTIVA'
    BEGIN
        SELECT
            Z.zona_productiva_id AS id,
            Z.codigo,
            Z.nombre,
            Z.descripcion,
            Z.estado,
            U.cantidadUso,
            CONVERT(BIT, CASE WHEN U.cantidadUso > 0 THEN 1 ELSE 0 END) AS enUso,
            COUNT_BIG(*) OVER() AS totalRegistros
        FROM [geo].[ZonaProductiva] Z
        CROSS APPLY
        (
            SELECT
                (SELECT COUNT_BIG(*) FROM [geo].[ZonaProductivaPredio] ZP WHERE ZP.zona_productiva_id = Z.zona_productiva_id AND ZP.estado = 1)
                +
                (SELECT COUNT_BIG(*) FROM [comercial].[OperativoZona] OZ WHERE OZ.zona_productiva_id = Z.zona_productiva_id)
                AS cantidadUso
        ) U
        ORDER BY Z.nombre, Z.zona_productiva_id
        OFFSET @nOffsetListado ROWS
        FETCH NEXT @nTamanoListado ROWS ONLY;
    END
    ELSE
    BEGIN
        SET @cMensaje = N'El catálogo seleccionado no está disponible.';
        GOTO __DESCO_Salida;
    END;

    SET @bResultado = 1;
    SET @cMensaje = N'Catálogo consultado correctamente.';

    END TRY
    BEGIN CATCH

        SET @__DbError = 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'config.PA_Catalogo_Sel_Listado',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
    END CATCH;

__DESCO_Salida:
BEGIN TRY

IF @__DbTranAbierta = 1
BEGIN
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
IF ISNULL(@bResultado,0) = 1 OR NULLIF(@cMensaje,N'') IS NULL SET @cMensaje = N'La operación no se completó y sus cambios fueron revertidos.';
SET @bResultado = 0;
END;

END TRY
BEGIN CATCH

        SET @__DbError = 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'config.PA_Catalogo_Sel_Listado',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bResultado,0) = 1
BEGIN
SET @bResultado = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'config.PA_Catalogo_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO


-- Detalle de predios: titulares con o sin asociación
CREATE OR ALTER PROCEDURE [prod].[PA_Predio_Sel_DetalleCompleto]
(
    @cJson NVARCHAR(MAX), @bResultado BIT OUTPUT, @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS
BEGIN
    SET @cMensaje=NULL; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;

    /* Respuesta explícita; mensajes públicos aprobados. */
    SET NOCOUNT ON;
    DECLARE @__DbTranEntrada INT = @@TRANCOUNT,
            @__DbTranAbierta BIT = 0,
            @__DbSavepoint VARCHAR(32) = REPLACE(CONVERT(VARCHAR(36),NEWID()),'-',''),
            @__DbMensaje NVARCHAR(300),
            @__DbError BIT = 0;
    SET @bResultado = 0;

    BEGIN TRY

    SET NOCOUNT ON;
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bOk BIT,@cMsg NVARCHAR(300),@nPredio BIGINT;
    SET @bResultado=0;
 SET @cMensaje=N'No se pudo cargar el detalle.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado] @cJson,'PREDIOS_VER',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bOk OUTPUT,@cMsg OUTPUT;
    IF @bOk=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    SELECT @nPredio=predioId FROM OPENJSON(@cJson,'$.filtros') WITH (predioId BIGINT '$.predioId');
    IF @nPredio IS NULL OR NOT EXISTS(SELECT 1 FROM [prod].[Predio] WHERE predio_id=@nPredio
      AND EXISTS (SELECT 1 FROM prod.PredioAmbito AM WHERE AM.predio_id=@nPredio AND AM.estado=1
         AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,AM.uot_id,'PREDIOS_VER')=1
         AND (AM.convenio_uot_organizacion_id IS NULL OR
              seg.FN_Usuario_TienePermisoUOT(@nUsuario,AM.uot_id,'APAPPSS_PREDIOS_VER')=1))) BEGIN SET @cMensaje=N'El predio seleccionado no está disponible.';
 GOTO __DESCO_Salida;
 END;

    /* 1. Ficha + mapa + versión vigente */
    SELECT PR.predio_id,PR.codigo,PR.nombre,PR.fecha_registro,PR.estado,U.ubicacion_id,U.distrito_codigo,U.centro_poblado_id,U.referencia,
           CASE WHEN U.posicion IS NULL THEN NULL ELSE U.posicion.Lat END latitud,
           CASE WHEN U.posicion IS NULL THEN NULL ELSE U.posicion.Long END longitud,U.altitud_m,
           PV.predio_version_id,PV.area_total_ha,PV.area_cultivable_ha,PV.tipo_riego,PV.fuente_agua,PV.infraestructura,PV.observacion,PV.fecha_desde
    FROM [prod].[Predio] PR INNER JOIN [geo].[Ubicacion] U ON U.ubicacion_id=PR.ubicacion_id
    OUTER APPLY(SELECT TOP(1) V.* FROM [prod].[PredioVersion] V WHERE V.predio_id=PR.predio_id AND V.estado=1 AND V.fecha_hasta IS NULL ORDER BY V.fecha_desde DESC) PV
    WHERE PR.predio_id=@nPredio;

    /* 2. Titularidad completa */
    SELECT PT.predio_titularidad_id,PT.persona_id AS socio_id,P.tipo_documento,P.numero_documento,P.nombres,P.apellido_paterno,P.apellido_materno,
           PT.tipo_titularidad,PT.porcentaje,PT.fecha_desde,PT.fecha_hasta,PT.estado
    FROM [prod].[PredioTitularidad] PT INNER JOIN [org].[Persona] P ON P.persona_id=PT.persona_id WHERE PT.predio_id=@nPredio ORDER BY PT.fecha_desde DESC,PT.predio_titularidad_id;

    /* 3. Historial de características */
    SELECT predio_version_id,area_total_ha,area_cultivable_ha,tipo_riego,fuente_agua,infraestructura,observacion,fecha_desde,fecha_hasta,estado
    FROM [prod].[PredioVersion] WHERE predio_id=@nPredio ORDER BY fecha_desde DESC,predio_version_id DESC;

    /* 4. Parcelas y cultivos */
    SELECT PA.parcela_id,PA.codigo parcelaCodigo,PA.nombre parcelaNombre,PA.area_ha,PA.estado parcelaEstado,PA.ubicacion_id,
           PC.parcela_cultivo_id,VP.variedad_palta_id,COALESCE(VC.nombre,VP.nombre,C.nombre) variedad,PC.fecha_inicio,PC.fecha_fin,PC.situacion_cultivo,PC.estado cultivoEstado
    FROM [prod].[Parcela] PA LEFT JOIN [prod].[ParcelaCultivo] PC ON PC.parcela_id=PA.parcela_id
    LEFT JOIN [prod].[VariedadPalta] VP ON VP.variedad_palta_id=PC.variedad_palta_id
    LEFT JOIN [prod].[VariedadCultivo] VC ON VC.variedad_cultivo_id=PC.variedad_cultivo_id
    LEFT JOIN [prod].[Cultivo] C ON C.cultivo_id=COALESCE(PC.cultivo_id,VC.cultivo_id)
    WHERE PA.predio_id=@nPredio ORDER BY PA.nombre,PC.fecha_inicio DESC;

    /* 5. Evidencias vinculadas al predio */
    SELECT A.archivo_id,A.nombre_original,A.mime_type,A.secure_url,A.fecha_carga,A.categoria,A.origen_captura
    FROM [archivo].[ArchivoVinculo] AV INNER JOIN [archivo].[Archivo] A ON A.archivo_id=AV.archivo_id WHERE AV.predio_id=@nPredio AND AV.estado=1 AND A.estado=1 ORDER BY A.fecha_carga DESC;

    SET @bResultado=1;
 SET @cMensaje=N'Detalle cargado correctamente.';

    END TRY
    BEGIN CATCH

        SET @__DbError = 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'prod.PA_Predio_Sel_DetalleCompleto',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
    END CATCH;

__DESCO_Salida:
BEGIN TRY

IF @__DbTranAbierta = 1
BEGIN
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
IF ISNULL(@bResultado,0) = 1 OR NULLIF(@cMensaje,N'') IS NULL SET @cMensaje = N'La operación no se completó y sus cambios fueron revertidos.';
SET @bResultado = 0;
END;

END TRY
BEGIN CATCH

        SET @__DbError = 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'prod.PA_Predio_Sel_DetalleCompleto',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bResultado,0) = 1
BEGIN
SET @bResultado = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'prod.PA_Predio_Sel_DetalleCompleto',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO


-- Edición de predios: personas, titularidad completa y catálogo
CREATE OR ALTER PROCEDURE [prod].[PA_Predio_Upd_Registro]
(
    @cJson NVARCHAR(MAX), @bResultado BIT OUTPUT, @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS
BEGIN
    SET @cMensaje=NULL; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;

    /* Respuesta explícita; mensajes públicos aprobados. */
    SET NOCOUNT ON;
    DECLARE @__DbTranEntrada INT = @@TRANCOUNT,
            @__DbTranAbierta BIT = 0,
            @__DbSavepoint VARCHAR(32) = REPLACE(CONVERT(VARCHAR(36),NEWID()),'-',''),
            @__DbMensaje NVARCHAR(300),
            @__DbError BIT = 0;
    SET @bResultado = 0;
    SET ANSI_NULLS ON;
    SET ANSI_PADDING ON;
    SET ANSI_WARNINGS ON;
    SET ARITHABORT ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET NUMERIC_ROUNDABORT OFF;

    BEGIN TRY

    SET NOCOUNT ON;
 SET XACT_ABORT ON;
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
            @nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),
            @nPredio BIGINT,@cCodigo VARCHAR(40),@cNombre NVARCHAR(150),@jUbi NVARCHAR(MAX),@jCar NVARCHAR(MAX),@jTit NVARCHAR(MAX),@dTit DATE,
            @cDistrito CHAR(6),@nCP BIGINT,@cRef NVARCHAR(300),@nLat DECIMAL(9,6),@nLon DECIMAL(9,6),@nAlt DECIMAL(8,2),@nUbicacionActual BIGINT,@bUbi BIT,@cMsgUbi NVARCHAR(300),
            @nArea DECIMAL(10,4),@nAreaCult DECIMAL(10,4),@cRiego VARCHAR(30),@cFuente NVARCHAR(150),@cInfra NVARCHAR(300),@cObs NVARCHAR(500),@dVig DATE,@nVersionActual BIGINT,@dVersionActual DATE,
            @dTitActual DATE,@cAnterior NVARCHAR(MAX),@cPosterior NVARCHAR(MAX),@cIdent NVARCHAR(200),@nAud BIGINT,@nTrans BIGINT;
    SET @bResultado=0;
 SET @cMensaje=N'No se pudo actualizar el predio.';
    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente] @cJson,'PREDIOS_EDITAR','PREDIO_EDITAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@nOp OUTPUT,@bRep OUTPUT,@cEstadoOp OUTPUT,@cIdRes OUTPUT,@cCodRes OUTPUT,@bIni OUTPUT,@cMsg OUTPUT;
    IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    IF @bRep=1 BEGIN IF @cEstadoOp='COMPLETADA' BEGIN SET @bResultado=1;
 SET @cMensaje=N'La solicitud ya fue procesada correctamente.';
 END ELSE SET @cMensaje=N'La solicitud ya se encuentra en proceso.';
 GOTO __DESCO_Salida;
 END;

    SELECT @nPredio=predioId,@cNombre=NULLIF(LTRIM(RTRIM(nombre)),N''),@dTit=fechaTitularidad FROM OPENJSON(@cJson,'$.predio') WITH (predioId BIGINT '$.predioId',nombre NVARCHAR(150) '$.nombre',fechaTitularidad DATE '$.fechaTitularidad');
    SET @jUbi=JSON_QUERY(@cJson,'$.ubicacion');
 SET @jCar=JSON_QUERY(@cJson,'$.caracteristicas');
 SET @jTit=JSON_QUERY(@cJson,'$.titulares');
    IF @dTit IS NULL SET @dTit=CONVERT(DATE,SYSUTCDATETIME());
    IF @nPredio IS NULL OR @cNombre IS NULL BEGIN SET @cMensaje=N'Complete los datos obligatorios del predio.';
 GOTO Fallar;
 END;
    IF NOT EXISTS(SELECT 1 FROM [prod].[Predio] WHERE predio_id=@nPredio AND estado=1) BEGIN SET @cMensaje=N'El predio seleccionado no está disponible.';
 GOTO Fallar;
 END;
    IF NOT EXISTS(SELECT 1 FROM prod.PredioAmbito AM WHERE AM.predio_id=@nPredio AND AM.estado=1
        AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,AM.uot_id,'PREDIOS_EDITAR')=1
        AND (AM.convenio_uot_organizacion_id IS NULL OR
             seg.FN_Usuario_TienePermisoUOT(@nUsuario,AM.uot_id,'APAPPSS_PREDIOS_EDITAR')=1))
    BEGIN SET @cMensaje=N'No tiene acceso al ámbito del predio.'; GOTO Fallar; END;
    SELECT @nUbicacionActual=ubicacion_id FROM [prod].[Predio] WHERE predio_id=@nPredio AND estado=1;

    IF @jUbi IS NOT NULL
    BEGIN
      SELECT @cDistrito=NULLIF(LTRIM(RTRIM(distritoCodigo)),''),@nCP=centroPobladoId,@cRef=NULLIF(LTRIM(RTRIM(referencia)),N''),@nLat=latitud,@nLon=longitud,@nAlt=altitudM FROM OPENJSON(@jUbi) WITH (distritoCodigo CHAR(6) '$.distritoCodigo',centroPobladoId BIGINT '$.centroPobladoId',referencia NVARCHAR(300) '$.referencia',latitud DECIMAL(9,6) '$.latitud',longitud DECIMAL(9,6) '$.longitud',altitudM DECIMAL(8,2) '$.altitudM');
      IF @cDistrito IS NULL BEGIN SET @cMensaje=N'Seleccione una ubicación válida.';
 GOTO Fallar;
 END;
    END;

    IF @jCar IS NOT NULL
    BEGIN
      SELECT @nArea=areaTotalHa,@nAreaCult=areaCultivableHa,@cRiego=NULLIF(LTRIM(RTRIM(tipoRiego)),''),@cFuente=NULLIF(LTRIM(RTRIM(fuenteAgua)),N''),@cInfra=NULLIF(LTRIM(RTRIM(infraestructura)),N''),@cObs=NULLIF(LTRIM(RTRIM(observacion)),N''),@dVig=fechaDesde FROM OPENJSON(@jCar) WITH (areaTotalHa DECIMAL(10,4) '$.areaTotalHa',areaCultivableHa DECIMAL(10,4) '$.areaCultivableHa',tipoRiego VARCHAR(30) '$.tipoRiego',fuenteAgua NVARCHAR(150) '$.fuenteAgua',infraestructura NVARCHAR(300) '$.infraestructura',observacion NVARCHAR(500) '$.observacion',fechaDesde DATE '$.fechaDesde');
      IF @nArea IS NULL OR @nArea<=0 OR (@nAreaCult IS NOT NULL AND (@nAreaCult<0 OR @nAreaCult>@nArea)) OR @dVig IS NULL BEGIN SET @cMensaje=N'Revise las características y su fecha de vigencia.';
 GOTO Fallar;
 END;
      SELECT TOP(1) @nVersionActual=predio_version_id,@dVersionActual=fecha_desde FROM [prod].[PredioVersion] WHERE predio_id=@nPredio AND estado=1 AND fecha_hasta IS NULL ORDER BY fecha_desde DESC;
      IF @nVersionActual IS NOT NULL AND @dVig<@dVersionActual BEGIN SET @cMensaje=N'La fecha de vigencia no puede ser anterior a la versión vigente.';
 GOTO Fallar;
 END;
      IF EXISTS(SELECT 1 FROM [prod].[Parcela] WHERE predio_id=@nPredio AND estado=1 GROUP BY predio_id HAVING SUM(area_ha)>ISNULL(@nAreaCult,@nArea)) BEGIN SET @cMensaje=N'El área indicada es menor al área ya distribuida en parcelas.';
 GOTO Fallar;
 END;
    END;

    IF @jTit IS NOT NULL
    BEGIN
      IF NOT EXISTS(SELECT 1 FROM OPENJSON(@jTit)) BEGIN SET @cMensaje=N'Agregue al menos un titular del predio.';
 GOTO Fallar;
 END;
      IF EXISTS(SELECT 1 FROM OPENJSON(@jTit) WITH (socioId BIGINT '$.socioId',tipoTitularidad VARCHAR(20) '$.tipoTitularidad',porcentaje DECIMAL(5,2) '$.porcentaje') T LEFT JOIN [org].[Persona] S ON S.persona_id=T.socioId WHERE T.socioId IS NULL OR S.persona_id IS NULL OR S.estado=0 OR T.tipoTitularidad IS NULL OR NOT EXISTS(SELECT 1 FROM config.CatalogoRecursoValor C WHERE C.catalogo='TIPO_TITULARIDAD_PREDIO' AND C.codigo=UPPER(T.tipoTitularidad) COLLATE DATABASE_DEFAULT AND C.estado=1) OR (T.porcentaje IS NULL OR T.porcentaje<=0 OR T.porcentaje>100)) BEGIN SET @cMensaje=N'Revise la información de titularidad.';
 GOTO Fallar;
 END;
      IF (SELECT SUM(ISNULL(porcentaje,0)) FROM OPENJSON(@jTit) WITH (porcentaje DECIMAL(5,2) '$.porcentaje'))<>100 BEGIN SET @cMensaje=N'La participación de titulares debe sumar 100%.';
 GOTO Fallar;
 END;
    IF EXISTS(SELECT socioId FROM OPENJSON(@jTit) WITH (socioId BIGINT '$.socioId') GROUP BY socioId HAVING COUNT(*)>1) BEGIN SET @cMensaje=N'No repita un mismo titular en el predio.';
 GOTO Fallar;
 END;
      SELECT @dTitActual=MAX(fecha_desde) FROM [prod].[PredioTitularidad] WHERE predio_id=@nPredio AND estado=1 AND fecha_hasta IS NULL;
      IF @dTitActual IS NOT NULL AND @dTit<@dTitActual BEGIN SET @cMensaje=N'La fecha de titularidad no puede ser anterior a la titularidad vigente.';
 GOTO Fallar;
 END;
    END;

    BEGIN TRY
      BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
      SELECT @cAnterior=
      (
        SELECT
            PR.predio_id,PR.codigo,PR.nombre,PR.ubicacion_id,PR.fecha_registro,PR.estado,
            JSON_QUERY
            (
                (
                    SELECT
                        U.distrito_codigo AS distritoCodigo,
                        U.centro_poblado_id AS centroPobladoId,
                        U.referencia,
                        CASE WHEN U.posicion IS NULL THEN NULL ELSE U.posicion.Lat END AS latitud,
                        CASE WHEN U.posicion IS NULL THEN NULL ELSE U.posicion.Long END AS longitud,
                        U.altitud_m AS altitudM
                    FROM [geo].[Ubicacion] U
                    WHERE U.ubicacion_id=PR.ubicacion_id
                    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER
                )
            ) AS ubicacion,
            JSON_QUERY
            (
                (
                    SELECT TOP(1) V.*
                    FROM [prod].[PredioVersion] V
                    WHERE V.predio_id=PR.predio_id
                      AND V.estado=1
                      AND V.fecha_hasta IS NULL
                    ORDER BY V.fecha_desde DESC
                    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER
                )
            ) AS caracteristicas,
            JSON_QUERY
            (
                (
                    SELECT T.persona_id,T.tipo_titularidad,T.porcentaje,T.fecha_desde
                    FROM [prod].[PredioTitularidad] T
                    WHERE T.predio_id=PR.predio_id
                      AND T.estado=1
                      AND T.fecha_hasta IS NULL
                    FOR JSON PATH
                )
            ) AS titulares
        FROM [prod].[Predio] PR
        WHERE PR.predio_id=@nPredio
        FOR JSON PATH,WITHOUT_ARRAY_WRAPPER
      );
      UPDATE [prod].[Predio] SET nombre=@cNombre WHERE predio_id=@nPredio AND estado=1;
      IF @jUbi IS NOT NULL
      BEGIN
        EXEC [geo].[PA_Ubicacion_Upd_Interna]
             @nUbicacionId=@nUbicacionActual,
             @cDistritoCodigo=@cDistrito,
             @nCentroPobladoId=@nCP,
             @cReferencia=@cRef,
             @bResultado=@bUbi OUTPUT,
             @cMensaje=@cMsgUbi OUTPUT,
             @nLatitud=@nLat,
             @nLongitud=@nLon,
             @nAltitudM=@nAlt,
             @bActualizarGeoposicion=1;
        IF @bUbi=0
        BEGIN
            BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
            SET @cMensaje=@cMsgUbi;
            GOTO Fallar;
        END;
      END;
      IF @jCar IS NOT NULL
      BEGIN
        IF @nVersionActual IS NOT NULL AND @dVig=@dVersionActual
        BEGIN
          UPDATE [prod].[PredioVersion]
          SET area_total_ha=@nArea,
              area_cultivable_ha=@nAreaCult,
              tipo_riego=@cRiego,
              fuente_agua=@cFuente,
              infraestructura=@cInfra,
              observacion=@cObs
          WHERE predio_version_id=@nVersionActual;
        END
        ELSE
        BEGIN
          IF @nVersionActual IS NOT NULL
            UPDATE [prod].[PredioVersion]
            SET fecha_hasta=DATEADD(DAY,-1,@dVig),estado=0
            WHERE predio_version_id=@nVersionActual;

          INSERT [prod].[PredioVersion](predio_id,area_total_ha,area_cultivable_ha,tipo_riego,fuente_agua,infraestructura,observacion,fecha_desde,fecha_hasta)
          VALUES(@nPredio,@nArea,@nAreaCult,@cRiego,@cFuente,@cInfra,@cObs,@dVig,NULL);
        END;
      END;
      IF @jTit IS NOT NULL
      BEGIN
        IF @dTitActual IS NOT NULL AND @dTit=@dTitActual
        BEGIN
          DELETE FROM [prod].[PredioTitularidad]
          WHERE predio_id=@nPredio
            AND estado=1
            AND fecha_hasta IS NULL
            AND fecha_desde=@dTit;
        END
        ELSE
        BEGIN
          UPDATE [prod].[PredioTitularidad]
          SET fecha_hasta=DATEADD(DAY,-1,@dTit),estado=0
          WHERE predio_id=@nPredio
            AND estado=1
            AND fecha_hasta IS NULL;
        END;

        INSERT [prod].[PredioTitularidad](predio_id,persona_id,socio_id,tipo_titularidad,porcentaje,fecha_desde,fecha_hasta)
        SELECT @nPredio,T.socioId,CASE WHEN S.socio_id IS NOT NULL AND S.estado=1 THEN S.socio_id ELSE NULL END,
          UPPER(T.tipoTitularidad),T.porcentaje,@dTit,NULL
        FROM OPENJSON(@jTit) WITH (socioId BIGINT '$.socioId',tipoTitularidad VARCHAR(20) '$.tipoTitularidad',porcentaje DECIMAL(5,2) '$.porcentaje') T
        LEFT JOIN org.Socio S ON S.socio_id=T.socioId;
      END;
      SELECT @cPosterior=
      (
        SELECT
            PR.predio_id,PR.codigo,PR.nombre,PR.ubicacion_id,PR.fecha_registro,PR.estado,
            JSON_QUERY
            (
                (
                    SELECT
                        U.distrito_codigo AS distritoCodigo,
                        U.centro_poblado_id AS centroPobladoId,
                        U.referencia,
                        CASE WHEN U.posicion IS NULL THEN NULL ELSE U.posicion.Lat END AS latitud,
                        CASE WHEN U.posicion IS NULL THEN NULL ELSE U.posicion.Long END AS longitud,
                        U.altitud_m AS altitudM
                    FROM [geo].[Ubicacion] U
                    WHERE U.ubicacion_id=PR.ubicacion_id
                    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER
                )
            ) AS ubicacion,
            JSON_QUERY
            (
                (
                    SELECT TOP(1) V.*
                    FROM [prod].[PredioVersion] V
                    WHERE V.predio_id=PR.predio_id
                      AND V.estado=1
                      AND V.fecha_hasta IS NULL
                    ORDER BY V.fecha_desde DESC
                    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER
                )
            ) AS caracteristicas,
            JSON_QUERY
            (
                (
                    SELECT T.persona_id,T.tipo_titularidad,T.porcentaje,T.fecha_desde
                    FROM [prod].[PredioTitularidad] T
                    WHERE T.predio_id=PR.predio_id
                      AND T.estado=1
                      AND T.fecha_hasta IS NULL
                    FOR JSON PATH
                )
            ) AS titulares
        FROM [prod].[Predio] PR
        WHERE PR.predio_id=@nPredio
        FOR JSON PATH,WITHOUT_ARRAY_WRAPPER
      );
      SET @cIdent=CONVERT(NVARCHAR(200),@nPredio);
      EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio] @nUsuario,@nSesion,@nDisp,@nModulo,'EDITAR','prod','Predio',@cIdent,@cAnterior,@cPosterior,NULL,NULL,NULL,NULL,@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
      /* Confirmar datos e idempotencia juntos. */
      EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOp,'COMPLETADA','prod','Predio',@cIdent,'PREDIO_ACTUALIZADO',@bFin OUTPUT,@cMsgFin OUTPUT;
IF ISNULL(@bFin,0) = 0
    THROW 51003, N'DESCO_IDEMPOTENCIA_NO_CERRADA', 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;

      SET @bResultado=1;
 SET @cMensaje=N'Predio actualizado correctamente.';
 GOTO __DESCO_Salida;
    END TRY
    BEGIN CATCH
SET @bResultado = 0;
 IF XACT_STATE()<>0 BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
 SET @cMensaje=N'No se pudo actualizar el predio. Intente nuevamente.';
 
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'prod.PA_Predio_Upd_Registro',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;
Fallar:
    IF @nOp IS NOT NULL AND @bResultado=0 EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOp,'FALLIDA',NULL,NULL,NULL,'NO_PROCESADO',@bFin OUTPUT,@cMsgFin OUTPUT;

    END TRY
    BEGIN CATCH

        SET @__DbError = 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'prod.PA_Predio_Upd_Registro',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
    END CATCH;

__DESCO_Salida:
BEGIN TRY

IF @__DbTranAbierta = 1
BEGIN
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
IF ISNULL(@bResultado,0) = 1 OR NULLIF(@cMensaje,N'') IS NULL SET @cMensaje = N'La operación no se completó y sus cambios fueron revertidos.';
SET @bResultado = 0;
END;

    IF @bResultado = 0 AND @nOp IS NOT NULL AND XACT_STATE() <> -1
    BEGIN
        IF ISNULL(@bRep,0) = 0
        BEGIN
        BEGIN TRY
            EXEC [auditoria].[PA_OperacionIdempotente_Upd_MensajeFallido]
                 @nOperacionIdempotenteId = @nOp, @cMensajeResultado = @cMensaje;
        END TRY
        BEGIN CATCH
            -- No sustituir el motivo funcional por un fallo de registro secundario.
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'prod.PA_Predio_Upd_Registro',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
        END CATCH;
        END
        ELSE
        BEGIN
            SELECT @cMensaje = COALESCE(mensaje_resultado,
                CASE WHEN estado_operacion = 'FALLIDA'
                     THEN N'La solicitud anterior no se completó. Corrija los datos y envíe una nueva solicitud.'
                     ELSE N'La solicitud todavía se está procesando. Consulte el resultado antes de repetirla.' END)
            FROM [auditoria].[OperacionIdempotente]
            WHERE operacion_idempotente_id = @nOp;
        END;
    END;

END TRY
BEGIN CATCH

        SET @__DbError = 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'prod.PA_Predio_Upd_Registro',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bResultado,0) = 1
BEGIN
SET @bResultado = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'prod.PA_Predio_Upd_Registro',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO


-- Registro tradicional: personas sin asociación
CREATE OR ALTER PROCEDURE [prod].[PA_Predio_Ins_Registro]
(
    @cJson NVARCHAR(MAX), @nPredioId BIGINT OUTPUT, @bResultado BIT OUTPUT, @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS
BEGIN
    SET @cMensaje=NULL; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;

    /* Respuesta explícita; mensajes públicos aprobados. */
    SET NOCOUNT ON;
    DECLARE @__DbTranEntrada INT = @@TRANCOUNT,
            @__DbTranAbierta BIT = 0,
            @__DbSavepoint VARCHAR(32) = REPLACE(CONVERT(VARCHAR(36),NEWID()),'-',''),
            @__DbMensaje NVARCHAR(300),
            @__DbError BIT = 0;
    SET @bResultado = 0;
    SET ANSI_NULLS ON;
    SET ANSI_PADDING ON;
    SET ANSI_WARNINGS ON;
    SET ARITHABORT ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET NUMERIC_ROUNDABORT OFF;

    BEGIN TRY

    SET NOCOUNT ON;
 SET XACT_ABORT ON;
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
            @nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),
            @cCodigo VARCHAR(40),@nCodigoConsecutivo BIGINT,@cNombre NVARCHAR(150),@dRegistro DATE,@cDistrito CHAR(6),@nCP BIGINT,@cRef NVARCHAR(300),@nLat DECIMAL(9,6),@nLon DECIMAL(9,6),@nAlt DECIMAL(8,2),@nUbicacion BIGINT,@bUbi BIT,@cMsgUbi NVARCHAR(300),
            @nArea DECIMAL(10,4),@nAreaCult DECIMAL(10,4),@cRiego VARCHAR(30),@cFuente NVARCHAR(150),@cInfra NVARCHAR(300),@cObs NVARCHAR(500),@dVig DATE,@jTit NVARCHAR(MAX),
            @cPosterior NVARCHAR(MAX),@cIdent NVARCHAR(200),@nAud BIGINT,@nTrans BIGINT;
    SELECT @nPredioId=NULL,@bResultado=0,@cMensaje=N'No se pudo registrar el predio.';
    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente] @cJson,'PREDIOS_CREAR','PREDIO_CREAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@nOp OUTPUT,@bRep OUTPUT,@cEstadoOp OUTPUT,@cIdRes OUTPUT,@cCodRes OUTPUT,@bIni OUTPUT,@cMsg OUTPUT;
    IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    IF @bRep=1 BEGIN IF @cEstadoOp='COMPLETADA' BEGIN SET @nPredioId=TRY_CONVERT(BIGINT,@cIdRes);
 SET @bResultado=1;
 SET @cMensaje=N'La solicitud ya fue procesada correctamente.';
 END ELSE SET @cMensaje=N'La solicitud ya se encuentra en proceso.';
 GOTO __DESCO_Salida;
 END;

    SELECT @cNombre=NULLIF(LTRIM(RTRIM(nombre)),N''),@dRegistro=fechaRegistro FROM OPENJSON(@cJson,'$.predio') WITH (nombre NVARCHAR(150) '$.nombre',fechaRegistro DATE '$.fechaRegistro');
    SELECT @cDistrito=NULLIF(LTRIM(RTRIM(distritoCodigo)),''),@nCP=centroPobladoId,@cRef=NULLIF(LTRIM(RTRIM(referencia)),N''),@nLat=latitud,@nLon=longitud,@nAlt=altitudM FROM OPENJSON(@cJson,'$.ubicacion') WITH (distritoCodigo CHAR(6) '$.distritoCodigo',centroPobladoId BIGINT '$.centroPobladoId',referencia NVARCHAR(300) '$.referencia',latitud DECIMAL(9,6) '$.latitud',longitud DECIMAL(9,6) '$.longitud',altitudM DECIMAL(8,2) '$.altitudM');
    SELECT @nArea=areaTotalHa,@nAreaCult=areaCultivableHa,@cRiego=NULLIF(LTRIM(RTRIM(tipoRiego)),''),@cFuente=NULLIF(LTRIM(RTRIM(fuenteAgua)),N''),@cInfra=NULLIF(LTRIM(RTRIM(infraestructura)),N''),@cObs=NULLIF(LTRIM(RTRIM(observacion)),N''),@dVig=fechaDesde FROM OPENJSON(@cJson,'$.caracteristicas') WITH (areaTotalHa DECIMAL(10,4) '$.areaTotalHa',areaCultivableHa DECIMAL(10,4) '$.areaCultivableHa',tipoRiego VARCHAR(30) '$.tipoRiego',fuenteAgua NVARCHAR(150) '$.fuenteAgua',infraestructura NVARCHAR(300) '$.infraestructura',observacion NVARCHAR(500) '$.observacion',fechaDesde DATE '$.fechaDesde');
    SET @jTit=JSON_QUERY(@cJson,'$.titulares');
 IF @dRegistro IS NULL SET @dRegistro=CONVERT(DATE,SYSUTCDATETIME());
 IF @dVig IS NULL SET @dVig=@dRegistro;
    IF @cNombre IS NULL OR @cDistrito IS NULL OR @nArea IS NULL OR @nArea<=0 BEGIN SET @cMensaje=N'Complete los datos obligatorios del predio.';
 GOTO Fallar;
 END;
    IF @nAreaCult IS NOT NULL AND (@nAreaCult<0 OR @nAreaCult>@nArea) BEGIN SET @cMensaje=N'El área cultivable no puede superar el área total.';
 GOTO Fallar;
 END;
    IF @jTit IS NULL OR NOT EXISTS(SELECT 1 FROM OPENJSON(@jTit)) BEGIN SET @cMensaje=N'Agregue al menos un titular del predio.';
 GOTO Fallar;
 END;
    IF EXISTS(SELECT 1 FROM OPENJSON(@jTit) WITH (socioId BIGINT '$.socioId',tipoTitularidad VARCHAR(20) '$.tipoTitularidad',porcentaje DECIMAL(5,2) '$.porcentaje') T LEFT JOIN [org].[Persona] S ON S.persona_id=T.socioId WHERE T.socioId IS NULL OR S.persona_id IS NULL OR S.estado=0 OR T.tipoTitularidad IS NULL OR NOT EXISTS(SELECT 1 FROM config.CatalogoRecursoValor C WHERE C.catalogo='TIPO_TITULARIDAD_PREDIO' AND C.codigo=UPPER(T.tipoTitularidad) COLLATE DATABASE_DEFAULT AND C.estado=1) OR (T.porcentaje IS NULL OR T.porcentaje<=0 OR T.porcentaje>100)) BEGIN SET @cMensaje=N'Revise la información de titularidad.';
 GOTO Fallar;
 END;
    IF (SELECT SUM(ISNULL(porcentaje,0)) FROM OPENJSON(@jTit) WITH (porcentaje DECIMAL(5,2) '$.porcentaje'))<>100 BEGIN SET @cMensaje=N'La participación de titulares debe sumar 100%.';
 GOTO Fallar;
 END;
    IF EXISTS(SELECT socioId FROM OPENJSON(@jTit) WITH (socioId BIGINT '$.socioId') GROUP BY socioId HAVING COUNT(*)>1) BEGIN SET @cMensaje=N'No repita un mismo titular en el predio.';
 GOTO Fallar;
 END;

    DECLARE @nUotCreacion BIGINT = TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId'));
    IF @nUotCreacion IS NULL
      SELECT TOP(1) @nUotCreacion=EU.uot_id
      FROM org.EmpleadoUOT EU WHERE EU.empleado_id=@nEmp AND EU.estado=1
        AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
        AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
        AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,EU.uot_id,'PREDIOS_CREAR')=1
      ORDER BY EU.es_principal DESC,EU.uot_id;
    IF @nUotCreacion IS NULL OR seg.FN_Usuario_TienePermisoUOT(@nUsuario,@nUotCreacion,'PREDIOS_CREAR')<>1
    BEGIN SET @cMensaje=N'Seleccione una unidad territorial autorizada.'; GOTO Fallar; END;

    BEGIN TRY
      BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
      EXEC [geo].[PA_Ubicacion_Ins_Interna] @cDistrito,@nCP,@cRef,@nLat,@nLon,@nAlt,@nUbicacion OUTPUT,@bUbi OUTPUT,@cMsgUbi OUTPUT;
      IF @bUbi=0 BEGIN BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
 SET @cMensaje=@cMsgUbi;
 GOTO Fallar;
 END;
      /* Código de predio generado por el sistema. */
      WHILE 1=1
      BEGIN
          SET @nCodigoConsecutivo = NEXT VALUE FOR [prod].[SQ_CodigoPredio];
          SET @cCodigo = 'PRE-' + RIGHT(REPLICATE('0',12) + CONVERT(VARCHAR(20),@nCodigoConsecutivo),12);
          IF NOT EXISTS(SELECT 1 FROM [prod].[Predio] WHERE codigo=@cCodigo) BREAK;
      END;

      INSERT [prod].[Predio](codigo,nombre,ubicacion_id,fecha_registro,uot_id) VALUES(@cCodigo,@cNombre,@nUbicacion,@dRegistro,@nUotCreacion);
 SET @nPredioId=CONVERT(BIGINT,SCOPE_IDENTITY());
      INSERT prod.PredioAmbito(predio_id,uot_id,usuario_creacion_id) VALUES(@nPredioId,@nUotCreacion,@nUsuario);
      INSERT [prod].[PredioVersion](predio_id,area_total_ha,area_cultivable_ha,tipo_riego,fuente_agua,infraestructura,observacion,fecha_desde,fecha_hasta)
      VALUES(@nPredioId,@nArea,@nAreaCult,@cRiego,@cFuente,@cInfra,@cObs,@dVig,NULL);
      INSERT [prod].[PredioTitularidad](predio_id,persona_id,socio_id,tipo_titularidad,porcentaje,fecha_desde,fecha_hasta)
      SELECT @nPredioId,T.socioId,CASE WHEN S.socio_id IS NOT NULL AND S.estado=1 THEN S.socio_id ELSE NULL END,
        UPPER(T.tipoTitularidad),T.porcentaje,@dRegistro,NULL
      FROM OPENJSON(@jTit) WITH (socioId BIGINT '$.socioId',tipoTitularidad VARCHAR(20) '$.tipoTitularidad',porcentaje DECIMAL(5,2) '$.porcentaje') T
      LEFT JOIN org.Socio S ON S.socio_id=T.socioId;
      INSERT prod.PredioIdentidad(persona_id,distrito_codigo,nombre_normalizado,predio_id)
      SELECT T.socioId,@cDistrito,UPPER(LTRIM(RTRIM(@cNombre))),@nPredioId
      FROM OPENJSON(@jTit) WITH(socioId BIGINT '$.socioId') T
      WHERE NOT EXISTS(SELECT 1 FROM prod.PredioIdentidad I WITH(UPDLOCK,HOLDLOCK)
           WHERE I.persona_id=T.socioId AND I.distrito_codigo=@cDistrito
             AND I.nombre_normalizado=UPPER(LTRIM(RTRIM(@cNombre))));
      SELECT @cPosterior=(SELECT PR.predio_id,PR.codigo,PR.nombre,PR.ubicacion_id,PR.fecha_registro,@nArea areaTotalHa,@nAreaCult areaCultivableHa,JSON_QUERY(@jTit) titulares FROM [prod].[Predio] PR WHERE PR.predio_id=@nPredioId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
      SET @cIdent=CONVERT(NVARCHAR(200),@nPredioId);
      EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio] @nUsuario,@nSesion,@nDisp,@nModulo,'CREAR','prod','Predio',@cIdent,NULL,@cPosterior,NULL,'estado',NULL,'1',@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
      /* Confirmar datos e idempotencia juntos. */
      EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOp,'COMPLETADA','prod','Predio',@cIdent,'PREDIO_CREADO',@bFin OUTPUT,@cMsgFin OUTPUT;
IF ISNULL(@bFin,0) = 0
    THROW 51003, N'DESCO_IDEMPOTENCIA_NO_CERRADA', 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;

      SET @bResultado=1;
 SET @cMensaje=N'Predio registrado correctamente.';
 GOTO __DESCO_Salida;
    END TRY
    BEGIN CATCH
SET @bResultado = 0;
 IF XACT_STATE()<>0 BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
 SET @cMensaje=N'No se pudo registrar el predio. Intente nuevamente.';
 
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'prod.PA_Predio_Ins_Registro',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;
Fallar:
    IF @nOp IS NOT NULL AND @bResultado=0 EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOp,'FALLIDA',NULL,NULL,NULL,'NO_PROCESADO',@bFin OUTPUT,@cMsgFin OUTPUT;

    END TRY
    BEGIN CATCH

        SET @__DbError = 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'prod.PA_Predio_Ins_Registro',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
    END CATCH;

__DESCO_Salida:
BEGIN TRY

IF @__DbTranAbierta = 1
BEGIN
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
IF ISNULL(@bResultado,0) = 1 OR NULLIF(@cMensaje,N'') IS NULL SET @cMensaje = N'La operación no se completó y sus cambios fueron revertidos.';
SET @bResultado = 0;
END;

    IF @bResultado = 0 AND @nOp IS NOT NULL AND XACT_STATE() <> -1
    BEGIN
        IF ISNULL(@bRep,0) = 0
        BEGIN
        BEGIN TRY
            EXEC [auditoria].[PA_OperacionIdempotente_Upd_MensajeFallido]
                 @nOperacionIdempotenteId = @nOp, @cMensajeResultado = @cMensaje;
        END TRY
        BEGIN CATCH
            -- No sustituir el motivo funcional por un fallo de registro secundario.
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'prod.PA_Predio_Ins_Registro',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
        END CATCH;
        END
        ELSE
        BEGIN
            SELECT @cMensaje = COALESCE(mensaje_resultado,
                CASE WHEN estado_operacion = 'FALLIDA'
                     THEN N'La solicitud anterior no se completó. Corrija los datos y envíe una nueva solicitud.'
                     ELSE N'La solicitud todavía se está procesando. Consulte el resultado antes de repetirla.' END)
            FROM [auditoria].[OperacionIdempotente]
            WHERE operacion_idempotente_id = @nOp;
        END;
    END;
IF @bResultado = 0
    SELECT @nPredioId = NULL;

END TRY
BEGIN CATCH

        SET @__DbError = 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'prod.PA_Predio_Ins_Registro',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bResultado,0) = 1
BEGIN
SET @bResultado = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'prod.PA_Predio_Ins_Registro',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO



-- Ficha completa del fundo en la transacción existente de expedientes
CREATE OR ALTER PROCEDURE prod.PA_E1_Predio_Ins_Registrar
 @cJson NVARCHAR(MAX),@nUot BIGINT,@nConvenio BIGINT,@nUsuario BIGINT,
 @nPredio BIGINT OUTPUT,@nEntidad BIGINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 IF @@TRANCOUNT=0 THROW 51110,N'La alta debe ejecutarse dentro de la transaccion E1.',1;
 DECLARE @nPersona BIGINT,@cNombre NVARCHAR(150),@cDistrito CHAR(6),@nCentroPoblado BIGINT,
 @cRef NVARCHAR(300),@nLat DECIMAL(9,6),@nLon DECIMAL(9,6),@nArea DECIMAL(10,4),@nAreaCult DECIMAL(10,4),@cRiego VARCHAR(30),
 @cFuente NVARCHAR(150),@cInfra NVARCHAR(300),@cObs NVARCHAR(500),@dDesde DATE,@dRegistro DATE,
 @nUbicacion BIGINT,@bUbi BIT,@cMsgUbi NVARCHAR(300),@nConsecutivo BIGINT,@cCodigo VARCHAR(40);
          SELECT @nPersona=personaId,@cNombre=nombre,@cDistrito=distritoCodigo,@nCentroPoblado=centroPobladoId,@cRef=referencia,@nLat=latitud,@nLon=longitud,@nArea=areaTotalHa,@nAreaCult=areaCultivableHa,@cRiego=tipoRiego,@cFuente=fuenteAgua,@cInfra=infraestructura,@cObs=observacion,@dDesde=fechaDesde,@dRegistro=fechaRegistro
          FROM OPENJSON(@cJson,'$.datos') WITH(personaId BIGINT,nombre NVARCHAR(150),distritoCodigo CHAR(6),centroPobladoId BIGINT,referencia NVARCHAR(300),latitud DECIMAL(9,6),longitud DECIMAL(9,6),areaTotalHa DECIMAL(10,4),areaCultivableHa DECIMAL(10,4),tipoRiego VARCHAR(30),fuenteAgua NVARCHAR(150),infraestructura NVARCHAR(300),observacion NVARCHAR(500),fechaDesde DATE,fechaRegistro DATE);
          SET @cNombre=NULLIF(LTRIM(RTRIM(@cNombre)),N'');
          IF @nPersona IS NULL OR @cNombre IS NULL OR LEN(@cNombre)<2 OR
             NOT EXISTS(SELECT 1 FROM org.Persona WHERE persona_id=@nPersona AND estado=1) OR
             NOT EXISTS(SELECT 1 FROM geo.Distrito WHERE distrito_codigo=@cDistrito AND estado=1) OR
             ((@nLat IS NULL AND @nLon IS NOT NULL) OR (@nLat IS NOT NULL AND @nLon IS NULL)) OR
             (@nLat IS NOT NULL AND (@nLat NOT BETWEEN -90 AND 90 OR @nLon NOT BETWEEN -180 AND 180)) OR
             (@nArea IS NOT NULL AND @nArea<=0) OR
             (@dRegistro IS NOT NULL AND @dRegistro>CONVERT(DATE,SYSUTCDATETIME())) OR
             (@dDesde IS NOT NULL AND @dDesde>CONVERT(DATE,SYSUTCDATETIME())) OR
             (@dDesde IS NOT NULL AND @dRegistro IS NOT NULL AND @dDesde<@dRegistro)
             THROW 51053,N'Revise titular, nombre, distrito y coordenadas.',1;
          -- Compatibilidad con alta rápida: las fechas omitidas reciben la fecha de registro.
          SET @dRegistro=COALESCE(@dRegistro,CONVERT(DATE,SYSUTCDATETIME()));
          SET @dDesde=COALESCE(@dDesde,@dRegistro);
          IF @nAreaCult IS NOT NULL AND (@nAreaCult<0 OR (@nArea IS NOT NULL AND @nAreaCult>@nArea))
             THROW 51053,N'La superficie cultivable debe estar entre cero y la superficie total.',1;
          IF @nConvenio IS NULL AND (@nArea IS NULL OR @nAreaCult IS NULL OR
             @dDesde IS NULL OR @dRegistro IS NULL OR
             NULLIF(LTRIM(RTRIM(@cRiego)), '') IS NULL OR @nLat IS NULL OR @nLon IS NULL)
             THROW 51053,N'Complete las superficies, el tipo de riego y la ubicación del fundo.',1;
          IF @nCentroPoblado IS NOT NULL AND NOT EXISTS(
             SELECT 1 FROM geo.CentroPoblado CP
             WHERE CP.centro_poblado_id=@nCentroPoblado AND CP.distrito_codigo=@cDistrito AND CP.estado=1)
             THROW 51055,N'El centro poblado no corresponde al distrito seleccionado.',1;
          IF @nConvenio IS NOT NULL AND NOT EXISTS(
             SELECT 1 FROM org.Socio S WHERE S.socio_id=@nPersona AND S.estado=1)
             THROW 51054,N'La persona no tiene un registro de socio vigente.',1;
          IF @nConvenio IS NOT NULL AND NOT EXISTS(
             SELECT 1 FROM org.SocioAsociacion SA
             JOIN org.ConvenioUOTOrganizacion C ON C.empresa_id=SA.asociacion_id AND C.convenio_uot_organizacion_id=@nConvenio
             WHERE SA.socio_id=@nPersona AND SA.estado=1 AND SA.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
               AND (SA.fecha_hasta IS NULL OR SA.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME())))
             THROW 51054,N'El titular no tiene membresía vigente para este convenio.',1;
          SELECT @nEntidad=predio_id FROM prod.PredioIdentidad WITH(UPDLOCK,HOLDLOCK)
          WHERE persona_id=@nPersona AND distrito_codigo=@cDistrito AND nombre_normalizado=UPPER(LTRIM(RTRIM(@cNombre)));
          IF @nEntidad IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.Predio WHERE predio_id=@nEntidad AND estado=1)
             THROW 51065,N'El predio está retirado; regularice su estado antes de volver a vincularlo.',1;
          IF @nEntidad IS NOT NULL AND NOT EXISTS(
              SELECT 1 FROM prod.Predio P
              WHERE P.predio_id=@nEntidad AND
                (P.uot_id=@nUot OR EXISTS(SELECT 1 FROM prod.PredioAmbito A WHERE A.predio_id=P.predio_id AND
                   seg.FN_Usuario_TienePermisoUOT(@nUsuario,A.uot_id,'PREDIOS_VER')=1)))
              THROW 51065,N'El predio identificado existe fuera del ámbito autorizado.',1;
          IF @nEntidad IS NULL
          BEGIN
            EXEC geo.PA_Ubicacion_Ins_Interna @cDistrito,@nCentroPoblado,@cRef,@nLat,@nLon,NULL,@nUbicacion OUTPUT,@bUbi OUTPUT,@cMsgUbi OUTPUT;
            IF ISNULL(@bUbi,0)=0
            BEGIN
              SET @cMsgUbi=COALESCE(NULLIF(@cMsgUbi,N''),N'No se pudo registrar la ubicación.');
              THROW 51055,@cMsgUbi,1;
            END;
            SET @nConsecutivo=NEXT VALUE FOR prod.SQ_CodigoPredio;
            SET @cCodigo='PRE-'+RIGHT(REPLICATE('0',12)+CONVERT(VARCHAR(20),@nConsecutivo),12);
            INSERT prod.Predio(codigo,nombre,ubicacion_id,fecha_registro,uot_id)
            VALUES(@cCodigo,@cNombre,@nUbicacion,COALESCE(@dRegistro,CONVERT(DATE,SYSUTCDATETIME())),@nUot);
            SET @nEntidad=SCOPE_IDENTITY();
            INSERT prod.PredioIdentidad(persona_id,distrito_codigo,nombre_normalizado,predio_id)
            VALUES(@nPersona,@cDistrito,UPPER(LTRIM(RTRIM(@cNombre))),@nEntidad);
            INSERT prod.PredioTitularidad(predio_id,persona_id,socio_id,tipo_titularidad,porcentaje,fecha_desde)
            VALUES(@nEntidad,@nPersona,CASE WHEN EXISTS(SELECT 1 FROM org.Socio WHERE socio_id=@nPersona AND estado=1) THEN @nPersona ELSE NULL END,
              'PROPIETARIO',100,COALESCE(@dRegistro,CONVERT(DATE,SYSUTCDATETIME())));
          END;
          SET @nPredio=@nEntidad;
          UPDATE prod.PredioAmbito SET estado=1 WHERE predio_id=@nEntidad AND uot_id=@nUot AND estado=0
             AND ((@nConvenio IS NULL AND convenio_uot_organizacion_id IS NULL) OR convenio_uot_organizacion_id=@nConvenio);
          IF NOT EXISTS(SELECT 1 FROM prod.PredioAmbito WITH(UPDLOCK,HOLDLOCK) WHERE predio_id=@nEntidad AND uot_id=@nUot
             AND ((@nConvenio IS NULL AND convenio_uot_organizacion_id IS NULL) OR convenio_uot_organizacion_id=@nConvenio))
             INSERT prod.PredioAmbito(predio_id,uot_id,convenio_uot_organizacion_id,usuario_creacion_id)
             VALUES(@nEntidad,@nUot,@nConvenio,@nUsuario);
          -- El alta con superficie es UNA sola transaccion: crear, vincular y registrar ficha.
          -- Nunca sobrescribir una ficha existente cuando se reutiliza un predio por identidad.
          IF @nArea IS NOT NULL AND NOT EXISTS(
             SELECT 1 FROM prod.PredioVersion WITH(UPDLOCK,HOLDLOCK)
             WHERE predio_id=@nPredio AND estado=1 AND fecha_hasta IS NULL)
          BEGIN
            DECLARE @nRevisionAlta INT;
            SELECT @nRevisionAlta=ISNULL(MAX(revision),0)+1 FROM prod.PredioVersion WITH(UPDLOCK,HOLDLOCK)
             WHERE predio_id=@nPredio AND fecha_desde=COALESCE(@dDesde,CONVERT(DATE,SYSUTCDATETIME()));
            INSERT prod.PredioVersion(predio_id,area_total_ha,area_cultivable_ha,tipo_riego,fuente_agua,infraestructura,observacion,fecha_desde,revision)
            VALUES(@nPredio,@nArea,@nAreaCult,NULLIF(LTRIM(RTRIM(@cRiego)),''),
              NULLIF(TRIM(@cFuente),N''),NULLIF(TRIM(@cInfra),N''),NULLIF(TRIM(@cObs),N''),
              COALESCE(@dDesde,CONVERT(DATE,SYSUTCDATETIME())),@nRevisionAlta);
          END;
END;
GO
