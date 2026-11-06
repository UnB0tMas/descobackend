package com.franco.desco.application.fieldtrip.port.in;

import com.franco.desco.application.fieldtrip.E2Commands;
import com.franco.desco.application.shared.*;
import com.franco.desco.domain.fieldtrip.E2Models;

public interface E2UseCase {
    AppResult<E2Models.ListResult> listar(E2Commands.Listar c, SessionIdentity i, RequestMetadata m);
    AppResult<E2Models.Catalogs> catalogos(E2Commands.Catalogos c, SessionIdentity i, RequestMetadata m);
    AppResult<E2Models.Detail> ver(E2Commands.Ver c, SessionIdentity i, RequestMetadata m);
    AppResult<E2Models.Operation> solicitar(E2Commands.Solicitar c, SessionIdentity i, RequestMetadata m);
    AppResult<E2Models.Operation> corregir(E2Commands.Corregir c, SessionIdentity i, RequestMetadata m);
    AppResult<E2Models.Operation> decidir(E2Commands.Decidir c, SessionIdentity i, RequestMetadata m);
    AppResult<E2Models.Operation> entregar(E2Commands.Entregar c, SessionIdentity i, RequestMetadata m);
    AppResult<E2Models.Operation> iniciar(E2Commands.Iniciar c, SessionIdentity i, RequestMetadata m);
    AppResult<E2Models.Operation> visitar(E2Commands.Visitar c, SessionIdentity i, RequestMetadata m);
    AppResult<E2Models.Operation> finalizarVisita(E2Commands.FinalizarVisita c, SessionIdentity i, RequestMetadata m);
    AppResult<E2Models.Operation> retornar(E2Commands.Retornar c, SessionIdentity i, RequestMetadata m);
    AppResult<E2Models.Operation> inspeccionar(E2Commands.Inspeccionar c, SessionIdentity i, RequestMetadata m);
    AppResult<E2Models.Operation> regularizarFin(E2Commands.RegularizarFin c, SessionIdentity i, RequestMetadata m);
    AppResult<E2Models.Operation> cerrar(E2Commands.Cerrar c, SessionIdentity i, RequestMetadata m);
    AppResult<E2Models.Operation> vincularDestino(E2Commands.VincularDestino c, SessionIdentity i, RequestMetadata m);
    AppResult<E2Models.Operation> cancelar(E2Commands.Cancelar c, SessionIdentity i, RequestMetadata m);
}
