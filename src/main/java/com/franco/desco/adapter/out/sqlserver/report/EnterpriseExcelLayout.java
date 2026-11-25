package com.franco.desco.adapter.out.sqlserver.report;

import org.apache.poi.ss.usermodel.*;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.xssf.usermodel.XSSFCellStyle;
import org.apache.poi.xssf.usermodel.XSSFColor;
import org.apache.poi.xssf.usermodel.XSSFFont;
import org.apache.poi.xssf.streaming.SXSSFWorkbook;

import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

/** Presentación única de los informes Excel; no consulta datos ni modifica reglas de negocio. */
public final class EnterpriseExcelLayout {
    private static final String DARK = "253040";
    private static final String BLUE = "2563EB";
    private static final String LIGHT = "F3F4F6";
    private static final String PALE = "FAFAFA";
    private static final String GREY = "667085";
    private static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DateTimeFormatter STAMP = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
    private final SXSSFWorkbook book;
    private final Sheet summary;
    private final Sheet detail;
    private final String code;
    private final String title;
    private final LocalDate from;
    private final LocalDate to;
    private final CellStyle banner;
    private final CellStyle subtitle;
    private final CellStyle section;
    private final CellStyle sectionCaption;
    private final CellStyle label;
    private final CellStyle value;
    private final CellStyle integer;
    private final CellStyle decimal;
    private final CellStyle currency;
    private final CellStyle datetime;
    private final CellStyle date;
    private final CellStyle[] textRows = new CellStyle[2];
    private final CellStyle[] numberRows = new CellStyle[2];
    private final CellStyle[] wholeRows = new CellStyle[2];
    private final CellStyle[] currencyRows = new CellStyle[2];
    private final CellStyle[] dateRows = new CellStyle[2];
    private final CellStyle[] datetimeRows = new CellStyle[2];
    private final Map<String, Integer> columnIndices = new HashMap<>();
    private final Map<String, BigDecimal> sums = new HashMap<>();
    private final Map<String, Set<String>> distinct = new HashMap<>();
    private final Map<String, Long> groups = new HashMap<>();
    private final Map<String, ProductSummary> products = new HashMap<>();
    private int totalRows;
    private int totalColumns;
    private String[] columnLabels = new String[0];
    private String groupField;

    private static final class ProductSummary {
        final String code;
        final String name;
        BigDecimal quantity = BigDecimal.ZERO;
        BigDecimal amount = BigDecimal.ZERO;
        ProductSummary(String code, String name) { this.code = code; this.name = name; }
    }

