-- DESCO GP | migracion aditiva, historiales inmutables.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_Incidencia_Upd_Cerrar;
GO
IF OBJECT_ID(N'prod.PA_GP_Incidencia_Upd_Cerrar', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Incidencia_Upd_Cerrar;
GO
CREATE PROCEDURE prod.PA_GP_Incidencia_Upd_Cerrar
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Incidencia BIGINT,
 @PerdidaM2 DECIMAL(14,2)=NULL,@PerdidosAnimales INT=NULL,
 @Descripcion NVARCHAR(2000),@Solicitud UNIQUEIDENTIFIER
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;

 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'SANIDAD_CREAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF @Solicitud IS NULL OR LEN(TRIM(COALESCE(@Descripcion,N'')))<3
 THROW 51103,N'Indique el resultado del control de la enfermedad.',1;
 BEGIN TRAN;
 BEGIN TRY
  DECLARE @Actividad BIGINT,@Parcela BIGINT,@Rubro VARCHAR(8),@Estado VARCHAR(12),
    @AfectadaM2 DECIMAL(14,2),@AfectadosAnimales INT,@ActualM2 DECIMAL(14,2),@ActualAnimales INT,
    @NuevaM2 DECIMAL(14,2),@NuevosAnimales INT,@Anterior BIGINT,@NuevaVersion BIGINT,
    @Finalizada BIT=0,@Resultado VARCHAR(18),@Ahora DATETIME2(0)=SYSUTCDATETIME();
  SELECT @Actividad=I.actividad_id,@Estado=I.estado_seguimiento,@AfectadaM2=I.afectada_m2,
     @AfectadosAnimales=I.afectados_animales,@Rubro=A.rubro,@Parcela=A.parcela_id
  FROM prod.GPIncidencia I JOIN prod.GPActividad A ON A.actividad_id=I.actividad_id
  JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.estado=1
  JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
  WHERE I.incidencia_id=@Incidencia AND A.uot_id=@Uot AND A.estado=1;
  IF @Actividad IS NULL THROW 51102,N'Incidencia fuera del ámbito.',1;
  IF EXISTS(SELECT 1 FROM prod.GPIncidencia WHERE solicitud_cierre=@Solicitud AND incidencia_id<>@Incidencia)
    THROW 51103,N'Solicitud de cierre utilizada para otra incidencia.',1;
  IF @Estado='CERRADA'
  BEGIN
   IF EXISTS(SELECT 1 FROM prod.GPIncidencia WHERE incidencia_id=@Incidencia AND solicitud_cierre=@Solicitud)
   BEGIN COMMIT; SELECT @Incidencia AS id; RETURN; END;
   THROW 51103,N'La incidencia ya fue cerrada.',1;
  END;
  SELECT @Parcela=parcela_id FROM prod.Parcela WITH(UPDLOCK,HOLDLOCK) WHERE parcela_id=@Parcela;
  SELECT @Estado=estado_seguimiento FROM prod.GPIncidencia WITH(UPDLOCK,HOLDLOCK) WHERE incidencia_id=@Incidencia;
  IF @Estado<>'ABIERTA' THROW 51103,N'La incidencia fue cerrada por otro técnico.',1;
  SELECT TOP(1) @ActualM2=superficie_exacta_m2,@ActualAnimales=cantidad_exacta,@Anterior=censo_id
    FROM prod.GPCenso WHERE actividad_id=@Actividad ORDER BY fecha_registro DESC,censo_id DESC;
  IF (@Rubro='CULTIVO' AND (@PerdidaM2 IS NULL OR @PerdidaM2<0 OR @PerdidaM2>@AfectadaM2 OR @PerdidaM2>COALESCE(@ActualM2,0) OR @PerdidosAnimales IS NOT NULL))
    OR (@Rubro='CRIANZA' AND (@PerdidosAnimales IS NULL OR @PerdidosAnimales<0 OR @PerdidosAnimales>@AfectadosAnimales OR @PerdidosAnimales>COALESCE(@ActualAnimales,0) OR @PerdidaM2 IS NOT NULL))
    THROW 51103,N'La pérdida supera la afectación o las existencias vigentes.',1;
  IF EXISTS(SELECT 1 FROM prod.GPIncidenciaTratamiento WHERE incidencia_id=@Incidencia AND fecha_fin_real IS NULL)
    THROW 51103,N'Finalice los tratamientos en curso antes de cerrar la incidencia.',1;
  SET @NuevaM2=CASE WHEN @Rubro='CULTIVO' THEN @ActualM2-@PerdidaM2 ELSE @ActualM2 END;
  SET @NuevosAnimales=CASE WHEN @Rubro='CRIANZA' THEN @ActualAnimales-@PerdidosAnimales ELSE @ActualAnimales END;
  SET @Finalizada=CASE WHEN @Rubro='CULTIVO' AND @NuevaM2=0 THEN 1
       WHEN @Rubro='CRIANZA' AND @NuevosAnimales=0 THEN 1 ELSE 0 END;
  IF @Finalizada=1 AND EXISTS(SELECT 1 FROM prod.GPIncidencia WHERE actividad_id=@Actividad AND incidencia_id<>@Incidencia AND estado_seguimiento='ABIERTA')
    THROW 51103,N'Cierre las demás incidencias abiertas antes de dar de baja la actividad.',1;
  SET @Resultado=CASE WHEN @Finalizada=1 THEN 'PERDIDA_TOTAL'
    WHEN (@Rubro='CULTIVO' AND @PerdidaM2>0) OR (@Rubro='CRIANZA' AND @PerdidosAnimales>0) THEN 'PERDIDA_PARCIAL'
    ELSE 'RECUPERADA' END;
  IF (@Rubro='CULTIVO' AND @PerdidaM2>0) OR (@Rubro='CRIANZA' AND @PerdidosAnimales>0)
  BEGIN
   INSERT prod.GPCenso(actividad_id,cantidad,aproximado,fecha,observacion,
     cantidad_aproximada,cantidad_exacta,superficie_aproximada_m2,superficie_exacta_m2,
     usuario_creacion_id,solicitud_id)
   SELECT @Actividad,CASE WHEN @Rubro='CRIANZA' THEN @NuevosAnimales ELSE NULL END,
      CASE WHEN @Rubro='CRIANZA' THEN 0 ELSE NULL END,CONVERT(DATE,@Ahora),
      CONCAT(N'Ajuste sanitario #',@Incidencia,N': ',TRIM(@Descripcion)),NULL,
      CASE WHEN @Rubro='CRIANZA' THEN @NuevosAnimales ELSE NULL END,NULL,@NuevaM2,@Usuario,NEWID();
   SET @NuevaVersion=CONVERT(BIGINT,SCOPE_IDENTITY());
   -- La distribución opcional por raza o variedad queda sin atribución hasta un nuevo censo desglosado.
  END;
  IF @Finalizada=1 UPDATE prod.GPActividad SET estado_proceso='FINALIZADA' WHERE actividad_id=@Actividad;
  UPDATE prod.GPIncidencia SET estado_seguimiento='CERRADA',resultado=@Resultado,perdida_m2=@PerdidaM2,
     perdidos_animales=@PerdidosAnimales,fecha_cierre=@Ahora,usuario_cierre_id=@Usuario,
     descripcion_cierre=TRIM(@Descripcion),solicitud_cierre=@Solicitud WHERE incidencia_id=@Incidencia;
  COMMIT; SELECT @Incidencia AS id;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
END;
GO
