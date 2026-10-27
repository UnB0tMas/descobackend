# DESCO — Diagramas UML de actividades (PlantUML)

**Proyecto:** DESCO – UOT Sara Sara  
**Documento:** Modelado de procesos principales para la tesis  
**Diagramas incluidos:** ACT-01, ACT-02, ACT-03 y ACT-04  
**Base:** código fuente vigente de Angular, Spring Boot y migraciones Flyway de SQL Server proporcionados el 19/10/2026.

## Compatibilidad con PlantUML

**Corrección de sintaxis:** en los cuatro diagramas, el primer carril se declara **antes** de `start` (por ejemplo, `|Usuario|` seguido por `start`). PlantUML lo exige cuando se utilizan *swimlanes* con la sintaxis moderna de actividades. Los restantes carriles se declaran a medida que avanza el flujo.

## Criterios de modelado

- Los diagramas son **de actividades UML**, no diagramas de secuencia. Utilizan particiones (*swimlanes*) para separar las acciones del usuario, del frontend y del backend/base de datos.
- Muestran los **flujos funcionales relevantes** y los resultados alternativos, no todos los métodos internos, consultas SQL ni excepciones técnicas.
- Los nombres de estados y operaciones funcionales siguen el código revisado. Las acciones de base de datos describen el resultado del procedimiento almacenado, no pretenden reproducir su implementación línea por línea.
- Cada bloque `plantuml` es autónomo: puede copiarse completo en PlantUML para generar una figura independiente.

---

## ACT-01 — Inicio de sesión y selección de UOT

**Objetivo:** representar la autenticación, las verificaciones adicionales y la resolución del contexto de unidad de organización territorial (UOT).  
**Inicio:** un usuario abre la pantalla de acceso.  
**Fin esperado:** el usuario autenticado accede a DESCO con el contexto UOT resuelto.  
**Variantes:** credenciales inválidas; validación de correo; segundo factor; cambio obligatorio de contraseña; selección manual o automática de UOT.

```plantuml
@startuml
title ACT-01 - Inicio de sesión y selección de UOT

skinparam backgroundColor #FFFFFF
skinparam shadowing false
skinparam defaultFontName Arial
skinparam defaultFontSize 13
skinparam activityBackgroundColor #EBF3FC
skinparam activityBorderColor #3972A5
skinparam activityFontColor #153957
skinparam diamondBackgroundColor #FFF3D9
skinparam diamondBorderColor #BA851D
skinparam arrowColor #57738F

|Usuario|
start
:Abrir pantalla de inicio de sesión;
:Ingresar usuario y contraseña;

|Frontend Angular|
:Validar campos obligatorios y longitudes;
if (¿Formulario válido?) then (Sí)
  :Enviar solicitud de inicio de sesión;
else (No)
  :Mostrar errores del formulario;
  stop
endif

|Backend / SQL Server|
:Validar credenciales y situación de la cuenta;
if (¿Acceso rechazado?) then (Sí)
  |Frontend Angular|
  :Mostrar mensaje de error de autenticación;
  stop
endif

if (¿Debe verificarse el correo?) then (Sí)
  |Frontend Angular|
  :Mostrar pantalla de validación de correo;
  |Usuario|
  :Ingresar código de verificación;
  |Backend / SQL Server|
  :Comprobar código y registrar validación;
  if (¿Código correcto y vigente?) then (Sí)
    |Frontend Angular|
    :Informar verificación satisfactoria;
    :Regresar a inicio de sesión;
  else (No)
    |Frontend Angular|
    :Mostrar error y permitir nuevo intento;
  endif
  stop
endif

if (¿Se requiere segundo factor?) then (Sí)
  |Frontend Angular|
  :Mostrar pantalla de segundo factor;
  |Usuario|
  :Ingresar código de seis dígitos;
  |Backend / SQL Server|
  :Verificar segundo factor;
  if (¿Segundo factor válido?) then (No)
    |Frontend Angular|
    :Mostrar error y permitir reintento;
    stop
  endif
endif

|Frontend Angular|
:Guardar contexto de sesión autenticada;
if (¿Cambio de contraseña obligatorio?) then (Sí)
  :Redirigir a cambio de contraseña;
  |Usuario|
  :Establecer nueva contraseña;
  |Backend / SQL Server|
  :Validar y aplicar cambio;
  |Frontend Angular|
  :Solicitar nuevo inicio de sesión;
  stop
endif

|Backend / SQL Server|
:Consultar contexto y UOT autorizadas;
if (¿Consulta de UOT disponible?) then (No)
  |Frontend Angular|
  :Mostrar pantalla de servicio no disponible;
  stop
endif

if (¿Hay un contexto UOT utilizable?) then (Sí)
  :Mantener el contexto actual;
else (No)
  if (¿Existe una sola UOT autorizada?) then (Sí)
    :Seleccionar automáticamente esa UOT;
  else (No)
    |Frontend Angular|
    :Mostrar UOT disponibles y modo general permitido;
    |Usuario|
    :Elegir UOT específica o modo general autorizado;
    |Backend / SQL Server|
    :Validar acceso y registrar contexto seleccionado;
    if (¿Selección aceptada?) then (No)
      |Frontend Angular|
      :Mostrar error de selección;
      stop
    endif
  endif
endif

|Frontend Angular|
:Actualizar contexto de sesión y permisos;
:Redirigir a inicio o ruta solicitada;
|Usuario|
:Acceder a DESCO en el contexto autorizado;
stop
@enduml
```

