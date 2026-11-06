-- V498: Catálogos productivos. Descripciones reales y códigos generados por el servidor.
-- Requiere las migraciones V462, V463, V489 y V496 aplicadas.
-- No altera códigos ni datos históricos existentes.
IF COL_LENGTH('prod.Cultivo','descripcion') IS NULL
 ALTER TABLE prod.Cultivo ADD descripcion NVARCHAR(500) NULL;
GO
IF COL_LENGTH('prod.EspeciePecuaria','descripcion') IS NULL
 ALTER TABLE prod.EspeciePecuaria ADD descripcion NVARCHAR(500) NULL;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'prod.FN_GP_CodigoBase', N'FN') IS NOT NULL DROP FUNCTION prod.FN_GP_CodigoBase;
GO
CREATE FUNCTION prod.FN_GP_CodigoBase(@Nombre NVARCHAR(160),@Longitud INT)
RETURNS VARCHAR(40)
AS
BEGIN
 DECLARE @Texto NVARCHAR(160)=UPPER(LTRIM(RTRIM(COALESCE(@Nombre,N''))));
 SET @Texto=TRANSLATE(@Texto,N'ÁÀÄÂÉÈËÊÍÌÏÎÓÒÖÔÚÙÜÛÑÇ',N'AAAAEEEEIIIIOOOOUUUUNC');
 DECLARE @Codigo VARCHAR(160)=CONVERT(VARCHAR(160),@Texto);
 DECLARE @Pos INT=PATINDEX('%[^A-Z0-9-]%',@Codigo COLLATE Latin1_General_100_BIN2);
 WHILE @Pos>0
 BEGIN
  SET @Codigo=STUFF(@Codigo,@Pos,1,'-');
  SET @Pos=PATINDEX('%[^A-Z0-9-]%',@Codigo COLLATE Latin1_General_100_BIN2);
 END;
 WHILE CHARINDEX('--',@Codigo)>0 SET @Codigo=REPLACE(@Codigo,'--','-');
 WHILE LEFT(@Codigo,1)='-' SET @Codigo=SUBSTRING(@Codigo,2,LEN(@Codigo));
 WHILE RIGHT(@Codigo,1)='-' SET @Codigo=LEFT(@Codigo,LEN(@Codigo)-1);
 IF @Codigo='' SET @Codigo='REGISTRO';
 RETURN LEFT(@Codigo,CASE WHEN @Longitud BETWEEN 2 AND 40 THEN @Longitud ELSE 40 END);
