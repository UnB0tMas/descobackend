-- DESCO APAPPSS: indicadores de la campaña, SOLO LECTURA.
-- Única responsabilidad: consultar agregados de recepción; sin modificar pesajes, asignaciones ni estados.
CREATE OR ALTER PROCEDURE comercial.PA_CampaniaVentaProceso_Sel_Indicadores
    @cJson NVARCHAR(MAX),
    @cDatos NVARCHAR(MAX) OUTPUT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60) OUTPUT,
    @nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @cDatos=NULL, @bResultado=0, @cMensaje=N'No se pudieron consultar los indicadores.',
           @cCodigoRespuesta='CAMPANIA_INDICADORES_ERROR', @nHttpRespuesta=400;

    DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
            @desde DATE=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.filtros.fechaInicio'),23),
            @hasta DATE=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.filtros.fechaFin'),23),
            @variedad SMALLINT=TRY_CONVERT(SMALLINT,JSON_VALUE(@cJson,'$.filtros.variedadPaltaId')),
            @uot BIGINT, @usuario BIGINT, @sesion BIGINT, @dispositivo BIGINT, @empleado BIGINT,
            @modulo INT, @corr UNIQUEIDENTIFIER, @sol UNIQUEIDENTIFIER,
            @ip VARCHAR(64), @endpoint NVARCHAR(250), @acceso BIT, @mensajeAcceso NVARCHAR(300),
            @inicioUtc DATETIME2(0), @finUtc DATETIME2(0);
    BEGIN TRY
        SELECT @uot=C.uot_id FROM comercial.CampaniaVenta C
        WHERE C.campania_venta_id=@camp AND C.estado=1;
        IF @uot IS NULL THROW 52001,N'La campaña no existe.',1;

        EXEC seg.PA_Operacion_Sel_ContextoAutorizado
            @cJson=@cJson, @cCodigoPermiso='CAMPANIAS_VER',
            @nUsuarioId=@usuario OUTPUT, @nSesionUsuarioId=@sesion OUTPUT,
            @nDispositivoUsuarioId=@dispositivo OUTPUT, @nEmpleadoId=@empleado OUTPUT,
            @nModuloId=@modulo OUTPUT, @gCorrelacionId=@corr OUTPUT,
            @gSolicitudId=@sol OUTPUT, @cIp=@ip OUTPUT, @cEndpoint=@endpoint OUTPUT,
            @bResultado=@acceso OUTPUT, @cMensaje=@mensajeAcceso OUTPUT;
        IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'CAMPANIAS_VER')<>1
            OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'JABAS_LISTAR')<>1
            THROW 52002,N'No tiene permiso para consultar los indicadores.',1;

        IF @desde IS NULL OR @hasta IS NULL OR @desde>@hasta OR DATEDIFF(DAY,@desde,@hasta)>366
            THROW 52003,N'Indique un intervalo válido de hasta 366 días.',1;
        IF JSON_VALUE(@cJson,'$.filtros.variedadPaltaId') IS NOT NULL
           AND (@variedad IS NULL OR @variedad<=0 OR NOT EXISTS(
                SELECT 1 FROM comercial.CampaniaCalibre G
                WHERE G.campania_venta_id=@camp AND G.variedad_palta_id=@variedad AND G.activo=1))
            THROW 52004,N'La variedad no pertenece a esta campaña.',1;

        -- Los pesajes se almacenan en UTC. Se utiliza la fecha de Perú (UTC-5),
        -- conservando un filtro sargable sobre la columna fecha_registro.
        SET @inicioUtc=DATEADD(HOUR,5,CONVERT(DATETIME2(0),@desde));
        SET @finUtc=DATEADD(HOUR,5,DATEADD(DAY,1,CONVERT(DATETIME2(0),@hasta)));

        CREATE TABLE #Pesajes (
            fecha DATE NOT NULL,
            jabaId BIGINT NOT NULL,
            pesoBrutoKg DECIMAL(12,3) NOT NULL,
            pesoNetoKg DECIMAL(12,3) NOT NULL,
            variedadPaltaId SMALLINT NULL,
            nombreVariedad NVARCHAR(150) NULL
        );
        INSERT INTO #Pesajes(fecha,jabaId,pesoBrutoKg,pesoNetoKg,variedadPaltaId,nombreVariedad)
        SELECT CONVERT(DATE,DATEADD(HOUR,-5,R.fecha_registro)),R.campania_jaba_recepcion_id,
               R.peso_bruto_kg,R.peso_neto_kg,G.variedad_palta_id,V.nombre
        FROM comercial.CampaniaJabaRecepcion R
        JOIN comercial.CampaniaJabaPlan J ON J.campania_jaba_plan_id=R.campania_jaba_plan_id AND J.activo=1
        JOIN comercial.ParticipacionCampaniaSocio P
          ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
          AND P.estado=1 AND P.estado_participacion='ACTIVO'
        LEFT JOIN comercial.CampaniaCalibre G ON G.campania_calibre_id=R.campania_calibre_id
        LEFT JOIN prod.VariedadPalta V ON V.variedad_palta_id=G.variedad_palta_id
        WHERE P.campania_venta_id=@camp
          AND R.fecha_registro>=@inicioUtc AND R.fecha_registro<@finUtc
          AND (@variedad IS NULL OR G.variedad_palta_id=@variedad);

        SET @cDatos=(SELECT @desde fechaInicio,@hasta fechaFin,@variedad variedadPaltaId,
            JSON_QUERY((SELECT COUNT_BIG(1) jabasRegistradas,
                 COALESCE(SUM(P.pesoBrutoKg),0) pesoBrutoKg,
                 COALESCE(SUM(P.pesoNetoKg),0) pesoNetoKg
                 FROM #Pesajes P FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) resumen,
            JSON_QUERY((SELECT P.fecha,
                 COUNT_BIG(1) jabas, SUM(P.pesoBrutoKg) pesoBrutoKg,
                 SUM(P.pesoNetoKg) pesoNetoKg
                 FROM #Pesajes P GROUP BY P.fecha ORDER BY P.fecha FOR JSON PATH)) porDia,
            JSON_QUERY((SELECT P.variedadPaltaId,
                 COALESCE(P.nombreVariedad,N'Sin clasificar') nombre,
                 COUNT_BIG(1) jabas,SUM(P.pesoNetoKg) pesoNetoKg
                 FROM #Pesajes P GROUP BY P.variedadPaltaId,P.nombreVariedad
                 ORDER BY pesoNetoKg DESC FOR JSON PATH,INCLUDE_NULL_VALUES)) porVariedad,
            JSON_QUERY((SELECT J.estado,COUNT_BIG(1) cantidad
                 FROM comercial.CampaniaJabaPlan J
                 JOIN comercial.ParticipacionCampaniaSocio P
                    ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
                 WHERE P.campania_venta_id=@camp AND P.estado=1 AND P.estado_participacion='ACTIVO'
                    AND J.activo=1 GROUP BY J.estado FOR JSON PATH)) porEstado
            FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
        SELECT @bResultado=1,@cMensaje=N'Indicadores consultados.',
               @cCodigoRespuesta='CAMPANIA_INDICADORES_OK',@nHttpRespuesta=200;
    END TRY
    BEGIN CATCH
        SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='CAMPANIA_INDICADORES_ERROR',
            @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN 409 ELSE 500 END,
            @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099
                THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudieron consultar los indicadores.' END;
    END CATCH;
END;
GO