**Correspondencia con el código:** `login.ts`, `segundo-factor.ts`, `validacion-correo.ts`, `cambio-password-obligatorio.ts`, `uot-context.guard.ts`, `uot-selection.ts`, `UotApiService`, `AuthController`, `UotController`. La pantalla de validación de correo devuelve al usuario a `/login`; la selección automática de UOT se realiza cuando hay una sola UOT autorizada sin seleccionar.

---

## ACT-02 — Registro y seguimiento de una visita técnica

**Objetivo:** representar el inicio, seguimiento y cierre de una visita técnica vinculada a una salida de campo.  
**Inicio:** el personal habilitado accede a la sección de visitas.  
**Fin esperado:** la visita queda en estado `FINALIZADA`; también puede conservarse `INICIADA` o terminar `ANULADA` según la acción elegida.  
**Reglas relevantes:** salida `PROGRAMADA` o `EN_CURSO`, participante válido, predio activo, datos de inicio completos, resumen y recomendaciones al finalizar.

```plantuml
@startuml
title ACT-02 - Registro y seguimiento de una visita técnica

skinparam backgroundColor #FFFFFF
skinparam shadowing false
skinparam defaultFontName Arial
skinparam defaultFontSize 13
skinparam activityBackgroundColor #EBF3FC
skinparam activityBorderColor #3972A5
skinparam activityFontColor #153957
skinparam diamondBackgroundColor #FFF3D9
skinparam diamondBorderColor #BA851D
skinparam arrowColor #57738F

|Usuario técnico|
start
:Ingresar al módulo de visitas;
:Seleccionar «Iniciar visita»;

|Frontend Angular|
:Cargar predios activos y salidas disponibles;
|Usuario técnico|
:Seleccionar salida de campo;
|Frontend Angular|
:Cargar participantes activos de la salida;
|Usuario técnico|
:Elegir participante y predio;
:Ingresar fecha, hora y objetivo;
:Capturar ubicación geográfica;

|Frontend Angular|
:Validar campos, fechas y coordenadas;
if (¿Datos completos y ubicación capturada?) then (No)
  :Mostrar errores y solicitar corrección;
  stop
endif

:Solicitar inicio de visita;
|Backend / SQL Server|
:Comprobar permisos y participante asignado;
:Validar salida, predio y visita en curso;
if (¿Se puede iniciar la visita?) then (No)
  |Frontend Angular|
  :Mostrar motivo del rechazo;
  stop
endif

if (¿La salida está PROGRAMADA?) then (Sí)
  :Cambiar salida de campo a EN_CURSO;
endif
:Registrar visita en estado INICIADA;
:Guardar fecha, ubicación y objetivo;

|Frontend Angular|
:Confirmar inicio y actualizar listado;
|Usuario técnico|
:Consultar el detalle de la visita;

if (¿Desea editar los datos de seguimiento?) then (Sí)
  :Modificar objetivo, resumen o recomendaciones;
  |Frontend Angular|
  :Validar cambios y solicitar actualización;
  |Backend / SQL Server|
  :Actualizar datos permitidos de la visita;
  if (¿Actualización exitosa?) then (No)
    |Frontend Angular|
    :Mostrar error de actualización;
    stop
  endif
  |Usuario técnico|
  :Revisar información actualizada;
endif

if (¿Desea finalizar la visita?) then (Sí)
  :Ingresar hora de fin, resumen y recomendaciones;
  |Frontend Angular|
  :Validar campos y fin no anterior al inicio;
  if (¿Formulario de cierre válido?) then (No)
    :Solicitar corrección del cierre;
    stop
  endif
  :Enviar solicitud de finalización;
  |Backend / SQL Server|
  :Verificar que la visita siga INICIADA;
  :Validar fechas, resumen y recomendaciones;
  if (¿Finalización aceptada?) then (Sí)
    :Registrar estado FINALIZADA y fecha de fin;
    |Frontend Angular|
    :Mostrar confirmación y actualizar detalle;
  else (No)
    |Frontend Angular|
    :Mostrar error de finalización;
  endif
else (No)
  if (¿Desea anular la visita?) then (Sí)
    |Usuario técnico|
    :Confirmar anulación e indicar motivo;
    |Backend / SQL Server|
    :Validar estado INICIADA y fecha de fin;
    if (¿Anulación permitida?) then (Sí)
      :Registrar estado ANULADA y motivo auditado;
      |Frontend Angular|
      :Informar anulación y actualizar detalle;
    else (No)
      |Frontend Angular|
      :Mostrar error de anulación;
    endif
  else (No)
    |Frontend Angular|
    :Conservar visita en estado INICIADA;
  endif
endif

stop
@enduml
```

