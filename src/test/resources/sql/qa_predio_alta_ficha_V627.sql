SET NOCOUNT ON;
IF OBJECT_ID(N'prod.PA_E1_Predio_Ins_Registrar',N'P') IS NULL
 THROW 52710,N'No existe el alta de predios E1.',1;
DECLARE @def NVARCHAR(MAX)=OBJECT_DEFINITION(OBJECT_ID(N'prod.PA_E1_Predio_Ins_Registrar',N'P'));
IF CHARINDEX(N'areaCultivableHa DECIMAL(10,4)',@def)=0 OR
   CHARINDEX(N'area_cultivable_ha,tipo_riego',@def)=0
 THROW 52711,N'El alta no guarda todas las características de forma atómica.',1;
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(N'prod.PredioVersion') AND name=N'area_cultivable_ha')
 THROW 52712,N'Falta la columna de área cultivable.',1;
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(N'prod.PredioVersion') AND name=N'tipo_riego')
 THROW 52713,N'Falta el tipo de riego.',1;
SELECT P.codigo, P.nombre, V.area_total_ha, V.area_cultivable_ha, V.tipo_riego
FROM prod.Predio P OUTER APPLY (
 SELECT TOP (1) V.area_total_ha,V.area_cultivable_ha,V.tipo_riego
 FROM prod.PredioVersion V WHERE V.predio_id=P.predio_id AND V.estado=1 AND V.fecha_hasta IS NULL
 ORDER BY V.fecha_desde DESC,V.revision DESC
) V
WHERE P.estado=1
ORDER BY P.predio_id DESC OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
IF (SELECT COUNT(DISTINCT P.codigo) FROM seg.Permiso P
    WHERE P.estado=1 AND P.codigo IN(N'PREDIOS_CREAR',N'PREDIOS_EDITAR',N'APAPPSS_PREDIOS_CREAR',N'APAPPSS_PREDIOS_EDITAR'))<>4
 THROW 52714,N'Faltan permisos de predios APAPPSS en el catálogo.',1;
IF EXISTS(SELECT 1 FROM seg.Permiso P WHERE P.estado=1
   AND P.codigo IN(N'PREDIOS_CREAR',N'PREDIOS_EDITAR',N'APAPPSS_PREDIOS_CREAR',N'APAPPSS_PREDIOS_EDITAR')
   AND NOT EXISTS(SELECT 1 FROM seg.RolPermiso RP JOIN seg.Rol R ON R.rol_id=RP.rol_id
      WHERE RP.permiso_id=P.permiso_id AND RP.estado=1 AND R.estado=1 AND R.codigo=N'ADMINISTRADOR'))
 THROW 52715,N'El administrador no tiene todos los permisos; revisar bootstrap.',1;
PRINT N'QA_OK: ficha y permisos del administrador validados. Sin cambios de datos.';
