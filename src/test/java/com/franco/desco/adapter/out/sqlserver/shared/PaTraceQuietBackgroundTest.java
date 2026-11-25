package com.franco.desco.adapter.out.sqlserver.shared;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;

import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class PaTraceQuietBackgroundTest {
    private final Logger logger = (Logger) LoggerFactory.getLogger(PaTrace.class);
    private ListAppender<ILoggingEvent> logs;
    private Map<String, String> previousMdc;

    @BeforeEach
    void setup() {
        previousMdc = MDC.getCopyOfContextMap();
        MDC.clear();
        logs = new ListAppender<>();
        logs.start();
        logger.addAppender(logs);
    }

    @AfterEach
    void cleanup() {
        logger.detachAppender(logs);
        logs.stop();
        MDC.clear();
        if (previousMdc != null) {
            MDC.setContextMap(previousMdc);
        }
    }

    @Test
    void consultasPeriodicasSinErrorNoGeneranLogsPeroSiSeEjecutan() {
        List<String> procedures = List.of(
                "seg.PA_Seguridad_Sel_NotificacionesPendientes",
                "comercial.PA_Venta_Upd_VencerReservas",
                "comercial.PA_CampaniaVenta_Upd_Vencer",
                "reporte.PA_Excel_Trabajo_Reservar"
        );
        AtomicInteger executions = new AtomicInteger();
        for (String procedure : procedures) {
            assertThat(PaTrace.call(procedure, () -> {
                executions.incrementAndGet();
                return Boolean.TRUE;
            })).isTrue();
        }
        assertThat(executions).hasValue(procedures.size());
        assertThat(logs.list).isEmpty();
    }

    @Test
    void conservaErroresFuncionalesYExcepcionesDePAPeriodicos() {
        String procedure = "seg.PA_Seguridad_Sel_NotificacionesPendientes";
        PaTrace.call(procedure, () -> Map.of("bResultado", false,
                "cMensaje", "Fallo de consulta"));
        assertThat(logs.list).anySatisfy(event ->
                assertThat(event.getFormattedMessage()).contains("PA ERROR FUNCIONAL"));
        logs.list.clear();

        IllegalStateException failure = new IllegalStateException("Fallo JDBC");
        assertThatThrownBy(() -> PaTrace.call(procedure, () -> { throw failure; }))
                .isSameAs(failure);
        assertThat(logs.list).anySatisfy(event ->
                assertThat(event.getFormattedMessage()).contains("PA ERROR SQL/TECNICO"));
    }

    @Test
    void solicitudHttpConElMismoPASeRegistraNormalmente() {
        try (MDC.MDCCloseable ignored = MDC.putCloseable("correlationId", "peticion-123")) {
            PaTrace.call("seg.PA_Seguridad_Sel_NotificacionesPendientes", () -> Boolean.TRUE);
        }
        assertThat(logs.list).anySatisfy(event ->
                assertThat(event.getFormattedMessage()).contains("PA INICIADO"));
        assertThat(logs.list).anySatisfy(event ->
                assertThat(event.getFormattedMessage()).contains("PA EXITOSO"));
    }

    @Test
    void otrosProcedimientosSiguenConTrazabilidadCompleta() {
        PaTrace.call("org.PA_Socio_Sel_Listado", () -> List.of());
        assertThat(logs.list).hasSize(2);
    }
}
