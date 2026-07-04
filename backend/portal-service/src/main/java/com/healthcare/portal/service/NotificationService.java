package com.healthcare.portal.service;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Slf4j
@Service
public class NotificationService {

    @PersistenceContext
    private EntityManager em;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void notifyPatient(UUID patientId, String type, String title, String body) {
        try {
            em.createNativeQuery("""
                    INSERT INTO dev.notifications
                        (id, patient_id, channel, status, notification_type, title, body,
                         scheduled_for, created_at, updated_at)
                    VALUES
                        (gen_random_uuid(), :patientId, 'email', 'pending', :type, :title, :body,
                         NOW(), NOW(), NOW())
                    """)
                    .setParameter("patientId", patientId)
                    .setParameter("type", type)
                    .setParameter("title", title)
                    .setParameter("body", body)
                    .executeUpdate();
        } catch (Exception e) {
            log.warn("Could not save patient notification [patientId={}, type={}]: {}", patientId, type, e.getMessage());
        }
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void notifyPractitioner(UUID practitionerId, String type, String title, String body) {
        // Notifications table is patient-scoped; practitioner notifications are logged only until schema is extended
        log.info("Practitioner notification [practitionerId={}, type={}, title={}]", practitionerId, type, title);
    }
}