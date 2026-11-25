IF OBJECT_ID(N'[campo].[PA_SalidaDestino_Sel_Predios]') IS NOT NULL
    DROP PROCEDURE [campo].[PA_SalidaDestino_Sel_Predios];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : campo.PA_SalidaDestino_Sel_Predios
' Descripción            : Consulta salida destino para predios.
' Aplicativo / Módulo    : DESCO / campo
*******************************************************************************************************/
CREATE   PROCEDURE campo.PA_SalidaDestino_Sel_Predios
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
