package com.franco.desco.adapter.in.web.convenio;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

@Schema(name = "ConvenioModuloRequest")
public record ConvenioModuloRequest(@NotNull Boolean habilitado) {}
