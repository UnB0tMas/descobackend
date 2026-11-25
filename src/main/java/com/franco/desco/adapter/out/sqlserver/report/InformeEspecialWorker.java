package com.franco.desco.adapter.out.sqlserver.report;

import com.franco.desco.adapter.out.sqlserver.shared.PaTrace;
import com.franco.desco.application.report.service.ReportJobEventService;
import com.franco.desco.infrastructure.storage.LocalBinaryStorage;
import com.franco.desco.infrastructure.storage.LocalStorageProperties;
import org.springframework.core.io.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.poi.xssf.streaming.SXSSFWorkbook;
import org.apache.poi.xwpf.usermodel.*;
import org.apache.poi.util.Units;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import tools.jackson.databind.json.JsonMapper;

import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.*;
import java.sql.CallableStatement;
import java.sql.Types;
import java.time.LocalDate;
import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;

/** Trabajos independientes; los permisos se validan al solicitar y al descargar. */
@Component
public class InformeEspecialWorker {
    private static final Logger LOG = LoggerFactory.getLogger(InformeEspecialWorker.class);
    private final JdbcTemplate jdbc;
    private final ReportJobEventService events;
    private final JsonMapper mapper;
    private final LocalBinaryStorage storage;
    private final Path root;
    private static final int MAX_ROWS=50_000;
    private record Job(long id,long usuarioId,long uotId,String tipo,String formato,LocalDate desde,LocalDate hasta) {}

    public InformeEspecialWorker(JdbcTemplate jdbc,JsonMapper mapper,LocalBinaryStorage storage,
                                 LocalStorageProperties properties, ReportJobEventService events) {
        this.jdbc=jdbc;this.mapper=mapper;this.storage=storage;this.events=events;
        this.root=Path.of(properties.root()).toAbsolutePath().normalize();
    }

    @Scheduled(fixedDelayString="${app.reports.special-poll-ms:8000}", initialDelayString="${app.reports.special-initial-ms:12000}")
    public void process() {
        Job job;
        try {
            job=jdbc.query("""
                UPDATE TOP(1) reporte.TrabajoEspecial WITH (READPAST, UPDLOCK, ROWLOCK)
                SET estado='PROCESANDO',actualizado_utc=SYSUTCDATETIME()
                OUTPUT inserted.trabajo_id,inserted.usuario_id,inserted.uot_id,inserted.tipo,inserted.formato,inserted.fecha_desde,inserted.fecha_hasta
                WHERE estado='PENDIENTE'
                """,rs -> rs.next()?new Job(rs.getLong(1),rs.getLong(2),rs.getLong(3),rs.getString(4),rs.getString(5),
                    rs.getDate(6).toLocalDate(),rs.getDate(7).toLocalDate()):null);
        } catch(Exception e) {
            LOG.error("No se pudo reservar el trabajo de informe especial.", e);
            return;
        }
        if(job==null)return;
        Path temp=null;
        try {
            Path directory=root.resolve("reports-special").normalize();
            Files.createDirectories(directory);
            temp=Files.createTempFile(directory,"report-", ".tmp");
            if("XLSX".equals(job.formato())) writeExcel(job,temp);
            else {
                Map<String,Object> data=sanidadData(job.id());
                if("DOCX".equals(job.formato())) writeDocx(data,job,temp);
                else writePdf(data,job,temp);
            }
            String ext=job.formato().toLowerCase(Locale.ROOT);
            Path destination=directory.resolve(job.id()+"."+ext);
            try{Files.move(temp,destination,StandardCopyOption.ATOMIC_MOVE,StandardCopyOption.REPLACE_EXISTING);}
            catch(AtomicMoveNotSupportedException e){Files.move(temp,destination,StandardCopyOption.REPLACE_EXISTING);}
            int updated = jdbc.update("UPDATE reporte.TrabajoEspecial SET estado='LISTO',archivo_clave=?,actualizado_utc=SYSUTCDATETIME(),mensaje=NULL WHERE trabajo_id=? AND estado='PROCESANDO'",
                "reports-special/"+job.id()+"."+ext,job.id());
            if (updated > 0) events.completed(job.usuarioId(), job.uotId(), job.id(), "ESPECIAL", "LISTO");
        } catch(Exception e) {
            LOG.error("Error al generar el informe especial. trabajoId={} tipo={} formato={}",
                    job.id(), job.tipo(), job.formato(), e);
            try {
                int updated = jdbc.update("UPDATE reporte.TrabajoEspecial SET estado='ERROR',actualizado_utc=SYSUTCDATETIME(),mensaje=? WHERE trabajo_id=? AND estado='PROCESANDO'",
                        "No se pudo preparar el informe.", job.id());
                if (updated > 0) events.completed(job.usuarioId(), job.uotId(), job.id(), "ESPECIAL", "ERROR");
            } catch (Exception updateError) {
                LOG.error("No se pudo registrar el fallo del informe especial. trabajoId={}", job.id(), updateError);
            }
        } finally {if(temp!=null)try{Files.deleteIfExists(temp);}catch(Exception ignored){}}
    }

