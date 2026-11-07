-- DESCO / 2026-11-06 / AL-03: consumo de productos entregados vinculado al tratamiento.
-- El retiro físico ya ocurrió al entregar; se liquida la cantidad sin otro movimiento de salida.
-- Tratamiento, consumo e historial se confirman o revierten juntos. No se convierten dosis en cantidades.
-- Ejemplo: entregar 10, aplicar 3, devolver 7 conserva un único consumo físico de 3.
IF OBJECT_ID(N'logistica.UsoProductoTecnico',N'U') IS NULL
CREATE TABLE logistica.UsoProductoTecnico(
 tipo_origen VARCHAR(16) NOT NULL,registro_id BIGINT NOT NULL,
 programacion_producto_id BIGINT NOT NULL REFERENCES logistica.ProgramacionProducto(programacion_producto_id),
 evento_id BIGINT NOT NULL REFERENCES logistica.ProgramacionProductoEvento(programacion_producto_evento_id),
 cantidad DECIMAL(19,3) NOT NULL CHECK(cantidad>0),
 CONSTRAINT PK_UsoProductoTecnico PRIMARY KEY(tipo_origen,registro_id),
 CONSTRAINT UQ_UsoProductoTecnico_Evento UNIQUE(evento_id));
GO
CREATE OR ALTER PROCEDURE logistica.PA_ConsumoTecnico_Registrar
 @Sesion BIGINT,@Usuario BIGINT,@Responsable BIGINT,@Programa BIGINT,@Cantidad DECIMAL(19,3),
 @Origen VARCHAR(16),@Registro BIGINT,@Clave UNIQUEIDENTIFIER
AS
BEGIN
 SET NOCOUNT ON;
 IF @@TRANCOUNT=0 THROW 51103,N'El consumo debe registrarse junto con el tratamiento.',1;
 IF @Cantidad IS NULL OR @Cantidad<=0 OR @Clave IS NULL THROW 51103,N'Indique una cantidad utilizada válida.',1;
 DECLARE @Uot BIGINT,@Empleado BIGINT,@Pendiente DECIMAL(19,3),@Estado VARCHAR(20),@Actor BIGINT;
 SELECT @Uot=uot_id,@Empleado=empleado_id,@Estado=estado_proceso,
  @Pendiente=cantidad_entregada-cantidad_devuelta-cantidad_consumida
 FROM logistica.ProgramacionProducto WITH(UPDLOCK,HOLDLOCK) WHERE programacion_producto_id=@Programa;
 SELECT @Actor=persona_id FROM seg.Usuario WHERE usuario_id=@Usuario AND estado=1;
 IF NOT EXISTS(SELECT 1 FROM seg.SesionUsuario WHERE sesion_usuario_id=@Sesion AND usuario_id=@Usuario AND estado=1
  AND fecha_revocacion IS NULL AND modo_uot='ESPECIFICA' AND uot_contexto_id=@Uot)
  OR seg.FN_Usuario_TienePermisoUOT(@Usuario,@Uot,'SANIDAD_CREAR')<>1
  OR @Empleado<>@Responsable OR (@Responsable<>@Actor AND seg.FN_Usuario_TienePermisoUOT(@Usuario,@Uot,'ALMACENES_MOVIMIENTO')<>1)
  THROW 51103,N'El producto entregado no corresponde al responsable o a la UOT seleccionada.',1;
 IF EXISTS(SELECT 1 FROM logistica.UsoProductoTecnico WHERE tipo_origen=@Origen AND registro_id=@Registro)
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM logistica.UsoProductoTecnico WHERE tipo_origen=@Origen AND registro_id=@Registro AND programacion_producto_id=@Programa AND cantidad=@Cantidad)
   THROW 51103,N'La solicitud ya tiene otro consumo registrado.',1;
  RETURN;
 END;
 IF @Estado<>'ENTREGADA' OR @Cantidad>@Pendiente OR @Uot IS NULL
  THROW 51103,N'La cantidad supera el producto entregado pendiente de uso.',1;
 UPDATE logistica.ProgramacionProducto SET cantidad_consumida=cantidad_consumida+@Cantidad,
  estado_proceso=CASE WHEN @Cantidad=@Pendiente THEN 'FINALIZADA' ELSE 'ENTREGADA' END WHERE programacion_producto_id=@Programa;
 INSERT logistica.ProgramacionProductoEvento(programacion_producto_id,tipo_evento,cantidad,usuario_id,clave_idempotencia,observacion)
 VALUES(@Programa,'CONSUMIR',@Cantidad,@Usuario,@Clave,CONCAT(N'Tratamiento ',@Origen,N' #',@Registro));
 DECLARE @Evento BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());
 INSERT logistica.UsoProductoTecnico VALUES(@Origen,@Registro,@Programa,@Evento,@Cantidad);
