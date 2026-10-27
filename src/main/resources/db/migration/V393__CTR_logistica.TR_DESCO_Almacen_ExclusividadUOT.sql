IF OBJECT_ID(N'[logistica].[TR_DESCO_Almacen_ExclusividadUOT]', N'TR') IS NOT NULL
    DROP TRIGGER [logistica].[TR_DESCO_Almacen_ExclusividadUOT];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger       : logistica.TR_DESCO_Almacen_ExclusividadUOT
' Descripción             : Impide dar acceso activo de un almacén a una UOT ajena.
' Tabla asociada          : logistica.AlmacenUOT
' Evento que lo dispara   : INSERT,UPDATE
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Creación de reglas de integridad y aislamiento por UOT.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- El trigger se ejecuta automáticamente al modificar logistica.AlmacenUOT.
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[logistica].[TR_DESCO_Almacen_ExclusividadUOT]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_DESCO_Almacen_ExclusividadUOT
ON logistica.AlmacenUOT AFTER INSERT,UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I JOIN logistica.Almacen A ON A.almacen_id=I.almacen_id
  WHERE I.estado=1 AND (I.fecha_hasta IS NULL OR I.fecha_hasta>SYSUTCDATETIME()) AND I.uot_id<>A.uot_propietaria_id)
   THROW 51210,N'El almacén solo puede ser utilizado por su UOT propietaria.',1;
END;
GO

IF OBJECT_ID(N'[logistica].[TR_DESCO_Almacen_ProtegerPropietario]', N'TR') IS NOT NULL
    DROP TRIGGER [logistica].[TR_DESCO_Almacen_ProtegerPropietario];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger       : logistica.TR_DESCO_Almacen_ProtegerPropietario
' Descripción             : Protege la UOT propietaria cuando existen operaciones históricas.
' Tabla asociada          : logistica.Almacen
' Evento que lo dispara   : UPDATE
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Creación de reglas de integridad y aislamiento por UOT.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- El trigger se ejecuta automáticamente al modificar logistica.Almacen.
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[logistica].[TR_DESCO_Almacen_ProtegerPropietario]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_DESCO_Almacen_ProtegerPropietario
ON logistica.Almacen AFTER UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.almacen_id=I.almacen_id
  WHERE I.uot_propietaria_id<>D.uot_propietaria_id)
   THROW 51211,N'No se puede modificar la UOT propietaria de un almacén.',1;
END;
GO

IF OBJECT_ID(N'[logistica].[TR_DESCO_MovimientoInventario_AmbitoUOT]', N'TR') IS NOT NULL
    DROP TRIGGER [logistica].[TR_DESCO_MovimientoInventario_AmbitoUOT];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger       : logistica.TR_DESCO_MovimientoInventario_AmbitoUOT
' Descripción             : Valida pertenencia UOT de todo movimiento registrado.
' Tabla asociada          : logistica.MovimientoInventario
' Evento que lo dispara   : INSERT,UPDATE
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Creación de reglas de integridad y aislamiento por UOT.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- El trigger se ejecuta automáticamente al modificar logistica.MovimientoInventario.
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[logistica].[TR_DESCO_MovimientoInventario_AmbitoUOT]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_DESCO_MovimientoInventario_AmbitoUOT
ON logistica.MovimientoInventario AFTER INSERT,UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I JOIN logistica.Almacen A ON A.almacen_id=I.almacen_id
 WHERE I.uot_id<>A.uot_propietaria_id)
   THROW 51212,N'El movimiento no pertenece a la UOT del almacén.',1;
END;
GO

IF OBJECT_ID(N'[comercial].[TR_DESCO_Venta_AmbitoUOT]', N'TR') IS NOT NULL
    DROP TRIGGER [comercial].[TR_DESCO_Venta_AmbitoUOT];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger       : comercial.TR_DESCO_Venta_AmbitoUOT
