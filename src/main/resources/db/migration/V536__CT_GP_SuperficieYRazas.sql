-- Evolución aditiva: los registros anteriores conservan su semántica y su historial.
IF COL_LENGTH('prod.GPCenso','superficie_aproximada_m2') IS NULL
 ALTER TABLE prod.GPCenso ADD superficie_aproximada_m2 DECIMAL(14,2) NULL;
GO
IF COL_LENGTH('prod.GPCenso','superficie_exacta_m2') IS NULL
 ALTER TABLE prod.GPCenso ADD superficie_exacta_m2 DECIMAL(14,2) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID('prod.GPCenso') AND name='CK_GP_SuperficieNoNegativa')
 ALTER TABLE prod.GPCenso ADD CONSTRAINT CK_GP_SuperficieNoNegativa CHECK
 ((superficie_aproximada_m2 IS NULL OR superficie_aproximada_m2>=0)
 AND (superficie_exacta_m2 IS NULL OR superficie_exacta_m2>=0));
GO
IF OBJECT_ID(N'prod.GPRaza',N'U') IS NULL
BEGIN
 CREATE TABLE prod.GPRaza (
  raza_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_GPRaza PRIMARY KEY,
  especie_pecuaria_id INT NOT NULL REFERENCES prod.EspeciePecuaria(especie_pecuaria_id),
  nombre NVARCHAR(120) NOT NULL,
  estado BIT NOT NULL CONSTRAINT DF_GPRaza_Estado DEFAULT(1),
  usuario_creacion_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
  fecha_registro DATETIME2(0) NOT NULL CONSTRAINT DF_GPRaza_Registro DEFAULT SYSUTCDATETIME()
 );
 CREATE UNIQUE INDEX UX_GPRaza_EspecieNombre ON prod.GPRaza(especie_pecuaria_id,nombre);
END;
GO
IF OBJECT_ID(N'prod.GPCensoRaza',N'U') IS NULL
BEGIN
 CREATE TABLE prod.GPCensoRaza(
  censo_id BIGINT NOT NULL REFERENCES prod.GPCenso(censo_id),
  raza_id INT NOT NULL REFERENCES prod.GPRaza(raza_id),
  cantidad_aproximada INT NULL,
  cantidad_exacta INT NULL,
  CONSTRAINT PK_GPCensoRaza PRIMARY KEY(censo_id,raza_id),
  CONSTRAINT CK_GPCensoRaza_Cantidad CHECK(
   (cantidad_aproximada IS NOT NULL OR cantidad_exacta IS NOT NULL) AND
   (cantidad_aproximada IS NULL OR cantidad_aproximada>=0) AND
   (cantidad_exacta IS NULL OR cantidad_exacta>=0))
 );
END;
GO
