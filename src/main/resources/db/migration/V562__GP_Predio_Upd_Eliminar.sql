-- DESCO GP | migracion aditiva, historiales inmutables.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_Predio_Upd_Eliminar;
GO
IF OBJECT_ID(N'prod.PA_GP_Predio_Upd_Eliminar', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Predio_Upd_Eliminar;
GO
CREATE PROCEDURE prod.PA_GP_Predio_Upd_Eliminar
@Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Predio BIGINT,@Motivo NVARCHAR(1000),@Solicitud UNIQUEIDENTIFIER
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;

 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'PREDIOS_RETIRAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF @Solicitud IS NULL OR LEN(TRIM(COALESCE(@Motivo,N'')))<3 THROW 51103,N'Indique el motivo.',1;
 BEGIN TRAN; BEGIN TRY
  IF EXISTS(SELECT 1 FROM prod.GPBajaLogica WHERE solicitud_id=@Solicitud AND tipo='PREDIO' AND registro_id=@Predio)
   BEGIN COMMIT; SELECT @Predio AS id; RETURN; END;
  IF EXISTS(SELECT 1 FROM prod.GPBajaLogica WHERE solicitud_id=@Solicitud) THROW 51103,N'Solicitud ya utilizada.',1;
  IF NOT EXISTS(SELECT 1 FROM prod.PredioAmbito B WITH(UPDLOCK,HOLDLOCK)
     JOIN prod.Predio P ON P.predio_id=B.predio_id AND P.estado=1
     WHERE B.predio_id=@Predio AND B.uot_id=@Uot AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL)
     THROW 51102,N'Predio fuera del ámbito general.',1;
  IF EXISTS(SELECT 1 FROM prod.PredioAmbito WHERE predio_id=@Predio AND estado=1 AND
      (uot_id<>@Uot OR convenio_uot_organizacion_id IS NOT NULL))
      THROW 51103,N'El predio está compartido con otro ámbito. Revise sus vinculaciones antes de retirarlo.',1;
  IF EXISTS(SELECT 1 FROM campo.SalidaDestinoE2 D JOIN campo.SalidaE2 E ON E.salida_campo_id=D.salida_campo_id
    WHERE D.predio_id=@Predio AND E.estado IN('APROBADA','EN_EJECUCION','EN_RETORNO'))
    THROW 51103,N'El predio tiene salidas de campo vigentes.',1;
  SELECT @Predio=predio_id FROM prod.Predio WITH(UPDLOCK,HOLDLOCK) WHERE predio_id=@Predio;
  UPDATE C SET estado=0 FROM prod.GPCenso C JOIN prod.GPActividad A ON A.actividad_id=C.actividad_id WHERE A.predio_id=@Predio AND C.estado=1;
  UPDATE E SET estado=0 FROM prod.GPEvento E JOIN prod.GPActividad A ON A.actividad_id=E.actividad_id WHERE A.predio_id=@Predio AND E.estado=1;
  UPDATE R SET estado=0 FROM prod.GPActividadRevision R JOIN prod.GPActividad A ON A.actividad_id=R.actividad_id WHERE A.predio_id=@Predio AND R.estado=1;
  UPDATE I SET estado=0 FROM prod.GPIncidencia I JOIN prod.GPActividad A ON A.actividad_id=I.actividad_id WHERE A.predio_id=@Predio AND I.estado=1;
  UPDATE T SET estado=0 FROM prod.GPIncidenciaTratamiento T JOIN prod.GPIncidencia I ON I.incidencia_id=T.incidencia_id JOIN prod.GPActividad A ON A.actividad_id=I.actividad_id WHERE A.predio_id=@Predio AND T.estado=1;
  UPDATE A SET estado=0 FROM prod.GPActividad A WHERE A.predio_id=@Predio AND A.estado=1;
  UPDATE P SET estado=0 FROM prod.Parcela P WHERE P.predio_id=@Predio AND P.estado=1;
  UPDATE prod.PredioAmbito SET estado=0 WHERE predio_id=@Predio AND uot_id=@Uot AND estado=1;
  UPDATE prod.Predio SET estado=0 WHERE predio_id=@Predio AND estado=1;
  INSERT prod.GPBajaLogica(tipo,registro_id,motivo,usuario_id,solicitud_id)
  VALUES('PREDIO',@Predio,TRIM(@Motivo),@Usuario,@Solicitud);
  COMMIT; SELECT @Predio AS id;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
END;
GO
