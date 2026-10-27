# ESPECIFICACIÓN FUNCIONAL OFICIAL END-TO-END – DESCO UOT SARA SARA

**Objetivo:** definir de manera exhaustiva qué hará el sistema, qué verá cada trabajador, qué podrá listar, registrar, editar, retirar, confirmar, aprobar, exportar y consultar, y cómo se organizará cada flujo de trabajo.

**Criterio rector:** el sistema se diseña alrededor de procesos reales de DESCO, no como una colección de mantenimientos aislados.

**Usuarios de la primera versión:** trabajadores autorizados de DESCO. Los productores se administran como parte de la operación, pero no ingresan directamente al sistema.

**Seguridad incluida:** validación de cuenta por correo, segundo factor, recuperación de contraseña por correo, sesiones revocables, dispositivos reconocidos, JWT, notificaciones de seguridad y permisos modulares.

# PARTE XXXI. ACCESO Y SEGURIDAD COMPLETOS

## 31.1. Login

1. El acceso normal usa nombre de usuario y contraseña.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
2. No se usa correo como sustituto automático del nombre de usuario.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
3. El mensaje de credenciales incorrectas es general.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
4. El usuario no puede deducir si una cuenta existe.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
5. Se limita la cantidad de intentos fallidos.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
6. Se registra fecha del último acceso correcto.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
7. Se registra actividad de seguridad relevante.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.

## 31.2. Validación de cuenta por correo

1. Toda cuenta nueva debe validar un correo de seguridad.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
2. Se genera código de un solo uso.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
3. El código expira.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
4. Solicitar nuevo código invalida el anterior.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
5. La pantalla permite reenviar después de un tiempo mínimo.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
6. Al validar se marca el correo como verificado.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.

## 31.3. Doble factor

1. El sistema incorpora doble factor.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
2. El canal inicial es correo electrónico.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
3. No se utiliza SMS.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
4. Administrador, Jefe UOT, Coordinador Comercial y Finanzas lo tienen obligatorio.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
5. El código es de un solo uso.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
6. El código expira rápidamente.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
7. El código no se registra en auditoría.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.

## 31.4. Recuperación de contraseña

1. Existe la opción Recuperar contraseña.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
2. Se envía código por correo validado.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
3. La respuesta inicial es general para no revelar cuentas.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
4. El código expira.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
5. El código es de un solo uso.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
6. Al cambiar la contraseña se revocan las sesiones anteriores.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
7. Se envía correo informando el cambio.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.

## 31.5. JWT y sesiones

1. El sistema usa token de acceso de corta duración.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
2. La sesión dispone de renovación revocable.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
3. Cada sesión se identifica individualmente.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
4. El usuario puede cerrar una sesión remota.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
5. El usuario puede cerrar todas las demás sesiones.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
6. Deshabilitar la cuenta revoca sesiones.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
7. Retirar al empleado revoca sesiones.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
8. Cambiar la contraseña revoca sesiones anteriores.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.

## 31.6. Dispositivos

1. Se identifica el dispositivo de forma lógica.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
2. Se registra navegador y sistema operativo.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
3. Se registra primera detección.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
4. Se registra última actividad.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
5. Se puede marcar un dispositivo como reconocido según política.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
6. El usuario puede quitar reconocimiento.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
7. Un dispositivo nuevo genera correo de seguridad.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.

## 31.7. Correos de seguridad

1. Se envía código de validación.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
2. Se envía código de recuperación.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
3. Se envía código de segundo factor.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
4. Se notifica nuevo dispositivo.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
5. Se notifica cambio de contraseña.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
6. Se notifica cambio de correo.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
7. No se envían contraseñas.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.
8. No se envían tokens de sesión.
   - Debe mostrarse con lenguaje comprensible.
   - Debe respetar límites de intentos cuando corresponda.
   - La acción sensible debe quedar trazable sin almacenar secretos.

# PARTE XXXII. SIDEBAR EXACTO POR ROL

## 32.1. Administrador

- Límite general: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Inicio
- Gestión técnica
  - Productores / socios
  - Predios
  - Parcelas y cultivos
  - Censos de plantas
  - Salidas de campo
  - Visitas técnicas
  - Evaluaciones agronómicas
  - Sanidad vegetal
  - Producción disponible
- Gestión comercial
  - Campañas de venta
  - Condiciones y precios
  - Participantes de campaña
  - Operativos de venta
  - Control de jabas
  - Acopio y entregas
  - Incidencias operativas
  - Ajustes de precio
- Recursos
  - Inventario y vehículos
  - Recursos programados
- Finanzas
  - Gastos
  - Liquidaciones
  - Pagos a socios
  - Cobros de compradores
- Administración
  - Empresas, asociaciones y áreas
  - Empleados
  - Usuarios y accesos
  - Roles y permisos
  - Catálogos
- Reportes y control
  - Reportes e indicadores
  - Auditoría
- Mi cuenta
  - Perfil
  - Seguridad
  - Sesiones
  - Dispositivos

## 32.2. Jefe / Responsable UOT

- Límite general: Supervisa, consulta y aprueba hitos; no realiza captura rutinaria salvo que tenga otro rol.
- Inicio
- Gestión técnica
  - Productores / socios
  - Predios
  - Parcelas y cultivos
  - Salidas de campo
  - Visitas técnicas
  - Sanidad vegetal
  - Producción disponible
- Gestión comercial
  - Campañas de venta
  - Condiciones y precios
  - Operativos de venta
  - Control de jabas
  - Acopio y entregas
  - Incidencias operativas
- Finanzas
  - Gastos
  - Liquidaciones
  - Pagos a socios
  - Cobros de compradores
- Reportes y control
  - Reportes e indicadores
  - Auditoría
- Mi cuenta
  - Perfil
  - Seguridad
  - Sesiones
  - Dispositivos

## 32.3. Coordinador técnico

- Límite general: Planifica y supervisa la actividad técnica y productiva.
- Inicio
- Gestión técnica
  - Productores / socios
  - Predios
  - Parcelas y cultivos
  - Censos de plantas
  - Salidas de campo
  - Visitas técnicas
  - Evaluaciones agronómicas
  - Sanidad vegetal
  - Producción disponible
- Reportes y control
  - Reportes e indicadores
- Mi cuenta
  - Perfil
  - Seguridad
  - Sesiones
  - Dispositivos

## 32.4. Técnico de campo

- Límite general: Registra y actualiza información técnica de campo, productores, predios, cultivos y evidencias.
- Inicio
- Gestión técnica
  - Productores / socios
  - Predios
  - Parcelas y cultivos
  - Censos de plantas
  - Salidas de campo
  - Visitas técnicas
  - Evaluaciones agronómicas
  - Sanidad vegetal
  - Producción disponible
- Reportes y control
  - Reportes e indicadores
- Mi cuenta
  - Perfil
  - Seguridad
  - Sesiones
  - Dispositivos

## 32.5. Coordinador comercial

- Límite general: Planifica y controla campañas, precios, operativos, acopio y cierre comercial.
- Inicio
- Gestión técnica
  - Productores / socios
  - Predios
  - Producción disponible
- Gestión comercial
  - Campañas de venta
  - Condiciones y precios
  - Participantes de campaña
  - Operativos de venta
  - Control de jabas
  - Acopio y entregas
  - Incidencias operativas
  - Ajustes de precio
- Finanzas
  - Gastos
  - Liquidaciones
  - Cobros de compradores
- Reportes y control
  - Reportes e indicadores
- Mi cuenta
  - Perfil
  - Seguridad
  - Sesiones
  - Dispositivos

## 32.6. Operador comercial y de acopio

- Límite general: Ejecuta el operativo de acopio, jabas, entregas e incidencias.
- Inicio
- Gestión técnica
  - Productores / socios
  - Producción disponible
- Gestión comercial
  - Campañas de venta
  - Participantes de campaña
  - Operativos de venta
  - Control de jabas
  - Acopio y entregas
  - Incidencias operativas
- Reportes y control
  - Reportes e indicadores
- Mi cuenta
  - Perfil
  - Seguridad
  - Sesiones
  - Dispositivos

## 32.7. Responsable de logística

- Límite general: Controla bienes, vehículos, suministros, entregas y devoluciones.
- Inicio
- Gestión técnica
  - Salidas de campo
- Gestión comercial
  - Operativos de venta
- Recursos
  - Inventario y vehículos
  - Recursos programados
- Reportes y control
  - Reportes e indicadores
- Mi cuenta
  - Perfil
  - Seguridad
  - Sesiones
  - Dispositivos

## 32.8. Responsable de finanzas y tesorería

- Límite general: Gestiona gastos, prorrateos, liquidaciones, pagos y cobros.
- Inicio
- Gestión técnica
  - Productores / socios
- Gestión comercial
  - Campañas de venta
  - Operativos de venta
  - Acopio y entregas
  - Ajustes de precio
- Finanzas
  - Gastos
  - Liquidaciones
  - Pagos a socios
  - Cobros de compradores
- Reportes y control
  - Reportes e indicadores
- Mi cuenta
  - Perfil
  - Seguridad
  - Sesiones
  - Dispositivos

## 32.9. Auditor / Consulta

- Límite general: Solo consulta, revisa trazabilidad y exporta información autorizada.
- Inicio
- Gestión técnica
  - Productores / socios
  - Predios
  - Parcelas y cultivos
  - Salidas de campo
  - Visitas técnicas
  - Sanidad vegetal
  - Producción disponible
- Gestión comercial
  - Campañas de venta
  - Condiciones y precios
  - Operativos de venta
  - Control de jabas
  - Acopio y entregas
  - Incidencias operativas
- Finanzas
  - Gastos
  - Liquidaciones
  - Pagos a socios
  - Cobros de compradores
- Reportes y control
  - Reportes e indicadores
  - Auditoría
- Mi cuenta
  - Perfil
  - Seguridad
  - Sesiones
  - Dispositivos

# PARTE XXXIII. CAPACIDADES EXACTAS POR ROL Y MÓDULO

## 33.1. Administrador → Dashboard

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Ver alertas.
- Ver pendientes.
- Ver accesos rápidos.
- Ver indicadores según rol.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar

### Qué puede editar

### Qué puede retirar, cancelar o anular

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.2. Administrador → Productores / socios

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver historial.
- Ver predios.
- Ver campañas.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular
- Retirar.

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.3. Administrador → Predios

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver mapa.
- Ver titularidad.
- Ver historial.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular
- Retirar.

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.4. Administrador → Parcelas y cultivos

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver expediente.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar parcela.
- Registrar cultivo.

### Qué puede editar
- Editar parcela.
- Editar cultivo.

### Qué puede retirar, cancelar o anular

### Qué puede confirmar o aprobar
- Finalizar cultivo.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.5. Administrador → Censos de plantas

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver historial.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.6. Administrador → Salidas de campo

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver recursos.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Programar.
- Asignar participantes.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular
- Cancelar.

### Qué puede confirmar o aprobar
- Finalizar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.7. Administrador → Visitas técnicas

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver ubicación.
- Ver evidencias.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular
- Anular.

### Qué puede confirmar o aprobar
- Finalizar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.8. Administrador → Evaluaciones agronómicas

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.
- Registrar materia seca.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.9. Administrador → Sanidad vegetal

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar casos.
- Ver evidencias.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar caso.
- Registrar tratamiento.
- Registrar seguimiento.

### Qué puede editar
- Editar caso.
- Cambiar estado.

### Qué puede retirar, cancelar o anular

### Qué puede confirmar o aprobar
- Cerrar caso.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.10. Administrador → Producción disponible

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Filtrar por zona.
- Filtrar por fecha.
- Ver origen.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar estimación.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular
- Descartar.

### Qué puede confirmar o aprobar
- Confirmar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.11. Administrador → Campañas de venta

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver comprador.
- Ver participantes.
- Ver operativos.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Crear.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular
- Cancelar.

### Qué puede confirmar o aprobar
- Activar.
- Cerrar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.12. Administrador → Condiciones y precios

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Versionar precio.
- Ver historial.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Crear condición.
- Crear precio.

### Qué puede editar
- Versionar precio.

### Qué puede retirar, cancelar o anular
- Deshabilitar valor no utilizado.

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.13. Administrador → Participantes de campaña

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver entregas.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Incluir socio.
- Programar en operativo.

### Qué puede editar

### Qué puede retirar, cancelar o anular
- Retirar socio.

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.14. Administrador → Operativos de venta

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver indicadores.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Crear.
- Asignar zonas.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular
- Cancelar.

### Qué puede confirmar o aprobar
- Cerrar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.15. Administrador → Control de jabas

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver saldo.
- Ver historial.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Asignar.
- Registrar devolución.

### Qué puede editar

### Qué puede retirar, cancelar o anular
- Anular movimiento autorizado.

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.16. Administrador → Acopio y entregas

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver valorización.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar
- Editar preliminar.

### Qué puede retirar, cancelar o anular
- Anular.

### Qué puede confirmar o aprobar
- Confirmar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.17. Administrador → Incidencias operativas

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver peso afectado.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar
- Editar revisión.
- Resolver.

### Qué puede retirar, cancelar o anular
- Anular.

### Qué puede confirmar o aprobar
- Resolver.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.18. Administrador → Ajustes de precio

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver impacto.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar

### Qué puede retirar, cancelar o anular
- Anular.

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.19. Administrador → Inventario y vehículos

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver historial.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar bien.
- Registrar vehículo.

### Qué puede editar
- Editar bien.
- Actualizar kilometraje.

### Qué puede retirar, cancelar o anular
- Dar de baja.

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.20. Administrador → Recursos programados

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver disponibilidad.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Programar.
- Asignar bien.
- Registrar devolución.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular
- Cancelar programación.

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.21. Administrador → Gastos

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver prorrateo.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar
- Editar registrado.

### Qué puede retirar, cancelar o anular
- Anular.

### Qué puede confirmar o aprobar
- Aprobar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.22. Administrador → Liquidaciones

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver saldo.
- Ver pagos.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Calcular.

### Qué puede editar
- Recalcular versión.

### Qué puede retirar, cancelar o anular
- Anular.

### Qué puede confirmar o aprobar
- Aprobar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.23. Administrador → Pagos a socios

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver saldo posterior.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar

### Qué puede retirar, cancelar o anular
- Anular.

### Qué puede confirmar o aprobar
- Confirmar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.24. Administrador → Cobros de compradores

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver saldo campaña.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar

### Qué puede retirar, cancelar o anular
- Anular.

### Qué puede confirmar o aprobar
- Confirmar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.25. Administrador → Empresas, asociaciones y áreas

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar empresa.
- Registrar asociación.
- Registrar área.

### Qué puede editar
- Editar empresa.
- Editar asociación.
- Editar área.

### Qué puede retirar, cancelar o anular

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.26. Administrador → Empleados

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver historial de área.
- Ver usuario.
- Ver roles.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular
- Retirar.

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.27. Administrador → Usuarios y accesos

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver dispositivos.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Crear cuenta.
- Asignar roles.

### Qué puede editar
- Editar cuenta.

### Qué puede retirar, cancelar o anular
- Deshabilitar.
- Retirar roles.

### Qué puede confirmar o aprobar
- Reactivar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.28. Administrador → Roles y permisos

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar roles.
- Ver usuarios por rol.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Crear rol.
- Asignar permisos.

### Qué puede editar
- Editar rol.

### Qué puede retirar, cancelar o anular
- Deshabilitar rol.
- Retirar permisos.

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.29. Administrador → Catálogos

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver uso.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar valor.

### Qué puede editar
- Editar valor.

### Qué puede retirar, cancelar o anular
- Deshabilitar valor.

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.30. Administrador → Documentos y evidencias

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver contexto.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Subir.
- Tomar fotografía.

### Qué puede editar

### Qué puede retirar, cancelar o anular
- Retirar.

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.31. Administrador → Reportes e indicadores

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar reportes.
- Filtrar.
- Ver detalle.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar

