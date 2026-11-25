IF OBJECT_ID(N'[org].[TR_Persona_ProtegerOrigenFactiliza]') IS NOT NULL
    DROP TRIGGER [org].[TR_Persona_ProtegerOrigenFactiliza];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : org.TR_Persona_ProtegerOrigenFactiliza
' Descripción            : Controla las modificaciones de persona proteger origen factiliza mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / org
*******************************************************************************************************/
CREATE   TRIGGER org.TR_Persona_ProtegerOrigenFactiliza
ON org.Persona
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        JOIN deleted D
          ON D.persona_id=I.persona_id
        JOIN integracion.IdentidadCampoOrigen O
          ON O.entidad_objetivo='PERSONA'
         AND O.entidad_id=I.persona_id
         AND O.proveedor='FACTILIZA'
         AND O.estado=1
        WHERE
             (O.campo='NOMBRES' AND NULLIF(TRIM(D.nombres),N'') IS NOT NULL
              AND ISNULL(I.nombres,N'') COLLATE Latin1_General_100_CI_AI
                  <> ISNULL(D.nombres,N'') COLLATE Latin1_General_100_CI_AI)
          OR (O.campo='APELLIDO_PATERNO' AND NULLIF(TRIM(D.apellido_paterno),N'') IS NOT NULL
              AND ISNULL(I.apellido_paterno,N'') COLLATE Latin1_General_100_CI_AI
                  <> ISNULL(D.apellido_paterno,N'') COLLATE Latin1_General_100_CI_AI)
          OR (O.campo='APELLIDO_MATERNO' AND NULLIF(TRIM(D.apellido_materno),N'') IS NOT NULL
              AND ISNULL(I.apellido_materno,N'') COLLATE Latin1_General_100_CI_AI
                  <> ISNULL(D.apellido_materno,N'') COLLATE Latin1_General_100_CI_AI)
          OR (O.campo='FECHA_NACIMIENTO' AND D.fecha_nacimiento IS NOT NULL
              AND ISNULL(I.fecha_nacimiento,CONVERT(DATE,'19000101'))
                  <> ISNULL(D.fecha_nacimiento,CONVERT(DATE,'19000101')))
          OR (O.campo IN('GEOGRAFIA','CENTRO_POBLADO','REFERENCIA') AND D.ubicacion_id IS NOT NULL
              AND ISNULL(I.ubicacion_id,-1)<>ISNULL(D.ubicacion_id,-1))
    )
    BEGIN
        THROW 51060,
              N'Los datos validados automáticamente no pueden modificarse.',
              1;
    END;
END;
GO
