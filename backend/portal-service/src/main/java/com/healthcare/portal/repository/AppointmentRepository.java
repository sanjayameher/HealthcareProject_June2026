package com.healthcare.portal.repository;

import com.healthcare.portal.domain.entity.Appointment;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface AppointmentRepository extends JpaRepository<Appointment, UUID> {

    Page<Appointment> findByPatientIdOrderByStartTimeDesc(UUID patientId, Pageable pageable);

    @Query("""
            SELECT a FROM Appointment a
            WHERE a.patientId = :patientId
              AND a.startTime >= :from
              AND a.startTime < :to
              AND a.status NOT IN :excluded
            ORDER BY a.startTime
            """)
    List<Appointment> findUpcomingForPatient(
            @Param("patientId") UUID patientId,
            @Param("from") OffsetDateTime from,
            @Param("to") OffsetDateTime to,
            @Param("excluded") List<com.healthcare.portal.domain.enums.AppointmentStatus> excluded);

    @Query("""
            SELECT a FROM Appointment a
            WHERE a.startTime >= :from
              AND a.startTime < :to
              AND a.status NOT IN :excluded
            ORDER BY a.startTime
            """)
    List<Appointment> findAllInDateRange(
            @Param("from") OffsetDateTime from,
            @Param("to") OffsetDateTime to,
            @Param("excluded") List<com.healthcare.portal.domain.enums.AppointmentStatus> excluded);
}