### Qué puede editar

### Qué puede retirar, cancelar o anular

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.32. Administrador → Auditoría

- Nivel funcional: `TOTAL`.
- Responsabilidad: Puede operar todo el sistema, administrar accesos, configuración, procesos y reportes, siempre respetando trazabilidad y estados.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar eventos.
- Filtrar.
- Ver antes y después.
- Ver dispositivo.
- Ver usuario.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar

### Qué puede editar

### Qué puede retirar, cancelar o anular

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.33. Jefe / Responsable UOT → Dashboard

- Nivel funcional: `LECTURA`.
- Responsabilidad: Supervisa, consulta y aprueba hitos; no realiza captura rutinaria salvo que tenga otro rol.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Ver alertas.
- Ver pendientes.
- Ver accesos rápidos.
- Ver indicadores según rol.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.34. Jefe / Responsable UOT → Productores / socios

- Nivel funcional: `LECTURA`.
- Responsabilidad: Supervisa, consulta y aprueba hitos; no realiza captura rutinaria salvo que tenga otro rol.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver historial.
- Ver predios.
- Ver campañas.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.35. Jefe / Responsable UOT → Predios

- Nivel funcional: `LECTURA`.
- Responsabilidad: Supervisa, consulta y aprueba hitos; no realiza captura rutinaria salvo que tenga otro rol.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver mapa.
- Ver titularidad.
- Ver historial.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.36. Jefe / Responsable UOT → Parcelas y cultivos

- Nivel funcional: `LECTURA`.
- Responsabilidad: Supervisa, consulta y aprueba hitos; no realiza captura rutinaria salvo que tenga otro rol.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver expediente.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.37. Jefe / Responsable UOT → Salidas de campo

- Nivel funcional: `LECTURA`.
- Responsabilidad: Supervisa, consulta y aprueba hitos; no realiza captura rutinaria salvo que tenga otro rol.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver recursos.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.38. Jefe / Responsable UOT → Visitas técnicas

- Nivel funcional: `LECTURA`.
- Responsabilidad: Supervisa, consulta y aprueba hitos; no realiza captura rutinaria salvo que tenga otro rol.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver ubicación.
- Ver evidencias.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.39. Jefe / Responsable UOT → Sanidad vegetal

- Nivel funcional: `LECTURA`.
- Responsabilidad: Supervisa, consulta y aprueba hitos; no realiza captura rutinaria salvo que tenga otro rol.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar casos.
- Ver evidencias.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.40. Jefe / Responsable UOT → Producción disponible

- Nivel funcional: `LECTURA`.
- Responsabilidad: Supervisa, consulta y aprueba hitos; no realiza captura rutinaria salvo que tenga otro rol.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Filtrar por zona.
- Filtrar por fecha.
- Ver origen.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.41. Jefe / Responsable UOT → Campañas de venta

- Nivel funcional: `SUPERVISION_APROBACION`.
- Responsabilidad: Supervisa, consulta y aprueba hitos; no realiza captura rutinaria salvo que tenga otro rol.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver comprador.
- Ver participantes.
- Ver operativos.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- Activar.
- Cerrar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.42. Jefe / Responsable UOT → Condiciones y precios

- Nivel funcional: `SUPERVISION_APROBACION`.
- Responsabilidad: Supervisa, consulta y aprueba hitos; no realiza captura rutinaria salvo que tenga otro rol.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Versionar precio.
- Ver historial.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.43. Jefe / Responsable UOT → Operativos de venta

- Nivel funcional: `SUPERVISION_APROBACION`.
- Responsabilidad: Supervisa, consulta y aprueba hitos; no realiza captura rutinaria salvo que tenga otro rol.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver indicadores.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- Cerrar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.44. Jefe / Responsable UOT → Control de jabas

- Nivel funcional: `LECTURA`.
- Responsabilidad: Supervisa, consulta y aprueba hitos; no realiza captura rutinaria salvo que tenga otro rol.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver saldo.
- Ver historial.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.45. Jefe / Responsable UOT → Acopio y entregas

- Nivel funcional: `LECTURA`.
- Responsabilidad: Supervisa, consulta y aprueba hitos; no realiza captura rutinaria salvo que tenga otro rol.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver valorización.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.46. Jefe / Responsable UOT → Incidencias operativas

- Nivel funcional: `SUPERVISION_APROBACION`.
- Responsabilidad: Supervisa, consulta y aprueba hitos; no realiza captura rutinaria salvo que tenga otro rol.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver peso afectado.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- Resolver.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.47. Jefe / Responsable UOT → Gastos

- Nivel funcional: `SUPERVISION_APROBACION`.
- Responsabilidad: Supervisa, consulta y aprueba hitos; no realiza captura rutinaria salvo que tenga otro rol.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver prorrateo.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- Aprobar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.48. Jefe / Responsable UOT → Liquidaciones

- Nivel funcional: `SUPERVISION_APROBACION`.
- Responsabilidad: Supervisa, consulta y aprueba hitos; no realiza captura rutinaria salvo que tenga otro rol.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver saldo.
- Ver pagos.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- Aprobar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.49. Jefe / Responsable UOT → Pagos a socios

- Nivel funcional: `LECTURA`.
- Responsabilidad: Supervisa, consulta y aprueba hitos; no realiza captura rutinaria salvo que tenga otro rol.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver saldo posterior.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.50. Jefe / Responsable UOT → Cobros de compradores

- Nivel funcional: `LECTURA`.
- Responsabilidad: Supervisa, consulta y aprueba hitos; no realiza captura rutinaria salvo que tenga otro rol.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver saldo campaña.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.51. Jefe / Responsable UOT → Reportes e indicadores

- Nivel funcional: `LECTURA`.
- Responsabilidad: Supervisa, consulta y aprueba hitos; no realiza captura rutinaria salvo que tenga otro rol.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar reportes.
- Filtrar.
- Ver detalle.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.52. Jefe / Responsable UOT → Auditoría

- Nivel funcional: `LECTURA`.
- Responsabilidad: Supervisa, consulta y aprueba hitos; no realiza captura rutinaria salvo que tenga otro rol.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar eventos.
- Filtrar.
- Ver antes y después.
- Ver dispositivo.
- Ver usuario.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.53. Coordinador técnico → Dashboard

- Nivel funcional: `LECTURA`.
- Responsabilidad: Planifica y supervisa la actividad técnica y productiva.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Ver alertas.
- Ver pendientes.
- Ver accesos rápidos.
- Ver indicadores según rol.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.54. Coordinador técnico → Productores / socios

- Nivel funcional: `COORDINACION`.
- Responsabilidad: Planifica y supervisa la actividad técnica y productiva.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver historial.
- Ver predios.
- Ver campañas.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular
- Retirar.

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.55. Coordinador técnico → Predios

- Nivel funcional: `COORDINACION`.
- Responsabilidad: Planifica y supervisa la actividad técnica y productiva.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver mapa.
- Ver titularidad.
- Ver historial.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular
- Retirar.

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.56. Coordinador técnico → Parcelas y cultivos

- Nivel funcional: `COORDINACION`.
- Responsabilidad: Planifica y supervisa la actividad técnica y productiva.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver expediente.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar parcela.
- Registrar cultivo.

### Qué puede editar
- Editar parcela.
- Editar cultivo.

### Qué puede retirar, cancelar o anular

### Qué puede confirmar o aprobar
- Finalizar cultivo.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.57. Coordinador técnico → Censos de plantas

- Nivel funcional: `COORDINACION`.
- Responsabilidad: Planifica y supervisa la actividad técnica y productiva.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver historial.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.58. Coordinador técnico → Salidas de campo

- Nivel funcional: `COORDINACION`.
- Responsabilidad: Planifica y supervisa la actividad técnica y productiva.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver recursos.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Programar.
- Asignar participantes.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular
- Cancelar.

### Qué puede confirmar o aprobar
- Finalizar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.59. Coordinador técnico → Visitas técnicas

- Nivel funcional: `COORDINACION`.
- Responsabilidad: Planifica y supervisa la actividad técnica y productiva.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver ubicación.
- Ver evidencias.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular
- Anular.

### Qué puede confirmar o aprobar
- Finalizar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.60. Coordinador técnico → Evaluaciones agronómicas

- Nivel funcional: `COORDINACION`.
- Responsabilidad: Planifica y supervisa la actividad técnica y productiva.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.
- Registrar materia seca.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.61. Coordinador técnico → Sanidad vegetal

- Nivel funcional: `COORDINACION`.
- Responsabilidad: Planifica y supervisa la actividad técnica y productiva.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar casos.
- Ver evidencias.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar caso.
- Registrar tratamiento.
- Registrar seguimiento.

### Qué puede editar
- Editar caso.
- Cambiar estado.

### Qué puede retirar, cancelar o anular

### Qué puede confirmar o aprobar
- Cerrar caso.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.62. Coordinador técnico → Producción disponible

- Nivel funcional: `COORDINACION`.
- Responsabilidad: Planifica y supervisa la actividad técnica y productiva.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Filtrar por zona.
- Filtrar por fecha.
- Ver origen.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar estimación.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular
- Descartar.

### Qué puede confirmar o aprobar
- Confirmar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.63. Coordinador técnico → Documentos y evidencias

- Nivel funcional: `COORDINACION`.
- Responsabilidad: Planifica y supervisa la actividad técnica y productiva.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver contexto.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Subir.
- Tomar fotografía.

### Qué puede editar

### Qué puede retirar, cancelar o anular
- Retirar.

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.64. Coordinador técnico → Reportes e indicadores

- Nivel funcional: `LECTURA`.
- Responsabilidad: Planifica y supervisa la actividad técnica y productiva.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar reportes.
- Filtrar.
- Ver detalle.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.65. Técnico de campo → Dashboard

- Nivel funcional: `LECTURA`.
- Responsabilidad: Registra y actualiza información técnica de campo, productores, predios, cultivos y evidencias.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Ver alertas.
- Ver pendientes.
- Ver accesos rápidos.
- Ver indicadores según rol.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.66. Técnico de campo → Productores / socios

- Nivel funcional: `OPERACION`.
- Responsabilidad: Registra y actualiza información técnica de campo, productores, predios, cultivos y evidencias.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver historial.
- Ver predios.
- Ver campañas.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.67. Técnico de campo → Predios

- Nivel funcional: `OPERACION`.
- Responsabilidad: Registra y actualiza información técnica de campo, productores, predios, cultivos y evidencias.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver mapa.
- Ver titularidad.
- Ver historial.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.68. Técnico de campo → Parcelas y cultivos

- Nivel funcional: `OPERACION`.
- Responsabilidad: Registra y actualiza información técnica de campo, productores, predios, cultivos y evidencias.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver expediente.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar parcela.
- Registrar cultivo.

### Qué puede editar
- Editar parcela.
- Editar cultivo.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.69. Técnico de campo → Censos de plantas

- Nivel funcional: `OPERACION`.
- Responsabilidad: Registra y actualiza información técnica de campo, productores, predios, cultivos y evidencias.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver historial.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.70. Técnico de campo → Salidas de campo

- Nivel funcional: `LECTURA`.
- Responsabilidad: Registra y actualiza información técnica de campo, productores, predios, cultivos y evidencias.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver recursos.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.71. Técnico de campo → Visitas técnicas

- Nivel funcional: `OPERACION`.
- Responsabilidad: Registra y actualiza información técnica de campo, productores, predios, cultivos y evidencias.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver ubicación.
- Ver evidencias.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.72. Técnico de campo → Evaluaciones agronómicas

- Nivel funcional: `OPERACION`.
- Responsabilidad: Registra y actualiza información técnica de campo, productores, predios, cultivos y evidencias.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.
- Registrar materia seca.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.73. Técnico de campo → Sanidad vegetal

- Nivel funcional: `OPERACION`.
- Responsabilidad: Registra y actualiza información técnica de campo, productores, predios, cultivos y evidencias.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar casos.
- Ver evidencias.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar caso.
- Registrar tratamiento.
- Registrar seguimiento.

### Qué puede editar
- Editar caso.
- Cambiar estado.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.74. Técnico de campo → Producción disponible

- Nivel funcional: `OPERACION`.
- Responsabilidad: Registra y actualiza información técnica de campo, productores, predios, cultivos y evidencias.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Filtrar por zona.
- Filtrar por fecha.
- Ver origen.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar estimación.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.75. Técnico de campo → Documentos y evidencias

- Nivel funcional: `OPERACION`.
- Responsabilidad: Registra y actualiza información técnica de campo, productores, predios, cultivos y evidencias.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver contexto.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Subir.
- Tomar fotografía.

### Qué puede editar

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.76. Técnico de campo → Reportes e indicadores

- Nivel funcional: `LECTURA`.
- Responsabilidad: Registra y actualiza información técnica de campo, productores, predios, cultivos y evidencias.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar reportes.
- Filtrar.
- Ver detalle.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.77. Coordinador comercial → Dashboard

- Nivel funcional: `LECTURA`.
- Responsabilidad: Planifica y controla campañas, precios, operativos, acopio y cierre comercial.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Ver alertas.
- Ver pendientes.
- Ver accesos rápidos.
- Ver indicadores según rol.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.78. Coordinador comercial → Productores / socios

- Nivel funcional: `LECTURA`.
- Responsabilidad: Planifica y controla campañas, precios, operativos, acopio y cierre comercial.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver historial.
- Ver predios.
- Ver campañas.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.79. Coordinador comercial → Predios

- Nivel funcional: `LECTURA`.
- Responsabilidad: Planifica y controla campañas, precios, operativos, acopio y cierre comercial.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver mapa.
- Ver titularidad.
- Ver historial.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.80. Coordinador comercial → Producción disponible

- Nivel funcional: `LECTURA`.
- Responsabilidad: Planifica y controla campañas, precios, operativos, acopio y cierre comercial.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Filtrar por zona.
- Filtrar por fecha.
- Ver origen.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.81. Coordinador comercial → Campañas de venta

- Nivel funcional: `COORDINACION`.
- Responsabilidad: Planifica y controla campañas, precios, operativos, acopio y cierre comercial.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver comprador.
- Ver participantes.
- Ver operativos.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Crear.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular
- Cancelar.

### Qué puede confirmar o aprobar
- Activar.
- Cerrar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.82. Coordinador comercial → Condiciones y precios

- Nivel funcional: `COORDINACION`.
- Responsabilidad: Planifica y controla campañas, precios, operativos, acopio y cierre comercial.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Versionar precio.
- Ver historial.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Crear condición.
- Crear precio.

### Qué puede editar
- Versionar precio.

### Qué puede retirar, cancelar o anular
- Deshabilitar valor no utilizado.

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.83. Coordinador comercial → Participantes de campaña

- Nivel funcional: `COORDINACION`.
- Responsabilidad: Planifica y controla campañas, precios, operativos, acopio y cierre comercial.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver entregas.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Incluir socio.
- Programar en operativo.

### Qué puede editar

### Qué puede retirar, cancelar o anular
- Retirar socio.

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.84. Coordinador comercial → Operativos de venta

- Nivel funcional: `COORDINACION`.
- Responsabilidad: Planifica y controla campañas, precios, operativos, acopio y cierre comercial.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver indicadores.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Crear.
- Asignar zonas.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular
- Cancelar.

### Qué puede confirmar o aprobar
- Cerrar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.85. Coordinador comercial → Control de jabas

- Nivel funcional: `COORDINACION`.
- Responsabilidad: Planifica y controla campañas, precios, operativos, acopio y cierre comercial.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver saldo.
- Ver historial.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Asignar.
- Registrar devolución.

### Qué puede editar

### Qué puede retirar, cancelar o anular
- Anular movimiento autorizado.

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.86. Coordinador comercial → Acopio y entregas

- Nivel funcional: `COORDINACION`.
- Responsabilidad: Planifica y controla campañas, precios, operativos, acopio y cierre comercial.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver valorización.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar
- Editar preliminar.

