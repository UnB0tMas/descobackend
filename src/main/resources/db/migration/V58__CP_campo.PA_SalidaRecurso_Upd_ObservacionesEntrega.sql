IF OBJECT_ID(N'[campo].[PA_SalidaRecurso_Upd_ObservacionesEntrega]') IS NOT NULL
    DROP PROCEDURE [campo].[PA_SalidaRecurso_Upd_ObservacionesEntrega];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : campo.PA_SalidaRecurso_Upd_ObservacionesEntrega
' Descripción            : Actualiza salida recurso para observaciones entrega.
' Aplicativo / Módulo    : DESCO / campo
*******************************************************************************************************/
CREATE   PROCEDURE campo.PA_SalidaRecurso_Upd_ObservacionesEntrega
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
