package com.healthcare.portal.repository;

import com.healthcare.portal.domain.entity.PatientAccount;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface PatientAccountRepository extends JpaRepository<PatientAccount, UUID> {

    Optional<PatientAccount> findByEmailHash(byte[] emailHash);

    Optional<PatientAccount> findByPatientId(UUID patientId);

    boolean existsByEmailHash(byte[] emailHash);
}