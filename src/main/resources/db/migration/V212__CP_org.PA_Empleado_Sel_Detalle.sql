IF OBJECT_ID(N'[org].[PA_Empleado_Sel_Detalle]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_Empleado_Sel_Detalle];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_Empleado_Sel_Detalle
' Descripción             : Consulta el detalle de empleados.
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
    EXEC [org].[PA_Empleado_Sel_Detalle]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [org].[PA_Empleado_Sel_Detalle]
    @cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @bResultado=0; SET @cMensaje=N'No se pudo consultar el empleado.'; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;
    BEGIN TRY
        DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bCtx BIT,@cMsg NVARCHAR(300),@nId BIGINT,@nUotSolicitada BIGINT,@nUot BIGINT,@bGeneral BIT,@bUot BIT,@cUotMsg NVARCHAR(300);
        SELECT @nId=COALESCE(TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.empleado.empleadoId')),TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.empleadoId')),TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.empleadoId'))),@nUotSolicitada=TRY_CONVERT(BIGINT,COALESCE(JSON_VALUE(@cJson,'$.empleado.uotId'),JSON_VALUE(@cJson,'$.filtros.uotId'),JSON_VALUE(@cJson,'$.uotId')));
        EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,'EMPLEADOS_VER',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bCtx OUTPUT,@cMsg OUTPUT;
        IF @bCtx=0 BEGIN SET @cMensaje=@cMsg; GOTO Salida; END;
        EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuario,@nSesion,@nUotSolicitada,'EMPLEADOS_VER',1,@nUot OUTPUT,@bGeneral OUTPUT,@bUot OUTPUT,@cUotMsg OUTPUT;
        IF @bUot=0 BEGIN SET @cMensaje=@cUotMsg; GOTO Salida; END;
        IF NOT EXISTS(SELECT 1 FROM org.EmpleadoUOT WHERE empleado_id=@nId AND uot_id=@nUot AND estado=1 AND fecha_hasta IS NULL) BEGIN SET @cMensaje=N'El empleado no está disponible en esta UOT.'; GOTO Salida; END;
        SELECT E.empleado_id empleadoId,EU.uot_id uotId,UO.codigo uotCodigo,UO.nombre uotNombre,EU.uot_id empresaId,UO.nombre empresa,COALESCE(EU.codigo_empleado,E.codigo_empleado) codigoEmpleado,
               COALESCE(EU.fecha_ingreso,E.fecha_ingreso) fechaIngreso,EU.fecha_cese fechaCese,EU.estado,
               P.tipo_documento tipoDocumento,P.numero_documento numeroDocumento,P.nombres,P.apellido_paterno apellidoPaterno,P.apellido_materno apellidoMaterno,P.telefono,P.correo,P.fecha_nacimiento fechaNacimiento,
               UB.distrito_codigo distritoCodigo,D.nombre distritoNombre,UB.centro_poblado_id centroPobladoId,CP.nombre centroPobladoNombre,UB.referencia referencia,
               EA.area_id areaId,EA.area area,EA.cargo,
               US.usuario_id usuarioId,
               US.nombre_usuario nombreUsuario,
               US.estado_cuenta estadoCuenta,
               US.ultimo_acceso_correcto ultimoAccesoCorrecto,
               US.segundo_factor_habilitado segundoFactorHabilitado
        FROM org.Empleado E JOIN org.Persona P ON P.persona_id=E.empleado_id JOIN org.EmpleadoUOT EU ON EU.empleado_id=E.empleado_id AND EU.uot_id=@nUot AND EU.estado=1 AND EU.fecha_hasta IS NULL
        JOIN org.UOT UO ON UO.uot_id=EU.uot_id LEFT JOIN geo.Ubicacion UB ON UB.ubicacion_id=P.ubicacion_id LEFT JOIN geo.Distrito D ON D.distrito_codigo=UB.distrito_codigo LEFT JOIN geo.CentroPoblado CP ON CP.centro_poblado_id=UB.centro_poblado_id AND CP.distrito_codigo=UB.distrito_codigo OUTER APPLY(SELECT TOP(1) EA0.area_id,A0.nombre area,EA0.cargo FROM org.EmpleadoArea EA0 JOIN org.Area A0 ON A0.area_id=EA0.area_id AND A0.uot_id=@nUot WHERE EA0.empleado_id=E.empleado_id AND EA0.estado=1 AND EA0.fecha_hasta IS NULL ORDER BY EA0.fecha_desde DESC,EA0.empleado_area_id DESC) EA LEFT JOIN seg.Usuario US ON US.persona_id=E.empleado_id WHERE E.empleado_id=@nId;
        SELECT EA.empleado_area_id empleadoAreaId,EA.area_id areaId,A.nombre area,EA.cargo,EA.fecha_desde fechaDesde,EA.fecha_hasta fechaHasta,EA.estado FROM org.EmpleadoArea EA JOIN org.Area A ON A.area_id=EA.area_id AND A.uot_id=@nUot WHERE EA.empleado_id=@nId ORDER BY EA.fecha_desde DESC;
        ;WITH RolesEfectivos AS
        (
            SELECT
                R.rol_id rolId,
                R.codigo,
                R.nombre,
                UUR.fecha_desde fechaDesde,
                UUR.fecha_hasta fechaHasta,
                CAST(1 AS BIT) estado,
                1 prioridad
            FROM seg.Usuario U
            JOIN seg.UsuarioUOT UU
              ON UU.usuario_id=U.usuario_id
             AND UU.uot_id=@nUot
             AND UU.estado=1
             AND UU.fecha_desde<=SYSUTCDATETIME()
             AND (
                    UU.fecha_hasta IS NULL
                    OR UU.fecha_hasta>SYSUTCDATETIME()
                 )
            JOIN seg.UsuarioUOTRol UUR
              ON UUR.usuario_uot_id=UU.usuario_uot_id
             AND UUR.estado=1
             AND UUR.fecha_desde<=SYSUTCDATETIME()
             AND (
                    UUR.fecha_hasta IS NULL
                    OR UUR.fecha_hasta>SYSUTCDATETIME()
                 )
            JOIN seg.Rol R
              ON R.rol_id=UUR.rol_id
             AND R.estado=1
            WHERE U.persona_id=@nId
              AND U.estado=1
              AND U.estado_cuenta='ACTIVA'

            UNION ALL

            SELECT
                R.rol_id,
                R.codigo,
                R.nombre,
                UR.fecha_desde,
                UR.fecha_hasta,
                CAST(1 AS BIT),
                2
            FROM seg.Usuario U
            JOIN seg.UsuarioRol UR
              ON UR.usuario_id=U.usuario_id
             AND UR.estado=1
             AND UR.fecha_desde<=SYSUTCDATETIME()
             AND (
                    UR.fecha_hasta IS NULL
                    OR UR.fecha_hasta>SYSUTCDATETIME()
                 )
            JOIN seg.Rol R
              ON R.rol_id=UR.rol_id
             AND R.estado=1
             AND R.codigo='ADMINISTRADOR'
            WHERE U.persona_id=@nId
              AND U.estado=1
              AND U.estado_cuenta='ACTIVA'
        ),
        RolesUnicos AS
        (
            SELECT
                rolId,
                codigo,
                nombre,
                fechaDesde,
                fechaHasta,
                estado,
                ROW_NUMBER() OVER
                (
                    PARTITION BY rolId
                    ORDER BY prioridad,fechaDesde DESC
                ) fila
            FROM RolesEfectivos
        )
        SELECT
            rolId,
            codigo,
            nombre,
            fechaDesde,
            fechaHasta,
            estado
        FROM RolesUnicos
        WHERE fila=1
        ORDER BY nombre;
        SET @bResultado=1; SET @cMensaje=N'Empleado consultado.';
    END TRY BEGIN CATCH SET @bResultado=0; SET @cMensaje=N'No se pudo consultar el empleado.'; END CATCH
Salida:
    SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido FROM config.FN_RespuestaUsuario(N'org.PA_Empleado_Sel_Detalle',@bResultado,@cMensaje) R;
    RETURN CASE WHEN @bResultado=1 THEN 0 ELSE 1 END;
END;
GO
