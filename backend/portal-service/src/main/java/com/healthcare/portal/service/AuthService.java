package com.healthcare.portal.service;

import com.healthcare.common.crypto.PhiEncryptionService;
import com.healthcare.common.exception.BusinessException;
import com.healthcare.portal.domain.entity.AdminAccount;
import com.healthcare.portal.domain.entity.PatientAccount;
import com.healthcare.portal.domain.entity.PractitionerAccount;
import com.healthcare.portal.domain.entity.PractitionerView;
import com.healthcare.portal.dto.LoginRequest;
import com.healthcare.portal.dto.LoginResponse;
import com.healthcare.portal.dto.SetPasswordRequest;
import com.healthcare.portal.repository.*;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private static final int MAX_ATTEMPTS = 5;
    private static final int LOCK_MINUTES = 30;

    private final AdminAccountRepository adminRepo;
    private final PractitionerAccountRepository practitionerAccountRepo;
    private final PatientAccountRepository patientAccountRepo;
    private final PractitionerViewRepository practitionerViewRepo;
    private final PhiEncryptionService phi;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenService jwtTokenService;

    // ── Admin Login ──────────────────────────────────────────────

    @Transactional
    public LoginResponse adminLogin(LoginRequest req, String ipAddress) {
        String normalizedEmail = req.email().toLowerCase().trim();
        AdminAccount account = adminRepo.findByEmail(normalizedEmail)
                .orElseThrow(() -> loginFailed("not_found"));

        checkAccountLocked(account.getLockedUntil(), account.getFailedLoginAttempts(), "admin");

        if (!account.isActive()) throw loginFailed("account_inactive");

        if (!passwordEncoder.matches(req.password(), account.getPasswordHash())) {
            account.setFailedLoginAttempts((short) (account.getFailedLoginAttempts() + 1));
            if (account.getFailedLoginAttempts() >= MAX_ATTEMPTS) {
                account.setLockedUntil(OffsetDateTime.now().plusMinutes(LOCK_MINUTES));
                log.warn("Admin account locked: {}", normalizedEmail);
            }
            adminRepo.save(account);
            throw loginFailed("bad_password");
        }

        account.setFailedLoginAttempts((short) 0);
        account.setLockedUntil(null);
        account.setLastLoginAt(OffsetDateTime.now());
        account.setLastLoginIp(ipAddress);
        adminRepo.save(account);

        String token = jwtTokenService.generateToken(account.getId(), "ADMIN", account.getEmail());
        return new LoginResponse(token, "ADMIN", account.getId(), account.getFullName(), account.isMustChangePassword());
    }

    // ── Doctor Login ─────────────────────────────────────────────

    @Transactional
    public LoginResponse doctorLogin(LoginRequest req, String ipAddress) {
        byte[] emailHash = phi.hmac(req.email().toLowerCase().trim());
        PractitionerAccount account = practitionerAccountRepo.findByEmailHash(emailHash)
                .orElseThrow(() -> loginFailed("not_found"));

        checkAccountLocked(account.getLockedUntil(), account.getFailedLoginAttempts(), "practitioner");

        if (!account.isActive()) throw loginFailed("account_inactive");

        if (!passwordEncoder.matches(req.password(), account.getPasswordHash())) {
            account.setFailedLoginAttempts((short) (account.getFailedLoginAttempts() + 1));
            if (account.getFailedLoginAttempts() >= MAX_ATTEMPTS) {
                account.setLockedUntil(OffsetDateTime.now().plusMinutes(LOCK_MINUTES));
            }
            practitionerAccountRepo.save(account);
            throw loginFailed("bad_password");
        }

        account.setFailedLoginAttempts((short) 0);
        account.setLockedUntil(null);
        account.setLastLoginAt(OffsetDateTime.now());
        account.setLastLoginIp(ipAddress);
        practitionerAccountRepo.save(account);

        PractitionerView prac = practitionerViewRepo.findById(account.getPractitionerId())
                .orElseThrow(() -> new EntityNotFoundException("Practitioner not found"));

        String fullName = (prac.getPrefix() != null ? prac.getPrefix() + " " : "")
                + prac.getGivenName() + " " + prac.getFamilyName();
        String token = jwtTokenService.generateToken(account.getPractitionerId(), "CLINICIAN", account.getEmail());
        return new LoginResponse(token, "CLINICIAN", account.getPractitionerId(), fullName.trim(), account.isMustChangePassword());
    }

    // ── Patient Login ────────────────────────────────────────────

    @Transactional
    public LoginResponse patientLogin(LoginRequest req, String ipAddress) {
        byte[] emailHash = phi.hmac(req.email().toLowerCase().trim());
        PatientAccount account = patientAccountRepo.findByEmailHash(emailHash)
                .orElseThrow(() -> loginFailed("not_found"));

        checkAccountLocked(account.getLockedUntil(), account.getFailedLoginAttempts(), "patient");

        if (!account.isActive()) throw loginFailed("account_inactive");

        if (!passwordEncoder.matches(req.password(), account.getPasswordHash())) {
            account.setFailedLoginAttempts((short) (account.getFailedLoginAttempts() + 1));
            if (account.getFailedLoginAttempts() >= MAX_ATTEMPTS) {
                account.setLockedUntil(OffsetDateTime.now().plusMinutes(LOCK_MINUTES));
            }
            patientAccountRepo.save(account);
            throw loginFailed("bad_password");
        }

        account.setFailedLoginAttempts((short) 0);
        account.setLockedUntil(null);
        account.setLastLoginAt(OffsetDateTime.now());
        account.setLastLoginIp(ipAddress);
        patientAccountRepo.save(account);

        String token = jwtTokenService.generateToken(account.getPatientId(), "PATIENT", account.getEmail());
        return new LoginResponse(token, "PATIENT", account.getPatientId(), "Patient", account.isMustChangePassword());
    }

    // ── Set Password (doctor / patient via one-time token) ───────

    @Transactional
    public void setDoctorPassword(SetPasswordRequest req) {
        UUID practitionerId = jwtTokenService.extractUserId(req.token());
        PractitionerAccount account = practitionerAccountRepo.findByPractitionerId(practitionerId)
                .orElseThrow(() -> new EntityNotFoundException("Practitioner account not found"));
        account.setPasswordHash(passwordEncoder.encode(req.newPassword()));
        account.setMustChangePassword(false);
        account.setPasswordChangedAt(OffsetDateTime.now());
        practitionerAccountRepo.save(account);
    }

    @Transactional
    public void setPatientPassword(SetPasswordRequest req) {
        UUID patientId = jwtTokenService.extractUserId(req.token());
        PatientAccount account = patientAccountRepo.findByPatientId(patientId)
                .orElseThrow(() -> new EntityNotFoundException("Patient account not found"));
        account.setPasswordHash(passwordEncoder.encode(req.newPassword()));
        account.setMustChangePassword(false);
        account.setPasswordChangedAt(OffsetDateTime.now());
        patientAccountRepo.save(account);
    }

    @Transactional
    public void setAdminPassword(UUID adminId, String newPassword) {
        AdminAccount account = adminRepo.findById(adminId)
                .orElseThrow(() -> new EntityNotFoundException("Admin account not found"));
        account.setPasswordHash(passwordEncoder.encode(newPassword));
        account.setMustChangePassword(false);
        adminRepo.save(account);
    }

    // ── Helpers ──────────────────────────────────────────────────

    private void checkAccountLocked(OffsetDateTime lockedUntil, short attempts, String type) {
        if (lockedUntil != null && lockedUntil.isAfter(OffsetDateTime.now())) {
            throw new BusinessException("Account is temporarily locked", HttpStatus.UNAUTHORIZED, "ACCOUNT_LOCKED");
        }
    }

    private BusinessException loginFailed(String reason) {
        return new BusinessException("Authentication failed: " + reason, HttpStatus.UNAUTHORIZED, "AUTH_FAILED");
    }
}