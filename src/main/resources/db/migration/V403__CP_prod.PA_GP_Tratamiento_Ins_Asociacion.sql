IF OBJECT_ID(N'[prod].[PA_GP_Tratamiento_Ins_Asociacion]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_GP_Tratamiento_Ins_Asociacion];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_GP_Tratamiento_Ins_Asociacion
' Descripción            : Registra gp tratamiento para asociacion.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE PROCEDURE prod.PA_GP_Tratamiento_Ins_Asociacion
@Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Problema INT,@Tratamiento INT
AS
BEGIN
 SET NOCOUNT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CATALOGOS_EDITAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS (SELECT 1 FROM prod.GPProblema WHERE problema_id=@Problema AND estado=1)
    OR NOT EXISTS (SELECT 1 FROM prod.GPTratamiento WHERE tratamiento_id=@Tratamiento AND estado=1)
     THROW 51103,N'Enfermedad o tratamiento no disponible.',1;
 IF EXISTS (SELECT 1 FROM prod.GPProblemaTratamiento WHERE tratamiento_id=@Tratamiento AND problema_id<>@Problema)
     THROW 51103,N'El tratamiento ya pertenece a otra enfermedad.',1;
 IF NOT EXISTS (SELECT 1 FROM prod.GPProblemaTratamiento WHERE problema_id=@Problema AND tratamiento_id=@Tratamiento)
     INSERT prod.GPProblemaTratamiento(problema_id,tratamiento_id) VALUES (@Problema,@Tratamiento);
 SELECT CAST(@Tratamiento AS BIGINT) AS id;
END;
GO
