IF OBJECT_ID(N'[prod].[PA_E1_Persona_Ins_Completa]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_E1_Persona_Ins_Completa];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_E1_Persona_Ins_Completa
' Descripción            : Registra e1 persona para completa.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_E1_Persona_Ins_Completa
  @cJson NVARCHAR(MAX),
  @nPersonaId BIGINT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @tipo VARCHAR(15), @numero VARCHAR(30), @nombres NVARCHAR(100),
          @paterno NVARCHAR(80), @materno NVARCHAR(80),
          @telefono VARCHAR(30), @correo VARCHAR(180), @fecha DATE,
          @distrito CHAR(6), @centro BIGINT, @referencia NVARCHAR(300),
          @ubicacion BIGINT, @existe BIT = 0, @ok BIT, @mensaje NVARCHAR(300),
          @personaEsperada BIGINT;

  SELECT @personaEsperada=personaId,
         @tipo=UPPER(TRIM(tipoDocumento)),@numero=TRIM(numeroDocumento),
         @nombres=NULLIF(TRIM(nombres),N''),@paterno=NULLIF(TRIM(apellidoPaterno),N''),
         @materno=NULLIF(TRIM(apellidoMaterno),N''),
         @telefono=NULLIF(TRIM(telefono),''),@correo=NULLIF(TRIM(correo),''),
         @fecha=fechaNacimiento,@distrito=NULLIF(TRIM(distritoCodigo),''),
         @centro=centroPobladoId,@referencia=NULLIF(TRIM(referencia),N'')
  FROM OPENJSON(@cJson,'$.datos') WITH (
    personaId BIGINT,tipoDocumento VARCHAR(15),numeroDocumento VARCHAR(30),
    nombres NVARCHAR(100),apellidoPaterno NVARCHAR(80),apellidoMaterno NVARCHAR(80),
    telefono VARCHAR(30),correo VARCHAR(180),fechaNacimiento DATE,
    distritoCodigo CHAR(6),centroPobladoId BIGINT,referencia NVARCHAR(300));

  IF @tipo IS NULL OR @tipo NOT IN('DNI','CE','PASAPORTE') OR @numero IS NULL OR LEN(@numero)<5 OR
      (@tipo='DNI' AND (@numero NOT LIKE REPLICATE('[0-9]',8) OR LEN(@numero)<>8))
    THROW 51052,N'Indique un documento válido para la persona.',1;

  -- Una persona existente puede continuar sin completar su información opcional.
  SET @nPersonaId=NULL;
  SELECT TOP (1) @nPersonaId=persona_id,@ubicacion=ubicacion_id
    FROM org.Persona WITH (UPDLOCK,HOLDLOCK)
    WHERE tipo_documento=@tipo AND numero_documento=@numero;
  -- Evita completar una identidad distinta de la seleccionada previamente.
  IF @personaEsperada IS NOT NULL AND
     (@nPersonaId IS NULL OR @personaEsperada<>@nPersonaId)
    THROW 51052,N'La persona seleccionada no coincide con el documento.',1;
  SET @existe=CASE WHEN @nPersonaId IS NULL THEN 0 ELSE 1 END;
  IF @existe=1
  BEGIN
    SELECT @nombres=COALESCE(@nombres,NULLIF(TRIM(P.nombres),N'')),
           @paterno=COALESCE(@paterno,NULLIF(TRIM(P.apellido_paterno),N'')),
           @distrito=COALESCE(@distrito,U.distrito_codigo)
      FROM org.Persona P LEFT JOIN geo.Ubicacion U ON U.ubicacion_id=P.ubicacion_id
      WHERE P.persona_id=@nPersonaId AND P.estado=1;
  END;
  IF @existe=0 AND (@nombres IS NULL OR @paterno IS NULL OR @distrito IS NULL)
    THROW 51052,N'Complete los datos obligatorios de la persona.',1;
  IF @distrito IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM geo.Distrito WHERE distrito_codigo=@distrito AND estado=1)
    THROW 51052,N'Seleccione un distrito válido para la persona.',1;
  IF @centro IS NOT NULL AND (@distrito IS NULL OR NOT EXISTS (
    SELECT 1 FROM geo.CentroPoblado WHERE centro_poblado_id=@centro
      AND distrito_codigo=@distrito AND estado=1))
    THROW 51052,N'El centro poblado no corresponde al distrito indicado.',1;
  IF @fecha>CONVERT(DATE,SYSUTCDATETIME())
    THROW 51052,N'La fecha de nacimiento no puede ser futura.',1;
  IF @correo IS NOT NULL AND @correo NOT LIKE '%_@_%._%'
    THROW 51052,N'Ingrese un correo electrónico válido.',1;
  -- La unicidad de correo pertenece a la persona, no al documento buscado.
  IF @correo IS NOT NULL AND EXISTS (
    SELECT 1 FROM org.Persona WITH (UPDLOCK,HOLDLOCK)
    WHERE correo_clave_desco=LOWER(@correo) COLLATE Latin1_General_100_CI_AS
      AND (@nPersonaId IS NULL OR persona_id<>@nPersonaId))
    THROW 51052,N'El correo electrónico ya está registrado. Ingrese otro.',1;

  IF @existe=1
  BEGIN
    IF EXISTS(SELECT 1 FROM org.Persona WHERE persona_id=@nPersonaId
      AND (estado<>1 OR tipo_persona<>'NATURAL'))
      THROW 51052,N'La persona no está disponible para este registro.',1;
    IF EXISTS(SELECT 1 FROM org.Persona WHERE persona_id=@nPersonaId AND (
       (NULLIF(TRIM(nombres),N'') IS NOT NULL AND TRIM(nombres) COLLATE Latin1_General_100_CI_AI
          <> @nombres COLLATE Latin1_General_100_CI_AI)
       OR (NULLIF(TRIM(apellido_paterno),N'') IS NOT NULL AND TRIM(apellido_paterno) COLLATE Latin1_General_100_CI_AI
          <> @paterno COLLATE Latin1_General_100_CI_AI)
       OR (NULLIF(TRIM(apellido_materno),N'') IS NOT NULL AND @materno IS NOT NULL
          AND TRIM(apellido_materno) COLLATE Latin1_General_100_CI_AI <> @materno COLLATE Latin1_General_100_CI_AI)
    )) THROW 51052,N'El documento pertenece a otra identidad. Seleccione la persona existente.',1;
    IF @ubicacion IS NOT NULL
    BEGIN
      IF NOT EXISTS(SELECT 1 FROM geo.Ubicacion WHERE ubicacion_id=@ubicacion AND estado=1 AND distrito_codigo=@distrito)
        THROW 51052,N'El distrito no coincide con la ubicación de la persona registrada.',1;
      IF @centro IS NOT NULL AND EXISTS(SELECT 1 FROM geo.Ubicacion WHERE ubicacion_id=@ubicacion
          AND centro_poblado_id IS NOT NULL AND centro_poblado_id<>@centro)
        THROW 51052,N'El centro poblado es distinto al registrado para esta persona.',1;
      -- Solo completar datos geográficos vacíos, nunca cambiar ubicaciones existentes.
      UPDATE geo.Ubicacion
         SET centro_poblado_id=COALESCE(centro_poblado_id,@centro),
             referencia=CASE WHEN NULLIF(TRIM(referencia),N'') IS NULL THEN @referencia ELSE referencia END
       WHERE ubicacion_id=@ubicacion AND estado=1;
    END;
  END;

  IF @ubicacion IS NULL AND @distrito IS NOT NULL
  BEGIN
    EXEC geo.PA_Ubicacion_Ins_Interna
      @cDistritoCodigo=@distrito,@nCentroPobladoId=@centro,@cReferencia=@referencia,
      @nLatitud=NULL,@nLongitud=NULL,@nAltitudM=NULL,
      @nUbicacionId=@ubicacion OUTPUT,@bResultado=@ok OUTPUT,@cMensaje=@mensaje OUTPUT;
    IF ISNULL(@ok,0)<>1 OR @ubicacion IS NULL
      THROW 51052,N'No se pudo registrar la ubicación de la persona.',1;
  END;

  IF @existe=0
  BEGIN
    -- Si Factiliza ya registró la identidad, el bloque anterior toma UPDATE.
    INSERT org.Persona (tipo_persona,tipo_documento,numero_documento,nombres,
      apellido_paterno,apellido_materno,telefono,correo,fecha_nacimiento,ubicacion_id,estado)
    VALUES ('NATURAL',@tipo,@numero,@nombres,@paterno,@materno,@telefono,@correo,@fecha,@ubicacion,1);
    SET @nPersonaId=CONVERT(BIGINT,SCOPE_IDENTITY());
  END
  ELSE
  BEGIN
    -- Los datos ya presentes, incluidos los recuperados automáticamente, no se sobrescriben.
    UPDATE org.Persona
       SET nombres=CASE WHEN NULLIF(TRIM(nombres),N'') IS NULL THEN @nombres ELSE nombres END,
           apellido_paterno=CASE WHEN NULLIF(TRIM(apellido_paterno),N'') IS NULL THEN @paterno ELSE apellido_paterno END,
           apellido_materno=CASE WHEN NULLIF(TRIM(apellido_materno),N'') IS NULL THEN @materno ELSE apellido_materno END,
           telefono=CASE WHEN NULLIF(TRIM(telefono),'') IS NULL THEN @telefono ELSE telefono END,
           correo=CASE WHEN NULLIF(TRIM(correo),'') IS NULL THEN @correo ELSE correo END,
           fecha_nacimiento=COALESCE(fecha_nacimiento,@fecha),
           ubicacion_id=COALESCE(ubicacion_id,@ubicacion)
     WHERE persona_id=@nPersonaId AND estado=1;
  END;
END;
GO