    private void writeExcel(Job job, Path target) throws Exception {
        SXSSFWorkbook book = new SXSSFWorkbook(150);
        book.setCompressTempFiles(true);
        try {
            EnterpriseExcelLayout layout = new EnterpriseExcelLayout(book, job.tipo(), job.desde(), job.hasta());
            AtomicInteger count = new AtomicInteger();
            PaTrace.run("reporte.PA_InformeEspecial_Filas", () -> jdbc.query(con -> {
                CallableStatement st = con.prepareCall("{call reporte.PA_InformeEspecial_Filas(?)}");
                st.setLong(1, job.id());
                st.setFetchSize(200);
                return st;
            }, rs -> {
                layout.columns(rs.getMetaData());
                while (rs.next()) {
                    int index = count.incrementAndGet();
                    if (index > MAX_ROWS) throw new IllegalStateException("Row limit");
                    layout.row(rs, index);
                }
                return null;
            }));
            layout.finish();
            try (OutputStream stream = Files.newOutputStream(target)) { book.write(stream); }
        } finally {
            book.close();
        }
    }

    @SuppressWarnings("unchecked")
    private Map<String,Object> sanidadData(long id) {
        String content=PaTrace.call("reporte.PA_InformeSanitario_Contenido", () -> jdbc.execute(connection -> {
            CallableStatement st=connection.prepareCall("{call reporte.PA_InformeSanitario_Contenido(?,?)}");
            st.setLong(1,id);st.registerOutParameter(2,Types.LONGNVARCHAR);return st;
        },(CallableStatement st)->{st.execute();return st.getNString(2);}));
        if(content==null||content.isBlank())throw new IllegalArgumentException("No data");
        return mapper.readValue(content,Map.class);
    }

