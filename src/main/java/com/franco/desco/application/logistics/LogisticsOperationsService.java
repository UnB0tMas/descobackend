package com.franco.desco.application.logistics;

import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import tools.jackson.databind.json.JsonMapper;

import javax.sql.DataSource;
import java.math.BigDecimal;
import java.sql.*;
import java.util.*;

@Service
public final class LogisticsOperationsService {
    public record Policy(Long uotId,Long productoId,Boolean permiteVenta,Boolean permiteUsoInterno) {}
    public record TransferLine(Long productoId,BigDecimal cantidad) {}
    public record Transfer(Long almacenOrigenId,Long almacenDestinoId,List<TransferLine> detalle,String observacion) {}
    public record RequestProduct(Long uotId,Long almacenId,Long productoId,Long empleadoId,BigDecimal cantidad,
                                 String actividad,String lugar,java.time.LocalDateTime fechaInicio,java.time.LocalDateTime fechaFin,
                                 Long archivoAutorizacionId,String observacion) {}
    public record ProductOperation(String operacion,BigDecimal cantidad,String observacion) {}

    private final JdbcTemplate jdbc;
    private final JsonMapper jsonMapper;

    public LogisticsOperationsService(DataSource dataSource, JsonMapper jsonMapper) {
        this.jdbc = new JdbcTemplate(dataSource);
        this.jsonMapper = jsonMapper;
    }

    public AppResult<Void> policy(SessionIdentity actor, Policy value) {
        return writeVoid("PA_ProductoUOT_Upd_Politica", actor,
                value.uotId(),value.productoId(),value.permiteVenta(),value.permiteUsoInterno());
    }

    public AppResult<Long> transfer(SessionIdentity actor, Transfer value, UUID key) {
        String lines;
        try {
            lines = jsonMapper.writeValueAsString(value.detalle());
        } catch (Exception ex) {
            return AppResult.error(AppStatus.BAD_REQUEST,"DETALLE_INVALIDO","Revise los productos de la transferencia.");
        }
        return writeId("PA_Almacen_Ins_TransferirStock",actor,value.almacenOrigenId(),
                value.almacenDestinoId(),lines, key.toString(),value.observacion());
    }

    public AppResult<Long> request(SessionIdentity actor, RequestProduct value, UUID key) {
        return writeId("PA_ProgramacionProducto_Ins_Solicitar",actor,
                value.uotId(),value.almacenId(),value.productoId(),value.empleadoId(),
                value.cantidad(),value.actividad(),value.lugar(),value.fechaInicio(),value.fechaFin(),
                value.archivoAutorizacionId(),value.observacion(),key.toString());
    }

    public AppResult<Long> operation(SessionIdentity actor, Long id, ProductOperation value, UUID key) {
        return writeId("PA_ProgramacionProducto_Ins_Operacion",actor,
                id,value.operacion(),value.cantidad(),value.observacion(),key.toString());
    }

    public AppResult<Void> attach(SessionIdentity actor,Long id,Long fileId) {
        return writeVoid("PA_RecursoProgramadoArchivo_Ins_Adjuntar",actor,id,fileId);
    }

    public AppResult<List<Map<String,Object>>> policies(SessionIdentity actor, Long uotId) {
        return read("PA_ProductoUOT_Sel_Politicas",actor,uotId);
    }

    public AppResult<List<Map<String,Object>>> programs(SessionIdentity actor,Long uotId,String state) {
        return read("PA_ProgramacionProducto_Sel_Listado",actor,uotId,state);
    }

    public AppResult<List<Map<String,Object>>> detail(SessionIdentity actor,Long id) {
        return read("PA_ProgramacionProducto_Sel_Detalle",actor,id);
    }

    private AppResult<Void> writeVoid(String name, SessionIdentity actor, Object... args) {
        if (!validActor(actor)) return invalidSession();
        try {
            Outcome out = jdbc.execute((ConnectionCallback<Outcome>) con -> call(con,name,actor.usuarioId(),args,false,false));
            if (out == null || !out.success()) return error(out);
            return AppResult.ok("OPERACION_REALIZADA",safeMessage(out.message(),"Acción realizada correctamente."),null);
        } catch (DataAccessException exception) {
            return unavailable();
        }
    }

