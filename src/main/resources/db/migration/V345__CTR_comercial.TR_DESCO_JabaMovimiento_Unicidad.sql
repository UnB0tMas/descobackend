IF OBJECT_ID(N'[comercial].[TR_DESCO_JabaMovimiento_Unicidad]', N'TR') IS NOT NULL
    DROP TRIGGER [comercial].[TR_DESCO_JabaMovimiento_Unicidad];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : comercial.TR_DESCO_JabaMovimiento_Unicidad
' Descripción              : Valida reglas de unicidad para movimientos de jabas.
' Tabla asociada          : comercial.JabaMovimiento
' Evento que lo dispara   : AFTER INSERT,UPDATE
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Comercial
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE sobre comercial.JabaMovimiento.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[comercial].[TR_DESCO_JabaMovimiento_Unicidad]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER comercial.TR_DESCO_JabaMovimiento_Unicidad ON comercial.JabaMovimiento AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
  SELECT 1 FROM inserted I LEFT JOIN deleted D ON D.jaba_movimiento_id=I.jaba_movimiento_id
  WHERE I.jaba_asignacion_id IS NOT NULL AND I.tipo_movimiento='ASIGNACION'
    AND (D.jaba_movimiento_id IS NULL OR ISNULL(I.jaba_asignacion_id,-1)<>ISNULL(D.jaba_asignacion_id,-1) OR ISNULL(I.tipo_movimiento,'')<>ISNULL(D.tipo_movimiento,''))
    AND EXISTS(SELECT 1 FROM comercial.JabaMovimiento X WITH(UPDLOCK,HOLDLOCK) WHERE X.jaba_asignacion_id=I.jaba_asignacion_id AND X.tipo_movimiento='ASIGNACION' AND X.jaba_movimiento_id<>I.jaba_movimiento_id)
 ) THROW 51036,N'La asignación ya tiene su movimiento registrado.',1;
 IF EXISTS(
  SELECT 1 FROM inserted I LEFT JOIN deleted D ON D.jaba_movimiento_id=I.jaba_movimiento_id
  WHERE I.jaba_devolucion_id IS NOT NULL
    AND (D.jaba_movimiento_id IS NULL OR ISNULL(I.jaba_devolucion_id,-1)<>ISNULL(D.jaba_devolucion_id,-1) OR ISNULL(I.tipo_movimiento,'')<>ISNULL(D.tipo_movimiento,''))
    AND EXISTS(SELECT 1 FROM comercial.JabaMovimiento X WITH(UPDLOCK,HOLDLOCK) WHERE X.jaba_devolucion_id=I.jaba_devolucion_id AND X.tipo_movimiento=I.tipo_movimiento AND X.jaba_movimiento_id<>I.jaba_movimiento_id)
 ) THROW 51037,N'La devolución ya tiene su movimiento registrado.',1;
END;
GO
