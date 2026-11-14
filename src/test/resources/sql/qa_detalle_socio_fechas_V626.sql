-- Verificación de lectura: no realiza cambios de datos.
SET NOCOUNT ON;
IF OBJECT_ID(N'org.PA_Socio_Sel_DetalleCompleto',N'P') IS NULL
    THROW 52611,N'No existe el detalle de socios.',1;
DECLARE @definicion NVARCHAR(MAX)=OBJECT_DEFINITION(OBJECT_ID(N'org.PA_Socio_Sel_DetalleCompleto',N'P'));
IF CHARINDEX(N'CONVERT(DATE,PCS.fecha_registro) AS fecha_registro',@definicion)=0
    THROW 52612,N'La fecha de inscripción a campaña no se convierte al tipo DATE.',1;
IF NOT EXISTS(
    SELECT 1 FROM sys.columns C
    JOIN sys.tables T ON C.object_id=T.object_id
    JOIN sys.schemas S ON S.schema_id=T.schema_id
    JOIN sys.types TY ON TY.user_type_id=C.user_type_id
    WHERE S.name=N'comercial' AND T.name=N'ParticipacionCampaniaSocio'
      AND C.name=N'fecha_registro' AND TY.name=N'datetime2')
    THROW 52613,N'La columna origen cambió: revisar compatibilidad del detalle de socios.',1;
SELECT TOP (10)
    P.participacion_campania_socio_id AS participacionId,
    P.fecha_registro AS fechaOriginal,
    CONVERT(DATE,P.fecha_registro) AS fechaFicha
FROM comercial.ParticipacionCampaniaSocio P
ORDER BY P.fecha_registro DESC;
PRINT N'QA_OK: fecha de campaña compatible con la ficha del socio. Sin cambios en base de datos.';
