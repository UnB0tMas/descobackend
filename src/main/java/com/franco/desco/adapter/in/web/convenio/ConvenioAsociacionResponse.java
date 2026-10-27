package com.franco.desco.adapter.in.web.convenio;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(name = "ConvenioAsociacionResponse")
public record ConvenioAsociacionResponse(Long organizacionId, String nombre) {}
