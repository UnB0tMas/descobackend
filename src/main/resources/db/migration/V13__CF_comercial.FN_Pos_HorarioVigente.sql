IF OBJECT_ID(N'[comercial].[FN_Pos_HorarioVigente]') IS NOT NULL
    DROP FUNCTION [comercial].[FN_Pos_HorarioVigente];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Función       : comercial.FN_Pos_HorarioVigente
' Descripción            : Devuelve el resultado de pos horario vigente.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   FUNCTION comercial.FN_Pos_HorarioVigente(@usuario BIGINT,@uot BIGINT)
RETURNS BIT
AS
BEGIN
 DECLARE @Ahora DATETIME2(0)=DATEADD(HOUR,-5,SYSUTCDATETIME());
 DECLARE @Dia INT=(DATEDIFF(DAY,CONVERT(DATE,'19000101',112),CONVERT(DATE,@Ahora))%7)+1;
 DECLARE @Hora TIME(0)=CONVERT(TIME(0),@Ahora);
 DECLARE @Empleado BIGINT;
 IF seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'POS_OPERAR')<>1 RETURN 0;
 SELECT @Empleado=U.persona_id FROM seg.Usuario U WHERE U.usuario_id=@usuario AND U.estado=1 AND U.estado_cuenta='ACTIVA';
 IF @Empleado IS NULL RETURN 0;
 IF EXISTS(SELECT 1 FROM comercial.AccesoEmpleadoPOS WHERE uot_id=@uot AND empleado_id=@Empleado AND habilitado=0) RETURN 0;
 IF seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'POS_SIN_HORARIO')=1 RETURN 1;
 IF NOT EXISTS(SELECT 1 FROM org.Empleado E JOIN org.EmpleadoUOT EU ON EU.empleado_id=E.empleado_id
   WHERE E.empleado_id=@Empleado AND E.estado=1 AND (E.fecha_cese IS NULL OR E.fecha_cese>=CONVERT(DATE,@Ahora))
    AND EU.uot_id=@uot AND EU.estado=1 AND EU.fecha_desde<=CONVERT(DATE,@Ahora)
    AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,@Ahora))) RETURN 0;
 IF EXISTS(SELECT 1 FROM comercial.HorarioEmpleadoPOS H WHERE H.empleado_id=@Empleado AND H.uot_id=@uot
   AND H.dia_semana=@Dia AND H.hora_inicio<=@Hora AND @Hora<H.hora_fin) RETURN 1;
 RETURN 0;
END;
GO
