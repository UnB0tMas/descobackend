-- APAPPSS: consultar y editar datos del comprador sin modificar el documento ni su vínculo.
-- No se alteran V601, V602 ni V610 ya existentes.
IF NOT EXISTS (SELECT 1 FROM seg.Permiso WHERE codigo = 'APAPPSS_COMPRADORES_EDITAR')
BEGIN
    INSERT seg.Permiso(modulo_id,codigo,nombre,descripcion,estado,accion,es_sensible,requiere_motivo)
    SELECT M.modulo_id,'APAPPSS_COMPRADORES_EDITAR',N'APAPPSS - Editar compradores',
           N'Modificar los datos de compradores de la UOT autorizada.',1,'EDITAR',1,0
    FROM seg.Modulo M WHERE M.codigo = 'APAPPSS';
END;
GO
INSERT seg.ModuloEspecialPermiso(modulo_especial_id,permiso_id)
SELECT M.modulo_especial_id,P.permiso_id
FROM seg.ModuloEspecial M
JOIN seg.Permiso P ON P.codigo = 'APAPPSS_COMPRADORES_EDITAR'
WHERE M.codigo = 'COMERCIALIZACION_ASOCIATIVA'
  AND NOT EXISTS (SELECT 1 FROM seg.ModuloEspecialPermiso MP
                  WHERE MP.modulo_especial_id = M.modulo_especial_id AND MP.permiso_id = P.permiso_id);
GO

CREATE OR ALTER PROCEDURE comercial.PA_APAPPSS_Comprador_Sel_Detalle
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT, @cCodigoRespuesta VARCHAR(60) OUTPUT, @nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo consultar el comprador.',
   @cCodigoRespuesta='APAPPSS_COMPRADOR_DETALLE_ERROR',@nHttpRespuesta=400;
 DECLARE @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
   @id BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.compradorId')),
   @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
   @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
   @acceso BIT,@mensajeAcceso NVARCHAR(300);
 BEGIN TRY
   IF @uot IS NULL OR @uot<1 OR @id IS NULL OR @id<1
      THROW 51850,N'Identifique el comprador y la UOT.',1;
   EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,
     @cCodigoPermiso='APAPPSS_COMPRADORES_LISTAR',
     @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,
     @nDispositivoUsuarioId=@dispositivo OUTPUT,@nEmpleadoId=@empleado OUTPUT,
     @nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,@gSolicitudId=@sol OUTPUT,
     @cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,@bResultado=@acceso OUTPUT,
     @cMensaje=@mensajeAcceso OUTPUT;
   IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'APAPPSS_COMPRADORES_LISTAR')<>1
      THROW 51851,N'No tiene permiso para consultar compradores.',1;
   IF NOT EXISTS (SELECT 1 FROM org.ConvenioUOTOrganizacion CU
      JOIN org.Empresa E ON E.empresa_id=CU.empresa_id AND E.ruc='20602771394' AND E.estado=1
      JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND CM.estado=1
      JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
      JOIN org.UOT U ON U.uot_id=CU.uot_id AND U.estado=1 AND U.es_raiz=0
      WHERE CU.uot_id=@uot AND CU.estado=1 AND CU.tipo_vinculo='ASOCIACION'
      AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())))
      AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()))))
      THROW 51852,N'La UOT no tiene convenio APAPPSS vigente.',1;
   IF NOT EXISTS(SELECT 1 FROM comercial.CompradorAPAPPSS B
     WHERE B.comprador_apappss_id=@id AND B.uot_id=@uot AND B.estado=1)
      THROW 51853,N'El comprador no está disponible en la UOT.',1;
   SET @cDatos=(SELECT B.comprador_apappss_id compradorId,B.tipo,
       B.persona_id personaId,B.empresa_id empresaId,
       CASE WHEN B.tipo='PERSONA' THEN TRIM(CONCAT(P.nombres,N' ',P.apellido_paterno,N' ',COALESCE(P.apellido_materno,N'')))
            ELSE E.razon_social END nombre,
       CASE WHEN B.tipo='PERSONA' THEN P.numero_documento ELSE E.ruc END documento,
       CASE WHEN B.tipo='PERSONA' THEN P.tipo_documento ELSE 'RUC' END tipoDocumento,
       P.nombres,P.apellido_paterno apellidoPaterno,P.apellido_materno apellidoMaterno,
       E.razon_social razonSocial,E.nombre_comercial nombreComercial,
       CASE WHEN B.tipo='PERSONA' THEN P.fecha_nacimiento ELSE NULL END fechaNacimiento,
       P.sexo,
       CASE WHEN B.tipo='PERSONA' THEN P.telefono ELSE E.telefono END telefono,
       CASE WHEN B.tipo='PERSONA' THEN P.correo ELSE E.correo END correo,
       G.distrito_codigo distritoCodigo,G.centro_poblado_id centroPobladoId,G.referencia,
       B.fecha_registro fechaRegistro
     FROM comercial.CompradorAPAPPSS B
     LEFT JOIN org.Persona P ON P.persona_id=B.persona_id AND P.estado=1
     LEFT JOIN org.Empresa E ON E.empresa_id=B.empresa_id AND E.estado=1
     LEFT JOIN geo.Ubicacion G ON G.ubicacion_id=CASE WHEN B.tipo='PERSONA' THEN P.ubicacion_id ELSE E.ubicacion_id END
     WHERE B.comprador_apappss_id=@id AND B.uot_id=@uot AND B.estado=1
     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
   SELECT @bResultado=1,@cCodigoRespuesta='APAPPSS_COMPRADOR_DETALLE_OK',
     @cMensaje=N'Comprador consultado.',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
   SELECT @cDatos=NULL,@bResultado=0,@cMensaje=LEFT(ERROR_MESSAGE(),300),
     @cCodigoRespuesta='APAPPSS_COMPRADOR_DETALLE_ERROR',
     @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51850 AND 51859 THEN 403 ELSE 500 END;
 END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE comercial.PA_APAPPSS_Comprador_Upd_Datos
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
     UPDATE org.Persona SET nombres=@nombres,apellido_paterno=@paterno,apellido_materno=@materno,
       telefono=@telefono,correo=@correo,fecha_nacimiento=@fecha,sexo=@sexo,
       ubicacion_id=@ubicacionNueva
     WHERE persona_id=@persona AND estado=1;
   END
   ELSE
   BEGIN
     UPDATE org.Empresa SET razon_social=@razon,nombre_comercial=@comercial,
       telefono=@telefono,correo=@correo,ubicacion_id=@ubicacionNueva
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
