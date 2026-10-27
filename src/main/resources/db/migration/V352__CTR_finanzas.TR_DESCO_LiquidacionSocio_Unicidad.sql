IF OBJECT_ID(N'[finanzas].[TR_DESCO_LiquidacionSocio_Unicidad]', N'TR') IS NOT NULL
    DROP TRIGGER [finanzas].[TR_DESCO_LiquidacionSocio_Unicidad];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : finanzas.TR_DESCO_LiquidacionSocio_Unicidad
' Descripción              : Valida reglas de unicidad para liquidaciones de socios.
' Tabla asociada          : finanzas.LiquidacionSocio
' Evento que lo dispara   : AFTER INSERT,UPDATE
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Finanzas
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE sobre finanzas.LiquidacionSocio.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[finanzas].[TR_DESCO_LiquidacionSocio_Unicidad]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER finanzas.TR_DESCO_LiquidacionSocio_Unicidad ON finanzas.LiquidacionSocio AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
  SELECT 1 FROM inserted I LEFT JOIN deleted D ON D.liquidacion_socio_id=I.liquidacion_socio_id
  WHERE I.estado=1 AND I.estado_proceso IN('APROBADA','PAGADA_PARCIAL','PAGADA')
    AND (D.liquidacion_socio_id IS NULL OR I.participacion_campania_socio_id<>D.participacion_campania_socio_id OR I.estado<>D.estado OR ISNULL(I.estado_proceso,'')<>ISNULL(D.estado_proceso,''))
    AND EXISTS(SELECT 1 FROM finanzas.LiquidacionSocio X WITH(UPDLOCK,HOLDLOCK) WHERE X.participacion_campania_socio_id=I.participacion_campania_socio_id AND X.estado=1 AND X.estado_proceso IN('APROBADA','PAGADA_PARCIAL','PAGADA') AND X.liquidacion_socio_id<>I.liquidacion_socio_id)
 ) THROW 51038,N'Ya existe una liquidación vigente para esta participación.',1;
END;
GO
