IF OBJECT_ID(N'[comercial].[PA_APAPPSS_Comprador_Sel_Listado]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_APAPPSS_Comprador_Sel_Listado];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_APAPPSS_Comprador_Sel_Listado
' Descripción            : Consulta información de APAPPSS Comprador (listado).
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_APAPPSS_Comprador_Sel_Listado
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
