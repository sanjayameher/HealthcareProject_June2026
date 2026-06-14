package com.healthcare.patient.service;

import com.healthcare.common.exception.ConflictException;
import com.healthcare.common.exception.ResourceNotFoundException;
import com.healthcare.patient.domain.entity.Organization;
import com.healthcare.patient.dto.request.CreateOrganizationRequest;
import com.healthcare.patient.dto.response.OrganizationResponse;
import com.healthcare.patient.mapper.PatientMapper;
import com.healthcare.patient.repository.OrganizationRepository;
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
public class OrganizationService {

    private final OrganizationRepository organizationRepository;
    private final PatientMapper mapper;

    @Transactional
    public OrganizationResponse createOrganization(CreateOrganizationRequest request) {
        if (request.npi() != null && organizationRepository.existsByNpi(request.npi())) {
            throw new ConflictException("Organization", "NPI", request.npi());
        }

        Organization org = mapper.toOrganizationEntity(request);

        if (request.parentId() != null) {
            Organization parent = organizationRepository.findById(request.parentId())
                    .orElseThrow(() -> new ResourceNotFoundException("Organization", request.parentId()));
            org.setParent(parent);
        }

        Organization saved = organizationRepository.save(org);
        log.info("Organization created: name={}, id={}", saved.getName(), saved.getId());
        return mapper.toOrganizationResponse(saved);
    }

    public OrganizationResponse getOrganization(UUID id) {
        return organizationRepository.findById(id)
                .map(mapper::toOrganizationResponse)
                .orElseThrow(() -> new ResourceNotFoundException("Organization", id));
    }

    public Page<OrganizationResponse> listOrganizations(String name, Pageable pageable) {
        if (name != null && !name.isBlank()) {
            return organizationRepository
                    .findByNameContainingIgnoreCaseAndActiveTrue(name, pageable)
                    .map(mapper::toOrganizationResponse);
        }
        return organizationRepository.findByActiveTrue(pageable)
                .map(mapper::toOrganizationResponse);
    }
}
