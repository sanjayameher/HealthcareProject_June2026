package com.healthcare.patient.repository;

import com.healthcare.patient.domain.entity.PatientName;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface PatientNameRepository extends JpaRepository<PatientName, UUID> {

    List<PatientName> findByPatientIdOrderByPeriodStartDesc(UUID patientId);
}
