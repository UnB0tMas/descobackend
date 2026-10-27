IF OBJECT_ID(N'[geo].[TR_Ubicacion_ProtegerOrigenFactiliza]', N'TR') IS NOT NULL
    DROP TRIGGER [geo].[TR_Ubicacion_ProtegerOrigenFactiliza];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : geo.TR_Ubicacion_ProtegerOrigenFactiliza
' Descripción              : Protege los datos de origen Factiliza asociados a ubicaciones.
' Tabla asociada          : geo.Ubicacion
' Evento que lo dispara   : AFTER UPDATE
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Geografía
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    -- Se ejecuta automáticamente mediante AFTER UPDATE sobre geo.Ubicacion.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[geo].[TR_Ubicacion_ProtegerOrigenFactiliza]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER geo.TR_Ubicacion_ProtegerOrigenFactiliza
ON geo.Ubicacion
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        JOIN deleted D
          ON D.ubicacion_id=I.ubicacion_id
        JOIN org.Persona P
          ON P.ubicacion_id=I.ubicacion_id
        JOIN integracion.IdentidadCampoOrigen O
          ON O.entidad_objetivo='PERSONA'
         AND O.entidad_id=P.persona_id
         AND O.proveedor='FACTILIZA'
         AND O.estado=1
        WHERE
             (
                 O.campo='GEOGRAFIA'
                 AND ISNULL(I.distrito_codigo,'')
                     <>ISNULL(D.distrito_codigo,'')
             )
          OR (
                 O.campo='CENTRO_POBLADO'
                 AND ISNULL(I.centro_poblado_id,-1)
                     <>ISNULL(D.centro_poblado_id,-1)
             )
          OR (
                 O.campo='REFERENCIA'
                 AND ISNULL(I.referencia,N'') COLLATE Latin1_General_100_CI_AI
                     <> ISNULL(D.referencia,N'') COLLATE Latin1_General_100_CI_AI
             )
    )
    BEGIN
        THROW 51061,
              N'Los datos validados automáticamente no pueden modificarse.',
              1;
    END;
END;
GO
