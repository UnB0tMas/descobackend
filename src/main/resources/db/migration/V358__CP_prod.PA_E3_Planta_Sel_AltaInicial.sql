IF OBJECT_ID(N'[prod].[PA_E3_Planta_Sel_AltaInicial]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_E3_Planta_Sel_AltaInicial];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_E3_Planta_Sel_AltaInicial
' Descripción            : Consulta e3 planta para alta inicial.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_E3_Planta_Sel_AltaInicial
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @bResultado=0,@cDatos=NULL,@cCodigoRespuesta='E3_ERROR',@cMensaje=N'No se pudo consultar el registro.',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@uot BIGINT,@conv BIGINT,@predio BIGINT;
 BEGIN TRY
  EXEC prod.PA_E3_Sel_ValidarPredio @cJson,'APAPPSS_PREDIOS_VER',@usuario OUTPUT,@uot OUTPUT,@conv OUTPUT,@predio OUTPUT;
  DECLARE @total BIGINT=(SELECT COUNT_BIG(*) FROM prod.PlantaPaltaE3 WHERE predio_id=@predio);
  SET @cDatos=(SELECT @total totalHistorico,CONVERT(BIT,CASE WHEN @total=0 THEN 1 ELSE 0 END) puedeCargaInicial FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Consulta realizada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  SELECT @bResultado=0,@cDatos=NULL,@cCodigoRespuesta='E3_ERROR',
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51300 AND 51399 THEN ERROR_MESSAGE() ELSE N'No se pudo consultar el registro.' END,
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51300 AND 51399 THEN 400 ELSE 503 END;
 END CATCH;
END;
GO
