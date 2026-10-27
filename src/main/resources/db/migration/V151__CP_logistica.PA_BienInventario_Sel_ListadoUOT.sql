IF OBJECT_ID(N'[logistica].[PA_BienInventario_Sel_ListadoUOT]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_BienInventario_Sel_ListadoUOT];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_BienInventario_Sel_ListadoUOT
' Descripción             : Lista por UOT los bien de inventario.
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
        @cMensaje NVARCHAR(300);
    EXEC [logistica].[PA_BienInventario_Sel_ListadoUOT]
        @nUsuarioId = 0,
        @nUotId = 0,
        @bModoGeneral = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE [logistica].[PA_BienInventario_Sel_ListadoUOT]
    @nUsuarioId BIGINT,
    @nUotId BIGINT = NULL,
    @bModoGeneral BIT = 0,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        @bResultado = 0,
        @cMensaje = N'No se pudo consultar el inventario.';

    IF @bModoGeneral = 0
       AND
       (
           @nUotId IS NULL
           OR [seg].[FN_Usuario_TienePermisoUOT](
               @nUsuarioId,
               @nUotId,
               'INVENTARIO_LISTAR'
           ) = 0
       )
    BEGIN
        SET @cMensaje = N'Seleccione una UOT autorizada.';
        RETURN;
    END;

    SELECT
        B.bien_inventario_id,
        B.uot_id,
        U.codigo AS uot_codigo,
        U.nombre AS uot_nombre,
        B.tipo_bien_id,
        T.codigo AS tipo_codigo,
        T.nombre AS tipo_bien,
        B.codigo_patrimonial,
        B.nombre,
        B.marca,
        B.modelo,
        B.serie,
        B.estado_bien,
        B.fecha_adquisicion,
        B.monto_adquisicion,
        B.moneda_adquisicion,
        B.estado
    FROM [logistica].[BienInventario] B
    INNER JOIN [org].[UOT] U
        ON U.uot_id = B.uot_id
       AND U.estado = 1
    INNER JOIN [logistica].[TipoBien] T
        ON T.tipo_bien_id = B.tipo_bien_id
    WHERE
        (
            (@bModoGeneral = 0 AND B.uot_id = @nUotId)
            OR
            (
                @bModoGeneral = 1
                AND [seg].[FN_Usuario_TienePermisoUOT](
                    @nUsuarioId,
                    B.uot_id,
                    'INVENTARIO_LISTAR'
                ) = 1
            )
        )
    ORDER BY U.nombre, B.nombre, B.bien_inventario_id;

    SELECT
        @bResultado = 1,
        @cMensaje = N'Inventario consultado correctamente.';
END;
GO
