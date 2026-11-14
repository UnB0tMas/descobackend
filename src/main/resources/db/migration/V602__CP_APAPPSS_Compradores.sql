-- Cada PA posee una responsabilidad. Se conserva el contrato JSON+6 parámetros de DESCO.
CREATE OR ALTER PROCEDURE comercial.PA_APAPPSS_Contexto_Sel
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT, @cCodigoRespuesta VARCHAR(60) OUTPUT, @nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo consultar APAPPSS.',@cCodigoRespuesta='APAPPSS_SIN_ACCESO',@nHttpRespuesta=403;
 DECLARE @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
 @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
 @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
 @acceso BIT,@mensajeAcceso NVARCHAR(300),@asociacion BIGINT,@convenio BIGINT,@nombre NVARCHAR(200);
 BEGIN TRY
   EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='CAMPANIAS_LISTAR',
     @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
     @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,@gSolicitudId=@sol OUTPUT,
     @cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,@bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
   IF @uot IS NULL OR ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'CAMPANIAS_LISTAR')<>1
      THROW 51801,N'No tiene permiso de campañas para la UOT seleccionada.',1;
   SELECT TOP(1) @asociacion=A.asociacion_id,@convenio=CU.convenio_uot_organizacion_id,@nombre=E.razon_social
   FROM org.Empresa E
   JOIN org.Asociacion A ON A.asociacion_id=E.empresa_id AND A.estado=1
   JOIN org.ConvenioUOTOrganizacion CU ON CU.empresa_id=E.empresa_id AND CU.uot_id=@uot AND CU.estado=1
   JOIN org.UOT U ON U.uot_id=CU.uot_id AND U.estado=1 AND U.es_raiz=0
   JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND CM.estado=1
   JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id AND ME.estado=1 AND ME.codigo='COMERCIALIZACION_ASOCIATIVA'
   WHERE E.ruc='20602771394' AND E.estado=1 AND CU.tipo_vinculo='ASOCIACION'
     AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())))
     AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())))
   ORDER BY CU.convenio_uot_organizacion_id DESC;
   IF @asociacion IS NULL THROW 51802,N'APAPPSS no tiene un convenio habilitado con la UOT seleccionada.',1;
   SET @cDatos=(SELECT @asociacion asociacionId,@uot uotId,@convenio convenioId,@nombre nombre,
      CAST('20602771394' AS VARCHAR(11)) ruc FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   SELECT @bResultado=1,@cCodigoRespuesta='APAPPSS_CONTEXTO_OK',@cMensaje=N'Asociación habilitada.',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
   SELECT @bResultado=0,@cDatos=NULL,@cMensaje=LEFT(ERROR_MESSAGE(),300),
      @cCodigoRespuesta='APAPPSS_SIN_ACCESO',@nHttpRespuesta=403;
 END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE comercial.PA_APAPPSS_Comprador_Sel_Listado
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT, @cCodigoRespuesta VARCHAR(60) OUTPUT, @nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudieron consultar compradores.',@cCodigoRespuesta='APAPPSS_COMPRADORES_ERROR',@nHttpRespuesta=403;
 DECLARE @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
   @pagina INT=COALESCE(TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.filtros.pagina')),1),
   @tamano INT=COALESCE(TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.filtros.tamano')),20),
   @buscar NVARCHAR(120)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.filtros.buscar')),N''),
   @tipo VARCHAR(10)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.filtros.tipo')),''),
   @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
   @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
   @acceso BIT,@mensajeAcceso NVARCHAR(300);
 BEGIN TRY
   EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='APAPPSS_COMPRADORES_LISTAR',
     @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
     @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
     @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
     @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
   IF ISNULL(@acceso,0)<>1 OR @uot IS NULL OR @pagina<1 OR @tamano NOT BETWEEN 1 AND 100
     OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'APAPPSS_COMPRADORES_LISTAR')<>1
     THROW 51811,N'No tiene autorización para consultar compradores.',1;
   IF @tipo IS NOT NULL AND @tipo NOT IN ('PERSONA','EMPRESA') THROW 51812,N'Tipo de comprador inválido.',1;
   IF NOT EXISTS (SELECT 1 FROM org.ConvenioUOTOrganizacion CU
      JOIN org.Empresa E ON E.empresa_id=CU.empresa_id AND E.ruc='20602771394' AND E.estado=1
      JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND CM.estado=1
      JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
      JOIN org.UOT U ON U.uot_id=CU.uot_id AND U.estado=1 AND U.es_raiz=0
      WHERE CU.uot_id=@uot AND CU.estado=1 AND CU.tipo_vinculo='ASOCIACION'
      AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())))
      AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()))))
     THROW 51813,N'La UOT no tiene el convenio APAPPSS vigente.',1;
   ;WITH Base AS (
     SELECT B.comprador_apappss_id compradorId,B.tipo,B.persona_id personaId,B.empresa_id empresaId,
       CASE WHEN B.tipo='PERSONA' THEN CONCAT(P.nombres,' ',P.apellido_paterno,' ',ISNULL(P.apellido_materno,'')) ELSE E.razon_social END nombre,
       CASE WHEN B.tipo='PERSONA' THEN P.numero_documento ELSE RTRIM(E.ruc) END documento,
       CASE WHEN B.tipo='PERSONA' THEN P.tipo_documento ELSE 'RUC' END tipoDocumento,
       CASE WHEN B.tipo='PERSONA' THEN P.telefono ELSE E.telefono END telefono,
       CASE WHEN B.tipo='PERSONA' THEN P.correo ELSE E.correo END correo,
       B.fecha_registro fechaRegistro
     FROM comercial.CompradorAPAPPSS B
     LEFT JOIN org.Persona P ON P.persona_id=B.persona_id
     LEFT JOIN org.Empresa E ON E.empresa_id=B.empresa_id
     WHERE B.uot_id=@uot AND B.estado=1 AND (@tipo IS NULL OR B.tipo=@tipo)
       AND (@buscar IS NULL OR (@buscar<>N'' AND
        (P.numero_documento LIKE N'%'+@buscar+N'%' OR E.ruc LIKE N'%'+@buscar+N'%'
         OR P.nombres LIKE N'%'+@buscar+N'%' OR P.apellido_paterno LIKE N'%'+@buscar+N'%'
         OR E.razon_social LIKE N'%'+@buscar+N'%')))
   )
   SELECT @cDatos=(SELECT (SELECT COUNT_BIG(*) FROM Base) totalRecords,
     @pagina pagina,@tamano tamano,
     JSON_QUERY((SELECT compradorId,tipo,personaId,empresaId,nombre,documento,tipoDocumento,telefono,correo,fechaRegistro
       FROM Base ORDER BY compradorId DESC OFFSET (@pagina-1)*@tamano ROWS FETCH NEXT @tamano ROWS ONLY FOR JSON PATH)) items
     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   SELECT @bResultado=1,@cMensaje=N'Compradores consultados.',@cCodigoRespuesta='APAPPSS_COMPRADORES_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
   SELECT @bResultado=0,@cDatos=NULL,@cMensaje=LEFT(ERROR_MESSAGE(),300),
     @cCodigoRespuesta='APAPPSS_COMPRADORES_ERROR',@nHttpRespuesta=403;
 END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE comercial.PA_APAPPSS_Comprador_Ins_Registro
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT, @cCodigoRespuesta VARCHAR(60) OUTPUT, @nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo registrar al comprador.',@cCodigoRespuesta='APAPPSS_COMPRADOR_ERROR',@nHttpRespuesta=400;
 DECLARE @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
   @tipo VARCHAR(10)=JSON_VALUE(@cJson,'$.datos.tipo'),
   @doc VARCHAR(20)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.documento')),''),
   @tipoDocumento VARCHAR(15)=JSON_VALUE(@cJson,'$.datos.tipoDocumento'),
   @nombres NVARCHAR(100)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.nombres')),N''),
   @paterno NVARCHAR(80)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.apellidoPaterno')),N''),
   @materno NVARCHAR(80)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.apellidoMaterno')),N''),
   @razon NVARCHAR(200)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.razonSocial')),N''),
   @comercial NVARCHAR(160)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.nombreComercial')),N''),
   @telefono VARCHAR(30)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.telefono')),''),
   @correo VARCHAR(180)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.correo')),''),
   @persona BIGINT,@empresa BIGINT,@id BIGINT,@locked INT,
   @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
   @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
   @acceso BIT,@mensajeAcceso NVARCHAR(300);
 BEGIN TRY
   IF @uot IS NULL OR @tipo NOT IN('PERSONA','EMPRESA') OR @doc IS NULL
      THROW 51821,N'Identifique el comprador y la UOT.',1;
   IF (@tipo='EMPRESA' AND (LEN(@doc)<>11 OR @doc LIKE '%[^0-9]%' OR @razon IS NULL))
      OR (@tipo='PERSONA' AND (@tipoDocumento NOT IN('DNI','CE') OR @nombres IS NULL OR @paterno IS NULL
      OR (@tipoDocumento='DNI' AND (LEN(@doc)<>8 OR @doc LIKE '%[^0-9]%'))
      OR (@tipoDocumento='CE' AND (LEN(@doc)<6 OR LEN(@doc)>20 OR @doc LIKE '%[^A-Za-z0-9]%'))))
      THROW 51822,N'El documento o los datos de identidad no son válidos.',1;
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
   DECLARE @lockName NVARCHAR(255)=CONCAT(N'APAPPSS:COMPRADOR:',@tipo,N':',@doc);
   EXEC @locked=sys.sp_getapplock @Resource=@lockName,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=5000;
   IF @locked<0 THROW 51825,N'El comprador está siendo registrado por otro usuario.',1;
   IF @tipo='PERSONA'
   BEGIN
     SELECT TOP(1) @persona=P.persona_id FROM org.Persona P WITH(UPDLOCK,HOLDLOCK)
       WHERE P.tipo_documento=@tipoDocumento AND P.numero_documento=@doc ORDER BY P.persona_id;
     IF @persona IS NULL
     BEGIN
       INSERT org.Persona(tipo_documento,numero_documento,nombres,apellido_paterno,apellido_materno,telefono,correo,estado)
       VALUES(@tipoDocumento,@doc,@nombres,@paterno,@materno,@telefono,@correo,1);
       SET @persona=CONVERT(BIGINT,SCOPE_IDENTITY());
     END;
     IF NOT EXISTS(SELECT 1 FROM org.Persona WHERE persona_id=@persona AND estado=1)
       THROW 51826,N'La persona existe pero no está activa.',1;
   END
   ELSE
   BEGIN
     IF @doc='20602771394' THROW 51827,N'La asociación APAPPSS no puede registrarse como su propio comprador.',1;
     SELECT TOP(1) @empresa=E.empresa_id FROM org.Empresa E WITH(UPDLOCK,HOLDLOCK)
       WHERE E.ruc=@doc ORDER BY E.empresa_id;
     IF @empresa IS NULL
     BEGIN
       INSERT org.Empresa(ruc,razon_social,nombre_comercial,telefono,correo,estado)
       VALUES(@doc,@razon,@comercial,@telefono,@correo,1);
       SET @empresa=CONVERT(BIGINT,SCOPE_IDENTITY());
     END;
     IF NOT EXISTS(SELECT 1 FROM org.Empresa WHERE empresa_id=@empresa AND estado=1)
       THROW 51828,N'La empresa existe pero no está activa.',1;
   END;
   SELECT @id=B.comprador_apappss_id FROM comercial.CompradorAPAPPSS B WITH(UPDLOCK,HOLDLOCK)
      WHERE B.uot_id=@uot AND ((@tipo='PERSONA' AND B.persona_id=@persona) OR (@tipo='EMPRESA' AND B.empresa_id=@empresa));
   IF @id IS NULL
   BEGIN
     INSERT comercial.CompradorAPAPPSS(uot_id,tipo,persona_id,empresa_id,estado)
       VALUES(@uot,@tipo,@persona,@empresa,1);
     SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
   END
   ELSE UPDATE comercial.CompradorAPAPPSS SET estado=1 WHERE comprador_apappss_id=@id;
   SET @cDatos=(SELECT @id compradorId,@tipo tipo,@persona personaId,@empresa empresaId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
   COMMIT TRANSACTION;
   SELECT @bResultado=1,@cMensaje=N'Comprador registrado.',@cCodigoRespuesta='APAPPSS_COMPRADOR_OK',@nHttpRespuesta=201;
 END TRY BEGIN CATCH
   IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
   SELECT @cDatos=NULL,@bResultado=0,
     @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51820 AND 51829 THEN LEFT(ERROR_MESSAGE(),300)
       ELSE N'No se pudo registrar al comprador.' END,
     @cCodigoRespuesta='APAPPSS_COMPRADOR_ERROR',
     @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51820 AND 51829 THEN 409 ELSE 500 END;
 END CATCH;
END;
GO
