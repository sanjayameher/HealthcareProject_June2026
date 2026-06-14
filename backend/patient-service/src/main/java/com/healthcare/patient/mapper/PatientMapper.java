package com.healthcare.patient.mapper;

import com.healthcare.patient.domain.entity.*;
import com.healthcare.patient.dto.request.CreatePatientRequest;
import com.healthcare.patient.dto.request.CreateOrganizationRequest;
import com.healthcare.patient.dto.request.CreatePractitionerRequest;
import com.healthcare.patient.dto.response.OrganizationResponse;
import com.healthcare.patient.dto.response.PatientResponse;
import com.healthcare.patient.dto.response.PractitionerResponse;
import org.mapstruct.*;

import java.util.List;

@Mapper(
        componentModel = "spring",
        nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE,
        unmappedTargetPolicy = ReportingPolicy.IGNORE
)
public interface PatientMapper {

    // ── Patient ──────────────────────────────────────────────────────────────

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "mrn", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(target = "version", ignore = true)
    @Mapping(target = "managingOrganization", ignore = true)
    @Mapping(target = "names", ignore = true)
    @Mapping(target = "addresses", ignore = true)
    @Mapping(target = "telecoms", ignore = true)
    @Mapping(target = "contacts", ignore = true)
    @Mapping(target = "identifiers", ignore = true)
    @Mapping(target = "flags", ignore = true)
    @Mapping(target = "multipleBirthOrder", ignore = true)
    Patient toEntity(CreatePatientRequest request);

    @Mapping(target = "managingOrganizationId",
             source = "managingOrganization.id")
    @Mapping(target = "managingOrganizationName",
             source = "managingOrganization.name")
    PatientResponse toResponse(Patient patient);

    List<PatientResponse.NameResponse> toNameResponses(List<PatientName> names);
    PatientResponse.NameResponse toNameResponse(PatientName name);

    List<PatientResponse.AddressResponse> toAddressResponses(List<PatientAddress> addresses);
    PatientResponse.AddressResponse toAddressResponse(PatientAddress address);

    List<PatientResponse.TelecomResponse> toTelecomResponses(List<PatientTelecom> telecoms);
    PatientResponse.TelecomResponse toTelecomResponse(PatientTelecom telecom);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "patient", ignore = true)
    @Mapping(target = "prefix",
             expression = "java(request.prefix() != null ? new String[]{request.prefix()} : null)")
    @Mapping(target = "suffix",
             expression = "java(request.suffix() != null ? new String[]{request.suffix()} : null)")
    @Mapping(target = "given",
             expression = "java(request.given() != null ? request.given().toArray(new String[0]) : null)")
    PatientName toNameEntity(CreatePatientRequest.NameRequest request);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "patient", ignore = true)
    PatientAddress toAddressEntity(CreatePatientRequest.AddressRequest request);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "patient", ignore = true)
    @Mapping(target = "valueHmac", ignore = true)
    PatientTelecom toTelecomEntity(CreatePatientRequest.TelecomRequest request);

    // ── Organization ─────────────────────────────────────────────────────────

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "parent", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(target = "deletedAt", ignore = true)
    Organization toOrganizationEntity(CreateOrganizationRequest request);

    @Mapping(target = "parentId", source = "parent.id")
    OrganizationResponse toOrganizationResponse(Organization org);

    // ── Practitioner ─────────────────────────────────────────────────────────

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "organization", ignore = true)
    @Mapping(target = "roles", ignore = true)
    @Mapping(target = "fullNameDisplay", ignore = true)
    @Mapping(target = "specialtyCodes", ignore = true)
    @Mapping(target = "specialtyDisplays", ignore = true)
    @Mapping(target = "qualificationCodes", ignore = true)
    @Mapping(target = "languages", ignore = true)
    @Mapping(target = "stateLicense", ignore = true)
    @Mapping(target = "stateLicenseState", ignore = true)
    @Mapping(target = "telehealthPlatform", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(target = "deletedAt", ignore = true)
    Practitioner toPractitionerEntity(CreatePractitionerRequest request);

    PractitionerResponse toPractitionerResponse(Practitioner practitioner);
}
