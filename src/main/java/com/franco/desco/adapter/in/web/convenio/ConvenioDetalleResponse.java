package com.franco.desco.adapter.in.web.convenio;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;

@Schema(name = "ConvenioDetalleResponse")
public record ConvenioDetalleResponse(
        Long convenioId, Long uotId, Long organizacionId, String organizacion,
        String tipoVinculo, String numeroConvenio, List<ConvenioModuloResponse> modulos
) {}
