IF OBJECT_ID(N'[seg].[TR_Usuario_SincronizarUOTEmpleado]', N'TR') IS NOT NULL
    DROP TRIGGER [seg].[TR_Usuario_SincronizarUOTEmpleado];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : seg.TR_Usuario_SincronizarUOTEmpleado
' Descripción              : Sincroniza UOT y empleado para usuarios.
' Tabla asociada          : seg.Usuario
' Evento que lo dispara   : AFTER INSERT
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Seguridad
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    -- Se ejecuta automáticamente mediante AFTER INSERT sobre seg.Usuario.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[seg].[TR_Usuario_SincronizarUOTEmpleado]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER seg.TR_Usuario_SincronizarUOTEmpleado
ON seg.Usuario AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT seg.UsuarioUOT(usuario_id,uot_id,es_predeterminada,fecha_desde,estado)
    SELECT I.usuario_id,EU.uot_id,
           CASE WHEN ROW_NUMBER() OVER(PARTITION BY I.usuario_id ORDER BY EU.es_principal DESC,EU.uot_id)=1 THEN 1 ELSE 0 END,
           SYSUTCDATETIME(),1
    FROM inserted I JOIN org.EmpleadoUOT EU ON EU.empleado_id=I.persona_id AND EU.estado=1 AND EU.fecha_hasta IS NULL
    WHERE NOT EXISTS(SELECT 1 FROM seg.UsuarioUOT X WHERE X.usuario_id=I.usuario_id AND X.uot_id=EU.uot_id AND X.estado=1 AND X.fecha_hasta IS NULL);
END;
GO
