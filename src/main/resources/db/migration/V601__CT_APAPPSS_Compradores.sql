-- DESCO APAPPSS. Maestro de compradores por UOT; no duplica org.Persona ni org.Empresa.
-- Este catálogo NO crea convenios, ni habilita asociaciones distintas de APAPPSS.
IF OBJECT_ID(N'comercial.CompradorAPAPPSS', N'U') IS NULL
BEGIN
    CREATE TABLE comercial.CompradorAPAPPSS (
        comprador_apappss_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_CompradorAPAPPSS PRIMARY KEY,
        uot_id BIGINT NOT NULL,
        tipo VARCHAR(10) NOT NULL,
        persona_id BIGINT NULL,
        empresa_id BIGINT NULL,
        fecha_registro DATETIME2(0) NOT NULL CONSTRAINT DF_CompradorAPAPPSS_Fecha DEFAULT SYSUTCDATETIME(),
        estado BIT NOT NULL CONSTRAINT DF_CompradorAPAPPSS_Estado DEFAULT (1),
        CONSTRAINT CK_CompradorAPAPPSS_Tipo CHECK (
           (tipo='PERSONA' AND persona_id IS NOT NULL AND empresa_id IS NULL)
           OR (tipo='EMPRESA' AND persona_id IS NULL AND empresa_id IS NOT NULL)),
        CONSTRAINT FK_CompradorAPAPPSS_UOT FOREIGN KEY (uot_id) REFERENCES org.UOT(uot_id),
        CONSTRAINT FK_CompradorAPAPPSS_Persona FOREIGN KEY (persona_id) REFERENCES org.Persona(persona_id),
        CONSTRAINT FK_CompradorAPAPPSS_Empresa FOREIGN KEY (empresa_id) REFERENCES org.Empresa(empresa_id)
    );
    CREATE UNIQUE INDEX UX_CompradorAPAPPSS_Persona ON comercial.CompradorAPAPPSS(uot_id, persona_id)
        WHERE persona_id IS NOT NULL;
    CREATE UNIQUE INDEX UX_CompradorAPAPPSS_Empresa ON comercial.CompradorAPAPPSS(uot_id, empresa_id)
        WHERE empresa_id IS NOT NULL;
END;
GO

IF NOT EXISTS(SELECT 1 FROM seg.Modulo WHERE codigo='APAPPSS')
    INSERT seg.Modulo(codigo,nombre,orden,estado,ruta,icono,visible_menu,es_grupo)
      VALUES('APAPPSS',N'APAPPSS',90,1,NULL,'handshake',0,0);

;WITH Nuevos AS (
  SELECT codigo,nombre,accion FROM (VALUES
    (CAST('APAPPSS_COMPRADORES_LISTAR' AS VARCHAR(40)),CAST(N'APAPPSS - Listar compradores' AS NVARCHAR(100)),CAST('LISTAR' AS VARCHAR(20))),
    ('APAPPSS_COMPRADORES_CREAR',N'APAPPSS - Registrar compradores','CREAR')
  ) N(codigo,nombre,accion)
)
INSERT seg.Permiso(modulo_id,codigo,nombre,descripcion,estado,accion,es_sensible,requiere_motivo)
SELECT M.modulo_id,N.codigo,N.nombre,N'Compradores de la asociación APAPPSS, con ámbito UOT.',1,N.accion,
    CASE WHEN N.accion='CREAR' THEN 1 ELSE 0 END,0
FROM Nuevos N CROSS JOIN seg.Modulo M
WHERE M.codigo='APAPPSS' AND NOT EXISTS (SELECT 1 FROM seg.Permiso P WHERE P.codigo=N.codigo);

INSERT seg.ModuloEspecialPermiso(modulo_especial_id,permiso_id)
SELECT M.modulo_especial_id,P.permiso_id
FROM seg.ModuloEspecial M CROSS JOIN seg.Permiso P
WHERE M.codigo='COMERCIALIZACION_ASOCIATIVA'
  AND P.codigo IN('APAPPSS_COMPRADORES_LISTAR','APAPPSS_COMPRADORES_CREAR')
  AND NOT EXISTS(SELECT 1 FROM seg.ModuloEspecialPermiso MP
      WHERE MP.modulo_especial_id=M.modulo_especial_id AND MP.permiso_id=P.permiso_id);
GO
