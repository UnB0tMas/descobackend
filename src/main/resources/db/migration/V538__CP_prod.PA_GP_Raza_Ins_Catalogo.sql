SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_Raza_Ins_Catalogo;
GO
IF OBJECT_ID(N'prod.PA_GP_Raza_Ins_Catalogo', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Raza_Ins_Catalogo;
GO
CREATE PROCEDURE prod.PA_GP_Raza_Ins_Catalogo
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,
 @Especie INT,@Nombre NVARCHAR(120)
AS
BEGIN
 SET NOCOUNT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CATALOGOS_CREAR',1)<>1
  THROW 51101,N'Acceso no autorizado.',1;
 IF @Especie IS NULL OR LEN(TRIM(COALESCE(@Nombre,N'')))<2
  THROW 51103,N'Seleccione una especie y el nombre de la raza.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.EspeciePecuaria WHERE especie_pecuaria_id=@Especie AND estado=1)
  THROW 51103,N'La especie seleccionada no está activa.',1;
 INSERT prod.GPRaza(especie_pecuaria_id,nombre,usuario_creacion_id)
 VALUES(@Especie,TRIM(@Nombre),@Usuario);
 SELECT CONVERT(BIGINT,SCOPE_IDENTITY()) AS id;
END;
GO
