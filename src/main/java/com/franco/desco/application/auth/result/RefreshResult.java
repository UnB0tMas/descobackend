package com.franco.desco.application.auth.result;

import com.franco.desco.domain.auth.AccessContext;

public record RefreshResult(
        TokenSet tokens,
        AccessContext contexto
) {
}
