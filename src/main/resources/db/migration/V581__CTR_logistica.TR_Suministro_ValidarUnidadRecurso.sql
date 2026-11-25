IF OBJECT_ID(N'[logistica].[TR_Suministro_ValidarUnidadRecurso]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_Suministro_ValidarUnidadRecurso];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_Suministro_ValidarUnidadRecurso
' Descripción            : Valida unidades de medida de los suministros.
' Aplicativo / Módulo    : DESCO / Logística
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_Suministro_ValidarUnidadRecurso ON logistica.Suministro AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I WHERE NOT EXISTS(SELECT 1 FROM config.CatalogoRecursoValor C WHERE C.catalogo='UNIDAD_MEDIDA' AND C.codigo=UPPER(I.unidad_medida) AND C.estado=1)) THROW 51000,N'La unidad de medida del suministro no está disponible.',1;
END;
GO
