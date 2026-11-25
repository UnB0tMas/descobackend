-- Incorporar especies comunes sin duplicar registros existentes.
IF OBJECT_ID(N'prod.EspeciePecuaria', N'U') IS NULL
BEGIN
    THROW 51000, N'No existe el catálogo de especies.', 1;
END;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @Especies TABLE (
    codigo VARCHAR(30) NOT NULL PRIMARY KEY,
    nombre NVARCHAR(90) NOT NULL,
    descripcion NVARCHAR(500) NOT NULL
);

INSERT INTO @Especies (codigo, nombre, descripcion)
VALUES
        ('BOVINO', N'Bovino', N'Ganado vacuno'),
        ('OVINO', N'Ovino', N'Ganado ovino'),
        ('CAPRINO', N'Caprino', N'Ganado caprino'),
        ('PORCINO', N'Porcino', N'Ganado porcino'),
        ('CUY', N'Cuy', N'Crianza de cuyes'),
        ('ALPACA', N'Alpaca', N'Camélido sudamericano'),
        ('LLAMA', N'Llama', N'Camélido sudamericano'),
        ('GALLINA', N'Gallina', N'Aves de corral'),
        ('EQUINO', N'Equino', N'Ganado equino'),
        ('CONEJO', N'Conejo', N'Crianza de conejos');

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO prod.EspeciePecuaria (codigo, nombre, descripcion)
    SELECT S.codigo, S.nombre, S.descripcion
    FROM @Especies S
    WHERE NOT EXISTS (
        SELECT 1
        FROM prod.EspeciePecuaria E WITH (UPDLOCK, HOLDLOCK)
        WHERE E.codigo = S.codigo OR E.nombre = S.nombre
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
