IF OBJECT_ID(N'[prod].[PA_E3_Enfermedad_Sel_Listado]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_E3_Enfermedad_Sel_Listado];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_E3_Enfermedad_Sel_Listado
' Descripción            : Consulta información de E3 Enfermedad (listado).
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_E3_Enfermedad_Sel_Listado
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No fue posible completar la operación.',@cCodigoRespuesta='E3_ERROR',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@planta BIGINT,@episodio BIGINT,@now DATETIME2(0)=SYSUTCDATETIME();
 BEGIN TRY
 EXEC prod.PA_E3_Sel_ValidarContexto @cJson,'APAPPSS_PREDIOS_VER',@usuario OUTPUT,@planta OUTPUT,@episodio OUTPUT;

 SET @cDatos=(SELECT JSON_QUERY((SELECT E.episodio_id episodioId,E.gp_problema_id diagnosticoId,
  COALESCE(GP.nombre,TP.nombre) enfermedad,
  CASE WHEN E.activo=0 THEN 'ELIMINADA' WHEN E.fin IS NULL THEN 'VIGENTE' ELSE 'RECUPERADA' END estado,
  CONVERT(VARCHAR(19),E.inicio,126)+'Z' fechaDiagnostico,
  CASE WHEN E.fin IS NULL THEN NULL ELSE CONVERT(VARCHAR(19),E.fin,126)+'Z' END fechaCuracion,
  DATEDIFF(DAY,CONVERT(DATE,E.inicio),CONVERT(DATE,COALESCE(E.fin,@now)))+1 diasEnferma,
  E.usuario_apertura_id usuarioRegistroId,U.nombre_usuario registradoPor,
  (SELECT COUNT_BIG(*) FROM sanidad.TratamientoPlantaE3 T WHERE T.episodio_id=E.episodio_id) totalTratamientos
  FROM sanidad.EpisodioPlantaE3 E
  LEFT JOIN prod.GPProblema GP ON GP.problema_id=E.gp_problema_id
  LEFT JOIN sanidad.TipoProblemaFitosanitario TP ON TP.tipo_problema_fitosanitario_id=E.tipo_problema_fitosanitario_id
  LEFT JOIN seg.Usuario U ON U.usuario_id=E.usuario_apertura_id
  WHERE E.planta_id=@planta ORDER BY E.episodio_id DESC FOR JSON PATH)) items
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
