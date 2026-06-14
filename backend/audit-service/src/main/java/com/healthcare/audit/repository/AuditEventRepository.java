package com.healthcare.audit.repository;

import com.healthcare.audit.domain.entity.AuditEvent;
import com.healthcare.audit.domain.entity.AuditEventId;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.UUID;

@Repository
public interface AuditEventRepository extends JpaRepository<AuditEvent, AuditEventId> {

    @Query("""
            SELECT a FROM AuditEvent a
            WHERE a.entityPatientId = :patientId
              AND a.recorded BETWEEN :from AND :to
            ORDER BY a.recorded DESC
            """)
    Page<AuditEvent> findByPatientAndPeriod(
            @Param("patientId") UUID patientId,
            @Param("from") OffsetDateTime from,
            @Param("to") OffsetDateTime to,
            Pageable pageable);

    @Query("""
            SELECT a FROM AuditEvent a
            WHERE a.agentUserId = :userId
              AND a.recorded BETWEEN :from AND :to
            ORDER BY a.recorded DESC
            """)
    Page<AuditEvent> findByUserAndPeriod(
            @Param("userId") UUID userId,
            @Param("from") OffsetDateTime from,
            @Param("to") OffsetDateTime to,
            Pageable pageable);
}
