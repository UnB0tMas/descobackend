-- Carga de seguridad y operación base. Ejecutada solo por SaraSaraInitialBootstrap.
-- No contiene GO ni transacciones autónomas: JDBC controla una única transacción.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME() <> N'DESCO_DB'
    THROW 51000, N'La inicialización solo se admite en DESCO_DB.', 1;

DECLARE @hashInicial VARCHAR(512);
DECLARE @ahora DATETIME2(0) = SYSUTCDATETIME(), @vigente DATETIME2(0) = DATEADD(SECOND, -2, SYSUTCDATETIME());
-- Las altas de personal y sus horarios usan el calendario de Perú (UTC-5).
DECLARE @hoy DATE = CONVERT(DATE, DATEADD(HOUR, -5, @ahora)),
        @hoyUtc DATE = CONVERT(DATE, @ahora), @uot BIGINT, @empresa BIGINT, @admin BIGINT;
SELECT @uot = U.uot_id, @empresa = U.empresa_legacy_id
FROM org.UOT U WITH (UPDLOCK, HOLDLOCK)
WHERE U.codigo = 'UOT_LEGACY_4' AND U.estado = 1 AND U.es_raiz = 0;
SELECT @admin = U.usuario_id FROM seg.Usuario U WITH (UPDLOCK, HOLDLOCK)
WHERE U.nombre_usuario = 'admin' AND U.estado = 1 AND U.estado_cuenta = 'ACTIVA';
IF @uot IS NULL OR @empresa IS NULL OR @admin IS NULL
    THROW 51000, N'No se encontró la configuración base de Sara Sara y su administrador.', 1;
IF NOT EXISTS (
    SELECT 1 FROM org.ConvenioUOTOrganizacion C WITH (NOLOCK)
    JOIN org.Empresa E WITH (NOLOCK) ON E.empresa_id = C.empresa_id AND E.estado = 1
    JOIN org.ConvenioModuloEspecial CM WITH (NOLOCK) ON CM.convenio_uot_organizacion_id = C.convenio_uot_organizacion_id AND CM.estado = 1
    JOIN seg.ModuloEspecial M WITH (NOLOCK) ON M.modulo_especial_id = CM.modulo_especial_id AND M.estado = 1
    WHERE C.uot_id = @uot AND C.estado = 1 AND E.ruc = '20602771394'
      AND M.codigo = 'COMERCIALIZACION_ASOCIATIVA'
      AND (C.fecha_inicio IS NULL OR C.fecha_inicio <= @hoyUtc)
      AND (C.fecha_fin IS NULL OR C.fecha_fin >= @hoyUtc)
)
    THROW 51000, N'No existe el convenio APAPPSS activo en Sara Sara.', 1;

-- Si la base DEV anterior está disponible, conservar la clave vigente de admin sin leerla en Java.
-- Si no existe, V2 ya trae su hash original. No se modifica su rol ni sus factores de autenticación.
DECLARE @hashAnterior VARCHAR(512);
IF DB_ID(N'DESCO_DB_dev2') IS NOT NULL AND HAS_DBACCESS(N'DESCO_DB_dev2') = 1
BEGIN
    EXEC sys.sp_executesql
        N'SELECT @h = password_hash FROM DESCO_DB_dev2.seg.Usuario WHERE nombre_usuario = ''admin'' AND estado = 1 AND estado_cuenta = ''ACTIVA'';',
        N'@h VARCHAR(512) OUTPUT', @h = @hashAnterior OUTPUT;
    IF @hashAnterior COLLATE Latin1_General_100_BIN2 LIKE '$argon2id$%'
        UPDATE seg.Usuario SET password_hash = @hashAnterior
        WHERE usuario_id = @admin
          AND password_hash COLLATE Latin1_General_100_BIN2 <> @hashAnterior COLLATE Latin1_General_100_BIN2;
END;

-- Reutilizar el hash final de admin solo en la carga inicial de esta BD local.
-- Argon2 es un hash unidireccional: no se recupera ni se vuelve a codificar la clave.
SELECT @hashInicial = U.password_hash
FROM seg.Usuario U WITH (UPDLOCK, HOLDLOCK)
WHERE U.usuario_id = @admin AND U.estado = 1 AND U.estado_cuenta = 'ACTIVA';
IF @hashInicial IS NULL OR @hashInicial COLLATE Latin1_General_100_BIN2 NOT LIKE '$argon2id$%'
    THROW 51000, N'El administrador activo no tiene un hash Argon2id compatible con la autenticación.', 1;

-- Desactivar exclusivamente las cuentas de la semilla antigua que no formarán parte del nuevo escenario.
UPDATE seg.Usuario SET estado = 0, estado_cuenta = 'RETIRADA', token_version = token_version + 1
WHERE nombre_usuario IN ('coordinador', 'jennifer.gutierrez6', 'pos_sarasara_01', 'pos_sarasara_02', 'pos_sarasara_03')
  AND estado = 1;

