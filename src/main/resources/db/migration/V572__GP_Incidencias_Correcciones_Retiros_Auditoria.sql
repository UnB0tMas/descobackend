-- DESCO GP: corrección y retiro lógico de incidencias, auditoría y filtros activos.
-- No borra registros ni altera versiones Flyway anteriores.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'prod.GPIncidenciaRevision',N'U') IS NULL
BEGIN
 CREATE TABLE prod.GPIncidenciaRevision(
  revision_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_GPIncidenciaRevision PRIMARY KEY,
  incidencia_id BIGINT NOT NULL REFERENCES prod.GPIncidencia(incidencia_id),
  accion VARCHAR(12) NOT NULL CONSTRAINT CK_GPIncidenciaRevision_Accion CHECK(accion IN('EDICION','RETIRO')),
  motivo NVARCHAR(1000) NOT NULL,
  usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
  fecha_registro DATETIME2(0) NOT NULL CONSTRAINT DF_GPIncidenciaRevision_Fecha DEFAULT SYSUTCDATETIME(),
  problema_anterior INT NOT NULL, problema_nuevo INT NOT NULL,
  afectada_anterior DECIMAL(14,2) NULL, afectada_nueva DECIMAL(14,2) NULL,
  animales_anteriores INT NULL, animales_nuevos INT NULL,
  descripcion_anterior NVARCHAR(2000) NOT NULL, descripcion_nueva NVARCHAR(2000) NOT NULL,
  solicitud_id UNIQUEIDENTIFIER NOT NULL CONSTRAINT UQ_GPIncidenciaRevision_Solicitud UNIQUE,
  estado BIT NOT NULL CONSTRAINT DF_GPIncidenciaRevision_Estado DEFAULT 1
 );
 CREATE INDEX IX_GPIncidenciaRevision_Incidencia ON prod.GPIncidenciaRevision(incidencia_id,revision_id DESC);
END;
GO
CREATE OR ALTER PROCEDURE prod.PA_GP_Incidencia_Upd_Corregir
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Incidencia BIGINT,
 @Problema INT,@AfectadaM2 DECIMAL(14,2)=NULL,@AfectadosAnimales INT=NULL,
 @Descripcion NVARCHAR(2000),@Motivo NVARCHAR(1000),@Solicitud UNIQUEIDENTIFIER
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'SANIDAD_EDITAR',1)<>1
  THROW 51101,N'Acceso no autorizado.',1;
 IF @Solicitud IS NULL OR @Problema IS NULL OR LEN(TRIM(COALESCE(@Descripcion,N'')))<3
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
    TRIM(@Descripcion)=TRIM(@DescripcionAnterior)
    THROW 51103,N'No se detectaron cambios en la incidencia.',1;
  UPDATE prod.GPIncidencia SET problema_id=@Problema,afectada_m2=@AfectadaM2,
    afectados_animales=@AfectadosAnimales WHERE incidencia_id=@Incidencia;
  UPDATE prod.GPEvento SET problema_id=@Problema,observacion=TRIM(@Descripcion)
    WHERE evento_id=@Incidencia;
  INSERT prod.GPIncidenciaRevision(incidencia_id,accion,motivo,usuario_id,
     problema_anterior,problema_nuevo,afectada_anterior,afectada_nueva,
     animales_anteriores,animales_nuevos,descripcion_anterior,descripcion_nueva,solicitud_id)
  VALUES(@Incidencia,'EDICION',TRIM(@Motivo),@Usuario,
     @ProblemaAnterior,@Problema,@AfectadaAnterior,@AfectadaM2,
     @AnimalesAnteriores,@AfectadosAnimales,@DescripcionAnterior,TRIM(@Descripcion),@Solicitud);
  INSERT prod.GPEvento(actividad_id,tipo,observacion,fecha_hecho,usuario_creacion_id,solicitud_id)
  VALUES(@Actividad,'OBSERVACION',CONCAT(N'Corrección de incidencia #',@Incidencia,
    N'. Motivo: ',TRIM(@Motivo)),SYSUTCDATETIME(),@Usuario,NEWID());
  COMMIT; SELECT @Incidencia AS id;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE prod.PA_GP_Incidencia_Upd_Retirar
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
CREATE OR ALTER PROCEDURE prod.PA_GP_IncidenciaRevision_Sel_Historial
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Incidencia BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_VER',0)<>1
  THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPIncidencia I
    JOIN prod.GPActividad A ON A.actividad_id=I.actividad_id AND A.uot_id=@Uot
    JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.estado=1
    JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot
      AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
    WHERE I.incidencia_id=@Incidencia)
    THROW 51102,N'Incidencia fuera del ámbito.',1;
 SELECT revision_id AS revisionId,incidencia_id AS incidenciaId,accion,motivo,
    usuario_id AS usuarioId,fecha_registro AS fechaRegistro,
    problema_anterior AS problemaAnterior,problema_nuevo AS problemaNuevo,
    afectada_anterior AS afectadaAnterior,afectada_nueva AS afectadaNueva,
    animales_anteriores AS animalesAnteriores,animales_nuevos AS animalesNuevos,
    descripcion_anterior AS descripcionAnterior,descripcion_nueva AS descripcionNueva
 FROM prod.GPIncidenciaRevision WHERE incidencia_id=@Incidencia
 ORDER BY revision_id DESC;