    public EnterpriseExcelLayout(SXSSFWorkbook workbook, String code, LocalDate from, LocalDate to) {
        this.book = workbook;
        this.code = code;
        this.title = reportTitle(code);
        this.from = from;
        this.to = to;
        this.summary = book.createSheet("Resumen");
        this.detail = book.createSheet("Detalle");
        this.banner = style(null, BLUE, true, (short) 10, null);
        this.subtitle = style(null, DARK, true, (short) 16, null);
        this.section = style(BLUE, "FFFFFF", true, (short) 10, null);
        this.sectionCaption = style(null, BLUE, true, (short) 10, null);
        this.sectionCaption.setBorderBottom(BorderStyle.THIN);
        ((XSSFCellStyle) this.sectionCaption).setBottomBorderColor(color(BLUE));
        this.label = style(null, GREY, false, (short) 10, null);
        this.value = style(null, DARK, false, (short) 10, null);
        this.integer = style(null, DARK, true, (short) 11, "#,##0");
        this.decimal = style(null, DARK, true, (short) 11, "#,##0.00");
        this.currency = style(null, DARK, true, (short) 11, "\"S/ \"#,##0.00");
        this.integer.setAlignment(HorizontalAlignment.RIGHT);
        this.decimal.setAlignment(HorizontalAlignment.RIGHT);
        this.currency.setAlignment(HorizontalAlignment.RIGHT);
        this.datetime = style(null, DARK, false, (short) 10, "dd/mm/yyyy hh:mm");
        this.date = style(null, DARK, false, (short) 10, "dd/mm/yyyy");
        for (int i = 0; i < 2; i++) {
            String background = i == 0 ? "FFFFFF" : PALE;
            textRows[i] = style(background, DARK, false, (short) 10, null);
            numberRows[i] = style(background, DARK, false, (short) 10, "#,##0.00");
            wholeRows[i] = style(background, DARK, false, (short) 10, "#,##0");
            currencyRows[i] = style(background, DARK, false, (short) 10, "\"S/ \"#,##0.00");
            dateRows[i] = style(background, DARK, false, (short) 10, "dd/mm/yyyy");
            datetimeRows[i] = style(background, DARK, false, (short) 10, "dd/mm/yyyy hh:mm");
            textRows[i].setWrapText(true);
            numberRows[i].setAlignment(HorizontalAlignment.RIGHT);
            wholeRows[i].setAlignment(HorizontalAlignment.RIGHT);
            currencyRows[i].setAlignment(HorizontalAlignment.RIGHT);
            dateRows[i].setAlignment(HorizontalAlignment.CENTER);
            datetimeRows[i].setAlignment(HorizontalAlignment.CENTER);
        }
        section.setWrapText(true);
        int[] widths = {5300, 4300, 4400, 4000, 5300, 4300, 4400, 4000};
        for (int i = 0; i < widths.length; i++) summary.setColumnWidth(i, widths[i]);
        summary.setDisplayGridlines(false);
        detail.setDisplayGridlines(false);
        summary.setZoom(95);
        titleRow(summary, 0, 0, 7, "DESCO  /  REPORTES", banner, 28);
        titleRow(summary, 2, 0, 7, title, subtitle, 33);
        titleRow(summary, 4, 0, 7, "INFORMACIÓN GENERAL", sectionCaption, 25);
        field(5, "Desde", from.format(DATE));
        field(6, "Hasta", to.format(DATE));
        field(7, "Generado", ZonedDateTime.now(ZoneId.of("America/Lima")).format(STAMP));
        detail.setRepeatingRows(CellRangeAddress.valueOf("1:5"));
        configurePrint(summary, false);
        configurePrint(detail, true);
    }

    private void configurePrint(Sheet sheet, boolean landscape) {
        sheet.setAutobreaks(true);
        sheet.setFitToPage(true);
        sheet.getPrintSetup().setLandscape(landscape);
        sheet.getPrintSetup().setFitWidth((short) 1);
        sheet.getPrintSetup().setFitHeight((short) 0);
        sheet.getFooter().setCenter("DESCO  |  Página &P de &N");
        sheet.getFooter().setRight("Uso interno");
    }

    private XSSFColor color(String rgb) {
        return new XSSFColor(new byte[]{(byte) Integer.parseInt(rgb.substring(0, 2), 16),
                (byte) Integer.parseInt(rgb.substring(2, 4), 16),
                (byte) Integer.parseInt(rgb.substring(4, 6), 16)}, null);
    }

    private CellStyle style(String background, String foreground, boolean strong, short size, String pattern) {
        XSSFCellStyle cell = (XSSFCellStyle) book.createCellStyle();
        if (background != null) {
            cell.setFillForegroundColor(color(background));
            cell.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        }
        XSSFFont font = (XSSFFont) book.createFont();
        font.setFontName("Aptos");
        font.setBold(strong);
        font.setFontHeightInPoints(size);
        font.setColor(color(foreground));
        cell.setFont(font);
        cell.setVerticalAlignment(VerticalAlignment.CENTER);
        if (pattern != null) cell.setDataFormat(book.createDataFormat().getFormat(pattern));
        return cell;
    }

