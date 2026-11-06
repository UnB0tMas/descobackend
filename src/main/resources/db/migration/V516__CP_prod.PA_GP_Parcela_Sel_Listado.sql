SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'prod.PA_GP_Parcela_Sel_Listado', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Parcela_Sel_Listado;
GO
CREATE PROCEDURE prod.PA_GP_Parcela_Sel_Listado
@Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Predio BIGINT
AS
BEGIN
  SET NOCOUNT ON;
IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_LISTAR',0)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.PredioAmbito WHERE predio_id=@Predio AND uot_id=@Uot AND estado=1 AND convenio_uot_organizacion_id IS NULL) THROW 51102,N'Predio fuera del ámbito general.',1;
 SELECT parcela_id AS parcelaId,predio_id AS predioId,codigo,nombre,area_ha AS areaHa,estado
 FROM prod.Parcela WHERE predio_id=@Predio ORDER BY estado DESC,nombre,parcela_id;
END;
GO
