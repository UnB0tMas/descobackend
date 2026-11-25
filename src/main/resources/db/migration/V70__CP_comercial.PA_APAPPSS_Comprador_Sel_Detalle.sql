IF OBJECT_ID(N'[comercial].[PA_APAPPSS_Comprador_Sel_Detalle]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_APAPPSS_Comprador_Sel_Detalle];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_APAPPSS_Comprador_Sel_Detalle
' Descripción            : Consulta información de APAPPSS Comprador (detalle).
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_APAPPSS_Comprador_Sel_Detalle
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