END;
GO
IF OBJECT_ID(N'prod.PA_GP_Cultivo_Ins_Catalogo', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Cultivo_Ins_Catalogo;
GO
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
IF OBJECT_ID(N'prod.PA_GP_Especie_Ins_Catalogo', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Especie_Ins_Catalogo;
GO
CREATE PROCEDURE prod.PA_GP_Especie_Ins_Catalogo
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Codigo VARCHAR(30),@Nombre NVARCHAR(90),@Descripcion NVARCHAR(500)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CATALOGOS_CREAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF LEN(TRIM(COALESCE(@Nombre,N'')))<2 THROW 51103,N'Ingrese un nombre válido.',1;
 
 DECLARE @NuevoCodigo VARCHAR(30)=CASE WHEN NULLIF(TRIM(@Codigo),'') IS NULL OR UPPER(TRIM(@Codigo))='AUTO'
   THEN prod.FN_GP_CodigoBase(@Nombre,30) ELSE UPPER(TRIM(@Codigo)) END;
 IF LEN(@NuevoCodigo)<2 THROW 51103,N'Código no válido.',1;
 BEGIN TRY
  BEGIN TRANSACTION;
  DECLARE @Lock INT;
  EXEC @Lock=sys.sp_getapplock @Resource='prod.EspeciePecuaria:CODIGO:',
    @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @Lock<0 THROW 51103,N'No se pudo reservar un código. Intente nuevamente.',1;
  IF NULLIF(TRIM(@Codigo),'') IS NULL OR UPPER(TRIM(@Codigo))='AUTO'
  BEGIN
   DECLARE @Base VARCHAR(30)=@NuevoCodigo,@Indice INT=1,@Sufijo VARCHAR(12);
   WHILE EXISTS(SELECT 1 FROM prod.EspeciePecuaria WITH(UPDLOCK,HOLDLOCK) WHERE codigo=@NuevoCodigo)
   BEGIN
    SET @Indice+=1;
    SET @Sufijo='-'+CONVERT(VARCHAR(11),@Indice);
    SET @NuevoCodigo=LEFT(@Base,30-LEN(@Sufijo))+@Sufijo;
   END;
  END
  INSERT prod.EspeciePecuaria(codigo,nombre,descripcion) VALUES(@NuevoCodigo,TRIM(@Nombre),NULLIF(TRIM(@Descripcion),N''));
  DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());
  COMMIT TRANSACTION;
  SELECT @Id AS id;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;
GO
IF OBJECT_ID(N'prod.PA_GP_Variedad_Ins_Catalogo', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Variedad_Ins_Catalogo;
GO
CREATE PROCEDURE prod.PA_GP_Variedad_Ins_Catalogo
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,
 @Cultivo INT,@Codigo VARCHAR(40),@Nombre NVARCHAR(120),@Descripcion NVARCHAR(500)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CATALOGOS_CREAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF LEN(TRIM(COALESCE(@Nombre,N'')))<2 THROW 51103,N'Ingrese un nombre válido.',1;
 IF @Cultivo IS NULL OR NOT EXISTS(SELECT 1 FROM prod.Cultivo WHERE cultivo_id=@Cultivo AND estado=1) THROW 51103,N'Cultivo no disponible.',1;
 DECLARE @NuevoCodigo VARCHAR(40)=CASE WHEN NULLIF(TRIM(@Codigo),'') IS NULL OR UPPER(TRIM(@Codigo))='AUTO'
   THEN prod.FN_GP_CodigoBase(@Nombre,40) ELSE UPPER(TRIM(@Codigo)) END;
 IF LEN(@NuevoCodigo)<2 THROW 51103,N'Código no válido.',1;
 BEGIN TRY
  BEGIN TRANSACTION;
  DECLARE @Lock INT;
  EXEC @Lock=sys.sp_getapplock @Resource='prod.VariedadCultivo:CODIGO:',
    @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @Lock<0 THROW 51103,N'No se pudo reservar un código. Intente nuevamente.',1;
  IF NULLIF(TRIM(@Codigo),'') IS NULL OR UPPER(TRIM(@Codigo))='AUTO'
  BEGIN
   DECLARE @Base VARCHAR(40)=@NuevoCodigo,@Indice INT=1,@Sufijo VARCHAR(12);
   WHILE EXISTS(SELECT 1 FROM prod.VariedadCultivo WITH(UPDLOCK,HOLDLOCK) WHERE cultivo_id=@Cultivo AND codigo=@NuevoCodigo)
   BEGIN
    SET @Indice+=1;
    SET @Sufijo='-'+CONVERT(VARCHAR(11),@Indice);
    SET @NuevoCodigo=LEFT(@Base,40-LEN(@Sufijo))+@Sufijo;
   END;
  END
  INSERT prod.VariedadCultivo(cultivo_id,codigo,nombre,descripcion) VALUES(@Cultivo,@NuevoCodigo,TRIM(@Nombre),NULLIF(TRIM(@Descripcion),N''));
  DECLARE @Id BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());
  COMMIT TRANSACTION;
  SELECT @Id AS id;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;
GO
IF OBJECT_ID(N'prod.PA_GP_Catalogo_Sel_Listado', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Catalogo_Sel_Listado;
GO
CREATE PROCEDURE prod.PA_GP_Catalogo_Sel_Listado
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'PREDIOS_VER',0)<>1
   AND prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CATALOGOS_LISTAR',0)<>1
   THROW 51101,N'Acceso no autorizado.',1;
 SELECT 'CULTIVO' tipo,CONVERT(BIGINT,cultivo_id) id,CONVERT(BIGINT,NULL) padreId,
 nombre COLLATE DATABASE_DEFAULT nombre,CONVERT(NVARCHAR(1000),descripcion) COLLATE DATABASE_DEFAULT descripcion,
 CONVERT(VARCHAR(40),codigo) COLLATE DATABASE_DEFAULT codigo FROM prod.Cultivo WHERE estado=1
 UNION ALL
 SELECT 'CRIANZA',CONVERT(BIGINT,especie_pecuaria_id),NULL,nombre COLLATE DATABASE_DEFAULT,CONVERT(NVARCHAR(1000),descripcion) COLLATE DATABASE_DEFAULT,
 CONVERT(VARCHAR(40),codigo) COLLATE DATABASE_DEFAULT FROM prod.EspeciePecuaria WHERE estado=1
 UNION ALL
 SELECT 'VARIEDAD',variedad_cultivo_id,CONVERT(BIGINT,cultivo_id),nombre COLLATE DATABASE_DEFAULT,
 CONVERT(NVARCHAR(1000),descripcion),codigo COLLATE DATABASE_DEFAULT FROM prod.VariedadCultivo WHERE estado=1
 UNION ALL
 SELECT 'RAZA',CONVERT(BIGINT,raza_id),CONVERT(BIGINT,especie_pecuaria_id),nombre COLLATE DATABASE_DEFAULT,
 CONVERT(NVARCHAR(1000),descripcion),CONVERT(VARCHAR(40),NULL) FROM prod.GPRaza WHERE estado=1
 UNION ALL
 SELECT 'PROBLEMA_CULTIVO',CONVERT(BIGINT,problema_id),CONVERT(BIGINT,cultivo_id),nombre COLLATE DATABASE_DEFAULT,
 NULL,NULL FROM prod.GPProblema WHERE cultivo_id IS NOT NULL AND estado=1
 UNION ALL
 SELECT 'PROBLEMA_CRIANZA',CONVERT(BIGINT,problema_id),CONVERT(BIGINT,especie_pecuaria_id),nombre COLLATE DATABASE_DEFAULT,
 NULL,NULL FROM prod.GPProblema WHERE especie_pecuaria_id IS NOT NULL AND estado=1
 UNION ALL
 SELECT 'TRATAMIENTO',CONVERT(BIGINT,tratamiento_id),NULL,nombre COLLATE DATABASE_DEFAULT,
 descripcion,NULL FROM prod.GPTratamiento WHERE estado=1
 UNION ALL
 SELECT 'RELACION',CONVERT(BIGINT,tratamiento_id),CONVERT(BIGINT,problema_id),CONVERT(NVARCHAR(160),NULL),NULL,NULL
 FROM prod.GPProblemaTratamiento
 ORDER BY tipo,nombre;
END;
GO
IF OBJECT_ID(N'prod.PA_GP_Catalogo_Upd_Registro', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Catalogo_Upd_Registro;
GO
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
