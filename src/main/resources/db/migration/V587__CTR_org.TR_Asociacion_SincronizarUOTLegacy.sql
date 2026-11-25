IF OBJECT_ID(N'[org].[TR_Asociacion_SincronizarUOTLegacy]') IS NOT NULL
    DROP TRIGGER [org].[TR_Asociacion_SincronizarUOTLegacy];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : org.TR_Asociacion_SincronizarUOTLegacy
' Descripción            : Sincroniza asociaciones con la estructura de UOT heredada.
' Aplicativo / Módulo    : DESCO / Organización
*******************************************************************************************************/
CREATE TRIGGER org.TR_Asociacion_SincronizarUOTLegacy
ON org.Asociacion AFTER INSERT,UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Root BIGINT=(SELECT TOP(1) uot_id FROM org.UOT WHERE es_raiz=1 AND estado=1 ORDER BY uot_id);
    UPDATE A SET uot_id=@Root FROM org.Asociacion A JOIN inserted I ON I.asociacion_id=A.asociacion_id WHERE A.uot_id IS NULL;
    INSERT org.ConvenioUOTOrganizacion(uot_id,empresa_id,tipo_vinculo,fecha_inicio,descripcion,estado)
    SELECT A.uot_id,A.asociacion_id,'ASOCIACION',A.fecha_constitucion,N'Convenio/vínculo generado automáticamente para compatibilidad.',A.estado
    FROM org.Asociacion A JOIN inserted I ON I.asociacion_id=A.asociacion_id
    WHERE I.uot_id IS NULL AND A.uot_id IS NOT NULL AND A.estado=1
      AND NOT EXISTS(SELECT 1 FROM org.ConvenioUOTOrganizacion C WHERE C.uot_id=A.uot_id AND C.empresa_id=A.asociacion_id AND C.tipo_vinculo='ASOCIACION' AND C.estado=1 AND C.fecha_fin IS NULL);
END;
GO