### Qué puede retirar, cancelar o anular
- Anular.

### Qué puede confirmar o aprobar
- Confirmar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.87. Coordinador comercial → Incidencias operativas

- Nivel funcional: `COORDINACION`.
- Responsabilidad: Planifica y controla campañas, precios, operativos, acopio y cierre comercial.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver peso afectado.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar
- Editar revisión.
- Resolver.

### Qué puede retirar, cancelar o anular
- Anular.

### Qué puede confirmar o aprobar
- Resolver.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.88. Coordinador comercial → Ajustes de precio

- Nivel funcional: `COORDINACION`.
- Responsabilidad: Planifica y controla campañas, precios, operativos, acopio y cierre comercial.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver impacto.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar

### Qué puede retirar, cancelar o anular
- Anular.

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.89. Coordinador comercial → Gastos

- Nivel funcional: `LECTURA`.
- Responsabilidad: Planifica y controla campañas, precios, operativos, acopio y cierre comercial.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver prorrateo.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.90. Coordinador comercial → Liquidaciones

- Nivel funcional: `LECTURA`.
- Responsabilidad: Planifica y controla campañas, precios, operativos, acopio y cierre comercial.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver saldo.
- Ver pagos.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.91. Coordinador comercial → Cobros de compradores

- Nivel funcional: `LECTURA`.
- Responsabilidad: Planifica y controla campañas, precios, operativos, acopio y cierre comercial.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver saldo campaña.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.92. Coordinador comercial → Documentos y evidencias

- Nivel funcional: `COORDINACION`.
- Responsabilidad: Planifica y controla campañas, precios, operativos, acopio y cierre comercial.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver contexto.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Subir.
- Tomar fotografía.

### Qué puede editar

### Qué puede retirar, cancelar o anular
- Retirar.

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.93. Coordinador comercial → Reportes e indicadores

- Nivel funcional: `LECTURA`.
- Responsabilidad: Planifica y controla campañas, precios, operativos, acopio y cierre comercial.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar reportes.
- Filtrar.
- Ver detalle.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.94. Operador comercial y de acopio → Dashboard

- Nivel funcional: `LECTURA`.
- Responsabilidad: Ejecuta el operativo de acopio, jabas, entregas e incidencias.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Ver alertas.
- Ver pendientes.
- Ver accesos rápidos.
- Ver indicadores según rol.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.95. Operador comercial y de acopio → Productores / socios

- Nivel funcional: `LECTURA`.
- Responsabilidad: Ejecuta el operativo de acopio, jabas, entregas e incidencias.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver historial.
- Ver predios.
- Ver campañas.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.96. Operador comercial y de acopio → Producción disponible

- Nivel funcional: `LECTURA`.
- Responsabilidad: Ejecuta el operativo de acopio, jabas, entregas e incidencias.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Filtrar por zona.
- Filtrar por fecha.
- Ver origen.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.97. Operador comercial y de acopio → Campañas de venta

- Nivel funcional: `LECTURA`.
- Responsabilidad: Ejecuta el operativo de acopio, jabas, entregas e incidencias.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver comprador.
- Ver participantes.
- Ver operativos.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.98. Operador comercial y de acopio → Participantes de campaña

- Nivel funcional: `OPERACION`.
- Responsabilidad: Ejecuta el operativo de acopio, jabas, entregas e incidencias.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver entregas.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Incluir socio.
- Programar en operativo.

### Qué puede editar

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.99. Operador comercial y de acopio → Operativos de venta

- Nivel funcional: `LECTURA`.
- Responsabilidad: Ejecuta el operativo de acopio, jabas, entregas e incidencias.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver indicadores.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.100. Operador comercial y de acopio → Control de jabas

- Nivel funcional: `OPERACION`.
- Responsabilidad: Ejecuta el operativo de acopio, jabas, entregas e incidencias.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver saldo.
- Ver historial.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Asignar.
- Registrar devolución.

### Qué puede editar

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.101. Operador comercial y de acopio → Acopio y entregas

- Nivel funcional: `OPERACION`.
- Responsabilidad: Ejecuta el operativo de acopio, jabas, entregas e incidencias.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver valorización.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar
- Editar preliminar.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.102. Operador comercial y de acopio → Incidencias operativas

- Nivel funcional: `OPERACION`.
- Responsabilidad: Ejecuta el operativo de acopio, jabas, entregas e incidencias.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver peso afectado.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar
- Editar revisión.
- Resolver.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.103. Operador comercial y de acopio → Documentos y evidencias

- Nivel funcional: `OPERACION`.
- Responsabilidad: Ejecuta el operativo de acopio, jabas, entregas e incidencias.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver contexto.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Subir.
- Tomar fotografía.

### Qué puede editar

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.104. Operador comercial y de acopio → Reportes e indicadores

- Nivel funcional: `LECTURA`.
- Responsabilidad: Ejecuta el operativo de acopio, jabas, entregas e incidencias.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar reportes.
- Filtrar.
- Ver detalle.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.105. Responsable de logística → Dashboard

- Nivel funcional: `LECTURA`.
- Responsabilidad: Controla bienes, vehículos, suministros, entregas y devoluciones.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Ver alertas.
- Ver pendientes.
- Ver accesos rápidos.
- Ver indicadores según rol.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.106. Responsable de logística → Salidas de campo

- Nivel funcional: `LECTURA`.
- Responsabilidad: Controla bienes, vehículos, suministros, entregas y devoluciones.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver recursos.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.107. Responsable de logística → Operativos de venta

- Nivel funcional: `LECTURA`.
- Responsabilidad: Controla bienes, vehículos, suministros, entregas y devoluciones.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver indicadores.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.108. Responsable de logística → Inventario y vehículos

- Nivel funcional: `OPERACION`.
- Responsabilidad: Controla bienes, vehículos, suministros, entregas y devoluciones.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver historial.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar bien.
- Registrar vehículo.

### Qué puede editar
- Editar bien.
- Actualizar kilometraje.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.109. Responsable de logística → Recursos programados

- Nivel funcional: `OPERACION`.
- Responsabilidad: Controla bienes, vehículos, suministros, entregas y devoluciones.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver disponibilidad.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Programar.
- Asignar bien.
- Registrar devolución.

### Qué puede editar
- Editar.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.110. Responsable de logística → Documentos y evidencias

- Nivel funcional: `OPERACION`.
- Responsabilidad: Controla bienes, vehículos, suministros, entregas y devoluciones.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver contexto.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Subir.
- Tomar fotografía.

### Qué puede editar

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.111. Responsable de logística → Reportes e indicadores

- Nivel funcional: `LECTURA`.
- Responsabilidad: Controla bienes, vehículos, suministros, entregas y devoluciones.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar reportes.
- Filtrar.
- Ver detalle.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.112. Responsable de finanzas y tesorería → Dashboard

- Nivel funcional: `LECTURA`.
- Responsabilidad: Gestiona gastos, prorrateos, liquidaciones, pagos y cobros.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Ver alertas.
- Ver pendientes.
- Ver accesos rápidos.
- Ver indicadores según rol.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.113. Responsable de finanzas y tesorería → Productores / socios

- Nivel funcional: `LECTURA`.
- Responsabilidad: Gestiona gastos, prorrateos, liquidaciones, pagos y cobros.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver historial.
- Ver predios.
- Ver campañas.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.114. Responsable de finanzas y tesorería → Campañas de venta

- Nivel funcional: `LECTURA`.
- Responsabilidad: Gestiona gastos, prorrateos, liquidaciones, pagos y cobros.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver comprador.
- Ver participantes.
- Ver operativos.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.115. Responsable de finanzas y tesorería → Operativos de venta

- Nivel funcional: `LECTURA`.
- Responsabilidad: Gestiona gastos, prorrateos, liquidaciones, pagos y cobros.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver indicadores.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.116. Responsable de finanzas y tesorería → Acopio y entregas

- Nivel funcional: `LECTURA`.
- Responsabilidad: Gestiona gastos, prorrateos, liquidaciones, pagos y cobros.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver valorización.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.117. Responsable de finanzas y tesorería → Ajustes de precio

- Nivel funcional: `LECTURA`.
- Responsabilidad: Gestiona gastos, prorrateos, liquidaciones, pagos y cobros.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver impacto.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.118. Responsable de finanzas y tesorería → Gastos

- Nivel funcional: `OPERACION_FINANCIERA`.
- Responsabilidad: Gestiona gastos, prorrateos, liquidaciones, pagos y cobros.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver prorrateo.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar
- Editar registrado.

### Qué puede retirar, cancelar o anular
- Anular.

### Qué puede confirmar o aprobar
- Aprobar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.119. Responsable de finanzas y tesorería → Liquidaciones

- Nivel funcional: `OPERACION_FINANCIERA`.
- Responsabilidad: Gestiona gastos, prorrateos, liquidaciones, pagos y cobros.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver saldo.
- Ver pagos.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Calcular.

### Qué puede editar
- Recalcular versión.

### Qué puede retirar, cancelar o anular
- Anular.

### Qué puede confirmar o aprobar
- Aprobar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.120. Responsable de finanzas y tesorería → Pagos a socios

- Nivel funcional: `OPERACION_FINANCIERA`.
- Responsabilidad: Gestiona gastos, prorrateos, liquidaciones, pagos y cobros.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver saldo posterior.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar

### Qué puede retirar, cancelar o anular
- Anular.

### Qué puede confirmar o aprobar
- Confirmar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.121. Responsable de finanzas y tesorería → Cobros de compradores

- Nivel funcional: `OPERACION_FINANCIERA`.
- Responsabilidad: Gestiona gastos, prorrateos, liquidaciones, pagos y cobros.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver saldo campaña.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Registrar.

### Qué puede editar

### Qué puede retirar, cancelar o anular
- Anular.

### Qué puede confirmar o aprobar
- Confirmar.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.122. Responsable de finanzas y tesorería → Documentos y evidencias

- Nivel funcional: `OPERACION_FINANCIERA`.
- Responsabilidad: Gestiona gastos, prorrateos, liquidaciones, pagos y cobros.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver contexto.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- Subir.
- Tomar fotografía.

### Qué puede editar

### Qué puede retirar, cancelar o anular
- Retirar.

### Qué puede confirmar o aprobar

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.123. Responsable de finanzas y tesorería → Reportes e indicadores

- Nivel funcional: `LECTURA`.
- Responsabilidad: Gestiona gastos, prorrateos, liquidaciones, pagos y cobros.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar reportes.
- Filtrar.
- Ver detalle.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.124. Auditor / Consulta → Dashboard

- Nivel funcional: `LECTURA`.
- Responsabilidad: Solo consulta, revisa trazabilidad y exporta información autorizada.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Ver alertas.
- Ver pendientes.
- Ver accesos rápidos.
- Ver indicadores según rol.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.125. Auditor / Consulta → Productores / socios

- Nivel funcional: `LECTURA`.
- Responsabilidad: Solo consulta, revisa trazabilidad y exporta información autorizada.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver historial.
- Ver predios.
- Ver campañas.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.126. Auditor / Consulta → Predios

- Nivel funcional: `LECTURA`.
- Responsabilidad: Solo consulta, revisa trazabilidad y exporta información autorizada.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver mapa.
- Ver titularidad.
- Ver historial.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.127. Auditor / Consulta → Parcelas y cultivos

- Nivel funcional: `LECTURA`.
- Responsabilidad: Solo consulta, revisa trazabilidad y exporta información autorizada.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver expediente.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.128. Auditor / Consulta → Salidas de campo

- Nivel funcional: `LECTURA`.
- Responsabilidad: Solo consulta, revisa trazabilidad y exporta información autorizada.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver recursos.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.129. Auditor / Consulta → Visitas técnicas

- Nivel funcional: `LECTURA`.
- Responsabilidad: Solo consulta, revisa trazabilidad y exporta información autorizada.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver ubicación.
- Ver evidencias.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.130. Auditor / Consulta → Sanidad vegetal

- Nivel funcional: `LECTURA`.
- Responsabilidad: Solo consulta, revisa trazabilidad y exporta información autorizada.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar casos.
- Ver evidencias.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.131. Auditor / Consulta → Producción disponible

- Nivel funcional: `LECTURA`.
- Responsabilidad: Solo consulta, revisa trazabilidad y exporta información autorizada.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Filtrar por zona.
- Filtrar por fecha.
- Ver origen.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.132. Auditor / Consulta → Campañas de venta

- Nivel funcional: `LECTURA`.
- Responsabilidad: Solo consulta, revisa trazabilidad y exporta información autorizada.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver comprador.
- Ver participantes.
- Ver operativos.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.133. Auditor / Consulta → Condiciones y precios

- Nivel funcional: `LECTURA`.
- Responsabilidad: Solo consulta, revisa trazabilidad y exporta información autorizada.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Versionar precio.
- Ver historial.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.134. Auditor / Consulta → Operativos de venta

- Nivel funcional: `LECTURA`.
- Responsabilidad: Solo consulta, revisa trazabilidad y exporta información autorizada.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver indicadores.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.135. Auditor / Consulta → Control de jabas

- Nivel funcional: `LECTURA`.
- Responsabilidad: Solo consulta, revisa trazabilidad y exporta información autorizada.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver saldo.
- Ver historial.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.136. Auditor / Consulta → Acopio y entregas

- Nivel funcional: `LECTURA`.
- Responsabilidad: Solo consulta, revisa trazabilidad y exporta información autorizada.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver valorización.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.137. Auditor / Consulta → Incidencias operativas

- Nivel funcional: `LECTURA`.
- Responsabilidad: Solo consulta, revisa trazabilidad y exporta información autorizada.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver peso afectado.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.138. Auditor / Consulta → Gastos

- Nivel funcional: `LECTURA`.
- Responsabilidad: Solo consulta, revisa trazabilidad y exporta información autorizada.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver prorrateo.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.139. Auditor / Consulta → Liquidaciones

- Nivel funcional: `LECTURA`.
- Responsabilidad: Solo consulta, revisa trazabilidad y exporta información autorizada.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver detalle.
- Ver saldo.
- Ver pagos.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.140. Auditor / Consulta → Pagos a socios

- Nivel funcional: `LECTURA`.
- Responsabilidad: Solo consulta, revisa trazabilidad y exporta información autorizada.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver saldo posterior.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.141. Auditor / Consulta → Cobros de compradores

- Nivel funcional: `LECTURA`.
- Responsabilidad: Solo consulta, revisa trazabilidad y exporta información autorizada.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar.
- Ver saldo campaña.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.142. Auditor / Consulta → Reportes e indicadores

- Nivel funcional: `LECTURA`.
- Responsabilidad: Solo consulta, revisa trazabilidad y exporta información autorizada.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar reportes.
- Filtrar.
- Ver detalle.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

## 33.143. Auditor / Consulta → Auditoría

- Nivel funcional: `LECTURA`.
- Responsabilidad: Solo consulta, revisa trazabilidad y exporta información autorizada.
- Al ingresar puede consultar el contexto autorizado.
- El menú solo muestra esta opción porque posee al menos un permiso sobre el módulo.
- El estado del registro puede restringir una acción aunque el rol tenga permiso.

### Qué puede listar
- Listar eventos.
- Filtrar.
- Ver antes y después.
- Ver dispositivo.
- Ver usuario.
- Puede aplicar filtros autorizados.
- Puede abrir detalle cuando posee permiso de consulta.

### Qué puede registrar
- No registra información nueva por defecto.

### Qué puede editar
- No modifica información por defecto.

### Qué puede retirar, cancelar o anular
- No ejecuta retiros o anulaciones por defecto.

### Qué puede confirmar o aprobar
- No realiza aprobaciones por defecto.

### Límites
- No puede saltar estados obligatorios.
- No puede ampliar sus propios permisos.
- No puede editar información histórica cerrada como si fuera un registro preliminar.
- Los mensajes recibidos deben ser funcionales y no técnicos.

