IF OBJECT_ID(N'[comercial].[TR_DESCO_JabaDevolucion_Kardex]', N'TR') IS NOT NULL
    DROP TRIGGER [comercial].[TR_DESCO_JabaDevolucion_Kardex];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : comercial.TR_DESCO_JabaDevolucion_Kardex
' Descripción              : Mantiene movimientos de kardex relacionados con devoluciones de jabas.
' Tabla asociada          : comercial.JabaDevolucion
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
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE,DELETE sobre comercial.JabaDevolucion.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[comercial].[TR_DESCO_JabaDevolucion_Kardex]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER comercial.TR_DESCO_JabaDevolucion_Kardex
ON comercial.JabaDevolucion AFTER INSERT,UPDATE,DELETE AS
BEGIN
 IF ROWCOUNT_BIG()=0 RETURN;
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM deleted D LEFT JOIN inserted I ON I.jaba_devolucion_id=D.jaba_devolucion_id WHERE I.jaba_devolucion_id IS NULL)
  THROW 51100,N'DESCO_MOVIMIENTO_INMUTABLE',1;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.jaba_devolucion_id=I.jaba_devolucion_id
  WHERE I.jaba_asignacion_id<>D.jaba_asignacion_id OR ISNULL(I.entrega_socio_id,0)<>ISNULL(D.entrega_socio_id,0)
  OR I.cantidad_llenas<>D.cantidad_llenas OR I.cantidad_vacias<>D.cantidad_vacias OR I.fecha_hora<>D.fecha_hora OR (D.estado=0 AND I.estado=1))
  THROW 51100,N'DESCO_MOVIMIENTO_INMUTABLE',1;
 IF EXISTS(SELECT 1 FROM inserted I JOIN comercial.JabaAsignacion A ON A.jaba_asignacion_id=I.jaba_asignacion_id
  JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
  JOIN comercial.OperativoVenta O WITH(UPDLOCK,HOLDLOCK) ON O.operativo_venta_id=OS.operativo_venta_id
  WHERE A.estado<>1 OR O.estado_proceso<>'EN_RECEPCION' OR O.estado<>1 OR
   (I.entrega_socio_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM comercial.EntregaSocio E WHERE E.entrega_socio_id=I.entrega_socio_id
    AND E.operativo_socio_id=A.operativo_socio_id AND E.estado=1 AND E.estado_proceso<>'ANULADA')))
  THROW 51100,N'DESCO_JABA_RELACION',1;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.jaba_devolucion_id=I.jaba_devolucion_id
  JOIN comercial.EntregaSocio E ON E.entrega_socio_id=I.entrega_socio_id WHERE D.estado=1 AND I.estado=0 AND E.estado=1 AND E.estado_proceso='CONFIRMADA')
  THROW 51000,N'La devolución pertenece a una entrega confirmada.',1;
 ;WITH X AS(SELECT jaba_asignacion_id,CONVERT(BIGINT,cantidad_llenas)+cantidad_vacias cantidad FROM inserted WHERE estado=1
  UNION ALL SELECT jaba_asignacion_id,-(CONVERT(BIGINT,cantidad_llenas)+cantidad_vacias) FROM deleted WHERE estado=1),
 D AS(SELECT jaba_asignacion_id,SUM(cantidad) cantidad FROM X GROUP BY jaba_asignacion_id)
 UPDATE A SET cantidad_devuelta=A.cantidad_devuelta+D.cantidad FROM comercial.JabaAsignacion A JOIN D ON D.jaba_asignacion_id=A.jaba_asignacion_id;
 INSERT comercial.JabaMovimiento(operativo_venta_id,operativo_socio_id,jaba_asignacion_id,jaba_devolucion_id,tipo_movimiento,cantidad,fecha_hora,usuario_id,motivo,estado)
 SELECT OS.operativo_venta_id,A.operativo_socio_id,I.jaba_asignacion_id,I.jaba_devolucion_id,X.tipo,X.cantidad,I.fecha_hora,I.usuario_registro_id,I.observacion,1
 FROM inserted I LEFT JOIN deleted D ON D.jaba_devolucion_id=I.jaba_devolucion_id
 JOIN comercial.JabaAsignacion A ON A.jaba_asignacion_id=I.jaba_asignacion_id JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
 CROSS APPLY(VALUES('DEVOLUCION_LLENA',I.cantidad_llenas),('DEVOLUCION_VACIA',I.cantidad_vacias)) X(tipo,cantidad)
 WHERE D.jaba_devolucion_id IS NULL AND I.estado=1 AND X.cantidad>0;
 UPDATE M SET estado=0,fecha_anulacion=I.fecha_anulacion,usuario_anulacion_id=I.usuario_anulacion_id,motivo_anulacion=I.motivo_anulacion
 FROM comercial.JabaMovimiento M JOIN inserted I ON I.jaba_devolucion_id=M.jaba_devolucion_id
 JOIN deleted D ON D.jaba_devolucion_id=I.jaba_devolucion_id WHERE I.estado=0 AND D.estado=1 AND M.estado=1;
END;
GO
