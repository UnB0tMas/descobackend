package com.franco.desco.application.account.port.out;

import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.account.AccountModels;

import java.util.List;

public interface AccountPersistencePort {
    PersistenceResult<List<AccountModels.SessionInfo>> sessions(SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> closeSession(SessionIdentity identity, RequestMetadata metadata, java.util.UUID targetSession);
    PersistenceResult<Void> closeOtherSessions(SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<List<AccountModels.DeviceInfo>> devices(SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> recognizeDevice(SessionIdentity identity, RequestMetadata metadata, Long deviceId, String action);
    PersistenceResult<String> currentPasswordHash(SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> changePassword(SessionIdentity identity, RequestMetadata metadata, String newPasswordHash);
    PersistenceResult<AccountModels.EmailChangeIssue> requestEmailChange(SessionIdentity identity, RequestMetadata metadata, String newEmail, String codeHmacHex);
    PersistenceResult<Void> confirmEmailChange(SessionIdentity identity, RequestMetadata metadata, String codeHmacHex);
}
