IF OBJECT_ID(N'[prod].[PA_GP_Cultivo_Ins_Catalogo]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_GP_Cultivo_Ins_Catalogo];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_GP_Cultivo_Ins_Catalogo
' Descripción            : Registra gp cultivo para catalogo.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE PROCEDURE prod.PA_GP_Cultivo_Ins_Catalogo
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Codigo VARCHAR(40),@Nombre NVARCHAR(120),@Descripcion NVARCHAR(500)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CATALOGOS_CREAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF LEN(TRIM(COALESCE(@Nombre,N'')))<2 THROW 51103,N'Ingrese un nombre válido.',1;
 
 DECLARE @NuevoCodigo VARCHAR(40)=CASE WHEN NULLIF(TRIM(@Codigo),'') IS NULL OR UPPER(TRIM(@Codigo))='AUTO'
   THEN prod.FN_GP_CodigoBase(@Nombre,40) ELSE UPPER(TRIM(@Codigo)) END;
 IF LEN(@NuevoCodigo)<2 THROW 51103,N'Código no válido.',1;
 BEGIN TRY
  BEGIN TRANSACTION;
  DECLARE @Lock INT;
  EXEC @Lock=sys.sp_getapplock @Resource='prod.Cultivo:CODIGO:',
    @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @Lock<0 THROW 51103,N'No se pudo reservar un código. Intente nuevamente.',1;
  IF NULLIF(TRIM(@Codigo),'') IS NULL OR UPPER(TRIM(@Codigo))='AUTO'
  BEGIN
   DECLARE @Base VARCHAR(40)=@NuevoCodigo,@Indice INT=1,@Sufijo VARCHAR(12);
   WHILE EXISTS(SELECT 1 FROM prod.Cultivo WITH(UPDLOCK,HOLDLOCK) WHERE codigo=@NuevoCodigo)
   BEGIN
    SET @Indice+=1;
    SET @Sufijo='-'+CONVERT(VARCHAR(11),@Indice);
    SET @NuevoCodigo=LEFT(@Base,40-LEN(@Sufijo))+@Sufijo;
   END;
  END
  INSERT prod.Cultivo(codigo,nombre,descripcion) VALUES(@NuevoCodigo,TRIM(@Nombre),NULLIF(TRIM(@Descripcion),N''));
  DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());
  COMMIT TRANSACTION;
  SELECT @Id AS id;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;
GO
