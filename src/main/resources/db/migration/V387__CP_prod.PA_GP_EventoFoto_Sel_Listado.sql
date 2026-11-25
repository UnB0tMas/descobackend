IF OBJECT_ID(N'[prod].[PA_GP_EventoFoto_Sel_Listado]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_GP_EventoFoto_Sel_Listado];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_GP_EventoFoto_Sel_Listado
' Descripción            : Consulta información de GP Evento Foto (listado).
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE PROCEDURE prod.PA_GP_EventoFoto_Sel_Listado
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'PREDIOS_VER',0)<>1
    THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPActividad A JOIN prod.PredioAmbito B
   ON B.predio_id=A.predio_id AND B.uot_id=@Uot AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
   WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot)
    THROW 51102,N'Actividad fuera del ámbito general.',1;
 SELECT F.evento_id AS eventoId,F.foto_id AS fotoId
 FROM prod.GPEvento E JOIN prod.GPEventoFoto F ON F.evento_id=E.evento_id
 WHERE E.actividad_id=@Actividad ORDER BY F.evento_id,F.foto_id;
END;
GO
