IF OBJECT_ID(N'[org].[TR_Persona_ProtegerOrigenFactiliza]', N'TR') IS NOT NULL
    DROP TRIGGER [org].[TR_Persona_ProtegerOrigenFactiliza];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : org.TR_Persona_ProtegerOrigenFactiliza
' Descripción              : Protege los datos de origen Factiliza asociados a personas.
' Tabla asociada          : org.Persona
' Evento que lo dispara   : AFTER UPDATE
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Organización
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    -- Se ejecuta automáticamente mediante AFTER UPDATE sobre org.Persona.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[org].[TR_Persona_ProtegerOrigenFactiliza]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER org.TR_Persona_ProtegerOrigenFactiliza
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
             (O.campo='NOMBRES'
              AND ISNULL(I.nombres,N'') COLLATE Latin1_General_100_CI_AI
                  <> ISNULL(D.nombres,N'') COLLATE Latin1_General_100_CI_AI)
          OR (O.campo='APELLIDO_PATERNO'
              AND ISNULL(I.apellido_paterno,N'') COLLATE Latin1_General_100_CI_AI
                  <> ISNULL(D.apellido_paterno,N'') COLLATE Latin1_General_100_CI_AI)
          OR (O.campo='APELLIDO_MATERNO'
              AND ISNULL(I.apellido_materno,N'') COLLATE Latin1_General_100_CI_AI
                  <> ISNULL(D.apellido_materno,N'') COLLATE Latin1_General_100_CI_AI)
          OR (O.campo='FECHA_NACIMIENTO'
              AND ISNULL(I.fecha_nacimiento,CONVERT(DATE,'19000101'))
                  <> ISNULL(D.fecha_nacimiento,CONVERT(DATE,'19000101')))
          OR (O.campo IN('GEOGRAFIA','CENTRO_POBLADO','REFERENCIA')
              AND ISNULL(I.ubicacion_id,-1)<>ISNULL(D.ubicacion_id,-1))
    )
    BEGIN
        THROW 51060,
              N'Los datos validados automáticamente no pueden modificarse.',
              1;
    END;
END;
GO
