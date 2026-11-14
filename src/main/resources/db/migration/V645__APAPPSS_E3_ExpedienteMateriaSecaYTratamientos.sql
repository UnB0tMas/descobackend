-- APAPPSS E3/E4: ampliación aditiva del expediente de una planta.
-- Conserva catálogos GP, actos E3 y mediciones históricas vinculadas a visitas.
SET XACT_ABORT ON;
GO

CREATE TABLE sanidad.EpisodioNotaE4 (
    nota_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_E4_EpisodioNota PRIMARY KEY,
    episodio_id BIGINT NOT NULL REFERENCES sanidad.EpisodioPlantaE3(episodio_id),
    comentario NVARCHAR(1500) NOT NULL,
    usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
    fecha_registro DATETIME2(0) NOT NULL CONSTRAINT DF_E4_NotaFecha DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_E4_NotaTexto CHECK (LEN(LTRIM(RTRIM(comentario))) > 0)
);
CREATE INDEX IX_E4_EpisodioNota ON sanidad.EpisodioNotaE4(episodio_id,fecha_registro DESC,nota_id DESC);
GO

CREATE TABLE sanidad.TratamientoAplicacionE4 (
    aplicacion_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_E4_TratamientoAplicacion PRIMARY KEY,
    episodio_id BIGINT NOT NULL REFERENCES sanidad.EpisodioPlantaE3(episodio_id),
    fecha_aplicacion DATE NOT NULL,
    comentario NVARCHAR(1000) NULL,
    resultado NVARCHAR(600) NULL,
    usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
    fecha_registro DATETIME2(0) NOT NULL CONSTRAINT DF_E4_AplicacionFecha DEFAULT SYSUTCDATETIME()
);
CREATE INDEX IX_E4_TratamientoAplicacion ON sanidad.TratamientoAplicacionE4(episodio_id,fecha_aplicacion DESC,aplicacion_id DESC);
ALTER TABLE sanidad.TratamientoPlantaE3 ADD aplicacion_id BIGINT NULL;
ALTER TABLE sanidad.TratamientoPlantaE3 WITH CHECK ADD CONSTRAINT FK_E4_TratamientoAplicacion
    FOREIGN KEY(aplicacion_id) REFERENCES sanidad.TratamientoAplicacionE4(aplicacion_id);
GO

-- La materia seca por planta no exige visita; no se altera la tabla histórica E3.
CREATE TABLE prod.PlantaMateriaSecaIndividualE4 (
    medicion_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_E4_SecaIndividual PRIMARY KEY,
    planta_id BIGINT NOT NULL REFERENCES prod.PlantaPaltaE3(planta_id),
    fecha_muestreo DATE NOT NULL,
    porcentaje DECIMAL(6,3) NOT NULL,
    informe NVARCHAR(2000) NULL,
    usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
    fecha_registro DATETIME2(0) NOT NULL CONSTRAINT DF_E4_SecaIndividualFecha DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_E4_SecaIndividualPct CHECK (porcentaje > 0 AND porcentaje <= 100)
);
CREATE INDEX IX_E4_SecaIndividual ON prod.PlantaMateriaSecaIndividualE4(planta_id,fecha_muestreo DESC,medicion_id DESC);
GO

-- Cobertura parcial: número de plantas ensayadas sin fingir identidad de árboles.
-- Cobertura total: instantánea de las plantas activas al registrar el informe.
CREATE TABLE prod.PredioMateriaSecaGlobalE4 (
    informe_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_E4_SecaGlobal PRIMARY KEY,
    predio_id BIGINT NOT NULL REFERENCES prod.Predio(predio_id),
    uot_id BIGINT NOT NULL REFERENCES org.UOT(uot_id),
    convenio_id BIGINT NOT NULL REFERENCES org.ConvenioUOTOrganizacion(convenio_uot_organizacion_id),
    fecha_muestreo DATE NOT NULL,
    porcentaje DECIMAL(6,3) NOT NULL,
    cantidad_plantas INT NOT NULL,
    total_plantas_activas INT NOT NULL,
    cobertura VARCHAR(7) NOT NULL,
    informe NVARCHAR(2000) NOT NULL,
    usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
    fecha_registro DATETIME2(0) NOT NULL CONSTRAINT DF_E4_SecaGlobalFecha DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_E4_SecaGlobalPct CHECK (porcentaje > 0 AND porcentaje <= 100),
    CONSTRAINT CK_E4_SecaGlobalCant CHECK (cantidad_plantas > 0 AND cantidad_plantas <= total_plantas_activas),
    CONSTRAINT CK_E4_SecaGlobalCob CHECK (cobertura IN ('TOTAL','PARCIAL')
         AND ((cobertura='TOTAL' AND cantidad_plantas=total_plantas_activas)
           OR (cobertura='PARCIAL' AND cantidad_plantas<total_plantas_activas)))
);
CREATE INDEX IX_E4_SecaGlobal ON prod.PredioMateriaSecaGlobalE4(predio_id,convenio_id,uot_id,fecha_muestreo DESC,informe_id DESC);
GO