END;
GO

/******************************************************************************************************
' Nombre del PA           : sanidad.PA_TratamientoFitosanitario_Ins_Registro
' Descripción             : Registra tratamientos fitosanitarios.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Sanidad
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
        @nTratamientoId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [sanidad].[PA_TratamientoFitosanitario_Ins_Registro]
        @cJson = N'{}',
        @nTratamientoId = @nTratamientoId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nTratamientoId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE OR ALTER PROCEDURE [sanidad].[PA_TratamientoFitosanitario_Ins_Registro]
(
    @cJson NVARCHAR(MAX),
    @nTratamientoId BIGINT OUTPUT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS
BEGIN
    SET @cMensaje=NULL; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;
    /* Respuesta explícita; mensajes públicos aprobados. */
    SET NOCOUNT ON;
    DECLARE @__DbTranEntrada INT = @@TRANCOUNT,
            @__DbTranAbierta BIT = 0,
            @__DbSavepoint VARCHAR(32) = REPLACE(CONVERT(VARCHAR(36),NEWID()),'-',''),
            @__DbMensaje NVARCHAR(300),
            @__DbError BIT = 0;
    SET @bResultado = 0;
    SET ANSI_NULLS ON;
    SET ANSI_PADDING ON;
    SET ANSI_WARNINGS ON;
    SET ARITHABORT ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET NUMERIC_ROUNDABORT OFF;
    BEGIN TRY
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE
        @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,
        @gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
        @nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),
        @bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),
        @nCaso BIGINT,@nVisita BIGINT,@nResp BIGINT,@dFecha DATETIME2(0),@cTrat NVARCHAR(300),
        @cProd NVARCHAR(160),@nDosis DECIMAL(12,4),@cUnidad VARCHAR(30),@cObs NVARCHAR(400),
        @cEstado VARCHAR(20),@nPredioCaso BIGINT,@nPredioVisita BIGINT,@dInicioVisita DATETIME2(0),
        @cPost NVARCHAR(MAX),@cIdent NVARCHAR(200),@nAud BIGINT,@nTrans BIGINT,
        @nAudCaso BIGINT,@nTransCaso BIGINT;
    SELECT
        @nTratamientoId=NULL,
        @bResultado=0,
        @cMensaje=N'No se pudo registrar el tratamiento.';
    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente]
        @cJson,'SANIDAD_CREAR','SANIDAD_TRATAMIENTO_CREAR',
        @nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,
        @gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@nOp OUTPUT,@bRep OUTPUT,
        @cEstadoOp OUTPUT,@cIdRes OUTPUT,@cCodRes OUTPUT,@bIni OUTPUT,@cMsg OUTPUT;
    IF @bIni=0 AND @bRep=0
    BEGIN
        SET @cMensaje=@cMsg;
        GOTO __DESCO_Salida;
    END;
    IF @bRep=1
    BEGIN
        IF @cEstadoOp='COMPLETADA'
        BEGIN
            SET @nTratamientoId=TRY_CONVERT(BIGINT,@cIdRes);
            SET @bResultado=1;
            SET @cMensaje=N'La solicitud ya fue procesada correctamente.';
        END
        ELSE
            SET @cMensaje=N'La solicitud ya se encuentra en proceso.';
        GOTO __DESCO_Salida;
    END;
    SELECT
        @nCaso=casoFitosanitarioId,
        @nVisita=visitaTecnicaId,
        @nResp=responsableEmpleadoId,
        @dFecha=fechaHora,
        @cTrat=NULLIF(LTRIM(RTRIM(tratamiento)),N''),
        @cProd=NULLIF(LTRIM(RTRIM(producto)),N''),
        @nDosis=dosis,
        @cUnidad=NULLIF(LTRIM(RTRIM(unidadDosis)),''),
        @cObs=NULLIF(LTRIM(RTRIM(observacion)),N'')
    FROM OPENJSON(@cJson,'$.tratamiento')
    WITH
    (
        casoFitosanitarioId BIGINT '$.casoFitosanitarioId',
        visitaTecnicaId BIGINT '$.visitaTecnicaId',
        responsableEmpleadoId BIGINT '$.responsableEmpleadoId',
        fechaHora DATETIME2(0) '$.fechaHora',
        tratamiento NVARCHAR(300) '$.tratamiento',
        producto NVARCHAR(160) '$.producto',
        dosis DECIMAL(12,4) '$.dosis',
        unidadDosis VARCHAR(30) '$.unidadDosis',
        observacion NVARCHAR(400) '$.observacion'
    );
    DECLARE @Programa BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.tratamiento.programacionProductoId')),
       @Utilizada DECIMAL(19,3)=TRY_CONVERT(DECIMAL(19,3),JSON_VALUE(@cJson,'$.tratamiento.cantidadUtilizada'));
    IF (@Programa IS NULL AND @Utilizada IS NOT NULL) OR (@Programa IS NOT NULL AND (@Utilizada IS NULL OR @Utilizada<=0))
    BEGIN SET @cMensaje=N'Seleccione el producto entregado y su cantidad utilizada.'; GOTO Fallar; END;
    IF @Programa IS NOT NULL
      SELECT @cProd=P.nombre FROM logistica.ProgramacionProducto PP JOIN logistica.Producto P ON P.producto_id=PP.producto_id WHERE PP.programacion_producto_id=@Programa;
    IF @nResp IS NULL SET @nResp=@nEmp;
    IF @dFecha IS NULL SET @dFecha=SYSUTCDATETIME();
    SELECT
        @cEstado=CF.estado_caso,
        @nPredioCaso=P.predio_id
    FROM [sanidad].[CasoFitosanitario] CF
    INNER JOIN [prod].[ParcelaCultivo] PC
        ON PC.parcela_cultivo_id=CF.parcela_cultivo_id
    INNER JOIN [prod].[Parcela] P
        ON P.parcela_id=PC.parcela_id
    WHERE CF.caso_fitosanitario_id=@nCaso
      AND CF.estado=1;
    IF @nPredioCaso IS NOT NULL AND prod.FN_Predio_VisibleSesion(@nSesion,@nUsuario,@nPredioCaso,'SANIDAD_CREAR')=0
    BEGIN SET @cMensaje=N'El caso no pertenece a la UOT de trabajo.'; GOTO Fallar; END;
    IF @cEstado IS NULL
    BEGIN
        SET @cMensaje=N'El caso sanitario seleccionado no está disponible.';
        GOTO Fallar;
    END;
    IF @cEstado IN('CONTROLADO','RECUPERADO','NO_RECUPERADO','CERRADO')
    BEGIN
        SET @cMensaje=N'El caso ya no admite nuevos tratamientos en su estado actual.';
        GOTO Fallar;
    END;
    IF @dFecha>SYSUTCDATETIME()
    BEGIN
        SET @cMensaje=N'La fecha del tratamiento no puede estar en el futuro.';
        GOTO Fallar;
    END;
    IF @cTrat IS NULL OR (@nDosis IS NOT NULL AND @nDosis<=0)
    BEGIN
        SET @cMensaje=N'Complete correctamente los datos del tratamiento.';
        GOTO Fallar;
    END;
    IF NOT EXISTS
    (
        SELECT 1
        FROM [org].[Empleado]
        WHERE empleado_id=@nResp
          AND estado=1
    )
    BEGIN
        SET @cMensaje=N'El responsable seleccionado no está disponible.';
        GOTO Fallar;
    END;
    IF @nVisita IS NOT NULL
    BEGIN
        SELECT
            @nPredioVisita=predio_id,
            @dInicioVisita=fecha_hora_inicio
        FROM [campo].[VisitaTecnica]
        WHERE visita_tecnica_id=@nVisita
          AND estado=1
          AND estado_proceso='INICIADA';
        IF @nPredioVisita IS NULL
        BEGIN
            SET @cMensaje=N'La visita seleccionada debe encontrarse en curso.';
            GOTO Fallar;
        END;
        IF @nPredioVisita<>@nPredioCaso
        BEGIN
            SET @cMensaje=N'La visita seleccionada no corresponde al predio del caso sanitario.';
            GOTO Fallar;
        END;
        IF @dFecha<@dInicioVisita
        BEGIN
            SET @cMensaje=N'La fecha del tratamiento no corresponde al periodo de la visita.';
            GOTO Fallar;
        END;
    END;
    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
        INSERT [sanidad].[TratamientoFitosanitario]
        (
            caso_fitosanitario_id,visita_tecnica_id,responsable_empleado_id,fecha_hora,
            tratamiento,producto,dosis,unidad_dosis,observacion,estado
        )
        VALUES
        (
            @nCaso,@nVisita,@nResp,@dFecha,@cTrat,@cProd,@nDosis,@cUnidad,@cObs,1
        );
        SET @nTratamientoId=CONVERT(BIGINT,SCOPE_IDENTITY());
        IF @Programa IS NOT NULL
        BEGIN
          DECLARE @ClaveUso UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia'));
          EXEC logistica.PA_ConsumoTecnico_Registrar @nSesion,@nUsuario,@nResp,@Programa,@Utilizada,'SANIDAD',@nTratamientoId,@ClaveUso;
        END;

        SET @cIdent=CONVERT(NVARCHAR(200),@nTratamientoId);
        SELECT @cPost=
        (
            SELECT
                @nTratamientoId tratamientoId,
                @nCaso casoFitosanitarioId,
                @nVisita visitaTecnicaId,
                @nResp responsableEmpleadoId,
                @dFecha fechaHora,
                @cTrat tratamiento,
                @cProd producto,
                @nDosis dosis,
                @cUnidad unidadDosis
            FOR JSON PATH,WITHOUT_ARRAY_WRAPPER
        );
        EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio]
            @nUsuario,@nSesion,@nDisp,@nModulo,'CREAR','sanidad','TratamientoFitosanitario',
            @cIdent,NULL,@cPost,NULL,NULL,NULL,NULL,@cIp,@gCorr,@gSol,@cEnd,
            @nAud OUTPUT,@nTrans OUTPUT;
        IF @cEstado='DETECTADO'
        BEGIN
            UPDATE [sanidad].[CasoFitosanitario]
            SET estado_caso='EN_TRATAMIENTO'
            WHERE caso_fitosanitario_id=@nCaso;
            SET @cIdent=CONVERT(NVARCHAR(200),@nCaso);
            EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio]
                @nUsuario,@nSesion,@nDisp,@nModulo,'CAMBIAR_ESTADO','sanidad','CasoFitosanitario',
                @cIdent,NULL,NULL,N'Inicio de tratamiento.','estado_caso','DETECTADO','EN_TRATAMIENTO',
                @cIp,@gCorr,@gSol,@cEnd,@nAudCaso OUTPUT,@nTransCaso OUTPUT;
        END;
        /* Confirmar datos e idempotencia juntos. */
        SET @cIdent=CONVERT(NVARCHAR(200),@nTratamientoId);
        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
            @nOp,'COMPLETADA','sanidad','TratamientoFitosanitario',@cIdent,
            'TRATAMIENTO_CREADO',@bFin OUTPUT,@cMsgFin OUTPUT;
