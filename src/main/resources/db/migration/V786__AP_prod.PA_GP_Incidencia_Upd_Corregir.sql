IF OBJECT_ID(N'[prod].[PA_GP_Incidencia_Upd_Corregir]', N'P') IS NOT NULL
    DROP PROCEDURE prod.PA_GP_Incidencia_Upd_Corregir;
GO

-- Control de actuaciones productivas por sesión, UOT y predio.
CREATE   PROCEDURE prod.PA_GP_Incidencia_Upd_Corregir
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Incidencia BIGINT,
 @Problema INT,@AfectadaM2 DECIMAL(14,2)=NULL,@AfectadosAnimales INT=NULL,
 @Descripcion NVARCHAR(2000),@Motivo NVARCHAR(1000),@Solicitud UNIQUEIDENTIFIER
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'SANIDAD_EDITAR',1)<>1
  THROW 51101,N'Acceso no autorizado.',1;
    DECLARE @PredioControlGP BIGINT;
    SET @PredioControlGP = (SELECT A.predio_id FROM prod.GPIncidencia I JOIN prod.GPActividad A ON A.actividad_id = I.actividad_id WHERE I.incidencia_id = @Incidencia AND A.uot_id = @Uot);
    IF @PredioControlGP IS NULL OR prod.FN_GP_PuedeActuar(@Sesion, @Usuario, @Uot, @PredioControlGP) <> 1
        THROW 51101, N'Debe iniciar una visita al predio desde una salida aprobada.', 1;

 IF @Solicitud IS NULL OR @Problema IS NULL
   OR LEN(TRIM(COALESCE(@Motivo,N'')))<3
  THROW 51103,N'La corrección requiere datos y motivo.',1;
 BEGIN TRAN;
 BEGIN TRY
  DECLARE @Revision BIGINT,@Actividad BIGINT,@Rubro VARCHAR(8),@Parcela BIGINT,
    @ProblemaAnterior INT,@DescripcionAnterior NVARCHAR(2000),
    @AfectadaAnterior DECIMAL(14,2),@AnimalesAnteriores INT,
    @ActualM2 DECIMAL(14,2),@ActualAnimales INT;
  SELECT @Revision=revision_id FROM prod.GPIncidenciaRevision WITH(UPDLOCK,HOLDLOCK)
   WHERE solicitud_id=@Solicitud;
  IF @Revision IS NOT NULL
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM prod.GPIncidenciaRevision WHERE revision_id=@Revision
       AND incidencia_id=@Incidencia AND accion='EDICION')
    THROW 51103,N'La solicitud pertenece a otra actuación.',1;
   COMMIT; SELECT @Incidencia AS id; RETURN;
  END;
  SELECT @Actividad=I.actividad_id,@Parcela=A.parcela_id,@Rubro=A.rubro,
   @ProblemaAnterior=I.problema_id,@DescripcionAnterior=E.observacion,
   @AfectadaAnterior=I.afectada_m2,@AnimalesAnteriores=I.afectados_animales
  FROM prod.GPIncidencia I WITH(UPDLOCK,HOLDLOCK)
  JOIN prod.GPEvento E ON E.evento_id=I.incidencia_id AND E.estado=1
  JOIN prod.GPActividad A ON A.actividad_id=I.actividad_id AND A.estado=1 AND A.estado_proceso='ACTIVA'
  JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.estado=1
  JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot
    AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
  WHERE I.incidencia_id=@Incidencia AND I.estado=1 AND I.estado_seguimiento='ABIERTA'
    AND A.uot_id=@Uot;
  IF @Actividad IS NULL THROW 51102,N'La incidencia no está activa o no pertenece al ámbito.',1;
  SELECT @Parcela=parcela_id FROM prod.Parcela WITH(UPDLOCK,HOLDLOCK) WHERE parcela_id=@Parcela;
  IF NOT EXISTS(SELECT 1 FROM prod.GPProblema P
       JOIN prod.GPActividad A ON A.actividad_id=@Actividad
       WHERE P.problema_id=@Problema AND P.estado=1 AND
         ((@Rubro='CULTIVO' AND P.cultivo_id=A.cultivo_id) OR
          (@Rubro='CRIANZA' AND P.especie_pecuaria_id=A.especie_pecuaria_id)))
    THROW 51103,N'La enfermedad no corresponde a esta actividad.',1;
  SELECT TOP(1) @ActualM2=C.superficie_exacta_m2,@ActualAnimales=C.cantidad_exacta
    FROM prod.GPCenso C WHERE C.actividad_id=@Actividad AND C.estado=1
    ORDER BY C.fecha_registro DESC,C.censo_id DESC;
  IF (@Rubro='CULTIVO' AND (@AfectadaM2 IS NULL OR @AfectadaM2<=0 OR
    @AfectadosAnimales IS NOT NULL OR @AfectadaM2>COALESCE(@ActualM2,0)))
    OR (@Rubro='CRIANZA' AND (@AfectadosAnimales IS NULL OR @AfectadosAnimales<=0 OR
    @AfectadaM2 IS NOT NULL OR @AfectadosAnimales>COALESCE(@ActualAnimales,0)))
    THROW 51103,N'La afectación es incompatible con el censo o la superficie vigente.',1;
  IF @Problema<>@ProblemaAnterior AND EXISTS(SELECT 1 FROM prod.GPIncidenciaTratamiento
    WHERE incidencia_id=@Incidencia AND estado=1)
    THROW 51103,N'No se puede cambiar la enfermedad si tiene tratamientos; registre una nueva incidencia.',1;
  IF @Problema=@ProblemaAnterior AND
    COALESCE(@AfectadaM2,-1)=COALESCE(@AfectadaAnterior,-1) AND
    COALESCE(@AfectadosAnimales,-1)=COALESCE(@AnimalesAnteriores,-1) AND
    COALESCE(TRIM(@Descripcion),N'')=TRIM(@DescripcionAnterior)
    THROW 51103,N'No se detectaron cambios en la incidencia.',1;
  UPDATE prod.GPIncidencia SET problema_id=@Problema,afectada_m2=@AfectadaM2,
    afectados_animales=@AfectadosAnimales WHERE incidencia_id=@Incidencia;
  UPDATE prod.GPEvento SET problema_id=@Problema,observacion=COALESCE(TRIM(@Descripcion),N'')
    WHERE evento_id=@Incidencia;
  INSERT prod.GPIncidenciaRevision(incidencia_id,accion,motivo,usuario_id,
     problema_anterior,problema_nuevo,afectada_anterior,afectada_nueva,
     animales_anteriores,animales_nuevos,descripcion_anterior,descripcion_nueva,solicitud_id)
  VALUES(@Incidencia,'EDICION',TRIM(@Motivo),@Usuario,
     @ProblemaAnterior,@Problema,@AfectadaAnterior,@AfectadaM2,
     @AnimalesAnteriores,@AfectadosAnimales,@DescripcionAnterior,COALESCE(TRIM(@Descripcion),N''),@Solicitud);
  INSERT prod.GPEvento(actividad_id,tipo,observacion,fecha_hecho,usuario_creacion_id,solicitud_id)
  VALUES(@Actividad,'OBSERVACION',CONCAT(N'Corrección de incidencia #',@Incidencia,
    N'. Motivo: ',TRIM(@Motivo)),SYSUTCDATETIME(),@Usuario,NEWID());
  COMMIT; SELECT @Incidencia AS id;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
END;
GO
