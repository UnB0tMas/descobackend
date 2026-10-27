package com.franco.desco.adapter.in.web.auth;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.auth.dto.request.EmailVerificationConfirmRequest;
import com.franco.desco.adapter.in.web.auth.dto.request.EmailVerificationRequest;
import com.franco.desco.adapter.in.web.auth.dto.request.LoginRequest;
import com.franco.desco.adapter.in.web.auth.dto.request.PasswordRecoveryRequest;
import com.franco.desco.adapter.in.web.auth.dto.request.PasswordResetRequest;
import com.franco.desco.adapter.in.web.auth.dto.request.RefreshTokenRequest;
import com.franco.desco.adapter.in.web.auth.dto.request.TwoFactorRequest;
import com.franco.desco.adapter.in.web.auth.dto.request.TwoFactorVerifyRequest;
import com.franco.desco.adapter.in.web.auth.dto.response.AuthChallengeResponse;
import com.franco.desco.adapter.in.web.auth.dto.response.AuthContextResponse;
import com.franco.desco.adapter.in.web.auth.dto.response.LoginResponse;
import com.franco.desco.adapter.in.web.auth.dto.response.RefreshResponse;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.adapter.in.web.common.ClientRequestContextResolver;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.auth.port.in.AuthUseCase;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping(
        value = "/api/v1/auth",
        produces = MediaType.APPLICATION_JSON_VALUE
)
@Tag(
        name = OpenApiConstants.TAG_AUTH,
        description = OpenApiConstants.TAG_AUTH_DESCRIPTION
)
public class AuthController {

    private final AuthUseCase authUseCase;
    private final AuthWebMapper mapper;
    private final ApiResponseFactory responseFactory;
    private final ClientRequestContextResolver contextResolver;
    private final JwtSessionIdentityResolver identityResolver;

    public AuthController(
            AuthUseCase authUseCase,
            AuthWebMapper mapper,
            ApiResponseFactory responseFactory,
            ClientRequestContextResolver contextResolver,
            JwtSessionIdentityResolver identityResolver
    ) {
        this.authUseCase = authUseCase;
        this.mapper = mapper;
        this.responseFactory = responseFactory;
        this.contextResolver = contextResolver;
        this.identityResolver = identityResolver;
    }

