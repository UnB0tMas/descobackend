# ROADMAP MAESTRO BACKEND DESCO
## Arquitectura hexagonal + SQL Server por procedimientos almacenados + OpenAPI/Swagger + E2E escalonado

**Fecha de baseline:** 29/08/2026  
**Proyecto:** DESCO UOT Sara Sara  
**Backend:** Java 21 + Spring Boot 4.1.1 + Spring Security + JDBC + JWT + Argon2 + Thymeleaf + OpenAPI  
**Persistencia:** SQL Server `DESCO_DB` mediante procedimientos almacenados.  
**Regla principal:** no se implementará lógica funcional de manipulación, cálculo, estados, permisos o transacciones en Java cuando esa responsabilidad ya pertenece al PA.

---

# 1. FUENTES REVISADAS Y CRITERIO DE AUTORIDAD

Este roadmap se deriva de tres archivos actuales:

1. **`SQL_DB_DESCO(2).sql`**
   - Snapshot de `DESCO_DB`.
   - 87 tablas de usuario.
   - 242 procedimientos almacenados.
   - 0 vistas.
   - 0 funciones.
   - 0 triggers DML.
   - La base ya contiene catálogos, permisos y configuración RBAC, aunque conserva inconsistencias de semillas que se detallan en Fase 0.

2. **`desco_codigo(1).md`**
   - Snapshot del backend actual.
   - 76 archivos extraídos.
   - Ya contiene el adaptador de entrada de seguridad, DTOs de Auth, `AuthApplicationService`, dominio de autenticación, configuración de Spring Security y configuración OpenAPI.

3. **`SISTEMA_TESIS(1).md`**
   - Contrato funcional oficial.
   - Define 32 módulos en la Parte XXXIV.
   - Define permisos modulares en la Parte XXXV.
   - Define estados visibles y transiciones en la Parte XXXVI.
   - Define el flujo operativo completo en §37.1–§37.51.
   - Define matriz completa de acceso por rol en la Parte XXXVIII.
   - Define el criterio de terminado para cada módulo en §39.1–§39.32.

> **Cita directa — `SISTEMA_TESIS(1).md`, objetivo:** “el sistema se diseña alrededor de procesos reales de DESCO, no como una colección de mantenimientos aislados.”

Esta frase determina el orden del roadmap: **se programa por dependencia de proceso y no por el orden visual del sidebar**.

---

# 2. DECISIÓN DE ARQUITECTURA

La plataforma backend queda organizada como arquitectura hexagonal real:

```text
                     ┌─────────────────────────────┐
                     │        Angular / HTTP       │
                     └──────────────┬──────────────┘
                                    │
                             ADAPTER IN
                                    │
                     Controller / Request / Response
                                    │
                                PORT IN
                                    │
                              Use Case
                                    │
                         Application Service
                                    │
                                PORT OUT
               ┌────────────────────┼────────────────────┐
               │                    │                    │
               ▼                    ▼                    ▼
        SQL Server Adapter     Security Adapter      Mail Adapter
               │                    │                    │
          PA / JDBC             JWT / Argon2          Thymeleaf
               │
               ▼
           DESCO_DB
```

## 2.1. Regla de dependencia

```text
domain
    NO depende de Spring
    NO depende de JDBC
    NO depende de Swagger
    NO depende de SQL Server

application
    depende de domain
    depende de puertos
    NO depende de HttpServletRequest
    NO depende de JdbcTemplate
    NO depende de SimpleJdbcCall
    NO depende de OpenAPI

adapter.in.web
    conoce Spring MVC
    conoce Swagger/OpenAPI
    convierte Request → Command/Query
    convierte Result → Response

adapter.out.sqlserver
    conoce JDBC
    conoce nombres de PA
    conoce ResultSet / OUTPUT params
    implementa puertos

infrastructure
    configura Spring Security
    configura OpenAPI
    configura CORS
    configura DataSource
    configura correo
```

---

# 3. PRINCIPIO DE REUTILIZACIÓN

**Reutilizar no significa crear un `GenericCrudController` para todo.**

Se reutilizará la infraestructura técnica, mientras cada módulo conserva contratos explícitos para OpenAPI.

## Sí se reutiliza

- `ApiResponse<T>`.
- `ApiResponseFactory`.
- `AppResult<T>`.
- `AppStatus`.
- `CorrelationIdFilter`.
- `ClientRequestContextResolver`.
- `RequestMetadata`.
- `SessionIdentity`.
- `PermissionGuard`.
- validación de sesión.
- ejecutor genérico de PA.
- fábrica de payload técnico para PA.
- lectura segura de ResultSet.
- paginación.
- idempotencia.
- hash del request.
- traducción de errores técnicos.
- OpenAPI common headers.
- pruebas contractuales comunes.

## No se reutiliza mediante “CRUD genérico”

Cada módulo tendrá:
- Controller explícito.
- Request explícito.
- Response explícito.
- Command/Query explícito.
- UseCase explícito.
- Port OUT explícito.
- Adapter SQL explícito.

Esto conserva un OpenAPI legible y evita contratos ambiguos en Angular.

---

# 4. CORRECCIONES BLOQUEANTES ANTES DE PROGRAMAR MÓDULOS — FASE 0

## 4.1. El backend extraído no contiene todos los puertos de salida que ya consume

En `desco_codigo(1).md`, `AuthApplicationService`, `PermissionGuard`, `SessionValidationFilter` y `ApplicationBeanConfig` hacen referencia a contratos que **no aparecen entre los 76 archivos extraídos**:

- `AuthPersistencePort`
- `PasswordHashPort`
- `DeviceFingerprintPort`
- `OtpPort`
- `RefreshTokenPort`
- `SecurityMailPort`
- `SecurityNotificationPort`
- `AccessTokenPort`
- `AuthorizationPort`
- `SessionValidationPort`
- `RequestHashPort`

También aparece una referencia a:
- `PaExecutionException`

Pero no aparece su implementación en `adapter.out.sqlserver.shared`.

### Gate F0-A

Antes de Productores, el proyecto debe:

```text
mvn clean test
```

y compilar sin imports internos faltantes.

Si esas clases existen físicamente pero el extractor no las incluyó, corregir primero el extractor y regenerar `desco_codigo.md`.  
Si realmente no existen, deben implementarse como parte de la plataforma hexagonal antes de continuar.

---

## 4.2. Falta el adaptador OUT reutilizable para SQL Server

El backend actual incluye la aplicación de Auth, pero el snapshot no muestra:

```text
adapter/out/sqlserver/shared/
    SqlServerPaExecutor
    PaExecutionException
    SqlValues
    PaResultSets
    PaPayloadFactory
```

ni:

```text
adapter/out/sqlserver/auth/
    AuthSqlServerAdapter
```

### Gate F0-B

No crear adapters SQL específicos de módulos hasta tener un ejecutor compartido capaz de:

1. Ejecutar PA con parámetros escalares.
2. Ejecutar PA cuyo contrato principal sea JSON.
3. Leer una fila.
4. Leer listas.
5. Leer múltiples resultsets.
6. Leer parámetros OUTPUT.
7. Mantener `NULL` correctamente.
8. Traducir `SQLException`/errores JDBC a una excepción técnica única.
9. No filtrar mensajes SQL al usuario.
10. Permitir que el adapter del módulo convierta únicamente el resultado del PA a un resultado de aplicación.

---

## 4.3. La semilla RBAC actual todavía tiene duplicados

El snapshot actual de `seg.Rol` contiene **11 roles**, no 9.

Duplicados semánticos detectados:

```text
OPERADOR_COMERCIAL
OPERADOR_COMERCIAL_ACOPIO

RESPONSABLE_FINANZAS
RESPONSABLE_FINANZAS_TESORERIA
```

El roadmap adopta como códigos canónicos:

```text
OPERADOR_COMERCIAL
RESPONSABLE_FINANZAS
```

porque ya forman parte del grupo original de nueve roles y coinciden con la nomenclatura compacta utilizada en la BD.

### Gate F0-C

Antes de crear usuarios reales:

1. Consolidar los permisos de los roles duplicados en el rol canónico.
2. Migrar cualquier `UsuarioRol` si llegara a existir.
3. Desactivar/eliminar los aliases redundantes.
4. Verificar que queden exactamente 9 roles funcionales base.

Actualmente el dump muestra `seg.Usuario = 0`, por lo que este es el mejor momento para sanearlo.

---

## 4.4. Existen dos generaciones de agrupadores del menú

El dump actual muestra 44 módulos porque conviven:

