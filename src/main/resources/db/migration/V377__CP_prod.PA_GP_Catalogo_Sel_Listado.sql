IF OBJECT_ID(N'[prod].[PA_GP_Catalogo_Sel_Listado]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_GP_Catalogo_Sel_Listado];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_GP_Catalogo_Sel_Listado
' Descripción            : Consulta información de GP Catalogo (listado).
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
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
 SELECT 'RELACION',CONVERT(BIGINT,R.tratamiento_id),CONVERT(BIGINT,R.problema_id),CONVERT(NVARCHAR(160),NULL),NULL,NULL
 FROM prod.GPProblemaTratamiento R
 JOIN prod.GPTratamiento T ON T.tratamiento_id=R.tratamiento_id AND T.estado=1
 JOIN prod.GPProblema P ON P.problema_id=R.problema_id AND P.estado=1
 ORDER BY tipo,nombre;
END;
GO
