IF OBJECT_ID(N'[prod].[PA_Predio_Ins_Registro]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_Predio_Ins_Registro];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_Predio_Ins_Registro
' Descripción            : Registra predios.
' Aplicativo / Módulo    : DESCO / Producción
*******************************************************************************************************/
CREATE   PROCEDURE [prod].[PA_Predio_Ins_Registro]
(
    @cJson NVARCHAR(MAX), @nPredioId BIGINT OUTPUT, @bResultado BIT OUTPUT, @cMensaje NVARCHAR(300) OUTPUT,
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
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
            @nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),
            @cCodigo VARCHAR(40),@nCodigoConsecutivo BIGINT,@cNombre NVARCHAR(150),@dRegistro DATE,@cDistrito CHAR(6),@nCP BIGINT,@cRef NVARCHAR(300),@nLat DECIMAL(9,6),@nLon DECIMAL(9,6),@nAlt DECIMAL(8,2),@nUbicacion BIGINT,@bUbi BIT,@cMsgUbi NVARCHAR(300),
            @nArea DECIMAL(10,4),@nAreaCult DECIMAL(10,4),@cRiego VARCHAR(30),@cFuente NVARCHAR(150),@cInfra NVARCHAR(300),@cObs NVARCHAR(500),@dVig DATE,@jTit NVARCHAR(MAX),
            @cPosterior NVARCHAR(MAX),@cIdent NVARCHAR(200),@nAud BIGINT,@nTrans BIGINT;
    SELECT @nPredioId=NULL,@bResultado=0,@cMensaje=N'No se pudo registrar el predio.';
    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente] @cJson,'PREDIOS_CREAR','PREDIO_CREAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@nOp OUTPUT,@bRep OUTPUT,@cEstadoOp OUTPUT,@cIdRes OUTPUT,@cCodRes OUTPUT,@bIni OUTPUT,@cMsg OUTPUT;
    IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    IF @bRep=1 BEGIN IF @cEstadoOp='COMPLETADA' BEGIN SET @nPredioId=TRY_CONVERT(BIGINT,@cIdRes);
 SET @bResultado=1;
 SET @cMensaje=N'La solicitud ya fue procesada correctamente.';
 END ELSE SET @cMensaje=N'La solicitud ya se encuentra en proceso.';
 GOTO __DESCO_Salida;
 END;

    SELECT @cNombre=NULLIF(LTRIM(RTRIM(nombre)),N''),@dRegistro=fechaRegistro FROM OPENJSON(@cJson,'$.predio') WITH (nombre NVARCHAR(150) '$.nombre',fechaRegistro DATE '$.fechaRegistro');
    SELECT @cDistrito=NULLIF(LTRIM(RTRIM(distritoCodigo)),''),@nCP=centroPobladoId,@cRef=NULLIF(LTRIM(RTRIM(referencia)),N''),@nLat=latitud,@nLon=longitud,@nAlt=altitudM FROM OPENJSON(@cJson,'$.ubicacion') WITH (distritoCodigo CHAR(6) '$.distritoCodigo',centroPobladoId BIGINT '$.centroPobladoId',referencia NVARCHAR(300) '$.referencia',latitud DECIMAL(9,6) '$.latitud',longitud DECIMAL(9,6) '$.longitud',altitudM DECIMAL(8,2) '$.altitudM');
    SELECT @nArea=areaTotalHa,@nAreaCult=areaCultivableHa,@cRiego=NULLIF(LTRIM(RTRIM(tipoRiego)),''),@cFuente=NULLIF(LTRIM(RTRIM(fuenteAgua)),N''),@cInfra=NULLIF(LTRIM(RTRIM(infraestructura)),N''),@cObs=NULLIF(LTRIM(RTRIM(observacion)),N''),@dVig=fechaDesde FROM OPENJSON(@cJson,'$.caracteristicas') WITH (areaTotalHa DECIMAL(10,4) '$.areaTotalHa',areaCultivableHa DECIMAL(10,4) '$.areaCultivableHa',tipoRiego VARCHAR(30) '$.tipoRiego',fuenteAgua NVARCHAR(150) '$.fuenteAgua',infraestructura NVARCHAR(300) '$.infraestructura',observacion NVARCHAR(500) '$.observacion',fechaDesde DATE '$.fechaDesde');
    SET @jTit=JSON_QUERY(@cJson,'$.titulares');
 IF @dRegistro IS NULL SET @dRegistro=CONVERT(DATE,SYSUTCDATETIME());
 IF @dVig IS NULL SET @dVig=@dRegistro;
    IF @cNombre IS NULL OR @cDistrito IS NULL OR @nArea IS NULL OR @nArea<=0 BEGIN SET @cMensaje=N'Complete los datos obligatorios del predio.';
 GOTO Fallar;
 END;
    IF @nAreaCult IS NOT NULL AND (@nAreaCult<0 OR @nAreaCult>@nArea) BEGIN SET @cMensaje=N'El área cultivable no puede superar el área total.';
 GOTO Fallar;
 END;
    IF @jTit IS NULL OR NOT EXISTS(SELECT 1 FROM OPENJSON(@jTit)) BEGIN SET @cMensaje=N'Agregue al menos un titular del predio.';
 GOTO Fallar;
 END;
    IF EXISTS(SELECT 1 FROM OPENJSON(@jTit) WITH (personaId BIGINT '$.personaId',socioId BIGINT '$.socioId',tipoTitularidad VARCHAR(20) '$.tipoTitularidad',porcentaje DECIMAL(5,2) '$.porcentaje') T
 LEFT JOIN org.Persona P ON P.persona_id=COALESCE(T.personaId,T.socioId)
 LEFT JOIN prod.TipoTitularidadCatalogo C ON C.codigo=UPPER(T.tipoTitularidad) AND C.estado=1
 WHERE P.persona_id IS NULL OR P.estado=0 OR C.codigo IS NULL OR T.porcentaje IS NULL OR T.porcentaje<=0 OR T.porcentaje>100) BEGIN SET @cMensaje=N'Revise la información de titularidad.';
 GOTO Fallar;
 END;
    IF (SELECT SUM(ISNULL(porcentaje,0)) FROM OPENJSON(@jTit) WITH (porcentaje DECIMAL(5,2) '$.porcentaje'))>100 BEGIN SET @cMensaje=N'La suma de porcentajes de titularidad no puede superar el 100%.';
 GOTO Fallar;
 END;
    IF EXISTS(SELECT COALESCE(personaId,socioId) FROM OPENJSON(@jTit) WITH (personaId BIGINT '$.personaId',socioId BIGINT '$.socioId') GROUP BY COALESCE(personaId,socioId) HAVING COUNT(*)>1) BEGIN SET @cMensaje=N'No repita un mismo titular en el predio.';
 GOTO Fallar;
 END;

    DECLARE @nUotCreacion BIGINT = TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId'));
    IF @nUotCreacion IS NULL
      SELECT TOP(1) @nUotCreacion=EU.uot_id
      FROM org.EmpleadoUOT EU WHERE EU.empleado_id=@nEmp AND EU.estado=1
        AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
        AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
        AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,EU.uot_id,'PREDIOS_CREAR')=1
      ORDER BY EU.es_principal DESC,EU.uot_id;
    IF @nUotCreacion IS NULL OR seg.FN_Usuario_TienePermisoUOT(@nUsuario,@nUotCreacion,'PREDIOS_CREAR')<>1
    BEGIN SET @cMensaje=N'Seleccione una unidad territorial autorizada.'; GOTO Fallar; END;

    BEGIN TRY
      BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
      EXEC [geo].[PA_Ubicacion_Ins_Interna] @cDistrito,@nCP,@cRef,@nLat,@nLon,@nAlt,@nUbicacion OUTPUT,@bUbi OUTPUT,@cMsgUbi OUTPUT;
      IF @bUbi=0 BEGIN BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
 SET @cMensaje=@cMsgUbi;
 GOTO Fallar;
 END;
      /* Código de predio generado por el sistema. */
      WHILE 1=1
      BEGIN
          SET @nCodigoConsecutivo = NEXT VALUE FOR [prod].[SQ_CodigoPredio];
          SET @cCodigo = 'PRE-' + RIGHT(REPLICATE('0',12) + CONVERT(VARCHAR(20),@nCodigoConsecutivo),12);
          IF NOT EXISTS(SELECT 1 FROM [prod].[Predio] WHERE codigo=@cCodigo) BREAK;
      END;

      INSERT [prod].[Predio](codigo,nombre,ubicacion_id,fecha_registro,uot_id) VALUES(@cCodigo,@cNombre,@nUbicacion,@dRegistro,@nUotCreacion);
 SET @nPredioId=CONVERT(BIGINT,SCOPE_IDENTITY());
      INSERT prod.PredioAmbito(predio_id,uot_id,usuario_creacion_id) VALUES(@nPredioId,@nUotCreacion,@nUsuario);
      INSERT [prod].[PredioVersion](predio_id,area_total_ha,area_cultivable_ha,tipo_riego,fuente_agua,infraestructura,observacion,fecha_desde,fecha_hasta)
      VALUES(@nPredioId,@nArea,@nAreaCult,@cRiego,@cFuente,@cInfra,@cObs,@dVig,NULL);
      INSERT [prod].[PredioTitularidad](predio_id,persona_id,socio_id,tipo_titularidad,porcentaje,fecha_desde,fecha_hasta,rol_titularidad)
      SELECT @nPredioId,COALESCE(X.personaId,X.socioId),S.socio_id,
        UPPER(X.tipoTitularidad),X.porcentaje,@dRegistro,NULL,
        CASE WHEN J.[key]='0' THEN 'PRINCIPAL' ELSE 'ADICIONAL' END
      FROM OPENJSON(@jTit) J
      CROSS APPLY OPENJSON(J.value) WITH (personaId BIGINT '$.personaId',socioId BIGINT '$.socioId',tipoTitularidad VARCHAR(20) '$.tipoTitularidad',porcentaje DECIMAL(5,2) '$.porcentaje') X
      LEFT JOIN org.Socio S ON S.socio_id=COALESCE(X.personaId,X.socioId) AND S.estado=1;
      INSERT prod.PredioIdentidad(persona_id,distrito_codigo,nombre_normalizado,predio_id)
      SELECT COALESCE(T.personaId,T.socioId),@cDistrito,UPPER(LTRIM(RTRIM(@cNombre))),@nPredioId
      FROM OPENJSON(@jTit) WITH(personaId BIGINT '$.personaId',socioId BIGINT '$.socioId') T
      WHERE NOT EXISTS(SELECT 1 FROM prod.PredioIdentidad I WITH(UPDLOCK,HOLDLOCK)
           WHERE I.persona_id=COALESCE(T.personaId,T.socioId) AND I.distrito_codigo=@cDistrito
             AND I.nombre_normalizado=UPPER(LTRIM(RTRIM(@cNombre))));
      SELECT @cPosterior=(SELECT PR.predio_id,PR.codigo,PR.nombre,PR.ubicacion_id,PR.fecha_registro,@nArea areaTotalHa,@nAreaCult areaCultivableHa,JSON_QUERY(@jTit) titulares FROM [prod].[Predio] PR WHERE PR.predio_id=@nPredioId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
      SET @cIdent=CONVERT(NVARCHAR(200),@nPredioId);
      EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio] @nUsuario,@nSesion,@nDisp,@nModulo,'CREAR','prod','Predio',@cIdent,NULL,@cPosterior,NULL,'estado',NULL,'1',@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
      /* Confirmar datos e idempotencia juntos. */
      EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOp,'COMPLETADA','prod','Predio',@cIdent,'PREDIO_CREADO',@bFin OUTPUT,@cMsgFin OUTPUT;
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
 SET @cMensaje=N'Predio registrado correctamente.';
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
 SET @cMensaje=N'No se pudo registrar el predio. Intente nuevamente.';
 
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'prod.PA_Predio_Ins_Registro',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;
Fallar:
    IF @nOp IS NOT NULL AND @bResultado=0 EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOp,'FALLIDA',NULL,NULL,NULL,'NO_PROCESADO',@bFin OUTPUT,@cMsgFin OUTPUT;

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
    @cProcedimiento = N'prod.PA_Predio_Ins_Registro',
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
    @cProcedimiento = N'prod.PA_Predio_Ins_Registro',
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
    SELECT @nPredioId = NULL;

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
    @cProcedimiento = N'prod.PA_Predio_Ins_Registro',
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
FROM config.FN_RespuestaUsuario(N'prod.PA_Predio_Ins_Registro',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
