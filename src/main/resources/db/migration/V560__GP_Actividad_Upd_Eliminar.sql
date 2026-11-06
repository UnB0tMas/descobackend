-- DESCO GP | migracion aditiva, historiales inmutables.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_Actividad_Upd_Eliminar;
GO
IF OBJECT_ID(N'prod.PA_GP_Actividad_Upd_Eliminar', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Actividad_Upd_Eliminar;
GO
CREATE PROCEDURE prod.PA_GP_Actividad_Upd_Eliminar
@Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT,@Motivo NVARCHAR(1000),@Solicitud UNIQUEIDENTIFIER
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;

 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_RETIRAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF @Solicitud IS NULL OR LEN(TRIM(COALESCE(@Motivo,N'')))<3 THROW 51103,N'Indique el motivo de eliminación.',1;
 BEGIN TRAN; BEGIN TRY
  DECLARE @Parcela BIGINT;
  IF EXISTS(SELECT 1 FROM prod.GPBajaLogica WHERE solicitud_id=@Solicitud AND tipo='ACTIVIDAD' AND registro_id=@Actividad)
   BEGIN COMMIT; SELECT @Actividad AS id; RETURN; END;
  IF EXISTS(SELECT 1 FROM prod.GPBajaLogica WHERE solicitud_id=@Solicitud) THROW 51103,N'Solicitud ya utilizada.',1;
  SELECT @Parcela=A.parcela_id FROM prod.GPActividad A
   JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.estado=1
   JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
   WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot AND A.estado=1;
  IF @Parcela IS NULL THROW 51102,N'Actividad no disponible.',1;
  SELECT @Parcela=parcela_id FROM prod.Parcela WITH(UPDLOCK,HOLDLOCK) WHERE parcela_id=@Parcela;
  UPDATE prod.GPCenso SET estado=0 WHERE actividad_id=@Actividad AND estado=1;
  UPDATE prod.GPEvento SET estado=0 WHERE actividad_id=@Actividad AND estado=1;
  UPDATE prod.GPActividadRevision SET estado=0 WHERE actividad_id=@Actividad AND estado=1;
  UPDATE prod.GPIncidencia SET estado=0 WHERE actividad_id=@Actividad AND estado=1;
  UPDATE T SET estado=0 FROM prod.GPIncidenciaTratamiento T JOIN prod.GPIncidencia I ON I.incidencia_id=T.incidencia_id WHERE I.actividad_id=@Actividad AND T.estado=1;
  UPDATE prod.GPActividad SET estado=0 WHERE actividad_id=@Actividad AND estado=1;
  INSERT prod.GPBajaLogica(tipo,registro_id,motivo,usuario_id,solicitud_id)
    VALUES('ACTIVIDAD',@Actividad,TRIM(@Motivo),@Usuario,@Solicitud);
  COMMIT; SELECT @Actividad AS id;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
END;
GO
