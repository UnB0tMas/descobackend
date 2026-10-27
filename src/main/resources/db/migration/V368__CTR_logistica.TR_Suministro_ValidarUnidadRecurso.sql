IF OBJECT_ID(N'[logistica].[TR_Suministro_ValidarUnidadRecurso]', N'TR') IS NOT NULL
    DROP TRIGGER [logistica].[TR_Suministro_ValidarUnidadRecurso];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : logistica.TR_Suministro_ValidarUnidadRecurso
' Descripción              : Valida unidades de medida de los suministros.
' Tabla asociada          : logistica.Suministro
' Evento que lo dispara   : AFTER INSERT,UPDATE
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE sobre logistica.Suministro.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[logistica].[TR_Suministro_ValidarUnidadRecurso]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_Suministro_ValidarUnidadRecurso ON logistica.Suministro AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I WHERE NOT EXISTS(SELECT 1 FROM config.CatalogoRecursoValor C WHERE C.catalogo='UNIDAD_MEDIDA' AND C.codigo=UPPER(I.unidad_medida) AND C.estado=1)) THROW 51000,N'La unidad de medida del suministro no está disponible.',1;
END;
GO
