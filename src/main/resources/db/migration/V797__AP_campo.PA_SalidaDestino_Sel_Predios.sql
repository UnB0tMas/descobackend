IF OBJECT_ID(N'[campo].[PA_SalidaDestino_Sel_Predios]', N'P') IS NOT NULL
    DROP PROCEDURE campo.PA_SalidaDestino_Sel_Predios;
GO

-- Control de actuaciones productivas por sesión, UOT y predio.
CREATE   PROCEDURE campo.PA_SalidaDestino_Sel_Predios
 @nUsuarioId BIGINT,@nUotId BIGINT,@cBuscar NVARCHAR(150)=NULL
AS
BEGIN
 SET NOCOUNT ON;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'SALIDAS_VER')<>1
   THROW 51341,N'No tiene permiso para consultar predios de la UOT.',1;
 SELECT P.predio_id predioId, P.codigo,
    CONCAT(P.nombre, CASE WHEN T.productor IS NULL THEN N'' ELSE N' · ' + T.productor END,
        CASE WHEN L.parcelas IS NULL THEN N'' ELSE N' · ' + L.parcelas END) nombre
 FROM prod.Predio P WITH (NOLOCK)
 OUTER APPLY (
     SELECT TOP (1) CONCAT(PE.nombres, N' ', PE.apellido_paterno, N' ', COALESCE(PE.apellido_materno,N'')) productor
     FROM prod.PredioTitularidad PT WITH (NOLOCK)
     JOIN org.Persona PE WITH (NOLOCK) ON PE.persona_id = PT.persona_id AND PE.estado = 1
     WHERE PT.predio_id = P.predio_id AND PT.estado = 1 AND PT.fecha_hasta IS NULL
     ORDER BY PT.persona_id
 ) T
 OUTER APPLY (
     SELECT STRING_AGG(CONVERT(NVARCHAR(MAX), PA.nombre), N', ') WITHIN GROUP (ORDER BY PA.parcela_id) parcelas
     FROM prod.Parcela PA WITH (NOLOCK)
     WHERE PA.predio_id = P.predio_id AND PA.estado = 1
 ) L
 WHERE P.estado=1
   AND (P.uot_id=@nUotId OR EXISTS(SELECT 1 FROM prod.PredioAmbito A
       WHERE A.predio_id=P.predio_id AND A.uot_id=@nUotId AND A.estado=1))
   AND (@cBuscar IS NULL OR P.nombre LIKE N'%'+@cBuscar+N'%' OR P.codigo LIKE N'%'+@cBuscar+N'%' OR T.productor LIKE N'%'+@cBuscar+N'%' OR L.parcelas LIKE N'%'+@cBuscar+N'%')
 ORDER BY P.nombre,P.predio_id;
END;
GO
