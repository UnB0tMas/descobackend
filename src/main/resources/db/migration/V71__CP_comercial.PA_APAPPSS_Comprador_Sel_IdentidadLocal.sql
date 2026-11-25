IF OBJECT_ID(N'[comercial].[PA_APAPPSS_Comprador_Sel_IdentidadLocal]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_APAPPSS_Comprador_Sel_IdentidadLocal];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_APAPPSS_Comprador_Sel_IdentidadLocal
' Descripción            : Consulta apappss comprador para identidad local.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_APAPPSS_Comprador_Sel_IdentidadLocal
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT, @cCodigoRespuesta VARCHAR(60) OUTPUT, @nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo consultar la identidad.',
   @cCodigoRespuesta='APAPPSS_IDENTIDAD_ERROR',@nHttpRespuesta=400;
 DECLARE @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
   @tipoDoc VARCHAR(15)=UPPER(NULLIF(TRIM(JSON_VALUE(@cJson,'$.filtros.tipoDocumento')),'')),
   @doc VARCHAR(30)=UPPER(NULLIF(TRIM(JSON_VALUE(@cJson,'$.filtros.documento')),'')),
   @tipo VARCHAR(10),@entidad BIGINT=NULL,@comprador BIGINT=NULL,
   @nombres NVARCHAR(100)=NULL,@paterno NVARCHAR(80)=NULL,@materno NVARCHAR(80)=NULL,
   @razon NVARCHAR(200)=NULL,@comercial NVARCHAR(160)=NULL,
   @telefono VARCHAR(30)=NULL,@correo VARCHAR(180)=NULL,
   @fecha DATE=NULL,@sexo VARCHAR(20)=NULL,
   @distrito CHAR(6)=NULL,@centro BIGINT=NULL,@referencia NVARCHAR(300)=NULL,
   @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
   @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
   @acceso BIT,@mensajeAcceso NVARCHAR(300);
 BEGIN TRY
  IF @uot IS NULL OR @tipoDoc IS NULL OR @doc IS NULL OR LEN(@doc) NOT BETWEEN 5 AND 30
    THROW 51832,N'Ingrese un documento válido.',1;
  IF NOT EXISTS(SELECT 1 FROM config.TipoDocumentoComprador
      WHERE codigo=@tipoDoc AND estado=1)
    THROW 51832,N'Tipo de documento no habilitado.',1;
  SET @tipo=CASE WHEN @tipoDoc='RUC' THEN 'EMPRESA' ELSE 'PERSONA' END;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='APAPPSS_COMPRADORES_CREAR',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'APAPPSS_COMPRADORES_CREAR')<>1
    THROW 51833,N'No tiene autorización para consultar identidades.',1;
  IF NOT EXISTS (SELECT 1 FROM org.ConvenioUOTOrganizacion CU
      JOIN org.Empresa E ON E.empresa_id=CU.empresa_id AND E.ruc='20602771394' AND E.estado=1
      JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND CM.estado=1
      JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
      JOIN org.UOT U ON U.uot_id=CU.uot_id AND U.estado=1 AND U.es_raiz=0
      WHERE CU.uot_id=@uot AND CU.estado=1 AND CU.tipo_vinculo='ASOCIACION'
      AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())))
      AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()))))
    THROW 51834,N'La UOT no tiene convenio vigente con APAPPSS.',1;
  IF @tipo='PERSONA'
  BEGIN
    SELECT TOP(1) @entidad=P.persona_id,@nombres=P.nombres,@paterno=P.apellido_paterno,
      @materno=P.apellido_materno,@telefono=P.telefono,@correo=P.correo,
      @fecha=P.fecha_nacimiento,@sexo=P.sexo,@distrito=G.distrito_codigo,
      @centro=G.centro_poblado_id,@referencia=G.referencia
    FROM org.Persona P
    LEFT JOIN geo.Ubicacion G ON G.ubicacion_id=P.ubicacion_id
    WHERE P.tipo_documento=@tipoDoc AND P.numero_documento=@doc AND P.estado=1
    ORDER BY P.persona_id;
  END
  ELSE
  BEGIN
    SELECT TOP(1) @entidad=E.empresa_id,@razon=E.razon_social,@comercial=E.nombre_comercial,
      @telefono=E.telefono,@correo=E.correo,@distrito=G.distrito_codigo,
      @centro=G.centro_poblado_id,@referencia=G.referencia
    FROM org.Empresa E
    LEFT JOIN geo.Ubicacion G ON G.ubicacion_id=E.ubicacion_id
    WHERE E.ruc=@doc AND E.estado=1
    ORDER BY E.empresa_id;
  END;
  IF @entidad IS NOT NULL
    SELECT @comprador=B.comprador_apappss_id
    FROM comercial.CompradorAPAPPSS B
    WHERE B.uot_id=@uot AND B.estado=1 AND
      ((@tipo='PERSONA' AND B.persona_id=@entidad) OR (@tipo='EMPRESA' AND B.empresa_id=@entidad));
  SET @cDatos=(SELECT CONVERT(BIT,CASE WHEN @entidad IS NULL THEN 0 ELSE 1 END) encontrado,
    @comprador compradorId,@tipo tipo,@entidad entidadId,@nombres nombres,@paterno apellidoPaterno,
    @materno apellidoMaterno,@razon razonSocial,@comercial nombreComercial,
    @telefono telefono,@correo correo,@fecha fechaNacimiento,@sexo sexo,
    @distrito distritoCodigo,@centro centroPobladoId,@referencia referencia
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
  SELECT @bResultado=1,@cMensaje=N'Consulta local completada.',
    @cCodigoRespuesta='APAPPSS_IDENTIDAD_LOCAL_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  SELECT @cDatos=NULL,@bResultado=0,@cMensaje=LEFT(ERROR_MESSAGE(),300),
    @cCodigoRespuesta='APAPPSS_IDENTIDAD_ERROR',@nHttpRespuesta=403;
 END CATCH;
END;
GO
