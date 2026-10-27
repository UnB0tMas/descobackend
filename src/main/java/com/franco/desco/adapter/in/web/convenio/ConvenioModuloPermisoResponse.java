package com.franco.desco.adapter.in.web.convenio;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(name = "ConvenioModuloPermisoResponse")
public record ConvenioModuloPermisoResponse(String codigo, String nombre) {}
