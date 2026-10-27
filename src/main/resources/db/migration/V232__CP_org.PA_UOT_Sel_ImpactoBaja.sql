IF OBJECT_ID(N'[org].[PA_UOT_Sel_ImpactoBaja]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_UOT_Sel_ImpactoBaja];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_UOT_Sel_ImpactoBaja
' Descripción             : Consulta el impacto de deshabilitar una unidad organizativa territorial.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Organización
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo: sustituir identificadores y valores por datos válidos.
    DECLARE
        @nUotIncluidas INT,
        @nUsuariosActivos INT,
        @nUsuariosExclusivos INT,
        @nEmpleadosActivos INT,
        @nAreasActivas INT,
        @nOrganizacionesActivas INT,
        @nPrediosActivos INT,
        @nAlmacenesActivos INT,
        @nProductosConStock INT,
        @nStockReservado INT,
        @nSuministrosConStock INT,
        @nSuministrosReservados INT,
        @nBienesActivos INT,
        @nVentasAbiertas INT,
        @nCampaniasAbiertas INT,
        @nOperativosAbiertos INT,
        @nSalidasAbiertas INT,
        @nRecursosAbiertos INT,
        @bPuedeDeshabilitar BIT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [org].[PA_UOT_Sel_ImpactoBaja]
        @nUsuarioId = 0,
        @nUotId = 0,
        @nUotIncluidas = @nUotIncluidas OUTPUT,
        @nUsuariosActivos = @nUsuariosActivos OUTPUT,
        @nUsuariosExclusivos = @nUsuariosExclusivos OUTPUT,
        @nEmpleadosActivos = @nEmpleadosActivos OUTPUT,
        @nAreasActivas = @nAreasActivas OUTPUT,
        @nOrganizacionesActivas = @nOrganizacionesActivas OUTPUT,
        @nPrediosActivos = @nPrediosActivos OUTPUT,
        @nAlmacenesActivos = @nAlmacenesActivos OUTPUT,
        @nProductosConStock = @nProductosConStock OUTPUT,
        @nStockReservado = @nStockReservado OUTPUT,
        @nSuministrosConStock = @nSuministrosConStock OUTPUT,
        @nSuministrosReservados = @nSuministrosReservados OUTPUT,
        @nBienesActivos = @nBienesActivos OUTPUT,
        @nVentasAbiertas = @nVentasAbiertas OUTPUT,
        @nCampaniasAbiertas = @nCampaniasAbiertas OUTPUT,
        @nOperativosAbiertos = @nOperativosAbiertos OUTPUT,
        @nSalidasAbiertas = @nSalidasAbiertas OUTPUT,
        @nRecursosAbiertos = @nRecursosAbiertos OUTPUT,
        @bPuedeDeshabilitar = @bPuedeDeshabilitar OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nUotIncluidas, @nUsuariosActivos, @nUsuariosExclusivos, @nEmpleadosActivos, @nAreasActivas, @nOrganizacionesActivas, @nPrediosActivos, @nAlmacenesActivos, @nProductosConStock, @nStockReservado, @nSuministrosConStock, @nSuministrosReservados, @nBienesActivos, @nVentasAbiertas, @nCampaniasAbiertas, @nOperativosAbiertos, @nSalidasAbiertas, @nRecursosAbiertos, @bPuedeDeshabilitar, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE org.PA_UOT_Sel_ImpactoBaja
 @nUsuarioId BIGINT,@nUotId BIGINT,
 @nUotIncluidas INT OUTPUT,@nUsuariosActivos INT OUTPUT,@nUsuariosExclusivos INT OUTPUT,@nEmpleadosActivos INT OUTPUT,
 @nAreasActivas INT OUTPUT,@nOrganizacionesActivas INT OUTPUT,@nPrediosActivos INT OUTPUT,@nAlmacenesActivos INT OUTPUT,
 @nProductosConStock INT OUTPUT,@nStockReservado INT OUTPUT,@nSuministrosConStock INT OUTPUT,@nSuministrosReservados INT OUTPUT,
 @nBienesActivos INT OUTPUT,@nVentasAbiertas INT OUTPUT,@nCampaniasAbiertas INT OUTPUT,@nOperativosAbiertos INT OUTPUT,@nSalidasAbiertas INT OUTPUT,@nRecursosAbiertos INT OUTPUT,
 @bPuedeDeshabilitar BIT OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @nUotIncluidas=0,@nUsuariosActivos=0,@nUsuariosExclusivos=0,@nEmpleadosActivos=0,@nAreasActivas=0,@nOrganizacionesActivas=0,@nPrediosActivos=0,@nAlmacenesActivos=0,
        @nProductosConStock=0,@nStockReservado=0,@nSuministrosConStock=0,@nSuministrosReservados=0,@nBienesActivos=0,@nVentasAbiertas=0,@nCampaniasAbiertas=0,@nOperativosAbiertos=0,@nSalidasAbiertas=0,@nRecursosAbiertos=0,
        @bPuedeDeshabilitar=0,@bResultado=0,@cMensaje=N'No se pudo revisar la UOT.',@cCodigoRespuesta='UOT_IMPACTO_NO_DISPONIBLE',@nHttpRespuesta=400;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'UOT_RETIRAR')=0 BEGIN SET @cMensaje=N'No tiene permiso para retirar esta UOT.'; RETURN 1; END;
 IF NOT EXISTS(SELECT 1 FROM org.UOT WHERE uot_id=@nUotId AND estado=1) BEGIN SET @cMensaje=N'La UOT no esta disponible.'; RETURN 1; END;
 DECLARE @Rama TABLE(uot_id BIGINT PRIMARY KEY);
 ;WITH R AS(SELECT uot_id FROM org.UOT WHERE uot_id=@nUotId AND estado=1 UNION ALL SELECT U.uot_id FROM org.UOT U JOIN R ON U.uot_padre_id=R.uot_id WHERE U.estado=1)
 INSERT @Rama SELECT uot_id FROM R OPTION(MAXRECURSION 100);
 SELECT @nUotIncluidas=COUNT(*) FROM @Rama;
 SELECT @nUsuariosActivos=COUNT(DISTINCT UU.usuario_id) FROM seg.UsuarioUOT UU JOIN @Rama R ON R.uot_id=UU.uot_id WHERE UU.estado=1 AND UU.fecha_hasta IS NULL;
 SELECT @nUsuariosExclusivos=COUNT(*) FROM(SELECT UU.usuario_id FROM seg.UsuarioUOT UU JOIN @Rama R ON R.uot_id=UU.uot_id WHERE UU.estado=1 AND UU.fecha_hasta IS NULL GROUP BY UU.usuario_id HAVING NOT EXISTS(SELECT 1 FROM seg.UsuarioUOT X JOIN org.UOT UX ON UX.uot_id=X.uot_id AND UX.estado=1 WHERE X.usuario_id=UU.usuario_id AND X.estado=1 AND X.fecha_hasta IS NULL AND NOT EXISTS(SELECT 1 FROM @Rama RR WHERE RR.uot_id=X.uot_id))) Q;
 SELECT @nEmpleadosActivos=COUNT(DISTINCT EU.empleado_id) FROM org.EmpleadoUOT EU JOIN @Rama R ON R.uot_id=EU.uot_id WHERE EU.estado=1 AND EU.fecha_hasta IS NULL;
 SELECT @nAreasActivas=COUNT(*) FROM org.Area A JOIN @Rama R ON R.uot_id=A.uot_id WHERE A.estado=1;
 SELECT @nOrganizacionesActivas=COUNT(*) FROM org.ConvenioUOTOrganizacion C JOIN @Rama R ON R.uot_id=C.uot_id WHERE C.estado=1 AND C.fecha_fin IS NULL;
 SELECT @nPrediosActivos=COUNT(*) FROM prod.Predio P JOIN @Rama R ON R.uot_id=P.uot_id WHERE P.estado=1;
 SELECT @nAlmacenesActivos=COUNT(*) FROM logistica.Almacen A JOIN @Rama R ON R.uot_id=A.uot_propietaria_id WHERE A.estado=1;
 SELECT @nProductosConStock=COUNT(*) FROM logistica.AlmacenProductoStock S JOIN logistica.Almacen A ON A.almacen_id=S.almacen_id JOIN @Rama R ON R.uot_id=A.uot_propietaria_id WHERE S.stock_actual<>0;
 SELECT @nStockReservado=COUNT(*) FROM logistica.AlmacenProductoStock S JOIN logistica.Almacen A ON A.almacen_id=S.almacen_id JOIN @Rama R ON R.uot_id=A.uot_propietaria_id WHERE S.stock_reservado<>0;
 SELECT @nSuministrosConStock=COUNT(*) FROM logistica.Suministro S JOIN @Rama R ON R.uot_id=S.uot_id JOIN logistica.SuministroSaldo K ON K.suministro_id=S.suministro_id WHERE S.estado=1 AND K.stock_actual<>0;
 SELECT @nSuministrosReservados=COUNT(*) FROM logistica.Suministro S JOIN @Rama R ON R.uot_id=S.uot_id JOIN logistica.SuministroSaldo K ON K.suministro_id=S.suministro_id WHERE S.estado=1 AND K.stock_reservado<>0;
 SELECT @nBienesActivos=COUNT(*) FROM logistica.BienInventario B JOIN @Rama R ON R.uot_id=B.uot_id WHERE B.estado=1 AND B.estado_bien<>'BAJA';
 SELECT @nVentasAbiertas=COUNT(*) FROM comercial.Venta V JOIN @Rama R ON R.uot_id=V.uot_id WHERE V.estado=1 AND V.estado_venta NOT IN('ENTREGADA','ANULADA');
 SELECT @nCampaniasAbiertas=COUNT(*) FROM comercial.CampaniaVenta C JOIN @Rama R ON R.uot_id=C.uot_id WHERE C.estado=1 AND C.estado_proceso NOT IN('CERRADA','CANCELADA');
 SELECT @nOperativosAbiertos=COUNT(*) FROM comercial.OperativoVenta O JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id JOIN @Rama R ON R.uot_id=C.uot_id WHERE O.estado=1 AND O.estado_proceso NOT IN('CERRADO','CANCELADO');
 SELECT @nSalidasAbiertas=COUNT(*) FROM campo.SalidaCampo S JOIN @Rama R ON R.uot_id=S.uot_id WHERE S.estado=1 AND S.estado_proceso NOT IN('FINALIZADA','CANCELADA');
 SELECT @nRecursosAbiertos=COUNT(*) FROM logistica.RecursoProgramado RP WHERE RP.estado=1 AND RP.estado_proceso NOT IN('COMPLETADO','CANCELADO') AND(EXISTS(SELECT 1 FROM comercial.CampaniaVenta C JOIN @Rama R ON R.uot_id=C.uot_id WHERE C.campania_venta_id=RP.campania_venta_id) OR EXISTS(SELECT 1 FROM comercial.OperativoVenta O JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id JOIN @Rama R ON R.uot_id=C.uot_id WHERE O.operativo_venta_id=RP.operativo_venta_id) OR EXISTS(SELECT 1 FROM campo.SalidaCampo S JOIN @Rama R ON R.uot_id=S.uot_id WHERE S.salida_campo_id=RP.salida_campo_id));
 SET @bPuedeDeshabilitar=CASE WHEN @nProductosConStock=0 AND @nStockReservado=0 AND @nSuministrosConStock=0 AND @nSuministrosReservados=0 AND @nBienesActivos=0 AND @nVentasAbiertas=0 AND @nCampaniasAbiertas=0 AND @nOperativosAbiertos=0 AND @nSalidasAbiertas=0 AND @nRecursosAbiertos=0 THEN 1 ELSE 0 END;
 SELECT @bResultado=1,@cMensaje=CASE WHEN @bPuedeDeshabilitar=1 THEN N'La UOT puede retirarse.' ELSE N'La UOT tiene recursos u operaciones pendientes.' END,@cCodigoRespuesta='UOT_IMPACTO_CONSULTADO',@nHttpRespuesta=200; RETURN 0;
END;
GO
