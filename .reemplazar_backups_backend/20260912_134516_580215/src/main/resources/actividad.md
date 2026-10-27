# DESCO Backend — cierre definitivo de beans duplicados de autenticación

## Error actual

Spring ya superó las ambigüedades anteriores de `DeviceFingerprintPort`, `OtpPort` y `RefreshTokenPort`.

El fallo actual es:

```text
AccessTokenPort:
jwtAccessTokenAdapter
jwtTokenAdapter
```

El bean canónico es `jwtAccessTokenAdapter`.
`JwtTokenAdapter` es la implementación legacy que debe salir del código fuente.

## Criterio validado contra DESCO_DB

No se modifica la base de datos.

`seg.PA_Sesion_Sel_Validar` valida la sesión usando `usuarioId`, `sesionPublicaId`, `tokenVersion` y `jtiHashHex`.
El backend obtiene esos valores desde el JWT (`sub`, `sid`, `tv`, `jti`) y calcula SHA-256 del `jti` antes de consultar el PA.

`seg.PA_Usuario_Sel_ContextoAcceso` devuelve `tokenVersion`, `sesionPublicaId` y los roles efectivos.
Por tanto la implementación que permanece debe ser la implementación específica del puerto de access token: `JwtAccessTokenAdapter`.

La autorización por permisos continúa consultándose contra SQL Server; este parche no mueve reglas de negocio a Java.

## Limpieza integral de adapters legacy ya detectados

Eliminar: `src/main/java/com/franco/desco/adapter/out/security/JwtTokenAdapter.java`

Eliminar: `src/main/java/com/franco/desco/adapter/out/security/DeviceFingerprintHmacAdapter.java`

Eliminar: `src/main/java/com/franco/desco/adapter/out/security/OpaqueRefreshTokenAdapter.java`

Eliminar: `src/main/java/com/franco/desco/adapter/out/security/HmacOtpAdapter.java`

Eliminar: `src/main/java/com/franco/desco/adapter/out/security/Argon2PasswordAdapter.java`

Eliminar: `src/main/java/com/franco/desco/adapter/out/security/Sha256RequestHashAdapter.java`

Eliminar: `src/main/java/com/franco/desco/adapter/out/sqlserver/security/AuthorizationSqlServerAdapter.java`

Eliminar: `src/main/java/com/franco/desco/adapter/out/sqlserver/security/SessionValidationSqlServerAdapter.java`

Eliminar: `src/main/java/com/franco/desco/adapter/out/sqlserver/security/SecurityNotificationSqlServerAdapter.java`

Eliminar: `../../../../../actividad.md`

Las eliminaciones son idempotentes. Si alguno ya fue eliminado, `reemplazar.py` mostrará `NO EXISTE` y continuará.

---

## `ApplicationBeanConfig.java`

Ruta: `src/main/java/com/franco/desco/infrastructure/config/ApplicationBeanConfig.java`

