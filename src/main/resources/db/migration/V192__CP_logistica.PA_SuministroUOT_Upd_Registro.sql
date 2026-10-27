IF OBJECT_ID(N'[logistica].[PA_SuministroUOT_Upd_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_SuministroUOT_Upd_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_SuministroUOT_Upd_Registro
' Descripción             : Actualiza los datos de suministro por UOT.
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
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [logistica].[PA_SuministroUOT_Upd_Registro]
        @nUsuarioId = 0,
        @nSesionUsuarioId = 0,
        @nUotId = 0,
        @nSuministroId = 0,
        @cNombre = N'',
        @cUnidad = '',
        @nStockMinimo = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE logistica.PA_SuministroUOT_Upd_Registro
 @nUsuarioId BIGINT,@nSesionUsuarioId BIGINT,@nUotId BIGINT,@nSuministroId BIGINT,@cNombre NVARCHAR(150),@cUnidad VARCHAR(20),@nStockMinimo DECIMAL(19,3)=NULL,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SELECT @bResultado=0,@cMensaje=N'No se pudo actualizar el suministro.',@cCodigoRespuesta='SUMINISTRO_NO_ACTUALIZADO',@nHttpRespuesta=400;
 DECLARE @Uot BIGINT=@nUotId,@General BIT,@Ok BIT,@Msg NVARCHAR(300); EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuarioId,@nSesionUsuarioId,@Uot,'INVENTARIO_EDITAR',1,@Uot OUTPUT,@General OUTPUT,@Ok OUTPUT,@Msg OUTPUT;
 IF @Ok=0 BEGIN SET @cMensaje=@Msg; RETURN 1; END;
 SET @cNombre=NULLIF(LTRIM(RTRIM(@cNombre)),N''); SET @cUnidad=UPPER(NULLIF(LTRIM(RTRIM(@cUnidad)),''));
 IF @cNombre IS NULL OR @cUnidad IS NULL OR (@nStockMinimo IS NOT NULL AND @nStockMinimo<0) BEGIN SET @cMensaje=N'Complete correctamente los datos del suministro.'; RETURN 1; END;
 UPDATE logistica.Suministro SET nombre=@cNombre,unidad_medida=@cUnidad,stock_minimo=COALESCE(@nStockMinimo,stock_minimo) WHERE suministro_id=@nSuministroId AND uot_id=@Uot AND estado=1;
 IF @@ROWCOUNT=0 BEGIN SET @cMensaje=N'El suministro no esta disponible en la UOT.'; SET @nHttpRespuesta=404; RETURN 1; END;
 SELECT @bResultado=1,@cMensaje=N'Suministro actualizado.',@cCodigoRespuesta='SUMINISTRO_ACTUALIZADO',@nHttpRespuesta=200; RETURN 0;
END;
GO
