SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_Evento_Ins_Registro;
GO
IF OBJECT_ID(N'prod.PA_GP_Evento_Ins_Registro', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Evento_Ins_Registro;
GO
CREATE PROCEDURE prod.PA_GP_Evento_Ins_Registro
@Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT,@Tipo VARCHAR(20),@Problema INT=NULL,@Tratamiento INT=NULL,@Responde BIGINT=NULL,@Observacion NVARCHAR(2000),@Fecha DATETIME2(0),@Afectados INT=NULL,@Aproximado BIT=NULL,@Solicitud UNIQUEIDENTIFIER
AS
BEGIN
  SET NOCOUNT ON;
-- Cada llamada registra exactamente un evento inmutable de una sola actividad.
 DECLARE @Permiso VARCHAR(70)=CASE @Tipo WHEN 'INCIDENCIA' THEN 'SANIDAD_CREAR' WHEN 'TRATAMIENTO' THEN 'SANIDAD_CREAR' WHEN 'EVALUACION' THEN 'EVALUACIONES_CREAR' ELSE 'PREDIOS_EDITAR' END;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,@Permiso,1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPActividad A JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.predio_id=A.predio_id JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot AND B.convenio_uot_organizacion_id IS NULL AND B.estado=1 WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot) THROW 51102,N'Actividad fuera del ámbito general.',1;
 IF @Tipo NOT IN('OBSERVACION','INCIDENCIA','TRATAMIENTO','EVALUACION','RESPUESTA') OR LEN(TRIM(COALESCE(@Observacion,N'')))<3 OR @Fecha IS NULL THROW 51103,N'Evento inválido.',1;
 IF @Tipo='RESPUESTA' AND (@Responde IS NULL OR NOT EXISTS(SELECT 1 FROM prod.GPEvento WHERE evento_id=@Responde AND actividad_id=@Actividad)) THROW 51103,N'La respuesta debe pertenecer al mismo historial.',1;
 IF @Tipo<>'RESPUESTA' AND @Responde IS NOT NULL THROW 51103,N'Referencia no válida.',1;
 IF @Problema IS NOT NULL AND NOT EXISTS (
   SELECT 1 FROM prod.GPProblema P JOIN prod.GPActividad A ON A.actividad_id=@Actividad
   WHERE P.problema_id=@Problema AND P.estado=1
     AND ((A.rubro='CULTIVO' AND P.cultivo_id=A.cultivo_id) OR (A.rubro='CRIANZA' AND P.especie_pecuaria_id=A.especie_pecuaria_id)))
      THROW 51103,N'Problema no asociado a esta especie.',1;
 IF @Tipo NOT IN('INCIDENCIA','TRATAMIENTO') AND @Problema IS NOT NULL THROW 51103,N'Problema no aplicable a este tipo de evento.',1;
 IF @Tipo='INCIDENCIA' AND @Problema IS NULL THROW 51103,N'Seleccione el problema detectado.',1;
 IF @Tipo='TRATAMIENTO' AND (@Problema IS NULL OR @Tratamiento IS NULL OR NOT EXISTS(
    SELECT 1 FROM prod.GPProblemaTratamiento X JOIN prod.GPTratamiento T ON T.tratamiento_id=X.tratamiento_id AND T.estado=1
    WHERE X.problema_id=@Problema AND X.tratamiento_id=@Tratamiento)) THROW 51103,N'Tratamiento no asociado al problema.',1;
 IF @Tipo NOT IN('TRATAMIENTO') AND @Tratamiento IS NOT NULL THROW 51103,N'Tratamiento solo aplicable a un evento de tratamiento.',1;
 IF (@Afectados IS NULL AND @Aproximado IS NOT NULL) OR (@Afectados IS NOT NULL AND (@Afectados<0 OR @Aproximado IS NULL))
   THROW 51103,N'El conteo afectado requiere valor y precisión coherentes.',1;
 IF @Tipo NOT IN('INCIDENCIA','EVALUACION','TRATAMIENTO') AND @Afectados IS NOT NULL
   THROW 51103,N'La cantidad afectada solo corresponde a un control sanitario o evaluación.',1;
 SET XACT_ABORT ON;
 BEGIN TRAN;
 DECLARE @Id BIGINT;
 SELECT @Id=evento_id FROM prod.GPEvento WITH(UPDLOCK,HOLDLOCK) WHERE solicitud_id=@Solicitud;
 IF @Id IS NULL
 BEGIN
   INSERT prod.GPEvento(actividad_id,tipo,problema_id,tratamiento_id,respuesta_a_id,observacion,fecha_hecho,cantidad_afectada,afectados_aproximado,usuario_creacion_id,solicitud_id)
   VALUES(@Actividad,@Tipo,@Problema,@Tratamiento,@Responde,TRIM(@Observacion),@Fecha,@Afectados,@Aproximado,@Usuario,@Solicitud);
   SET @Id=SCOPE_IDENTITY();
 END;
 COMMIT;
 SELECT @Id AS id;
END;
GO
