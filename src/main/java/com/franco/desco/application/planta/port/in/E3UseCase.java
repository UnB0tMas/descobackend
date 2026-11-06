package com.franco.desco.application.planta.port.in;
import com.franco.desco.application.planta.E3Commands.Execute;
import com.franco.desco.application.shared.*;
public interface E3UseCase {
 <T> AppResult<T> execute(Execute command,SessionIdentity identity,RequestMetadata metadata,Class<T> type);
}
