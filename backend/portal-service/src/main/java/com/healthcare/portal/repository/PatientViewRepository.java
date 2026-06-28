package com.healthcare.portal.repository;

import com.healthcare.portal.domain.entity.PatientView;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface PatientViewRepository extends JpaRepository<PatientView, UUID> {

    Optional<PatientView> findByMrn(String mrn);

    Page<PatientView> findByActive(boolean active, Pageable pageable);
}