    @SuppressWarnings("unchecked")
    private List<Map<String,Object>> list(Map<String,Object> data,String key){
        Object values=data.get(key);
        return values instanceof List<?> arr?(List<Map<String,Object>>) (List<?>)arr:List.of();
    }
    @SuppressWarnings("unchecked")
    private Map<String,Object> obj(Map<String,Object> data,String key){
        Object value=data.get(key);return value instanceof Map<?,?>m?(Map<String,Object>)m:Map.of();
    }
    private String value(Object o){return o==null||o.toString().isBlank()?"No registrado":o.toString();}
    private String info(Map<String,Object> row,String field){return value(row.get(field));}
    private String when(Map<String,Object> row){String date=info(row,"fecha");return date.length()>=10?date.substring(0,10):date;}
    private record Entry(String fecha,String titulo,String detalle) {}
    private List<Entry> events(Map<String,Object> data) {
        List<Entry> records=new ArrayList<>();
        for(Map<String,Object> e:list(data,"visitas"))records.add(new Entry(when(e),"Visita técnica",
                "Objetivo: "+info(e,"objetivo")+". Resumen: "+info(e,"resumen")+". Recomendaciones: "+info(e,"recomendaciones")));
        for(Map<String,Object> e:list(data,"casos"))records.add(new Entry(when(e),"Caso: "+info(e,"problema"),
                "Severidad: "+info(e,"severidad")+". Plantas registradas: "+info(e,"cantidad")+
                (Boolean.TRUE.equals(e.get("estimada"))?" (cantidad estimada). ":". ")+"Observación: "+info(e,"observacion")));
        for(Map<String,Object> e:list(data,"seguimientos"))records.add(new Entry(when(e),"Seguimiento: "+info(e,"problema"),
                "Resultado: "+info(e,"resultado")+". Observación: "+info(e,"observacion")));
        for(Map<String,Object> e:list(data,"tratamientos"))records.add(new Entry(when(e),"Tratamiento",
                info(e,"tratamiento")+". Producto: "+info(e,"producto")+". Dosis: "+info(e,"dosis")+" "+info(e,"unidad_dosis")+
                ". Observación: "+info(e,"observacion")));
        for(Map<String,Object> e:list(data,"episodios"))records.add(new Entry(when(e),"Planta "+info(e,"planta")+": "+info(e,"problema"),
                "Observación: "+info(e,"observacion")+". Cierre: "+info(e,"cierre")));
        for(Map<String,Object> e:list(data,"aplicaciones"))records.add(new Entry(when(e),"Aplicación en "+info(e,"planta"),
                "Comentario: "+info(e,"comentario")+". Resultado: "+info(e,"resultado")));
        for(Map<String,Object> e:list(data,"eventosPlanta"))records.add(new Entry(when(e),"Cambio de estado: planta "+info(e,"planta"),
                info(e,"anterior")+" → "+info(e,"nuevo")+". "+info(e,"observacion")));
        for(Map<String,Object> e:list(data,"seguimientosPlanta"))records.add(new Entry(when(e),"Seguimiento de planta "+info(e,"planta"),
                "Observación: "+info(e,"observacion")+". Resultado: "+info(e,"resultado")));
        for(Map<String,Object> e:list(data,"tratamientosPlanta"))records.add(new Entry(when(e),"Tratamiento de planta "+info(e,"planta"),
                info(e,"descripcion")+". Comentario: "+info(e,"comentario")+". Resultado: "+info(e,"resultado")));
        records.sort(Comparator.comparing(Entry::fecha).thenComparing(Entry::titulo));
        return records;
    }

