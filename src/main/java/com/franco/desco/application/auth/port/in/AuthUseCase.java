package com.franco.desco.application.auth.port.in;

import com.franco.desco.application.auth.command.*;
import com.franco.desco.application.auth.result.*;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.auth.AccessContext;

public interface AuthUseCase {

    AppResult<LoginResult> login(
            LoginCommand command,
            RequestMetadata metadata
    );

    AppResult<AuthChallenge> requestTwoFactor(
            RequestTwoFactorCommand command,
            RequestMetadata metadata
    );

    AppResult<LoginResult> verifyTwoFactor(
            VerifyTwoFactorCommand command,
            RequestMetadata metadata
    );

    AppResult<Void> requestEmailVerification(
            RequestEmailVerificationCommand command,
            RequestMetadata metadata
    );

    AppResult<Void> confirmEmailVerification(
            ConfirmEmailCommand command,
            RequestMetadata metadata
    );

    AppResult<Void> requestPasswordRecovery(
            PasswordRecoveryCommand command,
            RequestMetadata metadata
    );

    AppResult<Void> resetPassword(
            PasswordResetCommand command,
            RequestMetadata metadata
    );

    AppResult<RefreshResult> refresh(
            RefreshCommand command,
            RequestMetadata metadata
    );

    AppResult<AccessContext> me(SessionIdentity identity);

    AppResult<Void> logout(
            SessionIdentity identity,
            RequestMetadata metadata
    );

    AppResult<Void> logoutOthers(
            SessionIdentity identity,
            RequestMetadata metadata
    );
}
