IF OBJECT_ID(N'[org].[TR_Area_SincronizarUOTLegacy]') IS NOT NULL
    DROP TRIGGER [org].[TR_Area_SincronizarUOTLegacy];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : org.TR_Area_SincronizarUOTLegacy
' Descripción            : Sincroniza áreas con la estructura de UOT heredada.
' Aplicativo / Módulo    : DESCO / Organización
*******************************************************************************************************/
CREATE TRIGGER org.TR_Area_SincronizarUOTLegacy
ON org.Area AFTER INSERT,UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE A
       SET uot_id=COALESCE(A.uot_id,U.uot_id,R.uot_id)
    FROM org.Area A
    JOIN inserted I ON I.area_id=A.area_id
    LEFT JOIN org.UOT U ON U.empresa_legacy_id=A.empresa_id
    OUTER APPLY(SELECT TOP(1) X.uot_id FROM org.UOT X WHERE X.es_raiz=1 AND X.estado=1 ORDER BY X.uot_id) R
    WHERE A.uot_id IS NULL;
    IF EXISTS(SELECT 1 FROM org.Area A JOIN inserted I ON I.area_id=A.area_id WHERE A.uot_id IS NULL)
        THROW 51022,N'No fue posible resolver la UOT del área.',1;
    IF EXISTS(SELECT 1 FROM org.Area A JOIN inserted I ON I.area_id=A.area_id JOIN org.Area P ON P.area_id=A.area_padre_id WHERE P.uot_id<>A.uot_id)
        THROW 51023,N'El área superior debe pertenecer a la misma UOT.',1;
END;
GO
