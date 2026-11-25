IF OBJECT_ID(N'[logistica].[PA_ProgramacionProducto_Sel_Detalle]') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_ProgramacionProducto_Sel_Detalle];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : logistica.PA_ProgramacionProducto_Sel_Detalle
' Descripción            : Consulta datos y eventos de una solicitud autorizada.
' Aplicativo / Módulo    : DESCO / Logística
*******************************************************************************************************/
CREATE PROCEDURE logistica.PA_ProgramacionProducto_Sel_Detalle
 @nUsuarioId BIGINT,@nProgramacionId BIGINT,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @bResultado=0,@cMensaje=N'La solicitud no está disponible.';
 DECLARE @Uot BIGINT;
 SELECT @Uot=uot_id FROM logistica.ProgramacionProducto WHERE programacion_producto_id=@nProgramacionId;
 IF @Uot IS NULL OR seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@Uot,'RECURSOS_VER')=0
 BEGIN SET @cMensaje=N'La solicitud no está disponible para esta UOT.';RETURN;END;
 SELECT R.*,P.nombre productoNombre,A.nombre almacenNombre
 FROM logistica.ProgramacionProducto R JOIN logistica.Producto P ON P.producto_id=R.producto_id
 JOIN logistica.Almacen A ON A.almacen_id=R.almacen_id WHERE R.programacion_producto_id=@nProgramacionId;
 SELECT programacion_producto_evento_id eventoId,tipo_evento tipoEvento,cantidad,movimiento_inventario_id movimientoId,
 usuario_id usuarioId,observacion,fecha_hora fechaHora
 FROM logistica.ProgramacionProductoEvento WHERE programacion_producto_id=@nProgramacionId
 ORDER BY programacion_producto_evento_id;
 SELECT @bResultado=1,@cMensaje=N'Solicitud consultada correctamente.';
END;
GO
