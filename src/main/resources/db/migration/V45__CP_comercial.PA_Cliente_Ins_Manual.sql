IF OBJECT_ID(N'[comercial].[PA_Cliente_Ins_Manual]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_Cliente_Ins_Manual];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_Cliente_Ins_Manual
' Descripción             : Registra manualmente un cliente para la operación comercial.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Comercial
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo de referencia: reemplazar valores e identificadores por datos válidos.
    DECLARE
        @nClientePersonaId BIGINT,
        @nClienteEmpresaId BIGINT,
        @bReutilizado BIT,
        @cTipoDocumentoResultado VARCHAR(15),
        @cNumeroDocumentoResultado VARCHAR(30),
        @cNombreCliente NVARCHAR(220),
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [comercial].[PA_Cliente_Ins_Manual]
        @nUsuarioId = 0,
        @nUotId = 0,
        @cTipoCliente = '',
        @cTipoDocumento = '',
        @cNumeroDocumento = '',
        @cNombres = N'',
        @cApellidoPaterno = N'',
        @cApellidoMaterno = N'',
        @cRazonSocial = N'',
        @cTelefono = '',
        @cCorreo = '',
        @nClientePersonaId = @nClientePersonaId OUTPUT,
        @nClienteEmpresaId = @nClienteEmpresaId OUTPUT,
        @bReutilizado = @bReutilizado OUTPUT,
        @cTipoDocumentoResultado = @cTipoDocumentoResultado OUTPUT,
        @cNumeroDocumentoResultado = @cNumeroDocumentoResultado OUTPUT,
        @cNombreCliente = @cNombreCliente OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nClientePersonaId, @nClienteEmpresaId, @bReutilizado, @cTipoDocumentoResultado, @cNumeroDocumentoResultado, @cNombreCliente, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [comercial].[PA_Cliente_Ins_Manual]
    @nUsuarioId BIGINT,@nUotId BIGINT,@cTipoCliente VARCHAR(10),@cTipoDocumento VARCHAR(15),@cNumeroDocumento VARCHAR(30),
    @cNombres NVARCHAR(100)=NULL,@cApellidoPaterno NVARCHAR(80)=NULL,@cApellidoMaterno NVARCHAR(80)=NULL,
    @cRazonSocial NVARCHAR(200)=NULL,@cTelefono VARCHAR(30)=NULL,@cCorreo VARCHAR(180)=NULL,
    @nClientePersonaId BIGINT OUTPUT,@nClienteEmpresaId BIGINT OUTPUT,@bReutilizado BIT OUTPUT,
    @cTipoDocumentoResultado VARCHAR(15) OUTPUT,@cNumeroDocumentoResultado VARCHAR(30) OUTPUT,@cNombreCliente NVARCHAR(220) OUTPUT,
    @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    SELECT @nClientePersonaId=NULL,@nClienteEmpresaId=NULL,@bReutilizado=0,@cNombreCliente=NULL,@bResultado=0,
           @cMensaje=N'No se pudo registrar el cliente.',@cCodigoRespuesta='CLIENTE_NO_REGISTRADO',@nHttpRespuesta=400;
    SELECT @cTipoCliente=UPPER(NULLIF(LTRIM(RTRIM(@cTipoCliente)),'')),
           @cTipoDocumento=UPPER(NULLIF(LTRIM(RTRIM(@cTipoDocumento)),'')),
           @cNumeroDocumento=UPPER(NULLIF(LTRIM(RTRIM(@cNumeroDocumento)),'')),
           @cNombres=NULLIF(LTRIM(RTRIM(@cNombres)),N''),@cApellidoPaterno=NULLIF(LTRIM(RTRIM(@cApellidoPaterno)),N''),
           @cApellidoMaterno=NULLIF(LTRIM(RTRIM(@cApellidoMaterno)),N''),@cRazonSocial=NULLIF(LTRIM(RTRIM(@cRazonSocial)),N''),
           @cTelefono=NULLIF(LTRIM(RTRIM(@cTelefono)),''),@cCorreo=LOWER(NULLIF(LTRIM(RTRIM(@cCorreo)),''));
    SELECT @cTipoDocumentoResultado=@cTipoDocumento,@cNumeroDocumentoResultado=@cNumeroDocumento;

    IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'POS_OPERAR')=0
    BEGIN SET @cMensaje=N'No tiene permiso para registrar clientes de una venta.'; SET @cCodigoRespuesta='NO_AUTORIZADO'; SET @nHttpRespuesta=403; RETURN 1; END;
    IF @cTipoCliente NOT IN('PERSONA','EMPRESA') OR @cTipoDocumento NOT IN('DNI','RUC') OR @cNumeroDocumento IS NULL
    BEGIN SET @cMensaje=N'Complete correctamente los datos del cliente.'; RETURN 1; END;
    IF (@cTipoDocumento='DNI' AND (LEN(@cNumeroDocumento)<>8 OR @cNumeroDocumento LIKE '%[^0-9]%'))
       OR (@cTipoDocumento='RUC' AND (LEN(@cNumeroDocumento)<>11 OR @cNumeroDocumento LIKE '%[^0-9]%'))
    BEGIN SET @cMensaje=N'El documento ingresado no es válido.'; RETURN 1; END;

    /*
     * La carga manual es un fallback del flujo POS:
     * DESCO local -> Factiliza -> manual.
     * No se permite saltar la consulta automática invocando este PA directamente.
     */
    DECLARE @cClaveConsulta VARCHAR(60),
            @cEstadoConsulta VARCHAR(25);

    SET @cClaveConsulta =
        CASE
            WHEN @cTipoCliente='EMPRESA'
                THEN 'RUC:' + @cNumeroDocumento
            WHEN @cTipoDocumento='DNI'
                THEN 'DNI:' + @cNumeroDocumento
            WHEN @cTipoDocumento='RUC' AND LEFT(@cNumeroDocumento,2)='10'
                THEN 'DNI:' + SUBSTRING(@cNumeroDocumento,3,8)
            ELSE 'RUC:' + @cNumeroDocumento
        END;

    SELECT TOP(1)
           @cEstadoConsulta=CD.estado_consulta
    FROM integracion.ConsultaDocumento CD
    WHERE CD.entidad_objetivo=@cTipoCliente
      AND CD.clave_documento=@cClaveConsulta
      AND CD.estado=1
    ORDER BY CD.consulta_documento_id DESC;

    IF @cEstadoConsulta IS NULL
       OR @cEstadoConsulta NOT IN('ERROR','NO_ENCONTRADO','DATOS_INSUFICIENTES')
    BEGIN
        SET @cMensaje=N'Busque primero el cliente. La carga manual solo se habilita cuando la validación automática no puede completarse.';
        SET @cCodigoRespuesta='VALIDACION_AUTOMATICA_REQUERIDA';
        SET @nHttpRespuesta=409;
        RETURN 1;
    END;

    BEGIN TRY
      SET TRANSACTION ISOLATION LEVEL SERIALIZABLE; BEGIN TRAN;
      IF @cTipoCliente='PERSONA'
      BEGIN
        IF @cNombres IS NULL OR @cApellidoPaterno IS NULL
        BEGIN ROLLBACK; SET @cMensaje=N'Complete los nombres y apellidos del cliente.'; RETURN 1; END;
        DECLARE @Clave VARCHAR(50)=CASE WHEN @cTipoDocumento='DNI' THEN 'DNI:'+@cNumeroDocumento
             WHEN @cTipoDocumento='RUC' AND LEFT(@cNumeroDocumento,2)='10' THEN 'DNI:'+SUBSTRING(@cNumeroDocumento,3,8)
             ELSE @cTipoDocumento+':'+@cNumeroDocumento END;
        SELECT @nClientePersonaId=persona_id,@cTipoDocumentoResultado=tipo_documento,@cNumeroDocumentoResultado=numero_documento,
               @cNombreCliente=LTRIM(RTRIM(CONCAT(nombres,N' ',apellido_paterno,N' ',COALESCE(apellido_materno,N''))))
        FROM org.Persona WITH(UPDLOCK,HOLDLOCK)
        WHERE documento_clave_desco=@Clave;
        IF @nClientePersonaId IS NULL
        BEGIN
          INSERT org.Persona(tipo_documento,numero_documento,nombres,apellido_paterno,apellido_materno,telefono,correo,estado,fecha_creacion,tipo_persona)
          VALUES(@cTipoDocumento,@cNumeroDocumento,@cNombres,@cApellidoPaterno,@cApellidoMaterno,@cTelefono,@cCorreo,1,SYSUTCDATETIME(),'NATURAL');
          SET @nClientePersonaId=SCOPE_IDENTITY();
          SET @cNombreCliente=LTRIM(RTRIM(CONCAT(@cNombres,N' ',@cApellidoPaterno,N' ',COALESCE(@cApellidoMaterno,N''))));
        END ELSE SET @bReutilizado=1;
      END
      ELSE
      BEGIN
        IF @cTipoDocumento<>'RUC' OR @cRazonSocial IS NULL
        BEGIN ROLLBACK; SET @cMensaje=N'Para una empresa ingrese RUC y razón social.'; RETURN 1; END;
        SELECT @nClienteEmpresaId=empresa_id,@cNumeroDocumentoResultado=ruc,@cNombreCliente=razon_social
        FROM org.Empresa WITH(UPDLOCK,HOLDLOCK) WHERE ruc=@cNumeroDocumento;
        IF @nClienteEmpresaId IS NULL
        BEGIN
          INSERT org.Empresa(ruc,razon_social,nombre_comercial,telefono,correo,fecha_creacion,estado)
          VALUES(@cNumeroDocumento,@cRazonSocial,NULL,@cTelefono,@cCorreo,SYSUTCDATETIME(),1);
          SET @nClienteEmpresaId=SCOPE_IDENTITY(); SET @cNombreCliente=@cRazonSocial;
        END ELSE SET @bReutilizado=1;
      END;
      COMMIT;
      SELECT @bResultado=1,
             @cMensaje=CASE WHEN @bReutilizado=1 THEN N'El cliente ya se encontraba registrado.' ELSE N'Cliente registrado correctamente.' END,
             @cCodigoRespuesta=CASE WHEN @bReutilizado=1 THEN 'CLIENTE_REUTILIZADO' ELSE 'CLIENTE_REGISTRADO' END,
             @nHttpRespuesta=200;
      RETURN 0;
    END TRY
    BEGIN CATCH
      IF XACT_STATE()<>0 ROLLBACK;
      IF ERROR_NUMBER() IN(2601,2627)
          SET @cMensaje=N'El documento ya se encuentra registrado. Vuelva a consultar el cliente.';
      ELSE SET @cMensaje=N'No se pudo registrar el cliente.';
      RETURN 1;
    END CATCH;
END;
GO
