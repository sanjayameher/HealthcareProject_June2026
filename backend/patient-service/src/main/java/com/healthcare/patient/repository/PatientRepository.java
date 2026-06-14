package com.healthcare.patient.repository;

import com.healthcare.patient.domain.entity.Patient;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface PatientRepository extends JpaRepository<Patient, UUID> {

    Optional<Patient> findByMrn(String mrn);

    boolean existsByMrn(String mrn);

    @Query("""
            SELECT p FROM Patient p
            LEFT JOIN FETCH p.names n
            WHERE p.id = :id
            """)
    Optional<Patient> findByIdWithNames(@Param("id") UUID id);

    @Query("""
            SELECT DISTINCT p FROM Patient p
            LEFT JOIN p.names n
            WHERE LOWER(CONCAT(COALESCE(FUNCTION('array_to_string', n.given, ' '), ''), ' ', n.family))
                  LIKE LOWER(CONCAT('%', :nameFragment, '%'))
            """)
    Page<Patient> findByNameFragment(@Param("nameFragment") String nameFragment, Pageable pageable);

    @Query("SELECT p FROM Patient p WHERE p.managingOrganization.id = :orgId")
    Page<Patient> findByOrganizationId(@Param("orgId") UUID orgId, Pageable pageable);

    @Modifying
    @Query("UPDATE Patient p SET p.active = false, p.updatedAt = CURRENT_TIMESTAMP WHERE p.id = :id")
    int deactivate(@Param("id") UUID id);
}
