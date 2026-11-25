IF OBJECT_ID(N'[comercial].[TR_CampaniaJabaPlan_ValidarParticipante]') IS NOT NULL
    DROP TRIGGER [comercial].[TR_CampaniaJabaPlan_ValidarParticipante];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : comercial.TR_CampaniaJabaPlan_ValidarParticipante
' Descripción            : Valida las reglas de campania jaba plan validar participante al modificar registros.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   TRIGGER comercial.TR_CampaniaJabaPlan_ValidarParticipante
ON comercial.ParticipacionCampaniaSocio AFTER UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (SELECT 1 FROM inserted P
  JOIN comercial.CampaniaJabaPlan J ON J.participacion_campania_socio_id=P.participacion_campania_socio_id
  WHERE (P.estado=0 OR P.estado_participacion<>'ACTIVO') AND J.activo=1 AND J.estado<>'DEVUELTA')
  THROW 51421,N'No se puede retirar al socio mientras tenga jabas asignadas.',1;
END;
GO
