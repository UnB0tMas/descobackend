IF OBJECT_ID(N'[logistica].[PA_Suministro_Ins_TransferenciaComercial]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_Suministro_Ins_TransferenciaComercial];
GO

-- Moviliza stock comercial a un suministro técnico solo dentro de una salida aprobándose.
CREATE PROCEDURE [logistica].[PA_Suministro_Ins_TransferenciaComercial]
    @nUsuarioId BIGINT,
    @nUotId BIGINT,
    @nSalidaId BIGINT,
    @nSuministroId BIGINT,
    @nCantidad DECIMAL(19,3),
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SELECT @bResultado=0,@cMensaje=N'No se pudo transferir el producto.';

    IF @@TRANCOUNT=0
        THROW 51067,N'La transferencia requiere una solicitud autorizada.',1;
    IF @nCantidad IS NULL OR @nCantidad<=0 OR @nUotId IS NULL OR @nSalidaId IS NULL
        THROW 51067,N'La cantidad solicitada no es válida.',1;
    IF [seg].[FN_Usuario_TienePermisoUOT](@nUsuarioId,@nUotId,'SALIDAS_CONFIRMAR')<>1
        THROW 51060,N'No tiene permiso para aprobar esta salida.',1;

    DECLARE @nProductoId BIGINT,@cUnidadS VARCHAR(20),@cUnidadP VARCHAR(20),
            @bRequiereLote BIT,@bControlaVencimiento BIT,@nRestante DECIMAL(19,3)=@nCantidad,
            @nAlmacenId BIGINT,@nDisponible DECIMAL(19,3),@nTomar DECIMAL(19,3),
            @nMovimientoId BIGINT,@nMovimientoSuministroId BIGINT;

    SELECT @nProductoId=S.producto_id,@cUnidadS=S.unidad_medida,
           @cUnidadP=P.unidad_medida,@bRequiereLote=P.requiere_lote,
           @bControlaVencimiento=P.controla_vencimiento
    FROM logistica.Suministro S WITH (UPDLOCK,HOLDLOCK)
    INNER JOIN logistica.Producto P WITH (NOLOCK) ON P.producto_id=S.producto_id AND P.estado=1
    INNER JOIN logistica.ProductoUOTPolitica PU WITH (NOLOCK)
        ON PU.producto_id=P.producto_id AND PU.uot_id=@nUotId
       AND PU.estado=1 AND PU.permite_uso_interno=1
    WHERE S.suministro_id=@nSuministroId AND S.uot_id=@nUotId AND S.estado=1;
    IF @nProductoId IS NULL OR @cUnidadS<>@cUnidadP
        THROW 51067,N'El suministro no tiene un producto comercial válido.',1;
    IF @bRequiereLote=1 OR @bControlaVencimiento=1
        THROW 51067,N'El producto requiere entrega controlada por lote.',1;
    IF EXISTS(SELECT 1 FROM logistica.TransferenciaSuministroTecnico WITH (UPDLOCK,HOLDLOCK)
              WHERE salida_campo_id=@nSalidaId AND suministro_id=@nSuministroId)
        THROW 51067,N'El suministro ya tiene una transferencia para esta salida.',1;

    WHILE @nRestante>0
    BEGIN
        SELECT @nAlmacenId=NULL,@nDisponible=NULL;
        SELECT TOP(1) @nAlmacenId=A.almacen_id,@nDisponible=APS.stock_disponible
        FROM logistica.AlmacenProductoStock APS WITH (UPDLOCK,HOLDLOCK)
        INNER JOIN logistica.Almacen A WITH (NOLOCK)
            ON A.almacen_id=APS.almacen_id AND A.uot_propietaria_id=@nUotId AND A.estado=1
        INNER JOIN logistica.AlmacenUOT AU WITH (NOLOCK)
            ON AU.almacen_id=A.almacen_id AND AU.uot_id=@nUotId
           AND AU.estado=1 AND AU.permite_salida=1
           AND (AU.fecha_hasta IS NULL OR AU.fecha_hasta>=SYSUTCDATETIME())
        WHERE APS.producto_id=@nProductoId AND APS.estado=1 AND APS.stock_disponible>0
          AND NOT EXISTS(SELECT 1 FROM logistica.TransferenciaSuministroTecnico T WITH (NOLOCK)
                         WHERE T.salida_campo_id=@nSalidaId AND T.suministro_id=@nSuministroId
                           AND T.almacen_id=A.almacen_id)
        ORDER BY APS.stock_disponible DESC,A.almacen_id;
        IF @nAlmacenId IS NULL
            THROW 51067,N'No hay stock comercial suficiente para completar la solicitud.',1;
        SET @nTomar=CASE WHEN @nDisponible>=@nRestante THEN @nRestante ELSE @nDisponible END;

        INSERT INTO logistica.MovimientoInventario
            (almacen_id,uot_id,tipo_movimiento,naturaleza,documento_referencia,
             clave_idempotencia,usuario_id,observacion,estado)
        VALUES(@nAlmacenId,@nUotId,'USO_TECNICO','S',CONCAT(N'Salida E2 ',@nSalidaId),
               NEWID(),@nUsuarioId,N'Traslado autorizado a inventario técnico.',1);
        SET @nMovimientoId=CONVERT(BIGINT,SCOPE_IDENTITY());
        INSERT INTO logistica.DetalleMovimientoInventario
            (movimiento_inventario_id,producto_id,cantidad,costo_unitario,moneda,lote,fecha_vencimiento)
        VALUES(@nMovimientoId,@nProductoId,@nTomar,NULL,NULL,NULL,NULL);
        UPDATE logistica.AlmacenProductoStock
           SET stock_actual=stock_actual-@nTomar,fecha_actualizacion=SYSUTCDATETIME()
         WHERE almacen_id=@nAlmacenId AND producto_id=@nProductoId AND estado=1
           AND stock_disponible>=@nTomar;
        IF @@ROWCOUNT<>1
            THROW 51067,N'El stock comercial cambió durante la aprobación.',1;
        INSERT INTO logistica.TransferenciaSuministroTecnico
            (salida_campo_id,uot_id,suministro_id,producto_id,almacen_id,
             movimiento_inventario_id,cantidad,usuario_id)
        VALUES(@nSalidaId,@nUotId,@nSuministroId,@nProductoId,@nAlmacenId,
               @nMovimientoId,@nTomar,@nUsuarioId);
        SET @nRestante=@nRestante-@nTomar;
    END;
    INSERT INTO logistica.SuministroMovimiento
        (suministro_id,uot_id,recurso_programado_id,tipo_movimiento,cantidad,fecha_hora,
         usuario_id,documento_referencia,observacion,estado)
    VALUES(@nSuministroId,@nUotId,NULL,'TRANSFERENCIA_ENTRADA',@nCantidad,SYSUTCDATETIME(),
           @nUsuarioId,CONCAT(N'Salida E2 ',@nSalidaId),N'Ingreso desde stock comercial.',1);
    SET @nMovimientoSuministroId=CONVERT(BIGINT,SCOPE_IDENTITY());
    UPDATE logistica.TransferenciaSuministroTecnico
       SET suministro_movimiento_id=@nMovimientoSuministroId
     WHERE salida_campo_id=@nSalidaId AND suministro_id=@nSuministroId;
    SELECT @bResultado=1,@cMensaje=N'Producto transferido a suministros.';
END;
GO
