package com.healthcare.audit.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.OffsetDateTime;
import java.util.Map;
import java.util.UUID;

/**
 * Maps to audit.audit_events (range-partitioned annually).
 * IMMUTABLE — no UPDATE or DELETE permitted (enforced by RLS in PostgreSQL).
 * PRIMARY KEY is composite (id, recorded).
 */
@Entity
@Table(name = "audit_events", schema = "dev")
@IdClass(AuditEventId.class)
@Getter
@NoArgsConstructor
@EqualsAndHashCode(of = {"id", "recorded"})
public class AuditEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Id
    @Column(name = "recorded", nullable = false)
    private OffsetDateTime recorded;

    @Column(name = "type_system", nullable = false)
    private String typeSystem;

    @Column(name = "type_code", nullable = false, length = 30)
    private String typeCode;

    @Column(name = "type_display")
    private String typeDisplay;

    @Column(name = "action", nullable = false, length = 1)
    private String action;

    @Column(name = "outcome", nullable = false, length = 1)
    private String outcome;

    @Column(name = "outcome_description")
    private String outcomeDescription;

    @Column(name = "agent_user_id")
    private UUID agentUserId;

    @Column(name = "agent_role", length = 30)
    private String agentRole;

    @Column(name = "agent_name")
    private String agentName;

    @Column(name = "source_site", length = 100)
    private String sourceSite;

    @Column(name = "source_observer", length = 100)
    private String sourceObserver;

    @Column(name = "entity_patient_id")
    private UUID entityPatientId;

    @Column(name = "entity_resource_type", length = 50)
    private String entityResourceType;

    @Column(name = "entity_resource_id")
    private UUID entityResourceId;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "entity_detail", columnDefinition = "JSONB")
    private Map<String, Object> entityDetail;

    @Column(name = "ip_address", length = 45)
    private String ipAddress;

    @Column(name = "user_agent")
    private String userAgent;

    @Column(name = "session_id", length = 100)
    private String sessionId;

    @PrePersist
    void prePersist() {
        if (this.recorded == null) {
            this.recorded = OffsetDateTime.now();
        }
    }
}
