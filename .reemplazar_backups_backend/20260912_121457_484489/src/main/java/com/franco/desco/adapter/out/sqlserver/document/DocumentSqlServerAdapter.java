package com.franco.desco.adapter.out.sqlserver.document;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.document.DocumentCommands.*;
import com.franco.desco.application.document.port.out.DocumentPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.document.DocumentModels;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Component;

import java.util.*;

@Component
public class DocumentSqlServerAdapter implements DocumentPersistencePort {

    private final SqlServerPaExecutor executor;
    private final PaPayloadFactory payloadFactory;
    private final SimpleJdbcCall list;
    private final SimpleJdbcCall get;
    private final SimpleJdbcCall register;
    private final SimpleJdbcCall retire;

    public DocumentSqlServerAdapter(SqlServerPaFactory factory, SqlServerPaExecutor executor, PaPayloadFactory payloadFactory) {
        this.executor = executor;
        this.payloadFactory = payloadFactory;
        this.list = factory.callWithResultSets("archivo", "PA_Archivo_Sel_Listado", "items");
        this.get = factory.callWithResultSets("archivo", "PA_Archivo_Sel_Detalle", "archivo", "vinculos");
        this.register = factory.call("archivo", "PA_Archivo_Ins_Registro");
        this.retire = factory.call("archivo", "PA_Archivo_Upd_Retirar");
    }

    @Override
    public PersistenceResult<PageResult<DocumentModels.Summary>> list(ListDocuments command, SessionIdentity identity, RequestMetadata metadata) {
        int page = command.page().pagina();
        int size = command.page().tamanio();
        Filter f = command.page().filtros();
        Map<String, Object> filters = map(
                "tipoEvidencia", f == null ? null : f.tipoEvidencia(),
                "origenCaptura", f == null ? null : f.origenCaptura(),
                "usuarioId", f == null ? null : f.usuarioId(),
                "contextoTipo", f == null ? null : f.contextoTipo(),
                "contextoId", f == null ? null : f.contextoId(),
                "fechaDesde", f == null ? null : f.fechaDesde(),
                "fechaHasta", f == null ? null : f.fechaHasta(),
                "pagina", page,
                "tamanoPagina", size
        );
        var rs = executor.executeJsonMultiResult(list, payloadFactory.forQuery(identity, metadata, Map.of("filtros", filters)));
        return PaAdapterSupport.page(rs.raw(), rs.rows("items"), page, size, this::summary, "No se pudieron consultar los documentos.");
    }

    @Override
    public PersistenceResult<DocumentModels.Detail> get(GetDocument command, SessionIdentity identity, RequestMetadata metadata) {
        var rs = executor.executeJsonMultiResult(get, payloadFactory.forQuery(identity, metadata, Map.of("archivo", Map.of("archivoId", command.archivoId()))));
        if (!PaAdapterSupport.success(rs.raw())) {
            return PersistenceResult.error(PaAdapterSupport.message(rs.raw(), "No se pudo consultar el documento."));
        }
        var row = rs.one("archivo").orElse(null);
        if (row == null) return PersistenceResult.error("El documento seleccionado no está disponible.");
        var links = rs.rows("vinculos").stream().map(v -> new DocumentModels.Link(
                SqlValues.longValue(v, "archivoVinculoId"),
                SqlValues.string(v, "tipoContexto"),
                SqlValues.longValue(v, "contextoId")
        )).toList();
        return PersistenceResult.ok(
                PaAdapterSupport.message(rs.raw(), "Documento consultado correctamente."),
                new DocumentModels.Detail(
                        SqlValues.longValue(row, "archivoId"), SqlValues.string(row, "nombreOriginal"),
                        SqlValues.string(row, "mimeType"), SqlValues.string(row, "cloudinaryPublicId"),
                        SqlValues.string(row, "secureUrl"), SqlValues.longValue(row, "tamanoBytes"),
                        SqlValues.string(row, "categoria"), SqlValues.string(row, "tipoEvidencia"),
                        SqlValues.string(row, "origenCaptura"), SqlValues.string(row, "descripcion"),
                        SqlValues.instant(row, "fechaCaptura"), SqlValues.decimal(row, "latitudCaptura"),
                        SqlValues.decimal(row, "longitudCaptura"), SqlValues.instant(row, "fechaCarga"),
                        SqlValues.longValue(row, "usuarioId"), SqlValues.string(row, "nombreUsuario"), links
                )
        );
    }

