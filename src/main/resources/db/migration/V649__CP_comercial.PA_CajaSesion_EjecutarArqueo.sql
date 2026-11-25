IF OBJECT_ID(N'[comercial].[PA_CajaSesion_EjecutarArqueo]', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE [comercial].[PA_CajaSesion_EjecutarArqueo];
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* Balance por sesión y cierre transaccional. La simulación nunca modifica datos. */
CREATE PROCEDURE [comercial].[PA_CajaSesion_EjecutarArqueo]
    @cAccion VARCHAR(12),
    @nUsuarioId BIGINT,
    @nUotId BIGINT,
    @nCajaSesionId BIGINT,
    @nSaldoDeclarado DECIMAL(19,4) = NULL,
    @cObservacion NVARCHAR(500) = NULL,
    @cReporteJson NVARCHAR(MAX) OUTPUT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(80) OUTPUT,
    @nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @cReporteJson = NULL;
    SET @bResultado = 0;
    SET @cMensaje = N'No se pudo consultar la caja.';
    SET @cCodigoRespuesta = 'CAJA_NO_DISPONIBLE';
    SET @nHttpRespuesta = 404;

    IF @cAccion NOT IN ('CONSULTAR', 'CERRAR') OR @cAccion IS NULL
    BEGIN
        SET @cMensaje = N'La acción no está disponible.';
        SET @cCodigoRespuesta = 'ACCION_NO_DISPONIBLE';
        SET @nHttpRespuesta = 400;
        RETURN;
    END;

    DECLARE @Supervisa BIT = ISNULL(seg.FN_Usuario_TienePermisoUOT(@nUsuarioId, @nUotId, 'CAJAS_SUPERVISAR'), 0);
    DECLARE @Cierra BIT = ISNULL(seg.FN_Usuario_TienePermisoUOT(@nUsuarioId, @nUotId, 'CAJAS_CERRAR'), 0);

    IF (@cAccion = 'CERRAR' AND @Cierra = 0) OR (@cAccion = 'CONSULTAR' AND @Supervisa = 0 AND @Cierra = 0)
    BEGIN
        SET @cMensaje = N'No tienes permiso para esta operación.';
        SET @cCodigoRespuesta = 'CAJA_SIN_PERMISO';
        SET @nHttpRespuesta = 403;
        RETURN;
    END;

    DECLARE @Estado VARCHAR(10), @CajaId BIGINT, @Caja NVARCHAR(120), @UotNombre NVARCHAR(160);
    DECLARE @CajaActiva BIT;
    DECLARE @Fondo DECIMAL(19,4), @Efectivo DECIMAL(19,4), @Transferencias DECIMAL(19,4);
    DECLARE @Ingresos DECIMAL(19,4), @Egresos DECIMAL(19,4), @Esperado DECIMAL(19,4);
    DECLARE @Declarado DECIMAL(19,4), @Diferencia DECIMAL(19,4), @ObservacionFinal NVARCHAR(500);
    DECLARE @Pendientes BIGINT, @FechaApertura DATETIME2(0), @FechaCierre DATETIME2(0);
    DECLARE @Operador BIGINT, @UsuarioApertura BIGINT, @UsuarioCierre BIGINT;
    DECLARE @VentasTotal DECIMAL(19,4), @Cobrado DECIMAL(19,4);
    DECLARE @CerradaAhora BIT = 0;
    DECLARE @TranPropia BIT = 0;

    BEGIN TRY
        IF @cAccion = 'CERRAR'
        BEGIN
            IF @@TRANCOUNT = 0
            BEGIN
                BEGIN TRANSACTION;
                SET @TranPropia = 1;
            END
            ELSE
            BEGIN
                SAVE TRANSACTION CajaArqueoCierre;
            END;
        END;

        SELECT
            @Estado = S.estado,
            @CajaId = C.caja_id,
            @CajaActiva = C.estado,
            @Caja = C.nombre,
            @UotNombre = U.nombre,
            @Fondo = S.saldo_inicial,
            @Declarado = S.saldo_declarado,
            @Diferencia = S.diferencia,
            @ObservacionFinal = S.observacion_cierre,
            @Esperado = S.saldo_esperado,
            @FechaApertura = S.fecha_apertura,
            @FechaCierre = S.fecha_cierre,
            @Operador = S.usuario_operador_id,
            @UsuarioApertura = S.usuario_apertura_id,
            @UsuarioCierre = S.usuario_cierre_id
        FROM comercial.CajaSesion AS S WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN comercial.CajaPOS AS C ON C.caja_id = S.caja_id
        INNER JOIN org.UOT AS U ON U.uot_id = C.uot_id
        WHERE S.caja_sesion_id = @nCajaSesionId
          AND C.uot_id = @nUotId;

        IF @Estado IS NULL
        BEGIN
            IF @cAccion = 'CERRAR'
            BEGIN
                IF @TranPropia = 1
                BEGIN
                    ROLLBACK TRANSACTION;
                END
                ELSE
                BEGIN
                    ROLLBACK TRANSACTION CajaArqueoCierre;
                END;
            END;
            RETURN;
        END;

        IF @Supervisa = 0 AND NOT EXISTS
        (
            SELECT 1
            FROM comercial.CajaSesionOperador AS O
            WHERE O.caja_sesion_id = @nCajaSesionId
              AND O.usuario_id = @nUsuarioId
        ) AND @UsuarioApertura <> @nUsuarioId AND ISNULL(@UsuarioCierre, 0) <> @nUsuarioId
        BEGIN
            IF @cAccion = 'CERRAR'
            BEGIN
                IF @TranPropia = 1
                BEGIN
                    ROLLBACK TRANSACTION;
                END
                ELSE
                BEGIN
                    ROLLBACK TRANSACTION CajaArqueoCierre;
                END;
            END;
            SET @cMensaje = N'No tienes acceso a este turno.';
            SET @cCodigoRespuesta = 'TURNO_SIN_ACCESO';
            SET @nHttpRespuesta = 403;
            RETURN;
        END;

        IF @cAccion = 'CERRAR' AND
           (@CajaActiva = 0 OR
            (@Supervisa = 0 AND NOT EXISTS
            (
                SELECT 1
                FROM comercial.CajaSesionOperador AS O
                WHERE O.caja_sesion_id = @nCajaSesionId
                  AND O.usuario_id = @nUsuarioId
                  AND O.activo = 1
            )))
        BEGIN
            IF @TranPropia = 1
            BEGIN
                ROLLBACK TRANSACTION;
            END
            ELSE
            BEGIN
                ROLLBACK TRANSACTION CajaArqueoCierre;
            END;
            SET @cMensaje = N'No puedes cerrar este turno.';
            SET @cCodigoRespuesta = 'TURNO_NO_DISPONIBLE';
            SET @nHttpRespuesta = 403;
            RETURN;
        END;

        /* Un cierre registrado conserva importes y ventas originales. */
        IF @Estado = 'CERRADA'
        BEGIN
            SELECT @cReporteJson = R.reporte_json
            FROM comercial.CajaCierreReporte AS R
            WHERE R.caja_sesion_id = @nCajaSesionId;

            IF @cReporteJson IS NOT NULL
            BEGIN
                IF @cAccion = 'CERRAR'
                BEGIN
                    IF @TranPropia = 1
                    BEGIN
                        ROLLBACK TRANSACTION;
                    END
                    ELSE
                    BEGIN
                        ROLLBACK TRANSACTION CajaArqueoCierre;
                    END;
                    SET @cMensaje = N'La caja ya está cerrada.';
                    SET @cCodigoRespuesta = 'CAJA_YA_CERRADA';
                    SET @nHttpRespuesta = 409;
                    RETURN;
                END;

                SET @bResultado = 1;
                SET @cMensaje = N'Cierre consultado.';
                SET @cCodigoRespuesta = 'CAJA_ARQUEO_OK';
                SET @nHttpRespuesta = 200;
                RETURN;
            END;
        END;

        SELECT @Pendientes = COUNT_BIG(1)
        FROM comercial.Venta AS V WITH (UPDLOCK, HOLDLOCK)
        WHERE V.caja_sesion_id = @nCajaSesionId
          AND V.estado = 1
          AND V.estado_venta NOT IN ('ANULADA', 'ENTREGADA');

        SELECT
            @Efectivo = ISNULL(SUM(CASE WHEN MP.codigo = 'EFECTIVO' THEN P.importe ELSE 0 END), 0),
            @Transferencias = ISNULL(SUM(CASE WHEN MP.codigo <> 'EFECTIVO' THEN P.importe ELSE 0 END), 0),
            @Cobrado = ISNULL(SUM(P.importe), 0)
        FROM comercial.PagoVenta AS P
        INNER JOIN comercial.Venta AS V ON V.venta_id = P.venta_id
        INNER JOIN comercial.MetodoPago AS MP ON MP.metodo_pago_id = P.metodo_pago_id
        WHERE V.caja_sesion_id = @nCajaSesionId
          AND V.estado = 1
          AND V.estado_venta <> 'ANULADA'
          AND P.estado = 1
          AND P.estado_pago = 'CONFIRMADO';

        SELECT
            @Ingresos = ISNULL(SUM(CASE WHEN M.tipo = 'INGRESO' THEN M.importe ELSE 0 END), 0),
            @Egresos = ISNULL(SUM(CASE WHEN M.tipo = 'EGRESO' THEN M.importe ELSE 0 END), 0)
        FROM comercial.CajaMovimiento AS M
        WHERE M.caja_sesion_id = @nCajaSesionId;

        SELECT @VentasTotal = ISNULL(SUM(V.total), 0)
        FROM comercial.Venta AS V
        WHERE V.caja_sesion_id = @nCajaSesionId
          AND V.estado = 1
          AND V.estado_venta = 'ENTREGADA';

        IF @Estado = 'ABIERTA'
        BEGIN
            SET @Esperado = @Fondo + @Efectivo + @Ingresos - @Egresos;
        END;

        IF @cAccion = 'CERRAR'
        BEGIN
            IF @Estado = 'CERRADA'
            BEGIN
                IF @TranPropia = 1
                BEGIN
                    ROLLBACK TRANSACTION;
                END
                ELSE
                BEGIN
                    ROLLBACK TRANSACTION CajaArqueoCierre;
                END;
                SET @cMensaje = N'La caja ya está cerrada.';
                SET @cCodigoRespuesta = 'CAJA_YA_CERRADA';
                SET @nHttpRespuesta = 409;
                RETURN;
            END
            ELSE
            BEGIN
                IF @Estado <> 'ABIERTA' OR @nSaldoDeclarado IS NULL OR @nSaldoDeclarado < 0
                   OR @nSaldoDeclarado <> ROUND(@nSaldoDeclarado, 2)
                BEGIN
                    IF @TranPropia = 1
                    BEGIN
                        ROLLBACK TRANSACTION;
                    END
                    ELSE
                    BEGIN
                        ROLLBACK TRANSACTION CajaArqueoCierre;
                    END;
                    SET @cMensaje = N'El importe contado no es válido.';
                    SET @cCodigoRespuesta = 'IMPORTE_INVALIDO';
                    SET @nHttpRespuesta = 400;
                    RETURN;
                END;

                IF @Pendientes > 0
                BEGIN
                    IF @TranPropia = 1
                    BEGIN
                        ROLLBACK TRANSACTION;
                    END
                    ELSE
                    BEGIN
                        ROLLBACK TRANSACTION CajaArqueoCierre;
                    END;
                    SET @cMensaje = N'Tienes ventas pendientes de finalizar.';
                    SET @cCodigoRespuesta = 'VENTAS_PENDIENTES';
                    SET @nHttpRespuesta = 409;
                    RETURN;
                END;

                IF @Esperado < 0
                BEGIN
                    IF @TranPropia = 1
                    BEGIN
                        ROLLBACK TRANSACTION;
                    END
                    ELSE
                    BEGIN
                        ROLLBACK TRANSACTION CajaArqueoCierre;
                    END;
                    SET @cMensaje = N'Revisa los movimientos de efectivo.';
                    SET @cCodigoRespuesta = 'SALDO_INVALIDO';
                    SET @nHttpRespuesta = 409;
                    RETURN;
                END;

                SET @Diferencia = @nSaldoDeclarado - @Esperado;
                SET @ObservacionFinal = NULLIF(LTRIM(RTRIM(@cObservacion)), N'');
                IF @Diferencia <> 0 AND @ObservacionFinal IS NULL
                BEGIN
                    IF @TranPropia = 1
                    BEGIN
                        ROLLBACK TRANSACTION;
                    END
                    ELSE
                    BEGIN
                        ROLLBACK TRANSACTION CajaArqueoCierre;
                    END;
                    SET @cMensaje = N'Explica la diferencia de efectivo.';
                    SET @cCodigoRespuesta = 'OBSERVACION_OBLIGATORIA';
                    SET @nHttpRespuesta = 409;
                    RETURN;
                END;

                SET @FechaCierre = SYSUTCDATETIME();
                UPDATE comercial.CajaSesion
                SET estado = 'CERRADA',
                    fecha_cierre = @FechaCierre,
                    usuario_cierre_id = @nUsuarioId,
                    saldo_esperado = @Esperado,
                    saldo_declarado = @nSaldoDeclarado,
                    diferencia = @Diferencia,
                    observacion_cierre = @ObservacionFinal
                WHERE caja_sesion_id = @nCajaSesionId AND estado = 'ABIERTA';

                IF @@ROWCOUNT <> 1
                BEGIN
                    THROW 51001, N'No se pudo confirmar el cierre.', 1;
                END;

                UPDATE comercial.CajaSesionOperador
                SET activo = 0,
                    fecha_retiro = SYSUTCDATETIME(),
                    usuario_retiro_id = @nUsuarioId
                WHERE caja_sesion_id = @nCajaSesionId AND activo = 1;

                SET @Declarado = @nSaldoDeclarado;
                SET @Estado = 'CERRADA';
                SET @CerradaAhora = 1;
            END;
        END;

        /* Un único turno: los pagos se agrupan por medio, sin mezclar aperturas. */
        SELECT @cReporteJson =
        (
            SELECT
                @nCajaSesionId AS sesionId,
                @CajaId AS cajaId,
                @Caja AS caja,
                @UotNombre AS uotNombre,
                @Estado AS estado,
                CONVERT(VARCHAR(19), DATEADD(HOUR, -5, @FechaApertura), 126) AS fechaApertura,
                CONVERT(VARCHAR(19), DATEADD(HOUR, -5, @FechaCierre), 126) AS fechaCierre,
                @Operador AS operadorId,
                @Fondo AS saldoInicial,
                @Efectivo AS efectivo,
                @Transferencias AS otrosMedios,
                @Ingresos AS ingresos,
                @Egresos AS egresos,
                @VentasTotal AS ventasEntregadas,
                @Cobrado AS totalCobrado,
                @Esperado AS saldoEsperado,
                @Declarado AS saldoDeclarado,
                @Diferencia AS diferencia,
                @ObservacionFinal AS observacion,
                @Pendientes AS ventasPendientes,
                JSON_QUERY((
                    SELECT MP.codigo AS codigo, MP.nombre AS nombre, SUM(P.importe) AS total
                    FROM comercial.PagoVenta AS P
                    INNER JOIN comercial.MetodoPago AS MP ON MP.metodo_pago_id = P.metodo_pago_id
                    INNER JOIN comercial.Venta AS V ON V.venta_id = P.venta_id
                    WHERE V.caja_sesion_id = @nCajaSesionId
                      AND V.estado = 1 AND V.estado_venta <> 'ANULADA'
                      AND P.estado = 1 AND P.estado_pago = 'CONFIRMADO'
                    GROUP BY MP.codigo, MP.nombre
                    ORDER BY MP.nombre
                    FOR JSON PATH
                )) AS metodos,
                JSON_QUERY((
                    SELECT
                        V.venta_id AS ventaId,
                        CONVERT(VARCHAR(19), DATEADD(HOUR, -5, V.fecha_hora), 126) AS fecha,
                        V.estado_venta AS estado,
                        V.total AS total,
                        JSON_QUERY((
                            SELECT MP.codigo AS codigo, MP.nombre AS nombre, P.importe AS importe
                            FROM comercial.PagoVenta AS P
                            INNER JOIN comercial.MetodoPago AS MP ON MP.metodo_pago_id = P.metodo_pago_id
                            WHERE P.venta_id = V.venta_id AND P.estado = 1 AND P.estado_pago = 'CONFIRMADO'
                            ORDER BY P.pago_venta_id
                            FOR JSON PATH
                        )) AS pagos
                    FROM comercial.Venta AS V
                    WHERE V.caja_sesion_id = @nCajaSesionId AND V.estado = 1
                    ORDER BY V.fecha_hora, V.venta_id
                    FOR JSON PATH
                )) AS ventas
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        IF @CerradaAhora = 1
        BEGIN
            INSERT INTO comercial.CajaCierreReporte
                (caja_sesion_id, reporte_json, usuario_cierre_id)
            VALUES
                (@nCajaSesionId, @cReporteJson, @nUsuarioId);
        END;

        IF @cAccion = 'CERRAR'
        BEGIN
            IF @TranPropia = 1
            BEGIN
                COMMIT TRANSACTION;
            END;
        END;

        SET @bResultado = 1;
        SET @cMensaje = CASE WHEN @cAccion = 'CERRAR' THEN N'Caja cerrada.' ELSE N'Balance consultado.' END;
        SET @cCodigoRespuesta = 'CAJA_ARQUEO_OK';
        SET @nHttpRespuesta = 200;
    END TRY
    BEGIN CATCH
        IF @cAccion = 'CERRAR' AND XACT_STATE() <> 0
        BEGIN
            IF @TranPropia = 1
            BEGIN
                ROLLBACK TRANSACTION;
            END
            ELSE IF XACT_STATE() = 1
            BEGIN
                ROLLBACK TRANSACTION CajaArqueoCierre;
            END;
        END;
        THROW;
    END CATCH;
END;
GO