    private AppResult<Long> writeId(String name, SessionIdentity actor,Object... args) {
        if (!validActor(actor)) return invalidSession();
        try {
            Outcome out = jdbc.execute((ConnectionCallback<Outcome>) con -> call(con,name,actor.usuarioId(),args,true,false));
            if (out == null || !out.success() || out.id() == null) return error(out);
            return AppResult.created("OPERACION_REGISTRADA",safeMessage(out.message(),"Operación registrada correctamente."),out.id());
        } catch (DataAccessException exception) {
            return unavailable();
        }
    }

    private AppResult<List<Map<String,Object>>> read(String name,SessionIdentity actor,Object... args) {
        if (!validActor(actor)) return invalidSession();
        try {
            Outcome out=jdbc.execute((ConnectionCallback<Outcome>) con->call(con,name,actor.usuarioId(),args,false,true));
            if (out==null || !out.success()) return error(out);
            return AppResult.ok("CONSULTA_REALIZADA",safeMessage(out.message(),"Consulta realizada correctamente."),out.rows());
        } catch (DataAccessException exception) {
            return unavailable();
        }
    }

    private Outcome call(Connection con,String name,Long actor,Object[] args,boolean returnId,boolean rows) throws SQLException {
        int count=1+args.length+(returnId?1:0)+2;
        String markers=String.join(",",Collections.nCopies(count,"?"));
        try (CallableStatement statement=con.prepareCall("{call logistica."+name+"("+markers+")}")) {
            int index=1;
            statement.setLong(index++,actor);
            for (Object item:args) set(statement,index++,item);
            int idIndex=0;
            if (returnId) { idIndex=index++;statement.registerOutParameter(idIndex,Types.BIGINT); }
            int successIndex=index++;
            int messageIndex=index;
            statement.registerOutParameter(successIndex,Types.BIT);
            statement.registerOutParameter(messageIndex,Types.NVARCHAR);
            List<Map<String,Object>> values=new ArrayList<>();
            boolean hasResults=statement.execute();
            while (true) {
                if (hasResults) {
                    try(ResultSet result=statement.getResultSet()) {
                        if(rows && result!=null) {
                            ResultSetMetaData meta=result.getMetaData();
                            while(result.next()) {
                                Map<String,Object> row=new LinkedHashMap<>();
                                for(int col=1;col<=meta.getColumnCount();col++)
                                    row.put(meta.getColumnLabel(col),result.getObject(col));
                                values.add(row);
                            }
                        }
                    }
                } else if (statement.getUpdateCount()==-1) break;
                hasResults=statement.getMoreResults();
            }
            Long id=returnId?(Long)statement.getObject(idIndex):null;
            return new Outcome(statement.getBoolean(successIndex),statement.getString(messageIndex),id,List.copyOf(values));
        }
    }

    private void set(CallableStatement statement,int index,Object value) throws SQLException {
        if(value==null) statement.setObject(index,null);
        else if(value instanceof Long number) statement.setLong(index,number);
        else if(value instanceof Integer number) statement.setInt(index,number);
        else if(value instanceof Boolean enabled) statement.setBoolean(index,enabled);
        else if(value instanceof BigDecimal number) statement.setBigDecimal(index,number);
        else if(value instanceof java.time.LocalDateTime time) statement.setTimestamp(index,Timestamp.valueOf(time));
        else statement.setString(index,value.toString());
    }

    private static boolean validActor(SessionIdentity actor) {return actor!=null && actor.usuarioId()!=null;}
    private static String safeMessage(String message,String fallback) {
        if(message==null || message.isBlank())return fallback;
        return message.length()>300?fallback:message;
    }
    private static <T> AppResult<T> error(Outcome out) {
        return AppResult.error(AppStatus.BAD_REQUEST,"OPERACION_NO_COMPLETADA",
                safeMessage(out==null?null:out.message(),"No se pudo completar la operación."));
    }
    private static <T> AppResult<T> invalidSession() {
        return AppResult.error(AppStatus.UNAUTHORIZED,"SESION_NO_DISPONIBLE","Inicie sesión nuevamente.");
    }
    private static <T> AppResult<T> unavailable() {
        return AppResult.error(AppStatus.SERVICE_UNAVAILABLE,"SERVICIO_NO_DISPONIBLE","No se pudo completar la acción en este momento.");
    }
    private record Outcome(boolean success,String message,Long id,List<Map<String,Object>> rows) {}
}
