-- V668. APAPPSS / Pagos a socios: módulo independiente de interfaz y permisos por rol/UOT.
-- Mantener PAGOS_* para API financiera; este módulo añade un límite de acceso APAPPSS.
-- No reactiva concesiones denegadas ni habilita convenios nuevos.
SET XACT_ABORT ON;
GO
BEGIN TRANSACTION;

DECLARE @padre INT, @modulo INT, @especial INT;
SELECT @padre=modulo_id FROM seg.Modulo WHERE codigo='GRP_COMERCIAL' AND estado=1;
SELECT @especial=modulo_especial_id FROM seg.ModuloEspecial
WHERE codigo='COMERCIALIZACION_ASOCIATIVA' AND estado=1;
IF @padre IS NULL OR @especial IS NULL
    THROW 51000, N'Falta la estructura de comercialización asociativa.', 1;

IF NOT EXISTS (SELECT 1 FROM seg.Modulo WITH(UPDLOCK,HOLDLOCK) WHERE codigo='APAPPSS_PAGOS')
    INSERT INTO seg.Modulo (modulo_padre_id,codigo,nombre,orden,estado,ruta,icono,visible_menu,es_grupo)
    VALUES (@padre,'APAPPSS_PAGOS',N'APAPPSS - Pagos a socios',95,1,
            '/gestion-comercial/pagos-socios','money-bill-transfer',0,0);

SELECT @modulo=modulo_id FROM seg.Modulo WHERE codigo='APAPPSS_PAGOS' AND estado=1;
IF @modulo IS NULL
    THROW 51000, N'El módulo de pagos a socios está deshabilitado.', 1;

DECLARE @permisos TABLE (
    codigo VARCHAR(40) NOT NULL PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL,
    accion VARCHAR(20) NOT NULL,
    sensible BIT NOT NULL
);
INSERT INTO @permisos(codigo,nombre,accion,sensible) VALUES
 ('APAPPSS_PAGOS_LISTAR',N'APAPPSS - Listar pagos a socios','LISTAR',0),
 ('APAPPSS_PAGOS_VER',N'APAPPSS - Ver detalle de pagos','VER',0),
 ('APAPPSS_PAGOS_PAGAR',N'APAPPSS - Pagar a socio','CONFIRMAR',1);

INSERT INTO seg.Permiso (modulo_id,codigo,nombre,descripcion,estado,accion,es_sensible,requiere_motivo)
SELECT @modulo,X.codigo,X.nombre,N'Acción de pagos a socios en APAPPSS.',1,X.accion,X.sensible,0
FROM @permisos X
WHERE NOT EXISTS (SELECT 1 FROM seg.Permiso P WITH(UPDLOCK,HOLDLOCK) WHERE P.codigo=X.codigo);

IF EXISTS (SELECT 1 FROM @permisos X JOIN seg.Permiso P ON P.codigo=X.codigo
           WHERE P.modulo_id<>@modulo OR P.estado<>1)
    THROW 51000, N'Permisos APAPPSS_PAGOS inconsistentes o deshabilitados.', 1;

INSERT INTO seg.ModuloEspecialPermiso (modulo_especial_id,permiso_id)
SELECT @especial,P.permiso_id
FROM @permisos X JOIN seg.Permiso P ON P.codigo=X.codigo AND P.estado=1
WHERE NOT EXISTS (SELECT 1 FROM seg.ModuloEspecialPermiso MP WITH(UPDLOCK,HOLDLOCK)
                  WHERE MP.modulo_especial_id=@especial AND MP.permiso_id=P.permiso_id);

COMMIT TRANSACTION;
GO
