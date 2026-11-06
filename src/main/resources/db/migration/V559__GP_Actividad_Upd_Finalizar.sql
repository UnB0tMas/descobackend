-- DESCO GP | migracion aditiva, historiales inmutables.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_Actividad_Upd_Finalizar;
GO
IF OBJECT_ID(N'prod.PA_GP_Actividad_Upd_Finalizar', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Actividad_Upd_Finalizar;
GO
CREATE PROCEDURE prod.PA_GP_Actividad_Upd_Finalizar
@Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT,@Motivo NVARCHAR(1000),@Solicitud UNIQUEIDENTIFIER
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;

 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_EDITAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF @Solicitud IS NULL OR LEN(TRIM(COALESCE(@Motivo,N'')))<3 THROW 51103,N'Indique el motivo de finalización.',1;
 BEGIN TRAN; BEGIN TRY
  DECLARE @Parcela BIGINT,@PrevEstado BIT,@Nombre NVARCHAR(120);
  SELECT @Parcela=A.parcela_id,@PrevEstado=A.estado,@Nombre=A.nombre FROM prod.GPActividad A
  JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.estado=1
  JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
  WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot AND A.estado=1;
  IF @Parcela IS NULL THROW 51102,N'Actividad no disponible.',1;
  IF EXISTS(SELECT 1 FROM prod.GPActividadRevision WHERE solicitud_id=@Solicitud AND actividad_id=@Actividad)
   BEGIN COMMIT; SELECT @Actividad AS id; RETURN; END;
  IF EXISTS(SELECT 1 FROM prod.GPActividadRevision WHERE solicitud_id=@Solicitud)
   THROW 51103,N'Solicitud reutilizada.',1;
  SELECT @Parcela=parcela_id FROM prod.Parcela WITH(UPDLOCK,HOLDLOCK) WHERE parcela_id=@Parcela;
  IF NOT EXISTS(SELECT 1 FROM prod.GPActividad WHERE actividad_id=@Actividad AND estado_proceso='ACTIVA')
   THROW 51103,N'La actividad ya fue finalizada.',1;
  IF EXISTS(SELECT 1 FROM prod.GPIncidencia WHERE actividad_id=@Actividad AND estado_seguimiento='ABIERTA')
   THROW 51103,N'Primero cierre las incidencias abiertas.',1;
  UPDATE prod.GPActividad SET estado_proceso='FINALIZADA' WHERE actividad_id=@Actividad;
  INSERT prod.GPActividadRevision(actividad_id,nombre_anterior,nombre_nuevo,estado_anterior,estado_nuevo,motivo,usuario_id,solicitud_id)
  VALUES(@Actividad,@Nombre,@Nombre,1,1,CONCAT(N'FINALIZACIÓN: ',TRIM(@Motivo)),@Usuario,@Solicitud);
  COMMIT; SELECT @Actividad AS id;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
END;
GO
