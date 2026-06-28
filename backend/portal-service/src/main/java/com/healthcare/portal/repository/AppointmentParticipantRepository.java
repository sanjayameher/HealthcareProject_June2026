package com.healthcare.portal.repository;

import com.healthcare.portal.domain.entity.AppointmentParticipant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AppointmentParticipantRepository extends JpaRepository<AppointmentParticipant, UUID> {

    List<AppointmentParticipant> findByAppointmentId(UUID appointmentId);

    List<AppointmentParticipant> findByActorPractitionerId(UUID practitionerId);

    @Modifying
    @Query("DELETE FROM AppointmentParticipant p WHERE p.appointmentId = :appointmentId AND p.actorPractitionerId IS NOT NULL")
    void deletePractitionerParticipants(UUID appointmentId);

    @Query("""
        SELECT p.appointmentId FROM AppointmentParticipant p
        WHERE p.actorPractitionerId = :practitionerId
        """)
    List<UUID> findAppointmentIdsByPractitionerId(UUID practitionerId);
}