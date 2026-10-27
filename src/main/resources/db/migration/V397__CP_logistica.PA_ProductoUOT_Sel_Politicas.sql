IF OBJECT_ID(N'[logistica].[PA_ProductoUOT_Sel_Politicas]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_ProductoUOT_Sel_Politicas];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_ProductoUOT_Sel_Politicas
' Descripción             : Consulta el catálogo común y stock agregado de los almacenes de la UOT.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Creación de consulta de productos y políticas UOT.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Referencial: sustituir identificadores y valores por datos válidos.
    DECLARE @bResultado BIT,
            @cMensaje NVARCHAR(300);
    EXEC [logistica].[PA_ProductoUOT_Sel_Politicas]
        @nUsuarioId = 0,
        @nUotId = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE logistica.PA_ProductoUOT_Sel_Politicas
 @nUsuarioId BIGINT,@nUotId BIGINT,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @bResultado=0,@cMensaje=N'No se pudo consultar el catálogo de la UOT.';
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'ALMACENES_LISTAR')=0
  AND seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'POS_OPERAR')=0
 BEGIN SET @cMensaje=N'No tiene permiso para consultar estos productos.';RETURN;END;
 SELECT P.producto_id productoId,P.codigo,P.nombre,P.unidad_medida unidadMedida,
  COALESCE(U.permite_venta,CONVERT(BIT,0)) permiteVenta,
  COALESCE(U.permite_uso_interno,CONVERT(BIT,0)) permiteUsoInterno,
  COALESCE(U.estado,CONVERT(BIT,0)) configurado,
  COALESCE(S.stockActual,CONVERT(DECIMAL(19,3),0)) stockActual,
  COALESCE(S.stockReservado,CONVERT(DECIMAL(19,3),0)) stockReservado
 FROM logistica.Producto P
 LEFT JOIN logistica.ProductoUOTPolitica U ON U.producto_id=P.producto_id AND U.uot_id=@nUotId
 OUTER APPLY (SELECT SUM(A.stock_actual) stockActual,SUM(A.stock_reservado) stockReservado
 FROM logistica.AlmacenProductoStock A JOIN logistica.Almacen W ON W.almacen_id=A.almacen_id
 WHERE W.uot_propietaria_id=@nUotId AND A.producto_id=P.producto_id) S
 WHERE P.estado=1 ORDER BY P.nombre;
 SELECT @bResultado=1,@cMensaje=N'Catálogo consultado correctamente.';
END;
GO
