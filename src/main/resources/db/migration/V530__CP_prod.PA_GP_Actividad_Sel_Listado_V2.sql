SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_Actividad_Sel_Listado;
GO
IF OBJECT_ID(N'prod.PA_GP_Actividad_Sel_Listado', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Actividad_Sel_Listado;
GO
CREATE PROCEDURE prod.PA_GP_Actividad_Sel_Listado
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Parcela BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_VER',0)<>1
    THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.Parcela P JOIN prod.PredioAmbito B
    ON B.predio_id=P.predio_id AND B.uot_id=@Uot AND B.estado=1
    AND B.convenio_uot_organizacion_id IS NULL WHERE P.parcela_id=@Parcela)
    THROW 51102,N'Parcela fuera del ámbito general.',1;
 SELECT A.actividad_id AS actividadId,A.parcela_id AS parcelaId,
   A.predio_id AS predioId,A.rubro,A.cultivo_id AS cultivoId,
   A.especie_pecuaria_id AS especieId,
   COALESCE(A.nombre COLLATE DATABASE_DEFAULT,C.nombre COLLATE DATABASE_DEFAULT,E.nombre COLLATE DATABASE_DEFAULT) AS nombre,
   A.fecha_inicio AS fechaInicio,A.estado,
   COALESCE(X.cantidad_aproximada,X.cantidad) AS cantidadAproximada,
   X.cantidad_exacta AS cantidadExacta,X.censo_id AS versionActualId,
   X.fecha AS fechaUltimoCenso
 FROM prod.GPActividad A
 LEFT JOIN prod.Cultivo C ON C.cultivo_id=A.cultivo_id
 LEFT JOIN prod.EspeciePecuaria E ON E.especie_pecuaria_id=A.especie_pecuaria_id
 OUTER APPLY(SELECT TOP(1) N.cantidad_aproximada,N.cantidad_exacta,
  N.cantidad,N.censo_id,N.fecha FROM prod.GPCenso N
  WHERE N.actividad_id=A.actividad_id ORDER BY N.fecha_registro DESC,N.censo_id DESC) X
 WHERE A.parcela_id=@Parcela AND A.uot_id=@Uot
 ORDER BY A.estado DESC,A.actividad_id DESC;
END;
GO
