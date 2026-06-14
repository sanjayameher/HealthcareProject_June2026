package com.healthcare.patient.aspect;

import com.healthcare.common.audit.AuditContext;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.AfterReturning;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.stereotype.Component;

/**
 * AOP aspect that emits a structured HIPAA PHI-access audit log entry
 * after every public patient service method returns successfully.
 *
 * In production this would write to audit.phi_access_log via Kafka or a direct DB insert.
 */
@Aspect
@Component
@Slf4j
public class PhiAuditAspect {

    @AfterReturning(
            pointcut = "execution(public * com.healthcare.patient.service.PatientService.*(..))",
            returning = "result"
    )
    public void auditPhiAccess(JoinPoint jp, Object result) {
        AuditContext ctx = AuditContext.current();
        String userId = ctx != null ? String.valueOf(ctx.userId()) : "SYSTEM";
        String role   = ctx != null ? ctx.userRole() : "UNKNOWN";

        log.info("PHI_ACCESS action={} user={} role={} resource=Patient",
                jp.getSignature().getName(), userId, role);
    }
}