    @Override
    public PersistenceResult<Long> register(RegisterDocument c, SessionIdentity identity, RequestMetadata metadata) {
        Map<String, Object> archivo = map(
                "nombreOriginal", c.nombreOriginal(), "mimeType", c.mimeType(),
                "cloudinaryPublicId", c.cloudinaryPublicId(), "secureUrl", c.secureUrl(),
                "tamanoBytes", c.tamanoBytes(), "tipoEvidencia", c.tipoEvidencia(),
                "categoria", c.categoria(), "origenCaptura", c.origenCaptura(),
                "descripcion", c.descripcion(), "fechaCaptura", c.fechaCaptura(),
                "latitudCaptura", c.latitudCaptura(), "longitudCaptura", c.longitudCaptura()
        );
        Map<String, Object> vinculo = link(c.vinculo());
        Map<String, Object> out = executor.executeJsonMutation(
                register,
                payloadFactory.forWrite(identity, metadata, c, Map.of("archivo", archivo, "vinculo", vinculo))
        );
        return PaAdapterSupport.result(out, SqlValues.longValue(out, "nArchivoId"), "No se pudo registrar el documento.");
    }

    @Override
    public PersistenceResult<Void> retire(RetireDocument c, SessionIdentity identity, RequestMetadata metadata) {
        Map<String, Object> out = executor.executeJsonMutation(
                retire,
                payloadFactory.forWrite(identity, metadata, c, Map.of("archivo", map("archivoId", c.archivoId(), "motivo", c.motivo())))
        );
        return PaAdapterSupport.result(out, null, "No se pudo retirar el documento.");
    }

    private DocumentModels.Summary summary(Map<String, Object> row) {
        return new DocumentModels.Summary(
                SqlValues.longValue(row, "archivoId"), SqlValues.string(row, "nombreOriginal"),
                SqlValues.string(row, "mimeType"), SqlValues.string(row, "secureUrl"),
                SqlValues.longValue(row, "tamanoBytes"), SqlValues.string(row, "categoria"),
                SqlValues.string(row, "tipoEvidencia"), SqlValues.string(row, "origenCaptura"),
                SqlValues.string(row, "descripcion"), SqlValues.instant(row, "fechaCaptura"),
                SqlValues.decimal(row, "latitudCaptura"), SqlValues.decimal(row, "longitudCaptura"),
                SqlValues.instant(row, "fechaCarga"), SqlValues.longValue(row, "usuarioId"),
                SqlValues.string(row, "nombreUsuario"), SqlValues.string(row, "tipoContexto"),
                SqlValues.longValue(row, "contextoId")
        );
    }

    private Map<String, Object> link(Link v) {
        if (v == null) return Map.of();
        return map(
                "predioId", v.predioId(), "salidaCampoId", v.salidaCampoId(), "visitaTecnicaId", v.visitaTecnicaId(),
                "casoFitosanitarioId", v.casoFitosanitarioId(), "tratamientoId", v.tratamientoId(),
                "entregaSocioId", v.entregaSocioId(), "incidenciaOperativaId", v.incidenciaOperativaId(),
                "ajustePrecioSocioId", v.ajustePrecioSocioId(), "gastoCampaniaId", v.gastoCampaniaId(),
                "liquidacionSocioId", v.liquidacionSocioId(), "pagoSocioId", v.pagoSocioId(),
                "cobroCompradorId", v.cobroCompradorId(), "socioId", v.socioId(), "empleadoId", v.empleadoId(),
                "parcelaId", v.parcelaId(), "parcelaCultivoId", v.parcelaCultivoId(), "censoPlantasId", v.censoPlantasId(),
                "evaluacionAgronomicaId", v.evaluacionAgronomicaId(), "seguimientoFitosanitarioId", v.seguimientoFitosanitarioId(),
                "disponibilidadProduccionId", v.disponibilidadProduccionId(), "campaniaVentaId", v.campaniaVentaId(),
                "precioComercialId", v.precioComercialId(), "participacionCampaniaSocioId", v.participacionCampaniaSocioId(),
                "operativoVentaId", v.operativoVentaId(), "jabaAsignacionId", v.jabaAsignacionId(),
                "jabaDevolucionId", v.jabaDevolucionId(), "bienInventarioId", v.bienInventarioId(),
                "recursoProgramadoId", v.recursoProgramadoId()
        );
    }

    private static Map<String, Object> map(Object... pairs) {
        Map<String, Object> result = new LinkedHashMap<>();
        for (int i = 0; i < pairs.length; i += 2) if (pairs[i + 1] != null) result.put((String) pairs[i], pairs[i + 1]);
        return result;
    }
}
