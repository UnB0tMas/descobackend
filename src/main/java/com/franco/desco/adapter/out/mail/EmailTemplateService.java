package com.franco.desco.adapter.out.mail;

import com.franco.desco.infrastructure.config.MailProperties;
import org.springframework.stereotype.Component;
import org.thymeleaf.context.Context;
import org.thymeleaf.spring6.SpringTemplateEngine;

import java.time.Year;
import java.time.ZoneId;
import java.util.Locale;

@Component
public class EmailTemplateService {

    private static final String TEMPLATE =
            "email/security/security-message";

    private static final Locale PERU_LOCALE =
            Locale.forLanguageTag("es-PE");

    private static final ZoneId PERU_ZONE =
            ZoneId.of("America/Lima");

    private final SpringTemplateEngine templateEngine;
    private final MailProperties properties;

    public EmailTemplateService(
            SpringTemplateEngine templateEngine,
            MailProperties properties
    ) {
        this.templateEngine = templateEngine;
        this.properties = properties;
    }

    public RenderedEmail render(
            SecurityEmailModel model
    ) {
        Context context =
                new Context(PERU_LOCALE);

        context.setVariable(
                "preheader",
                model.preheader()
        );
        context.setVariable(
                "category",
                model.category()
        );
        context.setVariable(
                "title",
                model.title()
        );
        context.setVariable(
                "recipientName",
                model.recipientName()
        );
        context.setVariable(
                "intro",
                model.intro()
        );
        context.setVariable(
                "detail",
                model.detail()
        );
        context.setVariable(
                "codeLabel",
                model.codeLabel()
        );
        context.setVariable(
                "code",
                model.code()
        );
        context.setVariable(
                "actionLabel",
                model.actionLabel()
        );
        context.setVariable(
                "actionUrl",
                model.actionUrl()
        );
        context.setVariable(
                "warningTitle",
                model.warningTitle()
        );
        context.setVariable(
                "warningText",
                model.warningText()
        );
        context.setVariable(
                "closingText",
                model.closingText()
        );

        context.setVariable(
                "companyName",
                properties.companyName()
        );
        context.setVariable(
                "unitName",
                properties.unitName()
        );
        context.setVariable(
                "supportEmail",
                properties.supportEmail()
        );
        context.setVariable(
                "currentYear",
                Year.now(PERU_ZONE).getValue()
        );

        return new RenderedEmail(
                model.subject(),
                plainText(model),
                templateEngine.process(
                        TEMPLATE,
                        context
                )
        );
    }

    private String plainText(
            SecurityEmailModel model
    ) {
        StringBuilder text =
                new StringBuilder();

        append(
                text,
                properties.companyName()
        );
        append(
                text,
                properties.unitName()
        );
        text.append(
                System.lineSeparator()
        );
        append(text, model.title());

        if (hasText(
                model.recipientName()
        )) {
            append(
                    text,
                    "Hola, "
                            + model.recipientName()
                            + "."
            );
        }

        append(text, model.intro());
        append(text, model.detail());

        if (hasText(model.code())) {
            text.append(
                    System.lineSeparator()
            );
            append(
                    text,
                    safe(model.codeLabel())
                            + ": "
                            + model.code()
            );
        }

        if (hasText(
                model.actionUrl()
        )) {
            text.append(
                    System.lineSeparator()
            );
            append(
                    text,
                    model.actionLabel()
            );
            append(
                    text,
                    model.actionUrl()
            );
        }

        append(
                text,
                model.warningTitle()
        );
        append(
                text,
                model.warningText()
        );
        append(
                text,
                model.closingText()
        );

        return text.toString().trim();
    }

    private void append(
            StringBuilder builder,
            String value
    ) {
        if (hasText(value)) {
            builder.append(
                            value.trim()
                    )
                    .append(
                            System.lineSeparator()
                    );
        }
    }

    private boolean hasText(
            String value
    ) {
        return value != null
                && !value.isBlank();
    }

    private String safe(String value) {
        return value == null ? "Código" : value;
    }

    public record RenderedEmail(
            String subject,
            String plainText,
            String html
    ) {
    }
}
