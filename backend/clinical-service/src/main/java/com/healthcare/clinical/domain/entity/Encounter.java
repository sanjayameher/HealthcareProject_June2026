package com.healthcare.clinical.domain.entity;

import com.healthcare.clinical.domain.enums.EncounterClass;
import com.healthcare.clinical.domain.enums.EncounterStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.ColumnTransformer;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "encounters", schema = "dev")
@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode(of = "id")
public class Encounter {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "fhir_id", updatable = false)
    private UUID fhirId;

    @Column(name = "patient_id", nullable = false)
    private UUID patientId;

    @ColumnTransformer(write = "?::dev.encounter_status")
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, columnDefinition = "dev.encounter_status")
    private EncounterStatus status = EncounterStatus.planned;

    @ColumnTransformer(write = "?::dev.encounter_class")
    @Enumerated(EnumType.STRING)
    @Column(name = "class", nullable = false, columnDefinition = "dev.encounter_class")
    private EncounterClass encounterClass = EncounterClass.virtual;

    @Column(name = "type_code")
    private String typeCode;

    @Column(name = "type_display")
    private String typeDisplay;

    @Column(name = "service_type_code")
    private String serviceTypeCode;

    @Column(name = "service_type_display")
    private String serviceTypeDisplay;

    @Column(name = "priority_code")
    private String priorityCode = "routine";

    @Column(name = "primary_practitioner_id")
    private UUID primaryPractitionerId;

    @Column(name = "organization_id")
    private UUID organizationId;

    @Column(name = "period_start")
    private OffsetDateTime periodStart;

    @Column(name = "period_end")
    private OffsetDateTime periodEnd;

    @Column(name = "length_minutes", insertable = false, updatable = false)
    private Integer lengthMinutes;

    @Column(name = "appointment_id")
    private UUID appointmentId;

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "reason_codes", columnDefinition = "TEXT[]")
    private String[] reasonCodes = new String[]{};

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "reason_displays", columnDefinition = "TEXT[]")
    private String[] reasonDisplays = new String[]{};

    @Column(name = "telehealth_platform")
    private String telehealthPlatform;

    @Column(name = "telehealth_session_id")
    private String telehealthSessionId;

    @Column(name = "telehealth_session_url")
    private String telehealthSessionUrl;

    @Column(name = "connection_quality")
    private String connectionQuality;

    @Column(name = "hospitalization_admit_source")
    private String hospitalizationAdmitSource;

    @Column(name = "hospitalization_discharge_disposition")
    private String hospitalizationDischargeDisposition;

    @Column(name = "hospitalization_location")
    private String hospitalizationLocation;

    @Column(name = "chief_complaint")
    private String chiefComplaint;

    @Column(name = "assessment_plan")
    private String assessmentPlan;

    @Version
    @Column(name = "version")
    private Integer version = 1;

    @Column(name = "fhir_version_id")
    private String fhirVersionId = "1";

    @Column(name = "fhir_last_updated")
    private OffsetDateTime fhirLastUpdated;

    @Column(name = "created_at", updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at")
    private OffsetDateTime updatedAt;

    @PrePersist
    void prePersist() {
        if (fhirId == null) fhirId = UUID.randomUUID();
        this.fhirLastUpdated = OffsetDateTime.now();
        this.createdAt = OffsetDateTime.now();
        this.updatedAt = OffsetDateTime.now();
    }

    @PreUpdate
    void preUpdate() {
        this.fhirLastUpdated = OffsetDateTime.now();
        this.updatedAt = OffsetDateTime.now();
    }
}
