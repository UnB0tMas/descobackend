package com.franco.desco.application.fieldtrip.document;

import com.franco.desco.application.localdocument.LocalDocumentService;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.SessionIdentity;
import org.apache.poi.xwpf.usermodel.*;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;

/** Documento derivado de datos persistidos: nunca confía en nombres o recursos enviados por Angular. */
@Service
public final class E2DocumentService {
    private static final String DOCX = "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
    private static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")
            .withZone(ZoneId.of("America/Lima"));
    private final JdbcTemplate jdbc;
    private final JsonMapper mapper;
    private final LocalDocumentService local;

    public E2DocumentService(JdbcTemplate jdbc, JsonMapper mapper, LocalDocumentService local) {
        this.jdbc=jdbc; this.mapper=mapper; this.local=local;
    }

    public record Documento(Long archivoId, Long salidaId, String salidaNombre,
            String nombreOriginal, String mimeType, String tipo, Instant fechaCarga, Long tamanoBytes) {}

    public AppResult<List<Documento>> listar(Long uot, Long salida, SessionIdentity identity, boolean soloPropios) {
        if(identity==null||identity.usuarioId()==null)
            return AppResult.error(AppStatus.UNAUTHORIZED,"E2_DOC_SESION","Sesión no disponible.");
        try {
            List<Documento> docs=jdbc.query(
                "EXEC campo.PA_SalidaDocumento_Sel_Listado ?,?,?,?",
                (rs,n)->new Documento(rs.getLong("archivoId"),rs.getLong("salidaId"),
                  rs.getString("salidaNombre"),rs.getString("nombreOriginal"),
                  rs.getString("mimeType"),rs.getString("tipo"),
                  rs.getTimestamp("fechaCarga").toInstant(),rs.getLong("tamanoBytes")),
                identity.usuarioId(),uot,salida,soloPropios);
            return AppResult.ok("E2_DOCUMENTOS_LISTADOS","Documentos consultados.",docs);
        }catch(DataAccessException ex){
            return AppResult.error(AppStatus.SERVICE_UNAVAILABLE,"E2_DOC_LISTA_ERROR",
                    "No fue posible consultar los documentos.");
        }
    }

    public AppResult<Documento> generar(Long uot, Long salida, SessionIdentity identity) {
        if(identity==null||identity.usuarioId()==null||uot==null||salida==null)
            return AppResult.error(AppStatus.BAD_REQUEST,"E2_DOC_CONTEXTO","Identifique la salida y la sesión.");
        try {
            String json=jdbc.queryForObject("EXEC campo.PA_SalidaDocumento_Sel_Datos ?,?,?",
                    String.class,identity.usuarioId(),uot,salida);
            if(json==null||json.isBlank())
                return AppResult.error(AppStatus.NOT_FOUND,"E2_DOC_NO_DISPONIBLE","Solicitud no disponible.");
            JsonNode data=mapper.readTree(json);
            String version=data.path("fechaSolicitud").asText();
            String nombre="Solicitud_salida_"+salida+"_"+version.replaceAll("[^0-9]","")+".docx";
            UUID key=UUID.nameUUIDFromBytes(("DESCO:E2:WORD:"+identity.usuarioId()+":"+salida+":"+version)
                    .getBytes(StandardCharsets.UTF_8));
            byte[] bytes=construirWord(data);
            var upload=local.upload(identity,uot,new MemoryWordFile(nombre,bytes),"DOCUMENTO",
                    "Solicitud de salida #"+salida+" · "+version,"SALIDA",salida,false,key);
            if(!upload.exitoso()||upload.datos()==null)
                return AppResult.error(upload.estado(),upload.codigo(),upload.mensaje());
            return clasificar(identity,uot,salida,upload.datos().fileId(),"SOLICITUD_GENERADA");
        }catch(DataAccessException ex){
            return AppResult.error(AppStatus.SERVICE_UNAVAILABLE,"E2_DOC_BD_ERROR",
                    "No fue posible consultar los datos del documento.");
        }catch(Exception ex){
            return AppResult.error(AppStatus.SERVICE_UNAVAILABLE,"E2_DOC_GENERACION_ERROR",
                    "El Word no se pudo generar. Puede reintentar desde la ficha.");
        }
    }

