IF OBJECT_ID(N'[prod].[PA_GP_Tratamiento_Ins_Catalogo]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_GP_Tratamiento_Ins_Catalogo];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_GP_Tratamiento_Ins_Catalogo
' Descripción            : Registra gp tratamiento para catalogo.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE PROCEDURE prod.PA_GP_Tratamiento_Ins_Catalogo
@Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Nombre NVARCHAR(160),@Descripcion NVARCHAR(1000)=NULL
AS
BEGIN
  SET NOCOUNT ON;
IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CATALOGOS_CREAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF LEN(TRIM(COALESCE(@Nombre,N'')))<2 THROW 51103,N'Nombre obligatorio.',1;
 INSERT prod.GPTratamiento(nombre,descripcion) VALUES(TRIM(@Nombre),NULLIF(TRIM(@Descripcion),N'')); SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS id;
END;
GO