```java
package com.franco.desco.infrastructure.config;

import com.franco.desco.application.access.port.in.RoleUseCase;
import com.franco.desco.application.access.port.out.RolePersistencePort;
import com.franco.desco.application.access.service.RoleApplicationService;
import com.franco.desco.application.account.port.in.AccountUseCase;
import com.franco.desco.application.account.port.out.AccountPersistencePort;
import com.franco.desco.application.account.service.AccountApplicationService;
import com.franco.desco.application.auth.port.in.AuthUseCase;
import com.franco.desco.application.auth.port.out.*;
import com.franco.desco.application.auth.service.AuthApplicationService;
import com.franco.desco.application.campaign.port.in.CampaignUseCase;
import com.franco.desco.application.campaign.port.out.CampaignPersistencePort;
import com.franco.desco.application.campaign.service.CampaignApplicationService;
import com.franco.desco.application.campaignparticipant.port.in.CampaignParticipantUseCase;
import com.franco.desco.application.campaignparticipant.port.out.CampaignParticipantPersistencePort;
import com.franco.desco.application.campaignparticipant.service.CampaignParticipantApplicationService;
import com.franco.desco.application.catalog.port.in.CatalogUseCase;
import com.franco.desco.application.catalog.port.out.CatalogPersistencePort;
import com.franco.desco.application.catalog.service.CatalogApplicationService;
import com.franco.desco.application.census.port.in.CensusUseCase;
import com.franco.desco.application.census.port.out.CensusPersistencePort;
import com.franco.desco.application.census.service.CensusApplicationService;
import com.franco.desco.application.crates.port.in.CrateUseCase;
import com.franco.desco.application.crates.port.out.CratePersistencePort;
import com.franco.desco.application.crates.service.CrateApplicationService;
import com.franco.desco.application.cultivation.port.in.CultivationUseCase;
import com.franco.desco.application.cultivation.port.out.CultivationPersistencePort;
import com.franco.desco.application.cultivation.service.CultivationApplicationService;
import com.franco.desco.application.delivery.port.in.DeliveryUseCase;
import com.franco.desco.application.delivery.port.out.DeliveryPersistencePort;
import com.franco.desco.application.delivery.service.DeliveryApplicationService;
import com.franco.desco.application.document.port.in.DocumentUseCase;
import com.franco.desco.application.document.port.out.DocumentPersistencePort;
import com.franco.desco.application.document.service.DocumentApplicationService;
import com.franco.desco.application.employee.port.in.EmployeeUseCase;
import com.franco.desco.application.employee.port.out.EmployeePersistencePort;
import com.franco.desco.application.employee.service.EmployeeApplicationService;
import com.franco.desco.application.evaluation.port.in.EvaluationUseCase;
import com.franco.desco.application.evaluation.port.out.EvaluationPersistencePort;
import com.franco.desco.application.evaluation.service.EvaluationApplicationService;
import com.franco.desco.application.fieldtrip.port.in.FieldTripUseCase;
import com.franco.desco.application.fieldtrip.port.out.FieldTripPersistencePort;
import com.franco.desco.application.fieldtrip.service.FieldTripApplicationService;
import com.franco.desco.application.inventory.port.in.InventoryUseCase;
import com.franco.desco.application.inventory.port.out.InventoryPersistencePort;
import com.franco.desco.application.inventory.service.InventoryApplicationService;
import com.franco.desco.application.organization.port.in.OrganizationUseCase;
import com.franco.desco.application.organization.port.out.OrganizationPersistencePort;
import com.franco.desco.application.organization.service.OrganizationApplicationService;
import com.franco.desco.application.pricing.port.in.PricingUseCase;
import com.franco.desco.application.pricing.port.out.PricingPersistencePort;
import com.franco.desco.application.pricing.service.PricingApplicationService;
import com.franco.desco.application.producer.port.in.ProducerUseCase;
import com.franco.desco.application.producer.port.out.ProducerPersistencePort;
import com.franco.desco.application.producer.service.ProducerApplicationService;
import com.franco.desco.application.production.port.in.ProductionUseCase;
import com.franco.desco.application.production.port.out.ProductionPersistencePort;
import com.franco.desco.application.production.service.ProductionApplicationService;
import com.franco.desco.application.property.port.in.PropertyUseCase;
import com.franco.desco.application.property.port.out.PropertyPersistencePort;
import com.franco.desco.application.property.service.PropertyApplicationService;
import com.franco.desco.application.resourceprogram.port.in.ResourceProgramUseCase;
import com.franco.desco.application.resourceprogram.port.out.ResourceProgramPersistencePort;
import com.franco.desco.application.resourceprogram.service.ResourceProgramApplicationService;
import com.franco.desco.application.salesoperation.port.in.SalesOperationUseCase;
import com.franco.desco.application.salesoperation.port.out.SalesOperationPersistencePort;
import com.franco.desco.application.salesoperation.service.SalesOperationApplicationService;
import com.franco.desco.application.sanitation.port.in.SanitationUseCase;
import com.franco.desco.application.sanitation.port.out.SanitationPersistencePort;
import com.franco.desco.application.sanitation.service.SanitationApplicationService;
import com.franco.desco.application.useradmin.port.in.UserAdminUseCase;
import com.franco.desco.application.useradmin.port.out.UserAdminPersistencePort;
import com.franco.desco.application.useradmin.service.UserAdminApplicationService;
import com.franco.desco.application.visit.port.in.VisitUseCase;
import com.franco.desco.application.visit.port.out.VisitPersistencePort;
import com.franco.desco.application.visit.service.VisitApplicationService;
import com.franco.desco.application.incident.port.in.IncidentUseCase;
import com.franco.desco.application.incident.port.out.IncidentPersistencePort;
import com.franco.desco.application.incident.service.IncidentApplicationService;
import com.franco.desco.application.priceadjustment.port.in.PriceAdjustmentUseCase;
import com.franco.desco.application.priceadjustment.port.out.PriceAdjustmentPersistencePort;
import com.franco.desco.application.priceadjustment.service.PriceAdjustmentApplicationService;
import com.franco.desco.application.expense.port.in.ExpenseUseCase;
import com.franco.desco.application.expense.port.out.ExpensePersistencePort;
import com.franco.desco.application.expense.service.ExpenseApplicationService;
import com.franco.desco.application.liquidation.port.in.LiquidationUseCase;
import com.franco.desco.application.liquidation.port.out.LiquidationPersistencePort;
import com.franco.desco.application.liquidation.service.LiquidationApplicationService;
import com.franco.desco.application.payment.port.in.PaymentUseCase;
import com.franco.desco.application.payment.port.out.PaymentPersistencePort;
import com.franco.desco.application.payment.service.PaymentApplicationService;
import com.franco.desco.application.buyercollection.port.in.BuyerCollectionUseCase;
import com.franco.desco.application.buyercollection.port.out.BuyerCollectionPersistencePort;
import com.franco.desco.application.buyercollection.service.BuyerCollectionApplicationService;
import com.franco.desco.application.report.port.in.ReportUseCase;
import com.franco.desco.application.report.port.out.ReportPersistencePort;
import com.franco.desco.application.report.service.ReportApplicationService;
import com.franco.desco.application.audit.port.in.AuditUseCase;
import com.franco.desco.application.audit.port.out.AuditPersistencePort;
import com.franco.desco.application.audit.service.AuditApplicationService;
import com.franco.desco.application.dashboard.port.in.DashboardUseCase;
import com.franco.desco.application.dashboard.port.out.DashboardPersistencePort;
import com.franco.desco.application.dashboard.service.DashboardApplicationService;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ApplicationBeanConfig {

    @Bean
    AuthUseCase authUseCase(
            AuthPersistencePort authPersistencePort,
            PasswordHashPort passwordHashPort,
            @Qualifier("deviceFingerprintAdapter")
            DeviceFingerprintPort deviceFingerprintPort,
            @Qualifier("otpAdapter")
            OtpPort otpPort,
            @Qualifier("refreshTokenAdapter")
            RefreshTokenPort refreshTokenPort,
            SecurityMailPort securityMailPort,
            SecurityNotificationPort notificationPort,
            @Qualifier("jwtAccessTokenAdapter")
            AccessTokenPort accessTokenPort
    ) {
        return new AuthApplicationService(
                authPersistencePort,
                passwordHashPort,
                deviceFingerprintPort,
                otpPort,
                refreshTokenPort,
                securityMailPort,
                notificationPort,
                accessTokenPort
        );
    }

    @Bean
    OrganizationUseCase organizationUseCase(OrganizationPersistencePort persistence) {
        return new OrganizationApplicationService(persistence);
    }

    @Bean
    RoleUseCase roleUseCase(RolePersistencePort persistence) {
        return new RoleApplicationService(persistence);
    }

    @Bean
    CatalogUseCase catalogUseCase(CatalogPersistencePort persistence) {
        return new CatalogApplicationService(persistence);
    }

    @Bean
    EmployeeUseCase employeeUseCase(EmployeePersistencePort persistence) {
        return new EmployeeApplicationService(persistence);
    }

    @Bean
    UserAdminUseCase userAdminUseCase(
            UserAdminPersistencePort persistence,
            PasswordHashPort passwordHashPort
    ) {
        return new UserAdminApplicationService(persistence, passwordHashPort);
    }

    @Bean
    AccountUseCase accountUseCase(
            AccountPersistencePort persistence,
            PasswordHashPort passwordHashPort,
            @Qualifier("otpAdapter")
            OtpPort otpPort,
            SecurityMailPort securityMailPort,
            SecurityNotificationPort securityNotificationPort
    ) {
        return new AccountApplicationService(
                persistence,
                passwordHashPort,
                otpPort,
                securityMailPort,
                securityNotificationPort
        );
    }

    @Bean
    DocumentUseCase documentUseCase(DocumentPersistencePort persistence) {
        return new DocumentApplicationService(persistence);
    }

    @Bean
    ProducerUseCase producerUseCase(ProducerPersistencePort persistence) {
        return new ProducerApplicationService(persistence);
    }

    @Bean
    PropertyUseCase propertyUseCase(PropertyPersistencePort persistence) {
        return new PropertyApplicationService(persistence);
    }

    @Bean
    CultivationUseCase cultivationUseCase(CultivationPersistencePort persistence) {
        return new CultivationApplicationService(persistence);
    }

    @Bean
    CensusUseCase censusUseCase(CensusPersistencePort persistence) {
        return new CensusApplicationService(persistence);
    }

    @Bean
    InventoryUseCase inventoryUseCase(InventoryPersistencePort persistence) {
        return new InventoryApplicationService(persistence);
    }

    @Bean
    FieldTripUseCase fieldTripUseCase(FieldTripPersistencePort persistence) {
        return new FieldTripApplicationService(persistence);
    }

    @Bean
    ResourceProgramUseCase resourceProgramUseCase(ResourceProgramPersistencePort persistence) {
        return new ResourceProgramApplicationService(persistence);
    }

    @Bean
    VisitUseCase visitUseCase(VisitPersistencePort persistence) {
        return new VisitApplicationService(persistence);
    }

    @Bean
    EvaluationUseCase evaluationUseCase(EvaluationPersistencePort persistence) {
        return new EvaluationApplicationService(persistence);
    }

    @Bean
    SanitationUseCase sanitationUseCase(SanitationPersistencePort persistence) {
        return new SanitationApplicationService(persistence);
    }

    @Bean
    ProductionUseCase productionUseCase(ProductionPersistencePort persistence) {
        return new ProductionApplicationService(persistence);
    }

    @Bean
    CampaignUseCase campaignUseCase(CampaignPersistencePort persistence) {
        return new CampaignApplicationService(persistence);
    }

    @Bean
    PricingUseCase pricingUseCase(PricingPersistencePort persistence) {
        return new PricingApplicationService(persistence);
    }

    @Bean
    CampaignParticipantUseCase campaignParticipantUseCase(
            CampaignParticipantPersistencePort persistence
    ) {
        return new CampaignParticipantApplicationService(persistence);
    }

    @Bean
    SalesOperationUseCase salesOperationUseCase(SalesOperationPersistencePort persistence) {
        return new SalesOperationApplicationService(persistence);
    }

    @Bean
    CrateUseCase crateUseCase(CratePersistencePort persistence) {
        return new CrateApplicationService(persistence);
    }

    @Bean
    DeliveryUseCase deliveryUseCase(DeliveryPersistencePort persistence) {
        return new DeliveryApplicationService(persistence);
    }


    @Bean
    IncidentUseCase incidentUseCase(IncidentPersistencePort persistence) {
        return new IncidentApplicationService(persistence);
    }

    @Bean
    PriceAdjustmentUseCase priceAdjustmentUseCase(PriceAdjustmentPersistencePort persistence) {
        return new PriceAdjustmentApplicationService(persistence);
    }

    @Bean
    ExpenseUseCase expenseUseCase(ExpensePersistencePort persistence) {
        return new ExpenseApplicationService(persistence);
    }

    @Bean
    LiquidationUseCase liquidationUseCase(LiquidationPersistencePort persistence) {
        return new LiquidationApplicationService(persistence);
    }

    @Bean
    PaymentUseCase paymentUseCase(PaymentPersistencePort persistence) {
        return new PaymentApplicationService(persistence);
    }

    @Bean
    BuyerCollectionUseCase buyerCollectionUseCase(BuyerCollectionPersistencePort persistence) {
        return new BuyerCollectionApplicationService(persistence);
    }

    @Bean
    ReportUseCase reportUseCase(ReportPersistencePort persistence) {
        return new ReportApplicationService(persistence);
    }

    @Bean
    AuditUseCase auditUseCase(AuditPersistencePort persistence) {
        return new AuditApplicationService(persistence);
    }

    @Bean
    DashboardUseCase dashboardUseCase(DashboardPersistencePort persistence) {
        return new DashboardApplicationService(persistence);
    }
}
```

