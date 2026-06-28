package com.healthcare.portal.domain.entity;

import jakarta.persistence.*;
import lombok.*;

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

    /** participant_required enum: required | optional | information_only */
    @Column(name = "required", nullable = false, length = 30)
    private String required = "required";

    /** participant_status enum: accepted | declined | tentative | needs_action */
    @Column(name = "status", nullable = false, length = 30)
    private String status = "accepted";

    @Column(name = "period_start")
    private OffsetDateTime periodStart;

    @Column(name = "period_end")
    private OffsetDateTime periodEnd;
}