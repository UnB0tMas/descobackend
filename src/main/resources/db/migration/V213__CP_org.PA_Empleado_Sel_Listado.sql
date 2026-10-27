IF OBJECT_ID(N'[org].[PA_Empleado_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_Empleado_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_Empleado_Sel_Listado
' Descripción             : Lista empleados.
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
    -- El JSON mostrado es ilustrativo y debe ajustarse al contrato del PA.
    DECLARE
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [org].[PA_Empleado_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [org].[PA_Empleado_Sel_Listado]
    @cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @bResultado=0; SET @cMensaje=N'No se pudieron consultar los empleados.'; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;
    BEGIN TRY
        DECLARE @nPagina INT,@nTamano INT,@nOffset BIGINT; EXEC seg.PA_Consulta_Sel_ResolverPaginacion @cJson,@nPagina OUTPUT,@nTamano OUTPUT,@nOffset OUTPUT;
        DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bCtx BIT,@cMsg NVARCHAR(300),@nUotSolicitada BIGINT,@nUot BIGINT,@bGeneral BIT,@bUot BIT,@cUotMsg NVARCHAR(300),@nArea BIGINT,@bActivo BIT;
        SELECT @nUotSolicitada=uotId,@nArea=areaId,@bActivo=activo FROM OPENJSON(@cJson,'$.filtros') WITH(uotId BIGINT '$.uotId',areaId BIGINT '$.areaId',activo BIT '$.activo');
        EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,'EMPLEADOS_LISTAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bCtx OUTPUT,@cMsg OUTPUT;
        IF @bCtx=0 BEGIN SET @cMensaje=@cMsg; GOTO Salida; END;
        EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuario,@nSesion,@nUotSolicitada,'EMPLEADOS_LISTAR',0,@nUot OUTPUT,@bGeneral OUTPUT,@bUot OUTPUT,@cUotMsg OUTPUT;
        IF @bUot=0 BEGIN SET @cMensaje=@cUotMsg; GOTO Salida; END;
        SELECT E.empleado_id empleadoId,EU.uot_id uotId,UO.codigo uotCodigo,UO.nombre uotNombre,EU.uot_id empresaId,UO.nombre empresa,COALESCE(EU.codigo_empleado,E.codigo_empleado) codigoEmpleado,
               COALESCE(EU.fecha_ingreso,E.fecha_ingreso) fechaIngreso,EU.fecha_cese fechaCese,EU.estado,
               P.tipo_documento tipoDocumento,P.numero_documento numeroDocumento,P.nombres,P.apellido_paterno apellidoPaterno,P.apellido_materno apellidoMaterno,P.telefono,P.correo,
               EA.area_id areaId,EA.area area,EA.cargo,US.usuario_id usuarioId,US.nombre_usuario nombreUsuario,US.estado_cuenta estadoCuenta,COUNT_BIG(*) OVER() totalRegistros
        FROM org.Empleado E
        JOIN org.Persona P ON P.persona_id=E.empleado_id
        JOIN org.EmpleadoUOT EU ON EU.empleado_id=E.empleado_id AND EU.estado=1 AND EU.fecha_hasta IS NULL 
        JOIN org.UOT UO ON UO.uot_id=EU.uot_id AND UO.estado=1
        OUTER APPLY(
            SELECT TOP(1) EA0.area_id,A0.nombre area,EA0.cargo
            FROM org.EmpleadoArea EA0
            JOIN org.Area A0 ON A0.area_id=EA0.area_id AND A0.uot_id=EU.uot_id
            WHERE EA0.empleado_id=E.empleado_id AND EA0.estado=1 AND EA0.fecha_hasta IS NULL
            ORDER BY EA0.fecha_desde DESC,EA0.empleado_area_id DESC
        ) EA
        LEFT JOIN seg.Usuario US ON US.persona_id=E.empleado_id
        WHERE (@nUot IS NULL OR EU.uot_id=@nUot)
          AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,EU.uot_id,'EMPLEADOS_LISTAR')=1
          AND (@nArea IS NULL OR EA.area_id=@nArea)
          AND (@bActivo IS NULL OR E.estado=@bActivo)
        ORDER BY UO.nombre,P.apellido_paterno,P.nombres,E.empleado_id OFFSET @nOffset ROWS FETCH NEXT @nTamano ROWS ONLY;
        SET @bResultado=1; SET @cMensaje=N'Empleados consultados.';
    END TRY BEGIN CATCH SET @bResultado=0; SET @cMensaje=N'No se pudieron consultar los empleados.'; END CATCH
Salida:
    SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido FROM config.FN_RespuestaUsuario(N'org.PA_Empleado_Sel_Listado',@bResultado,@cMensaje) R;
    RETURN CASE WHEN @bResultado=1 THEN 0 ELSE 1 END;
END;
GO
