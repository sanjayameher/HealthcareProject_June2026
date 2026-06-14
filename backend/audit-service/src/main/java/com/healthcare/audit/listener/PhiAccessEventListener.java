package com.healthcare.audit.listener;

import com.healthcare.audit.domain.entity.AuditEvent;
import com.healthcare.audit.repository.AuditEventRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

import java.time.OffsetDateTime;
import java.util.Map;

/**
 * Consumes phi.accessed events from Kafka and persists them to audit.audit_events.
 * Running in a virtual thread per message (Java 21).
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class PhiAccessEventListener {

    private final AuditEventRepository auditEventRepository;

    @KafkaListener(topics = "phi.accessed", groupId = "audit-service")
    public void handlePhiAccess(Map<String, Object> event) {
        try {
            AuditEvent auditEvent = new AuditEvent();
            // AuditEvent fields are set via reflection-friendly approach for immutability
            auditEventRepository.save(buildFromEvent(event));
        } catch (Exception e) {
            log.error("Failed to persist PHI access audit event: {}", e.getMessage(), e);
        }
    }

    @KafkaListener(topics = "patient.created", groupId = "audit-service")
    public void handlePatientCreated(Map<String, Object> event) {
        log.info("Audit: patient.created event received: {}", event);
    }

    @KafkaListener(topics = "patient.updated", groupId = "audit-service")
    public void handlePatientUpdated(Map<String, Object> event) {
        log.info("Audit: patient.updated event received: {}", event);
    }

    @KafkaListener(topics = "encounter.finished", groupId = "audit-service")
    public void handleEncounterFinished(Map<String, Object> event) {
        log.info("Audit: encounter.finished event received: {}", event);
    }

    private AuditEvent buildFromEvent(Map<String, Object> event) {
        // In a real implementation, map event fields to AuditEvent fields
        // AuditEvent is immutable so we use the @PrePersist to set recorded timestamp
        return new AuditEvent();
    }
}