CREATE TRIGGER sanidad.TR_E4_NotaInmutable ON sanidad.EpisodioNotaE4 AFTER UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 THROW 51381,N'Las notas de la enfermedad se conservan como historial inmutable.',1;
END;
GO
CREATE TRIGGER sanidad.TR_E4_AplicacionInmutable ON sanidad.TratamientoAplicacionE4 AFTER UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 THROW 51382,N'Las aplicaciones de tratamientos son inmutables.',1;
END;
GO
CREATE TRIGGER prod.TR_E4_SecaIndividualInmutable ON prod.PlantaMateriaSecaIndividualE4 AFTER UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 THROW 51383,N'Las mediciones individuales son inmutables.',1;
END;
GO
CREATE TRIGGER prod.TR_E4_SecaGlobalInmutable ON prod.PredioMateriaSecaGlobalE4 AFTER UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 THROW 51384,N'Los informes globales son inmutables.',1;
END;
GO

-- Permisos de operación granulares; el administrador tiene todos y se mantiene el ámbito UOT.
DECLARE @modulo BIGINT = (SELECT TOP(1) modulo_id FROM seg.Permiso WHERE codigo='APAPPSS_PREDIOS_EDITAR' AND estado=1);
IF @modulo IS NULL THROW 51301,N'No existe el permiso base APAPPSS para registrar la ampliación.',1;
INSERT INTO seg.Permiso(modulo_id,codigo,nombre,descripcion,estado,accion,es_sensible,requiere_motivo)
SELECT @modulo, D.codigo,D.nombre,D.descripcion,1,'EDITAR',0,0
FROM (VALUES
 ('APAPPSS_PLANTAS_SALUD_COMENTAR',N'Comentar enfermedades de planta',N'Registrar notas clínicas asociadas a un episodio.'),
 ('APAPPSS_PLANTAS_TRATAMIENTO_LOTE',N'Aplicar tratamientos múltiples',N'Registrar tratamientos ligados a la misma enfermedad de forma atómica.'),
 ('APAPPSS_PLANTAS_SECA_REGISTRAR',N'Medir materia seca individual',N'Registrar un ensayo de materia seca de una planta.'),
 ('APAPPSS_PREDIOS_SECA_LOTE',N'Registrar materia seca global',N'Registrar un informe con cobertura total o parcial de un predio.')
) D(codigo,nombre,descripcion)
WHERE NOT EXISTS(SELECT 1 FROM seg.Permiso P WHERE P.codigo=D.codigo);
GO
DECLARE @admin BIGINT = (SELECT TOP(1) rol_id FROM seg.Rol WHERE codigo='ADMINISTRADOR' AND estado=1);
IF @admin IS NULL THROW 51302,N'No existe el rol ADMINISTRADOR activo.',1;
UPDATE RP SET estado=1,fecha_retiro=NULL,retirado_por_usuario_id=NULL,motivo_retiro=NULL
FROM seg.RolPermiso RP JOIN seg.Permiso P ON P.permiso_id=RP.permiso_id
WHERE RP.rol_id=@admin AND RP.estado=0
 AND P.codigo IN('APAPPSS_PLANTAS_SALUD_COMENTAR','APAPPSS_PLANTAS_TRATAMIENTO_LOTE',
 'APAPPSS_PLANTAS_SECA_REGISTRAR','APAPPSS_PREDIOS_SECA_LOTE');
