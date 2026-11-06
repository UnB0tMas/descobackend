-- V584: El alta tradicional registra predio, titularidad, ámbito y ficha productiva
-- en una única transacción gestionada por prod.PA_ExpedienteProductivo_Ejecutar.
-- Se mantienen las condiciones propias de APAPPSS y la reutilización de predios existentes.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE prod.PA_E1_Predio_Ins_Registrar
 @cJson NVARCHAR(MAX),@nUot BIGINT,@nConvenio BIGINT,@nUsuario BIGINT,
 @nPredio BIGINT OUTPUT,@nEntidad BIGINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 IF @@TRANCOUNT=0 THROW 51110,N'La alta debe ejecutarse dentro de la transaccion E1.',1;
 DECLARE @nPersona BIGINT,@cNombre NVARCHAR(150),@cDistrito CHAR(6),@nCentroPoblado BIGINT,
 @cRef NVARCHAR(300),@nLat DECIMAL(9,6),@nLon DECIMAL(9,6),@nArea DECIMAL(10,4),@nAreaCult DECIMAL(10,4),@cRiego VARCHAR(30),
 @nUbicacion BIGINT,@bUbi BIT,@cMsgUbi NVARCHAR(300),@nConsecutivo BIGINT,@cCodigo VARCHAR(40);
          SELECT @nPersona=personaId,@cNombre=nombre,@cDistrito=distritoCodigo,@nCentroPoblado=centroPobladoId,@cRef=referencia,@nLat=latitud,@nLon=longitud,@nArea=areaTotalHa,@nAreaCult=areaCultivableHa,@cRiego=tipoRiego
          FROM OPENJSON(@cJson,'$.datos') WITH(personaId BIGINT,nombre NVARCHAR(150),distritoCodigo CHAR(6),centroPobladoId BIGINT,referencia NVARCHAR(300),latitud DECIMAL(9,6),longitud DECIMAL(9,6),areaTotalHa DECIMAL(10,4),areaCultivableHa DECIMAL(10,4),tipoRiego VARCHAR(30));
          SET @cNombre=NULLIF(LTRIM(RTRIM(@cNombre)),N'');
          IF @nPersona IS NULL OR @cNombre IS NULL OR LEN(@cNombre)<2 OR
             NOT EXISTS(SELECT 1 FROM org.Persona WHERE persona_id=@nPersona AND estado=1) OR
             NOT EXISTS(SELECT 1 FROM geo.Distrito WHERE distrito_codigo=@cDistrito AND estado=1) OR
             ((@nLat IS NULL AND @nLon IS NOT NULL) OR (@nLat IS NOT NULL AND @nLon IS NULL)) OR
             (@nLat IS NOT NULL AND (@nLat NOT BETWEEN -90 AND 90 OR @nLon NOT BETWEEN -180 AND 180)) OR
             (@nArea IS NOT NULL AND @nArea<=0)
             THROW 51053,N'Revise titular, nombre, distrito y coordenadas.',1;
          IF @nAreaCult IS NOT NULL AND (@nAreaCult<0 OR (@nArea IS NOT NULL AND @nAreaCult>@nArea))
             THROW 51053,N'La superficie cultivable debe estar entre cero y la superficie total.',1;
          IF @nConvenio IS NULL AND (@nArea IS NULL OR @nAreaCult IS NULL OR
             NULLIF(LTRIM(RTRIM(@cRiego)), '') IS NULL OR @nLat IS NULL OR @nLon IS NULL)
             THROW 51053,N'Complete las superficies, el tipo de riego y la ubicación del fundo.',1;
          IF @nCentroPoblado IS NOT NULL AND NOT EXISTS(
             SELECT 1 FROM geo.CentroPoblado CP
             WHERE CP.centro_poblado_id=@nCentroPoblado AND CP.distrito_codigo=@cDistrito AND CP.estado=1)
             THROW 51055,N'El centro poblado no corresponde al distrito seleccionado.',1;
          IF @nConvenio IS NOT NULL AND NOT EXISTS(
             SELECT 1 FROM org.Socio S WHERE S.socio_id=@nPersona AND S.estado=1)
             THROW 51054,N'La persona no tiene un registro de socio vigente.',1;
          IF @nConvenio IS NOT NULL AND NOT EXISTS(
             SELECT 1 FROM org.SocioAsociacion SA
             JOIN org.ConvenioUOTOrganizacion C ON C.empresa_id=SA.asociacion_id AND C.convenio_uot_organizacion_id=@nConvenio
             WHERE SA.socio_id=@nPersona AND SA.estado=1 AND SA.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
               AND (SA.fecha_hasta IS NULL OR SA.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME())))
             THROW 51054,N'El titular no tiene membresía vigente para este convenio.',1;
          SELECT @nEntidad=predio_id FROM prod.PredioIdentidad WITH(UPDLOCK,HOLDLOCK)
          WHERE persona_id=@nPersona AND distrito_codigo=@cDistrito AND nombre_normalizado=UPPER(LTRIM(RTRIM(@cNombre)));
          IF @nEntidad IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.Predio WHERE predio_id=@nEntidad AND estado=1)
             THROW 51065,N'El predio está retirado; regularice su estado antes de volver a vincularlo.',1;
          IF @nEntidad IS NOT NULL AND NOT EXISTS(
              SELECT 1 FROM prod.Predio P
              WHERE P.predio_id=@nEntidad AND
                (P.uot_id=@nUot OR EXISTS(SELECT 1 FROM prod.PredioAmbito A WHERE A.predio_id=P.predio_id AND
                   seg.FN_Usuario_TienePermisoUOT(@nUsuario,A.uot_id,'PREDIOS_VER')=1)))
              THROW 51065,N'El predio identificado existe fuera del ámbito autorizado.',1;
          IF @nEntidad IS NULL
          BEGIN
            EXEC geo.PA_Ubicacion_Ins_Interna @cDistrito,@nCentroPoblado,@cRef,@nLat,@nLon,NULL,@nUbicacion OUTPUT,@bUbi OUTPUT,@cMsgUbi OUTPUT;
            IF ISNULL(@bUbi,0)=0
            BEGIN
              SET @cMsgUbi=COALESCE(NULLIF(@cMsgUbi,N''),N'No se pudo registrar la ubicación.');
              THROW 51055,@cMsgUbi,1;
            END;
            SET @nConsecutivo=NEXT VALUE FOR prod.SQ_CodigoPredio;
            SET @cCodigo='PRE-'+RIGHT(REPLICATE('0',12)+CONVERT(VARCHAR(20),@nConsecutivo),12);
            INSERT prod.Predio(codigo,nombre,ubicacion_id,fecha_registro,uot_id)
            VALUES(@cCodigo,@cNombre,@nUbicacion,CONVERT(DATE,SYSUTCDATETIME()),@nUot);
            SET @nEntidad=SCOPE_IDENTITY();
            INSERT prod.PredioIdentidad(persona_id,distrito_codigo,nombre_normalizado,predio_id)
            VALUES(@nPersona,@cDistrito,UPPER(LTRIM(RTRIM(@cNombre))),@nEntidad);
            INSERT prod.PredioTitularidad(predio_id,persona_id,socio_id,tipo_titularidad,porcentaje,fecha_desde)
            VALUES(@nEntidad,@nPersona,CASE WHEN EXISTS(SELECT 1 FROM org.Socio WHERE socio_id=@nPersona AND estado=1) THEN @nPersona ELSE NULL END,
              'PROPIETARIO',100,CONVERT(DATE,SYSUTCDATETIME()));
          END;
          SET @nPredio=@nEntidad;
          UPDATE prod.PredioAmbito SET estado=1 WHERE predio_id=@nEntidad AND uot_id=@nUot AND estado=0
             AND ((@nConvenio IS NULL AND convenio_uot_organizacion_id IS NULL) OR convenio_uot_organizacion_id=@nConvenio);
          IF NOT EXISTS(SELECT 1 FROM prod.PredioAmbito WITH(UPDLOCK,HOLDLOCK) WHERE predio_id=@nEntidad AND uot_id=@nUot
             AND ((@nConvenio IS NULL AND convenio_uot_organizacion_id IS NULL) OR convenio_uot_organizacion_id=@nConvenio))
             INSERT prod.PredioAmbito(predio_id,uot_id,convenio_uot_organizacion_id,usuario_creacion_id)
             VALUES(@nEntidad,@nUot,@nConvenio,@nUsuario);
          -- El alta con superficie es UNA sola transaccion: crear, vincular y registrar ficha.
          -- Nunca sobrescribir una ficha existente cuando se reutiliza un predio por identidad.
          IF @nArea IS NOT NULL AND NOT EXISTS(
             SELECT 1 FROM prod.PredioVersion WITH(UPDLOCK,HOLDLOCK)
             WHERE predio_id=@nPredio AND estado=1 AND fecha_hasta IS NULL)
          BEGIN
            DECLARE @nRevisionAlta INT;
            SELECT @nRevisionAlta=ISNULL(MAX(revision),0)+1 FROM prod.PredioVersion WITH(UPDLOCK,HOLDLOCK)
             WHERE predio_id=@nPredio AND fecha_desde=CONVERT(DATE,SYSUTCDATETIME());
            INSERT prod.PredioVersion(predio_id,area_total_ha,area_cultivable_ha,tipo_riego,fecha_desde,revision)
            VALUES(@nPredio,@nArea,@nAreaCult,NULLIF(LTRIM(RTRIM(@cRiego)),''),CONVERT(DATE,SYSUTCDATETIME()),@nRevisionAlta);
          END;
END;
GO
