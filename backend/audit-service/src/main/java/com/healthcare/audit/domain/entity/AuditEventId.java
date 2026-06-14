package com.healthcare.audit.domain.entity;

import java.io.Serializable;
import java.time.OffsetDateTime;
import java.util.Objects;
import java.util.UUID;

public class AuditEventId implements Serializable {

    private UUID id;
    private OffsetDateTime recorded;

    public AuditEventId() {}

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof AuditEventId that)) return false;
        return Objects.equals(id, that.id) && Objects.equals(recorded, that.recorded);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id, recorded);
    }
}
