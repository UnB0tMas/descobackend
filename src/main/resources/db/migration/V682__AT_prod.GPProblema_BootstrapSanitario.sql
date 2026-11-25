-- Bootstrap de catálogos productivos. Solo añade entradas ausentes; no modifica históricos.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF OBJECT_ID(N'prod.GPProblema', N'U') IS NULL
   OR OBJECT_ID(N'prod.Cultivo', N'U') IS NULL
   OR OBJECT_ID(N'prod.EspeciePecuaria', N'U') IS NULL
BEGIN
    THROW 51000, N'No están disponibles los catálogos productivos.', 1;
END;
GO

DECLARE @Enfermedades TABLE (
    ambito VARCHAR(10) NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nombre NVARCHAR(160) NOT NULL,
    PRIMARY KEY (ambito, codigo, nombre)
);

INSERT INTO @Enfermedades (ambito, codigo, nombre)
VALUES
    (N'CULTIVO',N'PALTA',N'Pudrición radicular (Phytophthora)'),
    (N'CULTIVO',N'PALTA',N'Antracnosis de palta'),
    (N'CULTIVO',N'PAPA',N'Tizón tardío de papa'),
    (N'CULTIVO',N'PAPA',N'Rhizoctoniasis de papa'),
    (N'CULTIVO',N'MAIZ',N'Roya común del maíz'),
    (N'CULTIVO',N'MAIZ',N'Tizón foliar del maíz'),
    (N'CULTIVO',N'ALFALFA',N'Antracnosis de alfalfa'),
    (N'CULTIVO',N'ALFALFA',N'Mildiu de alfalfa'),
    (N'CULTIVO',N'ARVEJA',N'Oídio de arveja'),
    (N'CULTIVO',N'ARVEJA',N'Fusariosis de arveja'),
    (N'CULTIVO',N'CAFE',N'Roya del café'),
    (N'CULTIVO',N'CAFE',N'Ojo de gallo del café'),
    (N'CULTIVO',N'CEBADA',N'Roya de cebada'),
    (N'CULTIVO',N'CEBADA',N'Mancha reticulada de cebada'),
    (N'CULTIVO',N'DURAZNO',N'Abolladura del duraznero'),
    (N'CULTIVO',N'DURAZNO',N'Podredumbre parda del durazno'),
    (N'CULTIVO',N'FRIJOL',N'Antracnosis de frijol'),
    (N'CULTIVO',N'FRIJOL',N'Roya del frijol'),
    (N'CULTIVO',N'HABA',N'Mancha chocolate del haba'),
    (N'CULTIVO',N'HABA',N'Roya del haba'),
    (N'CULTIVO',N'QUINUA',N'Mildiu de quinua'),
    (N'CULTIVO',N'QUINUA',N'Mancha foliar de quinua'),
    (N'CULTIVO',N'TRIGO',N'Roya amarilla del trigo'),
    (N'CULTIVO',N'TRIGO',N'Septoriosis del trigo'),
    (N'CULTIVO',N'UVA',N'Oídio de la vid'),
    (N'CULTIVO',N'UVA',N'Mildiu de la vid'),
    (N'CRIANZA',N'BOVINO',N'Mastitis bovina'),
    (N'CRIANZA',N'BOVINO',N'Parasitismo gastrointestinal bovino'),
    (N'CRIANZA',N'OVINO',N'Parasitismo gastrointestinal ovino'),
    (N'CRIANZA',N'OVINO',N'Pododermatitis ovina'),
    (N'CRIANZA',N'CAPRINO',N'Neumonía caprina'),
    (N'CRIANZA',N'CAPRINO',N'Parasitismo gastrointestinal caprino'),
    (N'CRIANZA',N'PORCINO',N'Sarna porcina'),
    (N'CRIANZA',N'PORCINO',N'Diarrea posdestete porcina'),
    (N'CRIANZA',N'CUY',N'Salmonelosis del cuy'),
    (N'CRIANZA',N'CUY',N'Ectoparasitosis del cuy'),
    (N'CRIANZA',N'ALPACA',N'Sarna en alpacas'),
    (N'CRIANZA',N'ALPACA',N'Parasitismo gastrointestinal en alpacas'),
    (N'CRIANZA',N'LLAMA',N'Sarna en llamas'),
    (N'CRIANZA',N'LLAMA',N'Parasitismo gastrointestinal en llamas'),
    (N'CRIANZA',N'GALLINA',N'Coccidiosis aviar'),
    (N'CRIANZA',N'GALLINA',N'Coriza infecciosa aviar'),
    (N'CRIANZA',N'EQUINO',N'Parasitismo gastrointestinal equino'),
    (N'CRIANZA',N'EQUINO',N'Dermatofitosis equina'),
    (N'CRIANZA',N'CONEJO',N'Coccidiosis del conejo'),
    (N'CRIANZA',N'CONEJO',N'Sarna del conejo');

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO prod.GPProblema (cultivo_id, especie_pecuaria_id, nombre)
    SELECT C.cultivo_id, NULL, S.nombre
    FROM @Enfermedades S
    INNER JOIN prod.Cultivo C ON C.codigo = S.codigo AND C.estado = 1
    WHERE S.ambito = 'CULTIVO'
      AND NOT EXISTS (
          SELECT 1 FROM prod.GPProblema P WITH (UPDLOCK, HOLDLOCK)
          WHERE P.cultivo_id = C.cultivo_id AND P.especie_pecuaria_id IS NULL AND P.nombre = S.nombre
      );

    INSERT INTO prod.GPProblema (cultivo_id, especie_pecuaria_id, nombre)
    SELECT NULL, E.especie_pecuaria_id, S.nombre
    FROM @Enfermedades S
    INNER JOIN prod.EspeciePecuaria E ON E.codigo = S.codigo AND E.estado = 1
    WHERE S.ambito = 'CRIANZA'
      AND NOT EXISTS (
          SELECT 1 FROM prod.GPProblema P WITH (UPDLOCK, HOLDLOCK)
          WHERE P.cultivo_id IS NULL AND P.especie_pecuaria_id = E.especie_pecuaria_id AND P.nombre = S.nombre
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
