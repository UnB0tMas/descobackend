IF OBJECT_ID(N'[prod].[PA_E3_Archivo_Sel_Listado]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_E3_Archivo_Sel_Listado];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_E3_Archivo_Sel_Listado
' Descripción            : Consulta información de E3 Archivo (listado).
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_E3_Archivo_Sel_Listado
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudieron consultar los archivos.',
   @cCodigoRespuesta='E3_ERROR',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@planta BIGINT,@episodio BIGINT;
 BEGIN TRY
  EXEC prod.PA_E3_Sel_ValidarContexto @cJson,'APAPPSS_PREDIOS_VER',
   @usuario OUTPUT,@planta OUTPUT,@episodio OUTPUT;
  SET @cDatos=(SELECT JSON_QUERY((
   SELECT X.archivoId,X.nombre,X.mimeType,X.categoria,X.descripcion,X.tipo,
      X.aplicacionId,X.episodioId,X.enfermedad,X.fechaCarga,X.usuarioNombre,X.[local],X.url
   FROM (
     SELECT A.archivo_id archivoId,A.nombre_original nombre,A.mime_type mimeType,
       A.categoria,A.descripcion,CONVERT(VARCHAR(20),'GENERAL') tipo,
       CONVERT(BIGINT,NULL) aplicacionId,CONVERT(BIGINT,NULL) episodioId,
       CONVERT(NVARCHAR(120),NULL) enfermedad,
       CONVERT(VARCHAR(19),A.fecha_carga,126)+'Z' fechaCarga,
       seg.FN_Usuario_NombreCompleto(U.usuario_id) usuarioNombre,
       CONVERT(BIT,CASE WHEN A.proveedor_almacenamiento='LOCAL' THEN 1 ELSE 0 END) [local],
       A.secure_url url
     FROM prod.PlantaEvidenciaE3 E
     JOIN archivo.Archivo A ON A.archivo_id=E.archivo_id AND A.estado=1
     LEFT JOIN seg.Usuario U ON U.usuario_id=A.usuario_id
     WHERE E.planta_id=@planta
     UNION ALL
     SELECT A.archivo_id,A.nombre_original,A.mime_type,A.categoria,A.descripcion,
       CONVERT(VARCHAR(20),'TRATAMIENTO'),T.aplicacion_id,E.episodio_id,
       CONVERT(NVARCHAR(120),COALESCE(GP.nombre,TP.nombre)),
       CONVERT(VARCHAR(19),A.fecha_carga,126)+'Z',seg.FN_Usuario_NombreCompleto(U.usuario_id),CONVERT(BIT,1),
       A.secure_url
     FROM sanidad.TratamientoArchivoE4 TA
     JOIN sanidad.TratamientoAplicacionE4 T ON T.aplicacion_id=TA.aplicacion_id
     JOIN sanidad.EpisodioPlantaE3 E ON E.episodio_id=T.episodio_id
     JOIN archivo.Archivo A ON A.archivo_id=TA.archivo_id AND A.estado=1 AND A.proveedor_almacenamiento='LOCAL'
     LEFT JOIN seg.Usuario U ON U.usuario_id=TA.usuario_id
     LEFT JOIN prod.GPProblema GP ON GP.problema_id=E.gp_problema_id
     LEFT JOIN sanidad.TipoProblemaFitosanitario TP ON TP.tipo_problema_fitosanitario_id=E.tipo_problema_fitosanitario_id
     WHERE E.planta_id=@planta
   ) X ORDER BY X.fechaCarga DESC,X.archivoId DESC FOR JSON PATH
  )) items FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Archivos consultados.',@cCodigoRespuesta='E3_OK',@nHttpRespuesta=200;
 END TRY
 BEGIN CATCH
  SELECT @cDatos=NULL,@bResultado=0,
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN 400 ELSE 503 END,
   @cCodigoRespuesta='E3_ERROR',
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51200 AND 51299 THEN ERROR_MESSAGE()
     ELSE N'No se pudieron consultar los archivos.' END;
 END CATCH;
END;
GO
