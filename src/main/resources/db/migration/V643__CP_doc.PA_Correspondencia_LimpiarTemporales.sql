-- Retira cargas temporales abandonadas después de siete días, salvo archivos en borradores.
IF OBJECT_ID(N'[doc].[PA_Correspondencia_LimpiarTemporales]',N'P') IS NOT NULL
    DROP PROCEDURE [doc].[PA_Correspondencia_LimpiarTemporales];
GO

CREATE PROCEDURE doc.PA_Correspondencia_LimpiarTemporales
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @Eliminados TABLE(clave_almacenamiento NVARCHAR(1000) NOT NULL);
    BEGIN TRANSACTION;
    ;WITH Caducados AS
    (
        SELECT TOP (50) A.archivo_id
        FROM archivo.Archivo A WITH (UPDLOCK,READPAST,ROWLOCK)
        WHERE A.categoria='CORRESPONDENCIA' AND A.proveedor_almacenamiento='LOCAL'
          AND A.clave_almacenamiento IS NOT NULL AND A.estado=1
          AND A.fecha_carga<DATEADD(DAY,-7,SYSUTCDATETIME())
          AND NOT EXISTS(SELECT 1 FROM doc.DocumentoArchivo DA WHERE DA.archivo_id=A.archivo_id)
          AND NOT EXISTS(
              SELECT 1 FROM doc.Borrador B
              CROSS APPLY OPENJSON(B.contenido,'$.adjuntosGuardados') J
              WHERE TRY_CONVERT(BIGINT,JSON_VALUE(J.[value],'$.archivoId'))=A.archivo_id)
        ORDER BY A.fecha_carga,A.archivo_id
    )
    UPDATE A
    SET estado=0
    OUTPUT inserted.clave_almacenamiento INTO @Eliminados(clave_almacenamiento)
    FROM archivo.Archivo A
    JOIN Caducados C ON C.archivo_id=A.archivo_id;
    COMMIT;
    SELECT clave_almacenamiento FROM @Eliminados;
END;
GO