IF ISNULL(@bFin,0) = 0
    THROW 51003, N'DESCO_IDEMPOTENCIA_NO_CERRADA', 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;
        SET @bResultado=1;
        SET @cMensaje=N'Tratamiento registrado correctamente.';
        GOTO __DESCO_Salida;
    END TRY
    BEGIN CATCH
SET @bResultado = 0;
        IF XACT_STATE()<>0 BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
        SET @cMensaje=N'No se pudo registrar el tratamiento. Intente nuevamente.';
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'sanidad.PA_TratamientoFitosanitario_Ins_Registro',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;
Fallar:
    IF @nOp IS NOT NULL AND @bResultado=0
        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
            @nOp,'FALLIDA',NULL,NULL,NULL,'NO_PROCESADO',@bFin OUTPUT,@cMsgFin OUTPUT;
    END TRY
    BEGIN CATCH
        SET @__DbError = 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'sanidad.PA_TratamientoFitosanitario_Ins_Registro',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
    END CATCH;
__DESCO_Salida:
BEGIN TRY
IF @__DbTranAbierta = 1
BEGIN
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
IF ISNULL(@bResultado,0) = 1 OR NULLIF(@cMensaje,N'') IS NULL SET @cMensaje = N'La operación no se completó y sus cambios fueron revertidos.';
SET @bResultado = 0;
END;
    IF @bResultado = 0 AND @nOp IS NOT NULL AND XACT_STATE() <> -1
    BEGIN
        IF ISNULL(@bRep,0) = 0
        BEGIN
        BEGIN TRY
            EXEC [auditoria].[PA_OperacionIdempotente_Upd_MensajeFallido]
                 @nOperacionIdempotenteId = @nOp, @cMensajeResultado = @cMensaje;
        END TRY
        BEGIN CATCH
            -- No sustituir el motivo funcional por un fallo de registro secundario.
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'sanidad.PA_TratamientoFitosanitario_Ins_Registro',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
        END CATCH;
        END
        ELSE
        BEGIN
            SELECT @cMensaje = COALESCE(mensaje_resultado,
                CASE WHEN estado_operacion = 'FALLIDA'
                     THEN N'La solicitud anterior no se completó. Corrija los datos y envíe una nueva solicitud.'
                     ELSE N'La solicitud todavía se está procesando. Consulte el resultado antes de repetirla.' END)
            FROM [auditoria].[OperacionIdempotente]
            WHERE operacion_idempotente_id = @nOp;
        END;
    END;
