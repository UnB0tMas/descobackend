package com.franco.desco.application.expediente.service;

import com.franco.desco.application.expediente.E1Commands;
import com.franco.desco.application.expediente.port.in.E1UseCase;
import com.franco.desco.application.expediente.port.out.E1PersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.domain.expediente.E1Models;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public final class E1ApplicationService implements E1UseCase {
    private static final Logger log = LoggerFactory.getLogger(E1ApplicationService.class);
    private final E1PersistencePort persistence;

    public E1ApplicationService(E1PersistencePort persistence) {
        this.persistence = persistence;
    }

    @Override
    public AppResult<E1Models.Convenios> listConvenios(E1Commands.ListConvenios c, SessionIdentity i, RequestMetadata m) {
        AppResult<E1Models.Convenios> error = validateContext(c.uotId(), null, null);
        return error != null ? error : ok(persistence.listConvenios(c, i, m));
    }

    @Override
    public AppResult<E1Models.Personas> searchPersonas(E1Commands.SearchPersonas c, SessionIdentity i, RequestMetadata m) {
        AppResult<E1Models.Personas> error = validateContext(c.uotId(), null, null);
        if (error != null) return error;
        if (c.buscar() == null || c.buscar().trim().length() < 3) {
            return AppResult.error(AppStatus.BAD_REQUEST, "BUSQUEDA_INVALIDA", "Ingrese al menos tres caracteres para buscar una persona.");
        }
        return ok(persistence.searchPersonas(c, i, m));
    }

    @Override
    public AppResult<E1Models.Identificador> createPersona(E1Commands.CreatePersona c, SessionIdentity i, RequestMetadata m) {
        AppResult<E1Models.Identificador> error = validateContext(c.uotId(), null, null);
        return error != null ? error : created(persistence.createPersona(c, i, m));
    }

    @Override
    public AppResult<E1Models.Predios> listPredios(E1Commands.ListPredios c, SessionIdentity i, RequestMetadata m) {
        AppResult<E1Models.Predios> error = validateContext(c.uotId(), c.convenioId(), null);
        if (error != null) return error;
        PersistenceResult<E1Models.Predios> result = persistence.listPredios(c, i, m);
        if (result != null && result.exitoso()
                && (result.datos() == null || result.datos().items() == null
                    || result.datos().items().stream().anyMatch(java.util.Objects::isNull))) {
            // Un listado valido puede estar vacio, pero nunca omitir el arreglo items.
            // No convertir una respuesta defectuosa en "sin registros": es un error de contrato.
            log.error("E1 listado de predios: contrato de persistencia invalido (uotId={}, convenioId={}, codigo={})",
                    c.uotId(), c.convenioId(), result.codigo());
            return AppResult.error(AppStatus.INTERNAL_ERROR, "EXPEDIENTE_RESPUESTA_INVALIDA",
                    "No se pudo cargar el listado de predios.");
        }
        return ok(result);
    }

    @Override
    public AppResult<E1Models.Identificador> createPredio(E1Commands.CreatePredio c, SessionIdentity i, RequestMetadata m) {
        AppResult<E1Models.Identificador> error = validateContext(c.uotId(), c.convenioId(), null);
        if (error != null) return error;
        if (c.convenioId() == null) {
            var p = c.predio();
            if (p == null || p.areaTotalHa() == null || p.areaTotalHa().signum() <= 0 ||
                    p.areaCultivableHa() == null || p.areaCultivableHa().signum() < 0 ||
                    p.areaCultivableHa().compareTo(p.areaTotalHa()) > 0 ||
                    p.tipoRiego() == null || p.tipoRiego().isBlank() || p.tipoRiego().length() > 30 ||
                    p.latitud() == null || p.longitud() == null) {
                return AppResult.error(AppStatus.BAD_REQUEST, "PREDIO_INCOMPLETO",
                        "Complete la ubicación y los datos productivos del fundo.");
            }
        }
        return created(persistence.createPredio(c, i, m));
    }

    @Override
    public AppResult<E1Models.Expediente> getExpediente(E1Commands.GetExpediente c, SessionIdentity i, RequestMetadata m) {
        AppResult<E1Models.Expediente> error = validateContext(c.uotId(), c.convenioId(), c.predioId());
        return error != null ? error : ok(persistence.getExpediente(c, i, m));
    }

    @Override
    public AppResult<E1Models.Catalogos> getCatalogos(E1Commands.GetCatalogos c, SessionIdentity i, RequestMetadata m) {
        AppResult<E1Models.Catalogos> error = validateContext(c.uotId(), null, null);
        return error != null ? error : ok(persistence.getCatalogos(c, i, m));
    }

    @Override
    public AppResult<E1Models.Identificador> addCultivo(E1Commands.AddCultivo c, SessionIdentity i, RequestMetadata m) {
        AppResult<E1Models.Identificador> error = validateContext(c.uotId(), c.convenioId(), c.predioId());
        return error != null ? error : created(persistence.addCultivo(c, i, m));
    }

    @Override
    public AppResult<E1Models.Identificador> addCrianza(E1Commands.AddCrianza c, SessionIdentity i, RequestMetadata m) {
        AppResult<E1Models.Identificador> error = validateContext(c.uotId(), c.convenioId(), c.predioId());
        return error != null ? error : created(persistence.addCrianza(c, i, m));
    }

    @Override
    public AppResult<E1Models.Identificador> addConteo(E1Commands.AddConteo c, SessionIdentity i, RequestMetadata m) {
        AppResult<E1Models.Identificador> error = validateContext(c.uotId(), c.convenioId(), c.predioId());
        return error != null ? error : created(persistence.addConteo(c, i, m));
    }

    @Override
    public AppResult<E1Models.Identificador> addActuacion(E1Commands.AddActuacion c, SessionIdentity i, RequestMetadata m) {
        AppResult<E1Models.Identificador> error = validateContext(c.uotId(), c.convenioId(), c.predioId());
        return error != null ? error : created(persistence.addActuacion(c, i, m));
    }

    @Override
    public AppResult<E1Models.Identificador> completeFicha(E1Commands.CompleteFicha c, SessionIdentity i, RequestMetadata m) {
        AppResult<E1Models.Identificador> error = validateContext(c.uotId(), c.convenioId(), c.predioId());
        if (error != null) return error;
        var ficha = c.ficha();
        if (ficha == null || (ficha.areaTotalHa() == null && ficha.areaCultivableHa() == null
                && (ficha.tipoRiego() == null || ficha.tipoRiego().isBlank()))) {
            return AppResult.error(AppStatus.BAD_REQUEST, "FICHA_SIN_CAMBIOS", "Ingrese al menos un dato técnico para guardar la ficha.");
        }
        if (ficha.areaTotalHa() != null && ficha.areaCultivableHa() != null
                && ficha.areaCultivableHa().compareTo(ficha.areaTotalHa()) > 0) {
            return AppResult.error(AppStatus.BAD_REQUEST, "AREA_INVALIDA", "El área cultivable no puede superar el área total.");
        }
        return ok(persistence.completeFicha(c, i, m));
    }

    @Override
    public AppResult<E1Models.Identificador> linkConvenio(E1Commands.LinkConvenio c, SessionIdentity i, RequestMetadata m) {
        AppResult<E1Models.Identificador> error = validateContext(c.uotId(), c.convenioId(), c.predioId());
        return error != null ? error : created(persistence.linkConvenio(c, i, m));
    }

    private <T> AppResult<T> ok(PersistenceResult<T> result) {
        return ApplicationResults.ok(result, "EXPEDIENTE_OK", "EXPEDIENTE_ERROR", AppStatus.BAD_REQUEST);
    }

    private <T> AppResult<T> created(PersistenceResult<T> result) {
        return ApplicationResults.created(result, "EXPEDIENTE_CREADO", "EXPEDIENTE_ERROR");
    }

    private <T> AppResult<T> validateContext(Long uotId, Long convenioId, Long predioId) {
        if (uotId == null || uotId < 1) {
            return AppResult.error(AppStatus.BAD_REQUEST, "CONTEXTO_INVALIDO", "Seleccione una UOT válida.");
        }
        if (convenioId != null && convenioId < 1) {
            return AppResult.error(AppStatus.BAD_REQUEST, "CONVENIO_INVALIDO", "El convenio no es válido.");
        }
        if (predioId != null && predioId < 1) {
            return AppResult.error(AppStatus.BAD_REQUEST, "PREDIO_INVALIDO", "El predio no es válido.");
        }
        return null;
    }
}
