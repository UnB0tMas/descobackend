IF OBJECT_ID(N'[sanidad].[PA_TratamientoFitosanitario_Ins_Registro]') IS NOT NULL
    DROP PROCEDURE [sanidad].[PA_TratamientoFitosanitario_Ins_Registro];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : sanidad.PA_TratamientoFitosanitario_Ins_Registro
' Descripción            : Registra tratamientos fitosanitarios.
' Aplicativo / Módulo    : DESCO / Sanidad
*******************************************************************************************************/
CREATE   PROCEDURE [sanidad].[PA_TratamientoFitosanitario_Ins_Registro]
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
       @Utilizada DECIMAL(19,3)=TRY_CONVERT(DECIMAL(19,3),JSON_VALUE(@cJson,'$.tratamiento.cantidadUtilizada')),
       @Salida BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.tratamiento.salidaCampoId')),
       @SolicitudRecurso BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.tratamiento.solicitudRecursoId')),
       @UnidadConsumo VARCHAR(20)=JSON_VALUE(@cJson,'$.tratamiento.unidadUtilizada');
    IF @Salida IS NOT NULL AND (@Programa IS NOT NULL OR @SolicitudRecurso IS NULL
       OR @nVisita IS NULL OR @Utilizada IS NULL OR @Utilizada<=0)
    BEGIN SET @cMensaje=N'Seleccione un insumo entregado para esta salida.'; GOTO Fallar; END;
    IF @Salida IS NULL AND @SolicitudRecurso IS NOT NULL
    BEGIN SET @cMensaje=N'Indique la salida del recurso.'; GOTO Fallar; END;
    IF @Salida IS NULL AND ((@Programa IS NULL AND @Utilizada IS NOT NULL) OR (@Programa IS NOT NULL AND (@Utilizada IS NULL OR @Utilizada<=0)))
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
    -- Una visita E2 general no se puede usar como tratamiento libre o programado histórico.
    IF @Salida IS NOT NULL OR (@nVisita IS NOT NULL AND EXISTS(
        SELECT 1 FROM campo.SalidaVisitaE2 SV
        JOIN campo.SalidaDestinoE2 D ON D.destino_id=SV.destino_id
        JOIN campo.SalidaE2 E ON E.salida_campo_id=D.salida_campo_id
        WHERE SV.visita_tecnica_id=@nVisita AND E.convenio_id IS NULL))
    BEGIN
        IF @Salida IS NULL OR seg.FN_TecnicoPuedeActuarPredio(
            @nSesion,@nUsuario,@nPredioCaso,@Salida,@nVisita,'SANIDAD_CREAR')<>1
        BEGIN SET @cMensaje=N'No tiene autorización para trabajar en este predio.'; GOTO Fallar; END;
    END;
    -- La actuación ordinaria no puede omitir el contexto E2; las programaciones históricas conservan su contrato.
    IF @nPredioCaso IS NOT NULL AND @Salida IS NULL AND @Programa IS NULL
       AND seg.FN_TecnicoPuedeActuarPredio(@nSesion,@nUsuario,@nPredioCaso,NULL,NULL,'SANIDAD_CREAR')<>1
    BEGIN SET @cMensaje=N'Seleccione una salida y visita autorizadas.'; GOTO Fallar; END;
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
        IF @Salida IS NOT NULL
        BEGIN
          DECLARE @ClaveSalida UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia'));
          EXEC logistica.PA_SalidaConsumoTecnico_Registrar
              @nSesion,@nUsuario,@Salida,@nVisita,@nPredioCaso,@SolicitudRecurso,
              @nTratamientoId,@Utilizada,@UnidadConsumo,@ClaveSalida;
        END;
        ELSE IF @Programa IS NOT NULL
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