-- Áreas operativas propias de la unidad. Se conservan las áreas de V2.
DECLARE @areas TABLE(codigo VARCHAR(30) PRIMARY KEY, nombre NVARCHAR(120));
INSERT @areas(codigo, nombre) VALUES
    ('SS-ASISTENCIA-PEC', N'Asistencia técnica pecuaria'),
    ('SS-APAPPSS', N'Asistencia a productores asociados'),
    ('SS-SANIDAD', N'Sanidad vegetal y seguimiento de campo'),
    ('SS-RECURSOS', N'Logística y recursos de campo'),
    ('SS-POS', N'Punto de venta y atención comercial'),
    ('SS-DOCUMENTOS', N'Gestión documentaria y correspondencia');
INSERT org.Area (uot_id, empresa_id, area_padre_id, codigo, nombre, estado)
SELECT @uot, @empresa, (SELECT area_id FROM org.Area WHERE uot_id = @uot AND codigo = 'SS-DIRECCION'), A.codigo, A.nombre, 1
FROM @areas A
WHERE NOT EXISTS (SELECT 1 FROM org.Area T WITH (UPDLOCK, HOLDLOCK) WHERE T.uot_id = @uot AND T.codigo = A.codigo);

DECLARE @perfiles TABLE (login VARCHAR(80) PRIMARY KEY, rol VARCHAR(80), nombreRol NVARCHAR(120), nombres NVARCHAR(100), paterno NVARCHAR(80), materno NVARCHAR(80), documento VARCHAR(30), area VARCHAR(30), cargo NVARCHAR(120), hash VARCHAR(512));
INSERT @perfiles VALUES
    ('tecnico', 'TECNICO_CAMPO_SARA', N'Técnico de campo', N'Luis Alberto', N'Quispe', N'Huamán', 'SS-TEC-001', 'SS-AGRONOMIA', N'Técnico de asistencia agraria', @hashInicial),
    ('tecnico_apappss', 'TECNICO_APAPPSS', N'Técnico APAPPSS', N'Rosa Elena', N'Vargas', N'Medina', 'SS-TEC-002', 'SS-APAPPSS', N'Técnica de productores asociados', @hashInicial),
    ('comprador', 'GESTOR_COMERCIAL_SARA', N'Gestor comercial y recursos', N'Miguel Ángel', N'Rojas', N'Cárdenas', 'SS-COM-001', 'SS-POS', N'Gestor de compras, almacén y ventas', @hashInicial);

INSERT seg.Rol(codigo, nombre, descripcion, estado, requiere_segundo_factor, es_sistema)
SELECT P.rol, P.nombreRol, N'Perfil operativo de la UOT Sara Sara.', 1, 0, 0
FROM @perfiles P
WHERE NOT EXISTS (SELECT 1 FROM seg.Rol R WITH (UPDLOCK, HOLDLOCK) WHERE R.codigo = P.rol);

