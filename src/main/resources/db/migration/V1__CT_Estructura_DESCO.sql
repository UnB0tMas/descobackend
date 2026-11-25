-- DESCO / Flyway V1: estructura final de una base nueva (SQL_DB_DESCO.sql, 16-11-2026).
-- Incluye esquemas, tablas, claves, índices, FOREIGN KEY y CHECK del estado final.
-- No incluye datos, procedimientos, funciones, vistas, triggers ni tablas internas de Flyway.
-- Uso exclusivo de instalación limpia; no aplicar sobre la BD de desarrollo ya migrada.

IF SCHEMA_ID(N'archivo') IS NULL EXEC(N'CREATE SCHEMA [archivo]');
IF SCHEMA_ID(N'auditoria') IS NULL EXEC(N'CREATE SCHEMA [auditoria]');
IF SCHEMA_ID(N'campo') IS NULL EXEC(N'CREATE SCHEMA [campo]');
IF SCHEMA_ID(N'comercial') IS NULL EXEC(N'CREATE SCHEMA [comercial]');
IF SCHEMA_ID(N'config') IS NULL EXEC(N'CREATE SCHEMA [config]');
IF SCHEMA_ID(N'finanzas') IS NULL EXEC(N'CREATE SCHEMA [finanzas]');
IF SCHEMA_ID(N'geo') IS NULL EXEC(N'CREATE SCHEMA [geo]');
IF SCHEMA_ID(N'integracion') IS NULL EXEC(N'CREATE SCHEMA [integracion]');
IF SCHEMA_ID(N'logistica') IS NULL EXEC(N'CREATE SCHEMA [logistica]');
IF SCHEMA_ID(N'org') IS NULL EXEC(N'CREATE SCHEMA [org]');
IF SCHEMA_ID(N'prod') IS NULL EXEC(N'CREATE SCHEMA [prod]');
IF SCHEMA_ID(N'reporte') IS NULL EXEC(N'CREATE SCHEMA [reporte]');
IF SCHEMA_ID(N'sanidad') IS NULL EXEC(N'CREATE SCHEMA [sanidad]');
IF SCHEMA_ID(N'seg') IS NULL EXEC(N'CREATE SCHEMA [seg]');
GO

CREATE TABLE [archivo].[Archivo]
(
    [archivo_id] bigint IDENTITY(1,1) NOT NULL,
    [nombre_original] nvarchar(255) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [mime_type] varchar(120) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [cloudinary_public_id] nvarchar(255) COLLATE Modern_Spanish_CI_AS NULL,
    [secure_url] nvarchar(1000) COLLATE Modern_Spanish_CI_AS NULL,
    [tamano_bytes] bigint NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_carga] datetime2(0) NOT NULL CONSTRAINT [DF_Archivo_FechaCarga] DEFAULT (sysutcdatetime()),
    [estado] bit NOT NULL CONSTRAINT [DF_Archivo_Estado] DEFAULT ((1)),
    [categoria] varchar(30) COLLATE Modern_Spanish_CI_AS NULL,
    [origen_captura] varchar(20) COLLATE Modern_Spanish_CI_AS NULL,
    [descripcion] nvarchar(400) COLLATE Modern_Spanish_CI_AS NULL,
    [hash_sha256] varbinary(32) NULL,
    [fecha_captura] datetime2(0) NULL,
    [posicion_captura] geography NULL,
    [fecha_retiro] datetime2(0) NULL,
    [retirado_por_usuario_id] bigint NULL,
    [motivo_retiro] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [tipo_evidencia] varchar(40) COLLATE Modern_Spanish_CI_AS NULL,
    [usuario_retiro_id] bigint NULL,
    [uot_id] bigint NULL,
    [proveedor_almacenamiento] varchar(20) COLLATE Modern_Spanish_CI_AS NULL,
    [clave_almacenamiento] nvarchar(1000) COLLATE Modern_Spanish_CI_AS NULL,
    [url_almacenamiento] nvarchar(1000) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [archivo].[ArchivoVinculo]
(
    [archivo_vinculo_id] bigint IDENTITY(1,1) NOT NULL,
    [archivo_id] bigint NOT NULL,
    [predio_id] bigint NULL,
    [salida_campo_id] bigint NULL,
    [visita_tecnica_id] bigint NULL,
    [caso_fitosanitario_id] bigint NULL,
    [tratamiento_id] bigint NULL,
    [entrega_socio_id] bigint NULL,
    [incidencia_operativa_id] bigint NULL,
    [ajuste_precio_socio_id] bigint NULL,
    [gasto_campania_id] bigint NULL,
    [liquidacion_socio_id] bigint NULL,
    [pago_socio_id] bigint NULL,
    [cobro_comprador_id] bigint NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_ArchivoVinculo_Estado] DEFAULT ((1)),
    [socio_id] bigint NULL,
    [empleado_id] bigint NULL,
    [parcela_id] bigint NULL,
    [parcela_cultivo_id] bigint NULL,
    [censo_plantas_id] bigint NULL,
    [evaluacion_agronomica_id] bigint NULL,
    [seguimiento_fitosanitario_id] bigint NULL,
    [disponibilidad_produccion_id] bigint NULL,
    [campania_venta_id] bigint NULL,
    [precio_comercial_id] bigint NULL,
    [participacion_campania_socio_id] bigint NULL,
    [operativo_venta_id] bigint NULL,
    [jaba_asignacion_id] bigint NULL,
    [jaba_devolucion_id] bigint NULL,
    [bien_inventario_id] bigint NULL,
    [recurso_programado_id] bigint NULL,
    [movimiento_inventario_id] bigint NULL
);
CREATE TABLE [auditoria].[AuditoriaEvento]
(
    [auditoria_evento_id] bigint IDENTITY(1,1) NOT NULL,
    [usuario_id] bigint NULL,
    [modulo_id] int NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF_AuditoriaEvento_Fecha] DEFAULT (sysutcdatetime()),
    [accion] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [esquema_entidad] sysname COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre_entidad] sysname COLLATE Modern_Spanish_CI_AS NOT NULL,
    [identificador] nvarchar(200) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [datos_anteriores] nvarchar(MAX) COLLATE Modern_Spanish_CI_AS NULL,
    [datos_posteriores] nvarchar(MAX) COLLATE Modern_Spanish_CI_AS NULL,
    [motivo] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL,
    [ip] varchar(64) COLLATE Modern_Spanish_CI_AS NULL,
    [dispositivo] nvarchar(200) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_AuditoriaEvento_Estado] DEFAULT ((1)),
    [sesion_usuario_id] bigint NULL,
    [dispositivo_usuario_id] bigint NULL,
    [correlacion_id] uniqueidentifier NULL,
    [solicitud_id] uniqueidentifier NULL,
    [resultado] varchar(20) COLLATE Modern_Spanish_CI_AS NULL,
    [endpoint] nvarchar(250) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [auditoria].[ErrorBaseDatos]
(
    [error_base_datos_id] bigint IDENTITY(1,1) NOT NULL,
    [fecha_utc] datetime2(3) NOT NULL,
    [numero_error] int NOT NULL,
    [procedimiento] nvarchar(257) COLLATE Modern_Spanish_CI_AS NULL,
    [linea] int NULL,
    [codigo] varchar(60) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [correlacion_id] uniqueidentifier NULL,
    [mensaje_sql] nvarchar(4000) COLLATE Modern_Spanish_CI_AS NULL,
    [tab] varchar(20) COLLATE Modern_Spanish_CI_AS NULL,
    [diagnostico_etapa] nvarchar(100) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [auditoria].[ExpedienteErrorTecnico]
(
    [error_id] bigint IDENTITY(1,1) NOT NULL,
    [fecha_utc] datetime2(3) NOT NULL CONSTRAINT [DF_E1_Error_Fecha] DEFAULT (sysutcdatetime()),
    [correlacion_id] uniqueidentifier NULL,
    [operacion] varchar(30) COLLATE Modern_Spanish_CI_AS NULL,
    [uot_id] bigint NULL,
    [convenio_id] bigint NULL,
    [persona_id] bigint NULL,
    [numero_sql] int NOT NULL,
    [procedimiento] nvarchar(256) COLLATE Modern_Spanish_CI_AS NULL,
    [linea_sql] int NULL,
    [mensaje_sql] nvarchar(2048) COLLATE Modern_Spanish_CI_AS NOT NULL
);
CREATE TABLE [auditoria].[OperacionIdempotente]
(
    [operacion_idempotente_id] bigint IDENTITY(1,1) NOT NULL,
    [usuario_id] bigint NOT NULL,
    [clave_idempotencia] uniqueidentifier NOT NULL,
    [ambito] varchar(100) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [request_hash] varbinary(64) NULL,
    [fecha_inicio] datetime2(0) NOT NULL CONSTRAINT [DF_OperacionIdempotente_Inicio] DEFAULT (sysutcdatetime()),
    [fecha_fin] datetime2(0) NULL,
    [estado_operacion] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_OperacionIdempotente_EstadoOperacion] DEFAULT ('EN_PROCESO'),
    [esquema_entidad] sysname COLLATE Modern_Spanish_CI_AS NULL,
    [nombre_entidad] sysname COLLATE Modern_Spanish_CI_AS NULL,
    [identificador_resultado] nvarchar(200) COLLATE Modern_Spanish_CI_AS NULL,
    [codigo_resultado] varchar(40) COLLATE Modern_Spanish_CI_AS NULL,
    [fecha_expiracion] datetime2(0) NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_OperacionIdempotente_Estado] DEFAULT ((1)),
    [mensaje_resultado] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [auditoria].[TransicionEstado]
(
    [transicion_estado_id] bigint IDENTITY(1,1) NOT NULL,
    [usuario_id] bigint NULL,
    [sesion_usuario_id] bigint NULL,
    [dispositivo_usuario_id] bigint NULL,
    [modulo_id] int NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF_TransicionEstado_Fecha] DEFAULT (sysutcdatetime()),
    [esquema_entidad] sysname COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre_entidad] sysname COLLATE Modern_Spanish_CI_AS NOT NULL,
    [identificador] nvarchar(200) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [campo_estado] sysname COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado_anterior] varchar(40) COLLATE Modern_Spanish_CI_AS NULL,
    [estado_nuevo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [motivo] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL,
    [correlacion_id] uniqueidentifier NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_TransicionEstado_Estado] DEFAULT ((1))
);
CREATE TABLE [campo].[EvaluacionAgronomica]
(
    [evaluacion_agronomica_id] bigint IDENTITY(1,1) NOT NULL,
    [visita_tecnica_id] bigint NOT NULL,
    [parcela_cultivo_id] bigint NULL,
    [tipo_evaluacion_id] smallint NOT NULL,
    [fecha_hora] datetime2(0) NOT NULL,
    [resultado] nvarchar(600) COLLATE Modern_Spanish_CI_AS NULL,
    [observacion] nvarchar(400) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_EvaluacionAgronomica_Estado] DEFAULT ((1))
);
CREATE TABLE [campo].[EvaluacionMateriaSeca]
(
    [evaluacion_materia_seca_id] bigint NOT NULL,
    [porcentaje_materia_seca] decimal(5,2) NOT NULL,
    [numero_muestras] smallint NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_EvaluacionMateriaSeca_Estado] DEFAULT ((1))
);
CREATE TABLE [campo].[MotivoSalida]
(
    [motivo_salida_id] smallint IDENTITY(1,1) NOT NULL,
    [codigo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(120) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_MotivoSalida_Estado] DEFAULT ((1))
);
CREATE TABLE [campo].[SalidaCampo]
(
    [salida_campo_id] bigint IDENTITY(1,1) NOT NULL,
    [motivo_salida_id] smallint NOT NULL,
    [fecha_hora_programada] datetime2(0) NOT NULL,
    [fecha_hora_salida_real] datetime2(0) NULL,
    [fecha_hora_retorno_real] datetime2(0) NULL,
    [descripcion] nvarchar(400) COLLATE Modern_Spanish_CI_AS NULL,
    [estado_proceso] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_SalidaCampo_Estado] DEFAULT ((1)),
    [uot_id] bigint NULL
);
CREATE TABLE [campo].[SalidaDestinoE2]
(
    [destino_id] bigint IDENTITY(1,1) NOT NULL,
    [salida_campo_id] bigint NOT NULL,
    [predio_id] bigint NULL,
    [referencia] nvarchar(250) COLLATE Modern_Spanish_CI_AS NULL,
    [orden] int NOT NULL,
    [actividad_prevista] nvarchar(400) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [campo].[SalidaE2]
(
    [salida_campo_id] bigint NOT NULL,
    [nombre] nvarchar(180) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [solicitante_empleado_id] bigint NOT NULL,
    [uot_id] bigint NOT NULL,
    [convenio_id] bigint NULL,
    [fecha_fin_prevista] datetime2(0) NULL,
    [estado] varchar(24) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_E2_SalidaEstado] DEFAULT ('SOLICITADA'),
    [fecha_solicitud] datetime2(0) NOT NULL CONSTRAINT [DF_E2_SalidaSolicitud] DEFAULT (sysutcdatetime()),
    [fecha_aprobacion] datetime2(0) NULL,
    [fecha_retorno_declarado] datetime2(0) NULL,
    [fecha_cierre] datetime2(0) NULL,
    [usuario_aprobador] bigint NULL
);
CREATE TABLE [campo].[SalidaEventoE2]
(
    [evento_id] bigint IDENTITY(1,1) NOT NULL,
    [salida_campo_id] bigint NOT NULL,
    [tipo] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [detalle] nvarchar(1200) COLLATE Modern_Spanish_CI_AS NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF__SalidaEve__fecha__785FB566] DEFAULT (sysutcdatetime()),
    [correlacion_id] uniqueidentifier NULL
);
CREATE TABLE [campo].[SalidaInspeccionE2]
(
    [salida_campo_id] bigint NOT NULL,
    [observacion_general] nvarchar(1200) COLLATE Modern_Spanish_CI_AS NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF_E2_InspeccionFecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [campo].[SalidaOperacionE2]
(
    [operacion_id] bigint IDENTITY(1,1) NOT NULL,
    [usuario_id] bigint NOT NULL,
    [tipo] varchar(35) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [idempotencia] uniqueidentifier NOT NULL,
    [hash_peticion] varbinary(32) NOT NULL,
    [respuesta] nvarchar(MAX) COLLATE Modern_Spanish_CI_AS NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF__SalidaOpe__fecha__0A7E65A1] DEFAULT (sysutcdatetime())
);
CREATE TABLE [campo].[SalidaParticipante]
(
    [salida_participante_id] bigint IDENTITY(1,1) NOT NULL,
    [salida_campo_id] bigint NOT NULL,
    [empleado_id] bigint NOT NULL,
    [funcion] nvarchar(120) COLLATE Modern_Spanish_CI_AS NULL,
    [es_responsable] bit NOT NULL CONSTRAINT [DF_SalidaParticipante_Responsable] DEFAULT ((0)),
    [estado] bit NOT NULL CONSTRAINT [DF_SalidaParticipante_Estado] DEFAULT ((1))
);
CREATE TABLE [campo].[SalidaRecursoE2]
(
    [solicitud_recurso_id] bigint IDENTITY(1,1) NOT NULL,
    [salida_campo_id] bigint NOT NULL,
    [bien_inventario_id] bigint NULL,
    [recurso_programado_id] bigint NULL,
    [estado] varchar(24) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF__SalidaRec__estad__6FCA6F65] DEFAULT ('SOLICITADO'),
    [resultado_declarado] varchar(24) COLLATE Modern_Spanish_CI_AS NULL,
    [observacion] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL,
    [resultado_validado] varchar(24) COLLATE Modern_Spanish_CI_AS NULL,
    [fecha_validacion] datetime2(0) NULL,
    [usuario_validacion] bigint NULL,
    [suministro_id] bigint NULL,
    [cantidad_solicitada] decimal(14,3) NOT NULL CONSTRAINT [DF_E2_RecursoCantidadSolicitada] DEFAULT ((1)),
    [cantidad_devuelta_declarada] decimal(14,3) NULL,
    [cantidad_devuelta_validada] decimal(14,3) NULL,
    [observacion_validacion] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL,
    [observacion_entrega] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [campo].[SalidaRetornoE2]
(
    [salida_campo_id] bigint NOT NULL,
    [observacion_general] nvarchar(1500) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF__SalidaRet__fecha__05B9B084] DEFAULT (sysutcdatetime()),
    [justificacion_sin_visita] nvarchar(1200) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [campo].[SalidaVisitaE2]
(
    [visita_tecnica_id] bigint NOT NULL,
    [destino_id] bigint NOT NULL,
    [tipo_visita_id] int NOT NULL
);
CREATE TABLE [campo].[TipoEvaluacion]
(
    [tipo_evaluacion_id] smallint IDENTITY(1,1) NOT NULL,
    [codigo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(120) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_TipoEvaluacion_Estado] DEFAULT ((1))
);
CREATE TABLE [campo].[TipoVisitaE2]
(
    [tipo_visita_id] int IDENTITY(1,1) NOT NULL,
    [codigo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(100) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF__TipoVisit__estad__7C30464A] DEFAULT ((1))
);
CREATE TABLE [campo].[VisitaTecnica]
(
    [visita_tecnica_id] bigint IDENTITY(1,1) NOT NULL,
    [salida_participante_id] bigint NOT NULL,
    [predio_id] bigint NOT NULL,
    [fecha_hora_inicio] datetime2(0) NOT NULL,
    [fecha_hora_fin] datetime2(0) NULL,
    [posicion_inicio] geography NULL,
    [objetivo] nvarchar(250) COLLATE Modern_Spanish_CI_AS NULL,
    [resumen] nvarchar(600) COLLATE Modern_Spanish_CI_AS NULL,
    [recomendaciones] nvarchar(600) COLLATE Modern_Spanish_CI_AS NULL,
    [estado_proceso] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_VisitaTecnica_Estado] DEFAULT ((1))
);
CREATE TABLE [comercial].[AccesoEmpleadoPOS]
(
    [uot_id] bigint NOT NULL,
    [empleado_id] bigint NOT NULL,
    [habilitado] bit NOT NULL CONSTRAINT [DF_AccesoPOS_Habilitado] DEFAULT ((1)),
    [motivo] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [usuario_actualizacion_id] bigint NOT NULL,
    [fecha_actualizacion] datetime2(0) NOT NULL CONSTRAINT [DF_AccesoPOS_Fecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [comercial].[AjustePrecioSocio]
(
    [ajuste_precio_socio_id] bigint IDENTITY(1,1) NOT NULL,
    [participacion_campania_socio_id] bigint NOT NULL,
    [operativo_venta_id] bigint NULL,
    [condicion_comercial_id] bigint NULL,
    [tipo_ajuste] varchar(25) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [precio_original] decimal(14,4) NULL,
    [precio_aplicado] decimal(14,4) NULL,
    [monto_ajuste] decimal(14,4) NULL,
    [porcentaje_ajuste] decimal(7,4) NULL,
    [motivo] nvarchar(400) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF_AjustePrecioSocio_Fecha] DEFAULT (sysutcdatetime()),
    [estado_ajuste] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_AjustePrecioSocio_Estado] DEFAULT ((1))
);
CREATE TABLE [comercial].[Boleta]
(
    [boleta_id] bigint IDENTITY(1,1) NOT NULL,
    [venta_id] bigint NOT NULL,
    [serie] varchar(10) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [numero] bigint NOT NULL,
    [fecha_emision] datetime2(0) NOT NULL CONSTRAINT [DF_Boleta_Fecha] DEFAULT (sysutcdatetime()),
    [cliente_documento] varchar(30) COLLATE Modern_Spanish_CI_AS NULL,
    [cliente_nombre] nvarchar(220) COLLATE Modern_Spanish_CI_AS NULL,
    [subtotal] decimal(19,4) NOT NULL,
    [impuesto] decimal(19,4) NOT NULL,
    [total] decimal(19,4) NOT NULL,
    [estado_comprobante] varchar(15) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_Boleta_EstadoComprobante] DEFAULT ('EMITIDO'),
    [estado] bit NOT NULL CONSTRAINT [DF_Boleta_Estado] DEFAULT ((1))
);
CREATE TABLE [comercial].[CajaAsignacion]
(
    [asignacion_id] bigint IDENTITY(1,1) NOT NULL,
    [caja_sesion_id] bigint NOT NULL,
    [usuario_anterior_id] bigint NOT NULL,
    [usuario_nuevo_id] bigint NOT NULL,
    [usuario_responsable_id] bigint NOT NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF__CajaAsign__fecha__110145FE] DEFAULT (sysutcdatetime())
);
CREATE TABLE [comercial].[CajaEvidencia]
(
    [caja_evidencia_id] bigint IDENTITY(1,1) NOT NULL,
    [caja_sesion_id] bigint NOT NULL,
    [archivo_id] bigint NOT NULL,
    [fase] varchar(10) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [usuario_registro_id] bigint NOT NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF_CajaEvidencia_Fecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [comercial].[CajaMovimiento]
(
    [caja_movimiento_id] bigint IDENTITY(1,1) NOT NULL,
    [caja_sesion_id] bigint NOT NULL,
    [tipo] varchar(10) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [importe] decimal(19,4) NOT NULL,
    [motivo] nvarchar(300) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF_CajaMovimiento_Fecha] DEFAULT (sysutcdatetime()),
    [clave_idempotencia] uniqueidentifier NOT NULL
);
CREATE TABLE [comercial].[CajaPOS]
(
    [caja_id] bigint IDENTITY(1,1) NOT NULL,
    [uot_id] bigint NOT NULL,
    [codigo] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(120) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_CajaPOS_Estado] DEFAULT ((1)),
    [usuario_creacion_id] bigint NOT NULL,
    [fecha_creacion] datetime2(0) NOT NULL CONSTRAINT [DF_CajaPOS_Creacion] DEFAULT (sysutcdatetime())
);
CREATE TABLE [comercial].[CajaSesion]
(
    [caja_sesion_id] bigint IDENTITY(1,1) NOT NULL,
    [caja_id] bigint NOT NULL,
    [usuario_apertura_id] bigint NOT NULL,
    [usuario_operador_id] bigint NOT NULL,
    [fecha_apertura] datetime2(0) NOT NULL CONSTRAINT [DF_CajaSesion_Apertura] DEFAULT (sysutcdatetime()),
    [saldo_inicial] decimal(19,4) NOT NULL,
    [fecha_cierre] datetime2(0) NULL,
    [usuario_cierre_id] bigint NULL,
    [saldo_esperado] decimal(19,4) NULL,
    [saldo_declarado] decimal(19,4) NULL,
    [diferencia] decimal(19,4) NULL,
    [observacion_cierre] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] varchar(10) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_CajaSesion_Estado] DEFAULT ('ABIERTA'),
    [observacion_apertura] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [comercial].[CajaSesionOperador]
(
    [caja_sesion_id] bigint NOT NULL,
    [usuario_id] bigint NOT NULL,
    [usuario_asignacion_id] bigint NOT NULL,
    [fecha_asignacion] datetime2(0) NOT NULL CONSTRAINT [DF_CajaSesionOperador_Desde] DEFAULT (sysutcdatetime()),
    [activo] bit NOT NULL CONSTRAINT [DF_CajaSesionOperador_Activo] DEFAULT ((1)),
    [usuario_retiro_id] bigint NULL,
    [fecha_retiro] datetime2(0) NULL
);
CREATE TABLE [comercial].[CampaniaCalibre]
(
    [campania_calibre_id] bigint IDENTITY(1,1) NOT NULL,
    [campania_venta_id] bigint NOT NULL,
    [variedad_palta_id] smallint NOT NULL,
    [calibre] varchar(12) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [gramos_desde] int NOT NULL,
    [gramos_hasta] int NULL,
    [precio_kg] decimal(14,4) NOT NULL,
    [version] int NOT NULL CONSTRAINT [DF_CampaniaCalibre_Version] DEFAULT ((1)),
    [usuario_registro_id] bigint NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF_CampaniaCalibre_Registro] DEFAULT (sysutcdatetime()),
    [activo] bit NOT NULL CONSTRAINT [DF_CampaniaCalibre_Activo] DEFAULT ((1))
);
CREATE TABLE [comercial].[CampaniaCalibrePrecioVersion]
(
    [campania_calibre_precio_version_id] bigint IDENTITY(1,1) NOT NULL,
    [campania_calibre_id] bigint NOT NULL,
    [version] int NOT NULL,
    [precio_kg] decimal(14,4) NOT NULL,
    [usuario_id] bigint NULL,
    [fecha] datetime2(0) NOT NULL CONSTRAINT [DF_CampaniaCalibrePrecioVersion_Fecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [comercial].[CampaniaControlE4]
(
    [campania_venta_id] bigint NOT NULL,
    [cupo_jabas] int NOT NULL,
    [tara_kg] decimal(10,3) NOT NULL,
    [version] bigint NOT NULL CONSTRAINT [DF_CampaniaControlE4_version] DEFAULT ((1)),
    [usuario_id] bigint NOT NULL,
    [actualizado_en] datetime2(0) NOT NULL CONSTRAINT [DF__CampaniaC__actua__52050254] DEFAULT (sysutcdatetime())
);
CREATE TABLE [comercial].[CampaniaJabaPlan]
(
    [campania_jaba_plan_id] bigint IDENTITY(1,1) NOT NULL,
    [participacion_campania_socio_id] bigint NOT NULL,
    [cantidad] int NOT NULL,
    [estado] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_CampaniaJabaPlan_Estado] DEFAULT ('PENDIENTE_RECOJO'),
    [activo] bit NOT NULL CONSTRAINT [DF_CampaniaJabaPlan_Activo] DEFAULT ((1)),
    [version] bigint NOT NULL CONSTRAINT [DF_CampaniaJabaPlan_Version] DEFAULT ((1)),
    [usuario_registro_id] bigint NOT NULL,
    [usuario_modifica_id] bigint NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF_CampaniaJabaPlan_Fecha] DEFAULT (sysutcdatetime()),
    [fecha_entrega] datetime2(0) NULL,
    [fecha_devolucion] datetime2(0) NULL,
    [recepcion_confirmada] bit NOT NULL CONSTRAINT [DF_CampaniaJabaPlan_RecepcionConfirmada] DEFAULT ((0)),
    [fecha_confirmacion_recepcion] datetime2(0) NULL,
    [usuario_confirmacion_recepcion_id] bigint NULL,
    [cantidad_ajuste_pendiente] int NOT NULL CONSTRAINT [DF_CampaniaJabaPlan_AjustePendiente] DEFAULT ((0)),
    [comentario_ajuste_pendiente] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [comercial].[CampaniaJabaPrecioSancion]
(
    [campania_jaba_recepcion_id] bigint NOT NULL,
    [campania_socio_sancion_id] bigint NULL,
    [precio_original_kg] decimal(14,4) NOT NULL,
    [descuento_precio_kg] decimal(14,4) NOT NULL,
    [precio_final_kg] decimal(14,4) NOT NULL,
    [sancion_nombre] nvarchar(120) COLLATE Modern_Spanish_CI_AS NULL,
    [fecha_precio] datetime2(0) NOT NULL CONSTRAINT [DF_CampaniaJabaPrecioSancion_Fecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [comercial].[CampaniaJabaRecepcion]
(
    [campania_jaba_recepcion_id] bigint IDENTITY(1,1) NOT NULL,
    [campania_jaba_plan_id] bigint NOT NULL,
    [numero_jaba] int NOT NULL,
    [peso_bruto_kg] decimal(12,3) NOT NULL,
    [descuento_jaba_kg] decimal(9,3) NOT NULL,
    [peso_neto_kg] AS (CONVERT([decimal](12,3),case when [peso_bruto_kg]=(0) then (0) else [peso_bruto_kg]-[descuento_jaba_kg] end)) PERSISTED,
    [campania_calibre_id] bigint NULL,
    [usuario_registro_id] bigint NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF_CampaniaJabaRecepcion_Fecha] DEFAULT (sysutcdatetime()),
    [usuario_modifica_id] bigint NULL,
    [fecha_modifica] datetime2(0) NULL,
    [version] int NOT NULL CONSTRAINT [DF_CampaniaJabaRecepcion_Version] DEFAULT ((1)),
    [observacion] nvarchar(400) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [comercial].[CampaniaSancionTarifa]
(
    [campania_sancion_tarifa_id] bigint IDENTITY(1,1) NOT NULL,
    [campania_venta_id] bigint NOT NULL,
    [sancion_venta_id] bigint NOT NULL,
    [descuento_precio_kg] decimal(14,4) NOT NULL,
    [activo] bit NOT NULL CONSTRAINT [DF_CampaniaSancionTarifa_Activo] DEFAULT ((1)),
    [usuario_registro_id] bigint NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF_CampaniaSancionTarifa_Fecha] DEFAULT (sysutcdatetime()),
    [usuario_modifica_id] bigint NULL,
    [fecha_modifica] datetime2(0) NULL
);
CREATE TABLE [comercial].[CampaniaSocioSancion]
(
    [campania_socio_sancion_id] bigint IDENTITY(1,1) NOT NULL,
    [campania_sancion_tarifa_id] bigint NOT NULL,
    [participacion_campania_socio_id] bigint NOT NULL,
    [desde_numero] int NOT NULL,
    [hasta_numero] int NULL,
    [alcance] varchar(10) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [comentario] nvarchar(500) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [activo] bit NOT NULL CONSTRAINT [DF_CampaniaSocioSancion_Activo] DEFAULT ((1)),
    [usuario_registro_id] bigint NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF_CampaniaSocioSancion_Fecha] DEFAULT (sysutcdatetime()),
    [usuario_modifica_id] bigint NULL,
    [fecha_modifica] datetime2(0) NULL
);
CREATE TABLE [comercial].[CampaniaVencimientoLog]
(
    [campania_vencimiento_log_id] bigint IDENTITY(1,1) NOT NULL,
    [campania_venta_id] bigint NOT NULL,
    [estado_anterior] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado_nuevo] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [fecha_hora_utc] datetime2(0) NOT NULL CONSTRAINT [DF_CampaniaVencimientoLog_Fecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [comercial].[CampaniaVenta]
(
    [campania_venta_id] bigint IDENTITY(1,1) NOT NULL,
    [asociacion_id] bigint NOT NULL,
    [empresa_compradora_id] bigint NULL,
    [codigo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(180) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [fecha_inicio] date NOT NULL,
    [fecha_fin] date NULL,
    [estado_proceso] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [observacion] nvarchar(400) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_CampaniaVenta_Estado] DEFAULT ((1)),
    [uot_id] bigint NOT NULL,
    [modalidad_venta_id] smallint NULL,
    [comprador_apappss_id] bigint NULL,
    [descuento_jaba_kg] decimal(9,3) NULL,
    [origen_jabas] varchar(12) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_CampaniaVenta_OrigenJabas] DEFAULT ('UOT')
);
CREATE TABLE [comercial].[CargoConceptoE4]
(
    [concepto_id] smallint IDENTITY(1,1) NOT NULL,
    [codigo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(120) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [activo] bit NOT NULL CONSTRAINT [DF__CargoConc__activ__6BC4D457] DEFAULT ((1))
);
CREATE TABLE [comercial].[CargoIndividualE4]
(
    [cargo_id] bigint IDENTITY(1,1) NOT NULL,
    [jaba_asignacion_id] bigint NOT NULL,
    [concepto_id] smallint NOT NULL,
    [tarifa_id] bigint NOT NULL,
    [cantidad] int NOT NULL,
    [precio_unitario] decimal(14,4) NOT NULL,
    [importe] AS (CONVERT([decimal](19,4),[cantidad]*[precio_unitario])) PERSISTED,
    [motivo] nvarchar(400) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [usuario_id] bigint NOT NULL,
    [fecha] datetime2(0) NOT NULL CONSTRAINT [DF__CargoIndi__fecha__791ECF75] DEFAULT (sysutcdatetime()),
    [estado] bit NOT NULL CONSTRAINT [DF__CargoIndi__estad__7A12F3AE] DEFAULT ((1))
);
CREATE TABLE [comercial].[CargoTarifaE4]
(
    [tarifa_id] bigint IDENTITY(1,1) NOT NULL,
    [concepto_id] smallint NOT NULL,
    [precio_unitario] decimal(14,4) NOT NULL,
    [vigente_desde] datetime2(0) NOT NULL,
    [vigente_hasta] datetime2(0) NULL,
    [usuario_id] bigint NULL,
    [campania_venta_id] bigint NULL
);
CREATE TABLE [comercial].[CatalogoSancionVenta]
(
    [sancion_venta_id] bigint IDENTITY(1,1) NOT NULL,
    [codigo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(120) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [descripcion] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [activo] bit NOT NULL CONSTRAINT [DF_CatalogoSancionVenta_Activo] DEFAULT ((1)),
    [usuario_registro_id] bigint NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF_CatalogoSancionVenta_Fecha] DEFAULT (sysutcdatetime()),
    [usuario_modifica_id] bigint NULL,
    [fecha_modifica] datetime2(0) NULL
);
CREATE TABLE [comercial].[CierreCampaniaE5]
(
    [campania_venta_id] bigint NOT NULL,
    [fecha] datetime2(0) NOT NULL CONSTRAINT [DF__CierreCam__fecha__64ADC274] DEFAULT (sysutcdatetime()),
    [usuario_id] bigint NULL,
    [observacion] nvarchar(800) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [excepcion_autorizada] bit NOT NULL CONSTRAINT [DF__CierreCam__excep__65A1E6AD] DEFAULT ((0)),
    [motivo_excepcion] nvarchar(800) COLLATE Modern_Spanish_CI_AS NULL,
    [balance_final] nvarchar(MAX) COLLATE Modern_Spanish_CI_AS NOT NULL
);
CREATE TABLE [comercial].[CompradorAPAPPSS]
(
    [comprador_apappss_id] bigint IDENTITY(1,1) NOT NULL,
    [uot_id] bigint NOT NULL,
    [tipo] varchar(10) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [persona_id] bigint NULL,
    [empresa_id] bigint NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF_CompradorAPAPPSS_Fecha] DEFAULT (sysutcdatetime()),
    [estado] bit NOT NULL CONSTRAINT [DF_CompradorAPAPPSS_Estado] DEFAULT ((1))
);
CREATE TABLE [comercial].[CondicionComercial]
(
    [condicion_comercial_id] bigint IDENTITY(1,1) NOT NULL,
    [modalidad_venta_id] smallint NOT NULL,
    [codigo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(160) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [descripcion] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [peso_minimo_g] decimal(8,2) NULL,
    [peso_maximo_g] decimal(8,2) NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_CondicionComercial_Estado] DEFAULT ((1))
);
CREATE TABLE [comercial].[DetalleVenta]
(
    [detalle_venta_id] bigint IDENTITY(1,1) NOT NULL,
    [venta_id] bigint NOT NULL,
    [producto_id] bigint NOT NULL,
    [producto_precio_id] bigint NOT NULL,
    [cantidad] decimal(19,3) NOT NULL,
    [precio_unitario] decimal(19,4) NOT NULL,
    [descuento_unitario] decimal(19,4) NOT NULL CONSTRAINT [DF_DetalleVenta_Descuento] DEFAULT ((0)),
    [subtotal] AS (CONVERT([decimal](19,4),[cantidad]*([precio_unitario]-[descuento_unitario]))) PERSISTED,
    [estado] bit NOT NULL CONSTRAINT [DF_DetalleVenta_Estado] DEFAULT ((1)),
    [precio_inicial_referencia] decimal(19,4) NOT NULL
);
CREATE TABLE [comercial].[EntregaDetalle]
(
    [entrega_detalle_id] bigint IDENTITY(1,1) NOT NULL,
    [entrega_socio_id] bigint NOT NULL,
    [variedad_palta_id] smallint NOT NULL,
    [condicion_comercial_id] bigint NOT NULL,
    [precio_comercial_id] bigint NULL,
    [kilogramos] decimal(14,3) NOT NULL,
    [precio_base] decimal(14,4) NOT NULL,
    [precio_aplicado] decimal(14,4) NOT NULL,
    [importe] AS (CONVERT([decimal](19,4),[kilogramos]*[precio_aplicado])) PERSISTED,
    [estado] bit NOT NULL CONSTRAINT [DF_EntregaDetalle_Estado] DEFAULT ((1))
);
CREATE TABLE [comercial].[EntregaSocio]
(
    [entrega_socio_id] bigint IDENTITY(1,1) NOT NULL,
    [operativo_socio_id] bigint NOT NULL,
    [predio_id] bigint NULL,
    [codigo_lote] varchar(60) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [fecha_hora] datetime2(0) NOT NULL,
    [peso_bruto_kg] decimal(14,3) NOT NULL,
    [tara_kg] decimal(14,3) NOT NULL,
    [peso_rechazado_kg] decimal(14,3) NOT NULL CONSTRAINT [DF_EntregaSocio_PesoRechazado] DEFAULT ((0)),
    [peso_neto_kg] AS ([peso_bruto_kg]-[tara_kg]) PERSISTED,
    [peso_aceptado_kg] AS (([peso_bruto_kg]-[tara_kg])-[peso_rechazado_kg]) PERSISTED,
    [estado_control_calidad] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [ticket_balanza] varchar(80) COLLATE Modern_Spanish_CI_AS NULL,
    [observacion] nvarchar(400) COLLATE Modern_Spanish_CI_AS NULL,
    [estado_proceso] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_EntregaSocio_Estado] DEFAULT ((1))
);
CREATE TABLE [comercial].[EventoE4]
(
    [evento_id] bigint IDENTITY(1,1) NOT NULL,
    [campania_venta_id] bigint NOT NULL,
    [entidad] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [entidad_id] bigint NOT NULL,
    [accion] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [detalle] nvarchar(MAX) COLLATE Modern_Spanish_CI_AS NULL,
    [usuario_id] bigint NOT NULL,
    [fecha] datetime2(0) NOT NULL CONSTRAINT [DF__EventoE4__fecha__08611305] DEFAULT (sysutcdatetime())
);
CREATE TABLE [comercial].[Factura]
(
    [factura_id] bigint IDENTITY(1,1) NOT NULL,
    [venta_id] bigint NOT NULL,
    [serie] varchar(10) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [numero] bigint NOT NULL,
    [fecha_emision] datetime2(0) NOT NULL CONSTRAINT [DF_Factura_Fecha] DEFAULT (sysutcdatetime()),
    [cliente_ruc] char(11) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [cliente_razon_social] nvarchar(220) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [subtotal] decimal(19,4) NOT NULL,
    [impuesto] decimal(19,4) NOT NULL,
    [total] decimal(19,4) NOT NULL,
    [estado_comprobante] varchar(15) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_Factura_EstadoComprobante] DEFAULT ('EMITIDO'),
    [estado] bit NOT NULL CONSTRAINT [DF_Factura_Estado] DEFAULT ((1))
);
CREATE TABLE [comercial].[HorarioAtencionUOT]
(
    [uot_id] bigint NOT NULL,
    [hora_inicio] time(0) NOT NULL CONSTRAINT [DF_HorarioInicio] DEFAULT ('07:00'),
    [hora_fin] time(0) NOT NULL CONSTRAINT [DF_HorarioFin] DEFAULT ('20:00'),
    [usuario_actualizacion_id] bigint NULL,
    [fecha_actualizacion] datetime2(0) NOT NULL CONSTRAINT [DF_HorarioActualizacion] DEFAULT (sysutcdatetime())
);
CREATE TABLE [comercial].[HorarioEmpleadoPOS]
(
    [horario_id] bigint IDENTITY(1,1) NOT NULL,
    [uot_id] bigint NOT NULL,
    [empleado_id] bigint NOT NULL,
    [dia_semana] tinyint NOT NULL,
    [hora_inicio] time(0) NOT NULL,
    [hora_fin] time(0) NOT NULL,
    [usuario_registro_id] bigint NOT NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF_HorarioPOS_Fecha] DEFAULT (sysutcdatetime()),
    [coincidencia_autorizada] bit NOT NULL CONSTRAINT [DF_HorarioPOS_Coincidencia] DEFAULT ((0)),
    [motivo_coincidencia] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [comercial].[IncidenciaFaltanteE4]
(
    [incidencia_id] bigint IDENTITY(1,1) NOT NULL,
    [jaba_asignacion_id] bigint NOT NULL,
    [cantidad] int NOT NULL,
    [estado] varchar(16) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF__Incidenci__estad__7FCBCD04] DEFAULT ('REGISTRADA'),
    [registrado_por] bigint NOT NULL,
    [registrado_en] datetime2(0) NOT NULL CONSTRAINT [DF__Incidenci__regis__01B41576] DEFAULT (sysutcdatetime()),
    [confirmado_por] bigint NULL,
    [confirmado_en] datetime2(0) NULL,
    [observacion] nvarchar(400) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [comercial].[IncidenciaOperativa]
(
    [incidencia_operativa_id] bigint IDENTITY(1,1) NOT NULL,
    [operativo_venta_id] bigint NOT NULL,
    [entrega_socio_id] bigint NULL,
    [tipo_incidencia] varchar(25) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [fecha_hora] datetime2(0) NOT NULL,
    [peso_afectado_kg] decimal(14,3) NULL,
    [severidad] varchar(10) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [descripcion] nvarchar(500) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado_incidencia] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_IncidenciaOperativa_Estado] DEFAULT ((1))
);
CREATE TABLE [comercial].[JabaAsignacion]
(
    [jaba_asignacion_id] bigint IDENTITY(1,1) NOT NULL,
    [operativo_socio_id] bigint NOT NULL,
    [fecha_hora] datetime2(0) NOT NULL,
    [cantidad_asignada] int NOT NULL,
    [observacion] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_JabaAsignacion_Estado] DEFAULT ((1)),
    [usuario_registro_id] bigint NULL,
    [fecha_anulacion] datetime2(0) NULL,
    [usuario_anulacion_id] bigint NULL,
    [motivo_anulacion] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [cantidad_devuelta] bigint NOT NULL CONSTRAINT [DF_DESCO_JabaAsignacion_Devuelta] DEFAULT ((0))
);
CREATE TABLE [comercial].[JabaClasificacionE4]
(
    [clasificacion_id] bigint IDENTITY(1,1) NOT NULL,
    [unidad_id] bigint NOT NULL,
    [numero] int NOT NULL,
    [peso_kg] decimal(14,3) NOT NULL,
    [rechazada] bit NOT NULL,
    [variedad_palta_id] smallint NULL,
    [condicion_comercial_id] bigint NULL,
    [precio_comercial_id] bigint NULL,
    [precio_base] decimal(14,4) NULL,
    [usuario_id] bigint NULL,
    [fecha] datetime2(0) NOT NULL CONSTRAINT [DF__JabaClasi__fecha__14C6E9EA] DEFAULT (sysutcdatetime())
);
CREATE TABLE [comercial].[JabaClasificacionHistorialE4]
(
    [historial_id] bigint IDENTITY(1,1) NOT NULL,
    [unidad_id] bigint NOT NULL,
    [version] bigint NOT NULL,
    [anterior] nvarchar(MAX) COLLATE Modern_Spanish_CI_AS NULL,
    [actual] nvarchar(MAX) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [motivo] nvarchar(400) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [usuario_id] bigint NOT NULL,
    [fecha] datetime2(0) NOT NULL CONSTRAINT [DF__JabaClasi__fecha__198B9F07] DEFAULT (sysutcdatetime())
);
CREATE TABLE [comercial].[JabaDevolucion]
(
    [jaba_devolucion_id] bigint IDENTITY(1,1) NOT NULL,
    [jaba_asignacion_id] bigint NOT NULL,
    [entrega_socio_id] bigint NULL,
    [fecha_hora] datetime2(0) NOT NULL,
    [cantidad_llenas] int NOT NULL,
    [cantidad_vacias] int NOT NULL,
    [observacion] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_JabaDevolucion_Estado] DEFAULT ((1)),
    [usuario_registro_id] bigint NULL,
    [fecha_anulacion] datetime2(0) NULL,
    [usuario_anulacion_id] bigint NULL,
    [motivo_anulacion] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [comercial].[JabaMovimiento]
(
    [jaba_movimiento_id] bigint IDENTITY(1,1) NOT NULL,
    [operativo_venta_id] bigint NOT NULL,
    [operativo_socio_id] bigint NULL,
    [jaba_asignacion_id] bigint NULL,
    [jaba_devolucion_id] bigint NULL,
    [tipo_movimiento] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [cantidad] int NOT NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF_JabaMovimiento_Fecha] DEFAULT (sysutcdatetime()),
    [usuario_id] bigint NULL,
    [motivo] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [referencia] varchar(80) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_JabaMovimiento_Estado] DEFAULT ((1)),
    [fecha_anulacion] datetime2(0) NULL,
    [usuario_anulacion_id] bigint NULL,
    [motivo_anulacion] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [comercial].[JabaPesajeHistorialE4]
(
    [historial_id] bigint IDENTITY(1,1) NOT NULL,
    [unidad_id] bigint NOT NULL,
    [version_anterior] bigint NOT NULL,
    [version_nueva] bigint NOT NULL,
    [estado_anterior] varchar(16) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado_nuevo] varchar(16) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [peso_anterior] decimal(14,3) NULL,
    [peso_nuevo] decimal(14,3) NULL,
    [tara_anterior] decimal(10,3) NULL,
    [tara_nueva] decimal(10,3) NULL,
    [precio_anterior] decimal(14,4) NULL,
    [precio_nuevo] decimal(14,4) NULL,
    [motivo] nvarchar(400) COLLATE Modern_Spanish_CI_AS NULL,
    [usuario_id] bigint NULL,
    [fecha] datetime2(0) NOT NULL CONSTRAINT [DF__JabaPesaj__fecha__4440F2E2] DEFAULT (sysutcdatetime())
);
CREATE TABLE [comercial].[JabaRetornoValidadoE4]
(
    [jaba_asignacion_id] bigint NOT NULL,
    [cantidad_validada] int NOT NULL,
    [observacion] nvarchar(400) COLLATE Modern_Spanish_CI_AS NULL,
    [validado_por] bigint NOT NULL,
    [validado_en] datetime2(0) NOT NULL CONSTRAINT [DF__JabaRetor__valid__407061FE] DEFAULT (sysutcdatetime())
);
CREATE TABLE [comercial].[JabaSaldoOperativo]
(
    [operativo_venta_id] bigint NOT NULL,
    [recibidas] bigint NOT NULL CONSTRAINT [DF_DESCO_JabaSaldo_Rec] DEFAULT ((0)),
    [asignadas] bigint NOT NULL CONSTRAINT [DF_DESCO_JabaSaldo_Asig] DEFAULT ((0)),
    [devueltas_llenas] bigint NOT NULL CONSTRAINT [DF_DESCO_JabaSaldo_Llenas] DEFAULT ((0)),
    [devueltas_vacias] bigint NOT NULL CONSTRAINT [DF_DESCO_JabaSaldo_Vacias] DEFAULT ((0)),
    [pendientes] AS (([asignadas]-[devueltas_llenas])-[devueltas_vacias]) PERSISTED,
    [disponibles] AS (([recibidas]-[asignadas])+[devueltas_vacias]) PERSISTED,
    [fecha_actualizacion] datetime2(3) NOT NULL CONSTRAINT [DF_DESCO_JabaSaldo_Fecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [comercial].[JabaStockHistorialE4]
(
    [historial_id] bigint IDENTITY(1,1) NOT NULL,
    [uot_id] bigint NOT NULL,
    [existencia_anterior] int NULL,
    [existencia_nueva] int NOT NULL,
    [motivo] nvarchar(400) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [usuario_id] bigint NOT NULL,
    [fecha] datetime2(0) NOT NULL CONSTRAINT [DF__JabaStock__fecha__3BABACE1] DEFAULT (sysutcdatetime())
);
CREATE TABLE [comercial].[JabaStockUotE4]
(
    [uot_id] bigint NOT NULL,
    [existencia_certificada] int NOT NULL,
    [version] bigint NOT NULL CONSTRAINT [DF_JabaStockUotE4_Version] DEFAULT ((1)),
    [actualizado_por] bigint NOT NULL,
    [actualizado_en] datetime2(0) NOT NULL CONSTRAINT [DF__JabaStock__actua__37DB1BFD] DEFAULT (sysutcdatetime())
);
CREATE TABLE [comercial].[JabaUnidadE4]
(
    [unidad_id] bigint IDENTITY(1,1) NOT NULL,
    [jaba_asignacion_id] bigint NOT NULL,
    [numero] int NOT NULL,
    [peso_bruto_kg] decimal(14,3) NULL,
    [tara_kg] decimal(10,3) NULL,
    [peso_neto_kg] AS ([peso_bruto_kg]-[tara_kg]) PERSISTED,
    [variedad_palta_id] smallint NULL,
    [condicion_comercial_id] bigint NULL,
    [precio_comercial_id] bigint NULL,
    [precio_base] decimal(14,4) NULL,
    [pesaje_estado] varchar(16) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF__JabaUnida__pesaj__5A9A4855] DEFAULT ('SIN_PESAJE'),
    [retorno_estado] varchar(16) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF__JabaUnida__retor__5B8E6C8E] DEFAULT ('PENDIENTE'),
    [usuario_pesaje_id] bigint NULL,
    [fecha_pesaje] datetime2(0) NULL,
    [usuario_retorno_id] bigint NULL,
    [fecha_retorno] datetime2(0) NULL,
    [entrega_socio_id] bigint NULL,
    [version] bigint NOT NULL CONSTRAINT [DF__JabaUnida__versi__5D76B500] DEFAULT ((1))
);
CREATE TABLE [comercial].[MetodoPago]
(
    [metodo_pago_id] smallint IDENTITY(1,1) NOT NULL,
    [codigo] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(100) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [requiere_numero_operacion] bit NOT NULL CONSTRAINT [DF_MetodoPago_Operacion] DEFAULT ((0)),
    [estado] bit NOT NULL CONSTRAINT [DF_MetodoPago_Estado] DEFAULT ((1))
);
CREATE TABLE [comercial].[ModalidadVenta]
(
    [modalidad_venta_id] smallint IDENTITY(1,1) NOT NULL,
    [codigo] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(100) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_ModalidadVenta_Estado] DEFAULT ((1))
);
CREATE TABLE [comercial].[OperativoSocio]
(
    [operativo_socio_id] bigint IDENTITY(1,1) NOT NULL,
    [operativo_venta_id] bigint NOT NULL,
    [participacion_campania_socio_id] bigint NOT NULL,
    [estado_participacion] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_OperativoSocio_Estado] DEFAULT ((1))
);
CREATE TABLE [comercial].[OperativoVenta]
(
    [operativo_venta_id] bigint IDENTITY(1,1) NOT NULL,
    [campania_venta_id] bigint NOT NULL,
    [codigo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [fecha_inicio_programada] datetime2(0) NOT NULL,
    [fecha_fin_programada] datetime2(0) NULL,
    [fecha_inicio_real] datetime2(0) NULL,
    [fecha_fin_real] datetime2(0) NULL,
    [cantidad_jabas_recibidas] int NOT NULL CONSTRAINT [DF_OperativoVenta_Jabas] DEFAULT ((0)),
    [estado_proceso] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [observacion] nvarchar(400) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_OperativoVenta_Estado] DEFAULT ((1))
);
CREATE TABLE [comercial].[OperativoZona]
(
    [operativo_venta_id] bigint NOT NULL,
    [zona_productiva_id] bigint NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_OperativoZona_Estado] DEFAULT ((1))
);
CREATE TABLE [comercial].[PagoVenta]
(
    [pago_venta_id] bigint IDENTITY(1,1) NOT NULL,
    [venta_id] bigint NOT NULL,
    [metodo_pago_id] smallint NOT NULL,
    [importe] decimal(19,4) NOT NULL,
    [moneda] char(3) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_PagoVenta_Moneda] DEFAULT ('PEN'),
    [numero_operacion] varchar(120) COLLATE Modern_Spanish_CI_AS NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF_PagoVenta_Fecha] DEFAULT (sysutcdatetime()),
    [usuario_id] bigint NOT NULL,
    [estado_pago] varchar(15) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_PagoVenta_EstadoPago] DEFAULT ('CONFIRMADO'),
    [estado] bit NOT NULL CONSTRAINT [DF_PagoVenta_Estado] DEFAULT ((1)),
    [fecha_anulacion] datetime2(0) NULL,
    [usuario_anulacion_id] bigint NULL,
    [motivo_anulacion] nvarchar(400) COLLATE Modern_Spanish_CI_AS NULL,
    [clave_idempotencia] uniqueidentifier NULL,
    [archivo_id] bigint NULL
);
CREATE TABLE [comercial].[ParticipacionCampaniaSocio]
(
    [participacion_campania_socio_id] bigint IDENTITY(1,1) NOT NULL,
    [campania_venta_id] bigint NOT NULL,
    [socio_asociacion_id] bigint NOT NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF_ParticipacionCampaniaSocio_Fecha] DEFAULT (sysutcdatetime()),
    [estado_participacion] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_ParticipacionCampaniaSocio_Estado] DEFAULT ((1))
);
CREATE TABLE [comercial].[PrecioComercial]
(
    [precio_comercial_id] bigint IDENTITY(1,1) NOT NULL,
    [campania_venta_id] bigint NOT NULL,
    [operativo_venta_id] bigint NULL,
    [variedad_palta_id] smallint NOT NULL,
    [condicion_comercial_id] bigint NOT NULL,
    [precio] decimal(14,4) NOT NULL,
    [moneda] char(3) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_PrecioComercial_Moneda] DEFAULT ('PEN'),
    [unidad_medida] varchar(10) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_PrecioComercial_Unidad] DEFAULT ('KG'),
    [fecha_vigencia_desde] datetime2(0) NOT NULL,
    [fecha_vigencia_hasta] datetime2(0) NULL,
    [version] int NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_PrecioComercial_Estado] DEFAULT ((1))
);
CREATE TABLE [comercial].[SancionSocioE4]
(
    [sancion_id] bigint IDENTITY(1,1) NOT NULL,
    [entrega_socio_id] bigint NOT NULL,
    [condicion_comercial_id] bigint NULL,
    [variedad_palta_id] smallint NULL,
    [kilos_afectados] decimal(14,3) NOT NULL,
    [precio_original] decimal(14,4) NOT NULL,
    [precio_nuevo] decimal(14,4) NOT NULL,
    [diferencia] AS (CONVERT([decimal](19,4),[kilos_afectados]*([precio_original]-[precio_nuevo]))) PERSISTED,
    [motivo] nvarchar(400) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [usuario_id] bigint NOT NULL,
    [fecha] datetime2(0) NOT NULL CONSTRAINT [DF__SancionSo__fecha__67001F3A] DEFAULT (sysutcdatetime()),
    [estado] bit NOT NULL CONSTRAINT [DF__SancionSo__estad__67F44373] DEFAULT ((1)),
    [aplicada_detalle] bit NOT NULL CONSTRAINT [DF__SancionSo__aplic__471D5F8D] DEFAULT ((0))
);
CREATE TABLE [comercial].[SolicitudE4]
(
    [usuario_id] bigint NOT NULL,
    [clave] uniqueidentifier NOT NULL,
    [accion] varchar(32) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [huella] varbinary(32) NOT NULL,
    [respuesta] nvarchar(MAX) COLLATE Modern_Spanish_CI_AS NULL,
    [fecha] datetime2(0) NOT NULL CONSTRAINT [DF__Solicitud__fecha__04908221] DEFAULT (sysutcdatetime())
);
CREATE TABLE [comercial].[Venta]
(
    [venta_id] bigint IDENTITY(1,1) NOT NULL,
    [uot_id] bigint NOT NULL,
    [almacen_id] bigint NOT NULL,
    [cliente_persona_id] bigint NULL,
    [cliente_empresa_id] bigint NULL,
    [vendedor_usuario_id] bigint NOT NULL,
    [clave_idempotencia] uniqueidentifier NOT NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF_Venta_Fecha] DEFAULT (sysutcdatetime()),
    [fecha_reserva_hasta] datetime2(0) NULL,
    [moneda] char(3) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_Venta_Moneda] DEFAULT ('PEN'),
    [subtotal] decimal(19,4) NOT NULL CONSTRAINT [DF_Venta_Subtotal] DEFAULT ((0)),
    [descuento] decimal(19,4) NOT NULL CONSTRAINT [DF_Venta_Descuento] DEFAULT ((0)),
    [impuesto] decimal(19,4) NOT NULL CONSTRAINT [DF_Venta_Impuesto] DEFAULT ((0)),
    [total] decimal(19,4) NOT NULL CONSTRAINT [DF_Venta_Total] DEFAULT ((0)),
    [estado_venta] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [observacion] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_Venta_Estado] DEFAULT ((1)),
    [fecha_anulacion] datetime2(0) NULL,
    [usuario_anulacion_id] bigint NULL,
    [motivo_anulacion] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL,
    [caja_sesion_id] bigint NULL
);
CREATE TABLE [comercial].[VentaAnulacionPOS]
(
    [venta_id] bigint NOT NULL,
    [usuario_id] bigint NOT NULL,
    [fecha] datetime2(0) NOT NULL CONSTRAINT [DF_VentaAnulacionPOS_Fecha] DEFAULT (sysutcdatetime()),
    [motivo] nvarchar(500) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [importe_reintegrado] decimal(19,4) NOT NULL,
    [devolucion_confirmada] bit NOT NULL,
    [movimiento_reversa_id] bigint NULL
);
CREATE TABLE [config].[CatalogoRecursoValor]
(
    [catalogo_recurso_valor_id] bigint IDENTITY(1,1) NOT NULL,
    [catalogo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [codigo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(150) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [descripcion] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_CatalogoRecursoValor_Estado] DEFAULT ((1)),
    [fecha_creacion] datetime2(0) NOT NULL CONSTRAINT [DF_CatalogoRecursoValor_Creacion] DEFAULT (sysutcdatetime()),
    [fecha_actualizacion] datetime2(0) NULL
);
CREATE TABLE [config].[DashboardElemento]
(
    [dashboard_elemento_id] bigint IDENTITY(1,1) NOT NULL,
    [codigo] varchar(80) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [tipo] varchar(12) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [titulo] nvarchar(180) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [subtitulo] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [permiso_id] bigint NOT NULL,
    [unidad] nvarchar(30) COLLATE Modern_Spanish_CI_AS NULL,
    [icono] varchar(80) COLLATE Modern_Spanish_CI_AS NULL,
    [tipo_grafico] varchar(20) COLLATE Modern_Spanish_CI_AS NULL,
    [permite_fechas] bit NOT NULL CONSTRAINT [DF_DashboardElemento_PermiteFechas] DEFAULT ((0)),
    [ancho] tinyint NOT NULL CONSTRAINT [DF_DashboardElemento_Ancho] DEFAULT ((1)),
    [orden] smallint NOT NULL CONSTRAINT [DF_DashboardElemento_Orden] DEFAULT ((0)),
    [estado] bit NOT NULL CONSTRAINT [DF_DashboardElemento_Estado] DEFAULT ((1)),
    [fecha_creacion] datetime2(0) NOT NULL CONSTRAINT [DF_DashboardElemento_FechaCreacion] DEFAULT (sysutcdatetime()),
    [fecha_modificacion] datetime2(0) NULL
);
CREATE TABLE [config].[DashboardRolElemento]
(
    [rol_id] bigint NOT NULL,
    [dashboard_elemento_id] bigint NOT NULL,
    [visible] bit NOT NULL CONSTRAINT [DF_DashboardRolElemento_Visible] DEFAULT ((1)),
    [orden] smallint NULL,
    [fecha_modificacion] datetime2(0) NOT NULL CONSTRAINT [DF_DashboardRolElemento_Fecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [config].[DashboardUsuarioElemento]
(
    [usuario_id] bigint NOT NULL,
    [dashboard_elemento_id] bigint NOT NULL,
    [visible] bit NOT NULL,
    [orden] smallint NULL,
    [fecha_modificacion] datetime2(0) NOT NULL CONSTRAINT [DF_DashboardUsuarioElemento_Fecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [config].[MensajeUsuario]
(
    [texto_origen] nvarchar(300) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [mensaje] nvarchar(180) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [codigo_error] varchar(60) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [http_error] smallint NOT NULL
);
CREATE TABLE [config].[RespuestaBaseDatos]
(
    [clave] varchar(150) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [codigo] varchar(60) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [numero_sql] int NULL,
    [mensaje] nvarchar(300) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [http_sugerido] smallint NOT NULL,
    [reintentable] bit NOT NULL,
    [estado] bit NOT NULL
);
CREATE TABLE [config].[RespuestaProcedimiento]
(
    [procedimiento] nvarchar(257) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [mensaje_exito] nvarchar(180) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [codigo_exito] varchar(60) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [mensaje_error] nvarchar(180) COLLATE Modern_Spanish_CI_AS NOT NULL
);
CREATE TABLE [config].[TipoDocumentoComprador]
(
    [tipo_documento_comprador_id] bigint IDENTITY(1,1) NOT NULL,
    [codigo] varchar(15) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(120) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [descripcion] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_TipoDocumentoComprador_Estado] DEFAULT ((1))
);
CREATE TABLE [finanzas].[CobroComprador]
(
    [cobro_comprador_id] bigint IDENTITY(1,1) NOT NULL,
    [campania_venta_id] bigint NOT NULL,
    [operativo_venta_id] bigint NULL,
    [fecha_hora] datetime2(0) NOT NULL,
    [importe] decimal(19,4) NOT NULL,
    [moneda] char(3) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_CobroComprador_Moneda] DEFAULT ('PEN'),
    [medio_pago] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [numero_operacion] varchar(100) COLLATE Modern_Spanish_CI_AS NULL,
    [estado_proceso] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_CobroComprador_Estado] DEFAULT ((1)),
    [fecha_confirmacion] datetime2(0) NULL,
    [usuario_confirmacion_id] bigint NULL,
    [fecha_anulacion] datetime2(0) NULL,
    [usuario_anulacion_id] bigint NULL,
    [motivo_anulacion] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [finanzas].[EventoPagoE5]
(
    [evento_id] bigint IDENTITY(1,1) NOT NULL,
    [pago_socio_id] bigint NOT NULL,
    [accion] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [importe] decimal(19,4) NOT NULL,
    [usuario_id] bigint NOT NULL,
    [motivo] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL,
    [fecha] datetime2(0) NOT NULL CONSTRAINT [DF__EventoPag__fecha__60DD3190] DEFAULT (sysutcdatetime())
);
CREATE TABLE [finanzas].[GastoCampania]
(
    [gasto_campania_id] bigint IDENTITY(1,1) NOT NULL,
    [campania_venta_id] bigint NOT NULL,
    [operativo_venta_id] bigint NULL,
    [tipo_gasto_id] smallint NOT NULL,
    [regla_prorrateo_id] smallint NOT NULL,
    [fecha] date NOT NULL,
    [concepto] nvarchar(250) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [importe] decimal(19,4) NOT NULL,
    [moneda] char(3) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_GastoCampania_Moneda] DEFAULT ('PEN'),
    [estado_proceso] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_GastoCampania_Estado] DEFAULT ((1))
);
CREATE TABLE [finanzas].[GastoProrrateoSocio]
(
    [gasto_prorrateo_socio_id] bigint IDENTITY(1,1) NOT NULL,
    [gasto_campania_id] bigint NOT NULL,
    [participacion_campania_socio_id] bigint NOT NULL,
    [importe_asignado] decimal(19,4) NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_GastoProrrateoSocio_Estado] DEFAULT ((1))
);
CREATE TABLE [finanzas].[GastoRepartoLineaE5]
(
    [reparto_id] bigint NOT NULL,
    [participacion_id] bigint NOT NULL,
    [monto] decimal(19,4) NOT NULL
);
CREATE TABLE [finanzas].[GastoRepartoVersionE5]
(
    [reparto_id] bigint IDENTITY(1,1) NOT NULL,
    [gasto_campania_id] bigint NOT NULL,
    [version] int NOT NULL,
    [importe] decimal(19,4) NOT NULL,
    [moneda] char(3) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [vendedores] int NOT NULL,
    [estado] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [observacion] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL,
    [usuario_id] bigint NOT NULL,
    [creado] datetime2(0) NOT NULL CONSTRAINT [DF__GastoRepa__cread__519AEE00] DEFAULT (sysutcdatetime()),
    [aprobado_por] bigint NULL,
    [aprobado] datetime2(0) NULL
);
CREATE TABLE [finanzas].[LiquidacionDetalle]
(
    [liquidacion_detalle_id] bigint IDENTITY(1,1) NOT NULL,
    [liquidacion_socio_id] bigint NOT NULL,
    [tipo] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [entrega_detalle_id] bigint NULL,
    [gasto_prorrateo_socio_id] bigint NULL,
    [ajuste_precio_socio_id] bigint NULL,
    [concepto] nvarchar(250) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [importe] decimal(19,4) NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_LiquidacionDetalle_Estado] DEFAULT ((1))
);
CREATE TABLE [finanzas].[LiquidacionSnapshotE5]
(
    [liquidacion_socio_id] bigint NOT NULL,
    [campania_venta_id] bigint NOT NULL,
    [peso_aceptado_kg] decimal(19,3) NOT NULL,
    [bruto_referencial] decimal(19,4) NOT NULL,
    [ajuste_precio] decimal(19,4) NOT NULL,
    [descuentos_adicionales] decimal(19,4) NOT NULL,
    [cargos] decimal(19,4) NOT NULL,
    [gastos] decimal(19,4) NOT NULL,
    [bonificaciones] decimal(19,4) NOT NULL,
    [ajuste_redondeo] decimal(19,4) NOT NULL CONSTRAINT [DF__Liquidaci__ajust__5B24583A] DEFAULT ((0)),
    [venta_ajustada] decimal(19,4) NOT NULL,
    [neto] decimal(19,4) NOT NULL,
    [fuente_hash] varbinary(32) NOT NULL,
    [moneda] char(3) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [creado_por] bigint NOT NULL,
    [creado] datetime2(0) NOT NULL CONSTRAINT [DF__Liquidaci__cread__5C187C73] DEFAULT (sysutcdatetime()),
    [aprobado_por] bigint NULL,
    [aprobado] datetime2(0) NULL,
    [observacion] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [finanzas].[LiquidacionSocio]
(
    [liquidacion_socio_id] bigint IDENTITY(1,1) NOT NULL,
    [participacion_campania_socio_id] bigint NOT NULL,
    [version] int NOT NULL,
    [fecha_calculo] datetime2(0) NOT NULL,
    [importe_bruto] decimal(19,4) NOT NULL,
    [total_ajustes] decimal(19,4) NOT NULL,
    [total_gastos] decimal(19,4) NOT NULL,
    [total_bonificaciones] decimal(19,4) NOT NULL,
    [importe_neto] decimal(19,4) NOT NULL,
    [moneda] char(3) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_LiquidacionSocio_Moneda] DEFAULT ('PEN'),
    [estado_proceso] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_LiquidacionSocio_Estado] DEFAULT ((1))
);
CREATE TABLE [finanzas].[PagoBeneficiarioE5]
(
    [pago_socio_id] bigint NOT NULL,
    [beneficiario_persona_id] bigint NOT NULL,
    [documento] varchar(60) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(290) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [usuario_registro_id] bigint NOT NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF_PagoBeneficiarioE5_Fecha] DEFAULT (sysutcdatetime()),
    [motivo_entrega] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL,
    [comprobante_archivo_id] bigint NULL
);
CREATE TABLE [finanzas].[PagoSocio]
(
    [pago_socio_id] bigint IDENTITY(1,1) NOT NULL,
    [liquidacion_socio_id] bigint NOT NULL,
    [fecha_hora] datetime2(0) NOT NULL,
    [importe] decimal(19,4) NOT NULL,
    [medio_pago] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [numero_operacion] varchar(100) COLLATE Modern_Spanish_CI_AS NULL,
    [estado_proceso] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_PagoSocio_Estado] DEFAULT ((1)),
    [fecha_confirmacion] datetime2(0) NULL,
    [usuario_confirmacion_id] bigint NULL,
    [fecha_anulacion] datetime2(0) NULL,
    [usuario_anulacion_id] bigint NULL,
    [motivo_anulacion] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [finanzas].[ReglaProrrateo]
(
    [regla_prorrateo_id] smallint IDENTITY(1,1) NOT NULL,
    [codigo] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(120) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_ReglaProrrateo_Estado] DEFAULT ((1))
);
CREATE TABLE [finanzas].[SolicitudE5]
(
    [usuario_id] bigint NOT NULL,
    [clave] uniqueidentifier NOT NULL,
    [accion] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [huella] varbinary(32) NOT NULL,
    [respuesta] nvarchar(MAX) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [fecha] datetime2(0) NOT NULL CONSTRAINT [DF__Solicitud__fecha__69727791] DEFAULT (sysutcdatetime())
);
CREATE TABLE [finanzas].[TipoGasto]
(
    [tipo_gasto_id] smallint IDENTITY(1,1) NOT NULL,
    [codigo] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(120) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_TipoGasto_Estado] DEFAULT ((1))
);
CREATE TABLE [geo].[CentroPoblado]
(
    [centro_poblado_id] bigint IDENTITY(1,1) NOT NULL,
    [distrito_codigo] char(6) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(150) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [codigo_inei] varchar(20) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_CentroPoblado_Estado] DEFAULT ((1))
);
CREATE TABLE [geo].[Departamento]
(
    [departamento_codigo] char(2) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(100) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_Departamento_Estado] DEFAULT ((1))
);
CREATE TABLE [geo].[Distrito]
(
    [distrito_codigo] char(6) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [provincia_codigo] char(4) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(100) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_Distrito_Estado] DEFAULT ((1))
);
CREATE TABLE [geo].[Provincia]
(
    [provincia_codigo] char(4) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [departamento_codigo] char(2) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(100) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_Provincia_Estado] DEFAULT ((1))
);
CREATE TABLE [geo].[Ubicacion]
(
    [ubicacion_id] bigint IDENTITY(1,1) NOT NULL,
    [distrito_codigo] char(6) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [centro_poblado_id] bigint NULL,
    [referencia] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [posicion] geography NULL,
    [altitud_m] decimal(8,2) NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_Ubicacion_Estado] DEFAULT ((1))
);
CREATE TABLE [geo].[ZonaProductiva]
(
    [zona_productiva_id] bigint IDENTITY(1,1) NOT NULL,
    [codigo] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(150) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [descripcion] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_ZonaProductiva_Estado] DEFAULT ((1))
);
CREATE TABLE [geo].[ZonaProductivaPredio]
(
    [zona_productiva_predio_id] bigint IDENTITY(1,1) NOT NULL,
    [zona_productiva_id] bigint NOT NULL,
    [predio_id] bigint NOT NULL,
    [fecha_desde] date NOT NULL,
    [fecha_hasta] date NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_ZonaProductivaPredio_Estado] DEFAULT ((1))
);
CREATE TABLE [geo].[ZonaProductivaUbicacion]
(
    [zona_productiva_ubicacion_id] bigint IDENTITY(1,1) NOT NULL,
    [zona_productiva_id] bigint NOT NULL,
    [distrito_codigo] char(6) COLLATE Modern_Spanish_CI_AS NULL,
    [centro_poblado_id] bigint NULL,
    [fecha_desde] date NOT NULL,
    [fecha_hasta] date NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_ZonaProductivaUbicacion_Estado] DEFAULT ((1))
);
CREATE TABLE [integracion].[ConsultaDocumento]
(
    [consulta_documento_id] bigint IDENTITY(1,1) NOT NULL,
    [entidad_objetivo] varchar(10) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [clave_documento] varchar(60) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [tipo_documento_solicitado] varchar(15) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [numero_documento_solicitado] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [tipo_documento_externo] varchar(15) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [numero_documento_externo] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [proveedor] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_ConsultaDocumento_Proveedor] DEFAULT ('FACTILIZA'),
    [estado_consulta] varchar(25) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_ConsultaDocumento_EstadoConsulta] DEFAULT ('PENDIENTE'),
    [cantidad_intentos] int NOT NULL CONSTRAINT [DF_ConsultaDocumento_Intentos] DEFAULT ((0)),
    [fecha_primera_solicitud_utc] datetime2(0) NOT NULL CONSTRAINT [DF_ConsultaDocumento_FechaPrimera] DEFAULT (sysutcdatetime()),
    [fecha_ultimo_intento_utc] datetime2(0) NOT NULL CONSTRAINT [DF_ConsultaDocumento_FechaUltimoIntento] DEFAULT (sysutcdatetime()),
    [bloqueo_hasta_utc] datetime2(0) NULL,
    [reintento_desde_utc] datetime2(0) NULL,
    [fecha_ultimo_exito_utc] datetime2(0) NULL,
    [ultimo_codigo_error] varchar(60) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_ConsultaDocumento_Estado] DEFAULT ((1))
);
CREATE TABLE [integracion].[IdentidadCampoOrigen]
(
    [identidad_campo_origen_id] bigint IDENTITY(1,1) NOT NULL,
    [entidad_objetivo] varchar(10) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [entidad_id] bigint NOT NULL,
    [campo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [proveedor] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [fecha_origen_utc] datetime2(0) NOT NULL CONSTRAINT [DF_IdentidadCampoOrigen_Fecha] DEFAULT (sysutcdatetime()),
    [estado] bit NOT NULL CONSTRAINT [DF_IdentidadCampoOrigen_Estado] DEFAULT ((1))
);
CREATE TABLE [logistica].[Almacen]
(
    [almacen_id] bigint IDENTITY(1,1) NOT NULL,
    [uot_propietaria_id] bigint NOT NULL,
    [ubicacion_id] bigint NULL,
    [codigo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(160) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [descripcion] nvarchar(400) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_Almacen_Estado] DEFAULT ((1)),
    [fecha_creacion] datetime2(0) NOT NULL CONSTRAINT [DF_Almacen_Fecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [logistica].[AlmacenProductoEvento]
(
    [almacen_producto_evento_id] bigint IDENTITY(1,1) NOT NULL,
    [almacen_id] bigint NOT NULL,
    [producto_id] bigint NOT NULL,
    [operacion] varchar(15) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [stock_minimo_anterior] decimal(19,3) NULL,
    [stock_minimo_nuevo] decimal(19,3) NULL,
    [estado_anterior] bit NULL,
    [estado_nuevo] bit NULL,
    [motivo] nvarchar(500) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_hora] datetime2(3) NOT NULL CONSTRAINT [DF_AlmacenProductoEvento_Fecha] DEFAULT (sysutcdatetime()),
    [clave_idempotencia] uniqueidentifier NOT NULL,
    [solicitud_sha256] varbinary(32) NOT NULL
);
CREATE TABLE [logistica].[AlmacenProductoStock]
(
    [almacen_id] bigint NOT NULL,
    [producto_id] bigint NOT NULL,
    [stock_actual] decimal(19,3) NOT NULL CONSTRAINT [DF_Stock_Actual] DEFAULT ((0)),
    [stock_reservado] decimal(19,3) NOT NULL CONSTRAINT [DF_Stock_Reservado] DEFAULT ((0)),
    [stock_disponible] AS ([stock_actual]-[stock_reservado]) PERSISTED,
    [stock_minimo] decimal(19,3) NOT NULL CONSTRAINT [DF_Stock_Minimo] DEFAULT ((0)),
    [fecha_actualizacion] datetime2(3) NOT NULL CONSTRAINT [DF_Stock_Fecha] DEFAULT (sysutcdatetime()),
    [estado] bit NOT NULL CONSTRAINT [DF_AlmacenProductoStock_Estado] DEFAULT ((1))
);
CREATE TABLE [logistica].[AlmacenUOT]
(
    [almacen_uot_id] bigint IDENTITY(1,1) NOT NULL,
    [almacen_id] bigint NOT NULL,
    [uot_id] bigint NOT NULL,
    [tipo_acceso] varchar(15) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [permite_entrada] bit NOT NULL CONSTRAINT [DF_AlmacenUOT_Entrada] DEFAULT ((1)),
    [permite_salida] bit NOT NULL CONSTRAINT [DF_AlmacenUOT_Salida] DEFAULT ((1)),
    [fecha_desde] datetime2(0) NOT NULL CONSTRAINT [DF_AlmacenUOT_Desde] DEFAULT (sysutcdatetime()),
    [fecha_hasta] datetime2(0) NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_AlmacenUOT_Estado] DEFAULT ((1))
);
CREATE TABLE [logistica].[BienEstadoHistorial]
(
    [bien_estado_historial_id] bigint IDENTITY(1,1) NOT NULL,
    [bien_inventario_id] bigint NOT NULL,
    [estado_bien] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [fecha_desde] datetime2(0) NOT NULL,
    [fecha_hasta] datetime2(0) NULL,
    [motivo] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL,
    [usuario_id] bigint NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_BienEstadoHistorial_Estado] DEFAULT ((1))
);
CREATE TABLE [logistica].[BienImagen]
(
    [bien_imagen_id] bigint IDENTITY(1,1) NOT NULL,
    [bien_inventario_id] bigint NOT NULL,
    [archivo_id] bigint NOT NULL,
    [es_principal] bit NOT NULL CONSTRAINT [DF_BienImagen_Principal] DEFAULT ((0)),
    [orden] smallint NOT NULL CONSTRAINT [DF_BienImagen_Orden] DEFAULT ((1)),
    [estado] bit NOT NULL CONSTRAINT [DF_BienImagen_Estado] DEFAULT ((1))
);
CREATE TABLE [logistica].[BienIncidente]
(
    [bien_incidente_id] bigint IDENTITY(1,1) NOT NULL,
    [bien_inventario_id] bigint NOT NULL,
    [tipo_incidente] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [fecha_hora] datetime2(0) NOT NULL,
    [descripcion] nvarchar(700) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [costo_estimado] decimal(19,4) NULL,
    [costo_real] decimal(19,4) NULL,
    [estado_incidente] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_BienIncidente_EstadoInc] DEFAULT ('ABIERTO'),
    [usuario_reporte_id] bigint NOT NULL,
    [fecha_cierre] datetime2(0) NULL,
    [usuario_cierre_id] bigint NULL,
    [solucion] nvarchar(700) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_BienIncidente_Estado] DEFAULT ((1))
);
CREATE TABLE [logistica].[BienInventario]
(
    [bien_inventario_id] bigint IDENTITY(1,1) NOT NULL,
    [empresa_id] bigint NOT NULL,
    [tipo_bien_id] smallint NOT NULL,
    [codigo_patrimonial] varchar(60) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(150) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [marca] nvarchar(80) COLLATE Modern_Spanish_CI_AS NULL,
    [modelo] nvarchar(80) COLLATE Modern_Spanish_CI_AS NULL,
    [serie] nvarchar(100) COLLATE Modern_Spanish_CI_AS NULL,
    [estado_bien] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_BienInventario_Estado] DEFAULT ((1)),
    [uot_id] bigint NOT NULL,
    [fecha_adquisicion] date NULL,
    [monto_adquisicion] decimal(19,4) NULL,
    [moneda_adquisicion] char(3) COLLATE Modern_Spanish_CI_AS NULL,
    [proveedor_persona_id] bigint NULL,
    [proveedor_empresa_id] bigint NULL,
    [observacion] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [logistica].[DetalleMovimientoInventario]
(
    [detalle_movimiento_inventario_id] bigint IDENTITY(1,1) NOT NULL,
    [movimiento_inventario_id] bigint NOT NULL,
    [producto_id] bigint NOT NULL,
    [cantidad] decimal(19,3) NOT NULL,
    [costo_unitario] decimal(19,4) NULL,
    [moneda] char(3) COLLATE Modern_Spanish_CI_AS NULL,
    [lote] varchar(80) COLLATE Modern_Spanish_CI_AS NULL,
    [fecha_vencimiento] date NULL
);
CREATE TABLE [logistica].[EntregaTecnica]
(
    [entrega_tecnica_id] bigint IDENTITY(1,1) NOT NULL,
    [uot_id] bigint NOT NULL,
    [almacen_id] bigint NOT NULL,
    [empleado_id] bigint NOT NULL,
    [usuario_entrega_id] bigint NOT NULL,
    [movimiento_inventario_id] bigint NULL,
    [clave_idempotencia] uniqueidentifier NOT NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF_EntregaTecnica_Fecha] DEFAULT (sysutcdatetime()),
    [motivo] nvarchar(300) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [observacion] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_EntregaTecnica_Estado] DEFAULT ((1))
);
CREATE TABLE [logistica].[EntregaTecnicaDetalle]
(
    [entrega_tecnica_detalle_id] bigint IDENTITY(1,1) NOT NULL,
    [entrega_tecnica_id] bigint NOT NULL,
    [producto_id] bigint NOT NULL,
    [cantidad] decimal(19,3) NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_EntregaTecnicaDetalle_Estado] DEFAULT ((1))
);
CREATE TABLE [logistica].[MovimientoInventario]
(
    [movimiento_inventario_id] bigint IDENTITY(1,1) NOT NULL,
    [almacen_id] bigint NOT NULL,
    [uot_id] bigint NOT NULL,
    [tipo_movimiento] varchar(25) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [naturaleza] char(1) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [movimiento_relacionado_id] bigint NULL,
    [proveedor_persona_id] bigint NULL,
    [proveedor_empresa_id] bigint NULL,
    [documento_referencia] nvarchar(120) COLLATE Modern_Spanish_CI_AS NULL,
    [clave_idempotencia] uniqueidentifier NOT NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF_MovInv_Fecha] DEFAULT (sysutcdatetime()),
    [usuario_id] bigint NOT NULL,
    [observacion] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_MovInv_Estado] DEFAULT ((1))
);
CREATE TABLE [logistica].[MovimientoInventarioLote]
(
    [asignacion_lote_id] bigint IDENTITY(1,1) NOT NULL,
    [detalle_movimiento_id] bigint NOT NULL,
    [detalle_origen_id] bigint NULL,
    [lote] varchar(80) COLLATE Modern_Spanish_CI_AS NULL,
    [fecha_vencimiento] date NULL,
    [cantidad] decimal(19,3) NOT NULL
);
CREATE TABLE [logistica].[Producto]
(
    [producto_id] bigint IDENTITY(1,1) NOT NULL,
    [codigo] varchar(50) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(180) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [descripcion] nvarchar(700) COLLATE Modern_Spanish_CI_AS NULL,
    [unidad_medida] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [categoria] nvarchar(100) COLLATE Modern_Spanish_CI_AS NULL,
    [requiere_lote] bit NOT NULL CONSTRAINT [DF_Producto_Lote] DEFAULT ((0)),
    [controla_vencimiento] bit NOT NULL CONSTRAINT [DF_Producto_Vencimiento] DEFAULT ((0)),
    [estado] bit NOT NULL CONSTRAINT [DF_Producto_Estado] DEFAULT ((1)),
    [fecha_creacion] datetime2(0) NOT NULL CONSTRAINT [DF_Producto_Fecha] DEFAULT (sysutcdatetime()),
    [clave_idempotencia] uniqueidentifier NULL,
    [permite_venta] bit NOT NULL CONSTRAINT [DF_Producto_PermiteVenta] DEFAULT ((0))
);
CREATE TABLE [logistica].[ProductoImagen]
(
    [producto_imagen_id] bigint IDENTITY(1,1) NOT NULL,
    [producto_id] bigint NOT NULL,
    [archivo_id] bigint NOT NULL,
    [es_principal] bit NOT NULL CONSTRAINT [DF_ProductoImagen_Principal] DEFAULT ((0)),
    [orden] smallint NOT NULL CONSTRAINT [DF_ProductoImagen_Orden] DEFAULT ((1)),
    [estado] bit NOT NULL CONSTRAINT [DF_ProductoImagen_Estado] DEFAULT ((1))
);
CREATE TABLE [logistica].[ProductoPrecio]
(
    [producto_precio_id] bigint IDENTITY(1,1) NOT NULL,
    [producto_id] bigint NOT NULL,
    [uot_id] bigint NULL,
    [precio_venta] decimal(19,4) NOT NULL,
    [moneda] char(3) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_ProductoPrecio_Moneda] DEFAULT ('PEN'),
    [version] int NOT NULL,
    [fecha_desde] datetime2(0) NOT NULL CONSTRAINT [DF_ProductoPrecio_Desde] DEFAULT (sysutcdatetime()),
    [fecha_hasta] datetime2(0) NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_ProductoPrecio_Estado] DEFAULT ((1)),
    [usuario_id] bigint NULL,
    [producto_precio_origen_id] bigint NULL,
    [clave_idempotencia] uniqueidentifier NULL,
    [precio_inicial] decimal(19,4) NOT NULL
);
CREATE TABLE [logistica].[ProductoUOTPolitica]
(
    [uot_id] bigint NOT NULL,
    [producto_id] bigint NOT NULL,
    [permite_venta] bit NOT NULL CONSTRAINT [DF_DESCO_PoliticaVenta] DEFAULT ((0)),
    [permite_uso_interno] bit NOT NULL CONSTRAINT [DF_DESCO_PoliticaUso] DEFAULT ((1)),
    [estado] bit NOT NULL CONSTRAINT [DF_DESCO_PoliticaEstado] DEFAULT ((1)),
    [usuario_actualizacion_id] bigint NULL,
    [fecha_actualizacion] datetime2(3) NOT NULL CONSTRAINT [DF_DESCO_PoliticaFecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [logistica].[ProgramacionProducto]
(
    [programacion_producto_id] bigint IDENTITY(1,1) NOT NULL,
    [uot_id] bigint NOT NULL,
    [almacen_id] bigint NOT NULL,
    [producto_id] bigint NOT NULL,
    [empleado_id] bigint NOT NULL,
    [cantidad_programada] decimal(19,3) NOT NULL,
    [cantidad_entregada] decimal(19,3) NOT NULL CONSTRAINT [DF_DESCO_PP_Entregada] DEFAULT ((0)),
    [cantidad_devuelta] decimal(19,3) NOT NULL CONSTRAINT [DF_DESCO_PP_Devuelta] DEFAULT ((0)),
    [cantidad_consumida] decimal(19,3) NOT NULL CONSTRAINT [DF_DESCO_PP_Consumida] DEFAULT ((0)),
    [estado_proceso] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_DESCO_PP_Estado] DEFAULT ('PENDIENTE'),
    [actividad] nvarchar(250) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [lugar_destino] nvarchar(300) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [fecha_inicio] datetime2(0) NOT NULL,
    [fecha_fin] datetime2(0) NULL,
    [observacion] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL,
    [archivo_autorizacion_id] bigint NULL,
    [usuario_solicitante_id] bigint NOT NULL,
    [usuario_aprobador_id] bigint NULL,
    [fecha_aprobacion] datetime2(0) NULL,
    [motivo_cierre] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [clave_idempotencia] uniqueidentifier NOT NULL,
    [fecha_creacion] datetime2(0) NOT NULL CONSTRAINT [DF_DESCO_PP_Fecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [logistica].[ProgramacionProductoEvento]
(
    [programacion_producto_evento_id] bigint IDENTITY(1,1) NOT NULL,
    [programacion_producto_id] bigint NOT NULL,
    [tipo_evento] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [cantidad] decimal(19,3) NULL,
    [movimiento_inventario_id] bigint NULL,
    [usuario_id] bigint NOT NULL,
    [clave_idempotencia] uniqueidentifier NOT NULL,
    [observacion] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF_DESCO_PPEvento_Fecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [logistica].[RecursoMovimiento]
(
    [recurso_movimiento_id] bigint IDENTITY(1,1) NOT NULL,
    [recurso_programado_id] bigint NOT NULL,
    [tipo_movimiento] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [cantidad] decimal(14,3) NOT NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF_RecursoMovimiento_Fecha] DEFAULT (sysutcdatetime()),
    [usuario_id] bigint NOT NULL,
    [observacion] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_RecursoMovimiento_Estado] DEFAULT ((1))
);
CREATE TABLE [logistica].[RecursoProgramado]
(
    [recurso_programado_id] bigint IDENTITY(1,1) NOT NULL,
    [campania_venta_id] bigint NULL,
    [operativo_venta_id] bigint NULL,
    [salida_campo_id] bigint NULL,
    [bien_inventario_id] bigint NULL,
    [suministro_id] bigint NULL,
    [cantidad_programada] decimal(14,3) NOT NULL,
    [observacion] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_RecursoProgramado_Estado] DEFAULT ((1)),
    [estado_proceso] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_RecursoProgramado_EstadoProceso] DEFAULT ('PROGRAMADO'),
    [usuario_programacion_id] bigint NULL,
    [fecha_programacion] datetime2(0) NULL CONSTRAINT [DF_RecursoProgramado_FechaProgramacion] DEFAULT (sysutcdatetime()),
    [fecha_cancelacion] datetime2(0) NULL,
    [usuario_cancelacion_id] bigint NULL,
    [motivo_cancelacion] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [cantidad_entregada] decimal(19,3) NOT NULL CONSTRAINT [DF_DESCO_Recurso_Entregado] DEFAULT ((0)),
    [cantidad_devuelta] decimal(19,3) NOT NULL CONSTRAINT [DF_DESCO_Recurso_Devuelto] DEFAULT ((0)),
    [cantidad_consumida] decimal(19,3) NOT NULL CONSTRAINT [DF_DESCO_Recurso_Consumido] DEFAULT ((0)),
    [cantidad_pendiente] AS (([cantidad_entregada]-[cantidad_devuelta])-[cantidad_consumida]) PERSISTED
);
CREATE TABLE [logistica].[RecursoProgramadoArchivo]
(
    [recurso_programado_id] bigint NOT NULL,
    [archivo_id] bigint NOT NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_vinculo] datetime2(0) NOT NULL CONSTRAINT [DF_DESCO_RPArchivo_Fecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [logistica].[ReservaStock]
(
    [reserva_stock_id] bigint IDENTITY(1,1) NOT NULL,
    [detalle_venta_id] bigint NOT NULL,
    [almacen_id] bigint NOT NULL,
    [producto_id] bigint NOT NULL,
    [cantidad] decimal(19,3) NOT NULL,
    [fecha_reserva] datetime2(0) NOT NULL CONSTRAINT [DF_ReservaStock_Fecha] DEFAULT (sysutcdatetime()),
    [fecha_expiracion] datetime2(0) NULL,
    [estado_reserva] varchar(15) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [fecha_liberacion] datetime2(0) NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_ReservaStock_Estado] DEFAULT ((1))
);
CREATE TABLE [logistica].[SalidaBien]
(
    [salida_bien_id] bigint IDENTITY(1,1) NOT NULL,
    [salida_campo_id] bigint NOT NULL,
    [bien_inventario_id] bigint NOT NULL,
    [fecha_hora_entrega] datetime2(0) NOT NULL,
    [fecha_hora_devolucion] datetime2(0) NULL,
    [estado_entrega] nvarchar(200) COLLATE Modern_Spanish_CI_AS NULL,
    [estado_devolucion] nvarchar(200) COLLATE Modern_Spanish_CI_AS NULL,
    [observacion] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_SalidaBien_Estado] DEFAULT ((1))
);
CREATE TABLE [logistica].[Suministro]
(
    [suministro_id] bigint IDENTITY(1,1) NOT NULL,
    [codigo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(150) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [unidad_medida] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_Suministro_Estado] DEFAULT ((1)),
    [stock_minimo] decimal(19,3) NOT NULL CONSTRAINT [DF_DESCO_Suministro_Minimo] DEFAULT ((0)),
    [uot_id] bigint NOT NULL
);
CREATE TABLE [logistica].[SuministroMovimiento]
(
    [suministro_movimiento_id] bigint IDENTITY(1,1) NOT NULL,
    [suministro_id] bigint NOT NULL,
    [recurso_programado_id] bigint NULL,
    [tipo_movimiento] varchar(25) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [cantidad] decimal(14,3) NOT NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF_SuministroMovimiento_Fecha] DEFAULT (sysutcdatetime()),
    [usuario_id] bigint NOT NULL,
    [documento_referencia] nvarchar(120) COLLATE Modern_Spanish_CI_AS NULL,
    [observacion] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_SuministroMovimiento_Estado] DEFAULT ((1)),
    [recurso_movimiento_id] bigint NULL,
    [movimiento_origen_id] bigint NULL,
    [uot_id] bigint NULL,
    [movimiento_anulado_id] bigint NULL
);
CREATE TABLE [logistica].[SuministroSaldo]
(
    [suministro_id] bigint NOT NULL,
    [stock_actual] decimal(19,3) NOT NULL CONSTRAINT [DF_DESCO_Saldo_Actual] DEFAULT ((0)),
    [stock_reservado] decimal(19,3) NOT NULL CONSTRAINT [DF_DESCO_Saldo_Reservado] DEFAULT ((0)),
    [stock_disponible] AS ([stock_actual]-[stock_reservado]) PERSISTED,
    [fecha_actualizacion] datetime2(3) NOT NULL CONSTRAINT [DF_DESCO_Saldo_Fecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [logistica].[SuministroSaldoConciliacion]
(
    [conciliacion_id] bigint IDENTITY(1,1) NOT NULL,
    [suministro_id] bigint NOT NULL,
    [saldo_anterior] decimal(19,3) NOT NULL,
    [saldo_kardex] decimal(19,3) NOT NULL,
    [fecha] datetime2(7) NOT NULL CONSTRAINT [DF__Suministr__fecha__5319221E] DEFAULT (sysutcdatetime())
);
CREATE TABLE [logistica].[TipoBien]
(
    [tipo_bien_id] smallint IDENTITY(1,1) NOT NULL,
    [codigo] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(100) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_TipoBien_Estado] DEFAULT ((1))
);
CREATE TABLE [logistica].[TransferenciaAlmacen]
(
    [transferencia_almacen_id] bigint IDENTITY(1,1) NOT NULL,
    [almacen_origen_id] bigint NOT NULL,
    [almacen_destino_id] bigint NOT NULL,
    [uot_origen_id] bigint NOT NULL,
    [uot_destino_id] bigint NOT NULL,
    [movimiento_salida_id] bigint NOT NULL,
    [movimiento_entrada_id] bigint NOT NULL,
    [clave_idempotencia] uniqueidentifier NOT NULL,
    [detalle_sha256] varbinary(32) NOT NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF_DESCO_TransferFecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [logistica].[UsoProductoTecnico]
(
    [tipo_origen] varchar(16) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [registro_id] bigint NOT NULL,
    [programacion_producto_id] bigint NOT NULL,
    [evento_id] bigint NOT NULL,
    [cantidad] decimal(19,3) NOT NULL
);
CREATE TABLE [logistica].[Vehiculo]
(
    [vehiculo_id] bigint NOT NULL,
    [placa] varchar(12) COLLATE Modern_Spanish_CI_AS NULL,
    [tipo_vehiculo] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [kilometraje_km] decimal(12,1) NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_Vehiculo_Estado] DEFAULT ((1)),
    [color] nvarchar(50) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [org].[Area]
(
    [area_id] bigint IDENTITY(1,1) NOT NULL,
    [empresa_id] bigint NULL,
    [area_padre_id] bigint NULL,
    [codigo] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(120) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_Area_Estado] DEFAULT ((1)),
    [uot_id] bigint NOT NULL
);
CREATE TABLE [org].[Asociacion]
(
    [asociacion_id] bigint NOT NULL,
    [fecha_constitucion] date NULL,
    [numero_partida] varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_Asociacion_Estado] DEFAULT ((1)),
    [uot_id] bigint NOT NULL
);
CREATE TABLE [org].[ConvenioModuloEspecial]
(
    [convenio_modulo_especial_id] bigint IDENTITY(1,1) NOT NULL,
    [convenio_uot_organizacion_id] bigint NOT NULL,
    [modulo_especial_id] int NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_ConvenioModuloEspecial_Estado] DEFAULT ((0)),
    [fecha_modificacion] datetime2(0) NOT NULL CONSTRAINT [DF_ConvenioModuloEspecial_Fecha] DEFAULT (sysutcdatetime()),
    [usuario_modificacion_id] bigint NULL
);
CREATE TABLE [org].[ConvenioUOTOrganizacion]
(
    [convenio_uot_organizacion_id] bigint IDENTITY(1,1) NOT NULL,
    [uot_id] bigint NOT NULL,
    [empresa_id] bigint NOT NULL,
    [tipo_vinculo] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [numero_convenio] varchar(80) COLLATE Modern_Spanish_CI_AS NULL,
    [fecha_inicio] date NULL,
    [fecha_fin] date NULL,
    [descripcion] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_ConvenioUOT_Estado] DEFAULT ((1)),
    [fecha_creacion] datetime2(0) NOT NULL CONSTRAINT [DF_ConvenioUOT_Fecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [org].[Empleado]
(
    [empleado_id] bigint NOT NULL,
    [empresa_id] bigint NULL,
    [codigo_empleado] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [fecha_ingreso] date NOT NULL,
    [fecha_cese] date NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_Empleado_Estado] DEFAULT ((1))
);
CREATE TABLE [org].[EmpleadoArea]
(
    [empleado_area_id] bigint IDENTITY(1,1) NOT NULL,
    [empleado_id] bigint NOT NULL,
    [area_id] bigint NOT NULL,
    [cargo] nvarchar(120) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [fecha_desde] date NOT NULL,
    [fecha_hasta] date NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_EmpleadoArea_Estado] DEFAULT ((1))
);
CREATE TABLE [org].[EmpleadoUOT]
(
    [empleado_uot_id] bigint IDENTITY(1,1) NOT NULL,
    [empleado_id] bigint NOT NULL,
    [uot_id] bigint NOT NULL,
    [es_principal] bit NOT NULL CONSTRAINT [DF_EmpleadoUOT_Principal] DEFAULT ((0)),
    [fecha_desde] date NOT NULL,
    [fecha_hasta] date NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_EmpleadoUOT_Estado] DEFAULT ((1)),
    [codigo_empleado] varchar(30) COLLATE Modern_Spanish_CI_AS NULL,
    [fecha_ingreso] date NULL,
    [fecha_cese] date NULL
);
CREATE TABLE [org].[Empresa]
(
    [empresa_id] bigint IDENTITY(1,1) NOT NULL,
    [ruc] char(11) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [razon_social] nvarchar(200) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre_comercial] nvarchar(160) COLLATE Modern_Spanish_CI_AS NULL,
    [telefono] varchar(30) COLLATE Modern_Spanish_CI_AS NULL,
    [correo] varchar(180) COLLATE Modern_Spanish_CI_AS NULL,
    [ubicacion_id] bigint NULL,
    [fecha_creacion] datetime2(0) NOT NULL CONSTRAINT [DF_Empresa_FechaCreacion] DEFAULT (sysutcdatetime()),
    [estado] bit NOT NULL CONSTRAINT [DF_Empresa_Estado] DEFAULT ((1)),
    [tipo_contribuyente] nvarchar(120) COLLATE Modern_Spanish_CI_AS NULL,
    [estado_sunat] varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
    [condicion_sunat] varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
    [correo_clave_desco] AS ((lower(ltrim(rtrim([correo])))) collate Latin1_General_100_CI_AS) PERSISTED
);
CREATE TABLE [org].[Persona]
(
    [persona_id] bigint IDENTITY(1,1) NOT NULL,
    [tipo_documento] varchar(15) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [numero_documento] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombres] nvarchar(100) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [apellido_paterno] nvarchar(80) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [apellido_materno] nvarchar(80) COLLATE Modern_Spanish_CI_AS NULL,
    [telefono] varchar(30) COLLATE Modern_Spanish_CI_AS NULL,
    [correo] varchar(180) COLLATE Modern_Spanish_CI_AS NULL,
    [fecha_nacimiento] date NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_Persona_Estado] DEFAULT ((1)),
    [fecha_creacion] datetime2(0) NOT NULL CONSTRAINT [DF_Persona_FechaCreacion] DEFAULT (sysutcdatetime()),
    [ubicacion_id] bigint NULL,
    [tipo_persona] varchar(12) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_Persona_TipoPersona] DEFAULT ('NATURAL'),
    [sexo] varchar(20) COLLATE Modern_Spanish_CI_AS NULL,
    [documento_clave_desco] AS ((CONVERT([varchar](50),case when upper(ltrim(rtrim([tipo_documento])))='DNI' then 'DNI:'+ltrim(rtrim([numero_documento])) when upper(ltrim(rtrim([tipo_documento])))='RUC' AND left(ltrim(rtrim([numero_documento])),(2))='10' AND len(ltrim(rtrim([numero_documento])))=(11) then 'DNI:'+substring(ltrim(rtrim([numero_documento])),(3),(8)) else (upper(ltrim(rtrim([tipo_documento])))+':')+upper(ltrim(rtrim([numero_documento]))) end)) collate Latin1_General_100_CI_AS) PERSISTED,
    [correo_clave_desco] AS ((lower(ltrim(rtrim([correo])))) collate Latin1_General_100_CI_AS) PERSISTED
);
CREATE TABLE [org].[Productor]
(
    [persona_id] bigint NOT NULL,
    [fecha_alta] date NOT NULL CONSTRAINT [DF_E1_ProductorFechaAlta] DEFAULT (CONVERT([date],sysutcdatetime())),
    [estado] bit NOT NULL CONSTRAINT [DF_E1_ProductorEstado] DEFAULT ((1)),
    [usuario_creacion_id] bigint NULL,
    [fecha_creacion] datetime2(0) NOT NULL CONSTRAINT [DF_E1_ProductorFechaCreacion] DEFAULT (sysutcdatetime()),
    [version_fila] timestamp NOT NULL
);
CREATE TABLE [org].[ProductorUOT]
(
    [productor_uot_id] bigint IDENTITY(1,1) NOT NULL,
    [persona_id] bigint NOT NULL,
    [uot_id] bigint NOT NULL,
    [fecha_desde] date NOT NULL CONSTRAINT [DF_E1_ProductorUOTDesde] DEFAULT (CONVERT([date],sysutcdatetime())),
    [fecha_hasta] date NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_E1_ProductorUOTEstado] DEFAULT ((1)),
    [usuario_creacion_id] bigint NULL,
    [fecha_creacion] datetime2(0) NOT NULL CONSTRAINT [DF_E1_ProductorUOTCreacion] DEFAULT (sysutcdatetime()),
    [version_fila] timestamp NOT NULL
);
CREATE TABLE [org].[Socio]
(
    [socio_id] bigint NOT NULL,
    [fecha_alta] date NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_Socio_Estado] DEFAULT ((1))
);
CREATE TABLE [org].[SocioAsociacion]
(
    [socio_asociacion_id] bigint IDENTITY(1,1) NOT NULL,
    [socio_id] bigint NOT NULL,
    [asociacion_id] bigint NOT NULL,
    [codigo_socio] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [fecha_desde] date NOT NULL,
    [fecha_hasta] date NULL,
    [situacion_membresia] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_SocioAsociacion_Estado] DEFAULT ((1))
);
CREATE TABLE [org].[UOT]
(
    [uot_id] bigint IDENTITY(1,1) NOT NULL,
    [uot_padre_id] bigint NULL,
    [empresa_legacy_id] bigint NULL,
    [ubicacion_id] bigint NULL,
    [codigo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(160) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [descripcion] nvarchar(400) COLLATE Modern_Spanish_CI_AS NULL,
    [es_raiz] bit NOT NULL CONSTRAINT [DF_UOT_EsRaiz] DEFAULT ((0)),
    [fecha_inicio] date NULL,
    [fecha_fin] date NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_UOT_Estado] DEFAULT ((1)),
    [fecha_creacion] datetime2(0) NOT NULL CONSTRAINT [DF_UOT_FechaCreacion] DEFAULT (sysutcdatetime())
);
CREATE TABLE [prod].[CensoPlantas]
(
    [censo_plantas_id] bigint IDENTITY(1,1) NOT NULL,
    [parcela_cultivo_id] bigint NOT NULL,
    [fecha_censo] date NOT NULL,
    [plantas_totales] int NOT NULL,
    [plantas_productivas] int NOT NULL,
    [plantas_no_productivas] int NOT NULL,
    [plantas_nuevas] int NOT NULL CONSTRAINT [DF_CensoPlantas_Nuevas] DEFAULT ((0)),
    [plantas_muertas] int NOT NULL CONSTRAINT [DF_CensoPlantas_Muertas] DEFAULT ((0)),
    [plantas_afectadas] int NOT NULL CONSTRAINT [DF_CensoPlantas_Afectadas] DEFAULT ((0)),
    [observacion] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_CensoPlantas_Estado] DEFAULT ((1))
);
CREATE TABLE [prod].[CrianzaConteo]
(
    [crianza_conteo_id] bigint IDENTITY(1,1) NOT NULL,
    [crianza_lote_id] bigint NOT NULL,
    [cantidad] int NULL,
    [fecha_observacion] date NOT NULL,
    [observacion] nvarchar(1000) COLLATE Modern_Spanish_CI_AS NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF__CrianzaCo__fecha__4D755761] DEFAULT (sysutcdatetime())
);
CREATE TABLE [prod].[CrianzaLote]
(
    [crianza_lote_id] bigint IDENTITY(1,1) NOT NULL,
    [predio_id] bigint NOT NULL,
    [especie_pecuaria_id] int NOT NULL,
    [nombre] nvarchar(100) COLLATE Modern_Spanish_CI_AS NULL,
    [fecha_inicio] date NOT NULL CONSTRAINT [DF_E1_LoteFecha] DEFAULT (CONVERT([date],sysutcdatetime())),
    [fecha_fin] date NULL,
    [estado] bit NOT NULL CONSTRAINT [DF__CrianzaLo__estad__47BC7E0B] DEFAULT ((1))
);
CREATE TABLE [prod].[Cultivo]
(
    [cultivo_id] int IDENTITY(1,1) NOT NULL,
    [codigo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(120) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_Cultivo_Estado] DEFAULT ((1)),
    [descripcion] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [prod].[DisponibilidadProduccion]
(
    [disponibilidad_produccion_id] bigint IDENTITY(1,1) NOT NULL,
    [parcela_cultivo_id] bigint NOT NULL,
    [visita_tecnica_id] bigint NULL,
    [fecha_estimacion] datetime2(0) NOT NULL,
    [disponible_desde] date NOT NULL,
    [disponible_hasta] date NULL,
    [cantidad_estimada_kg] decimal(14,3) NOT NULL,
    [estado_estimacion] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [observacion] nvarchar(400) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_DisponibilidadProduccion_Estado] DEFAULT ((1))
);
CREATE TABLE [prod].[EspeciePecuaria]
(
    [especie_pecuaria_id] int IDENTITY(1,1) NOT NULL,
    [codigo] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(90) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF__EspeciePe__estad__4203A4B5] DEFAULT ((1)),
    [descripcion] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [prod].[ExpedienteActuacion]
(
    [expediente_actuacion_id] bigint IDENTITY(1,1) NOT NULL,
    [predio_id] bigint NOT NULL,
    [uot_id] bigint NOT NULL,
    [convenio_uot_organizacion_id] bigint NULL,
    [parcela_cultivo_id] bigint NULL,
    [crianza_lote_id] bigint NULL,
    [tipo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [observacion] nvarchar(2000) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [fecha_hecho] datetime2(0) NOT NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF__Expedient__fecha__560A9D62] DEFAULT (sysutcdatetime()),
    [usuario_id] bigint NOT NULL,
    [salida_campo_id] bigint NULL,
    [visita_tecnica_id] bigint NULL,
    [correlacion_id] uniqueidentifier NULL
);
CREATE TABLE [prod].[FundoAccionHistorial]
(
    [historial_id] bigint IDENTITY(1,1) NOT NULL,
    [predio_id] bigint NOT NULL,
    [convenio_id] bigint NOT NULL,
    [accion] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [motivo] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF_FundoAccionHistorial_Fecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [prod].[FundoAccionSolicitud]
(
    [usuario_id] bigint NOT NULL,
    [clave] uniqueidentifier NOT NULL,
    [tipo] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [hash_peticion] varbinary(32) NOT NULL,
    [respuesta] nvarchar(MAX) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF_FundoAccionSolicitud_Fecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [prod].[FundoHabilitacion]
(
    [predio_id] bigint NOT NULL,
    [convenio_id] bigint NOT NULL,
    [uot_id] bigint NOT NULL,
    [habilitado] bit NOT NULL CONSTRAINT [DF_FundoHabilitacion_Habilitado] DEFAULT ((0)),
    [version] bigint NOT NULL CONSTRAINT [DF_FundoHabilitacion_Version] DEFAULT ((1)),
    [usuario_id] bigint NOT NULL,
    [actualizado_en] datetime2(0) NOT NULL CONSTRAINT [DF_FundoHabilitacion_Fecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [prod].[FundoProduccionE3]
(
    [fundo_produccion_id] bigint IDENTITY(1,1) NOT NULL,
    [predio_id] bigint NOT NULL,
    [uot_id] bigint NOT NULL,
    [convenio_id] bigint NOT NULL,
    [anio] smallint NOT NULL,
    [fecha_desde] date NOT NULL,
    [fecha_hasta] date NOT NULL,
    [estado_produccion] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [cantidad_disponible_kg] decimal(14,3) NOT NULL,
    [observacion] nvarchar(400) COLLATE Modern_Spanish_CI_AS NULL,
    [usuario_id] bigint NOT NULL,
    [actualizado_en] datetime2(0) NOT NULL CONSTRAINT [DF_FundoProduccionE3_Actualizado] DEFAULT (sysutcdatetime()),
    [version] bigint NOT NULL CONSTRAINT [DF_FundoProduccionE3_Version] DEFAULT ((1))
);
CREATE TABLE [prod].[FundoProduccionHistorialE3]
(
    [historial_id] bigint IDENTITY(1,1) NOT NULL,
    [fundo_produccion_id] bigint NOT NULL,
    [anterior] nvarchar(MAX) COLLATE Modern_Spanish_CI_AS NULL,
    [nuevo] nvarchar(MAX) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF_FundoProduccionHistorialE3_Fecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [prod].[FundoProduccionSolicitudE3]
(
    [solicitud_id] bigint IDENTITY(1,1) NOT NULL,
    [usuario_id] bigint NOT NULL,
    [clave] uniqueidentifier NOT NULL,
    [hash_peticion] varbinary(32) NOT NULL,
    [respuesta] nvarchar(MAX) COLLATE Modern_Spanish_CI_AS NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF_FundoProduccionSolicitudE3_Fecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [prod].[GPActividad]
(
    [actividad_id] bigint IDENTITY(1,1) NOT NULL,
    [parcela_id] bigint NOT NULL,
    [predio_id] bigint NOT NULL,
    [uot_id] bigint NOT NULL,
    [rubro] varchar(8) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [cultivo_id] int NULL,
    [especie_pecuaria_id] int NULL,
    [nombre] nvarchar(120) COLLATE Modern_Spanish_CI_AS NULL,
    [fecha_inicio] date NOT NULL CONSTRAINT [DF__GPActivid__fecha__7E6D9477] DEFAULT (CONVERT([date],sysutcdatetime())),
    [estado] bit NOT NULL CONSTRAINT [DF__GPActivid__estad__7F61B8B0] DEFAULT ((1)),
    [usuario_creacion_id] bigint NOT NULL,
    [fecha_creacion] datetime2(0) NOT NULL CONSTRAINT [DF__GPActivid__fecha__014A0122] DEFAULT (sysutcdatetime()),
    [solicitud_id] uniqueidentifier NOT NULL,
    [variedad_cultivo_id] bigint NULL,
    [estado_proceso] varchar(15) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_GPActividad_EstadoProceso] DEFAULT ('ACTIVA')
);
CREATE TABLE [prod].[GPActividadRevision]
(
    [revision_id] bigint IDENTITY(1,1) NOT NULL,
    [actividad_id] bigint NOT NULL,
    [nombre_anterior] nvarchar(120) COLLATE Modern_Spanish_CI_AS NULL,
    [nombre_nuevo] nvarchar(120) COLLATE Modern_Spanish_CI_AS NULL,
    [estado_anterior] bit NOT NULL,
    [estado_nuevo] bit NOT NULL,
    [motivo] nvarchar(1000) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF__GPActivid__fecha__5071BF9D] DEFAULT (sysutcdatetime()),
    [solicitud_id] uniqueidentifier NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_GPActividadRevision_Estado] DEFAULT ((1))
);
CREATE TABLE [prod].[GPBajaLogica]
(
    [baja_id] bigint IDENTITY(1,1) NOT NULL,
    [tipo] varchar(12) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [registro_id] bigint NOT NULL,
    [motivo] nvarchar(1000) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [usuario_id] bigint NOT NULL,
    [fecha] datetime2(0) NOT NULL CONSTRAINT [DF__GPBajaLog__fecha__0D7ACDDD] DEFAULT (sysutcdatetime()),
    [solicitud_id] uniqueidentifier NOT NULL
);
CREATE TABLE [prod].[GPCenso]
(
    [censo_id] bigint IDENTITY(1,1) NOT NULL,
    [actividad_id] bigint NOT NULL,
    [cantidad] int NULL,
    [aproximado] bit NULL,
    [fecha] date NOT NULL,
    [observacion] nvarchar(1000) COLLATE Modern_Spanish_CI_AS NULL,
    [usuario_creacion_id] bigint NOT NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF__GPCenso__fecha_r__08EB22EA] DEFAULT (sysutcdatetime()),
    [solicitud_id] uniqueidentifier NOT NULL,
    [cantidad_aproximada] int NULL,
    [cantidad_exacta] int NULL,
    [superficie_aproximada_m2] decimal(14,2) NULL,
    [superficie_exacta_m2] decimal(14,2) NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_GPCenso_Estado] DEFAULT ((1))
);
CREATE TABLE [prod].[GPCensoRaza]
(
    [censo_id] bigint NOT NULL,
    [raza_id] int NOT NULL,
    [cantidad_aproximada] int NULL,
    [cantidad_exacta] int NULL
);
CREATE TABLE [prod].[GPCensoVariedad]
(
    [censo_id] bigint NOT NULL,
    [variedad_cultivo_id] bigint NOT NULL,
    [superficie_m2] decimal(14,2) NOT NULL
);
CREATE TABLE [prod].[GPEvento]
(
    [evento_id] bigint IDENTITY(1,1) NOT NULL,
    [actividad_id] bigint NOT NULL,
    [tipo] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [problema_id] int NULL,
    [tratamiento_id] int NULL,
    [respuesta_a_id] bigint NULL,
    [observacion] nvarchar(2000) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [fecha_hecho] datetime2(0) NOT NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF__GPEvento__fecha___1EDA6409] DEFAULT (sysutcdatetime()),
    [usuario_creacion_id] bigint NOT NULL,
    [visita_id] bigint NULL,
    [solicitud_id] uniqueidentifier NOT NULL,
    [cantidad_afectada] int NULL,
    [afectados_aproximado] bit NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_GPEvento_Estado] DEFAULT ((1))
);
CREATE TABLE [prod].[GPEventoFoto]
(
    [foto_id] bigint IDENTITY(1,1) NOT NULL,
    [evento_id] bigint NOT NULL,
    [archivo_interno] varchar(65) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [mime_type] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [tamano_bytes] bigint NOT NULL,
    [usuario_creacion_id] bigint NOT NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF__GPEventoF__fecha__35BDC961] DEFAULT (sysutcdatetime())
);
CREATE TABLE [prod].[GPIncidencia]
(
    [incidencia_id] bigint NOT NULL,
    [actividad_id] bigint NOT NULL,
    [problema_id] int NOT NULL,
    [afectada_m2] decimal(14,2) NULL,
    [afectados_animales] int NULL,
    [estado] bit NOT NULL CONSTRAINT [DF__GPInciden__estad__7973D530] DEFAULT ((1)),
    [estado_seguimiento] varchar(12) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF__GPInciden__estad__7A67F969] DEFAULT ('ABIERTA'),
    [resultado] varchar(18) COLLATE Modern_Spanish_CI_AS NULL,
    [perdida_m2] decimal(14,2) NULL,
    [perdidos_animales] int NULL,
    [descripcion_cierre] nvarchar(2000) COLLATE Modern_Spanish_CI_AS NULL,
    [fecha_cierre] datetime2(0) NULL,
    [usuario_cierre_id] bigint NULL,
    [solicitud_cierre] uniqueidentifier NULL
);
CREATE TABLE [prod].[GPIncidenciaRevision]
(
    [revision_id] bigint IDENTITY(1,1) NOT NULL,
    [incidencia_id] bigint NOT NULL,
    [accion] varchar(12) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [motivo] nvarchar(1000) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF_GPIncidenciaRevision_Fecha] DEFAULT (sysutcdatetime()),
    [problema_anterior] int NOT NULL,
    [problema_nuevo] int NOT NULL,
    [afectada_anterior] decimal(14,2) NULL,
    [afectada_nueva] decimal(14,2) NULL,
    [animales_anteriores] int NULL,
    [animales_nuevos] int NULL,
    [descripcion_anterior] nvarchar(2000) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [descripcion_nueva] nvarchar(2000) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [solicitud_id] uniqueidentifier NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_GPIncidenciaRevision_Estado] DEFAULT ((1))
);
CREATE TABLE [prod].[GPIncidenciaTratamiento]
(
    [evento_id] bigint NOT NULL,
    [incidencia_id] bigint NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF__GPInciden__estad__03F163A3] DEFAULT ((1)),
    [tratamiento_id] int NOT NULL,
    [fecha_inicio] datetime2(0) NOT NULL CONSTRAINT [DF__GPInciden__fecha__05D9AC15] DEFAULT (sysutcdatetime()),
    [fecha_fin_prevista] datetime2(0) NULL,
    [fecha_fin_real] datetime2(0) NULL,
    [descripcion_cierre] nvarchar(1000) COLLATE Modern_Spanish_CI_AS NULL,
    [usuario_cierre_id] bigint NULL,
    [solicitud_cierre] uniqueidentifier NULL
);
CREATE TABLE [prod].[GPParcelaSolicitud]
(
    [solicitud_id] uniqueidentifier NOT NULL,
    [parcela_id] bigint NOT NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF__GPParcela__fecha__4317C47F] DEFAULT (sysutcdatetime())
);
CREATE TABLE [prod].[GPProblema]
(
    [problema_id] int IDENTITY(1,1) NOT NULL,
    [cultivo_id] int NULL,
    [especie_pecuaria_id] int NULL,
    [nombre] nvarchar(160) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF__GPProblem__estad__0EA3FC40] DEFAULT ((1))
);
CREATE TABLE [prod].[GPProblemaTratamiento]
(
    [problema_id] int NOT NULL,
    [tratamiento_id] int NOT NULL
);
CREATE TABLE [prod].[GPRaza]
(
    [raza_id] int IDENTITY(1,1) NOT NULL,
    [especie_pecuaria_id] int NOT NULL,
    [nombre] nvarchar(120) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_GPRaza_Estado] DEFAULT ((1)),
    [usuario_creacion_id] bigint NOT NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF_GPRaza_Registro] DEFAULT (sysutcdatetime()),
    [descripcion] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [prod].[GPTratamiento]
(
    [tratamiento_id] int IDENTITY(1,1) NOT NULL,
    [nombre] nvarchar(160) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [descripcion] nvarchar(1000) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF__GPTratami__estad__12748D24] DEFAULT ((1))
);
CREATE TABLE [prod].[Parcela]
(
    [parcela_id] bigint IDENTITY(1,1) NOT NULL,
    [predio_id] bigint NOT NULL,
    [codigo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(120) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [area_ha] decimal(10,4) NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_Parcela_Estado] DEFAULT ((1)),
    [ubicacion_id] bigint NULL
);
CREATE TABLE [prod].[ParcelaCultivo]
(
    [parcela_cultivo_id] bigint IDENTITY(1,1) NOT NULL,
    [parcela_id] bigint NOT NULL,
    [variedad_palta_id] smallint NULL,
    [fecha_inicio] date NOT NULL,
    [fecha_fin] date NULL,
    [situacion_cultivo] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_ParcelaCultivo_Estado] DEFAULT ((1)),
    [variedad_cultivo_id] bigint NULL,
    [cultivo_id] int NULL
);
CREATE TABLE [prod].[PlantaComentarioE3]
(
    [comentario_id] bigint IDENTITY(1,1) NOT NULL,
    [planta_id] bigint NOT NULL,
    [comentario] nvarchar(1500) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [usuario_id] bigint NOT NULL,
    [creado_en] datetime2(0) NOT NULL CONSTRAINT [DF_E3_ComentarioFecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [prod].[PlantaCorrelativoE3]
(
    [predio_id] bigint NOT NULL,
    [variedad_palta_id] smallint NOT NULL,
    [ultimo] int NOT NULL
);
CREATE TABLE [prod].[PlantaEventoE3]
(
    [evento_id] bigint IDENTITY(1,1) NOT NULL,
    [planta_id] bigint NOT NULL,
    [tipo] varchar(25) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado_anterior] varchar(16) COLLATE Modern_Spanish_CI_AS NULL,
    [estado_nuevo] varchar(16) COLLATE Modern_Spanish_CI_AS NULL,
    [observacion] nvarchar(1000) COLLATE Modern_Spanish_CI_AS NULL,
    [visita_tecnica_id] bigint NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_hecho] datetime2(0) NOT NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF__PlantaEve__fecha__271AA44F] DEFAULT (sysutcdatetime()),
    [correlacion_id] uniqueidentifier NULL
);
CREATE TABLE [prod].[PlantaEvidenciaE3]
(
    [planta_evidencia_id] bigint IDENTITY(1,1) NOT NULL,
    [planta_id] bigint NOT NULL,
    [archivo_id] bigint NOT NULL,
    [evento_id] bigint NULL,
    [tipo] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [usuario_id] bigint NOT NULL,
    [fecha] datetime2(0) NOT NULL CONSTRAINT [DF__PlantaEvi__fecha__42C2BEC4] DEFAULT (sysutcdatetime())
);
CREATE TABLE [prod].[PlantaFichaHistorialE3]
(
    [ficha_id] bigint IDENTITY(1,1) NOT NULL,
    [planta_id] bigint NOT NULL,
    [fecha_plantacion] date NULL,
    [edad_referencia_anios] smallint NULL,
    [fecha_referencia] date NULL,
    [version] bigint NOT NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF__PlantaFic__fecha__22DFFF17] DEFAULT (sysutcdatetime())
);
CREATE TABLE [prod].[PlantaMateriaSecaIndividualE4]
(
    [medicion_id] bigint IDENTITY(1,1) NOT NULL,
    [planta_id] bigint NOT NULL,
    [fecha_muestreo] date NOT NULL,
    [porcentaje] decimal(6,3) NOT NULL,
    [informe] nvarchar(2000) COLLATE Modern_Spanish_CI_AS NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF_E4_SecaIndividualFecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [prod].[PlantaMedicionE3]
(
    [medicion_id] bigint IDENTITY(1,1) NOT NULL,
    [planta_id] bigint NOT NULL,
    [visita_tecnica_id] bigint NOT NULL,
    [porcentaje] decimal(6,3) NOT NULL,
    [observacion] nvarchar(1000) COLLATE Modern_Spanish_CI_AS NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_hecho] datetime2(0) NOT NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF__PlantaMed__fecha__1F44785D] DEFAULT (sysutcdatetime())
);
CREATE TABLE [prod].[PlantaPaltaE3]
(
    [planta_id] bigint IDENTITY(1,1) NOT NULL,
    [predio_id] bigint NOT NULL,
    [uot_id] bigint NOT NULL,
    [convenio_id] bigint NOT NULL,
    [variedad_palta_id] smallint NOT NULL,
    [parcela_cultivo_id] bigint NULL,
    [secuencia] int NOT NULL,
    [codigo] varchar(80) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado_actual] varchar(16) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_E3_PlantaEstado] DEFAULT ('SANA'),
    [fecha_plantacion] date NULL,
    [edad_referencia_anios] smallint NULL,
    [fecha_referencia] date NULL,
    [creado_por_usuario_id] bigint NOT NULL,
    [creado_en] datetime2(0) NOT NULL CONSTRAINT [DF_E3_PlantaFecha] DEFAULT (sysutcdatetime()),
    [version] bigint NOT NULL CONSTRAINT [DF_E3_PlantaVersion] DEFAULT ((0)),
    [socio_id] bigint NULL,
    [activo] bit NOT NULL CONSTRAINT [DF_E3_PlantaActivo] DEFAULT ((1))
);
CREATE TABLE [prod].[PlantaSolicitudE3]
(
    [usuario_id] bigint NOT NULL,
    [accion] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [clave] uniqueidentifier NOT NULL,
    [hash_peticion] varbinary(32) NOT NULL,
    [respuesta] nvarchar(MAX) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [registrado_en] datetime2(0) NOT NULL CONSTRAINT [DF__PlantaSol__regis__46934FA8] DEFAULT (sysutcdatetime())
);
CREATE TABLE [prod].[Predio]
(
    [predio_id] bigint IDENTITY(1,1) NOT NULL,
    [codigo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(150) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [ubicacion_id] bigint NOT NULL,
    [fecha_registro] date NOT NULL CONSTRAINT [DF_Predio_FechaRegistro] DEFAULT (CONVERT([date],sysutcdatetime())),
    [estado] bit NOT NULL CONSTRAINT [DF_Predio_Estado] DEFAULT ((1)),
    [uot_id] bigint NULL
);
CREATE TABLE [prod].[PredioAmbito]
(
    [predio_ambito_id] bigint IDENTITY(1,1) NOT NULL,
    [predio_id] bigint NOT NULL,
    [uot_id] bigint NOT NULL,
    [convenio_uot_organizacion_id] bigint NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_E1_AmbitoEstado] DEFAULT ((1)),
    [fecha_creacion] datetime2(0) NOT NULL CONSTRAINT [DF_E1_AmbitoFecha] DEFAULT (sysutcdatetime()),
    [usuario_creacion_id] bigint NULL
);
CREATE TABLE [prod].[PredioIdentidad]
(
    [persona_id] bigint NOT NULL,
    [distrito_codigo] char(6) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre_normalizado] nvarchar(150) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [predio_id] bigint NOT NULL
);
CREATE TABLE [prod].[PredioMateriaSecaCambioE4]
(
    [cambio_id] bigint IDENTITY(1,1) NOT NULL,
    [informe_id] bigint NOT NULL,
    [accion] varchar(12) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_evento] datetime2(0) NOT NULL CONSTRAINT [DF_E4_SecaCambioFecha] DEFAULT (sysutcdatetime()),
    [correlacion_id] uniqueidentifier NULL,
    [valor_anterior] nvarchar(MAX) COLLATE Modern_Spanish_CI_AS NULL,
    [valor_nuevo] nvarchar(MAX) COLLATE Modern_Spanish_CI_AS NULL,
    [motivo] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [prod].[PredioMateriaSecaGlobalE4]
(
    [informe_id] bigint IDENTITY(1,1) NOT NULL,
    [predio_id] bigint NOT NULL,
    [uot_id] bigint NOT NULL,
    [convenio_id] bigint NOT NULL,
    [fecha_muestreo] date NOT NULL,
    [porcentaje] decimal(6,3) NOT NULL,
    [cantidad_plantas] int NOT NULL,
    [total_plantas_activas] int NOT NULL,
    [cobertura] varchar(7) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [informe] nvarchar(2000) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF_E4_SecaGlobalFecha] DEFAULT (sysutcdatetime()),
    [estado] bit NOT NULL CONSTRAINT [DF_E4_SecaGlobalEstado] DEFAULT ((1)),
    [version] bigint NOT NULL CONSTRAINT [DF_E4_SecaGlobalVersion] DEFAULT ((0)),
    [cantidad_frutos] int NULL,
    [metodo] varchar(15) COLLATE Modern_Spanish_CI_AS NULL,
    [modificado_por_usuario_id] bigint NULL,
    [fecha_modificacion] datetime2(0) NULL,
    [eliminado_por_usuario_id] bigint NULL,
    [fecha_baja] datetime2(0) NULL,
    [motivo_baja] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [prod].[PredioTitularidad]
(
    [predio_titularidad_id] bigint IDENTITY(1,1) NOT NULL,
    [predio_id] bigint NOT NULL,
    [socio_id] bigint NULL,
    [tipo_titularidad] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [porcentaje] decimal(5,2) NULL,
    [fecha_desde] date NOT NULL,
    [fecha_hasta] date NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_PredioTitularidad_Estado] DEFAULT ((1)),
    [persona_id] bigint NULL,
    [rol_titularidad] varchar(12) COLLATE Modern_Spanish_CI_AS NULL CONSTRAINT [DF_GP_RolTitular] DEFAULT ('ADICIONAL')
);
CREATE TABLE [prod].[PredioVersion]
(
    [predio_version_id] bigint IDENTITY(1,1) NOT NULL,
    [predio_id] bigint NOT NULL,
    [area_total_ha] decimal(10,4) NULL,
    [area_cultivable_ha] decimal(10,4) NULL,
    [tipo_riego] varchar(30) COLLATE Modern_Spanish_CI_AS NULL,
    [fuente_agua] nvarchar(150) COLLATE Modern_Spanish_CI_AS NULL,
    [infraestructura] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [observacion] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL,
    [fecha_desde] date NOT NULL,
    [fecha_hasta] date NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_PredioVersion_Estado] DEFAULT ((1)),
    [revision] int NOT NULL CONSTRAINT [DF_E1_PredioVersionRevision] DEFAULT ((1))
);
CREATE TABLE [prod].[ProduccionPlantaE3]
(
    [produccion_id] bigint IDENTITY(1,1) NOT NULL,
    [planta_id] bigint NOT NULL,
    [anio] smallint NOT NULL,
    [estimado_kg] decimal(14,3) NULL,
    [real_kg] decimal(14,3) NULL,
    [observacion] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL,
    [usuario_id] bigint NOT NULL,
    [registrado_en] datetime2(0) NOT NULL CONSTRAINT [DF__Produccio__regis__3A2D78C3] DEFAULT (sysutcdatetime()),
    [tipo_registro] varchar(12) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_E3_ProduccionTipo] DEFAULT ('LEGADO'),
    [fecha_evento] date NULL,
    [visita_tecnica_id] bigint NULL
);
CREATE TABLE [prod].[TipoTitularidadCatalogo]
(
    [tipo_titularidad_id] bigint IDENTITY(1,1) NOT NULL,
    [codigo] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(120) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_GP_TipoTitularidadEstado] DEFAULT ((1))
);
CREATE TABLE [prod].[VariedadCultivo]
(
    [variedad_cultivo_id] bigint IDENTITY(1,1) NOT NULL,
    [cultivo_id] int NOT NULL,
    [codigo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(120) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [variedad_palta_legacy_id] smallint NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_VariedadCultivo_Estado] DEFAULT ((1)),
    [descripcion] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [prod].[VariedadPalta]
(
    [variedad_palta_id] smallint IDENTITY(1,1) NOT NULL,
    [codigo] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(100) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_VariedadPalta_Estado] DEFAULT ((1))
);
CREATE TABLE [reporte].[TrabajoEspecial]
(
    [trabajo_id] bigint IDENTITY(1,1) NOT NULL,
    [usuario_id] bigint NOT NULL,
    [uot_id] bigint NOT NULL,
    [convenio_id] bigint NULL,
    [socio_id] bigint NULL,
    [predio_id] bigint NULL,
    [campania_id] bigint NULL,
    [tipo] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [formato] varchar(5) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [fecha_desde] date NOT NULL,
    [fecha_hasta] date NOT NULL,
    [clave] uniqueidentifier NOT NULL,
    [estado] varchar(15) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_TrabajoEspecialEstado] DEFAULT ('PENDIENTE'),
    [creado_utc] datetime2(0) NOT NULL CONSTRAINT [DF_TrabajoEspecialCreado] DEFAULT (sysutcdatetime()),
    [actualizado_utc] datetime2(0) NOT NULL CONSTRAINT [DF_TrabajoEspecialActualizado] DEFAULT (sysutcdatetime()),
    [archivo_clave] nvarchar(250) COLLATE Modern_Spanish_CI_AS NULL,
    [mensaje] nvarchar(200) COLLATE Modern_Spanish_CI_AS NULL,
    [visto] bit NOT NULL CONSTRAINT [DF_TrabajoEspecialVisto] DEFAULT ((0))
);
CREATE TABLE [reporte].[TrabajoExcel]
(
    [trabajo_id] bigint IDENTITY(1,1) NOT NULL,
    [usuario_id] bigint NOT NULL,
    [uot_id] bigint NOT NULL,
    [idempotencia] uniqueidentifier NOT NULL,
    [codigo] varchar(35) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [fecha_desde] date NOT NULL,
    [fecha_hasta] date NOT NULL,
    [almacen_id] bigint NULL,
    [predio_id] bigint NULL,
    [estado] varchar(16) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_TrabajoExcel_Estado] DEFAULT ('PENDIENTE'),
    [creado_utc] datetime2(0) NOT NULL CONSTRAINT [DF_TrabajoExcel_Creado] DEFAULT (sysutcdatetime()),
    [actualizado_utc] datetime2(0) NOT NULL CONSTRAINT [DF_TrabajoExcel_Actualizado] DEFAULT (sysutcdatetime()),
    [archivo_clave] nvarchar(250) COLLATE Modern_Spanish_CI_AS NULL,
    [total_filas] int NULL,
    [mensaje] nvarchar(200) COLLATE Modern_Spanish_CI_AS NULL,
    [visto] bit NOT NULL CONSTRAINT [DF_TrabajoExcel_Visto] DEFAULT ((0))
);
CREATE TABLE [sanidad].[CasoFitosanitario]
(
    [caso_fitosanitario_id] bigint IDENTITY(1,1) NOT NULL,
    [parcela_cultivo_id] bigint NOT NULL,
    [tipo_problema_fitosanitario_id] smallint NOT NULL,
    [visita_deteccion_id] bigint NULL,
    [fecha_deteccion] datetime2(0) NOT NULL,
    [plantas_afectadas] int NULL,
    [cantidad_estimada] bit NULL,
    [severidad] varchar(10) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado_caso] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [observacion] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_CasoFitosanitario_Estado] DEFAULT ((1))
);
CREATE TABLE [sanidad].[EpisodioNotaE4]
(
    [nota_id] bigint IDENTITY(1,1) NOT NULL,
    [episodio_id] bigint NOT NULL,
    [comentario] nvarchar(1500) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF_E4_NotaFecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [sanidad].[EpisodioPlantaE3]
(
    [episodio_id] bigint IDENTITY(1,1) NOT NULL,
    [planta_id] bigint NOT NULL,
    [tipo_problema_fitosanitario_id] smallint NULL,
    [inicio] datetime2(0) NOT NULL,
    [fin] datetime2(0) NULL,
    [observacion] nvarchar(1000) COLLATE Modern_Spanish_CI_AS NULL,
    [usuario_apertura_id] bigint NOT NULL,
    [usuario_cierre_id] bigint NULL,
    [visita_tecnica_id] bigint NULL,
    [gp_problema_id] int NULL,
    [activo] bit NOT NULL CONSTRAINT [DF_E3_EpisodioActivo] DEFAULT ((1)),
    [eliminado_en] datetime2(0) NULL,
    [eliminado_por_usuario_id] bigint NULL,
    [motivo_cierre] nvarchar(600) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [sanidad].[PlantaSeguimientoE3]
(
    [seguimiento_id] bigint IDENTITY(1,1) NOT NULL,
    [planta_id] bigint NOT NULL,
    [episodio_id] bigint NULL,
    [evento_id] bigint NOT NULL,
    [tipo] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [observacion] nvarchar(1000) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [resultado] nvarchar(600) COLLATE Modern_Spanish_CI_AS NULL,
    [visita_tecnica_id] bigint NULL,
    [fecha_hecho] datetime2(0) NOT NULL,
    [usuario_id] bigint NOT NULL
);
CREATE TABLE [sanidad].[SeguimientoFitosanitario]
(
    [seguimiento_fitosanitario_id] bigint IDENTITY(1,1) NOT NULL,
    [caso_fitosanitario_id] bigint NOT NULL,
    [visita_tecnica_id] bigint NULL,
    [fecha_hora] datetime2(0) NOT NULL,
    [plantas_afectadas] int NULL,
    [cantidad_estimada] bit NULL,
    [severidad] varchar(10) COLLATE Modern_Spanish_CI_AS NULL,
    [resultado] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [observacion] nvarchar(500) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_SeguimientoFitosanitario_Estado] DEFAULT ((1))
);
CREATE TABLE [sanidad].[TipoProblemaFitosanitario]
(
    [tipo_problema_fitosanitario_id] smallint IDENTITY(1,1) NOT NULL,
    [categoria] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [codigo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(140) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_TipoProblemaFitosanitario_Estado] DEFAULT ((1))
);
CREATE TABLE [sanidad].[TratamientoAplicacionE4]
(
    [aplicacion_id] bigint IDENTITY(1,1) NOT NULL,
    [episodio_id] bigint NOT NULL,
    [fecha_aplicacion] date NOT NULL,
    [comentario] nvarchar(1000) COLLATE Modern_Spanish_CI_AS NULL,
    [resultado] nvarchar(600) COLLATE Modern_Spanish_CI_AS NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF_E4_AplicacionFecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [sanidad].[TratamientoArchivoE4]
(
    [tratamiento_archivo_id] bigint IDENTITY(1,1) NOT NULL,
    [aplicacion_id] bigint NOT NULL,
    [archivo_id] bigint NOT NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF_E3_TratamientoArchivoFecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [sanidad].[TratamientoEdicionE3]
(
    [tratamiento_edicion_id] bigint IDENTITY(1,1) NOT NULL,
    [tratamiento_id] bigint NOT NULL,
    [anterior] nvarchar(MAX) COLLATE Modern_Spanish_CI_AS NULL,
    [nuevo] nvarchar(MAX) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF_E3_TratamientoEdicion_Fecha] DEFAULT (sysutcdatetime())
);
CREATE TABLE [sanidad].[TratamientoFitosanitario]
(
    [tratamiento_fitosanitario_id] bigint IDENTITY(1,1) NOT NULL,
    [caso_fitosanitario_id] bigint NOT NULL,
    [visita_tecnica_id] bigint NULL,
    [responsable_empleado_id] bigint NULL,
    [fecha_hora] datetime2(0) NOT NULL,
    [tratamiento] nvarchar(300) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [producto] nvarchar(160) COLLATE Modern_Spanish_CI_AS NULL,
    [dosis] decimal(12,4) NULL,
    [unidad_dosis] varchar(30) COLLATE Modern_Spanish_CI_AS NULL,
    [observacion] nvarchar(400) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_TratamientoFitosanitario_Estado] DEFAULT ((1))
);
CREATE TABLE [sanidad].[TratamientoPlantaE3]
(
    [tratamiento_id] bigint IDENTITY(1,1) NOT NULL,
    [episodio_id] bigint NOT NULL,
    [descripcion] nvarchar(600) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [resultado] nvarchar(600) COLLATE Modern_Spanish_CI_AS NULL,
    [fecha_aplicacion] datetime2(0) NOT NULL,
    [visita_tecnica_id] bigint NULL,
    [usuario_id] bigint NOT NULL,
    [fecha_registro] datetime2(0) NOT NULL CONSTRAINT [DF__Tratamien__fecha__3568C3A6] DEFAULT (sysutcdatetime()),
    [gp_tratamiento_id] int NULL,
    [comentario] nvarchar(1000) COLLATE Modern_Spanish_CI_AS NULL,
    [aplicacion_id] bigint NULL,
    [modificado_por_usuario_id] bigint NULL,
    [modificado_en] datetime2(0) NULL
);
CREATE TABLE [seg].[CodigoUnSoloUso]
(
    [codigo_un_solo_uso_id] bigint IDENTITY(1,1) NOT NULL,
    [usuario_id] bigint NOT NULL,
    [usuario_correo_seguridad_id] bigint NULL,
    [dispositivo_usuario_id] bigint NULL,
    [proposito] varchar(35) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [canal] varchar(15) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_CodigoUnSoloUso_Canal] DEFAULT ('EMAIL'),
    [codigo_hmac] varbinary(64) NOT NULL,
    [correo_destino] nvarchar(320) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [fecha_creacion] datetime2(0) NOT NULL CONSTRAINT [DF_CodigoUnSoloUso_Creacion] DEFAULT (sysutcdatetime()),
    [fecha_expiracion] datetime2(0) NOT NULL,
    [fecha_uso] datetime2(0) NULL,
    [fecha_invalidacion] datetime2(0) NULL,
    [intentos_fallidos] smallint NOT NULL CONSTRAINT [DF_CodigoUnSoloUso_IntentosFallidos] DEFAULT ((0)),
    [maximo_intentos] smallint NOT NULL,
    [ip_solicitud] varchar(64) COLLATE Modern_Spanish_CI_AS NULL,
    [grupo_solicitud] uniqueidentifier NOT NULL CONSTRAINT [DF_CodigoUnSoloUso_Grupo] DEFAULT (newid()),
    [estado] bit NOT NULL CONSTRAINT [DF_CodigoUnSoloUso_Estado] DEFAULT ((1))
);
CREATE TABLE [seg].[DispositivoUsuario]
(
    [dispositivo_usuario_id] bigint IDENTITY(1,1) NOT NULL,
    [usuario_id] bigint NOT NULL,
    [identificador_logico_hash] varbinary(64) NOT NULL,
    [navegador] nvarchar(120) COLLATE Modern_Spanish_CI_AS NULL,
    [sistema_operativo] nvarchar(120) COLLATE Modern_Spanish_CI_AS NULL,
    [user_agent] nvarchar(600) COLLATE Modern_Spanish_CI_AS NULL,
    [fecha_primera_deteccion] datetime2(0) NOT NULL CONSTRAINT [DF_DispositivoUsuario_PrimeraDeteccion] DEFAULT (sysutcdatetime()),
    [fecha_ultima_actividad] datetime2(0) NOT NULL CONSTRAINT [DF_DispositivoUsuario_UltimaActividad] DEFAULT (sysutcdatetime()),
    [es_reconocido] bit NOT NULL CONSTRAINT [DF_DispositivoUsuario_Reconocido] DEFAULT ((0)),
    [fecha_reconocimiento] datetime2(0) NULL,
    [fecha_retiro_reconocimiento] datetime2(0) NULL,
    [ultima_ip] varchar(64) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_DispositivoUsuario_Estado] DEFAULT ((1))
);
CREATE TABLE [seg].[HistorialPassword]
(
    [historial_password_id] bigint IDENTITY(1,1) NOT NULL,
    [usuario_id] bigint NOT NULL,
    [password_hash] varchar(512) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [fecha_desde] datetime2(0) NOT NULL CONSTRAINT [DF_HistorialPassword_FechaDesde] DEFAULT (sysutcdatetime()),
    [fecha_hasta] datetime2(0) NULL,
    [cambiado_por_usuario_id] bigint NULL,
    [motivo] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_HistorialPassword_Estado] DEFAULT ((1))
);
CREATE TABLE [seg].[IntentoAutenticacion]
(
    [intento_autenticacion_id] bigint IDENTITY(1,1) NOT NULL,
    [usuario_id] bigint NULL,
    [identificador_ingresado_hash] varbinary(64) NOT NULL,
    [dispositivo_usuario_id] bigint NULL,
    [fecha_hora] datetime2(0) NOT NULL CONSTRAINT [DF_IntentoAutenticacion_Fecha] DEFAULT (sysutcdatetime()),
    [resultado] varchar(35) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [ip] varchar(64) COLLATE Modern_Spanish_CI_AS NULL,
    [user_agent] nvarchar(600) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_IntentoAutenticacion_Estado] DEFAULT ((1))
);
CREATE TABLE [seg].[Modulo]
(
    [modulo_id] int IDENTITY(1,1) NOT NULL,
    [modulo_padre_id] int NULL,
    [codigo] varchar(60) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(120) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [orden] smallint NOT NULL CONSTRAINT [DF_Modulo_Orden] DEFAULT ((0)),
    [estado] bit NOT NULL CONSTRAINT [DF_Modulo_Estado] DEFAULT ((1)),
    [ruta] varchar(180) COLLATE Modern_Spanish_CI_AS NULL,
    [icono] varchar(80) COLLATE Modern_Spanish_CI_AS NULL,
    [visible_menu] bit NOT NULL CONSTRAINT [DF_Modulo_VisibleMenu] DEFAULT ((1)),
    [es_grupo] bit NOT NULL CONSTRAINT [DF_Modulo_EsGrupo] DEFAULT ((0))
);
CREATE TABLE [seg].[ModuloEspecial]
(
    [modulo_especial_id] int IDENTITY(1,1) NOT NULL,
    [codigo] varchar(60) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(120) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [descripcion] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_ModuloEspecial_Estado] DEFAULT ((1))
);
CREATE TABLE [seg].[ModuloEspecialPermiso]
(
    [modulo_especial_id] int NOT NULL,
    [permiso_id] bigint NOT NULL
);
CREATE TABLE [seg].[NotificacionSeguridad]
(
    [notificacion_seguridad_id] bigint IDENTITY(1,1) NOT NULL,
    [usuario_id] bigint NOT NULL,
    [tipo_notificacion] varchar(35) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [correo_destino] nvarchar(320) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [fecha_creacion] datetime2(0) NOT NULL CONSTRAINT [DF_NotificacionSeguridad_Creacion] DEFAULT (sysutcdatetime()),
    [fecha_ultimo_intento] datetime2(0) NULL,
    [fecha_envio] datetime2(0) NULL,
    [cantidad_intentos] smallint NOT NULL CONSTRAINT [DF_NotificacionSeguridad_Intentos] DEFAULT ((0)),
    [estado_envio] varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_NotificacionSeguridad_EstadoEnvio] DEFAULT ('PENDIENTE'),
    [proveedor_mensaje_id] nvarchar(200) COLLATE Modern_Spanish_CI_AS NULL,
    [correlacion_id] uniqueidentifier NOT NULL CONSTRAINT [DF_NotificacionSeguridad_Correlacion] DEFAULT (newid()),
    [metadata] nvarchar(MAX) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_NotificacionSeguridad_Estado] DEFAULT ((1))
);
CREATE TABLE [seg].[Permiso]
(
    [permiso_id] bigint IDENTITY(1,1) NOT NULL,
    [modulo_id] int NOT NULL,
    [codigo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(100) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [descripcion] nvarchar(200) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_Permiso_Estado] DEFAULT ((1)),
    [accion] varchar(20) COLLATE Modern_Spanish_CI_AS NULL,
    [es_sensible] bit NOT NULL CONSTRAINT [DF_Permiso_EsSensible] DEFAULT ((0)),
    [requiere_motivo] bit NOT NULL CONSTRAINT [DF_Permiso_RequiereMotivo] DEFAULT ((0))
);
CREATE TABLE [seg].[PoliticaSeguridad]
(
    [politica_seguridad_id] smallint IDENTITY(1,1) NOT NULL,
    [codigo] varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [max_intentos_login] smallint NOT NULL,
    [minutos_bloqueo_login] smallint NOT NULL,
    [max_intentos_codigo] smallint NOT NULL,
    [segundos_minimos_reenvio] smallint NOT NULL,
    [minutos_expiracion_validacion] smallint NOT NULL,
    [minutos_expiracion_recuperacion] smallint NOT NULL,
    [minutos_expiracion_segundo_factor] smallint NOT NULL,
    [minutos_access_token] smallint NOT NULL,
    [dias_refresh_token] smallint NOT NULL,
    [dias_dispositivo_reconocido] smallint NOT NULL,
    [fecha_desde] datetime2(0) NOT NULL CONSTRAINT [DF_PoliticaSeguridad_FechaDesde] DEFAULT (sysutcdatetime()),
    [fecha_hasta] datetime2(0) NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_PoliticaSeguridad_Estado] DEFAULT ((1))
);
CREATE TABLE [seg].[RefreshTokenSesion]
(
    [refresh_token_sesion_id] bigint IDENTITY(1,1) NOT NULL,
    [sesion_usuario_id] bigint NOT NULL,
    [token_hash] varbinary(64) NOT NULL,
    [token_padre_id] bigint NULL,
    [token_reemplazo_id] bigint NULL,
    [fecha_emision] datetime2(0) NOT NULL CONSTRAINT [DF_RefreshTokenSesion_Emision] DEFAULT (sysutcdatetime()),
    [fecha_expiracion] datetime2(0) NOT NULL,
    [fecha_uso] datetime2(0) NULL,
    [fecha_revocacion] datetime2(0) NULL,
    [motivo_revocacion] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_RefreshTokenSesion_Estado] DEFAULT ((1))
);
CREATE TABLE [seg].[Rol]
(
    [rol_id] bigint IDENTITY(1,1) NOT NULL,
    [codigo] varchar(40) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [nombre] nvarchar(100) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [descripcion] nvarchar(200) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_Rol_Estado] DEFAULT ((1)),
    [requiere_segundo_factor] bit NOT NULL CONSTRAINT [DF_Rol_RequiereSegundoFactor] DEFAULT ((0)),
    [es_sistema] bit NOT NULL CONSTRAINT [DF_Rol_EsSistema] DEFAULT ((0))
);
CREATE TABLE [seg].[RolPermiso]
(
    [rol_id] bigint NOT NULL,
    [permiso_id] bigint NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_RolPermiso_Estado] DEFAULT ((1)),
    [fecha_asignacion] datetime2(0) NULL CONSTRAINT [DF_RolPermiso_FechaAsignacion] DEFAULT (sysutcdatetime()),
    [asignado_por_usuario_id] bigint NULL,
    [fecha_retiro] datetime2(0) NULL,
    [retirado_por_usuario_id] bigint NULL,
    [motivo_retiro] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [seg].[SesionUsuario]
(
    [sesion_usuario_id] bigint IDENTITY(1,1) NOT NULL,
    [sesion_publica_id] uniqueidentifier NOT NULL CONSTRAINT [DF_SesionUsuario_PublicaId] DEFAULT (newsequentialid()),
    [usuario_id] bigint NOT NULL,
    [dispositivo_usuario_id] bigint NULL,
    [token_version] int NOT NULL,
    [fecha_creacion] datetime2(0) NOT NULL CONSTRAINT [DF_SesionUsuario_FechaCreacion] DEFAULT (sysutcdatetime()),
    [fecha_ultima_actividad] datetime2(0) NOT NULL CONSTRAINT [DF_SesionUsuario_UltimaActividad] DEFAULT (sysutcdatetime()),
    [fecha_expiracion_renovacion] datetime2(0) NOT NULL,
    [fecha_revocacion] datetime2(0) NULL,
    [motivo_revocacion] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [ip_creacion] varchar(64) COLLATE Modern_Spanish_CI_AS NULL,
    [ip_ultima_actividad] varchar(64) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_SesionUsuario_Estado] DEFAULT ((1)),
    [uot_contexto_id] bigint NULL,
    [modo_uot] varchar(12) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_SesionUsuario_ModoUOT] DEFAULT ('ESPECIFICA')
);
CREATE TABLE [seg].[TokenAccesoRevocado]
(
    [token_acceso_revocado_id] bigint IDENTITY(1,1) NOT NULL,
    [sesion_usuario_id] bigint NULL,
    [jti_hash] varbinary(64) NOT NULL,
    [fecha_revocacion] datetime2(0) NOT NULL CONSTRAINT [DF_TokenAccesoRevocado_Revocacion] DEFAULT (sysutcdatetime()),
    [fecha_expiracion_token] datetime2(0) NOT NULL,
    [motivo] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_TokenAccesoRevocado_Estado] DEFAULT ((1))
);
CREATE TABLE [seg].[Usuario]
(
    [usuario_id] bigint IDENTITY(1,1) NOT NULL,
    [persona_id] bigint NOT NULL,
    [nombre_usuario] varchar(80) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [password_hash] varchar(512) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_Usuario_Estado] DEFAULT ((1)),
    [fecha_creacion] datetime2(0) NOT NULL CONSTRAINT [DF_Usuario_FechaCreacion] DEFAULT (sysutcdatetime()),
    [intentos_fallidos] smallint NOT NULL CONSTRAINT [DF_Usuario_IntentosFallidos] DEFAULT ((0)),
    [fecha_ultimo_intento_fallido] datetime2(0) NULL,
    [bloqueado_hasta] datetime2(0) NULL,
    [ultimo_acceso_correcto] datetime2(0) NULL,
    [fecha_cambio_password] datetime2(0) NULL,
    [requiere_cambio_password] bit NOT NULL CONSTRAINT [DF_Usuario_RequiereCambioPassword] DEFAULT ((0)),
    [segundo_factor_habilitado] bit NOT NULL CONSTRAINT [DF_Usuario_SegundoFactor] DEFAULT ((0)),
    [token_version] int NOT NULL CONSTRAINT [DF_Usuario_TokenVersion] DEFAULT ((1)),
    [estado_cuenta] varchar(25) COLLATE Modern_Spanish_CI_AS NOT NULL CONSTRAINT [DF_Usuario_EstadoCuenta] DEFAULT ('PENDIENTE_VALIDACION'),
    [usuario_clave_desco] AS ((lower(ltrim(rtrim([nombre_usuario])))) collate Latin1_General_100_CI_AS) PERSISTED,
    [omitir_segundo_factor_pruebas] bit NOT NULL CONSTRAINT [DF_Usuario_OmitirSegundoFactorPruebas] DEFAULT ((0))
);
CREATE TABLE [seg].[UsuarioCorreoSeguridad]
(
    [usuario_correo_seguridad_id] bigint IDENTITY(1,1) NOT NULL,
    [usuario_id] bigint NOT NULL,
    [correo] nvarchar(320) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [correo_normalizado] nvarchar(320) COLLATE Modern_Spanish_CI_AS NOT NULL,
    [es_principal] bit NOT NULL CONSTRAINT [DF_UsuarioCorreoSeguridad_Principal] DEFAULT ((1)),
    [es_verificado] bit NOT NULL CONSTRAINT [DF_UsuarioCorreoSeguridad_Verificado] DEFAULT ((0)),
    [fecha_verificacion] datetime2(0) NULL,
    [fecha_desde] datetime2(0) NOT NULL CONSTRAINT [DF_UsuarioCorreoSeguridad_FechaDesde] DEFAULT (sysutcdatetime()),
    [fecha_hasta] datetime2(0) NULL,
    [creado_por_usuario_id] bigint NULL,
    [motivo_cambio] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_UsuarioCorreoSeguridad_Estado] DEFAULT ((1)),
    [correo_clave_desco] AS ((lower(ltrim(rtrim([correo])))) collate Latin1_General_100_CI_AS) PERSISTED
);
CREATE TABLE [seg].[UsuarioRol]
(
    [usuario_rol_id] bigint IDENTITY(1,1) NOT NULL,
    [usuario_id] bigint NOT NULL,
    [rol_id] bigint NOT NULL,
    [fecha_desde] datetime2(0) NOT NULL CONSTRAINT [DF_UsuarioRol_FechaDesde] DEFAULT (sysutcdatetime()),
    [fecha_hasta] datetime2(0) NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_UsuarioRol_Estado] DEFAULT ((1)),
    [asignado_por_usuario_id] bigint NULL,
    [retirado_por_usuario_id] bigint NULL,
    [motivo_retiro] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL
);
CREATE TABLE [seg].[UsuarioUOT]
(
    [usuario_uot_id] bigint IDENTITY(1,1) NOT NULL,
    [usuario_id] bigint NOT NULL,
    [uot_id] bigint NOT NULL,
    [es_predeterminada] bit NOT NULL CONSTRAINT [DF_UsuarioUOT_Default] DEFAULT ((0)),
    [fecha_desde] datetime2(0) NOT NULL CONSTRAINT [DF_UsuarioUOT_Desde] DEFAULT (sysutcdatetime()),
    [fecha_hasta] datetime2(0) NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_UsuarioUOT_Estado] DEFAULT ((1)),
    [asignado_por_usuario_id] bigint NULL
);
CREATE TABLE [seg].[UsuarioUOTPermiso]
(
    [usuario_uot_permiso_id] bigint IDENTITY(1,1) NOT NULL,
    [usuario_uot_id] bigint NOT NULL,
    [permiso_id] bigint NOT NULL,
    [permitido] bit NOT NULL,
    [motivo] nvarchar(300) COLLATE Modern_Spanish_CI_AS NULL,
    [fecha_desde] datetime2(0) NOT NULL CONSTRAINT [DF_UsuarioUOTPermiso_Desde] DEFAULT (sysutcdatetime()),
    [fecha_hasta] datetime2(0) NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_UsuarioUOTPermiso_Estado] DEFAULT ((1)),
    [asignado_por_usuario_id] bigint NULL
);
CREATE TABLE [seg].[UsuarioUOTRol]
(
    [usuario_uot_rol_id] bigint IDENTITY(1,1) NOT NULL,
    [usuario_uot_id] bigint NOT NULL,
    [rol_id] bigint NOT NULL,
    [fecha_desde] datetime2(0) NOT NULL CONSTRAINT [DF_UsuarioUOTRol_Desde] DEFAULT (sysutcdatetime()),
    [fecha_hasta] datetime2(0) NULL,
    [estado] bit NOT NULL CONSTRAINT [DF_UsuarioUOTRol_Estado] DEFAULT ((1)),
    [asignado_por_usuario_id] bigint NULL
);
ALTER TABLE [archivo].[Archivo] ADD CONSTRAINT [PK_Archivo] PRIMARY KEY CLUSTERED ([archivo_id] ASC);
ALTER TABLE [archivo].[ArchivoVinculo] ADD CONSTRAINT [PK_ArchivoVinculo] PRIMARY KEY CLUSTERED ([archivo_vinculo_id] ASC);
ALTER TABLE [auditoria].[AuditoriaEvento] ADD CONSTRAINT [PK_AuditoriaEvento] PRIMARY KEY CLUSTERED ([auditoria_evento_id] ASC);
ALTER TABLE [auditoria].[ErrorBaseDatos] ADD CONSTRAINT [PK_DESCO_ErrorBaseDatos] PRIMARY KEY CLUSTERED ([error_base_datos_id] ASC);
ALTER TABLE [auditoria].[ExpedienteErrorTecnico] ADD CONSTRAINT [PK__Expedien__DA71E16CEC4DDF33] PRIMARY KEY CLUSTERED ([error_id] ASC);
ALTER TABLE [auditoria].[OperacionIdempotente] ADD CONSTRAINT [PK_OperacionIdempotente] PRIMARY KEY CLUSTERED ([operacion_idempotente_id] ASC);
ALTER TABLE [auditoria].[TransicionEstado] ADD CONSTRAINT [PK_TransicionEstado] PRIMARY KEY CLUSTERED ([transicion_estado_id] ASC);
ALTER TABLE [campo].[EvaluacionAgronomica] ADD CONSTRAINT [PK_EvaluacionAgronomica] PRIMARY KEY CLUSTERED ([evaluacion_agronomica_id] ASC);
ALTER TABLE [campo].[EvaluacionMateriaSeca] ADD CONSTRAINT [PK_EvaluacionMateriaSeca] PRIMARY KEY CLUSTERED ([evaluacion_materia_seca_id] ASC);
ALTER TABLE [campo].[MotivoSalida] ADD CONSTRAINT [PK_MotivoSalida] PRIMARY KEY CLUSTERED ([motivo_salida_id] ASC);
ALTER TABLE [campo].[SalidaCampo] ADD CONSTRAINT [PK_SalidaCampo] PRIMARY KEY CLUSTERED ([salida_campo_id] ASC);
ALTER TABLE [campo].[SalidaDestinoE2] ADD CONSTRAINT [PK__SalidaDe__3B72E2A85341A21E] PRIMARY KEY CLUSTERED ([destino_id] ASC);
ALTER TABLE [campo].[SalidaE2] ADD CONSTRAINT [PK_SalidaE2] PRIMARY KEY CLUSTERED ([salida_campo_id] ASC);
ALTER TABLE [campo].[SalidaEventoE2] ADD CONSTRAINT [PK__SalidaEv__1850C3AD8EA80DEF] PRIMARY KEY CLUSTERED ([evento_id] ASC);
ALTER TABLE [campo].[SalidaInspeccionE2] ADD CONSTRAINT [PK_E2_SalidaInspeccion] PRIMARY KEY CLUSTERED ([salida_campo_id] ASC);
ALTER TABLE [campo].[SalidaOperacionE2] ADD CONSTRAINT [PK__SalidaOp__3434C7DFA0E6F729] PRIMARY KEY CLUSTERED ([operacion_id] ASC);
ALTER TABLE [campo].[SalidaParticipante] ADD CONSTRAINT [PK_SalidaParticipante] PRIMARY KEY CLUSTERED ([salida_participante_id] ASC);
ALTER TABLE [campo].[SalidaRecursoE2] ADD CONSTRAINT [PK__SalidaRe__B0EFB20391569D3F] PRIMARY KEY CLUSTERED ([solicitud_recurso_id] ASC);
ALTER TABLE [campo].[SalidaRetornoE2] ADD CONSTRAINT [PK__SalidaRe__ACB516A57C12800C] PRIMARY KEY CLUSTERED ([salida_campo_id] ASC);
ALTER TABLE [campo].[SalidaVisitaE2] ADD CONSTRAINT [PK__SalidaVi__77D80AF532B02580] PRIMARY KEY CLUSTERED ([visita_tecnica_id] ASC);
ALTER TABLE [campo].[TipoEvaluacion] ADD CONSTRAINT [PK_TipoEvaluacion] PRIMARY KEY CLUSTERED ([tipo_evaluacion_id] ASC);
ALTER TABLE [campo].[TipoVisitaE2] ADD CONSTRAINT [PK__TipoVisi__2200B0D6BDA6C652] PRIMARY KEY CLUSTERED ([tipo_visita_id] ASC);
ALTER TABLE [campo].[VisitaTecnica] ADD CONSTRAINT [PK_VisitaTecnica] PRIMARY KEY CLUSTERED ([visita_tecnica_id] ASC);
ALTER TABLE [comercial].[AccesoEmpleadoPOS] ADD CONSTRAINT [PK_AccesoEmpleadoPOS] PRIMARY KEY CLUSTERED ([uot_id] ASC,[empleado_id] ASC);
ALTER TABLE [comercial].[AjustePrecioSocio] ADD CONSTRAINT [PK_AjustePrecioSocio] PRIMARY KEY CLUSTERED ([ajuste_precio_socio_id] ASC);
ALTER TABLE [comercial].[Boleta] ADD CONSTRAINT [PK_Boleta] PRIMARY KEY CLUSTERED ([boleta_id] ASC);
ALTER TABLE [comercial].[CajaAsignacion] ADD CONSTRAINT [PK_CajaAsignacion] PRIMARY KEY CLUSTERED ([asignacion_id] ASC);
ALTER TABLE [comercial].[CajaEvidencia] ADD CONSTRAINT [PK_CajaEvidencia] PRIMARY KEY CLUSTERED ([caja_evidencia_id] ASC);
ALTER TABLE [comercial].[CajaMovimiento] ADD CONSTRAINT [PK_CajaMovimiento] PRIMARY KEY CLUSTERED ([caja_movimiento_id] ASC);
ALTER TABLE [comercial].[CajaPOS] ADD CONSTRAINT [PK_CajaPOS] PRIMARY KEY CLUSTERED ([caja_id] ASC);
ALTER TABLE [comercial].[CajaSesion] ADD CONSTRAINT [PK_CajaSesion] PRIMARY KEY CLUSTERED ([caja_sesion_id] ASC);
ALTER TABLE [comercial].[CajaSesionOperador] ADD CONSTRAINT [PK_CajaSesionOperador] PRIMARY KEY CLUSTERED ([caja_sesion_id] ASC,[usuario_id] ASC);
ALTER TABLE [comercial].[CampaniaCalibre] ADD CONSTRAINT [PK_CampaniaCalibre] PRIMARY KEY CLUSTERED ([campania_calibre_id] ASC);
ALTER TABLE [comercial].[CampaniaCalibrePrecioVersion] ADD CONSTRAINT [PK_CampaniaCalibrePrecioVersion] PRIMARY KEY CLUSTERED ([campania_calibre_precio_version_id] ASC);
ALTER TABLE [comercial].[CampaniaControlE4] ADD CONSTRAINT [PK__Campania__8DC2E25CC7FF9DFA] PRIMARY KEY CLUSTERED ([campania_venta_id] ASC);
ALTER TABLE [comercial].[CampaniaJabaPlan] ADD CONSTRAINT [PK_CampaniaJabaPlan] PRIMARY KEY CLUSTERED ([campania_jaba_plan_id] ASC);
ALTER TABLE [comercial].[CampaniaJabaPrecioSancion] ADD CONSTRAINT [PK_CampaniaJabaPrecioSancion] PRIMARY KEY CLUSTERED ([campania_jaba_recepcion_id] ASC);
ALTER TABLE [comercial].[CampaniaJabaRecepcion] ADD CONSTRAINT [PK_CampaniaJabaRecepcion] PRIMARY KEY CLUSTERED ([campania_jaba_recepcion_id] ASC);
ALTER TABLE [comercial].[CampaniaSancionTarifa] ADD CONSTRAINT [PK_CampaniaSancionTarifa] PRIMARY KEY CLUSTERED ([campania_sancion_tarifa_id] ASC);
ALTER TABLE [comercial].[CampaniaSocioSancion] ADD CONSTRAINT [PK_CampaniaSocioSancion] PRIMARY KEY CLUSTERED ([campania_socio_sancion_id] ASC);
ALTER TABLE [comercial].[CampaniaVencimientoLog] ADD CONSTRAINT [PK_CampaniaVencimientoLog] PRIMARY KEY CLUSTERED ([campania_vencimiento_log_id] ASC);
ALTER TABLE [comercial].[CampaniaVenta] ADD CONSTRAINT [PK_CampaniaVenta] PRIMARY KEY CLUSTERED ([campania_venta_id] ASC);
ALTER TABLE [comercial].[CargoConceptoE4] ADD CONSTRAINT [PK__CargoCon__EAFBEC4EAC619C86] PRIMARY KEY CLUSTERED ([concepto_id] ASC);
ALTER TABLE [comercial].[CargoIndividualE4] ADD CONSTRAINT [PK__CargoInd__982828C45E999954] PRIMARY KEY CLUSTERED ([cargo_id] ASC);
ALTER TABLE [comercial].[CargoTarifaE4] ADD CONSTRAINT [PK__CargoTar__0A71ABADE73B5E86] PRIMARY KEY CLUSTERED ([tarifa_id] ASC);
ALTER TABLE [comercial].[CatalogoSancionVenta] ADD CONSTRAINT [PK_CatalogoSancionVenta] PRIMARY KEY CLUSTERED ([sancion_venta_id] ASC);
ALTER TABLE [comercial].[CierreCampaniaE5] ADD CONSTRAINT [PK__CierreCa__8DC2E25C7D4DA0BC] PRIMARY KEY CLUSTERED ([campania_venta_id] ASC);
ALTER TABLE [comercial].[CompradorAPAPPSS] ADD CONSTRAINT [PK_CompradorAPAPPSS] PRIMARY KEY CLUSTERED ([comprador_apappss_id] ASC);
ALTER TABLE [comercial].[CondicionComercial] ADD CONSTRAINT [PK_CondicionComercial] PRIMARY KEY CLUSTERED ([condicion_comercial_id] ASC);
ALTER TABLE [comercial].[DetalleVenta] ADD CONSTRAINT [PK_DetalleVenta] PRIMARY KEY CLUSTERED ([detalle_venta_id] ASC);
ALTER TABLE [comercial].[EntregaDetalle] ADD CONSTRAINT [PK_EntregaDetalle] PRIMARY KEY CLUSTERED ([entrega_detalle_id] ASC);
ALTER TABLE [comercial].[EntregaSocio] ADD CONSTRAINT [PK_EntregaSocio] PRIMARY KEY CLUSTERED ([entrega_socio_id] ASC);
ALTER TABLE [comercial].[EventoE4] ADD CONSTRAINT [PK__EventoE4__1850C3AD24617F4E] PRIMARY KEY CLUSTERED ([evento_id] ASC);
ALTER TABLE [comercial].[Factura] ADD CONSTRAINT [PK_Factura] PRIMARY KEY CLUSTERED ([factura_id] ASC);
ALTER TABLE [comercial].[HorarioAtencionUOT] ADD CONSTRAINT [PK_HorarioAtencionUOT] PRIMARY KEY CLUSTERED ([uot_id] ASC);
ALTER TABLE [comercial].[HorarioEmpleadoPOS] ADD CONSTRAINT [PK_HorarioEmpleadoPOS] PRIMARY KEY CLUSTERED ([horario_id] ASC);
ALTER TABLE [comercial].[IncidenciaFaltanteE4] ADD CONSTRAINT [PK__Incidenc__D0002B7E161319C9] PRIMARY KEY CLUSTERED ([incidencia_id] ASC);
ALTER TABLE [comercial].[IncidenciaOperativa] ADD CONSTRAINT [PK_IncidenciaOperativa] PRIMARY KEY CLUSTERED ([incidencia_operativa_id] ASC);
ALTER TABLE [comercial].[JabaAsignacion] ADD CONSTRAINT [PK_JabaAsignacion] PRIMARY KEY CLUSTERED ([jaba_asignacion_id] ASC);
ALTER TABLE [comercial].[JabaClasificacionE4] ADD CONSTRAINT [PK_JabaClasificacionE4] PRIMARY KEY CLUSTERED ([clasificacion_id] ASC);
ALTER TABLE [comercial].[JabaClasificacionHistorialE4] ADD CONSTRAINT [PK__JabaClas__68FE18EE5A89E0FA] PRIMARY KEY CLUSTERED ([historial_id] ASC);
ALTER TABLE [comercial].[JabaDevolucion] ADD CONSTRAINT [PK_JabaDevolucion] PRIMARY KEY CLUSTERED ([jaba_devolucion_id] ASC);
ALTER TABLE [comercial].[JabaMovimiento] ADD CONSTRAINT [PK_JabaMovimiento] PRIMARY KEY CLUSTERED ([jaba_movimiento_id] ASC);
ALTER TABLE [comercial].[JabaPesajeHistorialE4] ADD CONSTRAINT [PK__JabaPesa__68FE18EE1B69A65D] PRIMARY KEY CLUSTERED ([historial_id] ASC);
ALTER TABLE [comercial].[JabaRetornoValidadoE4] ADD CONSTRAINT [PK__JabaReto__116FB4E853844EEE] PRIMARY KEY CLUSTERED ([jaba_asignacion_id] ASC);
ALTER TABLE [comercial].[JabaSaldoOperativo] ADD CONSTRAINT [PK_DESCO_JabaSaldo] PRIMARY KEY CLUSTERED ([operativo_venta_id] ASC);
ALTER TABLE [comercial].[JabaStockHistorialE4] ADD CONSTRAINT [PK__JabaStoc__68FE18EE8ABB40F9] PRIMARY KEY CLUSTERED ([historial_id] ASC);
ALTER TABLE [comercial].[JabaStockUotE4] ADD CONSTRAINT [PK_JabaStockUotE4] PRIMARY KEY CLUSTERED ([uot_id] ASC);
ALTER TABLE [comercial].[JabaUnidadE4] ADD CONSTRAINT [PK_JabaUnidadE4] PRIMARY KEY CLUSTERED ([unidad_id] ASC);
ALTER TABLE [comercial].[MetodoPago] ADD CONSTRAINT [PK_MetodoPago] PRIMARY KEY CLUSTERED ([metodo_pago_id] ASC);
ALTER TABLE [comercial].[ModalidadVenta] ADD CONSTRAINT [PK_ModalidadVenta] PRIMARY KEY CLUSTERED ([modalidad_venta_id] ASC);
ALTER TABLE [comercial].[OperativoSocio] ADD CONSTRAINT [PK_OperativoSocio] PRIMARY KEY CLUSTERED ([operativo_socio_id] ASC);
ALTER TABLE [comercial].[OperativoVenta] ADD CONSTRAINT [PK_OperativoVenta] PRIMARY KEY CLUSTERED ([operativo_venta_id] ASC);
ALTER TABLE [comercial].[OperativoZona] ADD CONSTRAINT [PK_OperativoZona] PRIMARY KEY CLUSTERED ([operativo_venta_id] ASC,[zona_productiva_id] ASC);
ALTER TABLE [comercial].[PagoVenta] ADD CONSTRAINT [PK_PagoVenta] PRIMARY KEY CLUSTERED ([pago_venta_id] ASC);
ALTER TABLE [comercial].[ParticipacionCampaniaSocio] ADD CONSTRAINT [PK_ParticipacionCampaniaSocio] PRIMARY KEY CLUSTERED ([participacion_campania_socio_id] ASC);
ALTER TABLE [comercial].[PrecioComercial] ADD CONSTRAINT [PK_PrecioComercial] PRIMARY KEY CLUSTERED ([precio_comercial_id] ASC);
ALTER TABLE [comercial].[SancionSocioE4] ADD CONSTRAINT [PK__SancionS__58FD673299040D50] PRIMARY KEY CLUSTERED ([sancion_id] ASC);
ALTER TABLE [comercial].[SolicitudE4] ADD CONSTRAINT [PK_SolicitudE4] PRIMARY KEY CLUSTERED ([usuario_id] ASC,[clave] ASC);
ALTER TABLE [comercial].[Venta] ADD CONSTRAINT [PK_Venta] PRIMARY KEY CLUSTERED ([venta_id] ASC);
ALTER TABLE [comercial].[VentaAnulacionPOS] ADD CONSTRAINT [PK_VentaAnulacionPOS] PRIMARY KEY CLUSTERED ([venta_id] ASC);
ALTER TABLE [config].[CatalogoRecursoValor] ADD CONSTRAINT [PK_CatalogoRecursoValor] PRIMARY KEY CLUSTERED ([catalogo_recurso_valor_id] ASC);
ALTER TABLE [config].[DashboardElemento] ADD CONSTRAINT [PK_DashboardElemento] PRIMARY KEY CLUSTERED ([dashboard_elemento_id] ASC);
ALTER TABLE [config].[DashboardRolElemento] ADD CONSTRAINT [PK_DashboardRolElemento] PRIMARY KEY CLUSTERED ([rol_id] ASC,[dashboard_elemento_id] ASC);
ALTER TABLE [config].[DashboardUsuarioElemento] ADD CONSTRAINT [PK_DashboardUsuarioElemento] PRIMARY KEY CLUSTERED ([usuario_id] ASC,[dashboard_elemento_id] ASC);
ALTER TABLE [config].[MensajeUsuario] ADD CONSTRAINT [PK_DESCO_MensajeUsuario] PRIMARY KEY CLUSTERED ([texto_origen] ASC);
ALTER TABLE [config].[RespuestaBaseDatos] ADD CONSTRAINT [PK_DESCO_RespuestaBaseDatos] PRIMARY KEY CLUSTERED ([clave] ASC);
ALTER TABLE [config].[RespuestaProcedimiento] ADD CONSTRAINT [PK_DESCO_RespuestaProcedimiento] PRIMARY KEY CLUSTERED ([procedimiento] ASC);
ALTER TABLE [config].[TipoDocumentoComprador] ADD CONSTRAINT [PK_TipoDocumentoComprador] PRIMARY KEY CLUSTERED ([tipo_documento_comprador_id] ASC);
ALTER TABLE [finanzas].[CobroComprador] ADD CONSTRAINT [PK_CobroComprador] PRIMARY KEY CLUSTERED ([cobro_comprador_id] ASC);
ALTER TABLE [finanzas].[EventoPagoE5] ADD CONSTRAINT [PK__EventoPa__1850C3AD9824A143] PRIMARY KEY CLUSTERED ([evento_id] ASC);
ALTER TABLE [finanzas].[GastoCampania] ADD CONSTRAINT [PK_GastoCampania] PRIMARY KEY CLUSTERED ([gasto_campania_id] ASC);
ALTER TABLE [finanzas].[GastoProrrateoSocio] ADD CONSTRAINT [PK_GastoProrrateoSocio] PRIMARY KEY CLUSTERED ([gasto_prorrateo_socio_id] ASC);
ALTER TABLE [finanzas].[GastoRepartoLineaE5] ADD CONSTRAINT [PK__GastoRep__1720DDBC1B0966F2] PRIMARY KEY CLUSTERED ([reparto_id] ASC,[participacion_id] ASC);
ALTER TABLE [finanzas].[GastoRepartoVersionE5] ADD CONSTRAINT [PK__GastoRep__F6B5E4ACD9D764BC] PRIMARY KEY CLUSTERED ([reparto_id] ASC);
ALTER TABLE [finanzas].[LiquidacionDetalle] ADD CONSTRAINT [PK_LiquidacionDetalle] PRIMARY KEY CLUSTERED ([liquidacion_detalle_id] ASC);
ALTER TABLE [finanzas].[LiquidacionSnapshotE5] ADD CONSTRAINT [PK__Liquidac__E88EB6CB6BF7DB12] PRIMARY KEY CLUSTERED ([liquidacion_socio_id] ASC);
ALTER TABLE [finanzas].[LiquidacionSocio] ADD CONSTRAINT [PK_LiquidacionSocio] PRIMARY KEY CLUSTERED ([liquidacion_socio_id] ASC);
ALTER TABLE [finanzas].[PagoBeneficiarioE5] ADD CONSTRAINT [PK_PagoBeneficiarioE5] PRIMARY KEY CLUSTERED ([pago_socio_id] ASC);
ALTER TABLE [finanzas].[PagoSocio] ADD CONSTRAINT [PK_PagoSocio] PRIMARY KEY CLUSTERED ([pago_socio_id] ASC);
ALTER TABLE [finanzas].[ReglaProrrateo] ADD CONSTRAINT [PK_ReglaProrrateo] PRIMARY KEY CLUSTERED ([regla_prorrateo_id] ASC);
ALTER TABLE [finanzas].[SolicitudE5] ADD CONSTRAINT [PK__Solicitu__99CA18922D6ED6DD] PRIMARY KEY CLUSTERED ([usuario_id] ASC,[clave] ASC);
ALTER TABLE [finanzas].[TipoGasto] ADD CONSTRAINT [PK_TipoGasto] PRIMARY KEY CLUSTERED ([tipo_gasto_id] ASC);
ALTER TABLE [geo].[CentroPoblado] ADD CONSTRAINT [PK_CentroPoblado] PRIMARY KEY CLUSTERED ([centro_poblado_id] ASC);
ALTER TABLE [geo].[Departamento] ADD CONSTRAINT [PK_Departamento] PRIMARY KEY CLUSTERED ([departamento_codigo] ASC);
ALTER TABLE [geo].[Distrito] ADD CONSTRAINT [PK_Distrito] PRIMARY KEY CLUSTERED ([distrito_codigo] ASC);
ALTER TABLE [geo].[Provincia] ADD CONSTRAINT [PK_Provincia] PRIMARY KEY CLUSTERED ([provincia_codigo] ASC);
ALTER TABLE [geo].[Ubicacion] ADD CONSTRAINT [PK_Ubicacion] PRIMARY KEY CLUSTERED ([ubicacion_id] ASC);
ALTER TABLE [geo].[ZonaProductiva] ADD CONSTRAINT [PK_ZonaProductiva] PRIMARY KEY CLUSTERED ([zona_productiva_id] ASC);
ALTER TABLE [geo].[ZonaProductivaPredio] ADD CONSTRAINT [PK_ZonaProductivaPredio] PRIMARY KEY CLUSTERED ([zona_productiva_predio_id] ASC);
ALTER TABLE [geo].[ZonaProductivaUbicacion] ADD CONSTRAINT [PK_ZonaProductivaUbicacion] PRIMARY KEY CLUSTERED ([zona_productiva_ubicacion_id] ASC);
ALTER TABLE [integracion].[ConsultaDocumento] ADD CONSTRAINT [PK_ConsultaDocumento] PRIMARY KEY CLUSTERED ([consulta_documento_id] ASC);
ALTER TABLE [integracion].[IdentidadCampoOrigen] ADD CONSTRAINT [PK_IdentidadCampoOrigen] PRIMARY KEY CLUSTERED ([identidad_campo_origen_id] ASC);
ALTER TABLE [logistica].[Almacen] ADD CONSTRAINT [PK_Almacen] PRIMARY KEY CLUSTERED ([almacen_id] ASC);
ALTER TABLE [logistica].[AlmacenProductoEvento] ADD CONSTRAINT [PK__AlmacenP__CD5EEA79DF7E4D28] PRIMARY KEY CLUSTERED ([almacen_producto_evento_id] ASC);
ALTER TABLE [logistica].[AlmacenProductoStock] ADD CONSTRAINT [PK_AlmacenProductoStock] PRIMARY KEY CLUSTERED ([almacen_id] ASC,[producto_id] ASC);
ALTER TABLE [logistica].[AlmacenUOT] ADD CONSTRAINT [PK_AlmacenUOT] PRIMARY KEY CLUSTERED ([almacen_uot_id] ASC);
ALTER TABLE [logistica].[BienEstadoHistorial] ADD CONSTRAINT [PK_BienEstadoHistorial] PRIMARY KEY CLUSTERED ([bien_estado_historial_id] ASC);
ALTER TABLE [logistica].[BienImagen] ADD CONSTRAINT [PK_BienImagen] PRIMARY KEY CLUSTERED ([bien_imagen_id] ASC);
ALTER TABLE [logistica].[BienIncidente] ADD CONSTRAINT [PK_BienIncidente] PRIMARY KEY CLUSTERED ([bien_incidente_id] ASC);
ALTER TABLE [logistica].[BienInventario] ADD CONSTRAINT [PK_BienInventario] PRIMARY KEY CLUSTERED ([bien_inventario_id] ASC);
ALTER TABLE [logistica].[DetalleMovimientoInventario] ADD CONSTRAINT [PK_DetalleMovimientoInventario] PRIMARY KEY CLUSTERED ([detalle_movimiento_inventario_id] ASC);
ALTER TABLE [logistica].[EntregaTecnica] ADD CONSTRAINT [PK_EntregaTecnica] PRIMARY KEY CLUSTERED ([entrega_tecnica_id] ASC);
ALTER TABLE [logistica].[EntregaTecnicaDetalle] ADD CONSTRAINT [PK_EntregaTecnicaDetalle] PRIMARY KEY CLUSTERED ([entrega_tecnica_detalle_id] ASC);
ALTER TABLE [logistica].[MovimientoInventario] ADD CONSTRAINT [PK_MovimientoInventario] PRIMARY KEY CLUSTERED ([movimiento_inventario_id] ASC);
ALTER TABLE [logistica].[MovimientoInventarioLote] ADD CONSTRAINT [PK__Movimien__0B0CA93DCC2254C2] PRIMARY KEY CLUSTERED ([asignacion_lote_id] ASC);
ALTER TABLE [logistica].[Producto] ADD CONSTRAINT [PK_Producto] PRIMARY KEY CLUSTERED ([producto_id] ASC);
ALTER TABLE [logistica].[ProductoImagen] ADD CONSTRAINT [PK_ProductoImagen] PRIMARY KEY CLUSTERED ([producto_imagen_id] ASC);
ALTER TABLE [logistica].[ProductoPrecio] ADD CONSTRAINT [PK_ProductoPrecio] PRIMARY KEY CLUSTERED ([producto_precio_id] ASC);
ALTER TABLE [logistica].[ProductoUOTPolitica] ADD CONSTRAINT [PK_DESCO_ProductoUOTPolitica] PRIMARY KEY CLUSTERED ([uot_id] ASC,[producto_id] ASC);
ALTER TABLE [logistica].[ProgramacionProducto] ADD CONSTRAINT [PK__Programa__C28BABABD5BDD3F0] PRIMARY KEY CLUSTERED ([programacion_producto_id] ASC);
ALTER TABLE [logistica].[ProgramacionProductoEvento] ADD CONSTRAINT [PK__Programa__065DFF15F3E6EE71] PRIMARY KEY CLUSTERED ([programacion_producto_evento_id] ASC);
ALTER TABLE [logistica].[RecursoMovimiento] ADD CONSTRAINT [PK_RecursoMovimiento] PRIMARY KEY CLUSTERED ([recurso_movimiento_id] ASC);
ALTER TABLE [logistica].[RecursoProgramado] ADD CONSTRAINT [PK_RecursoProgramado] PRIMARY KEY CLUSTERED ([recurso_programado_id] ASC);
ALTER TABLE [logistica].[RecursoProgramadoArchivo] ADD CONSTRAINT [PK_DESCO_RPArchivo] PRIMARY KEY CLUSTERED ([recurso_programado_id] ASC,[archivo_id] ASC);
ALTER TABLE [logistica].[ReservaStock] ADD CONSTRAINT [PK_ReservaStock] PRIMARY KEY CLUSTERED ([reserva_stock_id] ASC);
ALTER TABLE [logistica].[SalidaBien] ADD CONSTRAINT [PK_SalidaBien] PRIMARY KEY CLUSTERED ([salida_bien_id] ASC);
ALTER TABLE [logistica].[Suministro] ADD CONSTRAINT [PK_Suministro] PRIMARY KEY CLUSTERED ([suministro_id] ASC);
ALTER TABLE [logistica].[SuministroMovimiento] ADD CONSTRAINT [PK_SuministroMovimiento] PRIMARY KEY CLUSTERED ([suministro_movimiento_id] ASC);
ALTER TABLE [logistica].[SuministroSaldo] ADD CONSTRAINT [PK_DESCO_SuministroSaldo] PRIMARY KEY CLUSTERED ([suministro_id] ASC);
ALTER TABLE [logistica].[SuministroSaldoConciliacion] ADD CONSTRAINT [PK__Suminist__32AC208E16A0325F] PRIMARY KEY CLUSTERED ([conciliacion_id] ASC);
ALTER TABLE [logistica].[TipoBien] ADD CONSTRAINT [PK_TipoBien] PRIMARY KEY CLUSTERED ([tipo_bien_id] ASC);
ALTER TABLE [logistica].[TransferenciaAlmacen] ADD CONSTRAINT [PK__Transfer__DBB1B9BB0041C3FA] PRIMARY KEY CLUSTERED ([transferencia_almacen_id] ASC);
ALTER TABLE [logistica].[UsoProductoTecnico] ADD CONSTRAINT [PK_UsoProductoTecnico] PRIMARY KEY CLUSTERED ([tipo_origen] ASC,[registro_id] ASC);
ALTER TABLE [logistica].[Vehiculo] ADD CONSTRAINT [PK_Vehiculo] PRIMARY KEY CLUSTERED ([vehiculo_id] ASC);
ALTER TABLE [org].[Area] ADD CONSTRAINT [PK_Area] PRIMARY KEY CLUSTERED ([area_id] ASC);
ALTER TABLE [org].[Asociacion] ADD CONSTRAINT [PK_Asociacion] PRIMARY KEY CLUSTERED ([asociacion_id] ASC);
ALTER TABLE [org].[ConvenioModuloEspecial] ADD CONSTRAINT [PK_ConvenioModuloEspecial] PRIMARY KEY CLUSTERED ([convenio_modulo_especial_id] ASC);
ALTER TABLE [org].[ConvenioUOTOrganizacion] ADD CONSTRAINT [PK_ConvenioUOTOrganizacion] PRIMARY KEY CLUSTERED ([convenio_uot_organizacion_id] ASC);
ALTER TABLE [org].[Empleado] ADD CONSTRAINT [PK_Empleado] PRIMARY KEY CLUSTERED ([empleado_id] ASC);
ALTER TABLE [org].[EmpleadoArea] ADD CONSTRAINT [PK_EmpleadoArea] PRIMARY KEY CLUSTERED ([empleado_area_id] ASC);
ALTER TABLE [org].[EmpleadoUOT] ADD CONSTRAINT [PK_EmpleadoUOT] PRIMARY KEY CLUSTERED ([empleado_uot_id] ASC);
ALTER TABLE [org].[Empresa] ADD CONSTRAINT [PK_Empresa] PRIMARY KEY CLUSTERED ([empresa_id] ASC);
ALTER TABLE [org].[Persona] ADD CONSTRAINT [PK_Persona] PRIMARY KEY CLUSTERED ([persona_id] ASC);
ALTER TABLE [org].[Productor] ADD CONSTRAINT [PK_E1_Productor] PRIMARY KEY CLUSTERED ([persona_id] ASC);
ALTER TABLE [org].[ProductorUOT] ADD CONSTRAINT [PK_E1_ProductorUOT] PRIMARY KEY CLUSTERED ([productor_uot_id] ASC);
ALTER TABLE [org].[Socio] ADD CONSTRAINT [PK_Socio] PRIMARY KEY CLUSTERED ([socio_id] ASC);
ALTER TABLE [org].[SocioAsociacion] ADD CONSTRAINT [PK_SocioAsociacion] PRIMARY KEY CLUSTERED ([socio_asociacion_id] ASC);
ALTER TABLE [org].[UOT] ADD CONSTRAINT [PK_UOT] PRIMARY KEY CLUSTERED ([uot_id] ASC);
ALTER TABLE [prod].[CensoPlantas] ADD CONSTRAINT [PK_CensoPlantas] PRIMARY KEY CLUSTERED ([censo_plantas_id] ASC);
ALTER TABLE [prod].[CrianzaConteo] ADD CONSTRAINT [PK__CrianzaC__5DEAA283BDFA7A4C] PRIMARY KEY CLUSTERED ([crianza_conteo_id] ASC);
ALTER TABLE [prod].[CrianzaLote] ADD CONSTRAINT [PK__CrianzaL__816F4FBA451AD1DB] PRIMARY KEY CLUSTERED ([crianza_lote_id] ASC);
ALTER TABLE [prod].[Cultivo] ADD CONSTRAINT [PK_Cultivo] PRIMARY KEY CLUSTERED ([cultivo_id] ASC);
ALTER TABLE [prod].[DisponibilidadProduccion] ADD CONSTRAINT [PK_DisponibilidadProduccion] PRIMARY KEY CLUSTERED ([disponibilidad_produccion_id] ASC);
ALTER TABLE [prod].[EspeciePecuaria] ADD CONSTRAINT [PK__EspecieP__7766E21340C3DC1B] PRIMARY KEY CLUSTERED ([especie_pecuaria_id] ASC);
ALTER TABLE [prod].[ExpedienteActuacion] ADD CONSTRAINT [PK__Expedien__3F7ACA732A7F21F0] PRIMARY KEY CLUSTERED ([expediente_actuacion_id] ASC);
ALTER TABLE [prod].[FundoAccionHistorial] ADD CONSTRAINT [PK__FundoAcc__68FE18EE5596D75E] PRIMARY KEY CLUSTERED ([historial_id] ASC);
ALTER TABLE [prod].[FundoAccionSolicitud] ADD CONSTRAINT [PK_FundoAccionSolicitud] PRIMARY KEY CLUSTERED ([usuario_id] ASC,[clave] ASC);
ALTER TABLE [prod].[FundoHabilitacion] ADD CONSTRAINT [PK_FundoHabilitacion] PRIMARY KEY CLUSTERED ([predio_id] ASC,[convenio_id] ASC);
ALTER TABLE [prod].[FundoProduccionE3] ADD CONSTRAINT [PK_FundoProduccionE3] PRIMARY KEY CLUSTERED ([fundo_produccion_id] ASC);
ALTER TABLE [prod].[FundoProduccionHistorialE3] ADD CONSTRAINT [PK_FundoProduccionHistorialE3] PRIMARY KEY CLUSTERED ([historial_id] ASC);
ALTER TABLE [prod].[FundoProduccionSolicitudE3] ADD CONSTRAINT [PK_FundoProduccionSolicitudE3] PRIMARY KEY CLUSTERED ([solicitud_id] ASC);
ALTER TABLE [prod].[GPActividad] ADD CONSTRAINT [PK_GPActividad] PRIMARY KEY CLUSTERED ([actividad_id] ASC);
ALTER TABLE [prod].[GPActividadRevision] ADD CONSTRAINT [PK_GPActividadRevision] PRIMARY KEY CLUSTERED ([revision_id] ASC);
ALTER TABLE [prod].[GPBajaLogica] ADD CONSTRAINT [PK__GPBajaLo__9E4ACA0B994CA3E4] PRIMARY KEY CLUSTERED ([baja_id] ASC);
ALTER TABLE [prod].[GPCenso] ADD CONSTRAINT [PK_GPCenso] PRIMARY KEY CLUSTERED ([censo_id] ASC);
ALTER TABLE [prod].[GPCensoRaza] ADD CONSTRAINT [PK_GPCensoRaza] PRIMARY KEY CLUSTERED ([censo_id] ASC,[raza_id] ASC);
ALTER TABLE [prod].[GPCensoVariedad] ADD CONSTRAINT [PK_GPCensoVariedad] PRIMARY KEY CLUSTERED ([censo_id] ASC,[variedad_cultivo_id] ASC);
ALTER TABLE [prod].[GPEvento] ADD CONSTRAINT [PK_GPEvento] PRIMARY KEY CLUSTERED ([evento_id] ASC);
ALTER TABLE [prod].[GPEventoFoto] ADD CONSTRAINT [PK_GPEventoFoto] PRIMARY KEY CLUSTERED ([foto_id] ASC);
ALTER TABLE [prod].[GPIncidencia] ADD CONSTRAINT [PK_GPIncidencia] PRIMARY KEY CLUSTERED ([incidencia_id] ASC);
ALTER TABLE [prod].[GPIncidenciaRevision] ADD CONSTRAINT [PK_GPIncidenciaRevision] PRIMARY KEY CLUSTERED ([revision_id] ASC);
ALTER TABLE [prod].[GPIncidenciaTratamiento] ADD CONSTRAINT [PK_GPIncidenciaTratamiento] PRIMARY KEY CLUSTERED ([evento_id] ASC);
ALTER TABLE [prod].[GPParcelaSolicitud] ADD CONSTRAINT [PK__GPParcel__0CB3B442571849DB] PRIMARY KEY CLUSTERED ([solicitud_id] ASC);
ALTER TABLE [prod].[GPProblema] ADD CONSTRAINT [PK_GPProblema] PRIMARY KEY CLUSTERED ([problema_id] ASC);
ALTER TABLE [prod].[GPProblemaTratamiento] ADD CONSTRAINT [PK_GPProblemaTratamiento] PRIMARY KEY CLUSTERED ([problema_id] ASC,[tratamiento_id] ASC);
ALTER TABLE [prod].[GPRaza] ADD CONSTRAINT [PK_GPRaza] PRIMARY KEY CLUSTERED ([raza_id] ASC);
ALTER TABLE [prod].[GPTratamiento] ADD CONSTRAINT [PK_GPTratamiento] PRIMARY KEY CLUSTERED ([tratamiento_id] ASC);
ALTER TABLE [prod].[Parcela] ADD CONSTRAINT [PK_Parcela] PRIMARY KEY CLUSTERED ([parcela_id] ASC);
ALTER TABLE [prod].[ParcelaCultivo] ADD CONSTRAINT [PK_ParcelaCultivo] PRIMARY KEY CLUSTERED ([parcela_cultivo_id] ASC);
ALTER TABLE [prod].[PlantaComentarioE3] ADD CONSTRAINT [PK_E3_PlantaComentario] PRIMARY KEY CLUSTERED ([comentario_id] ASC);
ALTER TABLE [prod].[PlantaCorrelativoE3] ADD CONSTRAINT [PK_E3_Correlativo] PRIMARY KEY CLUSTERED ([predio_id] ASC,[variedad_palta_id] ASC);
ALTER TABLE [prod].[PlantaEventoE3] ADD CONSTRAINT [PK__PlantaEv__1850C3AD1247E197] PRIMARY KEY CLUSTERED ([evento_id] ASC);
ALTER TABLE [prod].[PlantaEvidenciaE3] ADD CONSTRAINT [PK__PlantaEv__DF08B6B16AE9D029] PRIMARY KEY CLUSTERED ([planta_evidencia_id] ASC);
ALTER TABLE [prod].[PlantaFichaHistorialE3] ADD CONSTRAINT [PK__PlantaFi__4F1F75DE9363B417] PRIMARY KEY CLUSTERED ([ficha_id] ASC);
ALTER TABLE [prod].[PlantaMateriaSecaIndividualE4] ADD CONSTRAINT [PK_E4_SecaIndividual] PRIMARY KEY CLUSTERED ([medicion_id] ASC);
ALTER TABLE [prod].[PlantaMedicionE3] ADD CONSTRAINT [PK_E3_Medicion] PRIMARY KEY CLUSTERED ([medicion_id] ASC);
ALTER TABLE [prod].[PlantaPaltaE3] ADD CONSTRAINT [PK_E3_Planta] PRIMARY KEY CLUSTERED ([planta_id] ASC);
ALTER TABLE [prod].[PlantaSolicitudE3] ADD CONSTRAINT [PK_E3_Idempotencia] PRIMARY KEY CLUSTERED ([usuario_id] ASC,[accion] ASC,[clave] ASC);
ALTER TABLE [prod].[Predio] ADD CONSTRAINT [PK_Predio] PRIMARY KEY CLUSTERED ([predio_id] ASC);
ALTER TABLE [prod].[PredioAmbito] ADD CONSTRAINT [PK__PredioAm__1C243C06372804E0] PRIMARY KEY CLUSTERED ([predio_ambito_id] ASC);
ALTER TABLE [prod].[PredioIdentidad] ADD CONSTRAINT [PK_E1_PredioIdentidad] PRIMARY KEY CLUSTERED ([persona_id] ASC,[distrito_codigo] ASC,[nombre_normalizado] ASC);
ALTER TABLE [prod].[PredioMateriaSecaCambioE4] ADD CONSTRAINT [PK_E4_SecaCambio] PRIMARY KEY CLUSTERED ([cambio_id] ASC);
ALTER TABLE [prod].[PredioMateriaSecaGlobalE4] ADD CONSTRAINT [PK_E4_SecaGlobal] PRIMARY KEY CLUSTERED ([informe_id] ASC);
ALTER TABLE [prod].[PredioTitularidad] ADD CONSTRAINT [PK_PredioTitularidad] PRIMARY KEY CLUSTERED ([predio_titularidad_id] ASC);
ALTER TABLE [prod].[PredioVersion] ADD CONSTRAINT [PK_PredioVersion] PRIMARY KEY CLUSTERED ([predio_version_id] ASC);
ALTER TABLE [prod].[ProduccionPlantaE3] ADD CONSTRAINT [PK__Producci__D3AC4FABC46821DA] PRIMARY KEY CLUSTERED ([produccion_id] ASC);
ALTER TABLE [prod].[TipoTitularidadCatalogo] ADD CONSTRAINT [PK_GP_TipoTitularidadCatalogo] PRIMARY KEY CLUSTERED ([tipo_titularidad_id] ASC);
ALTER TABLE [prod].[VariedadCultivo] ADD CONSTRAINT [PK_VariedadCultivo] PRIMARY KEY CLUSTERED ([variedad_cultivo_id] ASC);
ALTER TABLE [prod].[VariedadPalta] ADD CONSTRAINT [PK_VariedadPalta] PRIMARY KEY CLUSTERED ([variedad_palta_id] ASC);
ALTER TABLE [reporte].[TrabajoEspecial] ADD CONSTRAINT [PK_TrabajoEspecial] PRIMARY KEY CLUSTERED ([trabajo_id] ASC);
ALTER TABLE [reporte].[TrabajoExcel] ADD CONSTRAINT [PK_TrabajoExcel] PRIMARY KEY CLUSTERED ([trabajo_id] ASC);
ALTER TABLE [sanidad].[CasoFitosanitario] ADD CONSTRAINT [PK_CasoFitosanitario] PRIMARY KEY CLUSTERED ([caso_fitosanitario_id] ASC);
ALTER TABLE [sanidad].[EpisodioNotaE4] ADD CONSTRAINT [PK_E4_EpisodioNota] PRIMARY KEY CLUSTERED ([nota_id] ASC);
ALTER TABLE [sanidad].[EpisodioPlantaE3] ADD CONSTRAINT [PK__Episodio__0A2A533F25504C06] PRIMARY KEY CLUSTERED ([episodio_id] ASC);
ALTER TABLE [sanidad].[PlantaSeguimientoE3] ADD CONSTRAINT [PK__PlantaSe__24D3E5E8CC1FFF78] PRIMARY KEY CLUSTERED ([seguimiento_id] ASC);
ALTER TABLE [sanidad].[SeguimientoFitosanitario] ADD CONSTRAINT [PK_SeguimientoFitosanitario] PRIMARY KEY CLUSTERED ([seguimiento_fitosanitario_id] ASC);
ALTER TABLE [sanidad].[TipoProblemaFitosanitario] ADD CONSTRAINT [PK_TipoProblemaFitosanitario] PRIMARY KEY CLUSTERED ([tipo_problema_fitosanitario_id] ASC);
ALTER TABLE [sanidad].[TratamientoAplicacionE4] ADD CONSTRAINT [PK_E4_TratamientoAplicacion] PRIMARY KEY CLUSTERED ([aplicacion_id] ASC);
ALTER TABLE [sanidad].[TratamientoArchivoE4] ADD CONSTRAINT [PK_E3_TratamientoArchivoE4] PRIMARY KEY CLUSTERED ([tratamiento_archivo_id] ASC);
ALTER TABLE [sanidad].[TratamientoEdicionE3] ADD CONSTRAINT [PK_E3_TratamientoEdicion] PRIMARY KEY CLUSTERED ([tratamiento_edicion_id] ASC);
ALTER TABLE [sanidad].[TratamientoFitosanitario] ADD CONSTRAINT [PK_TratamientoFitosanitario] PRIMARY KEY CLUSTERED ([tratamiento_fitosanitario_id] ASC);
ALTER TABLE [sanidad].[TratamientoPlantaE3] ADD CONSTRAINT [PK__Tratamie__22997E7A72EC2665] PRIMARY KEY CLUSTERED ([tratamiento_id] ASC);
ALTER TABLE [seg].[CodigoUnSoloUso] ADD CONSTRAINT [PK_CodigoUnSoloUso] PRIMARY KEY CLUSTERED ([codigo_un_solo_uso_id] ASC);
ALTER TABLE [seg].[DispositivoUsuario] ADD CONSTRAINT [PK_DispositivoUsuario] PRIMARY KEY CLUSTERED ([dispositivo_usuario_id] ASC);
ALTER TABLE [seg].[HistorialPassword] ADD CONSTRAINT [PK_HistorialPassword] PRIMARY KEY CLUSTERED ([historial_password_id] ASC);
ALTER TABLE [seg].[IntentoAutenticacion] ADD CONSTRAINT [PK_IntentoAutenticacion] PRIMARY KEY CLUSTERED ([intento_autenticacion_id] ASC);
ALTER TABLE [seg].[Modulo] ADD CONSTRAINT [PK_Modulo] PRIMARY KEY CLUSTERED ([modulo_id] ASC);
ALTER TABLE [seg].[ModuloEspecial] ADD CONSTRAINT [PK_ModuloEspecial] PRIMARY KEY CLUSTERED ([modulo_especial_id] ASC);
ALTER TABLE [seg].[ModuloEspecialPermiso] ADD CONSTRAINT [PK_ModuloEspecialPermiso] PRIMARY KEY CLUSTERED ([modulo_especial_id] ASC,[permiso_id] ASC);
ALTER TABLE [seg].[NotificacionSeguridad] ADD CONSTRAINT [PK_NotificacionSeguridad] PRIMARY KEY CLUSTERED ([notificacion_seguridad_id] ASC);
ALTER TABLE [seg].[Permiso] ADD CONSTRAINT [PK_Permiso] PRIMARY KEY CLUSTERED ([permiso_id] ASC);
ALTER TABLE [seg].[PoliticaSeguridad] ADD CONSTRAINT [PK_PoliticaSeguridad] PRIMARY KEY CLUSTERED ([politica_seguridad_id] ASC);
ALTER TABLE [seg].[RefreshTokenSesion] ADD CONSTRAINT [PK_RefreshTokenSesion] PRIMARY KEY CLUSTERED ([refresh_token_sesion_id] ASC);
ALTER TABLE [seg].[Rol] ADD CONSTRAINT [PK_Rol] PRIMARY KEY CLUSTERED ([rol_id] ASC);
ALTER TABLE [seg].[RolPermiso] ADD CONSTRAINT [PK_RolPermiso] PRIMARY KEY CLUSTERED ([rol_id] ASC,[permiso_id] ASC);
ALTER TABLE [seg].[SesionUsuario] ADD CONSTRAINT [PK_SesionUsuario] PRIMARY KEY CLUSTERED ([sesion_usuario_id] ASC);
ALTER TABLE [seg].[TokenAccesoRevocado] ADD CONSTRAINT [PK_TokenAccesoRevocado] PRIMARY KEY CLUSTERED ([token_acceso_revocado_id] ASC);
ALTER TABLE [seg].[Usuario] ADD CONSTRAINT [PK_Usuario] PRIMARY KEY CLUSTERED ([usuario_id] ASC);
ALTER TABLE [seg].[UsuarioCorreoSeguridad] ADD CONSTRAINT [PK_UsuarioCorreoSeguridad] PRIMARY KEY CLUSTERED ([usuario_correo_seguridad_id] ASC);
ALTER TABLE [seg].[UsuarioRol] ADD CONSTRAINT [PK_UsuarioRol] PRIMARY KEY CLUSTERED ([usuario_rol_id] ASC);
ALTER TABLE [seg].[UsuarioUOT] ADD CONSTRAINT [PK_UsuarioUOT] PRIMARY KEY CLUSTERED ([usuario_uot_id] ASC);
ALTER TABLE [seg].[UsuarioUOTPermiso] ADD CONSTRAINT [PK_UsuarioUOTPermiso] PRIMARY KEY CLUSTERED ([usuario_uot_permiso_id] ASC);
ALTER TABLE [seg].[UsuarioUOTRol] ADD CONSTRAINT [PK_UsuarioUOTRol] PRIMARY KEY CLUSTERED ([usuario_uot_rol_id] ASC);
ALTER TABLE [auditoria].[OperacionIdempotente] ADD CONSTRAINT [UQ_OperacionIdempotente_Clave] UNIQUE NONCLUSTERED ([usuario_id] ASC,[ambito] ASC,[clave_idempotencia] ASC);
ALTER TABLE [campo].[MotivoSalida] ADD CONSTRAINT [UQ_MotivoSalida_Codigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [campo].[SalidaDestinoE2] ADD CONSTRAINT [UQ_E2_DestinoOrden] UNIQUE NONCLUSTERED ([salida_campo_id] ASC,[orden] ASC);
ALTER TABLE [campo].[SalidaOperacionE2] ADD CONSTRAINT [UX_E2_Operacion] UNIQUE NONCLUSTERED ([usuario_id] ASC,[tipo] ASC,[idempotencia] ASC);
ALTER TABLE [campo].[SalidaParticipante] ADD CONSTRAINT [UQ_SalidaParticipante] UNIQUE NONCLUSTERED ([salida_campo_id] ASC,[empleado_id] ASC);
ALTER TABLE [campo].[TipoEvaluacion] ADD CONSTRAINT [UQ_TipoEvaluacion_Codigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [campo].[TipoVisitaE2] ADD CONSTRAINT [UQ__TipoVisi__40F9A2066C81CD17] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [comercial].[Boleta] ADD CONSTRAINT [UQ_Boleta_SerieNumero] UNIQUE NONCLUSTERED ([serie] ASC,[numero] ASC);
ALTER TABLE [comercial].[Boleta] ADD CONSTRAINT [UQ_Boleta_Venta] UNIQUE NONCLUSTERED ([venta_id] ASC);
ALTER TABLE [comercial].[CajaEvidencia] ADD CONSTRAINT [UQ_CajaEvidencia_Archivo] UNIQUE NONCLUSTERED ([archivo_id] ASC);
ALTER TABLE [comercial].[CajaMovimiento] ADD CONSTRAINT [UQ_CajaMovimiento_Idempotencia] UNIQUE NONCLUSTERED ([clave_idempotencia] ASC);
ALTER TABLE [comercial].[CajaPOS] ADD CONSTRAINT [UQ_CajaPOS_UotCodigo] UNIQUE NONCLUSTERED ([uot_id] ASC,[codigo] ASC);
ALTER TABLE [comercial].[CampaniaCalibre] ADD CONSTRAINT [UQ_CampaniaCalibre_CampaniaVariedadCalibre] UNIQUE NONCLUSTERED ([campania_venta_id] ASC,[variedad_palta_id] ASC,[calibre] ASC);
ALTER TABLE [comercial].[CampaniaCalibrePrecioVersion] ADD CONSTRAINT [UQ_CampaniaCalibrePrecioVersion] UNIQUE NONCLUSTERED ([campania_calibre_id] ASC,[version] ASC);
ALTER TABLE [comercial].[CampaniaJabaPlan] ADD CONSTRAINT [UQ_CampaniaJabaPlan_Participante] UNIQUE NONCLUSTERED ([participacion_campania_socio_id] ASC);
ALTER TABLE [comercial].[CampaniaJabaRecepcion] ADD CONSTRAINT [UQ_CampaniaJabaRecepcion_PlanNumero] UNIQUE NONCLUSTERED ([campania_jaba_plan_id] ASC,[numero_jaba] ASC);
ALTER TABLE [comercial].[CampaniaSancionTarifa] ADD CONSTRAINT [UQ_CampaniaSancionTarifa] UNIQUE NONCLUSTERED ([campania_venta_id] ASC,[sancion_venta_id] ASC);
ALTER TABLE [comercial].[CampaniaSocioSancion] ADD CONSTRAINT [UQ_CampaniaSocioSancion_Socio] UNIQUE NONCLUSTERED ([participacion_campania_socio_id] ASC);
ALTER TABLE [comercial].[CampaniaVenta] ADD CONSTRAINT [UQ_CampaniaVenta_Codigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [comercial].[CargoConceptoE4] ADD CONSTRAINT [UQ__CargoCon__40F9A20621E1AB9E] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [comercial].[CargoIndividualE4] ADD CONSTRAINT [UQ_CargoIndividualE4_unico] UNIQUE NONCLUSTERED ([jaba_asignacion_id] ASC,[concepto_id] ASC);
ALTER TABLE [comercial].[CatalogoSancionVenta] ADD CONSTRAINT [UQ_CatalogoSancionVenta_Codigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [comercial].[CondicionComercial] ADD CONSTRAINT [UQ_CondicionComercial_Codigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [comercial].[EntregaSocio] ADD CONSTRAINT [UQ_EntregaSocio_CodigoLote] UNIQUE NONCLUSTERED ([codigo_lote] ASC);
ALTER TABLE [comercial].[Factura] ADD CONSTRAINT [UQ_Factura_SerieNumero] UNIQUE NONCLUSTERED ([serie] ASC,[numero] ASC);
ALTER TABLE [comercial].[Factura] ADD CONSTRAINT [UQ_Factura_Venta] UNIQUE NONCLUSTERED ([venta_id] ASC);
ALTER TABLE [comercial].[IncidenciaFaltanteE4] ADD CONSTRAINT [UQ__Incidenc__116FB4E973925C6E] UNIQUE NONCLUSTERED ([jaba_asignacion_id] ASC);
ALTER TABLE [comercial].[JabaClasificacionE4] ADD CONSTRAINT [UQ_JabaClasificacionE4_Orden] UNIQUE NONCLUSTERED ([unidad_id] ASC,[numero] ASC);
ALTER TABLE [comercial].[JabaUnidadE4] ADD CONSTRAINT [UQ_JabaUnidadE4_asignacion_numero] UNIQUE NONCLUSTERED ([jaba_asignacion_id] ASC,[numero] ASC);
ALTER TABLE [comercial].[MetodoPago] ADD CONSTRAINT [UQ_MetodoPago_Codigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [comercial].[ModalidadVenta] ADD CONSTRAINT [UQ_ModalidadVenta_Codigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [comercial].[OperativoSocio] ADD CONSTRAINT [UQ_OperativoSocio] UNIQUE NONCLUSTERED ([operativo_venta_id] ASC,[participacion_campania_socio_id] ASC);
ALTER TABLE [comercial].[OperativoVenta] ADD CONSTRAINT [UQ_OperativoVenta_Id_Campania] UNIQUE NONCLUSTERED ([operativo_venta_id] ASC,[campania_venta_id] ASC);
ALTER TABLE [comercial].[OperativoVenta] ADD CONSTRAINT [UQ_OperativoVenta_Campania_Codigo] UNIQUE NONCLUSTERED ([campania_venta_id] ASC,[codigo] ASC);
ALTER TABLE [comercial].[ParticipacionCampaniaSocio] ADD CONSTRAINT [UQ_ParticipacionCampaniaSocio] UNIQUE NONCLUSTERED ([campania_venta_id] ASC,[socio_asociacion_id] ASC);
ALTER TABLE [comercial].[PrecioComercial] ADD CONSTRAINT [UQ_PrecioComercial_Version] UNIQUE NONCLUSTERED ([campania_venta_id] ASC,[operativo_venta_id] ASC,[variedad_palta_id] ASC,[condicion_comercial_id] ASC,[version] ASC);
ALTER TABLE [comercial].[Venta] ADD CONSTRAINT [UQ_Venta_Idempotencia] UNIQUE NONCLUSTERED ([clave_idempotencia] ASC);
ALTER TABLE [config].[CatalogoRecursoValor] ADD CONSTRAINT [UQ_CatalogoRecursoValor] UNIQUE NONCLUSTERED ([catalogo] ASC,[codigo] ASC);
ALTER TABLE [config].[DashboardElemento] ADD CONSTRAINT [UQ_DashboardElemento_Codigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [config].[TipoDocumentoComprador] ADD CONSTRAINT [UQ_TipoDocumentoComprador_Codigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [finanzas].[GastoProrrateoSocio] ADD CONSTRAINT [UQ_GastoProrrateoSocio] UNIQUE NONCLUSTERED ([gasto_campania_id] ASC,[participacion_campania_socio_id] ASC);
ALTER TABLE [finanzas].[GastoRepartoVersionE5] ADD CONSTRAINT [UQ_GastoRepartoVersionE5] UNIQUE NONCLUSTERED ([gasto_campania_id] ASC,[version] ASC);
ALTER TABLE [finanzas].[LiquidacionSocio] ADD CONSTRAINT [UQ_LiquidacionSocio_Version] UNIQUE NONCLUSTERED ([participacion_campania_socio_id] ASC,[version] ASC);
ALTER TABLE [finanzas].[ReglaProrrateo] ADD CONSTRAINT [UQ_ReglaProrrateo_Codigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [finanzas].[TipoGasto] ADD CONSTRAINT [UQ_TipoGasto_Codigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [geo].[CentroPoblado] ADD CONSTRAINT [UQ_CentroPoblado_Id_Distrito] UNIQUE NONCLUSTERED ([centro_poblado_id] ASC,[distrito_codigo] ASC);
ALTER TABLE [geo].[CentroPoblado] ADD CONSTRAINT [UQ_CentroPoblado_Distrito_Nombre] UNIQUE NONCLUSTERED ([distrito_codigo] ASC,[nombre] ASC);
ALTER TABLE [geo].[Departamento] ADD CONSTRAINT [UQ_Departamento_Nombre] UNIQUE NONCLUSTERED ([nombre] ASC);
ALTER TABLE [geo].[Distrito] ADD CONSTRAINT [UQ_Distrito_Provincia_Nombre] UNIQUE NONCLUSTERED ([provincia_codigo] ASC,[nombre] ASC);
ALTER TABLE [geo].[Provincia] ADD CONSTRAINT [UQ_Provincia_Departamento_Nombre] UNIQUE NONCLUSTERED ([departamento_codigo] ASC,[nombre] ASC);
ALTER TABLE [geo].[ZonaProductiva] ADD CONSTRAINT [UQ_ZonaProductiva_Codigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [geo].[ZonaProductivaPredio] ADD CONSTRAINT [UQ_ZonaProductivaPredio_Periodo] UNIQUE NONCLUSTERED ([zona_productiva_id] ASC,[predio_id] ASC,[fecha_desde] ASC);
ALTER TABLE [geo].[ZonaProductivaUbicacion] ADD CONSTRAINT [UQ_ZonaProductivaUbicacion_Periodo] UNIQUE NONCLUSTERED ([zona_productiva_id] ASC,[distrito_codigo] ASC,[centro_poblado_id] ASC,[fecha_desde] ASC);
ALTER TABLE [integracion].[ConsultaDocumento] ADD CONSTRAINT [UQ_ConsultaDocumento_Clave] UNIQUE NONCLUSTERED ([entidad_objetivo] ASC,[clave_documento] ASC);
ALTER TABLE [integracion].[IdentidadCampoOrigen] ADD CONSTRAINT [UQ_IdentidadCampoOrigen] UNIQUE NONCLUSTERED ([entidad_objetivo] ASC,[entidad_id] ASC,[campo] ASC,[proveedor] ASC);
ALTER TABLE [logistica].[Almacen] ADD CONSTRAINT [UQ_Almacen_UOT_Codigo] UNIQUE NONCLUSTERED ([uot_propietaria_id] ASC,[codigo] ASC);
ALTER TABLE [logistica].[AlmacenProductoEvento] ADD CONSTRAINT [UQ_AlmacenProductoEvento_Clave] UNIQUE NONCLUSTERED ([clave_idempotencia] ASC);
ALTER TABLE [logistica].[BienImagen] ADD CONSTRAINT [UQ_BienImagen] UNIQUE NONCLUSTERED ([bien_inventario_id] ASC,[archivo_id] ASC);
ALTER TABLE [logistica].[BienInventario] ADD CONSTRAINT [UQ_BienInventario_CodigoPatrimonial] UNIQUE NONCLUSTERED ([codigo_patrimonial] ASC);
ALTER TABLE [logistica].[EntregaTecnicaDetalle] ADD CONSTRAINT [UQ_EntregaTecnicaDetalle_Producto] UNIQUE NONCLUSTERED ([entrega_tecnica_id] ASC,[producto_id] ASC);
ALTER TABLE [logistica].[MovimientoInventario] ADD CONSTRAINT [UQ_MovimientoInventario_Idempotencia] UNIQUE NONCLUSTERED ([clave_idempotencia] ASC);
ALTER TABLE [logistica].[Producto] ADD CONSTRAINT [UQ_Producto_Codigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [logistica].[ProductoImagen] ADD CONSTRAINT [UQ_ProductoImagen] UNIQUE NONCLUSTERED ([producto_id] ASC,[archivo_id] ASC);
ALTER TABLE [logistica].[ProductoPrecio] ADD CONSTRAINT [UQ_ProductoPrecio_Version] UNIQUE NONCLUSTERED ([producto_id] ASC,[uot_id] ASC,[version] ASC);
ALTER TABLE [logistica].[ProgramacionProducto] ADD CONSTRAINT [UQ_DESCO_PP_Clave] UNIQUE NONCLUSTERED ([clave_idempotencia] ASC);
ALTER TABLE [logistica].[ProgramacionProductoEvento] ADD CONSTRAINT [UQ_DESCO_PPEvento_Clave] UNIQUE NONCLUSTERED ([clave_idempotencia] ASC);
ALTER TABLE [logistica].[ReservaStock] ADD CONSTRAINT [UQ_ReservaStock_Detalle] UNIQUE NONCLUSTERED ([detalle_venta_id] ASC);
ALTER TABLE [logistica].[SalidaBien] ADD CONSTRAINT [UQ_SalidaBien] UNIQUE NONCLUSTERED ([salida_campo_id] ASC,[bien_inventario_id] ASC);
ALTER TABLE [logistica].[TipoBien] ADD CONSTRAINT [UQ_TipoBien_Codigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [logistica].[TransferenciaAlmacen] ADD CONSTRAINT [UQ_DESCO_TransferClave] UNIQUE NONCLUSTERED ([clave_idempotencia] ASC);
ALTER TABLE [logistica].[UsoProductoTecnico] ADD CONSTRAINT [UQ_UsoProductoTecnico_Evento] UNIQUE NONCLUSTERED ([evento_id] ASC);
ALTER TABLE [org].[ConvenioModuloEspecial] ADD CONSTRAINT [UQ_ConvenioModuloEspecial] UNIQUE NONCLUSTERED ([convenio_uot_organizacion_id] ASC,[modulo_especial_id] ASC);
ALTER TABLE [org].[Empresa] ADD CONSTRAINT [UQ_Empresa_RUC] UNIQUE NONCLUSTERED ([ruc] ASC);
ALTER TABLE [org].[Persona] ADD CONSTRAINT [UQ_Persona_Documento] UNIQUE NONCLUSTERED ([tipo_documento] ASC,[numero_documento] ASC);
ALTER TABLE [org].[ProductorUOT] ADD CONSTRAINT [UQ_E1_ProductorUOTPeriodo] UNIQUE NONCLUSTERED ([persona_id] ASC,[uot_id] ASC,[fecha_desde] ASC);
ALTER TABLE [org].[SocioAsociacion] ADD CONSTRAINT [UQ_SocioAsociacion_Periodo] UNIQUE NONCLUSTERED ([socio_id] ASC,[asociacion_id] ASC,[fecha_desde] ASC);
ALTER TABLE [org].[SocioAsociacion] ADD CONSTRAINT [UQ_SocioAsociacion_Codigo] UNIQUE NONCLUSTERED ([asociacion_id] ASC,[codigo_socio] ASC);
ALTER TABLE [org].[UOT] ADD CONSTRAINT [UQ_UOT_Codigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [prod].[CensoPlantas] ADD CONSTRAINT [UQ_CensoPlantas_Cultivo_Fecha] UNIQUE NONCLUSTERED ([parcela_cultivo_id] ASC,[fecha_censo] ASC);
ALTER TABLE [prod].[Cultivo] ADD CONSTRAINT [UQ_Cultivo_Codigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [prod].[DisponibilidadProduccion] ADD CONSTRAINT [UQ_DisponibilidadProduccion_Estimacion] UNIQUE NONCLUSTERED ([parcela_cultivo_id] ASC,[fecha_estimacion] ASC);
ALTER TABLE [prod].[EspeciePecuaria] ADD CONSTRAINT [UQ__EspecieP__40F9A206A5763223] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [prod].[FundoProduccionE3] ADD CONSTRAINT [UQ_FundoProduccionE3_AmbitoAnio] UNIQUE NONCLUSTERED ([predio_id] ASC,[convenio_id] ASC,[anio] ASC);
ALTER TABLE [prod].[FundoProduccionSolicitudE3] ADD CONSTRAINT [UQ_FundoProduccionSolicitudE3_Clave] UNIQUE NONCLUSTERED ([usuario_id] ASC,[clave] ASC);
ALTER TABLE [prod].[GPActividad] ADD CONSTRAINT [UQ_GPActividad_Solicitud] UNIQUE NONCLUSTERED ([solicitud_id] ASC);
ALTER TABLE [prod].[GPActividadRevision] ADD CONSTRAINT [UQ_GPActividadRevision_Solicitud] UNIQUE NONCLUSTERED ([solicitud_id] ASC);
ALTER TABLE [prod].[GPBajaLogica] ADD CONSTRAINT [UQ__GPBajaLo__0CB3B44387EE4F8F] UNIQUE NONCLUSTERED ([solicitud_id] ASC);
ALTER TABLE [prod].[GPCenso] ADD CONSTRAINT [UQ_GPCenso_Solicitud] UNIQUE NONCLUSTERED ([solicitud_id] ASC);
ALTER TABLE [prod].[GPEvento] ADD CONSTRAINT [UQ_GPEvento_Solicitud] UNIQUE NONCLUSTERED ([solicitud_id] ASC);
ALTER TABLE [prod].[GPEventoFoto] ADD CONSTRAINT [UQ_GPEventoFoto_Archivo] UNIQUE NONCLUSTERED ([archivo_interno] ASC);
ALTER TABLE [prod].[GPIncidenciaRevision] ADD CONSTRAINT [UQ_GPIncidenciaRevision_Solicitud] UNIQUE NONCLUSTERED ([solicitud_id] ASC);
ALTER TABLE [prod].[Parcela] ADD CONSTRAINT [UQ_Parcela_Predio_Codigo] UNIQUE NONCLUSTERED ([predio_id] ASC,[codigo] ASC);
ALTER TABLE [prod].[PlantaEvidenciaE3] ADD CONSTRAINT [UQ_E3_Evidencia] UNIQUE NONCLUSTERED ([planta_id] ASC,[archivo_id] ASC);
ALTER TABLE [prod].[PlantaFichaHistorialE3] ADD CONSTRAINT [UX_E3_FichaVersion] UNIQUE NONCLUSTERED ([planta_id] ASC,[version] ASC);
ALTER TABLE [prod].[PlantaPaltaE3] ADD CONSTRAINT [UQ_E3_PlantaNumero] UNIQUE NONCLUSTERED ([predio_id] ASC,[variedad_palta_id] ASC,[secuencia] ASC);
ALTER TABLE [prod].[PlantaPaltaE3] ADD CONSTRAINT [UQ_E3_PlantaCodigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [prod].[Predio] ADD CONSTRAINT [UQ_Predio_Codigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [prod].[PredioAmbito] ADD CONSTRAINT [UQ_E1_PredioAmbito] UNIQUE NONCLUSTERED ([predio_id] ASC,[uot_id] ASC,[convenio_uot_organizacion_id] ASC);
ALTER TABLE [prod].[TipoTitularidadCatalogo] ADD CONSTRAINT [UQ_GP_TipoTitularidadCodigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [prod].[VariedadCultivo] ADD CONSTRAINT [UQ_VariedadCultivo_Codigo] UNIQUE NONCLUSTERED ([cultivo_id] ASC,[codigo] ASC);
ALTER TABLE [prod].[VariedadPalta] ADD CONSTRAINT [UQ_VariedadPalta_Codigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [reporte].[TrabajoEspecial] ADD CONSTRAINT [UQ_TrabajoEspecial] UNIQUE NONCLUSTERED ([usuario_id] ASC,[clave] ASC);
ALTER TABLE [reporte].[TrabajoExcel] ADD CONSTRAINT [UQ_TrabajoExcel_Idempotencia] UNIQUE NONCLUSTERED ([usuario_id] ASC,[idempotencia] ASC);
ALTER TABLE [sanidad].[PlantaSeguimientoE3] ADD CONSTRAINT [UQ__PlantaSe__1850C3AC4D5EFA34] UNIQUE NONCLUSTERED ([evento_id] ASC);
ALTER TABLE [sanidad].[TipoProblemaFitosanitario] ADD CONSTRAINT [UQ_TipoProblemaFitosanitario_Codigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [sanidad].[TratamientoArchivoE4] ADD CONSTRAINT [UQ_E3_TratamientoArchivo] UNIQUE NONCLUSTERED ([aplicacion_id] ASC,[archivo_id] ASC);
ALTER TABLE [seg].[DispositivoUsuario] ADD CONSTRAINT [UQ_DispositivoUsuario_Huella] UNIQUE NONCLUSTERED ([usuario_id] ASC,[identificador_logico_hash] ASC);
ALTER TABLE [seg].[Modulo] ADD CONSTRAINT [UQ_Modulo_Codigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [seg].[ModuloEspecial] ADD CONSTRAINT [UQ_ModuloEspecial_Codigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [seg].[Permiso] ADD CONSTRAINT [UQ_Permiso_Modulo_Codigo] UNIQUE NONCLUSTERED ([modulo_id] ASC,[codigo] ASC);
ALTER TABLE [seg].[PoliticaSeguridad] ADD CONSTRAINT [UQ_PoliticaSeguridad_CodigoFecha] UNIQUE NONCLUSTERED ([codigo] ASC,[fecha_desde] ASC);
ALTER TABLE [seg].[RefreshTokenSesion] ADD CONSTRAINT [UQ_RefreshTokenSesion_Hash] UNIQUE NONCLUSTERED ([token_hash] ASC);
ALTER TABLE [seg].[Rol] ADD CONSTRAINT [UQ_Rol_Codigo] UNIQUE NONCLUSTERED ([codigo] ASC);
ALTER TABLE [seg].[SesionUsuario] ADD CONSTRAINT [UQ_SesionUsuario_PublicaId] UNIQUE NONCLUSTERED ([sesion_publica_id] ASC);
ALTER TABLE [seg].[TokenAccesoRevocado] ADD CONSTRAINT [UQ_TokenAccesoRevocado_Jti] UNIQUE NONCLUSTERED ([jti_hash] ASC);
ALTER TABLE [seg].[Usuario] ADD CONSTRAINT [UQ_Usuario_Persona] UNIQUE NONCLUSTERED ([persona_id] ASC);
ALTER TABLE [seg].[Usuario] ADD CONSTRAINT [UQ_Usuario_Nombre] UNIQUE NONCLUSTERED ([nombre_usuario] ASC);
ALTER TABLE [seg].[UsuarioRol] ADD CONSTRAINT [UQ_UsuarioRol] UNIQUE NONCLUSTERED ([usuario_id] ASC,[rol_id] ASC,[fecha_desde] ASC);
CREATE NONCLUSTERED INDEX [IX_Archivo_UOT] ON [archivo].[Archivo] ([uot_id] ASC,[estado] ASC) WHERE ([uot_id] IS NOT NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_Archivo_UOT_Estado_Fecha] ON [archivo].[Archivo] ([uot_id] ASC,[estado] ASC,[fecha_carga] DESC,[archivo_id] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_Archivo_PublicIdPresente] ON [archivo].[Archivo] ([cloudinary_public_id] ASC) WHERE ([cloudinary_public_id] IS NOT NULL) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_ArchivoVinculo_MovimientoInventario] ON [archivo].[ArchivoVinculo] ([movimiento_inventario_id] ASC,[estado] ASC) INCLUDE ([archivo_id]) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DESCO_Error_Correlacion] ON [auditoria].[ErrorBaseDatos] ([correlacion_id] ASC,[fecha_utc] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E1_Error_Correlacion] ON [auditoria].[ExpedienteErrorTecnico] ([correlacion_id] ASC,[fecha_utc] DESC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_SalidaCampo_UOT] ON [campo].[SalidaCampo] ([uot_id] ASC,[estado] ASC,[fecha_hora_programada] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E2_DestinoPredio] ON [campo].[SalidaDestinoE2] ([predio_id] ASC,[salida_campo_id] ASC) WHERE ([predio_id] IS NOT NULL) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E2_SalidaUotEstado] ON [campo].[SalidaE2] ([uot_id] ASC,[convenio_id] ASC,[estado] ASC,[fecha_solicitud] DESC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E2_EventosFecha] ON [campo].[SalidaEventoE2] ([salida_campo_id] ASC,[evento_id] ASC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_E2_RecursoProgramado] ON [campo].[SalidaRecursoE2] ([recurso_programado_id] ASC) WHERE ([recurso_programado_id] IS NOT NULL) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_E2_SalidaBien] ON [campo].[SalidaRecursoE2] ([salida_campo_id] ASC,[bien_inventario_id] ASC) WHERE ([bien_inventario_id] IS NOT NULL) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_E2_SalidaSuministro] ON [campo].[SalidaRecursoE2] ([salida_campo_id] ASC,[suministro_id] ASC) WHERE ([suministro_id] IS NOT NULL) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_CajaEvidencia_Sesion] ON [comercial].[CajaEvidencia] ([caja_sesion_id] ASC,[fase] ASC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [IX_CajaSesion_OperadorEstado] ON [comercial].[CajaSesion] ([usuario_operador_id] ASC) WHERE ([estado]='ABIERTA') WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_CajaSesion_Abierta] ON [comercial].[CajaSesion] ([caja_id] ASC) WHERE ([estado]='ABIERTA') WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_CajaSesionOperador_Activo] ON [comercial].[CajaSesionOperador] ([usuario_id] ASC) WHERE ([activo]=(1)) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_CampaniaJabaPlan_Estado] ON [comercial].[CampaniaJabaPlan] ([estado] ASC,[activo] ASC) INCLUDE ([cantidad]) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_CampaniaJabaPrecioSancion_Socio] ON [comercial].[CampaniaJabaPrecioSancion] ([campania_socio_sancion_id] ASC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_CampaniaJabaRecepcion_Calibre] ON [comercial].[CampaniaJabaRecepcion] ([campania_calibre_id] ASC) INCLUDE ([peso_bruto_kg],[descuento_jaba_kg]) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_CampaniaVenta_UOT] ON [comercial].[CampaniaVenta] ([uot_id] ASC,[estado] ASC,[fecha_inicio] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_CampaniaVenta_UOT_EstadoProceso] ON [comercial].[CampaniaVenta] ([uot_id] ASC,[estado] ASC,[estado_proceso] ASC,[campania_venta_id] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_CargoTarifaE4_Actual] ON [comercial].[CargoTarifaE4] ([concepto_id] ASC,[vigente_hasta] ASC,[vigente_desde] DESC) INCLUDE ([precio_unitario]) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_CargoTarifaE4_Campania] ON [comercial].[CargoTarifaE4] ([campania_venta_id] ASC,[concepto_id] ASC,[vigente_hasta] ASC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_CompradorAPAPPSS_Empresa] ON [comercial].[CompradorAPAPPSS] ([uot_id] ASC,[empresa_id] ASC) WHERE ([empresa_id] IS NOT NULL) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_CompradorAPAPPSS_Persona] ON [comercial].[CompradorAPAPPSS] ([uot_id] ASC,[persona_id] ASC) WHERE ([persona_id] IS NOT NULL) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_EntregaSocio_FundoProduccion] ON [comercial].[EntregaSocio] ([predio_id] ASC,[fecha_hora] ASC) INCLUDE ([entrega_socio_id],[operativo_socio_id],[estado],[estado_proceso]) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_HorarioEmpleadoPOS_Empleado] ON [comercial].[HorarioEmpleadoPOS] ([uot_id] ASC,[empleado_id] ASC,[dia_semana] ASC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_HorarioEmpleadoPOS_UOTDia] ON [comercial].[HorarioEmpleadoPOS] ([uot_id] ASC,[dia_semana] ASC,[hora_inicio] ASC,[hora_fin] ASC) INCLUDE ([empleado_id]) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_JabaClasificacionHistorialE4_Unidad] ON [comercial].[JabaClasificacionHistorialE4] ([unidad_id] ASC,[version] ASC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DESCO_JabaMovimiento_Asignacion_Apoyo] ON [comercial].[JabaMovimiento] ([jaba_asignacion_id] ASC,[tipo_movimiento] ASC) WHERE ([jaba_asignacion_id] IS NOT NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DESCO_JabaMovimiento_Devolucion_Apoyo] ON [comercial].[JabaMovimiento] ([jaba_devolucion_id] ASC,[tipo_movimiento] ASC) WHERE ([jaba_devolucion_id] IS NOT NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DESCO_JabaMovimiento_Operativo] ON [comercial].[JabaMovimiento] ([operativo_venta_id] ASC,[fecha_hora] ASC,[jaba_movimiento_id] ASC) INCLUDE ([tipo_movimiento],[cantidad],[estado]) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_DESCO_JabaMovimiento_Asignacion] ON [comercial].[JabaMovimiento] ([jaba_asignacion_id] ASC) WHERE ([jaba_asignacion_id] IS NOT NULL AND [tipo_movimiento]='ASIGNACION') WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_DESCO_JabaMovimiento_Devolucion] ON [comercial].[JabaMovimiento] ([jaba_devolucion_id] ASC,[tipo_movimiento] ASC) WHERE ([jaba_devolucion_id] IS NOT NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_JabaPesajeHistorialE4_Unidad] ON [comercial].[JabaPesajeHistorialE4] ([unidad_id] ASC,[historial_id] ASC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_JabaUnidadE4_Entrega] ON [comercial].[JabaUnidadE4] ([entrega_socio_id] ASC,[pesaje_estado] ASC) INCLUDE ([peso_bruto_kg],[tara_kg],[precio_base]) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_JabaUnidadE4_retorno] ON [comercial].[JabaUnidadE4] ([jaba_asignacion_id] ASC,[retorno_estado] ASC,[pesaje_estado] ASC) INCLUDE ([peso_bruto_kg],[tara_kg]) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_PagoVenta_Archivo] ON [comercial].[PagoVenta] ([archivo_id] ASC) WHERE ([archivo_id] IS NOT NULL) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_PagoVenta_Idempotencia] ON [comercial].[PagoVenta] ([clave_idempotencia] ASC) WHERE ([clave_idempotencia] IS NOT NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_SancionSocioE4_Entrega] ON [comercial].[SancionSocioE4] ([entrega_socio_id] ASC,[estado] ASC) INCLUDE ([kilos_afectados],[precio_original],[precio_nuevo]) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_Venta_CajaSesion] ON [comercial].[Venta] ([caja_sesion_id] ASC,[fecha_hora] ASC) INCLUDE ([total],[estado_venta]) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_Venta_UOT_Fecha] ON [comercial].[Venta] ([uot_id] ASC,[fecha_hora] DESC,[estado_venta] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DESCO_CobroComprador_Saldo] ON [finanzas].[CobroComprador] ([campania_venta_id] ASC,[estado] ASC,[estado_proceso] ASC) INCLUDE ([importe]) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_LiquidacionSnapshotE5_Campania] ON [finanzas].[LiquidacionSnapshotE5] ([campania_venta_id] ASC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DESCO_Liquidacion_Aprobada_Apoyo] ON [finanzas].[LiquidacionSocio] ([participacion_campania_socio_id] ASC,[estado] ASC,[estado_proceso] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_DESCO_Liquidacion_Aprobada] ON [finanzas].[LiquidacionSocio] ([participacion_campania_socio_id] ASC) WHERE ([estado]=(1) AND ([estado_proceso] IN ('APROBADA', 'PAGADA_PARCIAL', 'PAGADA'))) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_E5_PagoBeneficiario_Comprobante] ON [finanzas].[PagoBeneficiarioE5] ([comprobante_archivo_id] ASC) WHERE ([comprobante_archivo_id] IS NOT NULL) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DESCO_PagoSocio_Saldo] ON [finanzas].[PagoSocio] ([liquidacion_socio_id] ASC,[estado] ASC,[estado_proceso] ASC) INCLUDE ([importe]) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_AlmacenUOT_Activo] ON [logistica].[AlmacenUOT] ([almacen_id] ASC,[uot_id] ASC) WHERE ([estado]=(1) AND [fecha_hasta] IS NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_BienEstadoHistorial_Actual] ON [logistica].[BienEstadoHistorial] ([bien_inventario_id] ASC) WHERE ([estado]=(1) AND [fecha_hasta] IS NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_BienImagen_Principal] ON [logistica].[BienImagen] ([bien_inventario_id] ASC) WHERE ([estado]=(1) AND [es_principal]=(1)) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_BienInventario_UOT_Estado] ON [logistica].[BienInventario] ([uot_id] ASC,[estado] ASC,[estado_bien] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DetMovInv_Producto] ON [logistica].[DetalleMovimientoInventario] ([producto_id] ASC,[movimiento_inventario_id] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_EntregaTecnica_Idempotencia] ON [logistica].[EntregaTecnica] ([clave_idempotencia] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_MovimientoLote_Detalle] ON [logistica].[MovimientoInventarioLote] ([detalle_movimiento_id] ASC) INCLUDE ([lote],[fecha_vencimiento],[cantidad],[detalle_origen_id]) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_MovimientoLote_Origen] ON [logistica].[MovimientoInventarioLote] ([detalle_origen_id] ASC) INCLUDE ([lote],[fecha_vencimiento],[cantidad]) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_Producto_ClaveIdempotencia] ON [logistica].[Producto] ([clave_idempotencia] ASC) WHERE ([clave_idempotencia] IS NOT NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_ProductoImagen_Principal] ON [logistica].[ProductoImagen] ([producto_id] ASC) WHERE ([estado]=(1) AND [es_principal]=(1)) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_ProductoPrecio_ActivoGeneral] ON [logistica].[ProductoPrecio] ([producto_id] ASC) WHERE ([estado]=(1) AND [fecha_hasta] IS NULL AND [uot_id] IS NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_ProductoPrecio_ActivoUOT] ON [logistica].[ProductoPrecio] ([producto_id] ASC,[uot_id] ASC) WHERE ([estado]=(1) AND [fecha_hasta] IS NULL AND [uot_id] IS NOT NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_ProductoPrecio_ClaveIdempotencia] ON [logistica].[ProductoPrecio] ([clave_idempotencia] ASC) WHERE ([clave_idempotencia] IS NOT NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DESCO_PP_UOT_Estado] ON [logistica].[ProgramacionProducto] ([uot_id] ASC,[estado_proceso] ASC,[fecha_inicio] ASC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DESCO_RecursoMovimiento_Recurso] ON [logistica].[RecursoMovimiento] ([recurso_programado_id] ASC,[tipo_movimiento] ASC) INCLUDE ([cantidad],[estado]) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DESCO_Recurso_BienActivo_Apoyo] ON [logistica].[RecursoProgramado] ([bien_inventario_id] ASC,[estado] ASC,[estado_proceso] ASC) WHERE ([bien_inventario_id] IS NOT NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_DESCO_Recurso_BienActivo] ON [logistica].[RecursoProgramado] ([bien_inventario_id] ASC) WHERE ([bien_inventario_id] IS NOT NULL AND [estado]=(1) AND ([estado_proceso] IN ('PROGRAMADO', 'EN_EJECUCION'))) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_Suministro_UOT_Estado] ON [logistica].[Suministro] ([uot_id] ASC,[estado] ASC,[nombre] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_Suministro_UOT_Codigo] ON [logistica].[Suministro] ([uot_id] ASC,[codigo] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DESCO_Kardex_Suministro] ON [logistica].[SuministroMovimiento] ([suministro_id] ASC,[fecha_hora] ASC,[suministro_movimiento_id] ASC) INCLUDE ([tipo_movimiento],[cantidad],[estado],[recurso_programado_id]) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DESCO_SuministroMovimiento_Recurso_Apoyo] ON [logistica].[SuministroMovimiento] ([recurso_movimiento_id] ASC) WHERE ([recurso_movimiento_id] IS NOT NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DESCO_SuministroMovimiento_Reversion_Apoyo] ON [logistica].[SuministroMovimiento] ([movimiento_origen_id] ASC) WHERE ([movimiento_origen_id] IS NOT NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_SuministroMovimiento_UOT_Fecha] ON [logistica].[SuministroMovimiento] ([uot_id] ASC,[fecha_hora] ASC,[suministro_movimiento_id] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_DESCO_SuministroMovimiento_Recurso] ON [logistica].[SuministroMovimiento] ([recurso_movimiento_id] ASC) WHERE ([recurso_movimiento_id] IS NOT NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_DESCO_SuministroMovimiento_Reversion] ON [logistica].[SuministroMovimiento] ([movimiento_origen_id] ASC) WHERE ([movimiento_origen_id] IS NOT NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_SuministroMovimiento_Anulacion] ON [logistica].[SuministroMovimiento] ([movimiento_anulado_id] ASC) WHERE ([movimiento_anulado_id] IS NOT NULL) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_Vehiculo_PlacaRegistrada] ON [logistica].[Vehiculo] ([placa] ASC) WHERE ([placa] IS NOT NULL) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_Area_UOT_Estado] ON [org].[Area] ([uot_id] ASC,[estado] ASC,[nombre] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_Area_Id_UOT] ON [org].[Area] ([area_id] ASC,[uot_id] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_Area_UOT_Codigo] ON [org].[Area] ([uot_id] ASC,[codigo] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_Asociacion_UOT_Estado] ON [org].[Asociacion] ([uot_id] ASC,[estado] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_ConvenioUOT_Activo] ON [org].[ConvenioUOTOrganizacion] ([uot_id] ASC,[empresa_id] ASC,[tipo_vinculo] ASC) WHERE ([estado]=(1) AND [fecha_fin] IS NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DESCO_EmpleadoArea_Vigencia] ON [org].[EmpleadoArea] ([empleado_id] ASC,[estado] ASC,[fecha_hasta] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_EmpleadoUOT_UOT_Activo] ON [org].[EmpleadoUOT] ([uot_id] ASC,[estado] ASC,[fecha_hasta] ASC,[empleado_id] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_EmpleadoUOT_Activo] ON [org].[EmpleadoUOT] ([empleado_id] ASC,[uot_id] ASC) WHERE ([estado]=(1) AND [fecha_hasta] IS NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_EmpleadoUOT_CodigoActivo] ON [org].[EmpleadoUOT] ([uot_id] ASC,[codigo_empleado] ASC) WHERE ([estado]=(1) AND [fecha_hasta] IS NULL AND [codigo_empleado] IS NOT NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_EmpleadoUOT_Principal] ON [org].[EmpleadoUOT] ([empleado_id] ASC) WHERE ([estado]=(1) AND [fecha_hasta] IS NULL AND [es_principal]=(1)) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DESCO_Empresa_CorreoClave] ON [org].[Empresa] ([correo_clave_desco] ASC) WHERE ([correo] IS NOT NULL AND [correo]<>'') WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_Empresa_Ubicacion] ON [org].[Empresa] ([ubicacion_id] ASC) WHERE ([ubicacion_id] IS NOT NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DESCO_Persona_CorreoClave] ON [org].[Persona] ([correo_clave_desco] ASC) WHERE ([correo] IS NOT NULL AND [correo]<>'') WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DESCO_Persona_DocumentoClave] ON [org].[Persona] ([documento_clave_desco] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_Persona_Ubicacion] ON [org].[Persona] ([ubicacion_id] ASC) WHERE ([ubicacion_id] IS NOT NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_DESCO_Persona_Correo] ON [org].[Persona] ([correo_clave_desco] ASC) WHERE ([correo] IS NOT NULL AND [correo]<>'') WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_DESCO_Persona_DocumentoEquivalente] ON [org].[Persona] ([documento_clave_desco] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_E1_ProductorUOTVigente] ON [org].[ProductorUOT] ([persona_id] ASC,[uot_id] ASC) WHERE ([estado]=(1) AND [fecha_hasta] IS NULL) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DESCO_SocioAsociacion_Vigencia] ON [org].[SocioAsociacion] ([socio_id] ASC,[estado] ASC,[fecha_hasta] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_DESCO_SocioAsociacion_Vigente] ON [org].[SocioAsociacion] ([socio_id] ASC) WHERE ([estado]=(1) AND [fecha_hasta] IS NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_UOT_EmpresaLegacy] ON [org].[UOT] ([empresa_legacy_id] ASC) WHERE ([empresa_legacy_id] IS NOT NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_UOT_UnicaRaizActiva] ON [org].[UOT] ([es_raiz] ASC) WHERE ([es_raiz]=(1) AND [estado]=(1)) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E1_CrianzaLotePredio] ON [prod].[CrianzaLote] ([predio_id] ASC,[especie_pecuaria_id] ASC,[estado] ASC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E1_ActuacionCorrelacion] ON [prod].[ExpedienteActuacion] ([correlacion_id] ASC) WHERE ([correlacion_id] IS NOT NULL) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E1_ActuacionPredio] ON [prod].[ExpedienteActuacion] ([predio_id] ASC,[uot_id] ASC,[fecha_hecho] DESC,[expediente_actuacion_id] DESC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_FundoProduccionE3_Campania] ON [prod].[FundoProduccionE3] ([uot_id] ASC,[fecha_desde] ASC,[fecha_hasta] ASC,[predio_id] ASC) INCLUDE ([convenio_id],[estado_produccion],[cantidad_disponible_kg]) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_GPActividad_Parcela] ON [prod].[GPActividad] ([uot_id] ASC,[predio_id] ASC,[parcela_id] ASC,[actividad_id] ASC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_GPActividadRevision_Actividad] ON [prod].[GPActividadRevision] ([actividad_id] ASC,[revision_id] DESC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_GPCenso_Actividad] ON [prod].[GPCenso] ([actividad_id] ASC,[fecha] DESC,[censo_id] DESC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_GPEvento_Actividad] ON [prod].[GPEvento] ([actividad_id] ASC,[fecha_hecho] DESC,[evento_id] DESC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_GPEventoFoto_Evento] ON [prod].[GPEventoFoto] ([evento_id] ASC,[foto_id] ASC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_GPIncidencia_Actividad] ON [prod].[GPIncidencia] ([actividad_id] ASC,[estado_seguimiento] ASC,[incidencia_id] DESC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_GPIncidencia_SolicitudCierre] ON [prod].[GPIncidencia] ([solicitud_cierre] ASC) WHERE ([solicitud_cierre] IS NOT NULL) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_GPIncidenciaRevision_Incidencia] ON [prod].[GPIncidenciaRevision] ([incidencia_id] ASC,[revision_id] DESC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_GPIncTrat_Incidencia] ON [prod].[GPIncidenciaTratamiento] ([incidencia_id] ASC,[fecha_inicio] DESC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_GPIncTrat_SolicitudCierre] ON [prod].[GPIncidenciaTratamiento] ([solicitud_cierre] ASC) WHERE ([solicitud_cierre] IS NOT NULL) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_GPProblema_Cultivo] ON [prod].[GPProblema] ([cultivo_id] ASC,[nombre] ASC) WHERE ([cultivo_id] IS NOT NULL) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_GPProblema_Especie] ON [prod].[GPProblema] ([especie_pecuaria_id] ASC,[nombre] ASC) WHERE ([especie_pecuaria_id] IS NOT NULL) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_GPRaza_EspecieNombre] ON [prod].[GPRaza] ([especie_pecuaria_id] ASC,[nombre] ASC) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_GPTratamiento_Nombre] ON [prod].[GPTratamiento] ([nombre] ASC) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DESCO_ParcelaCultivo_Vigencia] ON [prod].[ParcelaCultivo] ([parcela_id] ASC,[estado] ASC,[fecha_fin] ASC,[situacion_cultivo] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_DESCO_ParcelaCultivo_Vigente] ON [prod].[ParcelaCultivo] ([parcela_id] ASC) WHERE ([estado]=(1) AND [fecha_fin] IS NULL AND [situacion_cultivo]='ACTIVO') WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E3_ComentarioPlanta] ON [prod].[PlantaComentarioE3] ([planta_id] ASC,[comentario_id] DESC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E3_EventoPlanta] ON [prod].[PlantaEventoE3] ([planta_id] ASC,[fecha_hecho] DESC,[evento_id] DESC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E4_SecaIndividual] ON [prod].[PlantaMateriaSecaIndividualE4] ([planta_id] ASC,[fecha_muestreo] DESC,[medicion_id] DESC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E3_Medicion_PlantaFecha] ON [prod].[PlantaMedicionE3] ([planta_id] ASC,[fecha_hecho] DESC,[medicion_id] DESC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E3_PlantaAmbito] ON [prod].[PlantaPaltaE3] ([convenio_id] ASC,[uot_id] ASC,[predio_id] ASC,[variedad_palta_id] ASC,[estado_actual] ASC,[planta_id] ASC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E3_PlantaSocio] ON [prod].[PlantaPaltaE3] ([convenio_id] ASC,[uot_id] ASC,[socio_id] ASC,[predio_id] ASC,[parcela_cultivo_id] ASC,[variedad_palta_id] ASC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_Predio_UOT] ON [prod].[Predio] ([uot_id] ASC,[estado] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E1_AmbitoUOT] ON [prod].[PredioAmbito] ([uot_id] ASC,[convenio_uot_organizacion_id] ASC,[predio_id] ASC) INCLUDE ([estado]) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_E1_AmbitoTradicional] ON [prod].[PredioAmbito] ([predio_id] ASC,[uot_id] ASC) WHERE ([convenio_uot_organizacion_id] IS NULL) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E4_SecaCambio_Informe] ON [prod].[PredioMateriaSecaCambioE4] ([informe_id] ASC,[fecha_evento] DESC,[cambio_id] DESC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E4_SecaGlobal] ON [prod].[PredioMateriaSecaGlobalE4] ([predio_id] ASC,[convenio_id] ASC,[uot_id] ASC,[fecha_muestreo] DESC,[informe_id] DESC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E1_TitularPersona] ON [prod].[PredioTitularidad] ([persona_id] ASC,[predio_id] ASC,[fecha_hasta] ASC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E1_TitularSocio] ON [prod].[PredioTitularidad] ([predio_id] ASC,[socio_id] ASC,[estado] ASC,[fecha_hasta] ASC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_E1_TitularPeriodo] ON [prod].[PredioTitularidad] ([predio_id] ASC,[persona_id] ASC,[fecha_desde] ASC) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_E1_TitularVigente] ON [prod].[PredioTitularidad] ([predio_id] ASC,[persona_id] ASC) WHERE ([estado]=(1) AND [fecha_hasta] IS NULL) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_GP_TitularPrincipalActual] ON [prod].[PredioTitularidad] ([predio_id] ASC) WHERE ([rol_titularidad]='PRINCIPAL' AND [estado]=(1) AND [fecha_hasta] IS NULL) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DESCO_PredioVersion_Vigencia] ON [prod].[PredioVersion] ([predio_id] ASC,[estado] ASC,[fecha_hasta] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_DESCO_PredioVersion_Vigente] ON [prod].[PredioVersion] ([predio_id] ASC) WHERE ([estado]=(1) AND [fecha_hasta] IS NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_E1_PredioVersionRevision] ON [prod].[PredioVersion] ([predio_id] ASC,[fecha_desde] ASC,[revision] ASC) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E3_ProduccionVersion] ON [prod].[ProduccionPlantaE3] ([planta_id] ASC,[anio] ASC,[produccion_id] DESC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_VariedadCultivo_Legacy] ON [prod].[VariedadCultivo] ([variedad_palta_legacy_id] ASC) WHERE ([variedad_palta_legacy_id] IS NOT NULL) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_TrabajoEspecial_Cola] ON [reporte].[TrabajoEspecial] ([estado] ASC,[creado_utc] ASC,[trabajo_id] ASC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_TrabajoEspecial_Usuario] ON [reporte].[TrabajoEspecial] ([usuario_id] ASC,[uot_id] ASC,[creado_utc] DESC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_TrabajoExcel_Cola] ON [reporte].[TrabajoExcel] ([estado] ASC,[creado_utc] ASC,[trabajo_id] ASC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_TrabajoExcel_Usuario] ON [reporte].[TrabajoExcel] ([usuario_id] ASC,[uot_id] ASC,[creado_utc] DESC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E4_EpisodioNota] ON [sanidad].[EpisodioNotaE4] ([episodio_id] ASC,[fecha_registro] DESC,[nota_id] DESC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E3_Episodio_GPProblema] ON [sanidad].[EpisodioPlantaE3] ([gp_problema_id] ASC,[planta_id] ASC,[inicio] DESC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_E3_EpisodioActivoProblema] ON [sanidad].[EpisodioPlantaE3] ([planta_id] ASC,[gp_problema_id] ASC) WHERE ([fin] IS NULL AND [activo]=(1) AND [gp_problema_id] IS NOT NULL) WITH (PAD_INDEX=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E3_SeguimientoHistorial] ON [sanidad].[PlantaSeguimientoE3] ([planta_id] ASC,[seguimiento_id] DESC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E4_TratamientoAplicacion] ON [sanidad].[TratamientoAplicacionE4] ([episodio_id] ASC,[fecha_aplicacion] DESC,[aplicacion_id] DESC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_E3_TratamientoArchivoId] ON [sanidad].[TratamientoArchivoE4] ([archivo_id] ASC) WITH (PAD_INDEX=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DESCO_Usuario_NombreClave] ON [seg].[Usuario] ([usuario_clave_desco] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_DESCO_Usuario_Nombre] ON [seg].[Usuario] ([usuario_clave_desco] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DESCO_CorreoSeguridad_Clave] ON [seg].[UsuarioCorreoSeguridad] ([correo_clave_desco] ASC,[estado] ASC,[fecha_hasta] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_DESCO_CorreoSeguridad_Principal] ON [seg].[UsuarioCorreoSeguridad] ([usuario_id] ASC) WHERE ([estado]=(1) AND [fecha_hasta] IS NULL AND [es_principal]=(1)) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_DESCO_CorreoSeguridad_Vigente] ON [seg].[UsuarioCorreoSeguridad] ([correo_clave_desco] ASC) WHERE ([estado]=(1) AND [fecha_hasta] IS NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE NONCLUSTERED INDEX [IX_DESCO_UsuarioRol_Vigencia] ON [seg].[UsuarioRol] ([usuario_id] ASC,[rol_id] ASC,[estado] ASC,[fecha_hasta] ASC) WITH (PAD_INDEX=OFF,FILLFACTOR=100,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_DESCO_UsuarioRol_Vigente] ON [seg].[UsuarioRol] ([usuario_id] ASC,[rol_id] ASC) WHERE ([estado]=(1) AND [fecha_hasta] IS NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_UsuarioUOT_Activo] ON [seg].[UsuarioUOT] ([usuario_id] ASC,[uot_id] ASC) WHERE ([estado]=(1) AND [fecha_hasta] IS NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_UsuarioUOT_Predeterminada] ON [seg].[UsuarioUOT] ([usuario_id] ASC) WHERE ([estado]=(1) AND [fecha_hasta] IS NULL AND [es_predeterminada]=(1)) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_UsuarioUOTPermiso_Activo] ON [seg].[UsuarioUOTPermiso] ([usuario_uot_id] ASC,[permiso_id] ASC) WHERE ([estado]=(1) AND [fecha_hasta] IS NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
CREATE UNIQUE NONCLUSTERED INDEX [UX_UsuarioUOTRol_Activo] ON [seg].[UsuarioUOTRol] ([usuario_uot_id] ASC,[rol_id] ASC) WHERE ([estado]=(1) AND [fecha_hasta] IS NULL) WITH (PAD_INDEX=OFF,FILLFACTOR=100,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON);
GO

-- Esquema documental vigente. Estructura definitiva consolidada desde el inicio.
IF SCHEMA_ID(N'doc') IS NULL EXEC(N'CREATE SCHEMA [doc]');
GO

CREATE TABLE [doc].[TipoDocumento]
(
    [tipo_documento_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [codigo] VARCHAR(40) NOT NULL UNIQUE,
    [nombre] NVARCHAR(120) NOT NULL,
    [descripcion] NVARCHAR(300) NULL,
    [estado] BIT NOT NULL CONSTRAINT [DF_DocTipo_Estado] DEFAULT (1)
);
GO

CREATE TABLE [doc].[Hilo]
(
    [hilo_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [uot_id] BIGINT NOT NULL REFERENCES [org].[UOT]([uot_id]),
    [asunto] NVARCHAR(240) NOT NULL,
    [creado_por_usuario_id] BIGINT NOT NULL REFERENCES [seg].[Usuario]([usuario_id]),
    [fecha_creacion] DATETIME2(0) NOT NULL CONSTRAINT [DF_DocHilo_Creacion] DEFAULT SYSUTCDATETIME(),
    [estado] VARCHAR(25) NOT NULL CONSTRAINT [DF_DocHilo_Estado] DEFAULT 'EN_TRAMITE',
    [fecha_cierre] DATETIME2(0) NULL,
    [motivo_anulacion] NVARCHAR(400) NULL
);
GO

CREATE TABLE [doc].[Documento]
(
    [documento_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [hilo_id] BIGINT NOT NULL REFERENCES [doc].[Hilo]([hilo_id]),
    [documento_padre_id] BIGINT NULL REFERENCES [doc].[Documento]([documento_id]),
    [tipo_documento_id] BIGINT NOT NULL REFERENCES [doc].[TipoDocumento]([tipo_documento_id]),
    [asunto] NVARCHAR(240) NOT NULL,
    [cuerpo] NVARCHAR(3000) NULL,
    [emisor_usuario_id] BIGINT NOT NULL REFERENCES [seg].[Usuario]([usuario_id]),
    [clave_idempotencia] UNIQUEIDENTIFIER NOT NULL,
    [fecha_envio] DATETIME2(0) NOT NULL CONSTRAINT [DF_DocDocumento_Envio] DEFAULT SYSUTCDATETIME(),
    [uot_emisor_id] BIGINT NULL REFERENCES [org].[UOT]([uot_id]),
    [reemplaza_documento_id] BIGINT NULL REFERENCES [doc].[Documento]([documento_id]),
    CONSTRAINT [UQ_DocDocumento_Idempotencia] UNIQUE ([emisor_usuario_id], [clave_idempotencia])
);
GO

CREATE INDEX [IX_DocDocumento_Hilo] ON [doc].[Documento]([hilo_id], [fecha_envio], [documento_id]);
GO

CREATE TABLE [doc].[Destinatario]
(
    [documento_id] BIGINT NOT NULL REFERENCES [doc].[Documento]([documento_id]),
    [usuario_id] BIGINT NOT NULL REFERENCES [seg].[Usuario]([usuario_id]),
    [fecha_primera_vista] DATETIME2(0) NULL,
    [fecha_visto] DATETIME2(0) NULL,
    [uot_id] BIGINT NULL REFERENCES [org].[UOT]([uot_id]),
    [fecha_entrega] DATETIME2(0) NULL CONSTRAINT [DF_DocDestinatario_Entrega] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_DocDestinatario] PRIMARY KEY ([documento_id], [usuario_id])
);
GO

CREATE INDEX [IX_DocDestinatario_Pendientes] ON [doc].[Destinatario]([usuario_id], [fecha_primera_vista], [documento_id]);
GO

CREATE TABLE [doc].[Participante]
(
    [hilo_id] BIGINT NOT NULL REFERENCES [doc].[Hilo]([hilo_id]),
    [usuario_id] BIGINT NOT NULL REFERENCES [seg].[Usuario]([usuario_id]),
    [fecha_incorporacion] DATETIME2(0) NOT NULL CONSTRAINT [DF_DocParticipante_Fecha] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_DocParticipante] PRIMARY KEY ([hilo_id], [usuario_id])
);
GO

CREATE TABLE [doc].[DocumentoArchivo]
(
    [documento_id] BIGINT NOT NULL REFERENCES [doc].[Documento]([documento_id]),
    [archivo_id] BIGINT NOT NULL REFERENCES [archivo].[Archivo]([archivo_id]),
    CONSTRAINT [PK_DocDocumentoArchivo] PRIMARY KEY ([documento_id], [archivo_id]),
    CONSTRAINT [UQ_DocDocumentoArchivo_Archivo] UNIQUE ([archivo_id])
);
GO

CREATE TABLE [doc].[Evento]
(
    [evento_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [hilo_id] BIGINT NOT NULL REFERENCES [doc].[Hilo]([hilo_id]),
    [documento_id] BIGINT NOT NULL REFERENCES [doc].[Documento]([documento_id]),
    [usuario_id] BIGINT NOT NULL REFERENCES [seg].[Usuario]([usuario_id]),
    [tipo] VARCHAR(30) NOT NULL,
    [detalle] NVARCHAR(400) NULL,
    [fecha_evento] DATETIME2(0) NOT NULL CONSTRAINT [DF_DocEvento_Fecha] DEFAULT SYSUTCDATETIME()
);
GO

CREATE INDEX [IX_DocEvento_Hilo] ON [doc].[Evento]([hilo_id], [fecha_evento], [evento_id]);
GO

CREATE TABLE [doc].[ParticipanteUOT]
(
    [hilo_id] BIGINT NOT NULL REFERENCES [doc].[Hilo]([hilo_id]),
    [usuario_id] BIGINT NOT NULL REFERENCES [seg].[Usuario]([usuario_id]),
    [uot_id] BIGINT NOT NULL REFERENCES [org].[UOT]([uot_id]),
    CONSTRAINT [PK_DocParticipanteUOT] PRIMARY KEY ([hilo_id], [usuario_id], [uot_id])
);
GO

CREATE TABLE [doc].[AsignacionPendiente]
(
    [asignacion_id] BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [hilo_id] BIGINT NOT NULL REFERENCES [doc].[Hilo]([hilo_id]),
    [documento_origen_id] BIGINT NOT NULL REFERENCES [doc].[Documento]([documento_id]),
    [responsable_usuario_id] BIGINT NOT NULL REFERENCES [seg].[Usuario]([usuario_id]),
    [asignado_usuario_id] BIGINT NOT NULL REFERENCES [seg].[Usuario]([usuario_id]),
    [estado] VARCHAR(20) NOT NULL CONSTRAINT [DF_DocAsignacion_Estado] DEFAULT ('PENDIENTE'),
    [respuesta_documento_id] BIGINT NULL REFERENCES [doc].[Documento]([documento_id]),
    [fecha_asignacion] DATETIME2(0) NOT NULL CONSTRAINT [DF_DocAsignacion_Fecha] DEFAULT SYSUTCDATETIME(),
    [fecha_respuesta] DATETIME2(0) NULL,
    CONSTRAINT [UQ_DocAsignacion_OrigenDestinatario] UNIQUE ([documento_origen_id], [asignado_usuario_id]),
    CONSTRAINT [CK_DocAsignacion_Estado] CHECK ([estado] IN ('PENDIENTE', 'RESPONDIDA', 'SUSTITUIDA'))
);
GO

CREATE INDEX [IX_DocAsignacion_HiloEstado] ON [doc].[AsignacionPendiente]([hilo_id], [estado], [responsable_usuario_id]);
GO

-- Relaciones referenciales: todas las tablas ya existen.
ALTER TABLE [archivo].[Archivo] WITH CHECK ADD CONSTRAINT [FK_Archivo_RetiradoPor] FOREIGN KEY ([retirado_por_usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [archivo].[Archivo] CHECK CONSTRAINT [FK_Archivo_RetiradoPor];
ALTER TABLE [archivo].[Archivo] WITH CHECK ADD CONSTRAINT [FK_Archivo_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [archivo].[Archivo] CHECK CONSTRAINT [FK_Archivo_UOT];
ALTER TABLE [archivo].[Archivo] WITH CHECK ADD CONSTRAINT [FK_Archivo_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [archivo].[Archivo] CHECK CONSTRAINT [FK_Archivo_Usuario];
ALTER TABLE [archivo].[Archivo] WITH CHECK ADD CONSTRAINT [FK_Archivo_UsuarioRetiro] FOREIGN KEY ([usuario_retiro_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [archivo].[Archivo] CHECK CONSTRAINT [FK_Archivo_UsuarioRetiro];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Ajuste] FOREIGN KEY ([ajuste_precio_socio_id]) REFERENCES [comercial].[AjustePrecioSocio] ([ajuste_precio_socio_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Ajuste];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Archivo] FOREIGN KEY ([archivo_id]) REFERENCES [archivo].[Archivo] ([archivo_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Archivo];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_BienInventario] FOREIGN KEY ([bien_inventario_id]) REFERENCES [logistica].[BienInventario] ([bien_inventario_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_BienInventario];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Campania] FOREIGN KEY ([campania_venta_id]) REFERENCES [comercial].[CampaniaVenta] ([campania_venta_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Campania];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Caso] FOREIGN KEY ([caso_fitosanitario_id]) REFERENCES [sanidad].[CasoFitosanitario] ([caso_fitosanitario_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Caso];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Censo] FOREIGN KEY ([censo_plantas_id]) REFERENCES [prod].[CensoPlantas] ([censo_plantas_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Censo];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Cobro] FOREIGN KEY ([cobro_comprador_id]) REFERENCES [finanzas].[CobroComprador] ([cobro_comprador_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Cobro];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Disponibilidad] FOREIGN KEY ([disponibilidad_produccion_id]) REFERENCES [prod].[DisponibilidadProduccion] ([disponibilidad_produccion_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Disponibilidad];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Empleado] FOREIGN KEY ([empleado_id]) REFERENCES [org].[Empleado] ([empleado_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Empleado];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Entrega] FOREIGN KEY ([entrega_socio_id]) REFERENCES [comercial].[EntregaSocio] ([entrega_socio_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Entrega];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Evaluacion] FOREIGN KEY ([evaluacion_agronomica_id]) REFERENCES [campo].[EvaluacionAgronomica] ([evaluacion_agronomica_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Evaluacion];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Gasto] FOREIGN KEY ([gasto_campania_id]) REFERENCES [finanzas].[GastoCampania] ([gasto_campania_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Gasto];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Incidencia] FOREIGN KEY ([incidencia_operativa_id]) REFERENCES [comercial].[IncidenciaOperativa] ([incidencia_operativa_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Incidencia];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_JabaAsignacion] FOREIGN KEY ([jaba_asignacion_id]) REFERENCES [comercial].[JabaAsignacion] ([jaba_asignacion_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_JabaAsignacion];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_JabaDevolucion] FOREIGN KEY ([jaba_devolucion_id]) REFERENCES [comercial].[JabaDevolucion] ([jaba_devolucion_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_JabaDevolucion];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Liquidacion] FOREIGN KEY ([liquidacion_socio_id]) REFERENCES [finanzas].[LiquidacionSocio] ([liquidacion_socio_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Liquidacion];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_MovimientoInventario] FOREIGN KEY ([movimiento_inventario_id]) REFERENCES [logistica].[MovimientoInventario] ([movimiento_inventario_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_MovimientoInventario];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Operativo] FOREIGN KEY ([operativo_venta_id]) REFERENCES [comercial].[OperativoVenta] ([operativo_venta_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Operativo];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Pago] FOREIGN KEY ([pago_socio_id]) REFERENCES [finanzas].[PagoSocio] ([pago_socio_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Pago];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Parcela] FOREIGN KEY ([parcela_id]) REFERENCES [prod].[Parcela] ([parcela_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Parcela];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_ParcelaCultivo] FOREIGN KEY ([parcela_cultivo_id]) REFERENCES [prod].[ParcelaCultivo] ([parcela_cultivo_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_ParcelaCultivo];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Participacion] FOREIGN KEY ([participacion_campania_socio_id]) REFERENCES [comercial].[ParticipacionCampaniaSocio] ([participacion_campania_socio_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Participacion];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Precio] FOREIGN KEY ([precio_comercial_id]) REFERENCES [comercial].[PrecioComercial] ([precio_comercial_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Precio];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Predio] FOREIGN KEY ([predio_id]) REFERENCES [prod].[Predio] ([predio_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Predio];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_RecursoProgramado] FOREIGN KEY ([recurso_programado_id]) REFERENCES [logistica].[RecursoProgramado] ([recurso_programado_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_RecursoProgramado];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Salida] FOREIGN KEY ([salida_campo_id]) REFERENCES [campo].[SalidaCampo] ([salida_campo_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Salida];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Seguimiento] FOREIGN KEY ([seguimiento_fitosanitario_id]) REFERENCES [sanidad].[SeguimientoFitosanitario] ([seguimiento_fitosanitario_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Seguimiento];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Socio] FOREIGN KEY ([socio_id]) REFERENCES [org].[Socio] ([socio_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Socio];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Tratamiento] FOREIGN KEY ([tratamiento_id]) REFERENCES [sanidad].[TratamientoFitosanitario] ([tratamiento_fitosanitario_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Tratamiento];
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [FK_ArchivoVinculo_Visita] FOREIGN KEY ([visita_tecnica_id]) REFERENCES [campo].[VisitaTecnica] ([visita_tecnica_id]);
ALTER TABLE [archivo].[ArchivoVinculo] CHECK CONSTRAINT [FK_ArchivoVinculo_Visita];
ALTER TABLE [auditoria].[AuditoriaEvento] WITH CHECK ADD CONSTRAINT [FK_AuditoriaEvento_DispositivoUsuario] FOREIGN KEY ([dispositivo_usuario_id]) REFERENCES [seg].[DispositivoUsuario] ([dispositivo_usuario_id]);
ALTER TABLE [auditoria].[AuditoriaEvento] CHECK CONSTRAINT [FK_AuditoriaEvento_DispositivoUsuario];
ALTER TABLE [auditoria].[AuditoriaEvento] WITH CHECK ADD CONSTRAINT [FK_AuditoriaEvento_Modulo] FOREIGN KEY ([modulo_id]) REFERENCES [seg].[Modulo] ([modulo_id]);
ALTER TABLE [auditoria].[AuditoriaEvento] CHECK CONSTRAINT [FK_AuditoriaEvento_Modulo];
ALTER TABLE [auditoria].[AuditoriaEvento] WITH CHECK ADD CONSTRAINT [FK_AuditoriaEvento_Sesion] FOREIGN KEY ([sesion_usuario_id]) REFERENCES [seg].[SesionUsuario] ([sesion_usuario_id]);
ALTER TABLE [auditoria].[AuditoriaEvento] CHECK CONSTRAINT [FK_AuditoriaEvento_Sesion];
ALTER TABLE [auditoria].[AuditoriaEvento] WITH CHECK ADD CONSTRAINT [FK_AuditoriaEvento_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [auditoria].[AuditoriaEvento] CHECK CONSTRAINT [FK_AuditoriaEvento_Usuario];
ALTER TABLE [auditoria].[OperacionIdempotente] WITH CHECK ADD CONSTRAINT [FK_OperacionIdempotente_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [auditoria].[OperacionIdempotente] CHECK CONSTRAINT [FK_OperacionIdempotente_Usuario];
ALTER TABLE [auditoria].[TransicionEstado] WITH CHECK ADD CONSTRAINT [FK_TransicionEstado_Dispositivo] FOREIGN KEY ([dispositivo_usuario_id]) REFERENCES [seg].[DispositivoUsuario] ([dispositivo_usuario_id]);
ALTER TABLE [auditoria].[TransicionEstado] CHECK CONSTRAINT [FK_TransicionEstado_Dispositivo];
ALTER TABLE [auditoria].[TransicionEstado] WITH CHECK ADD CONSTRAINT [FK_TransicionEstado_Modulo] FOREIGN KEY ([modulo_id]) REFERENCES [seg].[Modulo] ([modulo_id]);
ALTER TABLE [auditoria].[TransicionEstado] CHECK CONSTRAINT [FK_TransicionEstado_Modulo];
ALTER TABLE [auditoria].[TransicionEstado] WITH CHECK ADD CONSTRAINT [FK_TransicionEstado_Sesion] FOREIGN KEY ([sesion_usuario_id]) REFERENCES [seg].[SesionUsuario] ([sesion_usuario_id]);
ALTER TABLE [auditoria].[TransicionEstado] CHECK CONSTRAINT [FK_TransicionEstado_Sesion];
ALTER TABLE [auditoria].[TransicionEstado] WITH CHECK ADD CONSTRAINT [FK_TransicionEstado_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [auditoria].[TransicionEstado] CHECK CONSTRAINT [FK_TransicionEstado_Usuario];
ALTER TABLE [campo].[EvaluacionAgronomica] WITH CHECK ADD CONSTRAINT [FK_EvaluacionAgronomica_Cultivo] FOREIGN KEY ([parcela_cultivo_id]) REFERENCES [prod].[ParcelaCultivo] ([parcela_cultivo_id]);
ALTER TABLE [campo].[EvaluacionAgronomica] CHECK CONSTRAINT [FK_EvaluacionAgronomica_Cultivo];
ALTER TABLE [campo].[EvaluacionAgronomica] WITH CHECK ADD CONSTRAINT [FK_EvaluacionAgronomica_Tipo] FOREIGN KEY ([tipo_evaluacion_id]) REFERENCES [campo].[TipoEvaluacion] ([tipo_evaluacion_id]);
ALTER TABLE [campo].[EvaluacionAgronomica] CHECK CONSTRAINT [FK_EvaluacionAgronomica_Tipo];
ALTER TABLE [campo].[EvaluacionAgronomica] WITH CHECK ADD CONSTRAINT [FK_EvaluacionAgronomica_Visita] FOREIGN KEY ([visita_tecnica_id]) REFERENCES [campo].[VisitaTecnica] ([visita_tecnica_id]);
ALTER TABLE [campo].[EvaluacionAgronomica] CHECK CONSTRAINT [FK_EvaluacionAgronomica_Visita];
ALTER TABLE [campo].[EvaluacionMateriaSeca] WITH CHECK ADD CONSTRAINT [FK_EvaluacionMateriaSeca_Evaluacion] FOREIGN KEY ([evaluacion_materia_seca_id]) REFERENCES [campo].[EvaluacionAgronomica] ([evaluacion_agronomica_id]);
ALTER TABLE [campo].[EvaluacionMateriaSeca] CHECK CONSTRAINT [FK_EvaluacionMateriaSeca_Evaluacion];
ALTER TABLE [campo].[SalidaCampo] WITH CHECK ADD CONSTRAINT [FK_SalidaCampo_Motivo] FOREIGN KEY ([motivo_salida_id]) REFERENCES [campo].[MotivoSalida] ([motivo_salida_id]);
ALTER TABLE [campo].[SalidaCampo] CHECK CONSTRAINT [FK_SalidaCampo_Motivo];
ALTER TABLE [campo].[SalidaCampo] WITH CHECK ADD CONSTRAINT [FK_SalidaCampo_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [campo].[SalidaCampo] CHECK CONSTRAINT [FK_SalidaCampo_UOT];
ALTER TABLE [campo].[SalidaDestinoE2] WITH CHECK ADD CONSTRAINT [FK__SalidaDes__predi__68294D9D] FOREIGN KEY ([predio_id]) REFERENCES [prod].[Predio] ([predio_id]);
ALTER TABLE [campo].[SalidaDestinoE2] CHECK CONSTRAINT [FK__SalidaDes__predi__68294D9D];
ALTER TABLE [campo].[SalidaDestinoE2] WITH CHECK ADD CONSTRAINT [FK__SalidaDes__salid__67352964] FOREIGN KEY ([salida_campo_id]) REFERENCES [campo].[SalidaCampo] ([salida_campo_id]);
ALTER TABLE [campo].[SalidaDestinoE2] CHECK CONSTRAINT [FK__SalidaDes__salid__67352964];
ALTER TABLE [campo].[SalidaE2] WITH CHECK ADD CONSTRAINT [FK__SalidaE2__conven__5F94079C] FOREIGN KEY ([convenio_id]) REFERENCES [org].[ConvenioUOTOrganizacion] ([convenio_uot_organizacion_id]);
ALTER TABLE [campo].[SalidaE2] CHECK CONSTRAINT [FK__SalidaE2__conven__5F94079C];
ALTER TABLE [campo].[SalidaE2] WITH CHECK ADD CONSTRAINT [FK__SalidaE2__salida__5CB79AF1] FOREIGN KEY ([salida_campo_id]) REFERENCES [campo].[SalidaCampo] ([salida_campo_id]);
ALTER TABLE [campo].[SalidaE2] CHECK CONSTRAINT [FK__SalidaE2__salida__5CB79AF1];
ALTER TABLE [campo].[SalidaE2] WITH CHECK ADD CONSTRAINT [FK__SalidaE2__solici__5DABBF2A] FOREIGN KEY ([solicitante_empleado_id]) REFERENCES [org].[Empleado] ([empleado_id]);
ALTER TABLE [campo].[SalidaE2] CHECK CONSTRAINT [FK__SalidaE2__solici__5DABBF2A];
ALTER TABLE [campo].[SalidaE2] WITH CHECK ADD CONSTRAINT [FK__SalidaE2__uot_id__5E9FE363] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [campo].[SalidaE2] CHECK CONSTRAINT [FK__SalidaE2__uot_id__5E9FE363];
ALTER TABLE [campo].[SalidaE2] WITH CHECK ADD CONSTRAINT [FK__SalidaE2__usuari__62707447] FOREIGN KEY ([usuario_aprobador]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [campo].[SalidaE2] CHECK CONSTRAINT [FK__SalidaE2__usuari__62707447];
ALTER TABLE [campo].[SalidaEventoE2] WITH CHECK ADD CONSTRAINT [FK__SalidaEve__salid__76776CF4] FOREIGN KEY ([salida_campo_id]) REFERENCES [campo].[SalidaCampo] ([salida_campo_id]);
ALTER TABLE [campo].[SalidaEventoE2] CHECK CONSTRAINT [FK__SalidaEve__salid__76776CF4];
ALTER TABLE [campo].[SalidaEventoE2] WITH CHECK ADD CONSTRAINT [FK__SalidaEve__usuar__776B912D] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [campo].[SalidaEventoE2] CHECK CONSTRAINT [FK__SalidaEve__usuar__776B912D];
ALTER TABLE [campo].[SalidaInspeccionE2] WITH CHECK ADD CONSTRAINT [FK__SalidaIns__salid__0737E4A2] FOREIGN KEY ([salida_campo_id]) REFERENCES [campo].[SalidaCampo] ([salida_campo_id]);
ALTER TABLE [campo].[SalidaInspeccionE2] CHECK CONSTRAINT [FK__SalidaIns__salid__0737E4A2];
ALTER TABLE [campo].[SalidaInspeccionE2] WITH CHECK ADD CONSTRAINT [FK__SalidaIns__usuar__082C08DB] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [campo].[SalidaInspeccionE2] CHECK CONSTRAINT [FK__SalidaIns__usuar__082C08DB];
ALTER TABLE [campo].[SalidaOperacionE2] WITH CHECK ADD CONSTRAINT [FK__SalidaOpe__usuar__098A4168] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [campo].[SalidaOperacionE2] CHECK CONSTRAINT [FK__SalidaOpe__usuar__098A4168];
ALTER TABLE [campo].[SalidaParticipante] WITH CHECK ADD CONSTRAINT [FK_SalidaParticipante_Empleado] FOREIGN KEY ([empleado_id]) REFERENCES [org].[Empleado] ([empleado_id]);
ALTER TABLE [campo].[SalidaParticipante] CHECK CONSTRAINT [FK_SalidaParticipante_Empleado];
ALTER TABLE [campo].[SalidaParticipante] WITH CHECK ADD CONSTRAINT [FK_SalidaParticipante_Salida] FOREIGN KEY ([salida_campo_id]) REFERENCES [campo].[SalidaCampo] ([salida_campo_id]);
ALTER TABLE [campo].[SalidaParticipante] CHECK CONSTRAINT [FK_SalidaParticipante_Salida];
ALTER TABLE [campo].[SalidaRecursoE2] WITH CHECK ADD CONSTRAINT [FK__SalidaRec__bien___6DE226F3] FOREIGN KEY ([bien_inventario_id]) REFERENCES [logistica].[BienInventario] ([bien_inventario_id]);
ALTER TABLE [campo].[SalidaRecursoE2] CHECK CONSTRAINT [FK__SalidaRec__bien___6DE226F3];
ALTER TABLE [campo].[SalidaRecursoE2] WITH CHECK ADD CONSTRAINT [FK__SalidaRec__recur__6ED64B2C] FOREIGN KEY ([recurso_programado_id]) REFERENCES [logistica].[RecursoProgramado] ([recurso_programado_id]);
ALTER TABLE [campo].[SalidaRecursoE2] CHECK CONSTRAINT [FK__SalidaRec__recur__6ED64B2C];
ALTER TABLE [campo].[SalidaRecursoE2] WITH CHECK ADD CONSTRAINT [FK__SalidaRec__salid__6CEE02BA] FOREIGN KEY ([salida_campo_id]) REFERENCES [campo].[SalidaCampo] ([salida_campo_id]);
ALTER TABLE [campo].[SalidaRecursoE2] CHECK CONSTRAINT [FK__SalidaRec__salid__6CEE02BA];
ALTER TABLE [campo].[SalidaRecursoE2] WITH CHECK ADD CONSTRAINT [FK__SalidaRec__usuar__70BE939E] FOREIGN KEY ([usuario_validacion]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [campo].[SalidaRecursoE2] CHECK CONSTRAINT [FK__SalidaRec__usuar__70BE939E];
ALTER TABLE [campo].[SalidaRecursoE2] WITH CHECK ADD CONSTRAINT [FK_E2_SalidaRecursoSuministro] FOREIGN KEY ([suministro_id]) REFERENCES [logistica].[Suministro] ([suministro_id]);
ALTER TABLE [campo].[SalidaRecursoE2] CHECK CONSTRAINT [FK_E2_SalidaRecursoSuministro];
ALTER TABLE [campo].[SalidaRetornoE2] WITH CHECK ADD CONSTRAINT [FK__SalidaRet__salid__03D16812] FOREIGN KEY ([salida_campo_id]) REFERENCES [campo].[SalidaCampo] ([salida_campo_id]);
ALTER TABLE [campo].[SalidaRetornoE2] CHECK CONSTRAINT [FK__SalidaRet__salid__03D16812];
ALTER TABLE [campo].[SalidaRetornoE2] WITH CHECK ADD CONSTRAINT [FK__SalidaRet__usuar__04C58C4B] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [campo].[SalidaRetornoE2] CHECK CONSTRAINT [FK__SalidaRet__usuar__04C58C4B];
ALTER TABLE [campo].[SalidaVisitaE2] WITH CHECK ADD CONSTRAINT [FK__SalidaVis__desti__0000D72E] FOREIGN KEY ([destino_id]) REFERENCES [campo].[SalidaDestinoE2] ([destino_id]);
ALTER TABLE [campo].[SalidaVisitaE2] CHECK CONSTRAINT [FK__SalidaVis__desti__0000D72E];
ALTER TABLE [campo].[SalidaVisitaE2] WITH CHECK ADD CONSTRAINT [FK__SalidaVis__tipo___00F4FB67] FOREIGN KEY ([tipo_visita_id]) REFERENCES [campo].[TipoVisitaE2] ([tipo_visita_id]);
ALTER TABLE [campo].[SalidaVisitaE2] CHECK CONSTRAINT [FK__SalidaVis__tipo___00F4FB67];
ALTER TABLE [campo].[SalidaVisitaE2] WITH CHECK ADD CONSTRAINT [FK__SalidaVis__visit__7F0CB2F5] FOREIGN KEY ([visita_tecnica_id]) REFERENCES [campo].[VisitaTecnica] ([visita_tecnica_id]);
ALTER TABLE [campo].[SalidaVisitaE2] CHECK CONSTRAINT [FK__SalidaVis__visit__7F0CB2F5];
ALTER TABLE [campo].[VisitaTecnica] WITH CHECK ADD CONSTRAINT [FK_VisitaTecnica_Participante] FOREIGN KEY ([salida_participante_id]) REFERENCES [campo].[SalidaParticipante] ([salida_participante_id]);
ALTER TABLE [campo].[VisitaTecnica] CHECK CONSTRAINT [FK_VisitaTecnica_Participante];
ALTER TABLE [campo].[VisitaTecnica] WITH CHECK ADD CONSTRAINT [FK_VisitaTecnica_Predio] FOREIGN KEY ([predio_id]) REFERENCES [prod].[Predio] ([predio_id]);
ALTER TABLE [campo].[VisitaTecnica] CHECK CONSTRAINT [FK_VisitaTecnica_Predio];
ALTER TABLE [comercial].[AccesoEmpleadoPOS] WITH CHECK ADD CONSTRAINT [FK_AccesoPOS_Empleado] FOREIGN KEY ([empleado_id]) REFERENCES [org].[Empleado] ([empleado_id]);
ALTER TABLE [comercial].[AccesoEmpleadoPOS] CHECK CONSTRAINT [FK_AccesoPOS_Empleado];
ALTER TABLE [comercial].[AccesoEmpleadoPOS] WITH CHECK ADD CONSTRAINT [FK_AccesoPOS_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [comercial].[AccesoEmpleadoPOS] CHECK CONSTRAINT [FK_AccesoPOS_UOT];
ALTER TABLE [comercial].[AccesoEmpleadoPOS] WITH CHECK ADD CONSTRAINT [FK_AccesoPOS_Usuario] FOREIGN KEY ([usuario_actualizacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[AccesoEmpleadoPOS] CHECK CONSTRAINT [FK_AccesoPOS_Usuario];
ALTER TABLE [comercial].[AjustePrecioSocio] WITH CHECK ADD CONSTRAINT [FK_AjustePrecioSocio_Condicion] FOREIGN KEY ([condicion_comercial_id]) REFERENCES [comercial].[CondicionComercial] ([condicion_comercial_id]);
ALTER TABLE [comercial].[AjustePrecioSocio] CHECK CONSTRAINT [FK_AjustePrecioSocio_Condicion];
ALTER TABLE [comercial].[AjustePrecioSocio] WITH CHECK ADD CONSTRAINT [FK_AjustePrecioSocio_Operativo] FOREIGN KEY ([operativo_venta_id]) REFERENCES [comercial].[OperativoVenta] ([operativo_venta_id]);
ALTER TABLE [comercial].[AjustePrecioSocio] CHECK CONSTRAINT [FK_AjustePrecioSocio_Operativo];
ALTER TABLE [comercial].[AjustePrecioSocio] WITH CHECK ADD CONSTRAINT [FK_AjustePrecioSocio_Participacion] FOREIGN KEY ([participacion_campania_socio_id]) REFERENCES [comercial].[ParticipacionCampaniaSocio] ([participacion_campania_socio_id]);
ALTER TABLE [comercial].[AjustePrecioSocio] CHECK CONSTRAINT [FK_AjustePrecioSocio_Participacion];
ALTER TABLE [comercial].[AjustePrecioSocio] WITH CHECK ADD CONSTRAINT [FK_AjustePrecioSocio_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[AjustePrecioSocio] CHECK CONSTRAINT [FK_AjustePrecioSocio_Usuario];
ALTER TABLE [comercial].[Boleta] WITH CHECK ADD CONSTRAINT [FK_Boleta_Venta] FOREIGN KEY ([venta_id]) REFERENCES [comercial].[Venta] ([venta_id]);
ALTER TABLE [comercial].[Boleta] CHECK CONSTRAINT [FK_Boleta_Venta];
ALTER TABLE [comercial].[CajaAsignacion] WITH CHECK ADD CONSTRAINT [FK_CajaAsignacion_Sesion] FOREIGN KEY ([caja_sesion_id]) REFERENCES [comercial].[CajaSesion] ([caja_sesion_id]);
ALTER TABLE [comercial].[CajaAsignacion] CHECK CONSTRAINT [FK_CajaAsignacion_Sesion];
ALTER TABLE [comercial].[CajaEvidencia] WITH CHECK ADD CONSTRAINT [FK_CajaEvidencia_Archivo] FOREIGN KEY ([archivo_id]) REFERENCES [archivo].[Archivo] ([archivo_id]);
ALTER TABLE [comercial].[CajaEvidencia] CHECK CONSTRAINT [FK_CajaEvidencia_Archivo];
ALTER TABLE [comercial].[CajaEvidencia] WITH CHECK ADD CONSTRAINT [FK_CajaEvidencia_Sesion] FOREIGN KEY ([caja_sesion_id]) REFERENCES [comercial].[CajaSesion] ([caja_sesion_id]);
ALTER TABLE [comercial].[CajaEvidencia] CHECK CONSTRAINT [FK_CajaEvidencia_Sesion];
ALTER TABLE [comercial].[CajaEvidencia] WITH CHECK ADD CONSTRAINT [FK_CajaEvidencia_Usuario] FOREIGN KEY ([usuario_registro_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[CajaEvidencia] CHECK CONSTRAINT [FK_CajaEvidencia_Usuario];
ALTER TABLE [comercial].[CajaMovimiento] WITH CHECK ADD CONSTRAINT [FK_CajaMovimiento_Sesion] FOREIGN KEY ([caja_sesion_id]) REFERENCES [comercial].[CajaSesion] ([caja_sesion_id]);
ALTER TABLE [comercial].[CajaMovimiento] CHECK CONSTRAINT [FK_CajaMovimiento_Sesion];
ALTER TABLE [comercial].[CajaMovimiento] WITH CHECK ADD CONSTRAINT [FK_CajaMovimiento_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[CajaMovimiento] CHECK CONSTRAINT [FK_CajaMovimiento_Usuario];
ALTER TABLE [comercial].[CajaPOS] WITH CHECK ADD CONSTRAINT [FK_CajaPOS_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [comercial].[CajaPOS] CHECK CONSTRAINT [FK_CajaPOS_UOT];
ALTER TABLE [comercial].[CajaPOS] WITH CHECK ADD CONSTRAINT [FK_CajaPOS_Usuario] FOREIGN KEY ([usuario_creacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[CajaPOS] CHECK CONSTRAINT [FK_CajaPOS_Usuario];
ALTER TABLE [comercial].[CajaSesion] WITH CHECK ADD CONSTRAINT [FK_CajaSesion_Abre] FOREIGN KEY ([usuario_apertura_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[CajaSesion] CHECK CONSTRAINT [FK_CajaSesion_Abre];
ALTER TABLE [comercial].[CajaSesion] WITH CHECK ADD CONSTRAINT [FK_CajaSesion_Caja] FOREIGN KEY ([caja_id]) REFERENCES [comercial].[CajaPOS] ([caja_id]);
ALTER TABLE [comercial].[CajaSesion] CHECK CONSTRAINT [FK_CajaSesion_Caja];
ALTER TABLE [comercial].[CajaSesion] WITH CHECK ADD CONSTRAINT [FK_CajaSesion_Cierra] FOREIGN KEY ([usuario_cierre_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[CajaSesion] CHECK CONSTRAINT [FK_CajaSesion_Cierra];
ALTER TABLE [comercial].[CajaSesion] WITH CHECK ADD CONSTRAINT [FK_CajaSesion_Opera] FOREIGN KEY ([usuario_operador_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[CajaSesion] CHECK CONSTRAINT [FK_CajaSesion_Opera];
ALTER TABLE [comercial].[CajaSesionOperador] WITH CHECK ADD CONSTRAINT [FK_CajaSesionOperador_Asigna] FOREIGN KEY ([usuario_asignacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[CajaSesionOperador] CHECK CONSTRAINT [FK_CajaSesionOperador_Asigna];
ALTER TABLE [comercial].[CajaSesionOperador] WITH CHECK ADD CONSTRAINT [FK_CajaSesionOperador_Retira] FOREIGN KEY ([usuario_retiro_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[CajaSesionOperador] CHECK CONSTRAINT [FK_CajaSesionOperador_Retira];
ALTER TABLE [comercial].[CajaSesionOperador] WITH CHECK ADD CONSTRAINT [FK_CajaSesionOperador_Sesion] FOREIGN KEY ([caja_sesion_id]) REFERENCES [comercial].[CajaSesion] ([caja_sesion_id]);
ALTER TABLE [comercial].[CajaSesionOperador] CHECK CONSTRAINT [FK_CajaSesionOperador_Sesion];
ALTER TABLE [comercial].[CajaSesionOperador] WITH CHECK ADD CONSTRAINT [FK_CajaSesionOperador_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[CajaSesionOperador] CHECK CONSTRAINT [FK_CajaSesionOperador_Usuario];
ALTER TABLE [comercial].[CampaniaCalibre] WITH CHECK ADD CONSTRAINT [FK__CampaniaC__campa__21D6CC45] FOREIGN KEY ([campania_venta_id]) REFERENCES [comercial].[CampaniaVenta] ([campania_venta_id]);
ALTER TABLE [comercial].[CampaniaCalibre] CHECK CONSTRAINT [FK__CampaniaC__campa__21D6CC45];
ALTER TABLE [comercial].[CampaniaCalibre] WITH CHECK ADD CONSTRAINT [FK__CampaniaC__varie__22CAF07E] FOREIGN KEY ([variedad_palta_id]) REFERENCES [prod].[VariedadPalta] ([variedad_palta_id]);
ALTER TABLE [comercial].[CampaniaCalibre] CHECK CONSTRAINT [FK__CampaniaC__varie__22CAF07E];
ALTER TABLE [comercial].[CampaniaCalibrePrecioVersion] WITH CHECK ADD CONSTRAINT [FK__CampaniaC__campa__2B60367F] FOREIGN KEY ([campania_calibre_id]) REFERENCES [comercial].[CampaniaCalibre] ([campania_calibre_id]);
ALTER TABLE [comercial].[CampaniaCalibrePrecioVersion] CHECK CONSTRAINT [FK__CampaniaC__campa__2B60367F];
ALTER TABLE [comercial].[CampaniaControlE4] WITH CHECK ADD CONSTRAINT [FK__CampaniaC__campa__4E347170] FOREIGN KEY ([campania_venta_id]) REFERENCES [comercial].[CampaniaVenta] ([campania_venta_id]);
ALTER TABLE [comercial].[CampaniaControlE4] CHECK CONSTRAINT [FK__CampaniaC__campa__4E347170];
ALTER TABLE [comercial].[CampaniaJabaPlan] WITH CHECK ADD CONSTRAINT [FK_CampaniaJabaPlan_Participante] FOREIGN KEY ([participacion_campania_socio_id]) REFERENCES [comercial].[ParticipacionCampaniaSocio] ([participacion_campania_socio_id]);
ALTER TABLE [comercial].[CampaniaJabaPlan] CHECK CONSTRAINT [FK_CampaniaJabaPlan_Participante];
ALTER TABLE [comercial].[CampaniaJabaPrecioSancion] WITH CHECK ADD CONSTRAINT [FK__CampaniaJ__campa__2FEFE172] FOREIGN KEY ([campania_jaba_recepcion_id]) REFERENCES [comercial].[CampaniaJabaRecepcion] ([campania_jaba_recepcion_id]);
ALTER TABLE [comercial].[CampaniaJabaPrecioSancion] CHECK CONSTRAINT [FK__CampaniaJ__campa__2FEFE172];
ALTER TABLE [comercial].[CampaniaJabaPrecioSancion] WITH CHECK ADD CONSTRAINT [FK__CampaniaJ__campa__30E405AB] FOREIGN KEY ([campania_socio_sancion_id]) REFERENCES [comercial].[CampaniaSocioSancion] ([campania_socio_sancion_id]);
ALTER TABLE [comercial].[CampaniaJabaPrecioSancion] CHECK CONSTRAINT [FK__CampaniaJ__campa__30E405AB];
ALTER TABLE [comercial].[CampaniaJabaRecepcion] WITH CHECK ADD CONSTRAINT [FK__CampaniaJ__campa__31190FD5] FOREIGN KEY ([campania_jaba_plan_id]) REFERENCES [comercial].[CampaniaJabaPlan] ([campania_jaba_plan_id]);
ALTER TABLE [comercial].[CampaniaJabaRecepcion] CHECK CONSTRAINT [FK__CampaniaJ__campa__31190FD5];
ALTER TABLE [comercial].[CampaniaJabaRecepcion] WITH CHECK ADD CONSTRAINT [FK__CampaniaJ__campa__320D340E] FOREIGN KEY ([campania_calibre_id]) REFERENCES [comercial].[CampaniaCalibre] ([campania_calibre_id]);
ALTER TABLE [comercial].[CampaniaJabaRecepcion] CHECK CONSTRAINT [FK__CampaniaJ__campa__320D340E];
ALTER TABLE [comercial].[CampaniaSancionTarifa] WITH CHECK ADD CONSTRAINT [FK__CampaniaS__campa__20AD9DE2] FOREIGN KEY ([campania_venta_id]) REFERENCES [comercial].[CampaniaVenta] ([campania_venta_id]);
ALTER TABLE [comercial].[CampaniaSancionTarifa] CHECK CONSTRAINT [FK__CampaniaS__campa__20AD9DE2];
ALTER TABLE [comercial].[CampaniaSancionTarifa] WITH CHECK ADD CONSTRAINT [FK__CampaniaS__sanci__21A1C21B] FOREIGN KEY ([sancion_venta_id]) REFERENCES [comercial].[CatalogoSancionVenta] ([sancion_venta_id]);
ALTER TABLE [comercial].[CampaniaSancionTarifa] CHECK CONSTRAINT [FK__CampaniaS__sanci__21A1C21B];
ALTER TABLE [comercial].[CampaniaSocioSancion] WITH CHECK ADD CONSTRAINT [FK__CampaniaS__campa__284EBFAA] FOREIGN KEY ([campania_sancion_tarifa_id]) REFERENCES [comercial].[CampaniaSancionTarifa] ([campania_sancion_tarifa_id]);
ALTER TABLE [comercial].[CampaniaSocioSancion] CHECK CONSTRAINT [FK__CampaniaS__campa__284EBFAA];
ALTER TABLE [comercial].[CampaniaSocioSancion] WITH CHECK ADD CONSTRAINT [FK__CampaniaS__parti__2942E3E3] FOREIGN KEY ([participacion_campania_socio_id]) REFERENCES [comercial].[ParticipacionCampaniaSocio] ([participacion_campania_socio_id]);
ALTER TABLE [comercial].[CampaniaSocioSancion] CHECK CONSTRAINT [FK__CampaniaS__parti__2942E3E3];
ALTER TABLE [comercial].[CampaniaVencimientoLog] WITH CHECK ADD CONSTRAINT [FK_CampaniaVencimientoLog_Campania] FOREIGN KEY ([campania_venta_id]) REFERENCES [comercial].[CampaniaVenta] ([campania_venta_id]);
ALTER TABLE [comercial].[CampaniaVencimientoLog] CHECK CONSTRAINT [FK_CampaniaVencimientoLog_Campania];
ALTER TABLE [comercial].[CampaniaVenta] WITH CHECK ADD CONSTRAINT [FK_CampaniaVenta_Asociacion] FOREIGN KEY ([asociacion_id]) REFERENCES [org].[Asociacion] ([asociacion_id]);
ALTER TABLE [comercial].[CampaniaVenta] CHECK CONSTRAINT [FK_CampaniaVenta_Asociacion];
ALTER TABLE [comercial].[CampaniaVenta] WITH CHECK ADD CONSTRAINT [FK_CampaniaVenta_CompradorAPAPPSS] FOREIGN KEY ([comprador_apappss_id]) REFERENCES [comercial].[CompradorAPAPPSS] ([comprador_apappss_id]);
ALTER TABLE [comercial].[CampaniaVenta] CHECK CONSTRAINT [FK_CampaniaVenta_CompradorAPAPPSS];
ALTER TABLE [comercial].[CampaniaVenta] WITH CHECK ADD CONSTRAINT [FK_CampaniaVenta_EmpresaCompradora] FOREIGN KEY ([empresa_compradora_id]) REFERENCES [org].[Empresa] ([empresa_id]);
ALTER TABLE [comercial].[CampaniaVenta] CHECK CONSTRAINT [FK_CampaniaVenta_EmpresaCompradora];
ALTER TABLE [comercial].[CampaniaVenta] WITH CHECK ADD CONSTRAINT [FK_CampaniaVenta_ModalidadVenta] FOREIGN KEY ([modalidad_venta_id]) REFERENCES [comercial].[ModalidadVenta] ([modalidad_venta_id]);
ALTER TABLE [comercial].[CampaniaVenta] CHECK CONSTRAINT [FK_CampaniaVenta_ModalidadVenta];
ALTER TABLE [comercial].[CampaniaVenta] WITH CHECK ADD CONSTRAINT [FK_CampaniaVenta_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [comercial].[CampaniaVenta] CHECK CONSTRAINT [FK_CampaniaVenta_UOT];
ALTER TABLE [comercial].[CargoIndividualE4] WITH CHECK ADD CONSTRAINT [FK__CargoIndi__conce__754E3E91] FOREIGN KEY ([concepto_id]) REFERENCES [comercial].[CargoConceptoE4] ([concepto_id]);
ALTER TABLE [comercial].[CargoIndividualE4] CHECK CONSTRAINT [FK__CargoIndi__conce__754E3E91];
ALTER TABLE [comercial].[CargoIndividualE4] WITH CHECK ADD CONSTRAINT [FK__CargoIndi__jaba___745A1A58] FOREIGN KEY ([jaba_asignacion_id]) REFERENCES [comercial].[JabaAsignacion] ([jaba_asignacion_id]);
ALTER TABLE [comercial].[CargoIndividualE4] CHECK CONSTRAINT [FK__CargoIndi__jaba___745A1A58];
ALTER TABLE [comercial].[CargoIndividualE4] WITH CHECK ADD CONSTRAINT [FK__CargoIndi__tarif__764262CA] FOREIGN KEY ([tarifa_id]) REFERENCES [comercial].[CargoTarifaE4] ([tarifa_id]);
ALTER TABLE [comercial].[CargoIndividualE4] CHECK CONSTRAINT [FK__CargoIndi__tarif__764262CA];
ALTER TABLE [comercial].[CargoTarifaE4] WITH CHECK ADD CONSTRAINT [FK__CargoTari__campa__481183C6] FOREIGN KEY ([campania_venta_id]) REFERENCES [comercial].[CampaniaVenta] ([campania_venta_id]);
ALTER TABLE [comercial].[CargoTarifaE4] CHECK CONSTRAINT [FK__CargoTari__campa__481183C6];
ALTER TABLE [comercial].[CargoTarifaE4] WITH CHECK ADD CONSTRAINT [FK__CargoTari__conce__6EA14102] FOREIGN KEY ([concepto_id]) REFERENCES [comercial].[CargoConceptoE4] ([concepto_id]);
ALTER TABLE [comercial].[CargoTarifaE4] CHECK CONSTRAINT [FK__CargoTari__conce__6EA14102];
ALTER TABLE [comercial].[CierreCampaniaE5] WITH CHECK ADD CONSTRAINT [FK__CierreCam__campa__63B99E3B] FOREIGN KEY ([campania_venta_id]) REFERENCES [comercial].[CampaniaVenta] ([campania_venta_id]);
ALTER TABLE [comercial].[CierreCampaniaE5] CHECK CONSTRAINT [FK__CierreCam__campa__63B99E3B];
ALTER TABLE [comercial].[CompradorAPAPPSS] WITH CHECK ADD CONSTRAINT [FK_CompradorAPAPPSS_Empresa] FOREIGN KEY ([empresa_id]) REFERENCES [org].[Empresa] ([empresa_id]);
ALTER TABLE [comercial].[CompradorAPAPPSS] CHECK CONSTRAINT [FK_CompradorAPAPPSS_Empresa];
ALTER TABLE [comercial].[CompradorAPAPPSS] WITH CHECK ADD CONSTRAINT [FK_CompradorAPAPPSS_Persona] FOREIGN KEY ([persona_id]) REFERENCES [org].[Persona] ([persona_id]);
ALTER TABLE [comercial].[CompradorAPAPPSS] CHECK CONSTRAINT [FK_CompradorAPAPPSS_Persona];
ALTER TABLE [comercial].[CompradorAPAPPSS] WITH CHECK ADD CONSTRAINT [FK_CompradorAPAPPSS_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [comercial].[CompradorAPAPPSS] CHECK CONSTRAINT [FK_CompradorAPAPPSS_UOT];
ALTER TABLE [comercial].[CondicionComercial] WITH CHECK ADD CONSTRAINT [FK_CondicionComercial_Modalidad] FOREIGN KEY ([modalidad_venta_id]) REFERENCES [comercial].[ModalidadVenta] ([modalidad_venta_id]);
ALTER TABLE [comercial].[CondicionComercial] CHECK CONSTRAINT [FK_CondicionComercial_Modalidad];
ALTER TABLE [comercial].[DetalleVenta] WITH CHECK ADD CONSTRAINT [FK_DetalleVenta_Precio] FOREIGN KEY ([producto_precio_id]) REFERENCES [logistica].[ProductoPrecio] ([producto_precio_id]);
ALTER TABLE [comercial].[DetalleVenta] CHECK CONSTRAINT [FK_DetalleVenta_Precio];
ALTER TABLE [comercial].[DetalleVenta] WITH CHECK ADD CONSTRAINT [FK_DetalleVenta_Producto] FOREIGN KEY ([producto_id]) REFERENCES [logistica].[Producto] ([producto_id]);
ALTER TABLE [comercial].[DetalleVenta] CHECK CONSTRAINT [FK_DetalleVenta_Producto];
ALTER TABLE [comercial].[DetalleVenta] WITH CHECK ADD CONSTRAINT [FK_DetalleVenta_Venta] FOREIGN KEY ([venta_id]) REFERENCES [comercial].[Venta] ([venta_id]);
ALTER TABLE [comercial].[DetalleVenta] CHECK CONSTRAINT [FK_DetalleVenta_Venta];
ALTER TABLE [comercial].[EntregaDetalle] WITH CHECK ADD CONSTRAINT [FK_EntregaDetalle_Condicion] FOREIGN KEY ([condicion_comercial_id]) REFERENCES [comercial].[CondicionComercial] ([condicion_comercial_id]);
ALTER TABLE [comercial].[EntregaDetalle] CHECK CONSTRAINT [FK_EntregaDetalle_Condicion];
ALTER TABLE [comercial].[EntregaDetalle] WITH CHECK ADD CONSTRAINT [FK_EntregaDetalle_Entrega] FOREIGN KEY ([entrega_socio_id]) REFERENCES [comercial].[EntregaSocio] ([entrega_socio_id]);
ALTER TABLE [comercial].[EntregaDetalle] CHECK CONSTRAINT [FK_EntregaDetalle_Entrega];
ALTER TABLE [comercial].[EntregaDetalle] WITH CHECK ADD CONSTRAINT [FK_EntregaDetalle_Precio] FOREIGN KEY ([precio_comercial_id]) REFERENCES [comercial].[PrecioComercial] ([precio_comercial_id]);
ALTER TABLE [comercial].[EntregaDetalle] CHECK CONSTRAINT [FK_EntregaDetalle_Precio];
ALTER TABLE [comercial].[EntregaDetalle] WITH CHECK ADD CONSTRAINT [FK_EntregaDetalle_Variedad] FOREIGN KEY ([variedad_palta_id]) REFERENCES [prod].[VariedadPalta] ([variedad_palta_id]);
ALTER TABLE [comercial].[EntregaDetalle] CHECK CONSTRAINT [FK_EntregaDetalle_Variedad];
ALTER TABLE [comercial].[EntregaSocio] WITH CHECK ADD CONSTRAINT [FK_EntregaSocio_OperativoSocio] FOREIGN KEY ([operativo_socio_id]) REFERENCES [comercial].[OperativoSocio] ([operativo_socio_id]);
ALTER TABLE [comercial].[EntregaSocio] CHECK CONSTRAINT [FK_EntregaSocio_OperativoSocio];
ALTER TABLE [comercial].[EntregaSocio] WITH CHECK ADD CONSTRAINT [FK_EntregaSocio_Predio] FOREIGN KEY ([predio_id]) REFERENCES [prod].[Predio] ([predio_id]);
ALTER TABLE [comercial].[EntregaSocio] CHECK CONSTRAINT [FK_EntregaSocio_Predio];
ALTER TABLE [comercial].[EventoE4] WITH CHECK ADD CONSTRAINT [FK__EventoE4__campan__076CEECC] FOREIGN KEY ([campania_venta_id]) REFERENCES [comercial].[CampaniaVenta] ([campania_venta_id]);
ALTER TABLE [comercial].[EventoE4] CHECK CONSTRAINT [FK__EventoE4__campan__076CEECC];
ALTER TABLE [comercial].[Factura] WITH CHECK ADD CONSTRAINT [FK_Factura_Venta] FOREIGN KEY ([venta_id]) REFERENCES [comercial].[Venta] ([venta_id]);
ALTER TABLE [comercial].[Factura] CHECK CONSTRAINT [FK_Factura_Venta];
ALTER TABLE [comercial].[HorarioAtencionUOT] WITH CHECK ADD CONSTRAINT [FK_HorarioAtencion_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [comercial].[HorarioAtencionUOT] CHECK CONSTRAINT [FK_HorarioAtencion_UOT];
ALTER TABLE [comercial].[HorarioAtencionUOT] WITH CHECK ADD CONSTRAINT [FK_HorarioAtencion_Usuario] FOREIGN KEY ([usuario_actualizacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[HorarioAtencionUOT] CHECK CONSTRAINT [FK_HorarioAtencion_Usuario];
ALTER TABLE [comercial].[HorarioEmpleadoPOS] WITH CHECK ADD CONSTRAINT [FK_HorarioPOS_Empleado] FOREIGN KEY ([empleado_id]) REFERENCES [org].[Empleado] ([empleado_id]);
ALTER TABLE [comercial].[HorarioEmpleadoPOS] CHECK CONSTRAINT [FK_HorarioPOS_Empleado];
ALTER TABLE [comercial].[HorarioEmpleadoPOS] WITH CHECK ADD CONSTRAINT [FK_HorarioPOS_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [comercial].[HorarioEmpleadoPOS] CHECK CONSTRAINT [FK_HorarioPOS_UOT];
ALTER TABLE [comercial].[HorarioEmpleadoPOS] WITH CHECK ADD CONSTRAINT [FK_HorarioPOS_Usuario] FOREIGN KEY ([usuario_registro_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[HorarioEmpleadoPOS] CHECK CONSTRAINT [FK_HorarioPOS_Usuario];
ALTER TABLE [comercial].[IncidenciaFaltanteE4] WITH CHECK ADD CONSTRAINT [FK__Incidenci__jaba___7DE38492] FOREIGN KEY ([jaba_asignacion_id]) REFERENCES [comercial].[JabaAsignacion] ([jaba_asignacion_id]);
ALTER TABLE [comercial].[IncidenciaFaltanteE4] CHECK CONSTRAINT [FK__Incidenci__jaba___7DE38492];
ALTER TABLE [comercial].[IncidenciaOperativa] WITH CHECK ADD CONSTRAINT [FK_IncidenciaOperativa_Entrega] FOREIGN KEY ([entrega_socio_id]) REFERENCES [comercial].[EntregaSocio] ([entrega_socio_id]);
ALTER TABLE [comercial].[IncidenciaOperativa] CHECK CONSTRAINT [FK_IncidenciaOperativa_Entrega];
ALTER TABLE [comercial].[IncidenciaOperativa] WITH CHECK ADD CONSTRAINT [FK_IncidenciaOperativa_Operativo] FOREIGN KEY ([operativo_venta_id]) REFERENCES [comercial].[OperativoVenta] ([operativo_venta_id]);
ALTER TABLE [comercial].[IncidenciaOperativa] CHECK CONSTRAINT [FK_IncidenciaOperativa_Operativo];
ALTER TABLE [comercial].[JabaAsignacion] WITH CHECK ADD CONSTRAINT [FK_JabaAsignacion_OperativoSocio] FOREIGN KEY ([operativo_socio_id]) REFERENCES [comercial].[OperativoSocio] ([operativo_socio_id]);
ALTER TABLE [comercial].[JabaAsignacion] CHECK CONSTRAINT [FK_JabaAsignacion_OperativoSocio];
ALTER TABLE [comercial].[JabaAsignacion] WITH CHECK ADD CONSTRAINT [FK_JabaAsignacion_UsuarioAnulacion] FOREIGN KEY ([usuario_anulacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[JabaAsignacion] CHECK CONSTRAINT [FK_JabaAsignacion_UsuarioAnulacion];
ALTER TABLE [comercial].[JabaAsignacion] WITH CHECK ADD CONSTRAINT [FK_JabaAsignacion_UsuarioRegistro] FOREIGN KEY ([usuario_registro_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[JabaAsignacion] CHECK CONSTRAINT [FK_JabaAsignacion_UsuarioRegistro];
ALTER TABLE [comercial].[JabaClasificacionE4] WITH CHECK ADD CONSTRAINT [FK__JabaClasi__condi__12DEA178] FOREIGN KEY ([condicion_comercial_id]) REFERENCES [comercial].[CondicionComercial] ([condicion_comercial_id]);
ALTER TABLE [comercial].[JabaClasificacionE4] CHECK CONSTRAINT [FK__JabaClasi__condi__12DEA178];
ALTER TABLE [comercial].[JabaClasificacionE4] WITH CHECK ADD CONSTRAINT [FK__JabaClasi__preci__13D2C5B1] FOREIGN KEY ([precio_comercial_id]) REFERENCES [comercial].[PrecioComercial] ([precio_comercial_id]);
ALTER TABLE [comercial].[JabaClasificacionE4] CHECK CONSTRAINT [FK__JabaClasi__preci__13D2C5B1];
ALTER TABLE [comercial].[JabaClasificacionE4] WITH CHECK ADD CONSTRAINT [FK__JabaClasi__unida__0F0E1094] FOREIGN KEY ([unidad_id]) REFERENCES [comercial].[JabaUnidadE4] ([unidad_id]);
ALTER TABLE [comercial].[JabaClasificacionE4] CHECK CONSTRAINT [FK__JabaClasi__unida__0F0E1094];
ALTER TABLE [comercial].[JabaClasificacionE4] WITH CHECK ADD CONSTRAINT [FK__JabaClasi__varie__11EA7D3F] FOREIGN KEY ([variedad_palta_id]) REFERENCES [prod].[VariedadPalta] ([variedad_palta_id]);
ALTER TABLE [comercial].[JabaClasificacionE4] CHECK CONSTRAINT [FK__JabaClasi__varie__11EA7D3F];
ALTER TABLE [comercial].[JabaClasificacionHistorialE4] WITH CHECK ADD CONSTRAINT [FK__JabaClasi__unida__18977ACE] FOREIGN KEY ([unidad_id]) REFERENCES [comercial].[JabaUnidadE4] ([unidad_id]);
ALTER TABLE [comercial].[JabaClasificacionHistorialE4] CHECK CONSTRAINT [FK__JabaClasi__unida__18977ACE];
ALTER TABLE [comercial].[JabaDevolucion] WITH CHECK ADD CONSTRAINT [FK_JabaDevolucion_Asignacion] FOREIGN KEY ([jaba_asignacion_id]) REFERENCES [comercial].[JabaAsignacion] ([jaba_asignacion_id]);
ALTER TABLE [comercial].[JabaDevolucion] CHECK CONSTRAINT [FK_JabaDevolucion_Asignacion];
ALTER TABLE [comercial].[JabaDevolucion] WITH CHECK ADD CONSTRAINT [FK_JabaDevolucion_Entrega] FOREIGN KEY ([entrega_socio_id]) REFERENCES [comercial].[EntregaSocio] ([entrega_socio_id]);
ALTER TABLE [comercial].[JabaDevolucion] CHECK CONSTRAINT [FK_JabaDevolucion_Entrega];
ALTER TABLE [comercial].[JabaDevolucion] WITH CHECK ADD CONSTRAINT [FK_JabaDevolucion_UsuarioAnulacion] FOREIGN KEY ([usuario_anulacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[JabaDevolucion] CHECK CONSTRAINT [FK_JabaDevolucion_UsuarioAnulacion];
ALTER TABLE [comercial].[JabaDevolucion] WITH CHECK ADD CONSTRAINT [FK_JabaDevolucion_UsuarioRegistro] FOREIGN KEY ([usuario_registro_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[JabaDevolucion] CHECK CONSTRAINT [FK_JabaDevolucion_UsuarioRegistro];
ALTER TABLE [comercial].[JabaMovimiento] WITH CHECK ADD CONSTRAINT [FK_DESCO_JabaMovimiento_usuario_anulacion_id] FOREIGN KEY ([usuario_anulacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[JabaMovimiento] CHECK CONSTRAINT [FK_DESCO_JabaMovimiento_usuario_anulacion_id];
ALTER TABLE [comercial].[JabaMovimiento] WITH CHECK ADD CONSTRAINT [FK_JabaMovimiento_Asignacion] FOREIGN KEY ([jaba_asignacion_id]) REFERENCES [comercial].[JabaAsignacion] ([jaba_asignacion_id]);
ALTER TABLE [comercial].[JabaMovimiento] CHECK CONSTRAINT [FK_JabaMovimiento_Asignacion];
ALTER TABLE [comercial].[JabaMovimiento] WITH CHECK ADD CONSTRAINT [FK_JabaMovimiento_Devolucion] FOREIGN KEY ([jaba_devolucion_id]) REFERENCES [comercial].[JabaDevolucion] ([jaba_devolucion_id]);
ALTER TABLE [comercial].[JabaMovimiento] CHECK CONSTRAINT [FK_JabaMovimiento_Devolucion];
ALTER TABLE [comercial].[JabaMovimiento] WITH CHECK ADD CONSTRAINT [FK_JabaMovimiento_Operativo] FOREIGN KEY ([operativo_venta_id]) REFERENCES [comercial].[OperativoVenta] ([operativo_venta_id]);
ALTER TABLE [comercial].[JabaMovimiento] CHECK CONSTRAINT [FK_JabaMovimiento_Operativo];
ALTER TABLE [comercial].[JabaMovimiento] WITH CHECK ADD CONSTRAINT [FK_JabaMovimiento_OperativoSocio] FOREIGN KEY ([operativo_socio_id]) REFERENCES [comercial].[OperativoSocio] ([operativo_socio_id]);
ALTER TABLE [comercial].[JabaMovimiento] CHECK CONSTRAINT [FK_JabaMovimiento_OperativoSocio];
ALTER TABLE [comercial].[JabaMovimiento] WITH CHECK ADD CONSTRAINT [FK_JabaMovimiento_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[JabaMovimiento] CHECK CONSTRAINT [FK_JabaMovimiento_Usuario];
ALTER TABLE [comercial].[JabaPesajeHistorialE4] WITH CHECK ADD CONSTRAINT [FK__JabaPesaj__unida__434CCEA9] FOREIGN KEY ([unidad_id]) REFERENCES [comercial].[JabaUnidadE4] ([unidad_id]);
ALTER TABLE [comercial].[JabaPesajeHistorialE4] CHECK CONSTRAINT [FK__JabaPesaj__unida__434CCEA9];
ALTER TABLE [comercial].[JabaRetornoValidadoE4] WITH CHECK ADD CONSTRAINT [FK__JabaRetor__jaba___3E88198C] FOREIGN KEY ([jaba_asignacion_id]) REFERENCES [comercial].[JabaAsignacion] ([jaba_asignacion_id]);
ALTER TABLE [comercial].[JabaRetornoValidadoE4] CHECK CONSTRAINT [FK__JabaRetor__jaba___3E88198C];
ALTER TABLE [comercial].[JabaSaldoOperativo] WITH CHECK ADD CONSTRAINT [FK_DESCO_JabaSaldo_Operativo] FOREIGN KEY ([operativo_venta_id]) REFERENCES [comercial].[OperativoVenta] ([operativo_venta_id]);
ALTER TABLE [comercial].[JabaSaldoOperativo] CHECK CONSTRAINT [FK_DESCO_JabaSaldo_Operativo];
ALTER TABLE [comercial].[JabaStockHistorialE4] WITH CHECK ADD CONSTRAINT [FK__JabaStock__uot_i__3AB788A8] FOREIGN KEY ([uot_id]) REFERENCES [comercial].[JabaStockUotE4] ([uot_id]);
ALTER TABLE [comercial].[JabaStockHistorialE4] CHECK CONSTRAINT [FK__JabaStock__uot_i__3AB788A8];
ALTER TABLE [comercial].[JabaUnidadE4] WITH CHECK ADD CONSTRAINT [FK__JabaUnida__condi__58B1FFE3] FOREIGN KEY ([condicion_comercial_id]) REFERENCES [comercial].[CondicionComercial] ([condicion_comercial_id]);
ALTER TABLE [comercial].[JabaUnidadE4] CHECK CONSTRAINT [FK__JabaUnida__condi__58B1FFE3];
ALTER TABLE [comercial].[JabaUnidadE4] WITH CHECK ADD CONSTRAINT [FK__JabaUnida__entre__5C8290C7] FOREIGN KEY ([entrega_socio_id]) REFERENCES [comercial].[EntregaSocio] ([entrega_socio_id]);
ALTER TABLE [comercial].[JabaUnidadE4] CHECK CONSTRAINT [FK__JabaUnida__entre__5C8290C7];
ALTER TABLE [comercial].[JabaUnidadE4] WITH CHECK ADD CONSTRAINT [FK__JabaUnida__jaba___55D59338] FOREIGN KEY ([jaba_asignacion_id]) REFERENCES [comercial].[JabaAsignacion] ([jaba_asignacion_id]);
ALTER TABLE [comercial].[JabaUnidadE4] CHECK CONSTRAINT [FK__JabaUnida__jaba___55D59338];
ALTER TABLE [comercial].[JabaUnidadE4] WITH CHECK ADD CONSTRAINT [FK__JabaUnida__preci__59A6241C] FOREIGN KEY ([precio_comercial_id]) REFERENCES [comercial].[PrecioComercial] ([precio_comercial_id]);
ALTER TABLE [comercial].[JabaUnidadE4] CHECK CONSTRAINT [FK__JabaUnida__preci__59A6241C];
ALTER TABLE [comercial].[JabaUnidadE4] WITH CHECK ADD CONSTRAINT [FK__JabaUnida__varie__57BDDBAA] FOREIGN KEY ([variedad_palta_id]) REFERENCES [prod].[VariedadPalta] ([variedad_palta_id]);
ALTER TABLE [comercial].[JabaUnidadE4] CHECK CONSTRAINT [FK__JabaUnida__varie__57BDDBAA];
ALTER TABLE [comercial].[OperativoSocio] WITH CHECK ADD CONSTRAINT [FK_OperativoSocio_Operativo] FOREIGN KEY ([operativo_venta_id]) REFERENCES [comercial].[OperativoVenta] ([operativo_venta_id]);
ALTER TABLE [comercial].[OperativoSocio] CHECK CONSTRAINT [FK_OperativoSocio_Operativo];
ALTER TABLE [comercial].[OperativoSocio] WITH CHECK ADD CONSTRAINT [FK_OperativoSocio_Participacion] FOREIGN KEY ([participacion_campania_socio_id]) REFERENCES [comercial].[ParticipacionCampaniaSocio] ([participacion_campania_socio_id]);
ALTER TABLE [comercial].[OperativoSocio] CHECK CONSTRAINT [FK_OperativoSocio_Participacion];
ALTER TABLE [comercial].[OperativoVenta] WITH CHECK ADD CONSTRAINT [FK_OperativoVenta_Campania] FOREIGN KEY ([campania_venta_id]) REFERENCES [comercial].[CampaniaVenta] ([campania_venta_id]);
ALTER TABLE [comercial].[OperativoVenta] CHECK CONSTRAINT [FK_OperativoVenta_Campania];
ALTER TABLE [comercial].[OperativoZona] WITH CHECK ADD CONSTRAINT [FK_OperativoZona_Operativo] FOREIGN KEY ([operativo_venta_id]) REFERENCES [comercial].[OperativoVenta] ([operativo_venta_id]);
ALTER TABLE [comercial].[OperativoZona] CHECK CONSTRAINT [FK_OperativoZona_Operativo];
ALTER TABLE [comercial].[OperativoZona] WITH CHECK ADD CONSTRAINT [FK_OperativoZona_Zona] FOREIGN KEY ([zona_productiva_id]) REFERENCES [geo].[ZonaProductiva] ([zona_productiva_id]);
ALTER TABLE [comercial].[OperativoZona] CHECK CONSTRAINT [FK_OperativoZona_Zona];
ALTER TABLE [comercial].[PagoVenta] WITH CHECK ADD CONSTRAINT [FK_PagoVenta_Archivo] FOREIGN KEY ([archivo_id]) REFERENCES [archivo].[Archivo] ([archivo_id]);
ALTER TABLE [comercial].[PagoVenta] CHECK CONSTRAINT [FK_PagoVenta_Archivo];
ALTER TABLE [comercial].[PagoVenta] WITH CHECK ADD CONSTRAINT [FK_PagoVenta_Metodo] FOREIGN KEY ([metodo_pago_id]) REFERENCES [comercial].[MetodoPago] ([metodo_pago_id]);
ALTER TABLE [comercial].[PagoVenta] CHECK CONSTRAINT [FK_PagoVenta_Metodo];
ALTER TABLE [comercial].[PagoVenta] WITH CHECK ADD CONSTRAINT [FK_PagoVenta_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[PagoVenta] CHECK CONSTRAINT [FK_PagoVenta_Usuario];
ALTER TABLE [comercial].[PagoVenta] WITH CHECK ADD CONSTRAINT [FK_PagoVenta_UsuarioAnulacion] FOREIGN KEY ([usuario_anulacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[PagoVenta] CHECK CONSTRAINT [FK_PagoVenta_UsuarioAnulacion];
ALTER TABLE [comercial].[PagoVenta] WITH CHECK ADD CONSTRAINT [FK_PagoVenta_Venta] FOREIGN KEY ([venta_id]) REFERENCES [comercial].[Venta] ([venta_id]);
ALTER TABLE [comercial].[PagoVenta] CHECK CONSTRAINT [FK_PagoVenta_Venta];
ALTER TABLE [comercial].[ParticipacionCampaniaSocio] WITH CHECK ADD CONSTRAINT [FK_ParticipacionCampaniaSocio_Campania] FOREIGN KEY ([campania_venta_id]) REFERENCES [comercial].[CampaniaVenta] ([campania_venta_id]);
ALTER TABLE [comercial].[ParticipacionCampaniaSocio] CHECK CONSTRAINT [FK_ParticipacionCampaniaSocio_Campania];
ALTER TABLE [comercial].[ParticipacionCampaniaSocio] WITH CHECK ADD CONSTRAINT [FK_ParticipacionCampaniaSocio_SocioAsociacion] FOREIGN KEY ([socio_asociacion_id]) REFERENCES [org].[SocioAsociacion] ([socio_asociacion_id]);
ALTER TABLE [comercial].[ParticipacionCampaniaSocio] CHECK CONSTRAINT [FK_ParticipacionCampaniaSocio_SocioAsociacion];
ALTER TABLE [comercial].[PrecioComercial] WITH CHECK ADD CONSTRAINT [FK_PrecioComercial_Campania] FOREIGN KEY ([campania_venta_id]) REFERENCES [comercial].[CampaniaVenta] ([campania_venta_id]);
ALTER TABLE [comercial].[PrecioComercial] CHECK CONSTRAINT [FK_PrecioComercial_Campania];
ALTER TABLE [comercial].[PrecioComercial] WITH CHECK ADD CONSTRAINT [FK_PrecioComercial_Condicion] FOREIGN KEY ([condicion_comercial_id]) REFERENCES [comercial].[CondicionComercial] ([condicion_comercial_id]);
ALTER TABLE [comercial].[PrecioComercial] CHECK CONSTRAINT [FK_PrecioComercial_Condicion];
ALTER TABLE [comercial].[PrecioComercial] WITH CHECK ADD CONSTRAINT [FK_PrecioComercial_OperativoCampania] FOREIGN KEY ([operativo_venta_id],[campania_venta_id]) REFERENCES [comercial].[OperativoVenta] ([operativo_venta_id],[campania_venta_id]);
ALTER TABLE [comercial].[PrecioComercial] CHECK CONSTRAINT [FK_PrecioComercial_OperativoCampania];
ALTER TABLE [comercial].[PrecioComercial] WITH CHECK ADD CONSTRAINT [FK_PrecioComercial_Variedad] FOREIGN KEY ([variedad_palta_id]) REFERENCES [prod].[VariedadPalta] ([variedad_palta_id]);
ALTER TABLE [comercial].[PrecioComercial] CHECK CONSTRAINT [FK_PrecioComercial_Variedad];
ALTER TABLE [comercial].[SancionSocioE4] WITH CHECK ADD CONSTRAINT [FK__SancionSo__condi__623B6A1D] FOREIGN KEY ([condicion_comercial_id]) REFERENCES [comercial].[CondicionComercial] ([condicion_comercial_id]);
ALTER TABLE [comercial].[SancionSocioE4] CHECK CONSTRAINT [FK__SancionSo__condi__623B6A1D];
ALTER TABLE [comercial].[SancionSocioE4] WITH CHECK ADD CONSTRAINT [FK__SancionSo__entre__614745E4] FOREIGN KEY ([entrega_socio_id]) REFERENCES [comercial].[EntregaSocio] ([entrega_socio_id]);
ALTER TABLE [comercial].[SancionSocioE4] CHECK CONSTRAINT [FK__SancionSo__entre__614745E4];
ALTER TABLE [comercial].[SancionSocioE4] WITH CHECK ADD CONSTRAINT [FK__SancionSo__varie__632F8E56] FOREIGN KEY ([variedad_palta_id]) REFERENCES [prod].[VariedadPalta] ([variedad_palta_id]);
ALTER TABLE [comercial].[SancionSocioE4] CHECK CONSTRAINT [FK__SancionSo__varie__632F8E56];
ALTER TABLE [comercial].[Venta] WITH CHECK ADD CONSTRAINT [FK_Venta_Almacen] FOREIGN KEY ([almacen_id]) REFERENCES [logistica].[Almacen] ([almacen_id]);
ALTER TABLE [comercial].[Venta] CHECK CONSTRAINT [FK_Venta_Almacen];
ALTER TABLE [comercial].[Venta] WITH CHECK ADD CONSTRAINT [FK_Venta_CajaSesion] FOREIGN KEY ([caja_sesion_id]) REFERENCES [comercial].[CajaSesion] ([caja_sesion_id]);
ALTER TABLE [comercial].[Venta] CHECK CONSTRAINT [FK_Venta_CajaSesion];
ALTER TABLE [comercial].[Venta] WITH CHECK ADD CONSTRAINT [FK_Venta_ClienteEmpresa] FOREIGN KEY ([cliente_empresa_id]) REFERENCES [org].[Empresa] ([empresa_id]);
ALTER TABLE [comercial].[Venta] CHECK CONSTRAINT [FK_Venta_ClienteEmpresa];
ALTER TABLE [comercial].[Venta] WITH CHECK ADD CONSTRAINT [FK_Venta_ClientePersona] FOREIGN KEY ([cliente_persona_id]) REFERENCES [org].[Persona] ([persona_id]);
ALTER TABLE [comercial].[Venta] CHECK CONSTRAINT [FK_Venta_ClientePersona];
ALTER TABLE [comercial].[Venta] WITH CHECK ADD CONSTRAINT [FK_Venta_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [comercial].[Venta] CHECK CONSTRAINT [FK_Venta_UOT];
ALTER TABLE [comercial].[Venta] WITH CHECK ADD CONSTRAINT [FK_Venta_UsuarioAnulacion] FOREIGN KEY ([usuario_anulacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[Venta] CHECK CONSTRAINT [FK_Venta_UsuarioAnulacion];
ALTER TABLE [comercial].[Venta] WITH CHECK ADD CONSTRAINT [FK_Venta_Vendedor] FOREIGN KEY ([vendedor_usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[Venta] CHECK CONSTRAINT [FK_Venta_Vendedor];
ALTER TABLE [comercial].[VentaAnulacionPOS] WITH CHECK ADD CONSTRAINT [FK_VentaAnulacionPOS_Mov] FOREIGN KEY ([movimiento_reversa_id]) REFERENCES [logistica].[MovimientoInventario] ([movimiento_inventario_id]);
ALTER TABLE [comercial].[VentaAnulacionPOS] CHECK CONSTRAINT [FK_VentaAnulacionPOS_Mov];
ALTER TABLE [comercial].[VentaAnulacionPOS] WITH CHECK ADD CONSTRAINT [FK_VentaAnulacionPOS_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [comercial].[VentaAnulacionPOS] CHECK CONSTRAINT [FK_VentaAnulacionPOS_Usuario];
ALTER TABLE [comercial].[VentaAnulacionPOS] WITH CHECK ADD CONSTRAINT [FK_VentaAnulacionPOS_Venta] FOREIGN KEY ([venta_id]) REFERENCES [comercial].[Venta] ([venta_id]);
ALTER TABLE [comercial].[VentaAnulacionPOS] CHECK CONSTRAINT [FK_VentaAnulacionPOS_Venta];
ALTER TABLE [config].[DashboardElemento] WITH CHECK ADD CONSTRAINT [FK_DashboardElemento_Permiso] FOREIGN KEY ([permiso_id]) REFERENCES [seg].[Permiso] ([permiso_id]);
ALTER TABLE [config].[DashboardElemento] CHECK CONSTRAINT [FK_DashboardElemento_Permiso];
ALTER TABLE [config].[DashboardRolElemento] WITH CHECK ADD CONSTRAINT [FK_DashboardRolElemento_Elemento] FOREIGN KEY ([dashboard_elemento_id]) REFERENCES [config].[DashboardElemento] ([dashboard_elemento_id]);
ALTER TABLE [config].[DashboardRolElemento] CHECK CONSTRAINT [FK_DashboardRolElemento_Elemento];
ALTER TABLE [config].[DashboardRolElemento] WITH CHECK ADD CONSTRAINT [FK_DashboardRolElemento_Rol] FOREIGN KEY ([rol_id]) REFERENCES [seg].[Rol] ([rol_id]);
ALTER TABLE [config].[DashboardRolElemento] CHECK CONSTRAINT [FK_DashboardRolElemento_Rol];
ALTER TABLE [config].[DashboardUsuarioElemento] WITH CHECK ADD CONSTRAINT [FK_DashboardUsuarioElemento_Elemento] FOREIGN KEY ([dashboard_elemento_id]) REFERENCES [config].[DashboardElemento] ([dashboard_elemento_id]);
ALTER TABLE [config].[DashboardUsuarioElemento] CHECK CONSTRAINT [FK_DashboardUsuarioElemento_Elemento];
ALTER TABLE [config].[DashboardUsuarioElemento] WITH CHECK ADD CONSTRAINT [FK_DashboardUsuarioElemento_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [config].[DashboardUsuarioElemento] CHECK CONSTRAINT [FK_DashboardUsuarioElemento_Usuario];
ALTER TABLE [doc].[AsignacionPendiente] WITH CHECK ADD CONSTRAINT [FK__Asignacio__asign__2F50C2F4] FOREIGN KEY ([asignado_usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [doc].[AsignacionPendiente] CHECK CONSTRAINT [FK__Asignacio__asign__2F50C2F4];
ALTER TABLE [doc].[AsignacionPendiente] WITH CHECK ADD CONSTRAINT [FK__Asignacio__respo__2E5C9EBB] FOREIGN KEY ([responsable_usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [doc].[AsignacionPendiente] CHECK CONSTRAINT [FK__Asignacio__respo__2E5C9EBB];
ALTER TABLE [doc].[Destinatario] WITH CHECK ADD CONSTRAINT [FK__Destinata__uot_i__5B644F5C] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [doc].[Destinatario] CHECK CONSTRAINT [FK__Destinata__uot_i__5B644F5C];
ALTER TABLE [doc].[Destinatario] WITH CHECK ADD CONSTRAINT [FK__Destinata__usuar__27E4AB56] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [doc].[Destinatario] CHECK CONSTRAINT [FK__Destinata__usuar__27E4AB56];
ALTER TABLE [doc].[Documento] WITH CHECK ADD CONSTRAINT [FK__Documento__emiso__231FF639] FOREIGN KEY ([emisor_usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [doc].[Documento] CHECK CONSTRAINT [FK__Documento__emiso__231FF639];
ALTER TABLE [doc].[Documento] WITH CHECK ADD CONSTRAINT [FK__Documento__uot_e__597C06EA] FOREIGN KEY ([uot_emisor_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [doc].[Documento] CHECK CONSTRAINT [FK__Documento__uot_e__597C06EA];
ALTER TABLE [doc].[DocumentoArchivo] WITH CHECK ADD CONSTRAINT [FK__Documento__archi__316E1590] FOREIGN KEY ([archivo_id]) REFERENCES [archivo].[Archivo] ([archivo_id]);
ALTER TABLE [doc].[DocumentoArchivo] CHECK CONSTRAINT [FK__Documento__archi__316E1590];
ALTER TABLE [doc].[Evento] WITH CHECK ADD CONSTRAINT [FK__Evento__usuario___3632CAAD] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [doc].[Evento] CHECK CONSTRAINT [FK__Evento__usuario___3632CAAD];
ALTER TABLE [doc].[Hilo] WITH CHECK ADD CONSTRAINT [FK__Hilo__creado_por__1B7ED471] FOREIGN KEY ([creado_por_usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [doc].[Hilo] CHECK CONSTRAINT [FK__Hilo__creado_por__1B7ED471];
ALTER TABLE [doc].[Hilo] WITH CHECK ADD CONSTRAINT [FK__Hilo__uot_id__1A8AB038] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [doc].[Hilo] CHECK CONSTRAINT [FK__Hilo__uot_id__1A8AB038];
ALTER TABLE [doc].[Participante] WITH CHECK ADD CONSTRAINT [FK__Participa__usuar__2BB53C3A] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [doc].[Participante] CHECK CONSTRAINT [FK__Participa__usuar__2BB53C3A];
ALTER TABLE [doc].[ParticipanteUOT] WITH CHECK ADD CONSTRAINT [FK__Participa__uot_i__60290479] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [doc].[ParticipanteUOT] CHECK CONSTRAINT [FK__Participa__uot_i__60290479];
ALTER TABLE [doc].[ParticipanteUOT] WITH CHECK ADD CONSTRAINT [FK__Participa__usuar__5F34E040] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [doc].[ParticipanteUOT] CHECK CONSTRAINT [FK__Participa__usuar__5F34E040];
ALTER TABLE [finanzas].[CobroComprador] WITH CHECK ADD CONSTRAINT [FK_CobroComprador_Campania] FOREIGN KEY ([campania_venta_id]) REFERENCES [comercial].[CampaniaVenta] ([campania_venta_id]);
ALTER TABLE [finanzas].[CobroComprador] CHECK CONSTRAINT [FK_CobroComprador_Campania];
ALTER TABLE [finanzas].[CobroComprador] WITH CHECK ADD CONSTRAINT [FK_CobroComprador_OperativoCampania] FOREIGN KEY ([operativo_venta_id],[campania_venta_id]) REFERENCES [comercial].[OperativoVenta] ([operativo_venta_id],[campania_venta_id]);
ALTER TABLE [finanzas].[CobroComprador] CHECK CONSTRAINT [FK_CobroComprador_OperativoCampania];
ALTER TABLE [finanzas].[CobroComprador] WITH CHECK ADD CONSTRAINT [FK_DESCO_CobroComprador_usuario_anulacion_id] FOREIGN KEY ([usuario_anulacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [finanzas].[CobroComprador] CHECK CONSTRAINT [FK_DESCO_CobroComprador_usuario_anulacion_id];
ALTER TABLE [finanzas].[CobroComprador] WITH CHECK ADD CONSTRAINT [FK_DESCO_CobroComprador_usuario_confirmacion_id] FOREIGN KEY ([usuario_confirmacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [finanzas].[CobroComprador] CHECK CONSTRAINT [FK_DESCO_CobroComprador_usuario_confirmacion_id];
ALTER TABLE [finanzas].[EventoPagoE5] WITH CHECK ADD CONSTRAINT [FK__EventoPag__pago___5EF4E91E] FOREIGN KEY ([pago_socio_id]) REFERENCES [finanzas].[PagoSocio] ([pago_socio_id]);
ALTER TABLE [finanzas].[EventoPagoE5] CHECK CONSTRAINT [FK__EventoPag__pago___5EF4E91E];
ALTER TABLE [finanzas].[GastoCampania] WITH CHECK ADD CONSTRAINT [FK_GastoCampania_Campania] FOREIGN KEY ([campania_venta_id]) REFERENCES [comercial].[CampaniaVenta] ([campania_venta_id]);
ALTER TABLE [finanzas].[GastoCampania] CHECK CONSTRAINT [FK_GastoCampania_Campania];
ALTER TABLE [finanzas].[GastoCampania] WITH CHECK ADD CONSTRAINT [FK_GastoCampania_OperativoCampania] FOREIGN KEY ([operativo_venta_id],[campania_venta_id]) REFERENCES [comercial].[OperativoVenta] ([operativo_venta_id],[campania_venta_id]);
ALTER TABLE [finanzas].[GastoCampania] CHECK CONSTRAINT [FK_GastoCampania_OperativoCampania];
ALTER TABLE [finanzas].[GastoCampania] WITH CHECK ADD CONSTRAINT [FK_GastoCampania_Regla] FOREIGN KEY ([regla_prorrateo_id]) REFERENCES [finanzas].[ReglaProrrateo] ([regla_prorrateo_id]);
ALTER TABLE [finanzas].[GastoCampania] CHECK CONSTRAINT [FK_GastoCampania_Regla];
ALTER TABLE [finanzas].[GastoCampania] WITH CHECK ADD CONSTRAINT [FK_GastoCampania_TipoGasto] FOREIGN KEY ([tipo_gasto_id]) REFERENCES [finanzas].[TipoGasto] ([tipo_gasto_id]);
ALTER TABLE [finanzas].[GastoCampania] CHECK CONSTRAINT [FK_GastoCampania_TipoGasto];
ALTER TABLE [finanzas].[GastoProrrateoSocio] WITH CHECK ADD CONSTRAINT [FK_GastoProrrateoSocio_Gasto] FOREIGN KEY ([gasto_campania_id]) REFERENCES [finanzas].[GastoCampania] ([gasto_campania_id]);
ALTER TABLE [finanzas].[GastoProrrateoSocio] CHECK CONSTRAINT [FK_GastoProrrateoSocio_Gasto];
ALTER TABLE [finanzas].[GastoProrrateoSocio] WITH CHECK ADD CONSTRAINT [FK_GastoProrrateoSocio_Participacion] FOREIGN KEY ([participacion_campania_socio_id]) REFERENCES [comercial].[ParticipacionCampaniaSocio] ([participacion_campania_socio_id]);
ALTER TABLE [finanzas].[GastoProrrateoSocio] CHECK CONSTRAINT [FK_GastoProrrateoSocio_Participacion];
ALTER TABLE [finanzas].[GastoRepartoLineaE5] WITH CHECK ADD CONSTRAINT [FK__GastoRepa__parti__556B7EE4] FOREIGN KEY ([participacion_id]) REFERENCES [comercial].[ParticipacionCampaniaSocio] ([participacion_campania_socio_id]);
ALTER TABLE [finanzas].[GastoRepartoLineaE5] CHECK CONSTRAINT [FK__GastoRepa__parti__556B7EE4];
ALTER TABLE [finanzas].[GastoRepartoLineaE5] WITH CHECK ADD CONSTRAINT [FK__GastoRepa__repar__54775AAB] FOREIGN KEY ([reparto_id]) REFERENCES [finanzas].[GastoRepartoVersionE5] ([reparto_id]);
ALTER TABLE [finanzas].[GastoRepartoLineaE5] CHECK CONSTRAINT [FK__GastoRepa__repar__54775AAB];
ALTER TABLE [finanzas].[GastoRepartoVersionE5] WITH CHECK ADD CONSTRAINT [FK__GastoRepa__gasto__4EBE8155] FOREIGN KEY ([gasto_campania_id]) REFERENCES [finanzas].[GastoCampania] ([gasto_campania_id]);
ALTER TABLE [finanzas].[GastoRepartoVersionE5] CHECK CONSTRAINT [FK__GastoRepa__gasto__4EBE8155];
ALTER TABLE [finanzas].[LiquidacionDetalle] WITH CHECK ADD CONSTRAINT [FK_LiquidacionDetalle_Ajuste] FOREIGN KEY ([ajuste_precio_socio_id]) REFERENCES [comercial].[AjustePrecioSocio] ([ajuste_precio_socio_id]);
ALTER TABLE [finanzas].[LiquidacionDetalle] CHECK CONSTRAINT [FK_LiquidacionDetalle_Ajuste];
ALTER TABLE [finanzas].[LiquidacionDetalle] WITH CHECK ADD CONSTRAINT [FK_LiquidacionDetalle_Entrega] FOREIGN KEY ([entrega_detalle_id]) REFERENCES [comercial].[EntregaDetalle] ([entrega_detalle_id]);
ALTER TABLE [finanzas].[LiquidacionDetalle] CHECK CONSTRAINT [FK_LiquidacionDetalle_Entrega];
ALTER TABLE [finanzas].[LiquidacionDetalle] WITH CHECK ADD CONSTRAINT [FK_LiquidacionDetalle_Gasto] FOREIGN KEY ([gasto_prorrateo_socio_id]) REFERENCES [finanzas].[GastoProrrateoSocio] ([gasto_prorrateo_socio_id]);
ALTER TABLE [finanzas].[LiquidacionDetalle] CHECK CONSTRAINT [FK_LiquidacionDetalle_Gasto];
ALTER TABLE [finanzas].[LiquidacionDetalle] WITH CHECK ADD CONSTRAINT [FK_LiquidacionDetalle_Liquidacion] FOREIGN KEY ([liquidacion_socio_id]) REFERENCES [finanzas].[LiquidacionSocio] ([liquidacion_socio_id]);
ALTER TABLE [finanzas].[LiquidacionDetalle] CHECK CONSTRAINT [FK_LiquidacionDetalle_Liquidacion];
ALTER TABLE [finanzas].[LiquidacionSnapshotE5] WITH CHECK ADD CONSTRAINT [FK__Liquidaci__campa__5A303401] FOREIGN KEY ([campania_venta_id]) REFERENCES [comercial].[CampaniaVenta] ([campania_venta_id]);
ALTER TABLE [finanzas].[LiquidacionSnapshotE5] CHECK CONSTRAINT [FK__Liquidaci__campa__5A303401];
ALTER TABLE [finanzas].[LiquidacionSnapshotE5] WITH CHECK ADD CONSTRAINT [FK__Liquidaci__liqui__593C0FC8] FOREIGN KEY ([liquidacion_socio_id]) REFERENCES [finanzas].[LiquidacionSocio] ([liquidacion_socio_id]);
ALTER TABLE [finanzas].[LiquidacionSnapshotE5] CHECK CONSTRAINT [FK__Liquidaci__liqui__593C0FC8];
ALTER TABLE [finanzas].[LiquidacionSocio] WITH CHECK ADD CONSTRAINT [FK_LiquidacionSocio_Participacion] FOREIGN KEY ([participacion_campania_socio_id]) REFERENCES [comercial].[ParticipacionCampaniaSocio] ([participacion_campania_socio_id]);
ALTER TABLE [finanzas].[LiquidacionSocio] CHECK CONSTRAINT [FK_LiquidacionSocio_Participacion];
ALTER TABLE [finanzas].[PagoBeneficiarioE5] WITH CHECK ADD CONSTRAINT [FK__PagoBenef__benef__6EE13824] FOREIGN KEY ([beneficiario_persona_id]) REFERENCES [org].[Persona] ([persona_id]);
ALTER TABLE [finanzas].[PagoBeneficiarioE5] CHECK CONSTRAINT [FK__PagoBenef__benef__6EE13824];
ALTER TABLE [finanzas].[PagoBeneficiarioE5] WITH CHECK ADD CONSTRAINT [FK__PagoBenef__pago___6DED13EB] FOREIGN KEY ([pago_socio_id]) REFERENCES [finanzas].[PagoSocio] ([pago_socio_id]);
ALTER TABLE [finanzas].[PagoBeneficiarioE5] CHECK CONSTRAINT [FK__PagoBenef__pago___6DED13EB];
ALTER TABLE [finanzas].[PagoBeneficiarioE5] WITH CHECK ADD CONSTRAINT [FK__PagoBenef__usuar__6FD55C5D] FOREIGN KEY ([usuario_registro_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [finanzas].[PagoBeneficiarioE5] CHECK CONSTRAINT [FK__PagoBenef__usuar__6FD55C5D];
ALTER TABLE [finanzas].[PagoBeneficiarioE5] WITH CHECK ADD CONSTRAINT [FK_E5_PagoBeneficiario_Comprobante] FOREIGN KEY ([comprobante_archivo_id]) REFERENCES [archivo].[Archivo] ([archivo_id]);
ALTER TABLE [finanzas].[PagoBeneficiarioE5] CHECK CONSTRAINT [FK_E5_PagoBeneficiario_Comprobante];
ALTER TABLE [finanzas].[PagoSocio] WITH CHECK ADD CONSTRAINT [FK_DESCO_PagoSocio_usuario_anulacion_id] FOREIGN KEY ([usuario_anulacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [finanzas].[PagoSocio] CHECK CONSTRAINT [FK_DESCO_PagoSocio_usuario_anulacion_id];
ALTER TABLE [finanzas].[PagoSocio] WITH CHECK ADD CONSTRAINT [FK_DESCO_PagoSocio_usuario_confirmacion_id] FOREIGN KEY ([usuario_confirmacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [finanzas].[PagoSocio] CHECK CONSTRAINT [FK_DESCO_PagoSocio_usuario_confirmacion_id];
ALTER TABLE [finanzas].[PagoSocio] WITH CHECK ADD CONSTRAINT [FK_PagoSocio_Liquidacion] FOREIGN KEY ([liquidacion_socio_id]) REFERENCES [finanzas].[LiquidacionSocio] ([liquidacion_socio_id]);
ALTER TABLE [finanzas].[PagoSocio] CHECK CONSTRAINT [FK_PagoSocio_Liquidacion];
ALTER TABLE [geo].[CentroPoblado] WITH CHECK ADD CONSTRAINT [FK_CentroPoblado_Distrito] FOREIGN KEY ([distrito_codigo]) REFERENCES [geo].[Distrito] ([distrito_codigo]);
ALTER TABLE [geo].[CentroPoblado] CHECK CONSTRAINT [FK_CentroPoblado_Distrito];
ALTER TABLE [geo].[Distrito] WITH CHECK ADD CONSTRAINT [FK_Distrito_Provincia] FOREIGN KEY ([provincia_codigo]) REFERENCES [geo].[Provincia] ([provincia_codigo]);
ALTER TABLE [geo].[Distrito] CHECK CONSTRAINT [FK_Distrito_Provincia];
ALTER TABLE [geo].[Provincia] WITH CHECK ADD CONSTRAINT [FK_Provincia_Departamento] FOREIGN KEY ([departamento_codigo]) REFERENCES [geo].[Departamento] ([departamento_codigo]);
ALTER TABLE [geo].[Provincia] CHECK CONSTRAINT [FK_Provincia_Departamento];
ALTER TABLE [geo].[Ubicacion] WITH CHECK ADD CONSTRAINT [FK_Ubicacion_CentroPobladoDistrito] FOREIGN KEY ([centro_poblado_id],[distrito_codigo]) REFERENCES [geo].[CentroPoblado] ([centro_poblado_id],[distrito_codigo]);
ALTER TABLE [geo].[Ubicacion] CHECK CONSTRAINT [FK_Ubicacion_CentroPobladoDistrito];
ALTER TABLE [geo].[Ubicacion] WITH CHECK ADD CONSTRAINT [FK_Ubicacion_Distrito] FOREIGN KEY ([distrito_codigo]) REFERENCES [geo].[Distrito] ([distrito_codigo]);
ALTER TABLE [geo].[Ubicacion] CHECK CONSTRAINT [FK_Ubicacion_Distrito];
ALTER TABLE [geo].[ZonaProductivaPredio] WITH CHECK ADD CONSTRAINT [FK_ZonaProductivaPredio_Predio] FOREIGN KEY ([predio_id]) REFERENCES [prod].[Predio] ([predio_id]);
ALTER TABLE [geo].[ZonaProductivaPredio] CHECK CONSTRAINT [FK_ZonaProductivaPredio_Predio];
ALTER TABLE [geo].[ZonaProductivaPredio] WITH CHECK ADD CONSTRAINT [FK_ZonaProductivaPredio_Zona] FOREIGN KEY ([zona_productiva_id]) REFERENCES [geo].[ZonaProductiva] ([zona_productiva_id]);
ALTER TABLE [geo].[ZonaProductivaPredio] CHECK CONSTRAINT [FK_ZonaProductivaPredio_Zona];
ALTER TABLE [geo].[ZonaProductivaUbicacion] WITH CHECK ADD CONSTRAINT [FK_ZonaProductivaUbicacion_CentroPoblado] FOREIGN KEY ([centro_poblado_id]) REFERENCES [geo].[CentroPoblado] ([centro_poblado_id]);
ALTER TABLE [geo].[ZonaProductivaUbicacion] CHECK CONSTRAINT [FK_ZonaProductivaUbicacion_CentroPoblado];
ALTER TABLE [geo].[ZonaProductivaUbicacion] WITH CHECK ADD CONSTRAINT [FK_ZonaProductivaUbicacion_Distrito] FOREIGN KEY ([distrito_codigo]) REFERENCES [geo].[Distrito] ([distrito_codigo]);
ALTER TABLE [geo].[ZonaProductivaUbicacion] CHECK CONSTRAINT [FK_ZonaProductivaUbicacion_Distrito];
ALTER TABLE [geo].[ZonaProductivaUbicacion] WITH CHECK ADD CONSTRAINT [FK_ZonaProductivaUbicacion_Zona] FOREIGN KEY ([zona_productiva_id]) REFERENCES [geo].[ZonaProductiva] ([zona_productiva_id]);
ALTER TABLE [geo].[ZonaProductivaUbicacion] CHECK CONSTRAINT [FK_ZonaProductivaUbicacion_Zona];
ALTER TABLE [logistica].[Almacen] WITH CHECK ADD CONSTRAINT [FK_Almacen_Ubicacion] FOREIGN KEY ([ubicacion_id]) REFERENCES [geo].[Ubicacion] ([ubicacion_id]);
ALTER TABLE [logistica].[Almacen] CHECK CONSTRAINT [FK_Almacen_Ubicacion];
ALTER TABLE [logistica].[Almacen] WITH CHECK ADD CONSTRAINT [FK_Almacen_UOT] FOREIGN KEY ([uot_propietaria_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [logistica].[Almacen] CHECK CONSTRAINT [FK_Almacen_UOT];
ALTER TABLE [logistica].[AlmacenProductoEvento] WITH CHECK ADD CONSTRAINT [FK_AlmacenProductoEvento_Almacen] FOREIGN KEY ([almacen_id]) REFERENCES [logistica].[Almacen] ([almacen_id]);
ALTER TABLE [logistica].[AlmacenProductoEvento] CHECK CONSTRAINT [FK_AlmacenProductoEvento_Almacen];
ALTER TABLE [logistica].[AlmacenProductoEvento] WITH CHECK ADD CONSTRAINT [FK_AlmacenProductoEvento_Producto] FOREIGN KEY ([producto_id]) REFERENCES [logistica].[Producto] ([producto_id]);
ALTER TABLE [logistica].[AlmacenProductoEvento] CHECK CONSTRAINT [FK_AlmacenProductoEvento_Producto];
ALTER TABLE [logistica].[AlmacenProductoEvento] WITH CHECK ADD CONSTRAINT [FK_AlmacenProductoEvento_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [logistica].[AlmacenProductoEvento] CHECK CONSTRAINT [FK_AlmacenProductoEvento_Usuario];
ALTER TABLE [logistica].[AlmacenProductoStock] WITH CHECK ADD CONSTRAINT [FK_Stock_Almacen] FOREIGN KEY ([almacen_id]) REFERENCES [logistica].[Almacen] ([almacen_id]);
ALTER TABLE [logistica].[AlmacenProductoStock] CHECK CONSTRAINT [FK_Stock_Almacen];
ALTER TABLE [logistica].[AlmacenProductoStock] WITH CHECK ADD CONSTRAINT [FK_Stock_Producto] FOREIGN KEY ([producto_id]) REFERENCES [logistica].[Producto] ([producto_id]);
ALTER TABLE [logistica].[AlmacenProductoStock] CHECK CONSTRAINT [FK_Stock_Producto];
ALTER TABLE [logistica].[AlmacenUOT] WITH CHECK ADD CONSTRAINT [FK_AlmacenUOT_Almacen] FOREIGN KEY ([almacen_id]) REFERENCES [logistica].[Almacen] ([almacen_id]);
ALTER TABLE [logistica].[AlmacenUOT] CHECK CONSTRAINT [FK_AlmacenUOT_Almacen];
ALTER TABLE [logistica].[AlmacenUOT] WITH CHECK ADD CONSTRAINT [FK_AlmacenUOT_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [logistica].[AlmacenUOT] CHECK CONSTRAINT [FK_AlmacenUOT_UOT];
ALTER TABLE [logistica].[BienEstadoHistorial] WITH CHECK ADD CONSTRAINT [FK_BienEstadoHistorial_Bien] FOREIGN KEY ([bien_inventario_id]) REFERENCES [logistica].[BienInventario] ([bien_inventario_id]);
ALTER TABLE [logistica].[BienEstadoHistorial] CHECK CONSTRAINT [FK_BienEstadoHistorial_Bien];
ALTER TABLE [logistica].[BienEstadoHistorial] WITH CHECK ADD CONSTRAINT [FK_BienEstadoHistorial_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [logistica].[BienEstadoHistorial] CHECK CONSTRAINT [FK_BienEstadoHistorial_Usuario];
ALTER TABLE [logistica].[BienImagen] WITH CHECK ADD CONSTRAINT [FK_BienImagen_Archivo] FOREIGN KEY ([archivo_id]) REFERENCES [archivo].[Archivo] ([archivo_id]);
ALTER TABLE [logistica].[BienImagen] CHECK CONSTRAINT [FK_BienImagen_Archivo];
ALTER TABLE [logistica].[BienImagen] WITH CHECK ADD CONSTRAINT [FK_BienImagen_Bien] FOREIGN KEY ([bien_inventario_id]) REFERENCES [logistica].[BienInventario] ([bien_inventario_id]);
ALTER TABLE [logistica].[BienImagen] CHECK CONSTRAINT [FK_BienImagen_Bien];
ALTER TABLE [logistica].[BienIncidente] WITH CHECK ADD CONSTRAINT [FK_BienIncidente_Bien] FOREIGN KEY ([bien_inventario_id]) REFERENCES [logistica].[BienInventario] ([bien_inventario_id]);
ALTER TABLE [logistica].[BienIncidente] CHECK CONSTRAINT [FK_BienIncidente_Bien];
ALTER TABLE [logistica].[BienIncidente] WITH CHECK ADD CONSTRAINT [FK_BienIncidente_UsuarioCierre] FOREIGN KEY ([usuario_cierre_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [logistica].[BienIncidente] CHECK CONSTRAINT [FK_BienIncidente_UsuarioCierre];
ALTER TABLE [logistica].[BienIncidente] WITH CHECK ADD CONSTRAINT [FK_BienIncidente_UsuarioReporte] FOREIGN KEY ([usuario_reporte_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [logistica].[BienIncidente] CHECK CONSTRAINT [FK_BienIncidente_UsuarioReporte];
ALTER TABLE [logistica].[BienInventario] WITH CHECK ADD CONSTRAINT [FK_BienInventario_Empresa] FOREIGN KEY ([empresa_id]) REFERENCES [org].[Empresa] ([empresa_id]);
ALTER TABLE [logistica].[BienInventario] CHECK CONSTRAINT [FK_BienInventario_Empresa];
ALTER TABLE [logistica].[BienInventario] WITH CHECK ADD CONSTRAINT [FK_BienInventario_ProveedorEmpresa] FOREIGN KEY ([proveedor_empresa_id]) REFERENCES [org].[Empresa] ([empresa_id]);
ALTER TABLE [logistica].[BienInventario] CHECK CONSTRAINT [FK_BienInventario_ProveedorEmpresa];
ALTER TABLE [logistica].[BienInventario] WITH CHECK ADD CONSTRAINT [FK_BienInventario_ProveedorPersona] FOREIGN KEY ([proveedor_persona_id]) REFERENCES [org].[Persona] ([persona_id]);
ALTER TABLE [logistica].[BienInventario] CHECK CONSTRAINT [FK_BienInventario_ProveedorPersona];
ALTER TABLE [logistica].[BienInventario] WITH CHECK ADD CONSTRAINT [FK_BienInventario_Tipo] FOREIGN KEY ([tipo_bien_id]) REFERENCES [logistica].[TipoBien] ([tipo_bien_id]);
ALTER TABLE [logistica].[BienInventario] CHECK CONSTRAINT [FK_BienInventario_Tipo];
ALTER TABLE [logistica].[BienInventario] WITH CHECK ADD CONSTRAINT [FK_BienInventario_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [logistica].[BienInventario] CHECK CONSTRAINT [FK_BienInventario_UOT];
ALTER TABLE [logistica].[DetalleMovimientoInventario] WITH CHECK ADD CONSTRAINT [FK_DetMovInv_Movimiento] FOREIGN KEY ([movimiento_inventario_id]) REFERENCES [logistica].[MovimientoInventario] ([movimiento_inventario_id]);
ALTER TABLE [logistica].[DetalleMovimientoInventario] CHECK CONSTRAINT [FK_DetMovInv_Movimiento];
ALTER TABLE [logistica].[DetalleMovimientoInventario] WITH CHECK ADD CONSTRAINT [FK_DetMovInv_Producto] FOREIGN KEY ([producto_id]) REFERENCES [logistica].[Producto] ([producto_id]);
ALTER TABLE [logistica].[DetalleMovimientoInventario] CHECK CONSTRAINT [FK_DetMovInv_Producto];
ALTER TABLE [logistica].[EntregaTecnica] WITH CHECK ADD CONSTRAINT [FK_EntregaTecnica_Almacen] FOREIGN KEY ([almacen_id]) REFERENCES [logistica].[Almacen] ([almacen_id]);
ALTER TABLE [logistica].[EntregaTecnica] CHECK CONSTRAINT [FK_EntregaTecnica_Almacen];
ALTER TABLE [logistica].[EntregaTecnica] WITH CHECK ADD CONSTRAINT [FK_EntregaTecnica_Empleado] FOREIGN KEY ([empleado_id]) REFERENCES [org].[Empleado] ([empleado_id]);
ALTER TABLE [logistica].[EntregaTecnica] CHECK CONSTRAINT [FK_EntregaTecnica_Empleado];
ALTER TABLE [logistica].[EntregaTecnica] WITH CHECK ADD CONSTRAINT [FK_EntregaTecnica_Movimiento] FOREIGN KEY ([movimiento_inventario_id]) REFERENCES [logistica].[MovimientoInventario] ([movimiento_inventario_id]);
ALTER TABLE [logistica].[EntregaTecnica] CHECK CONSTRAINT [FK_EntregaTecnica_Movimiento];
ALTER TABLE [logistica].[EntregaTecnica] WITH CHECK ADD CONSTRAINT [FK_EntregaTecnica_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [logistica].[EntregaTecnica] CHECK CONSTRAINT [FK_EntregaTecnica_UOT];
ALTER TABLE [logistica].[EntregaTecnica] WITH CHECK ADD CONSTRAINT [FK_EntregaTecnica_Usuario] FOREIGN KEY ([usuario_entrega_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [logistica].[EntregaTecnica] CHECK CONSTRAINT [FK_EntregaTecnica_Usuario];
ALTER TABLE [logistica].[EntregaTecnicaDetalle] WITH CHECK ADD CONSTRAINT [FK_EntregaTecnicaDetalle_Entrega] FOREIGN KEY ([entrega_tecnica_id]) REFERENCES [logistica].[EntregaTecnica] ([entrega_tecnica_id]);
ALTER TABLE [logistica].[EntregaTecnicaDetalle] CHECK CONSTRAINT [FK_EntregaTecnicaDetalle_Entrega];
ALTER TABLE [logistica].[EntregaTecnicaDetalle] WITH CHECK ADD CONSTRAINT [FK_EntregaTecnicaDetalle_Producto] FOREIGN KEY ([producto_id]) REFERENCES [logistica].[Producto] ([producto_id]);
ALTER TABLE [logistica].[EntregaTecnicaDetalle] CHECK CONSTRAINT [FK_EntregaTecnicaDetalle_Producto];
ALTER TABLE [logistica].[MovimientoInventario] WITH CHECK ADD CONSTRAINT [FK_MovInv_Almacen] FOREIGN KEY ([almacen_id]) REFERENCES [logistica].[Almacen] ([almacen_id]);
ALTER TABLE [logistica].[MovimientoInventario] CHECK CONSTRAINT [FK_MovInv_Almacen];
ALTER TABLE [logistica].[MovimientoInventario] WITH CHECK ADD CONSTRAINT [FK_MovInv_ProveedorEmpresa] FOREIGN KEY ([proveedor_empresa_id]) REFERENCES [org].[Empresa] ([empresa_id]);
ALTER TABLE [logistica].[MovimientoInventario] CHECK CONSTRAINT [FK_MovInv_ProveedorEmpresa];
ALTER TABLE [logistica].[MovimientoInventario] WITH CHECK ADD CONSTRAINT [FK_MovInv_ProveedorPersona] FOREIGN KEY ([proveedor_persona_id]) REFERENCES [org].[Persona] ([persona_id]);
ALTER TABLE [logistica].[MovimientoInventario] CHECK CONSTRAINT [FK_MovInv_ProveedorPersona];
ALTER TABLE [logistica].[MovimientoInventario] WITH CHECK ADD CONSTRAINT [FK_MovInv_Relacionado] FOREIGN KEY ([movimiento_relacionado_id]) REFERENCES [logistica].[MovimientoInventario] ([movimiento_inventario_id]);
ALTER TABLE [logistica].[MovimientoInventario] CHECK CONSTRAINT [FK_MovInv_Relacionado];
ALTER TABLE [logistica].[MovimientoInventario] WITH CHECK ADD CONSTRAINT [FK_MovInv_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [logistica].[MovimientoInventario] CHECK CONSTRAINT [FK_MovInv_UOT];
ALTER TABLE [logistica].[MovimientoInventario] WITH CHECK ADD CONSTRAINT [FK_MovInv_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [logistica].[MovimientoInventario] CHECK CONSTRAINT [FK_MovInv_Usuario];
ALTER TABLE [logistica].[MovimientoInventarioLote] WITH CHECK ADD CONSTRAINT [FK__Movimient__detal__58D1FB74] FOREIGN KEY ([detalle_movimiento_id]) REFERENCES [logistica].[DetalleMovimientoInventario] ([detalle_movimiento_inventario_id]);
ALTER TABLE [logistica].[MovimientoInventarioLote] CHECK CONSTRAINT [FK__Movimient__detal__58D1FB74];
ALTER TABLE [logistica].[MovimientoInventarioLote] WITH CHECK ADD CONSTRAINT [FK__Movimient__detal__59C61FAD] FOREIGN KEY ([detalle_origen_id]) REFERENCES [logistica].[DetalleMovimientoInventario] ([detalle_movimiento_inventario_id]);
ALTER TABLE [logistica].[MovimientoInventarioLote] CHECK CONSTRAINT [FK__Movimient__detal__59C61FAD];
ALTER TABLE [logistica].[ProductoImagen] WITH CHECK ADD CONSTRAINT [FK_ProductoImagen_Archivo] FOREIGN KEY ([archivo_id]) REFERENCES [archivo].[Archivo] ([archivo_id]);
ALTER TABLE [logistica].[ProductoImagen] CHECK CONSTRAINT [FK_ProductoImagen_Archivo];
ALTER TABLE [logistica].[ProductoImagen] WITH CHECK ADD CONSTRAINT [FK_ProductoImagen_Producto] FOREIGN KEY ([producto_id]) REFERENCES [logistica].[Producto] ([producto_id]);
ALTER TABLE [logistica].[ProductoImagen] CHECK CONSTRAINT [FK_ProductoImagen_Producto];
ALTER TABLE [logistica].[ProductoPrecio] WITH CHECK ADD CONSTRAINT [FK_ProductoPrecio_Origen] FOREIGN KEY ([producto_precio_origen_id]) REFERENCES [logistica].[ProductoPrecio] ([producto_precio_id]);
ALTER TABLE [logistica].[ProductoPrecio] CHECK CONSTRAINT [FK_ProductoPrecio_Origen];
ALTER TABLE [logistica].[ProductoPrecio] WITH CHECK ADD CONSTRAINT [FK_ProductoPrecio_Producto] FOREIGN KEY ([producto_id]) REFERENCES [logistica].[Producto] ([producto_id]);
ALTER TABLE [logistica].[ProductoPrecio] CHECK CONSTRAINT [FK_ProductoPrecio_Producto];
ALTER TABLE [logistica].[ProductoPrecio] WITH CHECK ADD CONSTRAINT [FK_ProductoPrecio_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [logistica].[ProductoPrecio] CHECK CONSTRAINT [FK_ProductoPrecio_UOT];
ALTER TABLE [logistica].[ProductoPrecio] WITH CHECK ADD CONSTRAINT [FK_ProductoPrecio_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [logistica].[ProductoPrecio] CHECK CONSTRAINT [FK_ProductoPrecio_Usuario];
ALTER TABLE [logistica].[ProductoUOTPolitica] WITH CHECK ADD CONSTRAINT [FK_DESCO_Politica_Producto] FOREIGN KEY ([producto_id]) REFERENCES [logistica].[Producto] ([producto_id]);
ALTER TABLE [logistica].[ProductoUOTPolitica] CHECK CONSTRAINT [FK_DESCO_Politica_Producto];
ALTER TABLE [logistica].[ProductoUOTPolitica] WITH CHECK ADD CONSTRAINT [FK_DESCO_Politica_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [logistica].[ProductoUOTPolitica] CHECK CONSTRAINT [FK_DESCO_Politica_UOT];
ALTER TABLE [logistica].[ProgramacionProducto] WITH CHECK ADD CONSTRAINT [FK_DESCO_PP_Almacen] FOREIGN KEY ([almacen_id]) REFERENCES [logistica].[Almacen] ([almacen_id]);
ALTER TABLE [logistica].[ProgramacionProducto] CHECK CONSTRAINT [FK_DESCO_PP_Almacen];
ALTER TABLE [logistica].[ProgramacionProducto] WITH CHECK ADD CONSTRAINT [FK_DESCO_PP_Archivo] FOREIGN KEY ([archivo_autorizacion_id]) REFERENCES [archivo].[Archivo] ([archivo_id]);
ALTER TABLE [logistica].[ProgramacionProducto] CHECK CONSTRAINT [FK_DESCO_PP_Archivo];
ALTER TABLE [logistica].[ProgramacionProducto] WITH CHECK ADD CONSTRAINT [FK_DESCO_PP_Empleado] FOREIGN KEY ([empleado_id]) REFERENCES [org].[Empleado] ([empleado_id]);
ALTER TABLE [logistica].[ProgramacionProducto] CHECK CONSTRAINT [FK_DESCO_PP_Empleado];
ALTER TABLE [logistica].[ProgramacionProducto] WITH CHECK ADD CONSTRAINT [FK_DESCO_PP_Producto] FOREIGN KEY ([producto_id]) REFERENCES [logistica].[Producto] ([producto_id]);
ALTER TABLE [logistica].[ProgramacionProducto] CHECK CONSTRAINT [FK_DESCO_PP_Producto];
ALTER TABLE [logistica].[ProgramacionProducto] WITH CHECK ADD CONSTRAINT [FK_DESCO_PP_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [logistica].[ProgramacionProducto] CHECK CONSTRAINT [FK_DESCO_PP_UOT];
ALTER TABLE [logistica].[ProgramacionProductoEvento] WITH CHECK ADD CONSTRAINT [FK_DESCO_PPEvento_Mov] FOREIGN KEY ([movimiento_inventario_id]) REFERENCES [logistica].[MovimientoInventario] ([movimiento_inventario_id]);
ALTER TABLE [logistica].[ProgramacionProductoEvento] CHECK CONSTRAINT [FK_DESCO_PPEvento_Mov];
ALTER TABLE [logistica].[ProgramacionProductoEvento] WITH CHECK ADD CONSTRAINT [FK_DESCO_PPEvento_Programacion] FOREIGN KEY ([programacion_producto_id]) REFERENCES [logistica].[ProgramacionProducto] ([programacion_producto_id]);
ALTER TABLE [logistica].[ProgramacionProductoEvento] CHECK CONSTRAINT [FK_DESCO_PPEvento_Programacion];
ALTER TABLE [logistica].[RecursoMovimiento] WITH CHECK ADD CONSTRAINT [FK_RecursoMovimiento_RecursoProgramado] FOREIGN KEY ([recurso_programado_id]) REFERENCES [logistica].[RecursoProgramado] ([recurso_programado_id]);
ALTER TABLE [logistica].[RecursoMovimiento] CHECK CONSTRAINT [FK_RecursoMovimiento_RecursoProgramado];
ALTER TABLE [logistica].[RecursoMovimiento] WITH CHECK ADD CONSTRAINT [FK_RecursoMovimiento_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [logistica].[RecursoMovimiento] CHECK CONSTRAINT [FK_RecursoMovimiento_Usuario];
ALTER TABLE [logistica].[RecursoProgramado] WITH CHECK ADD CONSTRAINT [FK_RecursoProgramado_Bien] FOREIGN KEY ([bien_inventario_id]) REFERENCES [logistica].[BienInventario] ([bien_inventario_id]);
ALTER TABLE [logistica].[RecursoProgramado] CHECK CONSTRAINT [FK_RecursoProgramado_Bien];
ALTER TABLE [logistica].[RecursoProgramado] WITH CHECK ADD CONSTRAINT [FK_RecursoProgramado_Campania] FOREIGN KEY ([campania_venta_id]) REFERENCES [comercial].[CampaniaVenta] ([campania_venta_id]);
ALTER TABLE [logistica].[RecursoProgramado] CHECK CONSTRAINT [FK_RecursoProgramado_Campania];
ALTER TABLE [logistica].[RecursoProgramado] WITH CHECK ADD CONSTRAINT [FK_RecursoProgramado_Operativo] FOREIGN KEY ([operativo_venta_id]) REFERENCES [comercial].[OperativoVenta] ([operativo_venta_id]);
ALTER TABLE [logistica].[RecursoProgramado] CHECK CONSTRAINT [FK_RecursoProgramado_Operativo];
ALTER TABLE [logistica].[RecursoProgramado] WITH CHECK ADD CONSTRAINT [FK_RecursoProgramado_Salida] FOREIGN KEY ([salida_campo_id]) REFERENCES [campo].[SalidaCampo] ([salida_campo_id]);
ALTER TABLE [logistica].[RecursoProgramado] CHECK CONSTRAINT [FK_RecursoProgramado_Salida];
ALTER TABLE [logistica].[RecursoProgramado] WITH CHECK ADD CONSTRAINT [FK_RecursoProgramado_Suministro] FOREIGN KEY ([suministro_id]) REFERENCES [logistica].[Suministro] ([suministro_id]);
ALTER TABLE [logistica].[RecursoProgramado] CHECK CONSTRAINT [FK_RecursoProgramado_Suministro];
ALTER TABLE [logistica].[RecursoProgramado] WITH CHECK ADD CONSTRAINT [FK_RecursoProgramado_UsuarioCancelacion] FOREIGN KEY ([usuario_cancelacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [logistica].[RecursoProgramado] CHECK CONSTRAINT [FK_RecursoProgramado_UsuarioCancelacion];
ALTER TABLE [logistica].[RecursoProgramado] WITH CHECK ADD CONSTRAINT [FK_RecursoProgramado_UsuarioProgramacion] FOREIGN KEY ([usuario_programacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [logistica].[RecursoProgramado] CHECK CONSTRAINT [FK_RecursoProgramado_UsuarioProgramacion];
ALTER TABLE [logistica].[RecursoProgramadoArchivo] WITH CHECK ADD CONSTRAINT [FK_DESCO_RPArchivo_Archivo] FOREIGN KEY ([archivo_id]) REFERENCES [archivo].[Archivo] ([archivo_id]);
ALTER TABLE [logistica].[RecursoProgramadoArchivo] CHECK CONSTRAINT [FK_DESCO_RPArchivo_Archivo];
ALTER TABLE [logistica].[RecursoProgramadoArchivo] WITH CHECK ADD CONSTRAINT [FK_DESCO_RPArchivo_RP] FOREIGN KEY ([recurso_programado_id]) REFERENCES [logistica].[RecursoProgramado] ([recurso_programado_id]);
ALTER TABLE [logistica].[RecursoProgramadoArchivo] CHECK CONSTRAINT [FK_DESCO_RPArchivo_RP];
ALTER TABLE [logistica].[ReservaStock] WITH CHECK ADD CONSTRAINT [FK_ReservaStock_Almacen] FOREIGN KEY ([almacen_id]) REFERENCES [logistica].[Almacen] ([almacen_id]);
ALTER TABLE [logistica].[ReservaStock] CHECK CONSTRAINT [FK_ReservaStock_Almacen];
ALTER TABLE [logistica].[ReservaStock] WITH CHECK ADD CONSTRAINT [FK_ReservaStock_DetalleVenta] FOREIGN KEY ([detalle_venta_id]) REFERENCES [comercial].[DetalleVenta] ([detalle_venta_id]);
ALTER TABLE [logistica].[ReservaStock] CHECK CONSTRAINT [FK_ReservaStock_DetalleVenta];
ALTER TABLE [logistica].[ReservaStock] WITH CHECK ADD CONSTRAINT [FK_ReservaStock_Producto] FOREIGN KEY ([producto_id]) REFERENCES [logistica].[Producto] ([producto_id]);
ALTER TABLE [logistica].[ReservaStock] CHECK CONSTRAINT [FK_ReservaStock_Producto];
ALTER TABLE [logistica].[SalidaBien] WITH CHECK ADD CONSTRAINT [FK_SalidaBien_Bien] FOREIGN KEY ([bien_inventario_id]) REFERENCES [logistica].[BienInventario] ([bien_inventario_id]);
ALTER TABLE [logistica].[SalidaBien] CHECK CONSTRAINT [FK_SalidaBien_Bien];
ALTER TABLE [logistica].[SalidaBien] WITH CHECK ADD CONSTRAINT [FK_SalidaBien_Salida] FOREIGN KEY ([salida_campo_id]) REFERENCES [campo].[SalidaCampo] ([salida_campo_id]);
ALTER TABLE [logistica].[SalidaBien] CHECK CONSTRAINT [FK_SalidaBien_Salida];
ALTER TABLE [logistica].[Suministro] WITH CHECK ADD CONSTRAINT [FK_Suministro_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [logistica].[Suministro] CHECK CONSTRAINT [FK_Suministro_UOT];
ALTER TABLE [logistica].[SuministroMovimiento] WITH CHECK ADD CONSTRAINT [FK__Suministr__movim__5E8AD4CA] FOREIGN KEY ([movimiento_anulado_id]) REFERENCES [logistica].[SuministroMovimiento] ([suministro_movimiento_id]);
ALTER TABLE [logistica].[SuministroMovimiento] CHECK CONSTRAINT [FK__Suministr__movim__5E8AD4CA];
ALTER TABLE [logistica].[SuministroMovimiento] WITH CHECK ADD CONSTRAINT [FK_DESCO_SuministroMov_Origen] FOREIGN KEY ([movimiento_origen_id]) REFERENCES [logistica].[SuministroMovimiento] ([suministro_movimiento_id]);
ALTER TABLE [logistica].[SuministroMovimiento] CHECK CONSTRAINT [FK_DESCO_SuministroMov_Origen];
ALTER TABLE [logistica].[SuministroMovimiento] WITH CHECK ADD CONSTRAINT [FK_DESCO_SuministroMov_RecursoMov] FOREIGN KEY ([recurso_movimiento_id]) REFERENCES [logistica].[RecursoMovimiento] ([recurso_movimiento_id]);
ALTER TABLE [logistica].[SuministroMovimiento] CHECK CONSTRAINT [FK_DESCO_SuministroMov_RecursoMov];
ALTER TABLE [logistica].[SuministroMovimiento] WITH CHECK ADD CONSTRAINT [FK_SuministroMovimiento_RecursoProgramado] FOREIGN KEY ([recurso_programado_id]) REFERENCES [logistica].[RecursoProgramado] ([recurso_programado_id]);
ALTER TABLE [logistica].[SuministroMovimiento] CHECK CONSTRAINT [FK_SuministroMovimiento_RecursoProgramado];
ALTER TABLE [logistica].[SuministroMovimiento] WITH CHECK ADD CONSTRAINT [FK_SuministroMovimiento_Suministro] FOREIGN KEY ([suministro_id]) REFERENCES [logistica].[Suministro] ([suministro_id]);
ALTER TABLE [logistica].[SuministroMovimiento] CHECK CONSTRAINT [FK_SuministroMovimiento_Suministro];
ALTER TABLE [logistica].[SuministroMovimiento] WITH CHECK ADD CONSTRAINT [FK_SuministroMovimiento_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [logistica].[SuministroMovimiento] CHECK CONSTRAINT [FK_SuministroMovimiento_UOT];
ALTER TABLE [logistica].[SuministroMovimiento] WITH CHECK ADD CONSTRAINT [FK_SuministroMovimiento_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [logistica].[SuministroMovimiento] CHECK CONSTRAINT [FK_SuministroMovimiento_Usuario];
ALTER TABLE [logistica].[SuministroSaldo] WITH CHECK ADD CONSTRAINT [FK_DESCO_Saldo_Suministro] FOREIGN KEY ([suministro_id]) REFERENCES [logistica].[Suministro] ([suministro_id]);
ALTER TABLE [logistica].[SuministroSaldo] CHECK CONSTRAINT [FK_DESCO_Saldo_Suministro];
ALTER TABLE [logistica].[TransferenciaAlmacen] WITH CHECK ADD CONSTRAINT [FK_DESCO_TransferDestino] FOREIGN KEY ([almacen_destino_id]) REFERENCES [logistica].[Almacen] ([almacen_id]);
ALTER TABLE [logistica].[TransferenciaAlmacen] CHECK CONSTRAINT [FK_DESCO_TransferDestino];
ALTER TABLE [logistica].[TransferenciaAlmacen] WITH CHECK ADD CONSTRAINT [FK_DESCO_TransferMovEntrada] FOREIGN KEY ([movimiento_entrada_id]) REFERENCES [logistica].[MovimientoInventario] ([movimiento_inventario_id]);
ALTER TABLE [logistica].[TransferenciaAlmacen] CHECK CONSTRAINT [FK_DESCO_TransferMovEntrada];
ALTER TABLE [logistica].[TransferenciaAlmacen] WITH CHECK ADD CONSTRAINT [FK_DESCO_TransferMovSalida] FOREIGN KEY ([movimiento_salida_id]) REFERENCES [logistica].[MovimientoInventario] ([movimiento_inventario_id]);
ALTER TABLE [logistica].[TransferenciaAlmacen] CHECK CONSTRAINT [FK_DESCO_TransferMovSalida];
ALTER TABLE [logistica].[TransferenciaAlmacen] WITH CHECK ADD CONSTRAINT [FK_DESCO_TransferOrigen] FOREIGN KEY ([almacen_origen_id]) REFERENCES [logistica].[Almacen] ([almacen_id]);
ALTER TABLE [logistica].[TransferenciaAlmacen] CHECK CONSTRAINT [FK_DESCO_TransferOrigen];
ALTER TABLE [logistica].[UsoProductoTecnico] WITH CHECK ADD CONSTRAINT [FK__UsoProduc__event__5F14E4AF] FOREIGN KEY ([evento_id]) REFERENCES [logistica].[ProgramacionProductoEvento] ([programacion_producto_evento_id]);
ALTER TABLE [logistica].[UsoProductoTecnico] CHECK CONSTRAINT [FK__UsoProduc__event__5F14E4AF];
ALTER TABLE [logistica].[UsoProductoTecnico] WITH CHECK ADD CONSTRAINT [FK__UsoProduc__progr__5E20C076] FOREIGN KEY ([programacion_producto_id]) REFERENCES [logistica].[ProgramacionProducto] ([programacion_producto_id]);
ALTER TABLE [logistica].[UsoProductoTecnico] CHECK CONSTRAINT [FK__UsoProduc__progr__5E20C076];
ALTER TABLE [logistica].[Vehiculo] WITH CHECK ADD CONSTRAINT [FK_Vehiculo_BienInventario] FOREIGN KEY ([vehiculo_id]) REFERENCES [logistica].[BienInventario] ([bien_inventario_id]);
ALTER TABLE [logistica].[Vehiculo] CHECK CONSTRAINT [FK_Vehiculo_BienInventario];
ALTER TABLE [org].[Area] WITH CHECK ADD CONSTRAINT [FK_Area_PadreUOT] FOREIGN KEY ([area_padre_id],[uot_id]) REFERENCES [org].[Area] ([area_id],[uot_id]);
ALTER TABLE [org].[Area] CHECK CONSTRAINT [FK_Area_PadreUOT];
ALTER TABLE [org].[Area] WITH CHECK ADD CONSTRAINT [FK_Area_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [org].[Area] CHECK CONSTRAINT [FK_Area_UOT];
ALTER TABLE [org].[Asociacion] WITH CHECK ADD CONSTRAINT [FK_Asociacion_Empresa] FOREIGN KEY ([asociacion_id]) REFERENCES [org].[Empresa] ([empresa_id]);
ALTER TABLE [org].[Asociacion] CHECK CONSTRAINT [FK_Asociacion_Empresa];
ALTER TABLE [org].[Asociacion] WITH CHECK ADD CONSTRAINT [FK_Asociacion_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [org].[Asociacion] CHECK CONSTRAINT [FK_Asociacion_UOT];
ALTER TABLE [org].[ConvenioModuloEspecial] WITH CHECK ADD CONSTRAINT [FK_ConvenioModuloEspecial_Convenio] FOREIGN KEY ([convenio_uot_organizacion_id]) REFERENCES [org].[ConvenioUOTOrganizacion] ([convenio_uot_organizacion_id]);
ALTER TABLE [org].[ConvenioModuloEspecial] CHECK CONSTRAINT [FK_ConvenioModuloEspecial_Convenio];
ALTER TABLE [org].[ConvenioModuloEspecial] WITH CHECK ADD CONSTRAINT [FK_ConvenioModuloEspecial_Modulo] FOREIGN KEY ([modulo_especial_id]) REFERENCES [seg].[ModuloEspecial] ([modulo_especial_id]);
ALTER TABLE [org].[ConvenioModuloEspecial] CHECK CONSTRAINT [FK_ConvenioModuloEspecial_Modulo];
ALTER TABLE [org].[ConvenioModuloEspecial] WITH CHECK ADD CONSTRAINT [FK_ConvenioModuloEspecial_Usuario] FOREIGN KEY ([usuario_modificacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [org].[ConvenioModuloEspecial] CHECK CONSTRAINT [FK_ConvenioModuloEspecial_Usuario];
ALTER TABLE [org].[ConvenioUOTOrganizacion] WITH CHECK ADD CONSTRAINT [FK_ConvenioUOT_Empresa] FOREIGN KEY ([empresa_id]) REFERENCES [org].[Empresa] ([empresa_id]);
ALTER TABLE [org].[ConvenioUOTOrganizacion] CHECK CONSTRAINT [FK_ConvenioUOT_Empresa];
ALTER TABLE [org].[ConvenioUOTOrganizacion] WITH CHECK ADD CONSTRAINT [FK_ConvenioUOT_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [org].[ConvenioUOTOrganizacion] CHECK CONSTRAINT [FK_ConvenioUOT_UOT];
ALTER TABLE [org].[Empleado] WITH CHECK ADD CONSTRAINT [FK_Empleado_Empresa] FOREIGN KEY ([empresa_id]) REFERENCES [org].[Empresa] ([empresa_id]);
ALTER TABLE [org].[Empleado] CHECK CONSTRAINT [FK_Empleado_Empresa];
ALTER TABLE [org].[Empleado] WITH CHECK ADD CONSTRAINT [FK_Empleado_Persona] FOREIGN KEY ([empleado_id]) REFERENCES [org].[Persona] ([persona_id]);
ALTER TABLE [org].[Empleado] CHECK CONSTRAINT [FK_Empleado_Persona];
ALTER TABLE [org].[EmpleadoArea] WITH CHECK ADD CONSTRAINT [FK_EmpleadoArea_Area] FOREIGN KEY ([area_id]) REFERENCES [org].[Area] ([area_id]);
ALTER TABLE [org].[EmpleadoArea] CHECK CONSTRAINT [FK_EmpleadoArea_Area];
ALTER TABLE [org].[EmpleadoArea] WITH CHECK ADD CONSTRAINT [FK_EmpleadoArea_Empleado] FOREIGN KEY ([empleado_id]) REFERENCES [org].[Empleado] ([empleado_id]);
ALTER TABLE [org].[EmpleadoArea] CHECK CONSTRAINT [FK_EmpleadoArea_Empleado];
ALTER TABLE [org].[EmpleadoUOT] WITH CHECK ADD CONSTRAINT [FK_EmpleadoUOT_Empleado] FOREIGN KEY ([empleado_id]) REFERENCES [org].[Empleado] ([empleado_id]);
ALTER TABLE [org].[EmpleadoUOT] CHECK CONSTRAINT [FK_EmpleadoUOT_Empleado];
ALTER TABLE [org].[EmpleadoUOT] WITH CHECK ADD CONSTRAINT [FK_EmpleadoUOT_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [org].[EmpleadoUOT] CHECK CONSTRAINT [FK_EmpleadoUOT_UOT];
ALTER TABLE [org].[Empresa] WITH CHECK ADD CONSTRAINT [FK_Empresa_Ubicacion] FOREIGN KEY ([ubicacion_id]) REFERENCES [geo].[Ubicacion] ([ubicacion_id]);
ALTER TABLE [org].[Empresa] CHECK CONSTRAINT [FK_Empresa_Ubicacion];
ALTER TABLE [org].[Persona] WITH CHECK ADD CONSTRAINT [FK_Persona_Ubicacion] FOREIGN KEY ([ubicacion_id]) REFERENCES [geo].[Ubicacion] ([ubicacion_id]);
ALTER TABLE [org].[Persona] CHECK CONSTRAINT [FK_Persona_Ubicacion];
ALTER TABLE [org].[Productor] WITH CHECK ADD CONSTRAINT [FK_E1_ProductorPersona] FOREIGN KEY ([persona_id]) REFERENCES [org].[Persona] ([persona_id]);
ALTER TABLE [org].[Productor] CHECK CONSTRAINT [FK_E1_ProductorPersona];
ALTER TABLE [org].[Productor] WITH CHECK ADD CONSTRAINT [FK_E1_ProductorUsuario] FOREIGN KEY ([usuario_creacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [org].[Productor] CHECK CONSTRAINT [FK_E1_ProductorUsuario];
ALTER TABLE [org].[ProductorUOT] WITH CHECK ADD CONSTRAINT [FK_E1_ProductorUOTProductor] FOREIGN KEY ([persona_id]) REFERENCES [org].[Productor] ([persona_id]);
ALTER TABLE [org].[ProductorUOT] CHECK CONSTRAINT [FK_E1_ProductorUOTProductor];
ALTER TABLE [org].[ProductorUOT] WITH CHECK ADD CONSTRAINT [FK_E1_ProductorUOTUOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [org].[ProductorUOT] CHECK CONSTRAINT [FK_E1_ProductorUOTUOT];
ALTER TABLE [org].[ProductorUOT] WITH CHECK ADD CONSTRAINT [FK_E1_ProductorUOTUsuario] FOREIGN KEY ([usuario_creacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [org].[ProductorUOT] CHECK CONSTRAINT [FK_E1_ProductorUOTUsuario];
ALTER TABLE [org].[Socio] WITH CHECK ADD CONSTRAINT [FK_Socio_Persona] FOREIGN KEY ([socio_id]) REFERENCES [org].[Persona] ([persona_id]);
ALTER TABLE [org].[Socio] CHECK CONSTRAINT [FK_Socio_Persona];
ALTER TABLE [org].[SocioAsociacion] WITH CHECK ADD CONSTRAINT [FK_SocioAsociacion_Asociacion] FOREIGN KEY ([asociacion_id]) REFERENCES [org].[Asociacion] ([asociacion_id]);
ALTER TABLE [org].[SocioAsociacion] CHECK CONSTRAINT [FK_SocioAsociacion_Asociacion];
ALTER TABLE [org].[SocioAsociacion] WITH CHECK ADD CONSTRAINT [FK_SocioAsociacion_Socio] FOREIGN KEY ([socio_id]) REFERENCES [org].[Socio] ([socio_id]);
ALTER TABLE [org].[SocioAsociacion] CHECK CONSTRAINT [FK_SocioAsociacion_Socio];
ALTER TABLE [org].[UOT] WITH CHECK ADD CONSTRAINT [FK_UOT_EmpresaLegacy] FOREIGN KEY ([empresa_legacy_id]) REFERENCES [org].[Empresa] ([empresa_id]);
ALTER TABLE [org].[UOT] CHECK CONSTRAINT [FK_UOT_EmpresaLegacy];
ALTER TABLE [org].[UOT] WITH CHECK ADD CONSTRAINT [FK_UOT_Padre] FOREIGN KEY ([uot_padre_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [org].[UOT] CHECK CONSTRAINT [FK_UOT_Padre];
ALTER TABLE [org].[UOT] WITH CHECK ADD CONSTRAINT [FK_UOT_Ubicacion] FOREIGN KEY ([ubicacion_id]) REFERENCES [geo].[Ubicacion] ([ubicacion_id]);
ALTER TABLE [org].[UOT] CHECK CONSTRAINT [FK_UOT_Ubicacion];
ALTER TABLE [prod].[CensoPlantas] WITH CHECK ADD CONSTRAINT [FK_CensoPlantas_Cultivo] FOREIGN KEY ([parcela_cultivo_id]) REFERENCES [prod].[ParcelaCultivo] ([parcela_cultivo_id]);
ALTER TABLE [prod].[CensoPlantas] CHECK CONSTRAINT [FK_CensoPlantas_Cultivo];
ALTER TABLE [prod].[CrianzaConteo] WITH CHECK ADD CONSTRAINT [FK__CrianzaCo__crian__4B8D0EEF] FOREIGN KEY ([crianza_lote_id]) REFERENCES [prod].[CrianzaLote] ([crianza_lote_id]);
ALTER TABLE [prod].[CrianzaConteo] CHECK CONSTRAINT [FK__CrianzaCo__crian__4B8D0EEF];
ALTER TABLE [prod].[CrianzaConteo] WITH CHECK ADD CONSTRAINT [FK__CrianzaCo__usuar__4C813328] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[CrianzaConteo] CHECK CONSTRAINT [FK__CrianzaCo__usuar__4C813328];
ALTER TABLE [prod].[CrianzaLote] WITH CHECK ADD CONSTRAINT [FK__CrianzaLo__espec__45D43599] FOREIGN KEY ([especie_pecuaria_id]) REFERENCES [prod].[EspeciePecuaria] ([especie_pecuaria_id]);
ALTER TABLE [prod].[CrianzaLote] CHECK CONSTRAINT [FK__CrianzaLo__espec__45D43599];
ALTER TABLE [prod].[CrianzaLote] WITH CHECK ADD CONSTRAINT [FK__CrianzaLo__predi__44E01160] FOREIGN KEY ([predio_id]) REFERENCES [prod].[Predio] ([predio_id]);
ALTER TABLE [prod].[CrianzaLote] CHECK CONSTRAINT [FK__CrianzaLo__predi__44E01160];
ALTER TABLE [prod].[DisponibilidadProduccion] WITH CHECK ADD CONSTRAINT [FK_DisponibilidadProduccion_Cultivo] FOREIGN KEY ([parcela_cultivo_id]) REFERENCES [prod].[ParcelaCultivo] ([parcela_cultivo_id]);
ALTER TABLE [prod].[DisponibilidadProduccion] CHECK CONSTRAINT [FK_DisponibilidadProduccion_Cultivo];
ALTER TABLE [prod].[DisponibilidadProduccion] WITH CHECK ADD CONSTRAINT [FK_DisponibilidadProduccion_Visita] FOREIGN KEY ([visita_tecnica_id]) REFERENCES [campo].[VisitaTecnica] ([visita_tecnica_id]);
ALTER TABLE [prod].[DisponibilidadProduccion] CHECK CONSTRAINT [FK_DisponibilidadProduccion_Visita];
ALTER TABLE [prod].[ExpedienteActuacion] WITH CHECK ADD CONSTRAINT [FK__Expedient__conve__532E30B7] FOREIGN KEY ([convenio_uot_organizacion_id]) REFERENCES [org].[ConvenioUOTOrganizacion] ([convenio_uot_organizacion_id]);
ALTER TABLE [prod].[ExpedienteActuacion] CHECK CONSTRAINT [FK__Expedient__conve__532E30B7];
ALTER TABLE [prod].[ExpedienteActuacion] WITH CHECK ADD CONSTRAINT [FK__Expedient__crian__55167929] FOREIGN KEY ([crianza_lote_id]) REFERENCES [prod].[CrianzaLote] ([crianza_lote_id]);
ALTER TABLE [prod].[ExpedienteActuacion] CHECK CONSTRAINT [FK__Expedient__crian__55167929];
ALTER TABLE [prod].[ExpedienteActuacion] WITH CHECK ADD CONSTRAINT [FK__Expedient__parce__542254F0] FOREIGN KEY ([parcela_cultivo_id]) REFERENCES [prod].[ParcelaCultivo] ([parcela_cultivo_id]);
ALTER TABLE [prod].[ExpedienteActuacion] CHECK CONSTRAINT [FK__Expedient__parce__542254F0];
ALTER TABLE [prod].[ExpedienteActuacion] WITH CHECK ADD CONSTRAINT [FK__Expedient__predi__5145E845] FOREIGN KEY ([predio_id]) REFERENCES [prod].[Predio] ([predio_id]);
ALTER TABLE [prod].[ExpedienteActuacion] CHECK CONSTRAINT [FK__Expedient__predi__5145E845];
ALTER TABLE [prod].[ExpedienteActuacion] WITH CHECK ADD CONSTRAINT [FK__Expedient__uot_i__523A0C7E] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [prod].[ExpedienteActuacion] CHECK CONSTRAINT [FK__Expedient__uot_i__523A0C7E];
ALTER TABLE [prod].[ExpedienteActuacion] WITH CHECK ADD CONSTRAINT [FK__Expedient__usuar__56FEC19B] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[ExpedienteActuacion] CHECK CONSTRAINT [FK__Expedient__usuar__56FEC19B];
ALTER TABLE [prod].[FundoAccionHistorial] WITH CHECK ADD CONSTRAINT [FK__FundoAcci__conve__57C8C8A2] FOREIGN KEY ([convenio_id]) REFERENCES [org].[ConvenioUOTOrganizacion] ([convenio_uot_organizacion_id]);
ALTER TABLE [prod].[FundoAccionHistorial] CHECK CONSTRAINT [FK__FundoAcci__conve__57C8C8A2];
ALTER TABLE [prod].[FundoAccionHistorial] WITH CHECK ADD CONSTRAINT [FK__FundoAcci__predi__56D4A469] FOREIGN KEY ([predio_id]) REFERENCES [prod].[Predio] ([predio_id]);
ALTER TABLE [prod].[FundoAccionHistorial] CHECK CONSTRAINT [FK__FundoAcci__predi__56D4A469];
ALTER TABLE [prod].[FundoAccionHistorial] WITH CHECK ADD CONSTRAINT [FK__FundoAcci__usuar__58BCECDB] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[FundoAccionHistorial] CHECK CONSTRAINT [FK__FundoAcci__usuar__58BCECDB];
ALTER TABLE [prod].[FundoAccionSolicitud] WITH CHECK ADD CONSTRAINT [FK__FundoAcci__usuar__53041385] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[FundoAccionSolicitud] CHECK CONSTRAINT [FK__FundoAcci__usuar__53041385];
ALTER TABLE [prod].[FundoHabilitacion] WITH CHECK ADD CONSTRAINT [FK__FundoHabi__conve__4B62F1BD] FOREIGN KEY ([convenio_id]) REFERENCES [org].[ConvenioUOTOrganizacion] ([convenio_uot_organizacion_id]);
ALTER TABLE [prod].[FundoHabilitacion] CHECK CONSTRAINT [FK__FundoHabi__conve__4B62F1BD];
ALTER TABLE [prod].[FundoHabilitacion] WITH CHECK ADD CONSTRAINT [FK__FundoHabi__predi__4A6ECD84] FOREIGN KEY ([predio_id]) REFERENCES [prod].[Predio] ([predio_id]);
ALTER TABLE [prod].[FundoHabilitacion] CHECK CONSTRAINT [FK__FundoHabi__predi__4A6ECD84];
ALTER TABLE [prod].[FundoHabilitacion] WITH CHECK ADD CONSTRAINT [FK__FundoHabi__uot_i__4C5715F6] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [prod].[FundoHabilitacion] CHECK CONSTRAINT [FK__FundoHabi__uot_i__4C5715F6];
ALTER TABLE [prod].[FundoHabilitacion] WITH CHECK ADD CONSTRAINT [FK__FundoHabi__usuar__4F3382A1] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[FundoHabilitacion] CHECK CONSTRAINT [FK__FundoHabi__usuar__4F3382A1];
ALTER TABLE [prod].[FundoProduccionE3] WITH CHECK ADD CONSTRAINT [FK__FundoProd__conve__2EC6B30F] FOREIGN KEY ([convenio_id]) REFERENCES [org].[ConvenioUOTOrganizacion] ([convenio_uot_organizacion_id]);
ALTER TABLE [prod].[FundoProduccionE3] CHECK CONSTRAINT [FK__FundoProd__conve__2EC6B30F];
ALTER TABLE [prod].[FundoProduccionE3] WITH CHECK ADD CONSTRAINT [FK__FundoProd__predi__2CDE6A9D] FOREIGN KEY ([predio_id]) REFERENCES [prod].[Predio] ([predio_id]);
ALTER TABLE [prod].[FundoProduccionE3] CHECK CONSTRAINT [FK__FundoProd__predi__2CDE6A9D];
ALTER TABLE [prod].[FundoProduccionE3] WITH CHECK ADD CONSTRAINT [FK__FundoProd__uot_i__2DD28ED6] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [prod].[FundoProduccionE3] CHECK CONSTRAINT [FK__FundoProd__uot_i__2DD28ED6];
ALTER TABLE [prod].[FundoProduccionE3] WITH CHECK ADD CONSTRAINT [FK__FundoProd__usuar__2FBAD748] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[FundoProduccionE3] CHECK CONSTRAINT [FK__FundoProd__usuar__2FBAD748];
ALTER TABLE [prod].[FundoProduccionHistorialE3] WITH CHECK ADD CONSTRAINT [FK__FundoProd__fundo__3573B09E] FOREIGN KEY ([fundo_produccion_id]) REFERENCES [prod].[FundoProduccionE3] ([fundo_produccion_id]);
ALTER TABLE [prod].[FundoProduccionHistorialE3] CHECK CONSTRAINT [FK__FundoProd__fundo__3573B09E];
ALTER TABLE [prod].[FundoProduccionHistorialE3] WITH CHECK ADD CONSTRAINT [FK__FundoProd__usuar__3667D4D7] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[FundoProduccionHistorialE3] CHECK CONSTRAINT [FK__FundoProd__usuar__3667D4D7];
ALTER TABLE [prod].[FundoProduccionSolicitudE3] WITH CHECK ADD CONSTRAINT [FK__FundoProd__usuar__3B2C89F4] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[FundoProduccionSolicitudE3] CHECK CONSTRAINT [FK__FundoProd__usuar__3B2C89F4];
ALTER TABLE [prod].[GPActividad] WITH CHECK ADD CONSTRAINT [FK__GPActivid__culti__7C854C05] FOREIGN KEY ([cultivo_id]) REFERENCES [prod].[Cultivo] ([cultivo_id]);
ALTER TABLE [prod].[GPActividad] CHECK CONSTRAINT [FK__GPActivid__culti__7C854C05];
ALTER TABLE [prod].[GPActividad] WITH CHECK ADD CONSTRAINT [FK__GPActivid__espec__7D79703E] FOREIGN KEY ([especie_pecuaria_id]) REFERENCES [prod].[EspeciePecuaria] ([especie_pecuaria_id]);
ALTER TABLE [prod].[GPActividad] CHECK CONSTRAINT [FK__GPActivid__espec__7D79703E];
ALTER TABLE [prod].[GPActividad] WITH CHECK ADD CONSTRAINT [FK__GPActivid__parce__78B4BB21] FOREIGN KEY ([parcela_id]) REFERENCES [prod].[Parcela] ([parcela_id]);
ALTER TABLE [prod].[GPActividad] CHECK CONSTRAINT [FK__GPActivid__parce__78B4BB21];
ALTER TABLE [prod].[GPActividad] WITH CHECK ADD CONSTRAINT [FK__GPActivid__predi__79A8DF5A] FOREIGN KEY ([predio_id]) REFERENCES [prod].[Predio] ([predio_id]);
ALTER TABLE [prod].[GPActividad] CHECK CONSTRAINT [FK__GPActivid__predi__79A8DF5A];
ALTER TABLE [prod].[GPActividad] WITH CHECK ADD CONSTRAINT [FK__GPActivid__uot_i__7A9D0393] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [prod].[GPActividad] CHECK CONSTRAINT [FK__GPActivid__uot_i__7A9D0393];
ALTER TABLE [prod].[GPActividad] WITH CHECK ADD CONSTRAINT [FK__GPActivid__usuar__0055DCE9] FOREIGN KEY ([usuario_creacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[GPActividad] CHECK CONSTRAINT [FK__GPActivid__usuar__0055DCE9];
ALTER TABLE [prod].[GPActividad] WITH CHECK ADD CONSTRAINT [FK_GPActividad_VariedadCultivo] FOREIGN KEY ([variedad_cultivo_id]) REFERENCES [prod].[VariedadCultivo] ([variedad_cultivo_id]);
ALTER TABLE [prod].[GPActividad] CHECK CONSTRAINT [FK_GPActividad_VariedadCultivo];
ALTER TABLE [prod].[GPActividadRevision] WITH CHECK ADD CONSTRAINT [FK__GPActivid__activ__4E89772B] FOREIGN KEY ([actividad_id]) REFERENCES [prod].[GPActividad] ([actividad_id]);
ALTER TABLE [prod].[GPActividadRevision] CHECK CONSTRAINT [FK__GPActivid__activ__4E89772B];
ALTER TABLE [prod].[GPActividadRevision] WITH CHECK ADD CONSTRAINT [FK__GPActivid__usuar__4F7D9B64] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[GPActividadRevision] CHECK CONSTRAINT [FK__GPActivid__usuar__4F7D9B64];
ALTER TABLE [prod].[GPBajaLogica] WITH CHECK ADD CONSTRAINT [FK__GPBajaLog__usuar__0C86A9A4] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[GPBajaLogica] CHECK CONSTRAINT [FK__GPBajaLog__usuar__0C86A9A4];
ALTER TABLE [prod].[GPCenso] WITH CHECK ADD CONSTRAINT [FK__GPCenso__activid__060EB63F] FOREIGN KEY ([actividad_id]) REFERENCES [prod].[GPActividad] ([actividad_id]);
ALTER TABLE [prod].[GPCenso] CHECK CONSTRAINT [FK__GPCenso__activid__060EB63F];
ALTER TABLE [prod].[GPCenso] WITH CHECK ADD CONSTRAINT [FK__GPCenso__usuario__07F6FEB1] FOREIGN KEY ([usuario_creacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[GPCenso] CHECK CONSTRAINT [FK__GPCenso__usuario__07F6FEB1];
ALTER TABLE [prod].[GPCensoRaza] WITH CHECK ADD CONSTRAINT [FK__GPCensoRa__censo__5BE37249] FOREIGN KEY ([censo_id]) REFERENCES [prod].[GPCenso] ([censo_id]);
ALTER TABLE [prod].[GPCensoRaza] CHECK CONSTRAINT [FK__GPCensoRa__censo__5BE37249];
ALTER TABLE [prod].[GPCensoRaza] WITH CHECK ADD CONSTRAINT [FK__GPCensoRa__raza___5CD79682] FOREIGN KEY ([raza_id]) REFERENCES [prod].[GPRaza] ([raza_id]);
ALTER TABLE [prod].[GPCensoRaza] CHECK CONSTRAINT [FK__GPCensoRa__raza___5CD79682];
ALTER TABLE [prod].[GPCensoVariedad] WITH CHECK ADD CONSTRAINT [FK__GPCensoVa__censo__6A3191A0] FOREIGN KEY ([censo_id]) REFERENCES [prod].[GPCenso] ([censo_id]);
ALTER TABLE [prod].[GPCensoVariedad] CHECK CONSTRAINT [FK__GPCensoVa__censo__6A3191A0];
ALTER TABLE [prod].[GPCensoVariedad] WITH CHECK ADD CONSTRAINT [FK__GPCensoVa__varie__6B25B5D9] FOREIGN KEY ([variedad_cultivo_id]) REFERENCES [prod].[VariedadCultivo] ([variedad_cultivo_id]);
ALTER TABLE [prod].[GPCensoVariedad] CHECK CONSTRAINT [FK__GPCensoVa__varie__6B25B5D9];
ALTER TABLE [prod].[GPEvento] WITH CHECK ADD CONSTRAINT [FK__GPEvento__activi__1A15AEEC] FOREIGN KEY ([actividad_id]) REFERENCES [prod].[GPActividad] ([actividad_id]);
ALTER TABLE [prod].[GPEvento] CHECK CONSTRAINT [FK__GPEvento__activi__1A15AEEC];
ALTER TABLE [prod].[GPEvento] WITH CHECK ADD CONSTRAINT [FK__GPEvento__proble__1BFDF75E] FOREIGN KEY ([problema_id]) REFERENCES [prod].[GPProblema] ([problema_id]);
ALTER TABLE [prod].[GPEvento] CHECK CONSTRAINT [FK__GPEvento__proble__1BFDF75E];
ALTER TABLE [prod].[GPEvento] WITH CHECK ADD CONSTRAINT [FK__GPEvento__respue__1DE63FD0] FOREIGN KEY ([respuesta_a_id]) REFERENCES [prod].[GPEvento] ([evento_id]);
ALTER TABLE [prod].[GPEvento] CHECK CONSTRAINT [FK__GPEvento__respue__1DE63FD0];
ALTER TABLE [prod].[GPEvento] WITH CHECK ADD CONSTRAINT [FK__GPEvento__tratam__1CF21B97] FOREIGN KEY ([tratamiento_id]) REFERENCES [prod].[GPTratamiento] ([tratamiento_id]);
ALTER TABLE [prod].[GPEvento] CHECK CONSTRAINT [FK__GPEvento__tratam__1CF21B97];
ALTER TABLE [prod].[GPEvento] WITH CHECK ADD CONSTRAINT [FK__GPEvento__usuari__1FCE8842] FOREIGN KEY ([usuario_creacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[GPEvento] CHECK CONSTRAINT [FK__GPEvento__usuari__1FCE8842];
ALTER TABLE [prod].[GPEventoFoto] WITH CHECK ADD CONSTRAINT [FK__GPEventoF__usuar__34C9A528] FOREIGN KEY ([usuario_creacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[GPEventoFoto] CHECK CONSTRAINT [FK__GPEventoF__usuar__34C9A528];
ALTER TABLE [prod].[GPEventoFoto] WITH CHECK ADD CONSTRAINT [FK_GPEventoFoto_Evento] FOREIGN KEY ([evento_id]) REFERENCES [prod].[GPEvento] ([evento_id]);
ALTER TABLE [prod].[GPEventoFoto] CHECK CONSTRAINT [FK_GPEventoFoto_Evento];
ALTER TABLE [prod].[GPIncidencia] WITH CHECK ADD CONSTRAINT [FK__GPInciden__probl__787FB0F7] FOREIGN KEY ([problema_id]) REFERENCES [prod].[GPProblema] ([problema_id]);
ALTER TABLE [prod].[GPIncidencia] CHECK CONSTRAINT [FK__GPInciden__probl__787FB0F7];
ALTER TABLE [prod].[GPIncidencia] WITH CHECK ADD CONSTRAINT [FK__GPInciden__usuar__7B5C1DA2] FOREIGN KEY ([usuario_cierre_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[GPIncidencia] CHECK CONSTRAINT [FK__GPInciden__usuar__7B5C1DA2];
ALTER TABLE [prod].[GPIncidencia] WITH CHECK ADD CONSTRAINT [FK_GPIncidencia_Actividad] FOREIGN KEY ([actividad_id]) REFERENCES [prod].[GPActividad] ([actividad_id]);
ALTER TABLE [prod].[GPIncidencia] CHECK CONSTRAINT [FK_GPIncidencia_Actividad];
ALTER TABLE [prod].[GPIncidencia] WITH CHECK ADD CONSTRAINT [FK_GPIncidencia_Evento] FOREIGN KEY ([incidencia_id]) REFERENCES [prod].[GPEvento] ([evento_id]);
ALTER TABLE [prod].[GPIncidencia] CHECK CONSTRAINT [FK_GPIncidencia_Evento];
ALTER TABLE [prod].[GPIncidenciaRevision] WITH CHECK ADD CONSTRAINT [FK__GPInciden__incid__75392FF8] FOREIGN KEY ([incidencia_id]) REFERENCES [prod].[GPIncidencia] ([incidencia_id]);
ALTER TABLE [prod].[GPIncidenciaRevision] CHECK CONSTRAINT [FK__GPInciden__incid__75392FF8];
ALTER TABLE [prod].[GPIncidenciaRevision] WITH CHECK ADD CONSTRAINT [FK__GPInciden__usuar__7721786A] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[GPIncidenciaRevision] CHECK CONSTRAINT [FK__GPInciden__usuar__7721786A];
ALTER TABLE [prod].[GPIncidenciaTratamiento] WITH CHECK ADD CONSTRAINT [FK__GPInciden__event__02091B31] FOREIGN KEY ([evento_id]) REFERENCES [prod].[GPEvento] ([evento_id]);
ALTER TABLE [prod].[GPIncidenciaTratamiento] CHECK CONSTRAINT [FK__GPInciden__event__02091B31];
ALTER TABLE [prod].[GPIncidenciaTratamiento] WITH CHECK ADD CONSTRAINT [FK__GPInciden__incid__02FD3F6A] FOREIGN KEY ([incidencia_id]) REFERENCES [prod].[GPIncidencia] ([incidencia_id]);
ALTER TABLE [prod].[GPIncidenciaTratamiento] CHECK CONSTRAINT [FK__GPInciden__incid__02FD3F6A];
ALTER TABLE [prod].[GPIncidenciaTratamiento] WITH CHECK ADD CONSTRAINT [FK__GPInciden__trata__04E587DC] FOREIGN KEY ([tratamiento_id]) REFERENCES [prod].[GPTratamiento] ([tratamiento_id]);
ALTER TABLE [prod].[GPIncidenciaTratamiento] CHECK CONSTRAINT [FK__GPInciden__trata__04E587DC];
ALTER TABLE [prod].[GPIncidenciaTratamiento] WITH CHECK ADD CONSTRAINT [FK__GPInciden__usuar__06CDD04E] FOREIGN KEY ([usuario_cierre_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[GPIncidenciaTratamiento] CHECK CONSTRAINT [FK__GPInciden__usuar__06CDD04E];
ALTER TABLE [prod].[GPParcelaSolicitud] WITH CHECK ADD CONSTRAINT [FK__GPParcela__parce__412F7C0D] FOREIGN KEY ([parcela_id]) REFERENCES [prod].[Parcela] ([parcela_id]);
ALTER TABLE [prod].[GPParcelaSolicitud] CHECK CONSTRAINT [FK__GPParcela__parce__412F7C0D];
ALTER TABLE [prod].[GPParcelaSolicitud] WITH CHECK ADD CONSTRAINT [FK__GPParcela__usuar__4223A046] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[GPParcelaSolicitud] CHECK CONSTRAINT [FK__GPParcela__usuar__4223A046];
ALTER TABLE [prod].[GPProblema] WITH CHECK ADD CONSTRAINT [FK__GPProblem__culti__0CBBB3CE] FOREIGN KEY ([cultivo_id]) REFERENCES [prod].[Cultivo] ([cultivo_id]);
ALTER TABLE [prod].[GPProblema] CHECK CONSTRAINT [FK__GPProblem__culti__0CBBB3CE];
ALTER TABLE [prod].[GPProblema] WITH CHECK ADD CONSTRAINT [FK__GPProblem__espec__0DAFD807] FOREIGN KEY ([especie_pecuaria_id]) REFERENCES [prod].[EspeciePecuaria] ([especie_pecuaria_id]);
ALTER TABLE [prod].[GPProblema] CHECK CONSTRAINT [FK__GPProblem__espec__0DAFD807];
ALTER TABLE [prod].[GPProblemaTratamiento] WITH CHECK ADD CONSTRAINT [FK__GPProblem__probl__1550F9CF] FOREIGN KEY ([problema_id]) REFERENCES [prod].[GPProblema] ([problema_id]);
ALTER TABLE [prod].[GPProblemaTratamiento] CHECK CONSTRAINT [FK__GPProblem__probl__1550F9CF];
ALTER TABLE [prod].[GPProblemaTratamiento] WITH CHECK ADD CONSTRAINT [FK__GPProblem__trata__16451E08] FOREIGN KEY ([tratamiento_id]) REFERENCES [prod].[GPTratamiento] ([tratamiento_id]);
ALTER TABLE [prod].[GPProblemaTratamiento] CHECK CONSTRAINT [FK__GPProblem__trata__16451E08];
ALTER TABLE [prod].[GPRaza] WITH CHECK ADD CONSTRAINT [FK__GPRaza__especie___562A98F3] FOREIGN KEY ([especie_pecuaria_id]) REFERENCES [prod].[EspeciePecuaria] ([especie_pecuaria_id]);
ALTER TABLE [prod].[GPRaza] CHECK CONSTRAINT [FK__GPRaza__especie___562A98F3];
ALTER TABLE [prod].[GPRaza] WITH CHECK ADD CONSTRAINT [FK__GPRaza__usuario___5812E165] FOREIGN KEY ([usuario_creacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[GPRaza] CHECK CONSTRAINT [FK__GPRaza__usuario___5812E165];
ALTER TABLE [prod].[Parcela] WITH CHECK ADD CONSTRAINT [FK_Parcela_Predio] FOREIGN KEY ([predio_id]) REFERENCES [prod].[Predio] ([predio_id]);
ALTER TABLE [prod].[Parcela] CHECK CONSTRAINT [FK_Parcela_Predio];
ALTER TABLE [prod].[Parcela] WITH CHECK ADD CONSTRAINT [FK_Parcela_Ubicacion] FOREIGN KEY ([ubicacion_id]) REFERENCES [geo].[Ubicacion] ([ubicacion_id]);
ALTER TABLE [prod].[Parcela] CHECK CONSTRAINT [FK_Parcela_Ubicacion];
ALTER TABLE [prod].[ParcelaCultivo] WITH CHECK ADD CONSTRAINT [FK_E1_ParcelaCultivo_Cultivo] FOREIGN KEY ([cultivo_id]) REFERENCES [prod].[Cultivo] ([cultivo_id]);
ALTER TABLE [prod].[ParcelaCultivo] CHECK CONSTRAINT [FK_E1_ParcelaCultivo_Cultivo];
ALTER TABLE [prod].[ParcelaCultivo] WITH CHECK ADD CONSTRAINT [FK_ParcelaCultivo_Parcela] FOREIGN KEY ([parcela_id]) REFERENCES [prod].[Parcela] ([parcela_id]);
ALTER TABLE [prod].[ParcelaCultivo] CHECK CONSTRAINT [FK_ParcelaCultivo_Parcela];
ALTER TABLE [prod].[ParcelaCultivo] WITH CHECK ADD CONSTRAINT [FK_ParcelaCultivo_Variedad] FOREIGN KEY ([variedad_palta_id]) REFERENCES [prod].[VariedadPalta] ([variedad_palta_id]);
ALTER TABLE [prod].[ParcelaCultivo] CHECK CONSTRAINT [FK_ParcelaCultivo_Variedad];
ALTER TABLE [prod].[ParcelaCultivo] WITH CHECK ADD CONSTRAINT [FK_ParcelaCultivo_VariedadCultivo] FOREIGN KEY ([variedad_cultivo_id]) REFERENCES [prod].[VariedadCultivo] ([variedad_cultivo_id]);
ALTER TABLE [prod].[ParcelaCultivo] CHECK CONSTRAINT [FK_ParcelaCultivo_VariedadCultivo];
ALTER TABLE [prod].[PlantaComentarioE3] WITH CHECK ADD CONSTRAINT [FK__PlantaCom__plant__5B0F49A1] FOREIGN KEY ([planta_id]) REFERENCES [prod].[PlantaPaltaE3] ([planta_id]);
ALTER TABLE [prod].[PlantaComentarioE3] CHECK CONSTRAINT [FK__PlantaCom__plant__5B0F49A1];
ALTER TABLE [prod].[PlantaComentarioE3] WITH CHECK ADD CONSTRAINT [FK__PlantaCom__usuar__5C036DDA] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[PlantaComentarioE3] CHECK CONSTRAINT [FK__PlantaCom__usuar__5C036DDA];
ALTER TABLE [prod].[PlantaCorrelativoE3] WITH CHECK ADD CONSTRAINT [FK__PlantaCor__predi__206DA6C0] FOREIGN KEY ([predio_id]) REFERENCES [prod].[Predio] ([predio_id]);
ALTER TABLE [prod].[PlantaCorrelativoE3] CHECK CONSTRAINT [FK__PlantaCor__predi__206DA6C0];
ALTER TABLE [prod].[PlantaCorrelativoE3] WITH CHECK ADD CONSTRAINT [FK__PlantaCor__varie__2161CAF9] FOREIGN KEY ([variedad_palta_id]) REFERENCES [prod].[VariedadPalta] ([variedad_palta_id]);
ALTER TABLE [prod].[PlantaCorrelativoE3] CHECK CONSTRAINT [FK__PlantaCor__varie__2161CAF9];
ALTER TABLE [prod].[PlantaEventoE3] WITH CHECK ADD CONSTRAINT [FK__PlantaEve__plant__243E37A4] FOREIGN KEY ([planta_id]) REFERENCES [prod].[PlantaPaltaE3] ([planta_id]);
ALTER TABLE [prod].[PlantaEventoE3] CHECK CONSTRAINT [FK__PlantaEve__plant__243E37A4];
ALTER TABLE [prod].[PlantaEventoE3] WITH CHECK ADD CONSTRAINT [FK__PlantaEve__usuar__26268016] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[PlantaEventoE3] CHECK CONSTRAINT [FK__PlantaEve__usuar__26268016];
ALTER TABLE [prod].[PlantaEventoE3] WITH CHECK ADD CONSTRAINT [FK__PlantaEve__visit__25325BDD] FOREIGN KEY ([visita_tecnica_id]) REFERENCES [campo].[VisitaTecnica] ([visita_tecnica_id]);
ALTER TABLE [prod].[PlantaEventoE3] CHECK CONSTRAINT [FK__PlantaEve__visit__25325BDD];
ALTER TABLE [prod].[PlantaEvidenciaE3] WITH CHECK ADD CONSTRAINT [FK__PlantaEvi__archi__3FE65219] FOREIGN KEY ([archivo_id]) REFERENCES [archivo].[Archivo] ([archivo_id]);
ALTER TABLE [prod].[PlantaEvidenciaE3] CHECK CONSTRAINT [FK__PlantaEvi__archi__3FE65219];
ALTER TABLE [prod].[PlantaEvidenciaE3] WITH CHECK ADD CONSTRAINT [FK__PlantaEvi__event__40DA7652] FOREIGN KEY ([evento_id]) REFERENCES [prod].[PlantaEventoE3] ([evento_id]);
ALTER TABLE [prod].[PlantaEvidenciaE3] CHECK CONSTRAINT [FK__PlantaEvi__event__40DA7652];
ALTER TABLE [prod].[PlantaEvidenciaE3] WITH CHECK ADD CONSTRAINT [FK__PlantaEvi__plant__3EF22DE0] FOREIGN KEY ([planta_id]) REFERENCES [prod].[PlantaPaltaE3] ([planta_id]);
ALTER TABLE [prod].[PlantaEvidenciaE3] CHECK CONSTRAINT [FK__PlantaEvi__plant__3EF22DE0];
ALTER TABLE [prod].[PlantaEvidenciaE3] WITH CHECK ADD CONSTRAINT [FK__PlantaEvi__usuar__41CE9A8B] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[PlantaEvidenciaE3] CHECK CONSTRAINT [FK__PlantaEvi__usuar__41CE9A8B];
ALTER TABLE [prod].[PlantaFichaHistorialE3] WITH CHECK ADD CONSTRAINT [FK__PlantaFic__plant__20F7B6A5] FOREIGN KEY ([planta_id]) REFERENCES [prod].[PlantaPaltaE3] ([planta_id]);
ALTER TABLE [prod].[PlantaFichaHistorialE3] CHECK CONSTRAINT [FK__PlantaFic__plant__20F7B6A5];
ALTER TABLE [prod].[PlantaFichaHistorialE3] WITH CHECK ADD CONSTRAINT [FK__PlantaFic__usuar__21EBDADE] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[PlantaFichaHistorialE3] CHECK CONSTRAINT [FK__PlantaFic__usuar__21EBDADE];
ALTER TABLE [prod].[PlantaMateriaSecaIndividualE4] WITH CHECK ADD CONSTRAINT [FK__PlantaMat__plant__4C8C2020] FOREIGN KEY ([planta_id]) REFERENCES [prod].[PlantaPaltaE3] ([planta_id]);
ALTER TABLE [prod].[PlantaMateriaSecaIndividualE4] CHECK CONSTRAINT [FK__PlantaMat__plant__4C8C2020];
ALTER TABLE [prod].[PlantaMateriaSecaIndividualE4] WITH CHECK ADD CONSTRAINT [FK__PlantaMat__usuar__4D804459] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[PlantaMateriaSecaIndividualE4] CHECK CONSTRAINT [FK__PlantaMat__usuar__4D804459];
ALTER TABLE [prod].[PlantaMedicionE3] WITH CHECK ADD CONSTRAINT [FK__PlantaMed__plant__1C680BB2] FOREIGN KEY ([planta_id]) REFERENCES [prod].[PlantaPaltaE3] ([planta_id]);
ALTER TABLE [prod].[PlantaMedicionE3] CHECK CONSTRAINT [FK__PlantaMed__plant__1C680BB2];
ALTER TABLE [prod].[PlantaMedicionE3] WITH CHECK ADD CONSTRAINT [FK__PlantaMed__usuar__1E505424] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[PlantaMedicionE3] CHECK CONSTRAINT [FK__PlantaMed__usuar__1E505424];
ALTER TABLE [prod].[PlantaMedicionE3] WITH CHECK ADD CONSTRAINT [FK__PlantaMed__visit__1D5C2FEB] FOREIGN KEY ([visita_tecnica_id]) REFERENCES [campo].[VisitaTecnica] ([visita_tecnica_id]);
ALTER TABLE [prod].[PlantaMedicionE3] CHECK CONSTRAINT [FK__PlantaMed__visit__1D5C2FEB];
ALTER TABLE [prod].[PlantaPaltaE3] WITH CHECK ADD CONSTRAINT [FK__PlantaPal__conve__15F0184D] FOREIGN KEY ([convenio_id]) REFERENCES [org].[ConvenioUOTOrganizacion] ([convenio_uot_organizacion_id]);
ALTER TABLE [prod].[PlantaPaltaE3] CHECK CONSTRAINT [FK__PlantaPal__conve__15F0184D];
ALTER TABLE [prod].[PlantaPaltaE3] WITH CHECK ADD CONSTRAINT [FK__PlantaPal__cread__19C0A931] FOREIGN KEY ([creado_por_usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[PlantaPaltaE3] CHECK CONSTRAINT [FK__PlantaPal__cread__19C0A931];
ALTER TABLE [prod].[PlantaPaltaE3] WITH CHECK ADD CONSTRAINT [FK__PlantaPal__parce__17D860BF] FOREIGN KEY ([parcela_cultivo_id]) REFERENCES [prod].[ParcelaCultivo] ([parcela_cultivo_id]);
ALTER TABLE [prod].[PlantaPaltaE3] CHECK CONSTRAINT [FK__PlantaPal__parce__17D860BF];
ALTER TABLE [prod].[PlantaPaltaE3] WITH CHECK ADD CONSTRAINT [FK__PlantaPal__predi__1407CFDB] FOREIGN KEY ([predio_id]) REFERENCES [prod].[Predio] ([predio_id]);
ALTER TABLE [prod].[PlantaPaltaE3] CHECK CONSTRAINT [FK__PlantaPal__predi__1407CFDB];
ALTER TABLE [prod].[PlantaPaltaE3] WITH CHECK ADD CONSTRAINT [FK__PlantaPal__uot_i__14FBF414] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [prod].[PlantaPaltaE3] CHECK CONSTRAINT [FK__PlantaPal__uot_i__14FBF414];
ALTER TABLE [prod].[PlantaPaltaE3] WITH CHECK ADD CONSTRAINT [FK__PlantaPal__varie__16E43C86] FOREIGN KEY ([variedad_palta_id]) REFERENCES [prod].[VariedadPalta] ([variedad_palta_id]);
ALTER TABLE [prod].[PlantaPaltaE3] CHECK CONSTRAINT [FK__PlantaPal__varie__16E43C86];
ALTER TABLE [prod].[PlantaPaltaE3] WITH CHECK ADD CONSTRAINT [FK_E3_Planta_Socio] FOREIGN KEY ([socio_id]) REFERENCES [org].[Socio] ([socio_id]);
ALTER TABLE [prod].[PlantaPaltaE3] CHECK CONSTRAINT [FK_E3_Planta_Socio];
ALTER TABLE [prod].[PlantaSolicitudE3] WITH CHECK ADD CONSTRAINT [FK__PlantaSol__usuar__459F2B6F] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[PlantaSolicitudE3] CHECK CONSTRAINT [FK__PlantaSol__usuar__459F2B6F];
ALTER TABLE [prod].[Predio] WITH CHECK ADD CONSTRAINT [FK_Predio_Ubicacion] FOREIGN KEY ([ubicacion_id]) REFERENCES [geo].[Ubicacion] ([ubicacion_id]);
ALTER TABLE [prod].[Predio] CHECK CONSTRAINT [FK_Predio_Ubicacion];
ALTER TABLE [prod].[Predio] WITH CHECK ADD CONSTRAINT [FK_Predio_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [prod].[Predio] CHECK CONSTRAINT [FK_Predio_UOT];
ALTER TABLE [prod].[PredioAmbito] WITH CHECK ADD CONSTRAINT [FK__PredioAmb__conve__3691F209] FOREIGN KEY ([convenio_uot_organizacion_id]) REFERENCES [org].[ConvenioUOTOrganizacion] ([convenio_uot_organizacion_id]);
ALTER TABLE [prod].[PredioAmbito] CHECK CONSTRAINT [FK__PredioAmb__conve__3691F209];
ALTER TABLE [prod].[PredioAmbito] WITH CHECK ADD CONSTRAINT [FK__PredioAmb__predi__34A9A997] FOREIGN KEY ([predio_id]) REFERENCES [prod].[Predio] ([predio_id]);
ALTER TABLE [prod].[PredioAmbito] CHECK CONSTRAINT [FK__PredioAmb__predi__34A9A997];
ALTER TABLE [prod].[PredioAmbito] WITH CHECK ADD CONSTRAINT [FK__PredioAmb__uot_i__359DCDD0] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [prod].[PredioAmbito] CHECK CONSTRAINT [FK__PredioAmb__uot_i__359DCDD0];
ALTER TABLE [prod].[PredioAmbito] WITH CHECK ADD CONSTRAINT [FK__PredioAmb__usuar__396E5EB4] FOREIGN KEY ([usuario_creacion_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[PredioAmbito] CHECK CONSTRAINT [FK__PredioAmb__usuar__396E5EB4];
ALTER TABLE [prod].[PredioIdentidad] WITH CHECK ADD CONSTRAINT [FK__PredioIde__distr__3D3EEF98] FOREIGN KEY ([distrito_codigo]) REFERENCES [geo].[Distrito] ([distrito_codigo]);
ALTER TABLE [prod].[PredioIdentidad] CHECK CONSTRAINT [FK__PredioIde__distr__3D3EEF98];
ALTER TABLE [prod].[PredioIdentidad] WITH CHECK ADD CONSTRAINT [FK__PredioIde__perso__3C4ACB5F] FOREIGN KEY ([persona_id]) REFERENCES [org].[Persona] ([persona_id]);
ALTER TABLE [prod].[PredioIdentidad] CHECK CONSTRAINT [FK__PredioIde__perso__3C4ACB5F];
ALTER TABLE [prod].[PredioIdentidad] WITH CHECK ADD CONSTRAINT [FK__PredioIde__predi__3E3313D1] FOREIGN KEY ([predio_id]) REFERENCES [prod].[Predio] ([predio_id]);
ALTER TABLE [prod].[PredioIdentidad] CHECK CONSTRAINT [FK__PredioIde__predi__3E3313D1];
ALTER TABLE [prod].[PredioMateriaSecaCambioE4] WITH CHECK ADD CONSTRAINT [FK__PredioMat__infor__6740165C] FOREIGN KEY ([informe_id]) REFERENCES [prod].[PredioMateriaSecaGlobalE4] ([informe_id]);
ALTER TABLE [prod].[PredioMateriaSecaCambioE4] CHECK CONSTRAINT [FK__PredioMat__infor__6740165C];
ALTER TABLE [prod].[PredioMateriaSecaCambioE4] WITH CHECK ADD CONSTRAINT [FK__PredioMat__usuar__69285ECE] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[PredioMateriaSecaCambioE4] CHECK CONSTRAINT [FK__PredioMat__usuar__69285ECE];
ALTER TABLE [prod].[PredioMateriaSecaGlobalE4] WITH CHECK ADD CONSTRAINT [FK__PredioMat__conve__542D41E8] FOREIGN KEY ([convenio_id]) REFERENCES [org].[ConvenioUOTOrganizacion] ([convenio_uot_organizacion_id]);
ALTER TABLE [prod].[PredioMateriaSecaGlobalE4] CHECK CONSTRAINT [FK__PredioMat__conve__542D41E8];
ALTER TABLE [prod].[PredioMateriaSecaGlobalE4] WITH CHECK ADD CONSTRAINT [FK__PredioMat__elimi__627B613F] FOREIGN KEY ([eliminado_por_usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[PredioMateriaSecaGlobalE4] CHECK CONSTRAINT [FK__PredioMat__elimi__627B613F];
ALTER TABLE [prod].[PredioMateriaSecaGlobalE4] WITH CHECK ADD CONSTRAINT [FK__PredioMat__modif__61873D06] FOREIGN KEY ([modificado_por_usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[PredioMateriaSecaGlobalE4] CHECK CONSTRAINT [FK__PredioMat__modif__61873D06];
ALTER TABLE [prod].[PredioMateriaSecaGlobalE4] WITH CHECK ADD CONSTRAINT [FK__PredioMat__predi__5244F976] FOREIGN KEY ([predio_id]) REFERENCES [prod].[Predio] ([predio_id]);
ALTER TABLE [prod].[PredioMateriaSecaGlobalE4] CHECK CONSTRAINT [FK__PredioMat__predi__5244F976];
ALTER TABLE [prod].[PredioMateriaSecaGlobalE4] WITH CHECK ADD CONSTRAINT [FK__PredioMat__uot_i__53391DAF] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [prod].[PredioMateriaSecaGlobalE4] CHECK CONSTRAINT [FK__PredioMat__uot_i__53391DAF];
ALTER TABLE [prod].[PredioMateriaSecaGlobalE4] WITH CHECK ADD CONSTRAINT [FK__PredioMat__usuar__55216621] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[PredioMateriaSecaGlobalE4] CHECK CONSTRAINT [FK__PredioMat__usuar__55216621];
ALTER TABLE [prod].[PredioTitularidad] WITH CHECK ADD CONSTRAINT [FK_E1_Titular_Persona] FOREIGN KEY ([persona_id]) REFERENCES [org].[Persona] ([persona_id]);
ALTER TABLE [prod].[PredioTitularidad] CHECK CONSTRAINT [FK_E1_Titular_Persona];
ALTER TABLE [prod].[PredioTitularidad] WITH CHECK ADD CONSTRAINT [FK_PredioTitularidad_Predio] FOREIGN KEY ([predio_id]) REFERENCES [prod].[Predio] ([predio_id]);
ALTER TABLE [prod].[PredioTitularidad] CHECK CONSTRAINT [FK_PredioTitularidad_Predio];
ALTER TABLE [prod].[PredioTitularidad] WITH CHECK ADD CONSTRAINT [FK_PredioTitularidad_Socio] FOREIGN KEY ([socio_id]) REFERENCES [org].[Socio] ([socio_id]);
ALTER TABLE [prod].[PredioTitularidad] CHECK CONSTRAINT [FK_PredioTitularidad_Socio];
ALTER TABLE [prod].[PredioVersion] WITH CHECK ADD CONSTRAINT [FK_PredioVersion_Predio] FOREIGN KEY ([predio_id]) REFERENCES [prod].[Predio] ([predio_id]);
ALTER TABLE [prod].[PredioVersion] CHECK CONSTRAINT [FK_PredioVersion_Predio];
ALTER TABLE [prod].[ProduccionPlantaE3] WITH CHECK ADD CONSTRAINT [FK__Produccio__plant__38453051] FOREIGN KEY ([planta_id]) REFERENCES [prod].[PlantaPaltaE3] ([planta_id]);
ALTER TABLE [prod].[ProduccionPlantaE3] CHECK CONSTRAINT [FK__Produccio__plant__38453051];
ALTER TABLE [prod].[ProduccionPlantaE3] WITH CHECK ADD CONSTRAINT [FK__Produccio__usuar__3939548A] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [prod].[ProduccionPlantaE3] CHECK CONSTRAINT [FK__Produccio__usuar__3939548A];
ALTER TABLE [prod].[ProduccionPlantaE3] WITH CHECK ADD CONSTRAINT [FK_E3_ProduccionVisita] FOREIGN KEY ([visita_tecnica_id]) REFERENCES [campo].[VisitaTecnica] ([visita_tecnica_id]);
ALTER TABLE [prod].[ProduccionPlantaE3] CHECK CONSTRAINT [FK_E3_ProduccionVisita];
ALTER TABLE [prod].[VariedadCultivo] WITH CHECK ADD CONSTRAINT [FK_VariedadCultivo_Cultivo] FOREIGN KEY ([cultivo_id]) REFERENCES [prod].[Cultivo] ([cultivo_id]);
ALTER TABLE [prod].[VariedadCultivo] CHECK CONSTRAINT [FK_VariedadCultivo_Cultivo];
ALTER TABLE [prod].[VariedadCultivo] WITH CHECK ADD CONSTRAINT [FK_VariedadCultivo_Palta] FOREIGN KEY ([variedad_palta_legacy_id]) REFERENCES [prod].[VariedadPalta] ([variedad_palta_id]);
ALTER TABLE [prod].[VariedadCultivo] CHECK CONSTRAINT [FK_VariedadCultivo_Palta];
ALTER TABLE [reporte].[TrabajoEspecial] WITH CHECK ADD CONSTRAINT [FK__TrabajoEs__uot_i__7BD11EEE] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [reporte].[TrabajoEspecial] CHECK CONSTRAINT [FK__TrabajoEs__uot_i__7BD11EEE];
ALTER TABLE [reporte].[TrabajoEspecial] WITH CHECK ADD CONSTRAINT [FK__TrabajoEs__usuar__7ADCFAB5] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [reporte].[TrabajoEspecial] CHECK CONSTRAINT [FK__TrabajoEs__usuar__7ADCFAB5];
ALTER TABLE [reporte].[TrabajoExcel] WITH CHECK ADD CONSTRAINT [FK__TrabajoEx__uot_i__4EFE7877] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [reporte].[TrabajoExcel] CHECK CONSTRAINT [FK__TrabajoEx__uot_i__4EFE7877];
ALTER TABLE [reporte].[TrabajoExcel] WITH CHECK ADD CONSTRAINT [FK__TrabajoEx__usuar__4E0A543E] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [reporte].[TrabajoExcel] CHECK CONSTRAINT [FK__TrabajoEx__usuar__4E0A543E];
ALTER TABLE [sanidad].[CasoFitosanitario] WITH CHECK ADD CONSTRAINT [FK_CasoFitosanitario_Cultivo] FOREIGN KEY ([parcela_cultivo_id]) REFERENCES [prod].[ParcelaCultivo] ([parcela_cultivo_id]);
ALTER TABLE [sanidad].[CasoFitosanitario] CHECK CONSTRAINT [FK_CasoFitosanitario_Cultivo];
ALTER TABLE [sanidad].[CasoFitosanitario] WITH CHECK ADD CONSTRAINT [FK_CasoFitosanitario_TipoProblema] FOREIGN KEY ([tipo_problema_fitosanitario_id]) REFERENCES [sanidad].[TipoProblemaFitosanitario] ([tipo_problema_fitosanitario_id]);
ALTER TABLE [sanidad].[CasoFitosanitario] CHECK CONSTRAINT [FK_CasoFitosanitario_TipoProblema];
ALTER TABLE [sanidad].[CasoFitosanitario] WITH CHECK ADD CONSTRAINT [FK_CasoFitosanitario_Visita] FOREIGN KEY ([visita_deteccion_id]) REFERENCES [campo].[VisitaTecnica] ([visita_tecnica_id]);
ALTER TABLE [sanidad].[CasoFitosanitario] CHECK CONSTRAINT [FK_CasoFitosanitario_Visita];
ALTER TABLE [sanidad].[EpisodioNotaE4] WITH CHECK ADD CONSTRAINT [FK__EpisodioN__episo__411A6D74] FOREIGN KEY ([episodio_id]) REFERENCES [sanidad].[EpisodioPlantaE3] ([episodio_id]);
ALTER TABLE [sanidad].[EpisodioNotaE4] CHECK CONSTRAINT [FK__EpisodioN__episo__411A6D74];
ALTER TABLE [sanidad].[EpisodioNotaE4] WITH CHECK ADD CONSTRAINT [FK__EpisodioN__usuar__420E91AD] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [sanidad].[EpisodioNotaE4] CHECK CONSTRAINT [FK__EpisodioN__usuar__420E91AD];
ALTER TABLE [sanidad].[EpisodioPlantaE3] WITH CHECK ADD CONSTRAINT [FK__EpisodioP__elimi__5FD3FEBE] FOREIGN KEY ([eliminado_por_usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [sanidad].[EpisodioPlantaE3] CHECK CONSTRAINT [FK__EpisodioP__elimi__5FD3FEBE];
ALTER TABLE [sanidad].[EpisodioPlantaE3] WITH CHECK ADD CONSTRAINT [FK__EpisodioP__plant__2AEB3533] FOREIGN KEY ([planta_id]) REFERENCES [prod].[PlantaPaltaE3] ([planta_id]);
ALTER TABLE [sanidad].[EpisodioPlantaE3] CHECK CONSTRAINT [FK__EpisodioP__plant__2AEB3533];
ALTER TABLE [sanidad].[EpisodioPlantaE3] WITH CHECK ADD CONSTRAINT [FK__EpisodioP__tipo___2BDF596C] FOREIGN KEY ([tipo_problema_fitosanitario_id]) REFERENCES [sanidad].[TipoProblemaFitosanitario] ([tipo_problema_fitosanitario_id]);
ALTER TABLE [sanidad].[EpisodioPlantaE3] CHECK CONSTRAINT [FK__EpisodioP__tipo___2BDF596C];
ALTER TABLE [sanidad].[EpisodioPlantaE3] WITH CHECK ADD CONSTRAINT [FK__EpisodioP__usuar__2CD37DA5] FOREIGN KEY ([usuario_apertura_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [sanidad].[EpisodioPlantaE3] CHECK CONSTRAINT [FK__EpisodioP__usuar__2CD37DA5];
ALTER TABLE [sanidad].[EpisodioPlantaE3] WITH CHECK ADD CONSTRAINT [FK__EpisodioP__usuar__2DC7A1DE] FOREIGN KEY ([usuario_cierre_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [sanidad].[EpisodioPlantaE3] CHECK CONSTRAINT [FK__EpisodioP__usuar__2DC7A1DE];
ALTER TABLE [sanidad].[EpisodioPlantaE3] WITH CHECK ADD CONSTRAINT [FK__EpisodioP__visit__2EBBC617] FOREIGN KEY ([visita_tecnica_id]) REFERENCES [campo].[VisitaTecnica] ([visita_tecnica_id]);
ALTER TABLE [sanidad].[EpisodioPlantaE3] CHECK CONSTRAINT [FK__EpisodioP__visit__2EBBC617];
ALTER TABLE [sanidad].[EpisodioPlantaE3] WITH CHECK ADD CONSTRAINT [FK_E3_Episodio_GPProblema] FOREIGN KEY ([gp_problema_id]) REFERENCES [prod].[GPProblema] ([problema_id]);
ALTER TABLE [sanidad].[EpisodioPlantaE3] CHECK CONSTRAINT [FK_E3_Episodio_GPProblema];
ALTER TABLE [sanidad].[PlantaSeguimientoE3] WITH CHECK ADD CONSTRAINT [FK__PlantaSeg__episo__2898D86D] FOREIGN KEY ([episodio_id]) REFERENCES [sanidad].[EpisodioPlantaE3] ([episodio_id]);
ALTER TABLE [sanidad].[PlantaSeguimientoE3] CHECK CONSTRAINT [FK__PlantaSeg__episo__2898D86D];
ALTER TABLE [sanidad].[PlantaSeguimientoE3] WITH CHECK ADD CONSTRAINT [FK__PlantaSeg__event__298CFCA6] FOREIGN KEY ([evento_id]) REFERENCES [prod].[PlantaEventoE3] ([evento_id]);
ALTER TABLE [sanidad].[PlantaSeguimientoE3] CHECK CONSTRAINT [FK__PlantaSeg__event__298CFCA6];
ALTER TABLE [sanidad].[PlantaSeguimientoE3] WITH CHECK ADD CONSTRAINT [FK__PlantaSeg__plant__27A4B434] FOREIGN KEY ([planta_id]) REFERENCES [prod].[PlantaPaltaE3] ([planta_id]);
ALTER TABLE [sanidad].[PlantaSeguimientoE3] CHECK CONSTRAINT [FK__PlantaSeg__plant__27A4B434];
ALTER TABLE [sanidad].[PlantaSeguimientoE3] WITH CHECK ADD CONSTRAINT [FK__PlantaSeg__usuar__2B754518] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [sanidad].[PlantaSeguimientoE3] CHECK CONSTRAINT [FK__PlantaSeg__usuar__2B754518];
ALTER TABLE [sanidad].[PlantaSeguimientoE3] WITH CHECK ADD CONSTRAINT [FK__PlantaSeg__visit__2A8120DF] FOREIGN KEY ([visita_tecnica_id]) REFERENCES [campo].[VisitaTecnica] ([visita_tecnica_id]);
ALTER TABLE [sanidad].[PlantaSeguimientoE3] CHECK CONSTRAINT [FK__PlantaSeg__visit__2A8120DF];
ALTER TABLE [sanidad].[SeguimientoFitosanitario] WITH CHECK ADD CONSTRAINT [FK_SeguimientoFitosanitario_Caso] FOREIGN KEY ([caso_fitosanitario_id]) REFERENCES [sanidad].[CasoFitosanitario] ([caso_fitosanitario_id]);
ALTER TABLE [sanidad].[SeguimientoFitosanitario] CHECK CONSTRAINT [FK_SeguimientoFitosanitario_Caso];
ALTER TABLE [sanidad].[SeguimientoFitosanitario] WITH CHECK ADD CONSTRAINT [FK_SeguimientoFitosanitario_Visita] FOREIGN KEY ([visita_tecnica_id]) REFERENCES [campo].[VisitaTecnica] ([visita_tecnica_id]);
ALTER TABLE [sanidad].[SeguimientoFitosanitario] CHECK CONSTRAINT [FK_SeguimientoFitosanitario_Visita];
ALTER TABLE [sanidad].[TratamientoAplicacionE4] WITH CHECK ADD CONSTRAINT [FK__Tratamien__episo__46D346CA] FOREIGN KEY ([episodio_id]) REFERENCES [sanidad].[EpisodioPlantaE3] ([episodio_id]);
ALTER TABLE [sanidad].[TratamientoAplicacionE4] CHECK CONSTRAINT [FK__Tratamien__episo__46D346CA];
ALTER TABLE [sanidad].[TratamientoAplicacionE4] WITH CHECK ADD CONSTRAINT [FK__Tratamien__usuar__47C76B03] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [sanidad].[TratamientoAplicacionE4] CHECK CONSTRAINT [FK__Tratamien__usuar__47C76B03];
ALTER TABLE [sanidad].[TratamientoArchivoE4] WITH CHECK ADD CONSTRAINT [FK__Tratamien__aplic__2449249C] FOREIGN KEY ([aplicacion_id]) REFERENCES [sanidad].[TratamientoAplicacionE4] ([aplicacion_id]);
ALTER TABLE [sanidad].[TratamientoArchivoE4] CHECK CONSTRAINT [FK__Tratamien__aplic__2449249C];
ALTER TABLE [sanidad].[TratamientoArchivoE4] WITH CHECK ADD CONSTRAINT [FK__Tratamien__archi__253D48D5] FOREIGN KEY ([archivo_id]) REFERENCES [archivo].[Archivo] ([archivo_id]);
ALTER TABLE [sanidad].[TratamientoArchivoE4] CHECK CONSTRAINT [FK__Tratamien__archi__253D48D5];
ALTER TABLE [sanidad].[TratamientoArchivoE4] WITH CHECK ADD CONSTRAINT [FK__Tratamien__usuar__26316D0E] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [sanidad].[TratamientoArchivoE4] CHECK CONSTRAINT [FK__Tratamien__usuar__26316D0E];
ALTER TABLE [sanidad].[TratamientoEdicionE3] WITH CHECK ADD CONSTRAINT [FK__Tratamien__trata__44B5F42E] FOREIGN KEY ([tratamiento_id]) REFERENCES [sanidad].[TratamientoPlantaE3] ([tratamiento_id]);
ALTER TABLE [sanidad].[TratamientoEdicionE3] CHECK CONSTRAINT [FK__Tratamien__trata__44B5F42E];
ALTER TABLE [sanidad].[TratamientoEdicionE3] WITH CHECK ADD CONSTRAINT [FK__Tratamien__usuar__45AA1867] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [sanidad].[TratamientoEdicionE3] CHECK CONSTRAINT [FK__Tratamien__usuar__45AA1867];
ALTER TABLE [sanidad].[TratamientoFitosanitario] WITH CHECK ADD CONSTRAINT [FK_TratamientoFitosanitario_Caso] FOREIGN KEY ([caso_fitosanitario_id]) REFERENCES [sanidad].[CasoFitosanitario] ([caso_fitosanitario_id]);
ALTER TABLE [sanidad].[TratamientoFitosanitario] CHECK CONSTRAINT [FK_TratamientoFitosanitario_Caso];
ALTER TABLE [sanidad].[TratamientoFitosanitario] WITH CHECK ADD CONSTRAINT [FK_TratamientoFitosanitario_Responsable] FOREIGN KEY ([responsable_empleado_id]) REFERENCES [org].[Empleado] ([empleado_id]);
ALTER TABLE [sanidad].[TratamientoFitosanitario] CHECK CONSTRAINT [FK_TratamientoFitosanitario_Responsable];
ALTER TABLE [sanidad].[TratamientoFitosanitario] WITH CHECK ADD CONSTRAINT [FK_TratamientoFitosanitario_Visita] FOREIGN KEY ([visita_tecnica_id]) REFERENCES [campo].[VisitaTecnica] ([visita_tecnica_id]);
ALTER TABLE [sanidad].[TratamientoFitosanitario] CHECK CONSTRAINT [FK_TratamientoFitosanitario_Visita];
ALTER TABLE [sanidad].[TratamientoPlantaE3] WITH CHECK ADD CONSTRAINT [FK__Tratamien__episo__328C56FB] FOREIGN KEY ([episodio_id]) REFERENCES [sanidad].[EpisodioPlantaE3] ([episodio_id]);
ALTER TABLE [sanidad].[TratamientoPlantaE3] CHECK CONSTRAINT [FK__Tratamien__episo__328C56FB];
ALTER TABLE [sanidad].[TratamientoPlantaE3] WITH CHECK ADD CONSTRAINT [FK__Tratamien__usuar__34749F6D] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [sanidad].[TratamientoPlantaE3] CHECK CONSTRAINT [FK__Tratamien__usuar__34749F6D];
ALTER TABLE [sanidad].[TratamientoPlantaE3] WITH CHECK ADD CONSTRAINT [FK__Tratamien__visit__33807B34] FOREIGN KEY ([visita_tecnica_id]) REFERENCES [campo].[VisitaTecnica] ([visita_tecnica_id]);
ALTER TABLE [sanidad].[TratamientoPlantaE3] CHECK CONSTRAINT [FK__Tratamien__visit__33807B34];
ALTER TABLE [sanidad].[TratamientoPlantaE3] WITH CHECK ADD CONSTRAINT [FK_E3_Tratamiento_GPTratamiento] FOREIGN KEY ([gp_tratamiento_id]) REFERENCES [prod].[GPTratamiento] ([tratamiento_id]);
ALTER TABLE [sanidad].[TratamientoPlantaE3] CHECK CONSTRAINT [FK_E3_Tratamiento_GPTratamiento];
ALTER TABLE [sanidad].[TratamientoPlantaE3] WITH CHECK ADD CONSTRAINT [FK_E3_Tratamiento_ModificadoPor] FOREIGN KEY ([modificado_por_usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [sanidad].[TratamientoPlantaE3] CHECK CONSTRAINT [FK_E3_Tratamiento_ModificadoPor];
ALTER TABLE [sanidad].[TratamientoPlantaE3] WITH CHECK ADD CONSTRAINT [FK_E4_TratamientoAplicacion] FOREIGN KEY ([aplicacion_id]) REFERENCES [sanidad].[TratamientoAplicacionE4] ([aplicacion_id]);
ALTER TABLE [sanidad].[TratamientoPlantaE3] CHECK CONSTRAINT [FK_E4_TratamientoAplicacion];
ALTER TABLE [seg].[CodigoUnSoloUso] WITH CHECK ADD CONSTRAINT [FK_CodigoUnSoloUso_Correo] FOREIGN KEY ([usuario_correo_seguridad_id]) REFERENCES [seg].[UsuarioCorreoSeguridad] ([usuario_correo_seguridad_id]);
ALTER TABLE [seg].[CodigoUnSoloUso] CHECK CONSTRAINT [FK_CodigoUnSoloUso_Correo];
ALTER TABLE [seg].[CodigoUnSoloUso] WITH CHECK ADD CONSTRAINT [FK_CodigoUnSoloUso_Dispositivo] FOREIGN KEY ([dispositivo_usuario_id]) REFERENCES [seg].[DispositivoUsuario] ([dispositivo_usuario_id]);
ALTER TABLE [seg].[CodigoUnSoloUso] CHECK CONSTRAINT [FK_CodigoUnSoloUso_Dispositivo];
ALTER TABLE [seg].[CodigoUnSoloUso] WITH CHECK ADD CONSTRAINT [FK_CodigoUnSoloUso_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [seg].[CodigoUnSoloUso] CHECK CONSTRAINT [FK_CodigoUnSoloUso_Usuario];
ALTER TABLE [seg].[DispositivoUsuario] WITH CHECK ADD CONSTRAINT [FK_DispositivoUsuario_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [seg].[DispositivoUsuario] CHECK CONSTRAINT [FK_DispositivoUsuario_Usuario];
ALTER TABLE [seg].[HistorialPassword] WITH CHECK ADD CONSTRAINT [FK_HistorialPassword_CambiadoPor] FOREIGN KEY ([cambiado_por_usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [seg].[HistorialPassword] CHECK CONSTRAINT [FK_HistorialPassword_CambiadoPor];
ALTER TABLE [seg].[HistorialPassword] WITH CHECK ADD CONSTRAINT [FK_HistorialPassword_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [seg].[HistorialPassword] CHECK CONSTRAINT [FK_HistorialPassword_Usuario];
ALTER TABLE [seg].[IntentoAutenticacion] WITH CHECK ADD CONSTRAINT [FK_IntentoAutenticacion_Dispositivo] FOREIGN KEY ([dispositivo_usuario_id]) REFERENCES [seg].[DispositivoUsuario] ([dispositivo_usuario_id]);
ALTER TABLE [seg].[IntentoAutenticacion] CHECK CONSTRAINT [FK_IntentoAutenticacion_Dispositivo];
ALTER TABLE [seg].[IntentoAutenticacion] WITH CHECK ADD CONSTRAINT [FK_IntentoAutenticacion_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [seg].[IntentoAutenticacion] CHECK CONSTRAINT [FK_IntentoAutenticacion_Usuario];
ALTER TABLE [seg].[Modulo] WITH CHECK ADD CONSTRAINT [FK_Modulo_Padre] FOREIGN KEY ([modulo_padre_id]) REFERENCES [seg].[Modulo] ([modulo_id]);
ALTER TABLE [seg].[Modulo] CHECK CONSTRAINT [FK_Modulo_Padre];
ALTER TABLE [seg].[ModuloEspecialPermiso] WITH CHECK ADD CONSTRAINT [FK_ModuloEspecialPermiso_Modulo] FOREIGN KEY ([modulo_especial_id]) REFERENCES [seg].[ModuloEspecial] ([modulo_especial_id]);
ALTER TABLE [seg].[ModuloEspecialPermiso] CHECK CONSTRAINT [FK_ModuloEspecialPermiso_Modulo];
ALTER TABLE [seg].[ModuloEspecialPermiso] WITH CHECK ADD CONSTRAINT [FK_ModuloEspecialPermiso_Permiso] FOREIGN KEY ([permiso_id]) REFERENCES [seg].[Permiso] ([permiso_id]);
ALTER TABLE [seg].[ModuloEspecialPermiso] CHECK CONSTRAINT [FK_ModuloEspecialPermiso_Permiso];
ALTER TABLE [seg].[NotificacionSeguridad] WITH CHECK ADD CONSTRAINT [FK_NotificacionSeguridad_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [seg].[NotificacionSeguridad] CHECK CONSTRAINT [FK_NotificacionSeguridad_Usuario];
ALTER TABLE [seg].[Permiso] WITH CHECK ADD CONSTRAINT [FK_Permiso_Modulo] FOREIGN KEY ([modulo_id]) REFERENCES [seg].[Modulo] ([modulo_id]);
ALTER TABLE [seg].[Permiso] CHECK CONSTRAINT [FK_Permiso_Modulo];
ALTER TABLE [seg].[RefreshTokenSesion] WITH CHECK ADD CONSTRAINT [FK_RefreshTokenSesion_Padre] FOREIGN KEY ([token_padre_id]) REFERENCES [seg].[RefreshTokenSesion] ([refresh_token_sesion_id]);
ALTER TABLE [seg].[RefreshTokenSesion] CHECK CONSTRAINT [FK_RefreshTokenSesion_Padre];
ALTER TABLE [seg].[RefreshTokenSesion] WITH CHECK ADD CONSTRAINT [FK_RefreshTokenSesion_Reemplazo] FOREIGN KEY ([token_reemplazo_id]) REFERENCES [seg].[RefreshTokenSesion] ([refresh_token_sesion_id]);
ALTER TABLE [seg].[RefreshTokenSesion] CHECK CONSTRAINT [FK_RefreshTokenSesion_Reemplazo];
ALTER TABLE [seg].[RefreshTokenSesion] WITH CHECK ADD CONSTRAINT [FK_RefreshTokenSesion_Sesion] FOREIGN KEY ([sesion_usuario_id]) REFERENCES [seg].[SesionUsuario] ([sesion_usuario_id]);
ALTER TABLE [seg].[RefreshTokenSesion] CHECK CONSTRAINT [FK_RefreshTokenSesion_Sesion];
ALTER TABLE [seg].[RolPermiso] WITH CHECK ADD CONSTRAINT [FK_RolPermiso_AsignadoPor] FOREIGN KEY ([asignado_por_usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [seg].[RolPermiso] CHECK CONSTRAINT [FK_RolPermiso_AsignadoPor];
ALTER TABLE [seg].[RolPermiso] WITH CHECK ADD CONSTRAINT [FK_RolPermiso_Permiso] FOREIGN KEY ([permiso_id]) REFERENCES [seg].[Permiso] ([permiso_id]);
ALTER TABLE [seg].[RolPermiso] CHECK CONSTRAINT [FK_RolPermiso_Permiso];
ALTER TABLE [seg].[RolPermiso] WITH CHECK ADD CONSTRAINT [FK_RolPermiso_RetiradoPor] FOREIGN KEY ([retirado_por_usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [seg].[RolPermiso] CHECK CONSTRAINT [FK_RolPermiso_RetiradoPor];
ALTER TABLE [seg].[RolPermiso] WITH CHECK ADD CONSTRAINT [FK_RolPermiso_Rol] FOREIGN KEY ([rol_id]) REFERENCES [seg].[Rol] ([rol_id]);
ALTER TABLE [seg].[RolPermiso] CHECK CONSTRAINT [FK_RolPermiso_Rol];
ALTER TABLE [seg].[SesionUsuario] WITH CHECK ADD CONSTRAINT [FK_SesionUsuario_Dispositivo] FOREIGN KEY ([dispositivo_usuario_id]) REFERENCES [seg].[DispositivoUsuario] ([dispositivo_usuario_id]);
ALTER TABLE [seg].[SesionUsuario] CHECK CONSTRAINT [FK_SesionUsuario_Dispositivo];
ALTER TABLE [seg].[SesionUsuario] WITH CHECK ADD CONSTRAINT [FK_SesionUsuario_UOTContexto] FOREIGN KEY ([uot_contexto_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [seg].[SesionUsuario] CHECK CONSTRAINT [FK_SesionUsuario_UOTContexto];
ALTER TABLE [seg].[SesionUsuario] WITH CHECK ADD CONSTRAINT [FK_SesionUsuario_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [seg].[SesionUsuario] CHECK CONSTRAINT [FK_SesionUsuario_Usuario];
ALTER TABLE [seg].[TokenAccesoRevocado] WITH CHECK ADD CONSTRAINT [FK_TokenAccesoRevocado_Sesion] FOREIGN KEY ([sesion_usuario_id]) REFERENCES [seg].[SesionUsuario] ([sesion_usuario_id]);
ALTER TABLE [seg].[TokenAccesoRevocado] CHECK CONSTRAINT [FK_TokenAccesoRevocado_Sesion];
ALTER TABLE [seg].[Usuario] WITH CHECK ADD CONSTRAINT [FK_Usuario_Empleado] FOREIGN KEY ([persona_id]) REFERENCES [org].[Empleado] ([empleado_id]);
ALTER TABLE [seg].[Usuario] CHECK CONSTRAINT [FK_Usuario_Empleado];
ALTER TABLE [seg].[Usuario] WITH CHECK ADD CONSTRAINT [FK_Usuario_Persona] FOREIGN KEY ([persona_id]) REFERENCES [org].[Persona] ([persona_id]);
ALTER TABLE [seg].[Usuario] CHECK CONSTRAINT [FK_Usuario_Persona];
ALTER TABLE [seg].[UsuarioCorreoSeguridad] WITH CHECK ADD CONSTRAINT [FK_UsuarioCorreoSeguridad_CreadoPor] FOREIGN KEY ([creado_por_usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [seg].[UsuarioCorreoSeguridad] CHECK CONSTRAINT [FK_UsuarioCorreoSeguridad_CreadoPor];
ALTER TABLE [seg].[UsuarioCorreoSeguridad] WITH CHECK ADD CONSTRAINT [FK_UsuarioCorreoSeguridad_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [seg].[UsuarioCorreoSeguridad] CHECK CONSTRAINT [FK_UsuarioCorreoSeguridad_Usuario];
ALTER TABLE [seg].[UsuarioRol] WITH CHECK ADD CONSTRAINT [FK_UsuarioRol_AsignadoPor] FOREIGN KEY ([asignado_por_usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [seg].[UsuarioRol] CHECK CONSTRAINT [FK_UsuarioRol_AsignadoPor];
ALTER TABLE [seg].[UsuarioRol] WITH CHECK ADD CONSTRAINT [FK_UsuarioRol_RetiradoPor] FOREIGN KEY ([retirado_por_usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [seg].[UsuarioRol] CHECK CONSTRAINT [FK_UsuarioRol_RetiradoPor];
ALTER TABLE [seg].[UsuarioRol] WITH CHECK ADD CONSTRAINT [FK_UsuarioRol_Rol] FOREIGN KEY ([rol_id]) REFERENCES [seg].[Rol] ([rol_id]);
ALTER TABLE [seg].[UsuarioRol] CHECK CONSTRAINT [FK_UsuarioRol_Rol];
ALTER TABLE [seg].[UsuarioRol] WITH CHECK ADD CONSTRAINT [FK_UsuarioRol_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [seg].[UsuarioRol] CHECK CONSTRAINT [FK_UsuarioRol_Usuario];
ALTER TABLE [seg].[UsuarioUOT] WITH CHECK ADD CONSTRAINT [FK_UsuarioUOT_Asignador] FOREIGN KEY ([asignado_por_usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [seg].[UsuarioUOT] CHECK CONSTRAINT [FK_UsuarioUOT_Asignador];
ALTER TABLE [seg].[UsuarioUOT] WITH CHECK ADD CONSTRAINT [FK_UsuarioUOT_UOT] FOREIGN KEY ([uot_id]) REFERENCES [org].[UOT] ([uot_id]);
ALTER TABLE [seg].[UsuarioUOT] CHECK CONSTRAINT [FK_UsuarioUOT_UOT];
ALTER TABLE [seg].[UsuarioUOT] WITH CHECK ADD CONSTRAINT [FK_UsuarioUOT_Usuario] FOREIGN KEY ([usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [seg].[UsuarioUOT] CHECK CONSTRAINT [FK_UsuarioUOT_Usuario];
ALTER TABLE [seg].[UsuarioUOTPermiso] WITH CHECK ADD CONSTRAINT [FK_UsuarioUOTPermiso_Asignador] FOREIGN KEY ([asignado_por_usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [seg].[UsuarioUOTPermiso] CHECK CONSTRAINT [FK_UsuarioUOTPermiso_Asignador];
ALTER TABLE [seg].[UsuarioUOTPermiso] WITH CHECK ADD CONSTRAINT [FK_UsuarioUOTPermiso_Permiso] FOREIGN KEY ([permiso_id]) REFERENCES [seg].[Permiso] ([permiso_id]);
ALTER TABLE [seg].[UsuarioUOTPermiso] CHECK CONSTRAINT [FK_UsuarioUOTPermiso_Permiso];
ALTER TABLE [seg].[UsuarioUOTPermiso] WITH CHECK ADD CONSTRAINT [FK_UsuarioUOTPermiso_UsuarioUOT] FOREIGN KEY ([usuario_uot_id]) REFERENCES [seg].[UsuarioUOT] ([usuario_uot_id]);
ALTER TABLE [seg].[UsuarioUOTPermiso] CHECK CONSTRAINT [FK_UsuarioUOTPermiso_UsuarioUOT];
ALTER TABLE [seg].[UsuarioUOTRol] WITH CHECK ADD CONSTRAINT [FK_UsuarioUOTRol_Asignador] FOREIGN KEY ([asignado_por_usuario_id]) REFERENCES [seg].[Usuario] ([usuario_id]);
ALTER TABLE [seg].[UsuarioUOTRol] CHECK CONSTRAINT [FK_UsuarioUOTRol_Asignador];
ALTER TABLE [seg].[UsuarioUOTRol] WITH CHECK ADD CONSTRAINT [FK_UsuarioUOTRol_Rol] FOREIGN KEY ([rol_id]) REFERENCES [seg].[Rol] ([rol_id]);
ALTER TABLE [seg].[UsuarioUOTRol] CHECK CONSTRAINT [FK_UsuarioUOTRol_Rol];
ALTER TABLE [seg].[UsuarioUOTRol] WITH CHECK ADD CONSTRAINT [FK_UsuarioUOTRol_UsuarioUOT] FOREIGN KEY ([usuario_uot_id]) REFERENCES [seg].[UsuarioUOT] ([usuario_uot_id]);
ALTER TABLE [seg].[UsuarioUOTRol] CHECK CONSTRAINT [FK_UsuarioUOTRol_UsuarioUOT];
GO

-- Restricciones de validación del esquema final.
ALTER TABLE [archivo].[Archivo] WITH CHECK ADD CONSTRAINT [CK_Archivo_Categoria] CHECK ([categoria] IS NULL OR ([categoria]='OTRO' OR [categoria]='COMPROBANTE' OR [categoria]='TICKET' OR [categoria]='DOCUMENTO' OR [categoria]='FOTOGRAFIA'));
ALTER TABLE [archivo].[Archivo] WITH CHECK ADD CONSTRAINT [CK_Archivo_OrigenCaptura] CHECK ([origen_captura] IS NULL OR ([origen_captura]='CAMARA' OR [origen_captura]='CARGA'));
ALTER TABLE [archivo].[Archivo] WITH CHECK ADD CONSTRAINT [CK_Archivo_PosicionSRID] CHECK ([posicion_captura] IS NULL OR [posicion_captura].[STSrid]=(4326));
ALTER TABLE [archivo].[Archivo] WITH CHECK ADD CONSTRAINT [CK_Archivo_ProveedorAlmacenamiento] CHECK ([proveedor_almacenamiento] IS NULL OR ([proveedor_almacenamiento]='OTRO' OR [proveedor_almacenamiento]='CLOUDINARY' OR [proveedor_almacenamiento]='S3' OR [proveedor_almacenamiento]='SERVIDOR' OR [proveedor_almacenamiento]='LOCAL'));
ALTER TABLE [archivo].[Archivo] WITH CHECK ADD CONSTRAINT [CK_Archivo_Tamano] CHECK ([tamano_bytes] IS NULL OR [tamano_bytes]>=(0));
ALTER TABLE [archivo].[ArchivoVinculo] WITH CHECK ADD CONSTRAINT [CK_ArchivoVinculo_UnDestino] CHECK ((((((((((((((((((((((((((((case when [predio_id] IS NULL then (0) else (1) end+case when [salida_campo_id] IS NULL then (0) else (1) end)+case when [visita_tecnica_id] IS NULL then (0) else (1) end)+case when [caso_fitosanitario_id] IS NULL then (0) else (1) end)+case when [tratamiento_id] IS NULL then (0) else (1) end)+case when [entrega_socio_id] IS NULL then (0) else (1) end)+case when [incidencia_operativa_id] IS NULL then (0) else (1) end)+case when [ajuste_precio_socio_id] IS NULL then (0) else (1) end)+case when [gasto_campania_id] IS NULL then (0) else (1) end)+case when [liquidacion_socio_id] IS NULL then (0) else (1) end)+case when [pago_socio_id] IS NULL then (0) else (1) end)+case when [cobro_comprador_id] IS NULL then (0) else (1) end)+case when [socio_id] IS NULL then (0) else (1) end)+case when [empleado_id] IS NULL then (0) else (1) end)+case when [parcela_id] IS NULL then (0) else (1) end)+case when [parcela_cultivo_id] IS NULL then (0) else (1) end)+case when [censo_plantas_id] IS NULL then (0) else (1) end)+case when [evaluacion_agronomica_id] IS NULL then (0) else (1) end)+case when [seguimiento_fitosanitario_id] IS NULL then (0) else (1) end)+case when [disponibilidad_produccion_id] IS NULL then (0) else (1) end)+case when [campania_venta_id] IS NULL then (0) else (1) end)+case when [precio_comercial_id] IS NULL then (0) else (1) end)+case when [participacion_campania_socio_id] IS NULL then (0) else (1) end)+case when [operativo_venta_id] IS NULL then (0) else (1) end)+case when [jaba_asignacion_id] IS NULL then (0) else (1) end)+case when [jaba_devolucion_id] IS NULL then (0) else (1) end)+case when [bien_inventario_id] IS NULL then (0) else (1) end)+case when [recurso_programado_id] IS NULL then (0) else (1) end)=(1));
ALTER TABLE [auditoria].[AuditoriaEvento] WITH CHECK ADD CONSTRAINT [CK_AuditoriaEvento_DatosAnterioresJSON] CHECK ([datos_anteriores] IS NULL OR isjson([datos_anteriores])=(1));
ALTER TABLE [auditoria].[AuditoriaEvento] WITH CHECK ADD CONSTRAINT [CK_AuditoriaEvento_DatosPosterioresJSON] CHECK ([datos_posteriores] IS NULL OR isjson([datos_posteriores])=(1));
ALTER TABLE [auditoria].[AuditoriaEvento] WITH CHECK ADD CONSTRAINT [CK_AuditoriaEvento_Resultado] CHECK ([resultado] IS NULL OR ([resultado]='ERROR_CONTROLADO' OR [resultado]='RECHAZADO' OR [resultado]='EXITOSO'));
ALTER TABLE [auditoria].[OperacionIdempotente] WITH CHECK ADD CONSTRAINT [CK_OperacionIdempotente_EstadoOperacion] CHECK ([estado_operacion]='FALLIDA' OR [estado_operacion]='COMPLETADA' OR [estado_operacion]='EN_PROCESO');
ALTER TABLE [auditoria].[OperacionIdempotente] WITH CHECK ADD CONSTRAINT [CK_OperacionIdempotente_Fechas] CHECK (([fecha_fin] IS NULL OR [fecha_fin]>=[fecha_inicio]) AND ([fecha_expiracion] IS NULL OR [fecha_expiracion]>[fecha_inicio]));
ALTER TABLE [campo].[EvaluacionMateriaSeca] WITH CHECK ADD CONSTRAINT [CK_EvaluacionMateriaSeca_Muestras] CHECK ([numero_muestras]>(0));
ALTER TABLE [campo].[EvaluacionMateriaSeca] WITH CHECK ADD CONSTRAINT [CK_EvaluacionMateriaSeca_Porcentaje] CHECK ([porcentaje_materia_seca]>=(0) AND [porcentaje_materia_seca]<=(100));
ALTER TABLE [campo].[SalidaCampo] WITH CHECK ADD CONSTRAINT [CK_SalidaCampo_EstadoProceso] CHECK ([estado_proceso]='CANCELADA' OR [estado_proceso]='FINALIZADA' OR [estado_proceso]='EN_CURSO' OR [estado_proceso]='PROGRAMADA' OR [estado_proceso]='BORRADOR');
ALTER TABLE [campo].[SalidaCampo] WITH CHECK ADD CONSTRAINT [CK_SalidaCampo_FechasReales] CHECK ([fecha_hora_retorno_real] IS NULL OR [fecha_hora_salida_real] IS NOT NULL AND [fecha_hora_retorno_real]>=[fecha_hora_salida_real]);
ALTER TABLE [campo].[SalidaDestinoE2] WITH CHECK ADD CONSTRAINT [CK_E2_Destino] CHECK ([predio_id] IS NOT NULL OR nullif(ltrim(rtrim([referencia])),N'') IS NOT NULL);
ALTER TABLE [campo].[SalidaE2] WITH CHECK ADD CONSTRAINT [CK_E2_Estado] CHECK ([estado]='ELIMINADA' OR [estado]='CANCELADA' OR [estado]='CERRADA' OR [estado]='EN_RETORNO' OR [estado]='EN_EJECUCION' OR [estado]='RECHAZADA' OR [estado]='APROBADA' OR [estado]='OBSERVADA' OR [estado]='SOLICITADA' OR [estado]='BORRADOR');
ALTER TABLE [campo].[SalidaRecursoE2] WITH CHECK ADD CONSTRAINT [CK_E2_RecursoCantidades] CHECK (([cantidad_devuelta_declarada] IS NULL OR [cantidad_devuelta_declarada]>=(0) AND [cantidad_devuelta_declarada]<=[cantidad_solicitada]) AND ([cantidad_devuelta_validada] IS NULL OR [cantidad_devuelta_validada]>=(0) AND [cantidad_devuelta_validada]<=[cantidad_solicitada]));
ALTER TABLE [campo].[SalidaRecursoE2] WITH CHECK ADD CONSTRAINT [CK_E2_RecursoDeclarado] CHECK ([resultado_declarado] IS NULL OR ([resultado_declarado]='CONSUMIDO' OR [resultado_declarado]='FALTANTE' OR [resultado_declarado]='DANADO' OR [resultado_declarado]='CONFORME'));
ALTER TABLE [campo].[SalidaRecursoE2] WITH CHECK ADD CONSTRAINT [CK_E2_RecursoEstado] CHECK ([estado]='INCIDENCIA' OR [estado]='VALIDADO' OR [estado]='ENTREGADO' OR [estado]='SOLICITADO');
ALTER TABLE [campo].[SalidaRecursoE2] WITH CHECK ADD CONSTRAINT [CK_E2_RecursoTipo] CHECK ([bien_inventario_id] IS NOT NULL AND [suministro_id] IS NULL AND [cantidad_solicitada]=(1) OR [bien_inventario_id] IS NULL AND [suministro_id] IS NOT NULL AND [cantidad_solicitada]>(0));
ALTER TABLE [campo].[SalidaRecursoE2] WITH CHECK ADD CONSTRAINT [CK_E2_RecursoValidado] CHECK ([resultado_validado] IS NULL OR ([resultado_validado]='CONSUMIDO' OR [resultado_validado]='FALTANTE' OR [resultado_validado]='DANADO' OR [resultado_validado]='CONFORME'));
ALTER TABLE [campo].[VisitaTecnica] WITH CHECK ADD CONSTRAINT [CK_VisitaTecnica_EstadoProceso] CHECK ([estado_proceso]='ANULADA' OR [estado_proceso]='FINALIZADA' OR [estado_proceso]='INICIADA');
ALTER TABLE [campo].[VisitaTecnica] WITH CHECK ADD CONSTRAINT [CK_VisitaTecnica_Fechas] CHECK ([fecha_hora_fin] IS NULL OR [fecha_hora_fin]>=[fecha_hora_inicio]);
ALTER TABLE [campo].[VisitaTecnica] WITH CHECK ADD CONSTRAINT [CK_VisitaTecnica_SRID] CHECK ([posicion_inicio] IS NULL OR [posicion_inicio].[STSrid]=(4326));
ALTER TABLE [comercial].[AjustePrecioSocio] WITH CHECK ADD CONSTRAINT [CK_AjustePrecioSocio_EstadoProceso] CHECK ([estado_ajuste]='ANULADO' OR [estado_ajuste]='VIGENTE');
ALTER TABLE [comercial].[AjustePrecioSocio] WITH CHECK ADD CONSTRAINT [CK_AjustePrecioSocio_Porcentaje] CHECK ([porcentaje_ajuste] IS NULL OR [porcentaje_ajuste]>=(0) AND [porcentaje_ajuste]<=(100));
ALTER TABLE [comercial].[AjustePrecioSocio] WITH CHECK ADD CONSTRAINT [CK_AjustePrecioSocio_Precios] CHECK (([precio_original] IS NULL OR [precio_original]>=(0)) AND ([precio_aplicado] IS NULL OR [precio_aplicado]>=(0)));
ALTER TABLE [comercial].[AjustePrecioSocio] WITH CHECK ADD CONSTRAINT [CK_AjustePrecioSocio_Tipo] CHECK ([tipo_ajuste]='SANCION' OR [tipo_ajuste]='BONIFICACION' OR [tipo_ajuste]='DESCUENTO_PORCENTAJE' OR [tipo_ajuste]='DESCUENTO_MONTO' OR [tipo_ajuste]='PRECIO_ESPECIAL');
ALTER TABLE [comercial].[CajaEvidencia] WITH CHECK ADD CONSTRAINT [CK_CajaEvidencia_Fase] CHECK ([fase]='CIERRE' OR [fase]='APERTURA');
ALTER TABLE [comercial].[CajaMovimiento] WITH CHECK ADD CONSTRAINT [CK_CajaMovimiento_Importe] CHECK ([importe]>(0));
ALTER TABLE [comercial].[CajaMovimiento] WITH CHECK ADD CONSTRAINT [CK_CajaMovimiento_Tipo] CHECK ([tipo]='EGRESO' OR [tipo]='INGRESO');
ALTER TABLE [comercial].[CajaSesion] WITH CHECK ADD CONSTRAINT [CK_CajaSesion_Estado] CHECK ([estado]='CERRADA' OR [estado]='ABIERTA');
ALTER TABLE [comercial].[CajaSesion] WITH CHECK ADD CONSTRAINT [CK_CajaSesion_Importes] CHECK ([saldo_inicial]>=(0) AND ([saldo_declarado] IS NULL OR [saldo_declarado]>=(0)));
ALTER TABLE [comercial].[CampaniaCalibre] WITH CHECK ADD CONSTRAINT [CK_CampaniaCalibre_Gramos] CHECK ([gramos_desde]>=(0) AND ([gramos_hasta] IS NULL OR [gramos_hasta]>=[gramos_desde]));
ALTER TABLE [comercial].[CampaniaCalibre] WITH CHECK ADD CONSTRAINT [CK_CampaniaCalibre_Precio] CHECK ([precio_kg]>(0));
ALTER TABLE [comercial].[CampaniaCalibre] WITH CHECK ADD CONSTRAINT [CK_CampaniaCalibre_Tipo] CHECK ([calibre]='DESCARTE' OR [calibre]='SEGUNDA' OR [calibre]='PRIMERA');
ALTER TABLE [comercial].[CampaniaCalibrePrecioVersion] WITH CHECK ADD CONSTRAINT [CK_CampaniaCalibrePrecioVersion_Precio] CHECK ([precio_kg]>(0));
ALTER TABLE [comercial].[CampaniaControlE4] WITH CHECK ADD CONSTRAINT [CK__CampaniaC__cupo___4F2895A9] CHECK ([cupo_jabas]>=(1) AND [cupo_jabas]<=(100000));
ALTER TABLE [comercial].[CampaniaControlE4] WITH CHECK ADD CONSTRAINT [CK__CampaniaC__tara___501CB9E2] CHECK ([tara_kg]>=(0) AND [tara_kg]<(10));
ALTER TABLE [comercial].[CampaniaJabaPlan] WITH CHECK ADD CONSTRAINT [CK_CampaniaJabaPlan_AjustePendiente] CHECK ([cantidad_ajuste_pendiente]=(0) AND [comentario_ajuste_pendiente] IS NULL OR [estado]='ENTREGADA' AND [cantidad_ajuste_pendiente]<>(0) AND (([cantidad]+[cantidad_ajuste_pendiente])>=(0) AND ([cantidad]+[cantidad_ajuste_pendiente])<=(100000)) AND (coalesce(len(Trim([comentario_ajuste_pendiente])),(0))>=(5) AND coalesce(len(Trim([comentario_ajuste_pendiente])),(0))<=(500)));
ALTER TABLE [comercial].[CampaniaJabaPlan] WITH CHECK ADD CONSTRAINT [CK_CampaniaJabaPlan_Cantidad] CHECK ([cantidad]>=(1) AND [cantidad]<=(100000) OR [cantidad]=(0) AND [estado]='DEVUELTA');
ALTER TABLE [comercial].[CampaniaJabaPlan] WITH CHECK ADD CONSTRAINT [CK_CampaniaJabaPlan_Estado] CHECK ([estado]='DEVUELTA' OR [estado]='ENTREGADA' OR [estado]='PENDIENTE_RECOJO');
ALTER TABLE [comercial].[CampaniaJabaPlan] WITH CHECK ADD CONSTRAINT [CK_CampaniaJabaPlan_Fechas] CHECK ([estado]='PENDIENTE_RECOJO' AND [fecha_entrega] IS NULL AND [fecha_devolucion] IS NULL OR [estado]='ENTREGADA' AND [fecha_entrega] IS NOT NULL AND [fecha_devolucion] IS NULL OR [estado]='DEVUELTA' AND [fecha_entrega] IS NOT NULL AND [fecha_devolucion] IS NOT NULL);
ALTER TABLE [comercial].[CampaniaJabaPrecioSancion] WITH CHECK ADD CONSTRAINT [CK_CampaniaJabaPrecioSancion_Precio] CHECK ([precio_original_kg]>(0) AND [descuento_precio_kg]>=(0) AND [precio_final_kg]>(0) AND ([precio_original_kg]-[descuento_precio_kg])=[precio_final_kg]);
ALTER TABLE [comercial].[CampaniaJabaRecepcion] WITH CHECK ADD CONSTRAINT [CK_CampaniaJabaRecepcion_Numero] CHECK ([numero_jaba]>=(1));
ALTER TABLE [comercial].[CampaniaJabaRecepcion] WITH CHECK ADD CONSTRAINT [CK_CampaniaJabaRecepcion_Pesos] CHECK ([peso_bruto_kg]>=(0) AND [descuento_jaba_kg]>=(0) AND ([peso_bruto_kg]=(0) AND [descuento_jaba_kg]=(0) AND [campania_calibre_id] IS NULL OR [peso_bruto_kg]>(0) AND [peso_bruto_kg]>=[descuento_jaba_kg] AND [campania_calibre_id] IS NOT NULL));
ALTER TABLE [comercial].[CampaniaSancionTarifa] WITH CHECK ADD CONSTRAINT [CK_CampaniaSancionTarifa_Descuento] CHECK ([descuento_precio_kg]>(0));
ALTER TABLE [comercial].[CampaniaSocioSancion] WITH CHECK ADD CONSTRAINT [CK_CampaniaSocioSancion_Alcance] CHECK ([alcance]='CANTIDAD' OR [alcance]='TODAS');
ALTER TABLE [comercial].[CampaniaSocioSancion] WITH CHECK ADD CONSTRAINT [CK_CampaniaSocioSancion_Numero] CHECK ([desde_numero]>=(1) AND ([hasta_numero] IS NULL OR [hasta_numero]>=[desde_numero]));
ALTER TABLE [comercial].[CampaniaVenta] WITH CHECK ADD CONSTRAINT [CK_CampaniaVenta_DescuentoJaba] CHECK ([descuento_jaba_kg] IS NULL OR [descuento_jaba_kg]>=(0) AND [descuento_jaba_kg]<=(9.999));
ALTER TABLE [comercial].[CampaniaVenta] WITH CHECK ADD CONSTRAINT [CK_CampaniaVenta_EstadoProceso] CHECK ([estado_proceso]='CANCELADA' OR [estado_proceso]='CERRADA' OR [estado_proceso]='VENCIDA' OR [estado_proceso]='ACTIVA' OR [estado_proceso]='PLANIFICACION');
ALTER TABLE [comercial].[CampaniaVenta] WITH CHECK ADD CONSTRAINT [CK_CampaniaVenta_Fechas] CHECK ([fecha_fin] IS NULL OR [fecha_fin]>=[fecha_inicio]);
ALTER TABLE [comercial].[CampaniaVenta] WITH CHECK ADD CONSTRAINT [CK_CampaniaVenta_OrigenJabas] CHECK ([origen_jabas]='ASOCIACION' OR [origen_jabas]='UOT');
ALTER TABLE [comercial].[CargoIndividualE4] WITH CHECK ADD CONSTRAINT [CK__CargoIndi__canti__77368703] CHECK ([cantidad]>(0));
ALTER TABLE [comercial].[CargoIndividualE4] WITH CHECK ADD CONSTRAINT [CK__CargoIndi__preci__782AAB3C] CHECK ([precio_unitario]>=(0));
ALTER TABLE [comercial].[CargoTarifaE4] WITH CHECK ADD CONSTRAINT [CK__CargoTari__preci__6F95653B] CHECK ([precio_unitario]>=(0));
ALTER TABLE [comercial].[CargoTarifaE4] WITH CHECK ADD CONSTRAINT [CK_CargoTarifaE4_vigencia] CHECK ([vigente_hasta] IS NULL OR [vigente_hasta]>[vigente_desde]);
ALTER TABLE [comercial].[CierreCampaniaE5] WITH CHECK ADD CONSTRAINT [CK_CierreCampaniaE5_Excepcion] CHECK ([excepcion_autorizada]=(0) OR nullif(ltrim(rtrim([motivo_excepcion])),N'') IS NOT NULL);
ALTER TABLE [comercial].[CompradorAPAPPSS] WITH CHECK ADD CONSTRAINT [CK_CompradorAPAPPSS_Tipo] CHECK ([tipo]='PERSONA' AND [persona_id] IS NOT NULL AND [empresa_id] IS NULL OR [tipo]='EMPRESA' AND [persona_id] IS NULL AND [empresa_id] IS NOT NULL);
ALTER TABLE [comercial].[CondicionComercial] WITH CHECK ADD CONSTRAINT [CK_CondicionComercial_Pesos] CHECK (([peso_minimo_g] IS NULL OR [peso_minimo_g]>=(0)) AND ([peso_maximo_g] IS NULL OR [peso_maximo_g]>=(0)) AND ([peso_minimo_g] IS NULL OR [peso_maximo_g] IS NULL OR [peso_maximo_g]>=[peso_minimo_g]));
ALTER TABLE [comercial].[DetalleVenta] WITH CHECK ADD CONSTRAINT [CK_DetalleVenta_Cantidad] CHECK ([cantidad]>(0));
ALTER TABLE [comercial].[DetalleVenta] WITH CHECK ADD CONSTRAINT [CK_DetalleVenta_Precio] CHECK ([precio_unitario]>(0) AND [descuento_unitario]>=(0) AND [descuento_unitario]<[precio_unitario]);
ALTER TABLE [comercial].[DetalleVenta] WITH CHECK ADD CONSTRAINT [CK_DetalleVenta_PrecioInicialReferencia] CHECK ([precio_inicial_referencia]>=(0));
ALTER TABLE [comercial].[EntregaDetalle] WITH CHECK ADD CONSTRAINT [CK_EntregaDetalle_Kilogramos] CHECK ([kilogramos]>(0));
ALTER TABLE [comercial].[EntregaDetalle] WITH CHECK ADD CONSTRAINT [CK_EntregaDetalle_Precios] CHECK ([precio_base]>=(0) AND [precio_aplicado]>=(0));
ALTER TABLE [comercial].[EntregaSocio] WITH CHECK ADD CONSTRAINT [CK_EntregaSocio_ControlCalidad] CHECK ([estado_control_calidad]='RECHAZADO' OR [estado_control_calidad]='OBSERVADO' OR [estado_control_calidad]='CONFORME' OR [estado_control_calidad]='PENDIENTE');
ALTER TABLE [comercial].[EntregaSocio] WITH CHECK ADD CONSTRAINT [CK_EntregaSocio_EstadoProceso] CHECK ([estado_proceso]='ANULADA' OR [estado_proceso]='CONFIRMADA' OR [estado_proceso]='REGISTRADA');
ALTER TABLE [comercial].[EntregaSocio] WITH CHECK ADD CONSTRAINT [CK_EntregaSocio_Pesos] CHECK ([peso_bruto_kg]>(0) AND [tara_kg]>=(0) AND [tara_kg]<[peso_bruto_kg] AND [peso_rechazado_kg]>=(0) AND [peso_rechazado_kg]<=([peso_bruto_kg]-[tara_kg]));
ALTER TABLE [comercial].[Factura] WITH CHECK ADD CONSTRAINT [CK_Factura_RUC] CHECK (len([cliente_ruc])=(11) AND NOT [cliente_ruc] like '%[^0-9]%');
ALTER TABLE [comercial].[HorarioAtencionUOT] WITH CHECK ADD CONSTRAINT [CK_HorarioAtencion_Rango] CHECK ([hora_inicio]<[hora_fin]);
ALTER TABLE [comercial].[HorarioEmpleadoPOS] WITH CHECK ADD CONSTRAINT [CK_HorarioPOS_Dia] CHECK ([dia_semana]>=(1) AND [dia_semana]<=(7));
ALTER TABLE [comercial].[HorarioEmpleadoPOS] WITH CHECK ADD CONSTRAINT [CK_HorarioPOS_Horas] CHECK ([hora_inicio]<[hora_fin]);
ALTER TABLE [comercial].[IncidenciaFaltanteE4] WITH CHECK ADD CONSTRAINT [CK__Incidenci__canti__7ED7A8CB] CHECK ([cantidad]>(0));
ALTER TABLE [comercial].[IncidenciaFaltanteE4] WITH CHECK ADD CONSTRAINT [CK__Incidenci__estad__00BFF13D] CHECK ([estado]='CONFIRMADA' OR [estado]='REGISTRADA');
ALTER TABLE [comercial].[IncidenciaOperativa] WITH CHECK ADD CONSTRAINT [CK_IncidenciaOperativa_EstadoProceso] CHECK ([estado_incidencia]='ANULADA' OR [estado_incidencia]='RESUELTA' OR [estado_incidencia]='EN_REVISION' OR [estado_incidencia]='ABIERTA');
ALTER TABLE [comercial].[IncidenciaOperativa] WITH CHECK ADD CONSTRAINT [CK_IncidenciaOperativa_Peso] CHECK ([peso_afectado_kg] IS NULL OR [peso_afectado_kg]>=(0));
ALTER TABLE [comercial].[IncidenciaOperativa] WITH CHECK ADD CONSTRAINT [CK_IncidenciaOperativa_Severidad] CHECK ([severidad]='ALTA' OR [severidad]='MEDIA' OR [severidad]='BAJA');
ALTER TABLE [comercial].[IncidenciaOperativa] WITH CHECK ADD CONSTRAINT [CK_IncidenciaOperativa_Tipo] CHECK ([tipo_incidencia]='OTRO' OR [tipo_incidencia]='DOCUMENTACION' OR [tipo_incidencia]='TRANSPORTE' OR [tipo_incidencia]='EQUIPO' OR [tipo_incidencia]='JABAS' OR [tipo_incidencia]='PESO' OR [tipo_incidencia]='MERMA' OR [tipo_incidencia]='CALIDAD');
ALTER TABLE [comercial].[JabaAsignacion] WITH CHECK ADD CONSTRAINT [CK_DESCO_JabaAsignacion_Devuelta] CHECK ([cantidad_devuelta]>=(0) AND [cantidad_devuelta]<=[cantidad_asignada]);
ALTER TABLE [comercial].[JabaAsignacion] WITH CHECK ADD CONSTRAINT [CK_JabaAsignacion_Cantidad] CHECK ([cantidad_asignada]>(0));
ALTER TABLE [comercial].[JabaClasificacionE4] WITH CHECK ADD CONSTRAINT [CK__JabaClasi__numer__100234CD] CHECK ([numero]>(0));
ALTER TABLE [comercial].[JabaClasificacionE4] WITH CHECK ADD CONSTRAINT [CK__JabaClasi__peso___10F65906] CHECK ([peso_kg]>(0));
ALTER TABLE [comercial].[JabaClasificacionE4] WITH CHECK ADD CONSTRAINT [CK_JabaClasificacionE4_Tipo] CHECK ([rechazada]=(1) AND [precio_comercial_id] IS NULL AND [precio_base] IS NULL OR [rechazada]=(0) AND [variedad_palta_id] IS NOT NULL AND [condicion_comercial_id] IS NOT NULL AND [precio_comercial_id] IS NOT NULL AND [precio_base]>=(0));
ALTER TABLE [comercial].[JabaDevolucion] WITH CHECK ADD CONSTRAINT [CK_JabaDevolucion_Cantidades] CHECK ([cantidad_llenas]>=(0) AND [cantidad_vacias]>=(0) AND ([cantidad_llenas]+[cantidad_vacias])>(0));
ALTER TABLE [comercial].[JabaMovimiento] WITH CHECK ADD CONSTRAINT [CK_JabaMovimiento_Cantidad] CHECK ([cantidad]>(0));
ALTER TABLE [comercial].[JabaMovimiento] WITH CHECK ADD CONSTRAINT [CK_JabaMovimiento_Tipo] CHECK ([tipo_movimiento]='AJUSTE_SALIDA' OR [tipo_movimiento]='AJUSTE_ENTRADA' OR [tipo_movimiento]='DEVOLUCION_VACIA' OR [tipo_movimiento]='DEVOLUCION_LLENA' OR [tipo_movimiento]='ASIGNACION' OR [tipo_movimiento]='RECEPCION');
ALTER TABLE [comercial].[JabaRetornoValidadoE4] WITH CHECK ADD CONSTRAINT [CK__JabaRetor__canti__3F7C3DC5] CHECK ([cantidad_validada]>=(0));
ALTER TABLE [comercial].[JabaSaldoOperativo] WITH CHECK ADD CONSTRAINT [CK_DESCO_JabaSaldo_NoNegativo] CHECK ([recibidas]>=(0) AND [recibidas]<=(2147483647) AND ([asignadas]>=(0) AND [asignadas]<=(2147483647)) AND [devueltas_llenas]>=(0) AND [devueltas_vacias]>=(0) AND [asignadas]>=([devueltas_llenas]+[devueltas_vacias]) AND (([recibidas]-[asignadas])+[devueltas_vacias])>=(0));
ALTER TABLE [comercial].[JabaStockUotE4] WITH CHECK ADD CONSTRAINT [CK__JabaStock__exist__35F2D38B] CHECK ([existencia_certificada]>=(0));
ALTER TABLE [comercial].[JabaUnidadE4] WITH CHECK ADD CONSTRAINT [CK__JabaUnida__numer__56C9B771] CHECK ([numero]>(0));
ALTER TABLE [comercial].[JabaUnidadE4] WITH CHECK ADD CONSTRAINT [CK_JabaUnidadE4_pesaje] CHECK (([pesaje_estado]='ANULADA' OR [pesaje_estado]='PESADA' OR [pesaje_estado]='PRELIMINAR' OR [pesaje_estado]='SIN_PESAJE') AND ([retorno_estado]='FALTANTE' OR [retorno_estado]='DEVUELTA_VACIA' OR [retorno_estado]='DEVUELTA_LLENA' OR [retorno_estado]='PENDIENTE') AND (([pesaje_estado]='ANULADA' OR [pesaje_estado]='SIN_PESAJE') AND [peso_bruto_kg] IS NULL AND [tara_kg] IS NULL AND [precio_base] IS NULL AND [precio_comercial_id] IS NULL OR [pesaje_estado]='PRELIMINAR' AND [peso_bruto_kg]>[tara_kg] AND [tara_kg]>=(0) AND [precio_base] IS NULL AND [precio_comercial_id] IS NULL OR [pesaje_estado]='PESADA' AND [peso_bruto_kg]>[tara_kg] AND [tara_kg]>=(0) AND [variedad_palta_id] IS NOT NULL AND [condicion_comercial_id] IS NOT NULL AND [precio_base]>=(0)));
ALTER TABLE [comercial].[OperativoSocio] WITH CHECK ADD CONSTRAINT [CK_OperativoSocio_EstadoProceso] CHECK ([estado_participacion]='RETIRADO' OR [estado_participacion]='NO_PARTICIPO' OR [estado_participacion]='PARTICIPO' OR [estado_participacion]='PROGRAMADO');
ALTER TABLE [comercial].[OperativoVenta] WITH CHECK ADD CONSTRAINT [CK_OperativoVenta_EstadoProceso] CHECK ([estado_proceso]='CANCELADO' OR [estado_proceso]='CERRADO' OR [estado_proceso]='EN_RECEPCION' OR [estado_proceso]='PLANIFICADO');
ALTER TABLE [comercial].[OperativoVenta] WITH CHECK ADD CONSTRAINT [CK_OperativoVenta_FechasProgramadas] CHECK ([fecha_fin_programada] IS NULL OR [fecha_fin_programada]>=[fecha_inicio_programada]);
ALTER TABLE [comercial].[OperativoVenta] WITH CHECK ADD CONSTRAINT [CK_OperativoVenta_FechasReales] CHECK ([fecha_fin_real] IS NULL OR [fecha_inicio_real] IS NOT NULL AND [fecha_fin_real]>=[fecha_inicio_real]);
ALTER TABLE [comercial].[OperativoVenta] WITH CHECK ADD CONSTRAINT [CK_OperativoVenta_Jabas] CHECK ([cantidad_jabas_recibidas]>=(0));
ALTER TABLE [comercial].[PagoVenta] WITH CHECK ADD CONSTRAINT [CK_PagoVenta_EstadoPago] CHECK ([estado_pago]='ANULADO' OR [estado_pago]='CONFIRMADO');
ALTER TABLE [comercial].[PagoVenta] WITH CHECK ADD CONSTRAINT [CK_PagoVenta_Importe] CHECK ([importe]>(0));
ALTER TABLE [comercial].[ParticipacionCampaniaSocio] WITH CHECK ADD CONSTRAINT [CK_ParticipacionCampaniaSocio_EstadoProceso] CHECK ([estado_participacion]='EXCLUIDO' OR [estado_participacion]='RETIRADO' OR [estado_participacion]='ACTIVO');
ALTER TABLE [comercial].[PrecioComercial] WITH CHECK ADD CONSTRAINT [CK_PrecioComercial_Fechas] CHECK ([fecha_vigencia_hasta] IS NULL OR [fecha_vigencia_hasta]>=[fecha_vigencia_desde]);
ALTER TABLE [comercial].[PrecioComercial] WITH CHECK ADD CONSTRAINT [CK_PrecioComercial_Moneda] CHECK (NOT [moneda] like '%[^A-Z]%');
ALTER TABLE [comercial].[PrecioComercial] WITH CHECK ADD CONSTRAINT [CK_PrecioComercial_Precio] CHECK ([precio]>=(0));
ALTER TABLE [comercial].[PrecioComercial] WITH CHECK ADD CONSTRAINT [CK_PrecioComercial_Unidad] CHECK ([unidad_medida]='UNIDAD' OR [unidad_medida]='TN' OR [unidad_medida]='KG');
ALTER TABLE [comercial].[PrecioComercial] WITH CHECK ADD CONSTRAINT [CK_PrecioComercial_Version] CHECK ([version]>(0));
ALTER TABLE [comercial].[SancionSocioE4] WITH CHECK ADD CONSTRAINT [CK__SancionSo__kilos__6423B28F] CHECK ([kilos_afectados]>(0));
ALTER TABLE [comercial].[SancionSocioE4] WITH CHECK ADD CONSTRAINT [CK__SancionSo__preci__6517D6C8] CHECK ([precio_original]>=(0));
ALTER TABLE [comercial].[SancionSocioE4] WITH CHECK ADD CONSTRAINT [CK__SancionSo__preci__660BFB01] CHECK ([precio_nuevo]>=(0));
ALTER TABLE [comercial].[SancionSocioE4] WITH CHECK ADD CONSTRAINT [CK_SancionSocioE4_Precio] CHECK ([precio_nuevo]<=[precio_original]);
ALTER TABLE [comercial].[Venta] WITH CHECK ADD CONSTRAINT [CK_Venta_Cliente] CHECK ((case when [cliente_persona_id] IS NULL then (0) else (1) end+case when [cliente_empresa_id] IS NULL then (0) else (1) end)<=(1));
ALTER TABLE [comercial].[Venta] WITH CHECK ADD CONSTRAINT [CK_Venta_EstadoVenta] CHECK ([estado_venta]='ANULADA' OR [estado_venta]='ENTREGADA' OR [estado_venta]='PAGADA' OR [estado_venta]='PAGO_PARCIAL' OR [estado_venta]='SEPARADA' OR [estado_venta]='REGISTRADA');
ALTER TABLE [comercial].[Venta] WITH CHECK ADD CONSTRAINT [CK_Venta_Montos] CHECK ([subtotal]>=(0) AND [descuento]>=(0) AND [impuesto]>=(0) AND [total]>=(0));
ALTER TABLE [comercial].[VentaAnulacionPOS] WITH CHECK ADD CONSTRAINT [CK_VentaAnulacionPOS_Monto] CHECK ([importe_reintegrado]>=(0));
ALTER TABLE [config].[CatalogoRecursoValor] WITH CHECK ADD CONSTRAINT [CK_CatalogoRecursoValor_Catalogo] CHECK ([catalogo]='TIPO_TITULARIDAD_PREDIO' OR [catalogo]='CARGO_EMPLEADO' OR [catalogo]='MONEDA' OR [catalogo]='CATEGORIA_PRODUCTO' OR [catalogo]='UNIDAD_MEDIDA' OR [catalogo]='TIPO_VEHICULO');
ALTER TABLE [config].[DashboardElemento] WITH CHECK ADD CONSTRAINT [CK_DashboardElemento_Ancho] CHECK ([ancho]>=(1) AND [ancho]<=(2));
ALTER TABLE [config].[DashboardElemento] WITH CHECK ADD CONSTRAINT [CK_DashboardElemento_Grafico] CHECK ([tipo]='KPI' AND [tipo_grafico] IS NULL OR [tipo]='GRAFICO' AND ([tipo_grafico]='DONUT' OR [tipo_grafico]='COLUMN' OR [tipo_grafico]='BAR' OR [tipo_grafico]='AREA' OR [tipo_grafico]='LINE'));
ALTER TABLE [config].[DashboardElemento] WITH CHECK ADD CONSTRAINT [CK_DashboardElemento_Orden] CHECK ([orden]>=(0));
ALTER TABLE [config].[DashboardElemento] WITH CHECK ADD CONSTRAINT [CK_DashboardElemento_Tipo] CHECK ([tipo]='GRAFICO' OR [tipo]='KPI');
ALTER TABLE [config].[DashboardRolElemento] WITH CHECK ADD CONSTRAINT [CK_DashboardRolElemento_Orden] CHECK ([orden] IS NULL OR [orden]>=(0));
ALTER TABLE [config].[DashboardUsuarioElemento] WITH CHECK ADD CONSTRAINT [CK_DashboardUsuarioElemento_Orden] CHECK ([orden] IS NULL OR [orden]>=(0));
ALTER TABLE [config].[MensajeUsuario] WITH CHECK ADD CONSTRAINT [CK_DESCO_MensajeUsuario_Http] CHECK ([http_error]>=(400) AND [http_error]<=(599));
ALTER TABLE [config].[RespuestaBaseDatos] WITH CHECK ADD CONSTRAINT [CK_DESCO_Respuesta_Http] CHECK ([http_sugerido]>=(100) AND [http_sugerido]<=(599));
ALTER TABLE [config].[TipoDocumentoComprador] WITH CHECK ADD CONSTRAINT [CK_TipoDocumentoComprador_Codigo] CHECK (len([codigo])>=(2) AND len([codigo])<=(15) AND NOT [codigo] like '%[^A-Z0-9_]%');
ALTER TABLE [finanzas].[CobroComprador] WITH CHECK ADD CONSTRAINT [CK_CobroComprador_EstadoProceso] CHECK ([estado_proceso]='ANULADO' OR [estado_proceso]='CONFIRMADO' OR [estado_proceso]='REGISTRADO');
ALTER TABLE [finanzas].[CobroComprador] WITH CHECK ADD CONSTRAINT [CK_CobroComprador_Importe] CHECK ([importe]>(0));
ALTER TABLE [finanzas].[CobroComprador] WITH CHECK ADD CONSTRAINT [CK_CobroComprador_Moneda] CHECK (NOT [moneda] like '%[^A-Z]%');
ALTER TABLE [finanzas].[EventoPagoE5] WITH CHECK ADD CONSTRAINT [CK__EventoPag__accio__5FE90D57] CHECK ([accion]='REVERSAR' OR [accion]='PAGAR');
ALTER TABLE [finanzas].[GastoCampania] WITH CHECK ADD CONSTRAINT [CK_GastoCampania_EstadoProceso] CHECK ([estado_proceso]='ANULADO' OR [estado_proceso]='APROBADO' OR [estado_proceso]='REGISTRADO');
ALTER TABLE [finanzas].[GastoCampania] WITH CHECK ADD CONSTRAINT [CK_GastoCampania_Importe] CHECK ([importe]>(0));
ALTER TABLE [finanzas].[GastoCampania] WITH CHECK ADD CONSTRAINT [CK_GastoCampania_Moneda] CHECK (NOT [moneda] like '%[^A-Z]%');
ALTER TABLE [finanzas].[GastoProrrateoSocio] WITH CHECK ADD CONSTRAINT [CK_GastoProrrateoSocio_Importe] CHECK ([importe_asignado]>=(0));
ALTER TABLE [finanzas].[GastoRepartoLineaE5] WITH CHECK ADD CONSTRAINT [CK__GastoRepa__monto__565FA31D] CHECK ([monto]>=(0));
ALTER TABLE [finanzas].[GastoRepartoVersionE5] WITH CHECK ADD CONSTRAINT [CK__GastoRepa__estad__50A6C9C7] CHECK ([estado]='RECTIFICADO' OR [estado]='APROBADO' OR [estado]='PROPUESTO');
ALTER TABLE [finanzas].[GastoRepartoVersionE5] WITH CHECK ADD CONSTRAINT [CK__GastoRepa__vende__4FB2A58E] CHECK ([vendedores]>(0));
ALTER TABLE [finanzas].[LiquidacionDetalle] WITH CHECK ADD CONSTRAINT [CK_LiquidacionDetalle_Tipo] CHECK ([tipo]='OTRO' OR [tipo]='BONIFICACION' OR [tipo]='AJUSTE' OR [tipo]='GASTO' OR [tipo]='VENTA');
ALTER TABLE [finanzas].[LiquidacionDetalle] WITH CHECK ADD CONSTRAINT [CK_LiquidacionDetalle_UnOrigen] CHECK (((case when [entrega_detalle_id] IS NULL then (0) else (1) end+case when [gasto_prorrateo_socio_id] IS NULL then (0) else (1) end)+case when [ajuste_precio_socio_id] IS NULL then (0) else (1) end)<=(1));
ALTER TABLE [finanzas].[LiquidacionSocio] WITH CHECK ADD CONSTRAINT [CK_LiquidacionSocio_EstadoProceso] CHECK ([estado_proceso]='ANULADA' OR [estado_proceso]='PAGADA' OR [estado_proceso]='PAGADA_PARCIAL' OR [estado_proceso]='APROBADA' OR [estado_proceso]='OBSERVADA' OR [estado_proceso]='CALCULADA' OR [estado_proceso]='BORRADOR');
ALTER TABLE [finanzas].[LiquidacionSocio] WITH CHECK ADD CONSTRAINT [CK_LiquidacionSocio_Importes] CHECK ([importe_bruto]>=(0) AND [total_gastos]>=(0) AND [total_bonificaciones]>=(0));
ALTER TABLE [finanzas].[LiquidacionSocio] WITH CHECK ADD CONSTRAINT [CK_LiquidacionSocio_Moneda] CHECK (NOT [moneda] like '%[^A-Z]%');
ALTER TABLE [finanzas].[LiquidacionSocio] WITH CHECK ADD CONSTRAINT [CK_LiquidacionSocio_Version] CHECK ([version]>(0));
ALTER TABLE [finanzas].[PagoSocio] WITH CHECK ADD CONSTRAINT [CK_PagoSocio_EstadoProceso] CHECK ([estado_proceso]='ANULADO' OR [estado_proceso]='CONFIRMADO' OR [estado_proceso]='REGISTRADO');
ALTER TABLE [finanzas].[PagoSocio] WITH CHECK ADD CONSTRAINT [CK_PagoSocio_Importe] CHECK ([importe]>(0));
ALTER TABLE [geo].[Ubicacion] WITH CHECK ADD CONSTRAINT [CK_Ubicacion_SRID] CHECK ([posicion] IS NULL OR [posicion].[STSrid]=(4326));
ALTER TABLE [geo].[ZonaProductivaPredio] WITH CHECK ADD CONSTRAINT [CK_ZonaProductivaPredio_Fechas] CHECK ([fecha_hasta] IS NULL OR [fecha_hasta]>=[fecha_desde]);
ALTER TABLE [geo].[ZonaProductivaUbicacion] WITH CHECK ADD CONSTRAINT [CK_ZonaProductivaUbicacion_Fechas] CHECK ([fecha_hasta] IS NULL OR [fecha_hasta]>=[fecha_desde]);
ALTER TABLE [geo].[ZonaProductivaUbicacion] WITH CHECK ADD CONSTRAINT [CK_ZonaProductivaUbicacion_Nivel] CHECK ([distrito_codigo] IS NOT NULL AND [centro_poblado_id] IS NULL OR [distrito_codigo] IS NULL AND [centro_poblado_id] IS NOT NULL);
ALTER TABLE [integracion].[ConsultaDocumento] WITH CHECK ADD CONSTRAINT [CK_ConsultaDocumento_Entidad] CHECK ([entidad_objetivo]='EMPRESA' OR [entidad_objetivo]='PERSONA');
ALTER TABLE [integracion].[ConsultaDocumento] WITH CHECK ADD CONSTRAINT [CK_ConsultaDocumento_Estado] CHECK ([estado_consulta]='DATOS_INSUFICIENTES' OR [estado_consulta]='ERROR' OR [estado_consulta]='NO_ENCONTRADO' OR [estado_consulta]='EXITO' OR [estado_consulta]='RESERVADA' OR [estado_consulta]='PENDIENTE');
ALTER TABLE [integracion].[ConsultaDocumento] WITH CHECK ADD CONSTRAINT [CK_ConsultaDocumento_Intentos] CHECK ([cantidad_intentos]>=(0));
ALTER TABLE [logistica].[AlmacenProductoStock] WITH CHECK ADD CONSTRAINT [CK_AlmacenProductoStock_InactivoSinSaldo] CHECK ([estado]=(1) OR [stock_actual]=(0) AND [stock_reservado]=(0));
ALTER TABLE [logistica].[AlmacenProductoStock] WITH CHECK ADD CONSTRAINT [CK_Stock_NoNegativo] CHECK ([stock_actual]>=(0) AND [stock_reservado]>=(0) AND [stock_reservado]<=[stock_actual] AND [stock_minimo]>=(0));
ALTER TABLE [logistica].[AlmacenUOT] WITH CHECK ADD CONSTRAINT [CK_AlmacenUOT_Fechas] CHECK ([fecha_hasta] IS NULL OR [fecha_hasta]>=[fecha_desde]);
ALTER TABLE [logistica].[AlmacenUOT] WITH CHECK ADD CONSTRAINT [CK_AlmacenUOT_Tipo] CHECK ([tipo_acceso]='COMPARTIDO' OR [tipo_acceso]='PROPIETARIO');
ALTER TABLE [logistica].[BienEstadoHistorial] WITH CHECK ADD CONSTRAINT [CK_BienEstadoHistorial_Fechas] CHECK ([fecha_hasta] IS NULL OR [fecha_hasta]>=[fecha_desde]);
ALTER TABLE [logistica].[BienIncidente] WITH CHECK ADD CONSTRAINT [CK_BienIncidente_Costos] CHECK (([costo_estimado] IS NULL OR [costo_estimado]>=(0)) AND ([costo_real] IS NULL OR [costo_real]>=(0)));
ALTER TABLE [logistica].[BienIncidente] WITH CHECK ADD CONSTRAINT [CK_BienIncidente_EstadoInc] CHECK ([estado_incidente]='ANULADO' OR [estado_incidente]='CERRADO' OR [estado_incidente]='RESUELTO' OR [estado_incidente]='EN_ATENCION' OR [estado_incidente]='ABIERTO');
ALTER TABLE [logistica].[BienIncidente] WITH CHECK ADD CONSTRAINT [CK_BienIncidente_Tipo] CHECK ([tipo_incidente]='OTRO' OR [tipo_incidente]='MANTENIMIENTO' OR [tipo_incidente]='ROBO' OR [tipo_incidente]='PERDIDA' OR [tipo_incidente]='ACCIDENTE' OR [tipo_incidente]='AVERIA');
ALTER TABLE [logistica].[BienInventario] WITH CHECK ADD CONSTRAINT [CK_BienInventario_Adquisicion] CHECK ([monto_adquisicion] IS NULL OR [monto_adquisicion]>=(0));
ALTER TABLE [logistica].[BienInventario] WITH CHECK ADD CONSTRAINT [CK_BienInventario_EstadoProceso] CHECK ([estado_bien]='PENDIENTE_PLACA' OR [estado_bien]='NO_DISPONIBLE' OR [estado_bien]='BAJA' OR [estado_bien]='INACTIVO' OR [estado_bien]='AVERIADO' OR [estado_bien]='MANTENIMIENTO' OR [estado_bien]='ASIGNADO' OR [estado_bien]='DISPONIBLE');
ALTER TABLE [logistica].[BienInventario] WITH CHECK ADD CONSTRAINT [CK_BienInventario_Proveedor] CHECK (NOT ([proveedor_persona_id] IS NOT NULL AND [proveedor_empresa_id] IS NOT NULL));
ALTER TABLE [logistica].[DetalleMovimientoInventario] WITH CHECK ADD CONSTRAINT [CK_DetMovInv_Cantidad] CHECK ([cantidad]>(0));
ALTER TABLE [logistica].[DetalleMovimientoInventario] WITH CHECK ADD CONSTRAINT [CK_DetMovInv_Costo] CHECK ([costo_unitario] IS NULL OR [costo_unitario]>=(0));
ALTER TABLE [logistica].[EntregaTecnicaDetalle] WITH CHECK ADD CONSTRAINT [CK_EntregaTecnicaDetalle_Cantidad] CHECK ([cantidad]>(0));
ALTER TABLE [logistica].[MovimientoInventario] WITH CHECK ADD CONSTRAINT [CK_MovInv_Naturaleza] CHECK ([naturaleza]='S' OR [naturaleza]='E');
ALTER TABLE [logistica].[MovimientoInventario] WITH CHECK ADD CONSTRAINT [CK_MovInv_Proveedor] CHECK (NOT ([proveedor_persona_id] IS NOT NULL AND [proveedor_empresa_id] IS NOT NULL));
ALTER TABLE [logistica].[MovimientoInventario] WITH CHECK ADD CONSTRAINT [CK_MovInv_Tipo] CHECK ([tipo_movimiento]='USO_TECNICO' OR [tipo_movimiento]='OTRO' OR [tipo_movimiento]='MERMA' OR [tipo_movimiento]='AJUSTE' OR [tipo_movimiento]='TRANSFERENCIA' OR [tipo_movimiento]='CONSUMO' OR [tipo_movimiento]='VENTA' OR [tipo_movimiento]='DEVOLUCION' OR [tipo_movimiento]='DONACION' OR [tipo_movimiento]='COMPRA');
ALTER TABLE [logistica].[MovimientoInventarioLote] WITH CHECK ADD CONSTRAINT [CK__Movimient__canti__5ABA43E6] CHECK ([cantidad]>(0));
ALTER TABLE [logistica].[ProductoPrecio] WITH CHECK ADD CONSTRAINT [CK_ProductoPrecio_Fechas] CHECK ([fecha_hasta] IS NULL OR [fecha_hasta]>=[fecha_desde]);
ALTER TABLE [logistica].[ProductoPrecio] WITH CHECK ADD CONSTRAINT [CK_ProductoPrecio_Precio] CHECK ([precio_venta]>(0));
ALTER TABLE [logistica].[ProductoPrecio] WITH CHECK ADD CONSTRAINT [CK_ProductoPrecio_PrecioInicial] CHECK ([precio_inicial]>=(0));
ALTER TABLE [logistica].[ProgramacionProducto] WITH CHECK ADD CONSTRAINT [CK_DESCO_PP_Cantidades] CHECK ([cantidad_programada]>(0) AND [cantidad_entregada]>=(0) AND [cantidad_devuelta]>=(0) AND [cantidad_consumida]>=(0) AND [cantidad_entregada]<=[cantidad_programada] AND ([cantidad_devuelta]+[cantidad_consumida])<=[cantidad_entregada]);
ALTER TABLE [logistica].[ProgramacionProducto] WITH CHECK ADD CONSTRAINT [CK_DESCO_PP_Estados] CHECK ([estado_proceso]='CANCELADA' OR [estado_proceso]='RECHAZADA' OR [estado_proceso]='FINALIZADA' OR [estado_proceso]='ENTREGADA' OR [estado_proceso]='APROBADA' OR [estado_proceso]='PENDIENTE');
ALTER TABLE [logistica].[ProgramacionProducto] WITH CHECK ADD CONSTRAINT [CK_DESCO_PP_Fechas] CHECK ([fecha_fin] IS NULL OR [fecha_fin]>=[fecha_inicio]);
ALTER TABLE [logistica].[RecursoMovimiento] WITH CHECK ADD CONSTRAINT [CK_RecursoMovimiento_Cantidad] CHECK ([cantidad]>(0));
ALTER TABLE [logistica].[RecursoMovimiento] WITH CHECK ADD CONSTRAINT [CK_RecursoMovimiento_Tipo] CHECK ([tipo_movimiento]='AJUSTE' OR [tipo_movimiento]='CONSUMO' OR [tipo_movimiento]='DEVOLUCION' OR [tipo_movimiento]='ENTREGA' OR [tipo_movimiento]='ASIGNACION');
ALTER TABLE [logistica].[RecursoProgramado] WITH CHECK ADD CONSTRAINT [CK_DESCO_Recurso_Cantidades] CHECK ([cantidad_entregada]>=(0) AND [cantidad_devuelta]>=(0) AND [cantidad_consumida]>=(0) AND [cantidad_entregada]<=[cantidad_programada] AND ([cantidad_devuelta]+[cantidad_consumida])<=[cantidad_entregada]);
ALTER TABLE [logistica].[RecursoProgramado] WITH CHECK ADD CONSTRAINT [CK_RecursoProgramado_Cantidad] CHECK ([cantidad_programada]>(0) AND ([bien_inventario_id] IS NULL OR [cantidad_programada]=(1)));
ALTER TABLE [logistica].[RecursoProgramado] WITH CHECK ADD CONSTRAINT [CK_RecursoProgramado_EstadoProceso] CHECK ([estado_proceso]='CANCELADO' OR [estado_proceso]='COMPLETADO' OR [estado_proceso]='EN_EJECUCION' OR [estado_proceso]='PROGRAMADO');
ALTER TABLE [logistica].[RecursoProgramado] WITH CHECK ADD CONSTRAINT [CK_RecursoProgramado_UnDestino] CHECK (((case when [campania_venta_id] IS NULL then (0) else (1) end+case when [operativo_venta_id] IS NULL then (0) else (1) end)+case when [salida_campo_id] IS NULL then (0) else (1) end)=(1));
ALTER TABLE [logistica].[RecursoProgramado] WITH CHECK ADD CONSTRAINT [CK_RecursoProgramado_UnRecurso] CHECK ((case when [bien_inventario_id] IS NULL then (0) else (1) end+case when [suministro_id] IS NULL then (0) else (1) end)=(1));
ALTER TABLE [logistica].[ReservaStock] WITH CHECK ADD CONSTRAINT [CK_ReservaStock_Cantidad] CHECK ([cantidad]>(0));
ALTER TABLE [logistica].[ReservaStock] WITH CHECK ADD CONSTRAINT [CK_ReservaStock_EstadoReserva] CHECK ([estado_reserva]='VENCIDA' OR [estado_reserva]='LIBERADA' OR [estado_reserva]='CONSUMIDA' OR [estado_reserva]='ACTIVA');
ALTER TABLE [logistica].[SalidaBien] WITH CHECK ADD CONSTRAINT [CK_SalidaBien_Fechas] CHECK ([fecha_hora_devolucion] IS NULL OR [fecha_hora_devolucion]>=[fecha_hora_entrega]);
ALTER TABLE [logistica].[Suministro] WITH CHECK ADD CONSTRAINT [CK_DESCO_Suministro_Minimo] CHECK ([stock_minimo]>=(0));
ALTER TABLE [logistica].[Suministro] WITH CHECK ADD CONSTRAINT [CK_Suministro_Unidad] CHECK ([unidad_medida]='OTRO' OR [unidad_medida]='CAJA' OR [unidad_medida]='PAQUETE' OR [unidad_medida]='PAR' OR [unidad_medida]='ML' OR [unidad_medida]='L' OR [unidad_medida]='G' OR [unidad_medida]='KG' OR [unidad_medida]='UND');
ALTER TABLE [logistica].[SuministroMovimiento] WITH CHECK ADD CONSTRAINT [CK_SuministroMovimiento_Cantidad] CHECK ([cantidad]>(0));
ALTER TABLE [logistica].[SuministroMovimiento] WITH CHECK ADD CONSTRAINT [CK_SuministroMovimiento_Tipo] CHECK ([tipo_movimiento]='TRANSFERENCIA_SALIDA' OR [tipo_movimiento]='TRANSFERENCIA_ENTRADA' OR [tipo_movimiento]='AJUSTE_SALIDA' OR [tipo_movimiento]='AJUSTE_ENTRADA' OR [tipo_movimiento]='DEVOLUCION' OR [tipo_movimiento]='SALIDA' OR [tipo_movimiento]='ENTRADA');
ALTER TABLE [logistica].[SuministroSaldo] WITH CHECK ADD CONSTRAINT [CK_DESCO_SuministroSaldo_NoNegativo] CHECK ([stock_actual]>=(0) AND [stock_reservado]>=(0));
ALTER TABLE [logistica].[SuministroSaldo] WITH CHECK ADD CONSTRAINT [CK_DESCO_SuministroSaldo_Reserva] CHECK ([stock_actual]>=[stock_reservado]);
ALTER TABLE [logistica].[UsoProductoTecnico] WITH CHECK ADD CONSTRAINT [CK__UsoProduc__canti__600908E8] CHECK ([cantidad]>(0));
ALTER TABLE [logistica].[Vehiculo] WITH CHECK ADD CONSTRAINT [CK_Vehiculo_Kilometraje] CHECK ([kilometraje_km] IS NULL OR [kilometraje_km]>=(0));
ALTER TABLE [org].[ConvenioUOTOrganizacion] WITH CHECK ADD CONSTRAINT [CK_ConvenioUOT_Fechas] CHECK ([fecha_fin] IS NULL OR [fecha_inicio] IS NULL OR [fecha_fin]>=[fecha_inicio]);
ALTER TABLE [org].[ConvenioUOTOrganizacion] WITH CHECK ADD CONSTRAINT [CK_ConvenioUOT_Tipo] CHECK ([tipo_vinculo]='OTRO' OR [tipo_vinculo]='ONG' OR [tipo_vinculo]='EMPRESA' OR [tipo_vinculo]='ASOCIACION');
ALTER TABLE [org].[Empleado] WITH CHECK ADD CONSTRAINT [CK_Empleado_Fechas] CHECK ([fecha_cese] IS NULL OR [fecha_cese]>=[fecha_ingreso]);
ALTER TABLE [org].[EmpleadoArea] WITH CHECK ADD CONSTRAINT [CK_EmpleadoArea_Fechas] CHECK ([fecha_hasta] IS NULL OR [fecha_hasta]>=[fecha_desde]);
ALTER TABLE [org].[EmpleadoUOT] WITH CHECK ADD CONSTRAINT [CK_EmpleadoUOT_Fechas] CHECK ([fecha_hasta] IS NULL OR [fecha_hasta]>=[fecha_desde]);
ALTER TABLE [org].[Empresa] WITH CHECK ADD CONSTRAINT [CK_Empresa_RUC] CHECK (NOT [ruc] like '%[^0-9]%' AND len([ruc])=(11));
ALTER TABLE [org].[Persona] WITH CHECK ADD CONSTRAINT [CK_Persona_DocumentoFormatoBasico] CHECK ([tipo_documento]='DNI' AND len([numero_documento])=(8) AND NOT [numero_documento] like '%[^0-9]%' OR [tipo_documento]='RUC' AND len([numero_documento])=(11) AND NOT [numero_documento] like '%[^0-9]%' OR ([tipo_documento]='CE' OR [tipo_documento]='PASAPORTE' OR [tipo_documento]='OTRO') AND len(ltrim(rtrim([numero_documento])))>(0) OR NOT ([tipo_documento]='OTRO' OR [tipo_documento]='PASAPORTE' OR [tipo_documento]='CE' OR [tipo_documento]='RUC' OR [tipo_documento]='DNI') AND (len(ltrim(rtrim([numero_documento])))>=(5) AND len(ltrim(rtrim([numero_documento])))<=(30)) AND NOT [numero_documento] like '%[^A-Z0-9]%');
ALTER TABLE [org].[Persona] WITH CHECK ADD CONSTRAINT [CK_Persona_NumeroDocumento] CHECK (len(ltrim(rtrim([numero_documento])))>(0));
ALTER TABLE [org].[Persona] WITH CHECK ADD CONSTRAINT [CK_Persona_TipoDocumento] CHECK (len([tipo_documento])>=(2) AND len([tipo_documento])<=(15) AND NOT [tipo_documento] like '%[^A-Z0-9_]%');
ALTER TABLE [org].[Persona] WITH CHECK ADD CONSTRAINT [CK_Persona_TipoPersona] CHECK ([tipo_persona]='JURIDICA' OR [tipo_persona]='NATURAL');
ALTER TABLE [org].[ProductorUOT] WITH CHECK ADD CONSTRAINT [CK_E1_ProductorUOTVigencia] CHECK ([fecha_hasta] IS NULL OR [fecha_hasta]>=[fecha_desde]);
ALTER TABLE [org].[SocioAsociacion] WITH CHECK ADD CONSTRAINT [CK_SocioAsociacion_EstadoProceso] CHECK ([situacion_membresia]='RETIRADO' OR [situacion_membresia]='SUSPENDIDO' OR [situacion_membresia]='ACTIVO');
ALTER TABLE [org].[SocioAsociacion] WITH CHECK ADD CONSTRAINT [CK_SocioAsociacion_Fechas] CHECK ([fecha_hasta] IS NULL OR [fecha_hasta]>=[fecha_desde]);
ALTER TABLE [org].[UOT] WITH CHECK ADD CONSTRAINT [CK_UOT_Fechas] CHECK ([fecha_fin] IS NULL OR [fecha_inicio] IS NULL OR [fecha_fin]>=[fecha_inicio]);
ALTER TABLE [prod].[CensoPlantas] WITH CHECK ADD CONSTRAINT [CK_CensoPlantas_Valores] CHECK ([plantas_totales]>=(0) AND [plantas_productivas]>=(0) AND [plantas_no_productivas]>=(0) AND [plantas_nuevas]>=(0) AND [plantas_muertas]>=(0) AND [plantas_afectadas]>=(0) AND ([plantas_productivas]+[plantas_no_productivas])<=[plantas_totales] AND [plantas_afectadas]<=[plantas_totales]);
ALTER TABLE [prod].[CrianzaConteo] WITH CHECK ADD CONSTRAINT [CK_E1_CantidadNoNegativa] CHECK ([cantidad] IS NULL OR [cantidad]>=(0));
ALTER TABLE [prod].[CrianzaLote] WITH CHECK ADD CONSTRAINT [CK_E1_CrianzaVigencia] CHECK ([fecha_fin] IS NULL OR [fecha_fin]>=[fecha_inicio]);
ALTER TABLE [prod].[DisponibilidadProduccion] WITH CHECK ADD CONSTRAINT [CK_DisponibilidadProduccion_Cantidad] CHECK ([cantidad_estimada_kg]>=(0));
ALTER TABLE [prod].[DisponibilidadProduccion] WITH CHECK ADD CONSTRAINT [CK_DisponibilidadProduccion_EstadoProceso] CHECK ([estado_estimacion]='DESCARTADA' OR [estado_estimacion]='CONFIRMADA' OR [estado_estimacion]='ESTIMADA');
ALTER TABLE [prod].[DisponibilidadProduccion] WITH CHECK ADD CONSTRAINT [CK_DisponibilidadProduccion_Periodo] CHECK ([disponible_hasta] IS NULL OR [disponible_hasta]>=[disponible_desde]);
ALTER TABLE [prod].[ExpedienteActuacion] WITH CHECK ADD CONSTRAINT [CK_E1_ActuacionTipo] CHECK ([tipo]='SEGUIMIENTO' OR [tipo]='NECESIDAD' OR [tipo]='SANIDAD' OR [tipo]='CRIANZA' OR [tipo]='CULTIVO' OR [tipo]='GENERAL');
ALTER TABLE [prod].[FundoProduccionE3] WITH CHECK ADD CONSTRAINT [CK_FundoProduccionE3_Valido] CHECK ([anio]>=(2000) AND [anio]<=(2200) AND [fecha_desde]<=[fecha_hasta] AND datepart(year,[fecha_desde])=[anio] AND datepart(year,[fecha_hasta])=[anio] AND ([estado_produccion]='NO_DISPONIBLE' AND [cantidad_disponible_kg]=(0) OR ([estado_produccion]='DISPONIBLE' OR [estado_produccion]='PARCIAL') AND [cantidad_disponible_kg]>(0)));
ALTER TABLE [prod].[GPActividad] WITH CHECK ADD CONSTRAINT [CK__GPActivid__rubro__7B9127CC] CHECK ([rubro]='CRIANZA' OR [rubro]='CULTIVO');
ALTER TABLE [prod].[GPActividad] WITH CHECK ADD CONSTRAINT [CK_GP_ActividadEspecie] CHECK ([rubro]='CULTIVO' AND [cultivo_id] IS NOT NULL AND [especie_pecuaria_id] IS NULL OR [rubro]='CRIANZA' AND [especie_pecuaria_id] IS NOT NULL AND [cultivo_id] IS NULL);
ALTER TABLE [prod].[GPActividad] WITH CHECK ADD CONSTRAINT [CK_GPActividad_EstadoProceso] CHECK ([estado_proceso]='FINALIZADA' OR [estado_proceso]='ACTIVA');
ALTER TABLE [prod].[GPBajaLogica] WITH CHECK ADD CONSTRAINT [CK__GPBajaLogi__tipo__0B92856B] CHECK ([tipo]='ACTIVIDAD' OR [tipo]='PARCELA' OR [tipo]='PREDIO');
ALTER TABLE [prod].[GPCenso] WITH CHECK ADD CONSTRAINT [CK__GPCenso__cantida__0702DA78] CHECK ([cantidad]>=(0));
ALTER TABLE [prod].[GPCenso] WITH CHECK ADD CONSTRAINT [CK_GP_SuperficieNoNegativa] CHECK (([superficie_aproximada_m2] IS NULL OR [superficie_aproximada_m2]>=(0)) AND ([superficie_exacta_m2] IS NULL OR [superficie_exacta_m2]>=(0)));
ALTER TABLE [prod].[GPCenso] WITH CHECK ADD CONSTRAINT [CK_GPCenso_Aproximado] CHECK ([cantidad] IS NULL AND [aproximado] IS NULL OR [cantidad] IS NOT NULL AND [aproximado] IS NOT NULL);
ALTER TABLE [prod].[GPCenso] WITH CHECK ADD CONSTRAINT [CK_GPCenso_CantidadesVersionadas] CHECK (([cantidad_aproximada] IS NULL OR [cantidad_aproximada]>=(0)) AND ([cantidad_exacta] IS NULL OR [cantidad_exacta]>=(0)));
ALTER TABLE [prod].[GPCensoRaza] WITH CHECK ADD CONSTRAINT [CK_GPCensoRaza_Cantidad] CHECK (([cantidad_aproximada] IS NOT NULL OR [cantidad_exacta] IS NOT NULL) AND ([cantidad_aproximada] IS NULL OR [cantidad_aproximada]>=(0)) AND ([cantidad_exacta] IS NULL OR [cantidad_exacta]>=(0)));
ALTER TABLE [prod].[GPCensoVariedad] WITH CHECK ADD CONSTRAINT [CK_GPCensoVariedad_Superficie] CHECK ([superficie_m2]>(0));
ALTER TABLE [prod].[GPEvento] WITH CHECK ADD CONSTRAINT [CK__GPEvento__tipo__1B09D325] CHECK ([tipo]='RESPUESTA' OR [tipo]='EVALUACION' OR [tipo]='TRATAMIENTO' OR [tipo]='INCIDENCIA' OR [tipo]='OBSERVACION');
ALTER TABLE [prod].[GPEvento] WITH CHECK ADD CONSTRAINT [CK_GPEvento_CantidadAfectada] CHECK ([cantidad_afectada] IS NULL AND [afectados_aproximado] IS NULL OR [cantidad_afectada]>=(0) AND [afectados_aproximado] IS NOT NULL);
ALTER TABLE [prod].[GPEventoFoto] WITH CHECK ADD CONSTRAINT [CK_GPEventoFoto_Mime] CHECK ([mime_type]='image/webp' OR [mime_type]='image/png' OR [mime_type]='image/jpeg');
ALTER TABLE [prod].[GPEventoFoto] WITH CHECK ADD CONSTRAINT [CK_GPEventoFoto_Tamano] CHECK ([tamano_bytes]>(0) AND [tamano_bytes]<=(5242880));
ALTER TABLE [prod].[GPIncidencia] WITH CHECK ADD CONSTRAINT [CK_GPIncidencia_Afectacion] CHECK ([afectada_m2]>(0) AND [afectados_animales] IS NULL OR [afectados_animales]>(0) AND [afectada_m2] IS NULL);
ALTER TABLE [prod].[GPIncidencia] WITH CHECK ADD CONSTRAINT [CK_GPIncidencia_Estado] CHECK ([estado_seguimiento]='CERRADA' OR [estado_seguimiento]='ABIERTA');
ALTER TABLE [prod].[GPIncidencia] WITH CHECK ADD CONSTRAINT [CK_GPIncidencia_Perdida] CHECK (([perdida_m2] IS NULL OR [perdida_m2]>=(0)) AND ([perdidos_animales] IS NULL OR [perdidos_animales]>=(0)));
ALTER TABLE [prod].[GPIncidencia] WITH CHECK ADD CONSTRAINT [CK_GPIncidencia_Resultado] CHECK ([resultado] IS NULL OR ([resultado]='PERDIDA_TOTAL' OR [resultado]='PERDIDA_PARCIAL' OR [resultado]='RECUPERADA'));
ALTER TABLE [prod].[GPIncidenciaRevision] WITH CHECK ADD CONSTRAINT [CK_GPIncidenciaRevision_Accion] CHECK ([accion]='RETIRO' OR [accion]='EDICION');
ALTER TABLE [prod].[GPIncidenciaTratamiento] WITH CHECK ADD CONSTRAINT [CK_GPIncTrat_Fechas] CHECK (([fecha_fin_prevista] IS NULL OR [fecha_fin_prevista]>=[fecha_inicio]) AND ([fecha_fin_real] IS NULL OR [fecha_fin_real]>=[fecha_inicio]));
ALTER TABLE [prod].[GPProblema] WITH CHECK ADD CONSTRAINT [CK_GPProblema_Especie] CHECK ([cultivo_id] IS NOT NULL AND [especie_pecuaria_id] IS NULL OR [cultivo_id] IS NULL AND [especie_pecuaria_id] IS NOT NULL);
ALTER TABLE [prod].[Parcela] WITH CHECK ADD CONSTRAINT [CK_Parcela_Area] CHECK ([area_ha]>(0));
ALTER TABLE [prod].[ParcelaCultivo] WITH CHECK ADD CONSTRAINT [CK_E1_ParcelaCultivo_Identificacion] CHECK ([cultivo_id] IS NOT NULL OR [variedad_cultivo_id] IS NOT NULL OR [variedad_palta_id] IS NOT NULL);
ALTER TABLE [prod].[ParcelaCultivo] WITH CHECK ADD CONSTRAINT [CK_ParcelaCultivo_EstadoProceso] CHECK ([situacion_cultivo]='ABANDONADO' OR [situacion_cultivo]='FINALIZADO' OR [situacion_cultivo]='ACTIVO');
ALTER TABLE [prod].[ParcelaCultivo] WITH CHECK ADD CONSTRAINT [CK_ParcelaCultivo_Fechas] CHECK ([fecha_fin] IS NULL OR [fecha_fin]>=[fecha_inicio]);
ALTER TABLE [prod].[PlantaComentarioE3] WITH CHECK ADD CONSTRAINT [CK_E3_ComentarioNoVacio] CHECK (len(ltrim(rtrim([comentario])))>(0));
ALTER TABLE [prod].[PlantaEventoE3] WITH CHECK ADD CONSTRAINT [CK_E3_EventoTipo] CHECK ([tipo]='ENFERMEDAD' OR [tipo]='COMENTARIO' OR [tipo]='ELIMINACION' OR [tipo]='EVIDENCIA' OR [tipo]='PRODUCCION' OR [tipo]='TRATAMIENTO' OR [tipo]='SEGUIMIENTO' OR [tipo]='FICHA' OR [tipo]='CORRECCION' OR [tipo]='EVALUACION' OR [tipo]='ALTA');
ALTER TABLE [prod].[PlantaFichaHistorialE3] WITH CHECK ADD CONSTRAINT [CK_E3_FichaEdad] CHECK ([edad_referencia_anios] IS NULL OR [edad_referencia_anios]>=(0) AND [edad_referencia_anios]<=(200));
ALTER TABLE [prod].[PlantaMateriaSecaIndividualE4] WITH CHECK ADD CONSTRAINT [CK_E4_SecaIndividualPct] CHECK ([porcentaje]>(0) AND [porcentaje]<=(100));
ALTER TABLE [prod].[PlantaMedicionE3] WITH CHECK ADD CONSTRAINT [CK_E3_Medicion_Rango] CHECK ([porcentaje]>=(0) AND [porcentaje]<=(100));
ALTER TABLE [prod].[PlantaPaltaE3] WITH CHECK ADD CONSTRAINT [CK_E3_PlantaActivo] CHECK (([estado_actual]='ENFERMA' OR [estado_actual]='SANA' OR [estado_actual]='SIN_EVALUAR') AND [activo]=(1) OR ([estado_actual]='ELIMINADA' OR [estado_actual]='MUERTA') AND [activo]=(0));
ALTER TABLE [prod].[PlantaPaltaE3] WITH CHECK ADD CONSTRAINT [CK_E3_PlantaEdad] CHECK ([edad_referencia_anios] IS NULL OR [edad_referencia_anios]>=(0) AND [edad_referencia_anios]<=(200));
ALTER TABLE [prod].[PlantaPaltaE3] WITH CHECK ADD CONSTRAINT [CK_E3_PlantaEstado] CHECK ([estado_actual]='ELIMINADA' OR [estado_actual]='MUERTA' OR [estado_actual]='ENFERMA' OR [estado_actual]='SANA' OR [estado_actual]='SIN_EVALUAR');
ALTER TABLE [prod].[PredioMateriaSecaCambioE4] WITH CHECK ADD CONSTRAINT [CK_E4_SecaCambioAccion] CHECK ([accion]='INACTIVAR' OR [accion]='EDITAR' OR [accion]='CREAR');
ALTER TABLE [prod].[PredioMateriaSecaGlobalE4] WITH CHECK ADD CONSTRAINT [CK_E4_SecaGlobalCant] CHECK ([cantidad_plantas]>(0) AND [cantidad_plantas]<=[total_plantas_activas]);
ALTER TABLE [prod].[PredioMateriaSecaGlobalE4] WITH CHECK ADD CONSTRAINT [CK_E4_SecaGlobalCob] CHECK (([cobertura]='PARCIAL' OR [cobertura]='TOTAL') AND ([cobertura]='TOTAL' AND [cantidad_plantas]=[total_plantas_activas] OR [cobertura]='PARCIAL' AND [cantidad_plantas]<[total_plantas_activas]));
ALTER TABLE [prod].[PredioMateriaSecaGlobalE4] WITH CHECK ADD CONSTRAINT [CK_E4_SecaGlobalFrutos] CHECK ([cantidad_frutos] IS NULL OR [cantidad_frutos]>=(1) AND [cantidad_frutos]<=(10000));
ALTER TABLE [prod].[PredioMateriaSecaGlobalE4] WITH CHECK ADD CONSTRAINT [CK_E4_SecaGlobalMetodo] CHECK ([metodo] IS NULL OR ([metodo]='OTRO' OR [metodo]='NIR' OR [metodo]='MICROONDAS' OR [metodo]='HORNO' OR [metodo]='LABORATORIO'));
ALTER TABLE [prod].[PredioMateriaSecaGlobalE4] WITH CHECK ADD CONSTRAINT [CK_E4_SecaGlobalPct] CHECK ([porcentaje]>(0) AND [porcentaje]<=(100));
ALTER TABLE [prod].[PredioTitularidad] WITH CHECK ADD CONSTRAINT [CK_E1_Titular_Identidad] CHECK ([persona_id] IS NOT NULL);
ALTER TABLE [prod].[PredioTitularidad] WITH CHECK ADD CONSTRAINT [CK_GP_RolTitular] CHECK ([rol_titularidad]='ADICIONAL' OR [rol_titularidad]='PRINCIPAL');
ALTER TABLE [prod].[PredioTitularidad] WITH CHECK ADD CONSTRAINT [CK_PredioTitularidad_Fechas] CHECK ([fecha_hasta] IS NULL OR [fecha_hasta]>=[fecha_desde]);
ALTER TABLE [prod].[PredioTitularidad] WITH CHECK ADD CONSTRAINT [CK_PredioTitularidad_Porcentaje] CHECK ([porcentaje] IS NULL OR [porcentaje]>(0) AND [porcentaje]<=(100));
ALTER TABLE [prod].[PredioVersion] WITH CHECK ADD CONSTRAINT [CK_PredioVersion_Areas] CHECK ([area_total_ha]>(0) AND ([area_cultivable_ha] IS NULL OR [area_cultivable_ha]>=(0) AND [area_cultivable_ha]<=[area_total_ha]));
ALTER TABLE [prod].[PredioVersion] WITH CHECK ADD CONSTRAINT [CK_PredioVersion_Fechas] CHECK ([fecha_hasta] IS NULL OR [fecha_hasta]>=[fecha_desde]);
ALTER TABLE [prod].[ProduccionPlantaE3] WITH CHECK ADD CONSTRAINT [CK_E3_Produccion] CHECK ([anio]>=(2000) AND [anio]<=(2200) AND ([estimado_kg] IS NULL OR [estimado_kg]>=(0)) AND ([real_kg] IS NULL OR [real_kg]>=(0)));
ALTER TABLE [prod].[ProduccionPlantaE3] WITH CHECK ADD CONSTRAINT [CK_E3_ProduccionTipo] CHECK ([tipo_registro]='LEGADO' OR [tipo_registro]='ESTIMACION' AND [estimado_kg] IS NOT NULL AND [real_kg] IS NULL OR [tipo_registro]='COSECHA' AND [real_kg] IS NOT NULL AND [estimado_kg] IS NULL);
ALTER TABLE [reporte].[TrabajoEspecial] WITH CHECK ADD CONSTRAINT [CK_TrabajoEspecialEstado] CHECK ([estado]='ERROR' OR [estado]='LISTO' OR [estado]='PROCESANDO' OR [estado]='PENDIENTE');
ALTER TABLE [reporte].[TrabajoEspecial] WITH CHECK ADD CONSTRAINT [CK_TrabajoEspecialFormato] CHECK ([formato]='DOCX' OR [formato]='PDF' OR [formato]='XLSX');
ALTER TABLE [reporte].[TrabajoExcel] WITH CHECK ADD CONSTRAINT [CK_TrabajoExcel_Estado] CHECK ([estado]='ERROR' OR [estado]='LISTO' OR [estado]='PROCESANDO' OR [estado]='PENDIENTE');
ALTER TABLE [sanidad].[CasoFitosanitario] WITH CHECK ADD CONSTRAINT [CK_CasoFitosanitario_EstadoProceso] CHECK ([estado_caso]='CERRADO' OR [estado_caso]='NO_RECUPERADO' OR [estado_caso]='RECUPERADO' OR [estado_caso]='CONTROLADO' OR [estado_caso]='EN_SEGUIMIENTO' OR [estado_caso]='EN_TRATAMIENTO' OR [estado_caso]='DETECTADO');
ALTER TABLE [sanidad].[CasoFitosanitario] WITH CHECK ADD CONSTRAINT [CK_CasoFitosanitario_Estimacion] CHECK ([plantas_afectadas] IS NULL AND [cantidad_estimada] IS NULL OR [plantas_afectadas] IS NOT NULL);
ALTER TABLE [sanidad].[CasoFitosanitario] WITH CHECK ADD CONSTRAINT [CK_CasoFitosanitario_Plantas] CHECK ([plantas_afectadas] IS NULL OR [plantas_afectadas]>=(0));
ALTER TABLE [sanidad].[CasoFitosanitario] WITH CHECK ADD CONSTRAINT [CK_CasoFitosanitario_Severidad] CHECK ([severidad]='ALTA' OR [severidad]='MEDIA' OR [severidad]='BAJA');
ALTER TABLE [sanidad].[EpisodioNotaE4] WITH CHECK ADD CONSTRAINT [CK_E4_NotaTexto] CHECK (len(ltrim(rtrim([comentario])))>(0));
ALTER TABLE [sanidad].[EpisodioPlantaE3] WITH CHECK ADD CONSTRAINT [CK_E3_EpisodioFechas] CHECK ([fin] IS NULL OR [fin]>=[inicio]);
ALTER TABLE [sanidad].[PlantaSeguimientoE3] WITH CHECK ADD CONSTRAINT [CK_E3_SeguimientoTipo] CHECK ([tipo]='OTRO' OR [tipo]='FERTILIZACION' OR [tipo]='RIEGO' OR [tipo]='PODA' OR [tipo]='PREVENTIVO' OR [tipo]='SANITARIO');
ALTER TABLE [sanidad].[SeguimientoFitosanitario] WITH CHECK ADD CONSTRAINT [CK_SeguimientoFitosanitario_Estimacion] CHECK ([plantas_afectadas] IS NULL AND [cantidad_estimada] IS NULL OR [plantas_afectadas] IS NOT NULL);
ALTER TABLE [sanidad].[SeguimientoFitosanitario] WITH CHECK ADD CONSTRAINT [CK_SeguimientoFitosanitario_Plantas] CHECK ([plantas_afectadas] IS NULL OR [plantas_afectadas]>=(0));
ALTER TABLE [sanidad].[SeguimientoFitosanitario] WITH CHECK ADD CONSTRAINT [CK_SeguimientoFitosanitario_Resultado] CHECK ([resultado]='NO_RECUPERADO' OR [resultado]='RECUPERADO' OR [resultado]='CONTROLADO' OR [resultado]='EMPEORA' OR [resultado]='IGUAL' OR [resultado]='MEJORA');
ALTER TABLE [sanidad].[SeguimientoFitosanitario] WITH CHECK ADD CONSTRAINT [CK_SeguimientoFitosanitario_Severidad] CHECK ([severidad] IS NULL OR ([severidad]='ALTA' OR [severidad]='MEDIA' OR [severidad]='BAJA'));
ALTER TABLE [sanidad].[TipoProblemaFitosanitario] WITH CHECK ADD CONSTRAINT [CK_TipoProblemaFitosanitario_Categoria] CHECK ([categoria]='OTRO' OR [categoria]='ENFERMEDAD' OR [categoria]='PLAGA');
ALTER TABLE [sanidad].[TratamientoFitosanitario] WITH CHECK ADD CONSTRAINT [CK_TratamientoFitosanitario_Dosis] CHECK ([dosis] IS NULL OR [dosis]>(0));
ALTER TABLE [seg].[CodigoUnSoloUso] WITH CHECK ADD CONSTRAINT [CK_CodigoUnSoloUso_Canal] CHECK ([canal]='EMAIL');
ALTER TABLE [seg].[CodigoUnSoloUso] WITH CHECK ADD CONSTRAINT [CK_CodigoUnSoloUso_Fechas] CHECK ([fecha_expiracion]>[fecha_creacion] AND ([fecha_uso] IS NULL OR [fecha_uso]>=[fecha_creacion]) AND ([fecha_invalidacion] IS NULL OR [fecha_invalidacion]>=[fecha_creacion]));
ALTER TABLE [seg].[CodigoUnSoloUso] WITH CHECK ADD CONSTRAINT [CK_CodigoUnSoloUso_Intentos] CHECK ([intentos_fallidos]>=(0) AND [maximo_intentos]>(0) AND [intentos_fallidos]<=[maximo_intentos]);
ALTER TABLE [seg].[CodigoUnSoloUso] WITH CHECK ADD CONSTRAINT [CK_CodigoUnSoloUso_Proposito] CHECK ([proposito]='CAMBIO_CORREO' OR [proposito]='SEGUNDO_FACTOR' OR [proposito]='RECUPERACION_PASSWORD' OR [proposito]='VALIDACION_CORREO');
ALTER TABLE [seg].[DispositivoUsuario] WITH CHECK ADD CONSTRAINT [CK_DispositivoUsuario_Fechas] CHECK ([fecha_ultima_actividad]>=[fecha_primera_deteccion]);
ALTER TABLE [seg].[DispositivoUsuario] WITH CHECK ADD CONSTRAINT [CK_DispositivoUsuario_Reconocimiento] CHECK ([es_reconocido]=(0) OR [es_reconocido]=(1) AND [fecha_reconocimiento] IS NOT NULL);
ALTER TABLE [seg].[HistorialPassword] WITH CHECK ADD CONSTRAINT [CK_HistorialPassword_Fechas] CHECK ([fecha_hasta] IS NULL OR [fecha_hasta]>=[fecha_desde]);
ALTER TABLE [seg].[IntentoAutenticacion] WITH CHECK ADD CONSTRAINT [CK_IntentoAutenticacion_Resultado] CHECK ([resultado]='SEGUNDO_FACTOR_EXITOSO' OR [resultado]='SEGUNDO_FACTOR_INVALIDO' OR [resultado]='REQUIERE_SEGUNDO_FACTOR' OR [resultado]='CORREO_NO_VALIDADO' OR [resultado]='CUENTA_DESHABILITADA' OR [resultado]='CUENTA_BLOQUEADA' OR [resultado]='CREDENCIALES_INVALIDAS' OR [resultado]='EXITOSO');
ALTER TABLE [seg].[Modulo] WITH CHECK ADD CONSTRAINT [CK_Modulo_Orden] CHECK ([orden]>=(0));
ALTER TABLE [seg].[NotificacionSeguridad] WITH CHECK ADD CONSTRAINT [CK_NotificacionSeguridad_EstadoEnvio] CHECK ([estado_envio]='CANCELADO' OR [estado_envio]='FALLIDO' OR [estado_envio]='ENVIADO' OR [estado_envio]='ENVIANDO' OR [estado_envio]='PENDIENTE');
ALTER TABLE [seg].[NotificacionSeguridad] WITH CHECK ADD CONSTRAINT [CK_NotificacionSeguridad_Intentos] CHECK ([cantidad_intentos]>=(0));
ALTER TABLE [seg].[NotificacionSeguridad] WITH CHECK ADD CONSTRAINT [CK_NotificacionSeguridad_MetadataJSON] CHECK ([metadata] IS NULL OR isjson([metadata])=(1));
ALTER TABLE [seg].[NotificacionSeguridad] WITH CHECK ADD CONSTRAINT [CK_NotificacionSeguridad_Tipo] CHECK ([tipo_notificacion]='CAMBIO_CORREO' OR [tipo_notificacion]='CAMBIO_PASSWORD' OR [tipo_notificacion]='NUEVO_DISPOSITIVO' OR [tipo_notificacion]='SEGUNDO_FACTOR' OR [tipo_notificacion]='RECUPERACION_PASSWORD' OR [tipo_notificacion]='VALIDACION_CORREO');
ALTER TABLE [seg].[Permiso] WITH CHECK ADD CONSTRAINT [CK_Permiso_Accion] CHECK ([accion] IS NULL OR ([accion]='ADMINISTRAR' OR [accion]='EXPORTAR' OR [accion]='APROBAR' OR [accion]='CONFIRMAR' OR [accion]='RETIRAR' OR [accion]='EDITAR' OR [accion]='CREAR' OR [accion]='VER' OR [accion]='LISTAR'));
ALTER TABLE [seg].[PoliticaSeguridad] WITH CHECK ADD CONSTRAINT [CK_PoliticaSeguridad_Fechas] CHECK ([fecha_hasta] IS NULL OR [fecha_hasta]>=[fecha_desde]);
ALTER TABLE [seg].[PoliticaSeguridad] WITH CHECK ADD CONSTRAINT [CK_PoliticaSeguridad_Valores] CHECK ([max_intentos_login]>=(1) AND [max_intentos_login]<=(20) AND ([minutos_bloqueo_login]>=(1) AND [minutos_bloqueo_login]<=(1440)) AND ([max_intentos_codigo]>=(1) AND [max_intentos_codigo]<=(20)) AND ([segundos_minimos_reenvio]>=(15) AND [segundos_minimos_reenvio]<=(3600)) AND ([minutos_expiracion_validacion]>=(1) AND [minutos_expiracion_validacion]<=(1440)) AND ([minutos_expiracion_recuperacion]>=(1) AND [minutos_expiracion_recuperacion]<=(1440)) AND ([minutos_expiracion_segundo_factor]>=(1) AND [minutos_expiracion_segundo_factor]<=(60)) AND ([minutos_access_token]>=(1) AND [minutos_access_token]<=(120)) AND ([dias_refresh_token]>=(1) AND [dias_refresh_token]<=(90)) AND ([dias_dispositivo_reconocido]>=(1) AND [dias_dispositivo_reconocido]<=(365)));
ALTER TABLE [seg].[RefreshTokenSesion] WITH CHECK ADD CONSTRAINT [CK_RefreshTokenSesion_Fechas] CHECK ([fecha_expiracion]>[fecha_emision] AND ([fecha_uso] IS NULL OR [fecha_uso]>=[fecha_emision]) AND ([fecha_revocacion] IS NULL OR [fecha_revocacion]>=[fecha_emision]));
ALTER TABLE [seg].[SesionUsuario] WITH CHECK ADD CONSTRAINT [CK_SesionUsuario_Fechas] CHECK ([fecha_ultima_actividad]>=[fecha_creacion] AND [fecha_expiracion_renovacion]>[fecha_creacion] AND ([fecha_revocacion] IS NULL OR [fecha_revocacion]>=[fecha_creacion]));
ALTER TABLE [seg].[SesionUsuario] WITH CHECK ADD CONSTRAINT [CK_SesionUsuario_ModoUOT] CHECK ([modo_uot]='GENERAL' OR [modo_uot]='ESPECIFICA');
ALTER TABLE [seg].[SesionUsuario] WITH CHECK ADD CONSTRAINT [CK_SesionUsuario_TokenVersion] CHECK ([token_version]>=(1));
ALTER TABLE [seg].[TokenAccesoRevocado] WITH CHECK ADD CONSTRAINT [CK_TokenAccesoRevocado_Fechas] CHECK ([fecha_expiracion_token]>[fecha_revocacion]);
ALTER TABLE [seg].[Usuario] WITH CHECK ADD CONSTRAINT [CK_Usuario_EstadoCuenta] CHECK ([estado_cuenta]='RETIRADA' OR [estado_cuenta]='DESHABILITADA' OR [estado_cuenta]='BLOQUEADA' OR [estado_cuenta]='ACTIVA' OR [estado_cuenta]='PENDIENTE_VALIDACION');
ALTER TABLE [seg].[Usuario] WITH CHECK ADD CONSTRAINT [CK_Usuario_IntentosFallidos] CHECK ([intentos_fallidos]>=(0));
ALTER TABLE [seg].[Usuario] WITH CHECK ADD CONSTRAINT [CK_Usuario_TokenVersion] CHECK ([token_version]>=(1));
ALTER TABLE [seg].[UsuarioCorreoSeguridad] WITH CHECK ADD CONSTRAINT [CK_UsuarioCorreoSeguridad_Fechas] CHECK ([fecha_hasta] IS NULL OR [fecha_hasta]>=[fecha_desde]);
ALTER TABLE [seg].[UsuarioCorreoSeguridad] WITH CHECK ADD CONSTRAINT [CK_UsuarioCorreoSeguridad_Verificacion] CHECK ([es_verificado]=(0) AND [fecha_verificacion] IS NULL OR [es_verificado]=(1) AND [fecha_verificacion] IS NOT NULL);
ALTER TABLE [seg].[UsuarioRol] WITH CHECK ADD CONSTRAINT [CK_UsuarioRol_Fechas] CHECK ([fecha_hasta] IS NULL OR [fecha_hasta]>=[fecha_desde]);
ALTER TABLE [seg].[UsuarioUOT] WITH CHECK ADD CONSTRAINT [CK_UsuarioUOT_Fechas] CHECK ([fecha_hasta] IS NULL OR [fecha_hasta]>=[fecha_desde]);
ALTER TABLE [seg].[UsuarioUOTPermiso] WITH CHECK ADD CONSTRAINT [CK_UsuarioUOTPermiso_Fechas] CHECK ([fecha_hasta] IS NULL OR [fecha_hasta]>=[fecha_desde]);
ALTER TABLE [seg].[UsuarioUOTRol] WITH CHECK ADD CONSTRAINT [CK_UsuarioUOTRol_Fechas] CHECK ([fecha_hasta] IS NULL OR [fecha_hasta]>=[fecha_desde]);
GO
