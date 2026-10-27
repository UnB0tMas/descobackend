package com.franco.desco.domain.supply;

import java.math.BigDecimal;
import java.time.Instant;

public final class SupplyModels {
    private SupplyModels() {}
    public record Summary(Long supplyId,Long uotId,String uotCode,String uotName,String code,String name,String unit,boolean active,BigDecimal stock,BigDecimal current,BigDecimal reserved,BigDecimal available,BigDecimal minimum,boolean needsRestock,long totalRecords){}
    public record Movement(Long movementId,Long supplyId,Long uotId,String uotCode,String uotName,String code,String name,String unit,Long programmedResourceId,String type,BigDecimal quantity,Instant dateTime,String documentReference,String observation,String user,BigDecimal balance){}
}
