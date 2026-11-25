package com.franco.desco.adapter.out.sqlserver.report;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.apache.pdfbox.pdmodel.graphics.image.PDImageXObject;

import java.awt.Color;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

/** Presentación editorial de informes PDF; sin acceso a datos ni reglas de negocio. */
public final class EnterprisePdfLayout implements AutoCloseable {
    private static final float LEFT = 48;
    private static final float RIGHT = PDRectangle.A4.getWidth() - LEFT;
    private static final float CONTENT_WIDTH = RIGHT - LEFT;
    private static final Color NAVY = new Color(37, 48, 64);
    private static final Color BLUE = new Color(37, 99, 235);
    private static final Color SOFT = new Color(229, 231, 235);
    private static final Color MUTED = new Color(102, 112, 133);
    private static final PDType1Font REGULAR = new PDType1Font(Standard14Fonts.FontName.HELVETICA);
    private static final PDType1Font STRONG = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);
    private final PDDocument document;
    private final String reportTitle;
    private final String period;
    private PDPageContentStream stream;
    private float y;
    private int pageNumber;

    public EnterprisePdfLayout(PDDocument document, String reportTitle, String period) throws IOException {
        this.document = document;
        this.reportTitle = reportTitle;
        this.period = period;
        openPage();
    }

    private void openPage() throws IOException {
        PDPage page = new PDPage(PDRectangle.A4);
        document.addPage(page);
        stream = new PDPageContentStream(document, page);
        pageNumber++;
        float top = PDRectangle.A4.getHeight();
        text(LEFT, top - 36, "DESCO  /  INFORMES", STRONG, 9, BLUE);
        text(LEFT, top - 63, reportTitle, STRONG, 16, NAVY);
        text(LEFT, top - 84, "Período: " + period, REGULAR, 9, MUTED);
        stream.setStrokingColor(BLUE);
        stream.setLineWidth(1.2f);
        stream.moveTo(LEFT, top - 99);
        stream.lineTo(RIGHT, top - 99);
        stream.stroke();
        y = top - 125;
    }

    private void footer() throws IOException {
        stream.setStrokingColor(SOFT);
        stream.setLineWidth(1);
        stream.moveTo(LEFT, 45);
        stream.lineTo(RIGHT, 45);
        stream.stroke();
        text(LEFT, 30, "DESCO  |  Uso interno", REGULAR, 8, MUTED);
        text(RIGHT - 92, 30, "Página " + pageNumber, REGULAR, 8, MUTED);
    }

    private void nextPage() throws IOException {
        footer();
        stream.close();
        stream = null;
        openPage();
    }

    private void space(float required) throws IOException {
        if (y - required < 66) nextPage();
    }

    public void section(String title) throws IOException {
        space(44);
        y -= 7;
        text(LEFT, y - 11, title.toUpperCase(java.util.Locale.ROOT), STRONG, 10, BLUE);
        stream.setStrokingColor(SOFT);
        stream.setLineWidth(0.7f);
        stream.moveTo(LEFT, y - 19);
        stream.lineTo(RIGHT, y - 19);
        stream.stroke();
        y -= 35;
    }

    public void line(String content, int size, boolean bold) throws IOException {
        String safe = clean(content);
        PDType1Font font = bold ? STRONG : REGULAR;
        int pointSize = Math.max(8, Math.min(13, size));
        List<String> lines = wrap(safe, font, pointSize, CONTENT_WIDTH - (bold ? 0 : 4));
        for (String part : lines) {
            space(pointSize + 9);
            text(LEFT + (bold ? 0 : 4), y, part, font, pointSize, bold ? NAVY : MUTED);
            y -= pointSize + 6;
        }
        y -= bold ? 5 : 3;
    }

    public void stats(String... pairs) throws IOException {
        if (pairs.length == 0 || pairs.length % 2 != 0) return;
        int count = pairs.length / 2;
        int columns = Math.min(3, count);
        float gap = 16;
        float width = (CONTENT_WIDTH - (columns - 1) * gap) / columns;
        int rows = (count + columns - 1) / columns;
        space(rows * 52 + 10);
        for (int i = 0; i < count; i++) {
            int col = i % columns;
            int row = i / columns;
            float x = LEFT + col * (width + gap);
            float top = y - row * 52;
            text(x, top - 10, clean(pairs[i * 2]), REGULAR, 9, MUTED);
            text(x, top - 31, clean(pairs[i * 2 + 1]), STRONG, 14, NAVY);
            stream.setStrokingColor(SOFT);
            stream.setLineWidth(0.6f);
            stream.moveTo(x, top - 39);
            stream.lineTo(x + width, top - 39);
            stream.stroke();
        }
        y -= rows * 52 + 6;
    }

    public void image(byte[] data) throws IOException {
        PDImageXObject item = PDImageXObject.createFromByteArray(document, data, "evidencia");
        float originalWidth = item.getWidth();
        float originalHeight = item.getHeight();
        if (originalHeight <= 0 || originalWidth <= 0) return;
        float scale = Math.min(CONTENT_WIDTH / originalWidth, 245 / originalHeight);
        float width = originalWidth * scale;
        float height = originalHeight * scale;
        space(height + 24);
        float x = LEFT + (CONTENT_WIDTH - width) / 2;
        stream.drawImage(item, x, y - height, width, height);
        stream.setStrokingColor(SOFT);
        stream.addRect(x, y - height, width, height);
        stream.stroke();
        y -= height + 12;
    }

    private void text(float x, float atY, String content, PDType1Font font, int size, Color color)
            throws IOException {
        stream.beginText();
        stream.setNonStrokingColor(color);
        stream.setFont(font, size);
        stream.newLineAtOffset(x, atY);
        stream.showText(clean(content));
        stream.endText();
    }

    private List<String> wrap(String sentence, PDType1Font font, int size, float width) throws IOException {
        List<String> result = new ArrayList<>();
        StringBuilder line = new StringBuilder();
        for (String raw : sentence.split("\\s+")) {
            if (raw.isEmpty()) continue;
            String word = raw;
            while (!word.isEmpty() && font.getStringWidth(word) * size / 1000f > width) {
                int cut = 1;
                while (cut < word.length()
                        && font.getStringWidth(word.substring(0, cut + 1)) * size / 1000f < width) cut++;
                if (!line.isEmpty()) {
                    result.add(line.toString());
                    line.setLength(0);
                }
                result.add(word.substring(0, cut));
                word = word.substring(cut);
            }
            if (word.isEmpty()) continue;
            String candidate = line.isEmpty() ? word : line + " " + word;
            if (!line.isEmpty() && font.getStringWidth(candidate) * size / 1000f > width) {
                result.add(line.toString());
                line.setLength(0);
            }
            if (!line.isEmpty()) line.append(' ');
            line.append(word);
        }
        if (!line.isEmpty()) result.add(line.toString());
        if (result.isEmpty()) result.add(" ");
        return result;
    }

    private String clean(String content) {
        if (content == null) return "";
        StringBuilder result = new StringBuilder();
        for (int i = 0; i < content.length(); i++) {
            char ch = content.charAt(i);
            result.append((ch >= 32 && ch <= 126) || (ch >= 160 && ch <= 255) ? ch : ' ');
        }
        return result.toString();
    }

    @Override
    public void close() throws IOException {
        if (stream != null) {
            footer();
            stream.close();
            stream = null;
        }
    }
}
