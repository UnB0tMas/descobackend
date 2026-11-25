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
 @nUsuarioId BIGINT,@nSesionUsuarioId BIGINT,@nUotId BIGINT,@nSuministroId BIGINT,@cNombre NVARCHAR(150),@cUnidad VARCHAR(20),@nStockMinimo DECIMAL(19,3)=NULL,@nProductoId BIGINT=NULL,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SELECT @bResultado=0,@cMensaje=N'No se pudo actualizar el suministro.',@cCodigoRespuesta='SUMINISTRO_NO_ACTUALIZADO',@nHttpRespuesta=400;
 DECLARE @Uot BIGINT=@nUotId,@General BIT,@Ok BIT,@Msg NVARCHAR(300); EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuarioId,@nSesionUsuarioId,@Uot,'INVENTARIO_EDITAR',1,@Uot OUTPUT,@General OUTPUT,@Ok OUTPUT,@Msg OUTPUT;
 IF @Ok=0 BEGIN SET @cMensaje=@Msg; RETURN 1; END;
 SET @cNombre=NULLIF(LTRIM(RTRIM(@cNombre)),N''); SET @cUnidad=UPPER(NULLIF(LTRIM(RTRIM(@cUnidad)),''));
 IF @cNombre IS NULL OR @cUnidad IS NULL OR (@nStockMinimo IS NOT NULL AND @nStockMinimo<0) BEGIN SET @cMensaje=N'Complete correctamente los datos del suministro.'; RETURN 1; END;
 IF @nProductoId IS NOT NULL
 BEGIN
     IF EXISTS(SELECT 1 FROM logistica.Suministro S WITH (NOLOCK)
         WHERE S.suministro_id=@nSuministroId AND S.uot_id=@Uot
           AND S.producto_id IS NOT NULL AND S.producto_id<>@nProductoId)
     BEGIN
         SELECT @cMensaje=N'El suministro ya está vinculado con otro producto.',
                @cCodigoRespuesta='SUMINISTRO_VINCULO_EXISTENTE',@nHttpRespuesta=409;
         RETURN 1;
     END;
     IF NOT EXISTS(SELECT 1 FROM logistica.Suministro S WITH (NOLOCK)
         INNER JOIN logistica.Producto P WITH (NOLOCK) ON P.producto_id=@nProductoId
         INNER JOIN logistica.ProductoUOTPolitica PU WITH (NOLOCK)
            ON PU.producto_id=P.producto_id AND PU.uot_id=@Uot AND PU.estado=1
         WHERE S.suministro_id=@nSuministroId AND S.uot_id=@Uot AND S.estado=1
           AND P.estado=1 AND P.unidad_medida=S.unidad_medida)
       OR EXISTS(SELECT 1 FROM logistica.Suministro S WITH (NOLOCK)
         WHERE S.uot_id=@Uot AND S.producto_id=@nProductoId AND S.suministro_id<>@nSuministroId)
     BEGIN
         SELECT @cMensaje=N'El producto no está disponible o utiliza otra unidad de medida.',
                @cCodigoRespuesta='SUMINISTRO_VINCULO_NO_VALIDO',@nHttpRespuesta=409;
         RETURN 1;
     END;
     SELECT @cNombre=LEFT(P.nombre,150),@cUnidad=P.unidad_medida
       FROM logistica.Producto P WITH (NOLOCK) WHERE P.producto_id=@nProductoId;
 END;
 IF EXISTS(
     SELECT 1
     FROM logistica.Suministro S WITH (NOLOCK)
     INNER JOIN logistica.Producto P WITH (NOLOCK) ON P.producto_id=S.producto_id
     WHERE S.suministro_id=@nSuministroId AND S.uot_id=@Uot
       AND (S.producto_id IS NOT NULL)
       AND (@cNombre<>LEFT(P.nombre,150) OR @cUnidad<>P.unidad_medida)
 )
 BEGIN
     SELECT @cMensaje=N'Los datos del suministro vinculado se actualizan desde Productos.',
            @cCodigoRespuesta='SUMINISTRO_PRODUCTO_PROTEGIDO',@nHttpRespuesta=409;
     RETURN 1;
 END;
 UPDATE logistica.Suministro SET nombre=@cNombre,unidad_medida=@cUnidad,stock_minimo=COALESCE(@nStockMinimo,stock_minimo),producto_id=COALESCE(producto_id,@nProductoId) WHERE suministro_id=@nSuministroId AND uot_id=@Uot AND estado=1;
 IF @@ROWCOUNT=0 BEGIN SET @cMensaje=N'El suministro no esta disponible en la UOT.'; SET @nHttpRespuesta=404; RETURN 1; END;
 SELECT @bResultado=1,@cMensaje=N'Suministro actualizado.',@cCodigoRespuesta='SUMINISTRO_ACTUALIZADO',@nHttpRespuesta=200; RETURN 0;
END;
GO
