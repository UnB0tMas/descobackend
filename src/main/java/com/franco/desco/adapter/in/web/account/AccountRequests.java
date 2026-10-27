package com.franco.desco.adapter.in.web.account;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import java.util.UUID;

public final class AccountRequests {
    private AccountRequests() {}

    @Schema(name = "CloseAccountSessionRequest")
    public record CloseSession(
            @NotNull @Schema(format = "uuid") UUID sesionPublicaId
    ) {}

    @Schema(name = "DeviceRecognitionRequest")
    public record DeviceRecognition(
            @NotNull Long dispositivoUsuarioId,
            @NotNull Boolean reconocer
    ) {}

    @Schema(name = "ChangeOwnPasswordRequest")
    public record ChangePassword(
            @NotBlank @Schema(format = "password", accessMode = Schema.AccessMode.WRITE_ONLY) String passwordActual,
            @NotBlank @Size(min = 12, max = 128) @Schema(format = "password", accessMode = Schema.AccessMode.WRITE_ONLY) String nuevoPassword,
            @NotBlank @Size(min = 12, max = 128) @Schema(format = "password", accessMode = Schema.AccessMode.WRITE_ONLY) String confirmarPassword
    ) {}

    @Schema(name = "RequestOwnEmailChangeRequest")
    public record RequestEmailChange(
            @NotBlank @Email @Size(max = 320) String nuevoCorreo
    ) {}

    @Schema(name = "ConfirmOwnEmailChangeRequest")
    public record ConfirmEmailChange(
            @NotBlank @Pattern(regexp = "\\d{6,8}") @Schema(accessMode = Schema.AccessMode.WRITE_ONLY) String codigo
    ) {}
}
