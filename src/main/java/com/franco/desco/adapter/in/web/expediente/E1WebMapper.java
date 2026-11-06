package com.franco.desco.adapter.in.web.expediente;

import com.franco.desco.application.expediente.E1Commands;
import com.franco.desco.domain.expediente.E1Models;
import org.springframework.stereotype.Component;

@Component
public final class E1WebMapper {

    public E1Commands.Persona persona(E1WebTypes.PersonaRequest request) {
        return new E1Commands.Persona(
                request.tipoDocumento(),
                request.numeroDocumento(),
                request.nombres(),
                request.apellidoPaterno(),
                request.apellidoMaterno(),
                request.fechaNacimiento(),
                request.telefono(),
                request.correo(),
                request.distritoCodigo(),
                request.centroPobladoId(),
                request.referencia()
        );
    }

    public E1Commands.Predio predio(E1WebTypes.PredioRequest request) {
        return new E1Commands.Predio(
                request.personaId(),
                request.nombre(),
                request.distritoCodigo(),
                request.referencia(),
                request.latitud(),
                request.longitud(),
                request.centroPobladoId(),
                request.areaTotalHa(),
                request.areaCultivableHa(),
                request.tipoRiego(), request.altitudM(), request.fuenteAgua(),
                request.infraestructura(), request.observacion(),
                request.fechaRegistro(), request.fechaDesde(), request.tipoTitularidadPrincipal(),
                request.titularesAdicionales() == null ? java.util.List.of() :
                    request.titularesAdicionales().stream().map(t ->
                        new E1Commands.TitularAdicional(t.personaId(), t.tipoTitularidad(), t.porcentaje())
                    ).toList()
        );
    }

    public E1Commands.Cultivo cultivo(E1WebTypes.CultivoRequest request) {
        return new E1Commands.Cultivo(
                request.cultivoId(), request.variedadId(), request.parcelaId(),
                request.parcelaNombre(), request.fecha()
        );
    }

    public E1Commands.Crianza crianza(E1WebTypes.CrianzaRequest request) {
        return new E1Commands.Crianza(
                request.especieId(), request.nombre(), request.cantidad(),
                request.fecha(), request.observacion()
        );
    }

    public E1Commands.Conteo conteo(E1WebTypes.ConteoRequest request) {
        return new E1Commands.Conteo(
                request.loteId(), request.cantidad(), request.fecha(), request.observacion()
        );
    }

    public E1Commands.Actuacion actuacion(E1WebTypes.ActuacionRequest request) {
        return new E1Commands.Actuacion(
                request.tipo(), request.observacion(), request.fechaHecho(),
                request.crianzaId(), request.cultivoId()
        );
    }

    public E1Commands.Ficha ficha(E1WebTypes.FichaRequest request) {
        return new E1Commands.Ficha(request.areaTotalHa(), request.areaCultivableHa(), request.tipoRiego());
    }

    public E1WebTypes.Id response(E1Models.Identificador value) {
        return new E1WebTypes.Id(value.id());
    }

    public E1WebTypes.Convenios response(E1Models.Convenios value) {
        return new E1WebTypes.Convenios(value.items().stream()
                .map(item -> new E1WebTypes.Convenio(item.id(), item.nombre()))
                .toList());
    }

    public E1WebTypes.Personas response(E1Models.Personas value) {
        return new E1WebTypes.Personas(value.items().stream()
                .map(item -> new E1WebTypes.Persona(
                        item.personaId(), item.tipoDocumento(), item.numeroDocumento(), item.nombreCompleto()))
                .toList());
    }

    public E1WebTypes.Predios response(E1Models.Predios value) {
        return new E1WebTypes.Predios(value.items().stream()
                .map(item -> new E1WebTypes.PredioResumen(
                        item.predioId(), item.codigo(), item.nombre(), item.distritoCodigo(),
                        item.referencia(), item.latitud(), item.longitud(), item.titular()))
                .toList());
    }

    public E1WebTypes.Catalogos response(E1Models.Catalogos value) {
        return new E1WebTypes.Catalogos(
                value.cultivos().stream().map(item -> new E1WebTypes.Catalogo(item.id(), item.nombre())).toList(),
                value.variedades().stream().map(item -> new E1WebTypes.Variedad(item.id(), item.padreId(), item.nombre())).toList(),
                value.especies().stream().map(item -> new E1WebTypes.Catalogo(item.id(), item.nombre())).toList()
        );
    }

    public E1WebTypes.Expediente response(E1Models.Expediente value) {
        return new E1WebTypes.Expediente(
                value.predioId(), value.codigo(), value.nombre(), value.distritoCodigo(), value.referencia(),
                value.latitud(), value.longitud(), value.areaTotalHa(), value.areaCultivableHa(),
                value.tipoRiego(), value.fichaCompleta(),
                value.titulares().stream().map(item -> new E1WebTypes.Titular(
                        item.personaId(), item.socioId(), item.numeroDocumento(), item.nombreCompleto(),
                        item.tipoTitularidad(), item.porcentaje(), item.rolTitularidad())).toList(),
                value.cultivos().stream().map(item -> new E1WebTypes.Cultivo(
                        item.id(), item.cultivo(), item.variedad(), item.parcela(), item.fechaInicio(), item.fechaFin())).toList(),
                value.crianzas().stream().map(item -> new E1WebTypes.Crianza(
                        item.id(), item.especie(), item.lote(), item.fechaInicio(), item.cantidadActual())).toList(),
                value.historial().stream().map(item -> new E1WebTypes.Actuacion(
                        item.id(), item.tipo(), item.observacion(), item.fechaHecho(), item.fechaRegistro(), item.autor(),
                        item.cultivoId(), item.crianzaId(), item.salidaId(), item.visitaId())).toList(),
                value.censos().stream().map(item -> new E1WebTypes.Censo(
                        item.id(), item.cultivo(), item.fecha(), item.total(), item.productivas(), item.observacion())).toList(),
                value.conteos().stream().map(item -> new E1WebTypes.Conteo(
                        item.id(), item.crianzaId(), item.cantidad(), item.fechaHecho(), item.observacion())).toList()
        );
    }
}