```text
GESTION_TECNICA          ↔ GRP_TECNICA
GESTION_COMERCIAL        ↔ GRP_COMERCIAL
RECURSOS_GRUPO           ↔ GRP_RECURSOS
FINANZAS_GRUPO           ↔ GRP_FINANZAS
ADMINISTRACION_GRUPO     ↔ GRP_ADMINISTRACION
REPORTES_CONTROL         ↔ GRP_REPORTES_CONTROL
```

Los módulos funcionales actuales apuntan a los nuevos `GRP_*`.

### Gate F0-D

1. Mantener una sola generación de grupos.
2. No duplicar permisos por grupo.
3. No mostrar grupos huérfanos en `/auth/me`.
4. Ejecutar un test que compruebe que cada módulo visible tiene como máximo un padre activo.

---

# 5. PLATAFORMA REUTILIZABLE QUE DEBE QUEDAR CERRADA EN FASE 0

## 5.1. PaExecutor

Contrato técnico interno del adapter OUT:

```text
executeOne(...)
executeList(...)
executeMultiResult(...)
executeMutation(...)
```

No forma parte de `domain` ni de `application`.

## 5.2. PaPayloadFactory

Para todo PA de negocio que use contexto transversal, debe construir siempre:

```json
{
  "contexto": {
    "sesionPublicaId": "...",
    "correlacionId": "...",
    "solicitudId": "...",
    "claveIdempotencia": "...",
    "requestHashHex": "...",
    "ip": "...",
    "endpoint": "..."
  },
  "datos": {
  }
}
```

La clave es que **cada módulo solo rellene `datos`**.

## 5.3. PageRequest / PageResponse

Los listados deben usar un contrato uniforme:

```text
PageRequest
    pagina
    tamanio
    filtros
    orden

PageResponse<T>
    items
    pagina
    tamanio
    totalRegistros
    totalPaginas
```

La paginación real sigue en el PA.

## 5.4. Idempotencia

Toda escritura:

```text
POST
PUT
PATCH
DELETE lógico
confirmar
aprobar
anular
cerrar
```

debe aceptar:

```text
X-Idempotency-Key
```

El backend:
- lee la clave;
- calcula `requestHashHex`;
- agrega contexto;
- no decide duplicidad.

El PA decide si:
- inicia;
- reutiliza resultado;
- rechaza hash distinto;
- finaliza la operación.

## 5.5. Seguridad por permiso

No crear:

```text
ProductorAdministradorController
ProductorTecnicoController
ProductorAuditorController
```

Debe existir:

```text
ProductorController
```

y cada acción usa permiso:

```java
@PreAuthorize(
    "@permissionGuard.has(authentication, 'PRODUCTORES_CREAR')"
)
```

El mismo endpoint sirve a cualquier rol que obtenga ese permiso.

> **Cita directa — `SISTEMA_TESIS(1).md`, Parte XXXV:** “El permiso puede asignarse a uno o varios roles.”  
> **Cita directa — Parte XXXV:** “Un intento directo sin permiso debe ser rechazado.”  
> **Cita directa — Parte XXXV:** “El estado del proceso puede restringir la acción incluso si existe permiso.”

---

# 6. REGLA DE ESTADOS

Java **no contiene la máquina de estados**.

No hacer:

```java
if (estado.equals("PLANIFICACION")) {
    ...
}
```

para decidir una transición funcional.

Java puede:
- mostrar el estado devuelto;
- documentarlo;
- transportar el request;
- mapear la respuesta.

El PA:
- valida estado actual;
- valida transición;
- registra auditoría;
- actualiza estado;
- devuelve mensaje.

> **Cita directa — `SISTEMA_TESIS(1).md`, Parte XXXVI:** “No se cambia el estado mediante un selector genérico sin reglas.”

Estados que deben incluirse en las pruebas E2E:

```text
Salida       BORRADOR → PROGRAMADA → EN_CURSO → FINALIZADA / CANCELADA
Visita       INICIADA → FINALIZADA / ANULADA
Cultivo      ACTIVO → FINALIZADO / ABANDONADO
Sanidad      DETECTADO → EN_TRATAMIENTO → EN_SEGUIMIENTO → ... → CERRADO
Producción   ESTIMADA → CONFIRMADA / DESCARTADA
Campaña      PLANIFICACION → ACTIVA → CERRADA / CANCELADA
Operativo    PLANIFICADO → EN_RECEPCION → CERRADO / CANCELADO
Participación ACTIVO → RETIRADO / EXCLUIDO
Entrega      REGISTRADA → CONFIRMADA / ANULADA
Incidencia   ABIERTA → EN_REVISION → RESUELTA / ANULADA
Gasto        REGISTRADO → APROBADO / ANULADO
Liquidación  BORRADOR/CALCULADA → APROBADA → PAGADA_PARCIAL/PAGADA / ANULADA
Pago         REGISTRADO → CONFIRMADO / ANULADO
Cobro        REGISTRADO → CONFIRMADO / ANULADO
```

Fuente: `SISTEMA_TESIS(1).md`, §36.1–§36.16.

---

# 7. ESTÁNDAR OPENAPI OBLIGATORIO PARA TODOS LOS MÓDULOS

Todos los controllers deben seguir el mismo estándar.

```java
@RestController
@RequestMapping("/api/v1/productores")
@Tag(
    name = "Productores",
    description = "Gestión de productores y socios."
)
```

Cada operación:

```java
@Operation(
    operationId = "productoresCrear",
    summary = "Registrar productor",
    description = "Requiere el permiso PRODUCTORES_CREAR."
)
@SecurityRequirement(
    name = OpenApiConstants.BEARER_AUTH
)
@PreAuthorize(
    "@permissionGuard.has(authentication, 'PRODUCTORES_CREAR')"
)
```

## Convención de `operationId`

```text
<modulo>Listar
<modulo>Ver
<modulo>Crear
<modulo>Editar
<modulo>Retirar
<modulo>Confirmar
<modulo>Aprobar
<modulo>Exportar
```

Las acciones especiales mantienen nombres explícitos:

```text
campaniasActivar
campaniasCerrar
operativosAsignarZonas
jabasRegistrarDevolucion
liquidacionesRecalcular
pagosConfirmar
```

## DTO expuesto

Todos los `Request` y `Response` de `adapter.in.web`:
- `@Schema`;
- ejemplos;
- restricciones;
- campos sensibles `WRITE_ONLY`;
- identificadores y fechas tipados correctamente.

## No exponer en OpenAPI

```text
HttpServletRequest
JwtAuthenticationToken
JdbcTemplate
ResultSet
SimpleJdbcCall
SessionIdentity interno
```

---

# 8. INVENTARIO REAL DE PA POR ESQUEMA

La BD actual ya contiene la mayor parte del contrato funcional.

| Esquema | PA |
|---|---:|
| `seg` | 50 |
| `comercial` | 52 |
| `finanzas` | 25 |
| `logistica` | 22 |
| `org` | 22 |
| `prod` | 21 |
| `campo` | 17 |
| `sanidad` | 8 |
| `auditoria` | 8 |
| `geo` | 5 |
| `archivo` | 4 |
| `config` | 4 |
| `reporte` | 3 |
| `dbo` | 1 |
| **TOTAL** | **242** |

Consecuencia: el backend debe priorizar **adaptar contratos existentes** antes que solicitar nuevos PA.

---

# 9. ROADMAP MACRO

```text
F0  Estabilizar arquitectura + adapters OUT + sanear RBAC/menu
 │
 ▼
F1  Organizaciones + Roles + Catálogos/Geo + Empleados + Usuarios + Mi cuenta
 │
 ▼
F2  Documentos y evidencias reutilizables
 │
 ▼
F3  Productor → Predio → Parcela/Cultivo → Censo
 │
 ▼
F4  Inventario → Salida → Recursos → Visita → Evaluación → Sanidad → Producción
 │
 ▼
F5  Campaña → Condiciones/Precio → Participantes → Operativo
 │                           ↓
 │                     Jabas → Entrega → Incidencias/Ajustes
 │
 ▼
F6  Gastos → Prorrateo → Liquidación → Pago
 │                         └────────────→ Cobro comprador
 │
 ▼
F7  Reportes → Auditoría → Dashboard consolidado
 │
 ▼
F8  E2E completo + hardening + congelamiento OpenAPI para Angular
```

---

# 10. MATRIZ COMPLETA DE IMPLEMENTACIÓN