' Descripción             : Valida pertenencia UOT de ventas sobre almacenes.
' Tabla asociada          : comercial.Venta
' Evento que lo dispara   : INSERT,UPDATE
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Creación de reglas de integridad y aislamiento por UOT.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- El trigger se ejecuta automáticamente al modificar comercial.Venta.
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[comercial].[TR_DESCO_Venta_AmbitoUOT]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER comercial.TR_DESCO_Venta_AmbitoUOT
ON comercial.Venta AFTER INSERT,UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I JOIN logistica.Almacen A ON A.almacen_id=I.almacen_id
 WHERE I.uot_id<>A.uot_propietaria_id)
   THROW 51213,N'La venta no corresponde al almacén de la UOT.',1;
END;
GO

IF OBJECT_ID(N'[logistica].[TR_DESCO_ProgramacionProducto_AmbitoUOT]', N'TR') IS NOT NULL
    DROP TRIGGER [logistica].[TR_DESCO_ProgramacionProducto_AmbitoUOT];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger       : logistica.TR_DESCO_ProgramacionProducto_AmbitoUOT
' Descripción             : Valida pertenencia UOT de programaciones técnicas.
' Tabla asociada          : logistica.ProgramacionProducto
' Evento que lo dispara   : INSERT,UPDATE
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Creación de reglas de integridad y aislamiento por UOT.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- El trigger se ejecuta automáticamente al modificar logistica.ProgramacionProducto.
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[logistica].[TR_DESCO_ProgramacionProducto_AmbitoUOT]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_DESCO_ProgramacionProducto_AmbitoUOT
ON logistica.ProgramacionProducto AFTER INSERT,UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted I
        JOIN logistica.Almacen A ON A.almacen_id=I.almacen_id
        WHERE I.uot_id<>A.uot_propietaria_id)
        THROW 51214,N'La programación no pertenece a la UOT del almacén.',1;
END;
GO

IF OBJECT_ID(N'[logistica].[TR_DESCO_TransferenciaAlmacen_AmbitoUOT]', N'TR') IS NOT NULL
    DROP TRIGGER [logistica].[TR_DESCO_TransferenciaAlmacen_AmbitoUOT];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger       : logistica.TR_DESCO_TransferenciaAlmacen_AmbitoUOT
' Descripción             : Valida almacenes, UOT y salidas/entradas vinculadas.
' Tabla asociada          : logistica.TransferenciaAlmacen
' Evento que lo dispara   : INSERT,UPDATE
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Creación de reglas de integridad y aislamiento por UOT.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- El trigger se ejecuta automáticamente al modificar logistica.TransferenciaAlmacen.
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[logistica].[TR_DESCO_TransferenciaAlmacen_AmbitoUOT]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_DESCO_TransferenciaAlmacen_AmbitoUOT
ON logistica.TransferenciaAlmacen AFTER INSERT,UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted I
        JOIN logistica.Almacen A ON A.almacen_id=I.almacen_origen_id
        JOIN logistica.Almacen B ON B.almacen_id=I.almacen_destino_id
        JOIN logistica.MovimientoInventario MS ON MS.movimiento_inventario_id=I.movimiento_salida_id
        JOIN logistica.MovimientoInventario ME ON ME.movimiento_inventario_id=I.movimiento_entrada_id
        WHERE A.uot_propietaria_id<>I.uot_origen_id OR B.uot_propietaria_id<>I.uot_destino_id
          OR I.almacen_origen_id=I.almacen_destino_id
          OR MS.almacen_id<>I.almacen_origen_id OR ME.almacen_id<>I.almacen_destino_id
          OR MS.naturaleza<>'S' OR ME.naturaleza<>'E'
          OR MS.tipo_movimiento<>'TRANSFERENCIA' OR ME.tipo_movimiento<>'TRANSFERENCIA')
        THROW 51215,N'La transferencia tiene almacenes o movimientos incompatibles.',1;
END;
GO
