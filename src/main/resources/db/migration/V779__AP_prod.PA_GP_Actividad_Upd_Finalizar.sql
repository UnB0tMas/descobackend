IF OBJECT_ID(N'[prod].[PA_GP_Actividad_Upd_Finalizar]', N'P') IS NOT NULL
    DROP PROCEDURE prod.PA_GP_Actividad_Upd_Finalizar;
GO

-- Control de actuaciones productivas por sesión, UOT y predio.
CREATE PROCEDURE prod.PA_GP_Actividad_Upd_Finalizar
@Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT,@Motivo NVARCHAR(1000),@Solicitud UNIQUEIDENTIFIER
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;

 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_EDITAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
    DECLARE @PredioControlGP BIGINT;
    SET @PredioControlGP = (SELECT A.predio_id FROM prod.GPActividad A WHERE A.actividad_id = @Actividad AND A.uot_id = @Uot);
    IF @PredioControlGP IS NULL OR prod.FN_GP_PuedeActuar(@Sesion, @Usuario, @Uot, @PredioControlGP) <> 1
        THROW 51101, N'Debe iniciar una visita al predio desde una salida aprobada.', 1;

 IF @Solicitud IS NULL OR LEN(TRIM(COALESCE(@Motivo,N'')))<3 THROW 51103,N'Indique el motivo de finalización.',1;
 BEGIN TRAN; BEGIN TRY
  DECLARE @Parcela BIGINT,@PrevEstado BIT,@Nombre NVARCHAR(120),@Rubro VARCHAR(8),@AnimalesActuales INT;
  SELECT @Parcela=A.parcela_id,@PrevEstado=A.estado,@Nombre=A.nombre,@Rubro=A.rubro FROM prod.GPActividad A
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
  IF @Rubro='CRIANZA'
  BEGIN
    SELECT TOP (1) @AnimalesActuales=C.cantidad_exacta FROM prod.GPCenso C
     WHERE C.actividad_id=@Actividad AND C.estado=1 ORDER BY C.fecha_registro DESC,C.censo_id DESC;
    IF @AnimalesActuales IS NULL OR @AnimalesActuales<>0
     THROW 51103,N'La crianza aún tiene animales. Registre un censo de cero animales y su motivo antes de cerrarla.',1;
  END;
   -- Al finalizar un cultivo se cierran sus incidencias pendientes y tratamientos vigentes.
  -- La operación completa es atómica y no registra pérdidas o recuperación no declaradas.
  IF @Rubro='CULTIVO'
  BEGIN
    IF EXISTS(SELECT 1 FROM prod.GPIncidencia I WITH (UPDLOCK,HOLDLOCK)
              WHERE I.actividad_id=@Actividad AND I.estado=1 AND I.estado_seguimiento='ABIERTA')
    BEGIN
      IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'SANIDAD_CREAR',1)<>1
        THROW 51101,N'No tiene permiso para cerrar las incidencias de esta actividad.',1;
      DECLARE @Ahora DATETIME2(0)=SYSUTCDATETIME();
      UPDATE T
         SET T.fecha_fin_real=@Ahora,T.usuario_cierre_id=@Usuario
      FROM prod.GPIncidenciaTratamiento T WITH (UPDLOCK,HOLDLOCK)
      INNER JOIN prod.GPIncidencia I WITH (UPDLOCK,HOLDLOCK) ON I.incidencia_id=T.incidencia_id
      WHERE I.actividad_id=@Actividad AND I.estado=1 AND I.estado_seguimiento='ABIERTA'
        AND T.estado=1 AND T.fecha_fin_real IS NULL;
      UPDATE I
         SET I.estado_seguimiento='CERRADA',I.resultado='CIERRE_CICLO',
             I.perdida_m2=NULL,I.perdidos_animales=NULL,
             I.fecha_cierre=@Ahora,I.usuario_cierre_id=@Usuario,
             I.descripcion_cierre=CONCAT(N'Cierre por fin de ciclo agrícola. Motivo: ',TRIM(@Motivo)),
             I.solicitud_cierre=NEWID()
      FROM prod.GPIncidencia I WITH (UPDLOCK,HOLDLOCK)
      WHERE I.actividad_id=@Actividad AND I.estado=1 AND I.estado_seguimiento='ABIERTA';
    END;
  END
  ELSE IF EXISTS(SELECT 1 FROM prod.GPIncidencia WITH (UPDLOCK,HOLDLOCK)
            WHERE actividad_id=@Actividad AND estado=1 AND estado_seguimiento='ABIERTA')
      THROW 51103,N'Primero cierre las incidencias abiertas de la crianza.',1;
  UPDATE prod.GPActividad SET estado_proceso='FINALIZADA' WHERE actividad_id=@Actividad;
  INSERT prod.GPActividadRevision(actividad_id,nombre_anterior,nombre_nuevo,estado_anterior,estado_nuevo,motivo,usuario_id,solicitud_id)
  VALUES(@Actividad,@Nombre,@Nombre,1,1,CONCAT(N'FINALIZACIÓN: ',TRIM(@Motivo)),@Usuario,@Solicitud);
  COMMIT; SELECT @Actividad AS id;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
END;
GO
