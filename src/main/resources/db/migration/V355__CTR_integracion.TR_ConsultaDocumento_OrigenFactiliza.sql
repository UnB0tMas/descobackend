IF OBJECT_ID(N'[integracion].[TR_ConsultaDocumento_OrigenFactiliza]', N'TR') IS NOT NULL
    DROP TRIGGER [integracion].[TR_ConsultaDocumento_OrigenFactiliza];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : integracion.TR_ConsultaDocumento_OrigenFactiliza
' Descripción              : Valida la procedencia Factiliza de consultas de documentos.
' Tabla asociada          : integracion.ConsultaDocumento
' Evento que lo dispara   : AFTER INSERT, UPDATE
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Integraciones
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    -- Se ejecuta automáticamente mediante AFTER INSERT, UPDATE sobre integracion.ConsultaDocumento.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[integracion].[TR_ConsultaDocumento_OrigenFactiliza]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER integracion.TR_ConsultaDocumento_OrigenFactiliza
ON integracion.ConsultaDocumento
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH FactilizaPersona AS
    (
        SELECT DISTINCT
            P.persona_id,
            P.nombres,
            P.apellido_paterno,
            P.apellido_materno,
            P.fecha_nacimiento,
            U.distrito_codigo,
            U.centro_poblado_id,
            U.referencia
        FROM inserted C
        JOIN org.Persona P
          ON P.documento_clave_desco COLLATE DATABASE_DEFAULT
       = C.clave_documento COLLATE DATABASE_DEFAULT
        LEFT JOIN geo.Ubicacion U
          ON U.ubicacion_id=P.ubicacion_id
        WHERE C.entidad_objetivo='PERSONA'
          AND C.proveedor='FACTILIZA'
          AND C.estado_consulta='EXITO'
          AND C.estado=1
    )
    INSERT integracion.IdentidadCampoOrigen
    (
        entidad_objetivo,
        entidad_id,
        campo,
        proveedor,
        estado
    )
    SELECT
        'PERSONA',
        P.persona_id,
        X.campo,
        'FACTILIZA',
        1
    FROM FactilizaPersona P
    CROSS APPLY
    (
        VALUES
          ('NOMBRES',CASE WHEN NULLIF(LTRIM(RTRIM(P.nombres)),N'') IS NOT NULL THEN 1 ELSE 0 END),
          ('APELLIDO_PATERNO',CASE WHEN NULLIF(LTRIM(RTRIM(P.apellido_paterno)),N'') IS NOT NULL THEN 1 ELSE 0 END),
          ('APELLIDO_MATERNO',CASE WHEN NULLIF(LTRIM(RTRIM(P.apellido_materno)),N'') IS NOT NULL THEN 1 ELSE 0 END),
          ('FECHA_NACIMIENTO',CASE WHEN P.fecha_nacimiento IS NOT NULL THEN 1 ELSE 0 END),
          ('GEOGRAFIA',CASE WHEN P.distrito_codigo IS NOT NULL THEN 1 ELSE 0 END),
          ('CENTRO_POBLADO',CASE WHEN P.centro_poblado_id IS NOT NULL THEN 1 ELSE 0 END),
          ('REFERENCIA',CASE WHEN NULLIF(LTRIM(RTRIM(P.referencia)),N'') IS NOT NULL THEN 1 ELSE 0 END)
    ) X(campo,tieneDato)
    WHERE X.tieneDato=1
      AND NOT EXISTS
      (
          SELECT 1
          FROM integracion.IdentidadCampoOrigen O
          WHERE O.entidad_objetivo='PERSONA'
            AND O.entidad_id=P.persona_id
            AND O.campo=X.campo
            AND O.proveedor='FACTILIZA'
      );
END;
GO
