package com.franco.desco.infrastructure.persistence.campaign;

import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.json.JsonMapper;

import java.sql.CallableStatement;
import java.sql.Types;
import java.util.LinkedHashMap;
import java.util.Map;

/** El adaptador solo serializa contexto y ejecuta el PA. Todas las reglas viven en SQL Server. */
@Repository
public class CampaignPlanningSqlAdapter {
    private final JdbcTemplate jdbc;
    private final JsonMapper json;

    public CampaignPlanningSqlAdapter(JdbcTemplate jdbc, JsonMapper json) {
        this.jdbc = jdbc;
        this.json = json;
    }

    public PersistenceResult<Map<String, Object>> execute(String procedure,
            Map<String, ?> filters, Object data, SessionIdentity identity, RequestMetadata metadata) {
        if (identity == null || identity.sesionPublicaId() == null || metadata == null) {
            return PersistenceResult.error("CAMPANIA_SESION_INVALIDA", "La sesión no está disponible.", 401);
        }
        // Las opciones son constantes controladas por el servidor, nunca nombres suministrados por el cliente.
        if (!procedure.equals("PA_SancionCatalogo_Sel_Listado")
                && !procedure.equals("PA_SancionCatalogo_Ins_Registro")
                && !procedure.equals("PA_SancionCatalogo_Upd_Registro")
                && !procedure.equals("PA_SancionCatalogo_Upd_Deshabilitar")
                && !procedure.equals("PA_CampaniaSancion_Sel_Listado")
                && !procedure.equals("PA_CampaniaSancion_Upd_Configurar")
                && !procedure.equals("PA_CampaniaSancion_Upd_Lote")
                && !procedure.equals("PA_CampaniaSancion_Upd_Deshabilitar")
                && !procedure.equals("PA_CampaniaSocioSancion_Sel_Detalle")
                && !procedure.equals("PA_CampaniaSocioSancion_Upd_Asignar")
                && !procedure.equals("PA_CampaniaSocioSancion_Upd_Retirar")
                && !procedure.equals("PA_CampaniaVentaProceso_Sel_Indicadores")
                && !procedure.equals("PA_CampaniaVentaProceso_Sel_Detalle")
                && !procedure.equals("PA_CampaniaJabaRecepcion_Sel_Pagina")
                && !procedure.equals("PA_CampaniaJabaRecepcion_Upd_Registro")
                && !procedure.equals("PA_CampaniaJabaRecepcion_Upd_Corregir")
                && !procedure.equals("PA_CampaniaJabaRecepcion_Upd_Confirmar")
                && !procedure.equals("PA_CampaniaCalibre_Upd_Lista")
                && !procedure.equals("PA_CampaniaCalibre_Ins_Registro")
                && !procedure.equals("PA_CampaniaCalibre_Upd_Precio")
                && !procedure.equals("PA_CampaniaDescuentoJaba_Upd_Configurar")
                && !procedure.equals("PA_CampaniaPlan_Upd_Datos")
                && !procedure.equals("PA_CampaniaPlan_Ins_Crear")
                && !procedure.equals("PA_CampaniaJabaPlan_Sel_Detalle")
                && !procedure.equals("PA_CampaniaJabaPlan_Upd_Cantidad")
                && !procedure.equals("PA_CampaniaJabaPlan_Upd_Entregar")
                && !procedure.equals("PA_CampaniaJabaPlan_Upd_Devolver")
                && !procedure.equals("PA_CampaniaPlan_Sel_SociosElegibles")
                && !procedure.equals("PA_CampaniaPlan_Ins_SociosLote")
                && !procedure.equals("PA_CampaniaPlan_Upd_RetirarSocio")
                && !procedure.equals("PA_APAPPSS_Contexto_Sel")
                && !procedure.equals("PA_APAPPSS_Comprador_Sel_Listado")
                && !procedure.equals("PA_APAPPSS_Comprador_Ins_Registro")
                && !procedure.equals("PA_APAPPSS_TipoDocumento_Sel_Listado")
                && !procedure.equals("PA_APAPPSS_Comprador_Sel_IdentidadLocal")
                && !procedure.equals("PA_APAPPSS_Comprador_Sel_Detalle")
                && !procedure.equals("PA_APAPPSS_Comprador_Upd_Datos")) {
            return PersistenceResult.error("CAMPANIA_ACCION_INVALIDA", "Operación no disponible.", 400);
        }
        Map<String, Object> context = new LinkedHashMap<>();
        context.put("sesionPublicaId", identity.sesionPublicaId());
        context.put("correlacionId", metadata.correlacionId());
        context.put("solicitudId", metadata.solicitudId());
        context.put("claveIdempotencia", metadata.claveIdempotencia());
        context.put("ip", metadata.ip());
        context.put("endpoint", metadata.endpoint());
        context.put("userAgent", metadata.userAgent());
        context.put("deviceId", metadata.deviceId());
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("contexto", context);
        payload.put("filtros", filters == null ? Map.of() : filters);
        payload.put("datos", data == null ? Map.of() : data);
        String serialized = json.writeValueAsString(payload);
        try {
            return jdbc.execute(connection -> {
                CallableStatement stmt = connection.prepareCall("{call comercial." + procedure + "(?,?,?,?,?,?)}");
                stmt.setNString(1, serialized);
                stmt.registerOutParameter(2, Types.LONGNVARCHAR);
                stmt.registerOutParameter(3, Types.BIT);
                stmt.registerOutParameter(4, Types.NVARCHAR);
                stmt.registerOutParameter(5, Types.VARCHAR);
                stmt.registerOutParameter(6, Types.SMALLINT);
                return stmt;
            }, (CallableStatement stmt) -> {
                stmt.execute();
                boolean ok = stmt.getBoolean(3);
                String message = stmt.getNString(4);
                String code = stmt.getString(5);
                int http = stmt.getInt(6);
                if (!ok) return PersistenceResult.error(code, message, http == 0 ? 400 : http);
                String raw = stmt.getNString(2);
                Map<String, Object> result = raw == null || raw.isBlank()
                        ? Map.of() : json.readValue(raw, new TypeReference<Map<String, Object>>() {});
                return PersistenceResult.ok(code, message, http == 0 ? 200 : http, result);
            });
        } catch (DataAccessException ex) {
            return PersistenceResult.error("CAMPANIA_BD_NO_DISPONIBLE",
                    "No se pudo completar la operación comercial en este momento.", 503);
        }
    }
}
