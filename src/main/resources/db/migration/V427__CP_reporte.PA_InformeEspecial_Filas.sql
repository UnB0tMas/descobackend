IF OBJECT_ID(N'[reporte].[PA_InformeEspecial_Filas]') IS NOT NULL
    DROP PROCEDURE [reporte].[PA_InformeEspecial_Filas];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : reporte.PA_InformeEspecial_Filas
' Descripción            : Ejecuta el proceso de informe especial filas.
' Aplicativo / Módulo    : DESCO / reporte
*******************************************************************************************************/
CREATE   PROCEDURE reporte.PA_InformeEspecial_Filas @trabajoId BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @uot BIGINT,@convenio BIGINT,@tipo VARCHAR(30),@desde DATE,@hasta DATE,@socio BIGINT,@predio BIGINT,@campania BIGINT;
 SELECT @uot=uot_id,@convenio=convenio_id,@tipo=tipo,@desde=fecha_desde,@hasta=fecha_hasta,
 @socio=socio_id,@predio=predio_id,@campania=campania_id
 FROM reporte.TrabajoEspecial WHERE trabajo_id=@trabajoId AND estado='PROCESANDO' AND formato='XLSX';
 IF @tipo NOT IN('AP_SOCIOS','AP_PREDIOS','AP_CAMPANIAS','AP_VENTAS','AP_COMPRADORES','AP_LIQUIDACIONES','AP_PAGOS')
 THROW 51070,N'El informe no está disponible.',1;
 IF @tipo='AP_SOCIOS'
 SELECT S.socio_id SocioId,S.codigo_socio Codigo,CONCAT(P.nombres,N' ',P.apellido_paterno) Nombre,
 S.situacion_membresia Situacion,S.fecha_desde FechaAlta,S.fecha_hasta FechaBaja
 FROM org.SocioAsociacion S JOIN org.Asociacion A ON A.asociacion_id=S.asociacion_id AND A.uot_id=@uot
   AND A.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio)
 JOIN org.Persona P ON P.persona_id=S.socio_id WHERE S.estado=1 AND (@socio IS NULL OR S.socio_id=@socio)
 AND (S.fecha_hasta IS NULL OR S.fecha_hasta>=@desde) AND S.fecha_desde<=@hasta ORDER BY P.apellido_paterno,S.socio_id;
 ELSE IF @tipo='AP_PREDIOS'
 SELECT P.predio_id PredioId,P.codigo Codigo,P.nombre Predio,D.nombre Distrito,PR.nombre Provincia,DP.nombre Departamento,
 CP.nombre CentroPoblado,CASE WHEN U.posicion IS NOT NULL THEN U.posicion.Lat END Latitud,CASE WHEN U.posicion IS NOT NULL THEN U.posicion.Long END Longitud
 FROM prod.Predio P JOIN prod.PredioAmbito A ON A.predio_id=P.predio_id AND A.uot_id=@uot AND A.convenio_uot_organizacion_id=@convenio AND A.estado=1
 JOIN geo.Ubicacion U ON U.ubicacion_id=P.ubicacion_id JOIN geo.Distrito D ON D.distrito_codigo=U.distrito_codigo
 JOIN geo.Provincia PR ON PR.provincia_codigo=D.provincia_codigo JOIN geo.Departamento DP ON DP.departamento_codigo=PR.departamento_codigo
 LEFT JOIN geo.CentroPoblado CP ON CP.centro_poblado_id=U.centro_poblado_id
 WHERE P.estado=1 AND (@predio IS NULL OR P.predio_id=@predio) ORDER BY P.nombre;
 ELSE IF @tipo='AP_CAMPANIAS'
 SELECT C.campania_venta_id CampaniaId,C.codigo Codigo,C.nombre Campania,C.fecha_inicio Inicio,C.fecha_fin Fin,C.estado_proceso Estado
 FROM comercial.CampaniaVenta C WHERE C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) AND C.estado=1 AND C.fecha_inicio<=@hasta
 AND (C.fecha_fin IS NULL OR C.fecha_fin>=@desde) AND (@campania IS NULL OR C.campania_venta_id=@campania)
 ORDER BY C.fecha_inicio,C.campania_venta_id;
 ELSE IF @tipo='AP_VENTAS'
 SELECT C.nombre Campania,O.codigo Operativo,E.codigo_lote Lote,E.fecha_hora Fecha,
 E.peso_bruto_kg PesoBrutoKg,E.tara_kg TaraKg,E.peso_rechazado_kg RechazadoKg,
 E.peso_aceptado_kg AceptadoKg,E.estado_control_calidad Calidad,E.estado_proceso Estado
 FROM comercial.EntregaSocio E JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
 JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
 JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio)
 WHERE E.estado=1 AND CONVERT(DATE,E.fecha_hora) BETWEEN @desde AND @hasta AND (@campania IS NULL OR C.campania_venta_id=@campania)
 AND (@predio IS NULL OR E.predio_id=@predio) ORDER BY E.fecha_hora,E.entrega_socio_id;
 ELSE IF @tipo='AP_COMPRADORES'
 SELECT B.comprador_apappss_id CompradorId,B.tipo Tipo,B.persona_id PersonaId,B.empresa_id EmpresaId,
 B.fecha_registro Registro
 FROM comercial.CompradorAPAPPSS B WHERE B.uot_id=@uot AND B.estado=1 AND EXISTS(SELECT 1 FROM comercial.CampaniaVenta C WHERE C.comprador_apappss_id=B.comprador_apappss_id AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio) AND C.uot_id=@uot AND C.estado=1)
 AND CONVERT(DATE,B.fecha_registro) BETWEEN @desde AND @hasta ORDER BY B.fecha_registro,B.comprador_apappss_id;
 ELSE IF @tipo='AP_LIQUIDACIONES'
 SELECT C.nombre Campania,L.liquidacion_socio_id LiquidacionId,S.socio_id SocioId,L.version Version,L.fecha_calculo Fecha,
 L.importe_bruto Bruto,L.total_ajustes Ajustes,L.total_gastos Gastos,L.total_bonificaciones Bonificaciones,
 L.importe_neto Neto,L.estado_proceso Estado
 FROM finanzas.LiquidacionSocio L JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
 JOIN org.SocioAsociacion S ON S.socio_asociacion_id=P.socio_asociacion_id
 JOIN comercial.CampaniaVenta C ON C.campania_venta_id=P.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio)
 WHERE L.estado=1 AND CONVERT(DATE,L.fecha_calculo) BETWEEN @desde AND @hasta
 AND (@socio IS NULL OR S.socio_id=@socio) AND (@campania IS NULL OR C.campania_venta_id=@campania)
 ORDER BY L.fecha_calculo,L.liquidacion_socio_id;
 ELSE IF @tipo='AP_PAGOS'
 SELECT C.nombre Campania,P.pago_socio_id PagoId,S.socio_id SocioId,P.fecha_hora Fecha,
 P.importe Importe,P.medio_pago Medio,P.numero_operacion Operacion,P.estado_proceso Estado
 FROM finanzas.PagoSocio P JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=P.liquidacion_socio_id
 JOIN comercial.ParticipacionCampaniaSocio PS ON PS.participacion_campania_socio_id=L.participacion_campania_socio_id
 JOIN org.SocioAsociacion S ON S.socio_asociacion_id=PS.socio_asociacion_id
 JOIN comercial.CampaniaVenta C ON C.campania_venta_id=PS.campania_venta_id AND C.uot_id=@uot AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@convenio)
 WHERE P.estado=1 AND CONVERT(DATE,P.fecha_hora) BETWEEN @desde AND @hasta AND (@socio IS NULL OR S.socio_id=@socio)
 AND (@campania IS NULL OR C.campania_venta_id=@campania) ORDER BY P.fecha_hora,P.pago_socio_id;
END;
GO
