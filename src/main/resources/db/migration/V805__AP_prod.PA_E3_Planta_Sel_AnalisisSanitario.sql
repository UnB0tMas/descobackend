IF OBJECT_ID(N'[prod].[PA_E3_Planta_Sel_AnalisisSanitario]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_E3_Planta_Sel_AnalisisSanitario];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_E3_Planta_Sel_AnalisisSanitario
' Descripción            : Consulta e3 planta para analisis sanitario.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_E3_Planta_Sel_AnalisisSanitario
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No fue posible completar la operación.',@cCodigoRespuesta='E3_ERROR',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@planta BIGINT,@episodio BIGINT,@now DATETIME2(0)=SYSUTCDATETIME();
 BEGIN TRY
 EXEC prod.PA_E3_Sel_ValidarContexto @cJson,'APAPPSS_PREDIOS_VER',@usuario OUTPUT,@planta OUTPUT,@episodio OUTPUT;

 DECLARE @estadoPlanta VARCHAR(16)=(SELECT estado_actual FROM prod.PlantaPaltaE3 WHERE planta_id=@planta);
 SET @cDatos=(SELECT @planta plantaId,
  (SELECT COUNT_BIG(*) FROM sanidad.EpisodioPlantaE3 E WHERE E.planta_id=@planta AND E.activo=1) totalEnfermedades,
  (SELECT COUNT_BIG(*) FROM sanidad.EpisodioPlantaE3 E WHERE E.planta_id=@planta AND E.activo=1 AND E.fin IS NULL AND @estadoPlanta<>'MUERTA') enfermedadesVigentes,
  (SELECT COUNT_BIG(*) FROM sanidad.EpisodioPlantaE3 E WHERE E.planta_id=@planta AND E.activo=1 AND E.fin IS NOT NULL AND E.cierre_por_muerte=0) enfermedadesRecuperadas,
  (SELECT COUNT_BIG(*) FROM sanidad.EpisodioPlantaE3 E WHERE E.planta_id=@planta AND E.activo=1 AND (E.cierre_por_muerte=1 OR (@estadoPlanta='MUERTA' AND E.fin IS NULL))) enfermedadesNoControladas,
  (SELECT COUNT_BIG(*) FROM sanidad.TratamientoPlantaE3 T JOIN sanidad.EpisodioPlantaE3 E ON E.episodio_id=T.episodio_id
   WHERE E.planta_id=@planta AND E.activo=1) tratamientosAplicados,
  (SELECT MAX(T.fecha_aplicacion) FROM sanidad.TratamientoPlantaE3 T JOIN sanidad.EpisodioPlantaE3 E ON E.episodio_id=T.episodio_id
   WHERE E.planta_id=@planta AND E.activo=1) ultimoTratamiento,
  (SELECT COUNT_BIG(*) FROM prod.PlantaComentarioE3 C WHERE C.planta_id=@planta) totalComentarios,
  (SELECT TOP(1) P.estado_actual FROM prod.PlantaPaltaE3 P WHERE P.planta_id=@planta) estadoPlanta
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);

 SELECT @bResultado=1,@cMensaje=N'Operación realizada.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
  SELECT @bResultado=0,@cDatos=NULL,@nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN 400 ELSE 503 END,
    @cCodigoRespuesta='E3_ERROR',
    @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN ERROR_MESSAGE() ELSE N'No se pudo completar la operación.' END;
 END CATCH;
END;
GO