**Correspondencia con el código:** `visitas-list.ts`, `visita-detail.ts`, casos de uso `iniciar-visita`, `editar-visita`, `finalizar-visita`, `anular-visita`, `VisitApplicationService`; migraciones `V28__CP_campo.PA_VisitaTecnica_Ins_Iniciar.sql`, `V31__CP_campo.PA_VisitaTecnica_Upd_Anular.sql` y `V32__CP_campo.PA_VisitaTecnica_Upd_Finalizar.sql`. En la implementación, una visita se inicia a través del **participante de una salida**, no mediante una visita aislada.

---

## ACT-03 — Registro y procesamiento de una venta POS

**Objetivo:** representar la venta en punto de venta, desde la selección del almacén hasta el cobro y entrega.  
**Inicio:** un usuario autorizado ingresa al POS desde una UOT específica.  
**Fin esperado:** venta en estado `ENTREGADA` y carrito liberado.  
**Variantes:** cliente existente, cliente importado o registro manual permitido; validaciones de stock, método de pago y errores recuperables al cobrar o entregar.

```plantuml
@startuml
title ACT-03 - Registro y procesamiento de una venta POS

skinparam backgroundColor #FFFFFF
skinparam shadowing false
skinparam defaultFontName Arial
skinparam defaultFontSize 13
skinparam activityBackgroundColor #EBF3FC
skinparam activityBorderColor #3972A5
skinparam activityFontColor #153957
skinparam diamondBackgroundColor #FFF3D9
skinparam diamondBorderColor #BA851D
skinparam arrowColor #57738F

|Operador POS|
start
:Ingresar al punto de venta;
|Frontend Angular|
:Verificar sesión y UOT específica;
if (¿Contexto UOT específico disponible?) then (No)
  :Solicitar selección de UOT específica;
  stop
endif

:Cargar almacenes, métodos de pago y catálogo;
|Operador POS|
:Seleccionar almacén;
:Agregar productos y cantidades al carrito;
:Elegir tipo y documento del cliente;

|Frontend Angular|
:Validar longitud del DNI o RUC;
if (¿Documento válido?) then (No)
  :Solicitar corrección del documento;
  stop
endif

:Solicitar resolución del cliente;
|Backend / SQL Server|
:Buscar cliente registrado en DESCO;
if (¿Cliente existente?) then (Sí)
  :Recuperar datos del cliente;
else (No)
  :Intentar validación externa cuando corresponda;
  if (¿Se obtuvo y registró el cliente?) then (Sí)
    :Devolver cliente disponible;
  else (No)
    if (¿Se permite registro manual?) then (Sí)
      |Operador POS|
      :Completar datos del cliente manualmente;
      |Backend / SQL Server|
      :Validar y registrar o reutilizar cliente;
      if (¿Registro manual correcto?) then (No)
        |Frontend Angular|
        :Mostrar error de cliente;
        stop
      endif
    else (No)
      |Frontend Angular|
      :Informar que aún no puede continuar;
      stop
    endif
  endif
endif

|Operador POS|
:Seleccionar método de pago;
:Ingresar número de operación cuando se exija;
:Revisar y confirmar el carrito;
|Frontend Angular|
:Validar cliente, almacén, carrito y método;
:Comprobar cantidades contra stock mostrado;
if (¿Venta válida para enviar?) then (No)
  :Mostrar campos o cantidades a corregir;
  stop
endif

if (¿Existe una venta pendiente para reanudar?) then (Sí)
  :Recuperar identificador de venta pendiente;
else (No)
  :Solicitar creación de venta con clave idempotente;
  |Backend / SQL Server|
  :Validar permisos, precios vigentes y stock;
  if (¿Creación aceptada?) then (No)
    |Frontend Angular|
    :Mostrar error y conservar datos de reintento;
    stop
  endif
  :Registrar venta y detalle;
endif

|Backend / SQL Server|
:Consultar estado y saldo de la venta;
if (¿Venta anulada?) then (Sí)
  |Frontend Angular|
  :Informar que no puede reanudarse;
  stop
endif

if (¿Existe saldo pendiente?) then (Sí)
  |Frontend Angular|
  :Solicitar cobro por el saldo pendiente;
  |Backend / SQL Server|
  :Registrar pago con clave idempotente;
  if (¿Pago confirmado por el sistema?) then (No)
    |Frontend Angular|
    :Conservar venta pendiente para reanudar;
    :Mostrar error de cobro;
    stop
  endif
  :Consultar venta y saldo actualizado;
endif

if (¿Venta ya ENTREGADA?) then (No)
  |Frontend Angular|
  :Solicitar entrega con clave idempotente;
  |Backend / SQL Server|
  :Verificar venta PAGADA y existencias;
  if (¿Entrega permitida?) then (No)
    |Frontend Angular|
    :Conservar venta pendiente para reanudar;
    :Mostrar error de entrega;
    stop
  endif
  :Descontar stock y registrar movimiento Kardex;
  :Actualizar venta a ENTREGADA;
endif

|Frontend Angular|
:Consultar estado final de la venta;
:Mostrar comprobación de venta completada;
:Limpiar carrito y recargar catálogo;
|Operador POS|
:Consultar el resultado de la venta;
stop
@enduml
```

