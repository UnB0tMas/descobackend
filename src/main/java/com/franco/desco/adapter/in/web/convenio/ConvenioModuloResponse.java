package com.franco.desco.adapter.in.web.convenio;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(name = "ConvenioModuloResponse")
public record ConvenioModuloResponse(String codigo, String nombre, boolean habilitado) {}
