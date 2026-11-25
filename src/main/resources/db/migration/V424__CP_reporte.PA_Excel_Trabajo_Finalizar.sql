IF OBJECT_ID(N'[reporte].[PA_Excel_Trabajo_Finalizar]') IS NOT NULL
    DROP PROCEDURE [reporte].[PA_Excel_Trabajo_Finalizar];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : reporte.PA_Excel_Trabajo_Finalizar
' Descripción            : Ejecuta el proceso de excel trabajo finalizar.
' Aplicativo / Módulo    : DESCO / reporte
*******************************************************************************************************/
CREATE   PROCEDURE reporte.PA_Excel_Trabajo_Finalizar
 @nTrabajoId BIGINT,@bCorrecto BIT,@cClave NVARCHAR(250),@nFilas INT,@cMensaje NVARCHAR(200)
AS
BEGIN
 SET NOCOUNT ON;
 UPDATE reporte.TrabajoExcel SET estado=CASE WHEN @bCorrecto=1 THEN 'LISTO' ELSE 'ERROR' END,
    archivo_clave=CASE WHEN @bCorrecto=1 AND @cClave=CONCAT(N'exports/',@nTrabajoId,N'.xlsx') THEN @cClave ELSE NULL END,
    total_filas=CASE WHEN @bCorrecto=1 THEN @nFilas ELSE NULL END,
    mensaje=CASE WHEN @bCorrecto=1 THEN NULL ELSE LEFT(COALESCE(@cMensaje,N'No se pudo generar.'),200) END,
    actualizado_utc=SYSUTCDATETIME(),visto=0
 WHERE trabajo_id=@nTrabajoId AND estado='PROCESANDO';
END;
GO
