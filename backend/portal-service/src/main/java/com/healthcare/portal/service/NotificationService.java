package com.healthcare.portal.service;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Inserts rows into dev.notifications.
 * A background worker / Kafka consumer (outside this service) picks them up and sends the actual email/SMS.
 */
@Slf4j
@Service
public class NotificationService {

    @PersistenceContext
    private EntityManager em;

    @Transactional
    public void notifyPatient(UUID patientId, String type, String title, String body) {
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
    }

    @Transactional
    public void notifyPractitioner(UUID practitionerId, String type, String title, String body) {
        em.createNativeQuery("""
                INSERT INTO dev.notifications
                    (id, recipient_practitioner_id, channel, status, notification_type, title, body,
                     scheduled_for, created_at, updated_at)
                VALUES
                    (gen_random_uuid(), :practitionerId, 'email', 'pending', :type, :title, :body,
                     NOW(), NOW(), NOW())
                """)
                .setParameter("practitionerId", practitionerId)
                .setParameter("type", type)
                .setParameter("title", title)
                .setParameter("body", body)
                .executeUpdate();
    }
}