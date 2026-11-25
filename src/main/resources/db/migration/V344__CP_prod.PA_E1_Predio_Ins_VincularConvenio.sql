IF OBJECT_ID(N'[prod].[PA_E1_Predio_Ins_VincularConvenio]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_E1_Predio_Ins_VincularConvenio];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_E1_Predio_Ins_VincularConvenio
' Descripción            : Registra e1 predio para vincular convenio.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_E1_Predio_Ins_VincularConvenio
 @cJson NVARCHAR(MAX),@nUot BIGINT,@nConvenio BIGINT,@nPredio BIGINT,@nUsuario BIGINT,@nEntidad BIGINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 IF @@TRANCOUNT=0 THROW 51110,N'La vinculacion requiere transaccion E1.',1;
 DECLARE @nPersona BIGINT;
          SELECT @nPersona=personaId FROM OPENJSON(@cJson,'$.datos') WITH(personaId BIGINT);
          IF @nConvenio IS NULL OR NOT EXISTS(SELECT 1 FROM prod.PredioTitularidad WHERE predio_id=@nPredio AND persona_id=@nPersona AND estado=1 AND fecha_hasta IS NULL)
             OR NOT EXISTS(SELECT 1 FROM org.SocioAsociacion S JOIN org.ConvenioUOTOrganizacion C ON C.empresa_id=S.asociacion_id
                WHERE C.convenio_uot_organizacion_id=@nConvenio AND S.socio_id=@nPersona AND S.estado=1 AND S.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
                  AND (S.fecha_hasta IS NULL OR S.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME())))
             THROW 51056,N'El predio no puede vincularse a este convenio.',1;
          UPDATE prod.PredioAmbito SET estado=1 WHERE predio_id=@nPredio AND uot_id=@nUot AND convenio_uot_organizacion_id=@nConvenio AND estado=0;
          IF NOT EXISTS(SELECT 1 FROM prod.PredioAmbito WITH(UPDLOCK,HOLDLOCK) WHERE predio_id=@nPredio AND uot_id=@nUot AND convenio_uot_organizacion_id=@nConvenio)
             INSERT prod.PredioAmbito(predio_id,uot_id,convenio_uot_organizacion_id,usuario_creacion_id)
             VALUES(@nPredio,@nUot,@nConvenio,@nUsuario);
          SET @nEntidad=@nPredio;
END;
GO
