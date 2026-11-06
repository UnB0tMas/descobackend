SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'prod.PA_GP_Tratamiento_Ins_Asociacion', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Tratamiento_Ins_Asociacion;
GO
CREATE PROCEDURE prod.PA_GP_Tratamiento_Ins_Asociacion
@Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Problema INT,@Tratamiento INT
AS
BEGIN
  SET NOCOUNT ON;
IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CATALOGOS_EDITAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPProblema WHERE problema_id=@Problema AND estado=1) OR NOT EXISTS(SELECT 1 FROM prod.GPTratamiento WHERE tratamiento_id=@Tratamiento AND estado=1) THROW 51103,N'Asociación inválida.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPProblemaTratamiento WHERE problema_id=@Problema AND tratamiento_id=@Tratamiento)
   INSERT prod.GPProblemaTratamiento(problema_id,tratamiento_id) VALUES(@Problema,@Tratamiento);
 SELECT CAST(@Tratamiento AS BIGINT) AS id;
END;
GO
