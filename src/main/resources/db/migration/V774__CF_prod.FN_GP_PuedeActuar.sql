IF OBJECT_ID(N'[prod].[FN_GP_PuedeActuar]', N'FN') IS NOT NULL
    DROP FUNCTION prod.FN_GP_PuedeActuar;
GO

-- Control de actuaciones productivas por sesión, UOT y predio.
CREATE FUNCTION prod.FN_GP_PuedeActuar
(
    @Sesion UNIQUEIDENTIFIER,
    @Usuario BIGINT,
    @Uot BIGINT,
    @Predio BIGINT
)
RETURNS BIT
AS
BEGIN
    DECLARE @Empleado BIGINT;
    SELECT @Empleado = U.persona_id
    FROM seg.SesionUsuario S
    JOIN seg.Usuario U ON U.usuario_id = S.usuario_id AND U.estado = 1 AND U.estado_cuenta = 'ACTIVA'
    WHERE S.sesion_publica_id = @Sesion AND S.usuario_id = @Usuario
      AND S.estado = 1 AND S.fecha_revocacion IS NULL
      AND S.fecha_expiracion_renovacion > SYSUTCDATETIME()
      AND S.modo_uot = 'ESPECIFICA' AND S.uot_contexto_id = @Uot;
    IF @Empleado IS NULL OR @Uot IS NULL RETURN 0;

    IF @Predio IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM prod.Predio P
        JOIN prod.PredioAmbito A ON A.predio_id = P.predio_id
        WHERE P.predio_id = @Predio AND P.estado = 1 AND A.estado = 1
          AND A.uot_id = @Uot AND A.convenio_uot_organizacion_id IS NULL
    ) RETURN 0;

    -- La excepción es por permisos efectivos, no por el nombre del rol.
    IF seg.FN_Usuario_TienePermisoUOT(@Usuario, @Uot, 'SALIDAS_ADMINISTRAR') = 1
       AND seg.FN_Usuario_TienePermisoUOT(@Usuario, @Uot, 'PREDIOS_ADMINISTRAR') = 1
        RETURN 1;
    IF @Predio IS NULL RETURN 0;

    IF EXISTS (
        SELECT 1 FROM campo.SalidaE2 S
        JOIN campo.SalidaCampo C ON C.salida_campo_id = S.salida_campo_id AND C.estado = 1
        JOIN campo.SalidaParticipante SP ON SP.salida_campo_id = S.salida_campo_id
            AND SP.empleado_id = @Empleado AND SP.estado = 1
        JOIN org.Empleado E ON E.empleado_id = SP.empleado_id AND E.estado = 1
        JOIN org.EmpleadoUOT EU ON EU.empleado_id = E.empleado_id AND EU.uot_id = @Uot AND EU.estado = 1
        JOIN campo.SalidaDestinoE2 D ON D.salida_campo_id = S.salida_campo_id AND D.predio_id = @Predio
        JOIN campo.SalidaVisitaE2 SV ON SV.destino_id = D.destino_id
        JOIN campo.VisitaTecnica V ON V.visita_tecnica_id = SV.visita_tecnica_id AND V.predio_id = @Predio
        WHERE S.uot_id = @Uot AND S.convenio_id IS NULL AND S.estado = 'EN_EJECUCION'
          AND S.fecha_aprobacion IS NOT NULL AND S.fecha_aprobacion <= SYSUTCDATETIME()
          AND C.fecha_hora_salida_real IS NOT NULL AND C.fecha_hora_salida_real <= SYSUTCDATETIME()
          AND C.fecha_hora_retorno_real IS NULL AND C.fecha_hora_programada <= SYSUTCDATETIME()
          AND (S.fecha_fin_prevista IS NULL OR S.fecha_fin_prevista > SYSUTCDATETIME())
          AND V.estado = 1 AND V.estado_proceso = 'INICIADA' AND V.fecha_hora_fin IS NULL
          AND V.fecha_hora_inicio <= SYSUTCDATETIME()
          AND (E.fecha_cese IS NULL OR E.fecha_cese >= CONVERT(DATE, SYSUTCDATETIME()))
          AND EU.fecha_desde <= CONVERT(DATE, SYSUTCDATETIME())
          AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta >= CONVERT(DATE, SYSUTCDATETIME()))
          AND (EU.fecha_cese IS NULL OR EU.fecha_cese >= CONVERT(DATE, SYSUTCDATETIME()))
          AND NOT EXISTS (SELECT 1 FROM campo.SalidaRecursoE2 R
              WHERE R.salida_campo_id = S.salida_campo_id AND R.estado <> 'ENTREGADO')
    ) RETURN 1;
    RETURN 0;
END;
GO