    private void titleRow(Sheet sheet, int rowNumber, int first, int last, String text,
                          CellStyle cellStyle, int height) {
        Row row = sheet.getRow(rowNumber);
        if (row == null) row = sheet.createRow(rowNumber);
        row.setHeightInPoints(height);
        for (int col = first; col <= last; col++) row.createCell(col).setCellStyle(cellStyle);
        row.getCell(first).setCellValue(text);
        if (first < last) sheet.addMergedRegion(new CellRangeAddress(rowNumber, rowNumber, first, last));
    }

    private void field(int rowNumber, String name, String content) {
        Row row = summary.createRow(rowNumber);
        row.setHeightInPoints(21);
        Cell nameCell = row.createCell(0);
        nameCell.setCellValue(name);
        nameCell.setCellStyle(label);
        summary.addMergedRegion(new CellRangeAddress(rowNumber, rowNumber, 1, 7));
        Cell dataCell = row.createCell(1);
        dataCell.setCellValue(content);
        dataCell.setCellStyle(value);
    }

    public void columns(ResultSetMetaData meta) throws SQLException {
        totalColumns = meta.getColumnCount();
        if (totalColumns < 1) return;
        columnLabels = new String[totalColumns];
        int last = Math.max(0, Math.min(totalColumns - 1, 7));
        titleRow(detail, 0, 0, last, title, subtitle, 33);
        titleRow(detail, 2, 0, last, "Período: " + from.format(DATE) + " al " + to.format(DATE), value, 23);
        detail.setZoom(totalColumns >= 9 ? 70 : totalColumns >= 7 ? 80 : 95);
        Row row = detail.createRow(4);
        row.setHeightInPoints(32);
        for (int i = 1; i <= totalColumns; i++) {
            String name = meta.getColumnLabel(i);
            columnLabels[i - 1] = name;
            columnIndices.put(normalize(name), i);
            Cell cell = row.createCell(i - 1);
            cell.setCellValue(friendlyName(name));
            cell.setCellStyle(section);
            detail.setColumnWidth(i - 1, width(name));
        }
        groupField = switch (code) {
            case "TEC_SANIDAD" -> "Severidad";
            case "TEC_VISITAS", "TEC_SALIDAS", "AP_CAMPANIAS", "AP_LIQUIDACIONES", "AP_PAGOS" -> "Estado";
            case "REC_MOVIMIENTOS", "REC_PRODUCTOS" -> "Naturaleza";
            case "DOC_EVIDENCIAS" -> "Formato";
            case "DOC_CORRESPONDENCIA" -> "Tipo";
            case "AP_SOCIOS" -> "Situacion";
            case "AP_COMPRADORES" -> "Tipo";
            default -> null;
        };
    }

    private int width(String name) {
        String key = normalize(name);
        boolean compact = totalColumns >= 7;
        if (key.contains("observ") || key.contains("resumen") || key.contains("descripcion")
                || key.contains("recomend") || key.contains("objetivo") || key.contains("asunto"))
            return compact ? 6800 : 9900;
        if (key.contains("producto") || key.contains("nombre") || key.contains("predio")
                || key.contains("campania") || key.contains("referencia"))
            return compact ? 7500 : 9000;
        if (key.contains("fecha") || key.contains("inicio") || key.contains("retorno")
                || key.contains("deteccion") || key.contains("registro") || key.contains("programada")) return 4700;
        if (key.contains("codigo") || key.contains("calidad")) return 5200;
        if (key.contains("cantidad") || key.endsWith("id") || key.equals("venta")) return 3300;
        if (isMoney(name)) return 4400;
        return compact ? 4300 : Math.min(6400, Math.max(3800, name.length() * 230 + 2100));
    }

    private String friendlyName(String source) {
        String prepared = source.replaceAll("([a-záéíóúñ])([A-Z])", "$1 $2")
                .replace("Kg", " (kg)");
        return prepared.replace("Id", " ID");
    }

    private static String normalize(String input) {
        String normalized = java.text.Normalizer.normalize(input, java.text.Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "");
        return normalized.replaceAll("[^a-zA-Z0-9]", "").toLowerCase(Locale.ROOT);
    }