    private void writeDocx(Map<String,Object> data,Job job,Path target)throws Exception {
        try(XWPFDocument document=new XWPFDocument()) {
            Map<String,Object> head=obj(data,"cabecera");
            addWord(document,"INFORME DE SANIDAD",true,18);
            addWord(document,"DESCO  |  "+info(head,"unidad"),false,10);
            addWord(document,"Período: "+job.desde()+" al "+job.hasta(),false,10);
            addWord(document,"Predio: "+info(head,"predio")+" ("+info(head,"codigo")+")",false,11);
            if("AP_SANIDAD".equals(job.tipo()))addWord(document,"Socio: "+info(head,"socio"),false,10);
            addWord(document,"Ubicación: "+info(head,"departamento")+" / "+info(head,"provincia")+" / "+info(head,"distrito")+
                " / "+info(head,"centroPoblado"),false,10);
            addWord(document,"Coordenadas: "+info(head,"latitud")+", "+info(head,"longitud"),false,10);
            addWord(document,"ESTADO REGISTRADO",true,12);
            if(list(data,"plantas").isEmpty())addWord(document,"Sin inventario individual de plantas para este ámbito.",false,10);
            else {
                XWPFTable table=document.createTable();
                table.getRow(0).getCell(0).setText("Variedad");table.getRow(0).addNewTableCell().setText("Estado actual");
                table.getRow(0).addNewTableCell().setText("Cantidad");
                for(Map<String,Object> item:list(data,"plantas")) {
                    XWPFTableRow row=table.createRow();row.getCell(0).setText(info(item,"variedad"));
                    row.getCell(1).setText(info(item,"estado"));row.getCell(2).setText(info(item,"cantidad"));
                }
            }
            if(!list(data,"censos").isEmpty()) {
                addWord(document,"ÚLTIMOS CENSOS DISPONIBLES",true,12);
                for(Map<String,Object> row:list(data,"censos"))addWord(document,info(row,"variedad")+
                    " | Fecha: "+info(row,"fecha")+" | Total: "+info(row,"cantidad")+
                    " | Afectadas: "+info(row,"afectadas")+" | Muertas: "+info(row,"muertas"),false,10);
            }
            addWord(document,"CRONOLOGÍA DE ACTUACIONES",true,12);
            List<Entry> records=events(data);
            if(records.isEmpty())addWord(document,"No se encontraron actuaciones registradas en el período seleccionado.",false,10);
            for(Entry entry:records) {
                addWord(document,entry.fecha()+" | "+entry.titulo(),true,10);
                addWord(document,entry.detalle(),false,10);
            }
            addWord(document,"ANEXOS FOTOGRÁFICOS",true,12);
            int added=0;
            for(Map<String,Object> photo:list(data,"anexos")) {
                if(added>=12)break;
                byte[] image=readImage(photo);
                if(image==null)continue;
                try {
                    XWPFParagraph paragraph=document.createParagraph();XWPFRun run=paragraph.createRun();
                    int type="image/png".equals(photo.get("mime"))?Document.PICTURE_TYPE_PNG:Document.PICTURE_TYPE_JPEG;
                    run.addPicture(new java.io.ByteArrayInputStream(image),type,info(photo,"nombre"),Units.toEMU(320),Units.toEMU(215));
                    addWord(document,"Anexo "+(added+1)+". Planta "+info(photo,"planta")+" · "+info(photo,"fecha"),false,10);
                    added++;
                } catch(Exception ignored){ /* No impedir un documento por una foto ilegible. */ }
            }
            if(added==0)addWord(document,"No hay fotografías disponibles para este informe.",false,10);
            addWord(document,"Nota: los estados corresponden a registros disponibles; la ausencia de incidencias no acredita sanidad.",false,9);
            try(OutputStream stream=Files.newOutputStream(target)){document.write(stream);}
        }
    }
    private void addWord(XWPFDocument doc,String text,boolean bold,int size){
        XWPFParagraph paragraph=doc.createParagraph();
        XWPFRun run=paragraph.createRun();run.setBold(bold);run.setFontSize(size);run.setFontFamily("Calibri");run.setText(text);
    }