# PARTE XXXIV. FICHA DE PANTALLA POR MÓDULO

## 34.1. Dashboard

### Cabecera
- Título visible: Dashboard.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Ver alertas.
- Ver pendientes.
- Ver accesos rápidos.
- Ver indicadores según rol.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.2. Productores / socios

### Cabecera
- Título visible: Productores / socios.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver detalle.
- Ver historial.
- Ver predios.
- Ver campañas.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Registrar.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Editar.
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Retirar.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.3. Predios

### Cabecera
- Título visible: Predios.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver detalle.
- Ver mapa.
- Ver titularidad.
- Ver historial.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Registrar.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Editar.
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Retirar.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.4. Parcelas y cultivos

### Cabecera
- Título visible: Parcelas y cultivos.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver detalle.
- Ver expediente.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Registrar parcela.
- Registrar cultivo.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Editar parcela.
- Editar cultivo.
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Finalizar cultivo.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.5. Censos de plantas

### Cabecera
- Título visible: Censos de plantas.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver historial.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Registrar.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Editar.
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.6. Salidas de campo

### Cabecera
- Título visible: Salidas de campo.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver recursos.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Programar.
- Asignar participantes.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Editar.
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Cancelar.
- Finalizar.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.7. Visitas técnicas

### Cabecera
- Título visible: Visitas técnicas.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver ubicación.
- Ver evidencias.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Editar.
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Finalizar.
- Anular.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.8. Evaluaciones agronómicas

### Cabecera
- Título visible: Evaluaciones agronómicas.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver detalle.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Registrar.
- Registrar materia seca.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Editar.
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.9. Sanidad vegetal

### Cabecera
- Título visible: Sanidad vegetal.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar casos.
- Ver evidencias.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Registrar caso.
- Registrar tratamiento.
- Registrar seguimiento.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Editar caso.
- Cambiar estado.
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Cerrar caso.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.10. Producción disponible

### Cabecera
- Título visible: Producción disponible.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Filtrar por zona.
- Filtrar por fecha.
- Ver origen.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Registrar estimación.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Editar.
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Descartar.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.11. Campañas de venta

### Cabecera
- Título visible: Campañas de venta.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver comprador.
- Ver participantes.
- Ver operativos.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Crear.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Editar.
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Cerrar.
- Cancelar.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.12. Condiciones y precios

### Cabecera
- Título visible: Condiciones y precios.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Versionar precio.
- Ver historial.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Crear condición.
- Crear precio.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Versionar precio.
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.13. Participantes de campaña

### Cabecera
- Título visible: Participantes de campaña.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver entregas.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Incluir socio.
- Programar en operativo.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Retirar socio.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.14. Operativos de venta

### Cabecera
- Título visible: Operativos de venta.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver indicadores.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Crear.
- Asignar zonas.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Editar.
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Cerrar.
- Cancelar.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.15. Control de jabas

### Cabecera
- Título visible: Control de jabas.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver saldo.
- Ver historial.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Asignar.
- Registrar devolución.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Anular movimiento autorizado.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.16. Acopio y entregas

### Cabecera
- Título visible: Acopio y entregas.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver detalle.
- Ver valorización.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Registrar.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Editar preliminar.
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Anular.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.17. Incidencias operativas

### Cabecera
- Título visible: Incidencias operativas.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver peso afectado.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Registrar.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Editar revisión.
- Resolver.
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Anular.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.18. Ajustes de precio

### Cabecera
- Título visible: Ajustes de precio.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver impacto.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Registrar.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Anular.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.19. Inventario y vehículos

### Cabecera
- Título visible: Inventario y vehículos.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver historial.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Registrar bien.
- Registrar vehículo.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Editar bien.
- Actualizar kilometraje.
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Dar de baja.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.20. Recursos programados

### Cabecera
- Título visible: Recursos programados.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver disponibilidad.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Programar.
- Asignar bien.
- Registrar devolución.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Editar.
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Cancelar programación.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.21. Gastos

### Cabecera
- Título visible: Gastos.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver prorrateo.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Registrar.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Editar registrado.
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Anular.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.22. Liquidaciones

### Cabecera
- Título visible: Liquidaciones.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver detalle.
- Ver saldo.
- Ver pagos.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Calcular.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Recalcular versión.
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Anular.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.23. Pagos a socios

### Cabecera
- Título visible: Pagos a socios.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver saldo posterior.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Registrar.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Anular.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.24. Cobros de compradores

### Cabecera
- Título visible: Cobros de compradores.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver saldo campaña.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Registrar.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Anular.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.25. Empresas, asociaciones y áreas

### Cabecera
- Título visible: Empresas, asociaciones y áreas.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Registrar empresa.
- Registrar asociación.
- Registrar área.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Editar empresa.
- Editar asociación.
- Editar área.
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.26. Empleados

### Cabecera
- Título visible: Empleados.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver historial de área.
- Ver usuario.
- Ver roles.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Registrar.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Editar.
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Retirar.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.27. Usuarios y accesos

### Cabecera
- Título visible: Usuarios y accesos.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver dispositivos.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Crear cuenta.
- Asignar roles.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Editar cuenta.
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Retirar roles.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.28. Roles y permisos

### Cabecera
- Título visible: Roles y permisos.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar roles.
- Ver usuarios por rol.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Crear rol.
- Asignar permisos.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Editar rol.
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Retirar permisos.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.29. Catálogos

### Cabecera
- Título visible: Catálogos.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver uso.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Registrar valor.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Editar valor.
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.30. Documentos y evidencias

### Cabecera
- Título visible: Documentos y evidencias.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar.
- Ver contexto.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Subir.
- Tomar fotografía.
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Retirar.
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.31. Reportes e indicadores

### Cabecera
- Título visible: Reportes e indicadores.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar reportes.
- Filtrar.
- Ver detalle.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

## 34.32. Auditoría

### Cabecera
- Título visible: Auditoría.
- Mostrar estado o contexto principal cuando corresponda.
- Mostrar acción principal solo a usuarios autorizados.
- Mostrar navegación secundaria interna cuando el módulo tenga varias áreas.

### Listado
- Listar eventos.
- Filtrar.
- Ver antes y después.
- Ver dispositivo.
- Ver usuario.
- Debe paginar.
- Debe permitir limpiar filtros.
- Debe conservar filtros al volver desde un detalle.

### Registro
- Validar obligatorios antes de confirmar.
- Evitar doble envío.
- Mostrar progreso mientras se procesa.

### Edición
- Las ediciones históricas utilizan vigencias o versiones cuando corresponda.

### Salida del proceso
- Solicitar confirmación en acciones sensibles.
- Solicitar motivo cuando el proceso requiera trazabilidad.

# PARTE XXXV. PERMISOS MODULARES OFICIALES

## 35.1. `INICIO_LISTAR`

- Módulo: Dashboard.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.2. `INICIO_VER`

- Módulo: Dashboard.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.3. `INICIO_CREAR`

- Módulo: Dashboard.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.4. `INICIO_EDITAR`

- Módulo: Dashboard.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.5. `INICIO_RETIRAR`

- Módulo: Dashboard.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.6. `INICIO_CONFIRMAR`

- Módulo: Dashboard.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.7. `INICIO_APROBAR`

- Módulo: Dashboard.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.8. `INICIO_EXPORTAR`

- Módulo: Dashboard.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.9. `INICIO_ADMINISTRAR`

- Módulo: Dashboard.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.10. `PRODUCTORES_LISTAR`

- Módulo: Productores / socios.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.11. `PRODUCTORES_VER`

- Módulo: Productores / socios.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.12. `PRODUCTORES_CREAR`

- Módulo: Productores / socios.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.13. `PRODUCTORES_EDITAR`

- Módulo: Productores / socios.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.14. `PRODUCTORES_RETIRAR`

- Módulo: Productores / socios.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.15. `PRODUCTORES_CONFIRMAR`

- Módulo: Productores / socios.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.16. `PRODUCTORES_APROBAR`

- Módulo: Productores / socios.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.17. `PRODUCTORES_EXPORTAR`

- Módulo: Productores / socios.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.18. `PRODUCTORES_ADMINISTRAR`

- Módulo: Productores / socios.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.19. `PREDIOS_LISTAR`

- Módulo: Predios.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.20. `PREDIOS_VER`

- Módulo: Predios.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.21. `PREDIOS_CREAR`

- Módulo: Predios.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.22. `PREDIOS_EDITAR`

- Módulo: Predios.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.23. `PREDIOS_RETIRAR`

- Módulo: Predios.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.24. `PREDIOS_CONFIRMAR`

- Módulo: Predios.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.25. `PREDIOS_APROBAR`

- Módulo: Predios.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.26. `PREDIOS_EXPORTAR`

- Módulo: Predios.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.27. `PREDIOS_ADMINISTRAR`

- Módulo: Predios.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.28. `CULTIVOS_LISTAR`

- Módulo: Parcelas y cultivos.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.29. `CULTIVOS_VER`

- Módulo: Parcelas y cultivos.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.30. `CULTIVOS_CREAR`

- Módulo: Parcelas y cultivos.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.31. `CULTIVOS_EDITAR`

- Módulo: Parcelas y cultivos.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.32. `CULTIVOS_RETIRAR`

- Módulo: Parcelas y cultivos.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.33. `CULTIVOS_CONFIRMAR`

- Módulo: Parcelas y cultivos.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.34. `CULTIVOS_APROBAR`

- Módulo: Parcelas y cultivos.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.35. `CULTIVOS_EXPORTAR`

- Módulo: Parcelas y cultivos.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.36. `CULTIVOS_ADMINISTRAR`

- Módulo: Parcelas y cultivos.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.37. `CENSOS_LISTAR`

- Módulo: Censos de plantas.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.38. `CENSOS_VER`

- Módulo: Censos de plantas.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.39. `CENSOS_CREAR`

- Módulo: Censos de plantas.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.40. `CENSOS_EDITAR`

- Módulo: Censos de plantas.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.41. `CENSOS_RETIRAR`

- Módulo: Censos de plantas.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.42. `CENSOS_CONFIRMAR`

- Módulo: Censos de plantas.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.43. `CENSOS_APROBAR`

- Módulo: Censos de plantas.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.44. `CENSOS_EXPORTAR`

- Módulo: Censos de plantas.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.45. `CENSOS_ADMINISTRAR`

- Módulo: Censos de plantas.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.46. `SALIDAS_LISTAR`

- Módulo: Salidas de campo.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.47. `SALIDAS_VER`

- Módulo: Salidas de campo.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.48. `SALIDAS_CREAR`

- Módulo: Salidas de campo.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.49. `SALIDAS_EDITAR`

- Módulo: Salidas de campo.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.50. `SALIDAS_RETIRAR`

- Módulo: Salidas de campo.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.51. `SALIDAS_CONFIRMAR`

- Módulo: Salidas de campo.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.52. `SALIDAS_APROBAR`

- Módulo: Salidas de campo.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.53. `SALIDAS_EXPORTAR`

- Módulo: Salidas de campo.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.54. `SALIDAS_ADMINISTRAR`

- Módulo: Salidas de campo.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.55. `VISITAS_LISTAR`

- Módulo: Visitas técnicas.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.56. `VISITAS_VER`

- Módulo: Visitas técnicas.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.57. `VISITAS_CREAR`

- Módulo: Visitas técnicas.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.58. `VISITAS_EDITAR`

- Módulo: Visitas técnicas.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.59. `VISITAS_RETIRAR`

- Módulo: Visitas técnicas.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.60. `VISITAS_CONFIRMAR`

- Módulo: Visitas técnicas.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.61. `VISITAS_APROBAR`

- Módulo: Visitas técnicas.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.62. `VISITAS_EXPORTAR`

- Módulo: Visitas técnicas.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.63. `VISITAS_ADMINISTRAR`

- Módulo: Visitas técnicas.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.64. `EVALUACIONES_LISTAR`

- Módulo: Evaluaciones agronómicas.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.65. `EVALUACIONES_VER`

- Módulo: Evaluaciones agronómicas.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.66. `EVALUACIONES_CREAR`

- Módulo: Evaluaciones agronómicas.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.67. `EVALUACIONES_EDITAR`

- Módulo: Evaluaciones agronómicas.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.68. `EVALUACIONES_RETIRAR`

- Módulo: Evaluaciones agronómicas.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.69. `EVALUACIONES_CONFIRMAR`

- Módulo: Evaluaciones agronómicas.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.70. `EVALUACIONES_APROBAR`

- Módulo: Evaluaciones agronómicas.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.71. `EVALUACIONES_EXPORTAR`

- Módulo: Evaluaciones agronómicas.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.72. `EVALUACIONES_ADMINISTRAR`

- Módulo: Evaluaciones agronómicas.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.73. `SANIDAD_LISTAR`

- Módulo: Sanidad vegetal.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.74. `SANIDAD_VER`

- Módulo: Sanidad vegetal.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.75. `SANIDAD_CREAR`

- Módulo: Sanidad vegetal.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.76. `SANIDAD_EDITAR`

- Módulo: Sanidad vegetal.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.77. `SANIDAD_RETIRAR`

- Módulo: Sanidad vegetal.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.78. `SANIDAD_CONFIRMAR`

- Módulo: Sanidad vegetal.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.79. `SANIDAD_APROBAR`

- Módulo: Sanidad vegetal.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.80. `SANIDAD_EXPORTAR`

- Módulo: Sanidad vegetal.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.81. `SANIDAD_ADMINISTRAR`

- Módulo: Sanidad vegetal.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.82. `PRODUCCION_LISTAR`

- Módulo: Producción disponible.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.83. `PRODUCCION_VER`

- Módulo: Producción disponible.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.84. `PRODUCCION_CREAR`

- Módulo: Producción disponible.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.85. `PRODUCCION_EDITAR`

- Módulo: Producción disponible.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.86. `PRODUCCION_RETIRAR`

- Módulo: Producción disponible.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.87. `PRODUCCION_CONFIRMAR`

- Módulo: Producción disponible.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.88. `PRODUCCION_APROBAR`

- Módulo: Producción disponible.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.89. `PRODUCCION_EXPORTAR`

- Módulo: Producción disponible.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.90. `PRODUCCION_ADMINISTRAR`

- Módulo: Producción disponible.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.91. `CAMPANIAS_LISTAR`

- Módulo: Campañas de venta.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.92. `CAMPANIAS_VER`

- Módulo: Campañas de venta.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.93. `CAMPANIAS_CREAR`

- Módulo: Campañas de venta.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.94. `CAMPANIAS_EDITAR`

- Módulo: Campañas de venta.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.95. `CAMPANIAS_RETIRAR`

- Módulo: Campañas de venta.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.96. `CAMPANIAS_CONFIRMAR`

- Módulo: Campañas de venta.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.97. `CAMPANIAS_APROBAR`

- Módulo: Campañas de venta.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.98. `CAMPANIAS_EXPORTAR`

- Módulo: Campañas de venta.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.99. `CAMPANIAS_ADMINISTRAR`

- Módulo: Campañas de venta.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.100. `PRECIOS_LISTAR`

- Módulo: Condiciones y precios.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.101. `PRECIOS_VER`

- Módulo: Condiciones y precios.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.102. `PRECIOS_CREAR`

- Módulo: Condiciones y precios.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.103. `PRECIOS_EDITAR`

- Módulo: Condiciones y precios.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.104. `PRECIOS_RETIRAR`

- Módulo: Condiciones y precios.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.105. `PRECIOS_CONFIRMAR`

- Módulo: Condiciones y precios.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.106. `PRECIOS_APROBAR`

- Módulo: Condiciones y precios.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.107. `PRECIOS_EXPORTAR`

- Módulo: Condiciones y precios.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.108. `PRECIOS_ADMINISTRAR`

- Módulo: Condiciones y precios.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.109. `PARTICIPANTES_LISTAR`

