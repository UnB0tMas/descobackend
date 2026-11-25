IF OBJECT_ID(N'[seg].[TR_Usuario_SincronizarUOTEmpleado]') IS NOT NULL
    DROP TRIGGER [seg].[TR_Usuario_SincronizarUOTEmpleado];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : seg.TR_Usuario_SincronizarUOTEmpleado
' Descripción            : Sincroniza UOT y empleado para usuarios.
' Aplicativo / Módulo    : DESCO / Seguridad
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
