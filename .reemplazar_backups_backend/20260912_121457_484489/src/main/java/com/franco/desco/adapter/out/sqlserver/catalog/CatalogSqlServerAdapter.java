package com.franco.desco.adapter.out.sqlserver.catalog;

import com.franco.desco.adapter.out.sqlserver.shared.PaAdapterSupport;
import com.franco.desco.adapter.out.sqlserver.shared.PaExecutionException;
import com.franco.desco.adapter.out.sqlserver.shared.PaPayloadFactory;
import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaExecutor;
import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaFactory;
import com.franco.desco.adapter.out.sqlserver.shared.SqlValues;
import com.franco.desco.application.catalog.CatalogCommands.CreateCatalog;
import com.franco.desco.application.catalog.CatalogCommands.DisableCatalog;
import com.franco.desco.application.catalog.CatalogCommands.ListCatalog;
import com.franco.desco.application.catalog.CatalogCommands.ListDistricts;
import com.franco.desco.application.catalog.CatalogCommands.ListPopulationCenters;
import com.franco.desco.application.catalog.CatalogCommands.ListProvinces;
import com.franco.desco.application.catalog.CatalogCommands.UpdateCatalog;
import com.franco.desco.application.catalog.port.out.CatalogPersistencePort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.catalog.CatalogModels;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Component;

