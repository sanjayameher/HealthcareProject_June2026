package com.healthcare.portal.repository;

import com.healthcare.portal.domain.entity.PractitionerAvailabilitySlot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface PractitionerAvailabilitySlotRepository extends JpaRepository<PractitionerAvailabilitySlot, UUID> {

    List<PractitionerAvailabilitySlot> findByPractitionerIdAndSlotDateBetweenOrderBySlotDateAscStartTimeAsc(
            UUID practitionerId, LocalDate from, LocalDate to);

    List<PractitionerAvailabilitySlot> findByPractitionerIdAndSlotDateOrderByStartTimeAsc(
            UUID practitionerId, LocalDate slotDate);

    /** Available slots for a given doctor on a specific date that have no booked appointment. */
    @Query("""
        SELECT s FROM PractitionerAvailabilitySlot s
        WHERE s.practitionerId = :practitionerId
          AND s.slotDate = :slotDate
          AND s.available = true
          AND s.id NOT IN (
              SELECT a.slotId FROM Appointment a
              WHERE a.slotId IS NOT NULL
                AND a.status NOT IN ('cancelled', 'noshow')
          )
        ORDER BY s.startTime
        """)
    List<PractitionerAvailabilitySlot> findAvailableSlots(UUID practitionerId, LocalDate slotDate);

    /** Check whether a slot is occupied by a booked appointment. */
    @Query("""
        SELECT COUNT(a) > 0 FROM Appointment a
        WHERE a.slotId = :slotId
          AND a.status NOT IN ('cancelled', 'noshow')
        """)
    boolean isSlotBooked(UUID slotId);
}