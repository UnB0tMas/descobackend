/* DESCO / Inventario / 2026-10-27
   Registra o completa el vehiculo del mismo bien sin crear duplicados.
   Ejemplo: EXEC logistica.PA_Vehiculo_Upd_DatosPatrimoniales @Usuario,@Bien,NULL,@Tipo,NULL,@Ok OUTPUT,@Mensaje OUTPUT;
*/
IF OBJECT_ID(N'logistica.PA_Vehiculo_Upd_DatosPatrimoniales',N'P') IS NOT NULL
    DROP PROCEDURE logistica.PA_Vehiculo_Upd_DatosPatrimoniales;
GO
IF OBJECT_ID(N'logistica.PA_Vehiculo_Upd_DatosPatrimoniales', N'P') IS NOT NULL DROP PROCEDURE logistica.PA_Vehiculo_Upd_DatosPatrimoniales;
GO
CREATE PROCEDURE logistica.PA_Vehiculo_Upd_DatosPatrimoniales
 @nUsuarioId BIGINT,@nBienId BIGINT,@cPlaca VARCHAR(12),@cTipo VARCHAR(30),@nKilometraje DECIMAL(12,1),
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@cColor NVARCHAR(50)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @bResultado=0,@cMensaje=N'No se pudieron guardar los datos del vehiculo.';
 SELECT @cPlaca=UPPER(NULLIF(LTRIM(RTRIM(@cPlaca)),'')),@cTipo=UPPER(NULLIF(LTRIM(RTRIM(@cTipo)),''));
 IF @cPlaca IS NOT NULL AND (@cPlaca LIKE '%[^A-Z0-9-]%' OR @cPlaca NOT LIKE '%[A-Z0-9]%')
 BEGIN SET @cMensaje=N'La placa solo admite letras, numeros y guiones.';RETURN;END;
 IF @nKilometraje<0 BEGIN SET @cMensaje=N'El kilometraje no puede ser negativo.';RETURN;END;
 IF NOT EXISTS(SELECT 1 FROM config.CatalogoRecursoValor WHERE catalogo='TIPO_VEHICULO' AND codigo=@cTipo AND estado=1)
 BEGIN SET @cMensaje=N'Seleccione un tipo de vehiculo disponible.';RETURN;END;
 DECLARE @Propia BIT=CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END,@Estado VARCHAR(20),@NuevoEstado VARCHAR(20),@Uot BIGINT,@Anterior DECIMAL(12,1);
 BEGIN TRY
  IF @Propia=1 BEGIN TRANSACTION;
  SELECT @Estado=B.estado_bien,@Uot=B.uot_id
  FROM logistica.BienInventario B WITH(UPDLOCK,HOLDLOCK) JOIN logistica.TipoBien T ON T.tipo_bien_id=B.tipo_bien_id
  WHERE B.bien_inventario_id=@nBienId AND B.estado=1 AND B.estado_bien<>'BAJA'
    AND UPPER(T.nombre) COLLATE Modern_Spanish_CI_AI=N'VEHICULO';
  IF @Uot IS NULL THROW 51080,N'Solo un bien vigente de tipo Vehiculo puede registrar estos datos.',1;
  IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@Uot,'INVENTARIO_CREAR')=0 AND seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@Uot,'INVENTARIO_EDITAR')=0
      THROW 51080,N'No tiene permiso para modificar el vehiculo en esta UOT.',1;
  IF @cPlaca IS NOT NULL AND EXISTS(SELECT 1 FROM logistica.Vehiculo WITH(UPDLOCK,HOLDLOCK) WHERE placa=@cPlaca AND vehiculo_id<>@nBienId)
      THROW 51080,N'La placa ya pertenece a otro vehiculo.',1;
  SELECT @Anterior=kilometraje_km FROM logistica.Vehiculo WITH(UPDLOCK,HOLDLOCK) WHERE vehiculo_id=@nBienId;
  IF @nKilometraje<@Anterior THROW 51080,N'El kilometraje no puede ser menor al registrado.',1;
  SET @NuevoEstado=CASE WHEN @cPlaca IS NULL AND @Estado NOT IN('INACTIVO','MANTENIMIENTO','AVERIADO') THEN 'PENDIENTE_PLACA'
                       WHEN @cPlaca IS NOT NULL AND @Estado='PENDIENTE_PLACA' THEN 'DISPONIBLE' ELSE @Estado END;
  -- Retirar primero la disponibilidad antes de retirar una placa.
  IF @NuevoEstado='PENDIENTE_PLACA' AND @Estado<>@NuevoEstado
      UPDATE logistica.BienInventario SET estado_bien=@NuevoEstado WHERE bien_inventario_id=@nBienId;
  UPDATE logistica.Vehiculo SET color=NULLIF(LTRIM(RTRIM(@cColor)),N''),placa=@cPlaca,tipo_vehiculo=@cTipo,kilometraje_km=COALESCE(@nKilometraje,kilometraje_km),estado=1 WHERE vehiculo_id=@nBienId;
  IF @@ROWCOUNT=0
      INSERT logistica.Vehiculo(vehiculo_id,placa,tipo_vehiculo,kilometraje_km,estado,color) VALUES(@nBienId,@cPlaca,@cTipo,@nKilometraje,1,NULLIF(LTRIM(RTRIM(@cColor)),N''));
  IF @NuevoEstado<>@Estado
  BEGIN
      UPDATE logistica.BienInventario SET estado_bien=@NuevoEstado WHERE bien_inventario_id=@nBienId;
      UPDATE logistica.BienEstadoHistorial SET fecha_hasta=SYSUTCDATETIME() WHERE bien_inventario_id=@nBienId AND fecha_hasta IS NULL;
      INSERT logistica.BienEstadoHistorial(bien_inventario_id,estado_bien,fecha_desde,motivo,usuario_id,estado)
      VALUES(@nBienId,@NuevoEstado,SYSUTCDATETIME(),CASE WHEN @cPlaca IS NULL THEN N'Pendiente de registro de placa.' ELSE N'Placa registrada; vehiculo disponible.' END,@nUsuarioId,1);
  END;
  IF @Propia=1 COMMIT;
  SELECT @bResultado=1,@cMensaje=CASE WHEN @cPlaca IS NULL THEN N'Vehiculo guardado; placa pendiente.' ELSE N'Datos del vehiculo guardados correctamente.' END;
 END TRY
 BEGIN CATCH
  IF @Propia=1 AND XACT_STATE()<>0 ROLLBACK;
  SET @cMensaje=CASE WHEN ERROR_NUMBER()=51080 THEN ERROR_MESSAGE() ELSE N'No se pudieron guardar los datos del vehiculo.' END;
 END CATCH;
END;
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=N'Guarda datos opcionales y gestiona pendiente de placa en la misma transaccion del bien. Placa unica entre vehiculos y kilometraje no decreciente.',
 @level0type=N'SCHEMA',@level0name=N'logistica',@level1type=N'PROCEDURE',@level1name=N'PA_Vehiculo_Upd_DatosPatrimoniales';
GO