    private Object read(ResultSet rs, String name) throws SQLException {
        Integer index = columnIndices.get(normalize(name));
        return index == null ? null : rs.getObject(index);
    }

    private BigDecimal number(Object object) {
        if (!(object instanceof Number value)) return BigDecimal.ZERO;
        return value instanceof BigDecimal decimalValue ? decimalValue : new BigDecimal(value.toString());
    }

    public void row(ResultSet rs, int position) throws SQLException {
        totalRows = position;
        Row excelRow = detail.createRow(position + 4);
        excelRow.setHeightInPoints(23);
        for (int col = 1; col <= totalColumns; col++) {
            Object raw = rs.getObject(col);
            if (raw == null) continue;
            Cell cell = excelRow.createCell(col - 1);
            String name = columnLabels[col - 1];
            int stripe = position % 2;
            if (raw instanceof Timestamp dateTime) {
                cell.setCellValue(dateTime.toLocalDateTime());
                cell.setCellStyle(datetimeRows[stripe]);
            } else if (raw instanceof java.sql.Date sqlDate) {
                cell.setCellValue(sqlDate.toLocalDate());
                cell.setCellStyle(dateRows[stripe]);
            } else if (raw instanceof LocalDateTime dateTime) {
                cell.setCellValue(dateTime);
                cell.setCellStyle(datetimeRows[stripe]);
            } else if (raw instanceof LocalDate localDate) {
                cell.setCellValue(localDate);
                cell.setCellStyle(dateRows[stripe]);
            } else if (raw instanceof Number n) {
                String digits = n.toString();
                if (digits.matches("[0-9]{16,}")) {
                    cell.setCellValue(digits);
                    cell.setCellStyle(textRows[stripe]);
                } else {
                    cell.setCellValue(n.doubleValue());
                    if (isMoney(name)) cell.setCellStyle(currencyRows[stripe]);
                    else if (n.doubleValue() == Math.rint(n.doubleValue())) {
                        cell.setCellStyle(wholeRows[stripe]);
                    } else cell.setCellStyle(numberRows[stripe]);
                }
            } else {
                String content = String.valueOf(raw);
                if (!content.isEmpty() && "=+-@\t\r\n".indexOf(content.charAt(0)) >= 0) content = "'" + content;
                cell.setCellValue(content.length() > 32767 ? content.substring(0, 32767) : content);
                cell.setCellStyle(textRows[stripe]);
                if (content.length() > 95) excelRow.setHeightInPoints(48);
                else if (content.length() > 35 && excelRow.getHeightInPoints() < 36)
                    excelRow.setHeightInPoints(36);
            }
        }
        accumulate(rs);
    }

    private boolean isMoney(String name) {
        return Set.of("total", "importe", "subtotal", "descuento", "preciounitario", "descuentounitario",
                "impuesto", "costo", "costounitario", "bruto", "neto", "ajustes", "gastos",
                "bonificaciones").contains(normalize(name));
    }

    private void sum(ResultSet rs, String name) throws SQLException {
        Object raw = read(rs, name);
        if (raw instanceof Number) sums.merge(normalize(name), number(raw), BigDecimal::add);
    }

    private void unique(ResultSet rs, String name) throws SQLException {
        Object raw = read(rs, name);
        if (raw != null && !String.valueOf(raw).isBlank())
            distinct.computeIfAbsent(normalize(name), k -> new HashSet<>()).add(String.valueOf(raw));
    }