- Módulo: Participantes de campaña.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.110. `PARTICIPANTES_VER`

- Módulo: Participantes de campaña.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.111. `PARTICIPANTES_CREAR`

- Módulo: Participantes de campaña.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.112. `PARTICIPANTES_EDITAR`

- Módulo: Participantes de campaña.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.113. `PARTICIPANTES_RETIRAR`

- Módulo: Participantes de campaña.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.114. `PARTICIPANTES_CONFIRMAR`

- Módulo: Participantes de campaña.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.115. `PARTICIPANTES_APROBAR`

- Módulo: Participantes de campaña.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.116. `PARTICIPANTES_EXPORTAR`

- Módulo: Participantes de campaña.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.117. `PARTICIPANTES_ADMINISTRAR`

- Módulo: Participantes de campaña.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.118. `OPERATIVOS_LISTAR`

- Módulo: Operativos de venta.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.119. `OPERATIVOS_VER`

- Módulo: Operativos de venta.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.120. `OPERATIVOS_CREAR`

- Módulo: Operativos de venta.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.121. `OPERATIVOS_EDITAR`

- Módulo: Operativos de venta.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.122. `OPERATIVOS_RETIRAR`

- Módulo: Operativos de venta.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.123. `OPERATIVOS_CONFIRMAR`

- Módulo: Operativos de venta.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.124. `OPERATIVOS_APROBAR`

- Módulo: Operativos de venta.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.125. `OPERATIVOS_EXPORTAR`

- Módulo: Operativos de venta.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.126. `OPERATIVOS_ADMINISTRAR`

- Módulo: Operativos de venta.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.127. `JABAS_LISTAR`

- Módulo: Control de jabas.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.128. `JABAS_VER`

- Módulo: Control de jabas.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.129. `JABAS_CREAR`

- Módulo: Control de jabas.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.130. `JABAS_EDITAR`

- Módulo: Control de jabas.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.131. `JABAS_RETIRAR`

- Módulo: Control de jabas.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.132. `JABAS_CONFIRMAR`

- Módulo: Control de jabas.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.133. `JABAS_APROBAR`

- Módulo: Control de jabas.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.134. `JABAS_EXPORTAR`

- Módulo: Control de jabas.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.135. `JABAS_ADMINISTRAR`

- Módulo: Control de jabas.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.136. `ENTREGAS_LISTAR`

- Módulo: Acopio y entregas.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.137. `ENTREGAS_VER`

- Módulo: Acopio y entregas.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.138. `ENTREGAS_CREAR`

- Módulo: Acopio y entregas.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.139. `ENTREGAS_EDITAR`

- Módulo: Acopio y entregas.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.140. `ENTREGAS_RETIRAR`

- Módulo: Acopio y entregas.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.141. `ENTREGAS_CONFIRMAR`

- Módulo: Acopio y entregas.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.142. `ENTREGAS_APROBAR`

- Módulo: Acopio y entregas.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.143. `ENTREGAS_EXPORTAR`

- Módulo: Acopio y entregas.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.144. `ENTREGAS_ADMINISTRAR`

- Módulo: Acopio y entregas.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.145. `INCIDENCIAS_LISTAR`

- Módulo: Incidencias operativas.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.146. `INCIDENCIAS_VER`

- Módulo: Incidencias operativas.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.147. `INCIDENCIAS_CREAR`

- Módulo: Incidencias operativas.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.148. `INCIDENCIAS_EDITAR`

- Módulo: Incidencias operativas.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.149. `INCIDENCIAS_RETIRAR`

- Módulo: Incidencias operativas.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.150. `INCIDENCIAS_CONFIRMAR`

- Módulo: Incidencias operativas.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.151. `INCIDENCIAS_APROBAR`

- Módulo: Incidencias operativas.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.152. `INCIDENCIAS_EXPORTAR`

- Módulo: Incidencias operativas.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.153. `INCIDENCIAS_ADMINISTRAR`

- Módulo: Incidencias operativas.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.154. `AJUSTES_LISTAR`

- Módulo: Ajustes de precio.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.155. `AJUSTES_VER`

- Módulo: Ajustes de precio.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.156. `AJUSTES_CREAR`

- Módulo: Ajustes de precio.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.157. `AJUSTES_EDITAR`

- Módulo: Ajustes de precio.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.158. `AJUSTES_RETIRAR`

- Módulo: Ajustes de precio.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.159. `AJUSTES_CONFIRMAR`

- Módulo: Ajustes de precio.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.160. `AJUSTES_APROBAR`

- Módulo: Ajustes de precio.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.161. `AJUSTES_EXPORTAR`

- Módulo: Ajustes de precio.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.162. `AJUSTES_ADMINISTRAR`

- Módulo: Ajustes de precio.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.163. `INVENTARIO_LISTAR`

- Módulo: Inventario y vehículos.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.164. `INVENTARIO_VER`

- Módulo: Inventario y vehículos.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.165. `INVENTARIO_CREAR`

- Módulo: Inventario y vehículos.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.166. `INVENTARIO_EDITAR`

- Módulo: Inventario y vehículos.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.167. `INVENTARIO_RETIRAR`

- Módulo: Inventario y vehículos.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.168. `INVENTARIO_CONFIRMAR`

- Módulo: Inventario y vehículos.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.169. `INVENTARIO_APROBAR`

- Módulo: Inventario y vehículos.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.170. `INVENTARIO_EXPORTAR`

- Módulo: Inventario y vehículos.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.171. `INVENTARIO_ADMINISTRAR`

- Módulo: Inventario y vehículos.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.172. `RECURSOS_LISTAR`

- Módulo: Recursos programados.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.173. `RECURSOS_VER`

- Módulo: Recursos programados.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.174. `RECURSOS_CREAR`

- Módulo: Recursos programados.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.175. `RECURSOS_EDITAR`

- Módulo: Recursos programados.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.176. `RECURSOS_RETIRAR`

- Módulo: Recursos programados.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.177. `RECURSOS_CONFIRMAR`

- Módulo: Recursos programados.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.178. `RECURSOS_APROBAR`

- Módulo: Recursos programados.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.179. `RECURSOS_EXPORTAR`

- Módulo: Recursos programados.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.180. `RECURSOS_ADMINISTRAR`

- Módulo: Recursos programados.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.181. `GASTOS_LISTAR`

- Módulo: Gastos.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.182. `GASTOS_VER`

- Módulo: Gastos.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.183. `GASTOS_CREAR`

- Módulo: Gastos.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.184. `GASTOS_EDITAR`

- Módulo: Gastos.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.185. `GASTOS_RETIRAR`

- Módulo: Gastos.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.186. `GASTOS_CONFIRMAR`

- Módulo: Gastos.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.187. `GASTOS_APROBAR`

- Módulo: Gastos.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.188. `GASTOS_EXPORTAR`

- Módulo: Gastos.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.189. `GASTOS_ADMINISTRAR`

- Módulo: Gastos.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.190. `LIQUIDACIONES_LISTAR`

- Módulo: Liquidaciones.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.191. `LIQUIDACIONES_VER`

- Módulo: Liquidaciones.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.192. `LIQUIDACIONES_CREAR`

- Módulo: Liquidaciones.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.193. `LIQUIDACIONES_EDITAR`

- Módulo: Liquidaciones.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.194. `LIQUIDACIONES_RETIRAR`

- Módulo: Liquidaciones.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.195. `LIQUIDACIONES_CONFIRMAR`

- Módulo: Liquidaciones.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.196. `LIQUIDACIONES_APROBAR`

- Módulo: Liquidaciones.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.197. `LIQUIDACIONES_EXPORTAR`

- Módulo: Liquidaciones.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.198. `LIQUIDACIONES_ADMINISTRAR`

- Módulo: Liquidaciones.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.199. `PAGOS_LISTAR`

- Módulo: Pagos a socios.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.200. `PAGOS_VER`

- Módulo: Pagos a socios.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.201. `PAGOS_CREAR`

- Módulo: Pagos a socios.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.202. `PAGOS_EDITAR`

- Módulo: Pagos a socios.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.203. `PAGOS_RETIRAR`

- Módulo: Pagos a socios.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.204. `PAGOS_CONFIRMAR`

- Módulo: Pagos a socios.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.205. `PAGOS_APROBAR`

- Módulo: Pagos a socios.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.206. `PAGOS_EXPORTAR`

- Módulo: Pagos a socios.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.207. `PAGOS_ADMINISTRAR`

- Módulo: Pagos a socios.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.208. `COBROS_LISTAR`

- Módulo: Cobros de compradores.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.209. `COBROS_VER`

- Módulo: Cobros de compradores.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.210. `COBROS_CREAR`

- Módulo: Cobros de compradores.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.211. `COBROS_EDITAR`

- Módulo: Cobros de compradores.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.212. `COBROS_RETIRAR`

- Módulo: Cobros de compradores.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.213. `COBROS_CONFIRMAR`

- Módulo: Cobros de compradores.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.214. `COBROS_APROBAR`

- Módulo: Cobros de compradores.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.215. `COBROS_EXPORTAR`

- Módulo: Cobros de compradores.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.216. `COBROS_ADMINISTRAR`

- Módulo: Cobros de compradores.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.217. `ORGANIZACIONES_LISTAR`

- Módulo: Empresas, asociaciones y áreas.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.218. `ORGANIZACIONES_VER`

- Módulo: Empresas, asociaciones y áreas.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.219. `ORGANIZACIONES_CREAR`

- Módulo: Empresas, asociaciones y áreas.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.220. `ORGANIZACIONES_EDITAR`

- Módulo: Empresas, asociaciones y áreas.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.221. `ORGANIZACIONES_RETIRAR`

- Módulo: Empresas, asociaciones y áreas.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.222. `ORGANIZACIONES_CONFIRMAR`

- Módulo: Empresas, asociaciones y áreas.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.223. `ORGANIZACIONES_APROBAR`

- Módulo: Empresas, asociaciones y áreas.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.224. `ORGANIZACIONES_EXPORTAR`

- Módulo: Empresas, asociaciones y áreas.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.225. `ORGANIZACIONES_ADMINISTRAR`

- Módulo: Empresas, asociaciones y áreas.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.226. `EMPLEADOS_LISTAR`

- Módulo: Empleados.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.227. `EMPLEADOS_VER`

- Módulo: Empleados.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.228. `EMPLEADOS_CREAR`

- Módulo: Empleados.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.229. `EMPLEADOS_EDITAR`

- Módulo: Empleados.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.230. `EMPLEADOS_RETIRAR`

- Módulo: Empleados.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.231. `EMPLEADOS_CONFIRMAR`

- Módulo: Empleados.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.232. `EMPLEADOS_APROBAR`

- Módulo: Empleados.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.233. `EMPLEADOS_EXPORTAR`

- Módulo: Empleados.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.234. `EMPLEADOS_ADMINISTRAR`

- Módulo: Empleados.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.235. `USUARIOS_LISTAR`

- Módulo: Usuarios y accesos.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.236. `USUARIOS_VER`

- Módulo: Usuarios y accesos.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.237. `USUARIOS_CREAR`

- Módulo: Usuarios y accesos.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.238. `USUARIOS_EDITAR`

- Módulo: Usuarios y accesos.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.239. `USUARIOS_RETIRAR`

- Módulo: Usuarios y accesos.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.240. `USUARIOS_CONFIRMAR`

- Módulo: Usuarios y accesos.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.241. `USUARIOS_APROBAR`

- Módulo: Usuarios y accesos.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.242. `USUARIOS_EXPORTAR`

- Módulo: Usuarios y accesos.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.243. `USUARIOS_ADMINISTRAR`

- Módulo: Usuarios y accesos.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.244. `ROLESPERMISOS_LISTAR`

- Módulo: Roles y permisos.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.245. `ROLESPERMISOS_VER`

- Módulo: Roles y permisos.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.246. `ROLESPERMISOS_CREAR`

- Módulo: Roles y permisos.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.247. `ROLESPERMISOS_EDITAR`

- Módulo: Roles y permisos.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.248. `ROLESPERMISOS_RETIRAR`

- Módulo: Roles y permisos.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.249. `ROLESPERMISOS_CONFIRMAR`

- Módulo: Roles y permisos.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.250. `ROLESPERMISOS_APROBAR`

- Módulo: Roles y permisos.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.251. `ROLESPERMISOS_EXPORTAR`

- Módulo: Roles y permisos.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.252. `ROLESPERMISOS_ADMINISTRAR`

- Módulo: Roles y permisos.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.253. `CATALOGOS_LISTAR`

- Módulo: Catálogos.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.254. `CATALOGOS_VER`

- Módulo: Catálogos.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.255. `CATALOGOS_CREAR`

- Módulo: Catálogos.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.256. `CATALOGOS_EDITAR`

- Módulo: Catálogos.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.257. `CATALOGOS_RETIRAR`

- Módulo: Catálogos.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.258. `CATALOGOS_CONFIRMAR`

- Módulo: Catálogos.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.259. `CATALOGOS_APROBAR`

- Módulo: Catálogos.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.260. `CATALOGOS_EXPORTAR`

- Módulo: Catálogos.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.261. `CATALOGOS_ADMINISTRAR`

- Módulo: Catálogos.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.262. `ARCHIVOS_LISTAR`

- Módulo: Documentos y evidencias.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.263. `ARCHIVOS_VER`

- Módulo: Documentos y evidencias.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.264. `ARCHIVOS_CREAR`

- Módulo: Documentos y evidencias.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.265. `ARCHIVOS_EDITAR`

- Módulo: Documentos y evidencias.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.266. `ARCHIVOS_RETIRAR`

- Módulo: Documentos y evidencias.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.267. `ARCHIVOS_CONFIRMAR`

- Módulo: Documentos y evidencias.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.268. `ARCHIVOS_APROBAR`

- Módulo: Documentos y evidencias.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.269. `ARCHIVOS_EXPORTAR`

- Módulo: Documentos y evidencias.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.270. `ARCHIVOS_ADMINISTRAR`

- Módulo: Documentos y evidencias.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.271. `REPORTES_LISTAR`

- Módulo: Reportes e indicadores.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.272. `REPORTES_VER`

- Módulo: Reportes e indicadores.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.273. `REPORTES_CREAR`

- Módulo: Reportes e indicadores.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.274. `REPORTES_EDITAR`

- Módulo: Reportes e indicadores.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.275. `REPORTES_RETIRAR`

- Módulo: Reportes e indicadores.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.276. `REPORTES_CONFIRMAR`

- Módulo: Reportes e indicadores.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.277. `REPORTES_APROBAR`

- Módulo: Reportes e indicadores.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.278. `REPORTES_EXPORTAR`

- Módulo: Reportes e indicadores.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.279. `REPORTES_ADMINISTRAR`

- Módulo: Reportes e indicadores.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.280. `AUDITORIA_LISTAR`

- Módulo: Auditoría.
- Acción: LISTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.281. `AUDITORIA_VER`

- Módulo: Auditoría.
- Acción: VER.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.282. `AUDITORIA_CREAR`

- Módulo: Auditoría.
- Acción: CREAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.283. `AUDITORIA_EDITAR`

- Módulo: Auditoría.
- Acción: EDITAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.284. `AUDITORIA_RETIRAR`

- Módulo: Auditoría.
- Acción: RETIRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.285. `AUDITORIA_CONFIRMAR`

- Módulo: Auditoría.
- Acción: CONFIRMAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.286. `AUDITORIA_APROBAR`

- Módulo: Auditoría.
- Acción: APROBAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.287. `AUDITORIA_EXPORTAR`

- Módulo: Auditoría.
- Acción: EXPORTAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

## 35.288. `AUDITORIA_ADMINISTRAR`

- Módulo: Auditoría.
- Acción: ADMINISTRAR.
- El permiso puede asignarse a uno o varios roles.
- El permiso puede retirarse sin modificar el flujo general del módulo.
- La interfaz oculta el control si el permiso no existe.
- Un intento directo sin permiso debe ser rechazado.
- El estado del proceso puede restringir la acción incluso si existe permiso.
- Toda acción sensible registra trazabilidad.

