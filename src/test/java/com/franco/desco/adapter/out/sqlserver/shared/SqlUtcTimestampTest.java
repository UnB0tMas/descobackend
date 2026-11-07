package com.franco.desco.adapter.out.sqlserver.shared;

import org.junit.jupiter.api.Test;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.Map;
import java.util.TimeZone;
import static org.junit.jupiter.api.Assertions.assertEquals;

class SqlUtcTimestampTest {
    @Test
    void datetime2UtcDoesNotDependOnServerTimeZone() {
        TimeZone previous = TimeZone.getDefault();
        try {
            for (String zone : new String[]{"America/Lima", "UTC", "Asia/Tokyo"}) {
                TimeZone.setDefault(TimeZone.getTimeZone(zone));
                Timestamp value = Timestamp.valueOf("2026-11-06 17:13:38.123");
                Instant expected = Instant.parse("2026-11-06T17:13:38.123Z");
                assertEquals(expected, SqlValues.normalizeJdbcValue(value), zone);
                assertEquals(expected, PaResultSets.instant(Map.of("fecha", value), "fecha"), zone);
            }
        } finally {
            TimeZone.setDefault(previous);
        }
    }
}