    private void accumulate(ResultSet rs) throws SQLException {
        switch (code) {
            case "POS_VENTAS" -> {
                for (String field : List.of("Subtotal", "Descuento", "Impuesto", "Total")) sum(rs, field);
            }
            case "POS_DETALLE" -> {
                sum(rs, "Cantidad"); sum(rs, "Importe"); unique(rs, "Venta"); unique(rs, "Código");
                Object product = read(rs, "Producto");
                Object productCode = read(rs, "Código");
                if (product != null) {
                    String key = productCode == null ? String.valueOf(product) : String.valueOf(productCode);
                    ProductSummary summary = products.computeIfAbsent(key,
                            k -> new ProductSummary(key, String.valueOf(product)));
                    summary.quantity = summary.quantity.add(number(read(rs, "Cantidad")));
                    summary.amount = summary.amount.add(number(read(rs, "Importe")));
                }
            }
            case "TEC_VISITAS" -> unique(rs, "Predio");
            case "TEC_SANIDAD" -> { sum(rs, "Plantas afectadas"); unique(rs, "Predio"); }
            case "REC_PRODUCTOS" -> unique(rs, "Código");
            case "DOC_EVIDENCIAS" -> { sum(rs, "Tamaño bytes"); unique(rs, "Categoría"); }
            case "DOC_CORRESPONDENCIA" -> sum(rs, "Destinatarios");
            case "AP_PREDIOS" -> unique(rs, "Distrito");
            case "AP_VENTAS" -> {
                for (String field : List.of("PesoBrutoKg", "RechazadoKg", "AceptadoKg")) sum(rs, field);
            }
            case "AP_LIQUIDACIONES" -> {
                for (String field : List.of("Bruto", "Ajustes", "Gastos", "Bonificaciones", "Neto")) sum(rs, field);
            }
            case "AP_PAGOS" -> sum(rs, "Importe");
            default -> { }
        }
        if (groupField != null) {
            Object group = read(rs, groupField);
            if (group != null && !String.valueOf(group).isBlank())
                groups.merge(String.valueOf(group), 1L, Long::sum);
        }
    }

    private void metric(int rowNumber, int col, String name, BigDecimal amount, boolean monetary) {
        Row row = summary.getRow(rowNumber);
        if (row == null) row = summary.createRow(rowNumber);
        row.setHeightInPoints(29);
        for (int c = col; c < col + 3; c++) row.createCell(c).setCellStyle(label);
        row.getCell(col).setCellValue(name);
        summary.addMergedRegion(new CellRangeAddress(rowNumber, rowNumber, col, col + 2));
        Cell number = row.createCell(col + 3);
        number.setCellValue(amount.doubleValue());
        number.setCellStyle(monetary ? currency : amount.stripTrailingZeros().scale() > 0 ? decimal : integer);
    }

    private record Indicator(String label, BigDecimal total, boolean money) { }
    private Indicator metric(String name, int n) { return new Indicator(name, BigDecimal.valueOf(n), false); }
    private Indicator total(String name, String key, boolean money) {
        if (!columnIndices.containsKey(normalize(key))) return null;
        return new Indicator(name, sums.getOrDefault(normalize(key), BigDecimal.ZERO), money);
    }
    private Indicator uniqueMetric(String name, String key) {
        if (!columnIndices.containsKey(normalize(key))) return null;
        return metric(name, distinct.getOrDefault(normalize(key), Set.of()).size());
    }

