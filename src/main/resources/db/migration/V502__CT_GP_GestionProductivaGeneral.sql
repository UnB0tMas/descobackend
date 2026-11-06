-- DESCO GENERAL. Separado expresamente de los expedientes individuales APAPPSS.
-- No modificar estructuras ni procedimientos ya versionados.
IF OBJECT_ID(N'prod.GPActividad', N'U') IS NULL
BEGIN
    CREATE TABLE prod.GPActividad (
        actividad_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_GPActividad PRIMARY KEY,
        parcela_id BIGINT NOT NULL REFERENCES prod.Parcela(parcela_id),
        predio_id BIGINT NOT NULL REFERENCES prod.Predio(predio_id),
        uot_id BIGINT NOT NULL REFERENCES org.UOT(uot_id),
        rubro VARCHAR(8) NOT NULL CHECK(rubro IN('CULTIVO','CRIANZA')),
        cultivo_id INT NULL REFERENCES prod.Cultivo(cultivo_id),
        especie_pecuaria_id INT NULL REFERENCES prod.EspeciePecuaria(especie_pecuaria_id),
        nombre NVARCHAR(120) NULL,
        fecha_inicio DATE NOT NULL DEFAULT CONVERT(date,SYSUTCDATETIME()),
        estado BIT NOT NULL DEFAULT 1,
        usuario_creacion_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
        fecha_creacion DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        solicitud_id UNIQUEIDENTIFIER NOT NULL,
        CONSTRAINT CK_GP_ActividadEspecie CHECK (
            (rubro='CULTIVO' AND cultivo_id IS NOT NULL AND especie_pecuaria_id IS NULL) OR
            (rubro='CRIANZA' AND especie_pecuaria_id IS NOT NULL AND cultivo_id IS NULL)),
        CONSTRAINT UQ_GPActividad_Solicitud UNIQUE(solicitud_id)
    );
    CREATE INDEX IX_GPActividad_Parcela ON prod.GPActividad(uot_id,predio_id,parcela_id,actividad_id);
END;
GO
IF OBJECT_ID(N'prod.GPCenso', N'U') IS NULL
BEGIN
    CREATE TABLE prod.GPCenso (
        censo_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_GPCenso PRIMARY KEY,
        actividad_id BIGINT NOT NULL REFERENCES prod.GPActividad(actividad_id),
        cantidad INT NULL CHECK(cantidad>=0),
        aproximado BIT NULL,
        fecha DATE NOT NULL,
        observacion NVARCHAR(1000) NULL,
        usuario_creacion_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
        fecha_registro DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        solicitud_id UNIQUEIDENTIFIER NOT NULL CONSTRAINT UQ_GPCenso_Solicitud UNIQUE,
        CONSTRAINT CK_GPCenso_Aproximado CHECK((cantidad IS NULL AND aproximado IS NULL) OR
           (cantidad IS NOT NULL AND aproximado IS NOT NULL))
    );
    CREATE INDEX IX_GPCenso_Actividad ON prod.GPCenso(actividad_id,fecha DESC,censo_id DESC);
END;
GO
IF OBJECT_ID(N'prod.GPProblema', N'U') IS NULL
BEGIN
    CREATE TABLE prod.GPProblema (
        problema_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_GPProblema PRIMARY KEY,
        cultivo_id INT NULL REFERENCES prod.Cultivo(cultivo_id),
        especie_pecuaria_id INT NULL REFERENCES prod.EspeciePecuaria(especie_pecuaria_id),
        nombre NVARCHAR(160) NOT NULL,
        estado BIT NOT NULL DEFAULT 1,
        CONSTRAINT CK_GPProblema_Especie CHECK(
            (cultivo_id IS NOT NULL AND especie_pecuaria_id IS NULL) OR
            (cultivo_id IS NULL AND especie_pecuaria_id IS NOT NULL))
    );
