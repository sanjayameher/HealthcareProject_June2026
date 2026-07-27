package com.healthcare.cds.dto.request;

public record VitalSignsDto(
        String bp,
        String hr,
        String temp,
        String spo2,
        String weight
) {}
