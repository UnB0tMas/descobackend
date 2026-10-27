package com.franco.desco.application.account.port.in;

import com.franco.desco.application.account.AccountCommands.*;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.account.AccountModels;

import java.util.List;

public interface AccountUseCase {
    AppResult<List<AccountModels.SessionInfo>> sessions(SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> closeSession(CloseSession command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> closeOtherSessions(SessionIdentity identity, RequestMetadata metadata);
    AppResult<List<AccountModels.DeviceInfo>> devices(SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> recognizeDevice(DeviceRecognition command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> changePassword(ChangePassword command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> requestEmailChange(RequestEmailChange command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> confirmEmailChange(ConfirmEmailChange command, SessionIdentity identity, RequestMetadata metadata);
}
