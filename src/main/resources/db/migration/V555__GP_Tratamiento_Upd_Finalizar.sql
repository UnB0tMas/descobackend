-- DESCO GP | migracion aditiva, historiales inmutables.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_Tratamiento_Upd_Finalizar;
GO
IF OBJECT_ID(N'prod.PA_GP_Tratamiento_Upd_Finalizar', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Tratamiento_Upd_Finalizar;
GO
CREATE PROCEDURE prod.PA_GP_Tratamiento_Upd_Finalizar
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Evento BIGINT,
 @Descripcion NVARCHAR(1000),@Solicitud UNIQUEIDENTIFIER
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;

 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'SANIDAD_CREAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF @Solicitud IS NULL OR LEN(TRIM(COALESCE(@Descripcion,N'')))<3 THROW 51103,N'Indique el resultado del tratamiento.',1;
 BEGIN TRAN;
 BEGIN TRY
  DECLARE @Act BIGINT;
  SELECT @Act=I.actividad_id FROM prod.GPIncidenciaTratamiento T
   JOIN prod.GPIncidencia I ON I.incidencia_id=T.incidencia_id
   JOIN prod.GPActividad A ON A.actividad_id=I.actividad_id AND A.estado=1
   JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.estado=1
   JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
   WHERE T.evento_id=@Evento AND A.uot_id=@Uot;
  IF @Act IS NULL THROW 51102,N'Tratamiento no disponible.',1;
  IF EXISTS(SELECT 1 FROM prod.GPIncidenciaTratamiento WHERE solicitud_cierre=@Solicitud AND evento_id<>@Evento)
   THROW 51103,N'La solicitud se utilizó en otro tratamiento.',1;
  UPDATE prod.GPIncidenciaTratamiento SET fecha_fin_real=SYSUTCDATETIME(),descripcion_cierre=TRIM(@Descripcion),
    usuario_cierre_id=@Usuario,solicitud_cierre=@Solicitud
   WHERE evento_id=@Evento AND fecha_fin_real IS NULL AND solicitud_cierre IS NULL;
  IF @@ROWCOUNT=0 AND NOT EXISTS(SELECT 1 FROM prod.GPIncidenciaTratamiento WHERE evento_id=@Evento AND solicitud_cierre=@Solicitud)
    THROW 51103,N'El tratamiento ya fue finalizado.',1;
  COMMIT; SELECT @Evento AS id;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
END;
GO
