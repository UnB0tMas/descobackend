-- Bootstrap de catálogos productivos. Solo añade entradas ausentes; no modifica históricos.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF OBJECT_ID(N'prod.GPProblemaTratamiento', N'U') IS NULL
BEGIN
    THROW 51000, N'No está disponible la relación de tratamientos.', 1;
END;
GO

DECLARE @Vinculos TABLE (
    ambito VARCHAR(10) NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    problema NVARCHAR(160) NOT NULL,
    tratamiento NVARCHAR(160) NOT NULL,
    PRIMARY KEY (ambito, codigo, problema, tratamiento)
);

INSERT INTO @Vinculos (ambito, codigo, problema, tratamiento)
VALUES
    (N'CULTIVO', N'PALTA', N'Pudrición radicular (Phytophthora)', N'Evaluación y manejo · Pudrición radicular (Phytophthora) (PALTA)'),
    (N'CULTIVO', N'PALTA', N'Pudrición radicular (Phytophthora)', N'Control y seguimiento · Pudrición radicular (Phytophthora) (PALTA)'),
    (N'CULTIVO', N'PALTA', N'Antracnosis de palta', N'Evaluación y manejo · Antracnosis de palta (PALTA)'),
    (N'CULTIVO', N'PALTA', N'Antracnosis de palta', N'Control y seguimiento · Antracnosis de palta (PALTA)'),
    (N'CULTIVO', N'PAPA', N'Tizón tardío de papa', N'Evaluación y manejo · Tizón tardío de papa (PAPA)'),
    (N'CULTIVO', N'PAPA', N'Tizón tardío de papa', N'Control y seguimiento · Tizón tardío de papa (PAPA)'),
    (N'CULTIVO', N'PAPA', N'Rhizoctoniasis de papa', N'Evaluación y manejo · Rhizoctoniasis de papa (PAPA)'),
    (N'CULTIVO', N'PAPA', N'Rhizoctoniasis de papa', N'Control y seguimiento · Rhizoctoniasis de papa (PAPA)'),
    (N'CULTIVO', N'MAIZ', N'Roya común del maíz', N'Evaluación y manejo · Roya común del maíz (MAIZ)'),
    (N'CULTIVO', N'MAIZ', N'Roya común del maíz', N'Control y seguimiento · Roya común del maíz (MAIZ)'),
    (N'CULTIVO', N'MAIZ', N'Tizón foliar del maíz', N'Evaluación y manejo · Tizón foliar del maíz (MAIZ)'),
    (N'CULTIVO', N'MAIZ', N'Tizón foliar del maíz', N'Control y seguimiento · Tizón foliar del maíz (MAIZ)'),
    (N'CULTIVO', N'ALFALFA', N'Antracnosis de alfalfa', N'Evaluación y manejo · Antracnosis de alfalfa (ALFALFA)'),
    (N'CULTIVO', N'ALFALFA', N'Antracnosis de alfalfa', N'Control y seguimiento · Antracnosis de alfalfa (ALFALFA)'),
    (N'CULTIVO', N'ALFALFA', N'Mildiu de alfalfa', N'Evaluación y manejo · Mildiu de alfalfa (ALFALFA)'),
    (N'CULTIVO', N'ALFALFA', N'Mildiu de alfalfa', N'Control y seguimiento · Mildiu de alfalfa (ALFALFA)'),
    (N'CULTIVO', N'ARVEJA', N'Oídio de arveja', N'Evaluación y manejo · Oídio de arveja (ARVEJA)'),
    (N'CULTIVO', N'ARVEJA', N'Oídio de arveja', N'Control y seguimiento · Oídio de arveja (ARVEJA)'),
    (N'CULTIVO', N'ARVEJA', N'Fusariosis de arveja', N'Evaluación y manejo · Fusariosis de arveja (ARVEJA)'),
    (N'CULTIVO', N'ARVEJA', N'Fusariosis de arveja', N'Control y seguimiento · Fusariosis de arveja (ARVEJA)'),
    (N'CULTIVO', N'CAFE', N'Roya del café', N'Evaluación y manejo · Roya del café (CAFE)'),
    (N'CULTIVO', N'CAFE', N'Roya del café', N'Control y seguimiento · Roya del café (CAFE)'),
    (N'CULTIVO', N'CAFE', N'Ojo de gallo del café', N'Evaluación y manejo · Ojo de gallo del café (CAFE)'),
    (N'CULTIVO', N'CAFE', N'Ojo de gallo del café', N'Control y seguimiento · Ojo de gallo del café (CAFE)'),
    (N'CULTIVO', N'CEBADA', N'Roya de cebada', N'Evaluación y manejo · Roya de cebada (CEBADA)'),
    (N'CULTIVO', N'CEBADA', N'Roya de cebada', N'Control y seguimiento · Roya de cebada (CEBADA)'),
    (N'CULTIVO', N'CEBADA', N'Mancha reticulada de cebada', N'Evaluación y manejo · Mancha reticulada de cebada (CEBADA)'),
    (N'CULTIVO', N'CEBADA', N'Mancha reticulada de cebada', N'Control y seguimiento · Mancha reticulada de cebada (CEBADA)'),
    (N'CULTIVO', N'DURAZNO', N'Abolladura del duraznero', N'Evaluación y manejo · Abolladura del duraznero (DURAZNO)'),
    (N'CULTIVO', N'DURAZNO', N'Abolladura del duraznero', N'Control y seguimiento · Abolladura del duraznero (DURAZNO)'),
    (N'CULTIVO', N'DURAZNO', N'Podredumbre parda del durazno', N'Evaluación y manejo · Podredumbre parda del durazno (DURAZNO)'),
    (N'CULTIVO', N'DURAZNO', N'Podredumbre parda del durazno', N'Control y seguimiento · Podredumbre parda del durazno (DURAZNO)'),
    (N'CULTIVO', N'FRIJOL', N'Antracnosis de frijol', N'Evaluación y manejo · Antracnosis de frijol (FRIJOL)'),
    (N'CULTIVO', N'FRIJOL', N'Antracnosis de frijol', N'Control y seguimiento · Antracnosis de frijol (FRIJOL)'),
    (N'CULTIVO', N'FRIJOL', N'Roya del frijol', N'Evaluación y manejo · Roya del frijol (FRIJOL)'),
    (N'CULTIVO', N'FRIJOL', N'Roya del frijol', N'Control y seguimiento · Roya del frijol (FRIJOL)'),
    (N'CULTIVO', N'HABA', N'Mancha chocolate del haba', N'Evaluación y manejo · Mancha chocolate del haba (HABA)'),
    (N'CULTIVO', N'HABA', N'Mancha chocolate del haba', N'Control y seguimiento · Mancha chocolate del haba (HABA)'),
    (N'CULTIVO', N'HABA', N'Roya del haba', N'Evaluación y manejo · Roya del haba (HABA)'),
    (N'CULTIVO', N'HABA', N'Roya del haba', N'Control y seguimiento · Roya del haba (HABA)'),
    (N'CULTIVO', N'QUINUA', N'Mildiu de quinua', N'Evaluación y manejo · Mildiu de quinua (QUINUA)'),
    (N'CULTIVO', N'QUINUA', N'Mildiu de quinua', N'Control y seguimiento · Mildiu de quinua (QUINUA)'),
    (N'CULTIVO', N'QUINUA', N'Mancha foliar de quinua', N'Evaluación y manejo · Mancha foliar de quinua (QUINUA)'),
    (N'CULTIVO', N'QUINUA', N'Mancha foliar de quinua', N'Control y seguimiento · Mancha foliar de quinua (QUINUA)'),
    (N'CULTIVO', N'TRIGO', N'Roya amarilla del trigo', N'Evaluación y manejo · Roya amarilla del trigo (TRIGO)'),
    (N'CULTIVO', N'TRIGO', N'Roya amarilla del trigo', N'Control y seguimiento · Roya amarilla del trigo (TRIGO)'),
    (N'CULTIVO', N'TRIGO', N'Septoriosis del trigo', N'Evaluación y manejo · Septoriosis del trigo (TRIGO)'),
    (N'CULTIVO', N'TRIGO', N'Septoriosis del trigo', N'Control y seguimiento · Septoriosis del trigo (TRIGO)'),
    (N'CULTIVO', N'UVA', N'Oídio de la vid', N'Evaluación y manejo · Oídio de la vid (UVA)'),
    (N'CULTIVO', N'UVA', N'Oídio de la vid', N'Control y seguimiento · Oídio de la vid (UVA)'),
    (N'CULTIVO', N'UVA', N'Mildiu de la vid', N'Evaluación y manejo · Mildiu de la vid (UVA)'),
    (N'CULTIVO', N'UVA', N'Mildiu de la vid', N'Control y seguimiento · Mildiu de la vid (UVA)'),
    (N'CRIANZA', N'BOVINO', N'Mastitis bovina', N'Evaluación y manejo · Mastitis bovina (BOVINO)'),
    (N'CRIANZA', N'BOVINO', N'Mastitis bovina', N'Control y seguimiento · Mastitis bovina (BOVINO)'),
    (N'CRIANZA', N'BOVINO', N'Parasitismo gastrointestinal bovino', N'Evaluación y manejo · Parasitismo gastrointestinal bovino (BOVINO)'),
    (N'CRIANZA', N'BOVINO', N'Parasitismo gastrointestinal bovino', N'Control y seguimiento · Parasitismo gastrointestinal bovino (BOVINO)'),
    (N'CRIANZA', N'OVINO', N'Parasitismo gastrointestinal ovino', N'Evaluación y manejo · Parasitismo gastrointestinal ovino (OVINO)'),
    (N'CRIANZA', N'OVINO', N'Parasitismo gastrointestinal ovino', N'Control y seguimiento · Parasitismo gastrointestinal ovino (OVINO)'),
    (N'CRIANZA', N'OVINO', N'Pododermatitis ovina', N'Evaluación y manejo · Pododermatitis ovina (OVINO)'),
    (N'CRIANZA', N'OVINO', N'Pododermatitis ovina', N'Control y seguimiento · Pododermatitis ovina (OVINO)'),
    (N'CRIANZA', N'CAPRINO', N'Neumonía caprina', N'Evaluación y manejo · Neumonía caprina (CAPRINO)'),
    (N'CRIANZA', N'CAPRINO', N'Neumonía caprina', N'Control y seguimiento · Neumonía caprina (CAPRINO)'),
    (N'CRIANZA', N'CAPRINO', N'Parasitismo gastrointestinal caprino', N'Evaluación y manejo · Parasitismo gastrointestinal caprino (CAPRINO)'),
    (N'CRIANZA', N'CAPRINO', N'Parasitismo gastrointestinal caprino', N'Control y seguimiento · Parasitismo gastrointestinal caprino (CAPRINO)'),
    (N'CRIANZA', N'PORCINO', N'Sarna porcina', N'Evaluación y manejo · Sarna porcina (PORCINO)'),
    (N'CRIANZA', N'PORCINO', N'Sarna porcina', N'Control y seguimiento · Sarna porcina (PORCINO)'),
    (N'CRIANZA', N'PORCINO', N'Diarrea posdestete porcina', N'Evaluación y manejo · Diarrea posdestete porcina (PORCINO)'),
    (N'CRIANZA', N'PORCINO', N'Diarrea posdestete porcina', N'Control y seguimiento · Diarrea posdestete porcina (PORCINO)'),
    (N'CRIANZA', N'CUY', N'Salmonelosis del cuy', N'Evaluación y manejo · Salmonelosis del cuy (CUY)'),
    (N'CRIANZA', N'CUY', N'Salmonelosis del cuy', N'Control y seguimiento · Salmonelosis del cuy (CUY)'),
    (N'CRIANZA', N'CUY', N'Ectoparasitosis del cuy', N'Evaluación y manejo · Ectoparasitosis del cuy (CUY)'),
    (N'CRIANZA', N'CUY', N'Ectoparasitosis del cuy', N'Control y seguimiento · Ectoparasitosis del cuy (CUY)'),
    (N'CRIANZA', N'ALPACA', N'Sarna en alpacas', N'Evaluación y manejo · Sarna en alpacas (ALPACA)'),
    (N'CRIANZA', N'ALPACA', N'Sarna en alpacas', N'Control y seguimiento · Sarna en alpacas (ALPACA)'),
    (N'CRIANZA', N'ALPACA', N'Parasitismo gastrointestinal en alpacas', N'Evaluación y manejo · Parasitismo gastrointestinal en alpacas (ALPACA)'),
    (N'CRIANZA', N'ALPACA', N'Parasitismo gastrointestinal en alpacas', N'Control y seguimiento · Parasitismo gastrointestinal en alpacas (ALPACA)'),
    (N'CRIANZA', N'LLAMA', N'Sarna en llamas', N'Evaluación y manejo · Sarna en llamas (LLAMA)'),
    (N'CRIANZA', N'LLAMA', N'Sarna en llamas', N'Control y seguimiento · Sarna en llamas (LLAMA)'),
    (N'CRIANZA', N'LLAMA', N'Parasitismo gastrointestinal en llamas', N'Evaluación y manejo · Parasitismo gastrointestinal en llamas (LLAMA)'),
    (N'CRIANZA', N'LLAMA', N'Parasitismo gastrointestinal en llamas', N'Control y seguimiento · Parasitismo gastrointestinal en llamas (LLAMA)'),
    (N'CRIANZA', N'GALLINA', N'Coccidiosis aviar', N'Evaluación y manejo · Coccidiosis aviar (GALLINA)'),
    (N'CRIANZA', N'GALLINA', N'Coccidiosis aviar', N'Control y seguimiento · Coccidiosis aviar (GALLINA)'),
    (N'CRIANZA', N'GALLINA', N'Coriza infecciosa aviar', N'Evaluación y manejo · Coriza infecciosa aviar (GALLINA)'),
    (N'CRIANZA', N'GALLINA', N'Coriza infecciosa aviar', N'Control y seguimiento · Coriza infecciosa aviar (GALLINA)'),
    (N'CRIANZA', N'EQUINO', N'Parasitismo gastrointestinal equino', N'Evaluación y manejo · Parasitismo gastrointestinal equino (EQUINO)'),
    (N'CRIANZA', N'EQUINO', N'Parasitismo gastrointestinal equino', N'Control y seguimiento · Parasitismo gastrointestinal equino (EQUINO)'),
    (N'CRIANZA', N'EQUINO', N'Dermatofitosis equina', N'Evaluación y manejo · Dermatofitosis equina (EQUINO)'),
    (N'CRIANZA', N'EQUINO', N'Dermatofitosis equina', N'Control y seguimiento · Dermatofitosis equina (EQUINO)'),
    (N'CRIANZA', N'CONEJO', N'Coccidiosis del conejo', N'Evaluación y manejo · Coccidiosis del conejo (CONEJO)'),
    (N'CRIANZA', N'CONEJO', N'Coccidiosis del conejo', N'Control y seguimiento · Coccidiosis del conejo (CONEJO)'),
    (N'CRIANZA', N'CONEJO', N'Sarna del conejo', N'Evaluación y manejo · Sarna del conejo (CONEJO)'),
    (N'CRIANZA', N'CONEJO', N'Sarna del conejo', N'Control y seguimiento · Sarna del conejo (CONEJO)');

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO prod.GPProblemaTratamiento (problema_id, tratamiento_id)
    SELECT P.problema_id, T.tratamiento_id
    FROM @Vinculos S
    INNER JOIN prod.GPProblema P ON P.nombre = S.problema AND P.estado = 1
    INNER JOIN prod.GPTratamiento T ON T.nombre = S.tratamiento AND T.estado = 1
    LEFT JOIN prod.Cultivo C ON C.cultivo_id = P.cultivo_id AND C.codigo = S.codigo
    LEFT JOIN prod.EspeciePecuaria E ON E.especie_pecuaria_id = P.especie_pecuaria_id AND E.codigo = S.codigo
    WHERE ((S.ambito = 'CULTIVO' AND C.cultivo_id IS NOT NULL)
        OR (S.ambito = 'CRIANZA' AND E.especie_pecuaria_id IS NOT NULL))
      AND NOT EXISTS (
          SELECT 1 FROM prod.GPProblemaTratamiento R WITH (UPDLOCK, HOLDLOCK)
          WHERE R.problema_id = P.problema_id AND R.tratamiento_id = T.tratamiento_id
      )
      AND NOT EXISTS (
          SELECT 1 FROM prod.GPProblemaTratamiento R WITH (UPDLOCK, HOLDLOCK)
          WHERE R.tratamiento_id = T.tratamiento_id AND R.problema_id <> P.problema_id
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
