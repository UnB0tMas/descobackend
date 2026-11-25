IF OBJECT_ID(N'[org].[TR_EmpleadoArea_UnicaVigentePorUOT]') IS NOT NULL
    DROP TRIGGER [org].[TR_EmpleadoArea_UnicaVigentePorUOT];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : org.TR_EmpleadoArea_UnicaVigentePorUOT
' Descripción            : Controla que exista una única asignación vigente de empleado por UOT.
' Aplicativo / Módulo    : DESCO / Organización
*******************************************************************************************************/
CREATE TRIGGER org.TR_EmpleadoArea_UnicaVigentePorUOT
ON org.EmpleadoArea
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT
            EA.empleado_id,
            A.uot_id
        FROM org.EmpleadoArea EA
        JOIN org.Area A
          ON A.area_id=EA.area_id
        JOIN
        (
            SELECT DISTINCT empleado_id
            FROM inserted
        ) I
          ON I.empleado_id=EA.empleado_id
        WHERE EA.estado=1
          AND EA.fecha_hasta IS NULL
        GROUP BY
            EA.empleado_id,
            A.uot_id
        HAVING COUNT_BIG(*)>1
    )
    BEGIN
        THROW 51062,
              N'El empleado ya tiene un área vigente en la UOT.',
              1;
    END;
END;
GO
