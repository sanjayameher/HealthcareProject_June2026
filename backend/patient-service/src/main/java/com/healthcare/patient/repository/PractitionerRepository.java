package com.healthcare.patient.repository;

import com.healthcare.patient.domain.entity.Practitioner;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface PractitionerRepository extends JpaRepository<Practitioner, UUID> {

    Optional<Practitioner> findByNpi(String npi);

    boolean existsByNpi(String npi);

    Page<Practitioner> findByActiveTrueAndFamilyNameContainingIgnoreCase(String familyName, Pageable pageable);

    Page<Practitioner> findByActiveTrue(Pageable pageable);
}
