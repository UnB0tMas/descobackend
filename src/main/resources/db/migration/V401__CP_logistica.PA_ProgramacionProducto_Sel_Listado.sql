IF OBJECT_ID(N'[logistica].[PA_ProgramacionProducto_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_ProgramacionProducto_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_ProgramacionProducto_Sel_Listado
' Descripción             : Consulta solicitudes de productos de una UOT.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Creación de listado de solicitudes técnicas.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Referencial: sustituir identificadores y valores por datos válidos.
    DECLARE @bResultado BIT,
            @cMensaje NVARCHAR(300);
    EXEC [logistica].[PA_ProgramacionProducto_Sel_Listado]
        @nUsuarioId = 0,
        @nUotId = 0,
        @cEstado = '',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE logistica.PA_ProgramacionProducto_Sel_Listado
 @nUsuarioId BIGINT,@nUotId BIGINT,@cEstado VARCHAR(20)=NULL,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @bResultado=0,@cMensaje=N'No se pudo consultar la programación.';
 SET @cEstado=UPPER(NULLIF(LTRIM(RTRIM(@cEstado)),''));
 IF @cEstado IS NOT NULL AND @cEstado NOT IN('PENDIENTE','APROBADA','ENTREGADA','FINALIZADA','RECHAZADA','CANCELADA')
 BEGIN SET @cMensaje=N'El estado solicitado no es válido.';RETURN;END;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'RECURSOS_LISTAR')=0
 BEGIN SET @cMensaje=N'No tiene permiso para consultar los recursos de esta UOT.';RETURN;END;
 SELECT R.programacion_producto_id programacionId,R.uot_id uotId,R.almacen_id almacenId,
 R.producto_id productoId,P.nombre productoNombre,R.empleado_id empleadoId,
 R.cantidad_programada cantidadProgramada,R.cantidad_entregada cantidadEntregada,
 R.cantidad_devuelta cantidadDevuelta,R.cantidad_consumida cantidadConsumida,
 R.cantidad_entregada-R.cantidad_devuelta-R.cantidad_consumida cantidadPendiente,
 R.estado_proceso estadoProceso,R.actividad,R.lugar_destino lugar,R.fecha_inicio fechaInicio,R.fecha_fin fechaFin,
 R.archivo_autorizacion_id archivoAutorizacionId,R.observacion
 FROM logistica.ProgramacionProducto R JOIN logistica.Producto P ON P.producto_id=R.producto_id
 WHERE R.uot_id=@nUotId AND (@cEstado IS NULL OR R.estado_proceso=@cEstado)
 ORDER BY R.fecha_creacion DESC,R.programacion_producto_id DESC;
 SELECT @bResultado=1,@cMensaje=N'Programación consultada correctamente.';
END;
GO
