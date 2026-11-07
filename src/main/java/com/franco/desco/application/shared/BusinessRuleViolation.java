package com.franco.desco.application.shared;

/** An expected rejection that must roll back all changes in the operation. */
public class BusinessRuleViolation extends RuntimeException {
    public BusinessRuleViolation(String message) {
        super(message);
    }
}