---

## Aplicación

Guardar este archivo como:

```text
D:\FrancoSystem\desco\actividad.md
```

Ejecutar con IntelliJ/Spring Boot detenido:

```powershell
cd D:\FrancoSystem\desco
python .\reemplazar.py
mvn clean compile
```

No iniciar la aplicación antes de terminar `mvn clean compile`.

## Verificación del source

```powershell
Get-ChildItem .\src\main\java\com\franco\desco\adapter\out -Recurse -Filter *.java |
    Select-String -Pattern 'class JwtTokenAdapter|class OpaqueRefreshTokenAdapter|class DeviceFingerprintHmacAdapter|class HmacOtpAdapter|class Argon2PasswordAdapter'
```

Debe quedar sin resultados.

Comprobar la implementación canónica:

```powershell
Get-ChildItem .\src\main\java\com\franco\desco\adapter\out -Recurse -Filter JwtAccessTokenAdapter.java
```

Debe existir exactamente un `JwtAccessTokenAdapter.java`.

## Verificación de clases compiladas

```powershell
Get-ChildItem .\target\classes\com\franco\desco\adapter\out -Recurse -Filter *.class |
    Where-Object {
        $_.Name -match 'JwtTokenAdapter|OpaqueRefreshTokenAdapter|DeviceFingerprintHmacAdapter|HmacOtpAdapter|Argon2PasswordAdapter'
    } |
    Select-Object -ExpandProperty FullName
```

Debe quedar sin resultados.

Luego:

```powershell
mvn test
```

y volver a ejecutar `DescoApplication`.

## Resultado esperado

`authUseCase` queda fijado explícitamente a:

```text
deviceFingerprintAdapter
otpAdapter
refreshTokenAdapter
jwtAccessTokenAdapter
```

y desaparece la ambigüedad de `AccessTokenPort`.