DECLARE @permisos TABLE(rol VARCHAR(80), permiso VARCHAR(80), PRIMARY KEY(rol, permiso));
INSERT @permisos(rol, permiso) VALUES
('TECNICO_CAMPO_SARA', 'INICIO_LISTAR'),
    ('TECNICO_CAMPO_SARA', 'INICIO_VER'),
    ('TECNICO_CAMPO_SARA', 'REFERENCIAS_LISTAR'),
    ('TECNICO_CAMPO_SARA', 'UOT_LISTAR'),
    ('TECNICO_CAMPO_SARA', 'UOT_VER'),
    ('TECNICO_CAMPO_SARA', 'UOT_CAMBIAR_CONTEXTO'),
    ('TECNICO_CAMPO_SARA', 'CATALOGOS_LISTAR'),
    ('TECNICO_CAMPO_SARA', 'CATALOGOS_VER'),
    ('TECNICO_CAMPO_SARA', 'ARCHIVOS_LISTAR'),
    ('TECNICO_CAMPO_SARA', 'ARCHIVOS_VER'),
    ('TECNICO_CAMPO_SARA', 'ARCHIVOS_CREAR'),
    ('TECNICO_CAMPO_SARA', 'DOCS_LISTAR'),
    ('TECNICO_CAMPO_SARA', 'DOCS_VER'),
    ('TECNICO_CAMPO_SARA', 'DOCS_ENVIAR'),
    ('TECNICO_CAMPO_SARA', 'DOCS_SEGUIMIENTO'),
    ('TECNICO_CAMPO_SARA', 'DOCS_DECIDIR'),
    ('TECNICO_CAMPO_SARA', 'DOCS_INTERUOT'),
    ('TECNICO_CAMPO_SARA', 'PRODUCTORES_LISTAR'),
    ('TECNICO_CAMPO_SARA', 'PRODUCTORES_VER'),
    ('TECNICO_CAMPO_SARA', 'PRODUCTORES_CREAR'),
    ('TECNICO_CAMPO_SARA', 'PRODUCTORES_EDITAR'),
    ('TECNICO_CAMPO_SARA', 'PREDIOS_LISTAR'),
    ('TECNICO_CAMPO_SARA', 'PREDIOS_VER'),
    ('TECNICO_CAMPO_SARA', 'PREDIOS_CREAR'),
    ('TECNICO_CAMPO_SARA', 'PREDIOS_EDITAR'),
    ('TECNICO_CAMPO_SARA', 'CULTIVOS_LISTAR'),
    ('TECNICO_CAMPO_SARA', 'CULTIVOS_VER'),
    ('TECNICO_CAMPO_SARA', 'CULTIVOS_CREAR'),
    ('TECNICO_CAMPO_SARA', 'CULTIVOS_EDITAR'),
    ('TECNICO_CAMPO_SARA', 'CENSOS_LISTAR'),
    ('TECNICO_CAMPO_SARA', 'CENSOS_VER'),
    ('TECNICO_CAMPO_SARA', 'CENSOS_CREAR'),
    ('TECNICO_CAMPO_SARA', 'CENSOS_EDITAR'),
    ('TECNICO_CAMPO_SARA', 'EVALUACIONES_LISTAR'),
    ('TECNICO_CAMPO_SARA', 'EVALUACIONES_VER'),
    ('TECNICO_CAMPO_SARA', 'EVALUACIONES_CREAR'),
    ('TECNICO_CAMPO_SARA', 'EVALUACIONES_EDITAR'),
    ('TECNICO_CAMPO_SARA', 'SANIDAD_LISTAR'),
    ('TECNICO_CAMPO_SARA', 'SANIDAD_VER'),
    ('TECNICO_CAMPO_SARA', 'SANIDAD_CREAR'),
    ('TECNICO_CAMPO_SARA', 'SANIDAD_EDITAR'),
    ('TECNICO_CAMPO_SARA', 'SALIDAS_LISTAR'),
    ('TECNICO_CAMPO_SARA', 'SALIDAS_VER'),
    ('TECNICO_CAMPO_SARA', 'SALIDAS_CREAR'),
    ('TECNICO_CAMPO_SARA', 'SALIDAS_EDITAR'),
    ('TECNICO_CAMPO_SARA', 'SALIDAS_RETIRAR'),
    ('TECNICO_CAMPO_SARA', 'VISITAS_LISTAR'),
    ('TECNICO_CAMPO_SARA', 'VISITAS_VER'),
    ('TECNICO_CAMPO_SARA', 'VISITAS_CREAR'),
    ('TECNICO_CAMPO_SARA', 'VISITAS_EDITAR'),
    ('TECNICO_CAMPO_SARA', 'VISITAS_CONFIRMAR'),
    ('TECNICO_CAMPO_SARA', 'RECURSOS_LISTAR'),
    ('TECNICO_CAMPO_SARA', 'RECURSOS_VER'),
    ('TECNICO_CAMPO_SARA', 'EMPLEADOS_LISTAR'),
    ('TECNICO_CAMPO_SARA', 'EMPLEADOS_VER'),
    ('TECNICO_CAMPO_SARA', 'REPORTES_LISTAR'),
    ('TECNICO_CAMPO_SARA', 'REPORTES_VER'),
    ('TECNICO_CAMPO_SARA', 'DASHBOARD_BI_VER'),
    ('TECNICO_APAPPSS', 'INICIO_LISTAR'),
    ('TECNICO_APAPPSS', 'INICIO_VER'),
    ('TECNICO_APAPPSS', 'REFERENCIAS_LISTAR'),
    ('TECNICO_APAPPSS', 'UOT_LISTAR'),
    ('TECNICO_APAPPSS', 'UOT_VER'),
    ('TECNICO_APAPPSS', 'UOT_CAMBIAR_CONTEXTO'),
    ('TECNICO_APAPPSS', 'CATALOGOS_LISTAR'),
    ('TECNICO_APAPPSS', 'CATALOGOS_VER'),
    ('TECNICO_APAPPSS', 'ARCHIVOS_LISTAR'),
    ('TECNICO_APAPPSS', 'ARCHIVOS_VER'),
    ('TECNICO_APAPPSS', 'ARCHIVOS_CREAR'),
    ('TECNICO_APAPPSS', 'DOCS_LISTAR'),
    ('TECNICO_APAPPSS', 'DOCS_VER'),
    ('TECNICO_APAPPSS', 'DOCS_ENVIAR'),
    ('TECNICO_APAPPSS', 'DOCS_SEGUIMIENTO'),
    ('TECNICO_APAPPSS', 'DOCS_DECIDIR'),
    ('TECNICO_APAPPSS', 'DOCS_INTERUOT'),
    ('TECNICO_APAPPSS', 'APAPPSS_SOCIOS_LISTAR'),
    ('TECNICO_APAPPSS', 'APAPPSS_SOCIOS_VER'),
    ('TECNICO_APAPPSS', 'PRODUCTORES_CREAR'),
    ('TECNICO_APAPPSS', 'PRODUCTORES_EDITAR'),
    ('TECNICO_APAPPSS', 'APAPPSS_PREDIOS_LISTAR'),
    ('TECNICO_APAPPSS', 'APAPPSS_PREDIOS_VER'),
    ('TECNICO_APAPPSS', 'APAPPSS_PREDIOS_CREAR'),
    ('TECNICO_APAPPSS', 'APAPPSS_PREDIOS_EDITAR'),
    ('TECNICO_APAPPSS', 'APAPPSS_PLANTAS_CORREGIR'),
    ('TECNICO_APAPPSS', 'APAPPSS_PLANTAS_SALUD_COMENTAR'),
    ('TECNICO_APAPPSS', 'APAPPSS_PLANTAS_TRATAMIENTO_LOTE'),
    ('TECNICO_APAPPSS', 'APAPPSS_PLANTAS_SECA_REGISTRAR'),
    ('TECNICO_APAPPSS', 'APAPPSS_PREDIOS_SECA_LOTE'),
    ('TECNICO_APAPPSS', 'APAPPSS_PREDIOS_SECA_EDITAR'),
    ('TECNICO_APAPPSS', 'APAPPSS_PREDIOS_SECA_ELIMINAR'),
    ('TECNICO_APAPPSS', 'DASHBOARD_APAPPSS_VER'),
    ('TECNICO_APAPPSS', 'REPORTES_APAPPSS_VER'),
    ('TECNICO_APAPPSS', 'REPORTES_SANIDAD_DOC_VER'),
    ('TECNICO_APAPPSS', 'CAMPANIAS_LISTAR'),
    ('TECNICO_APAPPSS', 'CAMPANIAS_VER'),
    ('TECNICO_APAPPSS', 'PARTICIPANTES_LISTAR'),
    ('TECNICO_APAPPSS', 'PARTICIPANTES_VER'),
    ('GESTOR_COMERCIAL_SARA', 'INICIO_LISTAR'),
    ('GESTOR_COMERCIAL_SARA', 'INICIO_VER'),
    ('GESTOR_COMERCIAL_SARA', 'REFERENCIAS_LISTAR'),
    ('GESTOR_COMERCIAL_SARA', 'UOT_LISTAR'),
    ('GESTOR_COMERCIAL_SARA', 'UOT_VER'),
    ('GESTOR_COMERCIAL_SARA', 'UOT_CAMBIAR_CONTEXTO'),
    ('GESTOR_COMERCIAL_SARA', 'CATALOGOS_LISTAR'),
    ('GESTOR_COMERCIAL_SARA', 'CATALOGOS_VER'),
    ('GESTOR_COMERCIAL_SARA', 'ARCHIVOS_LISTAR'),
    ('GESTOR_COMERCIAL_SARA', 'ARCHIVOS_VER'),
    ('GESTOR_COMERCIAL_SARA', 'ARCHIVOS_CREAR'),
    ('GESTOR_COMERCIAL_SARA', 'DOCS_LISTAR'),
    ('GESTOR_COMERCIAL_SARA', 'DOCS_VER'),
    ('GESTOR_COMERCIAL_SARA', 'DOCS_ENVIAR'),
    ('GESTOR_COMERCIAL_SARA', 'DOCS_SEGUIMIENTO'),
    ('GESTOR_COMERCIAL_SARA', 'DOCS_DECIDIR'),
    ('GESTOR_COMERCIAL_SARA', 'DOCS_INTERUOT'),
    ('GESTOR_COMERCIAL_SARA', 'RECURSOS_LISTAR'),
    ('GESTOR_COMERCIAL_SARA', 'RECURSOS_VER'),
    ('GESTOR_COMERCIAL_SARA', 'RECURSOS_CREAR'),
    ('GESTOR_COMERCIAL_SARA', 'RECURSOS_EDITAR'),
    ('GESTOR_COMERCIAL_SARA', 'RECURSOS_CONFIRMAR'),
    ('GESTOR_COMERCIAL_SARA', 'INVENTARIO_LISTAR'),
    ('GESTOR_COMERCIAL_SARA', 'INVENTARIO_VER'),
    ('GESTOR_COMERCIAL_SARA', 'INVENTARIO_CREAR'),
    ('GESTOR_COMERCIAL_SARA', 'INVENTARIO_EDITAR'),
    ('GESTOR_COMERCIAL_SARA', 'INVENTARIO_CONFIRMAR'),
    ('GESTOR_COMERCIAL_SARA', 'ALMACENES_LISTAR'),
    ('GESTOR_COMERCIAL_SARA', 'ALMACENES_CREAR'),
    ('GESTOR_COMERCIAL_SARA', 'ALMACENES_MOVIMIENTO'),
    ('GESTOR_COMERCIAL_SARA', 'ALMACENES_KARDEX'),
    ('GESTOR_COMERCIAL_SARA', 'PRODUCTOS_LISTAR'),
    ('GESTOR_COMERCIAL_SARA', 'PRODUCTOS_VER'),
    ('GESTOR_COMERCIAL_SARA', 'PRODUCTOS_CREAR'),
    ('GESTOR_COMERCIAL_SARA', 'PRODUCTOS_EDITAR'),
    ('GESTOR_COMERCIAL_SARA', 'PRODUCTOS_PRECIO'),
    ('GESTOR_COMERCIAL_SARA', 'PRODUCTOS_IMAGENES'),
    ('GESTOR_COMERCIAL_SARA', 'PRODUCTOS_PRECIO_HISTORIAL'),
    ('GESTOR_COMERCIAL_SARA', 'POS_OPERAR'),
    ('GESTOR_COMERCIAL_SARA', 'CAJAS_LISTAR'),
    ('GESTOR_COMERCIAL_SARA', 'CAJAS_ABRIR'),
    ('GESTOR_COMERCIAL_SARA', 'CAJAS_CERRAR'),
    ('GESTOR_COMERCIAL_SARA', 'CAJAS_MOVIMIENTOS'),
    ('GESTOR_COMERCIAL_SARA', 'VENTAS_LISTAR'),
    ('GESTOR_COMERCIAL_SARA', 'VENTAS_CREAR'),
    ('GESTOR_COMERCIAL_SARA', 'VENTAS_PAGAR'),
    ('GESTOR_COMERCIAL_SARA', 'VENTAS_ENTREGAR'),
    ('GESTOR_COMERCIAL_SARA', 'VENTAS_COMPROBANTE'),
    ('GESTOR_COMERCIAL_SARA', 'VENTAS_ENTREGA_TECNICA'),
    ('GESTOR_COMERCIAL_SARA', 'VENTAS_HISTORIAL'),
    ('GESTOR_COMERCIAL_SARA', 'VENTAS_REPORTES'),
    ('GESTOR_COMERCIAL_SARA', 'VENTAS_EDITAR'),
    ('GESTOR_COMERCIAL_SARA', 'COMPROBANTES_VER'),
    ('GESTOR_COMERCIAL_SARA', 'PERSONAL_COMERCIAL_PROPIO'),
    ('GESTOR_COMERCIAL_SARA', 'ORGANIZACIONES_LISTAR'),
    ('GESTOR_COMERCIAL_SARA', 'ORGANIZACIONES_VER'),
    ('GESTOR_COMERCIAL_SARA', 'SALIDAS_LISTAR'),
    ('GESTOR_COMERCIAL_SARA', 'SALIDAS_VER');