END;
GO

-- Actualizaciones completas de los PA de consulta para respetar estado=1.
-- DESCO GP | migracion aditiva, historiales inmutables.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_Incidencia_Sel_Listado;
GO
IF OBJECT_ID(N'prod.PA_GP_Incidencia_Sel_Listado', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Incidencia_Sel_Listado;
GO
CREATE PROCEDURE prod.PA_GP_Incidencia_Sel_Listado
@Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;

 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_VER',0)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPActividad A JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.estado=1
  JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
  WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot AND A.estado=1) THROW 51102,N'Actividad no disponible.',1;
 SELECT I.incidencia_id incidenciaId,I.actividad_id actividadId,I.problema_id problemaId,P.nombre problema,
   I.estado_seguimiento AS estado,I.resultado,I.afectada_m2 afectadaM2,I.afectados_animales afectadosAnimales,
   I.perdida_m2 perdidaM2,I.perdidos_animales perdidosAnimales,
   E.observacion descripcion,E.fecha_registro fechaRegistro,E.usuario_creacion_id usuarioId,
   I.fecha_cierre fechaCierre,I.descripcion_cierre descripcionCierre,I.usuario_cierre_id usuarioCierreId
 FROM prod.GPIncidencia I JOIN prod.GPEvento E ON E.evento_id=I.incidencia_id
 JOIN prod.GPProblema P ON P.problema_id=I.problema_id
 WHERE I.actividad_id=@Actividad AND I.estado=1 AND E.estado=1 ORDER BY I.incidencia_id DESC;
END;
GO

-- DESCO GP | migracion aditiva, historiales inmutables.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_Tratamiento_Sel_Incidencia;
GO
IF OBJECT_ID(N'prod.PA_GP_Tratamiento_Sel_Incidencia', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Tratamiento_Sel_Incidencia;
GO
CREATE PROCEDURE prod.PA_GP_Tratamiento_Sel_Incidencia
@Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;

 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'CULTIVOS_VER',0)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPActividad A JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.estado=1
  JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
  WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot AND A.estado=1) THROW 51102,N'Actividad no disponible.',1;
 SELECT T.evento_id eventoId,T.incidencia_id incidenciaId,T.tratamiento_id tratamientoId,
   C.nombre tratamiento,E.observacion descripcion,T.fecha_inicio fechaInicio,
   T.fecha_fin_prevista fechaFinPrevista,T.fecha_fin_real fechaFinReal,
   T.descripcion_cierre descripcionCierre,E.usuario_creacion_id usuarioId
 FROM prod.GPIncidenciaTratamiento T JOIN prod.GPIncidencia I ON I.incidencia_id=T.incidencia_id
 JOIN prod.GPTratamiento C ON C.tratamiento_id=T.tratamiento_id
 JOIN prod.GPEvento E ON E.evento_id=T.evento_id
 WHERE I.actividad_id=@Actividad AND I.estado=1 AND T.estado=1 AND E.estado=1 ORDER BY T.evento_id DESC;
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_Evento_Sel_Historial;
GO
IF OBJECT_ID(N'prod.PA_GP_Evento_Sel_Historial', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Evento_Sel_Historial;
GO
CREATE PROCEDURE prod.PA_GP_Evento_Sel_Historial
@Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT
AS
BEGIN
  SET NOCOUNT ON;
IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'PREDIOS_VER',0)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF NOT EXISTS(SELECT 1 FROM prod.GPActividad A JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.predio_id=A.predio_id JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot AND B.convenio_uot_organizacion_id IS NULL AND B.estado=1 WHERE A.actividad_id=@Actividad AND A.uot_id=@Uot) THROW 51102,N'Actividad fuera del ámbito general.',1;
 SELECT E.evento_id AS eventoId,E.actividad_id AS actividadId,E.tipo,E.observacion,E.fecha_hecho AS fechaHecho,
 E.fecha_registro AS fechaRegistro,E.usuario_creacion_id AS usuarioId,E.respuesta_a_id AS respuestaAId,
 E.problema_id AS problemaId,P.nombre AS problema,E.tratamiento_id AS tratamientoId,T.nombre AS tratamiento,
 E.cantidad_afectada AS cantidadAfectada,E.afectados_aproximado AS afectadosAproximado,
 F.foto_id AS fotoId
 FROM prod.GPEvento E LEFT JOIN prod.GPProblema P ON P.problema_id=E.problema_id
 LEFT JOIN prod.GPTratamiento T ON T.tratamiento_id=E.tratamiento_id
 LEFT JOIN prod.GPEventoFoto F ON F.evento_id=E.evento_id
 WHERE E.actividad_id=@Actividad AND E.estado=1 ORDER BY E.fecha_hecho DESC,E.evento_id DESC;
