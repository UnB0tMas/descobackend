IF OBJECT_ID(N'[comercial].[PA_Venta_Sel_MetodosPago]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_Venta_Sel_MetodosPago];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_Venta_Sel_MetodosPago
' Descripción             : Consulta los métodos de pago disponibles para ventas.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Comercial
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo de referencia: reemplazar valores e identificadores por datos válidos.
    DECLARE
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(80),
        @nHttpRespuesta SMALLINT;
    EXEC [comercial].[PA_Venta_Sel_MetodosPago]
        @nUsuarioId = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [comercial].[PA_Venta_Sel_MetodosPago]
    @nUsuarioId BIGINT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(80) OUTPUT,
    @nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @bResultado = 0;
    SET @cMensaje = N'No se pudieron consultar los métodos de pago.';
    SET @cCodigoRespuesta = 'METODOS_PAGO_NO_LISTADOS';
    SET @nHttpRespuesta = 400;

    IF @nUsuarioId IS NULL
    BEGIN
        SET @cMensaje = N'La sesión ya no está disponible.';
        SET @cCodigoRespuesta = 'SESION_NO_DISPONIBLE';
        SET @nHttpRespuesta = 401;
        RETURN;
    END;

    /*
        En modo GENERAL no existe una UOT específica en SesionUsuario.
        Para un catálogo global basta comprobar que el usuario pueda operar el POS
        en al menos una UOT activa asignada.
    */
    IF NOT EXISTS
    (
        SELECT 1
        FROM seg.UsuarioUOT AS UU
        INNER JOIN org.UOT AS U
            ON U.uot_id = UU.uot_id
           AND U.estado = 1
        WHERE UU.usuario_id = @nUsuarioId
          AND UU.estado = 1
          AND UU.fecha_hasta IS NULL
          AND seg.FN_Usuario_TienePermisoUOT(
                @nUsuarioId,
                UU.uot_id,
                'POS_OPERAR'
              ) = 1
    )
    BEGIN
        SET @cMensaje = N'No tiene permiso para operar el punto de venta.';
        SET @cCodigoRespuesta = 'POS_SIN_PERMISO';
        SET @nHttpRespuesta = 403;
        RETURN;
    END;

    SELECT
        CONVERT(INT, MP.metodo_pago_id) AS metodoPagoId,
        MP.codigo AS codigo,
        MP.nombre AS nombre,
        MP.requiere_numero_operacion AS requiereNumeroOperacion
    FROM comercial.MetodoPago AS MP
    WHERE MP.estado = 1
    ORDER BY
        CASE MP.codigo
            WHEN 'EFECTIVO' THEN 1
            WHEN 'YAPE' THEN 2
            WHEN 'PLIN' THEN 3
            WHEN 'TARJETA' THEN 4
            WHEN 'TRANSFERENCIA' THEN 5
            WHEN 'DEPOSITO' THEN 6
            ELSE 99
        END,
        MP.nombre;

    SET @bResultado = 1;
    SET @cMensaje = N'Métodos de pago consultados.';
    SET @cCodigoRespuesta = 'METODOS_PAGO_LISTADOS';
    SET @nHttpRespuesta = 200;
END;
GO
