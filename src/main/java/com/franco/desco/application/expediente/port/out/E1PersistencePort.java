package com.franco.desco.application.expediente.port.out;

import com.franco.desco.application.expediente.E1Commands;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.expediente.E1Models;

public interface E1PersistencePort {
    PersistenceResult<E1Models.Convenios> listConvenios(E1Commands.ListConvenios command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E1Models.Personas> searchPersonas(E1Commands.SearchPersonas command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E1Models.Identificador> createPersona(E1Commands.CreatePersona command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E1Models.Predios> listPredios(E1Commands.ListPredios command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E1Models.Identificador> createPredio(E1Commands.CreatePredio command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E1Models.Expediente> getExpediente(E1Commands.GetExpediente command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E1Models.Catalogos> getCatalogos(E1Commands.GetCatalogos command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E1Models.Identificador> addCultivo(E1Commands.AddCultivo command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E1Models.Identificador> addCrianza(E1Commands.AddCrianza command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E1Models.Identificador> addConteo(E1Commands.AddConteo command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E1Models.Identificador> addActuacion(E1Commands.AddActuacion command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E1Models.Identificador> completeFicha(E1Commands.CompleteFicha command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E1Models.Identificador> linkConvenio(E1Commands.LinkConvenio command, SessionIdentity identity, RequestMetadata metadata);
}