# PARTE XXXVI. ESTADOS Y TRANSICIONES VISIBLES

## 36.1. Salida de campo

- `BORRADOR`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `PROGRAMADA`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `EN_CURSO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `FINALIZADA`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `CANCELADA`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- No se cambia el estado mediante un selector genérico sin reglas.
- Toda transición sensible registra usuario y fecha.

## 36.2. Visita

- `INICIADA`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `FINALIZADA`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `ANULADA`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- No se cambia el estado mediante un selector genérico sin reglas.
- Toda transición sensible registra usuario y fecha.

## 36.3. Cultivo

- `ACTIVO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `FINALIZADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `ABANDONADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- No se cambia el estado mediante un selector genérico sin reglas.
- Toda transición sensible registra usuario y fecha.

## 36.4. Caso fitosanitario

- `DETECTADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `EN_TRATAMIENTO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `EN_SEGUIMIENTO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `CONTROLADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `RECUPERADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `NO_RECUPERADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `CERRADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- No se cambia el estado mediante un selector genérico sin reglas.
- Toda transición sensible registra usuario y fecha.

## 36.5. Producción

- `ESTIMADA`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `CONFIRMADA`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `DESCARTADA`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- No se cambia el estado mediante un selector genérico sin reglas.
- Toda transición sensible registra usuario y fecha.

## 36.6. Campaña

- `PLANIFICACION`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `ACTIVA`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `CERRADA`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `CANCELADA`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- No se cambia el estado mediante un selector genérico sin reglas.
- Toda transición sensible registra usuario y fecha.

## 36.7. Operativo

- `PLANIFICADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `EN_RECEPCION`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `CERRADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `CANCELADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- No se cambia el estado mediante un selector genérico sin reglas.
- Toda transición sensible registra usuario y fecha.

## 36.8. Participación

- `ACTIVO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `RETIRADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `EXCLUIDO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- No se cambia el estado mediante un selector genérico sin reglas.
- Toda transición sensible registra usuario y fecha.

## 36.9. Productor en operativo

- `PROGRAMADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `PARTICIPO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `NO_PARTICIPO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `RETIRADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- No se cambia el estado mediante un selector genérico sin reglas.
- Toda transición sensible registra usuario y fecha.

## 36.10. Entrega

- `REGISTRADA`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `CONFIRMADA`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `ANULADA`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- No se cambia el estado mediante un selector genérico sin reglas.
- Toda transición sensible registra usuario y fecha.

## 36.11. Calidad

- `PENDIENTE`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `CONFORME`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `OBSERVADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `RECHAZADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- No se cambia el estado mediante un selector genérico sin reglas.
- Toda transición sensible registra usuario y fecha.

## 36.12. Incidencia

- `ABIERTA`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `EN_REVISION`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `RESUELTA`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `ANULADA`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- No se cambia el estado mediante un selector genérico sin reglas.
- Toda transición sensible registra usuario y fecha.

## 36.13. Gasto

- `REGISTRADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `APROBADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `ANULADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- No se cambia el estado mediante un selector genérico sin reglas.
- Toda transición sensible registra usuario y fecha.

## 36.14. Liquidación

- `BORRADOR`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `CALCULADA`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `APROBADA`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `PAGADA_PARCIAL`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `PAGADA`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `ANULADA`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- No se cambia el estado mediante un selector genérico sin reglas.
- Toda transición sensible registra usuario y fecha.

## 36.15. Pago

- `REGISTRADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `CONFIRMADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `ANULADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- No se cambia el estado mediante un selector genérico sin reglas.
- Toda transición sensible registra usuario y fecha.

## 36.16. Cobro

- `REGISTRADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `CONFIRMADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- `ANULADO`.
  - Debe mostrarse con etiqueta comprensible.
  - Debe habilitar únicamente acciones válidas.
- No se cambia el estado mediante un selector genérico sin reglas.
- Toda transición sensible registra usuario y fecha.

# PARTE XXXVII. FLUJO OPERATIVO COMPLETO

## 37.1. Administrador registra empleados y estructura organizacional.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.2. Administrador crea cuentas y asigna roles.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.3. Empleado valida su correo.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.4. Empleado inicia sesión.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.5. El sistema solicita segundo factor cuando corresponde.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.6. Técnico registra productor.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.7. Técnico registra predio.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.8. Técnico selecciona ubicación territorial en cascada.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.9. Técnico captura GPS.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.10. Técnico registra parcela.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.11. Técnico registra cultivo.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.12. Técnico registra censo.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.13. Coordinador técnico programa salida.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.14. Logística prepara recursos.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.15. Técnico inicia visita.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.16. Técnico registra evaluación.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.17. Técnico registra materia seca.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.18. Técnico registra caso fitosanitario si detecta problema.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.19. Técnico registra tratamiento.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.20. Técnico registra seguimiento.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.21. Técnico registra producción estimada.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.22. Coordinador técnico confirma producción.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.23. Coordinador comercial consulta producción disponible.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.24. Coordinador comercial crea campaña.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.25. Selecciona comprador.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.26. Define condiciones.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.27. Registra precio.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.28. Selecciona participantes.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.29. Crea operativo.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.30. Asigna zonas.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.31. Programa productores.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.32. Registra jabas recibidas.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.33. Operador asigna jabas.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.34. Operador registra devoluciones.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.35. Operador registra entrega.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.36. Registra pesos.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.37. Registra clasificación.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.38. Adjunta ticket.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.39. Registra incidencia cuando corresponda.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.40. Coordinador confirma entrega.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.41. Coordinador resuelve incidencias.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.42. Coordinador cierra operativo.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.43. Finanzas registra gastos.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.44. Finanzas ejecuta prorrateo.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.45. Finanzas calcula liquidación.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.46. Finanzas aprueba liquidación.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.47. Finanzas registra pago.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.48. Finanzas confirma pago.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.49. Finanzas registra cobro.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.50. Jefe UOT consulta indicadores.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

## 37.51. Auditor revisa trazabilidad.

- Verificar permiso.
- Verificar estado.
- Verificar datos obligatorios.
- Verificar relaciones del proceso.
- Mostrar confirmación si la acción es sensible.
- Mostrar mensaje funcional al terminar.
- Registrar trazabilidad cuando corresponda.

# PARTE XXXVIII. MATRIZ COMPLETA DE ACCESO

## 38.1. Administrador / Dashboard

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.2. Administrador / Productores / socios

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.3. Administrador / Predios

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.4. Administrador / Parcelas y cultivos

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.5. Administrador / Censos de plantas

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.6. Administrador / Salidas de campo

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.7. Administrador / Visitas técnicas

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.8. Administrador / Evaluaciones agronómicas

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.9. Administrador / Sanidad vegetal

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.10. Administrador / Producción disponible

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.11. Administrador / Campañas de venta

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.12. Administrador / Condiciones y precios

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.13. Administrador / Participantes de campaña

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.14. Administrador / Operativos de venta

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.15. Administrador / Control de jabas

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.16. Administrador / Acopio y entregas

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.17. Administrador / Incidencias operativas

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.18. Administrador / Ajustes de precio

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.19. Administrador / Inventario y vehículos

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.20. Administrador / Recursos programados

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.21. Administrador / Gastos

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.22. Administrador / Liquidaciones

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.23. Administrador / Pagos a socios

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.24. Administrador / Cobros de compradores

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.25. Administrador / Empresas, asociaciones y áreas

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.26. Administrador / Empleados

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.27. Administrador / Usuarios y accesos

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.28. Administrador / Roles y permisos

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.29. Administrador / Catálogos

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.30. Administrador / Documentos y evidencias

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.31. Administrador / Reportes e indicadores

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.32. Administrador / Auditoría

- Acceso: SÍ.
- Nivel: `TOTAL`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.33. Jefe / Responsable UOT / Dashboard

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.34. Jefe / Responsable UOT / Productores / socios

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.35. Jefe / Responsable UOT / Predios

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.36. Jefe / Responsable UOT / Parcelas y cultivos

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.37. Jefe / Responsable UOT / Censos de plantas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.38. Jefe / Responsable UOT / Salidas de campo

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.39. Jefe / Responsable UOT / Visitas técnicas

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.40. Jefe / Responsable UOT / Evaluaciones agronómicas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.41. Jefe / Responsable UOT / Sanidad vegetal

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.42. Jefe / Responsable UOT / Producción disponible

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.43. Jefe / Responsable UOT / Campañas de venta

- Acceso: SÍ.
- Nivel: `SUPERVISION_APROBACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.44. Jefe / Responsable UOT / Condiciones y precios

- Acceso: SÍ.
- Nivel: `SUPERVISION_APROBACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.45. Jefe / Responsable UOT / Participantes de campaña

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.46. Jefe / Responsable UOT / Operativos de venta

- Acceso: SÍ.
- Nivel: `SUPERVISION_APROBACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.47. Jefe / Responsable UOT / Control de jabas

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.48. Jefe / Responsable UOT / Acopio y entregas

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.49. Jefe / Responsable UOT / Incidencias operativas

- Acceso: SÍ.
- Nivel: `SUPERVISION_APROBACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.50. Jefe / Responsable UOT / Ajustes de precio

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.51. Jefe / Responsable UOT / Inventario y vehículos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.52. Jefe / Responsable UOT / Recursos programados

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.53. Jefe / Responsable UOT / Gastos

- Acceso: SÍ.
- Nivel: `SUPERVISION_APROBACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.54. Jefe / Responsable UOT / Liquidaciones

- Acceso: SÍ.
- Nivel: `SUPERVISION_APROBACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.55. Jefe / Responsable UOT / Pagos a socios

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.56. Jefe / Responsable UOT / Cobros de compradores

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.57. Jefe / Responsable UOT / Empresas, asociaciones y áreas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.58. Jefe / Responsable UOT / Empleados

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.59. Jefe / Responsable UOT / Usuarios y accesos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.60. Jefe / Responsable UOT / Roles y permisos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.61. Jefe / Responsable UOT / Catálogos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.62. Jefe / Responsable UOT / Documentos y evidencias

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.63. Jefe / Responsable UOT / Reportes e indicadores

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.64. Jefe / Responsable UOT / Auditoría

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.65. Coordinador técnico / Dashboard

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.66. Coordinador técnico / Productores / socios

- Acceso: SÍ.
- Nivel: `COORDINACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.67. Coordinador técnico / Predios

- Acceso: SÍ.
- Nivel: `COORDINACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.68. Coordinador técnico / Parcelas y cultivos

- Acceso: SÍ.
- Nivel: `COORDINACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.69. Coordinador técnico / Censos de plantas

- Acceso: SÍ.
- Nivel: `COORDINACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.70. Coordinador técnico / Salidas de campo

- Acceso: SÍ.
- Nivel: `COORDINACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.71. Coordinador técnico / Visitas técnicas

- Acceso: SÍ.
- Nivel: `COORDINACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.72. Coordinador técnico / Evaluaciones agronómicas

- Acceso: SÍ.
- Nivel: `COORDINACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.73. Coordinador técnico / Sanidad vegetal

- Acceso: SÍ.
- Nivel: `COORDINACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.74. Coordinador técnico / Producción disponible

- Acceso: SÍ.
- Nivel: `COORDINACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.75. Coordinador técnico / Campañas de venta

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.76. Coordinador técnico / Condiciones y precios

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.77. Coordinador técnico / Participantes de campaña

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.78. Coordinador técnico / Operativos de venta

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.79. Coordinador técnico / Control de jabas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.80. Coordinador técnico / Acopio y entregas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.81. Coordinador técnico / Incidencias operativas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.82. Coordinador técnico / Ajustes de precio

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.83. Coordinador técnico / Inventario y vehículos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.84. Coordinador técnico / Recursos programados

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.85. Coordinador técnico / Gastos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.86. Coordinador técnico / Liquidaciones

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.87. Coordinador técnico / Pagos a socios

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.88. Coordinador técnico / Cobros de compradores

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.89. Coordinador técnico / Empresas, asociaciones y áreas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.90. Coordinador técnico / Empleados

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.91. Coordinador técnico / Usuarios y accesos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.92. Coordinador técnico / Roles y permisos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.93. Coordinador técnico / Catálogos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.94. Coordinador técnico / Documentos y evidencias

- Acceso: SÍ.
- Nivel: `COORDINACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.95. Coordinador técnico / Reportes e indicadores

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.96. Coordinador técnico / Auditoría

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.97. Técnico de campo / Dashboard

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.98. Técnico de campo / Productores / socios

- Acceso: SÍ.
- Nivel: `OPERACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.99. Técnico de campo / Predios

- Acceso: SÍ.
- Nivel: `OPERACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.100. Técnico de campo / Parcelas y cultivos

- Acceso: SÍ.
- Nivel: `OPERACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.101. Técnico de campo / Censos de plantas

- Acceso: SÍ.
- Nivel: `OPERACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.102. Técnico de campo / Salidas de campo

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.103. Técnico de campo / Visitas técnicas

- Acceso: SÍ.
- Nivel: `OPERACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.104. Técnico de campo / Evaluaciones agronómicas

- Acceso: SÍ.
- Nivel: `OPERACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.105. Técnico de campo / Sanidad vegetal

- Acceso: SÍ.
- Nivel: `OPERACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.106. Técnico de campo / Producción disponible

- Acceso: SÍ.
- Nivel: `OPERACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.107. Técnico de campo / Campañas de venta

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.108. Técnico de campo / Condiciones y precios

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.109. Técnico de campo / Participantes de campaña

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.110. Técnico de campo / Operativos de venta

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.111. Técnico de campo / Control de jabas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.112. Técnico de campo / Acopio y entregas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.113. Técnico de campo / Incidencias operativas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.114. Técnico de campo / Ajustes de precio

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.115. Técnico de campo / Inventario y vehículos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.116. Técnico de campo / Recursos programados

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.117. Técnico de campo / Gastos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.118. Técnico de campo / Liquidaciones

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.119. Técnico de campo / Pagos a socios

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.120. Técnico de campo / Cobros de compradores

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.121. Técnico de campo / Empresas, asociaciones y áreas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.122. Técnico de campo / Empleados

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.123. Técnico de campo / Usuarios y accesos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.124. Técnico de campo / Roles y permisos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.125. Técnico de campo / Catálogos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.126. Técnico de campo / Documentos y evidencias

- Acceso: SÍ.
- Nivel: `OPERACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.127. Técnico de campo / Reportes e indicadores

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.128. Técnico de campo / Auditoría

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.129. Coordinador comercial / Dashboard

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.130. Coordinador comercial / Productores / socios

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.131. Coordinador comercial / Predios

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.132. Coordinador comercial / Parcelas y cultivos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.133. Coordinador comercial / Censos de plantas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.134. Coordinador comercial / Salidas de campo

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.135. Coordinador comercial / Visitas técnicas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.136. Coordinador comercial / Evaluaciones agronómicas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.137. Coordinador comercial / Sanidad vegetal

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.138. Coordinador comercial / Producción disponible

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.139. Coordinador comercial / Campañas de venta

- Acceso: SÍ.
- Nivel: `COORDINACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.140. Coordinador comercial / Condiciones y precios

- Acceso: SÍ.
- Nivel: `COORDINACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.141. Coordinador comercial / Participantes de campaña

- Acceso: SÍ.
- Nivel: `COORDINACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.142. Coordinador comercial / Operativos de venta

- Acceso: SÍ.
- Nivel: `COORDINACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.143. Coordinador comercial / Control de jabas

- Acceso: SÍ.
- Nivel: `COORDINACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.144. Coordinador comercial / Acopio y entregas

- Acceso: SÍ.
- Nivel: `COORDINACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.145. Coordinador comercial / Incidencias operativas