import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class CatalogSqlServerAdapter
        implements CatalogPersistencePort {

    private final SqlServerPaExecutor executor;
    private final PaPayloadFactory payloadFactory;

    private final SimpleJdbcCall list;
    private final SimpleJdbcCall create;
    private final SimpleJdbcCall update;
    private final SimpleJdbcCall disable;

    private final SimpleJdbcCall departments;
    private final SimpleJdbcCall provinces;
    private final SimpleJdbcCall districts;
    private final SimpleJdbcCall populationCenters;

    public CatalogSqlServerAdapter(
            SqlServerPaFactory factory,
            SqlServerPaExecutor executor,
            PaPayloadFactory payloadFactory
    ) {
        this.executor = executor;
        this.payloadFactory = payloadFactory;

        this.list = factory.callWithResultSets(
                "config",
                "PA_Catalogo_Sel_Listado",
                "items"
        );
        this.create = factory.call(
                "config",
                "PA_Catalogo_Ins_Registro"
        );
        this.update = factory.call(
                "config",
                "PA_Catalogo_Upd_Registro"
        );
        this.disable = factory.call(
                "config",
                "PA_Catalogo_Upd_Deshabilitar"
        );

        this.departments = factory.callWithResultSets(
                "geo",
                "PA_Departamento_Sel_Listado",
                "items"
        );
        this.provinces = factory.callWithResultSets(
                "geo",
                "PA_Provincia_Sel_PorDepartamento",
                "items"
        );
        this.districts = factory.callWithResultSets(
                "geo",
                "PA_Distrito_Sel_PorProvincia",
                "items"
        );
        this.populationCenters = factory.callWithResultSets(
                "geo",
                "PA_CentroPoblado_Sel_PorDistrito",
                "items"
        );
    }

    @Override
    public PersistenceResult<PageResult<CatalogModels.Item>> list(
            ListCatalog command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        int page = command.page().pagina();
        int size = command.page().tamanio();

        Map<String, Object> payload = payloadFactory.forQuery(
                identity,
                metadata,
                Map.of(
                        "paginacion",
                        Map.of(
                                "pagina", page,
                                "tamanoPagina", size
                        ),
                        "filtros",
                        Map.of(
                                "catalogo",
                                command.page().filtros().catalogo()
                        )
                )
        );

        var resultSets = executor.executeJsonMultiResult(
                list,
                payload
        );

        return PaAdapterSupport.page(
                resultSets.raw(),
                resultSets.rows("items"),
                page,
                size,
                this::item,
                "No se pudo consultar el catálogo."
        );
    }

    @Override
    public PersistenceResult<Long> create(
            CreateCatalog command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Map<String, Object> output = executor.executeJsonMutation(
                create,
                payloadFactory.forWrite(
                        identity,
                        metadata,
                        command,
                        Map.of(
                                "catalogo",
                                map(
                                        "catalogo", command.catalogo(),
                                        "codigo", command.codigo(),
                                        "nombre", command.nombre(),
                                        "descripcion", command.descripcion(),
                                        "categoria", command.categoria()
                                )
                        )
                )
        );

        return PaAdapterSupport.result(
                output,
                SqlValues.longValue(
                        output,
                        "nCatalogoId"
                ),
                "No se pudo registrar el valor del catálogo."
        );
    }

    @Override
    public PersistenceResult<Void> update(
            UpdateCatalog command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Map<String, Object> output = executor.executeJsonMutation(
                update,
                payloadFactory.forWrite(
                        identity,
                        metadata,
                        command,
                        Map.of(
                                "catalogo",
                                map(
                                        "catalogo", command.catalogo(),
                                        "id", command.id(),
                                        "nombre", command.nombre(),
                                        "descripcion", command.descripcion(),
                                        "categoria", command.categoria()
                                )
                        )
                )
        );

        return PaAdapterSupport.result(
                output,
                null,
                "No se pudo actualizar el valor del catálogo."
        );
    }

    @Override
    public PersistenceResult<Void> disable(
            DisableCatalog command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Map<String, Object> output = executor.executeJsonMutation(
                disable,
                payloadFactory.forWrite(
                        identity,
                        metadata,
                        command,
                        Map.of(
                                "catalogo",
                                map(
                                        "catalogo", command.catalogo(),
                                        "id", command.id(),
                                        "motivo", command.motivo()
                                )
                        )
                )
        );

        return PaAdapterSupport.result(
                output,
                null,
                "No se pudo deshabilitar el valor del catálogo."
        );
    }

    @Override
    public PersistenceResult<List<CatalogModels.Department>> departments() {
        try {
            var resultSets = executor.executeMultiResult(
                    departments,
                    Map.of()
            );

            return PersistenceResult.ok(
                    "Departamentos consultados correctamente.",
                    resultSets.rows("items")
                            .stream()
                            .map(row ->
                                    new CatalogModels.Department(
                                            SqlValues.string(
                                                    row,
                                                    "departamentoCodigo"
                                            ),
                                            SqlValues.string(
                                                    row,
                                                    "departamentoNombre"
                                            )
                                    )
                            )
                            .toList()
            );
        } catch (PaExecutionException exception) {
            return geoError(
                    exception,
                    "No se pudieron consultar los departamentos."
            );
        }
    }

    @Override
    public PersistenceResult<List<CatalogModels.Province>> provinces(
            ListProvinces command
    ) {
        try {
            var resultSets = executor.executeJsonMultiResult(
                    provinces,
                    Map.of(
                            "departamentoCodigo",
                            command.departamentoCodigo()
                    )
            );

            return PersistenceResult.ok(
                    "Provincias consultadas correctamente.",
                    resultSets.rows("items")
                            .stream()
                            .map(row ->
                                    new CatalogModels.Province(
                                            SqlValues.string(
                                                    row,
                                                    "provinciaCodigo"
                                            ),
                                            SqlValues.string(
                                                    row,
                                                    "provinciaNombre"
                                            )
                                    )
                            )
                            .toList()
            );
        } catch (PaExecutionException exception) {
            return geoError(
                    exception,
                    "El departamento seleccionado no está disponible."
            );
        }
    }

    @Override
    public PersistenceResult<List<CatalogModels.District>> districts(
            ListDistricts command
    ) {
        try {
            var resultSets = executor.executeJsonMultiResult(
                    districts,
                    Map.of(
                            "provinciaCodigo",
                            command.provinciaCodigo()
                    )
            );

            return PersistenceResult.ok(
                    "Distritos consultados correctamente.",
                    resultSets.rows("items")
                            .stream()
                            .map(row ->
                                    new CatalogModels.District(
                                            SqlValues.string(
                                                    row,
                                                    "distritoCodigo"
                                            ),
                                            SqlValues.string(
                                                    row,
                                                    "distritoNombre"
                                            )
                                    )
                            )
                            .toList()
            );
        } catch (PaExecutionException exception) {
            return geoError(
                    exception,
                    "La provincia seleccionada no está disponible."
            );
        }
    }

    @Override
    public PersistenceResult<List<CatalogModels.PopulationCenter>> populationCenters(
            ListPopulationCenters command
    ) {
        try {
            var resultSets = executor.executeJsonMultiResult(
                    populationCenters,
                    Map.of(
                            "distritoCodigo",
                            command.distritoCodigo()
                    )
            );

            return PersistenceResult.ok(
                    "Centros poblados consultados correctamente.",
                    resultSets.rows("items")
                            .stream()
                            .map(row ->
                                    new CatalogModels.PopulationCenter(
                                            SqlValues.longValue(
                                                    row,
                                                    "centroPobladoId"
                                            ),
                                            SqlValues.string(
                                                    row,
                                                    "codigoInei"
                                            ),
                                            SqlValues.string(
                                                    row,
                                                    "centroPobladoNombre"
                                            )
                                    )
                            )
                            .toList()
            );
        } catch (PaExecutionException exception) {
            return geoError(
                    exception,
                    "El distrito seleccionado no está disponible."
            );
        }
    }

    private CatalogModels.Item item(
            Map<String, Object> row
    ) {
        Long usage = SqlValues.longValue(
                row,
                "cantidadUso"
        );

        return new CatalogModels.Item(
                SqlValues.longValue(row, "id"),
                SqlValues.string(row, "codigo"),
                SqlValues.string(row, "nombre"),
                SqlValues.string(row, "descripcion"),
                SqlValues.bool(row, "estado"),
                usage == null ? 0L : usage,
                SqlValues.bool(row, "enUso")
        );
    }

    private static Map<String, Object> map(
            Object... values
    ) {
        Map<String, Object> result = new LinkedHashMap<>();

        for (int index = 0; index < values.length; index += 2) {
            Object value = values[index + 1];

            if (value != null) {
                result.put(
                        (String) values[index],
                        value
                );
            }
        }

        return result;
    }

    private static <T> PersistenceResult<T> geoError(
            PaExecutionException exception,
            String functionalMessage
    ) {
        Throwable current = exception;

        while (current != null) {
            if (current instanceof SQLException sqlException
                    && sqlException.getErrorCode() >= 50000
                    && sqlException.getErrorCode() < 51000) {
                return PersistenceResult.error(
                        functionalMessage
                );
            }

            current = current.getCause();
        }

        throw exception;
    }
}