END;
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('prod.GPProblema') AND name='UX_GPProblema_Cultivo')
 CREATE UNIQUE INDEX UX_GPProblema_Cultivo ON prod.GPProblema(cultivo_id,nombre) WHERE cultivo_id IS NOT NULL;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('prod.GPProblema') AND name='UX_GPProblema_Especie')
 CREATE UNIQUE INDEX UX_GPProblema_Especie ON prod.GPProblema(especie_pecuaria_id,nombre) WHERE especie_pecuaria_id IS NOT NULL;
GO
IF OBJECT_ID(N'prod.GPTratamiento', N'U') IS NULL
BEGIN
    CREATE TABLE prod.GPTratamiento (
        tratamiento_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_GPTratamiento PRIMARY KEY,
        nombre NVARCHAR(160) NOT NULL,
        descripcion NVARCHAR(1000) NULL,
        estado BIT NOT NULL DEFAULT 1
    );
END;
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('prod.GPTratamiento') AND name='UX_GPTratamiento_Nombre')
 CREATE UNIQUE INDEX UX_GPTratamiento_Nombre ON prod.GPTratamiento(nombre);
GO
IF OBJECT_ID(N'prod.GPProblemaTratamiento', N'U') IS NULL
BEGIN
    CREATE TABLE prod.GPProblemaTratamiento (
        problema_id INT NOT NULL REFERENCES prod.GPProblema(problema_id),
        tratamiento_id INT NOT NULL REFERENCES prod.GPTratamiento(tratamiento_id),
        CONSTRAINT PK_GPProblemaTratamiento PRIMARY KEY(problema_id,tratamiento_id)
    );
END;
GO
IF OBJECT_ID(N'prod.GPEvento', N'U') IS NULL
BEGIN
    CREATE TABLE prod.GPEvento (
        evento_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_GPEvento PRIMARY KEY,
        actividad_id BIGINT NOT NULL REFERENCES prod.GPActividad(actividad_id),
        tipo VARCHAR(20) NOT NULL CHECK(tipo IN('OBSERVACION','INCIDENCIA','TRATAMIENTO','EVALUACION','RESPUESTA')),
        problema_id INT NULL REFERENCES prod.GPProblema(problema_id),
        tratamiento_id INT NULL REFERENCES prod.GPTratamiento(tratamiento_id),
        respuesta_a_id BIGINT NULL REFERENCES prod.GPEvento(evento_id),
        observacion NVARCHAR(2000) NOT NULL,
        fecha_hecho DATETIME2(0) NOT NULL,
        fecha_registro DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        usuario_creacion_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
        visita_id BIGINT NULL,
        solicitud_id UNIQUEIDENTIFIER NOT NULL CONSTRAINT UQ_GPEvento_Solicitud UNIQUE
    );
    CREATE INDEX IX_GPEvento_Actividad ON prod.GPEvento(actividad_id,fecha_hecho DESC,evento_id DESC);
END;
GO
-- Seguridad compartida: una función de autorización, NO un procedimiento multiacción.
IF OBJECT_ID(N'prod.FN_GP_Permiso', N'FN') IS NOT NULL DROP FUNCTION prod.FN_GP_Permiso;
GO
CREATE FUNCTION prod.FN_GP_Permiso (
    @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Permiso VARCHAR(70),@Escritura BIT)
RETURNS BIT
AS
BEGIN
    DECLARE @OK BIT=0;
    IF EXISTS (
      SELECT 1 FROM seg.SesionUsuario S
      WHERE S.sesion_publica_id=@Sesion AND S.usuario_id=@Usuario
        AND S.estado=1 AND S.fecha_revocacion IS NULL
        AND (@Escritura=0 OR (S.modo_uot='ESPECIFICA' AND S.uot_contexto_id=@Uot))
        AND (S.modo_uot='GENERAL' OR S.uot_contexto_id=@Uot)
        AND seg.FN_Usuario_TienePermisoUOT(@Usuario,@Uot,@Permiso)=1
    ) SET @OK=1;
    RETURN @OK;
END;
GO