- Acceso: SÍ.
- Nivel: `COORDINACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.146. Coordinador comercial / Ajustes de precio

- Acceso: SÍ.
- Nivel: `COORDINACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.147. Coordinador comercial / Inventario y vehículos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.148. Coordinador comercial / Recursos programados

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.149. Coordinador comercial / Gastos

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.150. Coordinador comercial / Liquidaciones

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.151. Coordinador comercial / Pagos a socios

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.152. Coordinador comercial / Cobros de compradores

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.153. Coordinador comercial / Empresas, asociaciones y áreas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.154. Coordinador comercial / Empleados

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.155. Coordinador comercial / Usuarios y accesos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.156. Coordinador comercial / Roles y permisos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.157. Coordinador comercial / Catálogos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.158. Coordinador comercial / Documentos y evidencias

- Acceso: SÍ.
- Nivel: `COORDINACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.159. Coordinador comercial / Reportes e indicadores

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.160. Coordinador comercial / Auditoría

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.161. Operador comercial y de acopio / Dashboard

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.162. Operador comercial y de acopio / Productores / socios

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.163. Operador comercial y de acopio / Predios

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.164. Operador comercial y de acopio / Parcelas y cultivos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.165. Operador comercial y de acopio / Censos de plantas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.166. Operador comercial y de acopio / Salidas de campo

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.167. Operador comercial y de acopio / Visitas técnicas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.168. Operador comercial y de acopio / Evaluaciones agronómicas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.169. Operador comercial y de acopio / Sanidad vegetal

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.170. Operador comercial y de acopio / Producción disponible

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.171. Operador comercial y de acopio / Campañas de venta

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.172. Operador comercial y de acopio / Condiciones y precios

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.173. Operador comercial y de acopio / Participantes de campaña

- Acceso: SÍ.
- Nivel: `OPERACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.174. Operador comercial y de acopio / Operativos de venta

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.175. Operador comercial y de acopio / Control de jabas

- Acceso: SÍ.
- Nivel: `OPERACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.176. Operador comercial y de acopio / Acopio y entregas

- Acceso: SÍ.
- Nivel: `OPERACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.177. Operador comercial y de acopio / Incidencias operativas

- Acceso: SÍ.
- Nivel: `OPERACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.178. Operador comercial y de acopio / Ajustes de precio

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.179. Operador comercial y de acopio / Inventario y vehículos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.180. Operador comercial y de acopio / Recursos programados

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.181. Operador comercial y de acopio / Gastos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.182. Operador comercial y de acopio / Liquidaciones

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.183. Operador comercial y de acopio / Pagos a socios

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.184. Operador comercial y de acopio / Cobros de compradores

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.185. Operador comercial y de acopio / Empresas, asociaciones y áreas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.186. Operador comercial y de acopio / Empleados

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.187. Operador comercial y de acopio / Usuarios y accesos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.188. Operador comercial y de acopio / Roles y permisos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.189. Operador comercial y de acopio / Catálogos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.190. Operador comercial y de acopio / Documentos y evidencias

- Acceso: SÍ.
- Nivel: `OPERACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.191. Operador comercial y de acopio / Reportes e indicadores

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.192. Operador comercial y de acopio / Auditoría

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.193. Responsable de logística / Dashboard

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.194. Responsable de logística / Productores / socios

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.195. Responsable de logística / Predios

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.196. Responsable de logística / Parcelas y cultivos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.197. Responsable de logística / Censos de plantas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.198. Responsable de logística / Salidas de campo

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.199. Responsable de logística / Visitas técnicas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.200. Responsable de logística / Evaluaciones agronómicas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.201. Responsable de logística / Sanidad vegetal

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.202. Responsable de logística / Producción disponible

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.203. Responsable de logística / Campañas de venta

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.204. Responsable de logística / Condiciones y precios

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.205. Responsable de logística / Participantes de campaña

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.206. Responsable de logística / Operativos de venta

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.207. Responsable de logística / Control de jabas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.208. Responsable de logística / Acopio y entregas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.209. Responsable de logística / Incidencias operativas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.210. Responsable de logística / Ajustes de precio

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.211. Responsable de logística / Inventario y vehículos

- Acceso: SÍ.
- Nivel: `OPERACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.212. Responsable de logística / Recursos programados

- Acceso: SÍ.
- Nivel: `OPERACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.213. Responsable de logística / Gastos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.214. Responsable de logística / Liquidaciones

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.215. Responsable de logística / Pagos a socios

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.216. Responsable de logística / Cobros de compradores

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.217. Responsable de logística / Empresas, asociaciones y áreas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.218. Responsable de logística / Empleados

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.219. Responsable de logística / Usuarios y accesos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.220. Responsable de logística / Roles y permisos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.221. Responsable de logística / Catálogos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.222. Responsable de logística / Documentos y evidencias

- Acceso: SÍ.
- Nivel: `OPERACION`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.223. Responsable de logística / Reportes e indicadores

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.224. Responsable de logística / Auditoría

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.225. Responsable de finanzas y tesorería / Dashboard

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.226. Responsable de finanzas y tesorería / Productores / socios

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.227. Responsable de finanzas y tesorería / Predios

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.228. Responsable de finanzas y tesorería / Parcelas y cultivos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.229. Responsable de finanzas y tesorería / Censos de plantas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.230. Responsable de finanzas y tesorería / Salidas de campo

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.231. Responsable de finanzas y tesorería / Visitas técnicas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.232. Responsable de finanzas y tesorería / Evaluaciones agronómicas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.233. Responsable de finanzas y tesorería / Sanidad vegetal

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.234. Responsable de finanzas y tesorería / Producción disponible

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.235. Responsable de finanzas y tesorería / Campañas de venta

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.236. Responsable de finanzas y tesorería / Condiciones y precios

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.237. Responsable de finanzas y tesorería / Participantes de campaña

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.238. Responsable de finanzas y tesorería / Operativos de venta

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.239. Responsable de finanzas y tesorería / Control de jabas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.240. Responsable de finanzas y tesorería / Acopio y entregas

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.241. Responsable de finanzas y tesorería / Incidencias operativas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.242. Responsable de finanzas y tesorería / Ajustes de precio

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.243. Responsable de finanzas y tesorería / Inventario y vehículos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.244. Responsable de finanzas y tesorería / Recursos programados

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.245. Responsable de finanzas y tesorería / Gastos

- Acceso: SÍ.
- Nivel: `OPERACION_FINANCIERA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.246. Responsable de finanzas y tesorería / Liquidaciones

- Acceso: SÍ.
- Nivel: `OPERACION_FINANCIERA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.247. Responsable de finanzas y tesorería / Pagos a socios

- Acceso: SÍ.
- Nivel: `OPERACION_FINANCIERA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.248. Responsable de finanzas y tesorería / Cobros de compradores

- Acceso: SÍ.
- Nivel: `OPERACION_FINANCIERA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.249. Responsable de finanzas y tesorería / Empresas, asociaciones y áreas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.250. Responsable de finanzas y tesorería / Empleados

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.251. Responsable de finanzas y tesorería / Usuarios y accesos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.252. Responsable de finanzas y tesorería / Roles y permisos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.253. Responsable de finanzas y tesorería / Catálogos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.254. Responsable de finanzas y tesorería / Documentos y evidencias

