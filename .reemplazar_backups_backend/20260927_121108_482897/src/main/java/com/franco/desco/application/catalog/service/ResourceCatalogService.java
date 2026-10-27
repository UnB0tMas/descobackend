package com.franco.desco.application.catalog.service;

import com.franco.desco.application.catalog.CatalogCommands.CreateCatalog;
import com.franco.desco.application.catalog.CatalogCommands.DisableCatalog;
import com.franco.desco.application.catalog.CatalogCommands.ListCatalog;
import com.franco.desco.application.catalog.CatalogCommands.UpdateCatalog;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.catalog.CatalogModels;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

@Service
public class ResourceCatalogService {

    private static final Set<String> SUPPORTED = Set.of(
            "TIPO_VEHICULO",
            "UNIDAD_MEDIDA",
            "CATEGORIA_PRODUCTO",
            "MONEDA",
            "CARGO_EMPLEADO"
    );

    private final SimpleJdbcCall listCall;
    private final SimpleJdbcCall createCall;
    private final SimpleJdbcCall updateCall;
    private final SimpleJdbcCall disableCall;

    public ResourceCatalogService(DataSource dataSource) {
        this.listCall = base(
                dataSource,
                "PA_CatalogoRecurso_Sel_Listado",
                in("nUsuarioId", Types.BIGINT),
                in("cCatalogo", Types.VARCHAR),
                in("nPagina", Types.INTEGER),
                in("nTamano", Types.INTEGER)
        ).returningResultSet("items", this::mapItem);

        this.createCall = base(
                dataSource,
                "PA_CatalogoRecurso_Ins_Registro",
                in("nUsuarioId", Types.BIGINT),
                in("cCatalogo", Types.VARCHAR),
                in("cCodigo", Types.VARCHAR),
                in("cNombre", Types.NVARCHAR),
                in("cDescripcion", Types.NVARCHAR),
                new SqlOutParameter("nCatalogoId", Types.BIGINT)
        );

        this.updateCall = base(
                dataSource,
                "PA_CatalogoRecurso_Upd_Registro",
                in("nUsuarioId", Types.BIGINT),
                in("cCatalogo", Types.VARCHAR),
                in("nCatalogoId", Types.BIGINT),
                in("cNombre", Types.NVARCHAR),
                in("cDescripcion", Types.NVARCHAR)
        );

        this.disableCall = base(
                dataSource,
                "PA_CatalogoRecurso_Upd_Deshabilitar",
                in("nUsuarioId", Types.BIGINT),
                in("cCatalogo", Types.VARCHAR),
                in("nCatalogoId", Types.BIGINT),
                in("cMotivo", Types.NVARCHAR)
        );
    }

    public boolean supports(String catalog) {
        String normalized = normalizeCatalog(catalog);
        return normalized != null && SUPPORTED.contains(normalized);
    }

    public AppResult<PageResult<CatalogModels.Item>> list(
            ListCatalog command,
            SessionIdentity identity
    ) {
        if (command == null || command.page() == null || command.page().filtros() == null
                || identity == null || identity.usuarioId() == null) {
            return bad("CATALOGO_NO_LISTADO", "No se pudo consultar el catálogo.");
        }

        String catalog = normalizeCatalog(command.page().filtros().catalogo());
        if (!SUPPORTED.contains(catalog)) {
            return bad("CATALOGO_NO_LISTADO", "El catálogo seleccionado no está disponible.");
        }

        try {
            Map<String, Object> out = listCall.execute(
                    new MapSqlParameterSource()
                            .addValue("nUsuarioId", identity.usuarioId())
                            .addValue("cCatalogo", catalog)
                            .addValue("nPagina", command.page().pagina())
                            .addValue("nTamano", command.page().tamanio())
            );

            if (!ok(out)) {
                return error(out, "CATALOGO_NO_LISTADO", "No se pudo consultar el catálogo.");
            }

            List<CatalogRow> rows = list(out, "items");
            long total = rows.isEmpty() ? 0 : rows.getFirst().totalRecords();
            int page = command.page().pagina();
            int size = command.page().tamanio();
            int pages = total == 0 ? 0 : (int) Math.ceil((double) total / size);
            PageResult<CatalogModels.Item> result = new PageResult<>(
                    rows.stream().map(CatalogRow::item).toList(),
                    page,
                    size,
                    total,
                    pages
            );

            return AppResult.ok(
                    code(out, "CATALOGO_LISTADO"),
                    message(out, "Catálogo consultado."),
                    result
            );
        } catch (DataAccessException exception) {
            return unavailable("CATALOGO_NO_LISTADO", "No se pudo consultar el catálogo.");
        }
    }

