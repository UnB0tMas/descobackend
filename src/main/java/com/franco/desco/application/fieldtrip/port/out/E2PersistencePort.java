package com.franco.desco.application.fieldtrip.port.out;

import com.franco.desco.application.fieldtrip.E2Commands;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.fieldtrip.E2Models;

/** Puerto tipado de las operaciones E2. El SQL Server conserva las reglas y estados. */
public interface E2PersistencePort {
    PersistenceResult<E2Models.ListResult> listar(E2Commands.Listar command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E2Models.Catalogs> catalogos(E2Commands.Catalogos command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E2Models.Detail> ver(E2Commands.Ver command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E2Models.Operation> solicitar(E2Commands.Solicitar command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E2Models.Operation> corregir(E2Commands.Corregir command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E2Models.Operation> decidir(E2Commands.Decidir command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E2Models.Operation> entregar(E2Commands.Entregar command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E2Models.Operation> iniciar(E2Commands.Iniciar command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E2Models.Operation> visitar(E2Commands.Visitar command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E2Models.Operation> finalizarVisita(E2Commands.FinalizarVisita command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E2Models.Operation> retornar(E2Commands.Retornar command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E2Models.Operation> inspeccionar(E2Commands.Inspeccionar command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E2Models.Operation> regularizarFin(E2Commands.RegularizarFin command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E2Models.Operation> cerrar(E2Commands.Cerrar command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E2Models.Operation> vincularDestino(E2Commands.VincularDestino command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<E2Models.Operation> cancelar(E2Commands.Cancelar command, SessionIdentity identity, RequestMetadata metadata);
}
