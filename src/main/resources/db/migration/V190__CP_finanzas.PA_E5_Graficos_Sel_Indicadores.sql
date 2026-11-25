IF OBJECT_ID(N'[finanzas].[PA_E5_Graficos_Sel_Indicadores]') IS NOT NULL
    DROP PROCEDURE [finanzas].[PA_E5_Graficos_Sel_Indicadores];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : finanzas.PA_E5_Graficos_Sel_Indicadores
' Descripción            : Consulta e5 graficos para indicadores.
' Aplicativo / Módulo    : DESCO / finanzas
*******************************************************************************************************/
CREATE   PROCEDURE finanzas.PA_E5_Graficos_Sel_Indicadores
 @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT, @bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @bResultado=0,@cDatos=NULL,@cMensaje=N'No se pudieron consultar los gráficos.',@cCodigoRespuesta='E5_GRAFICOS_ERROR',@nHttpRespuesta=400;
 IF ISJSON(@cJson)<>1 RETURN;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @inicio DATE=TRY_CONVERT(DATE,NULLIF(JSON_VALUE(@cJson,'$.datos.fechaInicio'),'')),
  @fin DATE=TRY_CONVERT(DATE,NULLIF(JSON_VALUE(@cJson,'$.datos.fechaFin'),'')),
  @variedad SMALLINT=TRY_CONVERT(SMALLINT,JSON_VALUE(@cJson,'$.datos.variedadPaltaId')),
  @uot BIGINT,@asoc BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@ok BIT,@msg NVARCHAR(300);
 SELECT @uot=C.uot_id,@asoc=C.asociacion_id,@inicio=COALESCE(@inicio,C.fecha_inicio),
  @fin=COALESCE(@fin,C.fecha_fin,CONVERT(DATE,SYSUTCDATETIME()))
 FROM comercial.CampaniaVenta C WHERE C.campania_venta_id=@camp AND C.estado=1;
 IF @uot IS NULL OR @inicio IS NULL OR @fin IS NULL OR @fin<@inicio OR DATEDIFF(DAY,@inicio,@fin)>366
 BEGIN SET @cMensaje=N'Campaña o rango de fechas inválido.';RETURN; END;
 BEGIN TRY
 EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='LIQUIDACIONES_LISTAR',
  @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
  @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
  @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
  @bResultado=@ok OUTPUT,@cMensaje=@msg OUTPUT;
 IF ISNULL(@ok,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'LIQUIDACIONES_LISTAR')<>1
  THROW 51710,N'No dispone de acceso territorial a esta campaña.',1;
 IF NOT EXISTS(SELECT 1 FROM org.ConvenioUOTOrganizacion CU
    JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND CM.estado=1
    JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
    WHERE CU.uot_id=@uot AND CU.empresa_id=@asoc AND CU.estado=1
    AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,SYSUTCDATETIME()))
    AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,SYSUTCDATETIME())))
  THROW 51711,N'El convenio de la campaña no está habilitado.',1;
 SET @cDatos=(SELECT @camp campaniaId,@inicio fechaInicio,@fin fechaFin,@variedad variedadPaltaId,
  JSON_QUERY((SELECT CONVERT(CHAR(10),CONVERT(DATE,D.fecha_hora),126) fecha,
   CONVERT(DECIMAL(19,3),SUM(D.kilogramos)) kilogramos,
   CONVERT(DECIMAL(19,2),SUM(D.importe)) ventaEfectiva
   FROM finanzas.V_E5_VentasConfirmadas D
   WHERE D.campaniaId=@camp AND D.fecha_hora>=@inicio AND D.fecha_hora<DATEADD(DAY,1,@fin)
     AND (@variedad IS NULL OR D.variedad_palta_id=@variedad)
   GROUP BY CONVERT(DATE,D.fecha_hora) ORDER BY CONVERT(DATE,D.fecha_hora) FOR JSON PATH)) porDia,
  JSON_QUERY((SELECT D.variedad_palta_id variedadId,D.variedad,
    CONVERT(DECIMAL(19,3),SUM(D.kilogramos)) kilogramos,
    CONVERT(DECIMAL(19,2),SUM(D.importe)) ventaEfectiva
   FROM finanzas.V_E5_VentasConfirmadas D
   WHERE D.campaniaId=@camp AND D.fecha_hora>=@inicio AND D.fecha_hora<DATEADD(DAY,1,@fin)
     AND (@variedad IS NULL OR D.variedad_palta_id=@variedad)
   GROUP BY D.variedad_palta_id,D.variedad ORDER BY D.variedad FOR JSON PATH)) porVariedad
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 SELECT @bResultado=1,@cMensaje=N'Indicadores consultados.',@cCodigoRespuesta='E5_GRAFICOS_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  SELECT @bResultado=0,@cMensaje=N'No fue posible consultar los gráficos.',@cCodigoRespuesta='E5_GRAFICOS_ERROR',@nHttpRespuesta=400;
 END CATCH;
END;
GO
