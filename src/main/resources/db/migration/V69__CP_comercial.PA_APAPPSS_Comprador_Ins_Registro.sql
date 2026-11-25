IF OBJECT_ID(N'[comercial].[PA_APAPPSS_Comprador_Ins_Registro]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_APAPPSS_Comprador_Ins_Registro];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_APAPPSS_Comprador_Ins_Registro
' Descripción            : Registra la información de apappss comprador.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_APAPPSS_Comprador_Ins_Registro
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT, @cCodigoRespuesta VARCHAR(60) OUTPUT, @nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo registrar al comprador.',
   @cCodigoRespuesta='APAPPSS_COMPRADOR_ERROR',@nHttpRespuesta=400;
 DECLARE @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
   @tipo VARCHAR(10)=UPPER(NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.tipo')),'')),
   @tipoDocumento VARCHAR(15)=UPPER(NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.tipoDocumento')),'')),
   @doc VARCHAR(30)=UPPER(NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.documento')),'')),
   @nombres NVARCHAR(100)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.nombres')),N''),
   @paterno NVARCHAR(80)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.apellidoPaterno')),N''),
   @materno NVARCHAR(80)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.apellidoMaterno')),N''),
   @razon NVARCHAR(200)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.razonSocial')),N''),
   @comercial NVARCHAR(160)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.nombreComercial')),N''),
   @telefono VARCHAR(30)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.telefono')),''),
   @correo VARCHAR(180)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.correo')),''),
   @fecha DATE=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaNacimiento'),23),
   @sexo VARCHAR(20)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.sexo')),''),
   @distrito CHAR(6)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.distritoCodigo')),''),
   @centro BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.centroPobladoId')),
   @referencia NVARCHAR(300)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.referencia')),N''),
   @persona BIGINT=NULL,@empresa BIGINT=NULL,@id BIGINT=NULL,@ubicacion BIGINT=NULL,@locked INT,
   @okUbicacion BIT,@msgUbicacion NVARCHAR(300),
   @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
   @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
   @acceso BIT,@mensajeAcceso NVARCHAR(300);
 BEGIN TRY
   IF @uot IS NULL OR @tipo NOT IN('PERSONA','EMPRESA') OR @doc IS NULL OR @tipoDocumento IS NULL
      THROW 51821,N'Identifique el comprador y la UOT.',1;
   IF (@tipoDocumento='RUC' AND @tipo<>'EMPRESA') OR (@tipoDocumento<>'RUC' AND @tipo<>'PERSONA')
      OR LEN(@tipoDocumento) NOT BETWEEN 2 AND 15
      OR @tipoDocumento LIKE '%[^A-Z0-9_]%' OR @doc LIKE '%[^A-Z0-9]%'
      OR (@tipoDocumento='DNI' AND (LEN(@doc)<>8 OR @doc LIKE '%[^0-9]%'))
      OR (@tipoDocumento='RUC' AND (LEN(@doc)<>11 OR @doc LIKE '%[^0-9]%'))
      OR (@tipoDocumento='CE' AND LEN(@doc) NOT BETWEEN 6 AND 20)
      OR (@tipoDocumento NOT IN('DNI','RUC','CE') AND LEN(@doc) NOT BETWEEN 5 AND 30)
      THROW 51822,N'El documento o tipo de persona no es válido.',1;
   IF NOT EXISTS(SELECT 1 FROM config.TipoDocumentoComprador WHERE codigo=@tipoDocumento AND estado=1)
      THROW 51822,N'El tipo de documento no está habilitado en Administración.',1;
   IF @correo IS NOT NULL AND @correo NOT LIKE '%_@_%._%'
      THROW 51822,N'Ingrese un correo válido.',1;
   IF @fecha>CONVERT(DATE,SYSUTCDATETIME()) OR
      (JSON_VALUE(@cJson,'$.datos.fechaNacimiento') IS NOT NULL AND @fecha IS NULL)
      THROW 51822,N'La fecha de nacimiento no es válida.',1;
   IF @distrito IS NOT NULL AND NOT EXISTS(SELECT 1 FROM geo.Distrito WHERE distrito_codigo=@distrito AND estado=1)
      THROW 51822,N'El distrito seleccionado no existe.',1;
   IF @centro IS NOT NULL AND (@distrito IS NULL OR NOT EXISTS(
      SELECT 1 FROM geo.CentroPoblado WHERE centro_poblado_id=@centro AND distrito_codigo=@distrito AND estado=1))
      THROW 51822,N'El centro poblado no corresponde al distrito.',1;
   EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='APAPPSS_COMPRADORES_CREAR',
     @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
     @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
     @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
     @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
   IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'APAPPSS_COMPRADORES_CREAR')<>1
      THROW 51823,N'No tiene permiso para registrar compradores.',1;
   IF NOT EXISTS (SELECT 1 FROM org.ConvenioUOTOrganizacion CU
      JOIN org.Empresa E ON E.empresa_id=CU.empresa_id AND E.ruc='20602771394' AND E.estado=1
      JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND CM.estado=1
      JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
      JOIN org.UOT U ON U.uot_id=CU.uot_id AND U.estado=1 AND U.es_raiz=0
      WHERE CU.uot_id=@uot AND CU.estado=1 AND CU.tipo_vinculo='ASOCIACION'
      AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())))
      AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()))))
      THROW 51824,N'La UOT no tiene convenio vigente con APAPPSS.',1;
   BEGIN TRANSACTION;
   DECLARE @lockName NVARCHAR(255)=CONCAT(N'APAPPSS:COMPRADOR:',@tipo,N':',@tipoDocumento,N':',@doc);
   EXEC @locked=sys.sp_getapplock @Resource=@lockName,@LockMode='Exclusive',
     @LockOwner='Transaction',@LockTimeout=5000;
   IF @locked<0 THROW 51825,N'El comprador está siendo registrado por otro usuario.',1;

   IF @tipo='PERSONA'
   BEGIN
     SELECT TOP(1) @persona=P.persona_id,@ubicacion=P.ubicacion_id
       FROM org.Persona P WITH(UPDLOCK,HOLDLOCK)
       WHERE P.tipo_documento=@tipoDocumento AND P.numero_documento=@doc
       ORDER BY P.persona_id;
     IF @persona IS NULL AND (@nombres IS NULL OR @paterno IS NULL)
       THROW 51822,N'Complete los nombres y apellido paterno de la persona.',1;
     IF @persona IS NOT NULL AND NOT EXISTS(SELECT 1 FROM org.Persona WHERE persona_id=@persona AND estado=1)
       THROW 51826,N'La persona existe pero está inactiva.',1;
   END
   ELSE
   BEGIN
     IF @doc='20602771394' THROW 51827,N'La asociación APAPPSS no puede ser su propio comprador.',1;
     SELECT TOP(1) @empresa=E.empresa_id,@ubicacion=E.ubicacion_id
       FROM org.Empresa E WITH(UPDLOCK,HOLDLOCK) WHERE E.ruc=@doc ORDER BY E.empresa_id;
     IF @empresa IS NULL AND @razon IS NULL
       THROW 51822,N'Ingrese la razón social de la empresa.',1;
     IF @empresa IS NOT NULL AND NOT EXISTS(SELECT 1 FROM org.Empresa WHERE empresa_id=@empresa AND estado=1)
       THROW 51828,N'La empresa existe pero está inactiva.',1;
   END;

   -- Sólo completar la ubicación si aún no existe o si se facilitan campos vacíos compatibles.
   IF @ubicacion IS NULL AND @distrito IS NOT NULL
   BEGIN
     EXEC geo.PA_Ubicacion_Ins_Interna @cDistritoCodigo=@distrito,
       @nCentroPobladoId=@centro,@cReferencia=@referencia,
       @nLatitud=NULL,@nLongitud=NULL,@nAltitudM=NULL,
       @nUbicacionId=@ubicacion OUTPUT,@bResultado=@okUbicacion OUTPUT,@cMensaje=@msgUbicacion OUTPUT;
     IF ISNULL(@okUbicacion,0)<>1 OR @ubicacion IS NULL
       THROW 51829,N'No se pudo registrar la ubicación del comprador.',1;
   END
   ELSE IF @ubicacion IS NOT NULL AND @distrito IS NOT NULL
   BEGIN
     IF EXISTS(SELECT 1 FROM geo.Ubicacion U WHERE U.ubicacion_id=@ubicacion AND U.distrito_codigo<>@distrito)
       THROW 51829,N'La ubicación existente no coincide con el distrito ingresado.',1;
     UPDATE geo.Ubicacion
       SET centro_poblado_id=COALESCE(centro_poblado_id,@centro),
           referencia=CASE WHEN NULLIF(TRIM(referencia),N'') IS NULL THEN @referencia ELSE referencia END
     WHERE ubicacion_id=@ubicacion AND estado=1
       AND ((centro_poblado_id IS NULL AND @centro IS NOT NULL)
         OR (NULLIF(TRIM(referencia),N'') IS NULL AND @referencia IS NOT NULL));
   END;

   IF @tipo='PERSONA'
   BEGIN
     IF @persona IS NULL
     BEGIN
       INSERT org.Persona(tipo_persona,tipo_documento,numero_documento,nombres,apellido_paterno,
         apellido_materno,telefono,correo,fecha_nacimiento,sexo,ubicacion_id,estado)
       VALUES('NATURAL',@tipoDocumento,@doc,@nombres,@paterno,@materno,@telefono,@correo,
         @fecha,@sexo,@ubicacion,1);
       SET @persona=CONVERT(BIGINT,SCOPE_IDENTITY());
     END
     ELSE
       UPDATE org.Persona SET
         nombres=CASE WHEN NULLIF(TRIM(nombres),N'') IS NULL THEN COALESCE(@nombres,nombres) ELSE nombres END,
         apellido_paterno=CASE WHEN NULLIF(TRIM(apellido_paterno),N'') IS NULL THEN COALESCE(@paterno,apellido_paterno) ELSE apellido_paterno END,
         apellido_materno=CASE WHEN NULLIF(TRIM(apellido_materno),N'') IS NULL THEN COALESCE(@materno,apellido_materno) ELSE apellido_materno END,
         telefono=CASE WHEN NULLIF(TRIM(telefono),'') IS NULL THEN COALESCE(@telefono,telefono) ELSE telefono END,
         correo=CASE WHEN NULLIF(TRIM(correo),'') IS NULL THEN COALESCE(@correo,correo) ELSE correo END,
         fecha_nacimiento=COALESCE(fecha_nacimiento,@fecha),sexo=COALESCE(NULLIF(TRIM(sexo),''),@sexo),
         ubicacion_id=COALESCE(ubicacion_id,@ubicacion)
       WHERE persona_id=@persona AND estado=1;
   END
   ELSE
   BEGIN
     IF @empresa IS NULL
     BEGIN
       INSERT org.Empresa(ruc,razon_social,nombre_comercial,telefono,correo,ubicacion_id,estado)
       VALUES(@doc,@razon,@comercial,@telefono,@correo,@ubicacion,1);
       SET @empresa=CONVERT(BIGINT,SCOPE_IDENTITY());
     END
     ELSE
       UPDATE org.Empresa SET
         razon_social=CASE WHEN NULLIF(TRIM(razon_social),N'') IS NULL THEN COALESCE(@razon,razon_social) ELSE razon_social END,
         nombre_comercial=CASE WHEN NULLIF(TRIM(nombre_comercial),N'') IS NULL THEN COALESCE(@comercial,nombre_comercial) ELSE nombre_comercial END,
         telefono=CASE WHEN NULLIF(TRIM(telefono),'') IS NULL THEN COALESCE(@telefono,telefono) ELSE telefono END,
         correo=CASE WHEN NULLIF(TRIM(correo),'') IS NULL THEN COALESCE(@correo,correo) ELSE correo END,
         ubicacion_id=COALESCE(ubicacion_id,@ubicacion)
       WHERE empresa_id=@empresa AND estado=1;
   END;

   SELECT @id=B.comprador_apappss_id FROM comercial.CompradorAPAPPSS B WITH(UPDLOCK,HOLDLOCK)
     WHERE B.uot_id=@uot AND ((@tipo='PERSONA' AND B.persona_id=@persona)
       OR (@tipo='EMPRESA' AND B.empresa_id=@empresa));
   IF @id IS NULL
   BEGIN
     INSERT comercial.CompradorAPAPPSS(uot_id,tipo,persona_id,empresa_id,estado)
       VALUES(@uot,@tipo,@persona,@empresa,1);
     SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
   END
   ELSE THROW 51830,N'El comprador ya se encuentra registrado.',1;
   SET @cDatos=(SELECT @id compradorId,@tipo tipo,@persona personaId,@empresa empresaId
     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
   COMMIT TRANSACTION;
   SELECT @bResultado=1,@cMensaje=N'Comprador registrado.',
     @cCodigoRespuesta='APAPPSS_COMPRADOR_OK',@nHttpRespuesta=201;
 END TRY BEGIN CATCH
   IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
   SELECT @cDatos=NULL,@bResultado=0,
     @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51820 AND 51849 THEN LEFT(ERROR_MESSAGE(),300)
       ELSE N'No se pudo registrar al comprador.' END,
     @cCodigoRespuesta='APAPPSS_COMPRADOR_ERROR',
     @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51820 AND 51849 OR ERROR_NUMBER() IN(2601,2627) THEN 409 ELSE 500 END;
 END CATCH;
END;
GO
