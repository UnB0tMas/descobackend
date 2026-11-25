IF OBJECT_ID(N'[logistica].[PA_SalidaConsumoE2_Sel_Disponibles]', N'P') IS NOT NULL
    DROP PROCEDURE logistica.PA_SalidaConsumoE2_Sel_Disponibles;
GO

-- Respeta las programaciones históricas y limita el consumo de campo a recursos E2 entregados.
CREATE PROCEDURE logistica.PA_SalidaConsumoE2_Sel_Disponibles
    @gSesionPublica UNIQUEIDENTIFIER,
    @nUsuario BIGINT,
    @nResponsable BIGINT=NULL,
    @nSalida BIGINT=NULL,
    @nVisita BIGINT=NULL,
    @nPredio BIGINT=NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Sesion BIGINT,@Empleado BIGINT,@Uot BIGINT;
    SELECT @Sesion=S.sesion_usuario_id,@Uot=S.uot_contexto_id,@Empleado=U.persona_id
    FROM seg.SesionUsuario S
    JOIN seg.Usuario U ON U.usuario_id=S.usuario_id AND U.estado=1 AND U.estado_cuenta='ACTIVA'
    WHERE S.sesion_publica_id=@gSesionPublica AND S.usuario_id=@nUsuario
      AND S.estado=1 AND S.fecha_revocacion IS NULL AND S.fecha_expiracion_renovacion>SYSUTCDATETIME()
      AND S.modo_uot='ESPECIFICA';
    IF @Sesion IS NULL OR @Uot IS NULL OR seg.FN_Usuario_TienePermisoUOT(@nUsuario,@Uot,'SANIDAD_CREAR')<>1
        THROW 51060,N'No tiene permiso para consultar estos recursos.',1;
    IF @nSalida IS NULL
    BEGIN
        IF @nVisita IS NOT NULL OR @nPredio IS NOT NULL
            THROW 51066,N'Seleccione una salida válida.',1;
        SELECT PP.programacion_producto_id programacionProductoId,
            CAST(NULL AS BIGINT) solicitudRecursoId,CAST(NULL AS BIGINT) salidaCampoId,
            P.nombre producto,P.unidad_medida unidadMedida,A.nombre almacen,
            PP.cantidad_entregada cantidadEntregada,PP.cantidad_consumida cantidadUtilizada,
            PP.cantidad_entregada-PP.cantidad_devuelta-PP.cantidad_consumida cantidadPendiente,
            CAST(NULL AS NVARCHAR(100)) lote,CAST(NULL AS DATE) fechaVencimiento,
            CAST('PROGRAMACION' AS VARCHAR(30)) fuente
        FROM logistica.ProgramacionProducto PP
        JOIN logistica.Producto P ON P.producto_id=PP.producto_id
        JOIN logistica.Almacen A ON A.almacen_id=PP.almacen_id
        WHERE PP.estado_proceso='ENTREGADA' AND PP.uot_id=@Uot
          AND PP.cantidad_entregada>PP.cantidad_devuelta+PP.cantidad_consumida
          AND PP.empleado_id=COALESCE(@nResponsable,@Empleado)
          AND (PP.empleado_id=@Empleado OR seg.FN_Usuario_TienePermisoUOT(@nUsuario,@Uot,'ALMACENES_MOVIMIENTO')=1)
        ORDER BY P.nombre,PP.programacion_producto_id;
        RETURN;
    END;
    IF @nVisita IS NULL OR @nPredio IS NULL OR
       seg.FN_TecnicoPuedeActuarPredio(@Sesion,@nUsuario,@nPredio,@nSalida,@nVisita,'SANIDAD_CREAR')<>1
        THROW 51060,N'No tiene autorización para trabajar en este predio.',1;
    SELECT CAST(NULL AS BIGINT) programacionProductoId,R.solicitud_recurso_id solicitudRecursoId,
        R.salida_campo_id salidaCampoId,S.nombre producto,S.unidad_medida unidadMedida,
        CAST(NULL AS NVARCHAR(150)) almacen,RP.cantidad_entregada cantidadEntregada,
        RP.cantidad_consumida cantidadUtilizada,RP.cantidad_pendiente cantidadPendiente,
        CAST(NULL AS NVARCHAR(100)) lote,CAST(NULL AS DATE) fechaVencimiento,
        CASE WHEN EXISTS(SELECT 1 FROM logistica.TransferenciaSuministroTecnico T
             WHERE T.salida_campo_id=R.salida_campo_id AND T.suministro_id=R.suministro_id)
            THEN 'COMERCIAL_TRANSFERIDO' ELSE 'TECNICO' END fuente
    FROM campo.SalidaRecursoE2 R
    JOIN campo.SalidaE2 E ON E.salida_campo_id=R.salida_campo_id AND E.uot_id=@Uot
    JOIN logistica.RecursoProgramado RP ON RP.recurso_programado_id=R.recurso_programado_id
      AND RP.salida_campo_id=R.salida_campo_id AND RP.estado=1
    JOIN logistica.Suministro S ON S.suministro_id=R.suministro_id AND S.uot_id=@Uot AND S.estado=1
    WHERE R.salida_campo_id=@nSalida AND R.suministro_id IS NOT NULL AND R.estado='ENTREGADO'
      AND RP.estado_proceso='EN_EJECUCION' AND RP.cantidad_pendiente>0
    ORDER BY S.nombre,R.solicitud_recurso_id;
END;
GO
