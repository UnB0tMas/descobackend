package com.franco.desco.application.planta;
public final class E3Commands {
 private E3Commands() {}
 public record Execute(String accion,Long uotId,Long convenioId,Long predioId,Long plantaId,
     String buscar,String estado,Long variedadId,Integer pagina,Integer tamano,Object datos) {}
}