DECLARE @faltantes NVARCHAR(MAX), @diagnostico NVARCHAR(2048);
SELECT @faltantes = STRING_AGG(CONVERT(NVARCHAR(MAX), X.permiso), N', ')
FROM (SELECT DISTINCT permiso FROM @permisos) X
WHERE NOT EXISTS (SELECT 1 FROM seg.Permiso P WHERE P.codigo = X.permiso AND P.estado = 1);
IF @faltantes IS NOT NULL
BEGIN
    SET @diagnostico = LEFT(CONCAT(N'Faltan permisos activos: ', @faltantes), 2048);
    THROW 51000, @diagnostico, 1;
END;
INSERT seg.RolPermiso(rol_id, permiso_id, estado, fecha_asignacion, asignado_por_usuario_id)
SELECT R.rol_id, P.permiso_id, 1, @vigente, @admin
FROM @permisos X JOIN seg.Rol R ON R.codigo = X.rol
JOIN seg.Permiso P ON P.codigo = X.permiso AND P.estado = 1
WHERE NOT EXISTS (SELECT 1 FROM seg.RolPermiso RP WITH (UPDLOCK, HOLDLOCK) WHERE RP.rol_id = R.rol_id AND RP.permiso_id = P.permiso_id);

-- Replicar solo el diseño de indicadores, no los permisos de roles previos.
INSERT config.DashboardRolElemento(rol_id, dashboard_elemento_id, visible, orden)
SELECT R.rol_id, D.dashboard_elemento_id, D.visible, D.orden
FROM (VALUES ('TECNICO_CAMPO_SARA','TECNICO_CAMPO'), ('GESTOR_COMERCIAL_SARA','OPERADOR_POS')) X(nuevo, anterior)
JOIN seg.Rol R ON R.codigo = X.nuevo
JOIN seg.Rol B ON B.codigo = X.anterior
JOIN config.DashboardRolElemento D ON D.rol_id = B.rol_id
WHERE NOT EXISTS (SELECT 1 FROM config.DashboardRolElemento N WITH (UPDLOCK, HOLDLOCK) WHERE N.rol_id = R.rol_id AND N.dashboard_elemento_id = D.dashboard_elemento_id);