    private List<Indicator> indicators() {
        List<Indicator> metrics = new ArrayList<>();
        metrics.add(metric(switch (code) {
            case "POS_DETALLE", "REC_PRODUCTOS" -> "Líneas de detalle";
            case "POS_VENTAS" -> "Ventas registradas";
            case "TEC_VISITAS" -> "Visitas registradas";
            case "TEC_SALIDAS" -> "Salidas registradas";
            case "TEC_SANIDAD" -> "Casos registrados";
            case "DOC_EVIDENCIAS" -> "Archivos registrados";
            case "DOC_CORRESPONDENCIA" -> "Documentos registrados";
            case "AP_VENTAS" -> "Entregas registradas";
            default -> "Registros del período";
        }, totalRows));
        switch (code) {
            case "POS_VENTAS" -> {
                metrics.add(total("Importe total (S/)", "Total", true));
                metrics.add(total("Subtotal (S/)", "Subtotal", true));
                metrics.add(total("Descuentos (S/)", "Descuento", true));
            }
            case "POS_DETALLE" -> {
                metrics.add(total("Unidades registradas", "Cantidad", false));
                metrics.add(total("Importe de líneas (S/)", "Importe", true));
                metrics.add(uniqueMetric("Ventas diferentes", "Venta"));
                metrics.add(uniqueMetric("Productos diferentes", "Código"));
            }
            case "TEC_VISITAS" -> metrics.add(uniqueMetric("Predios visitados", "Predio"));
            case "TEC_SANIDAD" -> {
                metrics.add(total("Plantas afectadas", "Plantas afectadas", false));
                metrics.add(uniqueMetric("Predios con casos", "Predio"));
            }
            case "REC_PRODUCTOS" -> metrics.add(uniqueMetric("Productos diferentes", "Código"));
            case "DOC_EVIDENCIAS" -> {
                BigDecimal bytes = sums.get("tamanobytes");
                if (bytes != null) metrics.add(new Indicator("Volumen de archivos (MB)",
                        bytes.divide(BigDecimal.valueOf(1024 * 1024), 2, java.math.RoundingMode.HALF_UP), false));
                metrics.add(uniqueMetric("Categorías utilizadas", "Categoría"));
            }
            case "DOC_CORRESPONDENCIA" -> metrics.add(total("Destinatarios consignados", "Destinatarios", false));
            case "AP_PREDIOS" -> metrics.add(uniqueMetric("Distritos representados", "Distrito"));
            case "AP_VENTAS" -> {
                metrics.add(total("Peso aceptado (kg)", "AceptadoKg", false));
                metrics.add(total("Peso rechazado (kg)", "RechazadoKg", false));
                metrics.add(total("Peso bruto (kg)", "PesoBrutoKg", false));
            }
            case "AP_LIQUIDACIONES" -> {
                metrics.add(total("Neto registrado", "Neto", true));
                metrics.add(total("Bruto registrado", "Bruto", true));
                metrics.add(total("Ajustes registrados", "Ajustes", true));
            }
            case "AP_PAGOS" -> metrics.add(total("Importe registrado", "Importe", true));
            default -> { }
        }
        metrics.removeIf(java.util.Objects::isNull);
        return metrics;
    }

    public void finish() {
        field(8, "Registros", String.format(Locale.forLanguageTag("es-PE"), "%,d", totalRows));
        titleRow(summary, 10, 0, 7, "INDICADORES", sectionCaption, 25);
        List<Indicator> metrics = indicators();
        int max = Math.min(8, metrics.size());
        for (int i = 0; i < max; i++) {
            Indicator indicator = metrics.get(i);
            metric(12 + i / 2, (i % 2) * 4,
                    indicator.label(), indicator.total(), indicator.money());
        }
        if (totalRows == 0) {
            titleRow(summary, 14 + (max + 1) / 2, 0, 7,
                    "No hay registros para el período seleccionado.", value, 25);
            if (totalColumns > 0)
                titleRow(detail, 5, 0, Math.min(7, totalColumns - 1),
                        "No hay registros para el período seleccionado.", value, 25);
        } else if (!groups.isEmpty()) createDistribution();
        if ("POS_DETALLE".equals(code) && !products.isEmpty()) createProducts();
    }

