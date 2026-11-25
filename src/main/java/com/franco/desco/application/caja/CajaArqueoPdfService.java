package com.franco.desco.application.caja;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/** Acta A4 institucional: resume el cierre persistido sin exponer ventas individuales. */
@Service
public class CajaArqueoPdfService {
    private static final float LEFT = 44f;
    private static final float RIGHT = PDRectangle.A4.getWidth() - LEFT;
    private static final float WIDTH = RIGHT - LEFT;
    private static final PDType1Font NORMAL = new PDType1Font(Standard14Fonts.FontName.HELVETICA);
    private static final PDType1Font BOLD = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);
    private static final Color NAVY = new Color(17, 35, 61);
    private static final Color TEXT = new Color(34, 48, 67);
    private static final Color MUTED = new Color(99, 112, 130);
    private static final Color BORDER = new Color(224, 230, 238);
    private static final Color SOFT = new Color(245, 248, 252);
    private static final Color RED = new Color(169, 49, 57);

    public byte[] generar(CajaPosService.Arqueo balance) {
        if (balance == null || !"CERRADA".equals(balance.estado())) {
            throw new IllegalArgumentException("Solo se emiten reportes de turnos cerrados.");
        }
        try (PDDocument document = new PDDocument();
             ByteArrayOutputStream bytes = new ByteArrayOutputStream();
             Layout pdf = new Layout(document, balance.sesionId())) {
            metadata(pdf, balance);
            indicadores(pdf, balance);
            conciliacion(pdf, balance);
            medios(pdf, balance);
            observacion(pdf, balance);
            pdf.close();
            document.save(bytes);
            return bytes.toByteArray();
        } catch (IOException ex) {
            throw new IllegalStateException("No se pudo generar el documento.", ex);
        }
    }

    private void metadata(Layout pdf, CajaPosService.Arqueo b) throws IOException {
        pdf.ensure(88);
        float y = pdf.y;
        pdf.rectangle(LEFT, y - 76, WIDTH, 76, SOFT);
        pdf.labelValue(LEFT + 13, y - 17, "UNIDAD ORGANIZATIVA", b.uotNombre(), 245);
        pdf.labelValue(LEFT + 277, y - 17, "CAJA / TURNO", safe(b.caja()) + "  /  #" + b.sesionId(), 225);
        pdf.labelValue(LEFT + 13, y - 56, "APERTURA", date(b.fechaApertura()), 245);
        pdf.labelValue(LEFT + 277, y - 56, "CIERRE", date(b.fechaCierre()), 225);
        pdf.y -= 92;
    }

    private void indicadores(Layout pdf, CajaPosService.Arqueo b) throws IOException {
        pdf.ensure(92);
        float gap = 10;
        float card = (WIDTH - 2 * gap) / 3;
        BigDecimal difference = amount(b.diferencia());
        String status = difference.signum() == 0 ? "SIN DIFERENCIA"
                : difference.signum() < 0 ? "FALTANTE" : "SOBRANTE";
        pdf.card(LEFT, pdf.y, card, "TOTAL COBRADO", money(b.totalCobrado()), NAVY);
        pdf.card(LEFT + card + gap, pdf.y, card, "EFECTIVO ESPERADO", money(b.saldoEsperado()), NAVY);
        pdf.card(LEFT + 2 * (card + gap), pdf.y, card, status,
                money(difference.abs()), difference.signum() == 0 ? NAVY : RED);
        pdf.y -= 85;
    }

    private void conciliacion(Layout pdf, CajaPosService.Arqueo b) throws IOException {
        pdf.section("CONCILIACION DE EFECTIVO");
        pdf.twoColumn("Fondo inicial", money(b.saldoInicial()),
                "Cobros en efectivo", money(b.efectivo()));
        pdf.twoColumn("Ingresos de efectivo", money(b.ingresos()),
                "Egresos de efectivo", money(b.egresos()));
        pdf.twoColumn("Efectivo esperado", money(b.saldoEsperado()),
                "Efectivo declarado", money(b.saldoDeclarado()));
        pdf.ensure(36);
        float y = pdf.y;
        BigDecimal difference = amount(b.diferencia());
        pdf.rectangle(LEFT, y - 31, WIDTH, 31, SOFT);
        pdf.text(LEFT + 12, y - 20, difference.signum() == 0 ? "CAJA CUADRADA"
                : difference.signum() < 0 ? "DIFERENCIA: FALTANTE" : "DIFERENCIA: SOBRANTE",
                BOLD, 9, difference.signum() == 0 ? NAVY : RED);
        pdf.textRight(RIGHT - 12, y - 20, money(difference.abs()), BOLD, 10, TEXT);
        pdf.y -= 39;
    }

    private void medios(Layout pdf, CajaPosService.Arqueo b) throws IOException {
        pdf.section("RESUMEN DE COBROS");
        pdf.twoColumn("Ventas entregadas", money(b.ventasEntregadas()),
                "Total cobrado", money(b.totalCobrado()));
        pdf.twoColumn("Cobros en efectivo", money(b.efectivo()),
                "Cobros por otros medios", money(b.otrosMedios()));
        if (b.metodos() != null && !b.metodos().isEmpty()) {
            pdf.tableHeader("MEDIO DE PAGO", "IMPORTE");
            for (var metodo : b.metodos()) {
                pdf.tableLine(safe(metodo.nombre()), money(metodo.total()));
            }
        }
    }

    private void observacion(Layout pdf, CajaPosService.Arqueo b) throws IOException {
        if (b.observacion() == null || b.observacion().isBlank()) return;
        pdf.section("OBSERVACIONES DEL CIERRE");
        for (String line : pdf.wrap(safe(b.observacion()), NORMAL, 9, WIDTH - 28)) {
            pdf.ensure(18);
            pdf.text(LEFT + 10, pdf.y - 4, line, NORMAL, 9, TEXT);
            pdf.y -= 16;
        }
        pdf.y -= 5;
    }

    private static String money(BigDecimal amount) {
        return "S/ " + String.format(Locale.ROOT, "%,.2f", amount(amount));
    }

    private static BigDecimal amount(BigDecimal value) {
        return value == null ? BigDecimal.ZERO : value;
    }

    private static String date(String value) {
        if (value == null || value.isBlank()) return "—";
        if (value.length() >= 16 && value.charAt(4) == '-') {
            return value.substring(8, 10) + "/" + value.substring(5, 7) + "/" + value.substring(0, 4)
                    + "  " + value.substring(11, 16);
        }
        return safe(value);
    }

    private static String safe(String text) {
        if (text == null) return "—";
        StringBuilder result = new StringBuilder(text.length());
        for (int i = 0; i < text.length(); i++) {
            char c = text.charAt(i);
            if (c == '\n' || c == '\r' || c == '\t') result.append(' ');
            else if (c == '\u2013' || c == '\u2014') result.append('-');
            else if (c == '\u2018' || c == '\u2019') result.append('\'');
            else if (c == '\u201c' || c == '\u201d') result.append('"');
            else if (c >= 32 && c <= 255) result.append(c);
            else result.append(' ');
        }
        return result.toString();
    }

    private static final class Layout implements AutoCloseable {
        private final PDDocument document;
        private final long sesionId;
        private PDPageContentStream out;
        private float y;
        private int pageNumber;

        private Layout(PDDocument document, long sesionId) throws IOException {
            this.document = document;
            this.sesionId = sesionId;
            newPage();
        }

        private void newPage() throws IOException {
            if (out != null) { footer(); out.close(); }
            document.addPage(new PDPage(PDRectangle.A4));
            out = new PDPageContentStream(document, document.getPage(document.getNumberOfPages() - 1));
            pageNumber++;
            float top = PDRectangle.A4.getHeight();
            rectangle(LEFT, top - 40, 4, 24, NAVY);
            text(LEFT + 13, top - 26, "DESCO  |  GESTION COMERCIAL", BOLD, 9, NAVY);
            text(LEFT, top - 64, "ACTA DE CIERRE DE CAJA", BOLD, 17, NAVY);
            textRight(RIGHT, top - 64, "TURNO  " + sesionId, BOLD, 9, TEXT);
            line(LEFT, top - 76, RIGHT, top - 76, NAVY);
            y = top - 96;
        }

        private void footer() throws IOException {
            line(LEFT, 52, RIGHT, 52, BORDER);
            text(LEFT, 35, "DESCO  |  Control interno de caja", NORMAL, 8, MUTED);
            textRight(RIGHT, 35, "Turno " + sesionId + "  |  Pag. " + pageNumber, NORMAL, 8, MUTED);
        }

        private void ensure(float required) throws IOException {
            if (y - required < 70) newPage();
        }

        private void section(String heading) throws IOException {
            ensure(43);
            y -= 12;
            text(LEFT, y, heading, BOLD, 10, NAVY);
            y -= 12;
            line(LEFT, y, RIGHT, y, BORDER);
            y -= 20;
        }

        private void labelValue(float x, float top, String label, String value, float width) throws IOException {
            text(x, top, label, BOLD, 7.4f, MUTED);
            text(x, top - 16, ellipsis(safe(value), BOLD, 9.5f, width), BOLD, 9.5f, TEXT);
        }

        private void card(float x, float top, float width, String label, String value, Color foreground) throws IOException {
            rectangle(x, top - 70, width, 70, SOFT);
            line(x, top - 70, x + width, top - 70, BORDER);
            text(x + 11, top - 20, label, BOLD, 7.5f, MUTED);
            text(x + 11, top - 47, ellipsis(value, BOLD, 14, width - 22), BOLD, 14, foreground);
        }

        private void twoColumn(String label1, String value1, String label2, String value2) throws IOException {
            ensure(40);
            float top = y;
            line(LEFT, top - 34, RIGHT, top - 34, BORDER);
            text(LEFT + 8, top - 13, label1, NORMAL, 8.1f, MUTED);
            text(LEFT + 8, top - 28, value1, BOLD, 10, TEXT);
            float x = LEFT + WIDTH / 2 + 5;
            text(x, top - 13, label2, NORMAL, 8.1f, MUTED);
            text(x, top - 28, value2, BOLD, 10, TEXT);
            y -= 41;
        }

        private void tableHeader(String first, String second) throws IOException {
            ensure(28);
            rectangle(LEFT, y - 23, WIDTH, 23, SOFT);
            text(LEFT + 11, y - 15, first, BOLD, 8, NAVY);
            textRight(RIGHT - 11, y - 15, second, BOLD, 8, NAVY);
            y -= 23;
        }

        private void tableLine(String label, String value) throws IOException {
            ensure(24);
            float top = y;
            line(LEFT, top - 22, RIGHT, top - 22, BORDER);
            text(LEFT + 11, top - 15, ellipsis(label, NORMAL, 9, WIDTH - 154), NORMAL, 9, TEXT);
            textRight(RIGHT - 11, top - 15, value, BOLD, 9, TEXT);
            y -= 22;
        }

        private void rectangle(float x, float bottom, float width, float height, Color color) throws IOException {
            out.setNonStrokingColor(color);
            out.addRect(x, bottom, width, height);
            out.fill();
        }

        private void line(float x1, float y1, float x2, float y2, Color color) throws IOException {
            out.setStrokingColor(color);
            out.setLineWidth(.6f);
            out.moveTo(x1, y1);
            out.lineTo(x2, y2);
            out.stroke();
        }

        private void text(float x, float atY, String value, PDType1Font font, float size, Color color) throws IOException {
            out.beginText();
            out.setNonStrokingColor(color);
            out.setFont(font, size);
            out.newLineAtOffset(x, atY);
            out.showText(safe(value));
            out.endText();
        }

        private void textRight(float right, float atY, String value, PDType1Font font, float size, Color color) throws IOException {
            String printable = safe(value);
            text(right - width(printable, font, size), atY, printable, font, size, color);
        }

        private float width(String value, PDType1Font font, float size) throws IOException {
            return font.getStringWidth(safe(value)) * size / 1000f;
        }

        private String ellipsis(String value, PDType1Font font, float size, float maxWidth) throws IOException {
            String clean = safe(value);
            if (width(clean, font, size) <= maxWidth) return clean;
            while (!clean.isEmpty() && width(clean + "...", font, size) > maxWidth) {
                clean = clean.substring(0, clean.length() - 1);
            }
            return clean + "...";
        }

        private List<String> wrap(String text, PDType1Font font, float size, float maxWidth) throws IOException {
            List<String> result = new ArrayList<>();
            StringBuilder line = new StringBuilder();
            for (String token : safe(text).split("\\s+")) {
                if (token.isBlank()) continue;
                String word = token;
                while (!word.isEmpty() && width(word, font, size) > maxWidth) {
                    int cut = 1;
                    while (cut < word.length() && width(word.substring(0, cut + 1), font, size) <= maxWidth) cut++;
                    if (!line.isEmpty()) { result.add(line.toString()); line.setLength(0); }
                    result.add(word.substring(0, cut));
                    word = word.substring(cut);
                }
                if (word.isEmpty()) continue;
                String combined = line.isEmpty() ? word : line + " " + word;
                if (!line.isEmpty() && width(combined, font, size) > maxWidth) {
                    result.add(line.toString());
                    line.setLength(0);
                }
                if (!line.isEmpty()) line.append(' ');
                line.append(word);
            }
            if (!line.isEmpty()) result.add(line.toString());
            return result.isEmpty() ? List.of("—") : result;
        }

        @Override
        public void close() throws IOException {
            if (out != null) { footer(); out.close(); out = null; }
        }
    }
}
