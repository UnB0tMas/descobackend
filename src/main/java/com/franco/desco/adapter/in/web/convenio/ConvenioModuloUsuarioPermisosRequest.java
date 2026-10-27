package com.franco.desco.adapter.in.web.convenio;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import java.util.List;

@Schema(name = "ConvenioModuloUsuarioPermisosRequest")
public record ConvenioModuloUsuarioPermisosRequest(@NotNull List<String> permisos) {}
