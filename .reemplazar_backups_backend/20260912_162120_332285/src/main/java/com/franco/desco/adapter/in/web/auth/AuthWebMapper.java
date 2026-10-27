package com.franco.desco.adapter.in.web.auth;

import com.franco.desco.adapter.in.web.auth.dto.request.*;
import com.franco.desco.adapter.in.web.auth.dto.response.*;
import com.franco.desco.application.auth.command.*;
import com.franco.desco.application.auth.result.*;
import com.franco.desco.domain.auth.*;
import org.springframework.stereotype.Component;

@Component
public class AuthWebMapper {

    public LoginCommand toCommand(
            LoginRequest request
    ) {
        return new LoginCommand(
                request.nombreUsuario(),
                request.password()
        );
    }

    public RequestTwoFactorCommand toCommand(
            TwoFactorRequest request
    ) {
        return new RequestTwoFactorCommand(
                request.usuarioId(),
                request.correlacionId()
        );
    }

    public VerifyTwoFactorCommand toCommand(
            TwoFactorVerifyRequest request
    ) {
        return new VerifyTwoFactorCommand(
                request.usuarioId(),
                request.codigo(),
                request.correlacionId()
        );
    }

    public RequestEmailVerificationCommand toCommand(
            EmailVerificationRequest request
    ) {
        return new RequestEmailVerificationCommand(
                request.nombreUsuario()
        );
    }

    public ConfirmEmailCommand toCommand(
            EmailVerificationConfirmRequest request
    ) {
        return new ConfirmEmailCommand(
                request.usuarioId(),
                request.nombreUsuario(),
                request.codigo(),
                request.correlacionId()
        );
    }

    public PasswordRecoveryCommand toCommand(
            PasswordRecoveryRequest request
    ) {
        return new PasswordRecoveryCommand(
                request.nombreUsuario()
        );
    }

    public PasswordResetCommand toCommand(
            PasswordResetRequest request
    ) {
        return new PasswordResetCommand(
                request.nombreUsuario(),
                request.codigo(),
                request.nuevoPassword(),
                request.confirmarPassword()
        );
    }

    public RefreshCommand toCommand(
            RefreshTokenRequest request
    ) {
        return new RefreshCommand(
                request.refreshToken()
        );
    }

    public LoginResponse toResponse(
            LoginResult result
    ) {
        return new LoginResponse(
                result.paso().name(),
                toResponse(result.tokens()),
                toResponse(result.contexto()),
                toResponse(result.desafio())
        );
    }

    public RefreshResponse toResponse(
            RefreshResult result
    ) {
        return new RefreshResponse(
                toResponse(result.tokens()),
                toResponse(result.contexto())
        );
    }

    public AuthChallengeResponse toResponse(
            AuthChallenge challenge
    ) {
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

    public TokenResponse toResponse(
            TokenSet token
    ) {
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

    public AuthContextResponse toResponse(
            AccessContext context
    ) {
        if (context == null) {
            return null;
        }

        return new AuthContextResponse(
                toResponse(context.usuario()),
                context.roles()
                        .stream()
                        .map(this::toResponse)
                        .toList(),
                context.modulos()
                        .stream()
                        .map(this::toResponse)
                        .toList(),
                context.permisos()
                        .stream()
                        .map(this::toResponse)
                        .toList()
        );
    }

    private UserAccessResponse toResponse(
            AccessUser user
    ) {
        return new UserAccessResponse(
                user.usuarioId(),
                user.nombreUsuario(),
                user.estadoCuenta(),
                user.ultimoAccesoCorrectoUtc(),
                user.requiereCambioPassword(),
                user.segundoFactorHabilitado(),
                user.tokenVersion(),
                user.personaId(),
                user.tipoDocumento(),
                user.numeroDocumento(),
                user.nombres(),
                user.apellidoPaterno(),
                user.apellidoMaterno(),
                user.nombreCompleto(),
                user.telefono(),
                user.codigoEmpleado(),
                user.empresaId(),
                user.correoSeguridad(),
                user.correoSeguridadVerificado(),
                user.sesionPublicaId(),
                user.fechaSesionUtc(),
                user.fechaExpiracionRenovacionUtc(),
                user.dispositivoUsuarioId(),
                user.navegador(),
                user.sistemaOperativo(),
                user.dispositivoReconocido()
        );
    }

    private RoleAccessResponse toResponse(
            AccessRole role
    ) {
        return new RoleAccessResponse(
                role.rolId(),
                role.codigo(),
                role.nombre(),
                role.descripcion(),
                role.requiereSegundoFactor()
        );
    }

    private ModuleAccessResponse toResponse(
            AccessModule module
    ) {
        return new ModuleAccessResponse(
                module.moduloId(),
                module.moduloPadreId(),
                module.codigo(),
                module.nombre(),
                module.orden(),
                module.ruta(),
                module.icono(),
                module.visibleMenu(),
                module.esGrupo()
        );
    }

    private PermissionAccessResponse toResponse(
            AccessPermission permission
    ) {
        return new PermissionAccessResponse(
                permission.permisoId(),
                permission.moduloId(),
                permission.codigoModulo(),
                permission.codigo(),
                permission.nombre(),
                permission.descripcion(),
                permission.accion(),
                permission.sensible(),
                permission.requiereMotivo()
        );
    }
}
