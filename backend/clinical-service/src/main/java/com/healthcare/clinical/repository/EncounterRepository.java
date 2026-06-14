package com.healthcare.clinical.repository;

import com.healthcare.clinical.domain.entity.Encounter;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface EncounterRepository extends JpaRepository<Encounter, UUID> {

    Page<Encounter> findByPatientIdOrderByPeriodStartDesc(UUID patientId, Pageable pageable);

    List<Encounter> findByPatientIdAndStatus(UUID patientId, String status);
}
