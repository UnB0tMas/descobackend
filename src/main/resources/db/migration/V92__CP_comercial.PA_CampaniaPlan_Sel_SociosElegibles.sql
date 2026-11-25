IF OBJECT_ID(N'[comercial].[PA_CampaniaPlan_Sel_SociosElegibles]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_CampaniaPlan_Sel_SociosElegibles];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_CampaniaPlan_Sel_SociosElegibles
' Descripción            : Consulta campania plan para socios elegibles.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_CampaniaPlan_Sel_SociosElegibles
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo consultar socios elegibles.',@cCodigoRespuesta='SOCIOS_PLAN_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
 @uot BIGINT,@asociacion BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
 @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300);
 BEGIN TRY
  SELECT @uot=uot_id,@asociacion=asociacion_id FROM comercial.CampaniaVenta
    WHERE campania_venta_id=@camp AND estado=1 AND estado_proceso IN('PLANIFICACION','ACTIVA');
  IF @uot IS NULL THROW 51470,N'La campaña no está disponible.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='PARTICIPANTES_LISTAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'PARTICIPANTES_LISTAR')<>1
   THROW 51471,N'Sin permiso para consultar participantes.',1;
  SET @cDatos=(SELECT @camp campaniaId,
   JSON_QUERY((SELECT SA.socio_asociacion_id socioAsociacionId,
     CONCAT(PE.nombres,N' ',PE.apellido_paterno,N' ',COALESCE(PE.apellido_materno,N'')) nombre,
     PE.numero_documento numeroDocumento
    FROM org.SocioAsociacion SA JOIN org.Socio S ON S.socio_id=SA.socio_id AND S.estado=1
    JOIN org.Persona PE ON PE.persona_id=S.socio_id AND PE.estado=1
    WHERE SA.asociacion_id=@asociacion AND SA.estado=1 AND SA.situacion_membresia='ACTIVO'
      AND SA.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
      AND (SA.fecha_hasta IS NULL OR SA.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
      AND NOT EXISTS(SELECT 1 FROM comercial.ParticipacionCampaniaSocio P
       WHERE P.campania_venta_id=@camp AND P.socio_asociacion_id=SA.socio_asociacion_id
        AND P.estado=1 AND P.estado_participacion='ACTIVO')
    ORDER BY PE.apellido_paterno,PE.nombres,SA.socio_asociacion_id FOR JSON PATH)) socios
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Socios elegibles listados.',@cCodigoRespuesta='SOCIOS_PLAN_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  SELECT @bResultado=0,@cDatos=NULL,@cCodigoRespuesta='SOCIOS_PLAN_ERROR',
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51400 AND 51499 THEN 400 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51400 AND 51499 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo consultar socios elegibles.' END;
 END CATCH;
END;
GO
