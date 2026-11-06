SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_Foto_Sel_Archivo;
GO
IF OBJECT_ID(N'prod.PA_GP_Foto_Sel_Archivo', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Foto_Sel_Archivo;
GO
CREATE PROCEDURE prod.PA_GP_Foto_Sel_Archivo
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Foto BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'PREDIOS_VER',0)<>1
    THROW 51101,N'Acceso no autorizado.',1;
 SELECT F.archivo_interno AS archivoInterno,F.mime_type AS mimeType
 FROM prod.GPEventoFoto F
 JOIN prod.GPEvento E ON E.evento_id=F.evento_id
 JOIN prod.GPActividad A ON A.actividad_id=E.actividad_id AND A.uot_id=@Uot
 JOIN prod.PredioAmbito P ON P.predio_id=A.predio_id AND P.uot_id=@Uot
    AND P.estado=1 AND P.convenio_uot_organizacion_id IS NULL
 WHERE F.foto_id=@Foto;
END;
GO
