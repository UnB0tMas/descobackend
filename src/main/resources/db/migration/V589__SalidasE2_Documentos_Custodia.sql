-- DESCO / Salidas E2: documentos locales y custodia al despacho.
-- No modifica migraciones anteriores ni replica el kardex existente.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF COL_LENGTH(N'campo.SalidaRecursoE2',N'observacion_entrega') IS NULL
    ALTER TABLE campo.SalidaRecursoE2 ADD observacion_entrega NVARCHAR(500) NULL;
GO

CREATE OR ALTER PROCEDURE campo.PA_SalidaRecurso_Upd_ObservacionesEntrega
 @nUsuarioId BIGINT,@nUotId BIGINT,@nSalidaId BIGINT,@cRecursos NVARCHAR(MAX)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF ISJSON(@cRecursos)<>1 THROW 51301,N'Los recursos no tienen un formato válido.',1;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'RECURSOS_CREAR')<>1
     THROW 51302,N'Sin permiso para confirmar entrega.',1;
 BEGIN TRANSACTION;
 BEGIN TRY
     IF NOT EXISTS(SELECT 1 FROM campo.SalidaE2 WITH(UPDLOCK,HOLDLOCK)
       WHERE salida_campo_id=@nSalidaId AND uot_id=@nUotId AND estado='APROBADA')
       THROW 51303,N'La salida no está aprobada.',1;
     IF EXISTS(SELECT 1 FROM OPENJSON(@cRecursos)
         WITH(solicitudRecursoId BIGINT '$.solicitudRecursoId',observacion NVARCHAR(500) '$.observacion') X
         WHERE X.solicitudRecursoId IS NULL OR NULLIF(TRIM(X.observacion),N'') IS NULL)
       THROW 51304,N'Registre cómo se entrega cada recurso.',1;
     IF EXISTS(SELECT solicitudRecursoId FROM OPENJSON(@cRecursos)
         WITH(solicitudRecursoId BIGINT '$.solicitudRecursoId')
         GROUP BY solicitudRecursoId HAVING COUNT_BIG(*)>1)
       THROW 51305,N'Un recurso aparece repetido.',1;
     IF (SELECT COUNT_BIG(*) FROM campo.SalidaRecursoE2
       WHERE salida_campo_id=@nSalidaId AND estado='SOLICITADO') <>
       (SELECT COUNT_BIG(*) FROM OPENJSON(@cRecursos))
       THROW 51306,N'Debe declarar todos los recursos pendientes de entrega.',1;
     IF EXISTS(SELECT 1 FROM OPENJSON(@cRecursos)
        WITH(solicitudRecursoId BIGINT '$.solicitudRecursoId') X
        LEFT JOIN campo.SalidaRecursoE2 R ON R.solicitud_recurso_id=X.solicitudRecursoId
          AND R.salida_campo_id=@nSalidaId AND R.estado='SOLICITADO'
        WHERE R.solicitud_recurso_id IS NULL)
       THROW 51307,N'Existe un recurso fuera de la salida.',1;
     UPDATE R SET observacion_entrega=TRIM(X.observacion)
       FROM campo.SalidaRecursoE2 R
       JOIN OPENJSON(@cRecursos) WITH(
         solicitudRecursoId BIGINT '$.solicitudRecursoId',
         observacion NVARCHAR(500) '$.observacion') X
        ON X.solicitudRecursoId=R.solicitud_recurso_id
       WHERE R.salida_campo_id=@nSalidaId AND R.estado='SOLICITADO';
     INSERT campo.SalidaEventoE2(salida_campo_id,tipo,detalle,usuario_id)
        VALUES(@nSalidaId,'CUSTODIA_ENTREGA',N'Estado inicial de recursos registrado.',@nUsuarioId);
     COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
     IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
     THROW;
 END CATCH;
END;
GO

-- El despacho existente tiene la responsabilidad de cambiar inventario y kardex;
-- este control exige que la custodia de cada recurso haya sido documentada antes.
CREATE OR ALTER TRIGGER campo.TR_SalidaRecursoE2_ValidarEntrega
ON campo.SalidaRecursoE2
AFTER UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
     SELECT 1 FROM inserted I
     JOIN deleted D ON D.solicitud_recurso_id=I.solicitud_recurso_id
     WHERE I.estado='ENTREGADO' AND D.estado<>'ENTREGADO'
       AND NULLIF(TRIM(I.observacion_entrega),N'') IS NULL
 ) THROW 51308,N'Antes del despacho documente el estado de entrega de cada recurso.',1;
END;
GO

CREATE OR ALTER PROCEDURE campo.PA_SalidaDocumento_Sel_Datos
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

CREATE OR ALTER PROCEDURE campo.PA_SalidaDocumento_Upd_Clasificar
 @nUsuarioId BIGINT,@nUotId BIGINT,@nSalidaId BIGINT,
 @nArchivoId BIGINT,@cTipo VARCHAR(40)
