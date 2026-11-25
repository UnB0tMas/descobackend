IF OBJECT_ID(N'[reporte].[PA_Excel_Sel_Filas]') IS NOT NULL
    DROP PROCEDURE [reporte].[PA_Excel_Sel_Filas];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : reporte.PA_Excel_Sel_Filas
' Descripción            : Consulta excel para filas.
' Aplicativo / Módulo    : DESCO / reporte
*******************************************************************************************************/
CREATE   PROCEDURE reporte.PA_Excel_Sel_Filas @nTrabajoId BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @c VARCHAR(35),@u BIGINT,@uot BIGINT,@d DATE,@h DATE,@a BIGINT,@p BIGINT,
         @perm VARCHAR(40),@t0 DATETIME2(0),@t1 DATETIME2(0);
 SELECT @c=codigo,@u=usuario_id,@uot=uot_id,@d=fecha_desde,@h=fecha_hasta,@a=almacen_id,@p=predio_id
 FROM reporte.TrabajoExcel WHERE trabajo_id=@nTrabajoId AND estado='PROCESANDO';
 IF @u IS NULL THROW 51022,N'No existe el reporte pendiente.',1;
 SET @perm=CASE WHEN @c LIKE 'POS[_]%' THEN 'VENTAS_REPORTES'
                WHEN @c='TEC_VISITAS' THEN 'VISITAS_LISTAR' WHEN @c='TEC_SALIDAS' THEN 'SALIDAS_LISTAR'
                WHEN @c='TEC_SANIDAD' THEN 'SANIDAD_LISTAR' WHEN @c LIKE 'REC[_]%' THEN 'INVENTARIO_LISTAR'
                WHEN @c='DOC_EVIDENCIAS' THEN 'ARCHIVOS_LISTAR' ELSE 'DOCS_VER' END;
 IF ISNULL(seg.FN_Usuario_TienePermisoUOT(@u,@uot,'REPORTES_CONTROL_VER'),0)<>1
 OR ISNULL(seg.FN_Usuario_TienePermisoUOT(@u,@uot,'REPORTES_EXPORTAR'),0)<>1
 OR ISNULL(seg.FN_Usuario_TienePermisoUOT(@u,@uot,@perm),0)<>1
 OR (@c='DOC_CORRESPONDENCIA' AND ISNULL(seg.FN_Usuario_TienePermisoUOT(@u,@uot,'DOCS_LISTAR'),0)<>1)
 OR NOT EXISTS(SELECT 1 FROM seg.UsuarioUOT WHERE usuario_id=@u AND uot_id=@uot AND estado=1
    AND fecha_desde<=SYSUTCDATETIME() AND (fecha_hasta IS NULL OR fecha_hasta>=SYSUTCDATETIME()))
 THROW 51023,N'No tiene autorización vigente para consultar este reporte.',1;
 SET @t0=CONVERT(DATETIME2(0),(CAST(@d AS DATETIME2(0)) AT TIME ZONE 'SA Pacific Standard Time') AT TIME ZONE 'UTC');
 SET @t1=CONVERT(DATETIME2(0),(CAST(DATEADD(DAY,1,@h) AS DATETIME2(0)) AT TIME ZONE 'SA Pacific Standard Time') AT TIME ZONE 'UTC');
 IF @c='POS_VENTAS'
  SELECT TOP(100001) V.venta_id AS [Venta],DATEADD(HOUR,-5,V.fecha_hora) AS [Fecha],
    COALESCE(C.nombre,N'Sin caja') AS [Caja],V.moneda AS [Moneda],V.subtotal AS [Subtotal],
    V.descuento AS [Descuento],V.impuesto AS [Impuesto],V.total AS [Total],V.estado_venta AS [Estado]
  FROM comercial.Venta V LEFT JOIN comercial.CajaSesion CS ON CS.caja_sesion_id=V.caja_sesion_id
  LEFT JOIN comercial.CajaPOS C ON C.caja_id=CS.caja_id AND C.uot_id=@uot
  WHERE V.uot_id=@uot AND V.estado=1 AND V.moneda='PEN' AND V.estado_venta IN('PAGADA','ENTREGADA')
    AND V.fecha_hora>=@t0 AND V.fecha_hora<@t1 AND (@a IS NULL OR V.almacen_id=@a)
  ORDER BY V.fecha_hora,V.venta_id;
 ELSE IF @c='POS_DETALLE'
  SELECT TOP(100001) V.venta_id AS [Venta],DATEADD(HOUR,-5,V.fecha_hora) AS [Fecha],
    P.codigo AS [Código],P.nombre AS [Producto],D.cantidad AS [Cantidad],
    D.precio_unitario AS [Precio unitario],D.descuento_unitario AS [Descuento unitario],D.subtotal AS [Importe]
  FROM comercial.Venta V JOIN comercial.DetalleVenta D ON D.venta_id=V.venta_id AND D.estado=1
  JOIN logistica.Producto P ON P.producto_id=D.producto_id
  WHERE V.uot_id=@uot AND V.estado=1 AND V.moneda='PEN' AND V.estado_venta IN('PAGADA','ENTREGADA')
    AND V.fecha_hora>=@t0 AND V.fecha_hora<@t1 AND (@a IS NULL OR V.almacen_id=@a)
  ORDER BY V.fecha_hora,V.venta_id,D.detalle_venta_id;
 ELSE IF @c='TEC_VISITAS'
  SELECT TOP(100001) VT.visita_tecnica_id AS [Visita],DATEADD(HOUR,-5,VT.fecha_hora_inicio) AS [Inicio],
    DATEADD(HOUR,-5,VT.fecha_hora_fin) AS [Fin],P.nombre AS [Predio],
    VT.objetivo AS [Objetivo],VT.estado_proceso AS [Estado],VT.resumen AS [Resumen]
  FROM campo.VisitaTecnica VT JOIN campo.SalidaParticipante SP ON SP.salida_participante_id=VT.salida_participante_id
  JOIN campo.SalidaCampo SC ON SC.salida_campo_id=SP.salida_campo_id AND SC.uot_id=@uot
  JOIN prod.Predio P ON P.predio_id=VT.predio_id AND P.uot_id=@uot
  LEFT JOIN campo.SalidaE2 E ON E.salida_campo_id=SC.salida_campo_id
  WHERE VT.estado=1 AND SC.estado=1 AND (E.salida_campo_id IS NULL OR E.convenio_id IS NULL)
   AND VT.fecha_hora_inicio>=@t0 AND VT.fecha_hora_inicio<@t1 AND (@p IS NULL OR VT.predio_id=@p)
   AND EXISTS(SELECT 1 FROM prod.PredioAmbito A WHERE A.predio_id=P.predio_id AND A.uot_id=@uot AND A.estado=1 AND A.convenio_uot_organizacion_id IS NULL)
  ORDER BY VT.fecha_hora_inicio,VT.visita_tecnica_id;
 ELSE IF @c='TEC_SALIDAS'
  SELECT TOP(100001) S.salida_campo_id AS [Salida],DATEADD(HOUR,-5,S.fecha_hora_programada) AS [Programada],
    DATEADD(HOUR,-5,S.fecha_hora_salida_real) AS [Inicio real],DATEADD(HOUR,-5,S.fecha_hora_retorno_real) AS [Retorno],
    M.nombre AS [Motivo],S.estado_proceso AS [Estado],S.descripcion AS [Descripción]
  FROM campo.SalidaCampo S JOIN campo.MotivoSalida M ON M.motivo_salida_id=S.motivo_salida_id
  LEFT JOIN campo.SalidaE2 E ON E.salida_campo_id=S.salida_campo_id
  WHERE S.uot_id=@uot AND S.estado=1 AND (E.salida_campo_id IS NULL OR E.convenio_id IS NULL)
    AND S.fecha_hora_programada>=@t0 AND S.fecha_hora_programada<@t1
    AND (@p IS NULL OR EXISTS(SELECT 1 FROM campo.VisitaTecnica V JOIN campo.SalidaParticipante SP ON SP.salida_participante_id=V.salida_participante_id WHERE SP.salida_campo_id=S.salida_campo_id AND V.predio_id=@p))
  ORDER BY S.fecha_hora_programada,S.salida_campo_id;
 ELSE IF @c='TEC_SANIDAD'
  SELECT TOP(100001) C.caso_fitosanitario_id AS [Caso],DATEADD(HOUR,-5,C.fecha_deteccion) AS [Detección],
    P.nombre AS [Predio],C.severidad AS [Severidad],C.estado_caso AS [Estado],
    C.plantas_afectadas AS [Plantas afectadas],C.observacion AS [Observación]
  FROM sanidad.CasoFitosanitario C JOIN prod.ParcelaCultivo PC ON PC.parcela_cultivo_id=C.parcela_cultivo_id
  JOIN prod.Parcela PA ON PA.parcela_id=PC.parcela_id JOIN prod.Predio P ON P.predio_id=PA.predio_id AND P.uot_id=@uot
  WHERE C.estado=1 AND C.fecha_deteccion>=@t0 AND C.fecha_deteccion<@t1
   AND (@p IS NULL OR P.predio_id=@p) AND EXISTS(SELECT 1 FROM prod.PredioAmbito A WHERE A.predio_id=P.predio_id AND A.uot_id=@uot AND A.estado=1 AND A.convenio_uot_organizacion_id IS NULL)
  ORDER BY C.fecha_deteccion,C.caso_fitosanitario_id;
 ELSE IF @c='REC_MOVIMIENTOS'
  SELECT TOP(100001) M.movimiento_inventario_id AS [Movimiento],DATEADD(HOUR,-5,M.fecha_hora) AS [Fecha],
    A.nombre AS [Almacén],M.tipo_movimiento AS [Tipo],M.naturaleza AS [Naturaleza],M.documento_referencia AS [Referencia],M.observacion AS [Observación]
  FROM logistica.MovimientoInventario M JOIN logistica.Almacen A ON A.almacen_id=M.almacen_id
  WHERE M.uot_id=@uot AND M.estado=1 AND M.fecha_hora>=@t0 AND M.fecha_hora<@t1 AND (@a IS NULL OR M.almacen_id=@a)
  ORDER BY M.fecha_hora,M.movimiento_inventario_id;
 ELSE IF @c='REC_PRODUCTOS'
  SELECT TOP(100001) M.movimiento_inventario_id AS [Movimiento],DATEADD(HOUR,-5,M.fecha_hora) AS [Fecha],A.nombre AS [Almacén],
    P.codigo AS [Código],P.nombre AS [Producto],M.naturaleza AS [Naturaleza],D.cantidad AS [Cantidad],D.costo_unitario AS [Costo unitario]
  FROM logistica.MovimientoInventario M JOIN logistica.DetalleMovimientoInventario D ON D.movimiento_inventario_id=M.movimiento_inventario_id
  JOIN logistica.Producto P ON P.producto_id=D.producto_id JOIN logistica.Almacen A ON A.almacen_id=M.almacen_id
  WHERE M.uot_id=@uot AND M.estado=1 AND M.fecha_hora>=@t0 AND M.fecha_hora<@t1 AND (@a IS NULL OR M.almacen_id=@a)
  ORDER BY M.fecha_hora,M.movimiento_inventario_id,D.detalle_movimiento_inventario_id;
 ELSE IF @c='DOC_EVIDENCIAS'
  SELECT TOP(100001) F.archivo_id AS [Archivo],DATEADD(HOUR,-5,F.fecha_carga) AS [Fecha],F.nombre_original AS [Nombre],
    F.categoria AS [Categoría],F.tipo_evidencia AS [Tipo],F.mime_type AS [Formato],F.tamano_bytes AS [Tamaño bytes]
  FROM archivo.Archivo F
  WHERE F.uot_id=@uot AND F.estado=1 AND F.fecha_carga>=@t0 AND F.fecha_carga<@t1
    AND NOT EXISTS(SELECT 1 FROM archivo.ArchivoVinculo V WHERE V.archivo_id=F.archivo_id AND V.estado=1
       AND (V.campania_venta_id IS NOT NULL OR V.entrega_socio_id IS NOT NULL OR V.liquidacion_socio_id IS NOT NULL
            OR V.operativo_venta_id IS NOT NULL OR V.participacion_campania_socio_id IS NOT NULL))
  ORDER BY F.fecha_carga,F.archivo_id;
 ELSE IF @c='DOC_CORRESPONDENCIA'
  SELECT TOP(100001) D.documento_id AS [Documento],DATEADD(HOUR,-5,D.fecha_envio) AS [Fecha],T.nombre AS [Tipo],
    D.asunto AS [Asunto],D.emisor_usuario_id AS [Emisor],
    (SELECT COUNT_BIG(*) FROM doc.Destinatario E WHERE E.documento_id=D.documento_id) AS [Destinatarios]
  FROM doc.Documento D JOIN doc.Hilo H ON H.hilo_id=D.hilo_id AND H.uot_id=@uot
  JOIN doc.TipoDocumento T ON T.tipo_documento_id=D.tipo_documento_id
  WHERE D.fecha_envio>=@t0 AND D.fecha_envio<@t1
    AND (D.emisor_usuario_id=@u OR EXISTS(SELECT 1 FROM doc.Participante P WHERE P.hilo_id=H.hilo_id AND P.usuario_id=@u))
  ORDER BY D.fecha_envio,D.documento_id;
END;
GO
