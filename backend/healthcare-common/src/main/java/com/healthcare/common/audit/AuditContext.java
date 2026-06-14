package com.healthcare.common.audit;

import java.util.UUID;

/**
 * Thread-local holder for HIPAA audit context.
 * Set at the gateway/filter layer; read by AOP aspects before any PHI access.
 */
public final class AuditContext {

    private static final ThreadLocal<AuditContext> HOLDER = new ThreadLocal<>();

    private final UUID userId;
    private final String userRole;
    private final UUID organizationId;
    private final String requestId;
    private final String ipAddress;
    private final String userAgent;

    private AuditContext(Builder b) {
        this.userId = b.userId;
        this.userRole = b.userRole;
        this.organizationId = b.organizationId;
        this.requestId = b.requestId;
        this.ipAddress = b.ipAddress;
        this.userAgent = b.userAgent;
    }

    public static void set(AuditContext ctx) {
        HOLDER.set(ctx);
    }

    public static AuditContext current() {
        return HOLDER.get();
    }

    public static void clear() {
        HOLDER.remove();
    }

    public UUID userId() { return userId; }
    public String userRole() { return userRole; }
    public UUID organizationId() { return organizationId; }
    public String requestId() { return requestId; }
    public String ipAddress() { return ipAddress; }
    public String userAgent() { return userAgent; }

    public static Builder builder() { return new Builder(); }

    public static final class Builder {
        private UUID userId;
        private String userRole;
        private UUID organizationId;
        private String requestId;
        private String ipAddress;
        private String userAgent;

        public Builder userId(UUID v) { this.userId = v; return this; }
        public Builder userRole(String v) { this.userRole = v; return this; }
        public Builder organizationId(UUID v) { this.organizationId = v; return this; }
        public Builder requestId(String v) { this.requestId = v; return this; }
        public Builder ipAddress(String v) { this.ipAddress = v; return this; }
        public Builder userAgent(String v) { this.userAgent = v; return this; }
        public AuditContext build() { return new AuditContext(this); }
    }
}