**Correspondencia con el código:** `pos-page.ts`, `pos-cart.store.ts`, `procesar-venta-pos.use-case.ts`, `pos-http.adapter.ts`, `SaleController`, `SaleApplicationService`, migraciones `V395__AP_comercial.PA_Venta_Ins_Registrar.sql` y `V406__AP_comercial.PA_Venta_Upd_Entregar.sql`. El caso de uso POS **crea o recupera la venta, registra el pago de su saldo y finalmente solicita la entrega**. La entrega se realiza únicamente cuando se cumplen las condiciones de pago y existencias.

---

## ACT-04 — Registro de pago a un socio por liquidación

**Objetivo:** representar el registro y la confirmación del pago asociado a una liquidación de socio existente.  
**Inicio:** el responsable autorizado accede a pagos a socios y solicita registrar uno nuevo.  
**Fin esperado:** pago `CONFIRMADO`, con saldo de la liquidación actualizado según los pagos confirmados; también puede quedar `REGISTRADO` mientras espera confirmación.  
**Reglas relevantes:** liquidación `APROBADA` o `PAGADA_PARCIAL`, importe positivo no superior al saldo y confirmación en una acción independiente.

```plantuml
@startuml
title ACT-04 - Registro de pago a un socio por liquidación

skinparam backgroundColor #FFFFFF
skinparam shadowing false
skinparam defaultFontName Arial
skinparam defaultFontSize 13
skinparam activityBackgroundColor #EBF3FC
skinparam activityBorderColor #3972A5
skinparam activityFontColor #153957
skinparam diamondBackgroundColor #FFF3D9
skinparam diamondBorderColor #BA851D
skinparam arrowColor #57738F

|Responsable financiero|
start
:Ingresar al módulo Pagos a socios;
:Seleccionar «Registrar pago»;
:Indicar identificador de liquidación;
:Ingresar importe y medio de pago;
:Ingresar número de operación, si corresponde;

|Frontend Angular|
:Validar liquidación, importe positivo y medio;
if (¿Formulario correcto?) then (No)
  :Mostrar errores de ingreso;
  stop
endif

:Enviar solicitud de registro de pago;
|Backend / SQL Server|
:Validar permiso para crear pagos;
:Consultar liquidación del socio;
if (¿Liquidación APROBADA o PAGADA_PARCIAL?) then (No)
  |Frontend Angular|
  :Informar que la liquidación no admite pagos;
  stop
endif

:Obtener saldo pendiente actual;
if (¿Importe dentro del saldo disponible?) then (No)
  |Frontend Angular|
  :Informar importe no permitido;
  stop
endif

:Insertar pago en estado REGISTRADO;
:Registrar auditoría e idempotencia;
|Frontend Angular|
:Mostrar «Pago registrado»;
|Responsable financiero|
:Consultar detalle del pago;

if (¿Desea confirmar el pago?) then (No)
  |Frontend Angular|
  :Mantener pago en estado REGISTRADO;
  stop
endif

:Seleccionar «Confirmar pago»;
:Confirmar la operación en el diálogo;
|Frontend Angular|
:Enviar solicitud independiente de confirmación;
|Backend / SQL Server|
:Verificar permiso y estado REGISTRADO;
:Recalcular saldo pendiente de la liquidación;
if (¿Pago aún válido para confirmar?) then (No)
  |Frontend Angular|
  :Mostrar rechazo de confirmación;
  :Conservar información para revisión;
  stop
endif

:Actualizar pago a estado CONFIRMADO;
:Registrar fecha, usuario y auditoría;
:Actualizar estado de liquidación según saldo;
if (¿Queda saldo por pagar?) then (Sí)
  :Liquidación PAGADA_PARCIAL;
else (No)
  :Liquidación PAGADA;
endif

|Frontend Angular|
:Mostrar confirmación satisfactoria;
:Recargar detalle y saldos actualizados;
|Responsable financiero|
:Consultar pago confirmado y saldo restante;
stop
@enduml
```

