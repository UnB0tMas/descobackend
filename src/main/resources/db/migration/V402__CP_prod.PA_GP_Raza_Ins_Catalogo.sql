IF OBJECT_ID(N'[prod].[PA_GP_Raza_Ins_Catalogo]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_GP_Raza_Ins_Catalogo];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_GP_Raza_Ins_Catalogo
' Descripción            : Registra gp raza para catalogo.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE PROCEDURE prod.PA_GP_Raza_Ins_Catalogo
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,
 @Especie INT,@Nombre NVARCHAR(120),@Descripcion NVARCHAR(500)=NULL
AS
BEGIN
 SET NOCOUNT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CATALOGOS_CREAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF @Especie IS NULL OR LEN(TRIM(COALESCE(@Nombre,N'')))<2 THROW 51103,N'Especie y raza obligatorias.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.EspeciePecuaria WHERE especie_pecuaria_id=@Especie AND estado=1)
   THROW 51103,N'La especie seleccionada no está activa.',1;
 IF EXISTS(SELECT 1 FROM prod.GPRaza WHERE especie_pecuaria_id=@Especie AND nombre=TRIM(@Nombre))
   THROW 51103,N'La raza ya existe para la especie.',1;
 INSERT prod.GPRaza(especie_pecuaria_id,nombre,descripcion,usuario_creacion_id)
 VALUES(@Especie,TRIM(@Nombre),NULLIF(TRIM(@Descripcion),N''),@Usuario);
 SELECT CONVERT(BIGINT,SCOPE_IDENTITY()) AS id;
END;
GO