    public AppResult<Documento> adjuntar(Long uot, Long salida, SessionIdentity identity,
            MultipartFile file, String tipo, UUID key) {
        if(identity==null||identity.usuarioId()==null||uot==null||salida==null||key==null)
            return AppResult.error(AppStatus.BAD_REQUEST,"E2_DOC_CONTEXTO","Datos de la carga incompletos.");
        if(!"SOLICITUD_FIRMADA".equals(tipo)&&!"EVIDENCIA_SALIDA".equals(tipo))
            return AppResult.error(AppStatus.BAD_REQUEST,"E2_DOC_TIPO","Seleccione documento firmado o evidencia.");
        if(file==null||file.isEmpty()||file.getSize()>25L*1024*1024)
            return AppResult.error(AppStatus.BAD_REQUEST,"E2_DOC_ARCHIVO","Seleccione un archivo.");
        try {
            String mime=file.getContentType()==null?"":file.getContentType().toLowerCase();
            if(!List.of(DOCX,"application/pdf","application/msword","image/jpeg",
                    "image/png","image/webp","application/vnd.openxmlformats-officedocument.spreadsheetml.sheet").contains(mime))
                return AppResult.error(AppStatus.BAD_REQUEST,"E2_DOC_FORMATO","Formato no permitido.");
            var upload=local.upload(identity,uot,file,
                    mime.startsWith("image/")?"FOTOGRAFIA":"DOCUMENTO",
                    "Archivo de salida #"+salida,"SALIDA",salida,false,key);
            if(!upload.exitoso()||upload.datos()==null)
                return AppResult.error(upload.estado(),upload.codigo(),upload.mensaje());
            return clasificar(identity,uot,salida,upload.datos().fileId(),tipo);
        }catch(DataAccessException ex){
            return AppResult.error(AppStatus.SERVICE_UNAVAILABLE,"E2_DOC_REGISTRO_ERROR",
                    "No fue posible vincular el documento.");
        }
    }

    private AppResult<Documento> clasificar(SessionIdentity user,Long uot,Long salida,Long archivo,String tipo) {
        jdbc.update("EXEC campo.PA_SalidaDocumento_Upd_Clasificar ?,?,?,?,?",
                user.usuarioId(),uot,salida,archivo,tipo);
        var found=listar(uot,salida,user,true);
        if(!found.exitoso()||found.datos()==null)
            return AppResult.error(AppStatus.SERVICE_UNAVAILABLE,"E2_DOC_VERIFICACION",
                    "El archivo quedó registrado, pero no pudo verificarse.");
        return found.datos().stream().filter(x->archivo.equals(x.archivoId()))
                .findFirst().map(x->AppResult.ok("E2_DOC_GUARDADO","Archivo registrado.",x))
                .orElseGet(()->AppResult.error(AppStatus.SERVICE_UNAVAILABLE,"E2_DOC_NO_VISIBLE",
                        "No fue posible consultar el archivo almacenado."));
    }

