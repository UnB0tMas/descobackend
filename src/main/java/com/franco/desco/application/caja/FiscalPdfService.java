package com.franco.desco.application.caja;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.WriterException;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
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
import java.util.Map;

/** Representación A4 de la venta: una sola ficha fiscal para impresión y emisión posterior. */
@Service
public class FiscalPdfService {
    private static final float WIDTH = PDRectangle.A4.getWidth();
    private static final float HEIGHT = PDRectangle.A4.getHeight();
    private static final float LEFT = 42;
    private static final float RIGHT = WIDTH - LEFT;
    private static final float CONTENT = RIGHT - LEFT;
    private static final PDType1Font REGULAR = new PDType1Font(Standard14Fonts.FontName.HELVETICA);
    private static final PDType1Font BOLD = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);
    private static final Color INK = new Color(34, 49, 67);
    private static final Color BLUE = new Color(29, 72, 136);
    private static final Color MUTED = new Color(89, 104, 120);
    private static final Color LINE = new Color(215, 223, 231);
    private static final Color PALE = new Color(244, 247, 251);

    public byte[] generar(CajaPosService.Comprobante receipt) {
        try (PDDocument document = new PDDocument(); ByteArrayOutputStream buffer = new ByteArrayOutputStream()) {
            Canvas canvas = new Canvas(document, receipt);
            canvas.openPage(false);
            canvas.drawIssuerAndDocument();
            canvas.drawCustomer();
            canvas.drawTableHeader();
            List<Map<String, Object>> items = receipt.lineas() == null ? List.of() : receipt.lineas();
            for (Map<String, Object> item : items) {
                canvas.drawItem(item);
            }
            canvas.drawTotals();
            canvas.drawIdentification();
            canvas.closePage();
            document.save(buffer);
            return buffer.toByteArray();
        } catch (IOException | WriterException ex) {
            throw new IllegalStateException("No se pudo generar el comprobante.", ex);
        }
    }

    private static final class Canvas {
        private final PDDocument document;
        private final CajaPosService.Comprobante receipt;
        private PDPageContentStream stream;
        private float y;
        private int pageNumber;
        private int rowNumber;

        private Canvas(PDDocument document, CajaPosService.Comprobante receipt) {
            this.document = document;
            this.receipt = receipt;
        }

        private void openPage(boolean continuation) throws IOException {
            document.addPage(new PDPage(PDRectangle.A4));
            stream = new PDPageContentStream(document, document.getPage(document.getNumberOfPages() - 1));
            pageNumber++;
            stream.setNonStrokingColor(BLUE);
            stream.addRect(LEFT, HEIGHT - 43, CONTENT, 4);
            stream.fill();
            y = HEIGHT - 68;
            if (continuation) {
                write(LEFT, y, 13, true, INK, safe(receipt.emisorRazonSocial(), receipt.uotNombre()));
                writeRight(RIGHT, y, 9, false, MUTED, "Continuación · " + number());
                y -= 29;
                drawTableHeader();
            }
        }

        private void closePage() throws IOException {
            line(LEFT, RIGHT, 49, LINE);
            write(LEFT, 35, 8, false, MUTED, "DESCO | Gestión comercial");
            writeRight(RIGHT, 35, 8, false, MUTED, "Página " + pageNumber);
            stream.close();
        }

        private void nextPage() throws IOException {
            closePage();
            openPage(true);
        }

        private void drawIssuerAndDocument() throws IOException {
            // Datos del emisor y recuadro del comprobante, con límites independientes.
            float headerY = y;
            write(LEFT, y + 12, 8, true, MUTED, "EMISOR");
            y -= 10;
            List<String> issuer = wrap(safe(receipt.emisorRazonSocial(), receipt.uotNombre()), BOLD, 14, 290);
            for (String part : issuer.subList(0, Math.min(3, issuer.size()))) {
                write(LEFT, y, 14, true, BLUE, part);
                y -= 18;
            }
            if (has(receipt.emisorRuc())) {
                write(LEFT, y - 2, 9, true, INK, "RUC: " + safe(receipt.emisorRuc(), ""));
                y -= 16;
            }
            if (has(receipt.emisorDireccion())) {
                for (String part : wrap(safe(receipt.emisorDireccion(), ""), REGULAR, 8.5f, 296)) {
                    write(LEFT, y - 2, 8.5f, false, MUTED, part);
                    y -= 13;
                }
            }
            float boxX = RIGHT - 183;
            float boxTop = headerY + 17;
            box(boxX, boxTop - 88, 183, 88, BLUE, Color.WHITE);
            stream.setNonStrokingColor(BLUE);
            stream.addRect(boxX, boxTop - 6, 183, 6);
            stream.fill();
            writeCentered(boxX, 183, boxTop - 32, 11, true, INK,
                    "FACTURA".equals(receipt.tipoDocumento()) ? "FACTURA" : "BOLETA DE VENTA");
            line(boxX + 12, boxX + 171, boxTop - 43, LINE);
            writeCentered(boxX, 183, boxTop - 66, 12, true, BLUE, number());
            y = Math.min(y - 12, boxTop - 107);
        }

        private String number() {
            String serie = safe(receipt.serie(), "");
            Long numero = receipt.numero();
            return (serie.isBlank() ? "" : serie + "-")
                    + String.format(Locale.ROOT, "%08d", numero == null ? receipt.ventaId() : numero);
        }

        private void drawCustomer() throws IOException {
            float top = y;
            List<String> customer = wrap(safe(receipt.cliente(), "Cliente varios"), REGULAR, 9, CONTENT - 130);
            boolean documentAvailable = has(receipt.documento());
            boolean employeeAvailable = has(receipt.atendidoPor());
            float height = 67 + Math.max(0, customer.size() - 1) * 13
                    + (documentAvailable ? 18 : 0) + (employeeAvailable ? 18 : 0);
            box(LEFT, top - height, CONTENT, height, LINE, PALE);
            stream.setNonStrokingColor(BLUE);
            stream.addRect(LEFT, top - height, 3, height);
            stream.fill();
            float row = top - 18;
            write(LEFT + 13, row, 8, true, MUTED, "FECHA DE EMISIÓN");
            write(LEFT + 125, row, 9, false, INK, safe(receipt.fecha(), "").replace('T', ' '));
            row -= 19;
            write(LEFT + 13, row, 8, true, MUTED, "CLIENTE");
            for (String part : customer) {
                write(LEFT + 125, row, 9, false, INK, part);
                row -= 13;
            }
            row -= 5;
            if (documentAvailable) {
                write(LEFT + 13, row, 8, true, MUTED, "DOCUMENTO");
                write(LEFT + 125, row, 9, false, INK,
                        fit(safe(receipt.documento(), ""), REGULAR, 9, CONTENT - 138));
                row -= 18;
            }
            if (employeeAvailable) {
                write(LEFT + 13, row, 8, true, MUTED, "ATENDIDO POR");
                write(LEFT + 125, row, 9, false, INK,
                        fit(safe(receipt.atendidoPor(), ""), REGULAR, 9, CONTENT - 138));
            }
            y = top - height - 22;
        }

        private void drawTableHeader() throws IOException {
            stream.setNonStrokingColor(BLUE);
            stream.addRect(LEFT, y - 25, CONTENT, 29);
            stream.fill();
            write(LEFT + 11, y - 14, 9, true, Color.WHITE, "DESCRIPCIÓN");
            writeRight(LEFT + 346, y - 14, 9, true, Color.WHITE, "CANT.");
            writeRight(LEFT + 427, y - 14, 9, true, Color.WHITE, "P. UNIT.");
            writeRight(RIGHT - 10, y - 14, 9, true, Color.WHITE, "IMPORTE");
            y -= 39;
        }

        private void drawItem(Map<String, Object> item) throws IOException {
            List<String> description = wrap(safe(item.get("producto"), ""), REGULAR, 9, 266);
            float rowHeight = Math.max(31, 14 + description.size() * 13);
            if (y - rowHeight < 180) {
                nextPage();
            }
            if (++rowNumber % 2 == 0) {
                stream.setNonStrokingColor(PALE);
                stream.addRect(LEFT, y - rowHeight + 2, CONTENT, rowHeight);
                stream.fill();
            }
            float baseline = y - 13;
            for (String part : description) {
                write(LEFT + 11, baseline, 9, false, INK, part);
                baseline -= 13;
            }
            writeRight(LEFT + 346, y - 13, 9, false, INK, quantity(item.get("cantidad")));
            writeRight(LEFT + 427, y - 13, 9, false, INK, decimal(item.get("precioUnitario")));
            writeRight(RIGHT - 10, y - 13, 9, true, INK, decimal(item.get("subtotal")));
            y -= rowHeight;
            line(LEFT, RIGHT, y, LINE);
            y -= 5;
        }

        private void drawTotals() throws IOException {
            if (y < 192) {
                nextPage();
            }
            y -= 16;
            float x = RIGHT - 245;
            box(x, y - 99, 245, 99, LINE, PALE);
            write(x + 14, y - 19, 9, false, MUTED, "Subtotal");
            writeRight(RIGHT - 14, y - 19, 9, true, INK, money(receipt.subtotal()));
            write(x + 14, y - 40, 9, false, MUTED, "Impuestos");
            writeRight(RIGHT - 14, y - 40, 9, true, INK, money(receipt.impuesto()));
            line(x + 14, RIGHT - 14, y - 51, LINE);
            write(x + 14, y - 77, 12, true, INK, "TOTAL A PAGAR");
            writeRight(RIGHT - 14, y - 77, 13, true, BLUE, money(receipt.total()));
            y -= 116;
        }

        private void drawIdentification() throws IOException, WriterException {
            if (y < 168) {
                nextPage();
            }
            // Los comprobantes breves alinean el QR hacia el pie del A4;
            // los comprobantes extensos conservan el orden natural de lectura.
            float top = Math.min(y - 11, 215);
            float bottom = top - 112;
            line(LEFT, RIGHT, top + 4, LINE);
            if (has(receipt.qrContenido())) {
                drawQr(receipt.qrContenido(), LEFT + 10, bottom + 10, 88);
                write(LEFT + 119, top - 23, 9, true, INK, "Código QR del comprobante");
                write(LEFT + 119, top - 43, 9, false, MUTED, number());
                write(LEFT + 119, top - 63, 9, false, MUTED, "Gracias por su compra");
            } else {
                write(LEFT + 12, top - 25, 9, true, INK, number());
                write(LEFT + 12, top - 45, 9, false, MUTED, "Gracias por su compra");
            }
            y = bottom;
        }

        private void write(float x, float positionY, float size, boolean bold, Color color, String value)
                throws IOException {
            stream.setNonStrokingColor(color);
            stream.beginText();
            stream.setFont(bold ? BOLD : REGULAR, size);
            stream.newLineAtOffset(x, positionY);
            stream.showText(safe(value, ""));
            stream.endText();
        }

        private void writeRight(float end, float positionY, float size, boolean bold, Color color, String value)
                throws IOException {
            PDType1Font font = bold ? BOLD : REGULAR;
            String label = safe(value, "");
            write(end - textWidth(label, font, size), positionY, size, bold, color, label);
        }

        private void writeCentered(float x, float width, float positionY, float size, boolean bold, Color color, String value)
                throws IOException {
            PDType1Font font = bold ? BOLD : REGULAR;
            String label = safe(value, "");
            write(x + (width - textWidth(label, font, size)) / 2, positionY, size, bold, color, label);
        }

        private void line(float x1, float x2, float positionY, Color color) throws IOException {
            stream.setStrokingColor(color);
            stream.moveTo(x1, positionY);
            stream.lineTo(x2, positionY);
            stream.stroke();
        }

        private void box(float x, float bottom, float width, float height, Color border, Color fill) throws IOException {
            stream.setNonStrokingColor(fill);
            stream.addRect(x, bottom, width, height);
            stream.fill();
            stream.setStrokingColor(border);
            stream.addRect(x, bottom, width, height);
            stream.stroke();
        }

        private void drawQr(String value, float x, float bottom, float side) throws WriterException, IOException {
            BitMatrix image = new QRCodeWriter().encode(value, BarcodeFormat.QR_CODE, 160, 160);
            float cell = side / image.getWidth();
            stream.setNonStrokingColor(Color.WHITE);
            stream.addRect(x - 4, bottom - 4, side + 8, side + 8);
            stream.fill();
            stream.setNonStrokingColor(Color.BLACK);
            for (int row = 0; row < image.getHeight(); row++) {
                for (int col = 0; col < image.getWidth(); col++) {
                    if (image.get(col, row)) {
                        stream.addRect(x + col * cell, bottom + (image.getHeight() - row - 1) * cell,
                                cell + 0.01f, cell + 0.01f);
                    }
                }
            }
            stream.fill();
        }
    }

    private static String quantity(Object value) {
        return format(value, 3);
    }

    private static String decimal(Object value) {
        return format(value, 2);
    }

    private static String money(BigDecimal value) {
        return "PEN " + format(value, 2);
    }

    private static String format(Object value, int digits) {
        try {
            return String.format(Locale.US, "%1$." + digits + "f", new BigDecimal(String.valueOf(value)));
        } catch (NumberFormatException ex) {
            return "0." + "0".repeat(digits);
        }
    }

    private static boolean has(String value) {
        return value != null && !value.isBlank();
    }

    private static String safe(Object value, String fallback) {
        if (value == null || value.toString().isBlank()) {
            return fallback;
        }
        String normalized = value.toString().replace('\n', ' ').replace('\r', ' ')
                .replace('–', '-').replace('—', '-').replace('×', 'x');
        StringBuilder result = new StringBuilder();
        for (int i = 0; i < normalized.length(); i++) {
            String current = String.valueOf(normalized.charAt(i));
            try {
                REGULAR.getStringWidth(current);
                result.append(current);
            } catch (IOException | IllegalArgumentException ex) {
                result.append(' ');
            }
        }
        return result.toString().trim();
    }

    private static float textWidth(String value, PDType1Font font, float size) throws IOException {
        return font.getStringWidth(value) * size / 1000;
    }

    private static String fit(String value, PDType1Font font, float size, float maxWidth) throws IOException {
        if (textWidth(value, font, size) <= maxWidth) {
            return value;
        }
        String remaining = value;
        while (!remaining.isEmpty() && textWidth(remaining + "...", font, size) > maxWidth) {
            remaining = remaining.substring(0, remaining.length() - 1);
        }
        return remaining + "...";
    }

    private static List<String> wrap(String value, PDType1Font font, float size, float maxWidth) throws IOException {
        String normalized = safe(value, "");
        List<String> lines = new ArrayList<>();
        String line = "";
        for (String word : normalized.split("\\s+")) {
            String next = line.isEmpty() ? word : line + " " + word;
            if (textWidth(next, font, size) <= maxWidth) {
                line = next;
            } else {
                if (!line.isEmpty()) {
                    lines.add(line);
                }
                line = fit(word, font, size, maxWidth);
            }
        }
        if (!line.isEmpty()) {
            lines.add(line);
        }
        if (lines.isEmpty()) {
            lines.add("");
        }
        return lines;
    }
}
