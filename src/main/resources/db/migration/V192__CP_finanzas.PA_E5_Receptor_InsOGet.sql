IF OBJECT_ID(N'[finanzas].[PA_E5_Receptor_InsOGet]') IS NOT NULL
    DROP PROCEDURE [finanzas].[PA_E5_Receptor_InsOGet];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : finanzas.PA_E5_Receptor_InsOGet
' Descripción            : Ejecuta el proceso de e5 receptor ins o get.
' Aplicativo / Módulo    : DESCO / finanzas
*******************************************************************************************************/
CREATE   PROCEDURE finanzas.PA_E5_Receptor_InsOGet
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No fue posible registrar al receptor.',
  @cCodigoRespuesta='E5_RECEPTOR_ERROR',@nHttpRespuesta=400;
 IF ISJSON(@cJson)<>1 RETURN;
 DECLARE @liq BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.liquidacionId')),
  @tipo VARCHAR(15)=UPPER(TRIM(JSON_VALUE(@cJson,'$.datos.tipoDocumento'))),
  @doc VARCHAR(30)=UPPER(TRIM(JSON_VALUE(@cJson,'$.datos.numeroDocumento'))),
  @nombres NVARCHAR(100)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.nombres')),N''),
  @paterno NVARCHAR(80)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.apellidoPaterno')),N''),
  @materno NVARCHAR(80)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.apellidoMaterno')),N''),
  @identidad BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.identityId')),
  @correo VARCHAR(180)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.correo')),''),
  @telefono VARCHAR(30)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.telefono')),''),
  @sexo VARCHAR(20)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.sexo')),''),
  @nacimiento DATE=TRY_CONVERT(DATE,NULLIF(JSON_VALUE(@cJson,'$.datos.fechaNacimiento'),'')),
  @clave VARCHAR(50),@persona BIGINT,@uot BIGINT,
  @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@ok BIT,@msg NVARCHAR(300);
 IF @tipo NOT IN ('DNI','RUC','CE','PASAPORTE') OR NULLIF(@doc,'') IS NULL OR LEN(@doc)>30
 BEGIN SET @cMensaje=N'El documento del receptor no es válido.';RETURN;END;
 IF (@tipo='DNI' AND (LEN(@doc)<>8 OR @doc LIKE '%[^0-9]%'))
    OR (@tipo='RUC' AND (LEN(@doc)<>11 OR @doc NOT LIKE '10%' OR @doc LIKE '%[^0-9]%'))
    OR (@tipo IN('CE','PASAPORTE') AND (LEN(@doc)<5 OR @doc LIKE '%[^A-Z0-9]%'))
 BEGIN SET @cMensaje=N'Ingrese un DNI, RUC de persona natural o documento extranjero válido.';RETURN;END;
 SELECT @uot=C.uot_id FROM finanzas.LiquidacionSocio L
 JOIN comercial.ParticipacionCampaniaSocio PC ON PC.participacion_campania_socio_id=L.participacion_campania_socio_id
 JOIN comercial.CampaniaVenta C ON C.campania_venta_id=PC.campania_venta_id AND C.estado=1
 WHERE L.liquidacion_socio_id=@liq AND L.estado=1 AND L.estado_proceso='APROBADA'
  AND C.estado_proceso='ACTIVA'
  AND CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())) BETWEEN C.fecha_inicio AND C.fecha_fin
  AND NOT EXISTS(SELECT 1 FROM finanzas.PagoSocio P WHERE P.liquidacion_socio_id=L.liquidacion_socio_id AND P.estado=1 AND P.estado_proceso='CONFIRMADO');
 IF @uot IS NULL BEGIN SET @cMensaje=N'La liquidación ya no permite pagos ni nuevos receptores.';RETURN;END;
 BEGIN TRY
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='PAGOS_CONFIRMAR',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@ok OUTPUT,@cMensaje=@msg OUTPUT;
  IF ISNULL(@ok,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'PAGOS_CONFIRMAR')<>1
   THROW 51820,N'No dispone de permiso para seleccionar al receptor.',1;
  SET @clave=CASE WHEN @tipo='RUC' THEN CONCAT('DNI:',SUBSTRING(@doc,3,8))
   ELSE CONCAT(@tipo,':',@doc) END;
  BEGIN TRANSACTION;
  SELECT @persona=P.persona_id FROM org.Persona P WITH(UPDLOCK,HOLDLOCK)
   WHERE P.documento_clave_desco=@clave COLLATE Latin1_General_100_CI_AS AND P.estado=1;
  IF @identidad IS NOT NULL AND @identidad>0 AND (@persona IS NULL OR @identidad<>@persona)
   THROW 51821,N'El documento no corresponde a la identidad seleccionada.',1;
  IF @persona IS NULL
  BEGIN
   IF EXISTS(SELECT 1 FROM org.Persona P WITH(UPDLOCK,HOLDLOCK)
      WHERE P.documento_clave_desco=@clave COLLATE Latin1_General_100_CI_AS)
    THROW 51822,N'La identidad existe, pero está inactiva.',1;
   IF @nombres IS NULL OR @paterno IS NULL
    THROW 51823,N'Registre los nombres y apellidos del receptor.',1;
   INSERT org.Persona(tipo_documento,numero_documento,nombres,apellido_paterno,apellido_materno,
      telefono,correo,fecha_nacimiento,sexo,estado)
   VALUES(@tipo,@doc,@nombres,@paterno,@materno,@telefono,@correo,@nacimiento,@sexo,1);
   SET @persona=CONVERT(BIGINT,SCOPE_IDENTITY());
  END;
  COMMIT TRANSACTION;
  SET @cDatos=(SELECT @persona personaId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Receptor seleccionado.',@cCodigoRespuesta='E5_RECEPTOR_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @bResultado=0,@cMensaje=N'No fue posible validar o registrar la identidad del receptor.',
    @cCodigoRespuesta='E5_RECEPTOR_ERROR',@nHttpRespuesta=409;
 END CATCH;
END;
GO
