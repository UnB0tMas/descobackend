IF OBJECT_ID(N'[prod].[PA_E3_Sel_ValidarContexto]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_E3_Sel_ValidarContexto];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_E3_Sel_ValidarContexto
' Descripción            : Gestiona e3: validar contexto.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_E3_Sel_ValidarContexto
 @cJson NVARCHAR(MAX), @cPermiso VARCHAR(60), @nUsuario BIGINT OUTPUT,
 @nPlanta BIGINT OUTPUT, @nEpisodio BIGINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
 @conv BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.convenioId')),
 @predio BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.predioId')),
 @parcelaContexto BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.parcelaCultivoId')),
 @sesion BIGINT,@disp BIGINT,@emp BIGINT,@modulo INT,@corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,
 @ip VARCHAR(64),@endpoint NVARCHAR(250),@auth BIT,@authMensaje NVARCHAR(300),@fecha DATE=CONVERT(DATE,SYSUTCDATETIME());
 SELECT @nPlanta=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.plantaId')),
        @nEpisodio=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.episodioId'));
 IF ISJSON(@cJson)<>1 OR @uot IS NULL OR @conv IS NULL OR @predio IS NULL OR @nPlanta IS NULL
    THROW 51210,N'El contexto de la planta no es válido.',1;
 EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,@cPermiso,
   @nUsuario OUTPUT,@sesion OUTPUT,@disp OUTPUT,@emp OUTPUT,@modulo OUTPUT,
   @corr OUTPUT,@sol OUTPUT,@ip OUTPUT,@endpoint OUTPUT,@auth OUTPUT,@authMensaje OUTPUT;
 IF ISNULL(@auth,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@nUsuario,@uot,@cPermiso)<>1
    THROW 51211,N'No tiene permisos para realizar esta operación.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.PredioAmbito A
  JOIN org.ConvenioUOTOrganizacion C ON C.convenio_uot_organizacion_id=A.convenio_uot_organizacion_id
  JOIN org.ConvenioModuloEspecial M ON M.convenio_uot_organizacion_id=C.convenio_uot_organizacion_id AND M.estado=1
  JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=M.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
  JOIN prod.Predio PD ON PD.predio_id=A.predio_id AND PD.estado=1
  WHERE A.predio_id=@predio AND A.uot_id=@uot AND A.convenio_uot_organizacion_id=@conv AND A.estado=1
   AND C.uot_id=@uot AND C.estado=1 AND (C.fecha_inicio IS NULL OR C.fecha_inicio<=@fecha)
   AND (C.fecha_fin IS NULL OR C.fecha_fin>=@fecha)
   AND EXISTS(SELECT 1 FROM prod.PredioTitularidad T
     JOIN org.Socio S ON S.socio_id=T.socio_id
     JOIN org.SocioAsociacion SA ON SA.socio_id=T.socio_id AND SA.asociacion_id=C.empresa_id
       AND SA.estado=1 AND SA.fecha_desde<=@fecha AND (SA.fecha_hasta IS NULL OR SA.fecha_hasta>=@fecha)
     WHERE T.predio_id=@predio AND T.estado=1 AND T.fecha_hasta IS NULL AND S.estado=1))
    THROW 51212,N'El predio no pertenece al convenio autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 P
    WHERE P.planta_id=@nPlanta AND P.predio_id=@predio AND P.uot_id=@uot AND P.convenio_id=@conv)
    THROW 51213,N'La planta no pertenece al contexto seleccionado.',1;
 IF @parcelaContexto IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 P
   WHERE P.planta_id=@nPlanta AND P.parcela_cultivo_id=@parcelaContexto)
    THROW 51218,N'Esta planta no pertenece a la parcela seleccionada.',1;
 IF @nEpisodio IS NOT NULL AND NOT EXISTS(SELECT 1 FROM sanidad.EpisodioPlantaE3 E
    WHERE E.episodio_id=@nEpisodio AND E.planta_id=@nPlanta)
    THROW 51214,N'La enfermedad no pertenece a esta planta.',1;
 IF @cPermiso='APAPPSS_PREDIOS_EDITAR' AND EXISTS(SELECT 1 FROM prod.PlantaPaltaE3
   WHERE planta_id=@nPlanta AND estado_actual IN('MUERTA','ELIMINADA'))
    THROW 51219,N'La planta fallecida o eliminada solo admite consultas.',1;
END;
GO