| # | Fase | Módulo | Código | Dependencia principal | PA / familia principal | Ancla funcional |
|---:|:---:|---|---|---|---|---|
| 1 | F1 | Empresas, asociaciones y áreas | `ORGANIZACIONES` | Seguridad base; catálogos/geo cuando aplique | `org.PA_Empresa_*; org.PA_Asociacion_*; org.PA_Area_*` | SISTEMA_TESIS §37.1 |
| 2 | F1 | Roles y permisos | `ROLESPERMISOS` | Seguridad base; datos RBAC saneados | `seg.PA_Rol_*; seg.PA_RolPermiso_Upd_Asignaciones; seg.PA_Autorizacion_Sel_ValidarDelegacionRoles` | SISTEMA_TESIS §37.2 |
| 3 | F1 | Catálogos + geografía de apoyo | `CATALOGOS` | Seguridad base | `config.PA_Catalogo_*; geo.PA_Departamento_Sel_Listado; geo.PA_Provincia_Sel_PorDepartamento; geo.PA_Distrito_Sel_PorProvincia; geo.PA_CentroPoblado_Sel_PorDistrito` | SISTEMA_TESIS §37.8 |
| 4 | F1 | Empleados | `EMPLEADOS` | Organizaciones; roles base ya sembrados | `org.PA_Empleado_Sel_*; org.PA_Empleado_Ins_RegistroAdministracion; org.PA_Empleado_Upd_RegistroAdministracion; org.PA_Empleado_Upd_RetirarAdministracion` | SISTEMA_TESIS §37.1 |
| 5 | F1 | Usuarios y accesos | `USUARIOS` | Empleados; Roles y permisos; correo de seguridad | `seg.PA_UsuarioAdmin_*; seg.PA_UsuarioRol_Ins_Asignar; seg.PA_UsuarioRol_Upd_Retirar` | SISTEMA_TESIS §37.2–§37.5 |
| 6 | F1 | Mi cuenta: seguridad, sesiones y dispositivos | `CUENTA` | Auth completo; Usuario | `seg.PA_Sesion_Sel_Listado; seg.PA_Sesion_Upd_Cerrar; seg.PA_Sesion_Upd_CerrarOtras; seg.PA_Dispositivo_Sel_Listado; seg.PA_Dispositivo_Upd_Reconocimiento; seg.PA_Usuario_Upd_CambiarPassword; seg.PA_Usuario_Ins_SolicitarCambioCorreo; seg.PA_Usuario_Upd_ConfirmarCambioCorreo` | SISTEMA_TESIS §31.5–§31.7 |
| 7 | F2 | Documentos y evidencias — infraestructura transversal | `ARCHIVOS` | Usuario/sesión; almacenamiento externo definido | `archivo.PA_Archivo_Ins_Registro; archivo.PA_Archivo_Sel_Listado; archivo.PA_Archivo_Sel_Detalle; archivo.PA_Archivo_Upd_Retirar` | SISTEMA_TESIS §34.30 |
| 8 | F3 | Productores / socios | `PRODUCTORES` | Organizaciones; catálogos; geografía | `org.PA_Socio_Sel_Listado; org.PA_Socio_Sel_DetalleCompleto; org.PA_Socio_Ins_Registro; org.PA_Socio_Upd_Registro; org.PA_Socio_Del_Registro` | SISTEMA_TESIS §37.6 |
| 9 | F3 | Predios | `PREDIOS` | Productores; geo.Ubicacion | `prod.PA_Predio_Sel_Listado; prod.PA_Predio_Sel_DetalleCompleto; prod.PA_Predio_Ins_Registro; prod.PA_Predio_Upd_Registro; prod.PA_Predio_Del_Registro` | SISTEMA_TESIS §37.7–§37.9 |
| 10 | F3 | Parcelas y cultivos | `CULTIVOS` | Predios; VariedadPalta/catálogos | `prod.PA_ParcelaCultivo_Sel_Listado; prod.PA_ParcelaCultivo_Sel_DetalleExpediente; prod.PA_Parcela_Ins_Registro; prod.PA_Parcela_Upd_Registro; prod.PA_Cultivo_Ins_Registro; prod.PA_Cultivo_Upd_Registro; prod.PA_Cultivo_Upd_Finalizar` | SISTEMA_TESIS §37.10–§37.11 |
| 11 | F3 | Censos de plantas | `CENSOS` | Parcela/cultivo | `prod.PA_CensoPlantas_Sel_Historial; prod.PA_CensoPlantas_Ins_Registro; prod.PA_CensoPlantas_Upd_Registro` | SISTEMA_TESIS §37.12 |
| 12 | F4 | Inventario y vehículos | `INVENTARIO` | Organizaciones; catálogos TipoBien | `logistica.PA_BienInventario_*; logistica.PA_Vehiculo_*; logistica.PA_Suministro_*; logistica.PA_SuministroMovimiento_*` | SISTEMA_TESIS §37.14 |
| 13 | F4 | Salidas de campo | `SALIDAS` | Empleados; MotivoSalida | `campo.PA_SalidaCampo_Sel_*; campo.PA_SalidaCampo_Ins_Programar; campo.PA_SalidaCampo_Upd_Registro; campo.PA_SalidaCampo_Upd_Finalizar; campo.PA_SalidaCampo_Upd_Cancelar` | SISTEMA_TESIS §37.13 |
| 14 | F4 | Recursos programados | `RECURSOS` | Inventario; Salidas; posteriormente Campañas/Operativos | `logistica.PA_RecursoProgramado_*; logistica.PA_RecursoProgramado_Sel_ValidarDestinoInterno` | SISTEMA_TESIS §37.14 |
| 15 | F4 | Visitas técnicas | `VISITAS` | Predios; Salidas/participantes | `campo.PA_VisitaTecnica_Sel_*; campo.PA_VisitaTecnica_Ins_Iniciar; campo.PA_VisitaTecnica_Upd_Registro; campo.PA_VisitaTecnica_Upd_Finalizar; campo.PA_VisitaTecnica_Upd_Anular` | SISTEMA_TESIS §37.15 |
| 16 | F4 | Evaluaciones agronómicas | `EVALUACIONES` | Visitas; parcela/cultivo; TipoEvaluacion | `campo.PA_EvaluacionAgronomica_*; campo.PA_EvaluacionMateriaSeca_Ins_Registro` | SISTEMA_TESIS §37.16–§37.17 |
| 17 | F4 | Sanidad vegetal | `SANIDAD` | Visitas; parcela/cultivo; catálogo fitosanitario | `sanidad.PA_CasoFitosanitario_*; sanidad.PA_TratamientoFitosanitario_Ins_Registro; sanidad.PA_SeguimientoFitosanitario_Ins_Registro` | SISTEMA_TESIS §37.18–§37.20 |
| 18 | F4 | Producción disponible | `PRODUCCION` | Visitas; parcela/cultivo | `prod.PA_DisponibilidadProduccion_*` | SISTEMA_TESIS §37.21–§37.23 |
| 19 | F5 | Campañas de venta | `CAMPANIAS` | Producción; Asociación; Empresa comprador | `comercial.PA_CampaniaVenta_*` | SISTEMA_TESIS §37.24–§37.25 |
| 20 | F5 | Condiciones y precios | `PRECIOS` | Campañas; ModalidadVenta; VariedadPalta | `comercial.PA_CondicionComercial_*; comercial.PA_PrecioComercial_*` | SISTEMA_TESIS §37.26–§37.27 |
| 21 | F5 | Participantes de campaña | `PARTICIPANTES` | Campañas; SocioAsociacion | `comercial.PA_ParticipacionCampaniaSocio_*` | SISTEMA_TESIS §37.28 |
| 22 | F5 | Operativos de venta | `OPERATIVOS` | Campañas; participantes; zonas | `comercial.PA_OperativoVenta_*; comercial.PA_ParticipacionCampaniaSocio_Ins_ProgramarOperativo` | SISTEMA_TESIS §37.29–§37.31 |
| 23 | F5 | Control de jabas | `JABAS` | Operativos/OperativoSocio | `comercial.PA_Jabas_*` | SISTEMA_TESIS §37.32–§37.34 |
| 24 | F5 | Acopio y entregas | `ENTREGAS` | Operativos; participantes; predios; precios/condiciones | `comercial.PA_EntregaSocio_*` | SISTEMA_TESIS §37.35–§37.40 |
| 25 | F5 | Incidencias operativas | `INCIDENCIAS` | Operativos; entregas | `comercial.PA_IncidenciaOperativa_*` | SISTEMA_TESIS §37.39–§37.41 |
| 26 | F5 | Ajustes de precio | `AJUSTES` | Operativos; participantes; condiciones | `comercial.PA_AjustePrecioSocio_*` | SISTEMA_TESIS §33.18 / §37.41–§37.42 |
| 27 | F6 | Gastos | `GASTOS` | Campañas; participantes; reglas/tipos de gasto | `finanzas.PA_GastoCampania_*` | SISTEMA_TESIS §37.43–§37.44 |
| 28 | F6 | Liquidaciones | `LIQUIDACIONES` | Participantes; entregas; gastos prorrateados; ajustes | `finanzas.PA_LiquidacionSocio_*` | SISTEMA_TESIS §37.45–§37.46 |
| 29 | F6 | Pagos a socios | `PAGOS` | Liquidaciones aprobadas | `finanzas.PA_PagoSocio_*; finanzas.PA_Liquidacion_Sel_SaldoPendienteInterno` | SISTEMA_TESIS §37.47–§37.48 |
| 30 | F6 | Cobros de compradores | `COBROS` | Campañas | `finanzas.PA_CobroComprador_*; finanzas.PA_Campania_Sel_SaldoCompradorInterno` | SISTEMA_TESIS §37.49 |
| 31 | F7 | Reportes e indicadores | `REPORTES` | Todos los módulos operativos | `reporte.PA_Reporte_Sel_Catalogo; reporte.PA_Reporte_Sel_Datos; reporte.PA_Reporte_Sel_Exportacion` | SISTEMA_TESIS §37.50 |
| 32 | F7 | Auditoría | `AUDITORIA` | Seguridad/auditoría transversal; datos generados por todos los módulos | `auditoria.PA_Auditoria_Sel_Listado; auditoria.PA_Auditoria_Sel_Detalle; auditoria.PA_Auditoria_Sel_Exportacion` | SISTEMA_TESIS §37.51 |
| 33 | F7 | Dashboard | `INICIO` | Todos los módulos que alimentan indicadores | `dbo.PA_Dashboard_Sel_Resumen` | SISTEMA_TESIS §34.1 / §37.50 |