    public AppResult<Long> create(CreateCatalog command, SessionIdentity identity) {
        if (command == null || identity == null || identity.usuarioId() == null) {
            return bad("CATALOGO_NO_CREADO", "No se pudo registrar el valor.");
        }
        String catalog = normalizeCatalog(command.catalogo());
        if (!SUPPORTED.contains(catalog)) {
            return bad("CATALOGO_NO_CREADO", "El catálogo seleccionado no está disponible.");
        }

        try {
            Map<String, Object> out = createCall.execute(
                    new MapSqlParameterSource()
                            .addValue("nUsuarioId", identity.usuarioId())
                            .addValue("cCatalogo", catalog)
                            .addValue("cCodigo", trim(command.codigo()))
                            .addValue("cNombre", trim(command.nombre()))
                            .addValue("cDescripcion", trim(command.descripcion()))
            );
            if (!ok(out)) return error(out, "CATALOGO_NO_CREADO", "No se pudo registrar el valor.");

            Long id = longValue(out.get("nCatalogoId"));
            if (id == null) return unavailable("CATALOGO_NO_CREADO", "No se pudo obtener el valor registrado.");
            return AppResult.created(code(out, "CATALOGO_CREADO"), message(out, "Valor registrado."), id);
        } catch (DataAccessException exception) {
            return unavailable("CATALOGO_NO_CREADO", "No se pudo registrar el valor.");
        }
    }

    public AppResult<Void> update(UpdateCatalog command, SessionIdentity identity) {
        if (command == null || identity == null || identity.usuarioId() == null) {
            return bad("CATALOGO_NO_ACTUALIZADO", "No se pudo actualizar el valor.");
        }
        String catalog = normalizeCatalog(command.catalogo());
        if (!SUPPORTED.contains(catalog)) {
            return bad("CATALOGO_NO_ACTUALIZADO", "El catálogo seleccionado no está disponible.");
        }

        try {
            Map<String, Object> out = updateCall.execute(
                    new MapSqlParameterSource()
                            .addValue("nUsuarioId", identity.usuarioId())
                            .addValue("cCatalogo", catalog)
                            .addValue("nCatalogoId", command.id())
                            .addValue("cNombre", trim(command.nombre()))
                            .addValue("cDescripcion", trim(command.descripcion()))
            );
            if (!ok(out)) return error(out, "CATALOGO_NO_ACTUALIZADO", "No se pudo actualizar el valor.");
            return AppResult.ok(code(out, "CATALOGO_ACTUALIZADO"), message(out, "Valor actualizado."), null);
        } catch (DataAccessException exception) {
            return unavailable("CATALOGO_NO_ACTUALIZADO", "No se pudo actualizar el valor.");
        }
    }

    public AppResult<Void> disable(DisableCatalog command, SessionIdentity identity) {
        if (command == null || identity == null || identity.usuarioId() == null) {
            return bad("CATALOGO_NO_DESHABILITADO", "No se pudo deshabilitar el valor.");
        }
        String catalog = normalizeCatalog(command.catalogo());
        if (!SUPPORTED.contains(catalog)) {
            return bad("CATALOGO_NO_DESHABILITADO", "El catálogo seleccionado no está disponible.");
        }

        try {
            Map<String, Object> out = disableCall.execute(
                    new MapSqlParameterSource()
                            .addValue("nUsuarioId", identity.usuarioId())
                            .addValue("cCatalogo", catalog)
                            .addValue("nCatalogoId", command.id())
                            .addValue("cMotivo", trim(command.motivo()))
            );
            if (!ok(out)) return error(out, "CATALOGO_NO_DESHABILITADO", "No se pudo deshabilitar el valor.");
            return AppResult.ok(code(out, "CATALOGO_DESHABILITADO"), message(out, "Valor deshabilitado."), null);
        } catch (DataAccessException exception) {
            return unavailable("CATALOGO_NO_DESHABILITADO", "No se pudo deshabilitar el valor.");
        }
    }