INSERT INTO seg.RolPermiso(rol_id,permiso_id,estado,fecha_asignacion)
SELECT @admin,P.permiso_id,1,SYSUTCDATETIME()
FROM seg.Permiso P WHERE P.codigo IN(
 'APAPPSS_PLANTAS_SALUD_COMENTAR','APAPPSS_PLANTAS_TRATAMIENTO_LOTE',
 'APAPPSS_PLANTAS_SECA_REGISTRAR','APAPPSS_PREDIOS_SECA_LOTE')
 AND P.estado=1 AND NOT EXISTS(SELECT 1 FROM seg.RolPermiso RP
 WHERE RP.rol_id=@admin AND RP.permiso_id=P.permiso_id);
GO

CREATE OR ALTER PROCEDURE prod.PA_E3_ExpedienteE4_Ejecutar
 @cAccion VARCHAR(30), @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT,
 @bResultado BIT OUTPUT, @cMensaje NVARCHAR(300) OUTPUT,
 @cCodigoRespuesta VARCHAR(60) OUTPUT, @nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo completar el expediente.',
        @cCodigoRespuesta='E4_ERROR',@nHttpRespuesta=400;
 DECLARE @uot BIGINT, @conv BIGINT, @predio BIGINT, @planta BIGINT, @episodio BIGINT,
         @usuario BIGINT, @sesion BIGINT, @disp BIGINT, @emp BIGINT, @modulo INT,
         @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
         @auth BIT,@authMensaje NVARCHAR(300),@perm VARCHAR(60),@extra VARCHAR(60),
         @clave UNIQUEIDENTIFIER,@hash VARBINARY(32),@anterior VARBINARY(32),@previo NVARCHAR(MAX),
         @fecha DATE,@porcentaje DECIMAL(6,3),@texto NVARCHAR(2000),@comentario NVARCHAR(1000),
         @resultado NVARCHAR(600),@cantidad INT,@total INT,@id BIGINT,@estado VARCHAR(16),
         @inicio DATETIME2(0),@gp INT,@ahora DATETIME2(0)=SYSUTCDATETIME();
 BEGIN TRY
  IF ISJSON(@cJson)<>1 THROW 51310,N'Petición inválida.',1;
  SELECT @uot=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
   @conv=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.convenioId')),
   @predio=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.predioId')),
   @planta=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.plantaId')),
   @episodio=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.episodioId')),
   @clave=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia'));
  IF @uot IS NULL OR @conv IS NULL OR @predio IS NULL OR @uot<=0 OR @conv<=0 OR @predio<=0
    THROW 51311,N'Indique la UOT, convenio y predio válidos.',1;
  IF @cAccion NOT IN ('NOTAS_LISTAR','NOTA_REGISTRAR','TRATAMIENTOS_LOTE',
       'SECA_PLANTA_LISTAR','SECA_INDIVIDUAL','SECA_PREDIO_LISTAR','SECA_GLOBAL')
    THROW 51312,N'Operación no permitida.',1;
  SET @perm=CASE WHEN @cAccion IN ('NOTAS_LISTAR','SECA_PLANTA_LISTAR','SECA_PREDIO_LISTAR')
    THEN 'APAPPSS_PREDIOS_VER' ELSE 'APAPPSS_PREDIOS_EDITAR' END;
  SET @extra=CASE @cAccion
    WHEN 'NOTA_REGISTRAR' THEN 'APAPPSS_PLANTAS_SALUD_COMENTAR'
    WHEN 'TRATAMIENTOS_LOTE' THEN 'APAPPSS_PLANTAS_TRATAMIENTO_LOTE'
    WHEN 'SECA_INDIVIDUAL' THEN 'APAPPSS_PLANTAS_SECA_REGISTRAR'
    WHEN 'SECA_GLOBAL' THEN 'APAPPSS_PREDIOS_SECA_LOTE' ELSE NULL END;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,@perm,
    @usuario OUTPUT,@sesion OUTPUT,@disp OUTPUT,@emp OUTPUT,@modulo OUTPUT,
    @corr OUTPUT,@sol OUTPUT,@ip OUTPUT,@endpoint OUTPUT,@auth OUTPUT,@authMensaje OUTPUT;
  IF ISNULL(@auth,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,@perm)<>1
    THROW 51313,N'No tiene acceso al expediente de este predio.',1;
  IF @extra IS NOT NULL AND seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,@extra)<>1
    THROW 51314,N'No tiene permiso para registrar esta actuación.',1;
  SET @fecha=CONVERT(DATE,@ahora);
  IF NOT EXISTS (SELECT 1 FROM prod.PredioAmbito A
    JOIN org.ConvenioUOTOrganizacion C ON C.convenio_uot_organizacion_id=A.convenio_uot_organizacion_id
    JOIN org.ConvenioModuloEspecial M ON M.convenio_uot_organizacion_id=C.convenio_uot_organizacion_id AND M.estado=1
    JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=M.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
    JOIN prod.Predio P ON P.predio_id=A.predio_id AND P.estado=1
    WHERE A.predio_id=@predio AND A.uot_id=@uot AND A.convenio_uot_organizacion_id=@conv AND A.estado=1
      AND C.uot_id=@uot AND C.estado=1 AND (C.fecha_inicio IS NULL OR C.fecha_inicio<=@fecha)
      AND (C.fecha_fin IS NULL OR C.fecha_fin>=@fecha)
      AND EXISTS(SELECT 1 FROM prod.PredioTitularidad T
        JOIN org.Socio S ON S.socio_id=T.socio_id AND S.estado=1
        JOIN org.SocioAsociacion SA ON SA.socio_id=T.socio_id AND SA.asociacion_id=C.empresa_id
           AND SA.estado=1 AND SA.fecha_desde<=@fecha AND (SA.fecha_hasta IS NULL OR SA.fecha_hasta>=@fecha)
        WHERE T.predio_id=@predio AND T.estado=1 AND T.fecha_hasta IS NULL))
    THROW 51315,N'El predio no pertenece al convenio autorizado.',1;
  IF @cAccion NOT IN('SECA_GLOBAL','SECA_PREDIO_LISTAR')
  BEGIN
   IF @planta IS NULL OR NOT EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 P
      WHERE P.planta_id=@planta AND P.predio_id=@predio AND P.uot_id=@uot AND P.convenio_id=@conv)
    THROW 51316,N'La planta no pertenece a este predio.',1;
  END;
  IF @cAccion IN('NOTAS_LISTAR','NOTA_REGISTRAR','TRATAMIENTOS_LOTE')
  BEGIN
   IF @episodio IS NULL OR NOT EXISTS(SELECT 1 FROM sanidad.EpisodioPlantaE3 E
       WHERE E.episodio_id=@episodio AND E.planta_id=@planta)
    THROW 51317,N'La enfermedad no pertenece a esta planta.',1;
  END;

  IF @cAccion='NOTAS_LISTAR'
  BEGIN
   SET @cDatos=(SELECT JSON_QUERY((SELECT N.nota_id notaId,N.comentario,N.usuario_id usuarioId,
     U.nombre_usuario usuarioNombre,
     CONVERT(VARCHAR(19),N.fecha_registro,126)+'Z' fechaHora
     FROM sanidad.EpisodioNotaE4 N LEFT JOIN seg.Usuario U ON U.usuario_id=N.usuario_id
     WHERE N.episodio_id=@episodio ORDER BY N.fecha_registro DESC,N.nota_id DESC FOR JSON PATH)) items
     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='SECA_PREDIO_LISTAR'
  BEGIN
   SELECT @total=COUNT(*) FROM prod.PlantaPaltaE3 P WHERE P.predio_id=@predio AND P.uot_id=@uot
    AND P.convenio_id=@conv AND P.activo=1 AND P.estado_actual NOT IN('MUERTA','ELIMINADA');
   SET @cDatos=(SELECT @total totalPlantasActivas,
    JSON_QUERY((SELECT G.informe_id informeId,G.porcentaje,G.cantidad_plantas cantidadPlantas,
       G.total_plantas_activas totalPlantasAlRegistro,G.cobertura,G.informe,
       CONVERT(VARCHAR(10),G.fecha_muestreo,23) fechaMuestreo,
       CONVERT(VARCHAR(19),G.fecha_registro,126)+'Z' fechaRegistro,G.usuario_id usuarioId,
       U.nombre_usuario usuarioNombre
     FROM prod.PredioMateriaSecaGlobalE4 G LEFT JOIN seg.Usuario U ON U.usuario_id=G.usuario_id
     WHERE G.predio_id=@predio AND G.uot_id=@uot AND G.convenio_id=@conv
     ORDER BY G.fecha_muestreo DESC,G.informe_id DESC FOR JSON PATH)) items
     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='SECA_PLANTA_LISTAR'
  BEGIN
   SELECT @total=COUNT(*) FROM prod.PlantaPaltaE3 P WHERE P.predio_id=@predio AND P.uot_id=@uot
    AND P.convenio_id=@conv AND P.activo=1 AND P.estado_actual NOT IN('MUERTA','ELIMINADA');
   SET @cDatos=(SELECT
    JSON_QUERY((SELECT X.clave,X.origen,X.porcentaje,X.informe,X.fechaMuestreo,X.fechaRegistro,X.usuarioId,X.usuarioNombre
      FROM (SELECT CONCAT('IND-',I.medicion_id) clave,'INDIVIDUAL' origen,I.porcentaje,I.informe,
          CONVERT(VARCHAR(10),I.fecha_muestreo,23) fechaMuestreo,
          CONVERT(VARCHAR(19),I.fecha_registro,126)+'Z' fechaRegistro,I.usuario_id usuarioId,
          U.nombre_usuario usuarioNombre
          FROM prod.PlantaMateriaSecaIndividualE4 I LEFT JOIN seg.Usuario U ON U.usuario_id=I.usuario_id
          WHERE I.planta_id=@planta
        UNION ALL
        SELECT CONCAT('VIS-',V.medicion_id),'VISITA',V.porcentaje,V.observacion,
          CONVERT(VARCHAR(10),V.fecha_hecho,23),
          CONVERT(VARCHAR(19),V.fecha_registro,126)+'Z',V.usuario_id,U.nombre_usuario
          FROM prod.PlantaMedicionE3 V LEFT JOIN seg.Usuario U ON U.usuario_id=V.usuario_id
          WHERE V.planta_id=@planta) X
      ORDER BY X.fechaMuestreo DESC,X.fechaRegistro DESC FOR JSON PATH)) items,
    JSON_QUERY((SELECT TOP(1) G.informe_id informeId,G.porcentaje,G.cobertura,
      G.cantidad_plantas cantidadPlantas,G.total_plantas_activas totalPlantasAlRegistro,
      CONVERT(VARCHAR(10),G.fecha_muestreo,23) fechaMuestreo,
      G.informe,U.nombre_usuario usuarioNombre
      FROM prod.PredioMateriaSecaGlobalE4 G LEFT JOIN seg.Usuario U ON U.usuario_id=G.usuario_id
      WHERE G.predio_id=@predio AND G.uot_id=@uot AND G.convenio_id=@conv
        AND G.cobertura='TOTAL' AND G.total_plantas_activas=@total AND @total>0
      ORDER BY G.fecha_muestreo DESC,G.informe_id DESC FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) globalVigente
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE
  BEGIN
   IF @clave IS NULL THROW 51318,N'No se recibió la clave de idempotencia.',1;
   SET @hash=HASHBYTES('SHA2_256',CONCAT(@cAccion,N'|',JSON_QUERY(@cJson,'$.filtros'),
                                             N'|',JSON_QUERY(@cJson,'$.datos')));
   BEGIN TRANSACTION;
   SELECT @anterior=hash_peticion,@previo=respuesta
   FROM prod.PlantaSolicitudE3 WITH(UPDLOCK,HOLDLOCK)
   WHERE usuario_id=@usuario AND accion=@cAccion AND clave=@clave;
   IF @anterior IS NOT NULL
   BEGIN
    IF @anterior<>@hash THROW 51319,N'La clave ya fue utilizada con información diferente.',1;
    SELECT @cDatos=@previo,@bResultado=1,@cMensaje=N'Operación ya registrada.',
       @cCodigoRespuesta='E4_OK',@nHttpRespuesta=200;
    COMMIT TRANSACTION;
    RETURN;
   END;
   IF @cAccion='NOTA_REGISTRAR'
   BEGIN
    SELECT @estado=CASE WHEN E.activo=1 AND E.fin IS NULL AND P.estado_actual NOT IN('MUERTA','ELIMINADA')
       THEN 'VIGENTE' ELSE 'CERRADA' END
    FROM sanidad.EpisodioPlantaE3 E WITH(UPDLOCK,HOLDLOCK)
    JOIN prod.PlantaPaltaE3 P ON P.planta_id=E.planta_id WHERE E.episodio_id=@episodio;
    IF @estado<>'VIGENTE' THROW 51320,N'Solo se pueden comentar enfermedades vigentes.',1;
    SET @texto=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.comentario'))),N'');
    IF @texto IS NULL OR LEN(@texto)>1500 THROW 51321,N'Ingrese un comentario de hasta 1500 caracteres.',1;
    INSERT INTO sanidad.EpisodioNotaE4(episodio_id,comentario,usuario_id)
      VALUES(@episodio,@texto,@usuario);
    SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
    SET @cDatos=(SELECT @id notaId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   END
   ELSE IF @cAccion='TRATAMIENTOS_LOTE'
   BEGIN
    SELECT @inicio=E.inicio,@gp=E.gp_problema_id,
      @estado=CASE WHEN E.activo=1 AND E.fin IS NULL AND P.estado_actual NOT IN('MUERTA','ELIMINADA')
       THEN 'VIGENTE' ELSE 'CERRADA' END
    FROM sanidad.EpisodioPlantaE3 E WITH(UPDLOCK,HOLDLOCK)
    JOIN prod.PlantaPaltaE3 P ON P.planta_id=E.planta_id WHERE E.episodio_id=@episodio;
    IF @estado<>'VIGENTE' THROW 51322,N'La enfermedad ya no admite tratamientos.',1;
    DECLARE @aplica DATE=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaAplicacion'));
    IF @aplica IS NULL OR @aplica>CONVERT(DATE,@ahora) OR @aplica<CONVERT(DATE,@inicio)
      THROW 51323,N'La fecha de aplicación no es válida para esta enfermedad.',1;
    SET @comentario=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.comentario'))),N'');
    SET @resultado=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.resultado'))),N'');
    IF LEN(ISNULL(JSON_VALUE(@cJson,'$.datos.comentario'),N''))>1000
      OR LEN(ISNULL(JSON_VALUE(@cJson,'$.datos.resultado'),N''))>600
      THROW 51324,N'La descripción supera el tamaño permitido.',1;
    IF ISJSON(JSON_QUERY(@cJson,'$.datos.tratamientoIds'))<>1
      THROW 51325,N'Seleccione tratamientos del catálogo.',1;
    DECLARE @ids TABLE(tratamientoId INT NOT NULL PRIMARY KEY);
    INSERT INTO @ids(tratamientoId)
      SELECT DISTINCT TRY_CONVERT(INT,J.value) FROM OPENJSON(@cJson,'$.datos.tratamientoIds') J
      WHERE TRY_CONVERT(INT,J.value)>0;
    DECLARE @nTotal INT=(SELECT COUNT(*) FROM OPENJSON(@cJson,'$.datos.tratamientoIds'));
    IF @nTotal NOT BETWEEN 1 AND 20 OR @nTotal<>(SELECT COUNT(*) FROM @ids)
      THROW 51326,N'Seleccione entre uno y veinte tratamientos sin duplicados.',1;
    IF EXISTS(SELECT 1 FROM @ids I WHERE NOT EXISTS(
       SELECT 1 FROM prod.GPProblemaTratamiento R
       JOIN prod.GPTratamiento T ON T.tratamiento_id=R.tratamiento_id AND T.estado=1
       JOIN prod.GPProblema GP ON GP.problema_id=R.problema_id AND GP.estado=1
       WHERE R.problema_id=@gp AND R.tratamiento_id=I.tratamientoId))
      THROW 51327,N'Un tratamiento no corresponde a la enfermedad seleccionada.',1;
    INSERT INTO sanidad.TratamientoAplicacionE4(episodio_id,fecha_aplicacion,comentario,resultado,usuario_id)
      VALUES(@episodio,@aplica,@comentario,@resultado,@usuario);
    SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
    INSERT INTO sanidad.TratamientoPlantaE3(episodio_id,gp_tratamiento_id,descripcion,resultado,
         comentario,fecha_aplicacion,usuario_id,aplicacion_id)
      SELECT @episodio,T.tratamiento_id,T.nombre,@resultado,@comentario,
      CASE WHEN @aplica=CONVERT(DATE,@inicio) THEN @inicio ELSE CONVERT(DATETIME2(0),@aplica) END,
      @usuario,@id
      FROM @ids I JOIN prod.GPTratamiento T ON T.tratamiento_id=I.tratamientoId;
    INSERT INTO prod.PlantaEventoE3(planta_id,tipo,observacion,usuario_id,fecha_hecho,correlacion_id)
      VALUES(@planta,'TRATAMIENTO',LEFT(CONCAT(N'Aplicación de ',@nTotal,N' tratamiento(s): ',COALESCE(@comentario,N'Sin observación')),1000),
       @usuario,CASE WHEN @aplica=CONVERT(DATE,@inicio) THEN @inicio ELSE CONVERT(DATETIME2(0),@aplica) END,@corr);
    SET @cDatos=(SELECT @id aplicacionId,@nTotal tratamientosRegistrados
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   END
   ELSE IF @cAccion='SECA_INDIVIDUAL'
   BEGIN
    SELECT @estado=P.estado_actual FROM prod.PlantaPaltaE3 P WITH(UPDLOCK,HOLDLOCK)
      WHERE P.planta_id=@planta;
    IF @estado IN('MUERTA','ELIMINADA') THROW 51328,N'La planta no admite nuevas mediciones.',1;
    SET @fecha=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaMuestreo'));
    SET @porcentaje=TRY_CONVERT(DECIMAL(6,3),JSON_VALUE(@cJson,'$.datos.porcentaje'));
    SET @texto=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.informe'))),N'');
    IF @fecha IS NULL OR @fecha>CONVERT(DATE,@ahora) OR @porcentaje IS NULL OR @porcentaje<=0 OR @porcentaje>100
      OR LEN(ISNULL(JSON_VALUE(@cJson,'$.datos.informe'),N''))>2000
      THROW 51329,N'La fecha, el porcentaje o el informe no son válidos.',1;
    INSERT INTO prod.PlantaMateriaSecaIndividualE4(planta_id,fecha_muestreo,porcentaje,informe,usuario_id)
     VALUES(@planta,@fecha,@porcentaje,@texto,@usuario);
    SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
    SET @cDatos=(SELECT @id medicionId,@planta plantaId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   END
   ELSE IF @cAccion='SECA_GLOBAL'
   BEGIN
    SET @fecha=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaMuestreo'));
    SET @porcentaje=TRY_CONVERT(DECIMAL(6,3),JSON_VALUE(@cJson,'$.datos.porcentaje'));
    SET @cantidad=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.cantidadPlantas'));
    SET @texto=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.informe'))),N'');
    SELECT @total=COUNT(*) FROM prod.PlantaPaltaE3 P WITH(UPDLOCK,HOLDLOCK)
      WHERE P.predio_id=@predio AND P.uot_id=@uot AND P.convenio_id=@conv AND P.activo=1
        AND P.estado_actual NOT IN('MUERTA','ELIMINADA');
    IF @fecha IS NULL OR @fecha>CONVERT(DATE,@ahora) OR @porcentaje IS NULL OR @porcentaje<=0
      OR @porcentaje>100 OR @cantidad IS NULL OR @cantidad<1 OR @cantidad>@total
      OR @texto IS NULL OR LEN(ISNULL(JSON_VALUE(@cJson,'$.datos.informe'),N''))>2000
      THROW 51330,N'Ingrese un informe y una cantidad válida de plantas activas del predio.',1;
    INSERT INTO prod.PredioMateriaSecaGlobalE4(predio_id,uot_id,convenio_id,fecha_muestreo,
         porcentaje,cantidad_plantas,total_plantas_activas,cobertura,informe,usuario_id)
      VALUES(@predio,@uot,@conv,@fecha,@porcentaje,@cantidad,@total,
         CASE WHEN @cantidad=@total THEN 'TOTAL' ELSE 'PARCIAL' END,@texto,@usuario);
    SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
    SET @cDatos=(SELECT @id informeId,@cantidad cantidadPlantas,@total totalPlantasAlRegistro,
       CASE WHEN @cantidad=@total THEN 'TOTAL' ELSE 'PARCIAL' END cobertura
       FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   END;
   INSERT INTO prod.PlantaSolicitudE3(usuario_id,accion,clave,hash_peticion,respuesta)
     VALUES(@usuario,@cAccion,@clave,@hash,COALESCE(@cDatos,N'{}'));
   COMMIT TRANSACTION;
  END;
  SELECT @bResultado=1,@cCodigoRespuesta='E4_OK',@cMensaje=N'Operación completada.',@nHttpRespuesta=200;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
  SELECT @bResultado=0,@cDatos=NULL,
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() IN(51313,51314,51315) THEN 403
                       WHEN ERROR_NUMBER() BETWEEN 51310 AND 51399 THEN 400 ELSE 503 END,
   @cCodigoRespuesta='E4_ERROR',
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51310 AND 51399
            THEN ERROR_MESSAGE() ELSE N'No fue posible completar la operación.' END;
 END CATCH;
END;
GO
