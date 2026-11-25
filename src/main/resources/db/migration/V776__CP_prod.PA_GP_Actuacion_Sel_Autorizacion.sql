IF OBJECT_ID(N'[prod].[PA_GP_Actuacion_Sel_Autorizacion]', N'P') IS NOT NULL
    DROP PROCEDURE prod.PA_GP_Actuacion_Sel_Autorizacion;
GO

-- Control de actuaciones productivas por sesión, UOT y predio.
CREATE PROCEDURE prod.PA_GP_Actuacion_Sel_Autorizacion
    @Sesion UNIQUEIDENTIFIER,
    @Usuario BIGINT,
    @Uot BIGINT,
    @Predio BIGINT,
    @Persona BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CASE WHEN @Persona IS NOT NULL THEN prod.FN_GP_PuedeActuarProductor(@Sesion, @Usuario, @Uot, @Persona)
        ELSE prod.FN_GP_PuedeActuar(@Sesion, @Usuario, @Uot, @Predio) END AS permitido;
END;
GO
