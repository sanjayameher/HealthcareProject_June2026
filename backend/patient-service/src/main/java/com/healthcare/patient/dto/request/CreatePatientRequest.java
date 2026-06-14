package com.healthcare.patient.dto.request;

import com.healthcare.patient.domain.enums.AddressType;
import com.healthcare.patient.domain.enums.AddressUse;
import com.healthcare.patient.domain.enums.ContactSystem;
import com.healthcare.patient.domain.enums.ContactUse;
import com.healthcare.patient.domain.enums.Gender;
import com.healthcare.patient.domain.enums.NameUse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public record CreatePatientRequest(

        UUID managingOrganizationId,

        @NotNull(message = "Gender is required")
        Gender gender,

        @NotNull(message = "Date of birth is required")
        @Past(message = "Date of birth must be in the past")
        LocalDate birthDate,

        String preferredLanguage,

        @NotEmpty(message = "At least one name is required")
        @Valid
        List<NameRequest> names,

        @Valid
        List<AddressRequest> addresses,

        @Valid
        List<TelecomRequest> telecoms
) {

    public record NameRequest(
            NameUse use,

            @NotBlank(message = "Family name is required")
            @Size(max = 100)
            String family,

            @NotEmpty(message = "At least one given name is required")
            List<String> given,

            String prefix,
            String suffix
    ) {}

    public record AddressRequest(
            AddressUse use,
            AddressType type,

            @NotBlank(message = "Address line 1 is required")
            String line1,
            String line2,

            @NotBlank(message = "City is required")
            String city,

            @Pattern(regexp = "[A-Z]{2}", message = "State must be 2-letter code")
            String state,

            @Pattern(regexp = "\\d{5}(-\\d{4})?", message = "Invalid postal code")
            String postalCode,

            String country
    ) {}

    public record TelecomRequest(
            @NotNull
            ContactSystem system,

            @NotBlank
            String value,

            ContactUse use,
            Integer rank
    ) {}
}
