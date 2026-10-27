package com.franco.desco.adapter.out.sqlserver.useradmin;

import com.franco.desco.adapter.out.sqlserver.shared.DatabaseRecordMapper;
import com.franco.desco.adapter.out.sqlserver.shared.JsonPaAdapterSupport;
import com.franco.desco.adapter.out.sqlserver.shared.PaPayloadFactory;
import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaExecutor;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.application.useradmin.UserAdminCommands.*;
import com.franco.desco.application.useradmin.port.out.UserAdminPersistencePort;
import com.franco.desco.domain.useradmin.UserAdminModels;
import org.springframework.stereotype.Repository;

import java.util.LinkedHashMap;
import java.util.Map;

@Repository
public final class UserAdminSqlServerAdapter
        extends JsonPaAdapterSupport
        implements UserAdminPersistencePort {

    public UserAdminSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<UserAdminModels.Summary>> list(
            ListUsers command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return page(
                "seg.PA_UsuarioAdmin_Sel_Listado",
                command,
                identity,
                metadata,
                UserAdminModels.Summary.class
        );
    }

    @Override
    public PersistenceResult<UserAdminModels.Detail> get(
            GetUser command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return one(
                "seg.PA_UsuarioAdmin_Sel_Detalle",
                command,
                identity,
                metadata,
                UserAdminModels.Detail.class
        );
    }

    @Override
    public PersistenceResult<Long> create(
            CreateUserPersist command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return create(
                "seg.PA_UsuarioAdmin_Ins_CrearCuenta",
                command,
                identity,
                metadata
        );
    }

    @Override
    public PersistenceResult<Void> update(
            UpdateUser command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return mutate(
                "seg.PA_UsuarioAdmin_Upd_Registro",
                command,
                identity,
                metadata
        );
    }

    @Override
    public PersistenceResult<Void> disable(
            DisableUser command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return state(
                command.usuarioId(),
                "DESHABILITAR",
                command.motivo(),
                identity,
                metadata
        );
    }

    @Override
    public PersistenceResult<Void> reactivate(
            ReactivateUser command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return state(
                command.usuarioId(),
                "REACTIVAR",
                command.motivo(),
                identity,
                metadata
        );
    }

    @Override
    public PersistenceResult<Void> assignRole(
            AssignRole command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return mutate(
                "seg.PA_UsuarioRol_Ins_Asignar",
                command,
                identity,
                metadata
        );
    }

    @Override
    public PersistenceResult<Void> removeRole(
            RemoveRole command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return mutate(
                "seg.PA_UsuarioRol_Upd_Retirar",
                command,
                identity,
                metadata
        );
    }

    private PersistenceResult<Void> state(
            Long userId,
            String action,
            String reason,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Map<String, Object> command =
                new LinkedHashMap<>();

        command.put("usuarioId", userId);
        command.put("accion", action);
        command.put("motivo", reason);

        return mutate(
                "seg.PA_UsuarioAdmin_Upd_EstadoCuenta",
                command,
                identity,
                metadata
        );
    }
}
