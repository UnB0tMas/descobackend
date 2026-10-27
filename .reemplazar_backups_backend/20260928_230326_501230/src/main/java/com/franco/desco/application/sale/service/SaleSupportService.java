package com.franco.desco.application.sale.service;

import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.sale.SaleModels;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Service;
import tools.jackson.databind.json.JsonMapper;

import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class SaleSupportService {

    private static final int SQL_SERVER_GUID = -145;

    private final JsonMapper jsonMapper;
    private final SimpleJdbcCall manualCustomerCall;
    private final SimpleJdbcCall technicalEmployeesCall;
    private final SimpleJdbcCall technicalDeliveriesCall;
    private final SimpleJdbcCall technicalDeliveryCall;

    public SaleSupportService(JdbcTemplate jdbcTemplate, JsonMapper jsonMapper) {
        this.jsonMapper = jsonMapper;

        this.manualCustomerCall = new SimpleJdbcCall(jdbcTemplate)
                .withSchemaName("comercial")
                .withProcedureName("PA_Cliente_Ins_Manual")
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(
                        in("nUsuarioId", Types.BIGINT), in("nUotId", Types.BIGINT),
                        in("cTipoCliente", Types.VARCHAR), in("cTipoDocumento", Types.VARCHAR),
                        in("cNumeroDocumento", Types.VARCHAR), in("cNombres", Types.NVARCHAR),
                        in("cApellidoPaterno", Types.NVARCHAR), in("cApellidoMaterno", Types.NVARCHAR),
                        in("cRazonSocial", Types.NVARCHAR), in("cTelefono", Types.VARCHAR), in("cCorreo", Types.VARCHAR),
                        out("nClientePersonaId", Types.BIGINT), out("nClienteEmpresaId", Types.BIGINT),
                        out("bReutilizado", Types.BIT), out("cTipoDocumentoResultado", Types.VARCHAR),
                        out("cNumeroDocumentoResultado", Types.VARCHAR), out("cNombreCliente", Types.NVARCHAR),
                        commonOut("bResultado", Types.BIT), commonOut("cMensaje", Types.NVARCHAR),
                        commonOut("cCodigoRespuesta", Types.VARCHAR), commonOut("nHttpRespuesta", Types.SMALLINT)
                );

        this.technicalEmployeesCall = new SimpleJdbcCall(jdbcTemplate)
                .withSchemaName("logistica")
                .withProcedureName("PA_EntregaTecnica_Sel_Empleados")
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(
                        in("nUsuarioId", Types.BIGINT), in("nUotId", Types.BIGINT),
                        commonOut("bResultado", Types.BIT), commonOut("cMensaje", Types.NVARCHAR),
                        commonOut("cCodigoRespuesta", Types.VARCHAR), commonOut("nHttpRespuesta", Types.SMALLINT)
                )
                .returningResultSet("empleados", this::mapEmployee);

        this.technicalDeliveriesCall = new SimpleJdbcCall(jdbcTemplate)
                .withSchemaName("logistica")
                .withProcedureName("PA_EntregaTecnica_Sel_Listado")
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(
                        in("nUsuarioId", Types.BIGINT), in("nUotId", Types.BIGINT), in("nEmpleadoId", Types.BIGINT),
                        commonOut("bResultado", Types.BIT), commonOut("cMensaje", Types.NVARCHAR),
                        commonOut("cCodigoRespuesta", Types.VARCHAR), commonOut("nHttpRespuesta", Types.SMALLINT)
                )
                .returningResultSet("entregas", this::mapTechnicalDelivery);

        this.technicalDeliveryCall = new SimpleJdbcCall(jdbcTemplate)
                .withSchemaName("logistica")
                .withProcedureName("PA_EntregaTecnica_Ins_Registrar")
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(
                        in("nUsuarioId", Types.BIGINT), in("nUotId", Types.BIGINT), in("nAlmacenId", Types.BIGINT),
                        in("nEmpleadoId", Types.BIGINT), in("gClaveIdempotencia", SQL_SERVER_GUID),
                        in("cDetalleJson", Types.NVARCHAR), in("cMotivo", Types.NVARCHAR), in("cObservacion", Types.NVARCHAR),
                        out("nEntregaTecnicaId", Types.BIGINT), out("nMovimientoInventarioId", Types.BIGINT),
                        commonOut("bResultado", Types.BIT), commonOut("cMensaje", Types.NVARCHAR),
                        commonOut("cCodigoRespuesta", Types.VARCHAR), commonOut("nHttpRespuesta", Types.SMALLINT)
                );
    }

    public record TechnicalLine(Long productId, BigDecimal quantity) {}

    public AppResult<SaleModels.CustomerReference> manualCustomer(
            SessionIdentity identity, Long uotId, String customerType, String documentType, String documentNumber,
            String names, String paternalSurname, String maternalSurname, String businessName, String phone, String email
    ) {
        if (identity == null || identity.usuarioId() == null) return unauthorized();
        try {
            Map<String, Object> out = manualCustomerCall.execute(new MapSqlParameterSource()
                    .addValue("nUsuarioId", identity.usuarioId()).addValue("nUotId", uotId)
                    .addValue("cTipoCliente", upper(customerType)).addValue("cTipoDocumento", upper(documentType))
                    .addValue("cNumeroDocumento", trim(documentNumber)).addValue("cNombres", trim(names))
                    .addValue("cApellidoPaterno", trim(paternalSurname)).addValue("cApellidoMaterno", trim(maternalSurname))
                    .addValue("cRazonSocial", trim(businessName)).addValue("cTelefono", trim(phone)).addValue("cCorreo", trim(email)));
            if (!ok(out)) return error(out, "CLIENTE_NO_REGISTRADO", "No se pudo registrar el cliente.");
            SaleModels.CustomerReference data = new SaleModels.CustomerReference(
                    upper(customerType), longValue(out,"nClientePersonaId"), longValue(out,"nClienteEmpresaId"),
                    text(out.get("cTipoDocumentoResultado"), upper(documentType)),
                    text(out.get("cNumeroDocumentoResultado"), trim(documentNumber)),
                    text(out.get("cNombreCliente"), "Cliente"), bool(out.get("bReutilizado"))
            );
            return AppResult.ok(code(out,"CLIENTE_DISPONIBLE"), message(out,"Cliente disponible."), data);
        } catch (DataAccessException ex) {
            return AppResult.error(AppStatus.SERVICE_UNAVAILABLE,"CLIENTE_NO_REGISTRADO","No se pudo registrar el cliente.");
        }
    }

    public AppResult<List<SaleModels.TechnicalEmployee>> technicalEmployees(SessionIdentity identity, Long uotId) {
        if (identity == null || identity.usuarioId() == null) return unauthorized();
        try {
            Map<String,Object> out=technicalEmployeesCall.execute(new MapSqlParameterSource()
                    .addValue("nUsuarioId",identity.usuarioId()).addValue("nUotId",uotId));
            if(!ok(out)) return error(out,"EMPLEADOS_NO_LISTADOS","No se pudieron consultar los empleados.");
            return AppResult.ok(code(out,"EMPLEADOS_LISTADOS"),message(out,"Empleados consultados."),list(out,"empleados"));
        } catch (DataAccessException ex) {
            return AppResult.error(AppStatus.SERVICE_UNAVAILABLE,"EMPLEADOS_NO_LISTADOS","No se pudieron consultar los empleados.");
        }
    }

    public AppResult<List<SaleModels.TechnicalDeliverySummary>> technicalDeliveries(
            SessionIdentity identity, Long uotId, Long employeeId
    ) {
        if (identity == null || identity.usuarioId() == null) return unauthorized();
        try {
            Map<String,Object> out=technicalDeliveriesCall.execute(new MapSqlParameterSource()
                    .addValue("nUsuarioId",identity.usuarioId()).addValue("nUotId",uotId).addValue("nEmpleadoId",employeeId));
            if(!ok(out)) return error(out,"ENTREGAS_TECNICAS_NO_LISTADAS","No se pudieron consultar las entregas técnicas.");
            return AppResult.ok(code(out,"ENTREGAS_TECNICAS_LISTADAS"),message(out,"Entregas técnicas consultadas."),list(out,"entregas"));
        } catch (DataAccessException ex) {
            return AppResult.error(AppStatus.SERVICE_UNAVAILABLE,"ENTREGAS_TECNICAS_NO_LISTADAS","No se pudieron consultar las entregas técnicas.");
        }
    }

    public AppResult<SaleModels.TechnicalDeliveryCreated> technicalDelivery(
            SessionIdentity identity, Long uotId, Long warehouseId, Long employeeId, List<TechnicalLine> lines,
            String reason, String observation, UUID idempotencyKey
    ) {
        if (identity == null || identity.usuarioId() == null) return unauthorized();
        if (lines == null || lines.isEmpty() || idempotencyKey == null) {
            return AppResult.error(AppStatus.BAD_REQUEST,"ENTREGA_TECNICA_NO_REGISTRADA","La entrega debe incluir productos válidos.");
        }
        try {
            String json = jsonMapper.writeValueAsString(lines.stream()
                    .map(line -> Map.of("productoId", line.productId(), "cantidad", line.quantity())).toList());
            Map<String,Object> out=technicalDeliveryCall.execute(new MapSqlParameterSource()
                    .addValue("nUsuarioId",identity.usuarioId()).addValue("nUotId",uotId).addValue("nAlmacenId",warehouseId)
                    .addValue("nEmpleadoId",employeeId).addValue("gClaveIdempotencia",idempotencyKey.toString())
                    .addValue("cDetalleJson",json).addValue("cMotivo",trim(reason)).addValue("cObservacion",trim(observation)));
            if(!ok(out)) return error(out,"ENTREGA_TECNICA_NO_REGISTRADA","No se pudo registrar la entrega técnica.");
            SaleModels.TechnicalDeliveryCreated data = new SaleModels.TechnicalDeliveryCreated(
                    longValue(out,"nEntregaTecnicaId"), longValue(out,"nMovimientoInventarioId"));
            AppStatus status=AppStatus.fromHttp(http(out),AppStatus.CREATED);
            return status==AppStatus.CREATED
                    ? AppResult.created(code(out,"ENTREGA_TECNICA_REGISTRADA"),message(out,"Entrega técnica registrada."),data)
                    : AppResult.ok(code(out,"ENTREGA_TECNICA_REGISTRADA"),message(out,"Entrega técnica registrada."),data);
        } catch (Exception ex) {
            return AppResult.error(AppStatus.SERVICE_UNAVAILABLE,"ENTREGA_TECNICA_NO_REGISTRADA","No se pudo registrar la entrega técnica.");
        }
    }

    private SaleModels.TechnicalEmployee mapEmployee(ResultSet rs,int row) throws SQLException {
        return new SaleModels.TechnicalEmployee(nullableLong(rs,"empleadoId"),rs.getString("codigoEmpleado"),rs.getString("empleado"));
    }

    private SaleModels.TechnicalDeliverySummary mapTechnicalDelivery(ResultSet rs,int row) throws SQLException {
        var ts=rs.getTimestamp("fechaHora");
        return new SaleModels.TechnicalDeliverySummary(
                nullableLong(rs,"entregaTecnicaId"),nullableLong(rs,"uotId"),rs.getString("uotNombre"),
                nullableLong(rs,"almacenId"),rs.getString("almacen"),nullableLong(rs,"empleadoId"),rs.getString("empleado"),
                ts==null?null:ts.toLocalDateTime(),rs.getString("motivo"),rs.getString("observacion"),
                nullableLong(rs,"movimientoInventarioId"),nullableLong(rs,"usuarioEntregaId"),rs.getString("usuarioEntrega"));
    }

    private static SqlParameter in(String name,int type){return new SqlParameter(name,type);}
    private static SqlOutParameter out(String name,int type){return new SqlOutParameter(name,type);}
    private static SqlOutParameter commonOut(String name,int type){return new SqlOutParameter(name,type);}
    private static boolean ok(Map<String,Object> out){return bool(out.get("bResultado"));}
    private static boolean bool(Object v){return v instanceof Boolean b?b:v instanceof Number n&&n.intValue()!=0;}
    private static String code(Map<String,Object> out,String f){return text(out.get("cCodigoRespuesta"),f);}
    private static String message(Map<String,Object> out,String f){return text(out.get("cMensaje"),f);}
    private static Integer http(Map<String,Object> out){Object v=out.get("nHttpRespuesta");return v instanceof Number n?n.intValue():null;}
    private static Long longValue(Map<String,Object> out,String k){Object v=out.get(k);return v instanceof Number n?n.longValue():null;}
    private static Long nullableLong(ResultSet rs,String c)throws SQLException{long v=rs.getLong(c);return rs.wasNull()?null:v;}
    @SuppressWarnings("unchecked") private static <T> List<T> list(Map<String,Object> out,String key){Object v=out.get(key);return v instanceof List<?> l?List.copyOf((List<T>)l):List.of();}
    private static String trim(String value){if(value==null)return null;String v=value.trim();return v.isEmpty()?null:v;}
    private static String upper(String value){String v=trim(value);return v==null?null:v.toUpperCase();}
    private static String text(Object value,String fallback){String v=value==null?null:value.toString().trim();return v==null||v.isEmpty()?fallback:v;}
    private static <T> AppResult<T> unauthorized(){return AppResult.error(AppStatus.UNAUTHORIZED,"SESION_NO_DISPONIBLE","La sesión ya no está disponible. Inicie sesión nuevamente.");}
    private static <T> AppResult<T> error(Map<String,Object> out,String fallbackCode,String fallbackMessage){return AppResult.error(AppStatus.fromHttp(http(out),AppStatus.BAD_REQUEST),code(out,fallbackCode),message(out,fallbackMessage));}
}
