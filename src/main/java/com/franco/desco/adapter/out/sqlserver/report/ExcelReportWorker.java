package com.franco.desco.adapter.out.sqlserver.report;

import com.franco.desco.adapter.out.sqlserver.shared.PaTrace;
import com.franco.desco.application.report.service.ReportJobEventService;
import com.franco.desco.application.report.service.TemporaryReportService;
import com.franco.desco.infrastructure.storage.LocalStorageProperties;
import org.apache.poi.xssf.streaming.SXSSFWorkbook;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.nio.file.*;
import java.sql.*;
import java.time.LocalDate;
import java.util.concurrent.atomic.AtomicInteger;

/** Cola persistente: el navegador no participa en la generación. */
@Component
public class ExcelReportWorker {
    private static final Logger LOG = LoggerFactory.getLogger(ExcelReportWorker.class);
    private final TemporaryReportService temporaryReports;
    private final JdbcTemplate jdbc;
    private final ReportJobEventService events;
    private final Path root;
    private static final int MAX_ROWS=100000;
    public ExcelReportWorker(JdbcTemplate jdbc,LocalStorageProperties storage, ReportJobEventService events,
                             TemporaryReportService temporaryReports) {
        this.jdbc=jdbc;this.events=events;this.temporaryReports=temporaryReports;
        this.root=Path.of(storage.root()).toAbsolutePath().normalize();
    }
    private record Job(long id,long usuarioId,long uotId,String code,LocalDate from,LocalDate to) {}

    @Scheduled(fixedDelayString="${app.reports.excel-poll-ms:6000}",initialDelayString="${app.reports.excel-initial-ms:7000}")
    public void process() {
        Job job;
        try {
            job=PaTrace.call("reporte.PA_Excel_Trabajo_Reservar", () -> jdbc.query("EXEC reporte.PA_Excel_Trabajo_Reservar",rs ->
                rs.next()?new Job(rs.getLong("id"),rs.getLong("usuarioId"),rs.getLong("uotId"),rs.getString("codigo"),
                    rs.getDate("desde").toLocalDate(),rs.getDate("hasta").toLocalDate()):null),
                result -> true, result -> "Sin trabajos pendientes");
        } catch(Exception ignored){return;}
        if(job==null)return;
        Path temp=null;
        try {
            Path directory=root.resolve("exports").normalize();
            Files.createDirectories(directory);
            temp=Files.createTempFile(directory,"report-", ".tmp");
            int rows=generate(job,temp);
            Path target=directory.resolve(job.id()+".xlsx");
            try{Files.move(temp,target,StandardCopyOption.REPLACE_EXISTING,StandardCopyOption.ATOMIC_MOVE);}
            catch(AtomicMoveNotSupportedException e){Files.move(temp,target,StandardCopyOption.REPLACE_EXISTING);}
            PaTrace.call("reporte.PA_Excel_Trabajo_Finalizar", () -> jdbc.update("{call reporte.PA_Excel_Trabajo_Finalizar(?,?,?,?,?)}",job.id(),true,
                    "exports/"+job.id()+".xlsx",rows,null));
            events.completed(job.usuarioId(), job.uotId(), job.id(), "EXCEL", "LISTO");
        } catch(Exception ex) {
            try{PaTrace.call("reporte.PA_Excel_Trabajo_Finalizar", () -> jdbc.update("{call reporte.PA_Excel_Trabajo_Finalizar(?,?,?,?,?)}",job.id(),false,
                null,null,ex instanceof RowLimitException?"El rango contiene demasiados registros. Reduzca las fechas.":
                "No se pudo preparar el archivo."));
                events.completed(job.usuarioId(), job.uotId(), job.id(), "EXCEL", "ERROR");
            }catch(Exception ignored){}
        } finally {
            if(temp!=null)try{Files.deleteIfExists(temp);}catch(Exception ignored){}
        }
    }

    @Scheduled(fixedDelayString="${app.reports.excel-cleanup-ms:43200000}",initialDelayString="${app.reports.excel-cleanup-initial-ms:120000}")
    public void cleanup() {
        try {
            temporaryReports.purgeExpired();
        } catch (RuntimeException exception) {
            LOG.error("No se pudo completar la limpieza de reportes temporales.", exception);
        }
    }

    private int generate(Job job, Path target) throws Exception {
        SXSSFWorkbook book = new SXSSFWorkbook(200);
        book.setCompressTempFiles(true);
        try {
            EnterpriseExcelLayout layout = new EnterpriseExcelLayout(book, job.code(), job.from(), job.to());
            AtomicInteger count = new AtomicInteger();
            PaTrace.run("reporte.PA_Excel_Sel_Filas", () -> jdbc.query(con -> {
                CallableStatement st = con.prepareCall("{call reporte.PA_Excel_Sel_Filas(?)}");
                st.setLong(1, job.id());
                st.setFetchSize(200);
                return st;
            }, rs -> {
                layout.columns(rs.getMetaData());
                while (rs.next()) {
                    int index = count.incrementAndGet();
                    if (index > MAX_ROWS) throw new RowLimitException();
                    layout.row(rs, index);
                }
                return null;
            }));
            layout.finish();
            try (var out = Files.newOutputStream(target, StandardOpenOption.TRUNCATE_EXISTING)) {
                book.write(out);
            }
            return count.get();
        } finally {
            book.close();
        }
    }

    private static class RowLimitException extends RuntimeException {}
}
