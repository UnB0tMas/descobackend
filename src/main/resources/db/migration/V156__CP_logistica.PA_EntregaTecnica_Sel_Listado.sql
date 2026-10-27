IF OBJECT_ID(N'[logistica].[PA_EntregaTecnica_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_EntregaTecnica_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_EntregaTecnica_Sel_Listado
' Descripción             : Lista entrega técnica.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo: sustituir identificadores y valores por datos válidos.
    DECLARE
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [logistica].[PA_EntregaTecnica_Sel_Listado]
        @nUsuarioId = 0,
        @nUotId = 0,
        @nEmpleadoId = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE logistica.PA_EntregaTecnica_Sel_Listado
 @nUsuarioId BIGINT,@nUotId BIGINT,@nEmpleadoId BIGINT=NULL,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @bResultado=0,@cMensaje=N'No se pudieron consultar las entregas técnicas.',@cCodigoRespuesta='ENTREGAS_TECNICAS_NO_LISTADAS',@nHttpRespuesta=400;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'VENTAS_ENTREGA_TECNICA')=0
 BEGIN SET @cMensaje=N'No tiene permiso para consultar entregas técnicas.'; SET @cCodigoRespuesta='NO_AUTORIZADO'; SET @nHttpRespuesta=403; RETURN 1; END;
 SELECT ET.entrega_tecnica_id entregaTecnicaId,ET.uot_id uotId,U.nombre uotNombre,ET.almacen_id almacenId,A.nombre almacen,
        ET.empleado_id empleadoId,LTRIM(RTRIM(CONCAT(P.nombres,N' ',P.apellido_paterno,N' ',COALESCE(P.apellido_materno,N'')))) empleado,
        ET.fecha_hora fechaHora,ET.motivo,ET.observacion,ET.movimiento_inventario_id movimientoInventarioId,
        ET.usuario_entrega_id usuarioEntregaId,US.nombre_usuario usuarioEntrega
 FROM logistica.EntregaTecnica ET
 JOIN org.UOT U ON U.uot_id=ET.uot_id
 JOIN logistica.Almacen A ON A.almacen_id=ET.almacen_id
 JOIN org.Persona P ON P.persona_id=ET.empleado_id
 JOIN seg.Usuario US ON US.usuario_id=ET.usuario_entrega_id
 WHERE ET.uot_id=@nUotId AND ET.estado=1 AND (@nEmpleadoId IS NULL OR ET.empleado_id=@nEmpleadoId)
 ORDER BY ET.fecha_hora DESC,ET.entrega_tecnica_id DESC;
 SELECT @bResultado=1,@cMensaje=N'Entregas técnicas consultadas.',@cCodigoRespuesta='ENTREGAS_TECNICAS_LISTADAS',@nHttpRespuesta=200;
 RETURN 0;
END;
GO
