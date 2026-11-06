package com.franco.desco.application.planta.service;
import com.franco.desco.application.planta.E3Commands.Execute;
import com.franco.desco.application.planta.port.in.E3UseCase;
import com.franco.desco.application.planta.port.out.E3PersistencePort;
import com.franco.desco.application.shared.*;
import org.springframework.stereotype.Service;
@Service
public final class E3ApplicationService implements E3UseCase {
 private final E3PersistencePort port;
 public E3ApplicationService(E3PersistencePort port){this.port=port;}
 @Override public <T> AppResult<T> execute(Execute command,SessionIdentity identity,RequestMetadata metadata,Class<T> type){
  if(command.uotId()==null || command.uotId()<=0 || command.convenioId()==null || command.convenioId()<=0
    || command.predioId()==null || command.predioId()<=0 || command.plantaId()!=null && command.plantaId()<=0)
   return AppResult.error(AppStatus.BAD_REQUEST,"E3_CONTEXTO_INVALIDO","Seleccione un predio y convenio válidos.");
  if(command.pagina()!=null && (command.pagina()<1 || command.tamano()==null || command.tamano()<1 || command.tamano()>100))
   return AppResult.error(AppStatus.BAD_REQUEST,"E3_PAGINACION_INVALIDA","La paginación no es válida.");
  return ApplicationResults.ok(port.execute(command,identity,metadata,type),"E3_OK","E3_ERROR",AppStatus.BAD_REQUEST);
 }
}
