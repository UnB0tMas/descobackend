IF OBJECT_ID(N'[logistica].[TR_Vehiculo_ValidarTipoRecurso]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_Vehiculo_ValidarTipoRecurso];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_Vehiculo_ValidarTipoRecurso
' Descripción            : Valida la clasificación del vehículo como recurso.
' Aplicativo / Módulo    : DESCO / Logística
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_Vehiculo_ValidarTipoRecurso ON logistica.Vehiculo AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I WHERE NOT EXISTS(SELECT 1 FROM config.CatalogoRecursoValor C WHERE C.catalogo='TIPO_VEHICULO' AND C.codigo=UPPER(I.tipo_vehiculo) AND C.estado=1)) THROW 51000,N'El tipo de vehículo no está disponible.',1;
END;
GO
