IF OBJECT_ID(N'[prod].[PA_GP_Productor_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [prod].[PA_GP_Productor_Sel_Listado];
GO

-- Padrón exclusivo de productores de la UOT, sin duplicar org.Persona.
CREATE PROCEDURE prod.PA_GP_Productor_Sel_Listado
    @Sesion UNIQUEIDENTIFIER,
    @Usuario BIGINT,
    @Uot BIGINT,
    @Buscar NVARCHAR(120) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF prod.FN_GP_Permiso(@Sesion, @Usuario, @Uot, 'PREDIOS_LISTAR', 0) <> 1
        THROW 51101, N'Acceso no autorizado.', 1;

    SET @Buscar = NULLIF(TRIM(@Buscar), N'');
    IF @Buscar IS NOT NULL AND LEN(@Buscar) < 3
        THROW 51103, N'Ingrese al menos tres caracteres.', 1;

    SELECT TOP (500)
        P.persona_id AS personaId,
        P.tipo_documento AS tipoDocumento,
        P.numero_documento AS numeroDocumento,
        P.nombres,
        P.apellido_paterno AS apellidoPaterno,
        P.apellido_materno AS apellidoMaterno,
        CONCAT(P.nombres, N' ', P.apellido_paterno, N' ', COALESCE(P.apellido_materno, N'')) AS nombreCompleto,
        P.telefono,
        P.correo,
        P.fecha_nacimiento AS fechaNacimiento,
        U.distrito_codigo AS distritoCodigo,
        U.centro_poblado_id AS centroPobladoId,
        U.referencia
    FROM org.ProductorUOT PU WITH (NOLOCK)
    JOIN org.Productor PR WITH (NOLOCK) ON PR.persona_id = PU.persona_id AND PR.estado = 1
    JOIN org.Persona P WITH (NOLOCK) ON P.persona_id = PU.persona_id AND P.estado = 1
    LEFT JOIN geo.Ubicacion U WITH (NOLOCK) ON U.ubicacion_id = P.ubicacion_id
    WHERE PU.uot_id = @Uot AND PU.estado = 1 AND PU.fecha_hasta IS NULL
      AND (@Buscar IS NULL OR P.numero_documento LIKE @Buscar + '%'
        OR CONCAT(P.nombres, N' ', P.apellido_paterno, N' ', COALESCE(P.apellido_materno, N'')) LIKE N'%' + @Buscar + N'%')
    ORDER BY P.apellido_paterno, P.apellido_materno, P.nombres, P.persona_id;
END;
GO
