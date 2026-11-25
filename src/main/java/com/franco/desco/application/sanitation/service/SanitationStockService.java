package com.franco.desco.application.sanitation.service;

import com.franco.desco.adapter.out.sqlserver.sanitation.SanitationStockRepository;
import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public final class SanitationStockService {
    private final SanitationStockRepository repository;
    public SanitationStockService(SanitationStockRepository repository){this.repository=repository;}
    public List<SanitationStockRepository.RecursoEntregado> listar(SessionIdentity sesion,
            Long responsableEmpleadoId,Long salidaCampoId,Long visitaTecnicaId,Long predioId){
        if(salidaCampoId!=null&&(visitaTecnicaId==null||predioId==null))
            throw new IllegalArgumentException("Seleccione una visita y un predio.");
        return repository.listar(sesion,responsableEmpleadoId,salidaCampoId,visitaTecnicaId,predioId);
    }
}
