IF OBJECT_ID(N'[prod].[PA_E3_Sel_ValidarPredio]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_E3_Sel_ValidarPredio];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_E3_Sel_ValidarPredio
' Descripción            : Gestiona e3: validar predio.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_E3_Sel_ValidarPredio
 @cJson NVARCHAR(MAX),@cPermiso VARCHAR(60),@nUsuario BIGINT OUTPUT,
 @nUot BIGINT OUTPUT,@nConvenio BIGINT OUTPUT,@nPredio BIGINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @nUot=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
  @nConvenio=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.convenioId')),
  @nPredio=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.predioId'));
 IF ISJSON(@cJson)<>1 OR @nUot IS NULL OR @nConvenio IS NULL OR @nPredio IS NULL
  THROW 51310,N'Indique un predio, convenio y UOT válidos.',1;
 DECLARE @sesion BIGINT,@disp BIGINT,@emp BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
  @auth BIT,@msg NVARCHAR(300),@fecha DATE=CONVERT(DATE,SYSUTCDATETIME());
 EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,@cPermiso,
  @nUsuario OUTPUT,@sesion OUTPUT,@disp OUTPUT,@emp OUTPUT,@modulo OUTPUT,
  @corr OUTPUT,@sol OUTPUT,@ip OUTPUT,@endpoint OUTPUT,@auth OUTPUT,@msg OUTPUT;
 IF ISNULL(@auth,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@nUsuario,@nUot,@cPermiso)<>1
  THROW 51311,N'No tiene autorización para registrar plantas.',1;
 IF NOT EXISTS (SELECT 1 FROM prod.PredioAmbito A
   JOIN org.ConvenioUOTOrganizacion C ON C.convenio_uot_organizacion_id=A.convenio_uot_organizacion_id
   JOIN org.ConvenioModuloEspecial M ON M.convenio_uot_organizacion_id=C.convenio_uot_organizacion_id AND M.estado=1
   JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=M.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
   JOIN prod.Predio P ON P.predio_id=A.predio_id AND P.estado=1
   WHERE A.predio_id=@nPredio AND A.uot_id=@nUot AND A.convenio_uot_organizacion_id=@nConvenio AND A.estado=1
    AND C.uot_id=@nUot AND C.estado=1 AND (C.fecha_inicio IS NULL OR C.fecha_inicio<=@fecha)
    AND (C.fecha_fin IS NULL OR C.fecha_fin>=@fecha)
    AND EXISTS(SELECT 1 FROM prod.PredioTitularidad T
     JOIN org.Socio S ON S.socio_id=T.socio_id AND S.estado=1
     JOIN org.SocioAsociacion SA ON SA.socio_id=T.socio_id AND SA.asociacion_id=C.empresa_id
      AND SA.estado=1 AND SA.fecha_desde<=@fecha AND (SA.fecha_hasta IS NULL OR SA.fecha_hasta>=@fecha)
     WHERE T.predio_id=@nPredio AND T.estado=1 AND T.fecha_hasta IS NULL))
  THROW 51312,N'El predio no pertenece al convenio autorizado.',1;
END;
GO
