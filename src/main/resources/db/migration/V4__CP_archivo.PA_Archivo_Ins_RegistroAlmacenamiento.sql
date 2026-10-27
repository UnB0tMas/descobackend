IF OBJECT_ID(N'[archivo].[PA_Archivo_Ins_RegistroAlmacenamiento]', N'P') IS NOT NULL
    DROP PROCEDURE [archivo].[PA_Archivo_Ins_RegistroAlmacenamiento];
GO

/******************************************************************************************************
' Nombre del PA           : archivo.PA_Archivo_Ins_RegistroAlmacenamiento
' Descripción             : Registra metadatos del archivo y su ubicación de almacenamiento.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Archivo
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo. Sustituir JSON, IDs y valores por datos válidos del entorno.
    DECLARE
        @nArchivoId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300);
    EXEC [archivo].[PA_Archivo_Ins_RegistroAlmacenamiento]
        @nUsuarioId = 1,
        @nUotId = 1,
        @cNombreOriginal = N'ejemplo.pdf',
        @cMimeType = 'application/pdf',
        @cProveedor = 'CLOUDINARY',
        @cClave = N'clave-del-almacenamiento',
        @cUrl = N'https://ejemplo.invalid/archivo.pdf',
        @nArchivoId = @nArchivoId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @nArchivoId, @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE archivo.PA_Archivo_Ins_RegistroAlmacenamiento
 @nUsuarioId BIGINT,@nUotId BIGINT,@cNombreOriginal NVARCHAR(255),@cMimeType VARCHAR(120),@cProveedor VARCHAR(20),
 @cClave NVARCHAR(1000),@cUrl NVARCHAR(1000)=NULL,@nTamano BIGINT=NULL,@cCategoria VARCHAR(30)=NULL,@cDescripcion NVARCHAR(400)=NULL,
 @nArchivoId BIGINT OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET @nArchivoId=NULL; SET @bResultado=0; SET @cMensaje=N'No se pudo registrar el archivo.';
 IF seg.FN_Usuario_TieneAccesoUOT(@nUsuarioId,@nUotId)=0 BEGIN SET @cMensaje=N'No tiene acceso a la UOT seleccionada.'; RETURN; END;
 SET @cProveedor=UPPER(NULLIF(LTRIM(RTRIM(@cProveedor)),'')); SET @cNombreOriginal=NULLIF(LTRIM(RTRIM(@cNombreOriginal)),N''); SET @cClave=NULLIF(LTRIM(RTRIM(@cClave)),N'');
 SET @cCategoria=UPPER(NULLIF(LTRIM(RTRIM(@cCategoria)),''));
 IF @cProveedor IS NULL OR @cProveedor NOT IN('LOCAL','SERVIDOR','S3','CLOUDINARY','OTRO') OR @cNombreOriginal IS NULL OR @cClave IS NULL OR NULLIF(LTRIM(RTRIM(@cMimeType)),'') IS NULL
 BEGIN SET @cMensaje=N'Complete correctamente los datos del archivo.'; RETURN; END;
 IF @cCategoria IS NOT NULL AND @cCategoria NOT IN('FOTOGRAFIA','DOCUMENTO','TICKET','COMPROBANTE','OTRO')
 BEGIN SET @cMensaje=N'La categoría del archivo no es válida.'; RETURN; END;
 IF @nTamano IS NOT NULL AND @nTamano<0 BEGIN SET @cMensaje=N'El tamaño del archivo no es válido.'; RETURN; END;
 INSERT archivo.Archivo(nombre_original,mime_type,cloudinary_public_id,secure_url,tamano_bytes,usuario_id,fecha_carga,estado,categoria,origen_captura,descripcion,uot_id,proveedor_almacenamiento,clave_almacenamiento,url_almacenamiento)
 VALUES(@cNombreOriginal,@cMimeType,CASE WHEN @cProveedor='CLOUDINARY' THEN LEFT(@cClave,255) ELSE NULL END,CASE WHEN @cProveedor='CLOUDINARY' THEN @cUrl ELSE NULL END,@nTamano,@nUsuarioId,SYSUTCDATETIME(),1,@cCategoria,'CARGA',@cDescripcion,@nUotId,@cProveedor,@cClave,@cUrl);
 SET @nArchivoId=SCOPE_IDENTITY(); SET @bResultado=1; SET @cMensaje=N'Archivo registrado correctamente.';
END;
GO
