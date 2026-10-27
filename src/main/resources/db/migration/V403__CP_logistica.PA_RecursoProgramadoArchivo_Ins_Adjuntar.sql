IF OBJECT_ID(N'[logistica].[PA_RecursoProgramadoArchivo_Ins_Adjuntar]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_RecursoProgramadoArchivo_Ins_Adjuntar];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_RecursoProgramadoArchivo_Ins_Adjuntar
' Descripción             : Vincula documentos locales a recursos patrimoniales programados.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Creación de vínculos de autorización por UOT.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Referencial: sustituir identificadores y valores por datos válidos.
    DECLARE @bResultado BIT,
            @cMensaje NVARCHAR(300);
    EXEC [logistica].[PA_RecursoProgramadoArchivo_Ins_Adjuntar]
        @nUsuarioId = 0,
        @nRecursoProgramadoId = 0,
        @nArchivoId = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE logistica.PA_RecursoProgramadoArchivo_Ins_Adjuntar
 @nUsuarioId BIGINT,@nRecursoProgramadoId BIGINT,@nArchivoId BIGINT,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @bResultado=0,@cMensaje=N'No se pudo vincular el documento.';
 DECLARE @Uot BIGINT;
 SELECT @Uot=COALESCE(C.uot_id,CO.uot_id,SC.uot_id)
 FROM logistica.RecursoProgramado R
 LEFT JOIN comercial.CampaniaVenta C ON C.campania_venta_id=R.campania_venta_id
 LEFT JOIN comercial.OperativoVenta O ON O.operativo_venta_id=R.operativo_venta_id
 LEFT JOIN comercial.CampaniaVenta CO ON CO.campania_venta_id=O.campania_venta_id
 LEFT JOIN campo.SalidaCampo SC ON SC.salida_campo_id=R.salida_campo_id
 WHERE R.recurso_programado_id=@nRecursoProgramadoId AND R.estado=1;
 IF @Uot IS NULL OR seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@Uot,'RECURSOS_EDITAR')=0
 BEGIN SET @cMensaje=N'No tiene permiso para modificar esta programación.';RETURN;END;
 IF NOT EXISTS(SELECT 1 FROM archivo.Archivo WHERE archivo_id=@nArchivoId AND uot_id=@Uot AND estado=1
  AND proveedor_almacenamiento='LOCAL' AND clave_almacenamiento IS NOT NULL)
 BEGIN SET @cMensaje=N'El documento no está disponible para esta UOT.';RETURN;END;
 BEGIN TRY
  BEGIN TRAN;
  IF NOT EXISTS(SELECT 1 FROM logistica.RecursoProgramadoArchivo WITH(UPDLOCK,HOLDLOCK) WHERE recurso_programado_id=@nRecursoProgramadoId AND archivo_id=@nArchivoId)
   INSERT logistica.RecursoProgramadoArchivo(recurso_programado_id,archivo_id,usuario_id)
   VALUES(@nRecursoProgramadoId,@nArchivoId,@nUsuarioId);
  COMMIT;
  SET @bResultado=1;SET @cMensaje=N'Documento vinculado correctamente.';
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  SET @cMensaje=N'No se pudo vincular el documento.';
 END CATCH;
END;
GO