DECLARE @login VARCHAR(80), @rol VARCHAR(80), @nombre NVARCHAR(100), @paterno NVARCHAR(80), @materno NVARCHAR(80), @doc VARCHAR(30), @areaCodigo VARCHAR(30), @cargo NVARCHAR(120), @hash VARCHAR(512);
DECLARE @persona BIGINT, @usuario BIGINT, @area BIGINT, @rolId BIGINT, @usuarioUot BIGINT, @correo NVARCHAR(320);
DECLARE cuentas CURSOR LOCAL FAST_FORWARD FOR
    SELECT login, rol, nombres, paterno, materno, documento, area, cargo, hash FROM @perfiles ORDER BY login;
OPEN cuentas;
FETCH NEXT FROM cuentas INTO @login, @rol, @nombre, @paterno, @materno, @doc, @areaCodigo, @cargo, @hash;
WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @persona = NULL, @usuario = NULL, @area = NULL, @rolId = NULL, @usuarioUot = NULL;
    SET @correo = CONCAT(@login, '@sarasara.invalid');
    SELECT @area = area_id FROM org.Area WHERE uot_id = @uot AND codigo = @areaCodigo AND estado = 1;
    SELECT @rolId = rol_id FROM seg.Rol WHERE codigo = @rol AND estado = 1;
    SELECT @usuario = usuario_id, @persona = persona_id FROM seg.Usuario WITH (UPDLOCK, HOLDLOCK) WHERE nombre_usuario = @login;
    IF @area IS NULL OR @rolId IS NULL
        THROW 51000, N'No se encontró el área o rol de una cuenta operativa.', 1;
    IF @usuario IS NOT NULL AND @login <> 'tecnico'
        THROW 51000, N'Existe una cuenta operativa no prevista; se cancela la carga.', 1;
    IF @usuario IS NOT NULL AND NOT EXISTS (SELECT 1 FROM org.Persona WHERE persona_id = @persona AND numero_documento = 'DEV-TECNICO-2026' AND tipo_documento = 'OTRO')
        THROW 51000, N'La identidad de la cuenta técnica anterior no coincide.', 1;
    IF @persona IS NULL
    BEGIN
        INSERT org.Persona(tipo_documento, numero_documento, nombres, apellido_paterno, apellido_materno, correo, tipo_persona, estado)
        VALUES ('OTRO', @doc, @nombre, @paterno, @materno, @correo, 'NATURAL', 1);
        SET @persona = CONVERT(BIGINT, SCOPE_IDENTITY());
    END
    ELSE
    BEGIN
        UPDATE org.Persona SET nombres = @nombre, apellido_paterno = @paterno, apellido_materno = @materno,
            telefono = NULL, correo = @correo, estado = 1
        WHERE persona_id = @persona;
    END;
    IF NOT EXISTS (SELECT 1 FROM org.Empleado WHERE empleado_id = @persona)
        INSERT org.Empleado(empleado_id, empresa_id, codigo_empleado, fecha_ingreso, estado)
        VALUES (@persona, @empresa, @doc, @hoy, 1);
    ELSE
        UPDATE org.Empleado SET empresa_id = @empresa, estado = 1, fecha_cese = NULL WHERE empleado_id = @persona;

    UPDATE org.EmpleadoArea SET estado = 0, fecha_hasta = CASE WHEN fecha_desde > @hoy THEN fecha_desde ELSE @hoy END
    WHERE empleado_id = @persona AND estado = 1 AND fecha_hasta IS NULL AND area_id <> @area;
    IF NOT EXISTS (SELECT 1 FROM org.EmpleadoArea WHERE empleado_id = @persona AND area_id = @area AND estado = 1 AND fecha_hasta IS NULL)
        INSERT org.EmpleadoArea(empleado_id, area_id, cargo, fecha_desde, estado)
        VALUES (@persona, @area, @cargo, @hoy, 1);
    UPDATE org.EmpleadoUOT SET estado = 0, es_principal = 0, fecha_hasta = CASE WHEN fecha_desde > @hoy THEN fecha_desde ELSE @hoy END
    WHERE empleado_id = @persona AND estado = 1 AND fecha_hasta IS NULL AND uot_id <> @uot;
    IF NOT EXISTS (SELECT 1 FROM org.EmpleadoUOT WHERE empleado_id = @persona AND uot_id = @uot AND estado = 1 AND fecha_hasta IS NULL)
        INSERT org.EmpleadoUOT(empleado_id, uot_id, es_principal, fecha_desde, estado, codigo_empleado, fecha_ingreso)
        VALUES (@persona, @uot, 1, @hoy, 1, @doc, @hoy);
    ELSE
        UPDATE org.EmpleadoUOT SET es_principal = 1, fecha_cese = NULL
        WHERE empleado_id = @persona AND uot_id = @uot AND estado = 1 AND fecha_hasta IS NULL;

    IF @usuario IS NULL
    BEGIN
        INSERT seg.Usuario(persona_id, nombre_usuario, password_hash, estado, estado_cuenta,
            requiere_cambio_password, segundo_factor_habilitado, omitir_segundo_factor_pruebas, fecha_cambio_password)
        VALUES (@persona, @login, @hash, 1, 'ACTIVA', 0, 0, 1, @ahora);
        SET @usuario = CONVERT(BIGINT, SCOPE_IDENTITY());
    END
    ELSE
    BEGIN
        UPDATE seg.Usuario SET password_hash = @hash, estado = 1, estado_cuenta = 'ACTIVA',
            requiere_cambio_password = 0, segundo_factor_habilitado = 0, omitir_segundo_factor_pruebas = 1,
            intentos_fallidos = 0, fecha_ultimo_intento_fallido = NULL, bloqueado_hasta = NULL,
            fecha_cambio_password = @ahora, token_version = token_version + 1
        WHERE usuario_id = @usuario;
    END;
    -- Cerrar accesos históricos del técnico, sin tocar otros usuarios ni su historial.
    UPDATE UR SET estado = 0, fecha_hasta = CASE WHEN UR.fecha_desde >= @ahora THEN DATEADD(SECOND, 1, UR.fecha_desde) ELSE @ahora END
    FROM seg.UsuarioRol UR WHERE UR.usuario_id = @usuario AND UR.estado = 1 AND UR.fecha_hasta IS NULL AND UR.rol_id <> @rolId;
    UPDATE UR SET estado = 0, fecha_hasta = CASE WHEN UR.fecha_desde >= @ahora THEN DATEADD(SECOND, 1, UR.fecha_desde) ELSE @ahora END
    FROM seg.UsuarioUOTRol UR JOIN seg.UsuarioUOT UU ON UU.usuario_uot_id = UR.usuario_uot_id
    WHERE UU.usuario_id = @usuario AND UR.estado = 1 AND UR.fecha_hasta IS NULL AND (UU.uot_id <> @uot OR UR.rol_id <> @rolId);
    UPDATE UP SET estado = 0, fecha_hasta = CASE WHEN UP.fecha_desde >= @ahora THEN DATEADD(SECOND, 1, UP.fecha_desde) ELSE @ahora END
    FROM seg.UsuarioUOTPermiso UP JOIN seg.UsuarioUOT UU ON UU.usuario_uot_id = UP.usuario_uot_id
    WHERE UU.usuario_id = @usuario AND UP.estado = 1 AND UP.fecha_hasta IS NULL;
    UPDATE seg.UsuarioUOT SET estado = 0, es_predeterminada = 0,
        fecha_hasta = CASE WHEN fecha_desde >= @ahora THEN DATEADD(SECOND, 1, fecha_desde) ELSE @ahora END
    WHERE usuario_id = @usuario AND estado = 1 AND fecha_hasta IS NULL AND uot_id <> @uot;
    IF NOT EXISTS (SELECT 1 FROM seg.UsuarioUOT WHERE usuario_id = @usuario AND uot_id = @uot AND estado = 1 AND fecha_hasta IS NULL)
        INSERT seg.UsuarioUOT(usuario_id, uot_id, es_predeterminada, fecha_desde, estado, asignado_por_usuario_id)
        VALUES (@usuario, @uot, 1, @vigente, 1, @admin);
    ELSE
        UPDATE seg.UsuarioUOT SET es_predeterminada = 1, fecha_desde = CASE WHEN fecha_desde > @vigente THEN @vigente ELSE fecha_desde END
        WHERE usuario_id = @usuario AND uot_id = @uot AND estado = 1 AND fecha_hasta IS NULL;
    SELECT @usuarioUot = usuario_uot_id FROM seg.UsuarioUOT WHERE usuario_id = @usuario AND uot_id = @uot AND estado = 1 AND fecha_hasta IS NULL;
    IF NOT EXISTS (SELECT 1 FROM seg.UsuarioRol WHERE usuario_id = @usuario AND rol_id = @rolId AND estado = 1 AND fecha_hasta IS NULL)
        INSERT seg.UsuarioRol(usuario_id, rol_id, fecha_desde, estado, asignado_por_usuario_id)
        VALUES (@usuario, @rolId, @vigente, 1, @admin);
    IF NOT EXISTS (SELECT 1 FROM seg.UsuarioUOTRol WHERE usuario_uot_id = @usuarioUot AND rol_id = @rolId AND estado = 1 AND fecha_hasta IS NULL)
        INSERT seg.UsuarioUOTRol(usuario_uot_id, rol_id, fecha_desde, estado, asignado_por_usuario_id)
        VALUES (@usuarioUot, @rolId, @vigente, 1, @admin);

    -- Los permisos especiales requieren concesión territorial explícita; el rol por sí solo no basta.
    INSERT seg.UsuarioUOTPermiso(usuario_uot_id, permiso_id, permitido, motivo, fecha_desde, estado, asignado_por_usuario_id)
    SELECT @usuarioUot, P.permiso_id, 1, N'Acceso operativo inicial en Sara Sara', @vigente, 1, @admin
    FROM @permisos X JOIN seg.Permiso P ON P.codigo = X.permiso AND P.estado = 1
    WHERE X.rol = @rol AND EXISTS (SELECT 1 FROM seg.ModuloEspecialPermiso MP WITH (NOLOCK) WHERE MP.permiso_id = P.permiso_id)
      AND NOT EXISTS (SELECT 1 FROM seg.UsuarioUOTPermiso UP WITH (UPDLOCK, HOLDLOCK) WHERE UP.usuario_uot_id = @usuarioUot AND UP.permiso_id = P.permiso_id AND UP.estado = 1 AND UP.fecha_hasta IS NULL);

    UPDATE seg.UsuarioCorreoSeguridad SET estado = 0, fecha_hasta = CASE WHEN fecha_desde >= @ahora THEN DATEADD(SECOND, 1, fecha_desde) ELSE @ahora END
    WHERE usuario_id = @usuario AND estado = 1 AND fecha_hasta IS NULL AND correo_normalizado <> @correo;
    IF NOT EXISTS (SELECT 1 FROM seg.UsuarioCorreoSeguridad WHERE usuario_id = @usuario AND correo_normalizado = @correo AND estado = 1 AND fecha_hasta IS NULL)
        INSERT seg.UsuarioCorreoSeguridad(usuario_id, correo, correo_normalizado, es_principal, es_verificado, fecha_verificacion, fecha_desde, estado, creado_por_usuario_id)
        VALUES (@usuario, @correo, @correo, 1, 1, @vigente, @vigente, 1, @admin);

    IF @login = 'comprador'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM comercial.AccesoEmpleadoPOS WHERE uot_id = @uot AND empleado_id = @persona)
            INSERT comercial.AccesoEmpleadoPOS(uot_id, empleado_id, habilitado, motivo, usuario_actualizacion_id)
            VALUES (@uot, @persona, 1, N'Acceso comercial inicial', @admin);
        -- Toda la jornada de atención, los siete días. Sin permiso POS_SIN_HORARIO.
        IF NOT EXISTS (SELECT 1 FROM comercial.HorarioAtencionUOT WHERE uot_id = @uot)
            INSERT comercial.HorarioAtencionUOT(uot_id, hora_inicio, hora_fin, usuario_actualizacion_id)
            VALUES (@uot, '00:00:00', '23:59:59', @admin);
        ELSE
            UPDATE comercial.HorarioAtencionUOT SET hora_inicio = '00:00:00', hora_fin = '23:59:59', usuario_actualizacion_id = @admin
            WHERE uot_id = @uot;
        -- Las excepciones diarias de atención no deben contradecir la jornada inicial.
        UPDATE comercial.HorarioAtencionDiaPOS
        SET hora_inicio = '00:00:00', hora_fin = '23:59:59',
            usuario_actualizacion_id = @admin, fecha_actualizacion = @ahora
        WHERE uot_id = @uot;
        INSERT comercial.HorarioEmpleadoPOS(uot_id, empleado_id, dia_semana, hora_inicio, hora_fin, usuario_registro_id)
        SELECT @uot, @persona, D.dia, '00:00:00', '23:59:59', @admin
        FROM (VALUES (1),(2),(3),(4),(5),(6),(7)) D(dia)
        WHERE NOT EXISTS (SELECT 1 FROM comercial.HorarioEmpleadoPOS H WHERE H.uot_id = @uot AND H.empleado_id = @persona AND H.dia_semana = D.dia);
        IF NOT EXISTS (SELECT 1 FROM comercial.CajaPOS WHERE uot_id = @uot AND codigo = 'SS-CAJA-01')
            INSERT comercial.CajaPOS(uot_id, codigo, nombre, usuario_creacion_id, estado)
            VALUES (@uot, 'SS-CAJA-01', N'Caja principal - Pauza', @admin, 1);
    END;

    SELECT @faltantes = STRING_AGG(CONVERT(NVARCHAR(MAX), X.permiso), N', ')
    FROM @permisos X WHERE X.rol = @rol AND ISNULL(seg.FN_Usuario_TienePermisoUOT(@usuario, @uot, X.permiso), 0) <> 1;
    IF @faltantes IS NOT NULL
    BEGIN
        SET @diagnostico = LEFT(CONCAT(N'Permisos no efectivos para ', @login, N': ', @faltantes), 2048);
        THROW 51000, @diagnostico, 1;
    END;
    IF ISNULL(seg.FN_Usuario_TienePermisoUOT(@usuario, @uot, 'SALIDAS_ADMINISTRAR'), 0) = 1
       OR ISNULL(seg.FN_Usuario_TienePermisoUOT(@usuario, @uot, 'PREDIOS_ADMINISTRAR'), 0) = 1
        THROW 51000, N'Una cuenta operativa recibió una excepción administrativa no autorizada.', 1;
    FETCH NEXT FROM cuentas INTO @login, @rol, @nombre, @paterno, @materno, @doc, @areaCodigo, @cargo, @hash;
