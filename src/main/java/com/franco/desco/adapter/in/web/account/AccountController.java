package com.franco.desco.adapter.in.web.account;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.account.port.in.AccountUseCase;
import io.swagger.v3.oas.annotations.*;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/account")
@Tag(name = "Mi cuenta", description = "Seguridad, sesiones y dispositivos de la cuenta autenticada.")
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
public class AccountController {

    private final AccountUseCase useCase;
    private final AccountWebMapper mapper;
    private final ApiResponseFactory responses;
    private final ClientRequestContextResolver metadata;
    private final JwtSessionIdentityResolver identities;

    public AccountController(AccountUseCase useCase, AccountWebMapper mapper, ApiResponseFactory responses,
                             ClientRequestContextResolver metadata, JwtSessionIdentityResolver identities) {
        this.useCase = useCase;
        this.mapper = mapper;
        this.responses = responses;
        this.metadata = metadata;
        this.identities = identities;
    }

    @GetMapping("/sessions")
    @Operation(operationId = "accountSessionsList", summary = "Listar sesiones propias")
    public ResponseEntity<ApiResponse<List<AccountResponses.Session>>> sessions(
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.sessions(identities.resolve(authentication), metadata.resolve(request)),
                request,
                list -> list.stream().map(mapper::response).toList()
        );
    }

    @PostMapping("/sessions/close")
    @Operation(operationId = "accountSessionClose", summary = "Cerrar una sesión propia")
    public ResponseEntity<ApiResponse<Void>> closeSession(
            @Valid @RequestBody AccountRequests.CloseSession body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.closeSession(mapper.command(body), identities.resolve(authentication), metadata.resolve(request)),
                request
        );
    }

    @PostMapping("/sessions/close-others")
    @Operation(operationId = "accountSessionsCloseOthers", summary = "Cerrar las demás sesiones propias")
    public ResponseEntity<ApiResponse<Void>> closeOtherSessions(
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(useCase.closeOtherSessions(identities.resolve(authentication), metadata.resolve(request)), request);
    }

    @GetMapping("/devices")
    @Operation(operationId = "accountDevicesList", summary = "Listar dispositivos propios")
    public ResponseEntity<ApiResponse<List<AccountResponses.Device>>> devices(
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.devices(identities.resolve(authentication), metadata.resolve(request)),
                request,
                list -> list.stream().map(mapper::response).toList()
        );
    }

    @PutMapping("/devices/recognition")
    @Operation(operationId = "accountDeviceRecognitionUpdate", summary = "Reconocer o quitar reconocimiento de un dispositivo propio")
    public ResponseEntity<ApiResponse<Void>> updateRecognition(
            @Valid @RequestBody AccountRequests.DeviceRecognition body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.recognizeDevice(mapper.command(body), identities.resolve(authentication), metadata.resolve(request)),
                request
        );
    }

    @PutMapping("/security/password")
    @Operation(operationId = "accountPasswordChange", summary = "Cambiar contraseña propia")
    public ResponseEntity<ApiResponse<Void>> changePassword(
            @Valid @RequestBody AccountRequests.ChangePassword body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.changePassword(mapper.command(body), identities.resolve(authentication), metadata.resolve(request)),
                request
        );
    }

    @PostMapping("/security/email-change/request")
    @Operation(operationId = "accountEmailChangeRequest", summary = "Solicitar cambio del correo de seguridad")
    public ResponseEntity<ApiResponse<Void>> requestEmailChange(
            @Valid @RequestBody AccountRequests.RequestEmailChange body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.requestEmailChange(mapper.command(body), identities.resolve(authentication), metadata.resolve(request)),
                request
        );
    }

    @PostMapping("/security/email-change/confirm")
    @Operation(operationId = "accountEmailChangeConfirm", summary = "Confirmar cambio del correo de seguridad")
    public ResponseEntity<ApiResponse<Void>> confirmEmailChange(
            @Valid @RequestBody AccountRequests.ConfirmEmailChange body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.confirmEmailChange(mapper.command(body), identities.resolve(authentication), metadata.resolve(request)),
                request
        );
    }
}