    private CatalogRow mapItem(ResultSet rs, int rowNumber) throws SQLException {
        CatalogModels.Item item = new CatalogModels.Item(
                nullableLong(rs, "id"),
                rs.getString("codigo"),
                rs.getString("nombre"),
                rs.getString("descripcion"),
                rs.getBoolean("estado"),
                rs.getLong("cantidadUso"),
                rs.getBoolean("enUso")
        );
        return new CatalogRow(item, rs.getLong("totalRegistros"));
    }

    private static SimpleJdbcCall base(DataSource dataSource, String procedure, SqlParameter... parameters) {
        SqlParameter[] all = new SqlParameter[parameters.length + 4];
        System.arraycopy(parameters, 0, all, 0, parameters.length);
        all[parameters.length] = new SqlOutParameter("bResultado", Types.BIT);
        all[parameters.length + 1] = new SqlOutParameter("cMensaje", Types.NVARCHAR);
        all[parameters.length + 2] = new SqlOutParameter("cCodigoRespuesta", Types.VARCHAR);
        all[parameters.length + 3] = new SqlOutParameter("nHttpRespuesta", Types.SMALLINT);
        return new SimpleJdbcCall(dataSource)
                .withSchemaName("config")
                .withProcedureName(procedure)
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(all);
    }

    private static SqlParameter in(String name, int type) {
        return new SqlParameter(name, type);
    }

    @SuppressWarnings("unchecked")
    private static <T> List<T> list(Map<String, Object> out, String key) {
        Object value = out.get(key);
        return value instanceof List<?> values ? (List<T>) values : List.of();
    }

    private static boolean ok(Map<String, Object> out) {
        Object value = out.get("bResultado");
        return value instanceof Boolean bool
                ? bool
                : value instanceof Number number && number.intValue() != 0;
    }

    private static Integer http(Map<String, Object> out) {
        Object value = out.get("nHttpRespuesta");
        return value instanceof Number number ? number.intValue() : null;
    }

    private static String code(Map<String, Object> out, String fallback) {
        Object value = out.get("cCodigoRespuesta");
        return value == null || value.toString().isBlank() ? fallback : value.toString().trim();
    }

    private static String message(Map<String, Object> out, String fallback) {
        Object value = out.get("cMensaje");
        return value == null || value.toString().isBlank() ? fallback : value.toString().trim();
    }

    private static String normalizeCatalog(String value) {
        String normalized = trim(value);
        return normalized == null ? null : normalized.toUpperCase(Locale.ROOT);
    }

    private static String trim(String value) {
        if (value == null) return null;
        String normalized = value.trim();
        return normalized.isEmpty() ? null : normalized;
    }

    private static Long nullableLong(ResultSet rs, String column) throws SQLException {
        long value = rs.getLong(column);
        return rs.wasNull() ? null : value;
    }

    private static Long longValue(Object value) {
        return value instanceof Number number ? number.longValue() : null;
    }

    private static <T> AppResult<T> bad(String code, String message) {
        return AppResult.error(AppStatus.BAD_REQUEST, code, message);
    }

    private static <T> AppResult<T> unavailable(String code, String message) {
        return AppResult.error(AppStatus.SERVICE_UNAVAILABLE, code, message);
    }

    private static <T> AppResult<T> error(Map<String, Object> out, String fallbackCode, String fallbackMessage) {
        return AppResult.error(
                AppStatus.fromHttp(http(out), AppStatus.BAD_REQUEST),
                code(out, fallbackCode),
                message(out, fallbackMessage)
        );
    }

    private record CatalogRow(CatalogModels.Item item, long totalRecords) {
    }
}
