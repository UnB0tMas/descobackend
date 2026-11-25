package com.franco.desco.application.report.port.out;

import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;

import java.util.List;

public interface TemporaryReportPort {
    PersistenceResult<String> confirm(String type, long id, SessionIdentity identity, RequestMetadata metadata);
    List<String> purgeExpired(int batchSize);
}