END;
GO

-- DESCO GP | migracion aditiva, historiales inmutables.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_Tratamiento_Ins_Incidencia;
GO
IF OBJECT_ID(N'prod.PA_GP_Tratamiento_Ins_Incidencia', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Tratamiento_Ins_Incidencia;
GO
CREATE PROCEDURE prod.PA_GP_Tratamiento_Ins_Incidencia
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Actividad BIGINT,
 @Incidencia BIGINT,@Tratamiento INT,@Descripcion NVARCHAR(2000),@FechaFinPrevista DATETIME2(0)=NULL,
 @Solicitud UNIQUEIDENTIFIER
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
 WHERE I.incidencia_id=@Incidencia AND I.actividad_id=@Actividad AND I.estado=1 AND I.estado_seguimiento='ABIERTA')
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
   SELECT @Bloqueo=incidencia_id FROM prod.GPIncidencia WITH(UPDLOCK,HOLDLOCK) WHERE incidencia_id=@Incidencia AND estado=1 AND estado_seguimiento='ABIERTA';
   IF @Bloqueo IS NULL THROW 51103,N'La incidencia fue cerrada.',1;
   INSERT prod.GPEvento(actividad_id,tipo,problema_id,tratamiento_id,respuesta_a_id,observacion,fecha_hecho,
      usuario_creacion_id,solicitud_id)
   SELECT @Actividad,'TRATAMIENTO',problema_id,@Tratamiento,@Incidencia,TRIM(@Descripcion),SYSUTCDATETIME(),@Usuario,@Solicitud
   FROM prod.GPIncidencia WHERE incidencia_id=@Incidencia AND estado=1;
   SET @Id=CONVERT(BIGINT,SCOPE_IDENTITY());
   INSERT prod.GPIncidenciaTratamiento(evento_id,incidencia_id,tratamiento_id,fecha_fin_prevista)
   VALUES(@Id,@Incidencia,@Tratamiento,@FechaFinPrevista);
  END
  ELSE IF NOT EXISTS(SELECT 1 FROM prod.GPIncidenciaTratamiento WHERE evento_id=@Id AND incidencia_id=@Incidencia)
   THROW 51103,N'La solicitud corresponde a otra actuación.',1;
  COMMIT; SELECT @Id AS id;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
END;
GO

