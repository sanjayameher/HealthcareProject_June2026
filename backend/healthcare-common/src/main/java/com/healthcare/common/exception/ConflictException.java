package com.healthcare.common.exception;

import org.springframework.http.HttpStatus;

public class ConflictException extends BusinessException {

    public ConflictException(String message) {
        super(message, HttpStatus.CONFLICT, "CONFLICT");
    }

    public ConflictException(String resourceType, String field, Object value) {
        super(resourceType + " already exists with " + field + ": " + value,
                HttpStatus.CONFLICT, "DUPLICATE_RESOURCE");
    }
}