    private void writePdf(Map<String,Object> data, Job job, Path target) throws Exception {
        try (PDDocument document = new PDDocument()) {
            Map<String,Object> head = obj(data,"cabecera");
            try (EnterprisePdfLayout pen = new EnterprisePdfLayout(document, "INFORME DE SANIDAD",
                    job.desde() + " al " + job.hasta())) {
                pen.section("Ámbito del informe");
                pen.line("Unidad: " + info(head,"unidad"),10,true);
                pen.line("Predio: " + info(head,"predio") + " (" + info(head,"codigo") + ")",10,false);
                if ("AP_SANIDAD".equals(job.tipo())) pen.line("Socio: " + info(head,"socio"),10,false);
                pen.line("Ubicación: " + info(head,"departamento") + " / " + info(head,"provincia")
                        + " / " + info(head,"distrito") + " / " + info(head,"centroPoblado"),10,false);
                pen.line("Coordenadas: " + info(head,"latitud") + ", " + info(head,"longitud"),10,false);

                pen.section("Actividad del período");
                pen.stats("Casos registrados", String.valueOf(list(data,"casos").size()),
                        "Visitas técnicas", String.valueOf(list(data,"visitas").size()),
                        "Actuaciones", String.valueOf(events(data).size()));

                pen.section("Estado registrado de plantas");
                if (list(data,"plantas").isEmpty())
                    pen.line("Sin inventario individual de plantas para este ámbito.",10,false);
                for (Map<String,Object> row : list(data,"plantas"))
                    pen.line(info(row,"variedad") + "  |  Estado: " + info(row,"estado")
                            + "  |  Plantas: " + info(row,"cantidad"),10,false);

                if (!list(data,"censos").isEmpty()) {
                    pen.section("Últimos censos disponibles");
                    for (Map<String,Object> row : list(data,"censos"))
                        pen.line(info(row,"variedad") + "  |  " + info(row,"fecha")
                                + "  |  Total: " + info(row,"cantidad")
                                + "  |  Afectadas: " + info(row,"afectadas")
                                + "  |  Muertas: " + info(row,"muertas"),10,false);
                }

                pen.section("Cronología de actuaciones");
                List<Entry> records = events(data);
                if (records.isEmpty()) pen.line("No hay actuaciones registradas en el período.",10,false);
                for (Entry entry : records) {
                    pen.line(entry.fecha() + "  |  " + entry.titulo(),10,true);
                    pen.line(entry.detalle(),10,false);
                }

                pen.section("Anexos fotográficos");
                int index = 0;
                for (Map<String,Object> row : list(data,"anexos")) {
                    if (index >= 12) break;
                    byte[] bytes = readImage(row);
                    if (bytes == null) continue;
                    try {
                        pen.image(bytes);
                        pen.line("Anexo " + (index + 1) + ". Planta " + info(row,"planta")
                                + "  |  " + info(row,"fecha"),10,false);
                        index++;
                    } catch (Exception ignored) { /* Una imagen defectuosa no invalida el informe. */ }
                }
                if (index == 0) pen.line("No hay fotografías disponibles para este informe.",10,false);
                pen.line("Nota: la ausencia de incidencias registradas no acredita sanidad.",9,false);
            }
            document.save(target.toFile());
        }
    }

    private byte[] readImage(Map<String,Object> photo) {
        String mime=String.valueOf(photo.get("mime"));
        if(!mime.equals("image/jpeg")&&!mime.equals("image/png"))return null;
        Object key=photo.get("clave");
        if(key instanceof String path && !path.isBlank()) {
            try {
                Resource resource=storage.resource(path);
                if(resource.contentLength()>3_000_000)return null;
                try(InputStream input=resource.getInputStream()){
                    byte[] bytes=input.readNBytes(3_000_001);
                    return bytes.length>3_000_000?null:bytes;
                }
            } catch(Exception ignored){ /* Revisar la copia remota autorizada. */ }
        }
        Object remote=photo.get("url");
        if(!(remote instanceof String url))return null;
        try {
            java.net.URI uri=java.net.URI.create(url);
            if(!"https".equalsIgnoreCase(uri.getScheme()) || !"res.cloudinary.com".equalsIgnoreCase(uri.getHost())
                || (uri.getPort()!=-1 && uri.getPort()!=443))return null;
            java.net.http.HttpClient client=java.net.http.HttpClient.newBuilder()
                .followRedirects(java.net.http.HttpClient.Redirect.NEVER).connectTimeout(java.time.Duration.ofSeconds(5)).build();
            java.net.http.HttpRequest request=java.net.http.HttpRequest.newBuilder(uri)
                .timeout(java.time.Duration.ofSeconds(10)).GET().build();
            var response=client.send(request,java.net.http.HttpResponse.BodyHandlers.ofInputStream());
            if(response.statusCode()!=200)return null;
            try(InputStream input=response.body()){
                byte[] bytes=input.readNBytes(3_000_001);
                return bytes.length>3_000_000?null:bytes;
            }
        } catch(Exception ignored){return null;}
    }

}
