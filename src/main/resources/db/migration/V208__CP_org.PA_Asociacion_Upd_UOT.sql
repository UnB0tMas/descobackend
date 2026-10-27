IF OBJECT_ID(N'[org].[PA_Asociacion_Upd_UOT]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_Asociacion_Upd_UOT];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_Asociacion_Upd_UOT
' Descripción             : Actualiza la asociación vinculada con una unidad organizativa territorial.
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
        @cMensaje NVARCHAR(300);
    EXEC [org].[PA_Asociacion_Upd_UOT]
        @nUsuarioId = 0,
        @nAsociacionId = 0,
        @nUotId = 0,
        @cNumeroConvenio = '',
        @dFechaInicio = '2026-10-11',
        @dFechaFin = '2026-10-11',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE org.PA_Asociacion_Upd_UOT
 @nUsuarioId BIGINT,@nAsociacionId BIGINT,@nUotId BIGINT,@cNumeroConvenio VARCHAR(80)=NULL,@dFechaInicio DATE=NULL,@dFechaFin DATE=NULL,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON; SET @bResultado=0; SET @cMensaje=N'No se pudo asignar la asociación a la UOT.';
 IF seg.FN_Usuario_TieneAccesoUOT(@nUsuarioId,@nUotId)=0 BEGIN SET @cMensaje=N'No tiene acceso a la UOT seleccionada.'; RETURN; END;
 IF NOT EXISTS(SELECT 1 FROM org.Asociacion WHERE asociacion_id=@nAsociacionId AND estado=1) BEGIN SET @cMensaje=N'La asociación no está disponible.'; RETURN; END;
 IF @dFechaFin IS NOT NULL AND @dFechaInicio IS NOT NULL AND @dFechaFin<@dFechaInicio BEGIN SET @cMensaje=N'La fecha final del convenio no puede ser anterior a la fecha inicial.'; RETURN; END;
 BEGIN TRY BEGIN TRAN;
 UPDATE org.ConvenioUOTOrganizacion SET estado=0,fecha_fin=COALESCE(fecha_fin,CONVERT(date,SYSUTCDATETIME())) WHERE empresa_id=@nAsociacionId AND tipo_vinculo='ASOCIACION' AND estado=1 AND fecha_fin IS NULL;
 UPDATE org.Asociacion SET uot_id=@nUotId WHERE asociacion_id=@nAsociacionId;
 INSERT org.ConvenioUOTOrganizacion(uot_id,empresa_id,tipo_vinculo,numero_convenio,fecha_inicio,fecha_fin,descripcion,estado)
 VALUES(@nUotId,@nAsociacionId,'ASOCIACION',@cNumeroConvenio,COALESCE(@dFechaInicio,CONVERT(date,SYSUTCDATETIME())),@dFechaFin,N'Convenio de asociación con UOT.',1);
 COMMIT; SET @bResultado=1; SET @cMensaje=N'Asociación asignada a la UOT correctamente.';
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; SET @cMensaje=N'No se pudo asignar la asociación a la UOT.'; END CATCH;
END;
GO
