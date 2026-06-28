package com.healthcare.portal.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.UUID;

@Slf4j
@Service
public class ClinicalSyncService {

    private final RestClient restClient;

    public ClinicalSyncService(@Value("${healthcare.clinical.service-url}") String clinicalServiceUrl) {
        this.restClient = RestClient.builder()
                .baseUrl(clinicalServiceUrl)
                .build();
    }

    public void syncPractitionerStatus(UUID practitionerId, boolean active) {
        try {
            restClient.patch()
                    .uri("/api/v1/practitioners/{id}/toggle?active={active}", practitionerId, active)
                    .retrieve()
                    .toBodilessEntity();
            log.info("Synced practitioner {} active={} to clinical service", practitionerId, active);
        } catch (Exception e) {
            log.warn("Could not sync practitioner status to clinical service [id={}]: {}", practitionerId, e.getMessage());
        }
    }

    public void syncPatientStatus(UUID patientId, boolean active) {
        try {
            restClient.patch()
                    .uri("/api/v1/patients/{id}/toggle?active={active}", patientId, active)
                    .retrieve()
                    .toBodilessEntity();
            log.info("Synced patient {} active={} to clinical service", patientId, active);
        } catch (Exception e) {
            log.warn("Could not sync patient status to clinical service [id={}]: {}", patientId, e.getMessage());
        }
    }
}