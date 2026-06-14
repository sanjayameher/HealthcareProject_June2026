package com.healthcare.common.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.time.Instant;
import java.util.List;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiResponse<T>(
        boolean success,
        String message,
        T data,
        List<ValidationError> errors,
        Instant timestamp,
        String requestId
) {
    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(true, null, data, null, Instant.now(), null);
    }

    public static <T> ApiResponse<T> ok(T data, String message) {
        return new ApiResponse<>(true, message, data, null, Instant.now(), null);
    }

    public static <T> ApiResponse<T> created(T data) {
        return ok(data, "Resource created successfully");
    }

    public static <T> ApiResponse<T> error(String message) {
        return new ApiResponse<>(false, message, null, null, Instant.now(), null);
    }

    public static <T> ApiResponse<T> validationError(String message, List<ValidationError> errors) {
        return new ApiResponse<>(false, message, null, errors, Instant.now(), null);
    }

    public record ValidationError(String field, String message) {}
}
