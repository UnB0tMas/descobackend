IF OBJECT_ID(N'[logistica].[PA_SuministroUOT_Upd_Registro]') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_SuministroUOT_Upd_Registro];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : logistica.PA_SuministroUOT_Upd_Registro
' Descripción            : Actualiza los datos de suministro por UOT.
' Aplicativo / Módulo    : DESCO / Logística
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
