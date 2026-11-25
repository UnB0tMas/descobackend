IF OBJECT_ID(N'[prod].[PA_GP_Incidencia_Upd_Retirar]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_GP_Incidencia_Upd_Retirar];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_GP_Incidencia_Upd_Retirar
' Descripción            : Gestiona gp incidencia: retirar.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_GP_Incidencia_Upd_Retirar
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Incidencia BIGINT,
 @Motivo NVARCHAR(1000),@Solicitud UNIQUEIDENTIFIER
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'SANIDAD_RETIRAR',1)<>1
  THROW 51101,N'Acceso no autorizado.',1;
 IF @Solicitud IS NULL OR LEN(TRIM(COALESCE(@Motivo,N'')))<3
  THROW 51103,N'Indique el motivo del retiro.',1;
 BEGIN TRAN;
 BEGIN TRY
  DECLARE @Revision BIGINT,@Actividad BIGINT,@Problema INT,@Descripcion NVARCHAR(2000),
      @AfectadaM2 DECIMAL(14,2),@Animales INT;
  SELECT @Revision=revision_id FROM prod.GPIncidenciaRevision WITH(UPDLOCK,HOLDLOCK)
    WHERE solicitud_id=@Solicitud;
  IF @Revision IS NOT NULL
  BEGIN
    IF NOT EXISTS(SELECT 1 FROM prod.GPIncidenciaRevision WHERE revision_id=@Revision
       AND incidencia_id=@Incidencia AND accion='RETIRO')
      THROW 51103,N'La solicitud se utilizó en otra operación.',1;
    COMMIT; SELECT @Incidencia AS id; RETURN;
  END;
  SELECT @Actividad=I.actividad_id,@Problema=I.problema_id,@Descripcion=E.observacion,
      @AfectadaM2=I.afectada_m2,@Animales=I.afectados_animales
  FROM prod.GPIncidencia I WITH(UPDLOCK,HOLDLOCK)
  JOIN prod.GPEvento E ON E.evento_id=I.incidencia_id AND E.estado=1
  JOIN prod.GPActividad A ON A.actividad_id=I.actividad_id AND A.estado=1 AND A.estado_proceso='ACTIVA'
  JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.estado=1
  JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot
    AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
  WHERE I.incidencia_id=@Incidencia AND I.estado=1 AND I.estado_seguimiento='ABIERTA'
      AND A.uot_id=@Uot;
  IF @Actividad IS NULL
    THROW 51102,N'Solo es posible retirar incidencias abiertas del ámbito autorizado.',1;
  -- Nunca se deshace por esta vía una pérdida ya consolidada en un censo.
  INSERT prod.GPIncidenciaRevision(incidencia_id,accion,motivo,usuario_id,
       problema_anterior,problema_nuevo,afectada_anterior,afectada_nueva,
       animales_anteriores,animales_nuevos,descripcion_anterior,descripcion_nueva,solicitud_id)
  VALUES(@Incidencia,'RETIRO',TRIM(@Motivo),@Usuario,
       @Problema,@Problema,@AfectadaM2,@AfectadaM2,@Animales,@Animales,
       @Descripcion,@Descripcion,@Solicitud);
  UPDATE prod.GPIncidencia SET estado=0 WHERE incidencia_id=@Incidencia;
  UPDATE prod.GPEvento SET estado=0 WHERE evento_id=@Incidencia;
  UPDATE E SET estado=0 FROM prod.GPEvento E
    JOIN prod.GPIncidenciaTratamiento T ON T.evento_id=E.evento_id
    WHERE T.incidencia_id=@Incidencia AND E.estado=1;
  UPDATE prod.GPIncidenciaTratamiento SET estado=0
    WHERE incidencia_id=@Incidencia AND estado=1;
  INSERT prod.GPEvento(actividad_id,tipo,observacion,fecha_hecho,usuario_creacion_id,solicitud_id)
  VALUES(@Actividad,'OBSERVACION',CONCAT(N'Retiro lógico de incidencia #',@Incidencia,
    N'. Motivo: ',TRIM(@Motivo)),SYSUTCDATETIME(),@Usuario,NEWID());
  COMMIT; SELECT @Incidencia AS id;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
END;
GO
