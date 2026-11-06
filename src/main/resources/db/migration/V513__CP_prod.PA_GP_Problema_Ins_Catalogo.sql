SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'prod.PA_GP_Problema_Ins_Catalogo', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Problema_Ins_Catalogo;
GO
CREATE PROCEDURE prod.PA_GP_Problema_Ins_Catalogo
@Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Cultivo INT=NULL,@Especie INT=NULL,@Nombre NVARCHAR(160)
AS
BEGIN
  SET NOCOUNT ON;
IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CATALOGOS_CREAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF LEN(TRIM(COALESCE(@Nombre,N'')))<2 OR ((@Cultivo IS NULL AND @Especie IS NULL) OR (@Cultivo IS NOT NULL AND @Especie IS NOT NULL)) THROW 51103,N'Problema inválido.',1;
 INSERT prod.GPProblema(cultivo_id,especie_pecuaria_id,nombre) VALUES(@Cultivo,@Especie,TRIM(@Nombre)); SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS id;
END;
GO
