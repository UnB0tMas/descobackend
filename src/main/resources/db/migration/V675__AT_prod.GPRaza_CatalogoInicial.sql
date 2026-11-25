-- Incorporar razas asociadas a las especies; requiere un usuario existente para auditoría.
IF OBJECT_ID(N'prod.GPRaza', N'U') IS NULL OR OBJECT_ID(N'prod.EspeciePecuaria', N'U') IS NULL
BEGIN
    THROW 51000, N'No existen los catálogos pecuarios.', 1;
END;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @Usuario BIGINT;
SELECT TOP (1) @Usuario = U.usuario_id
FROM seg.Usuario U WITH (NOLOCK)
WHERE U.estado = 1
ORDER BY U.usuario_id;

IF @Usuario IS NULL
BEGIN
    THROW 51000, N'Se requiere un usuario activo para registrar el catálogo de razas.', 1;
END;

DECLARE @Razas TABLE (
    especieCodigo VARCHAR(30) NOT NULL,
    especieNombre NVARCHAR(90) NOT NULL,
    nombre NVARCHAR(120) NOT NULL,
    PRIMARY KEY (especieCodigo, nombre)
);

INSERT INTO @Razas (especieCodigo, especieNombre, nombre)
VALUES
        ('BOVINO', N'Bovino', N'Criollo'),
        ('BOVINO', N'Bovino', N'Brown Swiss'),
        ('BOVINO', N'Bovino', N'Holstein'),
        ('BOVINO', N'Bovino', N'Jersey'),
        ('OVINO', N'Ovino', N'Criollo'),
        ('OVINO', N'Ovino', N'Corriedale'),
        ('OVINO', N'Ovino', N'Junín'),
        ('OVINO', N'Ovino', N'Hampshire Down'),
        ('CAPRINO', N'Caprino', N'Criollo'),
        ('CAPRINO', N'Caprino', N'Saanen'),
        ('CAPRINO', N'Caprino', N'Anglo-Nubian'),
        ('PORCINO', N'Porcino', N'Criollo'),
        ('PORCINO', N'Porcino', N'Yorkshire'),
        ('PORCINO', N'Porcino', N'Landrace'),
        ('PORCINO', N'Porcino', N'Duroc'),
        ('CUY', N'Cuy', N'Criollo'),
        ('CUY', N'Cuy', N'Perú'),
        ('CUY', N'Cuy', N'Andina'),
        ('CUY', N'Cuy', N'Inti'),
        ('ALPACA', N'Alpaca', N'Huacaya'),
        ('ALPACA', N'Alpaca', N'Suri'),
        ('LLAMA', N'Llama', N'K''ara'),
        ('LLAMA', N'Llama', N'Ch''aku'),
        ('GALLINA', N'Gallina', N'Criolla'),
        ('GALLINA', N'Gallina', N'Leghorn'),
        ('GALLINA', N'Gallina', N'Rhode Island Red'),
        ('EQUINO', N'Equino', N'Criollo'),
        ('EQUINO', N'Equino', N'Peruano de Paso'),
        ('CONEJO', N'Conejo', N'Nueva Zelanda'),
        ('CONEJO', N'Conejo', N'California');

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO prod.GPRaza (especie_pecuaria_id, nombre, descripcion, usuario_creacion_id)
    SELECT E.especie_pecuaria_id, R.nombre, NULL, @Usuario
    FROM @Razas R
    INNER JOIN prod.EspeciePecuaria E
        ON E.codigo = R.especieCodigo OR E.nombre = R.especieNombre
    WHERE E.estado = 1
      AND NOT EXISTS (
          SELECT 1
          FROM prod.GPRaza G WITH (UPDLOCK, HOLDLOCK)
          WHERE G.especie_pecuaria_id = E.especie_pecuaria_id
            AND G.nombre = R.nombre
      );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;
    THROW;
END CATCH;
GO
