package com.franco.desco.application.e5.service;

import com.franco.desco.application.e5.E5Commands;
import com.franco.desco.application.e5.port.in.E5UseCase;
import com.franco.desco.application.e5.port.out.E5PersistencePort;
import com.franco.desco.application.shared.*;
import org.springframework.stereotype.Service;
import java.util.Set;

@Service
public final class E5ApplicationService implements E5UseCase {
    private static final Set<String> ACTIONS=Set.of("TABLERO","GASTOS","REPARTIR","APROBAR_REPARTO",
      "RECTIFICAR_REPARTO","REPARTO","LIQUIDAR","APROBAR","OBSERVAR","LIQUIDACIONES",
      "LIQUIDACION","PAGAR","REVERSAR","REPORTE","EXPORTAR","CIERRE_VALIDAR","CERRAR","COBROS");
    private final E5PersistencePort persistence;
    public E5ApplicationService(E5PersistencePort persistence) { this.persistence=persistence; }
    @Override public <T> AppResult<T> execute(E5Commands.Execute command,SessionIdentity identity,
                                              RequestMetadata metadata,Class<T> type) {
        if (command==null || command.accion()==null || !ACTIONS.contains(command.accion()) ||
            command.campaniaId()==null && command.gastoId()==null && command.participacionId()==null
                && command.liquidacionId()==null && command.pagoId()==null)
            return AppResult.error(AppStatus.BAD_REQUEST,"E5_CONTEXTO_INVALIDO",
                "Seleccione una campaña, gasto, liquidación o pago válido.");
        return ApplicationResults.ok(persistence.execute(command,identity,metadata,type),
                "E5_OK","E5_ERROR",AppStatus.BAD_REQUEST);
    }
}
