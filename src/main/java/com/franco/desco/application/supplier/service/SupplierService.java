package com.franco.desco.application.supplier.service;

import com.franco.desco.adapter.in.web.supplier.SupplierWebTypes;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.service.EmailValidationService;
import com.franco.desco.application.supplier.port.in.SupplierUseCase;
import com.franco.desco.application.supplier.port.out.SupplierPersistencePort;
import org.springframework.stereotype.Service;
import java.util.Map;

@Service
public final class SupplierService implements SupplierUseCase {
    private final SupplierPersistencePort persistence;
    private final EmailValidationService emailValidation;
    public SupplierService(SupplierPersistencePort persistence, EmailValidationService emailValidation) {
        this.persistence = persistence;
        this.emailValidation = emailValidation;
    }

    @Override
    public AppResult<SupplierWebTypes.Page> list(Long uotId, String search, String type,
                                                   boolean activeOnly, int page, int size, SessionIdentity identity) {
        return ApplicationResults.ok(persistence.execute("LISTAR", uotId,
            Map.of("pagina", page, "tamano", size, "buscar", search == null ? "" : search,
                   "tipo", type == null ? "" : type, "soloActivos", activeOnly),
            identity, SupplierWebTypes.Page.class), "PROVEEDORES_LISTADOS", "PROVEEDORES_NO_LISTADOS", AppStatus.BAD_REQUEST);
    }

    @Override
    public AppResult<SupplierWebTypes.Registered> register(SupplierWebTypes.Save data, SessionIdentity identity) {
        AppResult<SupplierWebTypes.Registered> error = emailValidation.required(data.correo());
        if (error != null) return error;
        return ApplicationResults.created(persistence.execute("REGISTRAR", data.uotId(), data,
            identity, SupplierWebTypes.Registered.class), "PROVEEDOR_REGISTRADO", "PROVEEDOR_NO_REGISTRADO");
    }

    @Override
    public AppResult<SupplierWebTypes.Registered> update(Long id, SupplierWebTypes.Save data, SessionIdentity identity) {
        AppResult<SupplierWebTypes.Registered> error = emailValidation.ifProvided(data.correo());
        if (error != null) return error;
        return ApplicationResults.ok(persistence.execute("ACTUALIZAR", data.uotId(),
            Map.of("id", id, "datos", data), identity, SupplierWebTypes.Registered.class),
            "PROVEEDOR_ACTUALIZADO", "PROVEEDOR_NO_ACTUALIZADO", AppStatus.BAD_REQUEST);
    }

    @Override
    public AppResult<SupplierWebTypes.Registered> setState(Long uotId, Long id, boolean enabled,
                                                            SessionIdentity identity) {
        return ApplicationResults.ok(persistence.execute("ESTADO", uotId,
            Map.of("id", id, "estado", enabled), identity, SupplierWebTypes.Registered.class),
            "PROVEEDOR_ESTADO_ACTUALIZADO", "PROVEEDOR_ESTADO_NO_ACTUALIZADO", AppStatus.BAD_REQUEST);
    }
}