---

# 11. DETALLE MÓDULO POR MÓDULO

### 1. Empresas, asociaciones y áreas

**Fase:** F1 — Administración, RBAC, cuenta personal, catálogos y geografía

**Código de módulo / permiso:** `ORGANIZACIONES`

**Ruta REST propuesta:** `/api/v1/organizaciones`

**Dependencias que deben estar cerradas antes:** Seguridad base; catálogos/geo cuando aplique.

**Procedimientos almacenados que constituyen la fuente funcional:** `org.PA_Empresa_*; org.PA_Asociacion_*; org.PA_Area_*`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.1.  
**Criterio:** Base organizacional para empleados, campañas, inventario y asociaciones de productores.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 2. Roles y permisos

**Fase:** F1 — Administración, RBAC, cuenta personal, catálogos y geografía

**Código de módulo / permiso:** `ROLESPERMISOS`

**Ruta REST propuesta:** `/api/v1/roles`

**Dependencias que deben estar cerradas antes:** Seguridad base; datos RBAC saneados.

**Procedimientos almacenados que constituyen la fuente funcional:** `seg.PA_Rol_*; seg.PA_RolPermiso_Upd_Asignaciones; seg.PA_Autorizacion_Sel_ValidarDelegacionRoles`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.2.  
**Criterio:** Los roles agrupan permisos; la autorización final sigue siendo por permiso.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 3. Catálogos + geografía de apoyo

**Fase:** F1 — Administración, RBAC, cuenta personal, catálogos y geografía

**Código de módulo / permiso:** `CATALOGOS`

**Ruta REST propuesta:** `/api/v1/catalogos + /api/v1/geo`

**Dependencias que deben estar cerradas antes:** Seguridad base.

**Procedimientos almacenados que constituyen la fuente funcional:** `config.PA_Catalogo_*; geo.PA_Departamento_Sel_Listado; geo.PA_Provincia_Sel_PorDepartamento; geo.PA_Distrito_Sel_PorProvincia; geo.PA_CentroPoblado_Sel_PorDistrito`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.8.  
**Criterio:** Debe estar disponible antes de formularios de predio, cultivo, sanidad, logística, comercial y finanzas.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 4. Empleados

**Fase:** F1 — Administración, RBAC, cuenta personal, catálogos y geografía

**Código de módulo / permiso:** `EMPLEADOS`

**Ruta REST propuesta:** `/api/v1/empleados`

**Dependencias que deben estar cerradas antes:** Organizaciones; roles base ya sembrados.

**Procedimientos almacenados que constituyen la fuente funcional:** `org.PA_Empleado_Sel_*; org.PA_Empleado_Ins_RegistroAdministracion; org.PA_Empleado_Upd_RegistroAdministracion; org.PA_Empleado_Upd_RetirarAdministracion`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.1.  
**Criterio:** Empleado depende de Persona y Empresa; retiro debe revocar accesos según PA.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 5. Usuarios y accesos

**Fase:** F1 — Administración, RBAC, cuenta personal, catálogos y geografía

**Código de módulo / permiso:** `USUARIOS`

**Ruta REST propuesta:** `/api/v1/usuarios`

**Dependencias que deben estar cerradas antes:** Empleados; Roles y permisos; correo de seguridad.

**Procedimientos almacenados que constituyen la fuente funcional:** `seg.PA_UsuarioAdmin_*; seg.PA_UsuarioRol_Ins_Asignar; seg.PA_UsuarioRol_Upd_Retirar`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.2–§37.5.  
**Criterio:** Crear cuenta, asignar/quitar roles, estado de cuenta, detalle y dispositivos.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 6. Mi cuenta: seguridad, sesiones y dispositivos

**Fase:** F1 — Administración, RBAC, cuenta personal, catálogos y geografía

**Código de módulo / permiso:** `CUENTA`

**Ruta REST propuesta:** `/api/v1/account`

**Dependencias que deben estar cerradas antes:** Auth completo; Usuario.

**Procedimientos almacenados que constituyen la fuente funcional:** `seg.PA_Sesion_Sel_Listado; seg.PA_Sesion_Upd_Cerrar; seg.PA_Sesion_Upd_CerrarOtras; seg.PA_Dispositivo_Sel_Listado; seg.PA_Dispositivo_Upd_Reconocimiento; seg.PA_Usuario_Upd_CambiarPassword; seg.PA_Usuario_Ins_SolicitarCambioCorreo; seg.PA_Usuario_Upd_ConfirmarCambioCorreo`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §31.5–§31.7.  
**Criterio:** Completa lo que el sidebar llama Perfil / Seguridad / Sesiones / Dispositivos.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 7. Documentos y evidencias — infraestructura transversal

**Fase:** F2 — Infraestructura transversal de documentos/evidencias

**Código de módulo / permiso:** `ARCHIVOS`

**Ruta REST propuesta:** `/api/v1/documentos`

**Dependencias que deben estar cerradas antes:** Usuario/sesión; almacenamiento externo definido.

**Procedimientos almacenados que constituyen la fuente funcional:** `archivo.PA_Archivo_Ins_Registro; archivo.PA_Archivo_Sel_Listado; archivo.PA_Archivo_Sel_Detalle; archivo.PA_Archivo_Upd_Retirar`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §34.30.  
**Criterio:** Implementarlo temprano evita repetir carga/vinculación de evidencias en cada módulo.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 8. Productores / socios

**Fase:** F3 — Núcleo técnico maestro: productor → predio → parcela/cultivo → censo

**Código de módulo / permiso:** `PRODUCTORES`

**Ruta REST propuesta:** `/api/v1/productores`

**Dependencias que deben estar cerradas antes:** Organizaciones; catálogos; geografía.

**Procedimientos almacenados que constituyen la fuente funcional:** `org.PA_Socio_Sel_Listado; org.PA_Socio_Sel_DetalleCompleto; org.PA_Socio_Ins_Registro; org.PA_Socio_Upd_Registro; org.PA_Socio_Del_Registro`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.6.  
**Criterio:** Raíz de la cadena productiva y comercial.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 9. Predios

**Fase:** F3 — Núcleo técnico maestro: productor → predio → parcela/cultivo → censo

**Código de módulo / permiso:** `PREDIOS`

**Ruta REST propuesta:** `/api/v1/predios`

**Dependencias que deben estar cerradas antes:** Productores; geo.Ubicacion.

**Procedimientos almacenados que constituyen la fuente funcional:** `prod.PA_Predio_Sel_Listado; prod.PA_Predio_Sel_DetalleCompleto; prod.PA_Predio_Ins_Registro; prod.PA_Predio_Upd_Registro; prod.PA_Predio_Del_Registro`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.7–§37.9.  
**Criterio:** Predio referencia ubicación y titularidad del socio.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 10. Parcelas y cultivos

