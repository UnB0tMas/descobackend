package com.franco.desco.adapter.out.sqlserver.shared;

import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageRequest;
import com.franco.desco.application.shared.port.out.RequestHashPort;
import org.springframework.stereotype.Component;
import tools.jackson.databind.json.JsonMapper;

import java.lang.reflect.RecordComponent;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

@Component
public final class PaPayloadFactory {

    private static final List<String> BUSINESS_ALIASES =
            List.of(
                    "datos",
                    "persona",
                    "socio",
                    "empresa",
                    "asociacion",
                    "area",
                    "empleado",
                    "usuario",
                    "rol",
                    "documento",
                    "predio",
                    "parcela",
                    "cultivo",
                    "censo",
                    "evaluacion",
                    "salida",
                    "visita",
                    "caso",
                    "tratamiento",
                    "seguimiento",
                    "campania",
                    "participacion",
                    "operativo",
                    "jabas",
                    "entrega",
                    "incidencia",
                    "ajuste",
                    "condicion",
                    "precio",
                    "bien",
                    "vehiculo",
                    "suministro",
                    "movimiento",
                    "recurso",
                    "gasto",
                    "liquidacion",
                    "pago",
                    "cobro",
                    "archivo",
                    "reporte"
            );

    private final JsonMapper jsonMapper;
    private final RequestHashPort requestHash;

    public PaPayloadFactory(
            JsonMapper jsonMapper,
            RequestHashPort requestHash
    ) {
        this.jsonMapper = jsonMapper;
        this.requestHash = requestHash;
    }

    public String query(
            SessionIdentity identity,
            RequestMetadata metadata,
            Object query
    ) {
        Map<String, Object> filters =
                queryFilters(query);

        Map<String, Object> root =
                new LinkedHashMap<>();

        root.put(
                "contexto",
                context(
                        identity,
                        metadata,
                        null
                )
        );

        root.put("filtros", filters);

        /*
         * Algunos PA históricos consultan identificadores en la raíz.
         * Mantener también los filtros planos hace compatible el backend con
         * esos contratos sin duplicar reglas de negocio.
         */
        root.putAll(filters);

        return write(root);
    }

    public String mutation(
            SessionIdentity identity,
            RequestMetadata metadata,
            Object command
    ) {
        Map<String, Object> data =
                toMap(command);

        String canonical =
                write(
                        canonicalize(data)
                );

        String hash =
                requestHash.sha256Hex(canonical);

        Map<String, Object> root =
                new LinkedHashMap<>();

        root.put(
                "contexto",
                context(
                        identity,
                        metadata,
                        hash
                )
        );

        root.putAll(data);

        /*
         * Colecciones cuyo nombre histórico en SQL difiere del nombre
         * del command Java.
         */
        if (data.containsKey("rolIds")) {
            root.put("roles", data.get("rolIds"));
        }
        if (data.containsKey("permisoIds")) {
            root.put("permisos", data.get("permisoIds"));
        }

        /*
         * La BD DESCO conserva procedimientos de distintas generaciones.
         * Todos reciben el mismo contenido de negocio, pero algunos esperan
         * $.datos y otros raíces semánticas como $.persona, $.socio,
         * $.empresa, $.movimiento, etc. Duplicar referencias JSON es
         * intencional: evita lógica de negocio en Java y permite mantener un
         * único Command de aplicación por acción.
         */
        for (String alias : BUSINESS_ALIASES) {
            root.putIfAbsent(alias, data);
        }

        return write(root);
    }

    public Map<String, Object> scalarInputs(
            Object value
    ) {
        return toMap(value);
    }

    public Map<String, Object> scalarInputs(
            Map<String, ?> values
    ) {
        return values == null
                ? Map.of()
                : new LinkedHashMap<>(values);
    }

