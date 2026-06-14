package com.healthcare.billing.repository;

import com.healthcare.billing.domain.entity.Coverage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CoverageRepository extends JpaRepository<Coverage, UUID> {

    List<Coverage> findByPatientIdOrderByOrderOfBenefitAsc(UUID patientId);

    List<Coverage> findByPatientIdAndStatus(UUID patientId, String status);
}
