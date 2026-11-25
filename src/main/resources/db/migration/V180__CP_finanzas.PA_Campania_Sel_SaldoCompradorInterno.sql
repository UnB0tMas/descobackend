IF OBJECT_ID(N'[finanzas].[PA_Campania_Sel_SaldoCompradorInterno]') IS NOT NULL
    DROP PROCEDURE [finanzas].[PA_Campania_Sel_SaldoCompradorInterno];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : finanzas.PA_Campania_Sel_SaldoCompradorInterno
' Descripción            : Consulta campania para saldo comprador interno.
' Aplicativo / Módulo    : DESCO / finanzas
*******************************************************************************************************/
CREATE   PROCEDURE [finanzas].[PA_Campania_Sel_SaldoCompradorInterno]
(
    @nCampaniaVentaId BIGINT,
    @nOperativoVentaId BIGINT = NULL,
    @nTotalValorizado DECIMAL(19,4) OUTPUT,
    @nTotalCobrado DECIMAL(19,4) OUTPUT,
    @nSaldoPendiente DECIMAL(19,4) OUTPUT
,@cMoneda CHAR(3)=NULL,@bResultado BIT=NULL OUTPUT,@cMensaje NVARCHAR(300)=NULL OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS
BEGIN
    SET @cMensaje=NULL; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;

 SET NOCOUNT ON;
 SELECT @bResultado=0,@cMensaje=N'No se pudo consultar la información.';
 BEGIN TRY

  SELECT @nTotalValorizado=0,@nTotalCobrado=0,@nSaldoPendiente=0;
  IF @nOperativoVentaId IS NULL SET @cMoneda=COALESCE(@cMoneda,'PEN');
  IF @cMoneda IS NULL
  BEGIN
   DECLARE @monedas INT;
   SELECT @monedas=COUNT(DISTINCT P.moneda),@cMoneda=MIN(P.moneda)
   FROM comercial.EntregaSocio E JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
   JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
   JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1
   JOIN comercial.PrecioComercial P ON P.precio_comercial_id=D.precio_comercial_id
   WHERE O.campania_venta_id=@nCampaniaVentaId AND (@nOperativoVentaId IS NULL OR O.operativo_venta_id=@nOperativoVentaId)
   AND E.estado=1 AND E.estado_proceso='CONFIRMADA';
   IF @monedas>1 THROW 51000,N'Seleccione la moneda para consultar el saldo.',1;
  END;
  IF @nOperativoVentaId IS NULL
   SELECT @nTotalValorizado=COALESCE(SUM(V.importe),0) FROM finanzas.V_E5_VentasConfirmadas V
   WHERE V.campaniaId=@nCampaniaVentaId AND COALESCE(@cMoneda,'PEN')='PEN';
  ELSE
   SELECT @nTotalValorizado=COALESCE(SUM(D.importe),0)
  FROM comercial.EntregaSocio E JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
  JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
  JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1
  JOIN comercial.PrecioComercial P ON P.precio_comercial_id=D.precio_comercial_id AND P.moneda=@cMoneda
  WHERE O.campania_venta_id=@nCampaniaVentaId AND (@nOperativoVentaId IS NULL OR O.operativo_venta_id=@nOperativoVentaId)
  AND E.estado=1 AND E.estado_proceso='CONFIRMADA';
  SELECT @nTotalCobrado=COALESCE(SUM(importe),0) FROM finanzas.CobroComprador
  WHERE campania_venta_id=@nCampaniaVentaId AND (@nOperativoVentaId IS NULL OR operativo_venta_id=@nOperativoVentaId)
  AND moneda=@cMoneda AND estado=1 AND estado_proceso='CONFIRMADO';
  SET @nSaldoPendiente=@nTotalValorizado-@nTotalCobrado;
  IF @nSaldoPendiente<0 THROW 51100,N'DESCO_KARDEX_REVISAR',1;

  SELECT @bResultado=1,@cMensaje=N'Saldo consultado.';
 END TRY
 BEGIN CATCH
  SET @bResultado=0;
  EXEC config.PA_Respuesta_ResolverError @cProcedimiento=N'finanzas.PA_Campania_Sel_SaldoCompradorInterno',@cMensaje=@cMensaje OUTPUT,@cJson=NULL;
 END CATCH;
Salida:
 SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'finanzas.PA_Campania_Sel_SaldoCompradorInterno',@bResultado,@cMensaje) R;
IF @bResultado=0 AND @@NESTLEVEL>1 THROW 51000,@cMensaje,1;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
