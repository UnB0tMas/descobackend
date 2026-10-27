package com.franco.desco.adapter.in.web.supply;

import com.franco.desco.domain.supply.SupplyModels;
import org.springframework.stereotype.Component;

@Component
public class SupplyWebMapper {
    public SupplyResponses.Summary response(SupplyModels.Summary v){return new SupplyResponses.Summary(v.supplyId(),v.uotId(),v.uotCode(),v.uotName(),v.code(),v.name(),v.unit(),v.active(),v.stock(),v.current(),v.reserved(),v.available(),v.minimum(),v.needsRestock());}
    public SupplyResponses.Movement response(SupplyModels.Movement v){return new SupplyResponses.Movement(v.movementId(),v.supplyId(),v.uotId(),v.uotCode(),v.uotName(),v.code(),v.name(),v.unit(),v.programmedResourceId(),v.type(),v.quantity(),v.dateTime(),v.documentReference(),v.observation(),v.user(),v.balance());}
}
