package com.franco.desco.adapter.out.sqlserver.shared;

import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageRequest;
import com.franco.desco.application.shared.pagination.PageResult;

import java.lang.reflect.RecordComponent;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public abstract class JsonPaAdapterSupport {

    private final SqlServerPaExecutor executor;
    private final PaPayloadFactory payloads;
    private final DatabaseRecordMapper mapper;

    protected JsonPaAdapterSupport(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        this.executor = executor;
        this.payloads = payloads;
        this.mapper = mapper;
    }

    protected <T> PersistenceResult<PageResult<T>> page(
            String procedure,
            Object query,
            SessionIdentity identity,
            RequestMetadata metadata,
            Class<T> itemType
    ) {
        PaExecution execution =
                executor.execute(
                        procedure,
                        Map.of(
                                "cJson",
                                payloads.query(
                                        identity,
                                        metadata,
                                        query
                                )
                        )
                );

        if (!execution.exitoso()) {
            return execution.toPersistence(null);
        }

        List<Map<String, Object>> rows =
                execution.resultSets().isEmpty()
                        ? List.of()
                        : execution.resultSets()
                        .getFirst();

        PageValues values =
                pageValues(query);

        List<T> items =
                mapper.rows(
                        rows,
                        itemType
                );

        long total =
                mapper.total(rows);

        int pages =
                total == 0
                        ? 0
                        : (int) Math.ceil(
                        (double) total
                                / values.size()
                );

        return execution.toPersistence(
                new PageResult<>(
                        items,
                        values.page(),
                        values.size(),
                        total,
                        pages
                )
        );
    }

    protected <T> PersistenceResult<T> one(
            String procedure,
            Object query,
            SessionIdentity identity,
            RequestMetadata metadata,
            Class<T> targetType
    ) {
        PaExecution execution =
                executor.execute(
                        procedure,
                        Map.of(
                                "cJson",
                                payloads.query(
                                        identity,
                                        metadata,
                                        query
                                )
                        )
                );

        if (!execution.exitoso()) {
            return execution.toPersistence(null);
        }

        return execution.toPersistence(
                mapper.aggregate(
                        execution.resultSets(),
                        targetType
                )
        );
    }

    protected <T> PersistenceResult<List<T>> list(
            String procedure,
            Object query,
            SessionIdentity identity,
            RequestMetadata metadata,
            Class<T> targetType
    ) {
        PaExecution execution =
                executor.execute(
                        procedure,
                        Map.of(
                                "cJson",
                                payloads.query(
                                        identity,
                                        metadata,
                                        query
                                )
                        )
                );

        if (!execution.exitoso()) {
            return execution.toPersistence(null);
        }

        List<Map<String, Object>> rows =
                execution.resultSets().isEmpty()
                        ? List.of()
                        : execution.resultSets()
                        .getFirst();

        return execution.toPersistence(
                mapper.rows(
                        rows,
                        targetType
                )
        );
    }

    protected PersistenceResult<Long> create(
            String procedure,
            Object command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        PaExecution execution =
                executor.execute(
                        procedure,
                        Map.of(
                                "cJson",
                                payloads.mutation(
                                        identity,
                                        metadata,
                                        command
                                )
                        )
                );

        if (!execution.exitoso()) {
            return execution.toPersistence(null);
        }

        return execution.toPersistence(
                mapper.firstLong(execution)
        );
    }

    protected PersistenceResult<Void> mutate(
            String procedure,
            Object command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        PaExecution execution =
                executor.execute(
                        procedure,
                        Map.of(
                                "cJson",
                                payloads.mutation(
                                        identity,
                                        metadata,
                                        command
                                )
                        )
                );

        return execution.toPersistence(null);
    }

    protected <T> PersistenceResult<List<T>> publicList(
            String procedure,
            Object input,
            Class<T> targetType
    ) {
        Map<String, Object> inputs =
                payloads.scalarInputs(input);

        PaExecution execution =
                executor.execute(
                        procedure,
                        inputs
                );

        if (!execution.exitoso()) {
            return execution.toPersistence(null);
        }

        List<Map<String, Object>> rows =
                execution.resultSets().isEmpty()
                        ? List.of()
                        : execution.resultSets()
                        .getFirst();

        return execution.toPersistence(
                mapper.rows(
                        rows,
                        targetType
                )
        );
    }

    protected <T> PersistenceResult<T> publicOne(
            String procedure,
            Map<String, ?> inputs,
            Class<T> targetType
    ) {
        PaExecution execution =
                executor.execute(
                        procedure,
                        inputs
                );

        if (!execution.exitoso()) {
            return execution.toPersistence(null);
        }

        return execution.toPersistence(
                mapper.aggregate(
                        execution.resultSets(),
                        targetType
                )
        );
    }

    protected PaExecution executeScalar(
            String procedure,
            Map<String, ?> inputs
    ) {
        return executor.execute(
                procedure,
                inputs
        );
    }

    protected DatabaseRecordMapper mapper() {
        return mapper;
    }

    protected PaPayloadFactory payloads() {
        return payloads;
    }

    private PageValues pageValues(Object query) {
        PageRequest<?> page =
                findPage(query);

        if (page == null) {
            return new PageValues(1, 20);
        }

        int pageNumber =
                Math.max(1, page.pagina());

        int size =
                Math.min(
                        100,
                        Math.max(
                                1,
                                page.tamanio()
                        )
                );

        return new PageValues(
                pageNumber,
                size
        );
    }

    private PageRequest<?> findPage(Object query) {
        if (query instanceof PageRequest<?> page) {
            return page;
        }

        if (query == null
                || !query.getClass().isRecord()) {
            return null;
        }

        for (RecordComponent component
                : query.getClass()
                .getRecordComponents()) {

            if (!PageRequest.class
                    .isAssignableFrom(
                            component.getType()
                    )) {
                continue;
            }

            try {
                return (PageRequest<?>)
                        component.getAccessor()
                                .invoke(query);
            } catch (ReflectiveOperationException exception) {
                throw new IllegalStateException(
                        "No se pudo resolver la paginación.",
                        exception
                );
            }
        }

        return null;
    }

    private record PageValues(
            int page,
            int size
    ) {
    }
}
