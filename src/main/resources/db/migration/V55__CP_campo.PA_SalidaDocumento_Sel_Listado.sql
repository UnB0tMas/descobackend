IF OBJECT_ID(N'[campo].[PA_SalidaDocumento_Sel_Listado]') IS NOT NULL
    DROP PROCEDURE [campo].[PA_SalidaDocumento_Sel_Listado];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : campo.PA_SalidaDocumento_Sel_Listado
' Descripción            : Consulta información de Salida Documento (listado).
' Aplicativo / Módulo    : DESCO / campo
*******************************************************************************************************/
CREATE   PROCEDURE campo.PA_SalidaDocumento_Sel_Listado
 @nUsuarioId BIGINT,@nUotId BIGINT=NULL,@nSalidaId BIGINT=NULL,
 @bSoloPropios BIT=1
AS
BEGIN
 SET NOCOUNT ON;
 SELECT A.archivo_id archivoId,V.salida_campo_id salidaId,
    E.nombre salidaNombre,A.nombre_original nombreOriginal,
    A.mime_type mimeType,A.tipo_evidencia tipo,A.fecha_carga fechaCarga,
    A.tamano_bytes tamanoBytes
 FROM archivo.ArchivoVinculo V
 JOIN archivo.Archivo A ON A.archivo_id=V.archivo_id AND A.estado=1
 JOIN campo.SalidaE2 E ON E.salida_campo_id=V.salida_campo_id
 WHERE V.estado=1 AND E.estado<>'ELIMINADA'
  AND A.proveedor_almacenamiento='LOCAL'
  AND A.tipo_evidencia IN('SOLICITUD_GENERADA','SOLICITUD_FIRMADA','EVIDENCIA_SALIDA')
  AND (@nUotId IS NULL OR E.uot_id=@nUotId)
  AND (@nSalidaId IS NULL OR E.salida_campo_id=@nSalidaId)
  AND (@bSoloPropios=0 OR A.usuario_id=@nUsuarioId)
  AND seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,E.uot_id,'SALIDAS_VER')=1
  AND (A.usuario_id=@nUsuarioId OR (@bSoloPropios=0 AND
       seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,E.uot_id,'SALIDAS_CONFIRMAR')=1))
 ORDER BY A.fecha_carga DESC,A.archivo_id DESC;
END;
GO
