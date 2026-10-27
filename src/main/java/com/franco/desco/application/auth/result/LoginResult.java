package com.franco.desco.application.auth.result;

import com.franco.desco.domain.auth.AccessContext;

public record LoginResult(
        AuthStep paso,
        TokenSet tokens,
        AccessContext contexto,
        AuthChallenge desafio
) {
}
