package com.healthcare.patient.service;

import com.healthcare.common.exception.ConflictException;
import com.healthcare.common.exception.ResourceNotFoundException;
import com.healthcare.patient.domain.entity.Practitioner;
import com.healthcare.patient.dto.request.CreatePractitionerRequest;
import com.healthcare.patient.dto.response.PractitionerResponse;
import com.healthcare.patient.mapper.PatientMapper;
import com.healthcare.patient.repository.PractitionerRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PractitionerService {

    private final PractitionerRepository practitionerRepository;
    private final PatientMapper mapper;

    @Transactional
    public PractitionerResponse createPractitioner(CreatePractitionerRequest request) {
        if (request.npi() != null && practitionerRepository.existsByNpi(request.npi())) {
            throw new ConflictException("Practitioner", "NPI", request.npi());
        }

        Practitioner practitioner = mapper.toPractitionerEntity(request);

        Practitioner saved = practitionerRepository.save(practitioner);
        log.info("Practitioner created: npi={}, id={}", saved.getNpi(), saved.getId());
        return mapper.toPractitionerResponse(saved);
    }

    public PractitionerResponse getPractitioner(UUID id) {
        return practitionerRepository.findById(id)
                .map(mapper::toPractitionerResponse)
                .orElseThrow(() -> new ResourceNotFoundException("Practitioner", id));
    }

    @Transactional
    public void togglePractitioner(UUID id, boolean active) {
        Practitioner practitioner = practitionerRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Practitioner", id));
        practitioner.setActive(active);
        practitionerRepository.save(practitioner);
        log.info("Practitioner {}: id={}", active ? "activated" : "deactivated", id);
    }

    public Page<PractitionerResponse> listPractitioners(String familyName, Pageable pageable) {
        if (familyName != null && !familyName.isBlank()) {
            return practitionerRepository
                    .findByActiveTrueAndFamilyNameContainingIgnoreCase(familyName, pageable)
                    .map(mapper::toPractitionerResponse);
        }
        return practitionerRepository.findByActiveTrue(pageable)
                .map(mapper::toPractitionerResponse);
    }
}