**Correspondencia con el código:** `pago-socio-form.ts`, `pago-socio-detail.ts`, `pagos-socios-http.adapter.ts`, `liquidaciones-list.ts`, `liquidacion-detail.ts`, `PaymentController`, `PaymentApplicationService`; migraciones `V125__CP_finanzas.PA_LiquidacionSocio_Upd_Aprobar.sql`, `V126__CP_finanzas.PA_Liquidacion_Sel_SaldoPendienteInterno.sql`, `V127__CP_finanzas.PA_PagoSocio_Ins_Registro.sql` y `V131__CP_finanzas.PA_PagoSocio_Upd_Confirmar.sql`. En DESCO **registrar** y **confirmar** el pago son dos acciones independientes; los pagos `REGISTRADO` no se suman como pagados hasta su confirmación.

---

## Uso del documento

1. Copia el contenido de un bloque `plantuml`, incluyendo `@startuml` y `@enduml`.
2. Pégalo en un editor compatible con PlantUML y genera la imagen PNG o SVG.
3. Incorpora las figuras en el apartado de *diagramas de actividades* de la tesis, conservando los códigos ACT-01 a ACT-04.

**Observación metodológica:** los diagramas representan los **procesos implementados en DESCO** a un nivel apropiado para una tesis. Los mensajes de error y la presentación exacta pueden variar en ejecución; los controles de acceso y reglas de negocio se mantienen en el backend y SQL Server. En ACT-01 la validación de correo y el cambio obligatorio de contraseña concluyen llevando a un nuevo inicio de sesión, conforme a la navegación implementada.
