IF OBJECT_ID(N'[org].[PA_Empleado_Sel_ListadoUOT]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_Empleado_Sel_ListadoUOT];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_Empleado_Sel_ListadoUOT
' Descripción             : Lista por UOT empleados.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Organización
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
        @cMensaje NVARCHAR(300);
    EXEC [org].[PA_Empleado_Sel_ListadoUOT]
        @nUsuarioId = 0,
        @nUotId = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE [org].[PA_Empleado_Sel_ListadoUOT]
    @nUsuarioId BIGINT,@nUotId BIGINT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @bResultado=0; SET @cMensaje=N'No se pudieron consultar los empleados.';
    IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'EMPLEADOS_LISTAR')=0 BEGIN SET @cMensaje=N'No tiene permiso para consultar esta UOT.'; RETURN 1; END;
    SELECT E.empleado_id empleadoId,EU.uot_id uotId,U.codigo uotCodigo,U.nombre uotNombre,E.codigo_empleado codigoEmpleado,P.tipo_documento tipoDocumento,P.numero_documento numeroDocumento,P.nombres,P.apellido_paterno apellidoPaterno,P.apellido_materno apellidoMaterno,E.estado
    FROM org.EmpleadoUOT EU JOIN org.Empleado E ON E.empleado_id=EU.empleado_id JOIN org.Persona P ON P.persona_id=E.empleado_id JOIN org.UOT U ON U.uot_id=EU.uot_id
    WHERE EU.uot_id=@nUotId AND EU.estado=1 AND EU.fecha_hasta IS NULL AND E.estado=1 ORDER BY P.apellido_paterno,P.nombres;
    SET @bResultado=1; SET @cMensaje=N'Empleados consultados.'; RETURN 0;
END;
GO
