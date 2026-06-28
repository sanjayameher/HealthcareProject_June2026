package com.healthcare.portal.controller;

import com.healthcare.common.dto.ApiResponse;
import com.healthcare.portal.dto.LoginRequest;
import com.healthcare.portal.dto.LoginResponse;
import com.healthcare.portal.dto.SetPasswordRequest;
import com.healthcare.portal.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@Tag(name = "Authentication", description = "Login endpoints for Admin, Doctor, and Patient portals")
public class AuthController {

    private final AuthService authService;

    @PostMapping("/admin/login")
    @Operation(summary = "Admin portal login")
    public ResponseEntity<ApiResponse<LoginResponse>> adminLogin(
            @Valid @RequestBody LoginRequest req,
            HttpServletRequest httpReq) {
        LoginResponse resp = authService.adminLogin(req, httpReq.getRemoteAddr());
        return ResponseEntity.ok(ApiResponse.ok(resp, "Login successful"));
    }

    @PostMapping("/doctor/login")
    @Operation(summary = "Doctor portal login")
    public ResponseEntity<ApiResponse<LoginResponse>> doctorLogin(
            @Valid @RequestBody LoginRequest req,
            HttpServletRequest httpReq) {
        LoginResponse resp = authService.doctorLogin(req, httpReq.getRemoteAddr());
        return ResponseEntity.ok(ApiResponse.ok(resp, "Login successful"));
    }

    @PostMapping("/patient/login")
    @Operation(summary = "Patient portal login")
    public ResponseEntity<ApiResponse<LoginResponse>> patientLogin(
            @Valid @RequestBody LoginRequest req,
            HttpServletRequest httpReq) {
        LoginResponse resp = authService.patientLogin(req, httpReq.getRemoteAddr());
        return ResponseEntity.ok(ApiResponse.ok(resp, "Login successful"));
    }

    @PostMapping("/doctor/set-password")
    @Operation(summary = "Set initial password for a doctor using one-time token")
    public ResponseEntity<ApiResponse<Void>> setDoctorPassword(@Valid @RequestBody SetPasswordRequest req) {
        authService.setDoctorPassword(req);
        return ResponseEntity.ok(ApiResponse.ok(null, "Password updated successfully"));
    }

    @PostMapping("/patient/set-password")
    @Operation(summary = "Set initial password for a patient using one-time token")
    public ResponseEntity<ApiResponse<Void>> setPatientPassword(@Valid @RequestBody SetPasswordRequest req) {
        authService.setPatientPassword(req);
        return ResponseEntity.ok(ApiResponse.ok(null, "Password updated successfully"));
    }
}