package com.healthcare.patient.service;

import com.healthcare.common.crypto.PhiEncryptionService;
import com.healthcare.common.exception.ConflictException;
import com.healthcare.common.exception.ResourceNotFoundException;
import com.healthcare.patient.domain.entity.*;
import com.healthcare.patient.dto.request.CreatePatientRequest;
import com.healthcare.patient.dto.request.UpdatePatientRequest;
import com.healthcare.patient.dto.response.PatientResponse;
import com.healthcare.patient.mapper.PatientMapper;
import com.healthcare.patient.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.lang.Nullable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;
import java.util.concurrent.atomic.AtomicReference;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PatientService {

    private final PatientRepository patientRepository;
    private final OrganizationRepository organizationRepository;
    private final PatientNameRepository patientNameRepository;
    private final PhiEncryptionService phiEncryptionService;
    private final PatientMapper mapper;
    @Nullable
    private final KafkaTemplate<String, Object> kafkaTemplate;

    @Transactional
    public PatientResponse createPatient(CreatePatientRequest request) {
        Patient patient = mapper.toEntity(request);

        if (request.managingOrganizationId() != null) {
            Organization org = organizationRepository.findById(request.managingOrganizationId())
                    .orElseThrow(() -> new ResourceNotFoundException("Organization",
                            request.managingOrganizationId()));
            patient.setManagingOrganization(org);
        }

        patient.setMrn(MrnGenerator.generate());

        if (request.names() != null) {
            request.names().forEach(nameReq -> {
                PatientName name = mapper.toNameEntity(nameReq);
                patient.addName(name);
            });
        }

        if (request.addresses() != null) {
            request.addresses().forEach(addrReq -> {
                PatientAddress address = mapper.toAddressEntity(addrReq);
                patient.addAddress(address);
            });
        }

        if (request.telecoms() != null) {
            request.telecoms().forEach(telReq -> {
                PatientTelecom telecom = mapper.toTelecomEntity(telReq);
                telecom.setValueHmac(phiEncryptionService.hmac(telReq.value()));
                patient.addTelecom(telecom);
            });
        }

        Patient saved = patientRepository.save(patient);
        sendEvent("patient.created", saved.getId().toString(), buildPatientCreatedEvent(saved));
        log.info("Patient created: mrn={}, id={}", saved.getMrn(), saved.getId());
        return mapper.toResponse(saved);
    }

    @Cacheable(value = "patients", key = "#id")
    public PatientResponse getPatient(UUID id) {
        Patient patient = patientRepository.findByIdWithNames(id)
                .orElseThrow(() -> new ResourceNotFoundException("Patient", id));
        return mapper.toResponse(patient);
    }

    public PatientResponse getPatientByMrn(String mrn) {
        Patient patient = patientRepository.findByMrn(mrn)
                .orElseThrow(() -> new ResourceNotFoundException("Patient with MRN " + mrn + " not found"));
        return mapper.toResponse(patient);
    }

    @Transactional
    @CacheEvict(value = "patients", key = "#id")
    public PatientResponse updatePatient(UUID id, UpdatePatientRequest request) {
        Patient patient = patientRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Patient", id));

        if (!patient.getVersion().equals(request.version())) {
            throw new ConflictException("Patient record has been modified by another user. Please refresh and retry.");
        }

        if (request.gender() != null) patient.setGender(request.gender());
        if (request.birthDate() != null) patient.setBirthDate(request.birthDate());
        if (request.preferredLanguage() != null) patient.setPreferredLanguage(request.preferredLanguage());
        if (request.active() != null) patient.setActive(request.active());

        if (request.managingOrganizationId() != null) {
            Organization org = organizationRepository.findById(request.managingOrganizationId())
                    .orElseThrow(() -> new ResourceNotFoundException("Organization",
                            request.managingOrganizationId()));
            patient.setManagingOrganization(org);
        }

        Patient saved = patientRepository.save(patient);
        sendEvent("patient.updated", saved.getId().toString(), buildPatientUpdatedEvent(saved));
        return mapper.toResponse(saved);
    }

    @Transactional
    @CacheEvict(value = "patients", key = "#id")
    public void togglePatient(UUID id, boolean active) {
        Patient patient = patientRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Patient", id));
        patient.setActive(active);
        patientRepository.save(patient);
        log.info("Patient {}: id={}", active ? "activated" : "deactivated", id);
    }

    @Transactional
    @CacheEvict(value = "patients", key = "#id")
    public void deletePatient(UUID id) {
        if (!patientRepository.existsById(id)) {
            throw new ResourceNotFoundException("Patient", id);
        }
        patientRepository.deleteById(id);
        log.info("Patient soft-deleted: id={}", id);
    }

    public Page<PatientResponse> searchPatients(String name, String mrn, Pageable pageable) {
        if (mrn != null && !mrn.isBlank()) {
            return patientRepository.findByMrnStartingWith(mrn.toUpperCase(), pageable)
                    .map(mapper::toResponse);
        }
        if (name != null && !name.isBlank()) {
            return patientRepository.findByNameFragment(name, pageable)
                    .map(mapper::toResponse);
        }
        return patientRepository.findAll(pageable).map(mapper::toResponse);
    }

    private record PatientCreatedEvent(UUID patientId, String mrn) {}
    private record PatientUpdatedEvent(UUID patientId, String mrn) {}

    /** Sends a Kafka event, skipped silently when broker is unavailable or Kafka is disabled. */
    private void sendEvent(String topic, String key, Object payload) {
        if (kafkaTemplate == null) return;
        try {
            kafkaTemplate.send(topic, key, payload);
        } catch (Exception e) {
            log.warn("Kafka unavailable — event not sent [topic={}, key={}]: {}", topic, key, e.getMessage());
        }
    }

    private PatientCreatedEvent buildPatientCreatedEvent(Patient p) {
        return new PatientCreatedEvent(p.getId(), p.getMrn());
    }

    private PatientUpdatedEvent buildPatientUpdatedEvent(Patient p) {
        return new PatientUpdatedEvent(p.getId(), p.getMrn());
    }

    /** Simple in-process MRN generator. In production: call DB function generate_mrn(). */
    private static class MrnGenerator {
        static String generate() {
            return "MRN" + System.currentTimeMillis();
        }
    }
}
