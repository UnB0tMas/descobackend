IF OBJECT_ID(N'[prod].[PA_GP_CensoVariedad_Sel_Historial]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_GP_CensoVariedad_Sel_Historial];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_GP_CensoVariedad_Sel_Historial
' Descripción            : Consulta información de GP Censo Variedad (historial).
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE PROCEDURE prod.PA_GP_CensoVariedad_Sel_Historial
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CENSOS_LISTAR',0)<>1
   THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPActividad A JOIN prod.PredioAmbito B
   ON B.predio_id=A.predio_id AND B.uot_id=@Uot AND B.estado=1
    AND B.convenio_uot_organizacion_id IS NULL
   WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot)
   THROW 51102,N'Actividad fuera del ámbito general.',1;
 SELECT C.censo_id AS censoId,V.variedad_cultivo_id AS variedadId,
   V.nombre,D.superficie_m2 AS superficieM2
 FROM prod.GPCenso C JOIN prod.GPCensoVariedad D ON D.censo_id=C.censo_id
 JOIN prod.VariedadCultivo V ON V.variedad_cultivo_id=D.variedad_cultivo_id
 WHERE C.actividad_id=@Actividad ORDER BY C.censo_id DESC,V.nombre;
END;
GO
