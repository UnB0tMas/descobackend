IF OBJECT_ID(N'[prod].[PA_E3_Tratamiento_Sel_Listado]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_E3_Tratamiento_Sel_Listado];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_E3_Tratamiento_Sel_Listado
' Descripción            : Consulta información de E3 Tratamiento (listado).
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_E3_Tratamiento_Sel_Listado
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No fue posible completar la operación.',@cCodigoRespuesta='E3_ERROR',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@planta BIGINT,@episodio BIGINT,@now DATETIME2(0)=SYSUTCDATETIME();
 BEGIN TRY
 EXEC prod.PA_E3_Sel_ValidarContexto @cJson,'APAPPSS_PREDIOS_VER',@usuario OUTPUT,@planta OUTPUT,@episodio OUTPUT;
 IF @episodio IS NULL THROW 51215,N'Seleccione una enfermedad válida.',1;

 SET @cDatos=(SELECT JSON_QUERY((SELECT T.tratamiento_id tratamientoId,T.gp_tratamiento_id catalogoTratamientoId,
  T.descripcion,T.resultado,T.comentario,
  CONVERT(VARCHAR(19),T.fecha_aplicacion,126)+'Z' fechaAplicacion,
  CONVERT(VARCHAR(19),T.fecha_registro,126)+'Z' fechaRegistro,
  T.usuario_id usuarioId,seg.FN_Usuario_NombreCompleto(U.usuario_id) usuarioNombre,
  T.modificado_por_usuario_id modificadoPorUsuarioId,seg.FN_Usuario_NombreCompleto(UM.usuario_id) modificadoPorNombre,
  CASE WHEN T.modificado_en IS NULL THEN NULL ELSE CONVERT(VARCHAR(19),T.modificado_en,126)+'Z' END modificadoEn
  FROM sanidad.TratamientoPlantaE3 T LEFT JOIN seg.Usuario U ON U.usuario_id=T.usuario_id
  LEFT JOIN seg.Usuario UM ON UM.usuario_id=T.modificado_por_usuario_id
  WHERE T.episodio_id=@episodio ORDER BY T.tratamiento_id DESC FOR JSON PATH)) items
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
