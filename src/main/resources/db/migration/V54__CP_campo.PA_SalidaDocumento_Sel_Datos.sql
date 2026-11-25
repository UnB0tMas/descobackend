IF OBJECT_ID(N'[campo].[PA_SalidaDocumento_Sel_Datos]') IS NOT NULL
    DROP PROCEDURE [campo].[PA_SalidaDocumento_Sel_Datos];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : campo.PA_SalidaDocumento_Sel_Datos
' Descripción            : Consulta información de Salida Documento (datos).
' Aplicativo / Módulo    : DESCO / campo
*******************************************************************************************************/
CREATE   PROCEDURE campo.PA_SalidaDocumento_Sel_Datos
 @nUsuarioId BIGINT,@nUotId BIGINT,@nSalidaId BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'SALIDAS_VER')<>1
   THROW 51310,N'No tiene permiso para ver la salida.',1;
 IF NOT EXISTS(SELECT 1
   FROM campo.SalidaE2 E JOIN seg.Usuario U ON U.usuario_id=@nUsuarioId
   WHERE E.salida_campo_id=@nSalidaId AND E.uot_id=@nUotId
     AND E.solicitante_empleado_id=U.persona_id AND E.estado NOT IN('BORRADOR','ELIMINADA'))
   THROW 51311,N'La solicitud no está confirmada o no le pertenece.',1;
 SELECT (
   SELECT E.salida_campo_id salidaId,E.nombre,E.estado,
      CONVERT(VARCHAR(19),E.fecha_solicitud,126)+'Z' fechaSolicitud,
      CONVERT(VARCHAR(19),S.fecha_hora_programada,126)+'Z' inicio,
      CONVERT(VARCHAR(19),E.fecha_fin_prevista,126)+'Z' fin,
      S.descripcion,MS.nombre motivo,UO.nombre uot,
      CONCAT(P.nombres,N' ',P.apellido_paterno,
        CASE WHEN NULLIF(P.apellido_materno,N'') IS NULL THEN N'' ELSE N' '+P.apellido_materno END) solicitante,
      JSON_QUERY((SELECT D.orden,PR.nombre predio,PR.codigo,D.actividad_prevista actividad
          FROM campo.SalidaDestinoE2 D
          JOIN prod.Predio PR ON PR.predio_id=D.predio_id
          WHERE D.salida_campo_id=@nSalidaId ORDER BY D.orden FOR JSON PATH)) destinos,
      JSON_QUERY((SELECT CONCAT(PP.nombres,N' ',PP.apellido_paterno,
          CASE WHEN NULLIF(PP.apellido_materno,N'') IS NULL THEN N'' ELSE N' '+PP.apellido_materno END) nombre,
          SP.funcion,SP.es_responsable responsable
          FROM campo.SalidaParticipante SP JOIN org.Persona PP ON PP.persona_id=SP.empleado_id
          WHERE SP.salida_campo_id=@nSalidaId AND SP.estado=1
          ORDER BY SP.es_responsable DESC,PP.nombres FOR JSON PATH)) participantes,
      JSON_QUERY((SELECT COALESCE(B.nombre,SM.nombre) nombre,
          CASE WHEN B.bien_inventario_id IS NULL THEN 'CONSUMIBLE'
               WHEN VH.vehiculo_id IS NOT NULL THEN 'VEHICULO' ELSE 'BIEN' END tipo,
          R.cantidad_solicitada cantidad,COALESCE(SM.unidad_medida,'UNIDAD') unidad
          FROM campo.SalidaRecursoE2 R
          LEFT JOIN logistica.BienInventario B ON B.bien_inventario_id=R.bien_inventario_id
          LEFT JOIN logistica.Vehiculo VH ON VH.vehiculo_id=B.bien_inventario_id
          LEFT JOIN logistica.Suministro SM ON SM.suministro_id=R.suministro_id
          WHERE R.salida_campo_id=@nSalidaId ORDER BY R.solicitud_recurso_id FOR JSON PATH)) recursos
   FROM campo.SalidaE2 E
   JOIN campo.SalidaCampo S ON S.salida_campo_id=E.salida_campo_id
   JOIN campo.MotivoSalida MS ON MS.motivo_salida_id=S.motivo_salida_id
   JOIN org.UOT UO ON UO.uot_id=E.uot_id
   JOIN org.Persona P ON P.persona_id=E.solicitante_empleado_id
   WHERE E.salida_campo_id=@nSalidaId AND E.uot_id=@nUotId
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER
 ) documento;
END;
GO
