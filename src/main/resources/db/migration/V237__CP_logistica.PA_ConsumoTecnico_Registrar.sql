IF OBJECT_ID(N'[logistica].[PA_ConsumoTecnico_Registrar]') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_ConsumoTecnico_Registrar];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : logistica.PA_ConsumoTecnico_Registrar
' Descripción            : Ejecuta el proceso de consumo tecnico registrar.
' Aplicativo / Módulo    : DESCO / logistica
*******************************************************************************************************/
CREATE   PROCEDURE logistica.PA_ConsumoTecnico_Registrar
 @Sesion BIGINT,@Usuario BIGINT,@Responsable BIGINT,@Programa BIGINT,@Cantidad DECIMAL(19,3),
 @Origen VARCHAR(16),@Registro BIGINT,@Clave UNIQUEIDENTIFIER
AS
BEGIN
 SET NOCOUNT ON;
 IF @@TRANCOUNT=0 THROW 51103,N'El consumo debe registrarse junto con el tratamiento.',1;
 IF @Cantidad IS NULL OR @Cantidad<=0 OR @Clave IS NULL THROW 51103,N'Indique una cantidad utilizada válida.',1;
 DECLARE @Uot BIGINT,@Empleado BIGINT,@Pendiente DECIMAL(19,3),@Estado VARCHAR(20),@Actor BIGINT;
 SELECT @Uot=uot_id,@Empleado=empleado_id,@Estado=estado_proceso,
  @Pendiente=cantidad_entregada-cantidad_devuelta-cantidad_consumida
 FROM logistica.ProgramacionProducto WITH(UPDLOCK,HOLDLOCK) WHERE programacion_producto_id=@Programa;
 SELECT @Actor=persona_id FROM seg.Usuario WHERE usuario_id=@Usuario AND estado=1;
 IF NOT EXISTS(SELECT 1 FROM seg.SesionUsuario WHERE sesion_usuario_id=@Sesion AND usuario_id=@Usuario AND estado=1
  AND fecha_revocacion IS NULL AND modo_uot='ESPECIFICA' AND uot_contexto_id=@Uot)
  OR seg.FN_Usuario_TienePermisoUOT(@Usuario,@Uot,'SANIDAD_CREAR')<>1
  OR @Empleado<>@Responsable OR (@Responsable<>@Actor AND seg.FN_Usuario_TienePermisoUOT(@Usuario,@Uot,'ALMACENES_MOVIMIENTO')<>1)
  THROW 51103,N'El producto entregado no corresponde al responsable o a la UOT seleccionada.',1;
 IF EXISTS(SELECT 1 FROM logistica.UsoProductoTecnico WHERE tipo_origen=@Origen AND registro_id=@Registro)
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM logistica.UsoProductoTecnico WHERE tipo_origen=@Origen AND registro_id=@Registro AND programacion_producto_id=@Programa AND cantidad=@Cantidad)
   THROW 51103,N'La solicitud ya tiene otro consumo registrado.',1;
  RETURN;
 END;
 IF @Estado<>'ENTREGADA' OR @Cantidad>@Pendiente OR @Uot IS NULL
  THROW 51103,N'La cantidad supera el producto entregado pendiente de uso.',1;
 UPDATE logistica.ProgramacionProducto SET cantidad_consumida=cantidad_consumida+@Cantidad,
  estado_proceso=CASE WHEN @Cantidad=@Pendiente THEN 'FINALIZADA' ELSE 'ENTREGADA' END WHERE programacion_producto_id=@Programa;
 INSERT logistica.ProgramacionProductoEvento(programacion_producto_id,tipo_evento,cantidad,usuario_id,clave_idempotencia,observacion)
 VALUES(@Programa,'CONSUMIR',@Cantidad,@Usuario,@Clave,CONCAT(N'Tratamiento ',@Origen,N' #',@Registro));
 DECLARE @Evento BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());
 INSERT logistica.UsoProductoTecnico VALUES(@Origen,@Registro,@Programa,@Evento,@Cantidad);
END;
GO
