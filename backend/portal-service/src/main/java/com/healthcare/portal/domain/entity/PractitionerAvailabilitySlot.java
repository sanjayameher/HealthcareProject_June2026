package com.healthcare.portal.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "practitioner_availability_slots", schema = "dev")
@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode(of = "id")
public class PractitionerAvailabilitySlot {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "practitioner_id", nullable = false)
    private UUID practitionerId;

    @Column(name = "slot_date", nullable = false)
    private LocalDate slotDate;

    @Column(name = "start_time", nullable = false)
    private LocalTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalTime endTime;

    @Column(name = "is_available", nullable = false)
    private boolean available = true;

    @Column(name = "slot_type", nullable = false, length = 20)
    private String slotType = "regular";

    @Column(name = "recurrence_rule")
    private String recurrenceRule;

    @Column(name = "max_appointments", nullable = false)
    private short maxAppointments = 1;

    @Column(name = "notes")
    private String notes;

    @Column(name = "created_at", updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at")
    private OffsetDateTime updatedAt;

    @PrePersist
    void prePersist() {
        this.createdAt = OffsetDateTime.now();
        this.updatedAt = OffsetDateTime.now();
    }

    @PreUpdate
    void preUpdate() {
        this.updatedAt = OffsetDateTime.now();
    }
}