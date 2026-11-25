IF OBJECT_ID(N'[reporte].[PA_TrabajoEvento_Sel_Uot]', N'P') IS NOT NULL
    DROP PROCEDURE [reporte].[PA_TrabajoEvento_Sel_Uot];
GO

-- Valida el ámbito específico y vigente de la sesión para recibir avisos de trabajos.
CREATE PROCEDURE [reporte].[PA_TrabajoEvento_Sel_Uot]
    @nUsuarioId BIGINT,
    @gSesionPublicaId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- La autorización se consulta sin NOLOCK para evitar lecturas de permisos no confirmados.
    SELECT SU.uot_contexto_id AS uotId
    FROM seg.SesionUsuario AS SU
    INNER JOIN seg.UsuarioUOT AS UU
        ON UU.usuario_id = SU.usuario_id
        AND UU.uot_id = SU.uot_contexto_id
        AND UU.estado = 1
        AND UU.fecha_desde <= SYSUTCDATETIME()
        AND (UU.fecha_hasta IS NULL OR UU.fecha_hasta >= SYSUTCDATETIME())
    WHERE SU.usuario_id = @nUsuarioId
        AND SU.sesion_publica_id = @gSesionPublicaId
        AND SU.estado = 1
        AND SU.fecha_revocacion IS NULL
        AND SU.modo_uot = 'ESPECIFICA'
        AND ISNULL(seg.FN_Usuario_TienePermisoUOT(SU.usuario_id, SU.uot_contexto_id, 'REPORTES_CONTROL_VER'), 0) = 1
        AND ISNULL(seg.FN_Usuario_TienePermisoUOT(SU.usuario_id, SU.uot_contexto_id, 'REPORTES_LISTAR'), 0) = 1;
END;
GO
