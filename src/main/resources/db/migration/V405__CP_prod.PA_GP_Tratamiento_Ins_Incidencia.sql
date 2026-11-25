IF OBJECT_ID(N'[prod].[PA_GP_Tratamiento_Ins_Incidencia]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_GP_Tratamiento_Ins_Incidencia];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_GP_Tratamiento_Ins_Incidencia
' Descripción            : Registra gp tratamiento para incidencia.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_GP_Tratamiento_Ins_Incidencia
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT,
 @Incidencia BIGINT,@Tratamiento INT,@Descripcion NVARCHAR(2000),@FechaFinPrevista DATETIME2(0)=NULL,
 @Solicitud UNIQUEIDENTIFIER,@Programacion BIGINT=NULL,@Utilizada DECIMAL(19,3)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'SANIDAD_CREAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF @Solicitud IS NULL OR LEN(TRIM(COALESCE(@Descripcion,N'')))<3 THROW 51103,N'Explique la actuación.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPActividad A
 JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.estado=1
 JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
 WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot AND A.estado=1 AND A.estado_proceso='ACTIVA')
 THROW 51102,N'Actividad no disponible.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPIncidencia I
 JOIN prod.GPProblemaTratamiento R ON R.problema_id=I.problema_id AND R.tratamiento_id=@Tratamiento
 JOIN prod.GPTratamiento T ON T.tratamiento_id=R.tratamiento_id AND T.estado=1
 WHERE I.incidencia_id=@Incidencia AND I.actividad_id=@Actividad AND I.estado_seguimiento='ABIERTA')
 THROW 51103,N'La incidencia no está abierta o el tratamiento no corresponde a la enfermedad.',1;
 IF @FechaFinPrevista IS NOT NULL AND @FechaFinPrevista<SYSUTCDATETIME()
 THROW 51103,N'La fecha final prevista debe ser futura.',1;
 BEGIN TRAN;
 BEGIN TRY
  DECLARE @Id BIGINT;
  SELECT @Id=evento_id FROM prod.GPEvento WITH(UPDLOCK,HOLDLOCK) WHERE solicitud_id=@Solicitud;
  IF @Id IS NULL
  BEGIN
   DECLARE @Bloqueo BIGINT;
   SELECT @Bloqueo=incidencia_id FROM prod.GPIncidencia WITH(UPDLOCK,HOLDLOCK) WHERE incidencia_id=@Incidencia AND estado_seguimiento='ABIERTA';
   IF @Bloqueo IS NULL THROW 51103,N'La incidencia fue cerrada.',1;
   INSERT prod.GPEvento(actividad_id,tipo,problema_id,tratamiento_id,respuesta_a_id,observacion,fecha_hecho,
      usuario_creacion_id,solicitud_id)
   SELECT @Actividad,'TRATAMIENTO',problema_id,@Tratamiento,@Incidencia,TRIM(@Descripcion),SYSUTCDATETIME(),@Usuario,@Solicitud
   FROM prod.GPIncidencia WHERE incidencia_id=@Incidencia;
   SET @Id=CONVERT(BIGINT,SCOPE_IDENTITY());
   INSERT prod.GPIncidenciaTratamiento(evento_id,incidencia_id,tratamiento_id,fecha_fin_prevista)
   VALUES(@Id,@Incidencia,@Tratamiento,@FechaFinPrevista);
  END
  ELSE IF NOT EXISTS(SELECT 1 FROM prod.GPIncidenciaTratamiento WHERE evento_id=@Id AND incidencia_id=@Incidencia)
   THROW 51103,N'La solicitud corresponde a otra actuación.',1;
  IF @Programacion IS NOT NULL
  BEGIN
    DECLARE @SesionId BIGINT,@Empleado BIGINT;
    SELECT @SesionId=sesion_usuario_id FROM seg.SesionUsuario WHERE sesion_publica_id=@Sesion AND usuario_id=@Usuario;
    SELECT @Empleado=persona_id FROM seg.Usuario WHERE usuario_id=@Usuario;
    EXEC logistica.PA_ConsumoTecnico_Registrar @SesionId,@Usuario,@Empleado,@Programacion,@Utilizada,'GP',@Id,@Solicitud;
  END
  ELSE IF @Utilizada IS NOT NULL OR EXISTS(SELECT 1 FROM logistica.UsoProductoTecnico WHERE tipo_origen='GP' AND registro_id=@Id) THROW 51103,N'Seleccione el producto entregado registrado en la solicitud.',1;
  COMMIT; SELECT @Id AS id;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
END;
GO