    @Operation(
            operationId = OpenApiConstants.AUTH_LOGIN,
            summary = "Iniciar sesión",
            description = """
                    Valida el nombre de usuario y la contraseña.

                    La respuesta puede:
                    - completar el login y devolver tokens + contexto;
                    - indicar que debe verificarse el correo;
                    - indicar que debe completarse segundo factor.

                    La contraseña se verifica con Argon2id en el backend.
                    """
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "400",
                    description = "La solicitud contiene información no válida.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "401",
                    description = "Las credenciales no son válidas o el acceso no puede continuar.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "503",
                    description = "El servicio no está disponible temporalmente.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "500",
                    description = "La solicitud no pudo procesarse.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            )
    })
    @PostMapping(
            value = "/login",
            consumes = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<ApiResponse<LoginResponse>> login(
            @Valid
            @RequestBody
            LoginRequest request,

            @Parameter(hidden = true)
            HttpServletRequest servletRequest
    ) {
        RequestMetadata metadata =
                contextResolver.resolve(
                        servletRequest
                );

        return responseFactory.from(
                authUseCase.login(
                        mapper.toCommand(request),
                        metadata
                ),
                servletRequest,
                mapper::toResponse
        );
    }

    @Operation(
            operationId = OpenApiConstants.AUTH_REQUEST_TWO_FACTOR,
            summary = "Solicitar código de segundo factor",
            description = """
                    Solicita un nuevo código de segundo factor para una autenticación iniciada previamente.

                    El código plano se envía por correo y nunca se almacena en SQL Server.
                    """
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "400",
                    description = "La solicitud no es válida.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "401",
                    description = "La solicitud de autenticación ya no es válida.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "503",
                    description = "El servicio no está disponible temporalmente.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            )
    })
    @PostMapping(
            value = "/2fa/request",
            consumes = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<ApiResponse<AuthChallengeResponse>> requestTwoFactor(
            @Valid
            @RequestBody
            TwoFactorRequest request,

            @Parameter(hidden = true)
            HttpServletRequest servletRequest
    ) {
        return responseFactory.from(
                authUseCase.requestTwoFactor(
                        mapper.toCommand(request),
                        contextResolver.resolve(
                                servletRequest
                        )
                ),
                servletRequest,
                mapper::toResponse
        );
    }

    @Operation(
            operationId = OpenApiConstants.AUTH_VERIFY_TWO_FACTOR,
            summary = "Validar segundo factor",
            description = """
                    Verifica el código de segundo factor recibido por correo.
                    Si la verificación es correcta, crea la sesión y devuelve los tokens junto con el contexto de acceso.
                    """
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "400",
                    description = "El código o la solicitud no son válidos.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "401",
                    description = "El código expiró, fue utilizado o no es válido.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "503",
                    description = "El servicio no está disponible temporalmente.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            )
    })
    @PostMapping(
            value = "/2fa/verify",
            consumes = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<ApiResponse<LoginResponse>> verifyTwoFactor(
            @Valid
            @RequestBody
            TwoFactorVerifyRequest request,

            @Parameter(hidden = true)
            HttpServletRequest servletRequest
    ) {
        return responseFactory.from(
                authUseCase.verifyTwoFactor(
                        mapper.toCommand(request),
                        contextResolver.resolve(
                                servletRequest
                        )
                ),
                servletRequest,
                mapper::toResponse
        );
    }

    @Operation(
            operationId = OpenApiConstants.AUTH_REQUEST_EMAIL_VERIFICATION,
            summary = "Solicitar verificación de correo",
            description = """
                    Solicita un código de verificación para el correo de seguridad asociado a la cuenta.

                    La respuesta funcional no debe revelar información innecesaria sobre la existencia de cuentas.
                    """
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "400",
                    description = "La solicitud contiene información no válida.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "503",
                    description = "El servicio no está disponible temporalmente.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            )
    })
    @PostMapping(
            value = "/email-verification/request",
            consumes = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<ApiResponse<Void>> requestEmailVerification(
            @Valid
            @RequestBody
            EmailVerificationRequest request,

            @Parameter(hidden = true)
            HttpServletRequest servletRequest
    ) {
        return responseFactory.from(
                authUseCase.requestEmailVerification(
                        mapper.toCommand(request),
                        contextResolver.resolve(
                                servletRequest
                        )
                ),
                servletRequest
        );
    }

    @Operation(
            operationId = OpenApiConstants.AUTH_CONFIRM_EMAIL_VERIFICATION,
            summary = "Confirmar verificación de correo",
            description = """
                    Confirma el correo de seguridad utilizando el código de un solo uso recibido por correo.
                    """
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "400",
                    description = "El código o la solicitud no son válidos.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "401",
                    description = "El código expiró, fue utilizado o no es válido.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "503",
                    description = "El servicio no está disponible temporalmente.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            )
    })
    @PostMapping(
            value = "/email-verification/confirm",
            consumes = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<ApiResponse<Void>> confirmEmailVerification(
            @Valid
            @RequestBody
            EmailVerificationConfirmRequest request,

            @Parameter(hidden = true)
            HttpServletRequest servletRequest
    ) {
        return responseFactory.from(
                authUseCase.confirmEmailVerification(
                        mapper.toCommand(request),
                        contextResolver.resolve(
                                servletRequest
                        )
                ),
                servletRequest
        );
    }

    @Operation(
            operationId = OpenApiConstants.AUTH_REQUEST_PASSWORD_RECOVERY,
            summary = "Solicitar recuperación de contraseña",
            description = """
                    Solicita el envío de un código de recuperación al correo de seguridad.

                    La respuesta inicial es general y no debe permitir deducir si una cuenta existe.
                    """
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "400",
                    description = "La solicitud contiene información no válida.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "503",
                    description = "El servicio no está disponible temporalmente.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            )
    })
    @PostMapping(
            value = "/password-recovery/request",
            consumes = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<ApiResponse<Void>> requestPasswordRecovery(
            @Valid
            @RequestBody
            PasswordRecoveryRequest request,

            @Parameter(hidden = true)
            HttpServletRequest servletRequest
    ) {
        return responseFactory.from(
                authUseCase.requestPasswordRecovery(
                        mapper.toCommand(request),
                        contextResolver.resolve(
                                servletRequest
                        )
                ),
                servletRequest
        );
    }

    @Operation(
            operationId = OpenApiConstants.AUTH_RESET_PASSWORD,
            summary = "Restablecer contraseña",
            description = """
                    Valida el código de recuperación y establece una nueva contraseña.

                    La contraseña nueva se convierte a Argon2id en el backend antes de enviarse al PA correspondiente.
                    Las sesiones anteriores deben quedar revocadas según la política de seguridad.
                    """
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "400",
                    description = "La solicitud, las contraseñas o el código no son válidos.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "401",
                    description = "El código de recuperación expiró, fue utilizado o no es válido.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "503",
                    description = "El servicio no está disponible temporalmente.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            )
    })
    @PostMapping(
            value = "/password-recovery/reset",
            consumes = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<ApiResponse<Void>> resetPassword(
            @Valid
            @RequestBody
            PasswordResetRequest request,

            @Parameter(hidden = true)
            HttpServletRequest servletRequest
    ) {
        return responseFactory.from(
                authUseCase.resetPassword(
                        mapper.toCommand(request),
                        contextResolver.resolve(
                                servletRequest
                        )
                ),
                servletRequest
        );
    }

    @Operation(
            operationId = OpenApiConstants.AUTH_REFRESH,
            summary = "Renovar sesión",
            description = """
                    Rota el refresh token y devuelve un nuevo access token y un nuevo refresh token.

                    El refresh token anterior deja de ser válido después de una rotación exitosa.
                    """
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "400",
                    description = "El refresh token no cumple el formato esperado.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "401",
                    description = "La sesión de renovación no es válida, expiró o fue revocada.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "503",
                    description = "El servicio no está disponible temporalmente.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            )
    })
    @PostMapping(
            value = "/refresh",
            consumes = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<ApiResponse<RefreshResponse>> refresh(
            @Valid
            @RequestBody
            RefreshTokenRequest request,

            @Parameter(hidden = true)
            HttpServletRequest servletRequest
    ) {
        return responseFactory.from(
                authUseCase.refresh(
                        mapper.toCommand(request),
                        contextResolver.resolve(
                                servletRequest
                        )
                ),
                servletRequest,
                mapper::toResponse
        );
    }

    @Operation(
            operationId = OpenApiConstants.AUTH_ME,
            summary = "Obtener contexto del usuario autenticado",
            description = """
                    Devuelve la identidad, roles, módulos y permisos efectivos correspondientes a la sesión autenticada.

                    Angular utiliza este contexto para construir el menú y ocultar o mostrar controles.
                    La autorización real siempre vuelve a validarse en el backend y en los PA.
                    """
    )
    @SecurityRequirement(
            name = OpenApiConstants.BEARER_AUTH
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "401",
                    description = "La sesión no es válida o expiró.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "403",
                    description = "La sesión no cuenta con autorización para acceder al recurso.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "503",
                    description = "El servicio no está disponible temporalmente.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            )
    })
    @GetMapping(
            value = "/me"
    )
    public ResponseEntity<ApiResponse<AuthContextResponse>> me(
            @Parameter(hidden = true)
            JwtAuthenticationToken authentication,

            @Parameter(hidden = true)
            HttpServletRequest servletRequest
    ) {
        SessionIdentity identity =
                identityResolver.resolve(
                        authentication
                );

        return responseFactory.from(
                authUseCase.me(identity),
                servletRequest,
                mapper::toResponse
        );
    }

    @Operation(
            operationId = OpenApiConstants.AUTH_LOGOUT,
            summary = "Cerrar sesión actual",
            description = """
                    Revoca la sesión actual en SQL Server.
                    El access token deja de ser aceptado aunque todavía no haya alcanzado su fecha de expiración.
                    """
    )
    @SecurityRequirement(
            name = OpenApiConstants.BEARER_AUTH
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "401",
                    description = "La sesión no es válida o expiró.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "503",
                    description = "El servicio no está disponible temporalmente.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            )
    })
    @PostMapping(
            value = "/logout"
    )
    public ResponseEntity<ApiResponse<Void>> logout(
            @Parameter(hidden = true)
            JwtAuthenticationToken authentication,

            @Parameter(hidden = true)
            HttpServletRequest servletRequest
    ) {
        SessionIdentity identity =
                identityResolver.resolve(
                        authentication
                );

        return responseFactory.from(
                authUseCase.logout(
                        identity,
                        contextResolver.resolve(
                                servletRequest
                        )
                ),
                servletRequest
        );
    }

    @Operation(
            operationId = OpenApiConstants.AUTH_LOGOUT_OTHERS,
            summary = "Cerrar las demás sesiones",
            description = """
                    Revoca todas las demás sesiones activas del usuario y mantiene vigente la sesión actual.
                    """
    )
    @SecurityRequirement(
            name = OpenApiConstants.BEARER_AUTH
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "401",
                    description = "La sesión no es válida o expiró.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "403",
                    description = "La operación no está autorizada.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "503",
                    description = "El servicio no está disponible temporalmente.",
                    content = @Content(
                            schema = @Schema(
                                    implementation = ApiResponse.class
                            )
                    )
            )
    })
    @PostMapping(
            value = "/logout-others"
    )
    public ResponseEntity<ApiResponse<Void>> logoutOthers(
            @Parameter(hidden = true)
            JwtAuthenticationToken authentication,

            @Parameter(hidden = true)
            HttpServletRequest servletRequest
    ) {
        SessionIdentity identity =
                identityResolver.resolve(
                        authentication
                );

        return responseFactory.from(
                authUseCase.logoutOthers(
                        identity,
                        contextResolver.resolve(
                                servletRequest
                        )
                ),
                servletRequest
        );
    }
}
