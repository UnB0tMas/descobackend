IF OBJECT_ID(N'[org].[PA_UOT_Upd_Deshabilitar]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_UOT_Upd_Deshabilitar];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_UOT_Upd_Deshabilitar
' Descripción             : Deshabilita una unidad organizativa territorial.
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
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [org].[PA_UOT_Upd_Deshabilitar]
        @nUsuarioId = 0,
        @nUotId = 0,
        @cMotivo = N'',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE org.PA_UOT_Upd_Deshabilitar
 @nUsuarioId BIGINT,@nUotId BIGINT,@cMotivo NVARCHAR(500),
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON; SELECT @bResultado=0,@cMensaje=N'No se pudo retirar la UOT.',@cCodigoRespuesta='UOT_NO_RETIRADA',@nHttpRespuesta=409;
 SET @cMotivo=NULLIF(LTRIM(RTRIM(@cMotivo)),N''); IF @cMotivo IS NULL BEGIN SET @cMensaje=N'Indique el motivo de la baja.'; RETURN 1; END;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'UOT_RETIRAR')=0 BEGIN SET @cMensaje=N'No tiene permiso para retirar esta UOT.'; RETURN 1; END;
 IF EXISTS(SELECT 1 FROM org.UOT WHERE uot_id=@nUotId AND es_raiz=1) BEGIN SET @cMensaje=N'La UOT raiz no puede retirarse.'; RETURN 1; END;
 DECLARE @Rama TABLE(uot_id BIGINT PRIMARY KEY); ;WITH R AS(SELECT uot_id FROM org.UOT WHERE uot_id=@nUotId AND estado=1 UNION ALL SELECT U.uot_id FROM org.UOT U JOIN R ON U.uot_padre_id=R.uot_id WHERE U.estado=1) INSERT @Rama SELECT uot_id FROM R OPTION(MAXRECURSION 100);
 IF NOT EXISTS(SELECT 1 FROM @Rama) BEGIN SET @cMensaje=N'La UOT ya no esta disponible.'; RETURN 1; END;
 IF EXISTS(SELECT 1 FROM logistica.AlmacenProductoStock S JOIN logistica.Almacen A ON A.almacen_id=S.almacen_id JOIN @Rama R ON R.uot_id=A.uot_propietaria_id WHERE S.stock_actual<>0 OR S.stock_reservado<>0) BEGIN SET @cMensaje=N'Transfiera o regularice el stock antes de retirar la UOT.'; RETURN 1; END;
 IF EXISTS(SELECT 1 FROM logistica.Suministro S JOIN @Rama R ON R.uot_id=S.uot_id JOIN logistica.SuministroSaldo K ON K.suministro_id=S.suministro_id WHERE S.estado=1 AND (K.stock_actual<>0 OR K.stock_reservado<>0)) BEGIN SET @cMensaje=N'Transfiera o regularice los suministros antes de retirar la UOT.'; RETURN 1; END;
 IF EXISTS(SELECT 1 FROM logistica.BienInventario B JOIN @Rama R ON R.uot_id=B.uot_id WHERE B.estado=1 AND B.estado_bien<>'BAJA') BEGIN SET @cMensaje=N'Transfiera o retire los bienes antes de retirar la UOT.'; RETURN 1; END;
 IF EXISTS(SELECT 1 FROM comercial.Venta V JOIN @Rama R ON R.uot_id=V.uot_id WHERE V.estado=1 AND V.estado_venta NOT IN('ENTREGADA','ANULADA')) BEGIN SET @cMensaje=N'Cierre o anule las ventas pendientes.'; RETURN 1; END;
 IF EXISTS(SELECT 1 FROM comercial.CampaniaVenta C JOIN @Rama R ON R.uot_id=C.uot_id WHERE C.estado=1 AND C.estado_proceso NOT IN('CERRADA','CANCELADA')) BEGIN SET @cMensaje=N'Cierre o cancele las campanias pendientes.'; RETURN 1; END;
 IF EXISTS(SELECT 1 FROM campo.SalidaCampo S JOIN @Rama R ON R.uot_id=S.uot_id WHERE S.estado=1 AND S.estado_proceso NOT IN('FINALIZADA','CANCELADA')) BEGIN SET @cMensaje=N'Finalice o cancele las salidas pendientes.'; RETURN 1; END;
 IF EXISTS(SELECT 1 FROM logistica.RecursoProgramado RP WHERE RP.estado=1 AND RP.estado_proceso NOT IN('COMPLETADO','CANCELADO') AND(EXISTS(SELECT 1 FROM comercial.CampaniaVenta C JOIN @Rama R ON R.uot_id=C.uot_id WHERE C.campania_venta_id=RP.campania_venta_id) OR EXISTS(SELECT 1 FROM comercial.OperativoVenta O JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id JOIN @Rama R ON R.uot_id=C.uot_id WHERE O.operativo_venta_id=RP.operativo_venta_id) OR EXISTS(SELECT 1 FROM campo.SalidaCampo S JOIN @Rama R ON R.uot_id=S.uot_id WHERE S.salida_campo_id=RP.salida_campo_id))) BEGIN SET @cMensaje=N'Cierre los recursos programados pendientes.'; RETURN 1; END;
 BEGIN TRY BEGIN TRAN;
  DECLARE @Ahora DATETIME2(0)=SYSUTCDATETIME(),@Hoy DATE=CONVERT(DATE,SYSUTCDATETIME());
  UPDATE PP SET estado=0,fecha_hasta=COALESCE(PP.fecha_hasta,@Ahora) FROM logistica.ProductoPrecio PP JOIN @Rama R ON R.uot_id=PP.uot_id WHERE PP.estado=1 AND PP.fecha_hasta IS NULL;
  UPDATE C SET estado=0,fecha_fin=COALESCE(C.fecha_fin,@Hoy) FROM org.ConvenioUOTOrganizacion C JOIN @Rama R ON R.uot_id=C.uot_id WHERE C.estado=1;
  UPDATE A SET estado=0 FROM org.Asociacion A JOIN @Rama R ON R.uot_id=A.uot_id WHERE A.estado=1;
  UPDATE EA SET estado=0,fecha_hasta=COALESCE(EA.fecha_hasta,@Hoy) FROM org.EmpleadoArea EA JOIN org.Area A ON A.area_id=EA.area_id JOIN @Rama R ON R.uot_id=A.uot_id WHERE EA.estado=1 AND EA.fecha_hasta IS NULL;
  UPDATE A SET estado=0 FROM org.Area A JOIN @Rama R ON R.uot_id=A.uot_id WHERE A.estado=1;
  UPDATE S SET estado=0 FROM logistica.Suministro S JOIN @Rama R ON R.uot_id=S.uot_id WHERE S.estado=1;
  UPDATE PC SET estado=0 FROM prod.ParcelaCultivo PC JOIN prod.Parcela P ON P.parcela_id=PC.parcela_id JOIN prod.Predio PR ON PR.predio_id=P.predio_id JOIN @Rama R ON R.uot_id=PR.uot_id WHERE PC.estado=1;
  UPDATE P SET estado=0 FROM prod.Parcela P JOIN prod.Predio PR ON PR.predio_id=P.predio_id JOIN @Rama R ON R.uot_id=PR.uot_id WHERE P.estado=1;
  UPDATE PR SET estado=0 FROM prod.Predio PR JOIN @Rama R ON R.uot_id=PR.uot_id WHERE PR.estado=1;
  UPDATE AU SET estado=0,fecha_hasta=COALESCE(AU.fecha_hasta,@Ahora) FROM logistica.AlmacenUOT AU JOIN @Rama R ON R.uot_id=AU.uot_id WHERE AU.estado=1 AND AU.fecha_hasta IS NULL;
  UPDATE A SET estado=0 FROM logistica.Almacen A JOIN @Rama R ON R.uot_id=A.uot_propietaria_id WHERE A.estado=1;
  DECLARE @Empleados TABLE(empleado_id BIGINT PRIMARY KEY); INSERT @Empleados SELECT DISTINCT EU.empleado_id FROM org.EmpleadoUOT EU JOIN @Rama R ON R.uot_id=EU.uot_id WHERE EU.estado=1 AND EU.fecha_hasta IS NULL;
  UPDATE EU SET estado=0,fecha_hasta=COALESCE(EU.fecha_hasta,@Hoy),fecha_cese=COALESCE(EU.fecha_cese,@Hoy),es_principal=0 FROM org.EmpleadoUOT EU JOIN @Rama R ON R.uot_id=EU.uot_id WHERE EU.estado=1 AND EU.fecha_hasta IS NULL;
  UPDATE E SET estado=0,fecha_cese=COALESCE(E.fecha_cese,@Hoy) FROM org.Empleado E JOIN @Empleados X ON X.empleado_id=E.empleado_id WHERE NOT EXISTS(SELECT 1 FROM org.EmpleadoUOT EU WHERE EU.empleado_id=E.empleado_id AND EU.estado=1 AND EU.fecha_hasta IS NULL);
  UPDATE EU SET es_principal=1 FROM org.EmpleadoUOT EU JOIN @Empleados X ON X.empleado_id=EU.empleado_id WHERE EU.estado=1 AND EU.fecha_hasta IS NULL AND NOT EXISTS(SELECT 1 FROM org.EmpleadoUOT P WHERE P.empleado_id=EU.empleado_id AND P.estado=1 AND P.fecha_hasta IS NULL AND P.es_principal=1) AND EU.empleado_uot_id=(SELECT TOP(1) Z.empleado_uot_id FROM org.EmpleadoUOT Z WHERE Z.empleado_id=EU.empleado_id AND Z.estado=1 AND Z.fecha_hasta IS NULL ORDER BY Z.fecha_desde,Z.empleado_uot_id);
  DECLARE @Usuarios TABLE(usuario_id BIGINT PRIMARY KEY); INSERT @Usuarios SELECT DISTINCT UU.usuario_id FROM seg.UsuarioUOT UU JOIN @Rama R ON R.uot_id=UU.uot_id WHERE UU.estado=1 AND UU.fecha_hasta IS NULL;
  UPDATE P SET estado=0,fecha_hasta=COALESCE(P.fecha_hasta,@Ahora) FROM seg.UsuarioUOTPermiso P JOIN seg.UsuarioUOT UU ON UU.usuario_uot_id=P.usuario_uot_id JOIN @Rama R ON R.uot_id=UU.uot_id WHERE P.estado=1 AND P.fecha_hasta IS NULL;
  UPDATE UR SET estado=0,fecha_hasta=COALESCE(UR.fecha_hasta,@Ahora) FROM seg.UsuarioUOTRol UR JOIN seg.UsuarioUOT UU ON UU.usuario_uot_id=UR.usuario_uot_id JOIN @Rama R ON R.uot_id=UU.uot_id WHERE UR.estado=1 AND UR.fecha_hasta IS NULL;
  UPDATE UU SET estado=0,fecha_hasta=COALESCE(UU.fecha_hasta,@Ahora),es_predeterminada=0 FROM seg.UsuarioUOT UU JOIN @Rama R ON R.uot_id=UU.uot_id WHERE UU.estado=1 AND UU.fecha_hasta IS NULL;
  UPDATE U SET estado=0,estado_cuenta='DESHABILITADA',token_version=token_version+1,bloqueado_hasta=NULL FROM seg.Usuario U JOIN @Usuarios X ON X.usuario_id=U.usuario_id WHERE NOT EXISTS(SELECT 1 FROM seg.UsuarioUOT UU JOIN org.UOT OU ON OU.uot_id=UU.uot_id AND OU.estado=1 WHERE UU.usuario_id=U.usuario_id AND UU.estado=1 AND UU.fecha_hasta IS NULL);
  UPDATE S SET estado=0,fecha_revocacion=COALESCE(S.fecha_revocacion,@Ahora),motivo_revocacion=N'UOT retirada' FROM seg.SesionUsuario S JOIN @Usuarios X ON X.usuario_id=S.usuario_id WHERE S.estado=1 AND NOT EXISTS(SELECT 1 FROM seg.UsuarioUOT UU JOIN org.UOT OU ON OU.uot_id=UU.uot_id AND OU.estado=1 WHERE UU.usuario_id=S.usuario_id AND UU.estado=1 AND UU.fecha_hasta IS NULL);
  UPDATE S SET modo_uot='ESPECIFICA',uot_contexto_id=F.uot_id,fecha_ultima_actividad=@Ahora FROM seg.SesionUsuario S JOIN @Usuarios X ON X.usuario_id=S.usuario_id CROSS APPLY(SELECT TOP(1) UU.uot_id FROM seg.UsuarioUOT UU JOIN org.UOT OU ON OU.uot_id=UU.uot_id AND OU.estado=1 WHERE UU.usuario_id=S.usuario_id AND UU.estado=1 AND UU.fecha_hasta IS NULL ORDER BY UU.es_predeterminada DESC,UU.usuario_uot_id) F WHERE S.estado=1 AND S.fecha_revocacion IS NULL AND (EXISTS(SELECT 1 FROM @Rama R WHERE R.uot_id=S.uot_contexto_id) OR (S.modo_uot='GENERAL' AND (SELECT COUNT(*) FROM seg.UsuarioUOT UU2 JOIN org.UOT U2 ON U2.uot_id=UU2.uot_id AND U2.estado=1 WHERE UU2.usuario_id=S.usuario_id AND UU2.estado=1 AND UU2.fecha_hasta IS NULL)<2));
  UPDATE U SET estado=0,fecha_fin=COALESCE(U.fecha_fin,@Hoy) FROM org.UOT U JOIN @Rama R ON R.uot_id=U.uot_id;
  COMMIT; SELECT @bResultado=1,@cMensaje=N'UOT retirada.',@cCodigoRespuesta='UOT_RETIRADA',@nHttpRespuesta=200; RETURN 0;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; SET @cMensaje=N'No se pudo retirar la UOT.'; RETURN 1; END CATCH;
END;
GO
