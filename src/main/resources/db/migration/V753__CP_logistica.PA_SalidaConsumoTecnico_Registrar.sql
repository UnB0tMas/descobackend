IF OBJECT_ID(N'[logistica].[PA_SalidaConsumoTecnico_Registrar]', N'P') IS NOT NULL
    DROP PROCEDURE logistica.PA_SalidaConsumoTecnico_Registrar;
GO

-- Consumo E2 sobre cantidades entregadas; no modifica saldos del almacén por duplicado.
CREATE PROCEDURE logistica.PA_SalidaConsumoTecnico_Registrar
    @nSesion BIGINT,
    @nUsuario BIGINT,
    @nSalida BIGINT,
    @nVisita BIGINT,
    @nPredio BIGINT,
    @nSolicitudRecurso BIGINT,
    @nTratamiento BIGINT,
    @nCantidad DECIMAL(19,3),
    @cUnidad VARCHAR(20),
    @gClave UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @@TRANCOUNT=0 THROW 51066,N'El consumo debe registrarse junto con el tratamiento.',1;
    IF @gClave IS NULL OR @nCantidad IS NULL OR @nCantidad<=0 OR @nTratamiento IS NULL
        THROW 51066,N'Indique una cantidad válida.',1;
    IF seg.FN_TecnicoPuedeActuarPredio(@nSesion,@nUsuario,@nPredio,@nSalida,@nVisita,'SANIDAD_CREAR')<>1
        THROW 51060,N'No tiene autorización para trabajar en este predio.',1;

    DECLARE @Recurso BIGINT,@CantidadDisponible DECIMAL(19,3),@Uot BIGINT,
            @Suministro BIGINT,@Unidad VARCHAR(20),@Normalizada DECIMAL(19,6),
            @CantidadStock DECIMAL(14,3),@Uso BIGINT,@Movimiento BIGINT;
    SELECT @Recurso=RP.recurso_programado_id,@CantidadDisponible=RP.cantidad_pendiente,
           @Suministro=S.suministro_id,@Unidad=S.unidad_medida,@Uot=S.uot_id
    FROM campo.SalidaRecursoE2 R WITH(UPDLOCK,HOLDLOCK)
    JOIN logistica.RecursoProgramado RP WITH(UPDLOCK,HOLDLOCK)
        ON RP.recurso_programado_id=R.recurso_programado_id AND RP.estado=1
    JOIN logistica.Suministro S ON S.suministro_id=R.suministro_id AND S.estado=1
    JOIN campo.SalidaE2 E ON E.salida_campo_id=R.salida_campo_id
    WHERE R.solicitud_recurso_id=@nSolicitudRecurso AND R.salida_campo_id=@nSalida
      AND R.estado='ENTREGADO' AND E.estado='EN_EJECUCION'
      AND RP.estado_proceso='EN_EJECUCION' AND RP.salida_campo_id=@nSalida
      AND RP.suministro_id=R.suministro_id AND S.uot_id=E.uot_id;
    IF @Recurso IS NULL THROW 51066,N'El producto no corresponde a esta salida.',1;

    -- 1 L = 1000 ML y 1 KG = 1000 G, únicamente si la unidad se identifica.
    SET @cUnidad=UPPER(TRIM(@cUnidad));
    SET @Normalizada=CASE
         WHEN @cUnidad=@Unidad THEN CONVERT(DECIMAL(19,6),@nCantidad)
         WHEN @Unidad='L' AND @cUnidad='ML' THEN CONVERT(DECIMAL(19,6),@nCantidad)/1000
         WHEN @Unidad='ML' AND @cUnidad='L' THEN CONVERT(DECIMAL(19,6),@nCantidad)*1000
         WHEN @Unidad='KG' AND @cUnidad='G' THEN CONVERT(DECIMAL(19,6),@nCantidad)/1000
         WHEN @Unidad='G' AND @cUnidad='KG' THEN CONVERT(DECIMAL(19,6),@nCantidad)*1000
         ELSE NULL END;
    SET @CantidadStock=TRY_CONVERT(DECIMAL(14,3),@Normalizada);
    IF @CantidadStock IS NULL OR @CantidadStock<=0 OR @Normalizada<>@CantidadStock
       OR @CantidadStock>@CantidadDisponible
        THROW 51067,N'La cantidad excede lo disponible.',1;

    SELECT @Uso=U.salida_uso_suministro_id
    FROM campo.SalidaUsoSuministroE2 U WITH(UPDLOCK,HOLDLOCK)
    WHERE U.clave_idempotencia=@gClave;
    IF @Uso IS NOT NULL
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM campo.SalidaUsoSuministroE2 U
            WHERE U.salida_uso_suministro_id=@Uso AND U.tratamiento_id=@nTratamiento
              AND U.solicitud_recurso_id=@nSolicitudRecurso AND U.cantidad=@CantidadStock)
            THROW 51065,N'La solicitud ya fue utilizada.',1;
        RETURN;
    END;
    IF EXISTS(SELECT 1 FROM campo.SalidaUsoSuministroE2 WHERE tratamiento_id=@nTratamiento)
        THROW 51065,N'El tratamiento ya tiene un consumo registrado.',1;
    INSERT campo.SalidaUsoSuministroE2
        (salida_campo_id,solicitud_recurso_id,recurso_programado_id,visita_tecnica_id,predio_id,
         tratamiento_id,cantidad,unidad_medida,usuario_id,clave_idempotencia)
    VALUES (@nSalida,@nSolicitudRecurso,@Recurso,@nVisita,@nPredio,
         @nTratamiento,@CantidadStock,@Unidad,@nUsuario,@gClave);
    SET @Uso=CONVERT(BIGINT,SCOPE_IDENTITY());
    INSERT logistica.RecursoMovimiento
        (recurso_programado_id,tipo_movimiento,cantidad,usuario_id,observacion)
    VALUES (@Recurso,'CONSUMO',@CantidadStock,@nUsuario,CONCAT(N'E2_USO:',@Uso));
    SET @Movimiento=CONVERT(BIGINT,SCOPE_IDENTITY());
    UPDATE campo.SalidaUsoSuministroE2
       SET recurso_movimiento_id=@Movimiento
       WHERE salida_uso_suministro_id=@Uso;
END;
GO
