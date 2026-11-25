IF OBJECT_ID(N'[comercial].[PA_CampaniaDescuentoJaba_Upd_Recalcular]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_CampaniaDescuentoJaba_Upd_Recalcular];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_CampaniaDescuentoJaba_Upd_Recalcular
' Descripción            : Gestiona campania descuento jaba: recalcular.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_CampaniaDescuentoJaba_Upd_Recalcular
 @camp BIGINT,@valor DECIMAL(9,3),@usuario BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 IF @@TRANCOUNT=0 THROW 52071,N'La actualización requiere una operación activa.',1;
 IF @valor IS NOT NULL AND (@valor<0 OR @valor>9.999)
   THROW 52072,N'El descuento por jaba no es válido.',1;
 -- No alterar valores incorporados a una liquidación no anulada.
 IF EXISTS(SELECT 1 FROM finanzas.LiquidacionSocio L
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
    WHERE P.campania_venta_id=@camp AND L.estado=1 AND L.estado_proceso NOT IN('ANULADA','CANCELADA'))
   THROW 52073,N'Esta campaña tiene liquidaciones en curso. Revise las liquidaciones antes de cambiar el descuento.',1;
 DECLARE @cambios TABLE (id BIGINT NOT NULL,planId BIGINT NOT NULL,numero INT NOT NULL,
   bruto DECIMAL(12,3) NOT NULL,anterior DECIMAL(9,3) NOT NULL,nuevo DECIMAL(9,3) NOT NULL,
   versionAnterior INT NOT NULL,versionNueva INT NOT NULL);
 UPDATE R SET descuento_jaba_kg=
     CASE WHEN R.peso_bruto_kg=0 THEN 0
       WHEN R.peso_bruto_kg<COALESCE(@valor,0) THEN CONVERT(DECIMAL(9,3),R.peso_bruto_kg)
       ELSE COALESCE(@valor,0) END,
   version=R.version+1,usuario_modifica_id=@usuario,fecha_modifica=SYSUTCDATETIME()
 OUTPUT inserted.campania_jaba_recepcion_id,inserted.campania_jaba_plan_id,inserted.numero_jaba,
   inserted.peso_bruto_kg,deleted.descuento_jaba_kg,inserted.descuento_jaba_kg,deleted.version,inserted.version
 INTO @cambios(id,planId,numero,bruto,anterior,nuevo,versionAnterior,versionNueva)
 FROM comercial.CampaniaJabaRecepcion R WITH(UPDLOCK,HOLDLOCK)
 JOIN comercial.CampaniaJabaPlan J ON J.campania_jaba_plan_id=R.campania_jaba_plan_id
 JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
 WHERE P.campania_venta_id=@camp AND R.descuento_jaba_kg<>
    CASE WHEN R.peso_bruto_kg=0 THEN 0
      WHEN R.peso_bruto_kg<COALESCE(@valor,0) THEN CONVERT(DECIMAL(9,3),R.peso_bruto_kg)
      ELSE COALESCE(@valor,0) END;
 INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
 SELECT @camp,'CampaniaJabaRecepcion',A.id,'RECALCULAR_TARA',
    (SELECT A.planId planId,A.numero numeroJaba,A.bruto pesoBrutoKg,A.anterior descuentoAnteriorKg,
      A.nuevo descuentoNuevoKg,A.versionAnterior versionAnterior,A.versionNueva versionNueva
     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario
 FROM @cambios A;
END;
GO
