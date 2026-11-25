-- Administración de proveedores por UOT; reutiliza identidades existentes.
IF OBJECT_ID(N'org.PA_ProveedorUOT_Ejecutar', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE org.PA_ProveedorUOT_Ejecutar;
END;
GO
CREATE PROCEDURE org.PA_ProveedorUOT_Ejecutar
    @cAccion VARCHAR(20),
    @nUsuarioId BIGINT,
    @nUotId BIGINT,
    @cJson NVARCHAR(MAX),
    @cDatos NVARCHAR(MAX) OUTPUT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigo VARCHAR(60) OUTPUT,
    @nHttp SMALLINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SELECT @cDatos = NULL, @bResultado = 0, @cMensaje = N'No se pudo completar la operación.',
           @cCodigo = 'PROVEEDOR_ERROR', @nHttp = 400;

    DECLARE @cPermiso VARCHAR(40) = CASE WHEN @cAccion = 'LISTAR' THEN 'ORGANIZACIONES_LISTAR'
        WHEN @cAccion = 'REGISTRAR' THEN 'ORGANIZACIONES_CREAR'
        ELSE 'ORGANIZACIONES_EDITAR' END;
    IF @cAccion NOT IN ('LISTAR', 'REGISTRAR', 'ACTUALIZAR', 'ESTADO') OR @nUsuarioId IS NULL OR @nUotId IS NULL
        OR ISJSON(@cJson) <> 1
    BEGIN
        RETURN;
    END;
    IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId, @nUotId, @cPermiso) <> 1
        OR NOT EXISTS (SELECT 1 FROM seg.UsuarioUOT UU WITH (NOLOCK)
            WHERE UU.usuario_id = @nUsuarioId AND UU.uot_id = @nUotId
              AND UU.estado = 1 AND (UU.fecha_hasta IS NULL OR UU.fecha_hasta >= CONVERT(DATE, SYSUTCDATETIME())))
    BEGIN
        SELECT @cMensaje = N'No tiene permiso en esta unidad.', @cCodigo = 'PROVEEDOR_SIN_PERMISO', @nHttp = 403;
        RETURN;
    END;

    BEGIN TRY
        IF @cAccion = 'LISTAR'
        BEGIN
            DECLARE @nPagina INT = COALESCE(TRY_CONVERT(INT, JSON_VALUE(@cJson, '$.pagina')), 1),
                    @nTamano INT = COALESCE(TRY_CONVERT(INT, JSON_VALUE(@cJson, '$.tamano')), 20),
                    @cBuscar NVARCHAR(160) = NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson, '$.buscar'))), N''),
                    @cTipo VARCHAR(10) = NULLIF(UPPER(JSON_VALUE(@cJson, '$.tipo')), ''),
                    @bSoloActivos BIT = COALESCE(TRY_CONVERT(BIT, JSON_VALUE(@cJson, '$.soloActivos')), 0);
            IF @nPagina < 1 OR @nTamano NOT BETWEEN 1 AND 100 OR @cTipo NOT IN ('PERSONA','EMPRESA')
                AND @cTipo IS NOT NULL
            BEGIN
                RETURN;
            END;
            ;WITH Registros AS
            (
                SELECT P.proveedor_uot_id id,
                       CASE WHEN P.persona_id IS NULL THEN 'EMPRESA' ELSE 'PERSONA' END tipo,
                       COALESCE(P.persona_id, P.empresa_id) entidadId,
                       CASE WHEN P.persona_id IS NULL THEN E.razon_social
                            ELSE CONCAT(R.nombres, N' ', R.apellido_paterno, N' ', COALESCE(R.apellido_materno, N'')) END nombre,
                       CASE WHEN P.persona_id IS NULL THEN 'RUC' ELSE R.tipo_documento END tipoDocumento,
                       CASE WHEN P.persona_id IS NULL THEN CONVERT(VARCHAR(30), E.ruc) ELSE R.numero_documento END documento,
                       CASE WHEN P.persona_id IS NULL THEN E.telefono ELSE R.telefono END telefono,
                       CASE WHEN P.persona_id IS NULL THEN E.correo ELSE R.correo END correo,
                       P.estado,
                       R.nombres, R.apellido_paterno apellidoPaterno, R.apellido_materno apellidoMaterno,
                       E.razon_social razonSocial, E.nombre_comercial nombreComercial,
                       R.fecha_nacimiento fechaNacimiento, R.sexo
                FROM org.ProveedorUOT P WITH (NOLOCK)
                LEFT JOIN org.Persona R WITH (NOLOCK) ON R.persona_id = P.persona_id
                LEFT JOIN org.Empresa E WITH (NOLOCK) ON E.empresa_id = P.empresa_id
                WHERE P.uot_id = @nUotId
            ), Filtrados AS
            (
                SELECT id, tipo, entidadId, nombre, tipoDocumento, documento, telefono, correo, estado,
                       nombres, apellidoPaterno, apellidoMaterno, razonSocial, nombreComercial, fechaNacimiento, sexo
                FROM Registros
                WHERE (@bSoloActivos = 0 OR estado = 1)
                  AND (@cTipo IS NULL OR tipo = @cTipo)
                  AND (@cBuscar IS NULL OR nombre LIKE N'%' + @cBuscar + N'%' OR documento LIKE N'%' + @cBuscar + N'%')
            )
            SELECT @cDatos =
                (SELECT (SELECT COUNT_BIG(1) FROM Filtrados) total,
                        JSON_QUERY((SELECT id, tipo, entidadId, LTRIM(RTRIM(nombre)) nombre,
                            tipoDocumento, documento, telefono, correo, estado,
                            nombres, apellidoPaterno, apellidoMaterno, razonSocial, nombreComercial, fechaNacimiento, sexo
                            FROM Filtrados ORDER BY nombre, id
                            OFFSET (@nPagina - 1) * @nTamano ROWS FETCH NEXT @nTamano ROWS ONLY
                            FOR JSON PATH)) items FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
            SELECT @bResultado = 1, @cMensaje = N'Proveedores consultados.',
                   @cCodigo = 'PROVEEDORES_LISTADOS', @nHttp = 200;
            RETURN;
        END;

        IF @cAccion = 'REGISTRAR'
        BEGIN
            DECLARE @cTipoEntidad VARCHAR(10) = UPPER(JSON_VALUE(@cJson, '$.tipo')),
                    @cTipoDocumento VARCHAR(15) = UPPER(JSON_VALUE(@cJson, '$.tipoDocumento')),
                    @cDocumento VARCHAR(30) = UPPER(LTRIM(RTRIM(JSON_VALUE(@cJson, '$.numeroDocumento')))),
                    @cNombre NVARCHAR(100) = NULLIF(TRIM(JSON_VALUE(@cJson, '$.nombres')), N''),
                    @cApellido NVARCHAR(80) = NULLIF(TRIM(JSON_VALUE(@cJson, '$.apellidoPaterno')), N''),
                    @cMaterno NVARCHAR(80) = NULLIF(TRIM(JSON_VALUE(@cJson, '$.apellidoMaterno')), N''),
                    @cRazon NVARCHAR(200) = NULLIF(TRIM(JSON_VALUE(@cJson, '$.razonSocial')), N''),
                    @cComercial NVARCHAR(160) = NULLIF(TRIM(JSON_VALUE(@cJson, '$.nombreComercial')), N''),
                    @cTelefono VARCHAR(30) = NULLIF(TRIM(JSON_VALUE(@cJson, '$.telefono')), ''),
                    @cCorreo VARCHAR(180) = NULLIF(LOWER(TRIM(JSON_VALUE(@cJson, '$.correo'))), ''),
                    @dNacimiento DATE = TRY_CONVERT(DATE, JSON_VALUE(@cJson, '$.fechaNacimiento')),
                    @cSexo VARCHAR(20) = NULLIF(UPPER(TRIM(JSON_VALUE(@cJson, '$.sexo'))), ''),
                    @nPersona BIGINT, @nEmpresa BIGINT, @nProveedor BIGINT;
            IF @cTipoEntidad NOT IN ('PERSONA','EMPRESA') OR @cDocumento IS NULL
                OR (@cTipoEntidad = 'EMPRESA' AND (@cTipoDocumento <> 'RUC' OR LEN(@cDocumento) <> 11 OR @cDocumento LIKE '%[^0-9]%' OR @cRazon IS NULL))
                OR (@cTipoEntidad = 'PERSONA' AND (@cTipoDocumento NOT IN ('DNI','CE','PASAPORTE')
                    OR @cNombre IS NULL OR @cApellido IS NULL
                    OR (@cTipoDocumento = 'DNI' AND (LEN(@cDocumento) <> 8 OR @cDocumento LIKE '%[^0-9]%'))))
            BEGIN
                SELECT @cMensaje = N'Complete los datos del proveedor.';
                RETURN;
            END;
            BEGIN TRANSACTION;
            IF @cTipoEntidad = 'PERSONA'
            BEGIN
                SELECT @nPersona = R.persona_id FROM org.Persona R WITH (UPDLOCK, HOLDLOCK)
                WHERE R.tipo_documento = @cTipoDocumento AND R.numero_documento = @cDocumento;
                IF @nPersona IS NULL
                BEGIN
                    INSERT org.Persona(tipo_documento,numero_documento,nombres,apellido_paterno,
                        apellido_materno,telefono,correo,fecha_nacimiento,sexo,estado)
                    VALUES (@cTipoDocumento,@cDocumento,@cNombre,@cApellido,@cMaterno,@cTelefono,@cCorreo,@dNacimiento,@cSexo,1);
                    SET @nPersona = SCOPE_IDENTITY();
                END;
            END;
            ELSE
            BEGIN
                SELECT @nEmpresa = E.empresa_id FROM org.Empresa E WITH (UPDLOCK, HOLDLOCK)
                WHERE E.ruc = @cDocumento;
                IF @nEmpresa IS NULL
                BEGIN
                    INSERT org.Empresa(ruc,razon_social,nombre_comercial,telefono,correo,estado)
                    VALUES (@cDocumento,@cRazon,@cComercial,@cTelefono,@cCorreo,1);
                    SET @nEmpresa = SCOPE_IDENTITY();
                END;
            END;
            IF NOT EXISTS (SELECT 1 FROM org.Persona R WHERE R.persona_id = @nPersona AND R.estado = 1)
                AND NOT EXISTS (SELECT 1 FROM org.Empresa E WHERE E.empresa_id = @nEmpresa AND E.estado = 1)
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT @cMensaje = N'El proveedor no está disponible.', @nHttp = 409;
                RETURN;
            END;
            SELECT @nProveedor = P.proveedor_uot_id FROM org.ProveedorUOT P WITH (UPDLOCK, HOLDLOCK)
            WHERE P.uot_id = @nUotId
              AND ((@nPersona IS NOT NULL AND P.persona_id = @nPersona)
                   OR (@nEmpresa IS NOT NULL AND P.empresa_id = @nEmpresa));
            IF @nProveedor IS NULL
            BEGIN
                INSERT org.ProveedorUOT(uot_id,persona_id,empresa_id,usuario_creacion_id)
                VALUES(@nUotId,@nPersona,@nEmpresa,@nUsuarioId);
                SET @nProveedor = SCOPE_IDENTITY();
            END;
            ELSE
            BEGIN
                UPDATE org.ProveedorUOT SET estado = 1, usuario_actualizacion_id = @nUsuarioId,
                    fecha_actualizacion = SYSUTCDATETIME() WHERE proveedor_uot_id = @nProveedor;
            END;
            COMMIT TRANSACTION;
            SELECT @cDatos = (SELECT @nProveedor id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                   @bResultado = 1, @cMensaje = N'Proveedor registrado.',
                   @cCodigo = 'PROVEEDOR_REGISTRADO', @nHttp = 201;
            RETURN;
        END;

        IF @cAccion = 'ACTUALIZAR'
        BEGIN
            DECLARE @nProveedorEditar BIGINT = TRY_CONVERT(BIGINT, JSON_VALUE(@cJson, '$.id')),
                    @cTipoEditar VARCHAR(10) = UPPER(JSON_VALUE(@cJson, '$.datos.tipo')),
                    @cDocTipoEditar VARCHAR(15) = UPPER(JSON_VALUE(@cJson, '$.datos.tipoDocumento')),
                    @cDocumentoEditar VARCHAR(30) = UPPER(NULLIF(TRIM(JSON_VALUE(@cJson, '$.datos.numeroDocumento')), '')),
                    @cNombresEditar NVARCHAR(100) = NULLIF(TRIM(JSON_VALUE(@cJson, '$.datos.nombres')), N''),
                    @cPaternoEditar NVARCHAR(80) = NULLIF(TRIM(JSON_VALUE(@cJson, '$.datos.apellidoPaterno')), N''),
                    @cMaternoEditar NVARCHAR(80) = NULLIF(TRIM(JSON_VALUE(@cJson, '$.datos.apellidoMaterno')), N''),
                    @cRazonEditar NVARCHAR(200) = NULLIF(TRIM(JSON_VALUE(@cJson, '$.datos.razonSocial')), N''),
                    @cComercialEditar NVARCHAR(160) = NULLIF(TRIM(JSON_VALUE(@cJson, '$.datos.nombreComercial')), N''),
                    @cTelefonoEditar VARCHAR(30) = NULLIF(TRIM(JSON_VALUE(@cJson, '$.datos.telefono')), ''),
                    @cCorreoEditar VARCHAR(180) = NULLIF(LOWER(TRIM(JSON_VALUE(@cJson, '$.datos.correo'))), ''),
                    @dNacimientoEditar DATE = TRY_CONVERT(DATE, JSON_VALUE(@cJson, '$.datos.fechaNacimiento')),
                    @cSexoEditar VARCHAR(20) = NULLIF(UPPER(TRIM(JSON_VALUE(@cJson, '$.datos.sexo'))), ''),
                    @nPersonaEditar BIGINT, @nEmpresaEditar BIGINT;
            IF @nProveedorEditar IS NULL OR @cDocumentoEditar IS NULL
               OR @cTipoEditar NOT IN ('PERSONA', 'EMPRESA')
               OR (@cTipoEditar = 'PERSONA' AND (@cNombresEditar IS NULL OR @cPaternoEditar IS NULL))
               OR (@cTipoEditar = 'EMPRESA' AND @cRazonEditar IS NULL)
            BEGIN
                SELECT @cMensaje = N'Complete los datos del proveedor.', @nHttp = 400;
                RETURN;
            END;
            BEGIN TRANSACTION;
            SELECT @nPersonaEditar = P.persona_id, @nEmpresaEditar = P.empresa_id
            FROM org.ProveedorUOT P WITH (UPDLOCK, HOLDLOCK)
            WHERE P.proveedor_uot_id = @nProveedorEditar AND P.uot_id = @nUotId AND P.estado = 1;
            IF (@nPersonaEditar IS NULL AND @nEmpresaEditar IS NULL)
               OR (@cTipoEditar = 'PERSONA' AND @nPersonaEditar IS NULL)
               OR (@cTipoEditar = 'EMPRESA' AND @nEmpresaEditar IS NULL)
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT @cMensaje = N'El proveedor no está disponible.', @nHttp = 404;
                RETURN;
            END;
            IF @nPersonaEditar IS NOT NULL
            BEGIN
                UPDATE org.Persona
                SET nombres = @cNombresEditar, apellido_paterno = @cPaternoEditar,
                    apellido_materno = @cMaternoEditar, telefono = @cTelefonoEditar,
                    correo = @cCorreoEditar, fecha_nacimiento = @dNacimientoEditar,
                    sexo = @cSexoEditar
                WHERE persona_id = @nPersonaEditar AND estado = 1
                  AND tipo_documento = @cDocTipoEditar AND numero_documento = @cDocumentoEditar;
            END;
            ELSE
            BEGIN
                UPDATE org.Empresa
                SET razon_social = @cRazonEditar, nombre_comercial = @cComercialEditar,
                    telefono = @cTelefonoEditar, correo = @cCorreoEditar
                WHERE empresa_id = @nEmpresaEditar AND estado = 1
                  AND ruc = @cDocumentoEditar AND @cDocTipoEditar = 'RUC';
            END;
            IF @@ROWCOUNT <> 1
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT @cMensaje = N'No se pudieron actualizar los datos.', @nHttp = 409;
                RETURN;
            END;
            UPDATE org.ProveedorUOT
            SET usuario_actualizacion_id = @nUsuarioId,
                fecha_actualizacion = SYSUTCDATETIME()
            WHERE proveedor_uot_id = @nProveedorEditar AND uot_id = @nUotId;
            COMMIT TRANSACTION;
            SELECT @cDatos = (SELECT @nProveedorEditar id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                   @bResultado = 1, @cMensaje = N'Proveedor actualizado.',
                   @cCodigo = 'PROVEEDOR_ACTUALIZADO', @nHttp = 200;
            RETURN;
        END;

        IF @cAccion = 'ESTADO'
        BEGIN
            DECLARE @nProveedorEstado BIGINT = TRY_CONVERT(BIGINT, JSON_VALUE(@cJson, '$.id')),
                    @bEstado BIT = TRY_CONVERT(BIT, JSON_VALUE(@cJson, '$.estado'));
            IF @nProveedorEstado IS NULL OR @bEstado IS NULL
            BEGIN
                RETURN;
            END;
            BEGIN TRANSACTION;
            UPDATE org.ProveedorUOT SET estado = @bEstado, usuario_actualizacion_id = @nUsuarioId,
                fecha_actualizacion = SYSUTCDATETIME()
            WHERE proveedor_uot_id = @nProveedorEstado AND uot_id = @nUotId;
            IF @@ROWCOUNT <> 1
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT @cMensaje = N'Proveedor no disponible.', @nHttp = 404;
                RETURN;
            END;
            COMMIT TRANSACTION;
            SELECT @cDatos = (SELECT @nProveedorEstado id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                   @bResultado = 1, @cMensaje = N'Estado actualizado.',
                   @cCodigo = 'PROVEEDOR_ESTADO_ACTUALIZADO', @nHttp = 200;
            RETURN;
        END;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;
        SELECT @cDatos = NULL, @bResultado = 0,
               @cMensaje = N'No se pudo guardar el proveedor.', @cCodigo = 'PROVEEDOR_NO_GUARDADO', @nHttp = 409;
    END CATCH;
END;
GO