**Fase:** F3 — Núcleo técnico maestro: productor → predio → parcela/cultivo → censo

**Código de módulo / permiso:** `CULTIVOS`

**Ruta REST propuesta:** `/api/v1/cultivos`

**Dependencias que deben estar cerradas antes:** Predios; VariedadPalta/catálogos.

**Procedimientos almacenados que constituyen la fuente funcional:** `prod.PA_ParcelaCultivo_Sel_Listado; prod.PA_ParcelaCultivo_Sel_DetalleExpediente; prod.PA_Parcela_Ins_Registro; prod.PA_Parcela_Upd_Registro; prod.PA_Cultivo_Ins_Registro; prod.PA_Cultivo_Upd_Registro; prod.PA_Cultivo_Upd_Finalizar`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.10–§37.11.  
**Criterio:** Base para censos, evaluaciones, sanidad y producción.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 11. Censos de plantas

**Fase:** F3 — Núcleo técnico maestro: productor → predio → parcela/cultivo → censo

**Código de módulo / permiso:** `CENSOS`

**Ruta REST propuesta:** `/api/v1/censos`

**Dependencias que deben estar cerradas antes:** Parcela/cultivo.

**Procedimientos almacenados que constituyen la fuente funcional:** `prod.PA_CensoPlantas_Sel_Historial; prod.PA_CensoPlantas_Ins_Registro; prod.PA_CensoPlantas_Upd_Registro`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.12.  
**Criterio:** No debe existir antes del cultivo al que pertenece.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 12. Inventario y vehículos

**Fase:** F4 — Operación técnica y logística: inventario → salida → recursos → visita → evaluación/sanidad/producción

**Código de módulo / permiso:** `INVENTARIO`

**Ruta REST propuesta:** `/api/v1/inventario`

**Dependencias que deben estar cerradas antes:** Organizaciones; catálogos TipoBien.

**Procedimientos almacenados que constituyen la fuente funcional:** `logistica.PA_BienInventario_*; logistica.PA_Vehiculo_*; logistica.PA_Suministro_*; logistica.PA_SuministroMovimiento_*`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.14.  
**Criterio:** Se adelanta antes de recursos programados porque estos referencian bienes/suministros.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 13. Salidas de campo

**Fase:** F4 — Operación técnica y logística: inventario → salida → recursos → visita → evaluación/sanidad/producción

**Código de módulo / permiso:** `SALIDAS`

**Ruta REST propuesta:** `/api/v1/salidas-campo`

**Dependencias que deben estar cerradas antes:** Empleados; MotivoSalida.

**Procedimientos almacenados que constituyen la fuente funcional:** `campo.PA_SalidaCampo_Sel_*; campo.PA_SalidaCampo_Ins_Programar; campo.PA_SalidaCampo_Upd_Registro; campo.PA_SalidaCampo_Upd_Finalizar; campo.PA_SalidaCampo_Upd_Cancelar`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.13.  
**Criterio:** Estados BORRADOR/PROGRAMADA/EN_CURSO/FINALIZADA/CANCELADA.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 14. Recursos programados

**Fase:** F4 — Operación técnica y logística: inventario → salida → recursos → visita → evaluación/sanidad/producción

**Código de módulo / permiso:** `RECURSOS`

**Ruta REST propuesta:** `/api/v1/recursos-programados`

**Dependencias que deben estar cerradas antes:** Inventario; Salidas; posteriormente Campañas/Operativos.

**Procedimientos almacenados que constituyen la fuente funcional:** `logistica.PA_RecursoProgramado_*; logistica.PA_RecursoProgramado_Sel_ValidarDestinoInterno`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.14.  
**Criterio:** Diseñar desde el inicio para destinos SALIDA/CAMPAÑA/OPERATIVO sin duplicar servicios.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 15. Visitas técnicas

**Fase:** F4 — Operación técnica y logística: inventario → salida → recursos → visita → evaluación/sanidad/producción

**Código de módulo / permiso:** `VISITAS`

**Ruta REST propuesta:** `/api/v1/visitas`

**Dependencias que deben estar cerradas antes:** Predios; Salidas/participantes.

**Procedimientos almacenados que constituyen la fuente funcional:** `campo.PA_VisitaTecnica_Sel_*; campo.PA_VisitaTecnica_Ins_Iniciar; campo.PA_VisitaTecnica_Upd_Registro; campo.PA_VisitaTecnica_Upd_Finalizar; campo.PA_VisitaTecnica_Upd_Anular`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.15.  
**Criterio:** La visita es el nodo de entrada para evaluación, sanidad y producción.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 16. Evaluaciones agronómicas

**Fase:** F4 — Operación técnica y logística: inventario → salida → recursos → visita → evaluación/sanidad/producción

**Código de módulo / permiso:** `EVALUACIONES`

**Ruta REST propuesta:** `/api/v1/evaluaciones`

**Dependencias que deben estar cerradas antes:** Visitas; parcela/cultivo; TipoEvaluacion.

**Procedimientos almacenados que constituyen la fuente funcional:** `campo.PA_EvaluacionAgronomica_*; campo.PA_EvaluacionMateriaSeca_Ins_Registro`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.16–§37.17.  
**Criterio:** Incluye materia seca; no crear endpoints por rol.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 17. Sanidad vegetal

**Fase:** F4 — Operación técnica y logística: inventario → salida → recursos → visita → evaluación/sanidad/producción

**Código de módulo / permiso:** `SANIDAD`

**Ruta REST propuesta:** `/api/v1/sanidad`

**Dependencias que deben estar cerradas antes:** Visitas; parcela/cultivo; catálogo fitosanitario.

**Procedimientos almacenados que constituyen la fuente funcional:** `sanidad.PA_CasoFitosanitario_*; sanidad.PA_TratamientoFitosanitario_Ins_Registro; sanidad.PA_SeguimientoFitosanitario_Ins_Registro`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.18–§37.20.  
**Criterio:** Transiciones controladas únicamente mediante PA específicos.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 18. Producción disponible

**Fase:** F4 — Operación técnica y logística: inventario → salida → recursos → visita → evaluación/sanidad/producción

**Código de módulo / permiso:** `PRODUCCION`

**Ruta REST propuesta:** `/api/v1/produccion`

**Dependencias que deben estar cerradas antes:** Visitas; parcela/cultivo.

**Procedimientos almacenados que constituyen la fuente funcional:** `prod.PA_DisponibilidadProduccion_*`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.21–§37.23.  
**Criterio:** Es la entrada de negocio para el bloque comercial.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 19. Campañas de venta

**Fase:** F5 — Cadena comercial: campaña → precio → participantes → operativo → jabas → entrega → incidencias/ajustes

**Código de módulo / permiso:** `CAMPANIAS`

**Ruta REST propuesta:** `/api/v1/campanias`

**Dependencias que deben estar cerradas antes:** Producción; Asociación; Empresa comprador.

**Procedimientos almacenados que constituyen la fuente funcional:** `comercial.PA_CampaniaVenta_*`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.24–§37.25.  
**Criterio:** Raíz del flujo comercial y financiero.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 20. Condiciones y precios

**Fase:** F5 — Cadena comercial: campaña → precio → participantes → operativo → jabas → entrega → incidencias/ajustes

**Código de módulo / permiso:** `PRECIOS`

**Ruta REST propuesta:** `/api/v1/condiciones-precios`

**Dependencias que deben estar cerradas antes:** Campañas; ModalidadVenta; VariedadPalta.

**Procedimientos almacenados que constituyen la fuente funcional:** `comercial.PA_CondicionComercial_*; comercial.PA_PrecioComercial_*`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.26–§37.27.  
**Criterio:** El versionado debe delegarse al PA; Java no recalcula precios históricos.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 21. Participantes de campaña

**Fase:** F5 — Cadena comercial: campaña → precio → participantes → operativo → jabas → entrega → incidencias/ajustes

**Código de módulo / permiso:** `PARTICIPANTES`

**Ruta REST propuesta:** `/api/v1/participantes-campania`

**Dependencias que deben estar cerradas antes:** Campañas; SocioAsociacion.

**Procedimientos almacenados que constituyen la fuente funcional:** `comercial.PA_ParticipacionCampaniaSocio_*`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.28.  
**Criterio:** Base de operativos, gastos prorrateados y liquidaciones.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 22. Operativos de venta

