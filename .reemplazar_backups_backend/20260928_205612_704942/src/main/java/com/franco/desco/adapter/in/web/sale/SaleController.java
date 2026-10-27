package com.franco.desco.adapter.in.web.sale;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.*;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.sale.SaleCommands;
import com.franco.desco.application.sale.port.in.SaleUseCase;
import io.swagger.v3.oas.annotations.Operation;
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
@Tag(name = OpenApiConstants.TAG_SALES, description = OpenApiConstants.TAG_SALES_DESCRIPTION)
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
@Validated
public class SaleController {
    private final SaleUseCase useCase;
    private final SaleWebMapper mapper;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identities;
    private final IdempotencyKeyResolver idempotency;

    public SaleController(
            SaleUseCase useCase,
            SaleWebMapper mapper,
            ApiResponseFactory responses,
            JwtSessionIdentityResolver identities,
            IdempotencyKeyResolver idempotency
    ) {
        this.useCase = useCase;
        this.mapper = mapper;
        this.responses = responses;
        this.identities = identities;
        this.idempotency = idempotency;
    }

    @GetMapping
    @PreAuthorize("@permissionGuard.hasUot(authentication,'VENTAS_LISTAR')")
    @Operation(operationId = "ventasListar", summary = "Listar ventas según contexto UOT")
    public ResponseEntity<ApiResponse<List<SaleResponses.Summary>>> list(
            @RequestParam(required = false) @Positive Long uotId,
            @RequestParam(required = false) String estado,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.list(identities.resolve(authentication), uotId, estado),
                request,
                values -> values.stream().map(mapper::response).toList()
        );
    }

    @GetMapping("/{id}")
    @PreAuthorize("@permissionGuard.hasUot(authentication,'VENTAS_LISTAR')")
    @Operation(operationId = "ventasVer", summary = "Ver detalle, pagos y comprobante de una venta")
    public ResponseEntity<ApiResponse<SaleResponses.Detail>> get(
            @PathVariable @Positive Long id,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.get(identities.resolve(authentication), id),
                request,
                mapper::response
        );
    }

    @GetMapping("/metodos-pago")
    @PreAuthorize("@permissionGuard.hasUot(authentication,'VENTAS_LISTAR')")
    @Operation(operationId = "ventasMetodosPagoListar", summary = "Listar métodos de pago activos")
    public ResponseEntity<ApiResponse<List<SaleResponses.PaymentMethod>>> methods(
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.paymentMethods(identities.resolve(authentication)),
                request,
                values -> values.stream().map(mapper::response).toList()
        );
    }

    @PostMapping
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'VENTAS_CREAR')")
    @Operation(operationId = "ventasCrear", summary = "Registrar una venta o separación")
    public ResponseEntity<ApiResponse<SaleResponses.Created>> create(
            @Valid @RequestBody SaleRequests.Create body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        List<SaleCommands.Line> lines = body.detalle().stream()
                .map(value -> new SaleCommands.Line(value.productoId(), value.cantidad()))
                .toList();

        var command = new SaleCommands.Create(
                body.uotId(), body.almacenId(), body.clientePersonaId(), body.clienteEmpresaId(),
                idempotency.required(request), lines, body.separar(), body.reservaHasta(), body.observacion()
        );

        return responses.from(
                useCase.create(identities.resolve(authentication), command),
                request,
                SaleResponses.Created::new
        );
    }

    @PostMapping("/{id}/pagos")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,'VENTAS_PAGAR')")
    @Operation(operationId = "ventasRegistrarPago", summary = "Registrar un pago total o parcial de una venta")
    public ResponseEntity<ApiResponse<SaleResponses.PaymentCreated>> pay(
            @PathVariable @Positive Long id,
            @Valid @RequestBody SaleRequests.Pay body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.pay(
                        identities.resolve(authentication),
                        new SaleCommands.Pay(
                                id, body.metodoPagoId(), body.importe(), idempotency.required(request), body.numeroOperacion()
                        )
                ),
                request,
                SaleResponses.PaymentCreated::new
        );
    }

    @PostMapping("/{id}/entregar")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,'VENTAS_ENTREGAR')")
    @Operation(operationId = "ventasEntregar", summary = "Entregar una venta totalmente pagada y descontar stock")
    public ResponseEntity<ApiResponse<Void>> deliver(
            @PathVariable @Positive Long id,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.deliver(
                        identities.resolve(authentication),
                        new SaleCommands.Deliver(id, idempotency.required(request))
                ),
                request
        );
    }

    @PostMapping("/{id}/anular")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,'VENTAS_ANULAR')")
    @Operation(operationId = "ventasAnular", summary = "Anular una venta sin pagos activos")
    public ResponseEntity<ApiResponse<Void>> cancel(
            @PathVariable @Positive Long id,
            @Valid @RequestBody SaleRequests.Cancel body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.cancel(
                        identities.resolve(authentication),
                        new SaleCommands.Cancel(id, body.motivo())
                ),
                request
        );
    }

    @PostMapping("/pagos/{id}/anular")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,'VENTAS_PAGAR')")
    @Operation(operationId = "ventasPagoAnular", summary = "Anular un pago registrado")
    public ResponseEntity<ApiResponse<Void>> cancelPayment(
            @PathVariable @Positive Long id,
            @Valid @RequestBody SaleRequests.CancelPayment body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.cancelPayment(
                        identities.resolve(authentication),
                        new SaleCommands.CancelPayment(id, body.motivo())
                ),
                request
        );
    }

    @PostMapping("/{id}/comprobante")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,'VENTAS_COMPROBANTE')")
    @Operation(operationId = "ventasComprobanteEmitir", summary = "Emitir boleta o factura para una venta")
    public ResponseEntity<ApiResponse<SaleResponses.ReceiptCreated>> receipt(
            @PathVariable @Positive Long id,
            @Valid @RequestBody SaleRequests.Receipt body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.issueReceipt(
                        identities.resolve(authentication),
                        new SaleCommands.IssueReceipt(
                                id, body.tipo(), body.serie(), body.numero(), body.documentoCliente(),
                                body.nombreCliente(), idempotency.required(request)
                        )
                ),
                request,
                SaleResponses.ReceiptCreated::new
        );
    }
}
