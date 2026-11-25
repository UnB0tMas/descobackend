IF OBJECT_ID(N'[campo].[PA_SalidaDocumental_Upd_VencerObservaciones]', N'P') IS NOT NULL
    DROP PROCEDURE [campo].[PA_SalidaDocumental_Upd_VencerObservaciones];
GO
-- Cierra las observaciones sin respuesta al vencer el plazo de 24 horas.
CREATE PROCEDURE campo.PA_SalidaDocumental_Upd_VencerObservaciones
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @salida BIGINT,@hilo BIGINT,@documento BIGINT,@responsable BIGINT;
    DECLARE @ahora DATETIME2(0)=SYSUTCDATETIME();
    DECLARE candidatos CURSOR LOCAL FAST_FORWARD FOR
        SELECT DISTINCT E.salida_campo_id
        FROM campo.SalidaE2 E
        JOIN campo.SalidaDocumentoVinculo V ON V.salida_campo_id=E.salida_campo_id
        JOIN doc.AsignacionPendiente A ON A.hilo_id=V.hilo_id AND A.estado='PENDIENTE'
        JOIN doc.Documento D ON D.documento_id=A.documento_origen_id
        WHERE E.estado='OBSERVADA' AND E.convenio_id IS NULL
          AND D.tipo_movimiento='OBSERVACION' AND D.fecha_limite<=@ahora;
    OPEN candidatos;
    FETCH NEXT FROM candidatos INTO @salida;
    WHILE @@FETCH_STATUS=0
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;
            SET @hilo=NULL;
            SET @documento=NULL;
            SET @responsable=NULL;
            IF EXISTS(SELECT 1 FROM campo.SalidaE2 WITH (UPDLOCK,HOLDLOCK)
                      WHERE salida_campo_id=@salida AND estado='OBSERVADA' AND convenio_id IS NULL)
            BEGIN
                SELECT TOP(1) @hilo=V.hilo_id,@documento=D.documento_id,@responsable=A.responsable_usuario_id
                FROM campo.SalidaDocumentoVinculo V
                JOIN doc.AsignacionPendiente A WITH (UPDLOCK,HOLDLOCK) ON A.hilo_id=V.hilo_id AND A.estado='PENDIENTE'
                JOIN doc.Documento D ON D.documento_id=A.documento_origen_id
                WHERE V.salida_campo_id=@salida AND D.tipo_movimiento='OBSERVACION'
                  AND D.fecha_limite<=@ahora
                ORDER BY D.documento_id DESC;
                IF @documento IS NOT NULL
                BEGIN
                    UPDATE campo.SalidaE2 SET estado='RECHAZADA',fecha_cierre=@ahora
                    WHERE salida_campo_id=@salida;
                    UPDATE campo.SalidaCampo SET estado_proceso='CANCELADA' WHERE salida_campo_id=@salida;
                    UPDATE doc.AsignacionPendiente SET estado='SUSTITUIDA'
                    WHERE hilo_id=@hilo AND estado='PENDIENTE';
                    UPDATE doc.Hilo SET estado='FINALIZADO',fecha_cierre=@ahora WHERE hilo_id=@hilo;
                    INSERT campo.SalidaEventoE2(salida_campo_id,tipo,detalle,usuario_id,fecha_hora)
                    VALUES(@salida,'VENCIMIENTO',N'Cierre automático: observación sin respuesta en 24 horas.',@responsable,@ahora);
                    INSERT doc.Evento(hilo_id,documento_id,usuario_id,tipo,detalle)
                    VALUES(@hilo,@documento,@responsable,'SALIDA_VENCIDA',N'Cierre automático por falta de respuesta.');
                    INSERT auditoria.TransicionEstado(usuario_id,esquema_entidad,nombre_entidad,identificador,campo_estado,estado_anterior,estado_nuevo,motivo)
                    VALUES(NULL,N'campo',N'SalidaE2',CONVERT(NVARCHAR(200),@salida),N'estado','OBSERVADA','RECHAZADA',N'Cierre automático por vencimiento de observación.');
                END;
            END;
            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
            CLOSE candidatos;
            DEALLOCATE candidatos;
            THROW;
        END CATCH;
        FETCH NEXT FROM candidatos INTO @salida;
    END;
    CLOSE candidatos;
    DEALLOCATE candidatos;
END;
GO
