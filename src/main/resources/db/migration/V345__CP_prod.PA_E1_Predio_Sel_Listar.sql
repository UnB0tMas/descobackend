IF OBJECT_ID(N'[prod].[PA_E1_Predio_Sel_Listar]') IS NOT NULL
    DROP PROCEDURE [prod].[PA_E1_Predio_Sel_Listar];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : prod.PA_E1_Predio_Sel_Listar
' Descripción            : Consulta e1 predio para listar.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   PROCEDURE prod.PA_E1_Predio_Sel_Listar
 @cJson NVARCHAR(MAX), @nUot BIGINT, @nConvenio BIGINT, @cDatos NVARCHAR(MAX) OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
        DECLARE @cBuscarPredio NVARCHAR(150)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.filtros.buscar'))),N'');
        DECLARE @cListaPredios NVARCHAR(MAX);
        -- Materializar primero el arreglo: nunca se debe devolver un DTO sin "items".
        -- FOR JSON PATH emite [] cuando no hay predios en el ambito solicitado.
        SELECT @cListaPredios=(SELECT TOP (100) P.predio_id predioId,P.codigo,P.nombre,U.distrito_codigo distritoCodigo,
          U.referencia,CASE WHEN U.posicion IS NULL THEN NULL ELSE U.posicion.Lat END latitud,
          CASE WHEN U.posicion IS NULL THEN NULL ELSE U.posicion.Long END longitud,
          (SELECT TOP (1) CONCAT(PE.nombres,N' ',PE.apellido_paterno)
             FROM prod.PredioTitularidad T
             JOIN org.Persona PE ON PE.persona_id=T.persona_id
             WHERE T.predio_id=P.predio_id AND T.estado=1 AND T.fecha_hasta IS NULL
             ORDER BY T.persona_id) titular
          FROM prod.PredioAmbito A
          JOIN prod.Predio P ON P.predio_id=A.predio_id AND P.estado=1
          JOIN geo.Ubicacion U ON U.ubicacion_id=P.ubicacion_id
          WHERE A.uot_id=@nUot AND A.estado=1
            AND ((@nConvenio IS NULL AND A.convenio_uot_organizacion_id IS NULL) OR A.convenio_uot_organizacion_id=@nConvenio)
            AND (@cBuscarPredio IS NULL OR P.nombre LIKE N'%'+@cBuscarPredio+N'%' OR P.codigo LIKE '%'+@cBuscarPredio+'%'
                OR EXISTS(SELECT 1 FROM prod.PredioTitularidad T
                          JOIN org.Persona PE ON PE.persona_id=T.persona_id
                          WHERE T.predio_id=P.predio_id
                            AND (PE.numero_documento LIKE '%'+@cBuscarPredio+'%' OR PE.nombres LIKE N'%'+@cBuscarPredio+N'%')))
          ORDER BY P.nombre,P.predio_id FOR JSON PATH,INCLUDE_NULL_VALUES);

        -- No encontrar filas equivale a un arreglo vacio, nunca a un campo ausente.
        IF @cListaPredios IS NULL OR @cListaPredios=N''
           SET @cListaPredios=N'[]';
        IF ISJSON(@cListaPredios)<>1 OR LEFT(LTRIM(@cListaPredios),1)<>N'['
           THROW 51068,N'La consulta de predios produjo un arreglo JSON invalido.',1;

        SET @cDatos=(SELECT JSON_QUERY(@cListaPredios) AS items FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
        IF ISJSON(@cDatos)<>1 OR JSON_QUERY(@cDatos,'$.items') IS NULL
           THROW 51068,N'El contrato JSON de predios no incluye items.',1;
END;
GO