    private static byte[] construirWord(JsonNode d) throws IOException {
        try (XWPFDocument word=new XWPFDocument(); ByteArrayOutputStream out=new ByteArrayOutputStream()) {
            XWPFParagraph title=word.createParagraph(); title.setAlignment(ParagraphAlignment.CENTER);
            XWPFRun t=title.createRun();t.setBold(true);t.setFontSize(16);t.setText("SOLICITUD DE SALIDA DE CAMPO");
            XWPFParagraph codigo=word.createParagraph();codigo.setAlignment(ParagraphAlignment.CENTER);
            codigo.createRun().setText("N.° "+d.path("salidaId").asText()+"  |  "+d.path("uot").asText());
            paragraph(word,"Fecha de solicitud: "+format(d.path("fechaSolicitud").asText()));
            paragraph(word,"Asunto: "+d.path("nombre").asText());
            paragraph(word,"Motivo: "+d.path("motivo").asText());
            String solicitante=d.path("solicitante").asText();
            paragraph(word,"Por medio del presente, "+solicitante+", en calidad de responsable de la salida, "
                +"solicita autorización para realizar actividades técnicas de campo, de conformidad "
                +"con la programación y los recursos detallados en este documento.");
            paragraph(word,"Inicio previsto: "+format(d.path("inicio").asText())
                +"       Fin previsto: "+format(d.path("fin").asText()));
            if(!d.path("descripcion").asText().isBlank())paragraph(word,"Descripción: "+d.path("descripcion").asText());
            heading(word,"Destinos y actividades previstas");
            var destinos=d.path("destinos");
            XWPFTable destinosTabla=word.createTable();writeRow(destinosTabla.getRow(0),"Fundo / predio","Actividad prevista");
            for(JsonNode x:destinos)writeRow(destinosTabla.createRow(),x.path("predio").asText(),x.path("actividad").asText());
            heading(word,"Participantes");
            XWPFTable participantes=word.createTable();writeRow(participantes.getRow(0),"Nombres y apellidos","Función");
            for(JsonNode x:d.path("participantes"))writeRow(participantes.createRow(),x.path("nombre").asText(),
                x.path("responsable").asBoolean()?"Responsable":x.path("funcion").asText("Técnico"));
            heading(word,"Recursos y vehículos solicitados");
            XWPFTable bienes=word.createTable();writeRow(bienes.getRow(0),"Recurso","Tipo","Cantidad");
            for(JsonNode x:d.path("recursos"))writeRow(bienes.createRow(),x.path("nombre").asText(),
                x.path("tipo").asText(),x.path("cantidad").asText()+" "+x.path("unidad").asText());
            paragraph(word,"La salida se ejecutará exclusivamente después de la aprobación correspondiente "
                +"y de la entrega física de los recursos autorizados. Al retornar se declarará su estado "
                +"y se cumplirá el procedimiento de inspección y cierre.");
            paragraph(word," "); paragraph(word," ");
            XWPFParagraph firma=word.createParagraph(); firma.setAlignment(ParagraphAlignment.CENTER);
            firma.createRun().setText("________________________________________");
            XWPFParagraph persona=word.createParagraph();persona.setAlignment(ParagraphAlignment.CENTER);
            persona.createRun().setText(solicitante+"\nResponsable de la salida · Firma");
            word.write(out);return out.toByteArray();
        }
    }

    private static void heading(XWPFDocument doc,String title){
        XWPFParagraph p=doc.createParagraph(); p.setSpacingBefore(260);
        XWPFRun r=p.createRun();r.setBold(true);r.setFontSize(12);r.setText(title);
    }
    private static void paragraph(XWPFDocument doc,String content){
        XWPFParagraph p=doc.createParagraph();p.setSpacingAfter(125);
        p.createRun().setText(content);
    }
    private static void writeRow(XWPFTableRow row,String... values){
        for(int i=0;i<values.length;i++){
            XWPFTableCell cell=i<row.getTableCells().size()?row.getCell(i):row.addNewTableCell();
            cell.setText(values[i]==null?"":values[i]);
        }
    }
    private static String format(String iso){
        try{return DATE.format(Instant.parse(iso));}catch(Exception ex){return iso;}
    }

    private record MemoryWordFile(String name,byte[] bytes) implements MultipartFile {
        @Override public String getName(){return "archivo";}
        @Override public String getOriginalFilename(){return name;}
        @Override public String getContentType(){return DOCX;}
        @Override public boolean isEmpty(){return bytes==null||bytes.length==0;}
        @Override public long getSize(){return bytes.length;}
        @Override public byte[] getBytes(){return bytes.clone();}
        @Override public InputStream getInputStream(){return new ByteArrayInputStream(bytes);}
        @Override public void transferTo(java.io.File dest) throws IOException{Files.write(dest.toPath(),bytes);}
    }
}