AS
BEGIN
 SET NOCOUNT ON;
 IF @cTipo NOT IN('SOLICITUD_GENERADA','SOLICITUD_FIRMADA','EVIDENCIA_SALIDA')
   THROW 51320,N'El tipo documental no está permitido.',1;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'SALIDAS_EDITAR')<>1
   THROW 51321,N'No tiene permiso para administrar documentos de la salida.',1;
 IF NOT EXISTS(SELECT 1 FROM campo.SalidaE2 E
     JOIN seg.Usuario U ON U.usuario_id=@nUsuarioId
     WHERE E.salida_campo_id=@nSalidaId AND E.uot_id=@nUotId
       AND E.solicitante_empleado_id=U.persona_id
       AND E.estado NOT IN('BORRADOR','ELIMINADA'))
   THROW 51322,N'La salida todavía no fue solicitada o no le pertenece.',1;
 IF NOT EXISTS(SELECT 1 FROM archivo.Archivo A
     JOIN archivo.ArchivoVinculo V ON V.archivo_id=A.archivo_id AND V.estado=1
     WHERE A.archivo_id=@nArchivoId AND A.usuario_id=@nUsuarioId
       AND A.uot_id=@nUotId AND A.estado=1
       AND A.proveedor_almacenamiento='LOCAL' AND V.salida_campo_id=@nSalidaId)
   THROW 51323,N'El archivo no corresponde al solicitante y a la salida.',1;
 IF @cTipo='SOLICITUD_GENERADA' AND EXISTS(SELECT 1 FROM archivo.Archivo
   WHERE archivo_id=@nArchivoId AND mime_type<>'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
   THROW 51324,N'El documento generado debe ser Word.',1;
 UPDATE archivo.Archivo SET tipo_evidencia=@cTipo
   WHERE archivo_id=@nArchivoId AND usuario_id=@nUsuarioId;
END;
GO

CREATE OR ALTER PROCEDURE campo.PA_SalidaDocumento_Sel_Listado
 @nUsuarioId BIGINT,@nUotId BIGINT=NULL,@nSalidaId BIGINT=NULL,
 @bSoloPropios BIT=1
AS
BEGIN
 SET NOCOUNT ON;
 SELECT A.archivo_id archivoId,V.salida_campo_id salidaId,
    E.nombre salidaNombre,A.nombre_original nombreOriginal,
    A.mime_type mimeType,A.tipo_evidencia tipo,A.fecha_carga fechaCarga,
    A.tamano_bytes tamanoBytes
 FROM archivo.ArchivoVinculo V
 JOIN archivo.Archivo A ON A.archivo_id=V.archivo_id AND A.estado=1
 JOIN campo.SalidaE2 E ON E.salida_campo_id=V.salida_campo_id
 WHERE V.estado=1 AND E.estado<>'ELIMINADA'
  AND A.proveedor_almacenamiento='LOCAL'
  AND A.tipo_evidencia IN('SOLICITUD_GENERADA','SOLICITUD_FIRMADA','EVIDENCIA_SALIDA')
  AND (@nUotId IS NULL OR E.uot_id=@nUotId)
  AND (@nSalidaId IS NULL OR E.salida_campo_id=@nSalidaId)
  AND (@bSoloPropios=0 OR A.usuario_id=@nUsuarioId)
  AND seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,E.uot_id,'SALIDAS_VER')=1
  AND (A.usuario_id=@nUsuarioId OR (@bSoloPropios=0 AND
       seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,E.uot_id,'SALIDAS_CONFIRMAR')=1))
 ORDER BY A.fecha_carga DESC,A.archivo_id DESC;
END;
GO

-- Asegurar que los bienes retornados tengan observación individual.
-- La operación RETORNAR del E2 conserva su contabilidad y el trigger solo valida.
CREATE OR ALTER TRIGGER campo.TR_SalidaRecursoE2_ValidarRetorno
ON campo.SalidaRecursoE2
AFTER UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (SELECT 1 FROM inserted I
    JOIN deleted D ON D.solicitud_recurso_id=I.solicitud_recurso_id
    WHERE I.resultado_declarado IS NOT NULL AND D.resultado_declarado IS NULL
      AND NULLIF(TRIM(I.observacion),N'') IS NULL)
    THROW 51332,N'Indique cómo retorna cada recurso y cuánto consumible se utilizó.',1;
END;
GO

-- Catálogo consultable de predios/fundos, con autorización por ámbito UOT.
CREATE OR ALTER PROCEDURE campo.PA_SalidaDestino_Sel_Predios
 @nUsuarioId BIGINT,@nUotId BIGINT,@cBuscar NVARCHAR(150)=NULL
AS
BEGIN
 SET NOCOUNT ON;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'SALIDAS_VER')<>1
   THROW 51341,N'No tiene permiso para consultar predios de la UOT.',1;
 SELECT P.predio_id predioId,P.codigo,P.nombre
 FROM prod.Predio P
 WHERE P.estado=1
   AND (P.uot_id=@nUotId OR EXISTS(SELECT 1 FROM prod.PredioAmbito A
       WHERE A.predio_id=P.predio_id AND A.uot_id=@nUotId AND A.estado=1))
   AND (@cBuscar IS NULL OR P.nombre LIKE N'%'+@cBuscar+N'%' OR P.codigo LIKE N'%'+@cBuscar+N'%')
 ORDER BY P.nombre,P.predio_id;
END;
GO
