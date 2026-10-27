package com.franco.desco.adapter.in.web.auth;

import com.franco.desco.adapter.in.web.auth.dto.request.*;
import com.franco.desco.adapter.in.web.auth.dto.response.*;
import com.franco.desco.application.auth.command.*;
import com.franco.desco.application.auth.result.*;
import com.franco.desco.domain.auth.*;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;

@Component
public class AuthWebMapper {

    public LoginCommand toCommand(LoginRequest request) {
        return new LoginCommand(request.nombreUsuario(), request.password());
    }

    public RequestTwoFactorCommand toCommand(TwoFactorRequest request) {
        return new RequestTwoFactorCommand(request.usuarioId(), request.correlacionId());
    }

    public VerifyTwoFactorCommand toCommand(TwoFactorVerifyRequest request) {
        return new VerifyTwoFactorCommand(request.usuarioId(), request.codigo(), request.correlacionId());
    }

    public RequestEmailVerificationCommand toCommand(EmailVerificationRequest request) {
        return new RequestEmailVerificationCommand(request.nombreUsuario());
    }

    public ConfirmEmailCommand toCommand(EmailVerificationConfirmRequest request) {
        return new ConfirmEmailCommand(
                request.usuarioId(),
                request.nombreUsuario(),
                request.codigo(),
                request.correlacionId()
        );
    }

    public PasswordRecoveryCommand toCommand(PasswordRecoveryRequest request) {
        return new PasswordRecoveryCommand(request.nombreUsuario());
    }

    public PasswordResetCommand toCommand(PasswordResetRequest request) {
        return new PasswordResetCommand(
                request.nombreUsuario(),
                request.codigo(),
                request.nuevoPassword(),
                request.confirmarPassword()
        );
    }

    public RefreshCommand toCommand(RefreshTokenRequest request) {
        return new RefreshCommand(request.refreshToken());
    }

    public LoginResponse toResponse(LoginResult result) {
        return new LoginResponse(
                result.paso().name(),
                toResponse(result.tokens()),
                toResponse(result.contexto()),
                toResponse(result.desafio())
        );
    }

    public RefreshResponse toResponse(RefreshResult result) {
        return new RefreshResponse(
                toResponse(result.tokens()),
                toResponse(result.contexto())
        );
    }

    public AuthChallengeResponse toResponse(AuthChallenge challenge) {
        if (challenge == null) {
            return null;
        }
        return new AuthChallengeResponse(
                challenge.paso().name(),
                challenge.usuarioId(),
                challenge.nombreUsuario(),
                challenge.correlacionId(),
                challenge.correoEnmascarado()
        );
    }

    public TokenResponse toResponse(TokenSet token) {
        if (token == null) {
            return null;
        }
        return new TokenResponse(
                token.accessToken(),
                token.tokenType(),
                token.accessTokenExpiraUtc(),
                token.refreshToken(),
                token.refreshTokenExpiraUtc(),
                token.sesionPublicaId()
        );
    }

    public AuthContextResponse toResponse(AccessContext context) {
        if (context == null) {
            return null;
        }

        Map<Integer, String> moduleCodes = effectiveModuleCodes(context);

        return new AuthContextResponse(
                toResponse(context.usuario()),
                context.roles().stream().map(this::toResponse).toList(),
                context.modulos().stream()
                        .map(module -> toResponse(module, moduleCodes))
                        .toList(),
                context.permisos().stream().map(this::toResponse).toList()
        );
    }

    private UserAccessResponse toResponse(AccessUser user) {
        return new UserAccessResponse(
                user.usuarioId(), user.nombreUsuario(), user.estadoCuenta(),
                user.ultimoAccesoCorrectoUtc(), user.requiereCambioPassword(),
                user.segundoFactorHabilitado(), user.tokenVersion(), user.personaId(),
                user.tipoDocumento(), user.numeroDocumento(), user.nombres(),
                user.apellidoPaterno(), user.apellidoMaterno(), user.nombreCompleto(),
                user.telefono(), user.codigoEmpleado(), user.empresaId(),
                user.correoSeguridad(), user.correoSeguridadVerificado(),
                user.sesionPublicaId(), user.fechaSesionUtc(),
                user.fechaExpiracionRenovacionUtc(), user.dispositivoUsuarioId(),
                user.navegador(), user.sistemaOperativo(), user.dispositivoReconocido()
        );
    }

