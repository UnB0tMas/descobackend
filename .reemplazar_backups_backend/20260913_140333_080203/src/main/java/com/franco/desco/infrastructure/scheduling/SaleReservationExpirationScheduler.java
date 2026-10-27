package com.franco.desco.infrastructure.scheduling;

import com.franco.desco.application.sale.port.out.SalePersistencePort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.concurrent.atomic.AtomicBoolean;

@Component
public class SaleReservationExpirationScheduler {
    private static final Logger log= LoggerFactory.getLogger(SaleReservationExpirationScheduler.class);
    private final SalePersistencePort persistence;
    private final AtomicBoolean running=new AtomicBoolean(false);

    public SaleReservationExpirationScheduler(SalePersistencePort persistence){this.persistence=persistence;}

    @Scheduled(fixedDelayString="${app.sales.reservation-expiration-ms:60000}")
    public void expire(){
        if(!running.compareAndSet(false,true))return;
        try{
            var result=persistence.expireReservations();
            if(!result.exitoso())log.warn("[VENTAS] No se pudieron procesar reservas vencidas: {}",result.mensaje());
            else if(result.datos()!=null&&result.datos()>0)log.info("[VENTAS] Reservas vencidas procesadas={}",result.datos());
        }catch(RuntimeException exception){log.error("[VENTAS] Error inesperado procesando reservas vencidas",exception);}
        finally{running.set(false);}
    }
}