**Fase:** F5 — Cadena comercial: campaña → precio → participantes → operativo → jabas → entrega → incidencias/ajustes

**Código de módulo / permiso:** `OPERATIVOS`

**Ruta REST propuesta:** `/api/v1/operativos`

**Dependencias que deben estar cerradas antes:** Campañas; participantes; zonas.

**Procedimientos almacenados que constituyen la fuente funcional:** `comercial.PA_OperativoVenta_*; comercial.PA_ParticipacionCampaniaSocio_Ins_ProgramarOperativo`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.29–§37.31.  
**Criterio:** OperativoSocio vincula operativo con participación.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 23. Control de jabas

**Fase:** F5 — Cadena comercial: campaña → precio → participantes → operativo → jabas → entrega → incidencias/ajustes

**Código de módulo / permiso:** `JABAS`

**Ruta REST propuesta:** `/api/v1/jabas`

**Dependencias que deben estar cerradas antes:** Operativos/OperativoSocio.

**Procedimientos almacenados que constituyen la fuente funcional:** `comercial.PA_Jabas_*`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.32–§37.34.  
**Criterio:** Saldo e historial provienen de PA; no calcular stock de jabas en Java.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 24. Acopio y entregas

**Fase:** F5 — Cadena comercial: campaña → precio → participantes → operativo → jabas → entrega → incidencias/ajustes

**Código de módulo / permiso:** `ENTREGAS`

**Ruta REST propuesta:** `/api/v1/entregas`

**Dependencias que deben estar cerradas antes:** Operativos; participantes; predios; precios/condiciones.

**Procedimientos almacenados que constituyen la fuente funcional:** `comercial.PA_EntregaSocio_*`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.35–§37.40.  
**Criterio:** Detalle, pesos, clasificación y valorización quedan en SQL.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 25. Incidencias operativas

**Fase:** F5 — Cadena comercial: campaña → precio → participantes → operativo → jabas → entrega → incidencias/ajustes

**Código de módulo / permiso:** `INCIDENCIAS`

**Ruta REST propuesta:** `/api/v1/incidencias`

**Dependencias que deben estar cerradas antes:** Operativos; entregas.

**Procedimientos almacenados que constituyen la fuente funcional:** `comercial.PA_IncidenciaOperativa_*`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.39–§37.41.  
**Criterio:** Resolver/anular solo mediante transiciones explícitas.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 26. Ajustes de precio

**Fase:** F5 — Cadena comercial: campaña → precio → participantes → operativo → jabas → entrega → incidencias/ajustes

**Código de módulo / permiso:** `AJUSTES`

**Ruta REST propuesta:** `/api/v1/ajustes-precio`

**Dependencias que deben estar cerradas antes:** Operativos; participantes; condiciones.

**Procedimientos almacenados que constituyen la fuente funcional:** `comercial.PA_AjustePrecioSocio_*`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §33.18 / §37.41–§37.42.  
**Criterio:** Impacto consultable; no recalcular impacto en Java.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 27. Gastos

**Fase:** F6 — Cadena financiera: gastos → liquidación → pagos/cobros

**Código de módulo / permiso:** `GASTOS`

**Ruta REST propuesta:** `/api/v1/gastos`

**Dependencias que deben estar cerradas antes:** Campañas; participantes; reglas/tipos de gasto.

**Procedimientos almacenados que constituyen la fuente funcional:** `finanzas.PA_GastoCampania_*`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.43–§37.44.  
**Criterio:** Prorrateo es lógica SQL; backend solo envía contrato y expone resultado.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 28. Liquidaciones

**Fase:** F6 — Cadena financiera: gastos → liquidación → pagos/cobros

**Código de módulo / permiso:** `LIQUIDACIONES`

**Ruta REST propuesta:** `/api/v1/liquidaciones`

**Dependencias que deben estar cerradas antes:** Participantes; entregas; gastos prorrateados; ajustes.

**Procedimientos almacenados que constituyen la fuente funcional:** `finanzas.PA_LiquidacionSocio_*`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.45–§37.46.  
**Criterio:** Es el módulo con mayor dependencia: implementar solo después de comercial + gastos.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 29. Pagos a socios

**Fase:** F6 — Cadena financiera: gastos → liquidación → pagos/cobros

**Código de módulo / permiso:** `PAGOS`

**Ruta REST propuesta:** `/api/v1/pagos`

**Dependencias que deben estar cerradas antes:** Liquidaciones aprobadas.

**Procedimientos almacenados que constituyen la fuente funcional:** `finanzas.PA_PagoSocio_*; finanzas.PA_Liquidacion_Sel_SaldoPendienteInterno`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.47–§37.48.  
**Criterio:** Saldo y transición de liquidación los gobierna SQL.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 30. Cobros de compradores

**Fase:** F6 — Cadena financiera: gastos → liquidación → pagos/cobros

**Código de módulo / permiso:** `COBROS`

**Ruta REST propuesta:** `/api/v1/cobros`

**Dependencias que deben estar cerradas antes:** Campañas.

**Procedimientos almacenados que constituyen la fuente funcional:** `finanzas.PA_CobroComprador_*; finanzas.PA_Campania_Sel_SaldoCompradorInterno`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.49.  
**Criterio:** Puede implementarse en paralelo a pagos una vez estable la campaña.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 31. Reportes e indicadores

**Fase:** F7 — Lectura global: reportes → auditoría → dashboard consolidado

**Código de módulo / permiso:** `REPORTES`

**Ruta REST propuesta:** `/api/v1/reportes`

**Dependencias que deben estar cerradas antes:** Todos los módulos operativos.

**Procedimientos almacenados que constituyen la fuente funcional:** `reporte.PA_Reporte_Sel_Catalogo; reporte.PA_Reporte_Sel_Datos; reporte.PA_Reporte_Sel_Exportacion`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.50.  
**Criterio:** Implementación final para evitar rehacer contratos mientras cambian módulos fuente.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 32. Auditoría

**Fase:** F7 — Lectura global: reportes → auditoría → dashboard consolidado

**Código de módulo / permiso:** `AUDITORIA`

**Ruta REST propuesta:** `/api/v1/auditoria`

**Dependencias que deben estar cerradas antes:** Seguridad/auditoría transversal; datos generados por todos los módulos.

**Procedimientos almacenados que constituyen la fuente funcional:** `auditoria.PA_Auditoria_Sel_Listado; auditoria.PA_Auditoria_Sel_Detalle; auditoria.PA_Auditoria_Sel_Exportacion`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §37.51.  
**Criterio:** La escritura de auditoría ya es transversal; el módulo final expone consulta.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.
### 33. Dashboard

**Fase:** F7 — Lectura global: reportes → auditoría → dashboard consolidado

**Código de módulo / permiso:** `INICIO`

**Ruta REST propuesta:** `/api/v1/dashboard`

**Dependencias que deben estar cerradas antes:** Todos los módulos que alimentan indicadores.

**Procedimientos almacenados que constituyen la fuente funcional:** `dbo.PA_Dashboard_Sel_Resumen`.

**Referencia directa a `SISTEMA_TESIS(1).md`:** §34.1 / §37.50.  
**Criterio:** Crear un endpoint mínimo antes si Angular lo necesita, pero cerrar el dashboard funcional al final.

**Qué implementar en el hexágono:**
- `adapter.in.web`: Controller, Request/Response y mapper HTTP.
- `application`: command/query/result y caso de uso.
- `application.port.out`: puerto semántico del módulo.
- `adapter.out.sqlserver`: adapter que llama únicamente a los PA de este módulo usando el ejecutor común.
- OpenAPI: `@Tag`, `@Operation(operationId=...)`, `@SecurityRequirement`, `@Schema` y respuestas funcionales.
- Seguridad: `@PreAuthorize("@permissionGuard.has(authentication, '<PERMISO>')")` por operación; el PA vuelve a validar permiso + sesión + estado.
- Escrituras: `X-Idempotency-Key`, `X-Correlation-Id`, hash de request y contexto técnico reutilizable.
- Pruebas: rol autorizado, rol no autorizado, estado permitido, estado no permitido y doble envío cuando exista escritura.


---

# 12. POR QUÉ ESTE ORDEN EVITA DEPENDENCIAS ROTAS

La propia BD confirma dependencias mediante claves foráneas:

```text
Empleado
    → Empresa + Persona

SocioAsociacion
    → Socio + Asociacion

PredioTitularidad
    → Socio + Predio

Parcela
    → Predio + Ubicacion

ParcelaCultivo
    → Parcela + VariedadPalta

CensoPlantas
    → ParcelaCultivo

VisitaTecnica
    → SalidaParticipante + Predio

EvaluacionAgronomica
    → VisitaTecnica + ParcelaCultivo

CasoFitosanitario
    → VisitaTecnica + ParcelaCultivo

DisponibilidadProduccion
    → VisitaTecnica + ParcelaCultivo

CampaniaVenta
    → Asociacion + Empresa

PrecioComercial
    → CampaniaVenta + CondicionComercial + VariedadPalta

ParticipacionCampaniaSocio
    → CampaniaVenta + SocioAsociacion

OperativoVenta
    → CampaniaVenta

OperativoSocio
    → OperativoVenta + ParticipacionCampaniaSocio

JabaAsignacion
    → OperativoSocio

EntregaSocio
    → OperativoSocio + Predio

IncidenciaOperativa
    → EntregaSocio + OperativoVenta

AjustePrecioSocio
    → OperativoVenta + ParticipacionCampaniaSocio + CondicionComercial

GastoCampania
    → CampaniaVenta + ReglaProrrateo + TipoGasto

GastoProrrateoSocio
    → GastoCampania + ParticipacionCampaniaSocio

LiquidacionSocio
    → ParticipacionCampaniaSocio

LiquidacionDetalle
    → LiquidacionSocio + EntregaDetalle + GastoProrrateoSocio + AjustePrecioSocio

PagoSocio
    → LiquidacionSocio

CobroComprador
    → CampaniaVenta
```

Por eso **Liquidaciones nunca debe programarse antes de Entregas + Gastos + Ajustes + Participantes**.

---

# 13. E2E ESCALONADO OBLIGATORIO

No esperar hasta el final para hacer un único E2E.

## E2E-0 — Seguridad

```text
Administrador/seed
    → Login
    → Validación correo
    → 2FA
    → JWT
    → /auth/me
    → refresh
    → logout
```

Debe probar:
- JWT válido/inválido;
- sesión revocada;
- permiso ausente;
- refresh rotado;
- OTP expirado;
- enumeración de usuario mitigada.

---

## E2E-1 — Administración

Fuente funcional: `SISTEMA_TESIS(1).md`, §37.1–§37.5.

```text
Empresa
  → Área
  → Empleado
  → Usuario
  → Rol
  → Validación correo
  → Login
  → Menú + permisos correctos
```

Gate:
- usuario con rol autorizado ve el módulo;
- usuario sin permiso recibe 403;
- segundo rol suma permisos;
- quitar rol elimina acceso sin modificar Java.

> **Cita directa — Parte XXXVIII:** “Si recibe un segundo rol, se suman sus permisos vigentes.”

---

## E2E-2 — Gestión técnica maestra

Fuente funcional: §37.6–§37.12.

```text
Productor
   → Predio
      → Ubicación
      → Parcela
         → Cultivo
            → Censo
```

Gate:
- detalle completo;
- filtros;
- paginación;
- historial;
- retiro/estado cuando corresponda;
- idempotencia de alta.

---

## E2E-3 — Campo + logística

Fuente funcional: §37.13–§37.23.

```text
Inventario
   ↓
Salida de campo
   ↓
Recursos asignados
   ↓
Visita técnica
   ├→ Evaluación
   ├→ Materia seca
   ├→ Caso fitosanitario → Tratamiento → Seguimiento
   └→ Producción estimada → Confirmada
```

Gate:
- no usar recursos no disponibles;
- no finalizar estados inválidos;
- evidencia vinculada;
- producción confirmada visible a comercial.

---

## E2E-4 — Comercial

Fuente funcional: §37.24–§37.42.

```text
Producción disponible
   ↓
Campaña
   ↓
Comprador
   ↓
Condiciones
   ↓
Precio/versiones
   ↓
Participantes
   ↓
Operativo + zonas
   ↓
Programación socios
   ↓
Jabas
   ↓
Entrega + detalle + ticket
   ↓
Incidencias / Ajustes
   ↓
Confirmación
   ↓
Cierre operativo
```

Gate:
- una transición inválida es rechazada;
- precio histórico no se reescribe;
- entrega confirmada ya no se edita como preliminar;
- jabas mantienen saldo correcto;
- doble envío no duplica movimientos.

---

## E2E-5 — Finanzas

Fuente funcional: §37.43–§37.49.

```text
Campaña
   ↓
Gastos
   ↓
Prorrateo
   ↓
Liquidación
   ↓
Aprobación
   ↓
Pago
   ↓
Confirmación pago

Comprador
   ↓
Cobro
   ↓
Confirmación cobro
```

Gate:
- prorrateo correcto desde PA;
- liquidación utiliza entregas/ajustes/gastos;
- pago no excede saldo;
- anulación recompone estado según PA;
- cobro actualiza saldo comprador.

---

## E2E-6 — Control

Fuente funcional: §37.50–§37.51.

```text
Datos operativos reales
   ↓
Dashboard
   ↓
Reportes
   ↓
Exportación
   ↓
Auditoría
```

Gate:
- auditor solo consulta;
- reportes filtran por acceso;
- trazabilidad muestra usuario, sesión, dispositivo, antes/después;
- exportar exige permiso correspondiente.

---

# 14. DEFINICIÓN DE TERMINADO DE CADA MÓDULO

`SISTEMA_TESIS(1).md`, Parte XXXIX, repite para los 32 módulos un checklist común.

Para backend lo convertimos en este **Definition of Done obligatorio**:

## Contrato

- [ ] Ruta `/api/v1/...` estable.
- [ ] Controller documentado con `@Tag`.
- [ ] Cada endpoint tiene `operationId` único.
- [ ] Request documentado con `@Schema`.
- [ ] Response documentado con `@Schema`.
- [ ] `/v3/api-docs` genera el contrato sin tipos internos.
- [ ] OpenAPI Generator puede generar Angular sin errores.

## Hexagonal

- [ ] No hay JDBC en `application`.
- [ ] No hay Spring MVC en `domain`.
- [ ] No hay OpenAPI en `domain`/`application`.
- [ ] Existe Port IN.
- [ ] Existe Port OUT semántico.
- [ ] Existe adapter SQL Server.
- [ ] El adapter usa infraestructura PA compartida.

## Seguridad

- [ ] Endpoint requiere Bearer cuando corresponde.
- [ ] `@PreAuthorize` valida permiso.
- [ ] Se prueba usuario con permiso.
- [ ] Se prueba usuario sin permiso.
- [ ] No hay `if (rol == ...)`.
- [ ] El PA vuelve a validar autorización.

## Escritura

- [ ] Idempotency key disponible.
- [ ] Request hash calculado.
- [ ] Correlation ID propagado.
- [ ] Doble envío probado.
- [ ] No hay INSERT/UPDATE/DELETE SQL directo desde Java.
- [ ] No hay transición de estado implementada en Java.

## Funcional

- [ ] Listado.
- [ ] Filtros.
- [ ] Paginación.
- [ ] Detalle.
- [ ] Registro si aplica.
- [ ] Edición si aplica.
- [ ] Retiro/anulación si aplica.
- [ ] Confirmación/aprobación si aplica.
- [ ] Historial si aplica.
- [ ] Archivos/evidencias si aplica.

## Estados

- [ ] Estado permitido probado.
- [ ] Estado no permitido probado.
- [ ] No existe endpoint genérico `cambiarEstado`.
- [ ] Cada transición sensible usa su PA específico.

## Mensajes

- [ ] Nunca retorna `SQLException`.
- [ ] Nunca retorna nombre de PA como error de usuario.
- [ ] Nunca retorna stacktrace.
- [ ] Mensaje funcional comprensible.
- [ ] Correlation ID disponible para soporte.

## Auditoría

- [ ] Acción sensible deja trazabilidad.
- [ ] Actor correcto.
- [ ] Sesión correcta.
- [ ] Correlación correcta.
- [ ] Antes/después cuando aplica.

> **Cita directa — `SISTEMA_TESIS(1).md`, Parte XXXIX:** cada módulo exige “prueba con rol autorizado”, “prueba con rol no autorizado”, “prueba con estado permitido”, “prueba con estado no permitido” y “prueba de doble envío”.

---

# 15. PLANTILLA DE PAQUETES PARA CADA MÓDULO

Ejemplo: Productores.

