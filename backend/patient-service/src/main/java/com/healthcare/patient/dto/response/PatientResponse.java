package com.healthcare.patient.dto.response;

import com.healthcare.patient.domain.enums.*;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public record PatientResponse(
        UUID id,
        String mrn,
        Gender gender,
        LocalDate birthDate,
        boolean active,
        UUID managingOrganizationId,
        String managingOrganizationName,
        List<NameResponse> names,
        List<AddressResponse> addresses,
        List<TelecomResponse> telecoms,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt,
        Integer version
) {

    public record NameResponse(
            UUID id,
            NameUse use,
            String family,
            String[] given,
            String[] prefix,
            String[] suffix,
            String text
    ) {}

    public record AddressResponse(
            UUID id,
            AddressUse use,
            AddressType type,
            String line1,
            String line2,
            String city,
            String state,
            String postalCode,
            String country
    ) {}

    public record TelecomResponse(
            UUID id,
            ContactSystem system,
            String value,
            ContactUse use,
            Integer rank
    ) {}
}
