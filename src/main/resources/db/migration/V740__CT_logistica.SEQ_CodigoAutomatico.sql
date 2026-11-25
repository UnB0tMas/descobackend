-- Secuencia compartida de códigos de recursos; no reiniciar numeradores existentes.
IF OBJECT_ID(N'logistica.SEQ_CodigoAutomatico', N'SO') IS NULL
BEGIN
    EXEC(N'CREATE SEQUENCE logistica.SEQ_CodigoAutomatico AS BIGINT START WITH 1 INCREMENT BY 1 MINVALUE 1 NO CYCLE CACHE 50');
END;
GO