```text
com.franco.desco
│
├── domain
│   └── productor
│       ├── Productor.java
│       ├── ProductorDetalle.java
│       └── ProductorResumen.java
│
├── application
│   └── productor
│       ├── command
│       │   ├── CrearProductorCommand.java
│       │   ├── EditarProductorCommand.java
│       │   └── RetirarProductorCommand.java
│       ├── query
│       │   ├── ListarProductoresQuery.java
│       │   └── VerProductorQuery.java
│       ├── result
│       ├── port
│       │   ├── in
│       │   │   └── ProductorUseCase.java
│       │   └── out
│       │       └── ProductorPersistencePort.java
│       └── service
│           └── ProductorApplicationService.java
│
├── adapter
│   ├── in
│   │   └── web
│   │       └── productor
│   │           ├── ProductorController.java
│   │           ├── ProductorWebMapper.java
│   │           └── dto
│   │               ├── request
│   │               └── response
│   │
│   └── out
│       └── sqlserver
│           └── productor
│               ├── ProductorSqlServerAdapter.java
│               └── ProductorSqlMapper.java
│
└── infrastructure
```

Repetir la misma convención para todos los módulos.

---

# 16. REGLA PARA APPLICATION SERVICE

El `ApplicationService` **no reimplementa el PA**.

Correcto:

```text
Controller
   → mapper
   → command
   → UseCase
   → Port OUT
   → PA
   → resultado
   → response
```

Incorrecto:

```text
ApplicationService
   → consulta A
   → calcula totales
   → valida estado
   → decide rol
   → consulta B
   → actualiza C
```

Si una operación requiere transacción, validación de estado o cálculo que afecta consistencia, debe existir en un PA único.

---

# 17. PERMISOS MODULARES

La BD ya contiene 288 permisos: 32 módulos × 9 acciones genéricas.

Patrón:

```text
<MODULE>_LISTAR
<MODULE>_VER
<MODULE>_CREAR
<MODULE>_EDITAR
<MODULE>_RETIRAR
<MODULE>_CONFIRMAR
<MODULE>_APROBAR
<MODULE>_EXPORTAR
<MODULE>_ADMINISTRAR
```

La API no crea endpoints diferentes por rol.

Ejemplo:

```text
POST /api/v1/productores
```

puede ser usado por:
- Administrador;
- Coordinador técnico;
- Técnico de campo;

**solo si el usuario efectivo contiene `PRODUCTORES_CREAR`.**

Auditor puede consumir:

```text
GET /api/v1/productores
GET /api/v1/productores/{id}
```

si tiene `PRODUCTORES_LISTAR` / `PRODUCTORES_VER`, pero el mismo controller rechaza el POST.

---

# 18. TESTING SIN FLYWAY

No se usará Flyway.

Para Testcontainers SQL Server:

```text
Testcontainer SQL Server
   ↓
DatabaseBootstrapTestSupport
   ↓
ScriptUtils.executeSqlScript(...)
   ↓
baseline SQL de prueba
   ↓
PA reales
```

Separar:

## Unitarias
- application services;
- mappers puros;
- crypto adapters.

## Adapter integration
- adapter SQL vs PA real.
- múltiples resultsets.
- outputs.
- errores controlados.

## Web contract
- MockMvc.
- Bean Validation.
- permisos.
- respuestas.
- Swagger.

## OpenAPI contract test

Agregar test que:

1. llama `/v3/api-docs`;
2. verifica HTTP 200;
3. verifica que todos los `operationId` sean únicos;
4. verifica `bearerAuth`;
5. verifica que ninguna operación exponga `HttpServletRequest`;
6. verifica que cada módulo implementado tenga su `Tag`.

---

# 19. ESTRATEGIA DE ENTREGA POR ITERACIONES

Cada iteración futura debe abarcar **uno o un pequeño grupo dependiente de módulos**, no 10 módulos a la vez.

Formato recomendado de cada entregable:

```text
1. Revisar PA actuales.
2. Revisar sección exacta de SISTEMA_TESIS.
3. Confirmar permisos.
4. Confirmar estados.
5. Definir endpoints.
6. Crear Port IN.
7. Crear Port OUT.
8. Crear ApplicationService.
9. Crear adapter SQL.
10. Crear Controller + DTOs.
11. Swagger/OpenAPI.
12. Tests.
13. E2E del bloque.
14. Actualizar roadmap.
```

---

# 20. ORDEN DE PRÓXIMOS ENTREGABLES

## Entregable 0 — BLOQUEANTE

**Estabilización de la plataforma hexagonal.**

Debe contener:
- puertos OUT faltantes;
- adapters OUT Auth;
- ejecutor PA reutilizable;
- excepción PA común;
- payload factory;
- hash/idempotencia;
- mail/security adapters faltantes;
- tests de compilación;
- saneamiento SQL de roles y grupos duplicados.

**No comenzar Productores antes de terminar este bloque.**

## Entregable 1

```text
Empresas / Asociaciones / Áreas
Roles y permisos
Catálogos + Geo
```

## Entregable 2

```text
Empleados
Usuarios y accesos
Mi cuenta / sesiones / dispositivos
```

E2E administración completo.

## Entregable 3

```text
Documentos/evidencias reutilizables
Productores
Predios
```

## Entregable 4

```text
Parcelas/cultivos
Censos
```

E2E técnico maestro.

## Entregable 5

```text
Inventario/vehículos
Salidas
Recursos programados
```

## Entregable 6

```text
Visitas
Evaluaciones
Sanidad
Producción disponible
```

E2E campo.

## Entregable 7

```text
Campañas
Condiciones/precios
Participantes
```

## Entregable 8

```text
Operativos
Jabas
Acopio/entregas
Incidencias
Ajustes
```

E2E comercial.

## Entregable 9

```text
Gastos
Liquidaciones
Pagos
Cobros
```

E2E financiero.

## Entregable 10

```text
Reportes
Auditoría
Dashboard final
```

## Entregable 11

E2E completo desde creación de empleado hasta cierre financiero, auditoría y reporte.

---

# 21. CAMINO E2E FINAL QUE DEBE FUNCIONAR

Este es el objetivo de cierre del backend:

```text
Administrador
  ↓
Empresa / Área
  ↓
Empleado
  ↓
Usuario + Rol
  ↓
Validación de correo
  ↓
Login + 2FA
  ↓
Productor
  ↓
Predio + ubicación
  ↓
Parcela
  ↓
Cultivo
  ↓
Censo
  ↓
Salida
  ↓
Recursos
  ↓
Visita
  ↓
Evaluación / Materia seca
  ↓
Sanidad
  ↓
Producción confirmada
  ↓
Campaña
  ↓
Condiciones + precio
  ↓
Participantes
  ↓
Operativo + zonas
  ↓
Jabas
  ↓
Entrega
  ↓
Incidencia / ajuste
  ↓
Cierre operativo
  ↓
Gasto + prorrateo
  ↓
Liquidación
  ↓
Aprobación
  ↓
Pago
  ↓
Cobro comprador
  ↓
Reporte
  ↓
Auditoría
```

Este orden reproduce en backend el proceso oficial descrito por `SISTEMA_TESIS(1).md`, §37.1–§37.51.

---

# 22. CRITERIO FINAL PARA NO GENERAR DEUDA TÉCNICA

Antes de marcar un módulo como “terminado” deben cumplirse simultáneamente:

```text
PA correcto
+
permiso correcto
+
estado correcto
+
arquitectura hexagonal
+
respuesta funcional
+
idempotencia
+
auditoría
+
Swagger/OpenAPI
+
tests
+
E2E
```

Si uno falta, el módulo **no está terminado**.

---

# 23. DECISIÓN DE INICIO

El siguiente paso de programación debe ser:

```text
FASE 0
↓
cerrar puertos/adapters OUT faltantes
↓
crear infraestructura PA común
↓
sanear roles/grupos duplicados
↓
mvn clean test
↓
validar /v3/api-docs
↓
recién entonces FASE 1
```

No se recomienda comenzar directamente con `ProductoresController`, porque el backend actual todavía presenta dependencias internas faltantes en el snapshot y la configuración RBAC/menu aún contiene duplicados.

---

# 24. RESUMEN EJECUTIVO

**Arquitectura:** Hexagonal.

**Base de datos:** fuente de verdad funcional por PA.

**Java:** orquesta, protege, transporta contratos y adapta tecnologías; no reemplaza la lógica SQL.

**Autorización:** por permiso, no por rol.

**Rol:** agrupador dinámico de permisos.

**Estados:** controlados por PA específicos.

**Reutilización:** infraestructura técnica común; contratos funcionales explícitos.

**Swagger:** contrato formal para Angular.

**Orden:** dependencias de datos y proceso.

**Validación:** E2E escalonado en cada bloque.

**Primer bloque real a ejecutar:** Fase 0 de estabilización.
