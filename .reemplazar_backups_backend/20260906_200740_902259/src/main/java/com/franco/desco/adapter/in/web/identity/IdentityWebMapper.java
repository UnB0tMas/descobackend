package com.franco.desco.adapter.in.web.identity;

import com.franco.desco.application.identity.IdentityCommands.ResolveDocument;
import com.franco.desco.domain.identity.IdentityModels;
import org.springframework.stereotype.Component;

@Component
public class IdentityWebMapper {

    public ResolveDocument command(
            IdentityRequests.Resolve request
    ) {
        return new ResolveDocument(
                IdentityModels.Target.valueOf(
                        request.entidadObjetivo().name()
                ),
                IdentityModels.DocumentType.valueOf(
                        request.tipoDocumento().name()
                ),
                request.numeroDocumento()
        );
    }

    public IdentityResponses.Resolve response(
            IdentityModels.ResolutionResult value
    ) {
        return new IdentityResponses.Resolve(
                value.origen().name(),
                value.encontrado(),
                value.insertadoAutomaticamente(),
                value.permiteCargaManual(),
                value.entidadObjetivo().name(),
                value.entidadId(),
                value.tipoPersona(),
                value.tipoDocumento() == null
                        ? null
                        : value.tipoDocumento().name(),
                value.numeroDocumento(),
                value.nombres(),
                value.apellidoPaterno(),
                value.apellidoMaterno(),
                value.telefono(),
                value.correo(),
                value.razonSocial(),
                value.fechaNacimiento(),
                value.sexo(),
                value.ubicacionId(),
                value.departamentoCodigo(),
                value.departamentoNombre(),
                value.provinciaCodigo(),
                value.provinciaNombre(),
                value.distritoCodigo(),
                value.distritoNombre(),
                value.centroPobladoId(),
                value.centroPobladoNombre(),
                value.referenciaUbicacion(),
                value.ubigeoReniec(),
                value.ubigeoSunat(),
                value.estadoEntidad(),
                value.esEmpleado(),
                value.esSocio(),
                value.esAsociacion(),
                value.estadoConsulta(),
                value.direccionFiscalSugerida(),
                value.reintentoDesdeUtc()
        );
    }
}
