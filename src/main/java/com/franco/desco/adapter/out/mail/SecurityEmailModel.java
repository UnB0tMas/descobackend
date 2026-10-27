package com.franco.desco.adapter.out.mail;

public record SecurityEmailModel(
        String subject,
        String preheader,
        String category,
        String title,
        String recipientName,
        String intro,
        String detail,
        String codeLabel,
        String code,
        String actionLabel,
        String actionUrl,
        String warningTitle,
        String warningText,
        String closingText
) {
}
