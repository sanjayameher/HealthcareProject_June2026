package com.healthcare.portal.domain.entity;

import com.healthcare.portal.domain.enums.ParticipantRequired;
import com.healthcare.portal.domain.enums.ParticipantStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcType;
import org.hibernate.dialect.PostgreSQLEnumJdbcType;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "appointment_participants", schema = "dev")
@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode(of = "id")
public class AppointmentParticipant {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "appointment_id", nullable = false)
    private UUID appointmentId;

    @Column(name = "type_code", nullable = false)
    private String typeCode;

    @Column(name = "type_display")
    private String typeDisplay;

    @Column(name = "actor_practitioner_id")
    private UUID actorPractitionerId;

    @Column(name = "actor_patient_id")
    private UUID actorPatientId;

    @Column(name = "actor_org_id")
    private UUID actorOrgId;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(name = "required", nullable = false, columnDefinition = "participant_required")
    private ParticipantRequired required = ParticipantRequired.required;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(name = "status", nullable = false, columnDefinition = "participant_status")
    private ParticipantStatus status = ParticipantStatus.accepted;

    @Column(name = "period_start")
    private OffsetDateTime periodStart;

    @Column(name = "period_end")
    private OffsetDateTime periodEnd;
}