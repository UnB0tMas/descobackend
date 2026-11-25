IF OBJECT_ID(N'[comercial].[PA_APAPPSS_Comprador_Upd_Datos]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_APAPPSS_Comprador_Upd_Datos];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_APAPPSS_Comprador_Upd_Datos
' Descripción            : Actualiza información de APAPPSS Comprador (datos).
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_APAPPSS_Comprador_Upd_Datos
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT, @cCodigoRespuesta VARCHAR(60) OUTPUT, @nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo actualizar el comprador.',
   @cCodigoRespuesta='APAPPSS_COMPRADOR_EDICION_ERROR',@nHttpRespuesta=400;
 DECLARE @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
   @id BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.compradorId')),
   @nombres NVARCHAR(100)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.nombres')),N''),
   @paterno NVARCHAR(80)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.apellidoPaterno')),N''),
   @materno NVARCHAR(80)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.apellidoMaterno')),N''),
   @razon NVARCHAR(200)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.razonSocial')),N''),
   @comercial NVARCHAR(160)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.nombreComercial')),N''),
   @telefono VARCHAR(30)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.telefono')),''),
   @correo VARCHAR(180)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.correo')),''),
   @soloCompletar BIT=ISNULL(TRY_CONVERT(BIT,JSON_VALUE(@cJson,'$.datos.completarDatos')),0),
   @fechaRaw VARCHAR(40)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.fechaNacimiento')),''),
   @fecha DATE=TRY_CONVERT(DATE,NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.fechaNacimiento')),''),23),
   @sexo VARCHAR(20)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.sexo')),''),
   @distrito CHAR(6)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.distritoCodigo')),''),
   @centro BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.centroPobladoId')),
   @referencia NVARCHAR(300)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.referencia')),N''),
   @tipo VARCHAR(10)=NULL,@persona BIGINT=NULL,@empresa BIGINT=NULL,
   @ubicacionAnterior BIGINT=NULL,@ubicacionNueva BIGINT=NULL,@locked INT,
   @okUbicacion BIT,@msgUbicacion NVARCHAR(300),
   @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
   @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
   @acceso BIT,@mensajeAcceso NVARCHAR(300);
 BEGIN TRY
   IF @uot IS NULL OR @uot<1 OR @id IS NULL OR @id<1
     THROW 51860,N'Identifique el comprador y la UOT.',1;
   IF @correo IS NOT NULL AND @correo NOT LIKE '%_@_%._%'
     THROW 51861,N'Ingrese un correo válido.',1;
   IF (@fechaRaw IS NOT NULL AND @fecha IS NULL) OR @fecha>CONVERT(DATE,SYSUTCDATETIME())
     THROW 51861,N'La fecha de nacimiento no es válida.',1;
   IF @distrito IS NOT NULL AND NOT EXISTS(SELECT 1 FROM geo.Distrito WHERE distrito_codigo=@distrito AND estado=1)
     THROW 51861,N'El distrito no está disponible.',1;
   IF @centro IS NOT NULL AND (@distrito IS NULL OR NOT EXISTS(
      SELECT 1 FROM geo.CentroPoblado WHERE centro_poblado_id=@centro AND distrito_codigo=@distrito AND estado=1))
     THROW 51861,N'El centro poblado no corresponde al distrito.',1;
   EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,
     @cCodigoPermiso='APAPPSS_COMPRADORES_EDITAR',
     @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,
     @nDispositivoUsuarioId=@dispositivo OUTPUT,@nEmpleadoId=@empleado OUTPUT,
     @nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,@gSolicitudId=@sol OUTPUT,
     @cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,@bResultado=@acceso OUTPUT,
     @cMensaje=@mensajeAcceso OUTPUT;
   IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'APAPPSS_COMPRADORES_EDITAR')<>1
     THROW 51862,N'No tiene permiso para editar compradores.',1;
   IF NOT EXISTS (SELECT 1 FROM org.ConvenioUOTOrganizacion CU
      JOIN org.Empresa E ON E.empresa_id=CU.empresa_id AND E.ruc='20602771394' AND E.estado=1
      JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND CM.estado=1
      JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
      JOIN org.UOT U ON U.uot_id=CU.uot_id AND U.estado=1 AND U.es_raiz=0
      WHERE CU.uot_id=@uot AND CU.estado=1 AND CU.tipo_vinculo='ASOCIACION'
      AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())))
      AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()))))
      THROW 51863,N'La UOT no tiene convenio APAPPSS vigente.',1;
   BEGIN TRANSACTION;
   SELECT @tipo=B.tipo,@persona=B.persona_id,@empresa=B.empresa_id
   FROM comercial.CompradorAPAPPSS B WITH(UPDLOCK,HOLDLOCK)
   WHERE B.comprador_apappss_id=@id AND B.uot_id=@uot AND B.estado=1;
   IF @tipo IS NULL THROW 51864,N'El comprador no está disponible en la UOT.',1;
   IF (@tipo='PERSONA' AND (@nombres IS NULL OR @paterno IS NULL))
      OR (@tipo='EMPRESA' AND @razon IS NULL)
      THROW 51865,N'Complete los datos de identificación obligatorios.',1;
   IF @tipo='PERSONA'
   BEGIN
     SELECT @ubicacionAnterior=P.ubicacion_id FROM org.Persona P WITH(UPDLOCK,HOLDLOCK)
     WHERE P.persona_id=@persona AND P.estado=1;
     IF @@ROWCOUNT<>1 THROW 51864,N'La identidad no está disponible.',1;
   END
   ELSE
   BEGIN
     SELECT @ubicacionAnterior=E.ubicacion_id FROM org.Empresa E WITH(UPDLOCK,HOLDLOCK)
     WHERE E.empresa_id=@empresa AND E.estado=1;
     IF @@ROWCOUNT<>1 THROW 51864,N'La empresa no está disponible.',1;
   END;
   SET @ubicacionNueva=@ubicacionAnterior;
   IF @soloCompletar=1 AND @ubicacionAnterior IS NOT NULL
   BEGIN
     -- Reutilizar los datos de ubicación que ya estaban registrados.
     SELECT @distrito=COALESCE(U.distrito_codigo,@distrito),
            @centro=COALESCE(U.centro_poblado_id,@centro),
            @referencia=COALESCE(NULLIF(TRIM(U.referencia),N''),@referencia)
     FROM geo.Ubicacion U WHERE U.ubicacion_id=@ubicacionAnterior AND U.estado=1;
   END;
   IF @distrito IS NOT NULL AND NOT EXISTS(SELECT 1 FROM geo.Ubicacion U
       WHERE U.ubicacion_id=@ubicacionAnterior AND U.distrito_codigo=@distrito
         AND ISNULL(U.centro_poblado_id,-1)=ISNULL(@centro,-1)
         AND ISNULL(U.referencia,N'')=ISNULL(@referencia,N''))
   BEGIN
     -- Una ubicación referenciada por otras entidades nunca se edita en sitio.
     EXEC geo.PA_Ubicacion_Ins_Interna @cDistritoCodigo=@distrito,
       @nCentroPobladoId=@centro,@cReferencia=@referencia,
       @nLatitud=NULL,@nLongitud=NULL,@nAltitudM=NULL,
       @nUbicacionId=@ubicacionNueva OUTPUT,@bResultado=@okUbicacion OUTPUT,
       @cMensaje=@msgUbicacion OUTPUT;
     IF ISNULL(@okUbicacion,0)<>1 OR @ubicacionNueva IS NULL
       THROW 51866,N'No se pudo actualizar la ubicación.',1;
   END;
   IF @tipo='PERSONA'
   BEGIN
     UPDATE org.Persona SET
       nombres=CASE WHEN @soloCompletar=1 THEN COALESCE(NULLIF(TRIM(nombres),N''),@nombres) ELSE @nombres END,
       apellido_paterno=CASE WHEN @soloCompletar=1 THEN COALESCE(NULLIF(TRIM(apellido_paterno),N''),@paterno) ELSE @paterno END,
       apellido_materno=CASE WHEN @soloCompletar=1 THEN COALESCE(NULLIF(TRIM(apellido_materno),N''),@materno) ELSE @materno END,
       telefono=CASE WHEN @soloCompletar=1 THEN COALESCE(NULLIF(TRIM(telefono),''),@telefono) ELSE @telefono END,
       correo=CASE WHEN @soloCompletar=1 THEN COALESCE(NULLIF(TRIM(correo),''),@correo) ELSE @correo END,
       fecha_nacimiento=CASE WHEN @soloCompletar=1 THEN COALESCE(fecha_nacimiento,@fecha) ELSE @fecha END,
       sexo=CASE WHEN @soloCompletar=1 THEN COALESCE(NULLIF(TRIM(sexo),''),@sexo) ELSE @sexo END,
       ubicacion_id=@ubicacionNueva
     WHERE persona_id=@persona AND estado=1;
   END
   ELSE
   BEGIN
     UPDATE org.Empresa SET
       razon_social=CASE WHEN @soloCompletar=1 THEN COALESCE(NULLIF(TRIM(razon_social),N''),@razon) ELSE @razon END,
       nombre_comercial=CASE WHEN @soloCompletar=1 THEN COALESCE(NULLIF(TRIM(nombre_comercial),N''),@comercial) ELSE @comercial END,
       telefono=CASE WHEN @soloCompletar=1 THEN COALESCE(NULLIF(TRIM(telefono),''),@telefono) ELSE @telefono END,
       correo=CASE WHEN @soloCompletar=1 THEN COALESCE(NULLIF(TRIM(correo),''),@correo) ELSE @correo END,
       ubicacion_id=@ubicacionNueva
     WHERE empresa_id=@empresa AND estado=1;
   END;
   SET @cDatos=(SELECT @id compradorId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   COMMIT TRANSACTION;
   SELECT @bResultado=1,@cCodigoRespuesta='APAPPSS_COMPRADOR_ACTUALIZADO',
     @cMensaje=N'Comprador actualizado.',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
   IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
   SELECT @cDatos=NULL,@bResultado=0,
     @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51860 AND 51869 THEN LEFT(ERROR_MESSAGE(),300)
       ELSE N'No se pudo actualizar al comprador.' END,
     @cCodigoRespuesta='APAPPSS_COMPRADOR_EDICION_ERROR',
     @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51860 AND 51869 THEN 409 ELSE 500 END;
 END CATCH;
END;
GO
