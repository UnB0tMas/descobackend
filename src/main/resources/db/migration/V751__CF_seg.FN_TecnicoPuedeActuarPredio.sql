IF OBJECT_ID(N'[seg].[FN_TecnicoPuedeActuarPredio]', N'FN') IS NOT NULL
    DROP FUNCTION seg.FN_TecnicoPuedeActuarPredio;
GO

-- Comprueba autorizaciones efectivas de campo; no se basa en IDs recibidos del navegador.
CREATE FUNCTION seg.FN_TecnicoPuedeActuarPredio
(
    @Sesion BIGINT,
    @Usuario BIGINT,
    @Predio BIGINT,
    @Salida BIGINT,
    @Visita BIGINT,
    @Permiso VARCHAR(40)
)
RETURNS BIT
AS
BEGIN
    DECLARE @Uot BIGINT, @Empleado BIGINT, @Requiere BIT=1, @AdminExento BIT=1;
    SELECT @Uot=S.uot_contexto_id,@Empleado=U.persona_id
    FROM seg.SesionUsuario S
    JOIN seg.Usuario U ON U.usuario_id=S.usuario_id AND U.estado=1 AND U.estado_cuenta='ACTIVA'
    JOIN org.Empleado E ON E.empleado_id=U.persona_id AND E.estado=1
    WHERE S.sesion_usuario_id=@Sesion AND S.usuario_id=@Usuario AND S.estado=1
      AND S.fecha_revocacion IS NULL AND S.fecha_expiracion_renovacion>SYSUTCDATETIME()
      AND S.modo_uot='ESPECIFICA'
      AND (E.fecha_cese IS NULL OR E.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()));
    IF @Uot IS NULL OR @Empleado IS NULL OR @Predio IS NULL
       OR seg.FN_Usuario_TienePermisoUOT(@Usuario,@Uot,@Permiso)<>1
        RETURN 0;
    IF NOT EXISTS(SELECT 1 FROM org.EmpleadoUOT EU
         WHERE EU.empleado_id=@Empleado AND EU.uot_id=@Uot AND EU.estado=1
           AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
           AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
           AND (EU.fecha_cese IS NULL OR EU.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME())))
        RETURN 0;
    IF NOT EXISTS(SELECT 1 FROM prod.Predio P WHERE P.predio_id=@Predio AND P.uot_id=@Uot AND P.estado=1)
       AND NOT EXISTS(SELECT 1 FROM prod.PredioAmbito A WHERE A.predio_id=@Predio AND A.uot_id=@Uot AND A.estado=1)
        RETURN 0;
    SELECT @Requiere=requiere_salida,@AdminExento=administrador_exento
    FROM campo.SalidaActuacionPolitica CP
    JOIN seg.Permiso P ON P.permiso_id=CP.permiso_id AND P.codigo=@Permiso AND P.estado=1
    WHERE CP.uot_id=@Uot AND CP.estado=1;
    IF @Requiere=0 RETURN 1;
    IF @AdminExento=1 AND seg.FN_Usuario_TienePermisoUOT(@Usuario,@Uot,'SALIDAS_ADMINISTRAR')=1
       AND seg.FN_Usuario_TienePermisoUOT(@Usuario,@Uot,'PREDIOS_ADMINISTRAR')=1
        RETURN 1;
    IF @Salida IS NULL OR @Visita IS NULL RETURN 0;
    IF NOT EXISTS
    (
        SELECT 1
        FROM campo.SalidaE2 E
        JOIN campo.SalidaCampo SC ON SC.salida_campo_id=E.salida_campo_id
        JOIN campo.SalidaParticipante SP ON SP.salida_campo_id=E.salida_campo_id
            AND SP.empleado_id=@Empleado AND SP.estado=1
        JOIN campo.SalidaDestinoE2 D ON D.salida_campo_id=E.salida_campo_id
            AND D.predio_id=@Predio
        JOIN campo.SalidaVisitaE2 SV ON SV.destino_id=D.destino_id
            AND SV.visita_tecnica_id=@Visita
        JOIN campo.VisitaTecnica V ON V.visita_tecnica_id=SV.visita_tecnica_id
            AND V.predio_id=@Predio AND V.estado=1 AND V.estado_proceso='INICIADA'
            AND V.fecha_hora_fin IS NULL
        WHERE E.salida_campo_id=@Salida AND E.uot_id=@Uot
          AND E.convenio_id IS NULL AND E.estado='EN_EJECUCION'
          AND E.fecha_aprobacion IS NOT NULL AND E.fecha_aprobacion<=SYSUTCDATETIME()
          AND (E.fecha_fin_prevista IS NULL OR E.fecha_fin_prevista>=SYSUTCDATETIME())
          AND SC.fecha_hora_programada<=SYSUTCDATETIME()
          AND V.fecha_hora_inicio<=SYSUTCDATETIME()
          AND (
            NOT EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 SR WHERE SR.salida_campo_id=E.salida_campo_id)
            OR NOT EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 SR
                     WHERE SR.salida_campo_id=E.salida_campo_id AND SR.estado<>'ENTREGADO')
          )
    ) RETURN 0;
    RETURN 1;
END;
GO
