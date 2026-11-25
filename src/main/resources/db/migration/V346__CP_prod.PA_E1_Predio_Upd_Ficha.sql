IF OBJECT_ID(N'[prod].[PA_E1_Predio_Upd_Ficha]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_E1_Predio_Upd_Ficha];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_E1_Predio_Upd_Ficha
' Descripción            : Actualiza e1 predio para ficha.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_E1_Predio_Upd_Ficha
 @cJson NVARCHAR(MAX), @nPredio BIGINT, @nEntidad BIGINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 IF @@TRANCOUNT=0 THROW 51110,N'La ficha requiere transaccion E1.',1;
 DECLARE @nArea DECIMAL(10,4),@nAreaCult DECIMAL(10,4),@cRiego VARCHAR(30);
          SELECT @nArea=areaTotalHa,@nAreaCult=areaCultivableHa,@cRiego=tipoRiego
          FROM OPENJSON(@cJson,'$.datos') WITH(areaTotalHa DECIMAL(10,4),areaCultivableHa DECIMAL(10,4),tipoRiego VARCHAR(30));
          IF @nArea IS NOT NULL AND @nArea<=0 OR @nAreaCult IS NOT NULL AND (@nAreaCult<0 OR (@nArea IS NOT NULL AND @nAreaCult>@nArea))
             THROW 51061,N'Área inválida.',1;
          UPDATE prod.PredioVersion SET fecha_hasta=DATEADD(DAY,-1,CONVERT(DATE,SYSUTCDATETIME()))
          WHERE predio_id=@nPredio AND fecha_hasta IS NULL AND fecha_desde<CONVERT(DATE,SYSUTCDATETIME());
          UPDATE prod.PredioVersion SET estado=0 WHERE predio_id=@nPredio AND fecha_hasta IS NULL AND fecha_desde=CONVERT(DATE,SYSUTCDATETIME());
          DECLARE @nRevision INT;
          SELECT @nRevision=ISNULL(MAX(revision),0)+1 FROM prod.PredioVersion WITH(UPDLOCK,HOLDLOCK)
             WHERE predio_id=@nPredio AND fecha_desde=CONVERT(DATE,SYSUTCDATETIME());
          INSERT prod.PredioVersion(predio_id,area_total_ha,area_cultivable_ha,tipo_riego,fecha_desde,revision)
          VALUES(@nPredio,@nArea,@nAreaCult,NULLIF(@cRiego,''),CONVERT(DATE,SYSUTCDATETIME()),@nRevision);
          SET @nEntidad=SCOPE_IDENTITY();
END;
GO