    private void createDistribution() {
        Sheet distribution = book.createSheet("Distribución");
        distribution.setDisplayGridlines(false);
        distribution.setZoom(95);
        distribution.setColumnWidth(0, 7700);
        distribution.setColumnWidth(1, 4300);
        titleRow(distribution, 0, 0, 1, "Registros por " + groupField.toLowerCase(Locale.ROOT), subtitle, 34);
        Row headers = distribution.createRow(2);
        headers.setHeightInPoints(27);
        for (int i = 0; i < 2; i++) headers.createCell(i).setCellStyle(section);
        headers.getCell(0).setCellValue(groupField);
        headers.getCell(1).setCellValue("Registros");
        List<Map.Entry<String, Long>> sorted = groups.entrySet().stream()
                .sorted(Comparator.<Map.Entry<String, Long>>comparingLong(Map.Entry::getValue).reversed()
                        .thenComparing(Map.Entry::getKey)).toList();
        int index = 3;
        for (Map.Entry<String, Long> item : sorted) {
            Row row = distribution.createRow(index++);
            row.setHeightInPoints(23);
            row.createCell(0).setCellValue(item.getKey());
            row.createCell(1).setCellValue(item.getValue());
            row.getCell(0).setCellStyle(textRows[index % 2]);
            row.getCell(1).setCellStyle(wholeRows[index % 2]);
        }
        configurePrint(distribution, false);
    }

    private void createProducts() {
        Sheet productSheet = book.createSheet("Por producto");
        productSheet.setDisplayGridlines(false);
        productSheet.setZoom(95);
        productSheet.setColumnWidth(0, 5600);
        productSheet.setColumnWidth(1, 8100);
        productSheet.setColumnWidth(2, 3700);
        productSheet.setColumnWidth(3, 5000);
        titleRow(productSheet, 0, 0, 3, "Ventas por producto", subtitle, 34);
        Row head = productSheet.createRow(2);
        head.setHeightInPoints(28);
        for (int i = 0; i < 4; i++) head.createCell(i).setCellStyle(section);
        head.getCell(0).setCellValue("Código");
        head.getCell(1).setCellValue("Producto");
        head.getCell(2).setCellValue("Cantidad");
        head.getCell(3).setCellValue("Importe (S/)");
        List<ProductSummary> sorted = products.values().stream()
                .sorted(Comparator.<ProductSummary, BigDecimal>comparing(p -> p.amount).reversed()
                        .thenComparing(p -> p.code)).toList();
        int line = 3;
        for (ProductSummary product : sorted) {
            Row row = productSheet.createRow(line++);
            row.setHeightInPoints(product.name.length() > 42 ? 34 : 23);
            row.createCell(0).setCellValue(product.code);
            row.createCell(1).setCellValue(product.name);
            row.createCell(2).setCellValue(product.quantity.doubleValue());
            row.createCell(3).setCellValue(product.amount.doubleValue());
            for (int i = 0; i < 2; i++) row.getCell(i).setCellStyle(textRows[line % 2]);
            row.getCell(2).setCellStyle(product.quantity.stripTrailingZeros().scale() > 0
                    ? numberRows[line % 2] : wholeRows[line % 2]);
            row.getCell(3).setCellStyle(currencyRows[line % 2]);
        }
        configurePrint(productSheet, true);
    }

    public static String reportTitle(String code) {
        return switch (code) {
            case "POS_VENTAS" -> "Ventas realizadas";
            case "POS_DETALLE" -> "Detalle de productos vendidos";
            case "TEC_VISITAS" -> "Visitas técnicas";
            case "TEC_SALIDAS" -> "Salidas de campo";
            case "TEC_SANIDAD" -> "Casos fitosanitarios";
            case "REC_MOVIMIENTOS" -> "Movimientos de inventario";
            case "REC_PRODUCTOS" -> "Movimientos por producto";
            case "DOC_EVIDENCIAS" -> "Evidencias registradas";
            case "DOC_CORRESPONDENCIA" -> "Correspondencia interna";
            case "AP_SOCIOS" -> "Padrón de socios";
            case "AP_PREDIOS" -> "Predios registrados";
            case "AP_CAMPANIAS" -> "Campañas comerciales";
            case "AP_VENTAS" -> "Entregas de producción";
            case "AP_COMPRADORES" -> "Compradores registrados";
            case "AP_LIQUIDACIONES" -> "Liquidaciones de socios";
            case "AP_PAGOS" -> "Pagos de socios";
            default -> "Reporte de gestión";
        };
    }
}
