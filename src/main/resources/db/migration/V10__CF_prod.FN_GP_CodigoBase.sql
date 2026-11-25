IF OBJECT_ID(N'[prod].[FN_GP_CodigoBase]') IS NOT NULL
    DROP FUNCTION [prod].[FN_GP_CodigoBase];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Función       : prod.FN_GP_CodigoBase
' Descripción            : Devuelve el resultado de gp codigo base.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
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
