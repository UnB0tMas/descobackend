SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_Parcela_Sel_Listado;
GO
IF OBJECT_ID(N'prod.PA_GP_Parcela_Sel_Listado', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Parcela_Sel_Listado;
GO
CREATE PROCEDURE prod.PA_GP_Parcela_Sel_Listado
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Predio BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_LISTAR',0)<>1
     THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS (SELECT 1 FROM prod.PredioAmbito
  WHERE predio_id=@Predio AND uot_id=@Uot AND estado=1 AND convenio_uot_organizacion_id IS NULL)
     THROW 51102,N'Predio fuera del ámbito general.',1;
 SELECT P.parcela_id AS parcelaId,P.predio_id AS predioId,P.codigo,P.nombre,
        P.area_ha AS areaHa,P.estado,
        U.distrito_codigo AS distritoCodigo,U.centro_poblado_id AS centroPobladoId,
        CASE WHEN U.posicion IS NULL THEN NULL ELSE CONVERT(DECIMAL(9,6),U.posicion.Lat) END AS latitud,
        CASE WHEN U.posicion IS NULL THEN NULL ELSE CONVERT(DECIMAL(9,6),U.posicion.Long) END AS longitud
 FROM prod.Parcela P LEFT JOIN geo.Ubicacion U ON U.ubicacion_id=P.ubicacion_id
 WHERE P.predio_id=@Predio ORDER BY P.estado DESC,P.nombre,P.parcela_id;
END;
GO
