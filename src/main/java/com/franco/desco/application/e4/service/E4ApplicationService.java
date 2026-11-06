package com.franco.desco.application.e4.service;

import com.franco.desco.application.e4.E4Commands.Execute;
import com.franco.desco.application.e4.port.in.E4UseCase;
import com.franco.desco.application.e4.port.out.E4PersistencePort;
import com.franco.desco.application.shared.*;
import org.springframework.stereotype.Service;

@Service
public final class E4ApplicationService implements E4UseCase {
    private final E4PersistencePort persistence;
    public E4ApplicationService(E4PersistencePort persistence) { this.persistence = persistence; }

    @Override
    public <T> AppResult<T> execute(Execute command, SessionIdentity identity,
                                     RequestMetadata metadata, Class<T> type) {
        if (command == null || command.accion() == null || command.campaniaId() == null
            && command.operativoSocioId() == null && command.asignacionId() == null
            && command.unidadId() == null && command.entregaId() == null) {
            return AppResult.error(AppStatus.BAD_REQUEST, "E4_CONTEXTO_INVALIDO",
                    "Seleccione una campaña, participante o asignación válida.");
        }
        if (!java.util.Set.of("RESUMEN","CONFIGURAR","ASIGNAR","UNIDADES","PESAR",
                              "DEVOLVER","CONFIRMAR","SANCION","TARIFA","CARGO","BALANCE","VALIDAR_FALTANTE",
                              "SOCIOS","INCLUIR_SOCIOS","CLASIFICAR","STOCK","VALIDAR_RETORNO",
                              "PREPESAR","ANULAR_PESAJE","CORREGIR_PESAJE","HISTORIAL")
                .contains(command.accion())) {
            return AppResult.error(AppStatus.BAD_REQUEST, "E4_OPERACION_INVALIDA", "Operación no permitida.");
        }
        return ApplicationResults.ok(persistence.execute(command,identity,metadata,type),
                "E4_OK", "E4_ERROR", AppStatus.BAD_REQUEST);
    }
}