END;
CLOSE cuentas;
DEALLOCATE cuentas;

-- El administrador recibe y resuelve solicitudes. El comprador atiende la entrega de recursos.
DECLARE @comprador BIGINT = (SELECT usuario_id FROM seg.Usuario WHERE nombre_usuario = 'comprador' AND estado = 1);
INSERT campo.SalidaResponsableUOT(uot_id, usuario_id, funcion, prioridad, suplente, fecha_desde, estado, actualizado_por)
SELECT @uot, X.usuario, X.funcion, 1, 0, @vigente, 1, @admin
FROM (VALUES (@admin, 'APROBADOR'), (@comprador, 'ENTREGA'), (@admin, 'INSPECTOR')) X(usuario, funcion)
WHERE NOT EXISTS (SELECT 1 FROM campo.SalidaResponsableUOT R WITH (UPDLOCK, HOLDLOCK) WHERE R.uot_id = @uot AND R.usuario_id = X.usuario AND R.funcion = X.funcion);
UPDATE R SET estado = 1, prioridad = 1, suplente = 0, fecha_desde = @vigente, fecha_hasta = NULL,
    actualizado_por = @admin, fecha_actualizacion = @ahora
FROM campo.SalidaResponsableUOT R
WHERE R.uot_id = @uot AND ((R.usuario_id = @admin AND R.funcion IN ('APROBADOR', 'INSPECTOR')) OR (R.usuario_id = @comprador AND R.funcion = 'ENTREGA'))
  AND (R.estado = 0 OR R.fecha_hasta IS NOT NULL OR R.prioridad <> 1 OR R.suplente <> 0 OR R.fecha_desde > @vigente);
IF ISNULL(seg.FN_Usuario_TienePermisoUOT(@admin, @uot, 'SALIDAS_CONFIRMAR'), 0) <> 1
    THROW 51000, N'El administrador no tiene permiso efectivo de aprobación en Sara Sara.', 1;