-- DESCO GP | migracion aditiva, historiales inmutables.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP PROCEDURE IF EXISTS prod.PA_GP_Tratamiento_Upd_Finalizar;
GO
IF OBJECT_ID(N'prod.PA_GP_Tratamiento_Upd_Finalizar', N'P') IS NOT NULL DROP PROCEDURE prod.PA_GP_Tratamiento_Upd_Finalizar;
GO
CREATE PROCEDURE prod.PA_GP_Tratamiento_Upd_Finalizar
 @Sesion UNIQUEIDENTIFIER,@Usuario BIGINT,@Uot BIGINT,@Evento BIGINT,
 @Descripcion NVARCHAR(1000),@Solicitud UNIQUEIDENTIFIER
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;

 IF prod.FN_GP_Permiso(@Sesion,@Usuario,@Uot,'SANIDAD_CREAR',1)<>1 THROW 51101,N'Acceso no autorizado.',1;
 IF @Solicitud IS NULL OR LEN(TRIM(COALESCE(@Descripcion,N'')))<3 THROW 51103,N'Indique el resultado del tratamiento.',1;
 BEGIN TRAN;
 BEGIN TRY
  DECLARE @Act BIGINT;
  SELECT @Act=I.actividad_id FROM prod.GPIncidenciaTratamiento T
   JOIN prod.GPIncidencia I ON I.incidencia_id=T.incidencia_id
   JOIN prod.GPActividad A ON A.actividad_id=I.actividad_id AND A.estado=1
   JOIN prod.Parcela P ON P.parcela_id=A.parcela_id AND P.estado=1
   JOIN prod.PredioAmbito B ON B.predio_id=A.predio_id AND B.uot_id=@Uot AND B.estado=1 AND B.convenio_uot_organizacion_id IS NULL
   WHERE T.evento_id=@Evento AND T.estado=1 AND I.estado=1 AND A.uot_id=@Uot;
  IF @Act IS NULL THROW 51102,N'Tratamiento no disponible.',1;
  IF EXISTS(SELECT 1 FROM prod.GPIncidenciaTratamiento WHERE solicitud_cierre=@Solicitud AND evento_id<>@Evento)
   THROW 51103,N'La solicitud se utilizó en otro tratamiento.',1;
  UPDATE prod.GPIncidenciaTratamiento SET fecha_fin_real=SYSUTCDATETIME(),descripcion_cierre=TRIM(@Descripcion),
    usuario_cierre_id=@Usuario,solicitud_cierre=@Solicitud
   WHERE evento_id=@Evento AND estado=1 AND fecha_fin_real IS NULL AND solicitud_cierre IS NULL;
  IF @@ROWCOUNT=0 AND NOT EXISTS(SELECT 1 FROM prod.GPIncidenciaTratamiento WHERE evento_id=@Evento AND solicitud_cierre=@Solicitud)
    THROW 51103,N'El tratamiento ya fue finalizado.',1;
  COMMIT; SELECT @Evento AS id;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
END;
GO

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
  WHERE I.incidencia_id=@Incidencia AND I.estado=1 AND A.uot_id=@Uot AND A.estado=1;
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
  IF EXISTS(SELECT 1 FROM prod.GPIncidenciaTratamiento WHERE incidencia_id=@Incidencia AND estado=1 AND fecha_fin_real IS NULL)
    THROW 51103,N'Finalice los tratamientos en curso antes de cerrar la incidencia.',1;
  SET @NuevaM2=CASE WHEN @Rubro='CULTIVO' THEN @ActualM2-@PerdidaM2 ELSE @ActualM2 END;
  SET @NuevosAnimales=CASE WHEN @Rubro='CRIANZA' THEN @ActualAnimales-@PerdidosAnimales ELSE @ActualAnimales END;
  SET @Finalizada=CASE WHEN @Rubro='CULTIVO' AND @NuevaM2=0 THEN 1
       WHEN @Rubro='CRIANZA' AND @NuevosAnimales=0 THEN 1 ELSE 0 END;
  IF @Finalizada=1 AND EXISTS(SELECT 1 FROM prod.GPIncidencia WHERE actividad_id=@Actividad AND incidencia_id<>@Incidencia AND estado=1 AND estado_seguimiento='ABIERTA')
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

-- Finalización de actividad no bloqueada por incidencias retiradas.
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
  IF EXISTS(SELECT 1 FROM prod.GPIncidencia WHERE actividad_id=@Actividad AND estado=1 AND estado_seguimiento='ABIERTA')
   THROW 51103,N'Primero cierre las incidencias abiertas.',1;
  UPDATE prod.GPActividad SET estado_proceso='FINALIZADA' WHERE actividad_id=@Actividad;
  INSERT prod.GPActividadRevision(actividad_id,nombre_anterior,nombre_nuevo,estado_anterior,estado_nuevo,motivo,usuario_id,solicitud_id)
  VALUES(@Actividad,@Nombre,@Nombre,1,1,CONCAT(N'FINALIZACIÓN: ',TRIM(@Motivo)),@Usuario,@Solicitud);
  COMMIT; SELECT @Actividad AS id;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
END;
GO
