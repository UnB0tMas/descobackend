IF OBJECT_ID(N'[comercial].[TR_DESCO_JabaAsignacion_Kardex]', N'TR') IS NOT NULL
    DROP TRIGGER [comercial].[TR_DESCO_JabaAsignacion_Kardex];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : comercial.TR_DESCO_JabaAsignacion_Kardex
' Descripción              : Mantiene movimientos de kardex relacionados con asignaciones de jabas.
' Tabla asociada          : comercial.JabaAsignacion
' Evento que lo dispara   : AFTER INSERT,UPDATE,DELETE
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Comercial
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE,DELETE sobre comercial.JabaAsignacion.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[comercial].[TR_DESCO_JabaAsignacion_Kardex]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER comercial.TR_DESCO_JabaAsignacion_Kardex
ON comercial.JabaAsignacion AFTER INSERT,UPDATE,DELETE AS
BEGIN
 IF ROWCOUNT_BIG()=0 RETURN;
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM deleted D LEFT JOIN inserted I ON I.jaba_asignacion_id=D.jaba_asignacion_id WHERE I.jaba_asignacion_id IS NULL)
  THROW 51100,N'DESCO_MOVIMIENTO_INMUTABLE',1;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.jaba_asignacion_id=I.jaba_asignacion_id
  WHERE I.operativo_socio_id<>D.operativo_socio_id OR I.cantidad_asignada<>D.cantidad_asignada OR I.fecha_hora<>D.fecha_hora
   OR (D.estado=0 AND I.estado=1)) THROW 51100,N'DESCO_MOVIMIENTO_INMUTABLE',1;
 IF EXISTS(SELECT 1 FROM inserted WHERE estado=0 AND cantidad_devuelta>0)
  THROW 51100,N'DESCO_JABA_CON_DEVOLUCIONES',1;
 IF EXISTS(SELECT 1 FROM inserted I LEFT JOIN deleted D ON D.jaba_asignacion_id=I.jaba_asignacion_id
  JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=I.operativo_socio_id
  JOIN comercial.OperativoVenta O WITH(UPDLOCK,HOLDLOCK) ON O.operativo_venta_id=OS.operativo_venta_id
  WHERE D.jaba_asignacion_id IS NULL AND (I.estado<>1 OR OS.estado<>1 OR OS.estado_participacion<>'PROGRAMADO' OR O.estado_proceso<>'EN_RECEPCION' OR O.estado<>1))
  THROW 51100,N'DESCO_JABA_RELACION',1;
 INSERT comercial.JabaMovimiento(operativo_venta_id,operativo_socio_id,jaba_asignacion_id,tipo_movimiento,cantidad,fecha_hora,usuario_id,motivo,estado)
 SELECT OS.operativo_venta_id,I.operativo_socio_id,I.jaba_asignacion_id,'ASIGNACION',I.cantidad_asignada,I.fecha_hora,I.usuario_registro_id,I.observacion,1
 FROM inserted I LEFT JOIN deleted D ON D.jaba_asignacion_id=I.jaba_asignacion_id
 JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=I.operativo_socio_id WHERE D.jaba_asignacion_id IS NULL;
 UPDATE M SET estado=0,fecha_anulacion=I.fecha_anulacion,usuario_anulacion_id=I.usuario_anulacion_id,motivo_anulacion=I.motivo_anulacion
 FROM comercial.JabaMovimiento M JOIN inserted I ON I.jaba_asignacion_id=M.jaba_asignacion_id
 JOIN deleted D ON D.jaba_asignacion_id=I.jaba_asignacion_id
 WHERE D.estado=1 AND I.estado=0 AND M.tipo_movimiento='ASIGNACION' AND M.estado=1;
END;
GO
