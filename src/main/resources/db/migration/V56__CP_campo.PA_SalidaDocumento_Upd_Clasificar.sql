IF OBJECT_ID(N'[campo].[PA_SalidaDocumento_Upd_Clasificar]') IS NOT NULL
    DROP PROCEDURE [campo].[PA_SalidaDocumento_Upd_Clasificar];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : campo.PA_SalidaDocumento_Upd_Clasificar
' Descripción            : Actualiza salida documento para clasificar.
' Aplicativo / Módulo    : DESCO / campo
*******************************************************************************************************/
CREATE   PROCEDURE campo.PA_SalidaDocumento_Upd_Clasificar
 @nUsuarioId BIGINT,@nUotId BIGINT,@nSalidaId BIGINT,
 @nArchivoId BIGINT,@cTipo VARCHAR(40)
AS
BEGIN
 SET NOCOUNT ON;
 IF @cTipo NOT IN('SOLICITUD_GENERADA','SOLICITUD_FIRMADA','EVIDENCIA_SALIDA')
   THROW 51320,N'El tipo documental no está permitido.',1;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'SALIDAS_EDITAR')<>1
   THROW 51321,N'No tiene permiso para administrar documentos de la salida.',1;
 IF NOT EXISTS(SELECT 1 FROM campo.SalidaE2 E
     JOIN seg.Usuario U ON U.usuario_id=@nUsuarioId
     WHERE E.salida_campo_id=@nSalidaId AND E.uot_id=@nUotId
       AND E.solicitante_empleado_id=U.persona_id
       AND E.estado NOT IN('BORRADOR','ELIMINADA'))
   THROW 51322,N'La salida todavía no fue solicitada o no le pertenece.',1;
 IF NOT EXISTS(SELECT 1 FROM archivo.Archivo A
     JOIN archivo.ArchivoVinculo V ON V.archivo_id=A.archivo_id AND V.estado=1
     WHERE A.archivo_id=@nArchivoId AND A.usuario_id=@nUsuarioId
       AND A.uot_id=@nUotId AND A.estado=1
       AND A.proveedor_almacenamiento='LOCAL' AND V.salida_campo_id=@nSalidaId)
   THROW 51323,N'El archivo no corresponde al solicitante y a la salida.',1;
 IF @cTipo='SOLICITUD_GENERADA' AND EXISTS(SELECT 1 FROM archivo.Archivo
   WHERE archivo_id=@nArchivoId AND mime_type<>'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
   THROW 51324,N'El documento generado debe ser Word.',1;
 UPDATE archivo.Archivo SET tipo_evidencia=@cTipo
   WHERE archivo_id=@nArchivoId AND usuario_id=@nUsuarioId;
END;
GO
