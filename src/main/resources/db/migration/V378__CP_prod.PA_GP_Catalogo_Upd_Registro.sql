IF OBJECT_ID(N'[prod].[PA_GP_Catalogo_Upd_Registro]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_GP_Catalogo_Upd_Registro];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_GP_Catalogo_Upd_Registro
' Descripción            : Actualiza la información de gp catalogo.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE PROCEDURE prod.PA_GP_Catalogo_Upd_Registro
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Tipo VARCHAR(24),@Id BIGINT,
 @Padre BIGINT=NULL,@Codigo VARCHAR(40)=NULL,@Nombre NVARCHAR(160)=NULL,
 @Descripcion NVARCHAR(1000)=NULL,@Estado BIT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CATALOGOS_EDITAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF @Id<1 OR @Estado IS NULL THROW 51103,N'Datos del catálogo inválidos.',1;
 IF @Tipo NOT IN ('CULTIVO','CRIANZA','VARIEDAD','RAZA','PROBLEMA_CULTIVO','PROBLEMA_CRIANZA','TRATAMIENTO','RELACION')
   THROW 51103,N'Tipo de catálogo no admitido.',1;
 IF @Estado=0 AND @Tipo='CULTIVO' AND EXISTS(SELECT 1 FROM prod.GPActividad WHERE cultivo_id=@Id AND estado=1)
   THROW 51103,N'No se puede desactivar un cultivo con actividades activas.',1;
 IF @Estado=0 AND @Tipo='CRIANZA' AND EXISTS(SELECT 1 FROM prod.GPActividad WHERE especie_pecuaria_id=@Id AND estado=1)
   THROW 51103,N'No se puede desactivar una especie con actividades activas.',1;
 IF @Estado=1 AND LEN(TRIM(COALESCE(@Nombre,N'')))<2 THROW 51103,N'Ingrese un nombre válido.',1;
 IF @Estado=1 AND @Tipo IN ('CULTIVO','CRIANZA','VARIEDAD') AND LEN(TRIM(COALESCE(@Codigo,'')))<2
   THROW 51103,N'Ingrese un código válido.',1;
 BEGIN TRAN;
 BEGIN TRY
  DECLARE @N INT=0;
  IF @Tipo='CULTIVO'
   UPDATE prod.Cultivo SET nombre=CASE WHEN @Estado=1 THEN TRIM(@Nombre) ELSE nombre END,
     descripcion=CASE WHEN @Estado=1 THEN NULLIF(TRIM(@Descripcion),N'') ELSE descripcion END,
     estado=@Estado WHERE cultivo_id=@Id;
  ELSE IF @Tipo='CRIANZA'
   UPDATE prod.EspeciePecuaria SET nombre=CASE WHEN @Estado=1 THEN TRIM(@Nombre) ELSE nombre END,
     descripcion=CASE WHEN @Estado=1 THEN NULLIF(TRIM(@Descripcion),N'') ELSE descripcion END,
     estado=@Estado WHERE especie_pecuaria_id=@Id;
  ELSE IF @Tipo='VARIEDAD'
   UPDATE prod.VariedadCultivo SET nombre=CASE WHEN @Estado=1 THEN TRIM(@Nombre) ELSE nombre END,
     descripcion=CASE WHEN @Estado=1 THEN NULLIF(TRIM(@Descripcion),N'') ELSE descripcion END,
     estado=@Estado WHERE variedad_cultivo_id=@Id AND (@Padre IS NULL OR cultivo_id=@Padre);
  ELSE IF @Tipo='RAZA'
   UPDATE prod.GPRaza SET nombre=CASE WHEN @Estado=1 THEN TRIM(@Nombre) ELSE nombre END,
     descripcion=CASE WHEN @Estado=1 THEN NULLIF(TRIM(@Descripcion),N'') ELSE descripcion END,
     estado=@Estado WHERE raza_id=@Id AND (@Padre IS NULL OR especie_pecuaria_id=@Padre);
  ELSE IF @Tipo IN('PROBLEMA_CULTIVO','PROBLEMA_CRIANZA')
   UPDATE prod.GPProblema SET nombre=CASE WHEN @Estado=1 THEN TRIM(@Nombre) ELSE nombre END,
     estado=@Estado WHERE problema_id=@Id AND
     ((@Tipo='PROBLEMA_CULTIVO' AND cultivo_id IS NOT NULL) OR
      (@Tipo='PROBLEMA_CRIANZA' AND especie_pecuaria_id IS NOT NULL));
  ELSE IF @Tipo='TRATAMIENTO'
   UPDATE prod.GPTratamiento SET nombre=CASE WHEN @Estado=1 THEN TRIM(@Nombre) ELSE nombre END,
      descripcion=CASE WHEN @Estado=1 THEN NULLIF(TRIM(@Descripcion),N'') ELSE descripcion END,
      estado=@Estado WHERE tratamiento_id=@Id;
  ELSE IF @Tipo='RELACION' AND @Estado=0
   DELETE FROM prod.GPProblemaTratamiento WHERE tratamiento_id=@Id AND problema_id=@Padre;
  ELSE THROW 51103,N'La asociación se administra desde Nuevo valor.',1;
  SET @N=@@ROWCOUNT;
  IF @N<>1 THROW 51103,N'El registro no existe o no corresponde al catálogo.',1;
  COMMIT;
  SELECT @Id AS id;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
