/* DESCO / 2026-11-06 / Corrección R06 auditoría Recursos.
   Bloquea cambios de unidad y trazabilidad con existencias/reservas en cualquier almacén.
   No cambia datos ni checksums de migraciones aplicadas.
   Prueba: PUT producto con stock cambiando KG a UND debe responder 409.
*/
CREATE OR ALTER TRIGGER logistica.TR_Producto_TrazabilidadConStock
ON logistica.Producto AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF NOT (UPDATE(unidad_medida) OR UPDATE(requiere_lote) OR UPDATE(controla_vencimiento)) RETURN;
    IF EXISTS (
        SELECT 1 FROM inserted I INNER JOIN deleted D ON D.producto_id=I.producto_id
        WHERE (I.unidad_medida<>D.unidad_medida OR I.requiere_lote<>D.requiere_lote OR I.controla_vencimiento<>D.controla_vencimiento)
          AND EXISTS (SELECT 1 FROM logistica.AlmacenProductoStock S WITH(UPDLOCK,HOLDLOCK)
                      WHERE S.producto_id=I.producto_id AND (S.stock_actual>0 OR S.stock_reservado>0))
    ) THROW 51080,N'No puede cambiar la unidad, el control de lotes ni el vencimiento mientras exista stock o reservas.',1;
END;
GO
CREATE OR ALTER PROCEDURE logistica.PA_Producto_Upd_Registro
    @nUsuarioId BIGINT,
    @nUotId BIGINT,
    @nProductoId BIGINT,
    @cNombre NVARCHAR(180),
    @cDescripcion NVARCHAR(700) = NULL,
    @cUnidad VARCHAR(20),
    @cCategoria VARCHAR(40) = NULL,
    @bRequiereLote BIT,
    @bControlaVencimiento BIT,
    @bPermiteVenta BIT, @nPrecioVenta DECIMAL(19,4)=NULL, @cMonedaVenta CHAR(3)=NULL,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60) = NULL OUTPUT,
    @nHttpRespuesta SMALLINT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT
        @bResultado = 0,
        @cMensaje = N'No se pudo actualizar el producto.',
        @cCodigoRespuesta = 'PRODUCTO_NO_ACTUALIZADO',
        @nHttpRespuesta = 400;

    SELECT
        @cNombre = NULLIF(LTRIM(RTRIM(@cNombre)), N''),
        @cDescripcion = NULLIF(LTRIM(RTRIM(@cDescripcion)), N''),
        @cUnidad = UPPER(NULLIF(LTRIM(RTRIM(@cUnidad)), '')),
        @cCategoria = UPPER(NULLIF(LTRIM(RTRIM(@cCategoria)), ''));

    IF @nUsuarioId IS NULL OR @nUotId IS NULL OR @nProductoId IS NULL
       OR @cNombre IS NULL OR @cUnidad IS NULL
    BEGIN
        SET @cMensaje = N'Complete correctamente los datos del producto.';
        RETURN 1;
    END;

    IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId, @nUotId, 'PRODUCTOS_EDITAR') = 0
    BEGIN
        SELECT @cMensaje = N'No tiene permiso para editar productos en esta UOT.',
               @cCodigoRespuesta = 'NO_AUTORIZADO', @nHttpRespuesta = 403;
        RETURN 1;
    END;

    IF NOT EXISTS (SELECT 1 FROM logistica.Producto WHERE producto_id = @nProductoId AND estado = 1)
    BEGIN
        SELECT @cMensaje = N'El producto no está disponible.',
               @cCodigoRespuesta = 'PRODUCTO_NO_DISPONIBLE', @nHttpRespuesta = 404;
        RETURN 1;
    END;

    IF NOT EXISTS
    (
        SELECT 1 FROM config.CatalogoRecursoValor
        WHERE catalogo = 'UNIDAD_MEDIDA' AND codigo = @cUnidad AND estado = 1
    )
    BEGIN
        SET @cMensaje = N'La unidad de medida seleccionada no está disponible.';
        RETURN 1;
    END;

    IF @cCategoria IS NOT NULL AND NOT EXISTS
    (
        SELECT 1 FROM config.CatalogoRecursoValor
        WHERE catalogo = 'CATEGORIA_PRODUCTO' AND codigo = @cCategoria AND estado = 1
    )
    BEGIN
        SET @cMensaje = N'La categoría seleccionada no está disponible.';
        RETURN 1;
    END;


    IF @nPrecioVenta IS NOT NULL OR @cMonedaVenta IS NOT NULL
    BEGIN SET @cMensaje=N'Defina el precio de venta desde Almacen.'; RETURN 1; END;
    IF @bPermiteVenta=0 AND EXISTS (SELECT 1 FROM logistica.ProductoUOTPolitica WHERE producto_id=@nProductoId AND estado=1 AND permite_venta=1)
    BEGIN SET @cMensaje=N'Deshabilite primero los precios comerciales de las UOT afectadas.'; RETURN 1; END;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @bPermiteVenta=0
            UPDATE logistica.ProductoPrecio SET estado=0,fecha_hasta=COALESCE(fecha_hasta,SYSUTCDATETIME())
            WHERE producto_id=@nProductoId AND estado=1 AND fecha_hasta IS NULL;
        UPDATE logistica.Producto
           SET nombre = @cNombre,
               descripcion = @cDescripcion,
               unidad_medida = @cUnidad,
               categoria = @cCategoria,
               requiere_lote = @bRequiereLote,
               controla_vencimiento = @bControlaVencimiento,
               permite_venta = @bPermiteVenta
         WHERE producto_id = @nProductoId
           AND estado = 1;

        IF @@ROWCOUNT = 0
        BEGIN
            SELECT @cMensaje = N'El producto no está disponible.',
                   @cCodigoRespuesta = 'PRODUCTO_NO_DISPONIBLE', @nHttpRespuesta = 404;
            ROLLBACK TRANSACTION;
            RETURN 1;
        END;
        COMMIT TRANSACTION;

        SELECT @bResultado = 1,
               @cMensaje = N'Producto actualizado correctamente.',
               @cCodigoRespuesta = 'PRODUCTO_ACTUALIZADO',
               @nHttpRespuesta = 200;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        SELECT @cMensaje = CASE WHEN ERROR_NUMBER()=51080 THEN ERROR_MESSAGE() ELSE N'No se pudo actualizar el producto.' END,
               @cCodigoRespuesta = CASE WHEN ERROR_NUMBER()=51080 THEN 'PRODUCTO_CON_STOCK' ELSE 'PRODUCTO_NO_ACTUALIZADO' END,
               @nHttpRespuesta = CASE WHEN ERROR_NUMBER()=51080 THEN 409 ELSE 400 END;
        RETURN 1;
    END CATCH;
END;
GO
