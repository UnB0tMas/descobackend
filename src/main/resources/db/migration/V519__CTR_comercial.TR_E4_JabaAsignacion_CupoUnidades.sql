IF OBJECT_ID(N'[comercial].[TR_E4_JabaAsignacion_CupoUnidades]') IS NOT NULL
    DROP TRIGGER [comercial].[TR_E4_JabaAsignacion_CupoUnidades];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : comercial.TR_E4_JabaAsignacion_CupoUnidades
' Descripción            : Controla las modificaciones de e4 jaba asignacion cupo unidades mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE TRIGGER comercial.TR_E4_JabaAsignacion_CupoUnidades
ON comercial.JabaAsignacion
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF ROWCOUNT_BIG()=0 RETURN;

    -- Inactive legacy campaigns remain unaffected. Confirmed E4 facts cannot be silently cancelled.
    IF EXISTS (
        SELECT 1 FROM inserted I JOIN deleted D ON D.jaba_asignacion_id=I.jaba_asignacion_id
        JOIN comercial.JabaUnidadE4 U ON U.jaba_asignacion_id=I.jaba_asignacion_id
        WHERE D.estado=1 AND I.estado=0
          AND (U.pesaje_estado='PESADA' OR U.retorno_estado<>'PENDIENTE'
               OR U.entrega_socio_id IS NOT NULL)
    )
        THROW 51250,N'La asignación con pesajes o devoluciones requiere reversión autorizada.',1;

    DECLARE @limites TABLE(campania_venta_id BIGINT NOT NULL PRIMARY KEY,cupo_jabas INT NOT NULL);
    INSERT INTO @limites(campania_venta_id,cupo_jabas)
    SELECT K.campania_venta_id,K.cupo_jabas
    FROM comercial.CampaniaControlE4 K WITH(UPDLOCK,HOLDLOCK)
    WHERE EXISTS(SELECT 1 FROM inserted I
       JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=I.operativo_socio_id
       JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
       WHERE O.campania_venta_id=K.campania_venta_id);

    IF EXISTS (
        SELECT 1 FROM @limites K
        CROSS APPLY (
            SELECT COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-A.cantidad_devuelta),0) AS asignadas
            FROM comercial.JabaAsignacion A
            JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
            JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
            WHERE O.campania_venta_id=K.campania_venta_id AND A.estado=1
        ) S
        WHERE S.asignadas>K.cupo_jabas
    )
        THROW 51251,N'La asignación excede el cupo físico configurado para la campaña.',1;

    -- Exactly one assignment-unit per crate, also for an assignment made through the legacy API.
    INSERT INTO comercial.JabaUnidadE4(jaba_asignacion_id,numero)
    SELECT I.jaba_asignacion_id, N.numero
    FROM inserted I
    LEFT JOIN deleted D ON D.jaba_asignacion_id=I.jaba_asignacion_id
    JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=I.operativo_socio_id
    JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
    JOIN @limites K ON K.campania_venta_id=O.campania_venta_id
    CROSS APPLY (
       SELECT TOP (I.cantidad_asignada)
          CONVERT(INT,ROW_NUMBER() OVER(ORDER BY A.object_id,B.object_id)) numero
       FROM sys.all_objects A CROSS JOIN sys.all_objects B
    ) N
    WHERE D.jaba_asignacion_id IS NULL AND I.estado=1;
END;
GO