    private RoleAccessResponse toResponse(AccessRole role) {
        String code = text(role.codigo());
        String name = text(role.nombre());

        return new RoleAccessResponse(
                role.rolId(),
                code != null ? code : fallbackRoleCode(role.rolId()),
                name != null ? name : "Perfil de acceso",
                role.descripcion(),
                role.requiereSegundoFactor()
        );
    }

    private ModuleAccessResponse toResponse(
            AccessModule module,
            Map<Integer, String> moduleCodes
    ) {
        String code = text(module.codigo());
        if (code == null && module.moduloId() != null) {
            code = moduleCodes.get(module.moduloId());
        }

        String name = text(module.nombre());
        if (name == null) {
            name = humanize(code);
        }

        return new ModuleAccessResponse(
                module.moduloId(), module.moduloPadreId(), code, name,
                module.orden(), module.ruta(), module.icono(),
                module.visibleMenu(), module.esGrupo()
        );
    }

    private PermissionAccessResponse toResponse(AccessPermission permission) {
        String code = permissionCode(permission);
        String name = text(permission.nombre());

        return new PermissionAccessResponse(
                permission.permisoId(),
                permission.moduloId(),
                text(permission.codigoModulo()),
                code,
                name != null ? name : humanize(code),
                permission.descripcion(),
                permission.accion(),
                permission.sensible(),
                permission.requiereMotivo()
        );
    }

    private Map<Integer, String> effectiveModuleCodes(AccessContext context) {
        Map<Integer, String> result = new LinkedHashMap<>();

        for (AccessModule module : context.modulos()) {
            if (module.moduloId() != null && text(module.codigo()) != null) {
                result.put(module.moduloId(), normalize(module.codigo()));
            }
        }

        for (AccessPermission permission : context.permisos()) {
            String moduleCode = text(permission.codigoModulo());
            if (permission.moduloId() != null && moduleCode != null) {
                result.putIfAbsent(permission.moduloId(), normalize(moduleCode));
            }
        }

        return result;
    }

    private String permissionCode(AccessPermission permission) {
        String stored = text(permission.codigo());
        if (stored != null) {
            return normalize(stored);
        }

        String module = text(permission.codigoModulo());
        String action = text(permission.accion());
        if (module == null || action == null) {
            return stored;
        }

        module = normalize(module);
        action = normalize(action);

        if ("VALIDACION_IDENTIDAD".equals(module)) {
            return switch (action) {
                case "VER" -> "VALIDACIONIDENTIDAD_CONSULTAR";
                case "CREAR" -> "VALIDACIONIDENTIDAD_IMPORTAR";
                case "EDITAR" -> "VALIDACIONIDENTIDAD_EDITAR";
                default -> module + "_" + action;
            };
        }

        return module + "_" + action;
    }

    private String fallbackRoleCode(Long roleId) {
        return roleId == null ? "ROL" : "ROL_" + roleId;
    }

    private String humanize(String value) {
        String normalized = text(value);
        if (normalized == null) {
            return "Acceso";
        }

        String[] words = normalized.toLowerCase(Locale.ROOT).split("_+");
        StringBuilder result = new StringBuilder();
        for (String word : words) {
            if (word.isBlank()) {
                continue;
            }
            if (!result.isEmpty()) {
                result.append(' ');
            }
            result.append(Character.toUpperCase(word.charAt(0)))
                    .append(word.substring(1));
        }
        return result.isEmpty() ? "Acceso" : result.toString();
    }

    private String text(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private String normalize(String value) {
        return value.trim().toUpperCase(Locale.ROOT);
    }
}