IF @bResultado = 0
    SELECT @nTratamientoId = NULL;
END TRY
BEGIN CATCH
        SET @__DbError = 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'sanidad.PA_TratamientoFitosanitario_Ins_Registro',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bResultado,0) = 1
BEGIN
SET @bResultado = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'sanidad.PA_TratamientoFitosanitario_Ins_Registro',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
CREATE OR ALTER PROCEDURE prod.PA_GP_Tratamiento_Ins_Incidencia
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT,
 @Incidencia BIGINT,@Tratamiento INT,@Descripcion NVARCHAR(2000),@FechaFinPrevista DATETIME2(0)=NULL,
 @Solicitud UNIQUEIDENTIFIER,@Programacion BIGINT=NULL,@Utilizada DECIMAL(19,3)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'SANIDAD_CREAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF @Solicitud IS NULL OR LEN(TRIM(COALESCE(@Descripcion,N'')))<3 THROW 51103,N'Explique la actuación.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPActividad A
 JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.estado=1
 JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
 WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot AND A.estado=1 AND A.estado_proceso='ACTIVA')
 THROW 51102,N'Actividad no disponible.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPIncidencia I
 JOIN prod.GPProblemaTratamiento R ON R.problema_id=I.problema_id AND R.tratamiento_id=@Tratamiento
 JOIN prod.GPTratamiento T ON T.tratamiento_id=R.tratamiento_id AND T.estado=1
 WHERE I.incidencia_id=@Incidencia AND I.actividad_id=@Actividad AND I.estado_seguimiento='ABIERTA')
 THROW 51103,N'La incidencia no está abierta o el tratamiento no corresponde a la enfermedad.',1;
 IF @FechaFinPrevista IS NOT NULL AND @FechaFinPrevista<SYSUTCDATETIME()
 THROW 51103,N'La fecha final prevista debe ser futura.',1;
 BEGIN TRAN;
 BEGIN TRY
  DECLARE @Id BIGINT;
  SELECT @Id=evento_id FROM prod.GPEvento WITH(UPDLOCK,HOLDLOCK) WHERE solicitud_id=@Solicitud;
  IF @Id IS NULL
  BEGIN
   DECLARE @Bloqueo BIGINT;
   SELECT @Bloqueo=incidencia_id FROM prod.GPIncidencia WITH(UPDLOCK,HOLDLOCK) WHERE incidencia_id=@Incidencia AND estado_seguimiento='ABIERTA';
   IF @Bloqueo IS NULL THROW 51103,N'La incidencia fue cerrada.',1;
   INSERT prod.GPEvento(actividad_id,tipo,problema_id,tratamiento_id,respuesta_a_id,observacion,fecha_hecho,
      usuario_creacion_id,solicitud_id)
   SELECT @Actividad,'TRATAMIENTO',problema_id,@Tratamiento,@Incidencia,TRIM(@Descripcion),SYSUTCDATETIME(),@Usuario,@Solicitud
   FROM prod.GPIncidencia WHERE incidencia_id=@Incidencia;
   SET @Id=CONVERT(BIGINT,SCOPE_IDENTITY());
   INSERT prod.GPIncidenciaTratamiento(evento_id,incidencia_id,tratamiento_id,fecha_fin_prevista)
   VALUES(@Id,@Incidencia,@Tratamiento,@FechaFinPrevista);
  END
  ELSE IF NOT EXISTS(SELECT 1 FROM prod.GPIncidenciaTratamiento WHERE evento_id=@Id AND incidencia_id=@Incidencia)
   THROW 51103,N'La solicitud corresponde a otra actuación.',1;
  IF @Programacion IS NOT NULL
  BEGIN
    DECLARE @SesionId BIGINT,@Empleado BIGINT;
    SELECT @SesionId=sesion_usuario_id FROM seg.SesionUsuario WHERE sesion_publica_id=@Sesion AND usuario_id=@Usuario;
    SELECT @Empleado=persona_id FROM seg.Usuario WHERE usuario_id=@Usuario;
    EXEC logistica.PA_ConsumoTecnico_Registrar @SesionId,@Usuario,@Empleado,@Programacion,@Utilizada,'GP',@Id,@Solicitud;
  END
  ELSE IF @Utilizada IS NOT NULL OR EXISTS(SELECT 1 FROM logistica.UsoProductoTecnico WHERE tipo_origen='GP' AND registro_id=@Id) THROW 51103,N'Seleccione el producto entregado registrado en la solicitud.',1;
  COMMIT; SELECT @Id AS id;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
END;

GO