- Acceso: SÍ.
- Nivel: `OPERACION_FINANCIERA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: SÍ.
- Puede editar: SÍ.
- Puede retirar/anular: SÍ.
- Puede aprobar: SÍ.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.255. Responsable de finanzas y tesorería / Reportes e indicadores

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.256. Responsable de finanzas y tesorería / Auditoría

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.257. Auditor / Consulta / Dashboard

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.258. Auditor / Consulta / Productores / socios

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.259. Auditor / Consulta / Predios

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.260. Auditor / Consulta / Parcelas y cultivos

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.261. Auditor / Consulta / Censos de plantas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.262. Auditor / Consulta / Salidas de campo

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.263. Auditor / Consulta / Visitas técnicas

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.264. Auditor / Consulta / Evaluaciones agronómicas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.265. Auditor / Consulta / Sanidad vegetal

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.266. Auditor / Consulta / Producción disponible

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.267. Auditor / Consulta / Campañas de venta

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.268. Auditor / Consulta / Condiciones y precios

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.269. Auditor / Consulta / Participantes de campaña

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.270. Auditor / Consulta / Operativos de venta

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.271. Auditor / Consulta / Control de jabas

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.272. Auditor / Consulta / Acopio y entregas

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.273. Auditor / Consulta / Incidencias operativas

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.274. Auditor / Consulta / Ajustes de precio

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.275. Auditor / Consulta / Inventario y vehículos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.276. Auditor / Consulta / Recursos programados

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.277. Auditor / Consulta / Gastos

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.278. Auditor / Consulta / Liquidaciones

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.279. Auditor / Consulta / Pagos a socios

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.280. Auditor / Consulta / Cobros de compradores

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.281. Auditor / Consulta / Empresas, asociaciones y áreas

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.282. Auditor / Consulta / Empleados

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.283. Auditor / Consulta / Usuarios y accesos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.284. Auditor / Consulta / Roles y permisos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.285. Auditor / Consulta / Catálogos

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.286. Auditor / Consulta / Documentos y evidencias

- Acceso: NO.
- Nivel: `SIN_ACCESO`.
- Puede listar: NO.
- Puede ver detalle: NO.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.287. Auditor / Consulta / Reportes e indicadores

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

## 38.288. Auditor / Consulta / Auditoría

- Acceso: SÍ.
- Nivel: `LECTURA`.
- Puede listar: SÍ.
- Puede ver detalle: SÍ.
- Puede registrar: NO.
- Puede editar: NO.
- Puede retirar/anular: NO.
- Puede aprobar: NO.
- Si recibe un segundo rol, se suman sus permisos vigentes.
- Las reglas del estado continúan aplicándose.

# PARTE XXXIX. DEFINICIÓN DE TERMINADO

## 39.1. Dashboard

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.2. Productores / socios

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.3. Predios

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.4. Parcelas y cultivos

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.5. Censos de plantas

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.6. Salidas de campo

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.7. Visitas técnicas

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.8. Evaluaciones agronómicas

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.9. Sanidad vegetal

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.10. Producción disponible

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.11. Campañas de venta

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.12. Condiciones y precios

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.13. Participantes de campaña

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.14. Operativos de venta

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.15. Control de jabas

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.16. Acopio y entregas

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.17. Incidencias operativas

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.18. Ajustes de precio

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.19. Inventario y vehículos

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.20. Recursos programados

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.21. Gastos

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.22. Liquidaciones

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.23. Pagos a socios

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.24. Cobros de compradores

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.25. Empresas, asociaciones y áreas

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.26. Empleados

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.27. Usuarios y accesos

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.28. Roles y permisos

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.29. Catálogos

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.30. Documentos y evidencias

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.31. Reportes e indicadores

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

## 39.32. Auditoría

- [ ] Sidebar configurado.
- [ ] Permisos configurados.
- [ ] Listado disponible.
- [ ] Filtros disponibles.
- [ ] Paginación disponible.
- [ ] Detalle disponible.
- [ ] Registro probado si aplica.
- [ ] Edición probada si aplica.
- [ ] Retiro o anulación probado si aplica.
- [ ] Estados probados.
- [ ] Mensajes revisados.
- [ ] Historial verificado.
- [ ] Archivos verificados cuando aplica.
- [ ] Auditoría verificada cuando aplica.
- [ ] Prueba con rol autorizado.
- [ ] Prueba con rol no autorizado.
- [ ] Prueba con estado permitido.
- [ ] Prueba con estado no permitido.
- [ ] Prueba de doble envío.
- [ ] Prueba móvil cuando aplica.

# ANEXO D. ACCIONES EXPLÍCITAS POR ROL

## D.1. Administrador en Dashboard

- Acción funcional disponible en el módulo: ver alertas.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver pendientes.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver accesos rápidos.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver indicadores según rol.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.2. Administrador en Productores / socios

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver predios.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver campañas.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.3. Administrador en Predios

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: capturar GPS.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver mapa.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver titularidad.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.4. Administrador en Parcelas y cultivos

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar parcela.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar parcela.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar cultivo.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar cultivo.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: finalizar cultivo.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver expediente.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.5. Administrador en Censos de plantas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: comparar censos.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.6. Administrador en Salidas de campo

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: programar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cancelar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: iniciar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: finalizar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: asignar participantes.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver recursos.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.7. Administrador en Visitas técnicas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: iniciar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: finalizar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver ubicación.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver evidencias.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.8. Administrador en Evaluaciones agronómicas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar materia seca.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.9. Administrador en Sanidad vegetal

- Acción funcional disponible en el módulo: listar casos.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar caso.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar caso.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar tratamiento.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar seguimiento.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cambiar estado.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cerrar caso.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver evidencias.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.10. Administrador en Producción disponible

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar estimación.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: confirmar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: descartar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar por zona.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar por fecha.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver origen.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.11. Administrador en Campañas de venta

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: crear.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: activar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cerrar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cancelar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver comprador.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver participantes.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver operativos.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.12. Administrador en Condiciones y precios

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: crear condición.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: crear precio.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: versionar precio.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: deshabilitar valor no utilizado.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.13. Administrador en Participantes de campaña

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: incluir socio.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar socio.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: excluir socio.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: programar en operativo.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver entregas.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.14. Administrador en Operativos de venta

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: crear.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: iniciar recepción.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cerrar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cancelar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: asignar zonas.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver indicadores.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.15. Administrador en Control de jabas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: asignar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar devolución.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver saldo.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular movimiento autorizado.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.16. Administrador en Acopio y entregas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar preliminar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: confirmar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver valorización.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar ticket.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.17. Administrador en Incidencias operativas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar revisión.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: resolver.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar evidencia.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver peso afectado.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.18. Administrador en Ajustes de precio

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver impacto.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar sustento.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.19. Administrador en Inventario y vehículos

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar bien.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar bien.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: dar de baja.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar vehículo.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: actualizar kilometraje.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.20. Administrador en Recursos programados

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: programar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cancelar programación.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: asignar bien.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar devolución.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver disponibilidad.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.21. Administrador en Gastos

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar registrado.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: aprobar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar comprobante.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver prorrateo.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.22. Administrador en Liquidaciones

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: calcular.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: recalcular versión.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: aprobar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver saldo.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver pagos.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.23. Administrador en Pagos a socios

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: confirmar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar comprobante.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver saldo posterior.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.24. Administrador en Cobros de compradores

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: confirmar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar comprobante.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver saldo campaña.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.25. Administrador en Empresas, asociaciones y áreas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar empresa.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar empresa.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar asociación.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar asociación.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar área.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar área.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.26. Administrador en Empleados

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial de área.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver usuario.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver roles.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.27. Administrador en Usuarios y accesos

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: crear cuenta.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar cuenta.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: deshabilitar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: reactivar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: revocar sesiones.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: asignar roles.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar roles.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver dispositivos.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.28. Administrador en Roles y permisos

- Acción funcional disponible en el módulo: listar roles.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: crear rol.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar rol.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: deshabilitar rol.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: asignar permisos.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar permisos.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver usuarios por rol.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.29. Administrador en Catálogos

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar valor.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar valor.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: deshabilitar valor.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver uso.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.30. Administrador en Documentos y evidencias

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: subir.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: previsualizar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver contexto.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: tomar fotografía.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.31. Administrador en Reportes e indicadores

- Acción funcional disponible en el módulo: listar reportes.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: exportar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: navegar a origen.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.32. Administrador en Auditoría

- Acción funcional disponible en el módulo: listar eventos.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver antes y después.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: exportar.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver dispositivo.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver usuario.
  - Nivel del rol en este módulo: TOTAL.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.33. Jefe / Responsable UOT en Dashboard

- Acción funcional disponible en el módulo: ver alertas.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver pendientes.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver accesos rápidos.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver indicadores según rol.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.34. Jefe / Responsable UOT en Productores / socios

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver predios.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver campañas.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.35. Jefe / Responsable UOT en Predios

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: capturar GPS.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver mapa.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver titularidad.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.36. Jefe / Responsable UOT en Parcelas y cultivos

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar parcela.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar parcela.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar cultivo.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar cultivo.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: finalizar cultivo.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver expediente.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.37. Jefe / Responsable UOT en Salidas de campo

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: programar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cancelar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: iniciar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: finalizar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: asignar participantes.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver recursos.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.38. Jefe / Responsable UOT en Visitas técnicas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: iniciar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: finalizar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver ubicación.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver evidencias.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.39. Jefe / Responsable UOT en Sanidad vegetal

- Acción funcional disponible en el módulo: listar casos.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar caso.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar caso.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar tratamiento.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar seguimiento.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cambiar estado.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cerrar caso.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver evidencias.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.40. Jefe / Responsable UOT en Producción disponible

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar estimación.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: confirmar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: descartar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar por zona.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar por fecha.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver origen.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.41. Jefe / Responsable UOT en Campañas de venta

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: crear.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: activar.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cerrar.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cancelar.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver comprador.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver participantes.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver operativos.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.42. Jefe / Responsable UOT en Condiciones y precios

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: crear condición.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: crear precio.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: versionar precio.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: deshabilitar valor no utilizado.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.43. Jefe / Responsable UOT en Operativos de venta

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: crear.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: iniciar recepción.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cerrar.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cancelar.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: asignar zonas.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver indicadores.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.44. Jefe / Responsable UOT en Control de jabas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: asignar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar devolución.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver saldo.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular movimiento autorizado.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.45. Jefe / Responsable UOT en Acopio y entregas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar preliminar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: confirmar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver valorización.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar ticket.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.46. Jefe / Responsable UOT en Incidencias operativas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar revisión.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: resolver.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar evidencia.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver peso afectado.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.47. Jefe / Responsable UOT en Gastos

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar registrado.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: aprobar.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar comprobante.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver prorrateo.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.48. Jefe / Responsable UOT en Liquidaciones

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: calcular.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: recalcular versión.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: aprobar.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver saldo.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver pagos.
  - Nivel del rol en este módulo: SUPERVISION_APROBACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.49. Jefe / Responsable UOT en Pagos a socios

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: confirmar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar comprobante.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver saldo posterior.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.50. Jefe / Responsable UOT en Cobros de compradores

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: confirmar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar comprobante.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver saldo campaña.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.51. Jefe / Responsable UOT en Reportes e indicadores

- Acción funcional disponible en el módulo: listar reportes.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: exportar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: navegar a origen.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.52. Jefe / Responsable UOT en Auditoría

- Acción funcional disponible en el módulo: listar eventos.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver antes y después.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: exportar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver dispositivo.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver usuario.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.53. Coordinador técnico en Dashboard

- Acción funcional disponible en el módulo: ver alertas.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver pendientes.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver accesos rápidos.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver indicadores según rol.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.54. Coordinador técnico en Productores / socios

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver predios.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver campañas.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.55. Coordinador técnico en Predios

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: capturar GPS.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver mapa.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver titularidad.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.56. Coordinador técnico en Parcelas y cultivos

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar parcela.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar parcela.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar cultivo.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar cultivo.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: finalizar cultivo.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver expediente.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.57. Coordinador técnico en Censos de plantas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: comparar censos.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.58. Coordinador técnico en Salidas de campo

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: programar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cancelar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: iniciar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: finalizar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: asignar participantes.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver recursos.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.59. Coordinador técnico en Visitas técnicas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: iniciar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: finalizar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver ubicación.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver evidencias.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.60. Coordinador técnico en Evaluaciones agronómicas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar materia seca.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.61. Coordinador técnico en Sanidad vegetal

- Acción funcional disponible en el módulo: listar casos.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar caso.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar caso.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar tratamiento.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar seguimiento.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cambiar estado.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cerrar caso.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver evidencias.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.62. Coordinador técnico en Producción disponible

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar estimación.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: confirmar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: descartar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar por zona.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar por fecha.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver origen.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.63. Coordinador técnico en Documentos y evidencias

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: subir.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: previsualizar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver contexto.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: tomar fotografía.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.64. Coordinador técnico en Reportes e indicadores

- Acción funcional disponible en el módulo: listar reportes.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: exportar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: navegar a origen.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.65. Técnico de campo en Dashboard

- Acción funcional disponible en el módulo: ver alertas.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver pendientes.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver accesos rápidos.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver indicadores según rol.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.66. Técnico de campo en Productores / socios

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver predios.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver campañas.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.67. Técnico de campo en Predios

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: capturar GPS.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver mapa.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver titularidad.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.68. Técnico de campo en Parcelas y cultivos

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar parcela.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar parcela.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar cultivo.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar cultivo.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: finalizar cultivo.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver expediente.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.69. Técnico de campo en Censos de plantas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: comparar censos.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.70. Técnico de campo en Salidas de campo

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: programar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cancelar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: iniciar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: finalizar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: asignar participantes.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver recursos.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.71. Técnico de campo en Visitas técnicas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: iniciar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: finalizar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver ubicación.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver evidencias.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.72. Técnico de campo en Evaluaciones agronómicas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar materia seca.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.73. Técnico de campo en Sanidad vegetal

- Acción funcional disponible en el módulo: listar casos.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar caso.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar caso.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar tratamiento.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar seguimiento.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cambiar estado.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cerrar caso.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver evidencias.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.74. Técnico de campo en Producción disponible

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar estimación.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: confirmar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: descartar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar por zona.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar por fecha.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver origen.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.75. Técnico de campo en Documentos y evidencias

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: subir.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: previsualizar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver contexto.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: tomar fotografía.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.76. Técnico de campo en Reportes e indicadores

- Acción funcional disponible en el módulo: listar reportes.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: exportar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: navegar a origen.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.77. Coordinador comercial en Dashboard

- Acción funcional disponible en el módulo: ver alertas.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver pendientes.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver accesos rápidos.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver indicadores según rol.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.78. Coordinador comercial en Productores / socios

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver predios.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver campañas.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.79. Coordinador comercial en Predios

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: capturar GPS.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver mapa.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver titularidad.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.80. Coordinador comercial en Producción disponible

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar estimación.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: confirmar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: descartar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar por zona.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar por fecha.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver origen.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.81. Coordinador comercial en Campañas de venta

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: crear.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: activar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cerrar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cancelar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver comprador.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver participantes.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver operativos.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.82. Coordinador comercial en Condiciones y precios

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: crear condición.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: crear precio.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: versionar precio.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: deshabilitar valor no utilizado.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.83. Coordinador comercial en Participantes de campaña

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: incluir socio.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar socio.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: excluir socio.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: programar en operativo.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver entregas.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.84. Coordinador comercial en Operativos de venta

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: crear.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: iniciar recepción.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cerrar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cancelar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: asignar zonas.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver indicadores.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.85. Coordinador comercial en Control de jabas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: asignar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar devolución.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver saldo.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular movimiento autorizado.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.86. Coordinador comercial en Acopio y entregas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar preliminar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: confirmar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver valorización.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar ticket.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.87. Coordinador comercial en Incidencias operativas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar revisión.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: resolver.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar evidencia.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver peso afectado.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.88. Coordinador comercial en Ajustes de precio

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver impacto.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar sustento.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.89. Coordinador comercial en Gastos

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar registrado.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: aprobar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar comprobante.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver prorrateo.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.90. Coordinador comercial en Liquidaciones

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: calcular.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: recalcular versión.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: aprobar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver saldo.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver pagos.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.91. Coordinador comercial en Cobros de compradores

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: confirmar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar comprobante.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver saldo campaña.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.92. Coordinador comercial en Documentos y evidencias

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: subir.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: previsualizar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver contexto.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: tomar fotografía.
  - Nivel del rol en este módulo: COORDINACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.93. Coordinador comercial en Reportes e indicadores

- Acción funcional disponible en el módulo: listar reportes.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: exportar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: navegar a origen.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.94. Operador comercial y de acopio en Dashboard

- Acción funcional disponible en el módulo: ver alertas.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver pendientes.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver accesos rápidos.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver indicadores según rol.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.95. Operador comercial y de acopio en Productores / socios

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver predios.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver campañas.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.96. Operador comercial y de acopio en Producción disponible

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar estimación.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: confirmar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: descartar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar por zona.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar por fecha.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver origen.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.97. Operador comercial y de acopio en Campañas de venta

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: crear.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: activar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cerrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cancelar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver comprador.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver participantes.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver operativos.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.98. Operador comercial y de acopio en Participantes de campaña

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: incluir socio.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar socio.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: excluir socio.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: programar en operativo.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver entregas.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.99. Operador comercial y de acopio en Operativos de venta

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: crear.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: iniciar recepción.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cerrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cancelar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: asignar zonas.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver indicadores.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.100. Operador comercial y de acopio en Control de jabas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: asignar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar devolución.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver saldo.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular movimiento autorizado.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.101. Operador comercial y de acopio en Acopio y entregas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar preliminar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: confirmar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver valorización.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar ticket.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.102. Operador comercial y de acopio en Incidencias operativas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar revisión.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: resolver.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar evidencia.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver peso afectado.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.103. Operador comercial y de acopio en Documentos y evidencias

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: subir.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: previsualizar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver contexto.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: tomar fotografía.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.104. Operador comercial y de acopio en Reportes e indicadores

- Acción funcional disponible en el módulo: listar reportes.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: exportar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: navegar a origen.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.105. Responsable de logística en Dashboard

- Acción funcional disponible en el módulo: ver alertas.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver pendientes.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver accesos rápidos.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver indicadores según rol.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.106. Responsable de logística en Salidas de campo

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: programar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cancelar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: iniciar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: finalizar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: asignar participantes.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver recursos.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.107. Responsable de logística en Operativos de venta

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: crear.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: iniciar recepción.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cerrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cancelar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: asignar zonas.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver indicadores.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.108. Responsable de logística en Inventario y vehículos

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar bien.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar bien.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: dar de baja.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar vehículo.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: actualizar kilometraje.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.109. Responsable de logística en Recursos programados

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: programar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cancelar programación.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: asignar bien.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar devolución.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver disponibilidad.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.110. Responsable de logística en Documentos y evidencias

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: subir.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: previsualizar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver contexto.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: tomar fotografía.
  - Nivel del rol en este módulo: OPERACION.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.111. Responsable de logística en Reportes e indicadores

- Acción funcional disponible en el módulo: listar reportes.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: exportar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: navegar a origen.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.112. Responsable de finanzas y tesorería en Dashboard

- Acción funcional disponible en el módulo: ver alertas.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver pendientes.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver accesos rápidos.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver indicadores según rol.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.113. Responsable de finanzas y tesorería en Productores / socios

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver predios.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver campañas.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.114. Responsable de finanzas y tesorería en Campañas de venta

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: crear.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: activar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cerrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cancelar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver comprador.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver participantes.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver operativos.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.115. Responsable de finanzas y tesorería en Operativos de venta

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: crear.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: iniciar recepción.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cerrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cancelar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: asignar zonas.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver indicadores.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.116. Responsable de finanzas y tesorería en Acopio y entregas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar preliminar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: confirmar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver valorización.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar ticket.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.117. Responsable de finanzas y tesorería en Ajustes de precio

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver impacto.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar sustento.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.118. Responsable de finanzas y tesorería en Gastos

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar registrado.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: aprobar.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar comprobante.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver prorrateo.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.119. Responsable de finanzas y tesorería en Liquidaciones

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: calcular.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: recalcular versión.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: aprobar.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver saldo.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver pagos.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.120. Responsable de finanzas y tesorería en Pagos a socios

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: confirmar.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar comprobante.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver saldo posterior.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.121. Responsable de finanzas y tesorería en Cobros de compradores

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: confirmar.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar comprobante.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver saldo campaña.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.122. Responsable de finanzas y tesorería en Documentos y evidencias

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: subir.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: previsualizar.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver contexto.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: tomar fotografía.
  - Nivel del rol en este módulo: OPERACION_FINANCIERA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.123. Responsable de finanzas y tesorería en Reportes e indicadores

- Acción funcional disponible en el módulo: listar reportes.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: exportar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: navegar a origen.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.124. Auditor / Consulta en Dashboard

- Acción funcional disponible en el módulo: ver alertas.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver pendientes.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver accesos rápidos.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver indicadores según rol.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.125. Auditor / Consulta en Productores / socios

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver predios.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver campañas.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.126. Auditor / Consulta en Predios

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: retirar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: capturar GPS.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver mapa.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver titularidad.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.127. Auditor / Consulta en Parcelas y cultivos

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar parcela.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar parcela.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar cultivo.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar cultivo.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: finalizar cultivo.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver expediente.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.128. Auditor / Consulta en Salidas de campo

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: programar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cancelar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: iniciar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: finalizar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: asignar participantes.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver recursos.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.129. Auditor / Consulta en Visitas técnicas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: iniciar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: finalizar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver ubicación.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver evidencias.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.130. Auditor / Consulta en Sanidad vegetal

- Acción funcional disponible en el módulo: listar casos.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar caso.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar caso.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar tratamiento.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar seguimiento.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cambiar estado.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cerrar caso.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver evidencias.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.131. Auditor / Consulta en Producción disponible

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar estimación.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: confirmar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: descartar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar por zona.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar por fecha.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver origen.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.132. Auditor / Consulta en Campañas de venta

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: crear.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: activar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cerrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cancelar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver comprador.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver participantes.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver operativos.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.133. Auditor / Consulta en Condiciones y precios

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: crear condición.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: crear precio.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: versionar precio.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: deshabilitar valor no utilizado.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.134. Auditor / Consulta en Operativos de venta

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: crear.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: iniciar recepción.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cerrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: cancelar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: asignar zonas.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver indicadores.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.135. Auditor / Consulta en Control de jabas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: asignar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar devolución.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver saldo.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver historial.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular movimiento autorizado.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.136. Auditor / Consulta en Acopio y entregas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar preliminar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: confirmar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver valorización.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar ticket.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.137. Auditor / Consulta en Incidencias operativas

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar revisión.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: resolver.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar evidencia.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver peso afectado.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.138. Auditor / Consulta en Gastos

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: editar registrado.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: aprobar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar comprobante.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver prorrateo.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.139. Auditor / Consulta en Liquidaciones

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: calcular.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: recalcular versión.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: aprobar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver saldo.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver pagos.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.140. Auditor / Consulta en Pagos a socios

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: confirmar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar comprobante.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver saldo posterior.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.141. Auditor / Consulta en Cobros de compradores

- Acción funcional disponible en el módulo: listar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: registrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: confirmar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: anular.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: adjuntar comprobante.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver saldo campaña.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.142. Auditor / Consulta en Reportes e indicadores

- Acción funcional disponible en el módulo: listar reportes.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver detalle.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: exportar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: navegar a origen.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.

## D.143. Auditor / Consulta en Auditoría

- Acción funcional disponible en el módulo: listar eventos.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: filtrar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver antes y después.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: exportar.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver dispositivo.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
- Acción funcional disponible en el módulo: ver usuario.
  - Nivel del rol en este módulo: LECTURA.
  - La acción se muestra solo si existe el permiso correspondiente.
  - El sistema valida el estado antes de ejecutarla.
  - El resultado se comunica con un mensaje no técnico.
