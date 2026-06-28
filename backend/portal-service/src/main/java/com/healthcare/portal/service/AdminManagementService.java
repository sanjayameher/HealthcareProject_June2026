package com.healthcare.portal.service;

import com.healthcare.common.crypto.PhiEncryptionService;
import com.healthcare.common.exception.ConflictException;
import com.healthcare.portal.domain.entity.AdminAccount;
import com.healthcare.portal.domain.entity.PatientAccount;
import com.healthcare.portal.domain.entity.PractitionerAccount;
import com.healthcare.portal.dto.CreateAdminRequest;
import com.healthcare.portal.dto.InviteResponse;
import com.healthcare.portal.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AdminManagementService {

    private final AdminAccountRepository adminRepo;
    private final PractitionerAccountRepository practitionerAccountRepo;
    private final PatientAccountRepository patientAccountRepo;
    private final PhiEncryptionService phi;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenService jwtTokenService;
    private final ClinicalSyncService clinicalSyncService;

    // ── Admin account management ─────────────────────────────────

    @Transactional
    public AdminAccount createAdmin(CreateAdminRequest req, UUID createdByAdminId) {
        String email = req.email().toLowerCase().trim();
        if (adminRepo.existsByEmail(email)) {
            throw new ConflictException("Admin account with this email already exists");
        }
        String rawPassword = (req.password() != null && !req.password().isBlank())
                ? req.password()
                : generateTempPassword();

        AdminAccount account = new AdminAccount();
        account.setEmail(email);
        account.setFullName(req.fullName());
        account.setPasswordHash(passwordEncoder.encode(rawPassword));
        account.setMustChangePassword(true);
        account.setActive(true);
        account.setSuperAdmin(false);
        account.setCreatedBy(createdByAdminId);
        return adminRepo.save(account);
    }

    // ── Doctor (practitioner) account management ─────────────────

    @Transactional
    public InviteResponse createDoctorAccount(UUID practitionerId, String email) {
        byte[] emailHash = phi.hmac(email.toLowerCase().trim());
        if (practitionerAccountRepo.existsByEmailHash(emailHash)) {
            throw new ConflictException("A practitioner account with this email already exists");
        }

        String tempPassword = generateTempPassword();
        PractitionerAccount account = new PractitionerAccount();
        account.setPractitionerId(practitionerId);
        account.setEmail(email.toLowerCase().trim());
        account.setEmailHash(emailHash);
        account.setPasswordHash(passwordEncoder.encode(tempPassword));
        account.setMustChangePassword(true);
        account.setActive(true);
        account = practitionerAccountRepo.save(account);

        String resetToken = jwtTokenService.generatePasswordResetToken(practitionerId, "CLINICIAN");
        return new InviteResponse(account.getId(), "CLINICIAN", resetToken);
    }

    public InviteResponse regenerateDoctorInvite(UUID practitionerId) {
        PractitionerAccount account = practitionerAccountRepo.findByPractitionerId(practitionerId)
                .orElseThrow(() -> new com.healthcare.common.exception.ResourceNotFoundException(
                        "PractitionerAccount", practitionerId));
        String resetToken = jwtTokenService.generatePasswordResetToken(practitionerId, "CLINICIAN");
        return new InviteResponse(account.getId(), "CLINICIAN", resetToken);
    }

    @Transactional
    public void toggleDoctorAccount(UUID practitionerId, boolean active, String reason) {
        practitionerAccountRepo.findByPractitionerId(practitionerId).ifPresent(account -> {
            account.setActive(active);
            if (!active) {
                account.setDeactivatedAt(OffsetDateTime.now());
                account.setDeactivationReason(reason);
            } else {
                account.setDeactivatedAt(null);
                account.setDeactivationReason(null);
            }
            practitionerAccountRepo.save(account);
        });
        clinicalSyncService.syncPractitionerStatus(practitionerId, active);
    }

    // ── Patient account management ───────────────────────────────

    @Transactional
    public InviteResponse createPatientAccount(UUID patientId, String email) {
        byte[] emailHash = phi.hmac(email.toLowerCase().trim());
        if (patientAccountRepo.existsByEmailHash(emailHash)) {
            throw new ConflictException("A patient account with this email already exists");
        }

        String tempPassword = generateTempPassword();
        PatientAccount account = new PatientAccount();
        account.setPatientId(patientId);
        account.setEmail(email.toLowerCase().trim());
        account.setEmailHash(emailHash);
        account.setPasswordHash(passwordEncoder.encode(tempPassword));
        account.setMustChangePassword(true);
        account.setActive(true);
        account = patientAccountRepo.save(account);

        String resetToken = jwtTokenService.generatePasswordResetToken(patientId, "PATIENT");
        return new InviteResponse(account.getId(), "PATIENT", resetToken);
    }

    public InviteResponse regeneratePatientInvite(UUID patientId) {
        PatientAccount account = patientAccountRepo.findByPatientId(patientId)
                .orElseThrow(() -> new com.healthcare.common.exception.ResourceNotFoundException(
                        "PatientAccount", patientId));
        String resetToken = jwtTokenService.generatePasswordResetToken(patientId, "PATIENT");
        return new InviteResponse(account.getId(), "PATIENT", resetToken);
    }

    @Transactional
    public void togglePatientAccount(UUID patientId, boolean active, String reason) {
        patientAccountRepo.findByPatientId(patientId).ifPresent(account -> {
            account.setActive(active);
            if (!active) {
                account.setDeactivatedAt(OffsetDateTime.now());
                account.setDeactivationReason(reason);
            } else {
                account.setDeactivatedAt(null);
                account.setDeactivationReason(null);
            }
            patientAccountRepo.save(account);
        });
        clinicalSyncService.syncPatientStatus(patientId, active);
    }

    private String generateTempPassword() {
        return "Temp@" + UUID.randomUUID().toString().replace("-", "").substring(0, 8);
    }
}