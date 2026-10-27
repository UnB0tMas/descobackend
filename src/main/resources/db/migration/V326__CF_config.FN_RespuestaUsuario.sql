IF OBJECT_ID(N'[config].[FN_RespuestaUsuario]', N'FN') IS NOT NULL
   OR OBJECT_ID(N'[config].[FN_RespuestaUsuario]', N'IF') IS NOT NULL
   OR OBJECT_ID(N'[config].[FN_RespuestaUsuario]', N'TF') IS NOT NULL
    DROP FUNCTION [config].[FN_RespuestaUsuario];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Función           : config.FN_RespuestaUsuario
' Descripción              : Resuelve el mensaje, código y estado HTTP sugerido para una respuesta de procedimiento.
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Configuración
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de ejecución:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    SELECT * FROM [config].[FN_RespuestaUsuario](N'comercial.PA_Venta_Ins_Registrar', 1, N'Acción realizada.');
*******************************************************************************************************/
CREATE FUNCTION config.FN_RespuestaUsuario
(@procedimiento NVARCHAR(257),@exitoso BIT,@texto NVARCHAR(300))
RETURNS TABLE
AS RETURN
 SELECT CONVERT(NVARCHAR(300),CASE WHEN @exitoso=1 THEN
   CASE WHEN M.mensaje=N'La acción ya se realizó.' THEN M.mensaje ELSE COALESCE(P.mensaje_exito,N'Acción realizada.') END
   ELSE COALESCE(M.mensaje,P.mensaje_error,N'No se pudo completar la acción.') END) mensaje,
 CONVERT(VARCHAR(60),CASE WHEN @exitoso=1 THEN COALESCE(P.codigo_exito,'ACCION_REALIZADA')
   ELSE COALESCE(M.codigo_error,'ACCION_NO_COMPLETADA') END) codigo,
 CONVERT(SMALLINT,CASE WHEN @exitoso=1 THEN 200 ELSE COALESCE(M.http_error,400) END) http_sugerido
 FROM (VALUES(1)) X(n)
 LEFT JOIN config.RespuestaProcedimiento P ON P.procedimiento=@procedimiento
 OUTER APPLY(SELECT TOP(1) mensaje,codigo_error,http_error FROM config.MensajeUsuario
  WHERE texto_origen=@texto ORDER BY texto_origen) M;
GO
