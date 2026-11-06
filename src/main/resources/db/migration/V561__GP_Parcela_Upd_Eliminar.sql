-- DESCO GP | migracion aditiva, historiales inmutables.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_Parcela_Upd_Eliminar;
GO
IF OBJECT_ID(N'prod.PA_GP_Parcela_Upd_Eliminar', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Parcela_Upd_Eliminar;
GO
CREATE PROCEDURE prod.PA_GP_Parcela_Upd_Eliminar
@Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Parcela BIGINT,@Motivo NVARCHAR(1000),@Solicitud UNIQUEIDENTIFIER
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;

 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_RETIRAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF @Solicitud IS NULL OR LEN(TRIM(COALESCE(@Motivo,N'')))<3 THROW 51103,N'Indique el motivo.',1;
 BEGIN TRAN; BEGIN TRY
  IF EXISTS(SELECT 1 FROM prod.GPBajaLogica WHERE solicitud_id=@Solicitud AND tipo='PARCELA' AND registro_id=@Parcela)
   BEGIN COMMIT; SELECT @Parcela AS id; RETURN; END;
  IF EXISTS(SELECT 1 FROM prod.GPBajaLogica WHERE solicitud_id=@Solicitud) THROW 51103,N'Solicitud ya utilizada.',1;
  IF NOT EXISTS(SELECT 1 FROM prod.Parcela P WITH(UPDLOCK,HOLDLOCK)
  JOIN prod.PredioAmbito B ON B.predio_id=P.predio_id AND B.uot_id=@Uot AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
  WHERE P.parcela_id=@Parcela AND P.estado=1) THROW 51102,N'Parcela no disponible.',1;
  UPDATE C SET estado=0 FROM prod.GPCenso C JOIN prod.GPActividad A ON A.actividad_id=C.actividad_id WHERE A.parcela_id=@Parcela AND C.estado=1;
  UPDATE E SET estado=0 FROM prod.GPEvento E JOIN prod.GPActividad A ON A.actividad_id=E.actividad_id WHERE A.parcela_id=@Parcela AND E.estado=1;
  UPDATE R SET estado=0 FROM prod.GPActividadRevision R JOIN prod.GPActividad A ON A.actividad_id=R.actividad_id WHERE A.parcela_id=@Parcela AND R.estado=1;
  UPDATE I SET estado=0 FROM prod.GPIncidencia I JOIN prod.GPActividad A ON A.actividad_id=I.actividad_id WHERE A.parcela_id=@Parcela AND I.estado=1;
  UPDATE T SET estado=0 FROM prod.GPIncidenciaTratamiento T JOIN prod.GPIncidencia I ON I.incidencia_id=T.incidencia_id JOIN prod.GPActividad A ON A.actividad_id=I.actividad_id WHERE A.parcela_id=@Parcela AND T.estado=1;
  UPDATE prod.GPActividad SET estado=0 WHERE parcela_id=@Parcela AND estado=1;
  UPDATE prod.Parcela SET estado=0 WHERE parcela_id=@Parcela AND estado=1;
  INSERT prod.GPBajaLogica(tipo,registro_id,motivo,usuario_id,solicitud_id)
  VALUES('PARCELA',@Parcela,TRIM(@Motivo),@Usuario,@Solicitud);
  COMMIT; SELECT @Parcela AS id;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
END;
GO
