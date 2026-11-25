package com.franco.desco.adapter.out.sqlserver.sanitation;

import com.franco.desco.adapter.out.sqlserver.shared.PaExecution;
import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaExecutor;
import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Un solo PA para consumos programados históricos o recursos entregados en E2. */
@Repository
public class SanitationStockRepository {
    private final SqlServerPaExecutor executor;

    public SanitationStockRepository(SqlServerPaExecutor executor) {
        this.executor = executor;
    }

    public record RecursoEntregado(Long programacionProductoId, Long solicitudRecursoId,
            Long salidaCampoId, String producto, String unidadMedida, String almacen,
            BigDecimal cantidadEntregada, BigDecimal cantidadUtilizada, BigDecimal cantidadPendiente,
            String lote, LocalDate fechaVencimiento, String fuente) {}

    public List<RecursoEntregado> listar(SessionIdentity sesion, Long responsable,
            Long salida, Long visita, Long predio) {
        Map<String,Object> parametros = new LinkedHashMap<>();
        parametros.put("gSesionPublica", sesion.sesionPublicaId());
        parametros.put("nUsuario", sesion.usuarioId());
        parametros.put("nResponsable", responsable);
        parametros.put("nSalida", salida);
        parametros.put("nVisita", visita);
        parametros.put("nPredio", predio);
        PaExecution resultado = executor.execute("logistica.PA_SalidaConsumoE2_Sel_Disponibles", parametros);
        if (!resultado.exitoso()) throw new IllegalStateException("No se pudieron consultar los productos entregados.");
        return resultado.resultSets().isEmpty() ? List.of() : resultado.resultSets().getFirst().stream()
                .map(r -> new RecursoEntregado(l(r,"programacionProductoId"),
                        l(r,"solicitudRecursoId"),l(r,"salidaCampoId"),
                        t(r,"producto"),t(r,"unidadMedida"),t(r,"almacen"),
                        d(r,"cantidadEntregada"),d(r,"cantidadUtilizada"),d(r,"cantidadPendiente"),
                        t(r,"lote"),fecha(r,"fechaVencimiento"),t(r,"fuente"))).toList();
    }
    private Long l(Map<String,Object> row,String key){Object v=row.get(key);return v instanceof Number n?n.longValue():null;}
    private String t(Map<String,Object> row,String key){Object v=row.get(key);return v==null?null:v.toString();}
    private BigDecimal d(Map<String,Object> row,String key){Object v=row.get(key);return v instanceof BigDecimal b?b:v instanceof Number n?BigDecimal.valueOf(n.doubleValue()):null;}
    private LocalDate fecha(Map<String,Object> row,String key){Object v=row.get(key);return v instanceof LocalDate f?f:v==null?null:LocalDate.parse(v.toString().substring(0,10));}
}
