package com.franco.desco.adapter.in.web.sale;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.*;
import com.franco.desco.application.sale.SaleCommands;
import com.franco.desco.application.sale.port.in.SaleUseCase;
import com.franco.desco.domain.sale.SaleModels;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/ventas")
@Tag(name="Ventas",description="Ventas, separaciones, pagos, entrega y comprobantes de productos DESCO.")
@SecurityRequirement(name="bearerAuth")
@Validated
public class SaleController {
    private final SaleUseCase useCase;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identities;
    private final IdempotencyKeyResolver idempotency;

    public SaleController(SaleUseCase useCase,ApiResponseFactory responses,JwtSessionIdentityResolver identities,IdempotencyKeyResolver idempotency){
        this.useCase=useCase;this.responses=responses;this.identities=identities;this.idempotency=idempotency;
    }

    @GetMapping
    @PreAuthorize("@permissionGuard.hasUot(authentication,'VENTAS_LISTAR')")
    public ResponseEntity<ApiResponse<List<SaleModels.Summary>>> list(@RequestParam(required=false) @Positive Long uotId,@RequestParam(required=false) String estado,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){
        return responses.from(useCase.list(identities.resolve(authentication),uotId,estado),request);
    }

    @GetMapping("/{id}")
    @PreAuthorize("@permissionGuard.hasUot(authentication,'VENTAS_LISTAR')")
    public ResponseEntity<ApiResponse<SaleModels.Detail>> get(@PathVariable @Positive Long id,@Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){
        return responses.from(useCase.get(identities.resolve(authentication),id),request);
    }

    @GetMapping("/metodos-pago")
    @PreAuthorize("@permissionGuard.hasUot(authentication,'VENTAS_LISTAR')")
    public ResponseEntity<ApiResponse<List<SaleModels.PaymentMethod>>> methods(@Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){
        return responses.from(useCase.paymentMethods(identities.resolve(authentication)),request);
    }

    @PostMapping
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'VENTAS_CREAR')")
    public ResponseEntity<ApiResponse<Long>> create(@Valid @RequestBody SaleRequests.Create body,@Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){
        List<SaleCommands.Line> lines=body.detalle().stream().map(x->new SaleCommands.Line(x.productoId(),x.cantidad())).toList();
        var c=new SaleCommands.Create(body.uotId(),body.almacenId(),body.clientePersonaId(),body.clienteEmpresaId(),idempotency.required(request),lines,body.separar(),body.reservaHasta(),body.observacion());
        return responses.from(useCase.create(identities.resolve(authentication),c),request);
    }

    @PostMapping("/{id}/pagos")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,'VENTAS_PAGAR')")
    public ResponseEntity<ApiResponse<Long>> pay(@PathVariable @Positive Long id,@Valid @RequestBody SaleRequests.Pay body,@Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){
        return responses.from(useCase.pay(identities.resolve(authentication),new SaleCommands.Pay(id,body.metodoPagoId(),body.importe(),idempotency.required(request),body.numeroOperacion())),request);
    }

    @PostMapping("/{id}/entregar")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,'VENTAS_ENTREGAR')")
    public ResponseEntity<ApiResponse<Void>> deliver(@PathVariable @Positive Long id,@Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){
        return responses.from(useCase.deliver(identities.resolve(authentication),new SaleCommands.Deliver(id,idempotency.required(request))),request);
    }

    @PostMapping("/{id}/anular")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,'VENTAS_ANULAR')")
    public ResponseEntity<ApiResponse<Void>> cancel(@PathVariable @Positive Long id,@Valid @RequestBody SaleRequests.Cancel body,@Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){
        return responses.from(useCase.cancel(identities.resolve(authentication),new SaleCommands.Cancel(id,body.motivo())),request);
    }

    @PostMapping("/pagos/{id}/anular")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,'VENTAS_PAGAR')")
    public ResponseEntity<ApiResponse<Void>> cancelPayment(@PathVariable @Positive Long id,@Valid @RequestBody SaleRequests.CancelPayment body,@Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){
        return responses.from(useCase.cancelPayment(identities.resolve(authentication),new SaleCommands.CancelPayment(id,body.motivo())),request);
    }

    @PostMapping("/{id}/comprobante")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,'VENTAS_COMPROBANTE')")
    public ResponseEntity<ApiResponse<Long>> receipt(@PathVariable @Positive Long id,@Valid @RequestBody SaleRequests.Receipt body,@Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){
        return responses.from(useCase.issueReceipt(identities.resolve(authentication),new SaleCommands.IssueReceipt(id,body.tipo(),body.serie(),body.numero(),body.documentoCliente(),body.nombreCliente(),idempotency.required(request))),request);
    }
}
