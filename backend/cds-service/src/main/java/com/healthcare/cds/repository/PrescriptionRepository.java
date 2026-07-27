package com.healthcare.cds.repository;

import com.healthcare.cds.domain.entity.Prescription;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface PrescriptionRepository extends JpaRepository<Prescription, UUID> {
    List<Prescription> findByPatientIdOrderByCreatedAtDesc(UUID patientId);
}
