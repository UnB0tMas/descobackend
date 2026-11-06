package com.franco.desco.adapter.in.web.productive;

import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.CorrelationIdFilter;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import java.sql.SQLException;
import java.util.UUID;
import java.util.Set;
import java.time.Instant;

@Order(Ordered.HIGHEST_PRECEDENCE)
@RestControllerAdvice(assignableTypes={GpController.class,GpFotoController.class})
public class GpSqlExceptionHandler {
  // Únicamente textos literales de THROW 51103 controlados por el proyecto GP.
  // No publicar mensajes de errores SQL Server no clasificados.
  private static final Set<String> VALIDACIONES = Set.of(
    "Datos de parcela inválidos.",
    "Datos de parcela o georreferencia inválidos.",
    "Debe explicar el motivo de la nueva versión.",
    "Detalle de razas inválido o mayor al total.",
    "Detalle de razas inválido o superior al total.",
    "Detalle de razas inválido.",
    "El conteo afectado requiere valor y precisión coherentes.",
    "El cultivo no está disponible.",
    "El motivo del cambio es obligatorio.",
    "El área de las parcelas supera el área disponible del predio.",
    "El área supera la superficie disponible.",
    "Evento inválido.",
    "Indique medición exacta o aproximada según el tipo de actividad.",
    "Indique una medición exacta o aproximada compatible con el rubro.",
    "La cantidad afectada solo corresponde a un control sanitario o evaluación.",
    "La especie no está disponible.",
    "La especie seleccionada no está activa.",
    "La respuesta debe pertenecer al mismo historial.",
    "No hay cambios para registrar.",
    "Problema no aplicable a este tipo de evento.",
    "Problema no asociado a esta especie.",
    "Referencia no válida.",
    "Seleccione el problema detectado.",
    "Seleccione una especie y el nombre de la raza.",
    "Solicitud correspondiente a otra actividad.",
    "Solicitud perteneciente a otro expediente.",
    "Solicitud reutilizada para otra parcela.",
    "Solicitud utilizada para otro predio.",
    "Tratamiento no asociado al problema.",
    "Tratamiento solo aplicable a un evento de tratamiento.",
    "Ubicación geográfica inválida.",
    "Ubicación inválida: compruebe el distrito y centro poblado.",
    "Un cultivo no puede tener razas.",
    "El distrito seleccionado no está disponible.",
    "El centro poblado seleccionado no corresponde al distrito.",
    "La ubicación seleccionada no es válida.",
    "No quedan hectáreas suficientes para esta parcela.",
    "La superficie excede las hectáreas disponibles para este predio."
  );

  static String mensajeValidacion(SQLException sql) {
    if (sql == null || sql.getMessage() == null) return "Revise los datos de la operación.";
    String literal = sql.getMessage().trim();
    // Los mensajes dinámicos del área tienen prefijo y sufijo controlados por V495.
    if (literal.startsWith("La superficie excede las hectáreas disponibles para este predio. Disponible: ")
        && literal.matches("La superficie excede las hectáreas disponibles para este predio\\. Disponible: [0-9]+\\.[0-9]{4} ha\\.")) {
      return literal;
    }
    return VALIDACIONES.contains(literal) ? literal : "Revise los datos de la operación.";
  }

  @ExceptionHandler(DataAccessException.class)
  public ResponseEntity<ApiResponse<Void>> database(DataAccessException ex,HttpServletRequest r){
    int number=0;SQLException sqlError=null;Throwable cause=ex;
    while(cause!=null){if(cause instanceof SQLException sql){number=sql.getErrorCode();sqlError=sql;break;}cause=cause.getCause();}
    UUID correlationId=CorrelationIdFilter.correlationId(r);
    HttpStatus status=switch(number){case 51101->HttpStatus.FORBIDDEN;case 51102->HttpStatus.NOT_FOUND;
      case 51103->HttpStatus.BAD_REQUEST;case 51109,2601,2627->HttpStatus.CONFLICT;
      default->HttpStatus.SERVICE_UNAVAILABLE;};
    String message=switch(number){case 51101->"No tiene permisos para esta operación.";
      case 51102->"El registro no está disponible en el ámbito seleccionado.";
      case 51103->mensajeValidacion(sqlError);
      case 51109->"El expediente cambió. Actualice la ficha antes de guardar.";
      case 2601,2627->"Ya existe un registro con esos datos.";
      default->"No fue posible completar la operación.";};
    return ResponseEntity.status(status).body(new ApiResponse<>(false,"GP_ERROR",message,null,
       correlationId,Instant.now()));
  }
}
