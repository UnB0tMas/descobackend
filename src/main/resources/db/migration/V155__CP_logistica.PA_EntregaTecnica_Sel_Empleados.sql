IF OBJECT_ID(N'[logistica].[PA_EntregaTecnica_Sel_Empleados]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_EntregaTecnica_Sel_Empleados];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_EntregaTecnica_Sel_Empleados
' Descripción             : Consulta los empleados vinculados a las entregas técnicas.
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
    EXEC [logistica].[PA_EntregaTecnica_Sel_Empleados]
        @nUsuarioId = 0,
        @nUotId = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE logistica.PA_EntregaTecnica_Sel_Empleados
 @nUsuarioId BIGINT,@nUotId BIGINT,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @bResultado=0,@cMensaje=N'No se pudieron consultar los empleados.',@cCodigoRespuesta='EMPLEADOS_NO_LISTADOS',@nHttpRespuesta=400;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'VENTAS_ENTREGA_TECNICA')=0
 BEGIN SET @cMensaje=N'No tiene permiso para registrar entregas técnicas.'; SET @cCodigoRespuesta='NO_AUTORIZADO'; SET @nHttpRespuesta=403; RETURN 1; END;
 SELECT E.empleado_id empleadoId,COALESCE(EU.codigo_empleado,E.codigo_empleado) codigoEmpleado,
        LTRIM(RTRIM(CONCAT(P.nombres,N' ',P.apellido_paterno,N' ',COALESCE(P.apellido_materno,N'')))) empleado
 FROM org.Empleado E
 JOIN org.Persona P ON P.persona_id=E.empleado_id AND P.estado=1
 JOIN org.EmpleadoUOT EU ON EU.empleado_id=E.empleado_id AND EU.uot_id=@nUotId AND EU.estado=1
   AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME()) AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
 WHERE E.estado=1 AND (E.fecha_cese IS NULL OR E.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()))
 ORDER BY empleado;
 SELECT @bResultado=1,@cMensaje=N'Empleados consultados.',@cCodigoRespuesta='EMPLEADOS_LISTADOS',@nHttpRespuesta=200;
 RETURN 0;
END;
GO
