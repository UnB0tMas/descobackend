package com.franco.desco.adapter.in.web.convenio;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;

@Schema(name = "ConvenioModuloUsuarioResponse")
public record ConvenioModuloUsuarioResponse(
        Long usuarioId, String usuario, String empleado, List<String> permisos
) {}
