package com.franco.desco.adapter.in.web.account;

import com.franco.desco.application.account.AccountCommands;
import com.franco.desco.domain.account.AccountModels;
import org.springframework.stereotype.Component;

@Component
public class AccountWebMapper {

    public AccountCommands.CloseSession command(AccountRequests.CloseSession request) {
        return new AccountCommands.CloseSession(request.sesionPublicaId());
    }

    public AccountCommands.DeviceRecognition command(AccountRequests.DeviceRecognition request) {
        return new AccountCommands.DeviceRecognition(request.dispositivoUsuarioId(), Boolean.TRUE.equals(request.reconocer()));
    }

    public AccountCommands.ChangePassword command(AccountRequests.ChangePassword request) {
        return new AccountCommands.ChangePassword(request.passwordActual(), request.nuevoPassword(), request.confirmarPassword());
    }

    public AccountCommands.RequestEmailChange command(AccountRequests.RequestEmailChange request) {
        return new AccountCommands.RequestEmailChange(request.nuevoCorreo());
    }

    public AccountCommands.ConfirmEmailChange command(AccountRequests.ConfirmEmailChange request) {
        return new AccountCommands.ConfirmEmailChange(request.codigo());
    }

    public AccountResponses.Session response(AccountModels.SessionInfo value) {
        return new AccountResponses.Session(
                value.sesionPublicaId(), value.fechaCreacionUtc(), value.fechaUltimaActividadUtc(),
                value.fechaExpiracionRenovacionUtc(), value.ipCreacion(), value.ipUltimaActividad(),
                value.sesionActual(), value.activa(), value.dispositivoUsuarioId(), value.navegador(),
                value.sistemaOperativo(), value.fechaPrimeraDeteccionUtc(),
                value.fechaUltimaActividadDispositivoUtc(), value.reconocido()
        );
    }

    public AccountResponses.Device response(AccountModels.DeviceInfo value) {
        return new AccountResponses.Device(
                value.dispositivoUsuarioId(), value.navegador(), value.sistemaOperativo(),
                value.fechaPrimeraDeteccionUtc(), value.fechaUltimaActividadUtc(), value.ultimaIp(),
                value.reconocidoVigente(), value.fechaReconocimientoUtc(),
                value.fechaExpiracionReconocimientoUtc(), value.dispositivoActual()
        );
    }
}
