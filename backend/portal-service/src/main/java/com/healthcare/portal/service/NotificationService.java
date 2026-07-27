package com.healthcare.portal.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationService {

    private final DataSource dataSource;

    public void notifyPatient(UUID patientId, String type, String title, String body) {
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "INSERT INTO dev.notifications " +
                     "(patient_id, channel, status, notification_type, title, body, scheduled_for, created_at, updated_at) " +
                     "VALUES (?, 'email'::dev.notification_channel, 'pending'::dev.notification_status, ?, ?, ?, NOW(), NOW(), NOW())")) {
            ps.setObject(1, patientId);
            ps.setString(2, type);
            ps.setString(3, title);
            ps.setString(4, body);
            ps.executeUpdate();
        } catch (Exception e) {
            log.warn("Could not save patient notification [patientId={}, type={}]: {}", patientId, type, e.getMessage());
        }
    }

    public void notifyPractitioner(UUID practitionerId, String type, String title, String body) {
        log.info("Practitioner notification [practitionerId={}, type={}, title={}]", practitionerId, type, title);
    }
}
