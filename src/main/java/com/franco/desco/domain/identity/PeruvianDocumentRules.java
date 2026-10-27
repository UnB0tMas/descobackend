package com.franco.desco.domain.identity;

import com.franco.desco.domain.identity.IdentityModels.DocumentType;
import com.franco.desco.domain.identity.IdentityModels.Target;

public final class PeruvianDocumentRules {

    private PeruvianDocumentRules() {
    }

    public static String normalize(String value) {
        return value == null ? null : value.trim();
    }

    public static boolean validFor(
            Target target,
            DocumentType type,
            String document
    ) {
        String normalized = normalize(document);

        if (target == null || type == null || normalized == null) {
            return false;
        }

        if (type == DocumentType.DNI) {
            return target == Target.PERSONA && isDni(normalized);
        }

        if (!isRuc(normalized)) {
            return false;
        }

        String prefix = normalized.substring(0, 2);

        if (target == Target.EMPRESA) {
            return "20".equals(prefix);
        }

        return "10".equals(prefix)
                || "15".equals(prefix)
                || "17".equals(prefix);
    }

    public static boolean isDni(String document) {
        return document != null
                && document.length() == 8
                && digitsOnly(document);
    }

    public static boolean isRuc(String document) {
        if (document == null
                || document.length() != 11
                || !digitsOnly(document)) {
            return false;
        }

        int sum = digit(document, 0) * 5
                + digit(document, 1) * 4
                + digit(document, 2) * 3
                + digit(document, 3) * 2
                + digit(document, 4) * 7
                + digit(document, 5) * 6
                + digit(document, 6) * 5
                + digit(document, 7) * 4
                + digit(document, 8) * 3
                + digit(document, 9) * 2;

        int check = 11 - (sum % 11);

        if (check == 10) {
            check = 0;
        } else if (check == 11) {
            check = 1;
        }

        return check == digit(document, 10);
    }

    private static int digit(String value, int index) {
        return value.charAt(index) - '0';
    }

    private static boolean digitsOnly(String value) {
        for (int i = 0; i < value.length(); i++) {
            if (!Character.isDigit(value.charAt(i))) {
                return false;
            }
        }
        return true;
    }
}
