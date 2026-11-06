SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_Foto_Ins_Registro;
GO
IF OBJECT_ID(N'prod.PA_GP_Foto_Ins_Registro', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Foto_Ins_Registro;
GO
CREATE PROCEDURE prod.PA_GP_Foto_Ins_Registro
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Evento BIGINT,
 @Archivo VARCHAR(65),@Mime VARCHAR(30),@Tamano BIGINT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF @Tamano NOT BETWEEN 1 AND 5242880 OR @Mime NOT IN('image/jpeg','image/png','image/webp')
    THROW 51103,N'La fotografía no cumple las restricciones.',1;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'SANIDAD_CREAR',1)<>1
    AND prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'EVALUACIONES_CREAR',1)<>1
    AND prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'PREDIOS_EDITAR',1)<>1
    THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPEvento E
    JOIN prod.GPActividad A ON A.actividad_id=E.actividad_id AND A.uot_id=@Uot
    JOIN prod.PredioAmbito P ON P.predio_id=A.predio_id AND P.uot_id=@Uot AND P.estado=1 AND P.convenio_uot_organizacion_id IS NULL
    WHERE E.evento_id=@Evento AND E.usuario_creacion_id=@Usuario)
    THROW 51102,N'Actuación no autorizada para asociar fotografía.',1;
 BEGIN TRAN;
 IF EXISTS(SELECT 1 FROM prod.GPEventoFoto WITH(UPDLOCK,HOLDLOCK) WHERE evento_id=@Evento)
 BEGIN ROLLBACK; THROW 51103,N'La actuación ya tiene fotografía.',1; END;
 INSERT prod.GPEventoFoto(evento_id,archivo_interno,mime_type,tamano_bytes,usuario_creacion_id)
 VALUES(@Evento,@Archivo,@Mime,@Tamano,@Usuario);
 SELECT CONVERT(BIGINT,SCOPE_IDENTITY()) AS id;
 COMMIT;
END;
GO
