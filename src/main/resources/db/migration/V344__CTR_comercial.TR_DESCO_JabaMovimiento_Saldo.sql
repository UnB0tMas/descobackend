IF OBJECT_ID(N'[comercial].[TR_DESCO_JabaMovimiento_Saldo]', N'TR') IS NOT NULL
    DROP TRIGGER [comercial].[TR_DESCO_JabaMovimiento_Saldo];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : comercial.TR_DESCO_JabaMovimiento_Saldo
' Descripción              : Controla los saldos de movimientos de jabas.
' Tabla asociada          : comercial.JabaMovimiento
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
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE,DELETE sobre comercial.JabaMovimiento.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[comercial].[TR_DESCO_JabaMovimiento_Saldo]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER comercial.TR_DESCO_JabaMovimiento_Saldo
ON comercial.JabaMovimiento AFTER INSERT,UPDATE,DELETE AS
BEGIN
 IF ROWCOUNT_BIG()=0 RETURN;
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM deleted D LEFT JOIN inserted I ON I.jaba_movimiento_id=D.jaba_movimiento_id WHERE I.jaba_movimiento_id IS NULL)
  THROW 51100,N'DESCO_MOVIMIENTO_INMUTABLE',1;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.jaba_movimiento_id=I.jaba_movimiento_id
  WHERE I.operativo_venta_id<>D.operativo_venta_id OR ISNULL(I.operativo_socio_id,0)<>ISNULL(D.operativo_socio_id,0)
  OR ISNULL(I.jaba_asignacion_id,0)<>ISNULL(D.jaba_asignacion_id,0) OR ISNULL(I.jaba_devolucion_id,0)<>ISNULL(D.jaba_devolucion_id,0)
  OR I.cantidad<>D.cantidad OR I.tipo_movimiento<>D.tipo_movimiento OR I.fecha_hora<>D.fecha_hora OR (D.estado=0 AND I.estado=1))
  THROW 51100,N'DESCO_MOVIMIENTO_INMUTABLE',1;
 IF EXISTS(SELECT 1 FROM inserted I JOIN comercial.OperativoVenta O WITH(UPDLOCK,HOLDLOCK) ON O.operativo_venta_id=I.operativo_venta_id
  WHERE O.estado<>1 OR O.estado_proceso NOT IN('PLANIFICADO','EN_RECEPCION'))
  THROW 51100,N'DESCO_RECURSO_NO_DISPONIBLE',1;
 IF EXISTS(SELECT 1 FROM inserted I WHERE I.tipo_movimiento='ASIGNACION' AND NOT EXISTS(
  SELECT 1 FROM comercial.JabaAsignacion A JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
  WHERE A.jaba_asignacion_id=I.jaba_asignacion_id AND A.cantidad_asignada=I.cantidad AND A.estado=I.estado
   AND OS.operativo_venta_id=I.operativo_venta_id AND OS.operativo_socio_id=I.operativo_socio_id))
  THROW 51100,N'DESCO_JABA_RELACION',1;
 IF EXISTS(SELECT 1 FROM inserted I WHERE I.tipo_movimiento IN('DEVOLUCION_LLENA','DEVOLUCION_VACIA') AND NOT EXISTS(
  SELECT 1 FROM comercial.JabaDevolucion D JOIN comercial.JabaAsignacion A ON A.jaba_asignacion_id=D.jaba_asignacion_id
  JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
  WHERE D.jaba_devolucion_id=I.jaba_devolucion_id AND D.jaba_asignacion_id=I.jaba_asignacion_id AND D.estado=I.estado
   AND OS.operativo_venta_id=I.operativo_venta_id AND OS.operativo_socio_id=I.operativo_socio_id
   AND I.cantidad=CASE WHEN I.tipo_movimiento='DEVOLUCION_LLENA' THEN D.cantidad_llenas ELSE D.cantidad_vacias END))
  THROW 51100,N'DESCO_JABA_RELACION',1;
 ;WITH X AS(SELECT operativo_venta_id,tipo_movimiento,CONVERT(BIGINT,cantidad) cantidad FROM inserted WHERE estado=1
 UNION ALL SELECT operativo_venta_id,tipo_movimiento,-CONVERT(BIGINT,cantidad) FROM deleted WHERE estado=1),
 D AS(SELECT operativo_venta_id,
 SUM(CASE WHEN tipo_movimiento IN('RECEPCION','AJUSTE_ENTRADA') THEN cantidad WHEN tipo_movimiento='AJUSTE_SALIDA' THEN -cantidad ELSE 0 END) recibidas,
 SUM(CASE WHEN tipo_movimiento='ASIGNACION' THEN cantidad ELSE 0 END) asignadas,
 SUM(CASE WHEN tipo_movimiento='DEVOLUCION_LLENA' THEN cantidad ELSE 0 END) llenas,
 SUM(CASE WHEN tipo_movimiento='DEVOLUCION_VACIA' THEN cantidad ELSE 0 END) vacias
 FROM X GROUP BY operativo_venta_id)
 UPDATE S SET recibidas=S.recibidas+D.recibidas,asignadas=S.asignadas+D.asignadas,
 devueltas_llenas=S.devueltas_llenas+D.llenas,devueltas_vacias=S.devueltas_vacias+D.vacias,fecha_actualizacion=SYSUTCDATETIME()
 FROM comercial.JabaSaldoOperativo S JOIN D ON D.operativo_venta_id=S.operativo_venta_id;
 UPDATE O SET cantidad_jabas_recibidas=CONVERT(INT,S.recibidas)
 FROM comercial.OperativoVenta O JOIN comercial.JabaSaldoOperativo S ON S.operativo_venta_id=O.operativo_venta_id
 WHERE EXISTS(SELECT 1 FROM inserted I WHERE I.operativo_venta_id=O.operativo_venta_id)
 OR EXISTS(SELECT 1 FROM deleted D WHERE D.operativo_venta_id=O.operativo_venta_id);
END;
GO
