IF OBJECT_ID(N'[org].[TR_Empleado_SincronizarUOTLegacy]', N'TR') IS NOT NULL
    DROP TRIGGER [org].[TR_Empleado_SincronizarUOTLegacy];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : org.TR_Empleado_SincronizarUOTLegacy
' Descripción              : Sincroniza empleados con datos de UOT heredados.
' Tabla asociada          : org.Empleado
' Evento que lo dispara   : AFTER INSERT,UPDATE
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Organización
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE sobre org.Empleado.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[org].[TR_Empleado_SincronizarUOTLegacy]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER org.TR_Empleado_SincronizarUOTLegacy
ON org.Empleado AFTER INSERT,UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT org.EmpleadoUOT(empleado_id,uot_id,es_principal,fecha_desde,fecha_hasta,estado)
    SELECT E.empleado_id,U.uot_id,
           CASE WHEN NOT EXISTS(SELECT 1 FROM org.EmpleadoUOT X WHERE X.empleado_id=E.empleado_id AND X.estado=1 AND X.fecha_hasta IS NULL AND X.es_principal=1) THEN 1 ELSE 0 END,
           E.fecha_ingreso,E.fecha_cese,E.estado
    FROM org.Empleado E JOIN inserted I ON I.empleado_id=E.empleado_id
    JOIN org.UOT U ON U.empresa_legacy_id=E.empresa_id
    WHERE NOT EXISTS(SELECT 1 FROM org.EmpleadoUOT X WHERE X.empleado_id=E.empleado_id AND X.uot_id=U.uot_id AND X.estado=1 AND X.fecha_hasta IS NULL);

    UPDATE EU SET fecha_hasta=E.fecha_cese,estado=E.estado
    FROM org.EmpleadoUOT EU JOIN inserted I ON I.empleado_id=EU.empleado_id JOIN org.Empleado E ON E.empleado_id=EU.empleado_id
    JOIN org.UOT U ON U.uot_id=EU.uot_id AND U.empresa_legacy_id=E.empresa_id;
END;
GO
