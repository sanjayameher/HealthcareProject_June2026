package com.healthcare.patient.repository;

import com.healthcare.patient.domain.entity.Organization;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface OrganizationRepository extends JpaRepository<Organization, UUID> {

    Optional<Organization> findByNpi(String npi);

    boolean existsByNpi(String npi);

    Page<Organization> findByActiveTrue(Pageable pageable);

    Page<Organization> findByNameContainingIgnoreCaseAndActiveTrue(String name, Pageable pageable);
}
