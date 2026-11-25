package com.franco.desco.adapter.out.sqlserver.document;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.document.*;
import com.franco.desco.application.document.DocumentCommands.*;
import com.franco.desco.application.document.port.out.DocumentPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.document.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class DocumentSqlServerAdapter
        extends JsonPaAdapterSupport
        implements DocumentPersistencePort {

    public DocumentSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<DocumentModels.Summary>> list(ListDocuments command, SessionIdentity identity, RequestMetadata metadata) {
        var page = page("archivo.PA_Archivo_Sel_Listado", command, identity, metadata, DocumentModels.Summary.class);
        if (!page.exitoso() || page.datos() == null) return page;
        var before = page.datos();
        var safe = before.items().stream().filter(item -> !"CORRESPONDENCIA".equals(item.categoria())).toList();
        return PersistenceResult.ok(page.codigo(), page.mensaje(), page.httpSugerido(),
                new PageResult<>(safe, before.pagina(), before.tamanio(), before.totalRegistros(), before.totalPaginas()));
    }

    @Override
    public PersistenceResult<DocumentModels.Detail> get(GetDocument command, SessionIdentity identity, RequestMetadata metadata) {
        var result = one("archivo.PA_Archivo_Sel_Detalle", command, identity, metadata, DocumentModels.Detail.class);
        if (result.exitoso() && result.datos() != null && "CORRESPONDENCIA".equals(result.datos().categoria()))
            return PersistenceResult.error("ARCHIVO_NO_DISPONIBLE", "Archivo no disponible en este módulo.", 404);
        return result;
    }

    @Override
    public PersistenceResult<Long> register(RegisterDocument command, SessionIdentity identity, RequestMetadata metadata) {
        return create("archivo.PA_Archivo_Ins_Registro", command, identity, metadata);
    }

    @Override
    public PersistenceResult<Void> retire(RetireDocument command, SessionIdentity identity, RequestMetadata metadata) {
        return mutate("archivo.PA_Archivo_Upd_Retirar", command, identity, metadata);
    }

}
