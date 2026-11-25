IF OBJECT_ID(N'[comercial].[PA_APAPPSS_Contexto_Sel]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_APAPPSS_Contexto_Sel];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_APAPPSS_Contexto_Sel
' Descripción            : Ejecuta el proceso de apappss contexto sel.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_APAPPSS_Contexto_Sel
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
