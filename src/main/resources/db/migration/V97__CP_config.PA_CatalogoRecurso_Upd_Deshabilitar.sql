IF OBJECT_ID(N'[config].[PA_CatalogoRecurso_Upd_Deshabilitar]', N'P') IS NOT NULL
    DROP PROCEDURE [config].[PA_CatalogoRecurso_Upd_Deshabilitar];
GO

/******************************************************************************************************
' Nombre del PA           : config.PA_CatalogoRecurso_Upd_Deshabilitar
' Descripción             : Deshabilita catálogo de recursos.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Configuración
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
    EXEC [config].[PA_CatalogoRecurso_Upd_Deshabilitar]
        @nUsuarioId = 0,
        @cCatalogo = '',
        @nCatalogoId = 0,
        @cMotivo = N'',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [config].[PA_CatalogoRecurso_Upd_Deshabilitar]
    @nUsuarioId BIGINT,@cCatalogo VARCHAR(40),@nCatalogoId BIGINT,@cMotivo NVARCHAR(300),
    @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @bResultado=0,@cMensaje=N'No se pudo deshabilitar el valor.',@cCodigoRespuesta='CATALOGO_NO_DESHABILITADO',@nHttpRespuesta=400;
    SELECT @cCatalogo=UPPER(NULLIF(LTRIM(RTRIM(@cCatalogo)),'')),@cMotivo=NULLIF(LTRIM(RTRIM(@cMotivo)),N'');
    IF @cCatalogo NOT IN('TIPO_VEHICULO','UNIDAD_MEDIDA','CATEGORIA_PRODUCTO','MONEDA') OR @nCatalogoId IS NULL OR @cMotivo IS NULL BEGIN SET @cMensaje=N'Seleccione el valor e indique el motivo.'; RETURN 1; END;
    IF NOT EXISTS(
        SELECT 1 FROM seg.UsuarioRol UR JOIN seg.Rol R ON R.rol_id=UR.rol_id AND R.estado=1 JOIN seg.RolPermiso RP ON RP.rol_id=R.rol_id AND RP.estado=1 JOIN seg.Permiso P ON P.permiso_id=RP.permiso_id AND P.estado=1 AND P.codigo='CATALOGOS_RETIRAR'
        WHERE UR.usuario_id=@nUsuarioId AND UR.estado=1 AND UR.fecha_desde<=SYSUTCDATETIME() AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta>SYSUTCDATETIME())
    ) BEGIN SET @cMensaje=N'No tiene permiso para deshabilitar catálogos.'; SET @cCodigoRespuesta='NO_AUTORIZADO'; SET @nHttpRespuesta=403; RETURN 1; END;
    DECLARE @cCodigo VARCHAR(40);
    SELECT @cCodigo=codigo FROM config.CatalogoRecursoValor WHERE catalogo_recurso_valor_id=@nCatalogoId AND catalogo=@cCatalogo AND estado=1;
    IF @cCodigo IS NULL BEGIN SET @cMensaje=N'El valor seleccionado no está disponible.'; SET @cCodigoRespuesta='NO_ENCONTRADO'; SET @nHttpRespuesta=404; RETURN 1; END;
    UPDATE config.CatalogoRecursoValor SET estado=0,fecha_actualizacion=SYSUTCDATETIME() WHERE catalogo_recurso_valor_id=@nCatalogoId;
    SELECT @bResultado=1,@cMensaje=N'Valor deshabilitado.',@cCodigoRespuesta='CATALOGO_DESHABILITADO',@nHttpRespuesta=200; RETURN 0;
END;
GO
