package com.franco.desco.adapter.out.sqlserver.expediente;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.franco.desco.application.expediente.E1Commands.Ejecutar;
import com.franco.desco.application.expediente.port.out.E1PersistencePort;
import com.franco.desco.application.shared.*;
import org.springframework.jdbc.core.CallableStatementCallback;
import org.springframework.jdbc.core.CallableStatementCreator;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.CallableStatement;
import java.sql.Types;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.Map;

@Repository
public final class E1SqlServerAdapter implements E1PersistencePort {
    private final JdbcTemplate jdbc;
    private final ObjectMapper json;

    public E1SqlServerAdapter(JdbcTemplate jdbc, ObjectMapper json) {
        this.jdbc = jdbc;
        this.json = json;
    }

    @Override
    public <T> PersistenceResult<T> ejecutar(Ejecutar command, SessionIdentity identity,
                                             RequestMetadata meta, Class<T> tipo) {
        try {
            Map<String, Object> filtros = new LinkedHashMap<>();
            filtros.put("uotId", command.uotId());
            filtros.put("convenioId", command.convenioId());
            filtros.put("predioId", command.predioId());
            filtros.put("buscar", command.buscar());
            Map<String, Object> base = new LinkedHashMap<>();
            base.put("filtros", filtros);
            base.put("datos", command.datos());
            String contenido = json.writeValueAsString(base);
            String huella = sha256(command.accion() + ":" + contenido);
            Map<String, Object> contexto = new LinkedHashMap<>();
            contexto.put("sesionPublicaId", identity.sesionPublicaId());
            contexto.put("correlacionId", meta.correlacionId());
            contexto.put("solicitudId", meta.solicitudId());
            contexto.put("claveIdempotencia", meta.claveIdempotencia());
            contexto.put("requestHashHex", huella);
            contexto.put("ip", meta.ip());
            contexto.put("endpoint", meta.endpoint());
            base.put("contexto", contexto);
            String entrada = json.writeValueAsString(base);
            return jdbc.execute((CallableStatementCreator) connection -> {
                CallableStatement statement = connection.prepareCall("{call prod.PA_ExpedienteProductivo_Ejecutar(?,?,?,?,?,?,?)}");
                statement.setString(1, command.accion());
                statement.setNString(2, entrada);
                statement.registerOutParameter(3, Types.NVARCHAR);
                statement.registerOutParameter(4, Types.BIT);
                statement.registerOutParameter(5, Types.NVARCHAR);
                statement.registerOutParameter(6, Types.VARCHAR);
                statement.registerOutParameter(7, Types.SMALLINT);
                return statement;
            }, (CallableStatementCallback<PersistenceResult<T>>) statement -> {
                statement.execute();
                boolean ok = statement.getBoolean(4);
                String raw = statement.getNString(3);
                T value = null;
                if (ok && raw != null) {
                    try { value = json.readValue(raw, tipo); }
                    catch (JsonProcessingException parseError) { throw new java.sql.SQLException("Respuesta inválida del procedimiento", parseError); }
                }
                return new PersistenceResult<>(ok, statement.getString(6), statement.getNString(5),
                        (int) statement.getShort(7), value);
            });
        } catch (Exception error) {
            return PersistenceResult.error("EXPEDIENTE_SQL_ERROR",
                    "No se pudo completar la operación; revise el contexto y vuelva a intentar.", 503);
        }
    }

    private static String sha256(String text) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(text.getBytes(StandardCharsets.UTF_8)));
        } catch (java.security.NoSuchAlgorithmException error) {
            throw new IllegalStateException("SHA-256 no disponible", error);
        }
    }
}