    private Map<String, Object> context(
            SessionIdentity identity,
            RequestMetadata metadata,
            String requestHashHex
    ) {
        Map<String, Object> context =
                new LinkedHashMap<>();

        if (identity != null) {
            context.put(
                    "usuarioId",
                    identity.usuarioId()
            );
            context.put(
                    "sesionPublicaId",
                    identity.sesionPublicaId()
            );
            context.put(
                    "tokenVersion",
                    identity.tokenVersion()
            );
        }

        if (metadata != null) {
            context.put(
                    "correlacionId",
                    metadata.correlacionId()
            );
            context.put(
                    "solicitudId",
                    metadata.solicitudId()
            );
            context.put(
                    "claveIdempotencia",
                    metadata.claveIdempotencia()
            );
            context.put(
                    "ip",
                    metadata.ip()
            );
            context.put(
                    "endpoint",
                    metadata.endpoint()
            );
            context.put(
                    "userAgent",
                    metadata.userAgent()
            );
            context.put(
                    "navegador",
                    metadata.navegador()
            );
            context.put(
                    "sistemaOperativo",
                    metadata.sistemaOperativo()
            );
            context.put(
                    "deviceId",
                    metadata.deviceId()
            );
        }

        if (requestHashHex != null) {
            context.put(
                    "requestHashHex",
                    requestHashHex
            );
        }

        return context;
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> queryFilters(
            Object query
    ) {
        if (query == null) {
            return new LinkedHashMap<>();
        }

        if (query instanceof PageRequest<?> page) {
            return pageFilters(page);
        }

        if (query.getClass().isRecord()) {
            Map<String, Object> values =
                    toMap(query);

            Object nestedPage =
                    values.get("page");

            if (nestedPage instanceof Map<?, ?> map) {
                Map<String, Object> result =
                        new LinkedHashMap<>();

                Object filters =
                        map.get("filtros");

                if (filters instanceof Map<?, ?> nestedFilters) {
                    nestedFilters.forEach(
                            (key, value) ->
                                    result.put(
                                            String.valueOf(key),
                                            value
                                    )
                    );
                }

                copyIfPresent(
                        map,
                        result,
                        "pagina",
                        "pagina"
                );
                copyIfPresent(
                        map,
                        result,
                        "tamanio",
                        "tamanoPagina"
                );
                copyIfPresent(
                        map,
                        result,
                        "ordenCampo",
                        "ordenCampo"
                );
                copyIfPresent(
                        map,
                        result,
                        "ordenDireccion",
                        "ordenDireccion"
                );

                values.forEach(
                        (key, value) -> {
                            if (!"page".equals(key)) {
                                result.putIfAbsent(
                                        key,
                                        value
                                );
                            }
                        }
                );

                return result;
            }

            return values;
        }

        return toMap(query);
    }

    private Map<String, Object> pageFilters(
            PageRequest<?> page
    ) {
        Map<String, Object> result =
                toMap(page.filtros());

        result.put("pagina", page.pagina());
        result.put(
                "tamanoPagina",
                page.tamanio()
        );

        if (page.ordenCampo() != null) {
            result.put(
                    "ordenCampo",
                    page.ordenCampo()
            );
        }

        if (page.ordenDireccion() != null) {
            result.put(
                    "ordenDireccion",
                    page.ordenDireccion()
            );
        }

        return result;
    }

    private void copyIfPresent(
            Map<?, ?> source,
            Map<String, Object> target,
            String sourceKey,
            String targetKey
    ) {
        if (source.containsKey(sourceKey)) {
            target.put(
                    targetKey,
                    source.get(sourceKey)
            );
        }
    }

    private Map<String, Object> toMap(
            Object value
    ) {
        if (value == null) {
            return new LinkedHashMap<>();
        }

        if (value instanceof Map<?, ?> map) {
            Map<String, Object> result =
                    new LinkedHashMap<>();

            map.forEach(
                    (key, item) ->
                            result.put(
                                    String.valueOf(key),
                                    normalize(item)
                            )
            );

            return result;
        }

        if (!value.getClass().isRecord()) {
            Map<String, Object> result =
                    new LinkedHashMap<>();
            result.put("valor", normalize(value));
            return result;
        }

        Map<String, Object> result =
                new LinkedHashMap<>();

        for (RecordComponent component
                : value.getClass()
                .getRecordComponents()) {
            try {
                Object item =
                        component.getAccessor()
                                .invoke(value);

                result.put(
                        component.getName(),
                        normalize(item)
                );

            } catch (ReflectiveOperationException exception) {
                throw new IllegalStateException(
                        "No se pudo construir el payload del procedimiento.",
                        exception
                );
            }
        }

        return result;
    }

    private Object normalize(Object value) {
        if (value == null) {
            return null;
        }

        if (value.getClass().isRecord()) {
            return toMap(value);
        }

        if (value instanceof Map<?, ?> map) {
            return toMap(map);
        }

        if (value instanceof Collection<?> collection) {
            List<Object> result =
                    new ArrayList<>(
                            collection.size()
                    );

            for (Object item : collection) {
                result.add(normalize(item));
            }

            return result;
        }

        if (value.getClass().isArray()) {
            int length =
                    java.lang.reflect.Array
                            .getLength(value);

            List<Object> result =
                    new ArrayList<>(length);

            for (int index = 0;
                 index < length;
                 index++) {
                result.add(
                        normalize(
                                java.lang.reflect.Array
                                        .get(value, index)
                        )
                );
            }

            return result;
        }

        return value;
    }

    private Object canonicalize(Object value) {
        if (value instanceof Map<?, ?> map) {
            Map<String, Object> sorted =
                    new TreeMap<>();

            map.forEach(
                    (key, item) ->
                            sorted.put(
                                    String.valueOf(key),
                                    canonicalize(item)
                            )
            );

            return sorted;
        }

        if (value instanceof Collection<?> collection) {
            return collection.stream()
                    .map(this::canonicalize)
                    .toList();
        }

        return value;
    }

    private String write(Object value) {
        try {
            return jsonMapper.writeValueAsString(
                    value
            );
        } catch (Exception exception) {
            throw new IllegalStateException(
                    "No se pudo preparar la solicitud de persistencia.",
                    exception
            );
        }
    }
}
