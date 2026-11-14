-- Corrección puntual: fecha de inscripción a campaña en ficha de socio.
-- V625 está aplicada: no alterar migraciones históricas ni eliminar datos.
-- Se actualiza únicamente la expresión que devuelve DATETIME2 para un campo LocalDate.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DECLARE @objeto INT = OBJECT_ID(N'org.PA_Socio_Sel_DetalleCompleto',N'P');
IF @objeto IS NULL
    THROW 52601,N'No se encontró el procedimiento de detalle de socios.',1;

DECLARE @definicion NVARCHAR(MAX) = OBJECT_DEFINITION(@objeto);
DECLARE @origen NVARCHAR(200) = N'PCS.estado_participacion,PCS.fecha_registro';
DECLARE @destino NVARCHAR(250) = N'PCS.estado_participacion,CONVERT(DATE,PCS.fecha_registro) AS fecha_registro';
IF @definicion IS NULL
    THROW 52602,N'No fue posible obtener la definición del procedimiento.',1;

-- Si otro despliegue ya realizó la corrección, no generar diferencias adicionales.
IF CHARINDEX(@destino,@definicion)=0
BEGIN
    IF CHARINDEX(@origen,@definicion)=0
        THROW 52603,N'La consulta de campañas cambió: requiere revisión antes de modificarla.',1;
    SET @definicion=REPLACE(@definicion,@origen,@destino);
    -- OBJECT_DEFINITION devuelve la sentencia de creación del procedimiento.
    -- EXEC sp_executesql permite reemplazarlo sin afectar otros procedimientos.
    DECLARE @inicio INT=PATINDEX(N'%CREATE PROCEDURE%',@definicion);
    IF @inicio>0
        SET @definicion=STUFF(@definicion,@inicio,LEN(N'CREATE PROCEDURE'),N'ALTER PROCEDURE');
    ELSE IF PATINDEX(N'%CREATE OR ALTER PROCEDURE%',@definicion)=0
            AND PATINDEX(N'%ALTER PROCEDURE%',@definicion)=0
        THROW 52604,N'No se reconoció el encabezado del procedimiento de socios.',1;
    EXEC sys.sp_executesql @definicion;
END;

IF CHARINDEX(@destino,OBJECT_DEFINITION(@objeto))=0
    THROW 52605,N'No se pudo verificar la corrección de fecha de la ficha del socio.',1;
GO
